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
## (quadrado 0,94 da casa, cabb577 a 50%, contorno f5d59b); a grelha é a do site (c9c2a7). O GLB de cada
## figura entra pela V3.1 (Plano B), quando os pilotos do Plano C passarem a O8.1.
##
## ORDEM 45: o campo de batalha do Mestre é o MESMO mapa da floresta da arena do jogador (Ordem 42), montado
## pelo mesmo código (cenas/arena/campo_da_mesa.gd). A grelha fica no mesmo sítio do mapa
## (assentamento.gd `origem_no_mapa`), as linhas, os destaques, o fogo e o anel da vez colam-se ao relevo, o
## toque vai contra o relevo, e o pé de cada figura segue a regra da base inclinada da Ordem 44 (a mesma
## `Assentamento.pegada`: a altura é o `peM` do servidor). O céu e o sol são os do mapa, os mesmos da arena do
## jogador (um só céu). Só apresentação, como antes.

signal casa_tocada(casa: Vector2i)

const CameraMesa := preload("res://camera/camera_mesa.gd")
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")
const Marcador := preload("res://cenas/comum/marcador_figura.gd")
## Decisão 10 do Mestre (ordem 6; site REF_29): a câmara livre só existe aqui, na arena do Mestre.
const CamaraLivre := preload("res://cenas/mestre/camara_livre.gd")
## Ordem 15 (parte F): os nomes das figuras juntas não se sobrepõem no ecrã.
const NomesSemSobrepor := preload("res://cenas/comum/nomes_sem_sobrepor.gd")
## Ordem 40: o clima (chuva e neve) é um módulo de apresentação; a arena só o liga. Nunca calcula regra.
const Clima := preload("res://arte/clima/clima.gd")
## Ordem 45: o mesmo mapa, a mesma regra do assentamento e o mesmo código de montagem da arena do jogador.
const CampoDaMesa := preload("res://cenas/arena/campo_da_mesa.gd")
const Assentamento := preload("res://cenas/arena/assentamento.gd")
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const SH_SOBRE := preload("res://cenas/arena/sobre_relevo.gdshader")

# Do site (cena.js): grelha c9c2a7, casas do «mover» cab577 a 50% com contorno f5d59b, anel de destino ffd28b
# (raio 0,65). O fundo, o céu e o sol já não são os do site: são os do mapa (Ordem 45, um só céu).
const COR_LINHAS := Color(0.788, 0.761, 0.655, 0.5)  # c9c2a7
const COR_DESTAQUE := Color(0.792, 0.710, 0.467, 0.5)  # cab577 a 50%
const COR_CONTORNO_DESTAQUE := Color("f5d59b")
const COR_ANEL := Color("ffd28b")
## Ordem 13: casa a arder (o fogo do ambiente; as casas vêm do servidor, na vista do Mestre).
const COR_FOGO := Color(1.0, 0.45, 0.10, 0.55)
## Os metros acima do relevo de cada camada colada ao chão (como na arena do jogador: 3–5 cm; o shader
## `sobre_relevo` resolve o resto, por cima da relva pisada).
const LEVANTA_LINHAS := 0.03
const LEVANTA_FOGO := 0.035
const LEVANTA_DESTAQUE := 0.04
const LEVANTA_CONTORNO := 0.045
## Raio (m) do cilindro câmara → foco onde as copas e os marcos do mapa somem (o da arena do jogador).
const RAIO_RECORTE_M := 5.0

var largura := 0
var altura := 0
var casa_m := 1.5
## Ordem 45: canto noroeste da casa (0, 0) no mundo (x, z), como na arena do jogador.
var origem := Vector2(-15.0, -15.0)
## O mapa da floresta (o campo de batalha), filho desta arena.
var mapa: Node3D
var camera: CameraMesa
var camara_livre: CamaraLivre
var clima: Clima

var _ambiente: WorldEnvironment
var _sol: DirectionalLight3D
var _grelha: Node3D
var _figuras: Node3D
var _destaques: MeshInstance3D
var _fogo: MeshInstance3D
var _casas_fogo: Array[Vector2i] = []
var _contornos: MeshInstance3D
var _anel: MeshInstance3D
var _nos: Dictionary = {}  # figuraId -> Node3D
var _entradas := 0  # ordem de entrada das figuras: a cor do anel (cena.js `units.size % 5`)
var _casas_destacadas: Array[Vector2i] = []


