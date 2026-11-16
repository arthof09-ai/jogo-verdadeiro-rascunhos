extends SceneTree
## chuva_no_mapa.gd — Ordem 64. A PROVA DA CHUVA SOBRE A ARENA INTEGRADA, a cair com o VENTO DO MUNDO (o do
## mapa, Ordem 43: o mesmo que dobra a relva e as copas). A arena da jogadora (cenas/arena/arena.tscn, com o
## mapa da floresta), um combate de DEMONSTRAÇÃO com figuras e as casas do «Mover» destacadas (postos no Estado
## por esta ferramenta, como na bancada da Ordem 40), a chuva do módulo arte/clima. Etiqueta no ecrã (o que é,
## o tempo, o vento do mundo, a inclinação da chuva, o molhado) e a SETA do vento do mundo desenhada no chão.
## Só apresentação: nada disto passa pelo servidor.
##
##   VÍDEO (o Godot grava o .ogv, quadro a quadro, a 30 q/s certos — leve, sem ffmpeg):
##     godot --path cliente --resolution 960x540 --fixed-fps 30 --write-movie <pasta>/chuva-fraca.ogv \
##       -s res://cenas/arena/ferramentas/chuva_no_mapa.gd -- --modo=fraca --saida=<pasta>
##     (o mesmo com --modo=forte e --modo=comutar)
##   CAPTURAS do chão seco/molhado (mesma câmara, antes e depois):
##     godot --path cliente --resolution 1600x900 --fixed-fps 30 -s res://cenas/arena/ferramentas/chuva_no_mapa.gd \
##       -- --modo=fotos --saida=<pasta>
##   MEDIÇÃO (FPS e draw calls, sem vsync, por perfil × sem chuva / fraca / forte):
##     godot --path cliente --resolution 1920x1080 -s res://cenas/arena/ferramentas/chuva_no_mapa.gd \
##       -- --modo=medir --saida=<pasta>
## Opções: --perfil=baixo|medio|alto (vídeos e fotos; por omissão «alto»).
## Precisa de janela (GPU): NÃO corre com --headless.

const CENA := "res://cenas/arena/arena.tscn"
const VentoMundo := preload("res://mapa/floresta/vento_mundo.gd")
const Clima := preload("res://arte/clima/clima.gd")
const DT := 1.0 / 30.0

var _modo := "fraca"
var _saida := ""
var _perfil := "alto"
var _arena: Node3D
var _rotulo: Label
var _seta: Control
var _t := 0.0
var _passos: Array = []   # [t, Callable]
var _feitos := 0
var _fim := 0.0
var _nota := ""
var _medidas: Dictionary = {"capturas": [], "amostras": []}
# medição
var _med_fila: Array = []
var _med_atual: Dictionary = {}
var _med_ticks := 0
var _med_quadros := 0
var _med_dc := 0
var _med_prim := 0
var _med_espera := 0.0


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modo="):
			_modo = a.trim_prefix("--modo=")
		elif a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
		elif a.begins_with("--perfil="):
			_perfil = a.trim_prefix("--perfil=")
		elif a.begins_with("--qualidade="):
			# A qualidade do vídeo gravado (0..1): os vídeos da prova são leves (o disco da bancada é curto).
			ProjectSettings.set_setting("editor/movie_writer/video_quality", float(a.trim_prefix("--qualidade=")))
	if _saida == "":
		_saida = ProjectSettings.globalize_path("res://cenas/arena/capturas/chuva")
	DirAccess.make_dir_recursive_absolute(_saida)
	process_frame.connect(_comecar, CONNECT_ONE_SHOT)


func _n(v: float, casas: int = 2) -> String:
	return (("%." + str(casas) + "f") % v).replace(".", ",")


# ------------------------------------------------------------------ combate de demonstração

func _figura(id: String, nome: String, x: int, y: int, lado: String, ori: String = "N") -> Dictionary:
	return {"id": id, "nomePublico": nome, "x": x, "y": y, "lado": lado, "orientacao": ori, "visivel": "de_pe"}


