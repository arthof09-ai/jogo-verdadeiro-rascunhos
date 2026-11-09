extends Node3D
## Arena 3D do ecrã do Mestre (§12 do desenho JV3.1, I0004 08/11/2026).
##
## Vive dentro de um SubViewport no lado esquerdo do ecrã do Mestre. Desenha a grelha da arena e TODAS as
## figuras colocadas (as não colocadas, as únicas que a Party não vê, ficam só na aba Figuras), com a
## mesma câmara da mesa (camera/camera_mesa.gd: fixa, 360°, panorama, zoom e arrasto). A figura da vez
## leva um anel. Pode destacar casas (as do «Mover» da aba Agir) e diz que casa o Mestre tocou
## (`casa_tocada`), para o «Colocar» e o «Mover». Nunca calcula regra: as casas destacadas vêm do servidor.
##
## Plano B (08/11/2026): as figuras desenham-se com o MARCADOR DO SITE (cenas/comum/marcador_figura.gd, os
## números do cena.js: anel de identificação pela ordem de entrada, sombra de contacto, corpo de pedra mate
## «marcador» ou «marcador-lobo», com a altura da ficha). As casas destacadas são as do «mover» do site
## (quadrado 0,94 da casa, cabb577 a 50%, contorno f5d59b); o fundo, a grelha e o sol são os do site. O GLB
## de cada figura entra pela V3.1 (Plano B), quando os pilotos do Plano C passarem a O8.1.

signal casa_tocada(casa: Vector2i)

const CameraMesa := preload("res://camera/camera_mesa.gd")
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")
const Marcador := preload("res://cenas/comum/marcador_figura.gd")
## Decisão 10 do Mestre (ordem 6; site REF_29): a câmara livre só existe aqui, na arena do Mestre.
const CamaraLivre := preload("res://cenas/mestre/camara_livre.gd")

const COR_CHAO := Color(0.30, 0.42, 0.26)
# Do site (cena.js): fundo 353b48, grelha c9c2a7, casas do «mover» cab577 a 50% com contorno f5d59b,
# sol ffb16b a 1,35, céu/chão hemisférico 96b4df / 222632 a 0,40, anel de destino ffd28b (raio 0,65).
const COR_FUNDO := Color("353b48")
const COR_LINHAS := Color(0.788, 0.761, 0.655, 0.5)  # c9c2a7
const COR_DESTAQUE := Color(0.792, 0.710, 0.467, 0.5)  # cab577 a 50%
const COR_CONTORNO_DESTAQUE := Color("f5d59b")
const COR_SOL := Color("ffb16b")
const COR_ANEL := Color("ffd28b")

var largura := 0
var altura := 0
var casa_m := 1.5
var camera: CameraMesa
var camara_livre: CamaraLivre

var _grelha: Node3D
var _figuras: Node3D
var _destaques: MultiMeshInstance3D
var _contornos: MeshInstance3D
var _anel: MeshInstance3D
var _nos: Dictionary = {}  # figuraId -> Node3D
var _entradas := 0  # ordem de entrada das figuras: a cor do anel (cena.js `units.size % 5`)
var _casas_destacadas: Array[Vector2i] = []


func _ready() -> void:
	var ambiente := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = COR_FUNDO
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("96b4df")
	env.ambient_light_energy = 0.40
	ambiente.environment = env
	add_child(ambiente)
	var sol := DirectionalLight3D.new()
	sol.light_color = COR_SOL
	sol.light_energy = 1.35
	sol.shadow_enabled = true
	sol.basis = Basis.looking_at(Vector3(24.0, -12.0, 18.0).normalized(), Vector3.UP)  # do site: em (-24, 12, -18), para o centro
	add_child(sol)
	camera = CameraMesa.new()
	camera.name = "Camera"
	add_child(camera)
	camera.current = true
	camera.toque.connect(_ao_toque)
	camara_livre = CamaraLivre.new()
	add_child(camara_livre)
	_grelha = Node3D.new()
	_grelha.name = "Grelha"
	add_child(_grelha)
	_figuras = Node3D.new()
	_figuras.name = "Figuras"
	add_child(_figuras)
	_destaques = MultiMeshInstance3D.new()
	_destaques.name = "Destaques"
	add_child(_destaques)
	_contornos = MeshInstance3D.new()
	_contornos.name = "ContornosDestaques"
	add_child(_contornos)
	_anel = MeshInstance3D.new()
	_anel.name = "AnelDaVez"
	_anel.mesh = Marcador.anel_plano(0.65, COR_ANEL)  # o anel de destino do site (0,65, ffd28b)
	_anel.visible = false
	add_child(_anel)
	construir_grelha(20, 20, 1.5)


func construir_grelha(w: int, h: int, c: float) -> void:
	if w == largura and h == altura and is_equal_approx(c, casa_m) and _grelha.get_child_count() > 0:
		return
	largura = maxi(1, w)
	altura = maxi(1, h)
	casa_m = c if c > 0.0 else 1.5
	for n in _grelha.get_children():
		n.queue_free()
	var tam := Vector2(largura * casa_m, altura * casa_m)
	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = tam
	plano.material = _material(COR_CHAO, false)
	chao.mesh = plano
	chao.position = Vector3(tam.x * 0.5, 0.0, tam.y * 0.5)
	_grelha.add_child(chao)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _material(COR_LINHAS, true))
	for i in range(largura + 1):
		im.surface_add_vertex(Vector3(i * casa_m, 0.01, 0.0))
		im.surface_add_vertex(Vector3(i * casa_m, 0.01, tam.y))
	for j in range(altura + 1):
		im.surface_add_vertex(Vector3(0.0, 0.01, j * casa_m))
		im.surface_add_vertex(Vector3(tam.x, 0.01, j * casa_m))
	im.surface_end()
	var linhas := MeshInstance3D.new()
	linhas.mesh = im
	_grelha.add_child(linhas)
	camera.configurar_arena(Vector3(tam.x * 0.5, 0.0, tam.y * 0.5), tam)


