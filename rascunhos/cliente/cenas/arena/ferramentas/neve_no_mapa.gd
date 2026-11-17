extends SceneTree
## neve_no_mapa.gd — Ordem Neve (Fatia 4). A PROVA VISUAL DA NEVE E NEVASCA NA ARENA INTEGRADA:
## - Modos:
##   · `--modo=renders`: produz na MESMA câmara (meio + cantos/bordas + obstáculos no mesmo enquadramento),
##     impondo deterministicamente o factor F ∈ [0, 1] (sem esperar tempo real):
##       - `render_t0_inicio.png` (F = 0, hora 16:15)
##       - `render_t1_meia_nevasca.png` (F = 0,5, nevasca, hora 16:15)
##       - `render_t2_nevasca_consolidada.png` (F = 1,0, nevasca consolidada, hora 16:15)
##       - `render_t2_luz2.png` (F = 1,0, nevasca consolidada numa 2.ª hora declarada do ciclo do dia: 07:00 manhã rasante / 21:30 noite)
##   · `--modo=rajada`: vídeo curto da nevasca com mudança de direcção + rajada a meio (o ângulo e a força da
##     queda mudam visivelmente dentro do mesmo plano).
##   · `--modo=troca`: vídeo curto `limpo → neve_fraca → nevasca → chuva → limpo` contínuo sem reiniciar, conduzido
##     por F com subida e derretimento graduais.
##   · `--modo=fraca`: vídeo curto de `neve_fraca` na arena com deriva do vento do mundo.

const CENA := "res://cenas/arena/arena.tscn"
const VentoMundo := preload("res://mapa/floresta/vento_mundo.gd")
const Clima := preload("res://arte/clima/clima.gd")
const DT := 1.0 / 30.0

var _modo := "renders"
var _saida := ""
var _perfil := "alto"
var _arena: Node3D
var _rotulo: Label
var _seta: Control
var _t := 0.0
var _passos: Array = []
var _feitos := 0
var _fim := 0.0
var _nota := ""
var _medidas: Dictionary = {"renders": [], "amostras": []}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modo="):
			_modo = a.trim_prefix("--modo=")
		elif a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
		elif a.begins_with("--perfil="):
			_perfil = a.trim_prefix("--perfil=")
		elif a.begins_with("--qualidade="):
			ProjectSettings.set_setting("editor/movie_writer/video_quality", float(a.trim_prefix("--qualidade=")))
	if _saida == "":
		_saida = ProjectSettings.globalize_path("res://../../../provas")
	DirAccess.make_dir_recursive_absolute(_saida)
	process_frame.connect(_comecar, CONNECT_ONE_SHOT)


func _n(v: float, casas: int = 2) -> String:
	return (("%." + str(casas) + "f") % v).replace(".", ",")


func _figura(id: String, nome: String, x: int, y: int, lado: String, ori: String = "N") -> Dictionary:
	return {"id": id, "nomePublico": nome, "x": x, "y": y, "lado": lado, "orientacao": ori, "visivel": "de_pe"}


