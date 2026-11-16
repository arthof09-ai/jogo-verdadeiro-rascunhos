extends Node3D
## clareira_prova.gd — Assimilação, missão V2.1 (Plano B v1.1): ESQUELETO da Clareira de prova.
## Dono: Claude (arte/). Rascunho escrito sob a NAC-OV-05: nunca foi executado.
##
## Objetivo deste esqueleto: o Muse e o Claude medirem JÁ o orçamento do kit V1.1 (chamadas,
## primitivas, FPS) com a mesma luz, céu, neblina e ciclo das 4 horas da Clareira final.
##
## >>> TUDO o que é geometria aqui é PLACEHOLDER (cilindros, esferas, caixas e cápsulas).
## >>> Nada disto vai ao olho do Mestre: a V2.1 troca pelos assets FICA/LAPIDA, o T1 do chão,
## >>> a Besta Cristalina e os vagalumes da V2.0c. Sem chibi e sem marcador na entrega.
##
## Teclas (só para a bancada): 1-4 = 6,5 h / 15 h / 18,5 h / 22 h; P = próximo perfil;
## C = liga/desliga o ciclo automático; M = imprime a medição (JSON) no console.
## No celular não há teclado: o ciclo corre sozinho e o rótulo mostra os números.

const LADO_CASAS := 20
const CASA_M := 1.5
const LADO_M := LADO_CASAS * CASA_M  # 30 m
const ESCALA_FIGURA := 1.25  # regra dele: figuras ×1,25
const HORAS_CHAVE: Array[float] = [6.5, 15.0, 18.5, 22.0]  # as do color script (Ordem 65)
const PERFIS: Array[String] = ["baixo", "medio", "alto"]
const AQUECIMENTO_S := 10.0  # B3: medir depois de 10 s
## O sol da casa (os números do ciclo do dia do mapa): nasce às 6 h, culmina às 12,5 h a 61,5°,
## põe-se às 19 h.
const LATITUDE := 38.0
const SOL_DECLINACAO := 9.5
const SOL_CULMINA := 12.5
## A máscara de pincelada da casa (arte/pincel/gerar_pincel.gd).
const PINCEL := "res://arte/pincel/pincel_mascara.png"
## Quanto a máscara quebra o terminador nos materiais da Clareira. Com a máscara da casa (traço
## de alto contraste), 0,12 deixa ler os degraus da rampa e ainda esfiapa a borda como pincel.
const FORCA_PINCEL := 0.12
const JANELA_QUADROS := 1800  # ~60 s a 30 fps
## PONTO PARA O OLHO DO MESTRE (REF_23): pontilhado nas copas que tapam figuras. Desligado por defeito.
const USAR_PONTILHADO_COPAS := false

const SHADER_TOON := preload("res://arte/shaders/toon_pintado.gdshader")
const SHADER_CONTORNO := preload("res://arte/shaders/contorno_casca.gdshader")
const SHADER_FOLHAGEM := preload("res://arte/shaders/folhagem_vento.gdshader")

@export var hora: float = 15.0
@export var ciclo_automatico: bool = true
## Um dia inteiro (24 h de jogo) em segundos reais.
@export var segundos_por_dia: float = 240.0
## A hora só é escrita na cena em degraus deste tamanho. O céu usa LIGHT0_* e uniforms:
## qualquer mudança no sol ou numa uniform refaz o cubemap de radiance (doc do sky shader).
@export var passo_hora: float = 0.1
@export var perfil: String = "medio"
@export var semente: int = 7
@export var quantidade_arbustos: int = 60

@onready var _ambiente: WorldEnvironment = $Ambiente
@onready var _sol: DirectionalLight3D = $Sol
@onready var _camera: Camera3D = $Camera
@onready var _perfis: AplicadorPerfil = $Perfis
@onready var _rotulo: Label = $Medicao/Rotulo

var _cs: ColorScript
var _mat_ceu: ShaderMaterial
var _mats_luz: Array[ShaderMaterial] = []
var _mats_contorno: Array[ShaderMaterial] = []
var _figuras: Array[Node3D] = []
var _rampas: Dictionary = {}
var _pincel: Texture2D
var _rng := RandomNumberGenerator.new()
var _hora_escrita := -100.0
var _t := 0.0
var _t_rotulo := 0.0
var _tempos := PackedFloat32Array()


