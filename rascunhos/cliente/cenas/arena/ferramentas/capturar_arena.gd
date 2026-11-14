extends SceneTree
## capturar_arena.gd — Ordem 42. A PROVA POR RENDER da arena integrada (cenas/arena/arena.tscn com o
## mapa da floresta como campo de batalha): abre a cena DO JOGO, põe-lhe um combate de DEMONSTRAÇÃO
## no Estado (figuras, opções de Mover, casas a arder — dados fictícios desta ferramenta, como nos
## testes; o cliente continua a não decidir nada), pousa a câmara da mesa em cada vista etiquetada,
## grava a captura (modo, foco e ângulo no NOME do ficheiro) e MEDE: chamadas de desenho,
## primitivas, FPS sem v-sync, e o movimento da relva (dois quadros a 2 s).
##
##   godot --path cliente --resolution 1920x1080 -s res://cenas/arena/ferramentas/capturar_arena.gd
##   (opções depois de «--»:  --so=1,5  só essas  ·  --pasta=capturas/x  ·  --png  sem perdas)
##
## Precisa de janela (GPU): NÃO corre com --headless.

const CENA := "res://cenas/arena/arena.tscn"
const LARGURA := 1920
const ALTURA := 1080
const MOVER := 1
const ATAQUE := 2

var _pasta := "res://cenas/arena/capturas"
var _so: Array = []
var _png := false
var _vp: SubViewport
var _arena: Node3D
var _medidas: Array = []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--so="):
			for s in a.trim_prefix("--so=").split(","):
				_so.append(int(s))
		elif a == "--png":
			_png = true
		elif a.begins_with("--pasta="):
			_pasta = "res://cenas/arena/" + a.trim_prefix("--pasta=")
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _s(v: float, casas: int = 1) -> String:
	var t := ("%." + str(casas) + "f") % absf(v)
	return ("+" if v >= 0.0 else "-") + t.replace(".", ",")


# ------------------------------------------------------------------ o combate de demonstração

func _figura(id: String, nome: String, x: int, y: int, lado: String, extra: Dictionary = {}) -> Dictionary:
	var f := {"id": id, "nomePublico": nome, "x": x, "y": y, "lado": lado, "orientacao": "N", "visivel": "de_pe"}
	f.merge(extra, true)
	return f


func _montar_combate() -> void:
	var est = root.get_node("/root/Estado")
	var figuras := [
		_figura("fA", "Ong", 10, 10, "jogadora", {"seatId": "s1"}),
		_figura("fB", "Lia", 7, 12, "jogadora", {"orientacao": "L"}),
		_figura("fC", "Lobo", 13, 7, "criatura", {"orientacao": "S"}),
		_figura("fD", "Orc", 12, 13, "criatura", {"orientacao": "O"}),
		_figura("fE", "Bandido", 4, 5, "criatura", {"visivel": "caida"}),
		_figura("fF", "Batedor", 2, 2, "criatura", {"orientacao": "S"}),
		_figura("fG", "Vigia", 17, 3, "criatura", {"orientacao": "O"}),
		_figura("fH", "Kai", 15, 17, "jogadora", {"orientacao": "N"}),
	]
	est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "demo-42", "seq": 1, "revision": 5,
		"fase": "combate", "rodada": 1, "mapa": {"largura": 20, "altura": 20, "casaM": 1.5},
		"figuras": figuras, "vezId": "fA", "propria": {"figuraId": "fA"},
		"fogo": {"casas": [{"x": 15, "y": 9}, {"x": 16, "y": 9}, {"x": 15, "y": 10}]}, "ambiente": {}})
	var ocupadas := {}
	for f in figuras:
		ocupadas[Vector2i(f["x"], f["y"])] = true
	var mover: Array = []
	for dy in range(-4, 5):
		for dx in range(-4, 5):
			var d := absi(dx) + absi(dy)
			var c := Vector2i(10 + dx, 10 + dy)
			if d == 0 or d > 4 or ocupadas.has(c):
				continue
			mover.append({"x": c.x, "y": c.y, "custoM": 1.5 * d})
	est.receber_opcoes({"v": 2, "type": "ROOM_OPTIONS", "revision": 5, "vezId": "fA", "orcamentoM": 6.0,
		"mover": mover, "ataques": [{"alvoId": "fC", "arma": "espada"}, {"alvoId": "fD", "arma": "espada"}],
		"consumiveis": [], "acoes": ["encerrar", "defender"], "reacoes": []})


