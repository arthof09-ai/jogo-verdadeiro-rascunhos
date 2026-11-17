extends SceneTree
## neve_no_mapa.gd — Ordem Neve (correcções, 17/11). A bancada da neve na arena integrada, refeita depois da
## sentença de 17/11 (nota 560): SEM legendas no ecrã, SEM encenação do vento e SEM F imposto quadro a quadro.
##
## Esta ferramenta só GRAVA imagens e o que o relógio diz; NÃO mede a cobertura. A medição é feita depois, por
## outro guião (`medir_pixeis_neve.gd`), que só lê os PNG do disco com `Image.get_pixel` — nunca chama
## `neve_em()`, `fator_f()` nem nenhuma função do clima. O que o clima declara de si próprio fica gravado à
## parte, com a etiqueta «declarado_pelo_sistema», e não entra em conta nenhuma da prova.
##
## Modos (`--modo=`):
##   · `renders`  — quadros fixos na mesma câmara (centro + cantos + obstáculos + lagoa), a 12:00 (meio-dia),
##                  com F imposto UMA vez por quadro (é um retrato determinístico, não uma dinâmica): t0 (F 0),
##                  fraca (neve fraca, F 0,35), t1 (nevasca, F 0,5), t2 (nevasca, F 1), t2_tarde (16:15) e
##                  t2_noite (21:30). Cada quadro sai em PAR: `<nome>.png` (como se vê) e `<nome>_sem_flocos.png`
##                  (o mesmo instante, clima congelado, só os flocos escondidos) — o par mede a precipitação e o
##                  chão separadamente. Mais 6 pares da nevasca F=1 e da neve fraca em instantes diferentes
##                  (`serie_*`), para os flocos não serem julgados por um instante escolhido.
##   · `dinamica` — a curva NATURAL: o clima corre pelo seu `_process`, em tempo real (relógio de parede),
##                  sem F imposto: limpo → nevasca → chuva (derrete) → limpo (seca). De 5 em 5 s grava um
##                  quadro sem flocos/gotas (960×540) para a medição de píxeis e anota o relógio.
##   · `rajada`   — a nevasca a correr sozinha (vento do mundo livre, rajadas do próprio sistema), com F
##                  imposto uma vez (o chão fica parado; o que se observa é a queda). Pares com/sem flocos de
##                  0,5 em 0,5 s durante 24 s — a medição da inclinação/alongamento dos flocos é feita nos
##                  píxeis pelo `medir_pixeis_neve.gd`.
##   · `gpu`      — custo real na janela (sem vsync): limpo, neve fraca, nevasca F=1 sem flocos, nevasca F=1
##                  com os 9.000 flocos. Tempo de quadro por relógio de parede (`Time.get_ticks_usec`).
##
## Uso (na pasta do cliente, COM janela — o render é o da GPU):
##   Godot --path . -s res://cenas/arena/ferramentas/neve_no_mapa.gd -- --modo=renders --saida=C:/caminho

const CENA := "res://cenas/arena/arena.tscn"
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const CampoDaMesa := preload("res://cenas/arena/campo_da_mesa.gd")

var _modo := "renders"
var _saida := ""
var _perfil := "alto"
var _arena: Node3D
var _registo: Dictionary = {"quadros": [], "declarado_pelo_sistema": []}
var _t0_ms := 0


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modo="):
			_modo = a.trim_prefix("--modo=")
		elif a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
		elif a.begins_with("--perfil="):
			_perfil = a.trim_prefix("--perfil=")
	if _saida == "":
		_saida = ProjectSettings.globalize_path("res://../../provas/ordem-neve")
	DirAccess.make_dir_recursive_absolute(_saida)
	process_frame.connect(_comecar, CONNECT_ONE_SHOT)


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


func _clima() -> Node:
	return _arena.clima


func _vento() -> Node:
	return _arena.mapa.vento


func _ciclo() -> Node:
	return _arena.mapa.ciclo


## A câmara única dos retratos (a mesma da primeira execução, para a comparação ser justa): centro da arena,
## cantos/bordas, obstáculos reais e a lagoa no mesmo enquadramento.
func _camera_enquadramento_unico() -> void:
	var cam = _arena.camera
	cam.definir_modo(1)
	cam.rumo = -122.0
	cam.inclinacao = 33.0
	cam.foco = Vector3(-2.0, _arena.altura_chao(-2.0, 1.5), 1.5)
	cam._limitar()
	cam.definir_zoom(0.95)
	cam._saltar()


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _esperar_s(s: float) -> void:
	var fim := Time.get_ticks_msec() + int(s * 1000.0)
	while Time.get_ticks_msec() < fim:
		await process_frame


