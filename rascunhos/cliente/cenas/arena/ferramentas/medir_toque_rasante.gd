extends SceneTree
## medir_toque_rasante.gd — Ordem 51. A MEDIÇÃO do toque rasante (câmara 360°, rumo 135°, inclinação 20°, zoom
## 0,6 — o modo rasante da prova da Ordem 45) na grelha 20 × 20 e na 30 × 30, nas DUAS arenas (a do jogador e a do
## Mestre), que tocam pelo mesmo raio partilhado `CampoDaMesa.ponto_no_chao`.
## As casas cujo centro o relevo tapa (pelo raio partilhado, como na Ordem 45) não contam.
## Para cada casa à vista: o centro da casa vai ao ecrã e o toque nesse ponto tem de voltar à mesma casa. Cada falha
## é nomeada: a casa, o modo, o que o raio devolveu (o ponto, ou null), o relevo nesse ponto, e o primeiro chão
## de referência (o mesmo raio, marchado a 0,01 m desde a câmara).
##
##   godot --headless --path cliente -s res://cenas/arena/ferramentas/medir_toque_rasante.gd [-- --json=caminho]
## Sai com 0 se as duas arenas dão o mesmo e não há falhas; 1 se há.

const CENA_MESTRE := "res://cenas/mestre/mestre.tscn"
const CENA_ARENA := "res://cenas/arena/arena.tscn"
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const CampoDaMesa := preload("res://cenas/arena/campo_da_mesa.gd")
## Os três modos da prova da Ordem 45 ([modo, rumo, inclinação, zoom]); o rasante é o terceiro.
const MODOS := [[0, 0.0, 55.0, 1.5], [2, 0.0, 78.0, 1.5], [1, 135.0, 20.0, 0.6]]
const NOMES := {0: "Fixa", 2: "Panorama", 1: "360° rasante"}

var _falhas := 0
var _json := {}


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


## O primeiro chão de referência: o raio marchado a 0,01 m desde a origem (até 600 m), sem atalhos.
static func _chao_de_referencia(o: Vector3, d: Vector3):
	var t := 0.0
	while t < 600.0:
		var q := o + d * t
		if q.y <= Relevo.altura(q.x, q.z):
			return q
		t += 0.01
	return null


func _correr() -> void:
	root.size = Vector2i(1920, 1080)
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var fx = JSON.parse_string(FileAccess.get_file_as_string(p))
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede._ativo = true
	rede.papel = "mestre"
	var m = (load(CENA_MESTRE) as PackedScene).instantiate()
	m.enviar_fn = func(_t, _c, _r): return ""
	m.pedir_vista_fn = func(): pass
	root.add_child(m)
	await _quadros(2)
	var a = m._arena
	for g in [[20, 20, 1.5], [30, 30, 1.5]]:
		await _medir(m, a, fx["mestre"]["vista"], g[0], g[1], g[2])
	m.queue_free()
	await _quadros(2)
	var saida := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--json="):
			saida = arg.trim_prefix("--json=")
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		f.store_string(JSON.stringify(_json, " "))
		f.close()
		print("medição escrita em %s" % saida)
	print("%s" % ("SEM FALHAS" if _falhas == 0 else "%d FALHAS" % _falhas))
	quit(1 if _falhas > 0 else 0)


