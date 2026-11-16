extends SceneTree
## Bancada da GRAMA (Ordem GRAMA, 39/46): os vídeos etiquetados, as capturas e a medição da relva que guarda a
## passagem — as três alturas (baixa, média, alta) LADO A LADO no campo da arena DO JOGO (cenas/arena/arena.tscn,
## com o mapa da floresta), e o MANEQUIM DE PROVA (Mannequin_F do UAL2 com o ANDAR v3:
## testes/manequim/andar-v3.glb) a atravessá-las em linha recta e em curva.
## Corre COM render — nunca com --headless (que não desenha). Não entra no CI: precisa de GPU; a prova é para os
## olhos. O arranjo é de DEMONSTRAÇÃO, posto por esta bancada: as manchas de altura, o manequim e o caminho dele
## não são o jogo (o manequim não é personagem, não está no Estado, não ocupa casa nenhuma).
##
##   UM VÍDEO POR ALTURA (recta + curva + a erva a recuperar) e o das TRÊS LADO A LADO, atravessadas em sequência:
##     godot --path cliente --resolution 1280x720 --fixed-fps 30 --write-movie <pasta>/grama-alta.avi \
##       -s res://testes/video_grama.gd -- --modo=alta --saida=<pasta>
##     (o mesmo com --modo=baixa, --modo=media e --modo=tres)
##   Cada corrida deixa em <pasta>: <modo>_fases.json (as fases do guião com os tempos, para a etiqueta do vídeo),
##   <modo>_medicao.json (os pés no relevo, a abertura da erva ao longo do tempo, os tempos de recuperação
##   medidos) e as capturas de apoio (<modo>_*.jpg).
##   MEDIÇÃO (FPS e chamadas de desenho por perfil, com e sem as três alturas e o rastro; tempo real, sem vsync):
##     godot --path cliente --resolution 1920x1080 --disable-vsync \
##       -s res://testes/video_grama.gd -- --modo=medir --saida=<pasta>

const CENA := "res://cenas/arena/arena.tscn"
const GLB := "res://testes/manequim/andar-v3.glb"
const GLB_SHA256 := "8413b0395d6b9f161aefe05004999ee5f605d4eb68e81a4767a81f9b56ea3491"
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const RastroRelva := preload("res://mapa/floresta/rastro_relva.gd")
const DT := 1.0 / 30.0
## O ANDAR v3 «no lugar» (andar_v3): 1,375 s por ciclo; a versão que anda (andar_frente_v3) avança 1,30 m por
## ciclo — é essa a velocidade a que o manequim se desloca, para os pés não patinarem.
const ANIM := "andar_v3"
const VELOCIDADE := 1.30 / 1.375
## Meia largura de quem passa (m): os ombros do manequim e a folga dos braços.
const RAIO_MANEQUIM := 0.45

## As três manchas LADO A LADO (x0, x1) — todas de z = −5 a z = +5 — e a altura de cada uma (m): RastroRelva.CLASSES.
const FAIXAS := {
	"baixa": [-9.0, -3.4],
	"media": [-2.8, 2.8],
	"alta": [3.4, 9.0],
}
const FAIXA_Z := 5.0
const NOMES := {"baixa": "BAIXA", "media": "MÉDIA", "alta": "ALTA"}

