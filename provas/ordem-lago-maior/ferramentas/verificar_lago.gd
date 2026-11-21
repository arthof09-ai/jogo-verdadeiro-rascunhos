extends SceneTree
## verificar_lago.gd — ORDEM LAGO-MAIOR. A medição do lago que a sonda (sonda_lago.gd, a da medição de antes) não faz:
##   - as casas de ANDAR × NADAR por grelha-mapa (1 m 75 × 75 · 1,5 m 50 × 50 · 2 m 37 × 37), pelo centro da casa
##     (andar: 0 < fundura ≤ FLUTUA_M; nadar: fundura > FLUTUA_M — a fronteira do NADO);
##   - a fundura no meio, a máxima, e a figura de 1,7 m no meio (o pé no leito: a água acima do pé; e o pé de quem
##     bóia, LagoFloresta.pe_na_agua — o que o jogo já faz hoje, sem mecânica nova);
##   - (só com o lago novo) nenhuma água fora da margem desenhada e nenhuma margem seca por dentro; a costura da zona
##     fina com a larga intacta; os vértices que o lago mudou; o maior desnível dentro das casas de andar.
## Corre com o relevo de ANTES (c9c176f) e com o de AGORA: as funções novas chamam-se por nome, se existirem.
##   copiar para cliente/_verificar_lago.gd e:  godot --headless --path cliente -s res://_verificar_lago.gd -- --saida=<f.json>

const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const LagoFloresta := preload("res://mapa/floresta/lago_floresta.gd")
const GRELHAS := [[1.0, 75, -37.5], [1.5, 50, -37.5], [2.0, 37, -37.0]]

var _saida := ""
## O relevo como objeto (não constante): as funções novas chamam-se por nome, e o analisador não as exige.
var _R: Object = load("res://mapa/floresta/relevo_floresta.gd")


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _tem(nome: String) -> bool:
	for m in (Relevo as GDScript).get_script_method_list():
		if m["name"] == nome:
			return true
	return false