func _ready() -> void:
	# Ordem 45: o Ambiente e o Sol são os do mapa (o mapa monta neles o céu pintado, a névoa e a luz),
	# como na arena do jogador. Os valores aqui são só o arranque, antes de o mapa os escrever.
	_ambiente = WorldEnvironment.new()
	_ambiente.name = "Ambiente"
	_ambiente.add_to_group(&"ambiente")
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.52, 0.66, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.88, 0.92)
	env.ambient_light_energy = 0.55
	_ambiente.environment = env
	add_child(_ambiente)
	_sol = DirectionalLight3D.new()
	_sol.name = "Sol"
	_sol.add_to_group(&"sol")
	_sol.shadow_enabled = true
	add_child(_sol)
	camera = CameraMesa.new()
	camera.name = "Camera"
	add_child(camera)
	camera.current = true
	camera.altura_em = altura_chao
	camera.toque.connect(_ao_toque)
	camara_livre = CamaraLivre.new()
	camara_livre.altura_em = altura_chao
	add_child(camara_livre)
	_grelha = Node3D.new()
	_grelha.name = "Grelha"
	add_child(_grelha)
	_figuras = Node3D.new()
	_figuras.name = "Figuras"
	add_child(_figuras)
	_fogo = _nova_camada("Fogo", 1)
	_destaques = _nova_camada("Destaques", 2)
	_contornos = MeshInstance3D.new()
	_contornos.name = "ContornosDestaques"
	_contornos.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_contornos.material_override = _material_sobre(COR_CONTORNO_DESTAQUE, false, 3)
	add_child(_contornos)
	_anel = MeshInstance3D.new()
	_anel.name = "AnelDaVez"
	_anel.mesh = Marcador.anel_plano(0.65, COR_ANEL)  # o anel de destino do site (0,65, ffd28b)
	_anel.material_override = _material_sobre(COR_ANEL, false, 4)
	_anel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_anel.visible = false
	add_child(_anel)
	clima = Clima.new()
	clima.name = "Clima"
	add_child(clima)
	construir_grelha(20, 20, 1.5)


## Ordem 15 (parte F): a cada quadro, os nomes arrumam-se para a câmara activa (a da mesa ou a livre).
func _process(_delta: float) -> void:
	# Ordem 45 (como a arena do jogador, Ordem 42): o que fica entre a câmara da mesa e o foco (copas, marcos)
	# não tapa o jogo; na câmara livre não se recorta nada.
	if mapa != null and is_instance_valid(mapa):
		var raio := RAIO_RECORTE_M if camera.is_processing() else 0.0
		mapa.definir_recorte_vista(camera.foco_atual() + Vector3(0.0, 1.0, 0.0), raio)
	arrumar_nomes()


## Arruma os nomes das figuras no ecrã (sobe os de trás que tocavam noutro). Devolve as caixas no ecrã.
func arrumar_nomes() -> Array[Rect2]:
	var rotulos: Array = []
	for no in _nos.values():
		if is_instance_valid(no) and (no as Node).has_node("Rotulo"):
			rotulos.append((no as Node).get_node("Rotulo"))
	return NomesSemSobrepor.arrumar(rotulos, get_viewport().get_camera_3d() if is_inside_tree() else null)


func construir_grelha(w: int, h: int, c: float) -> void:
	if w == largura and h == altura and is_equal_approx(c, casa_m) and _grelha.get_child_count() > 0:
		return
	largura = maxi(1, w)
	altura = maxi(1, h)
	casa_m = c if c > 0.0 else 1.5
	for n in _grelha.get_children():
		_grelha.remove_child(n)  # sai já: o «Linhas» novo fica com o nome dele
		n.queue_free()
	var tam := Vector2(largura * casa_m, altura * casa_m)
	origem = Assentamento.origem_no_mapa(tam, casa_m)
	var zona := Rect2(origem, tam)
	_garantir_mapa(zona)
	# Sem chão próprio: o chão é o do mapa. As linhas seguem o relevo (amostra a cada 1/4 de casa).
	var linhas := MeshInstance3D.new()
	linhas.name = "Linhas"
	linhas.mesh = CampoDaMesa.linhas_grelha(origem, casa_m, largura, altura, _material_sobre(COR_LINHAS, false, 0), LEVANTA_LINHAS)
	linhas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_grelha.add_child(linhas)
	var meio := origem + tam * 0.5
	var centro := Vector3(meio.x, altura_chao(meio.x, meio.y), meio.y)
	camera.configurar_arena(centro, tam)
	clima.configurar_area(centro, tam)
	clima.definir_grelha(Vector3(origem.x, centro.y, origem.y), casa_m)
	# Os destaques e o fogo da grelha velha voltam a assentar na nova (as figuras, na vista que se segue).
	destacar(_casas_destacadas.filter(func(k): return dentro(k)))
	_desenhar_casas_fogo()