var _modo := "tres"
var _saida := ""
var _arena: Node3D
var _mapa: Node3D
var _rastro: RastroRelva
var _manequim: Node3D
var _esqueleto: Skeleton3D
var _anim: AnimationPlayer
var _ossos_pe: Array[int] = []
var _t := 0.0
var _falhas := 0
var _caminho := PackedVector2Array()   # o caminho do manequim (pontos de 5 em 5 cm)
var _marcos: Array = []                 # [[distância no caminho, nome da fase]]
var _andado := 0.0
var _a_andar := false
var _fases: Array = []                  # [{"t0", "t1", "texto"}]
var _fase_agora := ""
var _medidas: Dictionary = {}
var _pes: Array[float] = []             # por quadro a andar: a folga do pé mais baixo ao relevo (m)
var _sondas: Array = []                 # [{nome, classe, p: Vector2, serie: [[t, abertura]]}]
var _fim_do_caminho_t := -1.0
var _espera_final := 3.0
var _capturas: Array = []               # [[t, nome]]
var _capturas_feitas := 0
var _fechado := false


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--modo="):
			_modo = a.trim_prefix("--modo=")
		elif a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
	if _saida == "":
		_saida = OS.get_user_data_dir().path_join("grama")
	DirAccess.make_dir_recursive_absolute(_saida)
	process_frame.connect(_comecar, CONNECT_ONE_SHOT)


func _n(v: float, casas: int = 2) -> String:
	return (("%." + str(casas) + "f") % v).replace(".", ",")


# ------------------------------------------------------------------ a cena

func _comecar() -> void:
	print("== bancada da grama · modo ", _modo, " · saída ", _saida, " · render: ", RenderingServer.get_video_adapter_name(), " ==")
	if DisplayServer.get_name() == "headless":
		printerr("a bancada da grama precisa de janela (GPU): não corre com --headless")
		quit(1)
		return
	var sha := FileAccess.get_sha256(GLB)
	if sha != GLB_SHA256:
		printerr("o manequim não é o ANDAR v3 aprovado: SHA-256 ", sha)
		quit(1)
		return
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = Vector2i(1920, 1080) if _modo == "medir" else Vector2i(1280, 720)
	var rede = root.get_node("/root/Rede")
	rede.persistir = false
	rede._ativo = true
	# Um combate de DEMONSTRAÇÃO (duas figuras-marcador do jogo, fora das manchas): a arena é a do jogo, tal e qual.
	root.get_node("/root/Estado").aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "demo-grama", "seq": 1,
		"revision": 5, "fase": "combate", "rodada": 1, "mapa": {"largura": 20, "altura": 20, "casaM": 1.5},
		"figuras": [
			{"id": "fA", "nomePublico": "Ong", "x": 2, "y": 16, "lado": "jogadora", "orientacao": "N", "visivel": "de_pe"},
			{"id": "fC", "nomePublico": "Lobo", "x": 17, "y": 3, "lado": "criatura", "orientacao": "S", "visivel": "de_pe"}],
		"vezId": "fA", "propria": {"figuraId": "fA"}, "ambiente": {}})
	_arena = (load(CENA) as PackedScene).instantiate()
	root.add_child(_arena)
	await process_frame
	await process_frame
	_arena.get_node("HUD").visible = false   # o vídeo é da relva: o HUD do jogo fica fora do quadro
	_arena._perfis.aplicar("alto")
	_mapa = _arena.mapa
	_rastro = _mapa.rastro
	_por_manchas(true)
	_por_manequim()
	if _modo == "medir":
		await _medir()
		quit(1 if _falhas > 0 else 0)
		return
	if not (FAIXAS.has(_modo) or _modo == "tres"):
		printerr("modo desconhecido: ", _modo)
		quit(1)
		return
	_guiao()
	_colocar(0.0)
	_rastro.seguir(_manequim, RAIO_MANEQUIM)
	process_frame.connect(_quadro)


func _por_manchas(ligar: bool) -> void:
	var manchas: Array = []
	if ligar:
		for nome: String in RastroRelva.ORDEM:
			var f: Array = FAIXAS[nome]
			manchas.append({"rect": Rect2(float(f[0]), -FAIXA_Z, float(f[1]) - float(f[0]), 2.0 * FAIXA_Z),
				"altura": float(RastroRelva.CLASSES[nome]["altura_m"])})
	_mapa.definir_manchas_relva(manchas)


