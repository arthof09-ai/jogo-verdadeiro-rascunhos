extends SceneTree
## dump_relevo.gd — ORDEM LAGO-MAIOR (desenho da margem). Despeja o relevo da Ordem 38 (altura_38) à volta da cova
## (x 0…42, z −42…0, passo 0,75 m) e as árvores/rochas do mapa sem zona (o que a margem nova não pode engolir).
## Corrido no relevo de ANTES (c9c176f): o dump.json desta pasta saiu daqui.
##   copiar para cliente/_dump_lago.gd e: godot --headless --path cliente -s res://_dump_lago.gd -- --saida=dump.json
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const CampoFloresta := preload("res://mapa/floresta/campo_floresta.gd")
var _saida := ""
func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
	process_frame.connect(_correr, CONNECT_ONE_SHOT)
func _correr() -> void:
	var h38 := []
	var z := -42.0
	while z <= 0.01:
		var linha := []
		var x := 0.0
		while x <= 42.01:
			linha.append(snappedf(Relevo.altura_38(x, z), 0.001))
			x += 0.75
		h38.append(linha)
		z += 0.75
	var m = CampoFloresta.new()
	m.vistas_por_tecla = false
	m.mostrar_medicao = false
	m.zona_jogo = Rect2()
	root.add_child(m)
	for i in 2:
		await process_frame
	var troncos := []
	for t: Array in m._troncos:
		troncos.append([t[0].x, t[0].y, t[1]])
	var rochas := []
	for r: Array in m._rochas:
		rochas.append([r[0].x, r[0].z, r[1]])
	var obst := []
	for o in m.obstaculos:
		obst.append([o["nome"], o["c"].x, o["c"].z, o["m"].x])
	var out := {"nivel": Relevo.nivel_lago(), "x0": 0.0, "z0": -42.0, "passo": 0.75, "h38": h38, "troncos": troncos, "rochas": rochas, "obstaculos": obst}
	var f := FileAccess.open(_saida, FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	quit(0)
