extends Node3D
## campo_floresta.gd — o campo de batalha da FLORESTA (jogo Assimilação). Ordem 37; religado à
## fundação corrigida na Ordem 38.
##
## Constrói o mapa inteiro na carga, a partir de UMA altura (relevo_floresta.gd), UMA paleta
## (paleta_floresta.gd), UMA grelha (grelha_floresta.gd) e das formas por família
## (formas_floresta.gd). Receita do fundo: ESTUDO-ELDEN.md.
##
##   ARENA — o quadrado jogável de 75 × 75 m (50 × 50 casas de 1,5 m) e a orla rica (24 m):
##     relevo, relva alta que se mexe, árvores de 4 famílias, estrato intermédio, pedras, e
##     UM MARCO POR QUADRANTE (defeito 4):
##       NO  o outeiro dos menires ....... terreno alto para defender (carvalhos velhos)
##       NE  a cova do charco ............ travessia em desvantagem (vidoeiros, juncos)
##       SE  o terraço do santuário ...... altura fortificada com duas rampas (pinheiros-mansos)
##       SO  a garganta .................. corredor entre o lombo de rocha e o tronco tombado (abetos)
##   FUNDO — o que não se alcança:
##     o anel de floresta (24–80 m para lá da arena): árvores INTEIRAS de malha pobre, no mesmo
##       chão e com a mesma luz (defeito 1: nenhuma vista denuncia o palco);
##     o anel longe: duas silhuetas fechadas e a serra, com o ar na tinta;
##     a ÁRVORE ANCESTRAL (260 m, a norte): geometria verdadeira, opaca, com sombra e contacto;
##     o céu: pintura, uma só hora nos 360°.
##
## SEM fogueira. SEM disco de terra no meio.
##
## HIGIENE (defeito 11): o mapa do chão coze-se UMA vez, depois de todos os carimbos (carimbar
## depois de cozer é erro com nome); nada falha calado (erros_floresta.gd).
##
## Para o jogo: `grelha` (contrato mundo↔casa, bloqueio, cobertura, ocupação), altura_em(x, z),
## grupo «sol» (DirectionalLight3D) e grupo «ambiente» (WorldEnvironment).

const Paleta := preload("res://mapa/floresta/paleta_floresta.gd")
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const Lote := preload("res://mapa/floresta/lote_malha.gd")
const Formas := preload("res://mapa/floresta/formas_floresta.gd")
const Grelha := preload("res://mapa/floresta/grelha_floresta.gd")
const Erros := preload("res://mapa/floresta/erros_floresta.gd")
const Ancestral := preload("res://mapa/floresta/arvore_ancestral.gd")
const RelvaFloresta := preload("res://mapa/floresta/relva_floresta.gd")

const SH_TERRENO := preload("res://mapa/floresta/shaders/terreno.gdshader")
const SH_RELVA := preload("res://mapa/floresta/shaders/relva.gdshader")
const SH_HASTE := preload("res://mapa/floresta/shaders/haste.gdshader")
const SH_COPA := preload("res://mapa/floresta/shaders/copa.gdshader")
const SH_SOLIDO := preload("res://mapa/floresta/shaders/solido.gdshader")
const SH_MARCO := preload("res://mapa/floresta/shaders/marco.gdshader")
const SH_AGUA := preload("res://mapa/floresta/shaders/agua.gdshader")
const SH_ANEL := preload("res://mapa/floresta/shaders/anel_floresta.gdshader")
const SH_ANEL_LONGE := preload("res://mapa/floresta/shaders/anel_longe.gdshader")
const SH_ANCESTRAL := preload("res://mapa/floresta/shaders/ancestral.gdshader")
const SH_CEU := preload("res://mapa/floresta/shaders/ceu_panorama.gdshader")

const CEU_PNG := "res://mapa/floresta/ceu/ceu_floresta_v3.png"
const CEU_ELEV_MIN := -6.0
const MAPA_N := 512          # resolução do mapa do chão (luz / terra / copas / contacto)
const MAPA_MEIO := 72.0      # o mapa do chão cobre [-72, 72] m
const RELEVO_N := 120        # resolução da sombra e da oclusão do relevo (1,2 m)
const ESCARPA_M := 1.7       # desnível dentro de uma casa a partir do qual ela não se pisa

## A Árvore Ancestral: a que distância do centro da arena, a que altura tem o pé, e a rotação
## (0 = frente do palácio virada a NORTE, palavra do Mestre; da arena vê-se a face sul).
const ANCESTRAL_DIST := 580.0
const ANCESTRAL_PE := -22.0
const ANCESTRAL_ROTACAO := 0.0
const CAMERA_LONGE := 1500.0
const CAMERA_PERTO := 0.25

## Vistas etiquetadas (capturas e teclas 1–9): nome, x, z, altura dos olhos, azimute, inclinação.
## As 14 primeiras são AS MESMAS da Ordem 37 (mesma posição, mesmo ângulo).
const VISTAS: Array = [
	["centro_olha-norte", 0.0, 0.0, 1.7, -7.0, 3.0],
	["centro_olha-leste", 0.0, 0.0, 1.7, 90.0, 3.0],
	["centro_olha-sul", 0.0, 0.0, 1.7, 180.0, 3.0],
	["centro_olha-oeste", 0.0, 0.0, 1.7, -90.0, 3.0],
	["canto-NO_olha-centro", -25.5, -28.5, 1.7, 138.0, 0.0],
	["canto-NE_olha-centro", 29.0, -26.0, 1.7, -132.0, 0.0],
	["canto-SE_olha-centro", 25.0, 29.5, 1.7, -40.0, 0.0],
	["canto-SO_olha-centro", -29.5, 25.5, 1.7, 49.0, 0.0],
	["canto-NO_olha-fora", -25.5, -28.5, 1.7, -45.0, 4.0],
	["canto-NE_olha-fora", 29.0, -26.0, 1.7, 45.0, 4.0],
	["canto-SE_olha-fora", 25.0, 29.5, 1.7, 135.0, 4.0],
	["canto-SO_olha-fora", -29.5, 25.5, 1.7, -135.0, 4.0],
	["longe_vista-ref07", 5.0, 27.0, 2.3, -11.0, 1.0],
	["alto_mapa-inteiro", 0.0, 46.0, 34.0, 0.0, -40.0],
	# as diagonais do centro: com as 4 primeiras, a volta de 360° fica vista de 45 em 45 graus
	["centro_olha-nordeste", 0.0, 0.0, 1.7, 45.0, 3.0],
	["centro_olha-sueste", 0.0, 0.0, 1.7, 135.0, 3.0],
	["centro_olha-sudoeste", 0.0, 0.0, 1.7, -135.0, 3.0],
	["centro_olha-noroeste", 0.0, 0.0, 1.7, -45.0, 3.0],
]

@export var semente: int = 38
## Fracção dos tufos de relva desenhada (perfis: 1,0 alto · 0,7 médio · 0,45 baixo).
@export_range(0.1, 1.0) var densidade_relva: float = 1.0
@export var mostrar_medicao: bool = true

## ORDEM 42 — o mapa como campo de batalha DO JOGO (cenas/arena/arena.gd).
## Na arena, o mapa usa o Ambiente, o Sol e a Câmara DA ARENA (um céu só, uma luz só): estes
## caminhos apontam para eles. Sozinho (campo_floresta.tscn) ficam os seus.
@export var no_ambiente: NodePath = ^"Ambiente"
@export var no_sol: NodePath = ^"Sol"
@export var no_camera: NodePath = ^"Camera"
## Teclas 1–9/0/F/L/M e a vista 0 na carga (só no mapa sozinho; na arena a câmara é a da mesa).
@export var vistas_por_tecla: bool = true
## A ZONA JOGÁVEL do jogo (x, z no mundo; vazia = nenhuma). Lá dentro o mapa não põe nada que
## ocupe uma casa sem o servidor saber: nem pedras soltas, nem árvores, nem estrato; e o tronco
## tombado da garganta acaba à entrada dela. Os marcos de relevo ficam (são chão).
@export var zona_jogo: Rect2 = Rect2()
## A relva dentro da zona jogável fica a esta fracção da altura (pisada; continua a mexer).
@export_range(0.1, 1.0) var relva_no_campo: float = 0.38

@onready var _ambiente: WorldEnvironment = get_node(no_ambiente)
@onready var _sol: DirectionalLight3D = get_node(no_sol)
@onready var _camera: Camera3D = get_node(no_camera)
@onready var _rotulo: Label = get_node_or_null(^"Medicao/Rotulo")

var arena: Node3D
var fundo: Node3D
var grelha: Grelha
var relva: RelvaFloresta
var medidas: Dictionary = {}