func _montar_combate() -> void:
	var rede = root.get_node("/root/Rede")
	var est = root.get_node("/root/Estado")
	rede.papel = "jogadora"
	rede.estado_ligacao = rede.Ligacao.NA_MESA
	rede._ativo = true
	est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "demo-ordem-neve", "seq": 1, "revision": 5,
		"fase": "combate", "rodada": 1, "mapa": {"largura": 20, "altura": 20, "casaM": 1.5},
		"iniciativa": ["fA", "fB", "fC", "fD", "fE", "fF"], "vezId": "fA", "ambiente": {},
		"figuras": [
			_figura("fA", "Ong", 9, 10, "jogadora"),
			_figura("fB", "Lia", 6, 8, "jogadora", "L"),
			_figura("fC", "Lobo", 12, 8, "criatura", "S"),
			_figura("fD", "Orc", 13, 12, "criatura", "O"),
			_figura("fE", "Kai", 3, 16, "jogadora", "N"),
			_figura("fF", "Batedor", 2, 3, "criatura", "S"),
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
	_arena.definir_modo(_arena.Modo.MOVER)


func _vento() -> Node:
	return _arena.mapa.vento


func _ciclo() -> Node:
	return _arena.mapa.ciclo


func _rumo_mundo() -> Vector2:
	var w: Vector3 = _vento().vetor()
	var d := Vector2(w.x, w.z)
	return d.normalized() if d.length() > 1e-5 else Vector2.RIGHT


## Câmara única dos renders determinísticos (F = 0, F = 0,5, F = 1,0 e 2.ª luz):
## mostra simultaneamente o CENTRO da arena, os CANTOS/BORDAS (NO e SO) e os OBSTÁCULOS reais (tronco tombado,
## menires, rochas e árvores da orla) no mesmo enquadramento.
func _camera_enquadramento_unico() -> void:
	var cam = _arena.camera
	cam.definir_modo(1)
	cam.rumo = -122.0
	cam.inclinacao = 33.0
	cam.foco = Vector3(-2.0, _arena.altura_chao(-2.0, 1.5), 1.5)
	cam._limitar()
	cam.definir_zoom(0.95)
	cam._saltar()


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


func _estado_texto() -> String:
	var c = _arena.clima
	var vm = _vento()
	var v: Dictionary = vm.vento_actual()
	var t_vento := "chuva" if c.tipo == "chuva" else "neve"
	var vc: Vector2 = c.vento_do_frame(t_vento)
	var queda: float = float(Clima.QUEDA[t_vento][c.intensidade])
	var incl := rad_to_deg(atan2(vc.length(), queda))
	var est_nome: String = c.estado_clima().to_upper()
	var f_val: float = c.fator_f()
	var l1 := "ORDEM NEVE · estado: %s · F = %s (neve %s · aglom. %s · cong. %s · molhado %s) · hora %s (%s)" % [
		est_nome, _n(f_val), _n(c.neve), _n(c.aglomerado), _n(c.congelamento), _n(c.molhado),
		_ciclo().hora_texto(), _ciclo().fase()]
	var l2 := "vento do MUNDO: sopra para %s (%s m/s, rajada %s) → queda: %s m/s, inclina %s° · flocos %d · gotas %d" % [
		VentoMundo.rumo(float(v["azimute_para"])), _n(float(v["velocidade_ms"]), 1), _n(float(v["rajada"])),
		_n(vc.length(), 2), _n(incl, 0), c.contagem_atual("neve"), c.contagem_atual("chuva")]
	var l3 := _nota if _nota != "" else "DEMONSTRAÇÃO: câmara fixa (centro + cantos/bordas + obstáculos). Seta amarela = vento do mundo."
	return l1 + "\n" + l2 + "\n" + l3


func _desenhar_seta() -> void:
	var cam: Camera3D = _arena.camera
	if cam == null or _arena.mapa == null:
		return
	var w := _rumo_mundo()
	var c3: Vector3 = _arena.centro_casa(Vector2i(13, 6)) + Vector3(0.0, 0.35, 0.0)
	var p3 := c3 + Vector3(w.x, 0.0, w.y) * 3.2
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


func _avancar_mundo(segundos: float) -> void:
	var n := maxi(1, int(round(segundos / DT)))
	for i in n:
		_vento().avancar(DT)
		_arena.clima.avancar(DT)
	CampoDaMesa.relva_segue_clima(_arena.clima, _arena.mapa, true)


const CampoDaMesa := preload("res://cenas/arena/campo_da_mesa.gd")


func _salvar_png(nome_ficheiro: String) -> void:
	_rotulo.text = _estado_texto()
	_seta.queue_redraw()
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	var caminho := _saida.path_join(nome_ficheiro)
	img.save_png(caminho)
	var c = _arena.clima
	var w: Vector3 = _vento().vetor()
	var reg := {
		"ficheiro": nome_ficheiro,
		"estado": c.estado_clima(),
		"fator_f": c.fator_f(),
		"neve": c.neve,
		"aglomerado": c.aglomerado,
		"congelamento": c.congelamento,
		"molhado": c.molhado,
		"neve_centro": snappedf(c.neve_em(Vector2.ZERO), 0.001),
		"neve_canto_NO": snappedf(c.neve_em(Vector2(-14.2, -14.2)), 0.001),
		"hora": _ciclo().hora_texto(),
		"vento_mundo": [snappedf(w.x, 0.01), snappedf(w.z, 0.01)],
	}
	(_medidas["renders"] as Array).append(reg)
	print("[neve] salvo: %s | %s" % [caminho, JSON.stringify(reg)])


func _comecar() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
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
	var vs := root.get_visible_rect().size
	_rotulo.position = Vector2(14, 0.14 * vs.y)
	_rotulo.size = Vector2(vs.x - 28.0, 0.0)
	_rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ls := LabelSettings.new()
	ls.font_size = maxi(12, int(round(0.020 * vs.y)))
	ls.outline_size = 5
	ls.outline_color = Color(0, 0, 0, 0.9)
	_rotulo.label_settings = ls
	camada.add_child(_rotulo)
	await process_frame
	await process_frame
	_arena._aplicar_perfil(_perfil)
	_mostrar_mover()
	_ciclo().parado = true
	_vento().parado = true
	_ciclo().definir_hora(16.25)
	_arena.mapa.aplicar_ciclo()
	for i in 20:
		_vento().avancar(0.1)

	if _modo == "renders":
		await _correr_renders()
		quit(0)
		return

	_configurar_guiao_video()
	process_frame.connect(_quadro_video)


func _correr_renders() -> void:
	var c = _arena.clima
	_camera_enquadramento_unico()
	await process_frame
	await process_frame

	# 1. t0: F = 0 (início, sem acumulação)
	c.definir_por_nome("limpo")
	c.impor_fator_f(0.0)
	_avancar_mundo(0.2)
	_nota = "t0 (F = 0,0) · Início antes da nevasca · Mesma câmara (centro + cantos/bordas + obstáculos)"
	await _salvar_png("render_t0_inicio.png")

	# 2. t1: F = 0,5 (meia nevasca: queda viva com o vento, acumulação em curso nos obstáculos/covas, centro a cobrir-se)
	c.definir_por_nome("nevasca")
	c.impor_fator_f(0.5)
	_avancar_mundo(1.2)
	_nota = "t1 (F = 0,5) · Meia nevasca · Queda com o vento do mundo, acumulação direccional e geada em progresso"
	await _salvar_png("render_t1_meia_nevasca.png")

	# 3. t2: F = 1,0 (nevasca consolidada, 16:15 tarde: centro coberto sem véu liso, covas/obstáculos espessos × zonas varridas finas)
	c.definir_por_nome("nevasca")
	c.impor_fator_f(1.0)
	_avancar_mundo(1.5)
	_nota = "t2 (F = 1,0) · Nevasca consolidada (16:15) · Centro coberto sem véu liso; covas/obstáculos densos × zonas varridas finas"
	await _salvar_png("render_t2_nevasca_consolidada.png")

	# 4. t2_luz2: F = 1,0 numa segunda hora declarada do ciclo do dia (21:30 noite de lua cheia: volume e relevo legíveis)
	_ciclo().definir_hora(21.5)
	_arena.mapa.aplicar_ciclo()
	c.impor_fator_f(1.0)
	_avancar_mundo(0.5)
	_nota = "t2_luz2 (F = 1,0) · Nevasca consolidada na 2.ª luz declarada (21:30 noite de lua cheia) · Volume 3D preservado"
	await _salvar_png("render_t2_luz2.png")

	var f := FileAccess.open(_saida.path_join("medicao_renders_neve.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(_medidas, "  "))
	f.close()


func _configurar_guiao_video() -> void:
	var c = _arena.clima
	match _modo:
		"rajada":
			_camera_enquadramento_unico()
			c.definir_por_nome("nevasca")
			c.impor_fator_f(0.75)
			c._tempo = 1.0
			_passos = [
				[0.0, func():
					c._tempo = 1.0
					_nota = "NEVASCA (calma inicial): flocos caem com inclinação moderada (~32°)"],
				[1.8, func():
					_vento().azimute_para = wrapf(_vento().azimute_para + 42.0, -180.0, 180.0)
					_vento().forca = 1.50
					c._tempo = 3.5
					c.impor_fator_f(0.92)
					_nota = "RAJADA + MUDANÇA DE DIRECÇÃO: o ângulo (~75°) e a força da queda aumentam visivelmente no mesmo plano"],
				[4.2, func():
					_vento().forca = 0.85
					c._tempo = 1.1
					c.impor_fator_f(1.0)
					_nota = "PÓS-RAJADA (nevasca consolidada F = 1,0): o vento amaina e o manto consolidado lê-se em todo o campo"],
			]
			_fim = 5.5
		"troca":
			_camera_enquadramento_unico()
			c.definir_por_nome("limpo")
			c.impor_fator_f(0.0)
			_passos = [
				[0.0, func():
					c.definir_por_nome("limpo")
					c.impor_fator_f(0.0)
					_nota = "1/5 LIMPO (F = 0,0) → transição viva sem reiniciar"],
				[0.9, func():
					c.definir_por_nome("neve_fraca")
					_nota = "2/5 NEVE FRACA: precipitação suave com o vento do mundo, subida gradual de F"],
				[2.2, func():
					c.definir_por_nome("nevasca")
					c._tempo = 3.8
					_nota = "3/5 NEVASCA: aglomeração direccional, centro coberto e congelamento gradual até F = 1,0"],
				[3.7, func():
					c.libertar_fator_f()
					c.definir_por_nome("chuva")
					_nota = "4/5 CHUVA: troca sem reiniciar; a neve e o gelo derretem gradualmente enquanto o chão molha"],
				[5.0, func():
					c.definir_por_nome("limpo")
					_nota = "5/5 LIMPO: a chuva pára e o manto/humidade recuam gradualmente sem corte seco"],
			]
			_fim = 6.0
		"fraca":
			_camera_enquadramento_unico()
			c.definir_por_nome("neve_fraca")
			c.impor_fator_f(0.35)
			_nota = "NEVE FRACA NA ARENA: deriva suave com o vento do mundo, terreno e grelha táctica legíveis"
			_fim = 4.5


func _quadro_video() -> void:
	_t += DT
	var c = _arena.clima
	while _feitos < _passos.size() and _t >= float(_passos[_feitos][0]):
		var fn: Callable = _passos[_feitos][1]
		_feitos += 1
		fn.call()
	if _modo == "troca":
		if _t >= 0.9 and _t < 2.2:
			var u := (_t - 0.9) / 1.3
			c.impor_fator_f(lerpf(0.0, 0.45, u))
		elif _t >= 2.2 and _t < 3.7:
			var u := (_t - 2.2) / 1.5
			c.impor_fator_f(lerpf(0.45, 1.0, u))
		elif _t >= 3.7 and _t < 5.0:
			var u := (_t - 3.7) / 1.3
			var f_desc := lerpf(1.0, 0.28, u)
			c.impor_fator_f(f_desc, false)
			c.molhado = lerpf(0.15, 0.90, u)
		elif _t >= 5.0:
			var u := clampf((_t - 5.0) / 1.0, 0.0, 1.0)
			var f_desc := lerpf(0.28, 0.05, u)
			c.impor_fator_f(f_desc, false)
			c.molhado = lerpf(0.90, 0.40, u)
	_vento().avancar(DT)
	c.avancar(DT)
	CampoDaMesa.relva_segue_clima(c, _arena.mapa, true)
	_rotulo.text = _estado_texto()
	_seta.queue_redraw()
	if int(round(_t * 30.0)) % 15 == 0:
		var vc: Vector2 = c.vento_do_frame("neve" if c.tipo == "neve" else "chuva")
		(_medidas["amostras"] as Array).append({
			"t": snappedf(_t, 0.01), "estado": c.estado_clima(), "f": snappedf(c.fator_f(), 0.01),
			"vento_queda_ms": snappedf(vc.length(), 0.01), "molhado": snappedf(c.molhado, 0.01)
		})
	if _t >= _fim:
		process_frame.disconnect(_quadro_video)
		var f := FileAccess.open(_saida.path_join("medicao_video_%s.json" % _modo), FileAccess.WRITE)
		f.store_string(JSON.stringify(_medidas, "  "))
		f.close()
		print("[neve] fim video %s" % _modo)
		quit(0)
