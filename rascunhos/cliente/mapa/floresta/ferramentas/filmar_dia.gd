extends SceneTree
## filmar_dia.gd — Ordem 43. A PROVA POR RENDER do ciclo do dia e do vento do mundo.
##
##   godot --path cliente --resolution 1920x1080 -s res://mapa/floresta/ferramentas/filmar_dia.gd -- <modo>
##
## MODOS (depois de «--»):
##   --horas            as 10 capturas etiquetadas (05:30 07:00 10:00 13:00 16:00 18:30 19:45 22:00
##                      01:00 04:00), o MESMO enquadramento em todas, em capturas/ciclo43/; e a
##                      MEDIÇÃO por hora (FPS sem v-sync, chamadas, primitivas, pinturas do forno
##                      das sombras, cor do quadro) em capturas/ciclo43/medicao_ciclo.json.
##   --dia              o TIMELAPSE de um dia completo: 05:00 → 07:00 do dia seguinte (26 h) em
##                      65 s a 30 q/s (1 s de filme = 24 min do mundo). Câmara fixa na clareira.
##   --vento            o filme do VENTO: 24 h (05:00 → 05:00) em 120 s; câmara baixa sobre a relva;
##                      a hora, o rumo, a força, a rajada e o gráfico da força escritos no ecrã.
##   --quadros=PASTA    onde gravar os quadros JPEG dos filmes (q00000.jpg …; o MP4 faz-se depois
##                      com o ffmpeg — ver NOTAS-CICLO-43.md). Sem isto, grava em capturas/_ensaio.
##   --amostras         nos filmes: só 1 quadro em cada 150 (para conferir o enquadramento).
##
## Os quadros saem de um SubViewport de 1920×1080 (como nas Ordens 37/38: a janela desta máquina
## é pequena). O relógio e o vento ficam PARADOS e são avançados aqui, quadro a quadro, ao ritmo do
## filme — o filme é o mesmo seja qual for a velocidade da máquina. O vento avança em tempo REAL do
## filme (1/30 s por quadro): as rajadas têm o ritmo verdadeiro; só as horas correm depressa.
##
## Por cima: o ENCAIXE «o céu por cima da clareira» — uma 2.ª câmara no centro da clareira a
## olhar para o zénite (norte em cima), que mostra o arco do sol e da lua ao longo do dia.
## Precisa de janela (GPU): NÃO corre com --headless.

const CENA := "res://mapa/floresta/campo_floresta.tscn"
const Ciclo := preload("res://mapa/floresta/ciclo_dia.gd")
const Vento := preload("res://mapa/floresta/vento_mundo.gd")
const LARGURA := 1920
const ALTURA := 1080
const QPS := 30.0
const HORAS := [5.5, 7.0, 10.0, 13.0, 16.0, 18.5, 19.75, 22.0, 1.0, 4.0]
## O enquadramento das capturas e do timelapse: da orla sul da clareira, a olhar para norte —
## a clareira, a orla e a Árvore Ancestral (a vista 13 da Ordem 38, «longe_vista-ref07», um
## pouco mais aberta).
const VISTA_DIA := [5.0, 27.0, 2.3, -11.0, 2.0, 62.0]       # x, z, olhos, az, incl, fov
## O enquadramento do vento: baixo, sobre a relva da clareira.
const VISTA_VENTO := [-14.0, 14.0, 1.25, 40.0, -4.0, 60.0]
const ENCAIXE := 420
const ENCAIXE_FOV := 150.0

