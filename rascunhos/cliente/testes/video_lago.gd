extends SceneTree
## Bancada do LAGO (Ordem 66): os vídeos etiquetados, os renders de apoio e a medição da água do lago na arena
## DO JOGO (cenas/arena/arena.tscn, com o mapa da floresta) — o MANEQUIM DE PROVA (Mannequin_F do UAL2 com o
## ANDAR v3: testes/manequim/andar-v3.glb) entra no lago, anda na RASA com a água pelo joelho e nada na FUNDA.
## ORDEM NADO: onde não faz pé (LagoFloresta.a_nadar) o manequim passa ao clipe de nado da casa — o «Swimming» do
## Mixamo convertido para o esqueleto dele (testes/manequim/nado-v1.glb, clipe nadar_v1, feito por
## testes/converter_nado.gd) — e deita-se à superfície; ao voltar a fazer pé, volta ao ANDAR v3 (mistura de 0,6 s).
## Corre COM render — nunca com --headless (que não desenha). Não entra no CI: precisa de GPU; a prova é para os
## olhos. O arranjo é de DEMONSTRAÇÃO, posto por esta bancada: o manequim e o caminho dele não são o jogo (o
## manequim não é personagem, não está no Estado, não ocupa casa nenhuma, e nada aqui decide regra: o que a água
## custa a quem a atravessa é do servidor). A câmara é da bancada (o lago fica fora da grelha de 20 × 20).
##
##   OS DOIS VÍDEOS:
##     godot --path cliente --resolution 1280x720 --fixed-fps 30 --write-movie <pasta>/<nome>.ogv \
##       -s res://testes/video_lago.gd -- --modo=rasa --saida=<pasta>
##     (o mesmo com --modo=funda)
##   Cada corrida deixa em <pasta>: <modo>_fases.json (as fases do guião com os tempos), <modo>_medicao.json (a
##   fundura e a imersão ao longo do caminho, os pés no leito, os anéis e a esteira) e quadros de apoio (.jpg).
##   OS RENDERS DE APOIO (o lago visto de fora e o plano da superfície):
##     godot --path cliente --resolution 1920x1080 -s res://testes/video_lago.gd -- --modo=fotos --saida=<pasta>
##   MEDIÇÃO (FPS e chamadas de desenho por perfil, com o lago em quadro e o manequim a nadar; tempo real, sem
##   vsync):
##     godot --path cliente --resolution 1920x1080 --disable-vsync \
##       -s res://testes/video_lago.gd -- --modo=medir --saida=<pasta>

const CENA := "res://cenas/arena/arena.tscn"
const GLB := "res://testes/manequim/andar-v3.glb"
const GLB_SHA256 := "8413b0395d6b9f161aefe05004999ee5f605d4eb68e81a4767a81f9b56ea3491"
## Ordem NADO: o clipe de nado da casa (o manequim com só o nadar_v1; daqui só se tira o clipe).
const GLB_NADO := "res://testes/manequim/nado-v1.glb"
const GLB_NADO_SHA256 := "5b75767967494201768a69a5743e155eda170e5c10d1f1baccb918d4130b5371"
const ANIM_NADO := "nadar_v1"
## O nadar_v1 está NO LUGAR (como o andar_v3); a fonte avançava 1,90 m × 1,1535 (a escala da anca) por ciclo de
## 4,533 s: 0,483 m/s é a velocidade a que as braçadas não patinam.
const VELOCIDADE_NADO_CLIPE := 0.483
## A anca no nadar_v1 fica, em média, 0,726 m acima da base do manequim (o corpo deitado); a nadar a anca vai
## AFUNDA_ANCA_NADO metros abaixo do nível (as costas e a nuca à tona).
const ANCA_NO_NADO := 0.726
const AFUNDA_ANCA_NADO := 0.08
## A mistura entre o andar e o nado (s): o clipe e a altura do corpo passam juntos.
const MISTURA_NADO_S := 0.6
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const LagoFloresta := preload("res://mapa/floresta/lago_floresta.gd")
const DT := 1.0 / 30.0
## O ANDAR v3 «no lugar» (andar_v3): 1,375 s por ciclo; a versão que anda avança 1,30 m por ciclo — é essa a
## velocidade do manequim em seco, para os pés não patinarem. Dentro de água anda mais devagar (e o ciclo com ele).
const ANIM := "andar_v3"
const VELOCIDADE := 1.30 / 1.375
const FRACCAO_NA_RASA := 0.74      # a andar com a água pelo joelho
const VELOCIDADE_A_NADAR := 0.62   # m/s na funda
## O raio do tronco na linha de água e o de cada perna (m).
const RAIO_TRONCO := 0.21
const RAIO_PERNA := 0.085