func _montar_combate() -> void:
	var rede = root.get_node("/root/Rede")
	var est = root.get_node("/root/Estado")
	rede.papel = "jogadora"
	rede.estado_ligacao = rede.Ligacao.NA_MESA
	rede._ativo = true  # a arena chama Rede.iniciar(); com isto não vai ao lobby (como o testes/hud_acoes.gd)
	est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "demo-64-chuva", "seq": 1, "revision": 5,
		"fase": "combate", "rodada": 1, "mapa": {"largura": 20, "altura": 20, "casaM": 1.5},
		"iniciativa": ["fA", "fB", "fC", "fD", "fE"], "vezId": "fA", "ambiente": {},
		"figuras": [
			_figura("fA", "Ong", 9, 10, "jogadora"),
			_figura("fB", "Lia", 6, 8, "jogadora", "L"),
			_figura("fC", "Lobo", 12, 8, "criatura", "S"),
			_figura("fD", "Orc", 13, 11, "criatura", "O"),
			_figura("fE", "Kai", 4, 15, "jogadora", "N"),
		],
		"propria": {"figuraId": "fA", "paLivre": 40, "estadoMorte": null, "ficha": {}}})


func _mostrar_mover() -> void:
	var est = root.get_node("/root/Estado")
	var movimentos: Array = []
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if absi(dx) + absi(dy) in [1, 2]:
				movimentos.append({"x": 9 + dx, "y": 10 + dy, "custoM": 1.5 * float(absi(dx) + absi(dy))})
	est.receber_opcoes({"v": 2, "type": "ROOM_OPTIONS", "revision": 5, "vezId": "fA", "orcamentoM": 9.0,
		"mover": movimentos, "ataques": [], "consumiveis": [], "acoes": ["encerrar"], "reacoes": []})
	_arena.definir_modo(_arena.Modo.MOVER)  # as casas do «Mover» destacadas: têm de continuar a ler-se


# ------------------------------------------------------------------ vento, câmara e etiqueta

func _vento() -> Node:
	return _arena.mapa.vento


## O vento do mundo no plano do chão (x, z), unitário (para onde sopra).
func _rumo_mundo() -> Vector2:
	var w: Vector3 = _vento().vetor()
	var d := Vector2(w.x, w.z)
	return d.normalized() if d.length() > 1e-5 else Vector2.RIGHT


## A câmara 360 de lado para o vento: o vento do mundo vai para a DIREITA do ecrã (a inclinação vê-se inteira).
func _camera_de_lado(foco: Vector3, incl: float, zoom: float) -> void:
	var w := _rumo_mundo()
	var rumo := rad_to_deg(atan2(-w.y, w.x))
	var cam = _arena.camera
	cam.definir_modo(1)
	cam.rumo = rumo
	cam.inclinacao = incl
	cam.foco = foco
	cam._limitar()
	cam.definir_zoom(zoom)
	cam._saltar()


func _camera_do_jogo() -> void:
	var cam = _arena.camera
	cam.definir_modo(0)
	cam.foco = _arena.centro_casa(Vector2i(10, 10))
	cam._limitar()
	cam.repor_zoom()
	cam._saltar()