## O mapa é construído para a zona jogável; se a grelha mudar de tamanho, o mapa refaz-se para a zona nova.
func _garantir_mapa(zona: Rect2) -> void:
	if mapa != null and is_instance_valid(mapa) and mapa.zona_jogo.is_equal_approx(zona):
		return
	if mapa != null and is_instance_valid(mapa):
		remove_child(mapa)
		mapa.free()
	mapa = CampoDaMesa.montar_mapa(self, zona, ^"../Ambiente", ^"../Sol", ^"../Camera")


## A altura do chão do mapa em (x, z) do mundo: a altura final única (malha = colisão = consulta).
func altura_chao(x: float, z: float) -> float:
	return Relevo.altura(x, z)


## Desenha a vista do Mestre: a grelha do mapa e as figuras colocadas.
func aplicar_vista(vista: Dictionary) -> void:
	var m = vista.get("mapa")
	if m is Dictionary:
		construir_grelha(int(m.get("largura", 20)), int(m.get("altura", 20)), float(m.get("casaM", 1.5)))
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
		var c := Vector2i(int(f.get("x", 0)), int(f.get("y", 0)))
		no.position = pe_figura(c)
		(no.get_node("Rotulo") as Label3D).text = Modelo.nome_mestre(f)
		# Morta: deitada como no site. Caída (viva): também deitada, para o Mestre a ver no chão.
		var deitada: bool = f.get("caido") == true or f.get("vivo") == false
		var marcador := no.get_node("Marcador") as Node3D
		_repor_prumo(marcador)
		Marcador.deitar(marcador, deitada)
		_assentar(marcador, c, deitada)
	for id in _nos.keys():
		if not vistos.has(id):
			(_nos[id] as Node).queue_free()
			_nos.erase(id)
	desenhar_fogo(vista)
	var vez := str(vista.get("vezId", "")) if vista.get("vezId") is String else ""
	_anel.visible = _nos.has(vez)
	if _anel.visible:
		var cv := casa_de_ponto((_nos[vez] as Node3D).position)
		var pg := pegada_figura(cv)
		_anel.transform = Transform3D(_inclinacao(pg), (_nos[vez] as Node3D).position + (pg["normal"] as Vector3) * 0.045)


# ---------------------------------------------------------------- o pé das figuras (Ordem 44, parte B)

## Onde pousa o pé de uma figura na casa: no centro, à altura da BASE INCLINADA com a encosta (assentamento.gd
## `pegada`, com o raio da pegada da arena do jogador: a altura é o `peM` que o servidor tem para a casa).
func pe_figura(c: Vector2i) -> Vector3:
	var p := centro_da_casa(c)
	return Vector3(p.x, float(pegada_figura(c)["y"]), p.z)


## A base de uma figura na casa `c`: {y, gradiente, normal, enterra, flutua} (assentamento.gd `pegada`).
func pegada_figura(c: Vector2i) -> Dictionary:
	var p := centro_da_casa(c)
	return Assentamento.pegada(p.x, p.z, Assentamento.raio_pegada(casa_m))