func _ready() -> void:
	_rng.seed = semente
	_cs = ColorScript.new()
	_mat_ceu = _ambiente.environment.sky.sky_material as ShaderMaterial
	if _mat_ceu:
		_cs.preencher_ceu(_mat_ceu)
	_pincel = _gerar_pincel()
	_criar_chao()
	_criar_arvores()
	_criar_arbustos()
	_criar_rochas()
	_criar_tochas()
	_criar_figuras()
	if _camera.has_method("configurar_arena"):
		_camera.call("configurar_arena", Vector3.ZERO, Vector2(LADO_M, LADO_M))
	_perfis.aplicar(perfil)
	_escrever_hora(true)
	print("[clareira] pronta: perfil=%s hora=%.1f (PLACEHOLDERS)" % [perfil, hora])


func _process(delta: float) -> void:
	_t += delta
	if ciclo_automatico and segundos_por_dia > 0.0:
		hora = fposmod(hora + delta * 24.0 / segundos_por_dia, 24.0)
	_escrever_hora(false)
	# PLACEHOLDER de "respiração", para a figura parada não ser estátua (B1). Some na V3.1.
	for i in _figuras.size():
		_figuras[i].scale = Vector3(1.0, 1.0 + 0.012 * sin(_t * 2.2 + float(i)), 1.0)
	if _t > AQUECIMENTO_S:
		_tempos.append(delta)
		if _tempos.size() > JANELA_QUADROS:
			_tempos.remove_at(0)
	_t_rotulo += delta
	if _t_rotulo >= 0.5:
		_t_rotulo = 0.0
		_atualizar_rotulo()


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	match k.keycode:
		KEY_1, KEY_2, KEY_3, KEY_4:
			hora = HORAS_CHAVE[k.keycode - KEY_1]
			_escrever_hora(true)
		KEY_P:
			var i := (PERFIS.find(AplicadorPerfil.normalizar(perfil)) + 1) % PERFIS.size()
			perfil = PERFIS[i]
			_perfis.aplicar(perfil)
		KEY_C:
			ciclo_automatico = not ciclo_automatico
		KEY_M:
			_imprimir_medicao()


# ------------------------------------------------------------------ hora e luz

func _escrever_hora(forcar: bool) -> void:
	var h := snappedf(fposmod(hora, 24.0), maxf(passo_hora, 0.01))
	if not forcar and is_equal_approx(h, _hora_escrita):
		return
	_hora_escrita = h
	_cs.aplicar(h, _sol, _ambiente.environment, _mats_luz, _mats_contorno, _mat_ceu)
	_posicionar_sol(h)


## O arco do sol é o da casa: a mesma conta do ciclo do dia do mapa (latitude, declinação e hora
## da culminação), por isso em cada hora-chave o sol está onde a paleta dessa hora o espera.
## Rasante, a geometria da luz fica presa nos 3°. De noite a mesma luz faz de lua, alta e fria
## (a cor e a energia vêm do color script). A V4.3 substitui por um arco contínuo, com lua própria.
func _posicionar_sol(h: float) -> void:
	var ah := deg_to_rad((h - SOL_CULMINA) * 15.0)
	var d := deg_to_rad(SOL_DECLINACAO)
	var f := deg_to_rad(LATITUDE)
	var elevacao := rad_to_deg(asin(clampf(sin(f) * sin(d) + cos(f) * cos(d) * cos(ah), -1.0, 1.0)))
	# azimute a partir do norte (-Z), positivo para leste (+X): a convenção da paleta da casa
	var azimute := rad_to_deg(atan2(-cos(d) * sin(ah), cos(f) * sin(d) - sin(f) * cos(d) * cos(ah)))
	if elevacao < 0.0:
		elevacao = 38.0
		azimute = 30.0
	# a luz viaja ao longo de -Z do nó: virar o nó de costas para o astro
	_sol.rotation_degrees = Vector3(-maxf(elevacao, 3.0), 180.0 - azimute, 0.0)


# ------------------------------------------------------------------ materiais

func _rampa(familia: String) -> Texture2D:
	if _rampas.has(familia):
		return _rampas[familia]
	var tex: Texture2D
	var caminho := "res://arte/rampas/rampa_%s.png" % familia
	if ResourceLoader.exists(caminho):
		tex = load(caminho) as Texture2D
	if tex == null:
		# Recurso: rampa genérica, só se o PNG da família faltar (arte/rampas/gerar_rampas.gd).
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.42, 0.56, 0.70, 1.0])
		g.colors = PackedColorArray([Color.BLACK, Color.BLACK, Color(0.55, 0.48, 0.55), Color.WHITE, Color.WHITE])
		var gt := GradientTexture1D.new()
		gt.gradient = g
		gt.width = 256
		tex = gt
	_rampas[familia] = tex
	return tex