func _estado_texto() -> String:
	var c = _arena.clima
	var vm = _vento()
	var v: Dictionary = vm.vento_actual()
	var vc: Vector2 = c.vento_do_frame("chuva")
	var queda: float = float(Clima.QUEDA["chuva"][c.intensidade])
	var incl := rad_to_deg(atan2(vc.length(), queda))
	var nome := "SEM CHUVA"
	if c.tipo == "chuva":
		nome = "CHUVA %s" % ("FORTE" if c.intensidade == "forte" else "FRACA")
	var l1 := "ORDEM 64 · %s · arena integrada · t = %s s · perfil %s · %d gotas + %d salpicos" % [
		nome, _n(_t, 1), _perfil.capitalize(), c.contagem_atual("chuva"), c.contagem_atual("salpicos")]
	var l2 := "vento do MUNDO (o da relva): sopra para %s · %s m/s · rajada %s  →  a chuva segue-o: %s m/s, inclina %s° · chão molhado %s%s" % [
		VentoMundo.rumo(float(v["azimute_para"])), _n(float(v["velocidade_ms"]), 1), _n(float(v["rajada"])),
		_n(vc.length(), 1), _n(incl, 0), _n(c.molhado), (" · água %s" % _n(c.agua)) if c.agua > 0.0 else ""]
	var l3 := "DEMONSTRAÇÃO: figuras e casas do Mover postas pela bancada; o vento e a hora são os do mapa. Seta amarela = vento do mundo."
	if _nota != "":
		l3 = _nota + "\n" + l3
	return l1 + "\n" + l2 + "\n" + l3


## A seta do vento do mundo, desenhada por cima, ancorada no chão perto do centro do campo.
func _desenhar_seta() -> void:
	var cam: Camera3D = _arena.camera
	if cam == null or _arena.mapa == null:
		return
	var w := _rumo_mundo()
	var c3: Vector3 = _arena.centro_casa(Vector2i(15, 6)) + Vector3(0.0, 0.3, 0.0)  # uma casa livre, longe da etiqueta
	var p3 := c3 + Vector3(w.x, 0.0, w.y) * 3.0
	if cam.is_position_behind(c3) or cam.is_position_behind(p3):
		return
	var a := cam.unproject_position(c3)
	var b := cam.unproject_position(p3)
	var d := (b - a)
	if d.length() < 4.0:
		return
	var u := d.normalized()
	var n := Vector2(-u.y, u.x)
	var cor := Color(1.0, 0.86, 0.1, 0.95)
	_seta.draw_line(a, b, Color(0, 0, 0, 0.7), 9.0, true)
	_seta.draw_line(a, b, cor, 5.0, true)
	_seta.draw_colored_polygon(PackedVector2Array([b + u * 16.0, b + n * 11.0, b - n * 11.0]), cor)


func _capturar(nome: String) -> void:
	await process_frame
	var img := root.get_texture().get_image()
	var ficheiro := "%s.jpg" % nome
	img.save_jpg(_saida.path_join(ficheiro), 0.9)
	var c = _arena.clima
	var w: Vector3 = _vento().vetor()
	(_medidas["capturas"] as Array).append({"captura": ficheiro, "t": _t, "tipo": c.tipo, "intensidade": c.intensidade,
		"molhado": c.molhado, "agua": c.agua, "gotas": c.contagem_atual("chuva"), "salpicos": c.contagem_atual("salpicos"),
		"vento_mundo": [w.x, w.z], "vento_chuva": [c.vento_do_frame("chuva").x, c.vento_do_frame("chuva").y]})
	print("[chuva64] %s" % ficheiro)


# ------------------------------------------------------------------ o guião