var _rng := RandomNumberGenerator.new()
var _mats: Array[ShaderMaterial] = []
var _ruido_tex: Texture2D
var _mapa_tex: ImageTexture
## O mapa do chão, entrelaçado (4 números por ponto): 0 = sol que chega (tudo) · 1 = terra à
## mostra · 2 = sol que chega contando só as copas · 3 = oclusão de contacto (1 = aberto).
var _mapa := PackedFloat32Array()
var _cozido := false
var _tudo: Dictionary = {}       # casas de 6 m -> [Vector3(x, z, raio)]: tudo o que ocupa chão
var _so_arvores: Dictionary = {} # idem, só os troncos (para a distância entre árvores)
var _troncos: Array = []         # [Vector2, raio]: os troncos de dentro da arena (para a grelha)
var _rochas: Array = []          # [Vector3 centro, tamanho]
var _lote_pedras := Lote.new()
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
	grelha = Grelha.new()
	_ruido_tex = _gerar_ruido()
	_montar_ambiente()
	_iniciar_mapa()
	# as vistas etiquetadas ficam livres (ninguém planta um tronco em cima da câmara)
	for v in VISTAS:
		if float(v[3]) < 10.0:
			_ocupar(_tudo, float(v[1]), float(v[2]), 2.4)
	# ---- tudo o que carimba o chão…
	_levantar_marcos()
	_plantar_arvores()
	_semear_rochas()
	_riscar_trilho()
	_criar_estrato()
	# ---- …e só depois se coze, UMA vez
	_cozer_mapa_chao()
	_criar_terreno()
	_criar_relva()
	_marcar_grelha()
	_criar_anel()
	_criar_anel_longe()
	_criar_ancestral()
	_escrever_materiais()
	if vistas_por_tecla:
		ir_para_vista(0)
	if _rotulo != null:
		_rotulo.visible = mostrar_medicao
	medidas["carga_ms"] = Time.get_ticks_msec() - t0
	medidas["erros"] = Erros.contagem()
	print("[floresta] pronta em %d ms | %s" % [medidas["carga_ms"], JSON.stringify(medidas)])


func _process(delta: float) -> void:
	if not mostrar_medicao or _rotulo == null:
		return
	_t_rotulo += delta
	if _t_rotulo >= 0.5:
		_t_rotulo = 0.0
		_rotulo.text = "Floresta 38 | %d fps | %d chamadas | %d primitivas | relva %d tufos | 1-9 vistas, F fundo, L LOD, WASD andar" % [
			Engine.get_frames_per_second(),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
			relva.tufos_ativos()]


func _unhandled_input(event: InputEvent) -> void:
	if not vistas_por_tecla:
		return
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	if k.keycode >= KEY_1 and k.keycode <= KEY_9:
		ir_para_vista(k.keycode - KEY_1)
	elif k.keycode == KEY_0:
		ir_para_vista(12)
	elif k.keycode == KEY_F:
		so_fundo(arena.visible)
	elif k.keycode == KEY_L:
		relva.ligar_lod(not relva.lod_ligado)
	elif k.keycode == KEY_M and _rotulo != null:
		_rotulo.visible = not _rotulo.visible


# ------------------------------------------------------------------ API

func altura_em(x: float, z: float) -> float:
	return Relevo.altura(x, z)


## Esconde a arena e deixa só o fundo (céu + anel de floresta + anel longe + Árvore Ancestral)
## — para MEDIR as chamadas de desenho do fundo.
func so_fundo(ligar: bool) -> void:
	arena.visible = not ligar


func ir_para_vista(i: int) -> void:
	if i < 0 or i >= VISTAS.size():
		Erros.erro(Erros.VISTA_INVALIDA, "ir_para_vista(%d)" % i)
		return
	var v: Array = VISTAS[i]
	var x: float = v[1]
	var z: float = v[2]
	_camera.position = Vector3(x, Relevo.altura(x, z) + float(v[3]), z)
	_camera.rotation = Vector3(deg_to_rad(float(v[5])), -deg_to_rad(float(v[4])), 0.0)
	if _camera.has_method("ler_transformacao"):
		_camera.call("ler_transformacao")


## Ordem 42: o recorte da vista da câmara da mesa (shaders/recorte_vista.gdshaderinc): o que fica entre a
## câmara e `foco` (copas, troncos, pedras, marcos) some num ponteado. raio = 0 desliga.
func definir_recorte_vista(foco: Vector3, raio: float) -> void:
	for m in _mats:
		m.set_shader_parameter("vista_foco", foco)
		m.set_shader_parameter("vista_raio", raio)


func definir_densidade_relva(f: float) -> void:
	densidade_relva = clampf(f, 0.1, 1.0)
	relva.definir_densidade(densidade_relva)


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
			img.generate_mipmaps()
			tex = ImageTexture.create_from_image(img)
	if tex == null:
		Erros.erro(Erros.CEU_EM_FALTA, CEU_PNG)
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
	# O sol do jogo (para as figuras): a MESMA direcção e cor da luz pintada e do disco do céu.
	# Sem sombra por defeito — as sombras do cenário vêm cozidas no mapa do chão.
	var l := Paleta.dir_luz()
	_sol.look_at_from_position(Vector3.ZERO, -l, Vector3.UP)
	_sol.light_color = Paleta.COR_SOL
	_sol.light_energy = 1.1
	_sol.shadow_enabled = false
	# a Árvore Ancestral está longe: a câmara tem de a alcançar
	_camera.far = CAMERA_LONGE
	_camera.near = CAMERA_PERTO


func _mat(sh: Shader) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = sh
	_mats.append(m)
	return m


## A luz pintada e o mapa do chão escrevem-se em TODOS os materiais, num sítio só.
func _escrever_materiais() -> void:
	for m in _mats:
		m.set_shader_parameter("dir_luz", Paleta.dir_luz())
		m.set_shader_parameter("cor_sol", Paleta.COR_SOL)
		m.set_shader_parameter("cor_sombra", Paleta.COR_SOMBRA)
		m.set_shader_parameter("cor_ceu", Paleta.COR_CEU_AMBIENTE)
		m.set_shader_parameter("cor_horizonte", Paleta.COR_HORIZONTE)       # (c) o ar pintado
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


func _instancia(pai: Node3D, malha: Mesh, mat: Material, nome: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = malha
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)
	return mi


# ------------------------------------------------------------------ quem ocupa o chão

func _ocupar(tabela: Dictionary, x: float, z: float, raio: float) -> void:
	var c := Vector2i(floori(x / 6.0), floori(z / 6.0))
	if not tabela.has(c):
		tabela[c] = []
	(tabela[c] as Array).append(Vector3(x, z, raio))


## Não há nada da tabela a menos de `folga` (m, para lá do raio de cada coisa)?
func _livre(tabela: Dictionary, x: float, z: float, folga: float) -> bool:
	var c := Vector2i(floori(x / 6.0), floori(z / 6.0))
	for dj in range(-1, 2):
		for di in range(-1, 2):
			var chave := c + Vector2i(di, dj)
			if not tabela.has(chave):
				continue
			for o: Vector3 in tabela[chave]:
				var d := folga + o.z
				if (o.x - x) * (o.x - x) + (o.y - z) * (o.y - z) < d * d:
					return false
	return true


## Ordem 42: o ponto (x, z), com `raio` à volta, toca a zona jogável do jogo?
func _na_zona(x: float, z: float, raio: float) -> bool:
	if not zona_jogo.has_area():
		return false
	return zona_jogo.grow(raio + 0.25).has_point(Vector2(x, z))


func _contar_tirado(o_que: String) -> void:
	medidas["zona_tirados_" + o_que] = int(medidas.get("zona_tirados_" + o_que, 0)) + 1


# ------------------------------------------------------------------ mapa do chão

func _mi(x: float) -> int:
	return int((x + MAPA_MEIO) / (2.0 * MAPA_MEIO) * MAPA_N)


## O mapa nasce com o que é do RELEVO (defeito 8): a sombra que as vertentes deitam (canal 0) e
## a oclusão no pé delas (canal 3). Faz-se a 1,2 m e alarga-se para a resolução do mapa.
func _iniciar_mapa() -> void:
	var n := RELEVO_N
	var passo := 2.0 * MAPA_MEIO / float(n)
	var l := Paleta.dir_luz()
	var d2 := Vector2(l.x, l.z).normalized()
	var sobe := l.y / Vector2(l.x, l.z).length()
	var roda: Array[Vector2] = []
	for k in 6:
		roda.append(Vector2(cos(TAU * k / 6.0), sin(TAU * k / 6.0)) * 2.4)
	var dados := PackedFloat32Array()
	dados.resize(n * n * 4)
	for j in n:
		var z := -MAPA_MEIO + (float(j) + 0.5) * passo
		for i in n:
			var x := -MAPA_MEIO + (float(i) + 0.5) * passo
			var h := Relevo.altura(x, z)
			var tapa := 0.0
			for s in range(1, 11):
				var t := float(s) * 1.2
				var a := Relevo.altura(x + d2.x * t, z + d2.y * t) - (h + 0.12 + sobe * t)
				if a > 0.0:
					tapa = maxf(tapa, a / (0.20 + 0.10 * t))
			var media := 0.0
			for o in roda:
				media += Relevo.altura(x + o.x, z + o.y)
			var cova := clampf((media / 6.0 - h - 0.05) / 0.75, 0.0, 1.0)
			var k4 := (j * n + i) * 4
			dados[k4] = 1.0 - 0.88 * clampf(tapa, 0.0, 1.0)
			dados[k4 + 1] = 0.0
			dados[k4 + 2] = 1.0
			dados[k4 + 3] = 1.0 - 0.75 * cova
	var img := Image.create_from_data(n, n, false, Image.FORMAT_RGBAF, dados.to_byte_array())
	img.resize(MAPA_N, MAPA_N, Image.INTERPOLATE_BILINEAR)
	_mapa = img.get_data().to_float32_array()
	if _mapa.size() != MAPA_N * MAPA_N * 4:
		Erros.erro(Erros.MALHA_VAZIA, "mapa do chão: %d números em vez de %d" % [_mapa.size(), MAPA_N * MAPA_N * 4])
		_mapa.resize(MAPA_N * MAPA_N * 4)
		_mapa.fill(1.0)