## A máscara de pincelada da casa (arte/pincel/pincel_mascara.png): pinceladas com cerdas, 0,5 = neutro.
func _gerar_pincel() -> Texture2D:
	if ResourceLoader.exists(PINCEL):
		var tex := load(PINCEL) as Texture2D
		if tex != null:
			return tex
	# Recurso, só se o PNG faltar: ruído contínuo em cinzento.
	var ruido := FastNoiseLite.new()
	ruido.seed = semente + 1
	ruido.frequency = 0.06
	var img: Image = ruido.get_seamless_image(128, 128)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## PLACEHOLDER do chão (o T1 da V2.0a substitui): duas cores de terra e musgo, nunca preto.
func _gerar_albedo_chao() -> Texture2D:
	var ruido := FastNoiseLite.new()
	ruido.seed = semente
	ruido.frequency = 0.03
	var base: Image = ruido.get_seamless_image(128, 128)
	var img := Image.create_empty(128, 128, false, Image.FORMAT_RGBA8)
	var musgo := Color("#56603a")
	var terra := Color("#7d6b4a")
	for y in 128:
		for x in 128:
			img.set_pixel(x, y, musgo.lerp(terra, base.get_pixel(x, y).r))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _mat_toon(familia: String, cor: Color) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER_TOON
	m.set_shader_parameter("cor_albedo", cor)
	m.set_shader_parameter("rampa", _rampa(familia))
	m.set_shader_parameter("pincel", _pincel)
	m.set_shader_parameter("forca_pincel", FORCA_PINCEL)
	_mats_luz.append(m)
	return m


func _mat_figura(familia: String, cor: Color) -> ShaderMaterial:
	var m := _mat_toon(familia, cor)
	var c := ShaderMaterial.new()
	c.shader = SHADER_CONTORNO
	c.set_shader_parameter("cor_albedo", cor)
	_mats_contorno.append(c)
	m.next_pass = c  # o AplicadorPerfil liga/desliga pelo grupo "figura"
	return m


## altura_presa / faixa_presa em espaço do modelo. As esferas-placeholder têm o pivô no
## centro, por isso a base fica em -raio (um GLB real tem o pivô no chão: altura_presa ~0,3).
func _mat_folhagem(cor: Color, altura_presa: float, faixa_presa: float) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER_FOLHAGEM
	m.set_shader_parameter("cor_albedo", cor)
	m.set_shader_parameter("rampa", _rampa("folhagem"))
	m.set_shader_parameter("pincel", _pincel)
	m.set_shader_parameter("forca_pincel", FORCA_PINCEL)
	m.set_shader_parameter("fonte_peso", 0)  # sem cor de vértice: COLOR.r = 1; a altura manda
	m.set_shader_parameter("centro_copa", Vector3.ZERO)
	m.set_shader_parameter("altura_presa", altura_presa)
	m.set_shader_parameter("faixa_presa", faixa_presa)
	# REF_23 (I0004, 08/11): o pontilhado das copas (alpha hash) fica DESLIGADO até à palavra do Mestre:
	# ele mandou tirar o pontilhado do chão do site. Por defeito, copas sem pontilhado (alpha scissor).
	m.set_shader_parameter("usar_alpha_hash", USAR_PONTILHADO_COPAS)
	_mats_luz.append(m)
	return m


# ------------------------------------------------------------------ placeholders

func _casa(i: int, j: int) -> Vector3:
	return Vector3((float(i) - (LADO_CASAS - 1) * 0.5) * CASA_M, 0.0, (float(j) - (LADO_CASAS - 1) * 0.5) * CASA_M)


