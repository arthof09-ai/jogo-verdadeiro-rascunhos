extends SceneTree
## provar_assentamento.gd — Ordem 42. A PROVA do assentamento da grelha no relevo, na arena DO JOGO
## (cenas/arena/arena.tscn), sem janela. Mede, para a grelha do snapshot de demonstração:
##   1. cada centro de casa contra a altura do relevo (Relevo.altura = malha = colisão);
##   2. cada vértice dos remendos (destaques, fogo, cursor) e das linhas contra o relevo — nada abaixo
##      do chão, nada mais do que LEVANTA_M + 2 cm acima;
##   3. cada figura: o pé contra o relevo debaixo da pegada — a base inclinada da Ordem 44 (parte B), com o
##      antes (a regra da Ordem 42) e o depois em todas as casas e nas 6 da encosta do outeiro;
##   4. o toque: o raio de cada centro de casa, visto pela câmara da mesa, volta à MESMA casa;
##   5. o desvio mapa-grelha: as casas do jogo que o mapa bloqueia (tem de dar 0);
##   6. um céu só: quantos WorldEnvironment e DirectionalLight3D há na árvore (Ordem 57: o sol, e a lua do mapa à parte).
##
##   godot --headless --path cliente -s res://cenas/arena/ferramentas/provar_assentamento.gd [-- --json=caminho]
## Sai com 0 se tudo passa, 1 se algo falha.

const CENA := "res://cenas/arena/arena.tscn"
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const GrelhaMapa := preload("res://mapa/floresta/grelha_floresta.gd")
const Assentamento := preload("res://cenas/arena/assentamento.gd")

var _falhas := 0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		_falhas += 1
	print(("  ok    " if cond else "  FALHA ") + texto)


## Ordem 44: a régua do pé. [enterra, flutua] da base de altura `y` no centro (x, z) e inclinação `g` (dy/dx, dy/dz),
## no centro e em 4 anéis de 32 pontos até ao raio `r`.
static func _medir_base(x: float, z: float, y: float, g: Vector2, r: float) -> Array:
	var enterra := 0.0
	var flutua := 0.0
	var pts: Array[Vector2] = [Vector2.ZERO]
	for anel in [0.25, 0.5, 0.75, 1.0]:
		for k in 32:
			var a := TAU * k / 32.0
			pts.append(Vector2(cos(a), sin(a)) * r * anel)
	for q in pts:
		var d := Relevo.altura(x + q.x, z + q.y) - (y + g.dot(q))
		enterra = maxf(enterra, d)
		flutua = maxf(flutua, -d)
	return [enterra, flutua]


## Ordem 44: a regra ANTIGA do pé (Ordem 42), só para a medição do antes: base horizontal, à altura mais baixa
## do centro e de 8 pontos no raio da pegada.
static func _pe_ordem42(x: float, z: float, y_centro: float, r: float) -> float:
	var y := y_centro
	for k in 8:
		var a := TAU * k / 8.0
		y = minf(y, Relevo.altura(x + cos(a) * r, z + sin(a) * r))
	return y