func _pode_carimbar(quem: String) -> bool:
	if _cozido:
		Erros.erro(Erros.COZEDURA_FORA_DE_ORDEM, quem)
		return false
	return true


## Carimbo elíptico suave: baixa o canal até (1 - forca) no centro. `dir` = eixo maior (unitário).
func _carimbo_min(canal: int, cx: float, cz: float, ra: float, rb: float, dir: Vector2, forca: float) -> void:
	if not _pode_carimbar("carimbo_min(%d)" % canal):
		return
	var ext := maxf(ra, rb)
	if absf(cx) - ext > MAPA_MEIO or absf(cz) - ext > MAPA_MEIO:
		return
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
				var s := 1.0 - forca * (1.0 - smoothstep(0.45, 1.0, q))
				var i := (iz * MAPA_N + ix) * 4 + canal
				if s < _mapa[i]:
					_mapa[i] = s


## Carimbo redondo suave: sobe o canal até `forca` no centro.
func _carimbo_max(canal: int, cx: float, cz: float, raio: float, forca: float) -> void:
	if not _pode_carimbar("carimbo_max(%d)" % canal):
		return
	if absf(cx) - raio > MAPA_MEIO or absf(cz) - raio > MAPA_MEIO:
		return
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
				var i := (iz * MAPA_N + ix) * 4 + canal
				if s > _mapa[i]:
					_mapa[i] = s


## Lê um canal do mapa do chão em (x, z); fora do mapa devolve `fora`.
func _ler(canal: int, x: float, z: float, fora: float = 0.0) -> float:
	var ix := _mi(x)
	var iz := _mi(z)
	if ix < 0 or iz < 0 or ix >= MAPA_N or iz >= MAPA_N:
		return fora
	return _mapa[(iz * MAPA_N + ix) * 4 + canal]


func _terra_em(x: float, z: float) -> float:
	return _ler(1, x, z, 0.0)


## Quanta copa há por cima (0 = céu aberto, 1 = debaixo da floresta).
func _coberto_em(x: float, z: float) -> float:
	return 1.0 - _ler(2, x, z, 0.3)


## Onde cai no chão a sombra de um ponto `p` (a luz vem de dir_luz).
func _sombra_de(p: Vector3) -> Vector2:
	var l := Paleta.dir_luz()
	var g := Vector2(p.x, p.z)
	for volta in 2:
		var alt := maxf(p.y - Relevo.altura(g.x, g.y), 0.0)
		g = Vector2(p.x, p.z) - Vector2(l.x, l.z) * (alt / l.y)
	return g


## A sombra de uma coisa ALTA e estreita (tronco, menir, lanterna): carimbos ao longo da altura.
func _sombra_alta(canais: Array, pe: Vector3, alto: float, raio: float, forca: float) -> void:
	var l := Paleta.dir_luz()
	var dir := Vector2(l.x, l.z).normalized()
	var n := maxi(int(alto / maxf(raio * 1.2, 0.45)), 1)
	for s in n + 1:
		var g := _sombra_de(pe + Vector3(0, alto * float(s) / float(n), 0))
		for canal: int in canais:
			_carimbo_min(canal, g.x, g.y, raio * 1.5, raio * 1.2, dir, forca)


## O pé de qualquer coisa pousada: escurece o contacto (canal 3) — nada flutua.
func _contacto(x: float, z: float, raio: float, forca: float = 0.6) -> void:
	_carimbo_min(3, x, z, raio, raio, Vector2.RIGHT, forca)


## Coze o mapa do chão: UMA vez, depois de todos os carimbos (defeito 11).
func _cozer_mapa_chao() -> void:
	if _cozido:
		Erros.erro(Erros.COZEDURA_FORA_DE_ORDEM, "o mapa do chão já estava cozido")
		return
	var img := Image.create_from_data(MAPA_N, MAPA_N, false, Image.FORMAT_RGBAF, _mapa.to_byte_array())
	img.convert(Image.FORMAT_RGBA8)
	_mapa_tex = ImageTexture.create_from_image(img)
	_cozido = true
	medidas["mapa_chao_cozeduras"] = 1


## Um trilho de bicho, estreito e torto: sai da garganta, contorna o centro por noroeste (nunca a
## menos de 12 m dele — não há disco de terra no meio) e sai a leste, entre a cova e o terraço.
func _riscar_trilho() -> void:
	var pts: Array[Vector2] = [Vector2(-21.0, 38.5), Vector2(-20.5, 29.0), Vector2(-19.3, 20.0), Vector2(-18.0, 11.0),
		Vector2(-13.5, 3.0), Vector2(-11.5, -6.0), Vector2(-4.0, -12.5), Vector2(5.0, -13.5), Vector2(12.0, -8.5),
		Vector2(20.5, -3.5), Vector2(29.0, 0.5), Vector2(39.0, 2.5)]
	var rn := Relevo.ruido()
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var n := int(a.distance_to(b) / 0.35)
		var perp := (b - a).orthogonal().normalized()
		for s in n:
			var p := a.lerp(b, float(s) / float(n))
			var desvio := rn.get_noise_2d(p.x * 9.0, p.y * 9.0) * 0.9
			var larg := 0.50 + 0.30 * rn.get_noise_2d(p.x * 20.0 + 9.0, p.y * 20.0)
			_carimbo_max(1, p.x + perp.x * desvio, p.y + perp.y * desvio, maxf(larg, 0.35), 0.72)


# ------------------------------------------------------------------ terreno

## O chão: a zona FINA (0,75 m, |x|,|z| ≤ 42 m) e a LARGA (3 m, até à orla da malha), feitas
## DIRECTAMENTE das duas grelhas cozidas do relevo, com a diagonal de (i+1, j) a (i, j+1) — a
## mesma de Relevo.altura(). A colisão é feita dos MESMOS triângulos da zona fina (defeito 9).
func _criar_terreno() -> void:
	var m := _mat(SH_TERRENO)
	m.set_shader_parameter("cor_relva", Paleta.CHAO_RELVA)
	m.set_shader_parameter("cor_relva_seca", Paleta.RELVA_SECA.darkened(0.25))
	m.set_shader_parameter("cor_floresta", Paleta.CHAO_FLORESTA)
	m.set_shader_parameter("cor_terra", Paleta.CHAO_TERRA)
	m.set_shader_parameter("cor_musgo", Paleta.CHAO_MUSGO)
	m.set_shader_parameter("cor_pedra", Paleta.PEDRA)
	m.set_shader_parameter("cor_pedra_quente", Paleta.PEDRA_QUENTE)
	m.set_shader_parameter("meio_arena", Relevo.MEIO)
	m.set_shader_parameter("ar_de", Relevo.ANEL_FORA - 22.0)
	m.set_shader_parameter("ar_ate", Relevo.CHAO_FORA)
	# ---- zona fina
	var nf := Relevo.N_FINO
	var gf := Relevo.grelha_fina()
	var v := PackedVector3Array()
	var nor := PackedVector3Array()
	v.resize(nf * nf)
	nor.resize(nf * nf)
	for j in nf:
		var z := -Relevo.MEIO_FINO + j * Relevo.PASSO_FINO
		for i in nf:
			var x := -Relevo.MEIO_FINO + i * Relevo.PASSO_FINO
			v[j * nf + i] = Vector3(x, gf[j * nf + i], z)
			nor[j * nf + i] = Relevo.normal(x, z)
	var idx := PackedInt32Array()
	idx.resize((nf - 1) * (nf - 1) * 6)
	var faces := PackedVector3Array()
	faces.resize((nf - 1) * (nf - 1) * 6)
	var k := 0
	for j in nf - 1:
		for i in nf - 1:
			var a := j * nf + i
			for o: int in [a, a + 1, a + nf, a + 1, a + nf + 1, a + nf]:
				idx[k] = o
				faces[k] = v[o]
				k += 1
	_instancia(arena, _malha_chao(v, nor, idx), m, "Terreno")
	medidas["terreno_fino_tri"] = idx.size() / 3
	# Colisão (jogável): os MESMOS triângulos que se vêem.
	var corpo := StaticBody3D.new()
	corpo.name = "ChaoColisao"
	var forma := ConcavePolygonShape3D.new()
	forma.set_faces(faces)
	var cs := CollisionShape3D.new()
	cs.shape = forma
	corpo.add_child(cs)
	arena.add_child(corpo)
	# ---- zona larga (a floresta da orla e do anel): sem os quadrados que a zona fina já cobre
	var nl := Relevo.N_LARGO
	var gl := Relevo.grelha_larga()
	var vl := PackedVector3Array()
	var norl := PackedVector3Array()
	var foral := PackedFloat32Array()
	vl.resize(nl * nl)
	norl.resize(nl * nl)
	foral.resize(nl * nl)
	for j in nl:
		var z := -Relevo.MEIO_LARGO + j * Relevo.PASSO_LARGO
		for i in nl:
			var x := -Relevo.MEIO_LARGO + i * Relevo.PASSO_LARGO
			var h := gl[j * nl + i]
			vl[j * nl + i] = Vector3(x, h, z)
			foral[j * nl + i] = Relevo.fora(x, z)
			var hx0 := gl[j * nl + maxi(i - 1, 0)]
			var hx1 := gl[j * nl + mini(i + 1, nl - 1)]
			var hz0 := gl[maxi(j - 1, 0) * nl + i]
			var hz1 := gl[mini(j + 1, nl - 1) * nl + i]
			norl[j * nl + i] = Vector3(hx0 - hx1, 2.0 * Relevo.PASSO_LARGO, hz0 - hz1).normalized()
	var idxl := PackedInt32Array()
	var limite := Relevo.CHAO_FORA + 1.0
	var borda := Relevo.MEIO_FINO - 0.01
	for j in nl - 1:
		for i in nl - 1:
			var a := j * nl + i
			var p0 := vl[a]
			var p1 := vl[a + nl + 1]
			if absf(p0.x) <= borda + 0.02 and absf(p1.x) <= borda + 0.02 and absf(p0.z) <= borda + 0.02 and absf(p1.z) <= borda + 0.02:
				continue
			if foral[a] > limite and foral[a + 1] > limite and foral[a + nl] > limite and foral[a + nl + 1] > limite:
				continue
			idxl.append_array([a, a + 1, a + nl, a + 1, a + nl + 1, a + nl])
	_instancia(fundo, _malha_chao(vl, norl, idxl), m, "TerrenoLargo")
	medidas["terreno_largo_tri"] = idxl.size() / 3