## A regra da base inclinada no marcador do site. A raiz do marcador deita-se no plano da base: o anel e a
## sombra de contacto (filhos dela) ficam no plano da encosta, à folga do site (0,035 e 0,018 m). O corpo de
## pé fica a prumo: o pivô desfaz a inclinação e segue o plano por baixo com um cisalhamento vertical (cada
## ponto do corpo sobe o que o plano sobe debaixo dele) — o fundo plano do cilindro do site assenta inteiro
## no plano, sem flutuar nem atravessar, e o eixo continua vertical. A cabeça desfaz o cisalhamento (fica
## redonda, no mesmo sítio). A cápsula da arena do jogador tem o fundo redondo e por isso sobe
## `subida_do_corpo`; um fundo plano rígido e a prumo não pode tocar um plano inclinado sem flutuar de um lado.
## O corpo caído deita-se no plano da base (Marcador.deitar no espaço da raiz inclinada). Num chão plano é
## tudo a identidade: o marcador fica como o site o desenha.
func _assentar(marcador: Node3D, c: Vector2i, deitada: bool) -> void:
	var pg := pegada_figura(c)
	var inclina := _inclinacao(pg)
	marcador.transform = Transform3D(inclina, Vector3.ZERO)
	if deitada:
		return
	var s := _cisalha(pg["gradiente"])
	var pivo := marcador.get_node("Pivo") as Node3D
	pivo.transform = Transform3D(inclina.inverse() * s, Vector3.ZERO)
	var cabeca := pivo.get_node_or_null("Cabeca") as Node3D
	if cabeca != null:
		cabeca.transform = Transform3D(s.inverse(), cabeca.position)


## Antes de deitar ou de assentar outra vez: o pivô e a cabeça como o site os cria (sem inclinação).
func _repor_prumo(marcador: Node3D) -> void:
	var pivo := marcador.get_node("Pivo") as Node3D
	pivo.transform = Transform3D.IDENTITY
	var cabeca := pivo.get_node_or_null("Cabeca") as Node3D
	if cabeca != null:
		cabeca.transform = Transform3D(Basis.IDENTITY, cabeca.position)


## A rotação que leva o «para cima» à normal do plano da base (identidade num chão plano).
func _inclinacao(pg: Dictionary) -> Basis:
	return Basis(Quaternion(Vector3.UP, (pg["normal"] as Vector3).normalized()))


## O cisalhamento vertical do plano y = gx·x + gz·z: (x, y, z) → (x, y + gx·x + gz·z, z).
static func _cisalha(g: Vector2) -> Basis:
	return Basis(Vector3(1.0, g.x, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, g.y, 1.0))


# ---------------------------------------------------------------- câmara livre (decisão 10; site REF_29)

## Entra na câmara livre. A câmara da mesa fica congelada (sem processo nem gestos): sair é exacto.
func entrar_camara_livre() -> void:
	if camara_livre.ativa:
		return
	camera.set_process(false)
	camera.set_process_unhandled_input(false)
	var tam := Vector2(largura * casa_m, altura * casa_m)
	var meio := origem + tam * 0.5
	camara_livre.entrar(Vector3(meio.x, altura_chao(meio.x, meio.y), meio.y), tam)


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


## Centro da casa, em cima do chão do mapa (a altura do relevo nesse ponto), como na arena do jogador.
func centro_da_casa(c: Vector2i) -> Vector3:
	return Assentamento.centro_casa(origem, casa_m, c)


func casa_de_ponto(p: Vector3) -> Vector2i:
	return Vector2i(floori((p.x - origem.x) / casa_m), floori((p.z - origem.y) / casa_m))


