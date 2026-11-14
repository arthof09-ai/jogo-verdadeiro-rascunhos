extends SceneTree
## Bancada do clima (Ordem 40): vídeos etiquetados, capturas e medição, sobre a arena de hoje (a arena do
## Mestre com as figuras-marcador da fixture do servidor, como o foto_mestre.gd). Corre COM render — nunca
## com --headless (que não desenha). Não entra no CI: precisa de GPU; a prova é para os olhos.
##
##   VÍDEO (um clima e uma intensidade por corrida; o Godot grava o .avi, quadro a quadro, a 30 fps certos):
##     godot --path cliente --resolution 1280x720 --fixed-fps 30 --write-movie <pasta>/neve-forte.avi \
##       -s res://testes/video_clima.gd -- --modo=video --clima=neve --intensidade=forte --saida=<pasta>
##   CAPTURAS (acumulação da neve em 3 tempos; chão molhado antes/depois):
##     godot --path cliente --resolution 1920x1080 --fixed-fps 30 --disable-vsync \
##       -s res://testes/video_clima.gd -- --modo=fotos --saida=<pasta>
##   MEDIÇÃO (FPS e draw calls por perfil, com e sem clima; tempo real, sem vsync):
##     godot --path cliente --resolution 1920x1080 --disable-vsync \
##       -s res://testes/video_clima.gd -- --modo=medir --saida=<pasta>
##
## As casas destacadas que aparecem são DEMONSTRAÇÃO (a marcação é nossa — não é o jogo): servem para se ver
## que os destaques continuam a ler-se com o clima ligado.

const ArenaMestre := preload("res://cenas/mestre/arena_mestre.gd")
const Perfis := preload("res://arte/perfis/aplicar_perfil.gd")
const Integrador := preload("res://arte/clima/integrador_vento.gd")

const NOMES := {"chuva": "CHUVA", "neve": "NEVE", "nenhum": "SEM CLIMA", "fraco": "FRACA", "forte": "FORTE"}