func _comecar() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED if _modo == "medir" else DisplayServer.VSYNC_ENABLED)
	_montar_combate()
	_arena = (load(CENA) as PackedScene).instantiate()
	root.add_child(_arena)
	var camada := CanvasLayer.new()
	camada.layer = 100
	root.add_child(camada)
	_seta = Control.new()
	_seta.set_anchors_preset(Control.PRESET_FULL_RECT)
	_seta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seta.draw.connect(_desenhar_seta)
	camada.add_child(_seta)
	_rotulo = Label.new()
	# Abaixo do ⚙ e da FICHA do HUD (o topo do ecrã é deles); letra grande, para sobreviver à compressão do vídeo.
	var vs := root.get_visible_rect().size  # o tamanho do ecrã nas coordenadas do HUD (o projecto estica)
	_rotulo.position = Vector2(14, 0.15 * vs.y)
	_rotulo.size = Vector2(vs.x - 28.0, 0.0)
	_rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ls := LabelSettings.new()
	ls.font_size = maxi(11, int(round(0.021 * vs.y)))
	ls.outline_size = 5
	ls.outline_color = Color(0, 0, 0, 0.9)
	_rotulo.label_settings = ls
	camada.add_child(_rotulo)
	await process_frame
	await process_frame
	_arena._aplicar_perfil(_perfil)
	_mostrar_mover()
	var c = _arena.clima
	c.desligar()
	c.definir_acumulacao(0.0, 0.0)
	var foco: Vector3 = _arena.centro_casa(Vector2i(9, 10))
	_camera_do_jogo()
	match _modo:
		"fraca", "forte":
			var nome := "chuva-" + _modo
			var i := "fraco" if _modo == "fraca" else "forte"
			_passos = [
				[0.0, func(): _nota = "SECO: a câmara do jogo, antes da chuva"],
				[1.5, func():
					c.definir("chuva", i)
					_nota = "%s: liga sem reiniciar a cena; a câmara do jogo enquadra o campo inteiro" % nome.to_upper()],
				[8.0, func():
					_camera_de_lado(foco, 24.0, 1.7)
					_nota = "de lado para o vento do mundo (vai para a direita do ecrã): a chuva inclina com ele; o chão molha"],
				[14.0, func():
					_camera_de_lado(_arena.centro_casa(Vector2i(12, 9)), 14.0, 2.6)
					_nota = "rasante, perto das figuras: o chão molhado reflecte, os pingos batem, as figuras brilham"],
				[19.0, func(): _camera_do_jogo(); _nota = "%s: de volta à câmara do jogo — grelha, casas do Mover e figuras lêem-se" % nome.to_upper()],
			]
			_fim = 23.0
		"comutar":
			_passos = [
				[0.0, func(): _camera_de_lado(foco, 26.0, 1.3); _nota = "SECO"],
				[1.0, func(): c.definir("chuva", "fraco"); _nota = "CHUVA FRACA (sem reiniciar)"],
				[6.0, func(): c.definir("chuva", "forte"); _nota = "→ CHUVA FORTE (sem reiniciar)"],
				[11.0, func(): c.definir("chuva", "fraco"); _nota = "→ CHUVA FRACA (sem reiniciar)"],
				[15.0, func(): c.desligar(); _nota = "→ DESLIGADA: as gotas saem; o chão seca devagar (40 s)"],
			]
			_fim = 19.0
		"fotos":
			_passos = [
				[1.0, func(): _camera_do_jogo(); _nota = "SECO — a câmara do jogo"],
				[1.5, func(): _capturar("chao-0-seco_camera-do-jogo")],
				[2.0, func(): _camera_de_lado(_arena.centro_casa(Vector2i(12, 9)), 16.0, 2.4); _nota = "SECO — rasante, perto"],
				[2.5, func(): _capturar("chao-0-seco_rasante")],
				[3.0, func(): c.definir("chuva", "forte"); _camera_do_jogo(); _nota = "CHUVA FORTE a molhar"],
				[13.0, func(): _capturar("chao-1-molhado-a-chover_camera-do-jogo")],
				[13.5, func(): _camera_de_lado(_arena.centro_casa(Vector2i(12, 9)), 16.0, 2.4); _nota = "MOLHADO — rasante, perto, a chover"],
				[14.5, func(): _capturar("chao-1-molhado-a-chover_rasante")],
				[15.0, func(): c.desligar(); _nota = "a chuva parou: o chão continua molhado (seca em 40 s)"],
				[17.5, func(): _capturar("chao-2-molhado-sem-chuva_rasante")],
				[18.0, func(): _camera_do_jogo(); _nota = "a chuva parou: o chão continua molhado — a câmara do jogo"],
				[19.0, func(): _capturar("chao-2-molhado-sem-chuva_camera-do-jogo")],
			]
			_fim = 19.5
		"medir":
			for p in ["baixo", "medio", "alto"]:
				_med_fila.append({"perfil": p, "clima": "nenhum"})
			for p in ["baixo", "medio", "alto"]:
				for cl in ["chuva-fraca", "chuva-forte"]:
					_med_fila.append({"perfil": p, "clima": cl})
			process_frame.connect(_quadro_medir)
			return
	process_frame.connect(_quadro)