# ------------------------------------------------------------------ câmara

func _mesa(modo: int, foco: Vector3, rumo: float, incl: float, zoom: float) -> void:
	var cam = _arena.camera
	cam.set_process(true)
	cam.definir_modo(modo)
	if modo == 1:  # LIVRE_360
		cam.rumo = rumo
		cam.inclinacao = incl
	cam.foco = foco
	cam._limitar()
	cam.definir_zoom(zoom)
	cam._saltar()


func _fixa(x: float, z: float, olhos: float, az: float, incl: float) -> void:
	var cam: Camera3D = _arena.camera
	cam.set_process(false)
	cam.global_position = Vector3(x, _arena.altura_chao(x, z) + olhos, z)
	cam.rotation = Vector3(deg_to_rad(incl), -deg_to_rad(az), 0.0)


func _nome_mesa(n: int, nome: String) -> String:
	var cam = _arena.camera
	var modo := ["FIXA", "360", "PANORAMA"][cam.modo] as String
	var f: Vector3 = cam._foco_alvo()
	return "%02d_%s_%s_foco-x%s-z%s_rumo%s_incl%s_dist%sm" % [n, nome, modo, _s(f.x), _s(f.z),
		_s(cam._rumo_alvo(), 0), _s(cam._incl_alvo(), 0), _s(cam._dist_alvo())]


# ------------------------------------------------------------------ prova

func _correr() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var rede = root.get_node("/root/Rede")
	rede._ativo = true  # sem servidor: a arena não vai ao lobby (como em testes/hud_acoes.gd)
	_vp = SubViewport.new()
	_vp.size = Vector2i(LARGURA, ALTURA)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	var mostra := TextureRect.new()
	mostra.texture = _vp.get_texture()
	mostra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mostra.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(mostra)
	_montar_combate()
	var t0 := Time.get_ticks_msec()
	_arena = (load(CENA) as PackedScene).instantiate()
	_vp.add_child(_arena)
	var carga := Time.get_ticks_msec() - t0
	await _quadros(3)
	_arena._perfis.aplicar("alto")
	_arena.definir_modo(MOVER)
	_arena._cursor = Vector2i(12, 10)
	_arena._atualizar_cursor()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_pasta))
	print("[arena42] carga %d ms" % carga)

	var cA: Vector3 = _arena.centro_casa(Vector2i(10, 10))
	var vistas: Array = [
		# n, nome, chamada
		[1, "centro-em-jogo-mover", func(): _mesa(0, cA, 0.0, 55.0, 1.5)],
		[2, "centro-em-jogo-ataque", func():
			_arena.definir_modo(ATAQUE)
			_mesa(0, cA, 0.0, 55.0, 1.5)],
		[3, "canto-NO_olha-centro", func():
			_arena.definir_modo(MOVER)
			_mesa(1, _arena.centro_casa(Vector2i(0, 0)), -135.0, 32.0, 1.5)],
		[4, "canto-NE_olha-centro", func(): _mesa(1, _arena.centro_casa(Vector2i(_arena.largura - 1, 0)), 135.0, 32.0, 1.5)],
		[5, "canto-SE_olha-centro", func(): _mesa(1, _arena.centro_casa(Vector2i(_arena.largura - 1, _arena.altura - 1)), 45.0, 32.0, 1.5)],
		[6, "canto-SO_olha-centro", func(): _mesa(1, _arena.centro_casa(Vector2i(0, _arena.altura - 1)), -45.0, 32.0, 1.5)],
		[7, "longe_vista-ref07", func(): _fixa(5.0, 27.0, 2.3, -11.0, 1.0)],
		[8, "panorama", func(): _mesa(2, cA, 0.0, 78.0, 1.5)],
	]
	# a volta de 360° rasante (inclinação mínima, zoom mínimo = a câmara mais longe): os cartões do anel longe
	var k := 9
	for rumo in [0.0, 45.0, 90.0, 135.0, 180.0, -135.0, -90.0, -45.0]:
		var r: float = rumo
		vistas.append([k, "volta360-rasante", func(): _mesa(1, Vector3(0, _arena.altura_chao(0, 0), 0), r, 20.0, 0.6)])
		k += 1
	# os perfis Baixo e Médio na vista do centro (o Alto é a 01)
	vistas.append([17, "centro-em-jogo-perfil-BAIXO", func():
		_arena._perfis.aplicar("baixo")
		_mesa(0, cA, 0.0, 55.0, 1.5)])
	vistas.append([18, "centro-em-jogo-perfil-MEDIO", func():
		_arena._perfis.aplicar("medio")
		_mesa(0, cA, 0.0, 55.0, 1.5)])
	# de perto, à altura das figuras: o pé assenta no relevo?
	vistas.append([19, "perto-figuras-rasante", func():
		_arena._perfis.aplicar("alto")
		_mesa(1, _arena.centro_casa(Vector2i(8, 9)), 200.0, 20.0, 3.0)])
	vistas.append([20, "perto-encosta-NO", func(): _mesa(1, _arena.centro_casa(Vector2i(3, 4)), 160.0, 20.0, 2.6)])

	for v: Array in vistas:
		var n: int = v[0]
		if not _so.is_empty() and not _so.has(n):
			continue
		(v[2] as Callable).call()
		await _quadros(4)
		var nome: String
		if _arena.camera.is_processing():
			nome = _nome_mesa(n, v[1])
		else:
			var p: Vector3 = _arena.camera.global_position
			nome = "%02d_%s_x%s_z%s_olhos%sm_az%s_incl%s" % [n, v[1], _s(p.x), _s(p.z), _s(p.y - _arena.altura_chao(p.x, p.z)).trim_prefix("+"),
				_s(-rad_to_deg(_arena.camera.rotation.y)), _s(rad_to_deg(_arena.camera.rotation.x))]
		var m := await _medir(n, nome)
		var img := _vp.get_texture().get_image()
		var caminho := ProjectSettings.globalize_path("%s/%s.%s" % [_pasta, nome, "png" if _png else "jpg"])
		if _png:
			img.save_png(caminho)
		else:
			img.save_jpg(caminho, 0.95)
		m["ficheiro"] = caminho.get_file()
		_medidas.append(m)
		print("[arena42] %s | %d chamadas | %d prim | %.0f fps" % [nome, m["chamadas"], m["primitivas"], m["fps"]])
		if n == 1 or n == 7:
			await _movimento(nome)
	var f := FileAccess.open(ProjectSettings.globalize_path(_pasta + "/medicao.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"ordem": 42, "gpu": RenderingServer.get_video_adapter_name(),
		"render": RenderingServer.get_current_rendering_method(), "resolucao": [LARGURA, ALTURA], "carga_ms": carga,
		"mapa": _arena.mapa.medidas, "vistas": _medidas}, "  "))
	f.close()
	print("[arena42] fim: %d vistas" % _medidas.size())
	quit(0)