func _malha_chao(v: PackedVector3Array, nor: PackedVector3Array, idx: PackedInt32Array) -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nor
	arr[Mesh.ARRAY_INDEX] = idx
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return malha


# ------------------------------------------------------------------ os marcos (um por quadrante)

func _levantar_marcos() -> void:
	var obra := Lote.new()       # construído: santuário e lanternas (shaders/marco.gdshader)
	var madeira := Lote.new()    # madeira morta: o tronco tombado e a árvore seca do charco
	var r := RandomNumberGenerator.new()
	r.seed = 3804
	_marco_menires(r)
	_marco_santuario(obra, r)
	_marco_garganta(madeira)
	_marco_charco(madeira, r)
	_instancia(arena, obra.fechar(), _mat(SH_MARCO), "MarcoSantuario")
	var mm := _mat(SH_SOLIDO)
	mm.set_shader_parameter("cor_musgo", Paleta.PEDRA_MUSGO)
	mm.set_shader_parameter("forca_musgo", 0.62)
	mm.set_shader_parameter("musgo_de", 0.50)
	_instancia(arena, madeira.fechar(), mm, "MarcoMadeira")
	medidas["marcos_tri"] = obra.triangulos() + madeira.triangulos()


## NO — o OUTEIRO DOS MENIRES: sete pedras altas em roda no topo plano (uma tombou) e a laje no
## meio. Quem está lá em cima vê a arena toda e tem as pedras por cobertura.
func _marco_menires(r: RandomNumberGenerator) -> void:
	var c := Relevo.OUTEIRO
	var n := 7
	for k in n:
		var ang := TAU * (float(k) + r.randf_range(-0.12, 0.12)) / float(n) + 0.35
		var d := 3.25 + r.randf_range(-0.2, 0.2)
		var x := c.x + cos(ang) * d
		var z := c.y + sin(ang) * d
		var alto := r.randf_range(2.5, 3.6)
		var deitado := k == 4
		var pe := Vector3(x, Relevo.altura(x, z) - 0.30, z)
		Formas.menir(_lote_pedras, pe, alto, r, deitado)
		_ocupar(_tudo, x, z, 0.9)
		_carimbo_max(1, x, z, 1.0, 0.85)
		_contacto(x, z, 1.5, 0.65)
		if deitado:
			_sombra_alta([0], pe, 0.7, 1.2, 0.85)
			grelha.dar_cobertura(Grelha.casa_em(x, z), Grelha.COBERTURA_MEIA)
		else:
			_sombra_alta([0], pe, alto, alto * 0.21, 0.90)
			grelha.bloquear(Grelha.casa_em(x, z), "menir")
	# a laje do meio e o chão gasto dentro da roda (a relva rareia, não some)
	var hc := Relevo.altura(c.x, c.y)
	_lote_pedras.rocha(Vector3(c.x, hc + 0.16, c.y), Vector3(1.35, 0.36, 0.95), Basis(Vector3.UP, 0.6), 2, Paleta.PEDRA_QUENTE, 12.0, 0.16)
	_ocupar(_tudo, c.x, c.y, 1.3)
	_carimbo_max(1, c.x, c.y, 1.7, 0.9)
	_carimbo_max(1, c.x, c.y, 3.6, 0.42)
	_contacto(c.x, c.y, 2.0, 0.5)
	grelha.dar_cobertura(Grelha.casa_em(c.x, c.y), Grelha.COBERTURA_MEIA)


## SE — o TERRAÇO DO SANTUÁRIO: o pagode pequeno (ecoa o palácio da Árvore Ancestral) no cimo
## da escarpa, virado ao centro da arena; lanternas acesas a ladear o cimo e o pé das duas rampas.
func _marco_santuario(obra: Lote, r: RandomNumberGenerator) -> void:
	var t := Relevo.TERRACO
	var frente := (-t).normalized()                  # para o centro da arena
	var p := t - frente * 1.1
	var rot := atan2(-frente.x, -frente.y)
	var base := Basis(Vector3.UP, rot)
	var y := Relevo.altura(p.x, p.y)
	obra.juntar(Formas.santuario(), Transform3D(base, Vector3(p.x, y, p.y)))
	# ocupa, carimba e bloqueia a planta (2,6 × 2,3 m de meias medidas, mais os degraus)
	_ocupar(_tudo, p.x, p.y, 3.2)
	_ocupar(_tudo, p.x + frente.x * 2.8, p.y + frente.y * 2.8, 1.4)
	_carimbo_max(1, p.x, p.y, 3.5, 1.0)
	for s in 5:
		_carimbo_max(1, p.x + frente.x * (2.2 + s * 0.9), p.y + frente.y * (2.2 + s * 0.9), 1.25, 0.8)
	_contacto(p.x, p.y, 4.6, 0.7)
	var l := Paleta.dir_luz()
	var dir := Vector2(l.x, l.z).normalized()
	for degrau: Array in [[0.8, 3.2], [2.4, 3.2], [3.6, 2.4], [4.8, 1.6], [5.8, 0.9]]:
		var g := _sombra_de(Vector3(p.x, y + float(degrau[0]), p.y))
		_carimbo_min(0, g.x, g.y, float(degrau[1]) * 1.25, float(degrau[1]), dir, 0.92)
	for lj in Grelha.LADO:
		for ci in Grelha.LADO:
			var casa := Vector2i(ci, lj)
			var cc := Grelha.canto(casa) + Vector2(0.75, 0.75) - p
			var lx := cc.dot(Vector2(-frente.y, frente.x))
			var lz := cc.dot(frente)
			if absf(lx) < 2.7 and lz > -2.4 and lz < 2.4:
				grelha.bloquear(casa, "santuário")
	# as lanternas: duas no cimo de cada rampa (3 casas de passagem entre elas), uma no pé
	for sinal: float in [1.0, -1.0]:
		var rampa := frente.rotated(deg_to_rad(96.0) * sinal)
		var lado := rampa.orthogonal()
		for pos: Vector2 in [t + rampa * 6.6 + lado * 2.35, t + rampa * 6.6 - lado * 2.35, t + rampa * 15.0 + lado * 2.6 * sinal]:
			var yl := Relevo.altura(pos.x, pos.y)
			obra.juntar(Formas.lanterna(), Transform3D(Basis(Vector3.UP, r.randf() * TAU), Vector3(pos.x, yl - 0.03, pos.y)))
			_ocupar(_tudo, pos.x, pos.y, 0.6)
			_carimbo_max(1, pos.x, pos.y, 0.8, 0.8)
			_contacto(pos.x, pos.y, 1.0, 0.6)
			_sombra_alta([0], Vector3(pos.x, yl, pos.y), 1.8, 0.36, 0.88)
			grelha.bloquear(Grelha.casa_em(pos.x, pos.y), "lanterna")


## SO — a GARGANTA: o tronco tombado de um gigante faz de muro a leste; o lombo de rocha (que é
## relevo) faz de muro a oeste. Entre os dois, um corredor de 3–4 casas.
func _marco_garganta(madeira: Lote) -> void:
	var a := Relevo.TRONCO_A
	var b := Relevo.TRONCO_B
	var raio := Relevo.TRONCO_RAIO
	# Ordem 42: na arena, o tronco (a ponta da copa, a norte) acaba antes da zona jogável.
	if zona_jogo.has_area():
		var corte := 1.0
		for s in 101:
			var q := a.lerp(b, float(s) / 100.0)
			if _na_zona(q.x, q.y, raio + 0.3):
				corte = maxf(float(s - 1) / 100.0, 0.2)
				break
		if corte < 1.0:
			b = a.lerp(b, corte)
			medidas["zona_tronco_tombado_m"] = snappedf(a.distance_to(b), 0.1)
	var ha := Relevo.altura(a.x, a.y)
	var hb := Relevo.altura(b.x, b.y)
	# assenta: o eixo nunca fica a mais de 0,8 raios do chão (nunca flutua; onde o chão sobe, enterra-se)
	var folga := INF
	for s in 21:
		var t := float(s) / 20.0
		var q := a.lerp(b, t)
		folga = minf(folga, Relevo.altura(q.x, q.y) - lerpf(ha, hb, t))
	var pa := Vector3(a.x, ha + folga + raio * 0.8, a.y)
	var pb := Vector3(b.x, hb + folga + raio * 0.8, b.y)
	var eixo := (pb - pa).normalized()
	var lado := Vector3.UP.cross(eixo).normalized()
	var base := Basis(lado, eixo, lado.cross(eixo))
	madeira.juntar(Formas.tronco_tombado(pa.distance_to(pb), raio), Transform3D(base, pa))
	var n := int(a.distance_to(b) / 1.1)
	for s in n + 1:
		var t := float(s) / float(n)
		var q := a.lerp(b, t)
		var centro := pa.lerp(pb, t)
		_ocupar(_tudo, q.x, q.y, raio + 0.4)
		_carimbo_max(1, q.x, q.y, raio * 1.25, 0.95)
		_contacto(q.x, q.y, raio * 2.3, 0.62)
		var g := _sombra_de(centro + Vector3(0, raio * 0.5, 0))
		_carimbo_min(0, g.x, g.y, raio * 1.5, raio * 1.3, Vector2.RIGHT, 0.90)
	# o prato das raízes (na ponta sul) deita sombra alta
	_sombra_alta([0], Vector3(a.x, ha, a.y), raio * 3.6, raio * 1.3, 0.85)
	for lj in Grelha.LADO:
		for ci in Grelha.LADO:
			var casa := Vector2i(ci, lj)
			var d := Relevo.ao_segmento(Grelha.canto(casa) + Vector2(0.75, 0.75), a, b).x
			if d < raio + 0.30:
				grelha.bloquear(casa, "tronco tombado")
			elif d < raio + 1.6:
				grelha.dar_cobertura(casa, Grelha.COBERTURA_TOTAL)