## O manequim de prova: o .glb carregado tal e qual (sem importação: a pasta tem .gdignore), a andar no lugar.
func _por_manequim() -> void:
	var doc := GLTFDocument.new()
	var estado := GLTFState.new()
	var e := doc.append_from_file(GLB, estado)
	if e != OK:
		printerr("o manequim não abriu: ", e)
		quit(1)
		return
	_manequim = doc.generate_scene(estado)
	_manequim.name = "ManequimDeProva"
	_arena.add_child(_manequim)
	_esqueleto = _manequim.find_children("*", "Skeleton3D", true, false)[0]
	_anim = _manequim.find_child("AnimationPlayer", true, false)
	_anim.get_animation(ANIM).loop_mode = Animation.LOOP_LINEAR
	_anim.play(ANIM)
	_anim.speed_scale = 0.0
	for nome in ["ball_l", "ball_r"]:
		_ossos_pe.append(_esqueleto.find_bone(nome))


func _mesa(foco: Vector2, rumo: float, incl: float, dist: float) -> void:
	var cam = _arena.camera
	cam.definir_modo(1)
	cam.rumo = rumo
	cam.inclinacao = incl
	cam.foco = Vector3(foco.x, 0.0, foco.y)
	cam._limitar()
	cam.definir_zoom(cam.distancia_no_zoom_1 / dist)
	cam._saltar()


# ------------------------------------------------------------------ o caminho

func _recta(a: Vector2, b: Vector2) -> void:
	var n := maxi(int(a.distance_to(b) / 0.05), 1)
	for i in range(0 if _caminho.is_empty() else 1, n + 1):
		_caminho.append(a.lerp(b, float(i) / float(n)))


## Um arco de círculo de `de` graus a `ate` graus (0° = +x, 90° = +z) à volta de `centro`.
func _arco(centro: Vector2, raio: float, de: float, ate: float) -> void:
	var n := maxi(int(absf(deg_to_rad(ate - de)) * raio / 0.05), 1)
	for i in range(1, n + 1):
		var a := deg_to_rad(lerpf(de, ate, float(i) / float(n)))
		_caminho.append(centro + Vector2(cos(a), sin(a)) * raio)


## Uma curva em S de `a` a `b`: o caminho serpenteia `largo` metros para cada lado, `ondas` vezes.
func _serpente(a: Vector2, b: Vector2, largo: float, ondas: float) -> void:
	var ao_longo := (b - a).normalized()
	var de_lado := Vector2(-ao_longo.y, ao_longo.x)
	var n := maxi(int(a.distance_to(b) / 0.04), 1)
	for i in range(1, n + 1):
		var u := float(i) / float(n)
		_caminho.append(a.lerp(b, u) + de_lado * largo * sin(u * TAU * ondas))


func _marco(nome: String) -> void:
	_marcos.append([_comprimento(), nome])


func _comprimento() -> float:
	var c := 0.0
	for i in range(1, _caminho.size()):
		c += _caminho[i - 1].distance_to(_caminho[i])
	return c


func _ponto_em(d: float) -> Array:
	var c := 0.0
	for i in range(1, _caminho.size()):
		var s := _caminho[i - 1].distance_to(_caminho[i])
		if c + s >= d and s > 0.0:
			return [_caminho[i - 1].lerp(_caminho[i], (d - c) / s), (_caminho[i] - _caminho[i - 1]) / s]
		c += s
	var n := _caminho.size()
	return [_caminho[n - 1], (_caminho[n - 1] - _caminho[n - 2]).normalized()]