var _saida := ""
var _modo := "video"
var _clima := "neve"
var _intensidade := "forte"
var _perfil := "alto"
var _segundos := 24.0
var _quadro := Vector2i(1280, 720)
var _vento_rumo := 20.0
var _vento_forca := 2.5
var _fx: Dictionary = {}
var _a  # ArenaMestre
var _rotulo: Label
var _seta: MeshInstance3D
var _falhas := 0
var _t := 0.0
var _dt := 1.0 / 30.0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--saida="):
			_saida = arg.trim_prefix("--saida=")
		elif arg.begins_with("--modo="):
			_modo = arg.trim_prefix("--modo=")
		elif arg.begins_with("--clima="):
			_clima = arg.trim_prefix("--clima=")
		elif arg.begins_with("--intensidade="):
			_intensidade = arg.trim_prefix("--intensidade=")
		elif arg.begins_with("--perfil="):
			_perfil = arg.trim_prefix("--perfil=")
		elif arg.begins_with("--segundos="):
			_segundos = float(arg.trim_prefix("--segundos="))
		elif arg.begins_with("--quadro="):
			var q := arg.trim_prefix("--quadro=").split("x")
			_quadro = Vector2i(int(q[0]), int(q[1]))
		elif arg.begins_with("--vento="):
			var p := arg.trim_prefix("--vento=").split(",")
			_vento_rumo = float(p[0])
			_vento_forca = float(p[1])
	if _saida == "":
		_saida = OS.get_user_data_dir().path_join("clima")
	DirAccess.make_dir_recursive_absolute(_saida)
	print("== bancada do clima · modo ", _modo, " · saída ", _saida, " · render: ", RenderingServer.get_video_adapter_name(), " ==")
	var caminho := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var d = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if not (d is Dictionary):
		printerr("sem a fixture do servidor")
		quit(1)
		return
	_fx = d
	# O quadro tem sempre o mesmo tamanho, seja qual for o ecrã do PC (a janela pode ser mais pequena).
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = _quadro
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede.papel = "mestre"
	_montar()
	await _quadros(3)
	match _modo:
		"video":
			await _video()
		"fotos":
			await _fotos()
		"medir":
			await _medir()
		_:
			printerr("modo desconhecido: ", _modo)
			_falhas += 1
	print("bancada do clima: %d falha(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


# ---------------------------------------------------------------- a cena

func _montar() -> void:
	var vista: Dictionary = _fx["mestre"]["vista"]
	_a = ArenaMestre.new()
	root.add_child(_a)
	_a.aplicar_vista(vista)
	var perfis := Perfis.new()
	perfis.name = "Perfis"
	_a.add_child(perfis)
	perfis.perfil_aplicado.connect(_a.clima.definir_perfil)
	perfis.aplicar(_perfil)
	_a.camera.definir_modo(_a.camera.Modo.FIXA)
	_a.camera.repor_zoom()
	_a.camera.focar(_centro_das_figuras())
	_a.camera._saltar()
	# Casas destacadas de DEMONSTRAÇÃO, ao lado das figuras (não é o jogo).
	var c: Vector2i = _a.casa_de_ponto(_centro_das_figuras())
	var casas: Array[Vector2i] = []
	for dx in range(-1, 2):
		for dy in range(2, 4):
			casas.append(c + Vector2i(dx, dy))
	_a.destacar(casas)
	# A seta do vento, deitada no chão à frente do campo: aponta para onde o vento do frame sopra.
	_seta = MeshInstance3D.new()
	_seta.mesh = _malha_seta()
	_a.add_child(_seta)
	var camada := CanvasLayer.new()
	root.add_child(camada)
	_rotulo = Label.new()
	_rotulo.position = Vector2(20, float(_quadro.y) - 104.0)
	_rotulo.add_theme_font_size_override("font_size", 22)
	_rotulo.add_theme_color_override("font_color", Color(1, 1, 1))
	_rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_rotulo.add_theme_constant_override("outline_size", 8)
	camada.add_child(_rotulo)


func _malha_seta() -> Mesh:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.55, 0.1)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.render_priority = 30
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, m)
	# Aponta para +X, comprimento 3 m: haste + ponta.
	for p in [Vector3(-1.5, 0, -0.12), Vector3(0.7, 0, -0.12), Vector3(0.7, 0, 0.12),
			Vector3(-1.5, 0, -0.12), Vector3(0.7, 0, 0.12), Vector3(-1.5, 0, 0.12),
			Vector3(0.7, 0, -0.45), Vector3(1.5, 0, 0.0), Vector3(0.7, 0, 0.45)]:
		im.surface_add_vertex(p)
	im.surface_end()
	return im


func _centro_das_figuras() -> Vector3:
	var soma := Vector3.ZERO
	var n := 0
	for f in _fx["mestre"]["vista"]["mestre"]["figuras"]:
		if f.get("colocada") == true:
			soma += _a.centro_da_casa(Vector2i(int(f.get("x", 0)), int(f.get("y", 0))))
			n += 1
	return soma / float(maxi(n, 1))


func _por_seta() -> void:
	var v: Vector2 = _a.clima.vento_do_frame()
	var foco: Vector3 = _a.camera.foco
	_seta.position = Vector3(foco.x, 0.06, foco.z + 6.0)
	_seta.rotation = Vector3(0.0, -atan2(v.y, v.x), 0.0)
	_seta.scale = Vector3.ONE * clampf(v.length() / 2.5, 0.5, 1.8)


func _etiqueta(extra: String) -> void:
	var cl = _a.clima
	var v: Vector2 = cl.vento_do_frame()
	var quantos := ""
	if cl.tipo == "chuva":
		quantos = "%d gotas + %d salpicos" % [cl.contagem_atual("chuva"), cl.contagem_atual("salpicos")]
	elif cl.tipo == "neve":
		quantos = "%d flocos" % cl.contagem_atual("neve")
	var titulo := "ORDEM 40 · CLIMA · %s" % NOMES[cl.tipo]
	if cl.tipo != "nenhum":
		titulo += " %s" % NOMES[cl.intensidade]
	_rotulo.text = "%s · perfil %s · %s\nvento %.1f m/s → %d° (seta laranja) · molhado %d%% · neve pousada %d%%\nt = %.1f s · %s" % [
		titulo, cl.perfil, quantos, v.length(), int(round(rad_to_deg(atan2(v.y, v.x)))),
		int(round(cl.molhado * 100.0)), int(round(cl.neve * 100.0)), _t, extra]