## NE — a COVA DO CHARCO: água parada no fundo (quem atravessa fica em baixo e à vista) e a
## árvore seca na margem.
func _marco_charco(madeira: Lote, r: RandomNumberGenerator) -> void:
	var c := Relevo.COVA
	var nivel := Relevo.nivel_agua()
	var l := Lote.new()
	var na := 36
	var nr := 8
	l.v.append(Vector3(c.x, nivel, c.y))
	l.n.append(Vector3.UP)
	l.c.append(Color(1, 1, 1, clampf(Relevo.agua(c.x, c.y) / Relevo.AGUA_ABAIXO, 0.0, 1.0)))
	l.uv.append(Vector2.ZERO)
	for j in range(1, nr + 1):
		var rho := 6.6 * float(j) / float(nr)
		for i in na:
			var ang := TAU * float(i) / float(na)
			var x := c.x + cos(ang) * rho
			var z := c.y + sin(ang) * rho
			l.v.append(Vector3(x, nivel, z))
			l.n.append(Vector3.UP)
			l.c.append(Color(1, 1, 1, clampf(Relevo.agua(x, z) / Relevo.AGUA_ABAIXO, 0.0, 1.0)))
			l.uv.append(Vector2.ZERO)
	for i in na:
		l.idx.append_array([0, 1 + i, 1 + (i + 1) % na])
	for j in range(1, nr):
		for i in na:
			var d0 := 1 + (j - 1) * na + i
			var d1 := 1 + (j - 1) * na + (i + 1) % na
			l.idx.append_array([d0, d0 + na, d1 + na, d0, d1 + na, d1])
	var ma := _mat(SH_AGUA)
	ma.set_shader_parameter("cor_funda", Paleta.AGUA)
	ma.set_shader_parameter("cor_rasa", Paleta.AGUA_RASA)
	ma.set_shader_parameter("cor_reflexo", Paleta.CEU_MEIO)
	_instancia(arena, l.fechar(), ma, "Charco")
	medidas["agua_tri"] = l.triangulos()
	# a margem: lodo à mostra numa faixa estreita à volta da água
	for i in 40:
		var ang := TAU * float(i) / 40.0
		_carimbo_max(1, c.x + cos(ang) * 5.1, c.y + sin(ang) * 5.1, 1.0, 0.62)
	# a árvore seca, inclinada para a água
	var ps := c + Vector2(4.9, 3.6)
	var pe := Vector3(ps.x, Relevo.altura(ps.x, ps.y), ps.y)
	Formas.arvore_morta(madeira, pe, 8.0, Vector3(-0.16, 0.0, -0.10), r)
	_ocupar(_tudo, ps.x, ps.y, 0.8)
	_ocupar(_so_arvores, ps.x, ps.y, 0.4)
	_troncos.append([ps, 0.4])
	_carimbo_max(1, ps.x, ps.y, 1.3, 0.9)
	_contacto(ps.x, ps.y, 1.6, 0.6)
	_sombra_alta([0], pe, 8.0, 0.42, 0.85)


# ------------------------------------------------------------------ árvores

## A família que manda em cada quadrante (defeitos 4 e 6): NO carvalho · NE vidoeiro ·
## SE pinheiro-manso · SO abeto. `dominio` = fracção das árvores que é da família da casa.
func _familia_em(x: float, z: float, dominio: float) -> int:
	if _rng.randf() > dominio:
		return _rng.randi_range(0, 3)
	if z < 0.0:
		return Formas.REDONDA if x < 0.0 else Formas.JOVEM
	return Formas.CONIFERA if x < 0.0 else Formas.GUARDA_SOL


func _altura_familia(familia: int) -> float:
	match familia:
		Formas.REDONDA:
			return _rf(13.5, 18.5)
		Formas.CONIFERA:
			return _rf(15.0, 22.0)
		Formas.JOVEM:
			return _rf(9.0, 13.0)
	return _rf(13.0, 18.0)


## Planta UMA árvore em (x, z): malha nos lotes, sombra e pé no mapa do chão, lugar ocupado.
func _arvore(lt: Lote, lc: Lote, x: float, z: float, h: float, familia: int, detalhe: int, sombra_fina: bool) -> void:
	var pos := Vector3(x, Relevo.altura(x, z), z)
	if _na_zona(x, z, Formas.raio_tronco(familia, h) + 0.5):
		# Ordem 42: não se planta dentro da zona jogável — mas a semente gasta-se igual (o resto do
		# mapa sai o MESMO) e o lugar fica ocupado (nada mais nasce ali).
		Formas.arvore(Lote.new(), Lote.new(), familia, pos, h, detalhe, _rng)
		_ocupar(_tudo, x, z, Formas.raio_tronco(familia, h) + 0.35)
		_contar_tirado("arvores")
		return
	var sombras: Array = Formas.arvore(lt, lc, familia, pos, h, detalhe, _rng)
	var raio := Formas.raio_tronco(familia, h)
	_ocupar(_tudo, x, z, raio + 0.35)
	_ocupar(_so_arvores, x, z, 0.0)
	if Grelha.casa_em(x, z) != Grelha.FORA:
		_troncos.append([Vector2(x, z), raio])
	if absf(x) > MAPA_MEIO + 12.0 or absf(z) > MAPA_MEIO + 12.0:
		return
	var l := Paleta.dir_luz()
	var dir := Vector2(l.x, l.z).normalized()
	var estica := 1.0 / l.y
	if sombra_fina:
		for s: Array in sombras:
			var c: Vector3 = s[0]
			var rb: float = s[1]
			var g := _sombra_de(c)
			_carimbo_min(0, g.x, g.y, rb * estica * 0.8, rb * 0.95, dir, 0.84)
			_carimbo_min(2, g.x, g.y, rb * estica * 0.8, rb * 0.95, dir, 0.84)
		_sombra_alta([0, 2], pos, h * 0.45, raio * 1.1, 0.80)
	else:
		# na orla funda basta a mancha da copa inteira
		var meio := Vector3.ZERO
		for s: Array in sombras:
			meio += s[0] as Vector3
		meio /= float(maxi(sombras.size(), 1))
		var g2 := _sombra_de(meio)
		var rc := h * (0.20 if familia == Formas.CONIFERA or familia == Formas.JOVEM else 0.34)
		# mais fraca que a das árvores da arena: debaixo da floresta a luz chega coada, em manchas
		_carimbo_min(0, g2.x, g2.y, rc * estica * 0.8, rc, dir, 0.70)
		_carimbo_min(2, g2.x, g2.y, rc * estica * 0.8, rc, dir, 0.70)
	# raízes: terra à mostra e contacto escuro em volta do pé
	_carimbo_max(1, x, z, raio * 2.2 + 0.9, 0.95)
	_contacto(x, z, raio * 3.0 + 1.2, 0.62)


## A CLAREIRA DE SOL do outeiro: uma aberta na parede de floresta a oés-sudoeste dele (o rumo
## do sol), para a luz da tarde acender os menires — o marco lê-se de toda a arena.
func _na_clareira_de_sol(x: float, z: float) -> bool:
	var l := Paleta.dir_luz()
	var para_sol := Vector2(l.x, l.z).normalized()
	var d := Vector2(x, z) - Relevo.OUTEIRO
	var ao_longo := d.dot(para_sol)
	return ao_longo > 0.0 and ao_longo < 46.0 and absf(d.dot(para_sol.orthogonal())) < 7.5 + 0.12 * ao_longo