func _correr() -> void:
	var flutua := LagoFloresta.FLUTUA_M
	var nivel := Relevo.nivel_lago()
	var out := {"nivel_m": snappedf(nivel, 0.001), "limiar_nado_m": flutua, "lago_novo": _tem("distancia_margem")}
	# ---- as casas por grelha
	var grelhas := {}
	for g in GRELHAS:
		var s: float = g[0]
		var n: int = g[1]
		var o: float = g[2]
		var andar := 0
		var nadar := 0
		var fmax := 0.0
		for y in n:
			for x in n:
				var cx := o + (x + 0.5) * s
				var cz := o + (y + 0.5) * s
				var f := Relevo.lago_fundura(cx, cz)
				if f > flutua:
					nadar += 1
				elif f > 0.0:
					andar += 1
				fmax = maxf(fmax, f)
		grelhas["%s m (%d × %d)" % [str(s), n, n]] = {"andar": andar, "nadar": nadar, "agua": andar + nadar,
			"fundura_max_centro_casa_m": snappedf(fmax, 0.01)}
	out["casas_por_grelha"] = grelhas
	# ---- o meio, a máxima e a figura de 1,7 m
	var centro: Vector2 = (Relevo as GDScript).get_script_constant_map().get("LAGO_CENTRO", Vector2(19.5, -21.0))
	var maxima := 0.0
	var onde := Vector2.ZERO
	var x := centro.x - 17.0
	while x <= centro.x + 17.0:
		var z := centro.y - 17.0
		while z <= centro.y + 17.0:
			var f := Relevo.lago_fundura(x, z)
			if f > maxima:
				maxima = f
				onde = Vector2(x, z)
			z += 0.25
		x += 0.25
	var f_meio := Relevo.lago_fundura(centro.x, centro.y)
	out["meio"] = {"x": centro.x, "z": centro.y, "fundura_m": snappedf(f_meio, 0.01),
		"figura_1_7m_pe_no_leito": {"agua_acima_do_pe_m": snappedf(f_meio, 0.01), "submersa": f_meio > 1.7,
			"cabeca_abaixo_da_agua_m": snappedf(f_meio - 1.7, 0.01)},
		"figura_1_7m_a_boiar_pe_na_agua": {"pe_y_m": snappedf(LagoFloresta.pe_na_agua(centro.x, centro.y), 0.01),
			"agua_acima_do_pe_m": snappedf(nivel - LagoFloresta.pe_na_agua(centro.x, centro.y), 0.01), "a_nadar": LagoFloresta.a_nadar(centro.x, centro.y)}}
	out["fundura_max_m"] = {"m": snappedf(maxima, 0.01), "x": onde.x, "z": onde.y}
	if out["lago_novo"]:
		# ---- a água fica dentro da margem desenhada (com 0,1 m de folga: a linha de água cai entre vértices de 0,75 m)
		var fora_com_agua := 0
		var dentro_seco := 0
		var amostras := 0
		x = centro.x - 17.0
		while x <= centro.x + 17.0:
			var z := centro.y - 17.0
			while z <= centro.y + 17.0:
				var d: float = _R.call("distancia_margem", x, z)
				var f := Relevo.lago_fundura(x, z)
				amostras += 1
				if d < -0.6 and f > 0.0:
					fora_com_agua += 1
				if d > 0.6 and f <= 0.0:
					dentro_seco += 1
				z += 0.25
			x += 0.25
		out["margem"] = {"amostras_0_25m": amostras, "agua_a_mais_de_0_6m_fora_da_margem": fora_com_agua,
			"seco_a_mais_de_0_6m_dentro_da_margem": dentro_seco}
		# ---- a costura e os vértices mexidos
		var fino := Relevo.grelha_fina()
		var costura_mexida := 0
		var mexidos := 0
		var mexidos_longe := 0
		for j in Relevo.N_FINO:
			for i in Relevo.N_FINO:
				var vx := -Relevo.MEIO_FINO + i * Relevo.PASSO_FINO
				var vz := -Relevo.MEIO_FINO + j * Relevo.PASSO_FINO
				var h38 := Relevo.altura_38(vx, vz)
				if not is_equal_approx(fino[j * Relevo.N_FINO + i], h38):
					mexidos += 1
					if maxf(absf(vx), absf(vz)) >= Relevo.MEIO_FINO - Relevo.COSTURA_M:
						costura_mexida += 1
					if Vector2(vx, vz).distance_to(centro) > 23.5:
						mexidos_longe += 1
		out["relevo"] = {"vertices_mexidos": mexidos, "vertices_mexidos_relevo": _R.call("lago_vertices_mexidos"),
			"na_costura": costura_mexida, "a_mais_de_23_5m_do_centro": mexidos_longe}
		# ---- o perfil, de 0,5 em 0,5 m da margem
		var perfil := []
		var s := 0.0
		while s <= 7.01:
			perfil.append([s, snappedf(_R.call("perfil_fundura", s), 0.01)])
			s += 0.5
		out["perfil_por_distancia_a_margem"] = perfil
	# ---- o maior desnível dentro de uma casa de 1,5 m de andar (a grelha bloqueia «escarpa» a partir de 1,7 m)
	var degrau_max := 0.0
	for y in 50:
		for xx in 50:
			var cx := -37.5 + (xx + 0.5) * 1.5
			var cz := -37.5 + (y + 0.5) * 1.5
			var f := Relevo.lago_fundura(cx, cz)
			if f > 0.0 and f <= flutua:
				var lo := INF
				var hi := -INF
				for p in [Vector2(-0.75, -0.75), Vector2(0.75, -0.75), Vector2(-0.75, 0.75), Vector2(0.75, 0.75), Vector2.ZERO]:
					var h := Relevo.altura(cx + p.x, cz + p.y)
					lo = minf(lo, h)
					hi = maxf(hi, h)
				degrau_max = maxf(degrau_max, hi - lo)
	out["degrau_max_casas_de_andar_1_5m"] = snappedf(degrau_max, 0.01)
	var t := JSON.stringify(out, "  ", false)
	if _saida != "":
		var fa := FileAccess.open(_saida, FileAccess.WRITE)
		fa.store_string(t)
		fa.close()
	print(t)
	quit(0)
