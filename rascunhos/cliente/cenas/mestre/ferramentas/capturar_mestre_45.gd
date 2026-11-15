extends SceneTree
## capturar_mestre_45.gd — Ordem 45. As CAPTURAS ROTULADAS do ecrã do Mestre (cenas/mestre/mestre.tscn) sobre o mapa
## da floresta: a vista normal, a neve (nevasca) e o alagamento (chuva forte). O clima liga-se pelo caminho do
## jogo: o clima que o Mestre escolhe na aba Ambiente chega na vista (`mestre.ambiente.clima`) e o ecrã dele segue-o
## (arena_mestre.gd `CLIMA_DO_AMBIENTE`). A vista é a da fixture do servidor (cenário «mestre»), com as figuras
## postas em casas que mostram o relevo (DEMONSTRAÇÃO). O tempo anda a passo fixo (--fixed-fps 30).
##
##   godot --path cliente --resolution 1920x1080 --fixed-fps 30 \
##     -s res://cenas/mestre/ferramentas/capturar_mestre_45.gd -- --modo=normal|neve|alaga --saida=<pasta>
## Precisa de janela (GPU): NÃO corre com --headless.

const CENA := "res://cenas/mestre/mestre.tscn"
const DT := 1.0 / 30.0

var _modo := "normal"
var _saida := ""
var _m  # o ecrã do Mestre (mestre.gd)
var _a  # a arena 3D dele (arena_mestre.gd)
var _vista: Dictionary = {}
var _rotulo: Label
var _t := 0.0
var _passos: Array = []  # [t, Callable]
var _feitos := 0
var _fim := 0.0
var _rotulo_extra := ""
var _medidas: Dictionary = {"capturas": []}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modo="):
			_modo = a.trim_prefix("--modo=")
		elif a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
	if _saida == "":
		_saida = OS.get_user_data_dir().path_join("mestre45")
	DirAccess.make_dir_recursive_absolute(_saida)
	process_frame.connect(_comecar, CONNECT_ONE_SHOT)


func _n(v: float, casas: int = 2) -> String:
	return (("%." + str(casas) + "f") % v).replace(".", ",")


func _comecar() -> void:
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var fx = JSON.parse_string(FileAccess.get_file_as_string(p))
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede.papel = "mestre"
	root.size = Vector2i(1920, 1080)
	_vista = (fx["mestre"]["vista"] as Dictionary).duplicate(true)
	# DEMONSTRAÇÃO: as quatro figuras da fixture em casas que mostram o relevo e o clima.
	var casas := {"heroina-teste": Vector2i(1, 1), "aliada-teste": Vector2i(8, 7), "orc-teste": Vector2i(10, 10), "lobo-teste": Vector2i(2, 17)}
	for f in _vista["mestre"]["figuras"]:
		var c = casas.get(str(f.get("fichaId", "")))
		if c is Vector2i:
			f["x"] = c.x
			f["y"] = c.y
			f["colocada"] = true
	_m = (load(CENA) as PackedScene).instantiate()
	_m.enviar_fn = func(_t2, _c, _r): return ""
	_m.pedir_vista_fn = func(): pass
	root.add_child(_m)
	await process_frame
	await process_frame
	_m._aviso_entendido()
	_m.aplicar_vista(_vista)
	_m._ao_redimensionar()
	_a = _m._arena
	var camada := CanvasLayer.new()
	camada.layer = 100
	root.add_child(camada)
	_rotulo = Label.new()
	_rotulo.position = Vector2(18, 1000)
	var ls := LabelSettings.new()
	ls.font_size = 20
	ls.outline_size = 6
	ls.outline_color = Color(0, 0, 0, 0.9)
	_rotulo.label_settings = ls
	camada.add_child(_rotulo)
	var c_ola: Vector3 = _a.centro_da_casa(Vector2i(10, 10))
	_mesa(2, c_ola, 0.0, 78.0, 1.0)
	match _modo:
		"normal":
			_passos = [
				[1.0, func(): _capturar("M01_vista-normal_ecra-do-mestre_panorama")],
				[1.1, func(): _mesa(0, _a.centro_da_casa(Vector2i(10, 10)), 0.0, 0.0, 1.5)],
				[2.5, func(): _capturar("M02_vista-normal_ecra-do-mestre_camara-fixa")],
				[2.6, func():
					_m._alternar_folha()
					_mesa(1, _a.centro_da_casa(Vector2i(1, 1)), 45.0, 30.0, 2.6)],
				[4.0, func(): _capturar("M03_vista-normal_folha-encolhida_encosta-do-outeiro-NO_pe-das-figuras")],
				[4.1, func(): _mesa(1, _a.centro_da_casa(Vector2i(9, 9)), 135.0, 18.0, 0.9)],
				[5.5, func(): _capturar("M04_vista-normal_folha-encolhida_360-rasante")],
				[5.6, func(): _m._livre.entrar_botao.pressed.emit()],  # pelo botão do ecrã, como o Mestre
				[7.0, func(): _capturar("M05_vista-normal_camara-livre-do-mestre_olhos-a-1,6-do-relevo")],
				[7.1, func(): _m._livre.sair_botao.pressed.emit()],
			]
			_fim = 7.5
		"neve":
			_passos = [
				[0.5, func(): _capturar("N01_neve_tempo-0-antes")],
				[1.5, func(): _clima_de_jogo("neve")],
				[9.0, func(): _capturar("N02_neve_tempo-1-inicio")],
				[22.0, func(): _capturar("N03_neve_tempo-2-meio")],
				[38.0, func(): _capturar("N04_neve_tempo-3-aglomerado")],
				[38.1, func():
					_m._alternar_folha()
					_mesa(1, _a.centro_da_casa(Vector2i(1, 2)), -150.0, 30.0, 1.6)],
				[40.0, func(): _capturar("N05_neve_folha-encolhida_perto-menires-e-canto-NO")],
				[40.1, func(): _mesa(1, _a.centro_da_casa(Vector2i(1, 18)), -60.0, 30.0, 1.6)],
				[42.0, func(): _capturar("N06_neve_folha-encolhida_perto-tronco-tombado-e-canto-SO")],
			]
			_fim = 42.5
		_:
			_passos = [
				[0.5, func(): _capturar("A01_alaga_tempo-0-seco")],
				[1.5, func(): _clima_de_jogo("tempestade")],
				[16.0, func(): _capturar("A02_alaga_tempo-1-a-crescer")],
				[30.0, func(): _capturar("A03_alaga_tempo-2-meio")],
				[44.0, func(): _capturar("A04_alaga_tempo-3-bolsas-cheias")],
				[44.1, func():
					_m._alternar_folha()
					_mesa(1, Vector3(-4.0, _a.altura_chao(-4.0, -6.0), -6.0), 170.0, 32.0, 1.5)],
				[46.0, func(): _capturar("A05_alaga_folha-encolhida_perto-covas-do-prado")],
				[46.1, func(): _mesa(1, Vector3(-14.0, _a.altura_chao(-14.0, 8.0), 8.0), -110.0, 32.0, 1.6)],
				[48.0, func(): _capturar("A06_alaga_folha-encolhida_perto-boca-da-garganta")],
			]
			_fim = 48.5
	process_frame.connect(_quadro)