func _plantar_arvores() -> void:
	# 4 quadrantes × (troncos, copas) = 8 malhas: o corte por frustum trabalha por quadrante.
	var troncos: Array = [Lote.new(), Lote.new(), Lote.new(), Lote.new()]
	var copas: Array = [Lote.new(), Lote.new(), Lote.new(), Lote.new()]
	var R := Formas.REDONDA
	var G := Formas.GUARDA_SOL
	var C := Formas.CONIFERA
	var J := Formas.JOVEM
	# Dentro da arena: postas à mão. Cada quadrante a sua família; o miolo (16 m) e a janela
	# norte (a vista da Árvore Ancestral) ficam abertos; as rampas e o corredor ficam livres.
	var dentro: Array = [
		# NO — carvalhos velhos a norte e a oeste do outeiro (nunca a oés-sudoeste: o sol da
		# tarde tem de chegar aos menires; nenhum na linha das vistas etiquetadas, nem entre elas
		# e o sol — a vista do canto NO ficava à sombra de um carvalho, com a encosta a negro)
		[-36.5, -33.0, 17.5, R], [-17.5, -30.5, 16.0, R], [-33.5, -1.5, 15.5, R], [-22.5, -35.0, 15.0, R],
		# NE — vidoeiros à volta do charco
		[11.5, -27.5, 12.0, J], [14.0, -30.5, 10.5, J], [31.0, -12.5, 12.5, J], [33.5, -32.5, 13.0, J],
		[28.0, -8.5, 11.0, J], [9.5, -12.0, 11.5, J], [10.5, -34.5, 12.0, J], [34.0, -21.0, 10.0, J],
		# SE — pinheiros-mansos à volta do terraço (nenhum a oés-sudoeste do santuário)
		[33.5, 19.5, 16.0, G], [19.5, 34.0, 17.0, G], [33.0, 33.0, 18.0, G],
		[34.0, 3.0, 14.0, G], [2.0, 35.0, 16.0, G],
		# SO — abetos a ladear a garganta
		[-31.5, 14.0, 18.0, C], [-33.0, 20.5, 15.5, C], [-35.5, 36.0, 20.0, C], [-9.0, 27.5, 17.0, C],
		[-10.0, 15.0, 15.0, C], [-28.0, 35.0, 18.0, C], [-11.5, 34.0, 16.0, C]]
	for d: Array in dentro:
		var x: float = d[0]
		var z: float = d[1]
		var q := (0 if x < 0.0 else 1) + (0 if z < 0.0 else 2)
		_arvore(troncos[q], copas[q], x, z, float(d[2]), int(d[3]), 2, true)
	medidas["arvores_arena"] = dentro.size()
	# A orla rica (até 24 m para lá da arena): ao acaso com distância mínima, por famílias.
	# A janela norte fica aberta.
	var postas := 0
	var tentativas := 0
	while postas < 250 and tentativas < 14000:
		tentativas += 1
		var x := _rf(-62.0, 62.0)
		var z := _rf(-62.0, 62.0)
		var f := Relevo.fora(x, z)
		if f < 1.0 or f > Relevo.ORLA_FORA:
			continue
		if Relevo.na_janela(x, z, 3.0) or _na_clareira_de_sol(x, z):
			continue
		if not _livre(_so_arvores, x, z, 4.7) or not _livre(_tudo, x, z, 1.3):
			continue
		var familia := _familia_em(x, z, 0.62)
		var q := (0 if x < 0.0 else 1) + (0 if z < 0.0 else 2)
		_arvore(troncos[q], copas[q], x, z, _altura_familia(familia), familia, 2 if f < 6.0 else 1, f < 9.0)
		postas += 1
	medidas["arvores_orla"] = postas
	var mat_tronco := _mat(SH_SOLIDO)
	mat_tronco.set_shader_parameter("cor_musgo", Paleta.PEDRA_MUSGO)
	mat_tronco.set_shader_parameter("forca_musgo", 0.45)
	var mat_copa := _mat(SH_COPA)
	mat_copa.set_shader_parameter("cor_ouro", Paleta.COPA_OURO)
	var tri := 0
	for q in 4:
		var lt: Lote = troncos[q]
		var lc: Lote = copas[q]
		if not lt.vazio():
			_instancia(arena, lt.fechar(), mat_tronco, "Troncos%d" % q)
			tri += lt.triangulos()
		if not lc.vazio():
			var mi := _instancia(arena, lc.fechar(), mat_copa, "Copas%d" % q)
			mi.extra_cull_margin = 1.0
			tri += lc.triangulos()
	medidas["arvores_tri"] = tri


# ------------------------------------------------------------------ pedras

func _semear_rochas() -> void:
	# À mão, por quadrante: cada pedra está onde serve o combate (meia cobertura no prado, o
	# miradouro da janela, o pé do outeiro, a beira da cova, o pé da escarpa, a crista do lombo).
	var lugares: Array = [
		# o prado do meio: pedras baixas, meia cobertura — nunca um muro
		[4.5, -6.5, 1.1], [-7.5, 3.5, 0.9], [6.5, 8.5, 0.8], [-3.0, -14.5, 1.2], [13.0, 1.0, 0.75], [-12.5, -3.0, 0.6],
		# N — o miradouro da janela
		[-8.5, -33.5, 1.9], [-2.5, -35.5, 1.3], [3.0, -33.0, 1.0], [-13.5, -31.0, 1.2],
		# NO — o pé do outeiro
		[-12.5, -12.5, 1.5], [-28.0, -9.0, 1.3], [-9.5, -23.5, 1.1], [-33.0, -22.0, 1.4], [-24.0, -35.5, 1.0],
		# NE — o rebordo da cova
		[10.0, -14.5, 1.6], [26.5, -10.0, 1.2], [15.5, -28.5, 1.0], [32.0, -18.5, 1.1], [20.0, -34.5, 1.2],
		# SE — o pé da escarpa do terraço
		[13.6, 13.2, 2.2], [15.8, 10.4, 1.5], [10.6, 15.8, 1.6], [11.6, 19.0, 1.1], [18.2, 9.2, 1.0], [34.0, 26.0, 1.4],
		# SO — a crista do lombo e a boca da garganta
		[-23.6, 19.0, 2.1], [-23.1, 15.4, 1.4], [-22.6, 12.2, 1.8], [-22.2, 9.4, 1.2], [-24.2, 22.4, 1.5],
		[-9.5, 19.5, 1.3], [-11.5, 7.5, 1.0], [-34.5, 8.0, 1.2],
		# as beiras
		[34.5, -4.5, 1.3], [-5.0, 34.5, 1.1]]
	for g: Array in lugares:
		var tam: float = g[2]
		_registar_rocha(float(g[0]), float(g[1]), tam)
		# satélites: 1–2 pedras menores encostadas
		for s in _rng.randi_range(1, 2):
			var ang := _rf(0.0, TAU)
			var d := tam * _rf(0.9, 1.4)
			var sx := float(g[0]) + cos(ang) * d
			var sz := float(g[1]) + sin(ang) * d
			if _livre(_tudo, sx, sz, 0.2):
				_registar_rocha(sx, sz, tam * _rf(0.25, 0.5))
	# Na orla: ao acaso.
	var postas := 0
	var tentativas := 0
	while postas < 46 and tentativas < 3000:
		tentativas += 1
		var x := _rf(-60.0, 60.0)
		var z := _rf(-60.0, 60.0)
		var f := Relevo.fora(x, z)
		if f < 0.5 or f > Relevo.ORLA_FORA - 2.0:
			continue
		var tam := _rf(0.6, 2.4)
		if not _livre(_tudo, x, z, tam * 0.9 + 0.3):
			continue
		_registar_rocha(x, z, tam)
		postas += 1
	var m := _mat(SH_SOLIDO)
	m.set_shader_parameter("cor_musgo", Paleta.PEDRA_MUSGO)
	m.set_shader_parameter("forca_musgo", 0.80)
	m.set_shader_parameter("musgo_de", 0.56)
	m.set_shader_parameter("musgo_liso", 1.0)
	_instancia(arena, _lote_pedras.fechar(), m, "Pedras")
	medidas["rochas"] = _rochas.size()
	medidas["rochas_tri"] = _lote_pedras.triangulos()


func _registar_rocha(x: float, z: float, tam: float) -> void:
	var c := Vector3(x, Relevo.altura(x, z), z)
	_ocupar(_tudo, x, z, tam * 0.9)
	var esc := Vector3(tam * _rf(0.85, 1.25), tam * _rf(0.55, 0.9), tam * _rf(0.85, 1.25))
	var rot := Basis(Vector3.UP, _rf(0.0, TAU)) * Basis(Vector3.RIGHT, _rf(-0.25, 0.25))
	var cor := Paleta.PEDRA.lerp(Paleta.PEDRA_QUENTE, _rf(0.0, 0.7))
	var veio := _rf(0.0, 60.0)
	if _na_zona(x, z, tam * 0.9):
		_contar_tirado("rochas")   # Ordem 42: a semente gastou-se igual; a pedra não se põe
		return
	_rochas.append([c, tam])
	_lote_pedras.rocha(c + Vector3(0, esc.y * 0.20, 0), esc, rot, 2 if tam > 1.1 else 1, cor, veio)
	var l := Paleta.dir_luz()
	var g := _sombra_de(c + Vector3(0, tam * 0.3, 0))
	_carimbo_min(0, g.x, g.y, tam * 0.9 * (1.0 + 0.5 / l.y), tam * 0.95, Vector2(l.x, l.z).normalized(), 0.9)
	_carimbo_max(1, x, z, tam * 1.2 + 0.2, 1.0)
	_contacto(x, z, tam * 1.8 + 0.5, 0.62)


# ------------------------------------------------------------------ estrato intermédio