func _quadro() -> void:
	_t += DT
	_rotulo.text = _estado_texto()
	_seta.queue_redraw()
	if int(_t * 30.0) % 15 == 0:
		var c = _arena.clima
		var w: Vector3 = _vento().vetor()
		var vc: Vector2 = c.vento_do_frame("chuva")
		(_medidas["amostras"] as Array).append({"t": snappedf(_t, 0.01), "vento_mundo": [w.x, w.z], "vento_chuva": [vc.x, vc.y],
			"molhado": c.molhado, "agua": c.agua, "gotas": c.contagem_atual("chuva"), "salpicos": c.contagem_atual("salpicos")})
	while _feitos < _passos.size() and _t >= float(_passos[_feitos][0]):
		var f: Callable = _passos[_feitos][1]
		_feitos += 1
		f.call()
	if _t >= _fim:
		process_frame.disconnect(_quadro)
		var f := FileAccess.open(_saida.path_join("chuva_%s_medicao.json" % _modo), FileAccess.WRITE)
		f.store_string(JSON.stringify(_medidas, "  "))
		f.close()
		print("[chuva64] fim %s: %d capturas" % [_modo, (_medidas["capturas"] as Array).size()])
		quit(0)


## A medição: por perfil × clima, espera o regime (a transição das partículas é 1,5 s) e mede 3 s:
## o tempo médio por quadro (ms, sem vsync), os quadros por segundo e os draw calls / primitivas do quadro.
func _quadro_medir() -> void:
	var c = _arena.clima
	_rotulo.text = "ORDEM 64 · MEDIÇÃO · %s · %s" % [str(_med_atual.get("perfil", "")), str(_med_atual.get("clima", ""))]
	if _med_atual.is_empty():
		if _med_fila.is_empty():
			process_frame.disconnect(_quadro_medir)
			var f := FileAccess.open(_saida.path_join("chuva_medicao.json"), FileAccess.WRITE)
			f.store_string(JSON.stringify(_medidas, "  "))
			f.close()
			print("[chuva64] medição feita: %d casos" % (_medidas["amostras"] as Array).size())
			quit(0)
			return
		_med_atual = _med_fila.pop_front()
		_arena._aplicar_perfil(str(_med_atual["perfil"]))
		c.definir_por_nome(str(_med_atual["clima"]))
		_med_espera = 1.0
		_med_ticks = Time.get_ticks_usec() + 3000000  # 3 s reais para o regime
		return
	if _med_espera > 0.0:
		if Time.get_ticks_usec() >= _med_ticks:
			_med_espera = 0.0
			_med_ticks = Time.get_ticks_usec()
			_med_quadros = 0
			_med_dc = 0
			_med_prim = 0
		return
	_med_quadros += 1
	_med_dc += int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
	_med_prim += int(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	var us := Time.get_ticks_usec() - _med_ticks
	if us >= 3000000:
		var ms := float(us) / 1000.0 / float(_med_quadros)
		var r := {"perfil": _med_atual["perfil"], "clima": _med_atual["clima"], "quadros": _med_quadros,
			"ms_por_quadro": snappedf(ms, 0.001), "fps": snappedf(1000.0 / ms, 0.1),
			"draw_calls": int(round(float(_med_dc) / _med_quadros)), "primitivas": int(round(float(_med_prim) / _med_quadros)),
			"gotas": c.contagem_atual("chuva"), "salpicos": c.contagem_atual("salpicos"),
			"resolucao": [root.size.x, root.size.y], "gpu": RenderingServer.get_video_adapter_name(),
			"renderer": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))}
		(_medidas["amostras"] as Array).append(r)
		print("[chuva64] %s" % JSON.stringify(r))
		_med_atual = {}