## Desenha a vista do Mestre: a grelha do mapa e as figuras colocadas.
func aplicar_vista(vista: Dictionary) -> void:
	var mapa = vista.get("mapa")
	if mapa is Dictionary:
		construir_grelha(int(mapa.get("largura", 20)), int(mapa.get("altura", 20)), float(mapa.get("casaM", 1.5)))
	var vistos := {}
	for f in Modelo.figuras(vista):
		if not (f is Dictionary) or f.get("colocada") != true:
			continue
		var id := str(f.get("id", ""))
		vistos[id] = true
		var no: Node3D = _nos.get(id)
		if no == null:
			no = _nova_figura(f)
			_nos[id] = no
			_figuras.add_child(no)
		no.position = centro_da_casa(Vector2i(int(f.get("x", 0)), int(f.get("y", 0))))
		(no.get_node("Rotulo") as Label3D).text = Modelo.nome_mestre(f)
		# Morta: deitada como no site. Caída (viva): também deitada, para o Mestre a ver no chão.
		Marcador.deitar(no.get_node("Marcador") as Node3D, f.get("caido") == true or f.get("vivo") == false)
	for id in _nos.keys():
		if not vistos.has(id):
			(_nos[id] as Node).queue_free()
			_nos.erase(id)
	var vez := str(vista.get("vezId", "")) if vista.get("vezId") is String else ""
	_anel.visible = _nos.has(vez)
	if _anel.visible:
		_anel.position = (_nos[vez] as Node3D).position + Vector3(0.0, 0.045, 0.0)


# ---------------------------------------------------------------- câmara livre (decisão 10; site REF_29)

## Entra na câmara livre. A câmara da mesa fica congelada (sem processo nem gestos): sair é exacto.
func entrar_camara_livre() -> void:
	if camara_livre.ativa:
		return
	camera.set_process(false)
	camera.set_process_unhandled_input(false)
	var tam := Vector2(largura * casa_m, altura * casa_m)
	camara_livre.entrar(Vector3(tam.x * 0.5, 0.0, tam.y * 0.5), tam)


## Volta à câmara do jogo, tal como estava.
func sair_camara_livre() -> void:
	camara_livre.sair()
	camera.current = true
	camera.set_process(true)
	camera.set_process_unhandled_input(true)


func camara_livre_ativa() -> bool:
	return camara_livre != null and camara_livre.ativa


func figuras_desenhadas() -> int:
	return _nos.size()


func centro_da_casa(c: Vector2i) -> Vector3:
	return Vector3((c.x + 0.5) * casa_m, 0.0, (c.y + 0.5) * casa_m)


func casa_de_ponto(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / casa_m), floori(p.z / casa_m))


func dentro(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < largura and c.y < altura


## Destaca as casas que o servidor mandou (o cliente não as escolhe).
func destacar(casas: Array[Vector2i]) -> void:
	_casas_destacadas = casas.duplicate()
	if casas.is_empty():
		_destaques.multimesh = null
		_contornos.mesh = null
		return
	var quad := QuadMesh.new()
	quad.size = Vector2(casa_m * 0.94, casa_m * 0.94)
	quad.orientation = PlaneMesh.FACE_Y
	quad.material = _material(COR_DESTAQUE, true)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = casas.size()
	for i in casas.size():
		mm.set_instance_transform(i, Transform3D(Basis(), centro_da_casa(casas[i]) + Vector3(0.0, 0.035, 0.0)))
	_destaques.multimesh = mm
	# O contorno de cada casa (LineSegments f5d59b do site).
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _material(COR_CONTORNO_DESTAQUE, true))
	var m := casa_m * 0.47
	for c in casas:
		var o := centro_da_casa(c) + Vector3(0.0, 0.036, 0.0)
		var cantos := [o + Vector3(-m, 0, -m), o + Vector3(m, 0, -m), o + Vector3(m, 0, m), o + Vector3(-m, 0, m)]
		for k in 4:
			im.surface_add_vertex(cantos[k])
			im.surface_add_vertex(cantos[(k + 1) % 4])
	im.surface_end()
	_contornos.mesh = im


func casas_destacadas() -> Array[Vector2i]:
	return _casas_destacadas


func _ao_toque(posicao: Vector2) -> void:
	var origem := camera.project_ray_origin(posicao)
	var direcao := camera.project_ray_normal(posicao)
	if absf(direcao.y) < 0.0001:
		return
	var t := -origem.y / direcao.y
	if t < 0.0:
		return
	var c := casa_de_ponto(origem + direcao * t)
	if dentro(c):
		casa_tocada.emit(c)


func _nova_figura(f: Dictionary) -> Node3D:
	var no := Node3D.new()
	no.name = "Figura_" + str(f.get("id", ""))
	var altura_m := float(f.get("alturaM")) if (f.get("alturaM") is float or f.get("alturaM") is int) else 0.0
	var forma := str(f.get("marcador")) if f.get("marcador") is String else "marcador"
	var marcador: Node3D = Marcador.criar(altura_m, forma, _entradas)
	_entradas += 1
	no.add_child(marcador)
	var rotulo := Label3D.new()
	rotulo.name = "Rotulo"
	rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	rotulo.no_depth_test = true
	rotulo.font_size = 48
	rotulo.pixel_size = 0.01
	rotulo.outline_size = 8
	rotulo.position.y = float(marcador.get_meta("altura_m")) + 0.35
	no.add_child(rotulo)
	return no


func _material(cor: Color, sem_luz: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	if cor.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if sem_luz:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m
