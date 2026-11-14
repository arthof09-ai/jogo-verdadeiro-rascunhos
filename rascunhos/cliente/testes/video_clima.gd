extends SceneTree
## Bancada do clima (Ordem 40): vídeos etiquetados, capturas e medição, sobre a arena de hoje (a arena do
## Mestre com as figuras-marcador da fixture do servidor, como o foto_mestre.gd). Corre COM render — nunca
## com --headless (que não desenha). Não entra no CI: precisa de GPU; a prova é para os olhos.
##
##   VÍDEO (um clima e uma intensidade por corrida; o Godot grava o .avi, quadro a quadro, a 30 fps certos):
##     godot --path cliente --resolution 1280x720 --fixed-fps 30 --write-movie <pasta>/neve-forte.avi \
##       -s res://testes/video_clima.gd -- --modo=video --clima=neve --intensidade=forte --saida=<pasta>
##   VÍDEO DA COMUTAÇÃO (chuva fraca → forte → neve fraca → forte → desligado, na mesma cena, sem reiniciar):
##     godot --path cliente --resolution 1280x720 --fixed-fps 30 --write-movie <pasta>/comutacao.avi \
##       -s res://testes/video_clima.gd -- --modo=troca --saida=<pasta>
##   A ARENA DA JOGADORA (cenas/arena/arena.tscn, com o HUD e um snapshot público de bancada): chuva forte e
##   neve forte na cena que a jogadora vê, com as capturas pelo caminho:
##     godot --path cliente --resolution 1280x720 --fixed-fps 30 --write-movie <pasta>/arena-jogadora.avi \
##       -s res://testes/video_clima.gd -- --modo=jogadora --saida=<pasta>
##   CAPTURAS (acumulação da neve em 3 tempos; chão molhado antes/depois):
##     godot --path cliente --resolution 1920x1080 --fixed-fps 30 --disable-vsync \
##       -s res://testes/video_clima.gd -- --modo=fotos --saida=<pasta>
##   MEDIÇÃO (FPS e draw calls por perfil, com e sem clima; tempo real, sem vsync):
##     godot --path cliente --resolution 1920x1080 --disable-vsync \
##       -s res://testes/video_clima.gd -- --modo=medir --saida=<pasta>
##
## ORDEM 41 (expansão: nevasca e chuva que alaga) — os mesmos comandos, com estes modos:
##   --modo=nevasca   VÍDEO: do ligar ao aglomerado (57 s de cena): rajadas, montes, gelo, véu.
##   --modo=alaga     VÍDEO LONGO: do chão seco à bolsa formada, e o drenar (bolsas → lama baça → seco), 112 s.
##   --modo=fracos    VÍDEO: chuva fraca e neve fraca — a base não regrediu (sem bolsas, sem aglomeração).
##   --modo=fotos41   CAPTURAS: nevasca em 3 tempos (canto e obstáculo marcados), alagamento em 3 tempos.
##   --modo=medir41   MEDIÇÃO: FPS/draw calls por perfil com e sem o clima forte; o crescimento medido.
## Nestes modos a bancada põe na cena OBSTÁCULOS de demonstração (muro, pedra, tronco — a arena de hoje é um
## tabuleiro liso), marca um canto e um obstáculo, e dá ao módulo 4 bacias de bancada «P1–P4» por
## definir_bacias() (é por aí que as poças do desenho do mapa entram). A figura que anda dentro da bolsa é
## movida pela bancada (demonstração do anel nos pés): nada disto é o jogo.
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
# Ordem 41
var _ordem41 := false
var _por_quadro := Callable()
var _medida := {}
var _ate_medir := 0
## As bacias da bancada (x, z, raio, fundura): P1 debaixo do lobo, P2 ao pé das três figuras, P3 e P4 livres.
const BACIAS_BANCADA: Array[Vector4] = [Vector4(14.6, 14.4, 3.3, 0.09), Vector4(4.6, 6.2, 2.5, 0.07),
	Vector4(21.5, 7.5, 2.8, 0.08), Vector4(8.5, 22.5, 3.6, 0.10)]
const FOCO_LARGO := Vector3(9.0, 0.0, 9.0)
const MODOS_41: Array[String] = ["nevasca", "alaga", "fracos", "fotos41", "medir41"]


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
	if _modo == "jogadora":
		await _jogadora()
		print("bancada do clima: %d falha(s)" % _falhas)
		quit(1 if _falhas > 0 else 0)
		return
	rede.papel = "mestre"
	_montar()
	if MODOS_41.has(_modo):
		_montar41()
	await _quadros(3)
	match _modo:
		"nevasca":
			await _nevasca()
		"alaga":
			await _alaga()
		"fracos":
			await _fracos()
		"fotos41":
			await _fotos41()
		"medir41":
			await _medir41()
		"video":
			await _video()
		"troca":
			await _troca()
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
	# A bancada começa sempre SECA e sem clima: o --clima= desta bancada também é lido pelo módulo (é o
	# parâmetro de apresentação dele), e o primeiro segundo de cada vídeo tem de ser o «antes».
	_a.clima.desligar()
	_a.clima.definir_acumulacao(0.0, 0.0)
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
	if _ordem41:
		_etiqueta41(extra)
		return
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
		if _por_quadro.is_valid():
			_por_quadro.call()
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