var _vp: SubViewport
var _vp_ceu: SubViewport
var _cam_ceu: Camera3D
var _painel: Control
var _cena: Node3D
var _ciclo: Node
var _vento: Node
var _modo := ""
var _titulo := ""
var _historia: Array = []      # [forca, forca_base] dos últimos 20 s (para o gráfico do vento)
var _fonte: Font


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _arg(nome: String, omissao: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(nome + "="):
			return a.trim_prefix(nome + "=")
	return omissao


func _correr() -> void:
	var args := OS.get_cmdline_user_args()
	for m in ["--horas", "--dia", "--vento"]:
		if args.has(m):
			_modo = m.trim_prefix("--")
	if _modo == "":
		push_error("[ciclo] diz o modo: --horas, --dia ou --vento")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_fonte = ThemeDB.fallback_font
	_vp = SubViewport.new()
	_vp.size = Vector2i(LARGURA, ALTURA)
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	var mostra := TextureRect.new()
	mostra.texture = _vp.get_texture()
	mostra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mostra.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mostra.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(mostra)
	_cena = (load(CENA) as PackedScene).instantiate()
	_cena.set("mostrar_medicao", false)
	_vp.add_child(_cena)
	await _quadros(2)
	_ciclo = _cena.get("ciclo")
	_vento = _cena.get("vento")
	_ciclo.set("parado", true)
	_vento.set("parado", true)
	# ---- a câmara principal
	var cam := _cena.get_node("Camera") as Camera3D
	var vista: Array = VISTA_VENTO if _modo == "vento" else VISTA_DIA
	var x: float = vista[0]
	var z: float = vista[1]
	cam.position = Vector3(x, float(_cena.call("altura_em", x, z)) + float(vista[2]), z)
	cam.rotation = Vector3(deg_to_rad(float(vista[4])), -deg_to_rad(float(vista[3])), 0.0)
	cam.fov = vista[5]
	cam.set_process(false)
	cam.set_process_unhandled_input(false)
	# ---- o encaixe do céu (a mesma cena, a olhar para o zénite)
	_vp_ceu = SubViewport.new()
	_vp_ceu.size = Vector2i(ENCAIXE, ENCAIXE)
	_vp_ceu.world_3d = _vp.find_world_3d()
	_vp_ceu.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.add_child(_vp_ceu)
	_cam_ceu = Camera3D.new()
	_cam_ceu.fov = ENCAIXE_FOV
	_cam_ceu.near = 0.5
	_cam_ceu.far = 9000.0
	_vp_ceu.add_child(_cam_ceu)
	var p0 := Vector3(0.0, float(_cena.call("altura_em", 0.0, 0.0)) + 1.7, 0.0)
	_cam_ceu.look_at_from_position(p0, p0 + Vector3.UP, Vector3(0.0, 0.0, -1.0))
	_cam_ceu.make_current()
	cam.make_current()
	# ---- o painel (texto, encaixe, gráficos): desenhado DENTRO do SubViewport, entra no quadro
	_painel = Control.new()
	_painel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_painel.size = Vector2(LARGURA, ALTURA)
	_painel.draw.connect(_desenhar)
	_vp.add_child(_painel)
	await _quadros(8)
	match _modo:
		"horas":
			await _fazer_horas()
		"dia":
			_titulo = "ORDEM 43 · UM DIA COMPLETO (timelapse: 1 s de filme = 24 min do mundo) · câmara fixa na clareira, a olhar para norte"
			await _filmar(5.0, 26.0, 65.0)
		"vento":
			_titulo = "ORDEM 43 · O VENTO DO MUNDO ao longo do dia (as horas correm 720×; as rajadas em tempo real)"
			await _filmar(5.0, 24.0, 120.0)
	quit(0)


# ------------------------------------------------------------------ os filmes

func _filmar(h0: float, horas: float, segundos: float) -> void:
	var pasta := _arg("--quadros", ProjectSettings.globalize_path("res://mapa/floresta/capturas/_ensaio/" + _modo))
	DirAccess.make_dir_recursive_absolute(pasta)
	var amostras := OS.get_cmdline_user_args().has("--amostras")
	var n := int(round(segundos * QPS))
	var dh := horas / float(n)
	_ciclo.call("definir_hora", h0)
	# o vento aquece 10 s antes de o filme começar (a inércia e o campo de rajadas assentam)
	for i in int(10.0 * QPS):
		_vento.call("avancar", 1.0 / QPS)
	_cena.call("aplicar_ciclo")
	await _quadros(6)
	var t0 := Time.get_ticks_msec()
	var registo: Array = []
	for i in n:
		var h: float = h0 + dh * float(i)
		_ciclo.call("definir_hora", h)
		_vento.call("avancar", 1.0 / QPS)
		_cena.call("aplicar_ciclo")
		_guardar_historia()
		_painel.queue_redraw()
		await RenderingServer.frame_post_draw
		if i % 30 == 0:
			var v: Dictionary = _vento.call("vento_actual")
			registo.append([snappedf(fposmod(h, 24.0), 0.001), snappedf(float(v["forca"]), 0.001), snappedf(float(v["azimute_de"]), 0.1), snappedf(float(v["rajada"]), 0.001)])
		if amostras and i % 150 != 0:
			continue
		_vp.get_texture().get_image().save_jpg(pasta.path_join("q%05d.jpg" % (i if not amostras else i / 150)), 0.92)
		if i % 300 == 0:
			print("[ciclo] %s quadro %d/%d  %s  (%.0f s)" % [_modo, i, n, Ciclo.texto_de(h), float(Time.get_ticks_msec() - t0) / 1000.0])
	var f := FileAccess.open(pasta.path_join("registo_%s.json" % _modo), FileAccess.WRITE)
	f.store_string(JSON.stringify({"modo": _modo, "quadros": n, "qps": QPS, "hora_inicial": h0, "horas": horas,
		"colunas": ["hora", "forca", "azimute_de", "rajada"], "amostras_1_por_segundo": registo}))
	f.close()
	print("[ciclo] FILME %s OK · %d quadros · %.1f s · em %s" % [_modo, n, float(n) / QPS, pasta])


func _guardar_historia() -> void:
	_historia.append([float(_vento.get("forca")), float(_vento.get("forca_base"))])
	while _historia.size() > int(20.0 * QPS):
		_historia.pop_front()


# ------------------------------------------------------------------ as capturas e a medição

func _fazer_horas() -> void:
	var pasta := ProjectSettings.globalize_path(_arg("--pasta", "res://mapa/floresta/capturas/ciclo43"))
	DirAccess.make_dir_recursive_absolute(pasta)
	_titulo = "ORDEM 43 · o ciclo do dia · o mesmo enquadramento a todas as horas"
	var linhas: Array = []
	var sombras: Node = _cena.get("sombras")
	for h: float in HORAS:
		_ciclo.call("definir_hora", h)
		# o vento corre 6 s antes de cada captura (a relva já vai dobrada pelo vento desta hora)
		for i in int(6.0 * QPS):
			_vento.call("avancar", 1.0 / QPS)
		_cena.call("aplicar_ciclo")
		_guardar_historia()
		_painel.queue_redraw()
		await _quadros(8)
		var e: Dictionary = _ciclo.call("estado")
		var nome := "c43_%s_%s.jpg" % [Ciclo.texto_de(h).replace(":", "h"), String(Ciclo.fase_de(h)).replace("ã", "a")]
		var img := _vp.get_texture().get_image()
		img.save_jpg(pasta.path_join(nome), 0.95)
		var v: Dictionary = _vento.call("vento_actual")
		var m := {"hora": Ciclo.texto_de(h), "fase": Ciclo.fase_de(h), "ficheiro": nome,
			"sol": [snappedf(float(e["sol_azimute"]), 0.1), snappedf(float(e["sol_elevacao"]), 0.1)],
			"lua": [snappedf(float(e["lua_azimute"]), 0.1), snappedf(float(e["lua_elevacao"]), 0.1)],
			"luz_de": "sol" if bool(e["luz_e_sol"]) else "lua",
			"sol_energia": snappedf(float(e["sol_energia"]), 0.001), "lua_energia": snappedf(float(e["lua_energia"]), 0.001),
			"ceu_luz": snappedf(float(e["ceu_luz"]), 0.001), "lume": snappedf(float(e["lume"]), 0.001),
			"nevoa": [snappedf(float(e["nevoa_inicio"]), 0.1), snappedf(float(e["nevoa_fim"]), 0.1), snappedf(float(e["nevoa_tecto"]), 0.001)],
			"vento_de": Vento.rumo(float(v["azimute_de"])), "vento_kmh": snappedf(float(v["velocidade_ms"]) * 3.6, 0.1),
			"luma": _luma(img)}
		# ---- a medida: só a cena (o encaixe do céu desligado), o relógio a ANDAR ao ritmo do jogo
		# (24 min por dia: o forno das sombras repinta quando a luz roda) — 2 s de quadros
		_vp_ceu.render_target_update_mode = SubViewport.UPDATE_DISABLED
		_painel.visible = false
		_ciclo.set("parado", false)
		_vento.set("parado", false)
		await _quadros(10)
		var p0: int = sombras.get("pinturas")
		var t0 := Time.get_ticks_usec()
		var n := 0
		while Time.get_ticks_usec() - t0 < 2000000:
			await process_frame
			n += 1
		m["fps_sem_vsync"] = snappedf(float(n) * 1000000.0 / float(Time.get_ticks_usec() - t0), 0.1)
		m["forno_pinturas_em_2s"] = int(sombras.get("pinturas")) - p0
		m["chamadas"] = _vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
		m["primitivas"] = _vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
		m["chamadas_sombras_lua"] = _vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
		m["chamadas_servidor"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		_ciclo.set("parado", true)
		_vento.set("parado", true)
		_vp_ceu.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_painel.visible = true
		linhas.append(m)
		print("[ciclo] %s" % JSON.stringify(m))
	# ---- o pior caso: o modo de prova (o dia em 96 s: o forno repinta quase todos os quadros)
	_ciclo.call("definir_hora", 15.0)
	_ciclo.set("modo_prova", true)
	_ciclo.set("parado", false)
	_vento.set("parado", false)
	_vp_ceu.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_painel.visible = false
	await _quadros(10)
	var sombras_p0: int = sombras.get("pinturas")
	var t1 := Time.get_ticks_usec()
	var n1 := 0
	while Time.get_ticks_usec() - t1 < 3000000:
		await process_frame
		n1 += 1
	var prova := {"fps_sem_vsync": snappedf(float(n1) * 1000000.0 / float(Time.get_ticks_usec() - t1), 0.1),
		"quadros": n1, "forno_pinturas": int(sombras.get("pinturas")) - sombras_p0, "hora_inicial": "15:00"}
	var saida := {
		"resolucao_da_prova": [LARGURA, ALTURA],
		"placa": RenderingServer.get_video_adapter_name(),
		"metodo": str(ProjectSettings.get_setting("rendering/renderer/rendering_method")),
		"motor": Engine.get_version_info()["string"],
		"enquadramento": {"x": VISTA_DIA[0], "z": VISTA_DIA[1], "olhos_m": VISTA_DIA[2], "az": VISTA_DIA[3], "incl": VISTA_DIA[4], "fov": VISTA_DIA[5]},
		"nota": "FPS e chamadas medidos SÓ na cena (sem o encaixe do céu nem o painel), com o relógio a andar ao ritmo do jogo (dia de 24 min)",
		"horas": linhas,
		"modo_prova_3s": prova,
		"medidas_da_cena": _cena.get("medidas"),
	}
	var f := FileAccess.open(pasta.path_join("medicao_ciclo.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(saida, "\t"))
	f.close()
	print("[ciclo] medicao_ciclo.json gravado · modo de prova: %s" % JSON.stringify(prova))


## Luma média (0–255) e % de píxeis estourados (> 0,97) e quase pretos (< 0,04), de 6 em 6 píxeis.
func _luma(img: Image) -> Dictionary:
	var soma := 0.0
	var n := 0
	var estourado := 0
	var breu := 0
	for y in range(0, img.get_height(), 6):
		for x in range(0, img.get_width(), 6):
			var c := img.get_pixel(x, y)
			var l := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			soma += l
			n += 1
			if c.v > 0.97 and c.s < 0.25:
				estourado += 1
			if l < 0.04:
				breu += 1
	return {"media_0_255": snappedf(soma / float(n) * 255.0, 0.1), "estourado_%": snappedf(estourado * 100.0 / float(n), 0.01),
		"quase_preto_%": snappedf(breu * 100.0 / float(n), 0.01)}


# ------------------------------------------------------------------ o painel

func _texto(p: Vector2, s: String, tam: int, cor: Color = Color.WHITE) -> void:
	_painel.draw_string_outline(_fonte, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, maxi(tam / 6, 3), Color(0, 0, 0, 0.85))
	_painel.draw_string(_fonte, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor)


func _desenhar() -> void:
	var h: float = _ciclo.call("hora_do_mundo")
	var e: Dictionary = _ciclo.call("estado")
	var v: Dictionary = _vento.call("vento_actual")
	var fundo := Color(0.02, 0.03, 0.06, 0.55)
	# ---- o título e a hora
	_painel.draw_rect(Rect2(0, 0, LARGURA, 46), fundo)
	_texto(Vector2(20, 32), _titulo, 22)
	_painel.draw_rect(Rect2(20, 62, 470, 168), fundo)
	_texto(Vector2(36, 150), Ciclo.texto_de(h), 92, Color("#ffe9b8"))
	_texto(Vector2(300, 112), String(_ciclo.call("fase")), 30)
	_texto(Vector2(36, 196), "sol  az %4.0f°  elev %5.1f°" % [fposmod(float(e["sol_azimute"]), 360.0), float(e["sol_elevacao"])], 22, Color("#ffd27a"))
	_texto(Vector2(36, 222), "lua  az %4.0f°  elev %5.1f°" % [fposmod(float(e["lua_azimute"]), 360.0), float(e["lua_elevacao"])], 22, Color("#b8ccff"))
	# ---- o vento
	var de := Vento.rumo(float(v["azimute_de"]))
	var kmh := float(v["velocidade_ms"]) * 3.6
	var y0 := 250.0
	var alto_vento := 300.0 if _modo == "vento" else 112.0
	_painel.draw_rect(Rect2(20, y0, 470, alto_vento), fundo)
	_texto(Vector2(36, y0 + 36), "VENTO de %s (de %03.0f°)" % [de, fposmod(float(v["azimute_de"]), 360.0)], 28, Color("#c8f0d0"))
	_texto(Vector2(36, y0 + 72), "%.1f km/h · força %.2f · rajada %3.0f %%" % [kmh, float(v["forca"]), float(v["rajada"]) * 100.0], 24)
	_texto(Vector2(36, y0 + 100), "curva do dia: força-base %.2f" % float(_vento.get("forca_base")), 20, Color(1, 1, 1, 0.8))
	_bussola(Vector2(420, y0 + 58), 40.0, float(v["azimute_para"]), float(v["forca"]))
	if _modo == "vento":
		_grafico(Rect2(36, y0 + 118, 438, 166))
	# ---- o encaixe do céu
	var r := Rect2(LARGURA - ENCAIXE - 20, 62, ENCAIXE, ENCAIXE)
	_painel.draw_rect(r.grow(4), Color(0, 0, 0, 0.7))
	_painel.draw_texture_rect(_vp_ceu.get_texture(), r, false)
	var meio := r.get_center()
	for rumo: Array in [["N", 0.0], ["L", 90.0], ["S", 180.0], ["O", 270.0]]:
		var a := deg_to_rad(float(rumo[1]))
		var dir := Vector3(sin(a) * cos(deg_to_rad(22.0)), sin(deg_to_rad(22.0)), -cos(a) * cos(deg_to_rad(22.0)))
		var p := _cam_ceu.unproject_position(_cam_ceu.global_position + dir * 100.0)
		p = r.position + p
		_texto(p + Vector2(-8, 9), rumo[0], 24, Color("#fff4c0"))
	_texto(Vector2(r.position.x, r.end.y + 30), "o céu por cima da clareira (olhar para o zénite)", 18)
	_ = meio


## A rosa do vento: a seta aponta PARA ONDE o vento sopra (norte em cima, como no encaixe).
func _bussola(c: Vector2, raio: float, az_para: float, forca: float) -> void:
	_painel.draw_arc(c, raio, 0.0, TAU, 40, Color(1, 1, 1, 0.6), 2.0)
	_texto(c + Vector2(-6, -raio - 6), "N", 16)
	var a := deg_to_rad(az_para)
	var d := Vector2(sin(a), -cos(a))
	var comp := raio * (0.35 + 0.65 * clampf(forca / 1.3, 0.0, 1.0))
	var ponta := c + d * comp
	_painel.draw_line(c - d * comp * 0.6, ponta, Color("#c8f0d0"), 4.0)
	var lado := Vector2(-d.y, d.x)
	_painel.draw_colored_polygon(PackedVector2Array([ponta + d * 6.0, ponta - d * 10.0 + lado * 8.0, ponta - d * 10.0 - lado * 8.0]), Color("#c8f0d0"))


## O gráfico da força nos últimos 20 s: a linha clara é a força (com as rajadas); a tracejada é
## a curva do dia (a força-base).
func _grafico(r: Rect2) -> void:
	_painel.draw_rect(r, Color(0, 0, 0, 0.35))
	_texto(r.position + Vector2(6, 20), "força nos últimos 20 s (— força com rajadas · ·· curva do dia)", 16, Color(1, 1, 1, 0.85))
	var topo := 1.6
	for k in [0.5, 1.0, 1.5]:
		var y := r.end.y - r.size.y * k / topo
		_painel.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), Color(1, 1, 1, 0.12), 1.0)
		_texto(Vector2(r.end.x - 34, y - 3), "%.1f" % k, 14, Color(1, 1, 1, 0.5))
	if _historia.size() < 2:
		return
	var n := int(20.0 * QPS)
	var pf := PackedVector2Array()
	var pb := PackedVector2Array()
	for i in _historia.size():
		var x := r.end.x - r.size.x * float(_historia.size() - 1 - i) / float(n)
		pf.append(Vector2(x, r.end.y - r.size.y * clampf(float(_historia[i][0]) / topo, 0.0, 1.0)))
		if i % 6 == 0:
			pb.append(Vector2(x, r.end.y - r.size.y * clampf(float(_historia[i][1]) / topo, 0.0, 1.0)))
	_painel.draw_polyline(pf, Color("#c8f0d0"), 2.5)
	for p in pb:
		_painel.draw_circle(p, 1.6, Color(1, 0.85, 0.5, 0.8))