var _modo := "rasa"
var _saida := ""
var _arena: Node3D
var _mapa: Node3D
var _lago: LagoFloresta
var _manequim: Node3D
var _esqueleto: Skeleton3D
var _anim: AnimationPlayer
var _a_nadar := false                   # Ordem NADO: o clipe de agora é o nadar_v1
var _peso_nado := 0.0                   # 0 = de pé (andar_v3) … 1 = deitado a nadar; anda com a mistura
var _quadros_a_nadar := 0
var _ossos: Dictionary = {}
var _camara: Camera3D
var _rotulo: Label
var _titulo := ""
var _angulo := ""
var _t := 0.0
var _falhas := 0
var _caminho := PackedVector2Array()
var _marcos: Array = []
var _andado := 0.0
var _a_andar := false
var _fases: Array = []
var _fase_agora := ""
var _serie: Array = []                  # [[t, fundura, imersão, folga do pé ao leito, anéis, pontos de esteira]]
var _fim_do_caminho_t := -1.0
var _espera_inicial := 2.5
var _espera_final := 8.0
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
		_saida = OS.get_user_data_dir().path_join("lago")
	DirAccess.make_dir_recursive_absolute(_saida)
	process_frame.connect(_comecar, CONNECT_ONE_SHOT)


func _n(v: float, casas: int = 2) -> String:
	return (("%." + str(casas) + "f") % v).replace(".", ",")


# ------------------------------------------------------------------ a cena

func _comecar() -> void:
	print("== bancada do lago · modo ", _modo, " · saída ", _saida, " · render: ", RenderingServer.get_video_adapter_name(), " ==")
	if DisplayServer.get_name() == "headless":
		printerr("a bancada do lago precisa de janela (GPU): não corre com --headless")
		quit(1)
		return
	var sha := FileAccess.get_sha256(GLB)
	if sha != GLB_SHA256:
		printerr("o manequim não é o ANDAR v3 aprovado: SHA-256 ", sha)
		quit(1)
		return
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = Vector2i(1280, 720) if _modo in ["rasa", "funda"] else Vector2i(1920, 1080)
	var rede = root.get_node("/root/Rede")
	rede.persistir = false
	rede._ativo = true
	# Um combate de DEMONSTRAÇÃO (duas figuras-marcador do jogo): a arena é a do jogo, tal e qual.
	root.get_node("/root/Estado").aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "demo-lago", "seq": 1,
		"revision": 5, "fase": "combate", "rodada": 1, "mapa": {"largura": 20, "altura": 20, "casaM": 1.5},
		"figuras": [
			{"id": "fA", "nomePublico": "Ong", "x": 2, "y": 16, "lado": "jogadora", "orientacao": "N", "visivel": "de_pe"},
			{"id": "fC", "nomePublico": "Lobo", "x": 17, "y": 3, "lado": "criatura", "orientacao": "S", "visivel": "de_pe"}],
		"vezId": "fA", "propria": {"figuraId": "fA"}, "ambiente": {}})
	_arena = (load(CENA) as PackedScene).instantiate()
	root.add_child(_arena)
	await process_frame
	await process_frame
	_arena.get_node("HUD").visible = false   # o vídeo é da água: o HUD do jogo fica fora do quadro
	_arena._perfis.aplicar("alto")
	_mapa = _arena.mapa
	_lago = _mapa.lago
	_por_camara()
	_por_rotulo()
	_por_manequim()
	match _modo:
		"medir":
			await _medir()
			quit(1 if _falhas > 0 else 0)
		"fotos":
			await _fotos()
			quit(0)
		"rasa", "funda":
			_guiao()
			_colocar(0.0)
			_estado_na_agua(-1.0)
			_colocar(0.0)
			_lago.seguir(_manequim, RAIO_TRONCO, _furos)
			process_frame.connect(_quadro)
		_:
			printerr("modo desconhecido: ", _modo)
			quit(1)


