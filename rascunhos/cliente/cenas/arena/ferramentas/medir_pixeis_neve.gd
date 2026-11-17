extends SceneTree
## medir_pixeis_neve.gd — Ordem Neve (correcções, 17/11). O MEDIDOR independente da bancada da neve.
##
## Lê SÓ ficheiros: os PNG gravados pelo `neve_no_mapa.gd` e, do registo dele, apenas a hora de cada quadro e a
## lista de píxeis da lagoa (projecção da câmara sobre o relevo). Cada número sai de `Image.get_pixel` sobre os
## renders. Não carrega a cena, não chama o clima, não lê `neve_em()`, `fator_f()` nem os campos
## «declarado_pelo_sistema» do registo. Corre sem janela:
##   Godot --headless --path . -s res://cenas/arena/ferramentas/medir_pixeis_neve.gd -- --pasta=C:/caminho --modo=renders
##
## Definições (fixas antes de ver os números novos; ver ESTADO-NEVE.md):
##   · luminância  L = 0,2126 R + 0,7152 G + 0,0722 B (valores do PNG, 0..1);
##   · píxel BRANCO-NEVE = max(R,G,B) ≥ 0,55 e saturação (max−min)/max ≤ 0,20 (a relva e a terra, mesmo ao sol,
##     têm saturação > 0,30; o falso positivo de fundo mede-se no t0 e publica-se ao lado);
##   · regiões em fracções do ecrã: CENTRO x 0,38–0,62 · y 0,38–0,62 (a mesma ampliação do Crítico 1);
##     PERIFERIA x 0,05–0,95 · y 0,30–0,90 menos o centro (sem o céu, sem a barra de botões);
##   · MODULAÇÃO = desvio-padrão (e p90−p10) da luminância média de ladrilhos de 24×24 px inteiros na região —
##     um véu liso dá ≈ 0; o desvio-padrão da FRACÇÃO DE BRANCO por ladrilho mede a variação da cobertura;
##   · FLOCOS = diferença de luminância entre o par do mesmo instante (com/sem flocos): píxel de floco se
##     |ΔL| ≥ 0,06; legibilidade = fracção desses píxeis e o |ΔL| médio deles;
##   · FORMA DOS FLOCOS (rajada) = tensor de estrutura dos gradientes de ΔL: ângulo dominante do traço em relação
##     à vertical do ecrã e coerência (0 = pontos redondos, → 1 = riscos alinhados).

const CENTRO := Rect2(0.38, 0.38, 0.24, 0.24)
const PERIF := Rect2(0.05, 0.30, 0.90, 0.60)
const AR := Rect2(0.03, 0.08, 0.94, 0.82)
const LADRILHO := 24
const LIMIAR_FLOCO := 0.06

var _pasta := ""
var _modo := "renders"
var _janela := Vector2(1920, 1080)


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pasta="):
			_pasta = a.trim_prefix("--pasta=")
		elif a.begins_with("--modo="):
			_modo = a.trim_prefix("--modo=")
	var r: Dictionary
	match _modo:
		"renders":
			r = _medir_renders()
		"dinamica":
			r = _medir_dinamica()
		"rajada":
			r = _medir_rajada()
	r["definicoes"] = {"centro": [CENTRO.position.x, CENTRO.position.y, CENTRO.end.x, CENTRO.end.y],
		"periferia": [PERIF.position.x, PERIF.position.y, PERIF.end.x, PERIF.end.y], "ladrilho_px": LADRILHO,
		"branco_neve": "max>=0.55 e sat<=0.20", "floco": "|dL|>=%.2f no par com/sem flocos" % LIMIAR_FLOCO,
		"fonte": "Image.get_pixel sobre os PNG; nenhuma chamada ao clima"}
	var f := FileAccess.open(_pasta.path_join("medicao_pixeis_%s.json" % _modo), FileAccess.WRITE)
	f.store_string(JSON.stringify(r, "  "))
	f.close()
	print(JSON.stringify(r, "  "))
	quit(0)