## O vídeo da COMUTAÇÃO: os dois climas e as duas intensidades, de seguida, na mesma cena, sem reiniciar nada.
## A chuva molha; a neve entra e o molhado seca por baixo dela; no fim desliga-se e o que pousou fica a derreter.
func _troca() -> void:
	var cl = _a.clima
	cl.definir_vento(_vento_rumo, _vento_forca)
	_a.camera.definir_zoom(1.6)
	_a.camera._saltar()
	_por_seta()
	await _passar(1.0, "câmara Fixa · sem clima")
	cl.definir("chuva", "fraco")
	await _passar(5.0, "COMUTAÇÃO sem reiniciar · chuva fraca")
	cl.definir("chuva", "forte")
	await _passar(5.0, "COMUTAÇÃO sem reiniciar · chuva fraca → CHUVA FORTE")
	await _gravar("troca-1-chuva-forte.png")
	cl.definir("neve", "fraco")
	await _passar(5.0, "COMUTAÇÃO sem reiniciar · chuva forte → NEVE FRACA (o molhado seca)")
	cl.definir("neve", "forte")
	await _passar(6.0, "COMUTAÇÃO sem reiniciar · neve fraca → NEVE FORTE")
	await _gravar("troca-2-neve-forte.png")
	cl.definir("nenhum")
	await _passar(3.0, "COMUTAÇÃO sem reiniciar · DESLIGADO (os flocos saem; a neve pousada fica a derreter)")
	await _gravar("troca-3-desligado.png")
	print("  video troca: ", JSON.stringify({"perfil": cl.perfil, "segundos": _t, "molhado": cl.molhado, "neve": cl.neve}))


# ---------------------------------------------------------------- a arena da jogadora

