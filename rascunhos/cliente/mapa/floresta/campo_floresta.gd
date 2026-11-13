extends Node3D
## campo_floresta.gd — ORDEM 37: o campo de batalha da FLORESTA (jogo Assimilação).
##
## Constrói o mapa inteiro na carga, a partir de UMA função de relevo (relevo_floresta.gd) e de
## UMA paleta (paleta_floresta.gd). Receita do fundo: ESTUDO-ELDEN.md (obrigatória).
##
##   Arena (0–30 m do centro; o quadrado jogável de 60×60 m) ... 3D real: relevo, relva alta
##     que se mexe, árvores, pedras, arbustos. O orçamento vai todo aqui.
##   Orla (até ~16 m para lá da arena) ......................... 3D real: a cinta de floresta.
##   Anel próximo (~46–100 m) ................................. geometria pobre, UMA malha,
##     tinta com a luz e o ar cozinhados (cor do vértice) + névoa do motor por cima.
##   Anel longe (135–245 m) ................................... 3 silhuetas planas em anel
##     FECHADO, UMA malha, todo o ar na tinta (fora da névoa do motor).
##   Árvore-âncora (215 m, a norte) ........................... 3D real, simples e gigante.
##   Céu ....................................................... pintura (textura), 1 passagem.
##
## SEM fogueira. SEM disco de terra no meio. Qualidade uniforme: a mesma densidade de relva,
## pedra e árvore em toda a arena (os 4 cantos têm árvore, pedra e relevo próprios).
##
## Nós que o jogo pode usar: grupo «sol» (DirectionalLight3D, sem sombra por defeito) e grupo
## «ambiente» (WorldEnvironment). altura_em(x, z) e Relevo.centro_casa(i, j) dão o chão.

const Paleta := preload("res://mapa/floresta/paleta_floresta.gd")
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const Lote := preload("res://mapa/floresta/lote_malha.gd")

const SH_TERRENO := preload("res://mapa/floresta/shaders/terreno.gdshader")
const SH_RELVA := preload("res://mapa/floresta/shaders/relva.gdshader")
const SH_COPA := preload("res://mapa/floresta/shaders/copa.gdshader")
const SH_SOLIDO := preload("res://mapa/floresta/shaders/solido.gdshader")
const SH_ANEL_PERTO := preload("res://mapa/floresta/shaders/anel_perto.gdshader")
const SH_ANEL_LONGE := preload("res://mapa/floresta/shaders/anel_longe.gdshader")
const SH_CEU := preload("res://mapa/floresta/shaders/ceu_panorama.gdshader")

const CEU_PNG := "res://mapa/floresta/ceu/ceu_floresta_v2.png"
const CEU_ELEV_MIN := -6.0
const MAPA_N := 384          # resolução do mapa do chão (luz/terra)
const MAPA_MEIO := 66.0      # o mapa do chão cobre [-66, 66] m
const BLOCO_RELVA := 20.0    # lado de cada bloco de relva (1 MultiMesh = 1 draw call)
const ANCORA_DIST := 215.0
const ANCORA_ALTURA := 96.0

## Vistas etiquetadas (capturas e teclas 1–9): nome, x, z, altura dos olhos, azimute, inclinação.
const VISTAS: Array = [
	["centro_olha-norte", 0.0, 0.0, 1.7, -7.0, 3.0],
	["centro_olha-leste", 0.0, 0.0, 1.7, 90.0, 3.0],
	["centro_olha-sul", 0.0, 0.0, 1.7, 180.0, 3.0],
	["centro_olha-oeste", 0.0, 0.0, 1.7, -90.0, 3.0],
	["canto-NO_olha-centro", -28.0, -28.0, 1.7, 135.0, 0.0],
	["canto-NE_olha-centro", 28.0, -28.0, 1.7, -135.0, 0.0],
	["canto-SE_olha-centro", 28.0, 28.0, 1.7, -45.0, 0.0],
	["canto-SO_olha-centro", -28.0, 28.0, 1.7, 45.0, 0.0],
	["canto-NO_olha-fora", -28.0, -28.0, 1.7, -45.0, 4.0],
	["canto-NE_olha-fora", 28.0, -28.0, 1.7, 45.0, 4.0],
	["canto-SE_olha-fora", 28.0, 28.0, 1.7, 135.0, 4.0],
	["canto-SO_olha-fora", -28.0, 28.0, 1.7, -135.0, 4.0],
	["longe_vista-ref07", 5.0, 27.0, 2.3, -11.0, 1.0],
	["alto_mapa-inteiro", 0.0, 62.0, 46.0, 0.0, -38.0],
]

@export var semente: int = 37
## Fracção dos tufos de relva desenhada (perfis: 1,0 alto · 0,7 médio · 0,45 baixo).
@export_range(0.1, 1.0) var densidade_relva: float = 1.0
@export var mostrar_medicao: bool = true

@onready var _ambiente: WorldEnvironment = $Ambiente
@onready var _sol: DirectionalLight3D = $Sol
@onready var _camera: Camera3D = $Camera
@onready var _rotulo: Label = $Medicao/Rotulo

var arena: Node3D
var fundo: Node3D
var medidas: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _mats: Array[ShaderMaterial] = []
var _ruido_tex: Texture2D
var _mapa_tex: ImageTexture
var _luz := PackedFloat32Array()      # sol que chega (árvores + pedras)
var _luz_copas := PackedFloat32Array()  # sol que chega (só copas)
var _terra := PackedFloat32Array()    # terra à mostra / relva excluída
var _arvores: Array = []              # {pos, h, r, topo, bolhas: [[centro, raio]]}
var _rochas: Array = []               # [centro: Vector3, raio: float]
var _relva_mms: Array[MultiMesh] = []
var _t_rotulo := 0.0


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	_rng.seed = semente
	arena = Node3D.new()
	arena.name = "Arena"
	add_child(arena)
	fundo = Node3D.new()
	fundo.name = "Fundo"
	add_child(fundo)
	_luz.resize(MAPA_N * MAPA_N)
	_luz.fill(1.0)
	_terra.resize(MAPA_N * MAPA_N)
	_terra.fill(0.0)
	_ruido_tex = _gerar_ruido()
	_montar_ambiente()
	_plantar_arvores()
	_semear_rochas()
	_riscar_trilho()
	_cozer_mapa_chao()
	_criar_terreno()
	_criar_arvores()
	_criar_rochas()
	_criar_arbustos()
	_criar_relva()
	_criar_anel_perto()
	_criar_anel_longe()
	_criar_ancora()
	_escrever_materiais()
	ir_para_vista(0)
	_rotulo.visible = mostrar_medicao
	medidas["carga_ms"] = Time.get_ticks_msec() - t0
	print("[floresta] pronta em %d ms | %s" % [medidas["carga_ms"], JSON.stringify(medidas)])