func _malha(mesh: Mesh, mat: Material, pos: Vector3, nome: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi


func _criar_chao() -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(LADO_M + 14.0, LADO_M + 14.0)
	var m := _mat_toon("chao", Color.WHITE)
	m.set_shader_parameter("textura_albedo", _gerar_albedo_chao())
	m.set_shader_parameter("escala_uv", Vector2(6.0, 6.0))
	# Sem luz de contorno no chão: num plano visto de raspão o rim acendia o chão inteiro ao
	# longe e estourava-o a branco (visto nas capturas da Ordem 65).
	m.set_shader_parameter("forca_rim", 0.0)
	var chao := _malha(pm, m, Vector3.ZERO, "Chao_PLACEHOLDER")
	chao.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Frondosas (12,5–14 m) em volta da arena e uma gigante ao fundo (B1, medidas adotadas).
func _criar_arvores() -> void:
	var casca := _mat_toon("casca", Color("#6b5644"))
	var copa_mat := _mat_folhagem(Color("#5f8a3c"), -2.5, 3.5)
	var lugares: Array[Vector3] = [
		Vector3(-18, 0, -12), Vector3(-17, 0, 6), Vector3(18, 0, -8),
		Vector3(17.5, 0, 9), Vector3(-6, 0, -19), Vector3(8, 0, -18.5),
	]
	for i in lugares.size():
		_arvore(lugares[i], 6.0, 0.5, 4.0, casca, copa_mat, "Arvore%d_PLACEHOLDER" % i)
	var copa_gigante := _mat_folhagem(Color("#4f7a38"), -4.0, 5.0)
	_arvore(Vector3(2, 0, -27), 10.0, 1.1, 6.5, casca, copa_gigante, "ArvoreGigante_PLACEHOLDER")


func _arvore(pos: Vector3, altura_tronco: float, raio: float, raio_copa: float,
		casca: Material, copa_mat: Material, nome: String) -> void:
	var tronco := CylinderMesh.new()
	tronco.top_radius = raio * 0.7
	tronco.bottom_radius = raio
	tronco.height = altura_tronco
	tronco.radial_segments = 12
	_malha(tronco, casca, pos + Vector3(0, altura_tronco * 0.5, 0), nome + "_tronco")
	var copa := SphereMesh.new()
	copa.radius = raio_copa
	copa.height = raio_copa * 1.6
	copa.radial_segments = 24
	copa.rings = 12
	# MeshInstance3D própria por copa: o opacidade_dither (instance uniform) é por instância.
	var mi := _malha(copa, copa_mat, pos + Vector3(0, altura_tronco + raio_copa * 0.5, 0), nome + "_copa")
	mi.add_to_group(&"folhagem")


## Arbustos 0,7–1 × 1,2–1,8 m numa MultiMesh (1 chamada), embaralhados para a densidade.
func _criar_arbustos() -> void:
	var esfera := SphereMesh.new()
	esfera.radius = 0.7
	esfera.height = 0.9
	esfera.radial_segments = 12
	esfera.rings = 6
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = esfera
	mm.instance_count = quantidade_arbustos
	for i in quantidade_arbustos:
		var ang := _rng.randf() * TAU
		var dist := _rng.randf_range(LADO_M * 0.5 - 2.0, LADO_M * 0.5 + 5.0)
		var s := _rng.randf_range(0.85, 1.3)
		var b := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3(s, s, s))
		mm.set_instance_transform(i, Transform3D(b, Vector3(cos(ang) * dist, 0.45 * s, sin(ang) * dist)))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Arbustos_PLACEHOLDER"
	mmi.multimesh = mm
	mmi.material_override = _mat_folhagem(Color("#6a9443"), -0.45, 0.9)
	mmi.add_to_group(&"folhagem")
	mmi.add_to_group(&"folhagem_densa")
	add_child(mmi)


## Rochas 3–3,4 m, 1,9–2,3 m e 0,6–1,1 m (B1).
func _criar_rochas() -> void:
	var pedra := _mat_toon("pedra", Color("#8c8798"))
	var tamanhos: Array[Vector3] = [
		Vector3(3.2, 3.0, 2.6), Vector3(2.1, 1.9, 1.8), Vector3(2.2, 2.0, 1.6),
		Vector3(0.9, 0.7, 0.8), Vector3(1.0, 0.6, 0.9), Vector3(0.7, 0.6, 0.6),
	]
	var casas: Array[Vector2i] = [
		Vector2i(1, 2), Vector2i(17, 3), Vector2i(3, 16), Vector2i(15, 17), Vector2i(6, 8), Vector2i(13, 10),
	]
	for i in tamanhos.size():
		var bm := BoxMesh.new()
		bm.size = tamanhos[i]
		var p := _casa(casas[i].x, casas[i].y) + Vector3(0, tamanhos[i].y * 0.5, 0)
		var mi := _malha(bm, pedra, p, "Rocha%d_PLACEHOLDER" % i)
		mi.rotation_degrees = Vector3(0, _rng.randf_range(0.0, 360.0), 0)


## Tochas 1,5–1,65 m, SEM sombra (B2.2).
func _criar_tochas() -> void:
	var madeira := _mat_toon("casca", Color("#5a4636"))
	for p in [_casa(2, 9), _casa(17, 10)]:
		var poste := CylinderMesh.new()
		poste.top_radius = 0.06
		poste.bottom_radius = 0.08
		poste.height = 1.6
		poste.radial_segments = 8
		_malha(poste, madeira, (p as Vector3) + Vector3(0, 0.8, 0), "Tocha_PLACEHOLDER")
		var luz := OmniLight3D.new()
		luz.position = (p as Vector3) + Vector3(0, 1.7, 0)
		luz.light_color = Color("#ffb066")
		luz.light_energy = 1.5
		luz.omni_range = 7.0
		luz.shadow_enabled = false
		add_child(luz)