## A câmara da bancada: a do jogo (a mesma lente), solta da grelha.
func _por_camara() -> void:
	var do_jogo: Camera3D = _arena.camera
	_camara = Camera3D.new()
	_camara.name = "CamaraDaBancada"
	_camara.fov = do_jogo.fov
	_camara.near = do_jogo.near
	_camara.far = do_jogo.far
	root.add_child(_camara)
	_camara.make_current()


func _olhar(de: Vector3, para: Vector3, fov: float = 0.0) -> void:
	_camara.look_at_from_position(de, para, Vector3.UP)
	if fov > 0.0:
		_camara.fov = fov


func _por_rotulo() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 100
	root.add_child(camada)
	_rotulo = Label.new()
	var vs := root.get_visible_rect().size
	_rotulo.position = Vector2(16, 12)
	_rotulo.size = Vector2(vs.x - 32.0, 0.0)
	_rotulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var ls := LabelSettings.new()
	ls.font_size = maxi(12, int(round(0.026 * vs.y)))
	ls.outline_size = 6
	ls.outline_color = Color(0, 0, 0, 0.9)
	_rotulo.label_settings = ls
	camada.add_child(_rotulo)


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
	_juntar_nado()
	_anim.play(ANIM)
	_anim.speed_scale = 0.0
	for nome in ["pelvis", "spine_03", "thigh_l", "calf_l", "foot_l", "ball_l", "thigh_r", "calf_r", "foot_r", "ball_r"]:
		_ossos[nome] = _esqueleto.find_bone(nome)
		if int(_ossos[nome]) < 0:
			printerr("o manequim não tem o osso ", nome)
			_falhas += 1


## Ordem NADO: o clipe de nado da casa entra na biblioteca do AnimationPlayer do manequim (as pistas são as
## mesmas: Armature/Skeleton3D:<osso>). O .glb tem de ser o convertido e conferido (SHA-256).
func _juntar_nado() -> void:
	var sha := FileAccess.get_sha256(GLB_NADO)
	if sha != GLB_NADO_SHA256:
		printerr("o clipe de nado não é o nado-v1 convertido: SHA-256 ", sha)
		_falhas += 1
		return
	var doc := GLTFDocument.new()
	var estado := GLTFState.new()
	if doc.append_from_file(GLB_NADO, estado) != OK:
		printerr("o nado-v1 não abriu")
		_falhas += 1
		return
	var cena: Node = doc.generate_scene(estado)
	var ap: AnimationPlayer = cena.find_child("AnimationPlayer", true, false)
	if ap == null or not ap.has_animation(ANIM_NADO):
		printerr("o nado-v1 não traz o clipe ", ANIM_NADO)
		_falhas += 1
		cena.free()
		return
	var clipe: Animation = ap.get_animation(ANIM_NADO).duplicate(true)
	clipe.loop_mode = Animation.LOOP_LINEAR
	_anim.get_animation_library(&"").add_animation(ANIM_NADO, clipe)
	cena.free()