func _guiao() -> void:
	if _modo == "tres":
		# as três lado a lado, atravessadas em sequência: de oeste para leste em linha recta, a volta, e de leste
		# para oeste em curva
		_marco("LINHA RECTA: baixa → média → alta")
		_recta(Vector2(-10.6, 1.6), Vector2(10.4, 1.6))
		_marco("a volta (fora das manchas)")
		_arco(Vector2(10.4, 0.0), 1.6, 90.0, -90.0)
		_marco("EM CURVA: alta → média → baixa")
		_serpente(Vector2(10.4, -1.6), Vector2(-10.6, -1.6), 1.0, 2.5)
		_espera_final = 13.0
		_mesa(Vector2(0.0, -0.5), 0.0, 47.0, 21.5)
		for nome: String in RastroRelva.ORDEM:
			var f: Array = FAIXAS[nome]
			var cx := (float(f[0]) + float(f[1])) * 0.5
			_sondas.append({"nome": nome + " (recta)", "classe": nome, "p": Vector2(cx, 1.6), "serie": []})
		_capturas = [[1.0, "antes"], [12.0, "recta-a-meio"], [25.5, "recta-feita"], [40.0, "curva-a-meio"], [53.0, "curva-feita"], [66.0, "recuperada"]]
	else:
		var f: Array = FAIXAS[_modo]
		var cx := (float(f[0]) + float(f[1])) * 0.5
		_marco("LINHA RECTA")
		_recta(Vector2(cx - 1.3, FAIXA_Z + 1.0), Vector2(cx - 1.3, -FAIXA_Z - 0.6))
		_marco("a volta (fora da mancha)")
		_arco(Vector2(cx, -FAIXA_Z - 0.6), 1.3, 180.0, 360.0)
		_marco("EM CURVA")
		_serpente(Vector2(cx + 1.3, -FAIXA_Z - 0.6), Vector2(cx + 1.3, FAIXA_Z + 1.0), 1.0, 1.5)
		_espera_final = RastroRelva.recuperacao(_modo) + 2.0
		_mesa(Vector2(cx, 0.6), 0.0, 44.0, 13.5)
		_sondas.append({"nome": _modo + " (recta)", "classe": _modo, "p": Vector2(cx - 1.3, 0.0), "serie": []})
		_sondas.append({"nome": _modo + " (longe do caminho)", "classe": _modo, "p": Vector2(cx - 0.1, 2.0), "serie": []})
		_capturas = [[1.0, "antes"], [8.0, "recta-a-meio"], [14.0, "recta-feita"], [23.0, "curva-a-meio"], [32.5, "curva-feita"]]
	_marco("fim")


func _colocar(d: float) -> void:
	var q := _ponto_em(d)
	var p: Vector2 = q[0]
	var rumo: Vector2 = q[1]
	_manequim.position = Vector3(p.x, Relevo.altura(p.x, p.y), p.y)
	_manequim.rotation.y = atan2(-rumo.x, -rumo.y)   # o manequim olha para −Z


# ------------------------------------------------------------------ o guião, quadro a quadro

func _fase(texto: String) -> void:
	if texto == _fase_agora:
		return
	if not _fases.is_empty():
		_fases[_fases.size() - 1]["t1"] = _t
	_fases.append({"t0": _t, "t1": _t, "texto": texto})
	_fase_agora = texto
	print("[grama] t=%s · %s" % [_n(_t, 1), texto])


func _quadro() -> void:
	if _fechado:
		return
	_t += DT
	var total := _comprimento()
	if _t < 1.5:
		_fase("antes: só o vento")
	elif _andado < total:
		if not _a_andar:
			_a_andar = true
			_anim.speed_scale = 1.0
		_andado = minf(_andado + VELOCIDADE * DT, total)
		_colocar(_andado)
		var nome := ""
		for m: Array in _marcos:
			if _andado >= float(m[0]):
				nome = m[1]
		_fase(nome if nome != "fim" else "parado")
		_medir_pes()
		if _andado >= total:
			_anim.speed_scale = 0.0
			_fim_do_caminho_t = _t
			_rastro.deixar(_manequim)   # parou: já não pisa (a erva debaixo dele recupera como a outra)
	else:
		_fase("parado: a erva recupera sozinha")
	for s: Dictionary in _sondas:
		var p: Vector2 = s["p"]
		(s["serie"] as Array).append([snappedf(_t, 0.001), snappedf(_rastro.abertura_em(p.x, p.y), 0.001)])
	while _capturas_feitas < _capturas.size() and _t >= float(_capturas[_capturas_feitas][0]):
		_capturar(_capturas[_capturas_feitas][1])
		_capturas_feitas += 1
	if _fim_do_caminho_t > 0.0 and _t >= _fim_do_caminho_t + _espera_final:
		_fechar()