## O que fica entre a relva e as copas (defeito 6): quatro silhuetas que não se confundem com
## pedra — arbusto de chamas direitas, silvado baixo com bagas, feto em arco, folha larga.
## Um MultiMesh por família e por quadrante (o corte por frustum tira os de trás).
func _criar_estrato() -> void:
	var malhas: Array = [Formas.arbusto(11), Formas.silvado(12), Formas.feto(13), Formas.folha_larga(14)]
	var nomes: Array[String] = ["Arbustos", "Silvados", "Fetos", "FolhasLargas"]
	var quantos: Array[int] = [96, 44, 240, 210]
	var listas: Array = []
	for t in 4:
		listas.append([[], [], [], []])
	var cova := Relevo.COVA
	for tipo in 4:
		var postos := 0
		var tent := 0
		while postos < quantos[tipo] and tent < 30000:
			tent += 1
			var x := _rf(-60.0, 60.0)
			var z := _rf(-60.0, 60.0)
			var f := Relevo.fora(x, z)
			if f > Relevo.ORLA_FORA - 3.0 or Vector2(x, z).length() < 15.0:
				continue
			if Relevo.agua(x, z) > 0.02 or Relevo.normal(x, z).y < 0.82 or _terra_em(x, z) > 0.5:
				continue
			var coberto := _coberto_em(x, z)
			var beira := 1.0 - smoothstep(0.0, 4.0, Vector2(x - cova.x, z - cova.y).length() - 5.4)
			var prob := 0.0
			var folga := 0.9
			match tipo:
				0:  # arbusto: a orla da floresta, à volta das pedras e ao longo do lombo
					prob = 0.05 + 0.55 * smoothstep(-8.0, 1.0, f) * (1.0 - smoothstep(10.0, 18.0, f))
					prob = maxf(prob, 0.55 * (1.0 - smoothstep(2.0, 4.5, Relevo.ao_segmento(Vector2(x, z), Relevo.LOMBO_A, Relevo.LOMBO_B).x)))
					folga = 1.3
				1:  # silvado: clareiras de sol na orla e o pé das vertentes
					prob = 0.04 + 0.30 * smoothstep(-5.0, 3.0, f) * (1.0 - coberto)
					folga = 1.5
				2:  # feto: debaixo das copas, na garganta e à beira da cova
					prob = 0.04 + 0.65 * coberto + 0.45 * beira
					if x < -8.0 and z > 6.0:
						prob += 0.25
					folga = 0.55
				3:  # folha larga: a beira-água e a sombra funda
					prob = 0.03 + 0.85 * beira + 0.35 * coberto * smoothstep(0.0, 8.0, f)
					folga = 0.5
			if Relevo.na_janela(x, z) and f > -3.0:
				prob *= 0.35
			if _rng.randf() > prob or not _livre(_tudo, x, z, folga):
				continue
			var s := _rf(0.75, 1.25)
			if tipo == 0:
				s = _rf(0.85, 1.35)
			var b := Basis(Vector3.UP, _rf(0.0, TAU)).scaled(Vector3(s, s * _rf(0.88, 1.18), s))
			var tom := _rf(0.86, 1.08)
			var cor_e := Color(tom, tom * _rf(0.96, 1.04), tom * _rf(0.92, 1.0), 1.0)
			if _na_zona(x, z, 0.9 * s):
				_contar_tirado("estrato")   # Ordem 42: fora da zona jogável (a semente gastou-se igual)
				postos += 1
				continue
			(listas[tipo][(0 if x < 0.0 else 1) + (0 if z < 0.0 else 2)] as Array).append(
				[Transform3D(b, Vector3(x, Relevo.altura(x, z) - 0.04, z)), cor_e])
			if tipo < 2:
				_ocupar(_tudo, x, z, 0.55 * s)
				_carimbo_max(1, x, z, 0.75 * s, 0.7)
				_contacto(x, z, 1.3 * s, 0.5)
				var g := _sombra_de(Vector3(x, Relevo.altura(x, z) + 0.6 * s, z))
				var l := Paleta.dir_luz()
				_carimbo_min(0, g.x, g.y, 1.3 * s, 0.9 * s, Vector2(l.x, l.z).normalized(), 0.8)
				grelha.dar_cobertura(Grelha.casa_em(x, z), Grelha.COBERTURA_MEIA)
			else:
				_ocupar(_tudo, x, z, 0.15)
				_contacto(x, z, 0.8 * s, 0.35)
			postos += 1
		medidas["estrato_" + nomes[tipo].to_lower()] = postos
	var m := _mat(SH_COPA)
	m.set_shader_parameter("cor_ouro", Paleta.COPA_OURO)
	m.set_shader_parameter("vento_forca", 0.09)
	var tri := 0
	for tipo in 4:
		var lote: Lote = malhas[tipo]
		var malha := lote.fechar()
		for q in 4:
			var lista: Array = listas[tipo][q]
			if lista.is_empty():
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_colors = true
			mm.mesh = malha
			mm.instance_count = lista.size()
			for i in lista.size():
				mm.set_instance_transform(i, lista[i][0])
				mm.set_instance_color(i, lista[i][1])
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "%s%d" % [nomes[tipo], q]
			mmi.multimesh = mm
			mmi.material_override = m
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			arena.add_child(mmi)
			tri += lista.size() * lote.triangulos()
	medidas["estrato_tri"] = tri


# ------------------------------------------------------------------ relva

func _criar_relva() -> void:
	var mat := _mat(SH_RELVA)
	mat.set_shader_parameter("cor_base", Paleta.RELVA_BASE)
	mat.set_shader_parameter("cor_ponta", Paleta.RELVA_PONTA)
	mat.set_shader_parameter("cor_seca", Paleta.RELVA_SECA)
	mat.set_shader_parameter("cor_floresta", Paleta.RELVA_SOMBRA)
	var mat_haste := _mat(SH_HASTE)
	mat_haste.set_shader_parameter("cor_haste", Paleta.JUNCO)
	relva = RelvaFloresta.new()
	relva.name = "Relva"
	arena.add_child(relva)
	if zona_jogo.has_area():
		var r := Vector4(zona_jogo.position.x, zona_jogo.position.y, zona_jogo.end.x, zona_jogo.end.y)
		mat.set_shader_parameter("campo_rect", r)
		mat.set_shader_parameter("campo_alto", relva_no_campo)
		mat_haste.set_shader_parameter("campo_rect", r)
		mat_haste.set_shader_parameter("campo_alto", relva_no_campo * 0.6)
	relva.semear(mat, mat_haste, _terra_em, _coberto_em, semente + 7)
	medidas.merge(relva.medidas, true)
	relva.definir_densidade(densidade_relva)


# ------------------------------------------------------------------ a grelha (terreno estático)

## Escreve na grelha o que o terreno é: o que BLOQUEIA (tronco, rocha, água funda, escarpa — os
## marcos já se escreveram ao levantar-se) e a COBERTURA que cada casa dá.
func _marcar_grelha() -> void:
	for lj in Grelha.LADO:
		for ci in Grelha.LADO:
			var casa := Vector2i(ci, lj)
			var c := Grelha.canto(casa) + Vector2(0.75, 0.75)
			if Relevo.agua(c.x, c.y) > 0.40:
				grelha.bloquear(casa, "água funda")
			elif Grelha.degrau(casa) > ESCARPA_M:
				grelha.bloquear(casa, "escarpa")
	for t: Array in _troncos:
		var p: Vector2 = t[0]
		var casa := Grelha.casa_em(p.x, p.y)
		grelha.bloquear(casa, "tronco")
		for viz in Grelha.vizinhas(casa, false):
			grelha.dar_cobertura(viz, Grelha.COBERTURA_MEIA)
	for r: Array in _rochas:
		var c: Vector3 = r[0]
		var tam: float = r[1]
		var casa := Grelha.casa_em(c.x, c.z)
		if casa == Grelha.FORA:
			continue
		if tam >= 1.0:
			var alcance := int(ceil(tam / Grelha.CASA_M))
			for dj in range(-alcance, alcance + 1):
				for di in range(-alcance, alcance + 1):
					var outra := casa + Vector2i(di, dj)
					if not Grelha.dentro(outra):
						continue
					var d := (Grelha.canto(outra) + Vector2(0.75, 0.75)).distance_to(Vector2(c.x, c.z))
					if d < tam * 0.85 or outra == casa:
						grelha.bloquear(outra, "rocha")
					elif d < tam * 0.85 + 1.6:
						grelha.dar_cobertura(outra, Grelha.COBERTURA_TOTAL if tam >= 1.5 else Grelha.COBERTURA_MEIA)
		elif tam >= 0.5:
			grelha.dar_cobertura(casa, Grelha.COBERTURA_MEIA)
	# A prova de que se joga: todas as casas livres têm de estar ligadas ao centro (4 vizinhas).
	var visto := PackedByteArray()
	visto.resize(Grelha.LADO * Grelha.LADO)
	var fila: Array[Vector2i] = [Vector2i(25, 25)]
	visto[Grelha.indice(fila[0])] = 1
	var cabeca := 0
	while cabeca < fila.size():
		var casa := fila[cabeca]
		cabeca += 1
		for viz in Grelha.vizinhas(casa, false):
			if visto[Grelha.indice(viz)] == 0 and not grelha.bloqueada(viz):
				visto[Grelha.indice(viz)] = 1
				fila.append(viz)
	var bloqueadas := grelha.casas_bloqueadas()
	medidas["casas"] = Grelha.LADO * Grelha.LADO
	medidas["casas_bloqueadas"] = bloqueadas
	medidas["casas_livres"] = Grelha.LADO * Grelha.LADO - bloqueadas
	medidas["casas_livres_isoladas"] = Grelha.LADO * Grelha.LADO - bloqueadas - fila.size()
	medidas["centro_livre"] = not grelha.bloqueada(Vector2i(25, 25))


# ------------------------------------------------------------------ o fundo: o anel de floresta