func dentro(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < largura and c.y < altura


## Destaca as casas que o servidor mandou (o cliente não as escolhe): remendos no relevo (0,94 da casa, cab577 a
## 50%) e o contorno de cada casa (f5d59b) amostrado no relevo.
func destacar(casas: Array) -> void:
	var lista: Array[Vector2i] = []
	for c in casas:
		lista.append(c)
	_casas_destacadas = lista
	if lista.is_empty():
		_destaques.mesh = null
		_contornos.mesh = null
		return
	var remendos: Array = []
	for c in lista:
		remendos.append([c, COR_DESTAQUE])
	_destaques.mesh = CampoDaMesa.malha_casas(origem, casa_m, remendos, 0.94, LEVANTA_DESTAQUE)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var m := casa_m * 0.47
	var n := CampoDaMesa.DIVISOES_CASA
	for c in lista:
		var o := centro_da_casa(c)
		var cantos := [Vector2(o.x - m, o.z - m), Vector2(o.x + m, o.z - m), Vector2(o.x + m, o.z + m), Vector2(o.x - m, o.z + m)]
		for k in 4:
			var a: Vector2 = cantos[k]
			var b: Vector2 = cantos[(k + 1) % 4]
			for i in n:
				var p0 := a.lerp(b, float(i) / n)
				var p1 := a.lerp(b, float(i + 1) / n)
				im.surface_add_vertex(CampoDaMesa.no_chao(p0.x, p0.y, LEVANTA_CONTORNO))
				im.surface_add_vertex(CampoDaMesa.no_chao(p1.x, p1.y, LEVANTA_CONTORNO))
	im.surface_end()
	_contornos.mesh = im


func casas_destacadas() -> Array[Vector2i]:
	return _casas_destacadas


## Ordem 13: as casas a arder da vista (o combustível de cada uma está na aba Ambiente).
func desenhar_fogo(vista: Dictionary) -> void:
	_casas_fogo.clear()
	var m = vista.get("mestre")
	var fogo = m.get("fogo") if m is Dictionary else null
	if fogo is Dictionary and fogo.get("casas") is Array:
		for k in fogo["casas"]:
			if k is Dictionary:
				var c := Vector2i(int(k.get("x", -1)), int(k.get("y", -1)))
				if dentro(c):
					_casas_fogo.append(c)
	_desenhar_casas_fogo()


func _desenhar_casas_fogo() -> void:
	var lista: Array = []
	for c in _casas_fogo:
		if dentro(c):
			lista.append([c, COR_FOGO])
	_fogo.mesh = CampoDaMesa.malha_casas(origem, casa_m, lista, 0.96, LEVANTA_FOGO)


func casas_a_arder() -> Array[Vector2i]:
	return _casas_fogo


## O toque: o raio da câmara contra o relevo do mapa (como na arena do jogador).
func casa_em_tela(posicao: Vector2) -> Vector2i:
	var hit = CampoDaMesa.ponto_no_chao(camera.project_ray_origin(posicao), camera.project_ray_normal(posicao))
	if hit == null:
		return Vector2i(-1, -1)
	var c := casa_de_ponto(hit)
	return c if dentro(c) else Vector2i(-1, -1)


func _ao_toque(posicao: Vector2) -> void:
	var c := casa_em_tela(posicao)
	if dentro(c):
		casa_tocada.emit(c)


func _nova_figura(f: Dictionary) -> Node3D:
	var no := Node3D.new()
	no.name = "Figura_" + str(f.get("id", ""))
	var altura_m := float(f.get("alturaM")) if (f.get("alturaM") is float or f.get("alturaM") is int) else 0.0
	var forma := str(f.get("marcador")) if f.get("marcador") is String else "marcador"
	var marcador: Node3D = Marcador.criar(altura_m, forma, _entradas)
	marcador.add_to_group(Clima.GRUPO_FIGURA)  # ordem 40: a figura responde ao clima (molhada, neve em cima)
	_entradas += 1
	_por_cima_da_relva(marcador.get_node("Anel") as MeshInstance3D, 4)
	_por_cima_da_relva(marcador.get_node("Contacto") as MeshInstance3D, 3)
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


## Ordem 45: o anel e a sombra de contacto do site ficam a 0,035 e 0,018 m do chão — debaixo da relva pisada do
## mapa (0,18–0,33 m). Desenham-se com o shader `sobre_relevo` (o das linhas e destaques: puxado para a câmara,
## por cima da relva), com a cor do site. A malha e o material do site ficam como são (o material de cima é
## transparente e sem luz, por isso o clima continua a deixá-los de fora, como os deixava).
func _por_cima_da_relva(mi: MeshInstance3D, prioridade: int) -> void:
	var original := mi.mesh.surface_get_material(0) as StandardMaterial3D
	var cor := original.albedo_color if original != null else Color.WHITE
	var vazio := StandardMaterial3D.new()
	vazio.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	vazio.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vazio.albedo_color = Color(cor, 0.0)
	vazio.next_pass = _material_sobre(cor, false, prioridade)
	mi.material_override = vazio
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _nova_camada(nome: String, prioridade: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = _material_sobre(Color.WHITE, true, prioridade)
	add_child(mi)
	return mi


func _material_sobre(cor: Color, da_instancia: bool, prioridade: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_SOBRE
	m.set_shader_parameter("cor", cor)
	m.set_shader_parameter("cor_da_instancia", da_instancia)
	m.render_priority = prioridade
	return m