## A folga do pé mais baixo ao relevo (m), neste quadro: o osso da planta do pé (ball_l / ball_r) contra a altura
## única do relevo debaixo dele. No ANDAR v3 em chão plano o osso do pé de apoio anda a ~0,02 m do chão.
func _medir_pes() -> void:
	var menor := INF
	for i in _ossos_pe:
		var p: Vector3 = (_esqueleto.global_transform * _esqueleto.get_bone_global_pose(i)).origin
		menor = minf(menor, p.y - Relevo.altura(p.x, p.z))
	_pes.append(menor)


func _capturar(nome: String) -> void:
	var img := root.get_texture().get_image()
	var ficheiro := "%s_t%02ds_%s.jpg" % [_modo, int(round(_t)), nome]
	img.save_jpg(_saida.path_join(ficheiro), 0.9)
	print("[grama] captura ", ficheiro)


func _fechar() -> void:
	_fechado = true
	_fases[_fases.size() - 1]["t1"] = _t
	var f := FileAccess.open(_saida.path_join(_modo + "_fases.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"modo": _modo, "duracao": _t, "fases": _fases}, "  "))
	f.close()
	# ---- o que se mediu
	var cam = _arena.camera
	_medidas = {"modo": _modo, "duracao_s": _t, "velocidade_m_s": VELOCIDADE, "raio_de_quem_passa_m": RAIO_MANEQUIM,
		"caminho_m": _comprimento(), "manchas": _mapa.manchas_relva.map(func(m): return {"x0": m[0].position.x,
			"z0": m[0].position.y, "x1": m[0].end.x, "z1": m[0].end.y, "altura_m": m[1]}),
		"camara": {"rumo": cam.rumo, "inclinacao": cam.inclinacao, "distancia_m": cam._dist_alvo(), "foco": [cam.foco.x, cam.foco.z]},
		"rastro_ativo_no_fim": _rastro.ativo(), "pontos_abertos_no_fim": _rastro.pontos_abertos()}
	if not _pes.is_empty():
		var soma := 0.0
		var mn := INF
		var mx := -INF
		for v in _pes:
			soma += v
			mn = minf(mn, v)
			mx = maxf(mx, v)
		_medidas["pes_no_relevo"] = {"quadros": _pes.size(), "folga_min_m": snappedf(mn, 0.001), "folga_max_m": snappedf(mx, 0.001),
			"folga_media_m": snappedf(soma / _pes.size(), 0.001),
			"o_que_e": "a altura do osso da planta do pé mais baixo acima do relevo, quadro a quadro, a andar"}
	var sondas: Array = []
	for s: Dictionary in _sondas:
		var serie: Array = s["serie"]
		var t_abre := -1.0
		var t_max := -1.0
		var t_fecha := -1.0
		var maximo := 0.0
		for par: Array in serie:
			var a := absf(float(par[1]))
			if a > 0.02 and t_abre < 0.0:
				t_abre = par[0]
			if a > maximo:
				maximo = a
			if a >= 0.98 * maxf(maximo, 0.05):
				t_max = par[0]
			if a > 0.02:
				t_fecha = -1.0
			elif t_abre >= 0.0 and t_fecha < 0.0:
				t_fecha = par[0]
		sondas.append({"sonda": s["nome"], "x": (s["p"] as Vector2).x, "z": (s["p"] as Vector2).y,
			"abertura_maxima": maximo, "abre_aos_s": t_abre, "ultimo_maximo_aos_s": t_max, "fechada_aos_s": t_fecha,
			"recuperacao_medida_s": (t_fecha - t_max) if t_fecha > 0.0 and t_max > 0.0 else -1.0,
			"recuperacao_da_tabela_s": RastroRelva.recuperacao(s["classe"])})
	_medidas["sondas"] = sondas
	_medidas["chamadas_de_desenho"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	f = FileAccess.open(_saida.path_join(_modo + "_medicao.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(_medidas, "  "))
	f.close()
	print("[grama] fim %s: %s s · %s" % [_modo, _n(_t, 1), JSON.stringify(_medidas.get("pes_no_relevo", {}))])
	quit(0)


# ------------------------------------------------------------------ medição (tempo real)

func _medir() -> void:
	var saida := {"render": RenderingServer.get_video_adapter_name(), "quadro": [root.content_scale_size.x, root.content_scale_size.y],
		"motor": Engine.get_version_info()["string"], "perfis": {}}
	_mesa(Vector2(0.0, -0.5), 0.0, 47.0, 21.5)
	# o manequim anda em roda pelas três manchas durante a medição (o rastro escreve o mapa em todos os quadros)
	_recta(Vector2(-10.6, 1.6), Vector2(10.4, 1.6))
	_arco(Vector2(10.4, 0.0), 1.6, 90.0, -90.0)
	_recta(Vector2(10.4, -1.6), Vector2(-10.6, -1.6))
	_arco(Vector2(-10.6, 0.0), 1.6, 270.0, 90.0)
	var total := _comprimento()
	_anim.speed_scale = 1.0
	for perfil: String in ["alto", "medio", "baixo"]:
		_arena._perfis.aplicar(perfil)
		var linha := {}
		for caso: String in ["sem", "com"]:
			var com := caso == "com"
			_por_manchas(com)
			_manequim.visible = com
			if com:
				_rastro.seguir(_manequim, RAIO_MANEQUIM)
			else:
				_rastro.deixar(_manequim)
				# esperar que o rastro feche de todo: o «sem» é a arena como estava antes desta ordem
				_rastro.avancar(RastroRelva.recuperacao_maxima() + 1.0)
			for i in 90:
				_passo_medir(total)
				await process_frame
			var t0 := Time.get_ticks_usec()
			var chamadas := 0.0
			var primitivas := 0.0
			var n := 360
			for i in n:
				_passo_medir(total)
				await process_frame
				chamadas += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
				primitivas += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(n)
			linha[caso] = {"fps": snappedf(1000.0 / ms, 0.1), "ms_por_quadro": snappedf(ms, 0.001),
				"chamadas_de_desenho": snappedf(chamadas / n, 0.1), "primitivas": int(primitivas / n),
				"tufos_desenhados": _mapa.relva.tufos_ativos(), "rastro_ativo": _rastro.ativo(),
				"densidade_relva": _mapa.densidade_relva}
			print("[grama] medir %s · %s as três alturas e o rastro: %s" % [perfil, caso, JSON.stringify(linha[caso])])
		saida["perfis"][perfil] = linha
		# os perfis continuam a aplicar-se com a grama nova: a densidade do perfil chegou à relva
		var esperada: float = _arena._perfis.PERFIS[perfil]["folhagem_densidade"]
		if not is_equal_approx(_mapa.densidade_relva, esperada):
			printerr("o perfil %s não chegou à relva: %s em vez de %s" % [perfil, _mapa.densidade_relva, esperada])
			_falhas += 1
	var f := FileAccess.open(_saida.path_join("medicao_perfis.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(saida, "  "))
	f.close()
	print("[grama] medição feita: %d falha(s)" % _falhas)


func _passo_medir(total: float) -> void:
	_andado = fposmod(_andado + VELOCIDADE * (1.0 / 60.0), total)
	_colocar(_andado)