## Congela/descongela o clima e o vento (para o par com/sem flocos ser o MESMO instante).
func _congelar(sim: bool) -> void:
	var m := Node.PROCESS_MODE_DISABLED if sim else Node.PROCESS_MODE_INHERIT
	_clima().process_mode = m
	_vento().process_mode = m


func _nuvens_visiveis(sim: bool) -> void:
	var c = _clima()
	for nome in ["_flocos", "_chuva", "_salpicos", "_veu"]:
		var n = c.get(nome)
		if n != null and is_instance_valid(n):
			if sim:
				c._atualizar_particulas()  # devolve a visibilidade que o próprio clima decide
			else:
				n.visible = false


func _gravar(nome: String, metade: bool = false) -> String:
	await _esperar(2)
	var img := root.get_texture().get_image()
	if metade:
		img.resize(img.get_width() / 2, img.get_height() / 2, Image.INTERPOLATE_BILINEAR)
	var caminho := _saida.path_join(nome)
	img.save_png(caminho)
	return caminho


## Grava o par do mesmo instante: como se vê, e sem as partículas (clima e vento congelados entre os dois).
func _gravar_par(nome: String, extra: Dictionary = {}) -> void:
	_congelar(true)
	await _esperar(1)
	await _gravar(nome + ".png")
	_nuvens_visiveis(false)
	await _gravar(nome + "_sem_flocos.png")
	_nuvens_visiveis(true)
	_congelar(false)
	var q := {"nome": nome, "hora": _ciclo().hora_texto(), "ms_desde_inicio": Time.get_ticks_msec() - _t0_ms}
	q.merge(extra)
	(_registo["quadros"] as Array).append(q)
	_declarar(nome)
	print("[neve] par gravado: %s" % nome)


## O que o clima diz de si próprio — guardado à parte, NUNCA usado como medição de cobertura.
func _declarar(nome: String) -> void:
	var c = _clima()
	var vf: Vector2 = c.vento_do_frame("neve" if c.tipo == "neve" else "chuva")
	(_registo["declarado_pelo_sistema"] as Array).append({
		"quadro": nome, "ms_desde_inicio": Time.get_ticks_msec() - _t0_ms, "estado": c.estado_clima(),
		"fator_f": snappedf(c.fator_f(), 0.001), "neve": snappedf(c.neve, 0.001), "aglomerado": snappedf(c.aglomerado, 0.001),
		"congelamento": snappedf(c.congelamento, 0.001), "molhado": snappedf(c.molhado, 0.001),
		"vento_queda_ms": [snappedf(vf.x, 0.01), snappedf(vf.y, 0.01)], "rajada_nevasca": snappedf(c.rajada_da_nevasca(c._tempo), 0.01),
		"vento_mundo": _vento().vento_actual(),
	})


## Os píxeis do ecrã onde há ÁGUA da lagoa (fundura > 0,25 m pelo relevo), pela projecção da câmara — conta da
## geometria e da câmara, não do clima. O medidor usa-os para ver se a lagoa mantém a cor dela.
func _pixeis_da_lagoa() -> Array:
	var cam: Camera3D = _arena.camera
	var vs := root.get_visible_rect().size
	var r: Array = []
	var nivel := Relevo.nivel_lago()
	var x := Relevo.COVA.x - Relevo.LAGO_RAIO
	while x <= Relevo.COVA.x + Relevo.LAGO_RAIO:
		var z := Relevo.COVA.y - Relevo.LAGO_RAIO
		while z <= Relevo.COVA.y + Relevo.LAGO_RAIO:
			if Relevo.lago_fundura(x, z) > 0.25:
				var p := Vector3(x, nivel, z)
				if not cam.is_position_behind(p):
					var s := cam.unproject_position(p)
					if s.x >= 0.0 and s.y >= 0.0 and s.x < vs.x and s.y < vs.y:
						r.append([int(s.x), int(s.y)])
			z += 0.35
		x += 0.35
	return r