## 4 figuras de 1,80 m ×1,25 e a criatura (Besta Cristalina > 2 m × 3–4 m), com contorno.
func _criar_figuras() -> void:
	var cores: Array[Color] = [Color("#9c3b33"), Color("#3f5f9a"), Color("#5f7f3a"), Color("#b08a3e")]
	var casas: Array[Vector2i] = [Vector2i(8, 12), Vector2i(10, 12), Vector2i(12, 13), Vector2i(9, 14)]
	var pele := _mat_toon("pele", Color("#c79273"))
	var metal := _mat_toon("metal", Color("#8d95a3"))
	metal.set_shader_parameter("metalico", 0.25)  # <= 0,3: acima disso o motor come a difusa (README)
	metal.set_shader_parameter("especular", 0.35)
	for i in cores.size():
		var cap := CapsuleMesh.new()
		cap.radius = 0.3 * ESCALA_FIGURA
		cap.height = 1.8 * ESCALA_FIGURA
		var mi := _malha(cap, _mat_figura("tecido", cores[i]), _casa(casas[i].x, casas[i].y) + Vector3(0, cap.height * 0.5, 0), "Figura%d_PLACEHOLDER" % i)
		mi.add_to_group(&"figura")
		_figuras.append(mi)
		# As duas famílias que faltavam à Clareira (Ordem 65): a cabeça é «pele» e a lâmina é
		# «metal». São filhas da figura (respiram com ela) e não levam contorno próprio.
		var cabeca := SphereMesh.new()
		cabeca.radius = 0.34 * ESCALA_FIGURA
		cabeca.height = 0.68 * ESCALA_FIGURA
		var mc := MeshInstance3D.new()
		mc.name = "Cabeca_PLACEHOLDER"
		mc.mesh = cabeca
		mc.material_override = pele
		mc.position = Vector3(0, cap.height * 0.5 - 0.12, 0)
		mi.add_child(mc)
		if i % 2 == 0:
			var lamina := BoxMesh.new()
			lamina.size = Vector3(0.09, 1.5, 0.22)
			var ml := MeshInstance3D.new()
			ml.name = "Lamina_PLACEHOLDER"
			ml.mesh = lamina
			ml.material_override = metal
			ml.position = Vector3(0.52, 0.15, 0.0)
			ml.rotation_degrees = Vector3(0, 0, -14)
			mi.add_child(ml)
	var corpo := BoxMesh.new()
	corpo.size = Vector3(2.0, 2.2, 3.6)
	var besta := _malha(corpo, _mat_figura("pedra", Color("#5e7fa8")), _casa(10, 6) + Vector3(0, 1.1, 0), "Besta_PLACEHOLDER")
	besta.add_to_group(&"figura")
	_figuras.append(besta)


# ------------------------------------------------------------------ medição

func _atualizar_rotulo() -> void:
	var chamadas := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var prims := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	_rotulo.text = "PLACEHOLDERS | %s | %d fps | %d chamadas | %d primitivas | %.1f h" % [
		perfil, Engine.get_frames_per_second(), chamadas, prims, hora]


## Mediana e p5 de FPS na janela (depois do aquecimento), em JSON numa linha.
func _imprimir_medicao() -> void:
	if _tempos.is_empty():
		print("[clareira] ainda no aquecimento (%.0f s)" % AQUECIMENTO_S)
		return
	var ord := _tempos.duplicate()
	ord.sort()
	var n := ord.size()
	var mediana_dt := ord[n / 2]
	var p95_dt := ord[mini(n - 1, int(n * 0.95))]
	var dados := {
		"cena": "clareira_prova_placeholders",
		"perfil": perfil,
		"hora": snappedf(hora, 0.1),
		"quadros": n,
		"fps_mediana": snappedf(1.0 / maxf(mediana_dt, 0.0001), 0.1),
		"fps_p5": snappedf(1.0 / maxf(p95_dt, 0.0001), 0.1),
		"chamadas": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitivas": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"gpu": RenderingServer.get_video_adapter_name(),
		"viewport": get_viewport().get_visible_rect().size,
		"escala_3d": get_viewport().scaling_3d_scale,
	}
	print("[clareira] ", JSON.stringify(dados))
