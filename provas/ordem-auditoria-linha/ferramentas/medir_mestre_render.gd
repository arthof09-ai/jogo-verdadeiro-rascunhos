extends SceneTree
## ORDEM-AUDITORIA-LINHA, ponto 4: o ecrã do Mestre medido COM RENDER (FPS + chamadas de desenho).
## Só mede: não muda nada no jogo. Corre com janela e GPU (NUNCA --headless):
##
##   Godot_v4.7.2-stable_win64.exe --path rascunhos/cliente -s <caminho absoluto>/medir_mestre_render.gd
##
## Monta a cena REAL do Mestre (res://cenas/mestre/mestre.tscn) com a vista da fixture do servidor
## (servidor/dados-exemplo/mesa-mestre.json), igual ao medir_mestre.gd, e em cada janela (1600×900, que foi a da
## bancada, e 1920×1080) e em cada modo de vsync (ligado = o que o Mestre vê; desligado = folga do GPU) aquece
## 3 s e mede 10 s: FPS médio (quadros/tempo), FPS mínimo do Engine, chamadas de desenho e primitivas por quadro.
## Imprime uma linha «MEDIDA {json}» por combinação. Código de saída 0 se mediu tudo, 2 se não deu para medir.

const CENA := "res://cenas/mestre/mestre.tscn"
const JANELAS := [Vector2i(1600, 900), Vector2i(1920, 1080)]
const AQUECER_S := 3.0
const MEDIR_S := 10.0

var _fx: Dictionary = {}


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _correr() -> void:
	var rede: Node = root.get_node("Rede")
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (d is Dictionary):
		printerr("sem a fixture do servidor")
		quit(2)
		return
	_fx = d
	rede.persistir = false
	rede.papel = "mestre"
	print("GPU: %s | %s" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_api_version()])
	var m = (load(CENA) as PackedScene).instantiate()
	m.enviar_fn = func(_t, _c, _r): return ""
	m.pedir_vista_fn = func(): pass
	root.add_child(m)
	await process_frame
	m._aviso_entendido()
	m.aplicar_vista(_fx["mestre"]["vista"].duplicate(true))
	var falhou := false
	for j in JANELAS:
		DisplayServer.window_set_size(j)
		root.size = j
		m._ao_redimensionar()
		for vsync in [DisplayServer.VSYNC_ENABLED, DisplayServer.VSYNC_DISABLED]:
			DisplayServer.window_set_vsync_mode(vsync)
			var med: Dictionary = await _medir()
			med["janela"] = "%dx%d" % [root.size.x, root.size.y]
			med["vsync"] = vsync == DisplayServer.VSYNC_ENABLED
			if med["quadros"] < 10:
				falhou = true
			print("MEDIDA " + JSON.stringify(med))
	quit(2 if falhou else 0)


func _medir() -> Dictionary:
	var t0 := Time.get_ticks_usec()
	while (Time.get_ticks_usec() - t0) / 1e6 < AQUECER_S:
		await process_frame
	var quadros := 0
	var dc_soma := 0
	var dc_max := 0
	var prim_soma := 0
	var fps_min := 1e9
	t0 = Time.get_ticks_usec()
	while (Time.get_ticks_usec() - t0) / 1e6 < MEDIR_S:
		await process_frame
		quadros += 1
		var dc := int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		dc_soma += dc
		dc_max = maxi(dc_max, dc)
		prim_soma += int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		if quadros > 30:
			fps_min = minf(fps_min, Engine.get_frames_per_second())
	var dur := (Time.get_ticks_usec() - t0) / 1e6
	return {
		"quadros": quadros, "segundos": snappedf(dur, 0.01), "fps_medio": snappedf(quadros / dur, 0.1),
		"fps_min_engine": fps_min, "chamadas_media": int(round(float(dc_soma) / maxi(quadros, 1))),
		"chamadas_max": dc_max, "primitivas_media": int(round(float(prim_soma) / maxi(quadros, 1))),
	}