func _comecar() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_t0_ms = Time.get_ticks_msec()
	_montar_combate()
	_arena = (load(CENA) as PackedScene).instantiate()
	root.add_child(_arena)
	await _esperar(2)
	_arena._aplicar_perfil(_perfil)
	_ciclo().parado = true
	_ciclo().definir_hora(12.0)
	_arena.mapa.aplicar_ciclo()
	_camera_enquadramento_unico()
	await _esperar(3)
	var vs := root.get_visible_rect().size
	_registo["janela"] = [int(vs.x), int(vs.y)]
	_registo["gpu"] = RenderingServer.get_video_adapter_name()
	_registo["perfil"] = _perfil
	_registo["lagoa_pixeis"] = _pixeis_da_lagoa()
	match _modo:
		"renders":
			await _correr_renders()
		"dinamica":
			await _correr_dinamica()
		"rajada":
			await _correr_rajada()
		"gpu":
			await _correr_gpu()
		_:
			push_error("modo desconhecido: %s" % _modo)
	var f := FileAccess.open(_saida.path_join("registo_%s.json" % _modo), FileAccess.WRITE)
	f.store_string(JSON.stringify(_registo, "  "))
	f.close()
	print("[neve] fim %s" % _modo)
	quit(0)


# ---------------------------------------------------------------- retratos (F imposto uma vez por retrato)

func _retrato(nome: String, estado: String, f: float, hora: float) -> void:
	var c = _clima()
	_ciclo().definir_hora(hora)
	_arena.mapa.aplicar_ciclo()
	c.definir_por_nome(estado)
	c.impor_fator_f(f)
	CampoDaMesa.relva_segue_clima(c, _arena.mapa, true)
	await _esperar_s(1.2)
	await _gravar_par(nome, {"estado": estado, "f_imposto": f, "hora_pedida": hora})


func _correr_renders() -> void:
	_vento().parado = true
	for i in 20:
		_vento().avancar(0.1)
	await _retrato("t0_limpo", "limpo", 0.0, 12.0)
	await _retrato("fraca", "neve_fraca", 0.35, 12.0)
	await _retrato("t1_meia_nevasca", "nevasca", 0.5, 12.0)
	await _retrato("t2_nevasca", "nevasca", 1.0, 12.0)
	await _retrato("t2_tarde", "nevasca", 1.0, 16.25)
	await _retrato("t2_noite", "nevasca", 1.0, 21.5)
	# Referências sem neve às mesmas horas (a lagoa e o chão compara-se à MESMA luz).
	await _retrato("t0_tarde", "limpo", 0.0, 16.25)
	await _retrato("t0_noite", "limpo", 0.0, 21.5)
	# Séries: os flocos em 6 instantes (de 1,9 em 1,9 s) na nevasca F=1 e na neve fraca, ao meio-dia.
	for qual in [["serie_nevasca", "nevasca", 1.0], ["serie_fraca", "neve_fraca", 0.35]]:
		_ciclo().definir_hora(12.0)
		_arena.mapa.aplicar_ciclo()
		_clima().definir_por_nome(qual[1])
		_clima().impor_fator_f(qual[2])
		await _esperar_s(1.5)
		for k in 6:
			await _gravar_par("%s_%d" % [qual[0], k], {"estado": qual[1], "f_imposto": qual[2], "hora_pedida": 12.0})
			await _esperar_s(1.9)
	_clima().libertar_fator_f()


# ---------------------------------------------------------------- a curva natural (sem F imposto)

func _correr_dinamica() -> void:
	var c = _clima()
	_vento().parado = false
	c.libertar_fator_f()
	c.definir_por_nome("limpo")
	c.definir_acumulacao(0.0, 0.0)
	var guiao := [[0.0, "limpo"], [5.0, "nevasca"], [115.0, "chuva"], [165.0, "limpo"], [215.0, ""]]
	_registo["guiao_s"] = guiao
	var inicio := Time.get_ticks_msec()
	var proximo_quadro := 0.0
	var passo := 0
	var n := 0
	while true:
		var t := float(Time.get_ticks_msec() - inicio) / 1000.0
		if passo < guiao.size() and t >= float(guiao[passo][0]):
			var e: String = guiao[passo][1]
			if e == "":
				break
			c.definir_por_nome(e)
			(_registo["quadros"] as Array).append({"troca_para": e, "t_s": snappedf(t, 0.01)})
			passo += 1
		if t >= proximo_quadro:
			_congelar(true)
			_nuvens_visiveis(false)
			var nome := "dinamica_%03d.png" % n
			await _gravar(nome, true)
			_nuvens_visiveis(true)
			_congelar(false)
			(_registo["quadros"] as Array).append({"nome": nome, "t_s": snappedf(t, 0.01), "estado_pedido": c.estado_clima()})
			_declarar(nome)
			n += 1
			proximo_quadro += 5.0
		CampoDaMesa.relva_segue_clima(c, _arena.mapa, true)
		await process_frame
	_registo["duracao_parede_s"] = float(Time.get_ticks_msec() - inicio) / 1000.0


# ---------------------------------------------------------------- a rajada que o sistema faz sozinho