static func _lum(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


static func _branco(c: Color) -> bool:
	var mx := maxf(c.r, maxf(c.g, c.b))
	var mn := minf(c.r, minf(c.g, c.b))
	return mx >= 0.55 and (mx - mn) / maxf(mx, 1e-4) <= 0.20


func _abrir(nome: String) -> Image:
	var img := Image.load_from_file(_pasta.path_join(nome))
	if img == null:
		push_error("falta %s" % nome)
	return img


static func _px(img: Image, r: Rect2) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	return Rect2i(int(r.position.x * w), int(r.position.y * h), int(r.size.x * w), int(r.size.y * h))


static func _std(v: Array) -> float:
	if v.size() < 2:
		return 0.0
	var m := 0.0
	for x in v:
		m += x
	m /= v.size()
	var s := 0.0
	for x in v:
		s += (x - m) * (x - m)
	return sqrt(s / (v.size() - 1))


static func _pct(v: Array, p: float) -> float:
	var o := v.duplicate()
	o.sort()
	return o[clampi(int(p * (o.size() - 1)), 0, o.size() - 1)]


## Cobertura (fracção de branco-neve) e modulação por ladrilhos numa região; `fora` (opcional) é excluída.
func _chao(img: Image, regiao: Rect2, fora: Rect2 = Rect2()) -> Dictionary:
	var r := _px(img, regiao)
	var rf := _px(img, fora) if fora.size != Vector2.ZERO else Rect2i()
	var lum_lad: Array = []
	var bra_lad: Array = []
	var brancos := 0
	var total := 0
	var soma_l := 0.0
	var ty := r.position.y
	while ty + LADRILHO <= r.end.y:
		var tx := r.position.x
		while tx + LADRILHO <= r.end.x:
			var lad := Rect2i(tx, ty, LADRILHO, LADRILHO)
			if rf.size == Vector2i.ZERO or not rf.intersects(lad):
				var sl := 0.0
				var sb := 0
				for y in range(ty, ty + LADRILHO):
					for x in range(tx, tx + LADRILHO):
						var c := img.get_pixel(x, y)
						sl += _lum(c)
						if _branco(c):
							sb += 1
				var n := LADRILHO * LADRILHO
				lum_lad.append(sl / n)
				bra_lad.append(float(sb) / n)
				brancos += sb
				total += n
				soma_l += sl
			tx += LADRILHO
		ty += LADRILHO
	return {
		"cobertura_branco": snappedf(float(brancos) / maxf(total, 1), 0.0001),
		"lum_media": snappedf(soma_l / maxf(total, 1), 0.0001),
		"modulacao_lum_std": snappedf(_std(lum_lad), 0.0001),
		"modulacao_lum_p90_p10": snappedf(_pct(lum_lad, 0.9) - _pct(lum_lad, 0.1), 0.0001),
		"variacao_cobertura_std": snappedf(_std(bra_lad), 0.0001),
		"ladrilhos": lum_lad.size(),
	}


## Flocos: o par do mesmo instante. Devolve a legibilidade e a forma (tensor de estrutura).
func _flocos(com: Image, sem: Image, regiao: Rect2, passo: int = 1) -> Dictionary:
	var r := _px(com, regiao)
	var n := 0
	var floco := 0
	var soma_d := 0.0
	var soma_sinal := 0.0
	var jxx := 0.0
	var jyy := 0.0
	var jxy := 0.0
	# ΔL numa grelha com passo `passo`; o gradiente usa os vizinhos da grelha.
	var w := r.size.x / passo
	var h := r.size.y / passo
	var d := PackedFloat32Array()
	d.resize(w * h)
	for j in h:
		for i in w:
			var x := r.position.x + i * passo
			var y := r.position.y + j * passo
			var v := _lum(com.get_pixel(x, y)) - _lum(sem.get_pixel(x, y))
			d[j * w + i] = v
			n += 1
			if absf(v) >= LIMIAR_FLOCO:
				floco += 1
				soma_d += absf(v)
				soma_sinal += v
	for j in range(1, h - 1):
		for i in range(1, w - 1):
			var gx := d[j * w + i + 1] - d[j * w + i - 1]
			var gy := d[(j + 1) * w + i] - d[(j - 1) * w + i]
			jxx += gx * gx
			jyy += gy * gy
			jxy += gx * gy
	var phi := 0.5 * atan2(2.0 * jxy, jxx - jyy)  # direcção dominante do GRADIENTE; o traço é perpendicular
	var coer := sqrt((jxx - jyy) * (jxx - jyy) + 4.0 * jxy * jxy) / maxf(jxx + jyy, 1e-9)
	return {
		"fraccao_pixeis_floco": snappedf(float(floco) / maxf(n, 1), 0.00001),
		"contraste_medio_floco": snappedf(soma_d / maxf(floco, 1), 0.0001),
		"sinal_medio_floco": snappedf(soma_sinal / maxf(floco, 1), 0.0001),
		"tracos_angulo_da_vertical_graus": snappedf(rad_to_deg(phi), 0.1),
		"tracos_coerencia": snappedf(coer, 0.0001),
	}


func _cor_media(img: Image, pts: Array) -> Dictionary:
	var s := Vector3.ZERO
	var b := 0
	for p in pts:
		var c := img.get_pixel(mini(int(float(p[0]) * img.get_width() / _janela.x), img.get_width() - 1), mini(int(float(p[1]) * img.get_height() / _janela.y), img.get_height() - 1))
		s += Vector3(c.r, c.g, c.b)
		if _branco(c):
			b += 1
	s /= maxf(pts.size(), 1)
	return {"rgb_media": [snappedf(s.x, 0.001), snappedf(s.y, 0.001), snappedf(s.z, 0.001)],
		"fraccao_branco": snappedf(float(b) / maxf(pts.size(), 1), 0.0001), "pixeis": pts.size()}


func _ler_registo(nome: String) -> Dictionary:
	var txt := FileAccess.get_file_as_string(_pasta.path_join(nome))
	var v = JSON.parse_string(txt)
	return v if v is Dictionary else {}


func _medir_renders() -> Dictionary:
	var reg := _ler_registo("registo_renders.json")
	var jn: Array = reg.get("janela", [1920, 1080])
	_janela = Vector2(jn[0], jn[1])
	var lagoa: Array = reg.get("lagoa_pixeis", [])
	var out := {"quadros": {}, "series": {}}
	var lagoa_ref := {}
	var ref_de := {"t0_limpo": "t0_limpo", "fraca": "t0_limpo", "t1_meia_nevasca": "t0_limpo", "t2_nevasca": "t0_limpo",
		"t0_tarde": "t0_tarde", "t2_tarde": "t0_tarde", "t0_noite": "t0_noite", "t2_noite": "t0_noite"}
	for nome in ["t0_limpo", "t0_tarde", "t0_noite", "fraca", "t1_meia_nevasca", "t2_nevasca", "t2_tarde", "t2_noite"]:
		var com := _abrir(nome + ".png")
		var sem := _abrir(nome + "_sem_flocos.png")
		var q := {
			"chao_centro": _chao(sem, CENTRO),
			"chao_periferia": _chao(sem, PERIF, CENTRO),
			"flocos_ar": _flocos(com, sem, AR),
			"flocos_centro": _flocos(com, sem, CENTRO),
			"lagoa": _cor_media(sem, lagoa),
		}
		var cm: Array = q["lagoa"]["rgb_media"]
		var v := Vector3(cm[0], cm[1], cm[2])
		if ref_de[nome] == nome:
			lagoa_ref[nome] = v
		# A lagoa compara-se ao quadro SEM NEVE da MESMA hora (t0, t0_tarde, t0_noite).
		q["lagoa"]["referencia"] = ref_de[nome]
		q["lagoa"]["distancia_rgb_ao_t0"] = snappedf(v.distance_to(lagoa_ref[ref_de[nome]]), 0.0001)
		out["quadros"][nome] = q
		print("[medir] %s feito" % nome)
	for serie in ["serie_nevasca", "serie_fraca"]:
		var lista: Array = []
		var centro: Array = []
		for k in 6:
			var com := _abrir("%s_%d.png" % [serie, k])
			var sem := _abrir("%s_%d_sem_flocos.png" % [serie, k])
			lista.append(_flocos(com, sem, AR, 2))
			centro.append(_flocos(com, sem, CENTRO))
		var cc: Array = centro.map(func(e): return e["contraste_medio_floco"])
		var cf: Array = centro.map(func(e): return e["fraccao_pixeis_floco"])
		var fr: Array = lista.map(func(e): return e["fraccao_pixeis_floco"])
		var ct: Array = lista.map(func(e): return e["contraste_medio_floco"])
		out["series"][serie] = {"instantes": lista, "fraccao_min": fr.min(), "fraccao_max": fr.max(),
			"fraccao_media": snappedf(fr.reduce(func(a, b): return a + b, 0.0) / fr.size(), 0.00001),
			"contraste_min": ct.min(), "contraste_media": snappedf(ct.reduce(func(a, b): return a + b, 0.0) / ct.size(), 0.0001),
			"centro_instantes": centro, "centro_contraste_media": snappedf(cc.reduce(func(a, b): return a + b, 0.0) / cc.size(), 0.0001),
			"centro_contraste_min": cc.min(), "centro_fraccao_media": snappedf(cf.reduce(func(a, b): return a + b, 0.0) / cf.size(), 0.00001)}
		print("[medir] %s feita" % serie)
	return out


func _medir_dinamica() -> Dictionary:
	var reg := _ler_registo("registo_dinamica.json")
	var curva: Array = []
	var trocas: Array = []
	for q in reg.get("quadros", []):
		if q.has("troca_para"):
			trocas.append(q)
			continue
		var img := _abrir(q["nome"])
		var c := _chao(img, CENTRO)
		var p := _chao(img, PERIF, CENTRO)
		curva.append({"t_s": q["t_s"], "nome": q["nome"], "cobertura_centro": c["cobertura_branco"],
			"cobertura_periferia": p["cobertura_branco"], "lum_centro": c["lum_media"], "modulacao_centro": c["modulacao_lum_std"]})
	# Tempos lidos da curva de píxeis (primeira passagem de cada limiar).
	var marcos := {}
	var base: float = curva[0]["cobertura_centro"] if not curva.is_empty() else 0.0
	var topo := base
	for e in curva:
		topo = maxf(topo, e["cobertura_centro"])
	for lim in [0.5, 0.9]:
		var alvo: float = base + float(lim) * (topo - base)
		for e in curva:
			if e["cobertura_centro"] >= alvo:
				marcos["sobe_%d%%_do_topo_t_s" % int(lim * 100)] = e["t_s"]
				break
	var passou_topo := false
	for lim in [0.5, 0.1]:
		var alvo: float = base + float(lim) * (topo - base)
		passou_topo = false
		for e in curva:
			if e["cobertura_centro"] >= topo - 1e-6:
				passou_topo = true
			elif passou_topo and e["cobertura_centro"] <= alvo:
				marcos["desce_a_%d%%_do_topo_t_s" % int(lim * 100)] = e["t_s"]
				break
	return {"curva": curva, "trocas": trocas, "cobertura_base": base, "cobertura_topo": topo, "marcos": marcos,
		"duracao_parede_s": reg.get("duracao_parede_s", 0.0)}


func _medir_rajada() -> Dictionary:
	var reg := _ler_registo("registo_rajada.json")
	var lista: Array = []
	for q in reg.get("quadros", []):
		var com := _abrir(q["nome"] + ".png")
		var sem := _abrir(q["nome"] + "_sem_flocos.png")
		var f := _flocos(com, sem, AR, 2)
		f["t_s"] = q.get("t_s", 0.0)
		f["nome"] = q["nome"]
		lista.append(f)
		print("[medir] %s" % q["nome"])
	var ang: Array = lista.map(func(e): return e["tracos_angulo_da_vertical_graus"])
	var coe: Array = lista.map(func(e): return e["tracos_coerencia"])
	return {"instantes": lista, "angulo_min": ang.min(), "angulo_max": ang.max(), "coerencia_min": coe.min(),
		"coerencia_max": coe.max()}