## A cena que a jogadora vê (arena.tscn: céu claro, cápsulas, HUD), com um snapshot PÚBLICO de bancada (não é
## o jogo). O clima liga-se como a arena o liga: pela preferência "clima" (arena._ao_preferencia).
func _jogadora() -> void:
	var rede := root.get_node("Rede")
	var estado := root.get_node("Estado")
	rede.papel = "jogadora"
	rede.estado_ligacao = rede.Ligacao.NA_MESA
	rede._ativo = true  # a arena chama Rede.iniciar(); com isto não vai ao lobby (como o testes/hud_acoes.gd)
	estado.aplicar_snapshot({
		"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "sala-bancada", "seq": 1, "revision": 5, "fase": "combate",
		"mapa": {"largura": 20, "altura": 20}, "iniciativa": ["fA", "fB", "fC", "fD"], "vezId": "fA", "rodada": 1, "ambiente": {},
		"figuras": [
			{"id": "fA", "nomePublico": "Heroína Teste", "lado": "jogadora", "x": 8, "y": 10},
			{"id": "fB", "nomePublico": "Aliada Teste", "lado": "jogadora", "x": 7, "y": 12},
			{"id": "fC", "nomePublico": "Lobo Teste", "lado": "criatura", "x": 11, "y": 9},
			{"id": "fD", "nomePublico": "Orc Teste", "lado": "criatura", "x": 12, "y": 11},
		],
		"propria": {"figuraId": "fA", "paLivre": 40, "estadoMorte": null, "ficha": {}},
	})
	var arena = (load("res://cenas/arena/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	await _quadros(2)
	var movimentos: Array = []
	for dx in range(-1, 2):
		for dy in range(1, 3):
			movimentos.append({"x": 9 + dx, "y": 11 + dy, "custoM": 1.5 * float(absi(dx) + dy)})
	estado.receber_opcoes({"v": 2, "type": "ROOM_OPTIONS", "revision": 5, "vezId": "fA", "orcamentoM": 9.0,
		"mover": movimentos, "ataques": [], "consumiveis": [], "acoes": ["encerrar"], "reacoes": []})
	arena.definir_modo(arena.Modo.MOVER)  # as casas do «Mover» destacadas: têm de continuar a ler-se
	arena._aplicar_perfil(_perfil)
	var cl = arena.clima
	cl.desligar()
	cl.definir_acumulacao(0.0, 0.0)
	cl.definir_vento(_vento_rumo, _vento_forca)
	arena.camera.definir_modo(arena.camera.Modo.FIXA)
	arena.camera.repor_zoom()
	arena.camera.focar(arena.centro_casa(Vector2i(9, 11)))
	arena.camera._saltar()
	var camada := CanvasLayer.new()
	camada.layer = 50
	root.add_child(camada)
	var rotulo := Label.new()
	rotulo.position = Vector2(20, 92)
	rotulo.add_theme_font_size_override("font_size", 20)
	rotulo.add_theme_color_override("font_color", Color(1, 1, 1))
	rotulo.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	rotulo.add_theme_constant_override("outline_size", 8)
	camada.add_child(rotulo)
	var passar := func(segundos: float, extra: String) -> void:
		var fim := _t + segundos
		while _t < fim - 0.0001:
			await process_frame
			_t += _dt
			var v: Vector2 = cl.vento_do_frame()
			rotulo.text = "ORDEM 40 · CLIMA · ARENA DA JOGADORA · %s%s · perfil %s
vento %.1f m/s → %d° · molhado %d%% · neve pousada %d%% · t = %.1f s · %s" % [
				NOMES[cl.tipo], (" " + NOMES[cl.intensidade]) if cl.tipo != "nenhum" else "", cl.perfil, v.length(),
				int(round(rad_to_deg(atan2(v.y, v.x)))), int(round(cl.molhado * 100.0)), int(round(cl.neve * 100.0)), _t, extra]
	await passar.call(1.5, "ANTES (sem clima)")
	await _gravar("jogadora-0-antes.png")
	arena._ao_preferencia("clima", "chuva-forte")
	await passar.call(9.0, "preferência «clima» = chuva-forte")
	await _gravar("jogadora-1-chuva-forte.png")
	arena._ao_preferencia("clima", "neve-forte")
	await passar.call(14.0, "preferência «clima» = neve-forte")
	await _gravar("jogadora-2-neve-forte.png")
	arena.camera.definir_zoom(3.0)
	await passar.call(5.0, "neve forte · de perto")
	await _gravar("jogadora-3-neve-forte-perto.png")
	arena._ao_preferencia("clima", "nenhum")
	await passar.call(2.5, "preferência «clima» = nenhum")
	print("  video arena-jogadora: ", JSON.stringify({"perfil": cl.perfil, "segundos": _t, "molhado": cl.molhado, "neve": cl.neve}))


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
			# Em tempo real: espera-se pelo RELÓGIO (não por quadros) que o clima anterior saia de todo e que o
			# novo chegue à contagem cheia; só então se mede, 2 s seguidos, já em regime.
			cl.definir("nenhum")
			cl.definir_acumulacao(0.0, 0.0)
			await create_timer(0.6).timeout
			if not cl.parado():
				printerr("  FALHA medir: o clima anterior não saiu (", perfil, " ", caso, ")")
				_falhas += 1
			cl.definir(caso[0], caso[1])
			if caso[0] == "chuva":
				cl.definir_acumulacao(0.8, 0.0)
			elif caso[0] == "neve":
				cl.definir_acumulacao(0.0, 0.6)
			await create_timer(0.8).timeout
			var n := 0
			var chamadas := 0
			var primitivas := 0
			var t0 := Time.get_ticks_usec()
			while Time.get_ticks_usec() - t0 < 2000000:
				await process_frame
				n += 1
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
	f.store_string(JSON.stringify({"render": RenderingServer.get_video_adapter_name(), "janela": [janela.x, janela.y],
		"quadro_do_render": [root.get_texture().get_width(), root.get_texture().get_height()], "casos": linhas, "ref_85": m}, "  "))
	f.close()
	var g := FileAccess.open(_saida.path_join("medicao.md"), FileAccess.WRITE)
	g.store_string(texto)
	g.close()


# ================================================================ ORDEM 41: nevasca e chuva que alaga

## A cena da expansão: obstáculos de DEMONSTRAÇÃO no grupo "clima_obstaculo", as marcas (canto, obstáculo,
## P1–P4) e as bacias da bancada.
func _montar41() -> void:
	_ordem41 = true
	var grupo: StringName = _a.clima.GRUPO_OBSTACULO
	var pedra := StandardMaterial3D.new()
	pedra.albedo_color = Color("6c675f")
	pedra.roughness = 1.0
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color("5b4634")
	madeira.roughness = 1.0
	# Muro: atravessado ao vento (comprido em Z).
	var muro := MeshInstance3D.new()
	muro.name = "Muro"
	var caixa := BoxMesh.new()
	caixa.size = Vector3(0.7, 1.3, 3.0)
	caixa.material = pedra
	muro.mesh = caixa
	muro.position = Vector3(9.75, 0.65, 6.0)
	# Pedra: um calhau baixo e largo.
	var calhau := MeshInstance3D.new()
	calhau.name = "Pedra"
	var esfera := SphereMesh.new()
	esfera.radius = 1.0
	esfera.height = 2.0
	esfera.radial_segments = 14
	esfera.rings = 7
	esfera.material = pedra
	calhau.mesh = esfera
	calhau.scale = Vector3(1.0, 0.62, 0.85)
	calhau.position = Vector3(6.4, 0.38, 11.6)
	# Tronco caído.
	var tronco := MeshInstance3D.new()
	tronco.name = "Tronco"
	var cil := CylinderMesh.new()
	cil.top_radius = 0.30
	cil.bottom_radius = 0.36
	cil.height = 3.2
	cil.radial_segments = 10
	cil.material = madeira
	tronco.mesh = cil
	tronco.rotation = Vector3(deg_to_rad(90.0), deg_to_rad(-12.0), 0.0)
	tronco.position = Vector3(18.5, 0.33, 12.0)
	for o in [muro, calhau, tronco]:
		o.add_to_group(grupo)
		_a.add_child(o)
	_marca("CANTO\n↓", Vector3(0.9, 2.3, 0.9), Color(1.0, 0.85, 0.3))
	_marca("OBSTÁCULO\n↓", Vector3(9.75, 2.6, 6.0), Color(1.0, 0.85, 0.3))
	_a.clima.definir_bacias(BACIAS_BANCADA)
	if _modo in ["alaga", "fotos41"]:
		for i in BACIAS_BANCADA.size():
			var b: Vector4 = BACIAS_BANCADA[i]
			_marca("P%d" % (i + 1), Vector3(b.x, 0.9, b.y - b.z - 0.3), Color(0.75, 0.92, 1.0), 30)


func _marca(texto: String, onde: Vector3, cor: Color, tamanho: int = 40) -> void:
	var r := Label3D.new()
	r.text = texto
	r.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	r.no_depth_test = true
	r.font_size = tamanho
	r.pixel_size = 0.01
	r.outline_size = 10
	r.modulate = cor
	r.position = onde
	r.render_priority = 40
	r.outline_render_priority = 39
	_a.add_child(r)


func _cam(modo: int, foco: Vector3, zoom: float, saltar: bool = false) -> void:
	_a.camera.definir_modo(modo)
	_a.camera.focar(foco)
	_a.camera.definir_zoom(zoom)
	if saltar:
		_a.camera._saltar()


func _no_da_figura(nome: String) -> Node3D:
	for f in _fx["mestre"]["vista"]["mestre"]["figuras"]:
		if str(f.get("nome", "")).begins_with(nome):
			return _a._nos.get(str(f.get("id", "")))
	return null


func _etiqueta41(extra: String) -> void:
	var cl = _a.clima
	var v: Vector2 = cl.vento_do_frame()
	var titulo := "SEM CLIMA"
	var quantos := ""
	if cl.tipo == "neve":
		titulo = "NEVASCA (neve forte)" if cl.nevasca() else "NEVE FRACA"
		quantos = " · %d flocos" % cl.contagem_atual("neve")
		if cl.contagem_atual("veu") > 0:
			quantos += " + %d do véu" % cl.contagem_atual("veu")
	elif cl.tipo == "chuva":
		titulo = "CHUVA QUE ALAGA (chuva forte)" if cl.alaga() else "CHUVA FRACA"
		quantos = " · %d gotas + %d salpicos" % [cl.contagem_atual("chuva"), cl.contagem_atual("salpicos")]
	var estado := ""
	var linha_agua: bool = _modo == "alaga" or cl.tipo == "chuva" or cl.agua > 0.0 or cl.lama > 0.0
	if _modo == "nevasca":
		linha_agua = false
	if linha_agua:
		_ate_medir -= 1
		if _ate_medir <= 0:
			_ate_medir = 10
			_medida = cl.medir_alagamento(0.25)
		estado = "molhado %d%% · ÁGUA %d%% (bolsas %.1f m², fundura máx. %.1f cm) · LAMA %d%% (%.1f m², brilho %d%%)" % [
			int(round(cl.molhado * 100.0)), int(round(cl.agua * 100.0)), float(_medida.get("area_agua_m2", 0.0)),
			100.0 * float(_medida.get("fundura_max_m", 0.0)), int(round(cl.lama * 100.0)),
			float(_medida.get("area_lama_m2", 0.0)), int(round(cl.lama_humida * 100.0))]
	else:
		estado = "rajada %d%% · neve pousada %d%% · AGLOMERADO %d%% · GELO %d%%" % [
			int(round(100.0 * cl.rajada_da_nevasca(cl._tempo) * cl.vento_da_nevasca())), int(round(cl.neve * 100.0)),
			int(round(cl.aglomerado * 100.0)), int(round(cl.gelo * 100.0))]
	_rotulo.text = "ORDEM 41 · %s · perfil %s%s\nvento %.1f m/s → %d° (seta laranja) · %s\nt = %.1f s · %s" % [
		titulo, cl.perfil, quantos, v.length(), int(round(rad_to_deg(atan2(v.y, v.x)))), estado, _t, extra]


# ---------------------------------------------------------------- vídeo: a nevasca

## Do ligar ao aglomerado. A câmara passa pelo obstáculo, pelo canto e pelas figuras, volta ao plano largo
## (o mesmo do início, para comparar) e acaba no Panorama (cantos e bordas cheios, centro varrido, véu).
func _nevasca() -> void:
	var cl = _a.clima
	cl.definir_vento(_vento_rumo, _vento_forca)
	_cam(_a.camera.Modo.FIXA, FOCO_LARGO, 1.15, true)
	_por_seta()
	await _passar(1.5, "câmara Fixa · ANTES (sem clima) · obstáculos e marcas são da bancada")
	await _gravar("nevasca-0-antes.png")
	cl.definir("neve", "forte")
	await _passar(4.0, "a nevasca ligou sem reiniciar a cena · o vento levanta-se")
	await _gravar("nevasca-1-inicio.png")
	await _passar(10.5, "RAJADAS: os flocos inclinam e aceleram juntos (vê a seta e a % da rajada)")
	_cam(_a.camera.Modo.FIXA, Vector3(10.6, 0.0, 6.6), 2.5)
	await _passar(9.0, "de perto · OBSTÁCULO: a neve junta-se na base e na cauda a sotavento")
	await _gravar("nevasca-2-obstaculo.png")
	_cam(_a.camera.Modo.FIXA, Vector3(3.2, 0.0, 3.8), 2.3)
	await _passar(9.0, "de perto · CANTO: o canto e as bordas enchem; as figuras ganham neve do lado abrigado")
	await _gravar("nevasca-3-canto.png")
	_cam(_a.camera.Modo.FIXA, Vector3(14.25, 0.6, 14.0), 3.0)
	await _passar(8.0, "de perto · FIGURA: neve nas costas (sotavento), gelo no contorno e do lado do vento")
	await _gravar("nevasca-4-figura.png")
	_cam(_a.camera.Modo.FIXA, FOCO_LARGO, 1.15)
	await _passar(7.5, "câmara Fixa · AGLOMERADO (o mesmo plano do início) · a grelha e os destaques lêem-se")
	await _gravar("nevasca-5-aglomerado.png")
	_a.camera.definir_modo(_a.camera.Modo.PANORAMA)
	await _passar(7.5, "câmara Panorama · cantos e bordas cheios, centro varrido")
	await _gravar("nevasca-6-panorama.png")
	print("  video nevasca: ", JSON.stringify({"perfil": cl.perfil, "segundos": _t, "flocos": cl.contagem_atual("neve"),
		"veu": cl.contagem_atual("veu"), "neve": cl.neve, "aglomerado": cl.aglomerado, "gelo": cl.gelo}))


# ---------------------------------------------------------------- vídeo: a chuva que alaga

## O lobo anda às voltas dentro da bolsa P1 (movido pela bancada): o anel à volta dos pés.
func _andar_lobo(ligar: bool) -> void:
	var lobo := _no_da_figura("Lobo")
	if lobo == null:
		return
	if not ligar:
		_por_quadro = Callable()
		return
	var centro := Vector3(14.25, 0.0, 14.25)
	var t0 := _t
	_por_quadro = func() -> void:
		var u := _t - t0
		# Anda 2 s, pára 1,5 s (parado, as ondas apagam-se; a andar, voltam).
		var ciclo := fposmod(u, 3.5)
		var fase := floorf(u / 3.5) * 2.0 + minf(ciclo, 2.0)
		lobo.position = centro + Vector3(cos(fase * 0.9) * 1.1 - 1.1, 0.0, sin(fase * 0.9) * 1.1)


func _alaga() -> void:
	var cl = _a.clima
	cl.definir_vento(_vento_rumo, _vento_forca)
	var largo := Vector3(10.5, 0.0, 11.0)
	var perto_p1 := Vector3(14.4, 0.0, 14.6)
	_cam(_a.camera.Modo.FIXA, largo, 1.15, true)
	_por_seta()
	await _passar(1.5, "câmara Fixa · CHÃO SECO (antes) · P1–P4 = as bacias que a bancada deu ao módulo")
	await _gravar("alaga-0-seco.png")
	cl.definir("chuva", "forte")
	await _passar(7.0, "chuva forte ligada sem reiniciar · primeiro o chão encharca (a água só se junta depois)")
	await _gravar("alaga-1-encharcado.png")
	_cam(_a.camera.Modo.FIXA, perto_p1, 2.3)
	await _passar(11.0, "de perto · P1: a bolsa NASCE pequena no ponto baixo e CRESCE, com a lama à frente")
	await _gravar("alaga-2-bolsa-pequena.png")
	_cam(_a.camera.Modo.FIXA, largo, 1.15)
	await _passar(11.0, "câmara Fixa · as bolsas crescem (nível e extensão na etiqueta) · lama à volta")
	await _gravar("alaga-3-a-crescer.png")
	_cam(_a.camera.Modo.FIXA, perto_p1, 2.6)
	_andar_lobo(true)
	await _passar(13.0, "de perto · salpico de ÁGUA (coroa) dentro da bolsa; o lobo anda: ANEL nos pés (só apresentação)")
	await _gravar("alaga-4-pes-na-agua.png")
	_andar_lobo(false)
	_cam(_a.camera.Modo.FIXA, largo, 1.15)
	await _passar(4.5, "câmara Fixa · BOLSAS FORMADAS")
	await _gravar("alaga-5-bolsas-formadas.png")
	_a.camera.definir_modo(_a.camera.Modo.PANORAMA)
	await _passar(4.0, "câmara Panorama · BOLSAS FORMADAS · o campo inteiro")
	await _gravar("alaga-6-panorama.png")
	cl.definir("nenhum")
	_cam(_a.camera.Modo.FIXA, largo, 1.15)
	await _passar(12.0, "A CHUVA PAROU · as bolsas escoam (encolhem para o fundo); a lama fica")
	await _gravar("alaga-7-a-drenar.png")
	_cam(_a.camera.Modo.FIXA, perto_p1, 2.3)
	await _passar(13.0, "de perto · P1 a drenar: a linha de água recua, a lama fica onde a água chegou")
	await _gravar("alaga-8-lama.png")
	await _passar(10.0, "de perto · sem água: a LAMA perde o brilho (fase 2)")
	await _gravar("alaga-9-lama-baca.png")
	_cam(_a.camera.Modo.FIXA, largo, 1.15)
	await _passar(21.0, "câmara Fixa · a LAMA seca e encolhe (fase 3) · o chão também seca")
	await _gravar("alaga-10-a-secar.png")
	await _passar(5.0, "câmara Fixa · seco outra vez")
	await _gravar("alaga-11-seco.png")
	print("  video alaga: ", JSON.stringify({"perfil": cl.perfil, "segundos": _t, "molhado": cl.molhado, "agua": cl.agua, "lama": cl.lama}))


# ---------------------------------------------------------------- vídeo: os climas fracos (a base não regrediu)

func _fracos() -> void:
	var cl = _a.clima
	cl.definir_vento(_vento_rumo, _vento_forca)
	_cam(_a.camera.Modo.FIXA, FOCO_LARGO, 1.15, true)
	_por_seta()
	await _passar(1.0, "câmara Fixa · sem clima")
	cl.definir("chuva", "fraco")
	await _passar(9.0, "CHUVA FRACA · a base: molha, sem bolsas e sem lama (água e lama a 0%)")
	await _gravar("fracos-1-chuva-fraca.png")
	_cam(_a.camera.Modo.FIXA, Vector3(14.25, 0.0, 14.25), 2.6)
	await _passar(5.0, "CHUVA FRACA de perto · em cima da bacia P1: não se junta água")
	await _gravar("fracos-2-chuva-fraca-perto.png")
	_cam(_a.camera.Modo.FIXA, FOCO_LARGO, 1.15)
	cl.definir("neve", "fraco")
	await _passar(12.0, "NEVE FRACA · a base: vento manso, branqueia por igual (aglomerado e gelo a 0%), sem véu")
	await _gravar("fracos-3-neve-fraca.png")
	_cam(_a.camera.Modo.FIXA, Vector3(10.6, 0.0, 6.6), 2.5)
	await _passar(5.0, "NEVE FRACA de perto · obstáculo: sem monte nem cauda")
	await _gravar("fracos-4-neve-fraca-perto.png")
	_a.camera.definir_modo(_a.camera.Modo.PANORAMA)
	await _passar(3.0, "NEVE FRACA · Panorama")
	await _gravar("fracos-5-neve-fraca-panorama.png")
	var limpo: bool = cl.aglomerado == 0.0 and cl.gelo == 0.0 and cl.agua == 0.0 and cl.lama == 0.0 and cl.contagem_atual("veu") == 0
	if not limpo:
		printerr("  FALHA fracos: o clima fraco acumulou estado do forte")
		_falhas += 1
	print("  video fracos: ", JSON.stringify({"perfil": cl.perfil, "segundos": _t, "molhado": cl.molhado, "neve": cl.neve,
		"aglomerado": cl.aglomerado, "gelo": cl.gelo, "agua": cl.agua, "lama": cl.lama, "sem_estado_forte": limpo}))


# ---------------------------------------------------------------- capturas da expansão

func _fotos41() -> void:
	var cl = _a.clima
	cl.definir_vento(_vento_rumo, _vento_forca)
	# NEVASCA em 3 tempos, sempre o mesmo plano (canto e obstáculo marcados).
	_cam(_a.camera.Modo.FIXA, FOCO_LARGO, 1.15, true)
	await _passar(0.5, "câmara Fixa · antes")
	await _gravar("nevasca-tempo-0-antes.png")
	cl.definir("neve", "forte")
	await _passar(5.0, "NEVASCA · tempo 1 de 3: INÍCIO")
	await _gravar("nevasca-tempo-1-inicio.png")
	await _passar(17.0, "NEVASCA · tempo 2 de 3: MEIO")
	await _gravar("nevasca-tempo-2-meio.png")
	await _passar(30.0, "NEVASCA · tempo 3 de 3: AGLOMERADO")
	await _gravar("nevasca-tempo-3-aglomerado.png")
	_cam(_a.camera.Modo.FIXA, Vector3(10.6, 0.0, 6.6), 2.5, true)
	await _passar(1.0, "NEVASCA aglomerada · o obstáculo de perto")
	await _gravar("nevasca-perto-obstaculo.png")
	_cam(_a.camera.Modo.FIXA, Vector3(3.2, 0.0, 3.8), 2.3, true)
	await _passar(1.0, "NEVASCA aglomerada · o canto de perto")
	await _gravar("nevasca-perto-canto.png")
	_cam(_a.camera.Modo.FIXA, Vector3(14.25, 0.6, 14.0), 3.0, true)
	await _passar(1.0, "NEVASCA aglomerada · a figura de perto")
	await _gravar("nevasca-perto-figura.png")
	_a.camera.definir_modo(_a.camera.Modo.PANORAMA)
	_a.camera._saltar()
	await _passar(1.0, "NEVASCA aglomerada · Panorama")
	await _gravar("nevasca-panorama.png")
	# ALAGAMENTO em 3 tempos, sempre o mesmo plano.
	cl.definir("nenhum")
	cl.definir_acumulacao(0.0, 0.0)
	cl.definir_forte(0.0, 0.0, 0.0, 0.0)
	_t = 0.0
	var largo := Vector3(10.5, 0.0, 11.0)
	_cam(_a.camera.Modo.FIXA, largo, 1.15, true)
	await _passar(3.0, "ALAGAMENTO · tempo 1 de 3: SECO")
	await _gravar("alaga-tempo-1-seco.png")
	cl.definir("chuva", "forte")
	await _passar(18.0, "ALAGAMENTO · a meio: as bolsas a crescer")
	await _gravar("alaga-tempo-1b-a-crescer.png")
	_andar_lobo(true)
	await _passar(26.0, "ALAGAMENTO · tempo 2 de 3: BOLSA formada")
	await _gravar("alaga-tempo-2-bolsa.png")
	_cam(_a.camera.Modo.FIXA, Vector3(14.4, 0.0, 14.6), 2.6, true)
	await _passar(2.0, "ALAGAMENTO · a bolsa P1 de perto (o lobo anda: anel nos pés)")
	await _gravar("alaga-perto-bolsa.png")
	_andar_lobo(false)
	_a.camera.definir_modo(_a.camera.Modo.PANORAMA)
	_a.camera._saltar()
	await _passar(1.0, "ALAGAMENTO · bolsas formadas · Panorama")
	await _gravar("alaga-panorama.png")
	cl.definir("nenhum")
	_cam(_a.camera.Modo.FIXA, largo, 1.15, true)
	await _passar(25.0, "ALAGAMENTO · tempo 3 de 3: LAMA (a água escoou, a lama fica)")
	await _gravar("alaga-tempo-3-lama.png")
	_cam(_a.camera.Modo.FIXA, Vector3(14.4, 0.0, 14.6), 2.6, true)
	await _passar(1.0, "ALAGAMENTO · a lama de P1 de perto (ainda a brilhar)")
	await _gravar("alaga-perto-lama.png")
	await _passar(11.0, "ALAGAMENTO · a lama de P1 de perto (baça)")
	await _gravar("alaga-perto-lama-baca.png")
	# As bacias que o módulo sorteia quando ninguém as dá (é o que as arenas de hoje mostram).
	cl.definir_bacias([])
	cl.definir("chuva", "forte")
	cl.definir_acumulacao(1.0, 0.0)
	cl.definir_forte(0.0, 0.0, 1.0)
	_a.camera.definir_modo(_a.camera.Modo.PANORAMA)
	_a.camera._saltar()
	await _passar(2.0, "ALAGAMENTO · as 5 bacias SORTEADAS pelo módulo (sem definir_bacias) · Panorama")
	await _gravar("alaga-bacias-sorteadas.png")


# ---------------------------------------------------------------- medição da expansão

## FPS em tempo real (sem vsync) e draw calls por perfil, com e sem o clima forte formado, em duas câmaras
## (Fixa zoom 1,5 como na Ordem 40, e Panorama: o campo inteiro com tudo à vista). Depois, o crescimento
## medido com a conta do módulo (em passos de 1/30 s, sem render): o alagamento e a nevasca.
func _medir41() -> void:
	var cl = _a.clima
	var perfis: Node = _a.get_node("Perfis")
	cl.definir_vento(_vento_rumo, _vento_forca)
	cl.segundos_transicao = 0.2
	cl.segundos_levantar = 0.2
	var casos := [["nenhum", "fraco", "sem clima"], ["neve", "fraco", "neve fraca (base)"], ["neve", "forte", "NEVASCA formada"],
		["chuva", "fraco", "chuva fraca (base)"], ["chuva", "forte", "CHUVA ALAGADA"]]
	var linhas: Array = []
	var texto := "| Perfil | Câmara | Clima | Partículas | FPS (média) | ms/frame | Draw calls | Primitivas |\n| --- | --- | --- | --- | --- | --- | --- | --- |\n"
	for perfil in ["baixo", "medio", "alto"]:
		perfis.aplicar(perfil)
		for camara in ["fixa", "panorama"]:
			_a.camera.definir_modo(_a.camera.Modo.PANORAMA if camara == "panorama" else _a.camera.Modo.FIXA)
			_a.camera._saltar()
			for caso in casos:
				cl.definir("nenhum")
				cl.definir_acumulacao(0.0, 0.0)
				cl.definir_forte(0.0, 0.0, 0.0, 0.0)
				await create_timer(0.6).timeout
				if not cl.parado():
					printerr("  FALHA medir41: o clima anterior não saiu (", perfil, " ", caso, ")")
					_falhas += 1
				cl.definir(caso[0], caso[1])
				if caso[0] == "chuva":
					cl.definir_acumulacao(1.0 if caso[1] == "forte" else 0.8, 0.0)
					if caso[1] == "forte":
						cl.definir_forte(0.0, 0.0, 1.0)
				elif caso[0] == "neve":
					cl.definir_acumulacao(0.0, 0.9 if caso[1] == "forte" else 0.6)
					if caso[1] == "forte":
						cl.definir_forte(1.0, 1.0, 0.0, 0.0)
				await create_timer(0.8).timeout
				var n := 0
				var chamadas := 0
				var primitivas := 0
				var t0 := Time.get_ticks_usec()
				while Time.get_ticks_usec() - t0 < 2000000:
					await process_frame
					n += 1
					chamadas = maxi(chamadas, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)))
					primitivas = maxi(primitivas, int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)))
				var seg := float(Time.get_ticks_usec() - t0) / 1e6
				var particulas: int = cl.contagem_atual("chuva") + cl.contagem_atual("salpicos") + cl.contagem_atual("neve") + cl.contagem_atual("veu")
				var linha := {"perfil": perfil, "camara": camara, "clima": caso[2], "particulas": particulas, "veu": cl.contagem_atual("veu"),
					"fps": n / seg, "ms": 1000.0 * seg / n, "draw_calls": chamadas, "primitivas": primitivas}
				linhas.append(linha)
				texto += "| %s | %s | %s | %d | %.0f | %.2f | %d | %d |\n" % [perfil, camara, caso[2], particulas, n / seg, 1000.0 * seg / n, chamadas, primitivas]
				print("  medido ", JSON.stringify(linha))
	# ---- o crescimento, com a conta do módulo (passos de 1/30 s, sem esperar pelo relógio)
	perfis.aplicar("alto")
	cl.segundos_transicao = 1.5
	cl.segundos_levantar = 4.0
	var passo := 1.0 / 30.0
	var repor := func() -> void:
		cl.definir("nenhum")
		cl.definir_acumulacao(0.0, 0.0)
		cl.definir_forte(0.0, 0.0, 0.0, 0.0)
	repor.call()
	cl.definir("chuva", "forte")
	var alag: Array = []
	var marcos := {}
	var t := 0.0
	var final_m2 := 0.0
	texto += "\n### Alagamento: chuva forte ligada em t = 0 (chão seco), desligada em t = 50 s\n\n| t (s) | fase | molhado | água | bolsas (m²) | % do campo | fundura máx. (cm) | lama | lama (m²) | brilho da lama |\n| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
	for i in range(1, 30 * 125 + 1):
		if i == 30 * 50 + 1:
			final_m2 = float(cl.medir_alagamento(0.1)["area_agua_m2"])
			cl.definir("nenhum")
		cl.avancar(passo)
		t = i * passo
		var chove := i <= 30 * 50
		if chove and i % 6 == 0:
			var m: Dictionary = cl.medir_alagamento(0.1)
			var a := float(m["area_agua_m2"])
			for marco in [["primeira_agua_s", 0.01], ["bolsa_le_se_1m2_s", 1.0], ["bolsas_5m2_s", 5.0]]:
				if not marcos.has(marco[0]) and a >= float(marco[1]):
					marcos[marco[0]] = t
			if not marcos.has("cheias_s") and cl.agua >= 1.0:
				marcos["cheias_s"] = t
		if not chove:
			if not marcos.has("sem_agua_s") and cl.agua <= 0.0:
				marcos["sem_agua_s"] = t
			if not marcos.has("lama_baca_s") and cl.lama_humida <= 0.0:
				marcos["lama_baca_s"] = t
			if not marcos.has("lama_seca_s") and cl.lama <= 0.0:
				marcos["lama_seca_s"] = t
			if not marcos.has("chao_seco_s") and cl.molhado <= 0.0:
				marcos["chao_seco_s"] = t
		if i % 150 == 0:
			var m2: Dictionary = cl.medir_alagamento(0.1)
			var fase := "chove" if chove else "parou"
			alag.append({"t": t, "fase": fase, "molhado": cl.molhado, "agua": cl.agua, "area_agua_m2": m2["area_agua_m2"],
				"percent_agua": m2["percent_agua"], "fundura_max_m": m2["fundura_max_m"], "lama": cl.lama, "area_lama_m2": m2["area_lama_m2"],
				"lama_humida": cl.lama_humida})
			texto += "| %d | %s | %.2f | %.2f | %.1f | %.1f | %.1f | %.2f | %.1f | %.2f |\n" % [int(round(t)), fase, cl.molhado, cl.agua,
				float(m2["area_agua_m2"]), float(m2["percent_agua"]), 100.0 * float(m2["fundura_max_m"]), cl.lama, float(m2["area_lama_m2"]), cl.lama_humida]
	marcos["area_final_m2"] = final_m2
	texto += "\nMarcos (s): %s\n" % JSON.stringify(marcos)
	print("  alagamento ", JSON.stringify(marcos))
	# ---- a nevasca: quanto há no canto, na cauda do muro, a barlavento dele e no centro aberto
	repor.call()
	for i in 30 * 3:
		cl.avancar(passo)  # o vento deita-se
	cl.definir("neve", "forte")
	var pontos := {"canto": Vector2(0.6, 0.6), "borda": Vector2(0.5, 15.0), "sotavento_do_muro": Vector2(11.0, 6.3),
		"barlavento_do_muro": Vector2(8.6, 6.0), "centro_aberto": Vector2(20.0, 20.0)}
	var nev: Array = []
	texto += "\n### Nevasca: neve forte ligada em t = 0 · neve no ponto (0 = nada, 1 = manto cheio; > 1 = monte)\n\n| t (s) | neve pousada | aglomerado | gelo | canto | borda | sotavento do muro | barlavento do muro | centro aberto |\n| --- | --- | --- | --- | --- | --- | --- | --- | --- |\n"
	for i in range(1, 30 * 75 + 1):
		cl.avancar(passo)
		t = i * passo
		if not marcos.has("aglomerado_cheio_s") and cl.aglomerado >= 1.0:
			marcos["aglomerado_cheio_s"] = t
		if not marcos.has("gelo_cheio_s") and cl.gelo >= 1.0:
			marcos["gelo_cheio_s"] = t
		if i % 150 == 0:
			var l := {"t": t, "neve": cl.neve, "aglomerado": cl.aglomerado, "gelo": cl.gelo}
			for k in pontos:
				l[k] = cl.neve_em(pontos[k])
			nev.append(l)
			texto += "| %d | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f |\n" % [int(round(t)), cl.neve, cl.aglomerado, cl.gelo,
				float(l["canto"]), float(l["borda"]), float(l["sotavento_do_muro"]), float(l["barlavento_do_muro"]), float(l["centro_aberto"])]
	texto += "\nMarcos (s): %s\n" % JSON.stringify(marcos)
	print("  nevasca ", JSON.stringify(marcos))
	repor.call()
	var janela := root.size
	var f := FileAccess.open(_saida.path_join("medicao41.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"render": RenderingServer.get_video_adapter_name(), "janela": [janela.x, janela.y],
		"quadro_do_render": [root.get_texture().get_width(), root.get_texture().get_height()], "vento": [_vento_rumo, _vento_forca],
		"bacias": cl.bacias(), "abrigos": cl.abrigos(), "casos": linhas, "alagamento": alag, "nevasca": nev, "marcos": marcos}, "  "))
	f.close()
	var g := FileAccess.open(_saida.path_join("medicao41.md"), FileAccess.WRITE)
	g.store_string(texto)
	g.close()