func _correr_rajada() -> void:
	var c = _clima()
	_vento().parado = false
	c.definir_por_nome("nevasca")
	c.impor_fator_f(1.0)  # uma vez: o chão consolidado; a queda e o vento correm livres
	await _esperar_s(5.0)  # o vento da nevasca levanta-se (segundos_levantar = 4 s)
	var inicio := Time.get_ticks_msec()
	var k := 0
	while float(Time.get_ticks_msec() - inicio) / 1000.0 < 24.0:
		await _gravar_par("rajada_%02d" % k, {"t_s": snappedf(float(Time.get_ticks_msec() - inicio) / 1000.0, 0.01)})
		k += 1
		await _esperar_s(0.5)
	c.libertar_fator_f()


# ---------------------------------------------------------------- custo na GPU

func _medir_janela(nome: String, segundos: float) -> Dictionary:
	await _esperar_s(2.0)
	var tempos: Array[float] = []
	var antes := Time.get_ticks_usec()
	var fim := antes + int(segundos * 1e6)
	var vp_rid := root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp_rid, true)
	var gpu_ms: Array[float] = []
	var cpu_ms: Array[float] = []
	while Time.get_ticks_usec() < fim:
		await process_frame
		var agora := Time.get_ticks_usec()
		tempos.append(float(agora - antes) / 1000.0)
		antes = agora
		gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(vp_rid))
		cpu_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(vp_rid))
	var ord := tempos.duplicate()
	ord.sort()
	var soma := 0.0
	for x in tempos:
		soma += x
	var media := soma / float(tempos.size())
	var g := 0.0
	for x in gpu_ms:
		g += x
	var cp := 0.0
	for x in cpu_ms:
		cp += x
	var r := {
		"caso": nome, "quadros": tempos.size(), "ms_media": snappedf(media, 0.001),
		"ms_p50": snappedf(ord[ord.size() / 2], 0.001), "ms_p95": snappedf(ord[int(ord.size() * 0.95)], 0.001),
		"ms_p99": snappedf(ord[int(ord.size() * 0.99)], 0.001), "ms_max": snappedf(ord[ord.size() - 1], 0.001),
		"fps_media": snappedf(1000.0 / media, 0.1),
		"render_gpu_ms_media": snappedf(g / float(gpu_ms.size()), 0.001),
		"render_cpu_ms_media": snappedf(cp / float(cpu_ms.size()), 0.001),
		"chamadas_desenho": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitivas": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"flocos_visiveis": _clima().contagem_atual("neve"),
		"vsync": DisplayServer.window_get_vsync_mode(),
	}
	print("[neve] gpu %s" % JSON.stringify(r))
	return r


func _correr_gpu() -> void:
	# Janela fixa a 1920×1080, sem vsync, max_fps 0. Aquecimento de 8 s (compilação de shaders, relógios da GPU)
	# antes de qualquer medida; os casos correm em duas voltas, a segunda em ordem inversa, para a deriva
	# térmica/de relógio não favorecer nenhum caso.
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await _esperar_s(1.0)
	var vs := root.get_visible_rect().size
	_registo["janela_medida"] = [int(vs.x), int(vs.y)]
	var c = _clima()
	_vento().parado = false
	await _esperar_s(8.0)
	var casos: Array = []
	casos.append(await _medir_janela("limpo_sem_camada_de_clima", 10.0))
	var volta := ["nevasca_F1_9000_flocos", "nevasca_F1_so_chao_sem_flocos", "neve_fraca_F0.35_3000_flocos", "limpo_F0_camada_presa"]
	for r in 2:
		var ordem := volta.duplicate()
		if r == 1:
			ordem.reverse()
		for caso in ordem:
			c.set_process(true)
			match caso:
				"nevasca_F1_9000_flocos", "nevasca_F1_so_chao_sem_flocos":
					c.definir_por_nome("nevasca")
					c.impor_fator_f(1.0)
				"neve_fraca_F0.35_3000_flocos":
					c.definir_por_nome("neve_fraca")
					c.impor_fator_f(0.35)
				"limpo_F0_camada_presa":
					c.definir_por_nome("limpo")
					c.impor_fator_f(0.0)
			await _esperar_s(2.0)
			if caso == "nevasca_F1_so_chao_sem_flocos":
				# O mesmo estado, sem os flocos: separa o custo das partículas do custo do chão.
				c.set_process(false)
				_nuvens_visiveis(false)
			var m := await _medir_janela(caso, 10.0)
			m["volta"] = r + 1
			casos.append(m)
	c.set_process(true)
	_nuvens_visiveis(true)
	_registo["casos"] = casos
	c.libertar_fator_f()