## Ordem NADO: escolhe o clipe pelo sítio do manequim — a nadar onde não faz pé, a andar no resto (em seco e na
## rasa, tal como antes). `dt` < 0: troca já, sem mistura (o primeiro quadro, a medição).
func _estado_na_agua(dt: float) -> void:
	var p := _manequim.position
	var nadar := LagoFloresta.a_nadar(p.x, p.z) and _anim.has_animation(ANIM_NADO)
	if nadar != _a_nadar or dt < 0.0:
		_a_nadar = nadar
		var vel := _anim.speed_scale
		_anim.play(ANIM_NADO if nadar else ANIM, 0.0 if dt < 0.0 else MISTURA_NADO_S)
		_anim.speed_scale = vel
	var alvo := 1.0 if _a_nadar else 0.0
	_peso_nado = alvo if dt < 0.0 else move_toward(_peso_nado, alvo, dt / MISTURA_NADO_S)


## A velocidade de reprodução do clipe de agora para o manequim avançar `v` m/s sem os pés (ou as braçadas)
## patinarem.
func _escala_do_clipe(v: float) -> float:
	return v / (VELOCIDADE_NADO_CLIPE if _a_nadar else VELOCIDADE)


func _osso(nome: String) -> Vector3:
	return (_esqueleto.global_transform * _esqueleto.get_bone_global_pose(int(_ossos[nome]))).origin


## Onde o corpo do manequim FURA a superfície da água agora: [Vector3(x, z, raio)]. Com a água abaixo da anca são
## as duas pernas (a coxa ou a canela, onde cada uma cruza o nível); mais fundo, é o tronco.
func _furos() -> Array:
	var nivel := _lago.nivel()
	var anca := _osso("pelvis")
	if anca.y <= nivel + 0.03:
		var peito := _osso("spine_03")
		var k := clampf((nivel - anca.y) / maxf(peito.y - anca.y, 0.01), 0.0, 1.0)
		if _a_nadar:
			k = 0.5   # Ordem NADO: deitado, o tronco fura a água a meio, entre a anca e o peito
		var p := anca.lerp(peito, k)
		return [Vector3(p.x, p.z, RAIO_TRONCO)]
	var r: Array = []
	for lado in ["l", "r"]:
		var cadeia: Array[Vector3] = [_osso("thigh_" + lado), _osso("calf_" + lado), _osso("foot_" + lado), _osso("ball_" + lado)]
		for i in range(cadeia.size() - 1):
			var a := cadeia[i]
			var b := cadeia[i + 1]
			if (a.y - nivel) * (b.y - nivel) <= 0.0 and absf(a.y - b.y) > 0.0001:
				var p := a.lerp(b, (a.y - nivel) / (a.y - b.y))
				r.append(Vector3(p.x, p.z, RAIO_PERNA))
				break
	return r


# ------------------------------------------------------------------ o caminho

func _recta(a: Vector2, b: Vector2) -> void:
	var n := maxi(int(a.distance_to(b) / 0.05), 1)
	for i in range(0 if _caminho.is_empty() else 1, n + 1):
		_caminho.append(a.lerp(b, float(i) / float(n)))