## Chamadas de desenho e primitivas do quadro (do SubViewport) e FPS sem v-sync (2 s de relógio).
func _medir(n: int, nome: String) -> Dictionary:
	await _quadros(2)
	var t0 := Time.get_ticks_usec()
	var q := 0
	while Time.get_ticks_usec() - t0 < 2000000:
		await process_frame
		q += 1
	var seg := float(Time.get_ticks_usec() - t0) / 1e6
	return {"n": n, "vista": nome,
		"chamadas": _vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"primitivas": _vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		"objectos": _vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
		"fps": q / seg, "relva_tufos_desenhados": _arena.mapa.relva.tufos_ativos()}


## A relva mexe? Dois quadros da mesma vista a 2 s: diferença média de luma, e a IMAGEM da diferença.
func _movimento(nome: String) -> void:
	var a := _vp.get_texture().get_image()
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 2000:
		await process_frame
	var b := _vp.get_texture().get_image()
	a.convert(Image.FORMAT_RGB8)
	b.convert(Image.FORMAT_RGB8)
	var d := Image.create(LARGURA / 2, ALTURA / 2, false, Image.FORMAT_RGB8)
	var soma := 0.0
	var conta := 0
	for y in range(0, ALTURA, 2):
		for x in range(0, LARGURA, 2):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			var dl := absf(ca.get_luminance() - cb.get_luminance())
			soma += dl
			conta += 1
			var v := clampf(dl * 6.0, 0.0, 1.0)
			d.set_pixel(x / 2, y / 2, Color(v, v, v))
	var media := soma / conta * 255.0
	d.save_png(ProjectSettings.globalize_path("%s/%s_MOVIMENTO-2s.png" % [_pasta, nome]))
	_medidas.back()["movimento_luma_2s"] = media
	print("[arena42] movimento da relva em %s: %.2f/255" % [nome, media])