func _correr() -> void:
	root.get_node("/root/Rede")._ativo = true
	var est = root.get_node("/root/Estado")
	var figuras: Array = []
	var k := 0
	for y in range(0, 20, 3):
		for x in range(0, 20, 3):
			figuras.append({"id": "f%d" % k, "nomePublico": "F%d" % k, "x": x, "y": y, "lado": "criatura", "visivel": "de_pe"})
			k += 1
	est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "prova-42", "seq": 1, "revision": 1,
		"fase": "combate", "mapa": {"largura": 20, "altura": 20, "casaM": 1.5}, "figuras": figuras,
		"vezId": "f0", "propria": {"figuraId": "f0"}, "fogo": {"casas": [{"x": 5, "y": 5}]}, "ambiente": {}})
	var todas: Array = []
	for y in 20:
		for x in 20:
			todas.append({"x": x, "y": y, "custoM": 1.5})
	est.receber_opcoes({"v": 2, "type": "ROOM_OPTIONS", "revision": 1, "vezId": "f0", "mover": todas,
		"ataques": [], "consumiveis": [], "acoes": [], "reacoes": []})
	var arena = (load(CENA) as PackedScene).instantiate()
	root.add_child(arena)
	for i in 4:
		await process_frame
	arena.definir_modo(1)
	arena._cursor = Vector2i(7, 7)
	arena._atualizar_cursor()
	print("== Ordem 42: a grelha assenta no relevo ==")
	print("grelha %d×%d casas de %.1f m; origem (canto NO) x=%.2f z=%.2f" % [arena.largura, arena.altura, arena.casa_m, arena.origem.x, arena.origem.y])

	# 1. centros
	var d1 := 0.0
	for y in arena.altura:
		for x in arena.largura:
			var p: Vector3 = arena.centro_casa(Vector2i(x, y))
			d1 = maxf(d1, absf(p.y - Relevo.altura(p.x, p.z)))
	_ok(d1 < 0.001, "centro de casa − relevo: maior %.5f m (400 casas)" % d1)

	# 2. remendos e linhas
	for nome in ["Destaques", "Fogo", "Cursor", "Linhas"]:
		var mi: MeshInstance3D = arena.get_node("Grelha/" + nome)
		if mi.mesh == null:
			_ok(false, "%s sem malha" % nome)
			continue
		var v: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var lo := INF
		var hi := -INF
		for q in v:
			var dh := q.y - Relevo.altura(q.x, q.z)
			lo = minf(lo, dh)
			hi = maxf(hi, dh)
		_ok(lo >= 0.0 and hi <= arena.LEVANTA_M + 0.02 + 0.0001, "%s: %d vértices, acima do relevo entre %.3f e %.3f m" % [nome, v.size(), lo, hi])
	# a casa do meio de cada remendo de destaque: nenhum ponto da casa abaixo do remendo (a meio dos triângulos)
	var pior := 0.0
	for y in arena.altura:
		for x in arena.largura:
			var c: Vector3 = arena.centro_casa(Vector2i(x, y))
			for a in 16:
				var ang := TAU * a / 16.0
				var r: float = arena.casa_m * 0.4
				var px: float = c.x + cos(ang) * r
				var pz: float = c.z + sin(ang) * r
				# o remendo é interpolado entre vértices a 0,34 m: quanto fica abaixo do relevo, no pior ponto?
				var passo: float = arena.casa_m * 0.9 / arena.DIVISOES_CASA
				var x0: float = c.x - arena.casa_m * 0.45
				var z0: float = c.z - arena.casa_m * 0.45
				var i := clampi(floori((px - x0) / passo), 0, arena.DIVISOES_CASA - 1)
				var j := clampi(floori((pz - z0) / passo), 0, arena.DIVISOES_CASA - 1)
				var fx: float = (px - x0) / passo - i
				var fz: float = (pz - z0) / passo - j
				var h00 := Relevo.altura(x0 + i * passo, z0 + j * passo)
				var h10 := Relevo.altura(x0 + (i + 1) * passo, z0 + j * passo)
				var h01 := Relevo.altura(x0 + i * passo, z0 + (j + 1) * passo)
				var h11 := Relevo.altura(x0 + (i + 1) * passo, z0 + (j + 1) * passo)
				var hr: float = lerpf(lerpf(h00, h10, fx), lerpf(h01, h11, fx), fz) + arena.LEVANTA_M + 0.01
				pior = maxf(pior, Relevo.altura(px, pz) - hr)
	_ok(pior < 0.45, "entre vértices, o relevo sobe acima do remendo no máximo %.3f m (o shader puxa 0,45 m)" % pior)

	# 3. figuras (Ordem 44, parte B: a base inclinada com a encosta). A régua é independente do ajuste: o centro e
	# 4 anéis de 32 pontos (129 pontos; o ajuste da base usa 33). Mede-se, em cada ponto da pegada, o relevo contra
	# o PLANO da base: enterra = o relevo acima do plano, flutua = o plano acima do relevo.
	var r_pe: float = Assentamento.raio_pegada(arena.casa_m)
	var fora_do_sitio := 0
	var fig_pior := [0.0, 0.0]
	for id in arena._nos:
		var no: Node3D = arena._nos[id]
		var c := Vector2i(int(est.figuras[id]["x"]), int(est.figuras[id]["y"]))
		var destino: Vector3 = arena.pe_figura(c)
		var pg: Dictionary = arena.pegada_figura(c)
		var m := _medir_base(destino.x, destino.z, destino.y, pg["gradiente"], r_pe)
		fig_pior[0] = maxf(fig_pior[0], m[0])
		fig_pior[1] = maxf(fig_pior[1], m[1])
		if not no.position.is_equal_approx(destino):
			fora_do_sitio += 1
		# a mancha da base no plano da pegada: a normal dela é a do plano
		var base: Node3D = no.get_node("Base")
		var n_base: Vector3 = (no.global_transform.basis * base.transform.basis * Vector3.UP).normalized()
		if n_base.angle_to(pg["normal"]) > 0.001:
			fora_do_sitio += 1
	_ok(fora_do_sitio == 0, "as %d figuras estão no pé da casa e a base está no plano da encosta" % arena._nos.size())
	_ok(fig_pior[0] <= 0.10 and fig_pior[1] <= 0.10, "pé das %d figuras: enterra no máximo %.3f m, flutua no máximo %.3f m (limite 0,10)" % [arena._nos.size(), fig_pior[0], fig_pior[1]])
	# e em TODAS as casas: ANTES (a regra da Ordem 42: base horizontal à altura mais baixa da pegada) e DEPOIS
	var casas_m: Array = []
	var antes_pior := [0.0, 0.0]
	var depois_pior_6 := [0.0, 0.0]
	var depois_pior_resto := [0.0, 0.0]
	var antes_pior_resto := [0.0, 0.0]
	var seis: Array = []
	for y in arena.altura:
		for x in arena.largura:
			var c := Vector2i(x, y)
			var p: Vector3 = arena.centro_casa(c)
			var y_antes := _pe_ordem42(p.x, p.z, p.y, r_pe)
			var ma := _medir_base(p.x, p.z, y_antes, Vector2.ZERO, r_pe)
			var pg: Dictionary = arena.pegada_figura(c)
			var md := _medir_base(p.x, p.z, float(pg["y"]), pg["gradiente"], r_pe)
			var g: Vector2 = pg["gradiente"]
			var linha := {"x": x, "y": y, "inclinacao_graus": snappedf(rad_to_deg(atan(g.length())), 0.1),
				"antes": {"peM": y_antes, "enterraM": ma[0], "flutuaM": ma[1]},
				"depois": {"peM": float(pg["y"]), "enterraM": md[0], "flutuaM": md[1]}}
			casas_m.append(linha)
			antes_pior = [maxf(antes_pior[0], ma[0]), maxf(antes_pior[1], ma[1])]
			if ma[0] > 0.35:
				seis.append(linha)
				depois_pior_6 = [maxf(depois_pior_6[0], md[0]), maxf(depois_pior_6[1], md[1])]
			else:
				depois_pior_resto = [maxf(depois_pior_resto[0], md[0]), maxf(depois_pior_resto[1], md[1])]
				antes_pior_resto = [maxf(antes_pior_resto[0], ma[0]), maxf(antes_pior_resto[1], ma[1])]
	print("        ANTES (Ordem 42, base horizontal ao ponto mais baixo): pior enterra %.3f m, pior flutua %.3f m (400 casas)" % antes_pior)
	print("        as casas onde a base entrava > 0,35 m: %d" % seis.size())
	for l in seis:
		print("          casa (%d, %d), encosta %.1f°: antes enterra %.3f / flutua %.3f m → depois enterra %.3f / flutua %.3f m" % [l["x"], l["y"],
			l["inclinacao_graus"], l["antes"]["enterraM"], l["antes"]["flutuaM"], l["depois"]["enterraM"], l["depois"]["flutuaM"]])
	_ok(seis.size() == 6, "são as 6 casas da encosta do outeiro medidas na Ordem 42 (%d)" % seis.size())
	_ok(depois_pior_6[0] <= 0.10 and depois_pior_6[1] <= 0.10, "DEPOIS, nas %d casas da encosta: enterra no máximo %.3f m, flutua no máximo %.3f m (limite 0,10)" % [seis.size(), depois_pior_6[0], depois_pior_6[1]])
	_ok(depois_pior_resto[0] <= maxf(0.10, antes_pior_resto[0]) and depois_pior_resto[1] <= maxf(0.10, antes_pior_resto[1]),
		"DEPOIS, nas outras %d casas: enterra no máximo %.3f m (antes %.3f), flutua no máximo %.3f m (antes %.3f)" % [400 - seis.size(),
		depois_pior_resto[0], antes_pior_resto[0], depois_pior_resto[1], antes_pior_resto[1]])
	var saida := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--json="):
			saida = a.trim_prefix("--json=")
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		f.store_string(JSON.stringify({"regua": "centro + 4 anéis de 32 pontos (129), raio %.2f m" % r_pe,
			"antes": "Ordem 42: base horizontal à altura mais baixa do centro e de 8 pontos no raio",
			"depois": "Ordem 44: base inclinada (plano dos mínimos quadrados, minimax), assentamento.gd",
			"seis": seis, "casas": casas_m}, " "))
		f.close()
		print("        medição escrita em %s" % saida)

	# 4. o toque, pela câmara da mesa (Fixa, Panorama, 360° rasante)
	var cam: Camera3D = arena.camera
	for modo in [[0, 0.0, 55.0, 1.5], [2, 0.0, 78.0, 1.5], [1, 135.0, 20.0, 0.6]]:
		cam.definir_modo(modo[0])
		if modo[0] == 1:
			cam.rumo = modo[1]
			cam.inclinacao = modo[2]
		cam.definir_zoom(modo[3])
		cam._saltar()
		await process_frame
		var certas := 0
		var vistas := 0
		for y in arena.altura:
			for x in arena.largura:
				var p: Vector3 = arena.centro_casa(Vector2i(x, y))
				if cam.is_position_behind(p) or not cam.is_position_in_frustum(p):
					continue
				vistas += 1
				if arena.casa_em_tela(cam.unproject_position(p)) == Vector2i(x, y):
					certas += 1
		_ok(certas == vistas and vistas > 0, "toque no modo %d: %d de %d casas à vista voltam à mesma casa" % [modo[0], certas, vistas])

	# 5. desvio mapa-grelha
	var g = arena.mapa.grelha
	var bloq := 0
	var c0 := Vector2i(roundi((arena.origem.x + GrelhaMapa.MEIO) / GrelhaMapa.CASA_M), roundi((arena.origem.y + GrelhaMapa.MEIO) / GrelhaMapa.CASA_M))
	for y in arena.altura:
		for x in arena.largura:
			if g.bloqueada(c0 + Vector2i(x, y)):
				bloq += 1
	_ok(bloq == 0, "casas do jogo que o mapa bloqueia: %d (casa do jogo (0,0) = casa do mapa %s)" % [bloq, c0])
	print("        o mapa tirou da zona: %s" % JSON.stringify({"rochas": arena.mapa.medidas.get("zona_tirados_rochas", 0),
		"arvores": arena.mapa.medidas.get("zona_tirados_arvores", 0), "estrato": arena.mapa.medidas.get("zona_tirados_estrato", 0),
		"tronco_tombado_m": arena.mapa.medidas.get("zona_tronco_tombado_m", 0)}))

	# 6. um céu só
	var ambientes := root.find_children("*", "WorldEnvironment", true, false).size()
	# (Ordem 57) desde a Ordem 43 o mapa tem também a LUA (DirectionalLight3D do grupo «lua»): conta à parte, e é a do mapa
	var luzes := root.find_children("*", "DirectionalLight3D", true, false)
	var luas := luzes.filter(func(l): return (l as Node).is_in_group("lua"))
	var sois := luzes.size() - luas.size()
	var env: Environment = arena.get_node("Ambiente").environment
	_ok(ambientes == 1 and sois == 1 and luas.size() == 1 and luas[0] == arena.mapa.lua,
		"um céu só: %d WorldEnvironment, %d sol e %d lua (a do mapa)" % [ambientes, sois, luas.size()])
	_ok(env.background_mode == Environment.BG_SKY and env.sky != null and env.fog_enabled, "o Ambiente da arena é o do mapa (céu pintado e névoa)")
	_ok(arena.mapa.medidas.get("erros", -1) == 0, "o mapa construiu-se com 0 erros")

	# 7. perfis: a densidade da folhagem chega à relva do mapa
	for nome in ["baixo", "medio", "alto"]:
		arena._aplicar_perfil(nome)
		var d: float = arena.mapa.densidade_relva
		_ok(is_equal_approx(d, float(AplicadorPerfil.PERFIS[nome]["folhagem_densidade"])), "perfil %s: relva do mapa a %.2f" % [nome, d])

	print("%s" % ("TUDO PASSOU" if _falhas == 0 else "%d FALHAS" % _falhas))
	quit(1 if _falhas > 0 else 0)