func _process(delta: float) -> void:
	if not mostrar_medicao:
		return
	_t_rotulo += delta
	if _t_rotulo >= 0.5:
		_t_rotulo = 0.0
		_rotulo.text = "Floresta 37 | %d fps | %d chamadas | %d primitivas | teclas 1-9 vistas, F fundo, WASD andar" % [
			Engine.get_frames_per_second(),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)]


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode >= KEY_1 and k.keycode <= KEY_9:
		ir_para_vista(k.keycode - KEY_1)
	elif k.keycode == KEY_0:
		ir_para_vista(12)
	elif k.keycode == KEY_F:
		so_fundo(arena.visible)
	elif k.keycode == KEY_M:
		_rotulo.visible = not _rotulo.visible


# ------------------------------------------------------------------ API

func altura_em(x: float, z: float) -> float:
	return Relevo.altura(x, z)


## Esconde a arena e deixa só o fundo (céu + anéis + âncora) — para MEDIR os draw calls do fundo.
func so_fundo(ligar: bool) -> void:
	arena.visible = not ligar


func ir_para_vista(i: int) -> void:
	if i < 0 or i >= VISTAS.size():
		return
	var v: Array = VISTAS[i]
	var x: float = v[1]
	var z: float = v[2]
	_camera.position = Vector3(x, Relevo.altura(x, z) + float(v[3]), z)
	_camera.rotation = Vector3(deg_to_rad(float(v[5])), -deg_to_rad(float(v[4])), 0.0)
	if _camera.has_method("ler_transformacao"):
		_camera.call("ler_transformacao")


func definir_densidade_relva(f: float) -> void:
	densidade_relva = clampf(f, 0.1, 1.0)
	for mm in _relva_mms:
		mm.visible_instance_count = int(round(mm.instance_count * densidade_relva)) if densidade_relva < 0.999 else -1


# ------------------------------------------------------------------ ambiente e materiais

func _montar_ambiente() -> void:
	var env := _ambiente.environment
	var mat_ceu := ShaderMaterial.new()
	mat_ceu.shader = SH_CEU
	var tex: Texture2D
	if ResourceLoader.exists(CEU_PNG):
		tex = load(CEU_PNG) as Texture2D
	if tex == null:
		# Projecto ainda não importado (clone fresco): lê o PNG directamente.
		var img := Image.load_from_file(ProjectSettings.globalize_path(CEU_PNG))
		if img != null:
			tex = ImageTexture.create_from_image(img)
	mat_ceu.set_shader_parameter("pintura", tex)
	mat_ceu.set_shader_parameter("cor_horizonte", Paleta.COR_HORIZONTE)      # (a) a faixa baixa do céu
	mat_ceu.set_shader_parameter("faixa", Paleta.FAIXA_HORIZONTE)
	mat_ceu.set_shader_parameter("elev_min_graus", CEU_ELEV_MIN)
	var sky := Sky.new()
	sky.sky_material = mat_ceu
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Paleta.COR_CEU_AMBIENTE
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Paleta.COR_HORIZONTE                               # (b) a névoa
	env.fog_light_energy = 1.0
	env.fog_sun_scatter = 0.0
	env.fog_density = Paleta.NEVOA_TECTO
	env.fog_depth_begin = Paleta.NEVOA_INICIO
	env.fog_depth_end = Paleta.NEVOA_FIM
	env.fog_depth_curve = Paleta.NEVOA_CURVA
	env.fog_sky_affect = 0.0   # o céu é pintura: a sua faixa baixa JÁ é a cor do horizonte
	env.fog_aerial_perspective = 0.0
	# O sol do jogo (para as figuras): mesma direcção e cor da luz pintada. Sem sombra por
	# defeito — as sombras do cenário vêm cozidas no mapa do chão.
	var l := Paleta.dir_luz()
	_sol.look_at_from_position(Vector3.ZERO, -l, Vector3.UP)
	_sol.light_color = Paleta.COR_SOL
	_sol.light_energy = 1.1
	_sol.shadow_enabled = false