## Um arco de círculo de `de` graus a `ate` graus (0° = +x, 90° = +z) à volta de `centro`.
func _arco(centro: Vector2, raio: float, de: float, ate: float) -> void:
	var n := maxi(int(absf(deg_to_rad(ate - de)) * raio / 0.05), 1)
	for i in range(0 if _caminho.is_empty() else 1, n + 1):
		var a := deg_to_rad(lerpf(de, ate, float(i) / float(n)))
		_caminho.append(centro + Vector2(cos(a), sin(a)) * raio)


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
	var nivel := _lago.nivel()
	if _modo == "rasa":
		_titulo = "(a) ENTRAR NO LAGO E ANDAR NA RASA, COM A ÁGUA PELO JOELHO"
		_angulo = "câmara a 3/4, da margem sul, a olhar para noroeste"
		# da erva da margem oeste para dentro de água, ao longo da rasa para norte (em curva) e parar lá dentro
		_recta(Vector2(9.2, -15.6), Vector2(13.4, -17.4))
		_arco(Vector2(13.4, -19.3), 1.9, 90.0, -90.0)
		_espera_final = 9.0
		_olhar(Vector3(17.6, nivel + 3.1, -11.6), Vector3(14.2, nivel + 0.25, -19.6), 50.0)
		_capturas = [[1.0, "antes"], [5.5, "a-entrar"], [9.0, "na-rasa-1"], [13.0, "na-rasa-2"], [18.0, "na-rasa-3"], [22.0, "parado"], [27.0, "aneis-a-morrer"]]
	else:
		_titulo = "(b) NADAR NA FUNDA: A ESTEIRA FORMA-SE ATRÁS DA PEÇA E DESFAZ-SE DEVAGAR"
		_angulo = "câmara alta, da margem sul, a olhar para norte"
		# da rasa do lado oeste para dentro da funda (a água sobe pelo corpo), uma volta a nado e a saída para sul
		_recta(Vector2(13.4, -21.0), Vector2(17.5, -21.0))
		_arco(Vector2(19.5, -21.0), 2.0, 180.0, 450.0)
		_recta(Vector2(19.5, -19.0), Vector2(19.5, -15.2))
		_espera_inicial = 2.0
		_espera_final = 16.0
		_olhar(Vector3(19.9, nivel + 6.4, -11.0), Vector3(19.4, nivel, -20.3), 50.0)
		_capturas = [[1.0, "antes"], [6.0, "a-agua-sobe"], [10.0, "nado-1"], [15.0, "nado-2"], [20.0, "nado-3"], [25.0, "nado-4"], [30.0, "a-sair"], [34.0, "esteira-a-desfazer-1"], [38.0, "esteira-a-desfazer-2"], [42.0, "esteira-a-desfazer-3"], [45.0, "esteira-desfeita"]]


## Põe o manequim no ponto `d` do caminho: os pés no leito enquanto faz pé; na funda bóia com a água pelo peito.
func _colocar(d: float) -> void:
	var q := _ponto_em(d)
	var p: Vector2 = q[0]
	var rumo: Vector2 = q[1]
	var y := LagoFloresta.pe_na_agua(p.x, p.y)
	if Relevo.lago_fundura(p.x, p.y) > LagoFloresta.FLUTUA_M:
		y += 0.022 * sin(_t * 2.3) * (1.0 - _peso_nado)   # a boiar de pé, o corpo sobe e desce um nada
	# Ordem NADO: a nadar o corpo deita-se à tona (o nadar_v1 traz o seu próprio balanço da anca).
	var y_nado := _lago.nivel() - AFUNDA_ANCA_NADO - ANCA_NO_NADO
	y = lerpf(y, y_nado, smoothstep(0.0, 1.0, _peso_nado))
	_manequim.position = Vector3(p.x, y, p.y)
	_manequim.rotation.y = atan2(-rumo.x, -rumo.y)   # o manequim olha para −Z


## A velocidade do manequim (m/s) com `fundura` metros de água debaixo dele.
func _velocidade(fundura: float) -> float:
	var v := VELOCIDADE * lerpf(1.0, FRACCAO_NA_RASA, smoothstep(0.05, 0.40, fundura))
	return lerpf(v, VELOCIDADE_A_NADAR, smoothstep(0.75, LagoFloresta.FLUTUA_M, fundura))


# ------------------------------------------------------------------ o guião, quadro a quadro

func _fase(texto: String) -> void:
	if texto == _fase_agora:
		return
	if not _fases.is_empty():
		_fases[_fases.size() - 1]["t1"] = _t
	_fases.append({"t0": _t, "t1": _t, "texto": texto})
	_fase_agora = texto
	print("[lago] t=%s · %s" % [_n(_t, 1), texto])