## O clima de jogo muda como mudaria em jogo: o Mestre escolhe-o, o servidor manda a vista, o ecrã segue-a.
func _clima_de_jogo(nome: String) -> void:
	_vista["mestre"]["ambiente"]["clima"] = nome
	_m.aplicar_vista(_vista)


func _mesa(modo: int, foco: Vector3, rumo: float, incl: float, zoom: float) -> void:
	var cam = _a.camera
	cam.definir_modo(modo)
	if modo == 1:
		cam.rumo = rumo
		cam.inclinacao = incl
	cam.foco = foco
	cam._limitar()
	cam.definir_zoom(zoom)
	cam._saltar()


func _estado_texto() -> String:
	var c = _a.clima
	var amb := str(_vista["mestre"]["ambiente"].get("clima", "—"))
	var base := "ORDEM 45 · ECRÃ DO MESTRE (só o Mestre vê) · %s · t = %s s · clima de jogo «%s» → ecrã: %s %s" % [
		{"normal": "VISTA NORMAL", "neve": "NEVE (nevasca)", "alaga": "ALAGAMENTO (chuva forte)"}.get(_modo, _modo), _n(_t, 1), amb, c.tipo,
		c.intensidade if c.tipo != "nenhum" else ""]
	if c.tipo == "neve" or c.neve > 0.0:
		base += " · neve %s · aglomerado %s · gelo %s · abrigos do mapa %d" % [_n(c.neve), _n(c.aglomerado), _n(c.gelo), c.abrigos().size()]
	elif c.tipo == "chuva" or c.molhado > 0.0:
		base += " · molhado %s · água %s · lama %s · bacias do relevo %d" % [_n(c.molhado), _n(c.agua), _n(c.lama), c.bacias().size()]
	else:
		base += " · mapa da floresta, grelha %d×%d de %s m, origem (%s; %s)" % [_a.largura, _a.altura, _n(_a.casa_m, 1), _n(_a.origem.x, 1), _n(_a.origem.y, 1)]
	return base + "\nDEMONSTRAÇÃO: as figuras são da fixture do servidor, postas em casas que mostram o relevo; o céu, o sol, as bacias e os abrigos são os do mapa."


func _capturar(nome: String) -> void:
	await process_frame
	var img := root.get_texture().get_image()
	var ficheiro := "%s.png" % nome
	img.save_png(_saida.path_join(ficheiro))
	var c = _a.clima
	var m := {"captura": ficheiro, "t": _t, "clima_de_jogo": _vista["mestre"]["ambiente"].get("clima"), "tipo": c.tipo,
		"intensidade": c.intensidade, "neve": c.neve, "aglomerado": c.aglomerado, "gelo": c.gelo, "molhado": c.molhado,
		"agua": c.agua, "lama": c.lama, "bacias": c.bacias().size(), "abrigos": c.abrigos().size(),
		"camara_livre": _a.camara_livre_ativa()}
	if _modo == "alaga":
		m["alagamento_na_zona"] = c.medir_alagamento(0.1)
	(_medidas["capturas"] as Array).append(m)
	print("[mestre45] %s" % ficheiro)


func _quadro() -> void:
	_t += DT
	_rotulo.text = _estado_texto()
	while _feitos < _passos.size() and _t >= float(_passos[_feitos][0]):
		var f: Callable = _passos[_feitos][1]
		_feitos += 1
		f.call()
	if _t >= _fim:
		process_frame.disconnect(_quadro)
		var f := FileAccess.open(_saida.path_join("mestre45_%s_medicao.json" % _modo), FileAccess.WRITE)
		f.store_string(JSON.stringify(_medidas, "  "))
		f.close()
		print("[mestre45] fim %s: %d capturas" % [_modo, (_medidas["capturas"] as Array).size()])
		quit(0)