func _mat(sh: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = sh
	_mats.append(m)
	return m


## A luz pintada e o mapa do chão escrevem-se em TODOS os materiais da arena, num sítio só.
func _escrever_materiais() -> void:
	for m in _mats:
		m.set_shader_parameter("dir_luz", Paleta.dir_luz())
		m.set_shader_parameter("cor_sol", Paleta.COR_SOL)
		m.set_shader_parameter("cor_sombra", Paleta.COR_SOMBRA)
		m.set_shader_parameter("cor_ceu", Paleta.COR_CEU_AMBIENTE)
		m.set_shader_parameter("mapa_chao", _mapa_tex)
		m.set_shader_parameter("mapa_meio", MAPA_MEIO)
		m.set_shader_parameter("ruido", _ruido_tex)


func _gerar_ruido() -> Texture2D:
	var r := FastNoiseLite.new()
	r.seed = semente + 5
	r.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	r.frequency = 0.035
	r.fractal_octaves = 4
	var img: Image = r.get_seamless_image(256, 256)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _rf(a: float, b: float) -> float:
	return _rng.randf_range(a, b)


# ------------------------------------------------------------------ mapa do chão (luz + terra)

func _mi(x: float) -> int:
	return int((x + MAPA_MEIO) / (2.0 * MAPA_MEIO) * MAPA_N)


## Carimbo elíptico suave: baixa `arr` até (1 - forca) no centro. `dir` = eixo maior (unitário).
func _carimbo_min(arr: PackedFloat32Array, cx: float, cz: float, ra: float, rb: float, dir: Vector2, forca: float) -> void:
	var ext := maxf(ra, rb)
	var x0 := clampi(_mi(cx - ext), 0, MAPA_N - 1)
	var x1 := clampi(_mi(cx + ext), 0, MAPA_N - 1)
	var z0 := clampi(_mi(cz - ext), 0, MAPA_N - 1)
	var z1 := clampi(_mi(cz + ext), 0, MAPA_N - 1)
	var passo := 2.0 * MAPA_MEIO / MAPA_N
	var perp := Vector2(-dir.y, dir.x)
	for iz in range(z0, z1 + 1):
		var wz := -MAPA_MEIO + (iz + 0.5) * passo - cz
		for ix in range(x0, x1 + 1):
			var wx := -MAPA_MEIO + (ix + 0.5) * passo - cx
			var a := (wx * dir.x + wz * dir.y) / ra
			var b := (wx * perp.x + wz * perp.y) / rb
			var q := a * a + b * b
			if q < 1.0:
				var s := forca * (1.0 - smoothstep(0.45, 1.0, q))
				var i := iz * MAPA_N + ix
				if 1.0 - s < arr[i]:
					arr[i] = 1.0 - s


func _carimbo_max(arr: PackedFloat32Array, cx: float, cz: float, raio: float, forca: float) -> void:
	var x0 := clampi(_mi(cx - raio), 0, MAPA_N - 1)
	var x1 := clampi(_mi(cx + raio), 0, MAPA_N - 1)
	var z0 := clampi(_mi(cz - raio), 0, MAPA_N - 1)
	var z1 := clampi(_mi(cz + raio), 0, MAPA_N - 1)
	var passo := 2.0 * MAPA_MEIO / MAPA_N
	for iz in range(z0, z1 + 1):
		var wz := -MAPA_MEIO + (iz + 0.5) * passo - cz
		for ix in range(x0, x1 + 1):
			var wx := -MAPA_MEIO + (ix + 0.5) * passo - cx
			var q := (wx * wx + wz * wz) / (raio * raio)
			if q < 1.0:
				var s := forca * (1.0 - smoothstep(0.35, 1.0, q))
				var i := iz * MAPA_N + ix
				if s > arr[i]:
					arr[i] = s


func _terra_em(x: float, z: float) -> float:
	var ix := _mi(x)
	var iz := _mi(z)
	if ix < 0 or iz < 0 or ix >= MAPA_N or iz >= MAPA_N:
		return 0.0
	return _terra[iz * MAPA_N + ix]


## Onde cai no chão a sombra de um ponto a `p` (a luz vem de dir_luz).
func _sombra_de(p: Vector3) -> Vector2:
	var l := Paleta.dir_luz()
	var g := Vector2(p.x, p.z)
	for volta in 2:
		var alt := maxf(p.y - Relevo.altura(g.x, g.y), 0.0)
		g = Vector2(p.x, p.z) - Vector2(l.x, l.z) * (alt / l.y)
	return g


func _cozer_mapa_chao() -> void:
	var l := Paleta.dir_luz()
	var dir := Vector2(l.x, l.z).normalized()
	var estica := 1.0 / l.y
	# 1) copas (e troncos) — o canal «só copas» é copiado antes das pedras
	for a in _arvores:
		for b in a["bolhas"]:
			var c: Vector3 = b[0]
			var r: float = b[1]
			var g := _sombra_de(c)
			_carimbo_min(_luz, g.x, g.y, r * estica * 0.8, r * 0.95, dir, 0.92)
		var pos: Vector3 = a["pos"]
		var topo: float = a["topo"]
		var rt: float = a["r"]
		var n := int(topo / 0.45)
		for s in n:
			var g2 := _sombra_de(pos + Vector3(0, float(s) * 0.45, 0))
			_carimbo_min(_luz, g2.x, g2.y, rt * 1.5, rt * 1.5, dir, 0.85)
	_luz_copas = _luz.duplicate()
	# 2) pedras
	for r in _rochas:
		var c2: Vector3 = r[0]
		var raio: float = r[1]
		var g3 := _sombra_de(c2 + Vector3(0, raio * 0.2, 0))
		_carimbo_min(_luz, g3.x, g3.y, raio * 0.9 * (1.0 + 0.5 * estica), raio * 0.95, dir, 0.9)
	var img := Image.create_empty(MAPA_N, MAPA_N, false, Image.FORMAT_RGB8)
	var dados := PackedByteArray()
	dados.resize(MAPA_N * MAPA_N * 3)
	for i in MAPA_N * MAPA_N:
		dados[i * 3] = int(clampf(_luz[i], 0.0, 1.0) * 255.0)
		dados[i * 3 + 1] = int(clampf(_terra[i], 0.0, 1.0) * 255.0)
		dados[i * 3 + 2] = int(clampf(_luz_copas[i], 0.0, 1.0) * 255.0)
	img.set_data(MAPA_N, MAPA_N, false, Image.FORMAT_RGB8, dados)
	_mapa_tex = ImageTexture.create_from_image(img)


## Um trilho de bicho, estreito e torto, que passa LONGE do centro (sem disco de terra no meio).
func _riscar_trilho() -> void:
	var pts: Array[Vector2] = [Vector2(-34, 19), Vector2(-22, 15), Vector2(-12, 19), Vector2(-2, 21),
		Vector2(8, 15.5), Vector2(15, 7), Vector2(23, 1), Vector2(29, -7), Vector2(36, -10)]
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var n := int(a.distance_to(b) / 0.35)
		for s in n:
			var p := a.lerp(b, float(s) / n)
			var desvio := Relevo.ruido().get_noise_2d(p.x * 9.0, p.y * 9.0) * 0.9
			var larg := 0.55 + 0.35 * Relevo.ruido().get_noise_2d(p.x * 20.0 + 9.0, p.y * 20.0)
			var perp := (b - a).orthogonal().normalized()
			_carimbo_max(_terra, p.x + perp.x * desvio, p.y + perp.y * desvio, maxf(larg, 0.35), 0.75)


# ------------------------------------------------------------------ terreno

func _criar_terreno() -> void:
	var meio := int(Relevo.MEIO_3D)
	var n := meio * 2 + 1
	var alt := PackedFloat32Array()
	alt.resize(n * n)
	for j in n:
		for i in n:
			alt[j * n + i] = Relevo.altura(float(i - meio), float(j - meio))
	var v := PackedVector3Array()
	var nor := PackedVector3Array()
	v.resize(n * n)
	nor.resize(n * n)
	var fora := PackedFloat32Array()
	fora.resize(n * n)
	for j in n:
		for i in n:
			var x := float(i - meio)
			var z := float(j - meio)
			var f := Relevo.fora(x, z)
			fora[j * n + i] = f
			var h := alt[j * n + i]
			# a orla do terreno real mergulha por baixo da saia do anel (fecha a emenda)
			if f > Relevo.ANEL_DENTRO + 2.5:
				h -= 1.4 * smoothstep(Relevo.ANEL_DENTRO + 2.5, Relevo.ANEL_DENTRO + 4.5, f)
			v[j * n + i] = Vector3(x, h, z)
			var hx0 := alt[j * n + maxi(i - 1, 0)]
			var hx1 := alt[j * n + mini(i + 1, n - 1)]
			var hz0 := alt[maxi(j - 1, 0) * n + i]
			var hz1 := alt[mini(j + 1, n - 1) * n + i]
			nor[j * n + i] = Vector3(hx0 - hx1, 2.0, hz0 - hz1).normalized()
	var idx := PackedInt32Array()
	var limite := Relevo.ANEL_DENTRO + 4.5
	for j in n - 1:
		for i in n - 1:
			var a := j * n + i
			if fora[a] > limite and fora[a + 1] > limite and fora[a + n] > limite and fora[a + n + 1] > limite:
				continue
			idx.append_array([a, a + 1, a + n, a + 1, a + n + 1, a + n])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nor
	arr[Mesh.ARRAY_INDEX] = idx
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.name = "Terreno"
	mi.mesh = malha
	var m := _mat(SH_TERRENO)
	m.set_shader_parameter("cor_relva", Paleta.CHAO_RELVA)
	m.set_shader_parameter("cor_relva_seca", Paleta.RELVA_SECA.darkened(0.25))
	m.set_shader_parameter("cor_terra", Paleta.CHAO_TERRA)
	m.set_shader_parameter("cor_musgo", Paleta.CHAO_MUSGO)
	m.set_shader_parameter("cor_pedra", Paleta.PEDRA)
	mi.material_override = m
	arena.add_child(mi)
	medidas["terreno_tri"] = idx.size() / 3
	# Colisão (jogável): o mesmo relevo, em HeightMapShape3D de 1 m.
	var corpo := StaticBody3D.new()
	corpo.name = "ChaoColisao"
	var forma := HeightMapShape3D.new()
	forma.map_width = n
	forma.map_depth = n
	forma.map_data = alt
	var cs := CollisionShape3D.new()
	cs.shape = forma
	corpo.add_child(cs)
	arena.add_child(corpo)


# ------------------------------------------------------------------ árvores

func _plantar_arvores() -> void:
	# Dentro da arena: postas à mão — orla e cantos, três no interior, nenhuma no centro
	# e nenhuma na linha da janela norte (a vista da árvore-âncora).
	var dentro: Array = [
		[-25.0, -22.5, 15.0], [-27.0, 3.0, 13.5], [-22.0, 25.0, 16.0], [1.5, 27.8, 14.0],
		[26.0, 25.5, 15.5], [27.0, -4.0, 13.0], [23.5, -25.0, 14.5],
		[-10.0, 13.0, 12.5], [11.5, -15.0, 11.5], [-16.0, -13.0, 12.0]]
	for d in dentro:
		_registar_arvore(float(d[0]), float(d[1]), float(d[2]))
	# A cinta de floresta na orla: ao acaso com distância mínima; a janela norte fica aberta.
	var tentativas := 0
	var postas := 0
	while postas < 118 and tentativas < 9000:
		tentativas += 1
		var x := _rf(-51.0, 51.0)
		var z := _rf(-51.0, 51.0)
		var f := Relevo.fora(x, z)
		if f < 1.8 or f > Relevo.ANEL_DENTRO + 1.5:
			continue
		if Relevo.na_janela(x, z):
			continue
		var livre := true
		for a in _arvores:
			var p: Vector3 = a["pos"]
			if Vector2(p.x - x, p.z - z).length_squared() < 5.0 * 5.0:
				livre = false
				break
		if not livre:
			continue
		_registar_arvore(x, z, _rf(11.0, 16.5))
		postas += 1
	medidas["arvores"] = _arvores.size()


func _registar_arvore(x: float, z: float, h: float) -> void:
	var pos := Vector3(x, Relevo.altura(x, z) - 0.15, z)
	var raio := h * _rf(0.030, 0.040)
	var topo := h * _rf(0.50, 0.60)
	var incl := Vector3(_rf(-0.10, 0.10), 0.0, _rf(-0.10, 0.10))
	var fase := _rf(0.0, 1.0)
	var cimo := pos + Vector3(incl.x * topo, topo, incl.z * topo)
	var bolhas: Array = []
	var nb := _rng.randi_range(5, 7)
	for b in nb:
		var ang := TAU * (float(b) + _rf(-0.3, 0.3)) / float(nb)
		var dist := h * _rf(0.14, 0.26)
		var sobe := h * _rf(0.05, 0.24)
		var c := cimo + Vector3(cos(ang) * dist, sobe, sin(ang) * dist)
		bolhas.append([c, h * _rf(0.17, 0.24)])
	bolhas.append([cimo + Vector3(_rf(-0.6, 0.6), h * _rf(0.26, 0.34), _rf(-0.6, 0.6)), h * _rf(0.19, 0.25)])
	_arvores.append({"pos": pos, "h": h, "r": raio, "topo": topo, "incl": incl, "fase": fase, "cimo": cimo, "bolhas": bolhas})
	# raízes: terra à mostra em volta do tronco, relva excluída no pé
	_carimbo_max(_terra, x, z, raio * 2.2 + 1.1, 0.95)


func _criar_arvores() -> void:
	# 4 quadrantes × (troncos, copas) = 8 malhas: o corte por frustum trabalha por quadrante.
	var troncos: Array = [Lote.new(), Lote.new(), Lote.new(), Lote.new()]
	var copas: Array = [Lote.new(), Lote.new(), Lote.new(), Lote.new()]
	for a in _arvores:
		var pos: Vector3 = a["pos"]
		var q := (0 if pos.x < 0.0 else 1) + (0 if pos.z < 0.0 else 2)
		var lt: Lote = troncos[q]
		var lc: Lote = copas[q]
		var h: float = a["h"]
		var raio: float = a["r"]
		var topo: float = a["topo"]
		var incl: Vector3 = a["incl"]
		var fase: float = a["fase"]
		var cimo: Vector3 = a["cimo"]
		var casca := Paleta.CASCA.lerp(Color("#7a6a55"), _rf(0.0, 0.45))
		var casca_base := casca.darkened(0.30)
		casca_base.a = 0.80
		# tronco: 7 níveis, raiz alargada, leve torção
		var pts: Array = []
		for i in 7:
			var t := float(i) / 6.0
			var y := t * topo
			var c := pos + Vector3(incl.x * y + sin(t * 3.0 + fase * 6.0) * 0.22 * t, y, incl.z * y + cos(t * 2.3 + fase * 4.0) * 0.22 * t)
			var r := raio * lerpf(1.0, 0.58, t) * (1.0 + 1.1 * exp(-y / (raio * 1.8)))
			pts.append([c, r])
		pts[6][0] = cimo
		lt.tubo(pts, 8, casca_base, casca, false)
		# ramos até às bolhas + as bolhas
		# perto da arena a copa tem mais malha (silhueta mais rica); na orla funda basta menos
		var sub := 2 if Relevo.fora(pos.x, pos.z) < 9.0 else 1
		var centro_vol := cimo + Vector3(0, h * 0.14, 0)
		var bolhas: Array = a["bolhas"]
		for bi in bolhas.size():
			var b: Array = bolhas[bi]
			var c2: Vector3 = b[0]
			var rb: float = b[1]
			var base_ramo := cimo - Vector3(0, _rf(0.0, 0.18) * topo, 0)
			var meio_ramo := base_ramo.lerp(c2, 0.5) + Vector3(0, -0.06 * h, 0)
			lt.tubo([[base_ramo, raio * 0.42], [meio_ramo, raio * 0.30], [c2, raio * 0.14]], 5, casca, casca, false)
			var tinta := Paleta.COPA_A.lerp(Paleta.COPA_B, _rf(0.0, 1.0))
			if _rng.randf() < 0.16:
				tinta = tinta.lerp(Paleta.COPA_OURO, _rf(0.3, 0.6))
			lc.bolha(c2, Vector3(rb, rb * _rf(0.66, 0.80), rb), sub, tinta, _rf(0.0, 90.0), centro_vol, fase, 1.0)
	var mat_tronco := _mat(SH_SOLIDO)
	mat_tronco.set_shader_parameter("cor_musgo", Paleta.PEDRA_MUSGO)
	mat_tronco.set_shader_parameter("forca_musgo", 0.45)
	var mat_copa := _mat(SH_COPA)
	mat_copa.set_shader_parameter("cor_ouro", Paleta.COPA_OURO)
	var tri := 0
	for q in 4:
		var lt2: Lote = troncos[q]
		var lc2: Lote = copas[q]
		if not lt2.vazio():
			_instancia(arena, lt2.fechar(), mat_tronco, "Troncos%d" % q)
			tri += lt2.triangulos()
		if not lc2.vazio():
			var mi := _instancia(arena, lc2.fechar(), mat_copa, "Copas%d" % q)
			mi.extra_cull_margin = 1.0
			tri += lc2.triangulos()
	medidas["arvores_tri"] = tri


func _instancia(pai: Node3D, malha: Mesh, mat: Material, nome: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = malha
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)
	return mi


# ------------------------------------------------------------------ pedras

func _semear_rochas() -> void:
	# À mão: a escarpa do terraço (sueste), o cômoro (oeste), a beira da cova (nordeste),
	# o miradouro da janela (norte) e pedras soltas pelos 4 quadrantes.
	var lugares: Array = [
		[10.3, 12.0, 2.6], [12.2, 9.2, 1.8], [9.3, 15.8, 2.0], [14.8, 7.8, 1.3], [11.2, 19.4, 1.5], [20.5, 14.0, 1.0],
		[-14.8, 6.3, 1.6], [-11.4, 9.6, 1.0], [-15.6, 10.2, 0.7],
		[4.0, -8.0, 1.2], [12.6, -7.4, 0.9], [6.4, -15.8, 1.4],
		[-6.5, -30.5, 2.3], [-1.0, -32.5, 1.5], [-10.5, -29.0, 1.1], [3.5, -30.0, 0.8],
		[-22.0, -8.0, 2.1], [-6.0, -20.0, 1.6], [20.0, -14.0, 1.9], [-4.0, 18.5, 1.2], [24.5, 6.5, 1.5],
		[-24.0, 16.5, 1.3], [1.5, -4.5, 0.55], [-7.0, -6.0, 0.8], [-19.0, -22.0, 1.4], [17.0, 24.5, 1.7],
		[-27.5, 27.0, 1.6], [27.5, -27.0, 1.8], [-28.0, -27.5, 1.3], [5.5, 5.0, 0.6], [-2.0, 9.0, 0.45]]
	for g in lugares:
		_registar_rocha(float(g[0]), float(g[1]), float(g[2]))
		# satélites: 1–2 pedras menores encostadas
		for s in _rng.randi_range(1, 2):
			var ang := _rf(0.0, TAU)
			var d := float(g[2]) * _rf(0.9, 1.4)
			_registar_rocha(float(g[0]) + cos(ang) * d, float(g[1]) + sin(ang) * d, float(g[2]) * _rf(0.25, 0.5))
	# Na orla: ao acaso.
	var postas := 0
	var tentativas := 0
	while postas < 34 and tentativas < 2000:
		tentativas += 1
		var x := _rf(-48.0, 48.0)
		var z := _rf(-48.0, 48.0)
		var f := Relevo.fora(x, z)
		if f < 0.5 or f > Relevo.ANEL_DENTRO:
			continue
		if _terra_em(x, z) > 0.3:
			continue
		_registar_rocha(x, z, _rf(0.6, 2.4))
		postas += 1
	medidas["rochas"] = _rochas.size()


func _registar_rocha(x: float, z: float, tam: float) -> void:
	_rochas.append([Vector3(x, Relevo.altura(x, z), z), tam])
	_carimbo_max(_terra, x, z, tam * 1.25 + 0.25, 1.0)


func _criar_rochas() -> void:
	var lote := Lote.new()
	for r in _rochas:
		var c: Vector3 = r[0]
		var tam: float = r[1]
		var esc := Vector3(tam * _rf(0.85, 1.25), tam * _rf(0.55, 0.9), tam * _rf(0.85, 1.25))
		var rot := Basis(Vector3.UP, _rf(0.0, TAU)) * Basis(Vector3.RIGHT, _rf(-0.25, 0.25))
		var cor := Paleta.PEDRA.lerp(Color("#a09a86"), _rf(0.0, 0.6))
		lote.rocha(c + Vector3(0, esc.y * 0.22, 0), esc, rot, 2 if tam > 1.1 else 1, cor, _rf(0.0, 60.0))
	var m := _mat(SH_SOLIDO)
	m.set_shader_parameter("cor_musgo", Paleta.PEDRA_MUSGO)
	m.set_shader_parameter("forca_musgo", 0.85)
	m.set_shader_parameter("musgo_liso", 1.0)
	_instancia(arena, lote.fechar(), m, "Pedras")
	medidas["rochas_tri"] = lote.triangulos()


# ------------------------------------------------------------------ arbustos

func _criar_arbustos() -> void:
	var l := Lote.new()
	l.bolha(Vector3(0, 0.42, 0), Vector3(0.9, 0.62, 0.9), 1, Color.WHITE, 3.0, Vector3(0, -0.2, 0), 0.0, 0.5, 0.36)
	l.bolha(Vector3(0.55, 0.30, 0.25), Vector3(0.55, 0.42, 0.55), 1, Color(0.92, 0.95, 0.9), 11.0, Vector3(0, -0.2, 0), 0.3, 0.5, 0.36)
	var malha := l.fechar()
	var lugares: Array[Transform3D] = []
	var cores: Array[Color] = []
	var tent := 0
	# espalhados pela arena e pela orla, mais cerrados junto à floresta e às pedras
	while lugares.size() < 230 and tent < 6000:
		tent += 1
		var x := _rf(-47.0, 47.0)
		var z := _rf(-47.0, 47.0)
		var f := Relevo.fora(x, z)
		if f > Relevo.ANEL_DENTRO:
			continue
		var prob := 0.10 + 0.55 * smoothstep(-9.0, 2.0, f)
		for r in _rochas:
			var c: Vector3 = r[0]
			if Vector2(c.x - x, c.z - z).length() < float(r[1]) * 1.5 + 1.2:
				prob = 0.7
				break
		if Relevo.na_janela(x, z) and f > -2.0:
			prob *= 0.35
		if _rng.randf() > prob or _terra_em(x, z) > 0.5:
			continue
		var s := _rf(0.7, 1.7)
		var b := Basis(Vector3.UP, _rf(0.0, TAU)).scaled(Vector3(s, s * _rf(0.8, 1.2), s))
		lugares.append(Transform3D(b, Vector3(x, Relevo.altura(x, z) - 0.05, z)))
		var tinta := Paleta.COPA_A.lerp(Paleta.COPA_B, _rf(0.2, 1.0))
		tinta.a = 1.0
		cores.append(tinta)
		_carimbo_max(_terra, x, z, s * 0.75, 0.7)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = malha
	mm.instance_count = lugares.size()
	for i in lugares.size():
		mm.set_instance_transform(i, lugares[i])
		mm.set_instance_color(i, cores[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Arbustos"
	mmi.multimesh = mm
	var m := _mat(SH_COPA)
	m.set_shader_parameter("cor_ouro", Paleta.COPA_OURO)
	m.set_shader_parameter("vento_forca", 0.10)
	mmi.material_override = m
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena.add_child(mmi)
	medidas["arbustos"] = lugares.size()
	medidas["arbustos_tri"] = lugares.size() * l.triangulos()
	# a sombra dos arbustos entra no mapa do chão (pequena, ao pé)
	var luz := Paleta.dir_luz()
	var dir := Vector2(luz.x, luz.z).normalized()
	for t in lugares:
		var g := _sombra_de(t.origin + Vector3(0, 0.4, 0))
		_carimbo_min(_luz, g.x, g.y, 1.3 * t.basis.get_scale().x, 0.9 * t.basis.get_scale().x, dir, 0.8)
	_cozer_mapa_chao_final()


## Os arbustos carimbaram luz e terra depois do primeiro cozer: regrava a textura.
func _cozer_mapa_chao_final() -> void:
	var dados := PackedByteArray()
	dados.resize(MAPA_N * MAPA_N * 3)
	for i in MAPA_N * MAPA_N:
		dados[i * 3] = int(clampf(_luz[i], 0.0, 1.0) * 255.0)
		dados[i * 3 + 1] = int(clampf(_terra[i], 0.0, 1.0) * 255.0)
		dados[i * 3 + 2] = int(clampf(_luz_copas[i], 0.0, 1.0) * 255.0)
	var img := Image.create_from_data(MAPA_N, MAPA_N, false, Image.FORMAT_RGB8, dados)
	_mapa_tex = ImageTexture.create_from_image(img)


# ------------------------------------------------------------------ relva

## Um tufo: 6 lâminas de 3 triângulos, abertas em leque, curvas. Altura normalizada (1 = ponta).
func _malha_tufo() -> ArrayMesh:
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for b in 6:
		var ang := TAU * (float(b) + r.randf_range(-0.35, 0.35)) / 6.0
		var fora_dir := Vector3(cos(ang), 0.0, sin(ang))
		var lado := Vector3(-sin(ang + r.randf_range(-0.5, 0.5)), 0.0, cos(ang))
		var larg := r.randf_range(0.030, 0.045)
		var alt := r.randf_range(0.62, 1.0)
		var abre := r.randf_range(0.10, 0.34)
		var pe := fora_dir * r.randf_range(0.02, 0.13)
		var meio := pe + fora_dir * abre * 0.35 + Vector3(0, alt * 0.52, 0)
		var ponta := pe + fora_dir * abre + Vector3(0, alt, 0)
		var base := v.size()
		v.append_array([pe - lado * larg, pe + lado * larg, meio - lado * larg * 0.72, meio + lado * larg * 0.72, ponta])
		uv.append_array([Vector2(0, 0), Vector2(1, 0), Vector2(0, 0.52 * alt), Vector2(1, 0.52 * alt), Vector2(0.5, alt)])
		idx.append_array([base, base + 1, base + 2, base + 1, base + 3, base + 2, base + 2, base + 3, base + 4])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


func _criar_relva() -> void:
	var tufo := _malha_tufo()
	var mat := _mat(SH_RELVA)
	mat.set_shader_parameter("cor_base", Paleta.RELVA_BASE)
	mat.set_shader_parameter("cor_ponta", Paleta.RELVA_PONTA)
	mat.set_shader_parameter("cor_seca", Paleta.RELVA_SECA)
	var rn := Relevo.ruido()
	var limite := Relevo.ANEL_DENTRO + 3.0
	var total := 0
	var blocos := 0
	var meio := 60.0
	var nb := int(2.0 * meio / BLOCO_RELVA)
	for bj in nb:
		for bi in nb:
			var x0 := -meio + bi * BLOCO_RELVA
			var z0 := -meio + bj * BLOCO_RELVA
			var xs: Array[Transform3D] = []
			var cs: Array[Color] = []
			var candidatos := int(BLOCO_RELVA * BLOCO_RELVA * 5.2)
			for k in candidatos:
				var x := x0 + _rng.randf() * BLOCO_RELVA
				var z := z0 + _rng.randf() * BLOCO_RELVA
				var f := Relevo.fora(x, z)
				if f > limite:
					continue
				# densidade: cheia na arena; na orla rareia debaixo da floresta
				var dens := 1.0
				if f > 0.0:
					dens = lerpf(0.85, 0.22, clampf(f / limite, 0.0, 1.0))
				var mancha := rn.get_noise_2d(x * 6.0 + 300.0, z * 6.0)
				dens *= 0.80 + 0.35 * mancha
				var terra := _terra_em(x, z)
				if terra > 0.55:
					continue
				dens *= 1.0 - terra
				if _rng.randf() > dens:
					continue
				var nrm := Relevo.normal(x, z)
				if nrm.y < 0.80:
					continue
				var alto := _rf(0.55, 0.95) * (1.0 + 0.30 * mancha)
				var largo := _rf(0.9, 1.35)
				var b := Basis(Vector3.UP, _rf(0.0, TAU)).scaled(Vector3(largo, alto, largo))
				xs.append(Transform3D(b, Vector3(x, Relevo.altura(x, z) - 0.04, z)))
				var seca := clampf(0.5 + rn.get_noise_2d(x * 3.0 - 200.0, z * 3.0 + 70.0) * 1.4, 0.0, 1.0) * _rf(0.5, 1.0)
				cs.append(Color(_rng.randf(), seca * 0.8, _rng.randf(), 1.0))
			if xs.is_empty():
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_custom_data = true
			mm.mesh = tufo
			mm.instance_count = xs.size()
			for i in xs.size():
				mm.set_instance_transform(i, xs[i])
				mm.set_instance_custom_data(i, cs[i])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Relva_%d_%d" % [bi, bj]
			mmi.multimesh = mm
			mmi.material_override = mat
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mmi.extra_cull_margin = 1.0
			arena.add_child(mmi)
			_relva_mms.append(mm)
			total += xs.size()
			blocos += 1
	medidas["relva_tufos"] = total
	medidas["relva_blocos"] = blocos
	medidas["relva_tri"] = total * 18
	definir_densidade_relva(densidade_relva)


# ------------------------------------------------------------------ o fundo: anel próximo

## Ponto do mundo a `f` metros para fora da orla da arena, no azimute `ang` (radianos).
func _ponto_anel(ang: float, f: float) -> Vector2:
	var dx := sin(ang)
	var dz := -cos(ang)
	var r := (Relevo.MEIO + f) / Relevo.quadrado(dx, dz)
	return Vector2(dx * r, dz * r)


## A tinta do anel próximo: luz cozinhada (lado do sol quente, lado da sombra frio) e depois
## o AR — a cor do horizonte entra com a distância e com a baixa do vale (a bruma assenta).
func _tinta_perto(cor: Color, nrm: Vector3, p: Vector3) -> Color:
	var k := smoothstep(-0.25, 0.65, nrm.dot(Paleta.dir_luz()))
	var c := Color(cor.r * lerpf(0.60, 1.16, k), cor.g * lerpf(0.70, 1.08, k), cor.b * lerpf(0.86, 0.84, k))
	var f := Relevo.fora(p.x, p.z)
	var quanto := lerpf(0.06, 0.46, clampf((f - Relevo.ANEL_DENTRO) / (Relevo.ANEL_FORA - Relevo.ANEL_DENTRO), 0.0, 1.0))
	quanto += 0.30 * smoothstep(1.0, -11.0, p.y)
	return Paleta.ar(c, quanto)                                          # (c) a tinta dos anéis


func _criar_anel_perto() -> void:
	var lt := Lote.new()
	# --- a saia de terreno (a MESMA função de relevo, em malha pobre)
	var na := 144
	var nr := 9
	var base := lt.v.size()
	for j in nr + 1:
		var tj := float(j) / float(nr)
		var f := lerpf(Relevo.ANEL_DENTRO - 1.0, Relevo.ANEL_FORA, pow(tj, 1.15))
		for i in na:
			var ang := TAU * float(i) / float(na)
			var p2 := _ponto_anel(ang, f)
			var h := Relevo.altura(p2.x, p2.y)
			h -= 0.9 * (1.0 - smoothstep(Relevo.ANEL_DENTRO, Relevo.ANEL_DENTRO + 5.0, f))
			var p := Vector3(p2.x, h, p2.y)
			lt.v.append(p)
			var nrm := Relevo.normal(p2.x, p2.y)
			lt.n.append(nrm)
			var chao := Paleta.CHAO_RELVA.lerp(Paleta.ANEL_FLORESTA, 0.5).darkened(0.18)
			lt.c.append(_tinta_perto(chao, nrm.lerp(Vector3.UP, 0.5), p))
			lt.uv.append(Vector2.ZERO)
	# a contra-encosta: para lá da crista o chão cai e derrete na cor do horizonte
	for i in na:
		var ang2 := TAU * float(i) / float(na)
		var p3 := _ponto_anel(ang2, Relevo.ANEL_FORA + 16.0)
		lt.v.append(Vector3(p3.x, Relevo.altura(p3.x, p3.y) - 26.0, p3.y))
		lt.n.append(Vector3.UP)
		lt.c.append(Paleta.COR_HORIZONTE)
		lt.uv.append(Vector2.ZERO)
	for j in nr + 1:
		for i in na:
			var a := base + j * na + i
			var b := base + j * na + (i + 1) % na
			lt.idx.append_array([a, b, a + na, b, b + na, a + na])
	var tri_saia := lt.triangulos()
	# --- a linha de árvores: bolhas pobres (20–80 triângulos), tinta cozinhada
	var inicio := lt.v.size()
	var postas := 0
	var tent := 0
	while postas < 760 and tent < 5000:
		tent += 1
		var ang3 := _rf(0.0, TAU)
		var f2 := lerpf(Relevo.ANEL_DENTRO + 1.0, Relevo.ANEL_FORA - 1.0, pow(_rng.randf(), 1.25))
		var p4 := _ponto_anel(ang3, f2)
		var h2 := Relevo.altura(p4.x, p4.y)
		var alto := _rf(9.5, 15.5)
		# na janela norte as árvores do vale são mais baixas: a vista fica aberta
		if Relevo.na_janela(p4.x, p4.y):
			alto *= lerpf(0.62, 1.0, clampf((f2 - 20.0) / 30.0, 0.0, 1.0))
		var largo := alto * _rf(0.30, 0.42)
		var tinta := Paleta.ANEL_FLORESTA.lerp(Paleta.COPA_B, _rf(0.0, 0.55))
		if _rng.randf() < 0.14:
			tinta = tinta.lerp(Paleta.COPA_OURO, 0.4)
		var sub := 1 if f2 < Relevo.ANEL_DENTRO + 16.0 else 0
		var centro := Vector3(p4.x, h2 + alto * 0.58, p4.y)
		lt.bolha(centro, Vector3(largo, alto * 0.46, largo), sub, tinta, _rf(0.0, 80.0), centro - Vector3(0, alto * 0.3, 0), 0.0, 0.0, 0.34)
		if sub == 1:
			var c2 := centro + Vector3(_rf(-1.0, 1.0) * largo * 0.7, -alto * _rf(0.05, 0.22), _rf(-1.0, 1.0) * largo * 0.7)
			lt.bolha(c2, Vector3(largo * 0.75, alto * 0.30, largo * 0.75), 0, tinta.darkened(0.08), _rf(0.0, 80.0), centro - Vector3(0, alto * 0.3, 0), 0.0, 0.0, 0.34)
			var casca := Paleta.CASCA.darkened(0.15)
			lt.tubo([[Vector3(p4.x, h2 - 0.5, p4.y), alto * 0.034], [Vector3(p4.x, h2 + alto * 0.45, p4.y), alto * 0.022]], 4, casca, casca, false)
		postas += 1
	for i in range(inicio, lt.v.size()):
		var cor := lt.c[i]
		var ao := cor.a
		var cc := _tinta_perto(Color(cor.r * lerpf(0.7, 1.0, ao), cor.g * lerpf(0.7, 1.0, ao), cor.b * lerpf(0.7, 1.0, ao)), lt.n[i], lt.v[i])
		cc.a = 1.0
		lt.c[i] = cc
	var mat := ShaderMaterial.new()
	mat.shader = SH_ANEL_PERTO
	_instancia(fundo, lt.fechar(), mat, "AnelPerto")
	medidas["anel_perto_tri"] = lt.triangulos()
	medidas["anel_perto_saia_tri"] = tri_saia
	medidas["anel_perto_arvores"] = postas


# ------------------------------------------------------------------ o fundo: anel longe

func _criar_anel_longe() -> void:
	var lt := Lote.new()
	var rn := Relevo.ruido()
	var sol_az := deg_to_rad(Paleta.SOL_AZIMUTE)
	# raio, altura mínima, altura máxima, ar (0–1), tinta, frequência do perfil, dentes
	var capas: Array = [
		[135.0, 8.0, 17.0, 0.76, Paleta.ANEL_FLORESTA.lerp(Paleta.ANEL_MONTE, 0.25), 260.0, 0.9],
		[185.0, 14.0, 30.0, 0.85, Paleta.ANEL_FLORESTA.lerp(Paleta.ANEL_MONTE, 0.65), 180.0, 0.45],
		[245.0, 22.0, 54.0, 0.905, Paleta.ANEL_MONTE, 140.0, 0.0],
	]
	var az_ancora := deg_to_rad(Relevo.ANCORA_AZIMUTE)
	var n := 384
	for capa in capas:
		var raio: float = capa[0]
		var hmin: float = capa[1]
		var hmax: float = capa[2]
		var ar: float = capa[3]
		var tinta: Color = capa[4]
		var freq: float = capa[5]
		var dentes: float = capa[6]
		var base := lt.v.size()
		for i in n:
			var ang := TAU * float(i) / float(n)
			var cx := cos(ang)
			var sz := sin(ang)
			# perfil periódico: ruído amostrado sobre um círculo (fecha sem costura)
			var p := 0.5 + 0.5 * rn.get_noise_2d(cx * freq + raio, sz * freq)
			p = p * 0.65 + 0.35 * (0.5 + 0.5 * rn.get_noise_2d(cx * freq * 3.1, sz * freq * 3.1 + raio))
			if dentes <= 0.0:
				# montanhas: cumes vincados
				p = 1.0 - absf(2.0 * p - 1.0)
				p = p * 0.75 + 0.25 * (0.5 + 0.5 * rn.get_noise_2d(cx * freq * 6.0 + 9.0, sz * freq * 6.0))
			var h := lerpf(hmin, hmax, clampf(p, 0.0, 1.0))
			# o passo da árvore-âncora: as capas da frente baixam para o tronco se ver inteiro
			if raio < ANCORA_DIST:
				h *= lerpf(0.60, 1.0, smoothstep(deg_to_rad(9.0), deg_to_rad(30.0), absf(angle_difference(ang, az_ancora))))
			# dentes de copa na silhueta de floresta
			h += dentes * (1.2 + 1.2 * rn.get_noise_2d(cx * 4200.0, sz * 4200.0 + raio))
			var x := sin(ang) * raio
			var z := -cos(ang) * raio
			# para o lado do sol o ar é mais espesso (mais claro)
			var lado := 0.5 + 0.5 * cos(ang - sol_az)
			var ar_i := clampf(ar + 0.09 * lado * lado, 0.0, 0.96)
			var cor_topo := Paleta.ar(tinta, ar_i)
			lt.v.append_array([Vector3(x, -34.0, z), Vector3(x, h * 0.30, z), Vector3(x, h * 0.72, z), Vector3(x, h, z)])
			var nrm := Vector3(-sin(ang), 0.0, cos(ang))
			lt.n.append_array([nrm, nrm, nrm, nrm])
			# a base é a COR DO HORIZONTE: a bruma entre as capas (a emenda sem costura)
			lt.c.append_array([Paleta.COR_HORIZONTE, Paleta.ar(cor_topo, 0.72), Paleta.ar(cor_topo, 0.22), cor_topo])
			lt.uv.append_array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
		for i in n:
			var a := base + i * 4
			var b := base + ((i + 1) % n) * 4
			for k in 3:
				lt.idx.append_array([a + k, b + k, a + k + 1, b + k, b + k + 1, a + k + 1])
	var mat := ShaderMaterial.new()
	mat.shader = SH_ANEL_LONGE
	_instancia(fundo, lt.fechar(), mat, "AnelLonge")
	medidas["anel_longe_tri"] = lt.triangulos()


# ------------------------------------------------------------------ o fundo: árvore-âncora

func _criar_ancora() -> void:
	var lt := Lote.new()
	var d := Paleta.dir_de(Relevo.ANCORA_AZIMUTE, 0.0)
	var pe := Vector3(d.x * ANCORA_DIST, -14.0, d.z * ANCORA_DIST)
	var h := ANCORA_ALTURA
	var casca := Color("#6b6248")
	var raio := h * 0.085
	var topo := h * 0.50
	var pts: Array = []
	for i in 8:
		var t := float(i) / 7.0
		var y := t * (topo + 14.0)
		var r := raio * lerpf(1.0, 0.62, t) * (1.0 + 1.5 * exp(-y / (raio * 2.6)))
		pts.append([pe + Vector3(sin(t * 2.0) * 1.5, y, cos(t * 1.7) * 1.2), r])
	lt.tubo(pts, 10, casca, casca, false)
	var cimo: Vector3 = pts[7][0]
	var centro_vol := cimo + Vector3(0, h * 0.10, 0)
	# copa em guarda-chuva: 3 andares de bolhas achatadas
	var andares: Array = [[0.50, 0.02, 7, 0.20], [0.30, 0.16, 6, 0.21], [0.0, 0.27, 1, 0.26]]
	var r3 := RandomNumberGenerator.new()
	r3.seed = 707
	for andar in andares:
		var dist: float = float(andar[0]) * h
		var sobe: float = float(andar[1]) * h
		var quantas: int = andar[2]
		var rb: float = float(andar[3]) * h
		for b in quantas:
			var ang := TAU * (float(b) + r3.randf_range(-0.25, 0.25)) / float(quantas)
			var c := cimo + Vector3(cos(ang) * dist * r3.randf_range(0.85, 1.1), sobe + r3.randf_range(-0.03, 0.03) * h, sin(ang) * dist * r3.randf_range(0.85, 1.1))
			if quantas > 1:
				lt.tubo([[cimo - Vector3(0, r3.randf_range(0.0, 0.2) * topo, 0), raio * 0.36], [cimo.lerp(c, 0.55) - Vector3(0, 0.03 * h, 0), raio * 0.26], [c, raio * 0.12]], 6, casca, casca, false)
			var tinta := Paleta.ANEL_FLORESTA.lerp(Paleta.COPA_OURO, r3.randf_range(0.10, 0.40))
			lt.bolha(c, Vector3(rb * r3.randf_range(0.95, 1.2), rb * 0.52, rb * r3.randf_range(0.95, 1.2)), 1, tinta, r3.randf_range(0.0, 90.0), centro_vol, 0.0, 0.0, 0.30)
	# tinta: luz cozinhada + MUITO ar (está a 215 m); a base derrete na cor do horizonte
	var sol := Paleta.dir_sol_pintado()
	for i in lt.v.size():
		var cor := lt.c[i]
		var k := smoothstep(-0.35, 0.75, lt.n[i].dot(sol))
		var ao := lerpf(0.72, 1.0, cor.a)
		var c2 := Color(cor.r * lerpf(0.62, 1.20, k) * ao, cor.g * lerpf(0.72, 1.10, k) * ao, cor.b * lerpf(0.90, 0.80, k) * ao)
		var quanto := 0.70 + 0.26 * (1.0 - smoothstep(-6.0, 34.0, lt.v[i].y))
		var cc := Paleta.ar(c2, quanto)
		cc.a = 1.0
		lt.c[i] = cc
	var mat := ShaderMaterial.new()
	mat.shader = SH_ANEL_LONGE
	_instancia(fundo, lt.fechar(), mat, "ArvoreAncora")
	medidas["ancora_tri"] = lt.triangulos()