func _nome_da_fase(fundura: float, imersao: float) -> String:
	if fundura <= 0.0:
		return "em seco, na margem"
	if fundura > LagoFloresta.FLUTUA_M:
		return "a NADAR na funda (não faz pé): a esteira nasce atrás"
	if imersao > 0.62:
		return "o leito desce: a água SOBE pelo corpo"
	if imersao > 0.22:
		return "na RASA: a água pelo joelho, anéis à volta das pernas e pelo caminho"
	return "a entrar: a água pelo tornozelo"


func _quadro() -> void:
	if _fechado:
		return
	_t += DT
	var total := _comprimento()
	var p3 := _manequim.position
	var fundura := Relevo.lago_fundura(p3.x, p3.z)
	var imersao := _lago.imersao(p3.x, p3.z, p3.y)
	if _t < _espera_inicial:
		_fase("antes: a superfície só com o vento")
	elif _andado < total:
		if not _a_andar:
			_a_andar = true
		var v := _velocidade(fundura)
		_estado_na_agua(DT)
		_anim.speed_scale = _escala_do_clipe(v)
		_andado = minf(_andado + v * DT, total)
		_colocar(_andado)
		if _a_nadar:
			_quadros_a_nadar += 1
		_fase(_nome_da_fase(fundura, imersao))
		if _andado >= total:
			_anim.speed_scale = 0.0
			_fim_do_caminho_t = _t
	else:
		_fase("parado dentro de água: os anéis e a esteira desfazem-se sozinhos")
	# ---- a etiqueta
	var l1 := "ORDEM 66 · O LAGO · %s" % _titulo
	var l2 := "%s · t = %s s · fundura debaixo da peça: %s m · água no corpo: %s m · %s" % [
		_angulo, _n(_t, 1), _n(fundura), _n(imersao), _fase_agora]
	var l3 := "DEMONSTRAÇÃO: manequim de prova (ANDAR v3 · NADO v1, clipe %s) e câmara da bancada" % (ANIM_NADO if _a_nadar else ANIM) + "; a água, o relevo e a luz são os do mapa do jogo. %d anéis · %d pontos de esteira" % [
		_lago.pulsos_vivos(), _lago.pontos_de_rasto()]
	_rotulo.text = l1 + "\n" + l2 + "\n" + l3
	# ---- o que se mede: os pés no leito (enquanto faz pé)
	var folga := NAN
	if _a_andar and fundura <= LagoFloresta.FLUTUA_M:
		folga = INF
		for nome in ["ball_l", "ball_r"]:
			var o := _osso(nome)
			folga = minf(folga, o.y - Relevo.altura(o.x, o.z))
	_serie.append([snappedf(_t, 0.001), snappedf(fundura, 0.001), snappedf(imersao, 0.001),
		snappedf(folga, 0.001) if not is_nan(folga) else null, _lago.pulsos_vivos(), _lago.pontos_de_rasto()])
	while _capturas_feitas < _capturas.size() and _t >= float(_capturas[_capturas_feitas][0]):
		_capturar(_capturas[_capturas_feitas][1])
		_capturas_feitas += 1
	if _fim_do_caminho_t > 0.0 and _t >= _fim_do_caminho_t + _espera_final:
		_fechar()


func _capturar(nome: String) -> void:
	var img := root.get_texture().get_image()
	var ficheiro := "%s_t%02ds_%s.jpg" % [_modo, int(round(_t)), nome]
	DirAccess.make_dir_recursive_absolute(_saida.path_join("quadros"))
	img.save_jpg(_saida.path_join("quadros").path_join(ficheiro), 0.9)
	print("[lago] captura ", ficheiro)


