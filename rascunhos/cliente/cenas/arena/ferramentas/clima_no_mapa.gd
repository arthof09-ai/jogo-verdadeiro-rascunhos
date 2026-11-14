extends SceneTree
## clima_no_mapa.gd — Ordem 42, parte 2. A PROVA DO CLIMA FORTE SOBRE O MAPA INTEGRADO: a arena do jogo
## (cenas/arena/arena.tscn, com o mapa da floresta), a nevasca e a chuva que alaga do módulo do clima
## (arte/clima, Ordens 40/41). As bacias do alagamento são os pontos baixos REAIS do relevo
## (cenas/arena/bacias_do_relevo.gd) e os abrigos da nevasca são os obstáculos REAIS do mapa (os 8 mais perto
## da zona). Etiqueta no ecrã (o que é, o tempo, o vento, o estado do clima) e capturas em 3 tempos, com o
## tempo e a câmara no nome do ficheiro. O combate é de DEMONSTRAÇÃO (posto no Estado por esta ferramenta).
##
##   VÍDEO + CAPTURAS (o Godot grava o .avi, quadro a quadro, a 30 q/s certos):
##     godot --path cliente --resolution 1920x1080 --fixed-fps 30 --write-movie <pasta>/nevasca.avi \
##       -s res://cenas/arena/ferramentas/clima_no_mapa.gd -- --modo=nevasca --saida=<pasta>
##     (o mesmo com --modo=alaga)
## Precisa de janela (GPU): NÃO corre com --headless.

const CENA := "res://cenas/arena/arena.tscn"
const DT := 1.0 / 30.0

var _modo := "nevasca"
var _saida := ""
var _arena: Node3D
var _vp: SubViewport
var _rotulo: Label
var _t := 0.0
var _medidas: Dictionary = {"tempos": []}
var _passos: Array = []   # [t, Callable]
var _feitos := 0
var _fim := 0.0


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modo="):
			_modo = a.trim_prefix("--modo=")
		elif a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
	if _saida == "":
		_saida = ProjectSettings.globalize_path("res://cenas/arena/capturas/clima")
	DirAccess.make_dir_recursive_absolute(_saida)
	process_frame.connect(_comecar, CONNECT_ONE_SHOT)


func _s(v: float, casas: int = 1) -> String:
	var t := ("%." + str(casas) + "f") % absf(v)
	return ("+" if v >= 0.0 else "-") + t.replace(".", ",")


func _n(v: float, casas: int = 2) -> String:
	return (("%." + str(casas) + "f") % v).replace(".", ",")


# ------------------------------------------------------------------ combate de demonstração

func _figura(id: String, nome: String, x: int, y: int, lado: String, ori: String = "N") -> Dictionary:
	return {"id": id, "nomePublico": nome, "x": x, "y": y, "lado": lado, "orientacao": ori, "visivel": "de_pe"}


func _montar_combate() -> void:
	var est = root.get_node("/root/Estado")
	var figuras := [
		_figura("fA", "Ong", 10, 10, "jogadora"),
		_figura("fB", "Lia", 8, 7, "jogadora", "L"),       # na cova rasa do prado (o pé na água, no alagamento)
		_figura("fC", "Lobo", 13, 6, "criatura", "S"),
		_figura("fD", "Orc", 12, 13, "criatura", "O"),
		_figura("fF", "Batedor", 1, 1, "criatura", "S"),  # no canto NO, ao pé dos menires
		_figura("fH", "Kai", 2, 17, "jogadora", "N"),      # no canto SO, ao pé do tronco tombado
	]
	est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "demo-42-clima", "seq": 1, "revision": 5,
		"fase": "combate", "rodada": 1, "mapa": {"largura": 20, "altura": 20, "casaM": 1.5},
		"figuras": figuras, "vezId": "fA", "propria": {"figuraId": "fA"}, "ambiente": {}})


# ------------------------------------------------------------------ câmara e etiqueta

func _mesa(modo: int, foco: Vector3, rumo: float, incl: float, zoom: float) -> void:
	var cam = _arena.camera
	cam.definir_modo(modo)
	if modo == 1:
		cam.rumo = rumo
		cam.inclinacao = incl
	cam.foco = foco
	cam._limitar()
	cam.definir_zoom(zoom)
	cam._saltar()


func _nome_camera() -> String:
	var cam = _arena.camera
	var f: Vector3 = cam._foco_alvo()
	return "%s_foco-x%s-z%s_rumo%s_incl%s_dist%sm" % [["FIXA", "360", "PANORAMA"][cam.modo], _s(f.x), _s(f.z),
		_s(cam._rumo_alvo(), 0), _s(cam._incl_alvo(), 0), _s(cam._dist_alvo())]


func _estado_texto() -> String:
	var c = _arena.clima
	var v: Vector2 = c.vento_do_frame()
	var base := "ORDEM 42 · %s SOBRE O MAPA INTEGRADO · t = %s s · vento %s m/s" % [
		"NEVASCA (neve forte)" if _modo == "nevasca" else "CHUVA QUE ALAGA (chuva forte)", _n(_t, 1), _n(v.length(), 1)]
	if _modo == "nevasca":
		base += " · neve %s · aglomerado %s · gelo %s · abrigos do mapa: %d" % [_n(c.neve), _n(c.aglomerado), _n(c.gelo), c.abrigos().size()]
	else:
		base += " · molhado %s · água %s · lama %s · bacias do relevo: %d" % [_n(c.molhado), _n(c.agua), _n(c.lama), c.bacias().size()]
	return base + "\nDEMONSTRAÇÃO: as figuras e o tempo são da bancada; as bacias e os abrigos são os do relevo e dos obstáculos reais do mapa."