func _medir(m, a, base: Dictionary, w: int, h: int, casa: float) -> void:
	var nome := "%dx%d" % [w, h]
	var v: Dictionary = base.duplicate(true)
	v["mapa"] = {"largura": w, "altura": h, "casaM": casa}
	v["mestre"]["figuras"] = []
	m.aplicar_vista(v)
	await _quadros(3)
	var est = root.get_node("Estado")
	est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "medir-51", "seq": 1, "revision": 1,
		"fase": "combate", "mapa": {"largura": w, "altura": h, "casaM": casa}, "figuras": [], "ambiente": {}})
	var jog = (load(CENA_ARENA) as PackedScene).instantiate()
	root.add_child(jog)
	await _quadros(3)
	var reg := {}
	for modo in MODOS:
		var rm: Dictionary = await _toque(a, a.camera, modo, w, h)
		var rj: Dictionary = await _toque(jog, jog.camera, modo, w, h)
		# as duas câmaras têm ecrãs diferentes (o Mestre vê pelo SubViewport): compara-se o que falha, não o que se vê
		var igual: bool = rm["falhas"].map(func(f): return f["casa"]) == rj["falhas"].map(func(f): return f["casa"])
		_falhas += rm["falhas"].size() + rj["falhas"].size() + (0 if igual else 1)
		print("== %s · %s: jogador %d/%d (%d tapadas) · Mestre %d/%d (%d tapadas)%s" % [nome, NOMES[modo[0]],
			rj["certas"], rj["vistas"], rj["tapadas"], rm["certas"], rm["vistas"], rm["tapadas"], "" if igual else " · AS ARENAS DIFEREM"])
		for f in rj["falhas"]:
			print("   FALHA jogador %s" % _texto(f))
		for f in rm["falhas"]:
			print("   FALHA Mestre  %s" % _texto(f))
		reg[NOMES[modo[0]]] = {"modo": modo, "jogador": rj, "mestre": rm}
	_json[nome] = reg
	jog.queue_free()
	await _quadros(2)


static func _texto(f: Dictionary) -> String:
	return "casa %s → %s · folga mínima do raio junto ao centro %s m (raio a %s m do centro) · o raio devolveu %s (relevo ali %s) · chão de referência %s → casa %s" % [
		f["casa"], f["deu"], f["folga_minima_junto_ao_centro_m"], f["distancia_raio_centro_m"], f["raio_devolveu"], f["relevo_no_ponto"], f["chao_referencia"], f["casa_referencia"]]


func _toque(arena, cam, modo: Array, w: int, h: int) -> Dictionary:
	cam.definir_modo(modo[0])
	if modo[0] == 1:
		cam.rumo = modo[1]
		cam.inclinacao = modo[2]
	cam.definir_zoom(modo[3])
	cam._saltar()
	await _quadros(1)
	var certas := 0
	var vistas := 0
	var tapadas := 0
	var falhas: Array = []
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			var q: Vector3 = arena.centro_casa(c) if arena.has_method("centro_casa") else arena.centro_da_casa(c)
			if cam.is_position_behind(q) or not cam.is_position_in_frustum(q):
				continue
			var o: Vector3 = cam.global_position
			var hit = CampoDaMesa.ponto_no_chao(o, (q - o).normalized())
			if hit != null and (hit - o).length() < (q - o).length() - 0.05:
				tapadas += 1
				continue
			vistas += 1
			var ecra: Vector2 = cam.unproject_position(q)
			var t: Vector2i = arena.casa_em_tela(ecra)
			if t == c:
				certas += 1
				continue
			var ro: Vector3 = cam.project_ray_origin(ecra)
			var rd: Vector3 = cam.project_ray_normal(ecra)
			var r = CampoDaMesa.ponto_no_chao(ro, rd)
			var ref = _chao_de_referencia(ro, rd)
			var cref := Vector2i(-1, -1)
			if ref != null:
				cref = Vector2i(floori((ref.x - arena.origem.x) / arena.casa_m), floori((ref.z - arena.origem.y) / arena.casa_m))
			# a folga do raio do ecrã sobre o relevo, a ±0,6 m do ponto mais próximo do centro da casa (passos de 1 mm)
			var tq := (q - ro).dot(rd)
			var folga := INF
			var tt := tq - 0.6
			while tt <= tq + 0.6:
				var pp: Vector3 = ro + rd * tt
				folga = minf(folga, pp.y - Relevo.altura(pp.x, pp.z))
				tt += 0.001
			falhas.append({"folga_minima_junto_ao_centro_m": "%.5f" % folga, "distancia_raio_centro_m": "%.5f" % (ro + rd * tq).distance_to(q),"casa": "(%d,%d)" % [x, y], "deu": "(%d,%d)" % [t.x, t.y], "modo": modo,
				"camera": "%.3v" % ro, "direcao": "%.4v" % rd,
				"raio_devolveu": "null" if r == null else "%.3v" % r,
				"relevo_no_ponto": "-" if r == null else "%.3f" % Relevo.altura(r.x, r.z),
				"chao_referencia": "null" if ref == null else "%.3v" % ref, "casa_referencia": "(%d,%d)" % [cref.x, cref.y]})
	return {"certas": certas, "vistas": vistas, "tapadas": tapadas, "falhas": falhas}