func _gravar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		printerr("  FALHA ", nome, ": sem imagem (o render não correu)")
		_falhas += 1
		return
	var erro := img.save_png(_saida.path_join(nome))
	if erro != OK:
		printerr("  FALHA ", nome, ": erro ", erro)
		_falhas += 1
		return
	print("  ok    ", nome, " (", img.get_width(), "×", img.get_height(), ")")


## Corre `segundos` de tempo da cena (com --fixed-fps cada quadro vale 1/fps certo).
func _passar(segundos: float, extra: String) -> void:
	var fim := _t + segundos
	while _t < fim - 0.0001:
		await process_frame
		_t += _dt
		_por_seta()
		_etiqueta(extra)


func _process(delta: float) -> bool:
	_dt = delta
	return false


# ---------------------------------------------------------------- vídeo

## O guião de um vídeo: 1 s sem clima (o «antes»), liga o clima sem reiniciar a cena, o vento MUDA a meio
## (rumo e força — os flocos seguem daí para a frente, sem saltar), aproxima das figuras e acaba no Panorama.
func _video() -> void:
	var cl = _a.clima
	cl.definir_vento(_vento_rumo, _vento_forca)
	var nome := "%s-%s" % [_clima, _intensidade]
	_por_seta()
	await _passar(1.0, "câmara Fixa · ANTES (sem clima)")
	await _gravar("%s-0-antes.png" % nome)
	cl.definir(_clima, _intensidade)
	var parte := (_segundos - 1.0) / 23.0
	await _passar(7.0 * parte, "câmara Fixa · o clima ligou sem reiniciar a cena")
	await _gravar("%s-1-fixa.png" % nome)
	cl.definir_vento(_vento_rumo + 75.0, _vento_forca * 1.7)
	await _passar(4.0 * parte, "câmara Fixa · O VENTO MUDOU (rumo +75°, força ×1,7)")
	_a.camera.definir_zoom(3.0)
	await _passar(6.0 * parte, "câmara Fixa de perto · figuras")
	await _gravar("%s-2-perto.png" % nome)
	_a.camera.definir_modo(_a.camera.Modo.PANORAMA)
	await _passar(6.0 * parte, "câmara Panorama · o campo inteiro")
	await _gravar("%s-3-panorama.png" % nome)
	print("  video ", nome, ": ", JSON.stringify({
		"clima": _clima, "intensidade": _intensidade, "perfil": cl.perfil, "segundos": _t,
		"gotas": cl.contagem_atual("chuva"), "salpicos": cl.contagem_atual("salpicos"), "flocos": cl.contagem_atual("neve"),
		"molhado": cl.molhado, "neve": cl.neve}))


# ---------------------------------------------------------------- capturas

func _fotos() -> void:
	var cl = _a.clima
	cl.definir_vento(_vento_rumo, _vento_forca)
	_a.camera.definir_zoom(2.2)
	_a.camera._saltar()
	# Neve forte: a acumulação em 3 tempos (início / meio / depois).
	await _passar(0.5, "câmara Fixa · antes")
	await _gravar("neve-acumulacao-0-antes.png")
	cl.definir("neve", "forte")
	await _passar(4.0, "câmara Fixa · neve forte · início")
	await _gravar("neve-acumulacao-1-inicio.png")
	await _passar(18.0, "câmara Fixa · neve forte · meio")
	await _gravar("neve-acumulacao-2-meio.png")
	await _passar(26.0, "câmara Fixa · neve forte · depois")
	await _gravar("neve-acumulacao-3-depois.png")
	_a.camera.definir_modo(_a.camera.Modo.PANORAMA)
	await _passar(2.0, "câmara Panorama · neve forte · depois")
	await _gravar("neve-acumulacao-4-depois-panorama.png")
	# Chuva forte: o chão antes e depois.
	_a.camera.definir_modo(_a.camera.Modo.FIXA)
	cl.definir("nenhum")
	cl.definir_acumulacao(0.0, 0.0)
	_t = 0.0
	await _passar(3.0, "câmara Fixa · chão seco (antes)")
	await _gravar("chuva-chao-0-antes-seco.png")
	cl.definir("chuva", "forte")
	await _passar(4.0, "câmara Fixa · chuva forte · a molhar")
	await _gravar("chuva-chao-1-a-molhar.png")
	await _passar(8.0, "câmara Fixa · chuva forte · molhado")
	await _gravar("chuva-chao-2-molhado.png")
	_a.camera.definir_zoom(3.0)
	await _passar(2.0, "câmara Fixa de perto · chuva forte · molhado")
	await _gravar("chuva-chao-3-molhado-perto.png")
	_a.camera.definir_modo(_a.camera.Modo.LIVRE_360)
	_a.camera.rumo = 140.0
	_a.camera.inclinacao = 28.0
	_a.camera.definir_zoom(2.0)
	await _passar(2.0, "câmara 360° rasante · chuva forte · molhado")
	await _gravar("chuva-chao-4-molhado-360-rasante.png")
	cl.definir("nenhum")
	await _passar(4.0, "câmara 360° rasante · parou de chover: o chão fica molhado")
	await _gravar("chuva-chao-5-depois-da-chuva.png")