func _capturar(nome: String) -> void:
	await process_frame
	var img := _vp.get_texture().get_image()
	var ficheiro := "%s_t%02ds_%s.jpg" % [nome, int(round(_t)), _nome_camera()]
	img.save_jpg(_saida.path_join(ficheiro), 0.92)
	var c = _arena.clima
	var m := {"captura": ficheiro, "t": _t, "neve": c.neve, "aglomerado": c.aglomerado, "gelo": c.gelo,
		"molhado": c.molhado, "agua": c.agua, "lama": c.lama}
	if _modo == "alaga":
		m["alagamento_na_zona"] = c.medir_alagamento(0.1)
	(_medidas["tempos"] as Array).append(m)
	print("[clima42] %s" % ficheiro)


# ------------------------------------------------------------------ o guião

func _comecar() -> void:
	var rede = root.get_node("/root/Rede")
	rede._ativo = true
	_montar_combate()
	# A cena desenha-se num SubViewport de 1920×1080 (seja qual for a janela); a janela mostra-o (e é a
	# janela que o --write-movie grava).
	_vp = SubViewport.new()
	_vp.size = Vector2i(1920, 1080)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	var mostra := TextureRect.new()
	mostra.texture = _vp.get_texture()
	mostra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mostra.stretch_mode = TextureRect.STRETCH_SCALE
	mostra.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(mostra)
	_arena = (load(CENA) as PackedScene).instantiate()
	_vp.add_child(_arena)
	var camada := CanvasLayer.new()
	camada.layer = 100
	_vp.add_child(camada)
	_rotulo = Label.new()
	_rotulo.position = Vector2(110, 18)
	var ls := LabelSettings.new()
	ls.font_size = 22
	ls.outline_size = 6
	ls.outline_color = Color(0, 0, 0, 0.85)
	_rotulo.label_settings = ls
	camada.add_child(_rotulo)
	await process_frame
	await process_frame
	_arena._perfis.aplicar("alto")
	var c = _arena.clima
	var cA: Vector3 = _arena.centro_casa(Vector2i(10, 10))
	_medidas["bacias"] = []
	var niveis: Array = c.bacias_nivel()
	for i in c.bacias().size():
		var b: Vector4 = c.bacias()[i]
		(_medidas["bacias"] as Array).append({"x": b.x, "z": b.y, "raio": b.z, "fundura": b.w, "nivel": niveis[i]})
	_medidas["abrigos"] = []
	for n in _arena.get_node("Grelha/AbrigosDoMapa").get_children():
		(_medidas["abrigos"] as Array).append({"nome": String(n.name), "x": n.position.x, "z": n.position.z,
			"tamanho": [(n.mesh as BoxMesh).size.x, (n.mesh as BoxMesh).size.y, (n.mesh as BoxMesh).size.z]})
	_mesa(2, cA, 0.0, 78.0, 1.0)
	if _modo == "nevasca":
		_passos = [
			[0.5, func(): _capturar("nevasca_tempo-0-antes")],
			[1.5, func():
				c.definir_vento(20.0, 3.0)
				c.definir("neve", "forte")],
			[9.0, func(): _capturar("nevasca_tempo-1-inicio")],
			[22.0, func(): _capturar("nevasca_tempo-2-meio")],
			[38.0, func(): _capturar("nevasca_tempo-3-aglomerado")],
			[38.5, func(): _mesa(1, _arena.centro_casa(Vector2i(1, 2)), -150.0, 30.0, 1.6)],
			[40.5, func(): _capturar("nevasca_perto-menires-e-canto-NO")],
			[41.0, func(): _mesa(1, _arena.centro_casa(Vector2i(1, 18)), -60.0, 30.0, 1.6)],
			[43.0, func(): _capturar("nevasca_perto-tronco-tombado-e-canto-SO")],
		]
		_fim = 44.0
	else:
		_passos = [
			[0.5, func(): _capturar("alaga_tempo-0-seco")],
			[1.5, func():
				c.definir_vento(20.0, 2.5)
				c.definir("chuva", "forte")],
			[16.0, func(): _capturar("alaga_tempo-1-a-crescer")],
			[30.0, func(): _capturar("alaga_tempo-2-meio")],
			[44.0, func(): _capturar("alaga_tempo-3-bolsas-cheias")],
			[44.5, func(): _mesa(1, Vector3(-4.0, _arena.altura_chao(-4.0, -6.0), -6.0), 170.0, 32.0, 1.5)],
			[46.5, func(): _capturar("alaga_perto-covas-do-prado")],
			[47.0, func(): _mesa(1, Vector3(-14.0, _arena.altura_chao(-14.0, 8.0), 8.0), -110.0, 32.0, 1.6)],
			[49.0, func(): _capturar("alaga_perto-boca-da-garganta")],
		]
		_fim = 50.0
	process_frame.connect(_quadro)


func _quadro() -> void:
	_t += DT
	_rotulo.text = _estado_texto()
	while _feitos < _passos.size() and _t >= float(_passos[_feitos][0]):
		var f: Callable = _passos[_feitos][1]
		_feitos += 1
		f.call()
	if _t >= _fim:
		process_frame.disconnect(_quadro)
		var f := FileAccess.open(_saida.path_join("clima_%s_medicao.json" % _modo), FileAccess.WRITE)
		f.store_string(JSON.stringify(_medidas, "  "))
		f.close()
		print("[clima42] fim %s: %d capturas" % [_modo, (_medidas["tempos"] as Array).size()])
		quit(0)