## Ponto do mundo a `f` metros para fora da orla da arena, no azimute `ang` (radianos).
func _ponto_anel(ang: float, f: float) -> Vector2:
	var dx := sin(ang)
	var dz := -cos(ang)
	var r := (Relevo.MEIO + f) / Relevo.quadrado(dx, dz)
	return Vector2(dx * r, dz * r)


## A floresta para lá da orla rica (defeito 1). Árvores INTEIRAS das mesmas famílias, com o pé
## no MESMO chão (a zona larga do terreno, que vai até à cor do horizonte) e a mesma luz; só a
## malha é pobre. Uma malha por quadrante (tronco e copa juntos): no máximo 4 chamadas.
func _criar_anel() -> void:
	var troncos: Array = [Lote.new(), Lote.new(), Lote.new(), Lote.new()]
	var copas: Array = [Lote.new(), Lote.new(), Lote.new(), Lote.new()]
	var postas := 0
	var tent := 0
	while postas < 720 and tent < 30000:
		tent += 1
		var ang := _rf(0.0, TAU)
		var f := lerpf(Relevo.ORLA_FORA + 0.5, Relevo.ANEL_FORA, pow(_rng.randf(), 1.15))
		var p := _ponto_anel(ang, f)
		var baixa := 1.0
		if Relevo.na_janela(p.x, p.y, 5.0):
			# na janela da Árvore Ancestral o vale fica aberto: poucas árvores, baixas e ao fundo
			if f < 40.0 or _rng.randf() > 0.4:
				continue
			baixa = 0.62
		if not _livre(_so_arvores, p.x, p.y, 5.2):
			continue
		var familia := _familia_em(p.x, p.y, 0.55)
		var q := (0 if p.x < 0.0 else 1) + (0 if p.y < 0.0 else 2)
		var pos := Vector3(p.x, Relevo.altura(p.x, p.y), p.y)
		Formas.arvore(troncos[q], copas[q], familia, pos, _altura_familia(familia) * baixa, 1 if f < 44.0 else 0, _rng)
		_ocupar(_so_arvores, p.x, p.y, 0.0)
		postas += 1
	var m := _mat(SH_ANEL)
	m.set_shader_parameter("cor_ouro", Paleta.COPA_OURO)
	m.set_shader_parameter("cor_musgo", Paleta.PEDRA_MUSGO)
	var tri := 0
	for q in 4:
		var lt: Lote = troncos[q]
		var lc: Lote = copas[q]
		if lt.vazio():
			continue
		for i in lt.uv.size():
			lt.uv[i] = Vector2(2.0, 0.0)      # marca TRONCO (shaders/anel_floresta.gdshader)
		var base := lt.v.size()
		lt.v.append_array(lc.v)
		lt.n.append_array(lc.n)
		lt.c.append_array(lc.c)
		lt.uv.append_array(lc.uv)
		var de := lt.idx.size()
		lt.idx.append_array(lc.idx)
		for i in range(de, lt.idx.size()):
			lt.idx[i] += base
		var mi := _instancia(fundo, lt.fechar(), m, "AnelFloresta%d" % q)
		mi.extra_cull_margin = 1.0
		tri += lt.triangulos()
	medidas["anel_arvores"] = postas
	medidas["anel_tri"] = tri


# ------------------------------------------------------------------ o fundo: anel longe

## Duas silhuetas FECHADAS à volta do mapa (floresta e montes, em quadrado arredondado para lá
## da orla do chão) e a serra ao fundo (círculo, atrás da Árvore Ancestral). Todo o ar na tinta;
## a base de cada uma é a COR DO HORIZONTE.
func _criar_anel_longe() -> void:
	var lt := Lote.new()
	var rn := Relevo.ruido()
	var sol_az := deg_to_rad(Paleta.SOL_AZIMUTE)
	var az_ancora := deg_to_rad(Relevo.ANCORA_AZIMUTE)
	# para fora (ou raio, se círculo), altura mín, altura máx, ar (0–1), tinta, frequência, dentes, círculo?, base
	var capas: Array = [
		[Relevo.CHAO_FORA + 14.0, 8.0, 18.0, 0.60, Paleta.ANEL_FLORESTA.lerp(Paleta.ANEL_MONTE, 0.25), 260.0, 0.9, false, -34.0],
		[Relevo.CHAO_FORA + 78.0, 15.0, 34.0, 0.74, Paleta.ANEL_FLORESTA.lerp(Paleta.ANEL_MONTE, 0.70), 180.0, 0.45, false, -40.0],
		[980.0, 60.0, 190.0, 0.86, Paleta.ANEL_SERRA, 140.0, 0.0, true, -90.0],
	]
	var n := 384
	for capa: Array in capas:
		var dist: float = capa[0]
		var hmin: float = capa[1]
		var hmax: float = capa[2]
		var ar: float = capa[3]
		var tinta: Color = capa[4]
		var freq: float = capa[5]
		var dentes: float = capa[6]
		var circulo: bool = capa[7]
		var chao: float = capa[8]
		var base := lt.v.size()
		for i in n:
			var ang := TAU * float(i) / float(n)
			var cx := cos(ang)
			var sz := sin(ang)
			# perfil periódico: ruído amostrado sobre um círculo (fecha sem costura)
			var p := 0.5 + 0.5 * rn.get_noise_2d(cx * freq + dist, sz * freq)
			p = p * 0.65 + 0.35 * (0.5 + 0.5 * rn.get_noise_2d(cx * freq * 3.1, sz * freq * 3.1 + dist))
			if dentes <= 0.0:
				# serra: cumes vincados
				p = 1.0 - absf(2.0 * p - 1.0)
				p = p * 0.75 + 0.25 * (0.5 + 0.5 * rn.get_noise_2d(cx * freq * 6.0 + 9.0, sz * freq * 6.0))
			var h := lerpf(hmin, hmax, clampf(p, 0.0, 1.0))
			var pos: Vector2
			if circulo:
				pos = Vector2(sin(ang), -cos(ang)) * dist
			else:
				pos = _ponto_anel(ang, dist)
				# o passo da Árvore Ancestral: as capas da frente baixam para o pé dela se ver
				h *= lerpf(0.22, 1.0, smoothstep(deg_to_rad(11.0), deg_to_rad(34.0), absf(angle_difference(ang, az_ancora))))
				h += Relevo.altura(pos.x, pos.y) * 0.35
			# dentes de copa na silhueta de floresta
			h += dentes * (1.2 + 1.2 * rn.get_noise_2d(cx * 4200.0, sz * 4200.0 + dist))
			# para o lado do sol o ar é mais espesso (mais claro)
			var lado := 0.5 + 0.5 * cos(ang - sol_az)
			var ar_i := clampf(ar + 0.08 * lado * lado, 0.0, 0.96)
			var cor_topo := Paleta.ar(tinta, ar_i)
			lt.v.append_array([Vector3(pos.x, chao, pos.y), Vector3(pos.x, chao + (h - chao) * 0.55, pos.y),
				Vector3(pos.x, chao + (h - chao) * 0.85, pos.y), Vector3(pos.x, h, pos.y)])
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


# ------------------------------------------------------------------ o fundo: a Árvore Ancestral

## O marco do mapa (defeito 2): geometria verdadeira, opaca, com a luz do mapa, a sombra da
## copa cozida no tronco e o outeiro de copas onde assenta (com a sombra dela pintada: contacto).
func _criar_ancestral() -> void:
	var d: Dictionary = Ancestral.construir()
	var rumo := Paleta.dir_de(Relevo.ANCORA_AZIMUTE, 0.0)
	var pe := Vector3(rumo.x * ANCESTRAL_DIST, ANCESTRAL_PE, rumo.z * ANCESTRAL_DIST)
	var m := _mat(SH_ANCESTRAL)
	m.set_shader_parameter("cor_musgo", Paleta.ANCESTRAL_MUSGO)
	m.set_shader_parameter("cor_folha_luz", Paleta.ANCESTRAL_FOLHA_LUZ)
	m.set_shader_parameter("altura", Ancestral.ALTURA)
	var mi := _instancia(fundo, d["malha"], m, "ArvoreAncestral")
	mi.position = pe
	mi.rotation.y = ANCESTRAL_ROTACAO
	var mat_monte := ShaderMaterial.new()
	mat_monte.shader = SH_ANEL_LONGE
	var monte := _instancia(fundo, d["outeiro"], mat_monte, "OuteiroAncestral")
	monte.position = pe
	medidas["ancestral_tri"] = d["tri"]
	medidas["ancestral_partes"] = d["partes"]
	medidas["ancestral_outeiro_tri"] = d["outeiro_tri"]
	medidas["ancestral_pagodes"] = d["pagodes"]
	medidas["ancestral_pagodes_no_ar"] = d["pagodes_no_ar"]
	if int(d["pagodes_no_ar"]) > 0:
		Erros.erro(Erros.SEM_APOIO, "Árvore Ancestral: %d pagode(s) sem apoio por baixo" % int(d["pagodes_no_ar"]))
	medidas["ancestral_altura_m"] = Ancestral.ALTURA
	# a altura MEDIDA na malha (não a declarada): do pé do tronco (y = 0 do modelo) ao cimo da copa
	var caixa: AABB = (d["malha"] as ArrayMesh).get_aabb()
	medidas["ancestral_cimo_medido_m"] = snappedf(caixa.end.y, 0.1)
	medidas["ancestral_largura_medida_m"] = snappedf(maxf(caixa.size.x, caixa.size.z), 0.1)
	medidas["ancestral_dist_m"] = ANCESTRAL_DIST