# ---------------------------------------------------------------- medição

## FPS em tempo real (sem vsync) e draw calls, por perfil, com e sem cada clima, na câmara Fixa (zoom 1,5).
func _medir() -> void:
	var cl = _a.clima
	var perfis: Node = _a.get_node("Perfis")
	cl.definir_vento(_vento_rumo, _vento_forca)
	cl.segundos_transicao = 0.2
	var linhas: Array = []
	var texto := "| Perfil | Clima | Partículas | FPS (média) | ms/frame | Draw calls | Primitivas |\n| --- | --- | --- | --- | --- | --- | --- |\n"
	for perfil in ["baixo", "medio", "alto"]:
		perfis.aplicar(perfil)
		for caso in [["nenhum", "fraco"], ["chuva", "fraco"], ["chuva", "forte"], ["neve", "fraco"], ["neve", "forte"]]:
			cl.definir("nenhum")
			cl.definir_acumulacao(0.0, 0.0)
			await _quadros(30)
			cl.definir(caso[0], caso[1])
			if caso[0] == "chuva":
				cl.definir_acumulacao(0.8, 0.0)
			elif caso[0] == "neve":
				cl.definir_acumulacao(0.0, 0.6)
			await _quadros(90)
			var n := 300
			var chamadas := 0
			var primitivas := 0
			var t0 := Time.get_ticks_usec()
			for i in n:
				await process_frame
				chamadas = maxi(chamadas, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)))
				primitivas = maxi(primitivas, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)))
			var seg := float(Time.get_ticks_usec() - t0) / 1e6
			var particulas: int = cl.contagem_atual("chuva") + cl.contagem_atual("salpicos") + cl.contagem_atual("neve")
			var nome_caso: String = "sem clima" if caso[0] == "nenhum" else "%s %s" % [caso[0], caso[1]]
			var linha := {"perfil": perfil, "clima": nome_caso, "particulas": particulas, "fps": n / seg, "ms": 1000.0 * seg / n,
				"draw_calls": chamadas, "primitivas": primitivas}
			linhas.append(linha)
			texto += "| %s | %s | %d | %.0f | %.2f | %d | %d |\n" % [perfil, nome_caso, particulas, n / seg, 1000.0 * seg / n, chamadas, primitivas]
			print("  medido ", JSON.stringify(linha))
	# A medição da REF_85 com a conta do jogo: 3000 flocos, vento que muda de rumo e de força a meio.
	var integ := Integrador.new()
	integ.definir_caixa(cl.caixa_tamanho())
	var vento_fn := func(t: float) -> Vector2:
		var rumo := deg_to_rad(20.0 + (75.0 if t > 5.0 else 0.0) + 10.0 * sin(0.21 * t))
		return Vector2(cos(rumo), sin(rumo)) * (2.5 * (1.7 if t > 5.0 else 1.0) * (1.0 + 0.25 * sin(0.37 * t)))
	var m: Dictionary = integ.medir(3000, 600, 1.0 / 60.0, vento_fn, 1.8, 0.32)
	print("  REF_85 ", JSON.stringify(m))
	var janela := root.size
	var f := FileAccess.open(_saida.path_join("medicao.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"render": RenderingServer.get_video_adapter_name(), "janela": [janela.x, janela.y], "casos": linhas, "ref_85": m}, "  "))
	f.close()
	var g := FileAccess.open(_saida.path_join("medicao.md"), FileAccess.WRITE)
	g.store_string(texto)
	g.close()
