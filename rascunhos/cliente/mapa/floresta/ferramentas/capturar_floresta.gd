extends SceneTree
## capturar_floresta.gd — Ordem 37. A PROVA POR RENDER do mapa da floresta: abre a cena, pousa a
## câmara em cada vista etiquetada, grava a captura (posição e ângulo escritos no NOME do
## ficheiro) e MEDE: chamadas de desenho (cena inteira e só o fundo), primitivas, FPS sem
## v-sync e o movimento da relva (diferença entre dois quadros da mesma vista).
##
##   godot --path cliente --resolution 1920x1080 -s res://mapa/floresta/ferramentas/capturar_floresta.gd
##   (opções depois de «--»:  --so=3,12   só essas vistas ·  --sem-medir  ·  --pasta=capturas/x)
##
## Precisa de janela (GPU): NÃO corre com --headless.

const CENA := "res://mapa/floresta/campo_floresta.tscn"
const LARGURA := 1920
const ALTURA := 1080

var _pasta := "res://mapa/floresta/capturas"
var _so: Array = []
var _medir := true


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--so="):
			for s in a.trim_prefix("--so=").split(","):
				_so.append(int(s))
		elif a == "--sem-medir":
			_medir = false
		elif a.begins_with("--pasta="):
			_pasta = "res://mapa/floresta/" + a.trim_prefix("--pasta=")
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _sinal(v: float) -> String:
	return ("+" if v >= 0.0 else "-") + str(absf(v)).replace(".", ",")


func _correr() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	# A prova faz-se num SubViewport de 1920×1080 (a resolução do projecto), seja qual for o
	# tamanho do ecrã desta máquina; a janela só o mostra.
	var vp := SubViewport.new()
	vp.size = Vector2i(LARGURA, ALTURA)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var mostra := TextureRect.new()
	mostra.texture = vp.get_texture()
	mostra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mostra.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mostra.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(mostra)
	var cena: Node3D = (load(CENA) as PackedScene).instantiate()
	cena.set("mostrar_medicao", false)
	vp.add_child(cena)
	await _quadros(12)
	var pasta_abs := ProjectSettings.globalize_path(_pasta)
	DirAccess.make_dir_recursive_absolute(pasta_abs)
	var vistas: Array = cena.get("VISTAS")
	var linhas: Array = []
	for i in vistas.size():
		if not _so.is_empty() and not _so.has(i):
			continue
		var v: Array = vistas[i]
		cena.call("so_fundo", false)
		cena.call("ir_para_vista", i)
		await _quadros(6)
		var img := vp.get_texture().get_image()
		var nome := "%02d_%s_x%s_z%s_olhos%sm_az%s_incl%s.png" % [i + 1, v[0], _sinal(v[1]), _sinal(v[2]),
			str(v[3]).replace(".", ","), _sinal(v[4]), _sinal(v[5])]
		img.save_png(pasta_abs.path_join(nome))
		var m := {"vista": v[0], "ficheiro": nome}
		if _medir:
			m["chamadas_total"] = _info(vp, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
			m["primitivas_total"] = _info(vp, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
			m["objectos_total"] = _info(vp, Viewport.RENDER_INFO_OBJECTS_IN_FRAME)
			m["chamadas_servidor"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			# FPS sem v-sync: 2 s de quadros contados pelo relógio
			var t0 := Time.get_ticks_usec()
			var n := 0
			while Time.get_ticks_usec() - t0 < 2000000:
				await process_frame
				n += 1
			m["fps_sem_vsync"] = snappedf(float(n) * 1000000.0 / float(Time.get_ticks_usec() - t0), 0.1)
			# a relva mexe? diferença média entre este quadro e o de 2 s antes (0–255, luma)
			var img2 := vp.get_texture().get_image()
			m["movimento_luma_media"] = snappedf(_diferenca(img, img2), 0.001)
			# só o fundo (céu + anéis + âncora)
			cena.call("so_fundo", true)
			await _quadros(4)
			m["chamadas_fundo"] = _info(vp, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
			m["primitivas_fundo"] = _info(vp, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
			if i == 0 or i == 12:
				vp.get_texture().get_image().save_png(pasta_abs.path_join(nome.replace(".png", "_SO-FUNDO.png")))
			cena.call("so_fundo", false)
		linhas.append(m)
		print("[captura] %s" % JSON.stringify(m))
	if _medir:
		var saida := {
			"resolucao_da_prova": [LARGURA, ALTURA],
			"ecra": [DisplayServer.screen_get_size().x, DisplayServer.screen_get_size().y],
			"placa": RenderingServer.get_video_adapter_name(),
			"metodo": str(ProjectSettings.get_setting("rendering/renderer/rendering_method")),
			"motor": Engine.get_version_info()["string"],
			"medidas_da_cena": cena.get("medidas"),
			"vistas": linhas,
		}
		var f := FileAccess.open(pasta_abs.path_join("medicao.json"), FileAccess.WRITE)
		f.store_string(JSON.stringify(saida, "\t"))
		f.close()
		print("[captura] medicao.json gravado")
	quit(0)


## Contador do viewport da prova (só os objectos 3D visíveis; o céu é uma passagem à parte).
func _info(vp: Viewport, que: Viewport.RenderInfo) -> int:
	return vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, que)


## Diferença média de luma (0–255) entre duas imagens, amostrada de 4 em 4 píxeis.
func _diferenca(a: Image, b: Image) -> float:
	var soma := 0.0
	var n := 0
	for y in range(0, a.get_height(), 4):
		for x in range(0, a.get_width(), 4):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			soma += absf(ca.get_luminance() - cb.get_luminance())
			n += 1
	return soma / float(maxi(n, 1)) * 255.0
