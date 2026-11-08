extends Node3D
## Arena 3D do ecrã do Mestre (§12 do desenho JV3.1, I0004 08/11/2026).
##
## Vive dentro de um SubViewport no lado esquerdo do ecrã do Mestre. Desenha a grelha da arena e TODAS as
## figuras colocadas (as não colocadas, as únicas que a Party não vê, ficam só na aba Figuras), com a
## mesma câmara da mesa (camera/camera_mesa.gd: fixa, 360°, panorama, zoom e arrasto). A figura da vez
## leva um anel. Pode destacar casas (as do «Mover» da aba Agir) e diz que casa o Mestre tocou
## (`casa_tocada`), para o «Colocar» e o «Mover». Os marcadores são provisórios, como os da arena da
## jogadora: o visual é do Plano B. Nunca calcula regra: as casas destacadas vêm do servidor.

signal casa_tocada(casa: Vector2i)

const CameraMesa := preload("res://camera/camera_mesa.gd")
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")

const COR_CHAO := Color(0.30, 0.42, 0.26)
const COR_LINHAS := Color(0.0, 0.0, 0.0, 0.35)
const COR_DESTAQUE := Color(0.30, 0.75, 1.0, 0.45)
const COR_LADO := {"jogadora": Color(0.40, 0.70, 1.0), "criatura": Color(0.85, 0.35, 0.30), "npc": Color(0.95, 0.80, 0.35)}
const COR_MORTA := Color(0.35, 0.35, 0.35)
const COR_ANEL := Color(1.0, 0.95, 0.4)

var largura := 0
var altura := 0
var casa_m := 1.5
var camera: CameraMesa

var _grelha: Node3D
var _figuras: Node3D
var _destaques: MultiMeshInstance3D
var _anel: MeshInstance3D
var _nos: Dictionary = {}  # figuraId -> Node3D
var _casas_destacadas: Array[Vector2i] = []


func _ready() -> void:
	var ambiente := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.18, 0.2, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.88, 0.92)
	env.ambient_light_energy = 0.6
	ambiente.environment = env
	add_child(ambiente)
	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
	add_child(sol)
	camera = CameraMesa.new()
	camera.name = "Camera"
	add_child(camera)
	camera.current = true
	camera.toque.connect(_ao_toque)
	_grelha = Node3D.new()
	_grelha.name = "Grelha"
	add_child(_grelha)
	_figuras = Node3D.new()
	_figuras.name = "Figuras"
	add_child(_figuras)
	_destaques = MultiMeshInstance3D.new()
	_destaques.name = "Destaques"
	add_child(_destaques)
	_anel = MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.5
	toro.outer_radius = 0.62
	toro.material = _material(COR_ANEL, true)
	_anel.mesh = toro
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
		var cor: Color = COR_MORTA if f.get("vivo") == false else COR_LADO.get(str(f.get("lado", "")), Color.GRAY)
		((no.get_child(0) as MeshInstance3D).mesh as CylinderMesh).material = _material(cor, false)
		(no.get_child(1) as Label3D).text = Modelo.nome_mestre(f)
		no.rotation_degrees.x = 80.0 if (f.get("caido") == true or f.get("vivo") == false) else 0.0
	for id in _nos.keys():
		if not vistos.has(id):
			(_nos[id] as Node).queue_free()
			_nos.erase(id)
	var vez := str(vista.get("vezId", "")) if vista.get("vezId") is String else ""
	_anel.visible = _nos.has(vez)
	if _anel.visible:
		_anel.position = (_nos[vez] as Node3D).position + Vector3(0.0, 0.03, 0.0)
		_anel.scale = Vector3.ONE * casa_m * 0.7


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
		return
	var quad := QuadMesh.new()
	quad.size = Vector2(casa_m * 0.9, casa_m * 0.9)
	quad.orientation = PlaneMesh.FACE_Y
	quad.material = _material(COR_DESTAQUE, true)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = casas.size()
	for i in casas.size():
		mm.set_instance_transform(i, Transform3D(Basis(), centro_da_casa(casas[i]) + Vector3(0.0, 0.02, 0.0)))
	_destaques.multimesh = mm


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
	var corpo := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = casa_m * 0.3
	cil.bottom_radius = casa_m * 0.34
	cil.height = casa_m * 1.1
	corpo.mesh = cil
	corpo.position.y = cil.height * 0.5
	no.add_child(corpo)
	var rotulo := Label3D.new()
	rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	rotulo.no_depth_test = true
	rotulo.font_size = 48
	rotulo.pixel_size = 0.01
	rotulo.outline_size = 8
	rotulo.position.y = casa_m * 1.5
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