func _fechar() -> void:
	_fechado = true
	_fases[_fases.size() - 1]["t1"] = _t
	var f := FileAccess.open(_saida.path_join(_modo + "_fases.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"modo": _modo, "titulo": _titulo, "angulo": _angulo, "duracao": _t, "fases": _fases}, "  "))
	f.close()
	var fundura_max := 0.0
	var imersao_max := 0.0
	var folga_min := INF
	var folga_max := -INF
	var folga_soma := 0.0
	var folga_n := 0
	for s: Array in _serie:
		fundura_max = maxf(fundura_max, float(s[1]))
		imersao_max = maxf(imersao_max, float(s[2]))
		if s[3] != null:
			folga_min = minf(folga_min, float(s[3]))
			folga_max = maxf(folga_max, float(s[3]))
			folga_soma += float(s[3])
			folga_n += 1
	var medidas := {"modo": _modo, "duracao_s": _t, "caminho_m": _comprimento(),
		"velocidade_em_seco_m_s": VELOCIDADE, "velocidade_na_rasa_m_s": VELOCIDADE * FRACCAO_NA_RASA,
		"velocidade_a_nadar_m_s": VELOCIDADE_A_NADAR, "fundura_maxima_no_caminho_m": fundura_max,
		"nado": {"clipe": ANIM_NADO, "glb": GLB_NADO, "glb_sha256": GLB_NADO_SHA256, "quadros_a_nadar": _quadros_a_nadar,
			"o_que_e": "quadros em que o manequim usou o clipe de nado (onde não faz pé: LagoFloresta.a_nadar)"},
		"agua_no_corpo_maxima_m": imersao_max, "nivel_do_lago_m": _lago.nivel(), "lago": _lago.medidas,
		"camara": {"posicao": [_camara.position.x, _camara.position.y, _camara.position.z], "fov": _camara.fov},
		"chamadas_de_desenho": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"serie": {"colunas": ["t_s", "fundura_m", "agua_no_corpo_m", "folga_do_pe_ao_leito_m", "aneis", "pontos_de_esteira"], "linhas": _serie}}
	if folga_n > 0:
		medidas["pes_no_leito"] = {"quadros": folga_n, "folga_min_m": snappedf(folga_min, 0.001), "folga_max_m": snappedf(folga_max, 0.001),
			"folga_media_m": snappedf(folga_soma / folga_n, 0.001),
			"o_que_e": "a altura do osso da planta do pé mais baixo acima do leito, quadro a quadro, enquanto faz pé"}
	f = FileAccess.open(_saida.path_join(_modo + "_medicao.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(medidas, "  "))
	f.close()
	print("[lago] fim %s: %s s · %s" % [_modo, _n(_t, 1), JSON.stringify(medidas.get("pes_no_leito", {}))])
	quit(0)


# ------------------------------------------------------------------ os renders de apoio

func _fotos() -> void:
	var nivel := _lago.nivel()
	_manequim.visible = false
	# deixar o mundo assentar (o forno das sombras, a relva)
	for i in 40:
		await process_frame
	var vistas: Array = [
		["lago-visto-de-fora_do-alto-da-margem-sul_margem-rasa-e-funda", Vector3(21.5, nivel + 9.5, -6.5), Vector3(19.3, nivel, -19.8), 55.0,
			"O LAGO VISTO DE FORA · do alto da margem sul · a margem, a RASA (clara, vê-se o leito) e a FUNDA (escura, ao meio)"],
		["lago-visto-de-cima_planta_rasa-e-funda", Vector3(19.5, nivel + 24.0, -19.4), Vector3(19.5, nivel, -19.5), 50.0,
			"O LAGO EM PLANTA · de cima · a RASA à volta e a FUNDA ao meio (três bolhas fundidas, 2 m de fundura)"],
		["lago-da-margem_altura-dos-olhos_de-oeste", Vector3(8.6, nivel + 2.1, -17.2), Vector3(19.5, nivel, -20.0), 55.0,
			"O LAGO DA MARGEM · à altura dos olhos, de oeste · o céu espelhado e o brilho na ruga"],
		["plano-da-superficie_rasante_de-perto", Vector3(15.2, nivel + 0.55, -15.4), Vector3(18.6, nivel, -19.6), 42.0,
			"PLANO DA SUPERFÍCIE · rasante, de perto · as ondinhas do vento, as rugas e o brilho"],
		["plano-da-superficie_de-cima_de-perto_talude", Vector3(15.9, nivel + 3.4, -18.6), Vector3(16.6, nivel, -20.6), 45.0,
			"PLANO DA SUPERFÍCIE · de cima, de perto · a passagem da RASA para a FUNDA (o talude lê-se no fundo)"],
	]
	for v: Array in vistas:
		_olhar(v[1], v[2], v[3])
		_rotulo.text = "ORDEM 66 · %s\nrender de apoio (parado) · arena integrada do jogo, perfil Alto · nível do lago %s m · rasa %s m · funda %s m" % [
			v[4], _n(nivel), _n(Relevo.LAGO_RASA_M), _n(Relevo.LAGO_FUNDA_M, 1)]
		for i in 12:
			await process_frame
		var img := root.get_texture().get_image()
		img.save_png(_saida.path_join(String(v[0]) + ".png"))
		print("[lago] render ", v[0])


# ------------------------------------------------------------------ medição (tempo real)

func _medir() -> void:
	var nivel := _lago.nivel()
	var saida := {"render": RenderingServer.get_video_adapter_name(), "quadro": [root.content_scale_size.x, root.content_scale_size.y],
		"motor": Engine.get_version_info()["string"], "lago": _lago.medidas, "perfis": {}}
	_rotulo.visible = false
	_olhar(Vector3(19.9, nivel + 6.4, -11.0), Vector3(19.4, nivel, -20.3), 50.0)
	_arco(Vector2(19.5, -21.0), 2.0, 0.0, 360.0)
	var total := _comprimento()
	_colocar(0.0)
	_estado_na_agua(-1.0)   # Ordem NADO: o arco da medição é todo na funda: a nadar
	_anim.speed_scale = _escala_do_clipe(VELOCIDADE_A_NADAR)
	for perfil: String in ["alto", "medio", "baixo"]:
		_arena._perfis.aplicar(perfil)
		var linha := {}
		for caso: String in ["sem", "com"]:
			var com := caso == "com"
			_lago.visible = com
			_manequim.visible = com
			if com:
				_lago.seguir(_manequim, RAIO_TRONCO, _furos)
			else:
				_lago.deixar(_manequim)
			for i in 120:
				_passo_medir(total)
				await process_frame
			var t0 := Time.get_ticks_usec()
			var chamadas := 0.0
			var primitivas := 0.0
			var n := 480
			for i in n:
				_passo_medir(total)
				await process_frame
				chamadas += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
				primitivas += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			var ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(n)
			linha[caso] = {"fps": snappedf(1000.0 / ms, 0.1), "ms_por_quadro": snappedf(ms, 0.001),
				"chamadas_de_desenho": snappedf(chamadas / n, 0.1), "primitivas": int(primitivas / n),
				"aneis": _lago.pulsos_vivos(), "pontos_de_esteira": _lago.pontos_de_rasto()}
			print("[lago] medir %s · %s o lago e o manequim a nadar: %s" % [perfil, caso, JSON.stringify(linha[caso])])
		saida["perfis"][perfil] = linha
	var f := FileAccess.open(_saida.path_join("medicao_perfis.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(saida, "  "))
	f.close()
	print("[lago] medição feita: %d falha(s)" % _falhas)


func _passo_medir(total: float) -> void:
	_t += 1.0 / 60.0
	_andado = fposmod(_andado + VELOCIDADE_A_NADAR * (1.0 / 60.0), total)
	_estado_na_agua(1.0 / 60.0)
	_colocar(_andado)
