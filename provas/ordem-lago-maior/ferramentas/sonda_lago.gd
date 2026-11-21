extends SceneTree
## sonda_lago.gd — ORDEM LAGO-MAIOR. Mede o LAGO (relevo) e a DECORAÇÃO do mapa (árvores, rochas, estrato) com
## a zona de jogo = o mapa inteiro e sem zona. Escreve um JSON. Não é suite: corre de uma cópia temporária em
## cliente/ (como a ferramenta das CAPTURAS-MAPA) e apaga-se depois.
##   godot --headless --path cliente -s res://_sonda_lago.gd -- --saida=<ficheiro.json> [--sem-mapa]

const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const Grelha := preload("res://mapa/floresta/grelha_floresta.gd")
const CampoFloresta := preload("res://mapa/floresta/campo_floresta.gd")
const LagoFloresta := preload("res://mapa/floresta/lago_floresta.gd")

var _saida := ""


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


static func lago() -> Dictionary:
	var c := Relevo.COVA
	var nado := LagoFloresta.FLUTUA_M
	# área fina (0,25 m)
	var p := 0.25
	var area := 0.0
	var andar := 0.0
	var nadar := 0.0
	var maxima := 0.0
	var r_max := 0.0
	var x := c.x - 16.0
	while x <= c.x + 16.0:
		var z := c.y - 16.0
		while z <= c.y + 16.0:
			var f := Relevo.lago_fundura(x, z)
			if f > 0.0:
				area += p * p
				if f > nado:
					nadar += p * p
				else:
					andar += p * p
				maxima = maxf(maxima, f)
				r_max = maxf(r_max, Vector2(x - c.x, z - c.y).length())
			z += p
		x += p
	# o raio da margem por rumo (de 15 em 15 graus): a primeira distância, a partir do centro, onde se sai da água
	var margem := []
	for k in 24:
		var ang := TAU * k / 24.0
		var d := 0.0
		while d < 16.0 and Relevo.lago_fundura(c.x + sin(ang) * d, c.y - cos(ang) * d) > 0.0:
			d += 0.05
		margem.append(snappedf(d, 0.05))
	# as casas do mapa (1,5 m): pelo centro
	var casas_andar := 0
	var casas_nadar := 0
	var casas_charco := 0
	var funduras_nadar := []
	for l in Grelha.LADO:
		for ci in Grelha.LADO:
			var cc := Grelha.canto(Vector2i(ci, l)) + Vector2(0.75, 0.75)
			var f := Relevo.lago_fundura(cc.x, cc.y)
			if f > nado:
				casas_nadar += 1
				funduras_nadar.append(snappedf(f, 0.01))
			elif f > 0.0:
				casas_andar += 1
			if Relevo.agua(cc.x, cc.y) > 0.40:
				casas_charco += 1
	funduras_nadar.sort()
	return {"area_m2": snappedf(area, 0.1), "andar_m2": snappedf(andar, 0.1), "nadar_m2": snappedf(nadar, 0.1),
		"fundura_max_m": snappedf(maxima, 0.01), "raio_max_m": snappedf(r_max, 0.05), "nivel_m": snappedf(Relevo.nivel_lago(), 0.001),
		"fundura_centro_m": snappedf(Relevo.lago_fundura(c.x, c.y), 0.01), "margem_por_rumo_m": margem,
		"limiar_nado_m": nado, "casas_1_5_andar": casas_andar, "casas_1_5_nadar": casas_nadar,
		"casas_1_5_charco_38": casas_charco, "funduras_casas_nadar": funduras_nadar}


func _mapa(zona: Rect2) -> Dictionary:
	var m = CampoFloresta.new()
	m.vistas_por_tecla = false
	m.mostrar_medicao = false
	m.zona_jogo = zona
	root.add_child(m)
	for i in 2:
		await process_frame
	var dentro_arv := 0
	for t: Array in m._troncos:
		var p: Vector2 = t[0]
		if Grelha.casa_em(p.x, p.y) != Grelha.FORA:
			dentro_arv += 1
	var dentro_roc := 0
	var rochas_na_agua := []
	for r: Array in m._rochas:
		var c: Vector3 = r[0]
		if Grelha.casa_em(c.x, c.z) != Grelha.FORA:
			dentro_roc += 1
		if Relevo.lago_fundura(c.x, c.z) > 0.0:
			rochas_na_agua.append([snappedf(c.x, 0.1), snappedf(c.z, 0.1), r[1]])
	var arv_na_agua := []
	for t: Array in m._troncos:
		var p: Vector2 = t[0]
		if Relevo.lago_fundura(p.x, p.y) > 0.0:
			arv_na_agua.append([snappedf(p.x, 0.1), snappedf(p.y, 0.1)])
	var estrato := 0
	for no in m.arena.get_children():
		if no is MultiMeshInstance3D:
			for i in (no as MultiMeshInstance3D).multimesh.instance_count:
				var o: Vector3 = (no as MultiMeshInstance3D).multimesh.get_instance_transform(i).origin
				if Grelha.casa_em(o.x, o.z) != Grelha.FORA:
					estrato += 1
	var motivos := {}
	var agua := 0
	for l in Grelha.LADO:
		for ci in Grelha.LADO:
			var mo: String = m.grelha.motivo_bloqueio(Vector2i(ci, l))
			if mo != "":
				motivos[mo] = int(motivos.get(mo, 0)) + 1
	var r := {"zona": [zona.position.x, zona.position.y, zona.size.x, zona.size.y],
		"arvores_no_mapa": dentro_arv, "rochas_no_mapa": dentro_roc, "estrato_no_mapa": estrato,
		"arvores_na_agua": arv_na_agua, "rochas_na_agua": rochas_na_agua,
		"casas_bloqueadas": m.grelha.casas_bloqueadas(), "motivos": motivos, "medidas": m.medidas}
	m.queue_free()
	await process_frame
	return r


func _correr() -> void:
	var out := {"lago": lago()}
	if not OS.get_cmdline_user_args().has("--sem-mapa"):
		var mapa := Rect2(-37.5, -37.5, 75.0, 75.0)
		out["mapa_zona_mapa"] = await _mapa(mapa)
		out["mapa_zona_20x20"] = await _mapa(Rect2(-15, -15, 30, 30))
		out["mapa_sem_zona"] = await _mapa(Rect2())
	var t := JSON.stringify(out, "  ", false)
	if _saida != "":
		var f := FileAccess.open(_saida, FileAccess.WRITE)
		f.store_string(t)
		f.close()
	print(JSON.stringify(out["lago"]))
	quit(0)
