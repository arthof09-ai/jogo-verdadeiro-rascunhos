extends Node3D
## Arena da mesa (JV2.1a / JV2.2).
##
## - Grelha parametrizável: 20×20 casas de 1,5 m por padrão; o ROOM_SNAPSHOT.mapa manda.
## - Desenha as figuras que o servidor projetou (marcadores provisórios; o visual é do Plano B).
## - Destaca SÓ as casas que vieram em ROOM_OPTIONS.mover, e os alvos de ROOM_OPTIONS.ataques.
## - Toque ou clique numa casa destacada → ROOM_INTENT. Setas do teclado só no modo Mover.
## - O cliente NUNCA calcula regra: não decide casas, custos nem alvos; só mostra e envia.
## - Chega-se aqui pelo lobby (cenas/lobby) quando a fase passa a "combate"; se o lugar
##   se perder (token inválido, outro aparelho, "Sair da mesa"), volta-se ao lobby.
## - ORDEM 42: o campo de batalha é o MAPA DA FLORESTA (mapa/floresta/campo_floresta.gd). A grelha do
##   snapshot assenta no centro da arena do mapa, alinhada às linhas de 1,5 m dele; cada casa, cada
##   destaque e cada figura fica à altura do relevo (Relevo.altura: a mesma altura que a malha do
##   chão desenha). O fundo, o céu, a névoa e o sol são os do mapa — um só, no Ambiente e no Sol
##   desta cena. Só apresentação: as casas, os custos e os alvos continuam a vir do servidor.

enum Modo { NENHUM, MOVER, ATAQUE, CONSUMIVEL }

const CENA_LOBBY := "res://cenas/lobby/lobby.tscn"
## `orientacao` do servidor é uma letra (sala.js: 'S' por omissão; MASTER_PLACE aceita até 8 letras).
## Rumo em graus à volta do Y; a frente do Node3D é -Z e a casa y cresce para +Z (sul).
## PROVISÓRIO: o conjunto exato de letras não está na especificação; aceitam-se N/S/L/O e E/W.
const RUMO_ORIENTACAO := {"N": 0.0, "S": 180.0, "L": -90.0, "E": -90.0, "O": 90.0, "W": 90.0}

@export var largura_padrao: int = 20
@export var altura_padrao: int = 20
@export var casa_m_padrao: float = 1.5

const COR_CHAO := Color(0.30, 0.42, 0.26)
const COR_LINHAS := Color(0.0, 0.0, 0.0, 0.35)
const COR_MOVER := Color(0.30, 0.75, 1.0, 0.45)
const COR_ALVO := Color(1.0, 0.30, 0.25, 0.50)
const COR_CURSOR := Color(1.0, 0.90, 0.30, 0.65)
const COR_PROPRIA := Color(0.35, 0.60, 1.0)
const COR_JOGADORA := Color(0.40, 0.85, 0.50)
const COR_CRIATURA := Color(0.85, 0.35, 0.30)
const COR_MORTA := Color(0.35, 0.35, 0.35)
## Ordem 13: casa a arder (o fogo do ambiente; as casas vêm do servidor, em Estado.fogo).
const COR_FOGO := Color(1.0, 0.45, 0.10, 0.55)

const CameraMesa := preload("res://camera/camera_mesa.gd")
## Ordem 42: o mapa da floresta e a sua altura única.
const CampoFloresta := preload("res://mapa/floresta/campo_floresta.gd")
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const GrelhaMapa := preload("res://mapa/floresta/grelha_floresta.gd")
const SH_SOBRE := preload("res://cenas/arena/sobre_relevo.gdshader")
## Quantos metros acima do chão vai o que se cola ao relevo (o resto resolve-o o shader).
const LEVANTA_M := 0.03
## Divisões por lado de cada remendo de casa (os vértices seguem o relevo).
const DIVISOES_CASA := 4
## Raio (m) do cilindro câmara → foco onde as copas e os marcos do mapa somem (não tapam o jogo).
const RAIO_RECORTE_M := 5.0
## Ordem 15 (parte F): os nomes das figuras juntas não se sobrepõem no ecrã.
const NomesSemSobrepor := preload("res://cenas/comum/nomes_sem_sobrepor.gd")
## Ordem 40: o clima (chuva e neve) é um módulo de apresentação; a arena só o liga. Nunca calcula regra.
const Clima := preload("res://arte/clima/clima.gd")

@onready var camera: CameraMesa = $Camera
@onready var hud = $HUD  # hud.gd (sem tipo para não criar preload circular)
@onready var _sol: DirectionalLight3D = $Sol
@onready var _grelha: Node3D = $Grelha
@onready var _figuras: Node3D = $Figuras
## Uma só tabela de perfis gráficos: a do AplicadorPerfil (arte/perfis/aplicar_perfil.gd). I0004, 08/11.
@onready var _perfis: AplicadorPerfil = $Perfis

var largura := 20
var altura := 20
var casa_m := 1.5
## Ordem 42: canto noroeste da casa (0, 0) no mundo (x, z). A grelha fica centrada no mapa.
var origem := Vector2(-15.0, -15.0)
## O mapa da floresta (o campo de batalha), filho desta cena.
var mapa: Node3D
var modo: int = Modo.NENHUM

var _item: Dictionary = {}
var _casas: Dictionary = {}  # Vector2i -> custoM (como veio do servidor)
var _alvos: Dictionary = {}  # figuraId -> Array de opções de ataque, ou true
var _cursor := Vector2i(-1, -1)
var _destaques: MeshInstance3D
var _fogo: MeshInstance3D
var _marcador: MeshInstance3D
var _mat_destaque: ShaderMaterial
var _rotulo_custo: Label3D
var _nos: Dictionary = {}  # figuraId -> Node3D
var _focou := false
var _saindo := false
var _mover_depois: Dictionary = {}  # o movimento que segue o «Sair c/ segurança» aceite
var _id_seguranca := ""  # o intentId do Desvincular desse movimento (ordem 33: só o recibo DELE o solta)
var _ultimo_id := ""  # o intentId da última intenção que saiu
var clima: Clima  # ordem 40


## Ordem 15 (parte F): a cada quadro, os nomes arrumam-se para a câmara.
func _process(_delta: float) -> void:
	# Ordem 42: o que fica entre a câmara da mesa e o foco (copas, marcos) não tapa o jogo.
	if mapa != null and is_instance_valid(mapa):
		var raio := RAIO_RECORTE_M if camera.is_processing() else 0.0
		mapa.definir_recorte_vista(camera.foco_atual() + Vector3(0.0, 1.0, 0.0), raio)
	var rotulos: Array = []
	for no in _nos.values():
		if is_instance_valid(no) and (no as Node).has_node("Nome"):
			rotulos.append((no as Node).get_node("Nome"))
	NomesSemSobrepor.arrumar(rotulos, camera)


func _ready() -> void:
	# Ordem 42: o Sol já não se roda aqui — a direcção é a da luz pintada do mapa (paleta).
	camera.altura_em = altura_chao
	_perfis.perfil_aplicado.connect(_ao_perfil_aplicado)
	clima = Clima.new()
	clima.name = "Clima"
	add_child(clima)
	_perfis.perfil_aplicado.connect(clima.definir_perfil)  # as contagens do clima seguem o perfil gráfico
	_construir_grelha(largura_padrao, altura_padrao, casa_m_padrao)
	camera.toque.connect(_ao_toque)
	Estado.snapshot_aplicado.connect(_ao_snapshot)
	Estado.evento_aplicado.connect(_ao_evento)
	Estado.opcoes_mudaram.connect(_ao_opcoes)
	hud.arena = self
	hud.modo_pedido.connect(definir_modo)
	hud.acao_pedida.connect(enviar_acao)
	hud.preferencia_mudou.connect(_ao_preferencia)
	hud.aplicar_preferencias_iniciais()
	Rede.precisa_entrar.connect(_ao_precisa_entrar)
	Rede.recibo_recebido.connect(_ao_recibo_seguranca)
	Rede.recusa_recebida.connect(_ao_recusa_seguranca)
	Rede.iniciar()  # não faz nada se o lobby já ligou
	# O snapshot pode ter chegado antes de a cena abrir (veio do lobby): desenha já.
	if Estado.tem_snapshot:
		_ao_snapshot()
	print("pronto")  # o CI (JV0.2) espera esta linha no console


func _ao_precisa_entrar(_motivo: String) -> void:
	if _saindo:
		return
	_saindo = true
	get_tree().change_scene_to_file.call_deferred(CENA_LOBBY)


# ---------------------------------------------------------------- grelha

func _construir_grelha(w: int, h: int, c: float) -> void:
	largura = maxi(1, w)
	altura = maxi(1, h)
	casa_m = c if c > 0.0 else 1.5
	for n in _grelha.get_children():
		n.queue_free()
	var tam := Vector2(largura * casa_m, altura * casa_m)
	origem = _origem_no_mapa(tam)
	_garantir_mapa(Rect2(origem, tam))

	# Sem chão próprio: o chão é o do mapa (e é ele que responde ao clima: ver _garantir_mapa).
	# As linhas seguem o relevo (amostra a cada 1/4 de casa).
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _material_sobre(COR_LINHAS, false))
	var passos_x := largura * DIVISOES_CASA
	var passos_z := altura * DIVISOES_CASA
	for i in range(largura + 1):
		var x := origem.x + i * casa_m
		for k in passos_z:
			im.surface_add_vertex(_no_chao(x, origem.y + tam.y * k / passos_z, LEVANTA_M))
			im.surface_add_vertex(_no_chao(x, origem.y + tam.y * (k + 1) / passos_z, LEVANTA_M))
	for j in range(altura + 1):
		var z := origem.y + j * casa_m
		for k in passos_x:
			im.surface_add_vertex(_no_chao(origem.x + tam.x * k / passos_x, z, LEVANTA_M))
			im.surface_add_vertex(_no_chao(origem.x + tam.x * (k + 1) / passos_x, z, LEVANTA_M))
	im.surface_end()
	var linhas := MeshInstance3D.new()
	linhas.name = "Linhas"
	linhas.mesh = im
	linhas.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_grelha.add_child(linhas)

	_mat_destaque = _material_sobre(Color.WHITE, true)
	# Ordem 13: as casas a arder, por baixo dos destaques.
	_fogo = _nova_camada("Fogo", 1)
	_destaques = _nova_camada("Destaques", 2)
	_marcador = _nova_camada("Cursor", 3)
	_marcador.visible = false

	_rotulo_custo = Label3D.new()
	_rotulo_custo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_rotulo_custo.no_depth_test = true
	_rotulo_custo.font_size = 64
	_rotulo_custo.outline_size = 16
	_rotulo_custo.pixel_size = 0.006
	_rotulo_custo.visible = false
	_grelha.add_child(_rotulo_custo)

	var meio := origem + tam * 0.5
	var centro := Vector3(meio.x, altura_chao(meio.x, meio.y), meio.y)
	camera.configurar_arena(centro, tam)
	clima.configurar_area(centro, tam)
	clima.definir_grelha(Vector3(origem.x, centro.y, origem.y), casa_m)
	_mostrar_destaques()
	mostrar_fogo()


## Ordem 42: onde fica a grelha no mapa. Centrada no centro da arena do mapa (0, 0) e, se as casas
## forem de 1,5 m, encostada às linhas da grelha do mapa (−37,5 + k × 1,5): cada casa do jogo é
## uma casa do mapa (20 × 20 → casas 15–34 do mapa).
func _origem_no_mapa(tam: Vector2) -> Vector2:
	var o := -tam * 0.5
	if is_equal_approx(casa_m, GrelhaMapa.CASA_M):
		o.x = -GrelhaMapa.MEIO + roundf((o.x + GrelhaMapa.MEIO) / GrelhaMapa.CASA_M) * GrelhaMapa.CASA_M
		o.y = -GrelhaMapa.MEIO + roundf((o.y + GrelhaMapa.MEIO) / GrelhaMapa.CASA_M) * GrelhaMapa.CASA_M
	return o


## O mapa é construído para a zona jogável (lá dentro não põe nada que ocupe uma casa sem o servidor
## saber). Se o snapshot mudar o tamanho da grelha, o mapa refaz-se para a zona nova.
func _garantir_mapa(zona: Rect2) -> void:
	if mapa != null and is_instance_valid(mapa) and mapa.zona_jogo.is_equal_approx(zona):
		return
	if mapa != null and is_instance_valid(mapa):
		remove_child(mapa)
		mapa.free()
	mapa = CampoFloresta.new()
	mapa.name = "Mapa"
	mapa.no_ambiente = ^"../Ambiente"
	mapa.no_sol = ^"../Sol"
	mapa.no_camera = ^"../Camera"
	mapa.vistas_por_tecla = false
	mapa.mostrar_medicao = false
	mapa.zona_jogo = zona
	add_child(mapa)
	move_child(mapa, 0)
	# Ordem 42 + clima (Ordens 40/41): o chão que molha e branqueia é o do mapa (a zona fina e a larga).
	for caminho in [^"Arena/Terreno", ^"Fundo/TerrenoLargo"]:
		var chao := mapa.get_node_or_null(caminho)
		if chao != null:
			chao.add_to_group(Clima.GRUPO_CHAO)
	if _perfis.atual != "":
		_ao_perfil_aplicado(_perfis.atual)


## A altura do chão do mapa em (x, z) do mundo: a altura final única (malha = colisão = consulta).
func altura_chao(x: float, z: float) -> float:
	return Relevo.altura(x, z)


func _no_chao(x: float, z: float, levanta: float) -> Vector3:
	return Vector3(x, Relevo.altura(x, z) + levanta, z)


func _material_sobre(cor: Color, da_instancia: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SH_SOBRE
	m.set_shader_parameter("cor", cor)
	m.set_shader_parameter("cor_da_instancia", da_instancia)
	return m


func _nova_camada(nome: String, prioridade: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nome
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := _mat_destaque.duplicate() as ShaderMaterial
	m.render_priority = prioridade
	mi.material_override = m
	_grelha.add_child(mi)
	return mi


## Uma malha com um remendo por casa: (DIVISOES_CASA + 1)² vértices por casa, cada um à altura do
## relevo + `levanta`. `casas` = [[Vector2i, Color], ...]; `escala` = fracção da casa coberta.
func _malha_casas(casas: Array, escala: float, levanta: float) -> ArrayMesh:
	if casas.is_empty():
		return null
	var n := DIVISOES_CASA
	var v := PackedVector3Array()
	var cores := PackedColorArray()
	var idx := PackedInt32Array()
	var lado := casa_m * escala
	for e: Array in casas:
		var c: Vector2i = e[0]
		var cor: Color = e[1]
		var x0 := origem.x + (c.x + 0.5) * casa_m - lado * 0.5
		var z0 := origem.y + (c.y + 0.5) * casa_m - lado * 0.5
		var base := v.size()
		for j in n + 1:
			for i in n + 1:
				v.append(_no_chao(x0 + lado * i / n, z0 + lado * j / n, levanta))
				cores.append(cor)
		for j in n:
			for i in n:
				var a := base + j * (n + 1) + i
				idx.append_array([a, a + 1, a + n + 1, a + 1, a + n + 2, a + n + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_COLOR] = cores
	arr[Mesh.ARRAY_INDEX] = idx
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return malha


func dentro(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < largura and c.y < altura


## Centro da casa, em cima do chão do mapa (a altura do relevo nesse ponto).
func centro_casa(c: Vector2i) -> Vector3:
	var x := origem.x + (c.x + 0.5) * casa_m
	var z := origem.y + (c.y + 0.5) * casa_m
	return Vector3(x, Relevo.altura(x, z), z)


## Ordem 42: onde pousa o pé de uma figura na casa: no centro, à altura MAIS BAIXA do relevo debaixo da
## pegada (o centro e 8 pontos no raio da base). Numa encosta nenhum lado da base fica no ar; o lado
## de cima entra uns centímetros no chão (a relva tapa-o).
func pe_figura(c: Vector2i) -> Vector3:
	var p := centro_casa(c)
	var r := casa_m * 0.28
	var y := p.y
	for k in 8:
		var a := TAU * k / 8.0
		y = minf(y, Relevo.altura(p.x + cos(a) * r, p.z + sin(a) * r))
	return Vector3(p.x, y, p.z)


## Casa sob um ponto da tela, ou (-1,-1). É só geometria de ecrã → chão (o relevo do mapa): o raio
## desce até ao primeiro ponto abaixo do chão e afina-se por bisseção.
func casa_em_tela(p: Vector2) -> Vector2i:
	var hit = ponto_no_chao(camera.project_ray_origin(p), camera.project_ray_normal(p))
	if hit == null:
		return Vector2i(-1, -1)
	var c := Vector2i(floori((hit.x - origem.x) / casa_m), floori((hit.z - origem.y) / casa_m))
	return c if dentro(c) else Vector2i(-1, -1)


## O primeiro ponto onde o raio (o, d) toca o chão do mapa, ou null.
func ponto_no_chao(o: Vector3, d: Vector3):
	if d.y > -0.0005:
		return null
	# começa onde o raio desce abaixo dos 12 m (o relevo da arena do mapa fica muito abaixo disso)
	var t := maxf((o.y - 12.0) / -d.y, 0.0)
	var passo := 0.25
	var antes := t
	for i in 4000:
		var q := o + d * t
		if q.y <= Relevo.altura(q.x, q.z):
			var a := antes
			var b := t
			for k in 14:
				var m := (a + b) * 0.5
				var qm := o + d * m
				if qm.y <= Relevo.altura(qm.x, qm.z):
					b = m
				else:
					a = m
			return o + d * b
		if q.y < -40.0:
			return null
		antes = t
		t += passo
	return null


## Posição na tela da cabeça de uma figura (para os números de dano), ou null.
func posicao_tela(figura_id: String):
	var no = _nos.get(figura_id)
	if no == null:
		return null
	var p: Vector3 = no.global_position + Vector3(0.0, 2.0, 0.0)
	if camera.is_position_behind(p):
		return null
	return camera.unproject_position(p)


# ---------------------------------------------------------------- modos e intenções

func definir_modo(m: int, extra: Dictionary = {}) -> void:
	modo = m
	_item = extra
	_casas.clear()
	_alvos.clear()
	if m == Modo.CONSUMIVEL:
		var alvos = extra.get("alvos")
		var lista: Array = alvos if alvos is Array else []
		if lista.is_empty():
			enviar_acao({"tipo": "consumivel", "itemId": extra.get("itemId")})
			return
		if lista.size() == 1:
			enviar_acao({"tipo": "consumivel", "itemId": extra.get("itemId"), "alvoId": _id_de(lista[0])})
			return
		for a in lista:
			_alvos[_id_de(a)] = true
	else:
		_preencher_do_servidor()
	if modo == Modo.MOVER:
		var minha: Vector2i = Estado.casa_de(Estado.figuras.get(Estado.minha_figura_id))
		_cursor = minha if dentro(minha) else Vector2i(_casas.keys()[0])
	_mostrar_destaques()
	_atualizar_cursor()
	hud.ao_modo_mudou(modo)


## Lê ROOM_OPTIONS (só se vale para a revisão corrente). Sem opções → sai do modo.
func _preencher_do_servidor() -> void:
	match modo:
		Modo.MOVER:
			for o in Estado.lista_opcao("mover"):
				if o is Dictionary and o.get("x") != null and o.get("y") != null:
					_casas[Vector2i(int(o["x"]), int(o["y"]))] = o.get("custoM")
			if _casas.is_empty():
				modo = Modo.NENHUM
		Modo.ATAQUE:
			for o in Estado.lista_opcao("ataques"):
				if o is Dictionary:
					var fid := _id_de(o.get("alvoId"))
					if fid == "":
						continue
					if not _alvos.has(fid):
						_alvos[fid] = []
					_alvos[fid].append(o)
			if _alvos.is_empty():
				modo = Modo.NENHUM
		_:
			modo = Modo.NENHUM


func enviar_acao(acao: Dictionary) -> bool:
	var id: String = Rede.enviar_intencao(acao, Estado.revisao)
	if id == "":
		return false
	_ultimo_id = id
	modo = Modo.NENHUM
	_casas.clear()
	_alvos.clear()
	_mostrar_destaques()
	_atualizar_cursor()
	hud.fechar_gaveta()
	hud.ao_modo_mudou(modo)
	return true


func _ao_toque(p: Vector2) -> void:
	if modo == Modo.NENHUM:
		return
	var c := casa_em_tela(p)
	if dentro(c):
		_escolher_casa(c)


func _escolher_casa(c: Vector2i) -> void:
	match modo:
		Modo.MOVER:
			if _casas.has(c):
				var destino := {"tipo": "mover", "destino": {"x": c.x, "y": c.y}}
				if hud.sair_com_seguranca and Estado.tem_acao("desvincular"):
					# Como no site: a intenção «Sair c/ segurança» gasta-se na partida. O servidor recebe primeiro
					# o Desvincular e, aceite esse, o movimento (uma intenção de cada vez).
					_mover_depois = destino
					if enviar_acao({"tipo": "desvincular"}):
						_id_seguranca = _ultimo_id
						hud.consumir_seguranca()
					else:
						_mover_depois = {}
				else:
					enviar_acao(destino)
		Modo.ATAQUE:
			var fid: String = Estado.figura_na_casa(c)
			if fid == "" or not _alvos.has(fid):
				return
			var ops: Array = _alvos[fid]
			if ops.size() == 1:
				_enviar_ataque(ops[0])
				return
			var itens: Array = []
			for i in ops.size():
				var o: Dictionary = ops[i]
				itens.append([hud.nome_legivel(o.get("arma"), o.get("nome"), "Opção %d" % (i + 1)), _enviar_ataque.bind(o)])
			hud.escolher("Com o quê?", itens)
		Modo.CONSUMIVEL:
			var fid: String = Estado.figura_na_casa(c)
			if fid != "" and _alvos.has(fid):
				enviar_acao({"tipo": "consumivel", "itemId": _item.get("itemId"), "alvoId": fid})
		_:
			pass


## O recibo do Desvincular: aceite, segue o movimento (com a revisão nova); recusado, o movimento não sai.
## Ordem 33 (V33): só o recibo DESTE Desvincular conta. Antes, qualquer recibo novo soltava o movimento — e a
## recusa do servidor chega como ROOM_REJECT (`_ao_recusa_seguranca`), não como recibo: o movimento ficava guardado
## e saía com o recibo da acção seguinte que ela fizesse (andava sozinha para a casa de antes).
func _ao_recibo_seguranca(intent_id: String, estado: String, _msg: Dictionary) -> void:
	if _mover_depois.is_empty() or intent_id != _id_seguranca:
		return
	var m := _mover_depois
	_mover_depois = {}
	_id_seguranca = ""
	if estado == "APLICADA":
		(func(): enviar_acao(m)).call_deferred()


## Ordem 33 (V33): o Desvincular recusado (ROOM_REJECT) — o movimento não sai.
func _ao_recusa_seguranca(intent_id: String, _motivo: String, _texto: String) -> void:
	if intent_id != "" and intent_id == _id_seguranca:
		_mover_depois = {}
		_id_seguranca = ""


func _enviar_ataque(o: Dictionary) -> void:
	enviar_acao({"tipo": "atacar", "alvoId": o.get("alvoId"), "arma": o.get("arma")})


func _id_de(v) -> String:
	if v is String:
		return v
	if v is Dictionary:
		var x = v.get("alvoId", v.get("id"))
		return x if x is String else ""
	return ""


# ---------------------------------------------------------------- teclado (só no Mover)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if modo == Modo.MOVER:
			var c := casa_em_tela(event.position)
			if dentro(c) and c != _cursor:
				_cursor = c
				_atualizar_cursor()
		return
	var tecla := event as InputEventKey
	if tecla == null or not tecla.pressed:
		return
	if tecla.keycode == KEY_ESCAPE and modo != Modo.NENHUM:
		definir_modo(Modo.NENHUM)
		get_viewport().set_input_as_handled()
		return
	if modo != Modo.MOVER:
		return  # setas só no modo Mover
	var d := Vector2i.ZERO
	match tecla.keycode:
		KEY_UP:
			d = _direcao_tela(Vector2(0, -1))
		KEY_DOWN:
			d = _direcao_tela(Vector2(0, 1))
		KEY_LEFT:
			d = _direcao_tela(Vector2(-1, 0))
		KEY_RIGHT:
			d = _direcao_tela(Vector2(1, 0))
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_escolher_casa(_cursor)
			get_viewport().set_input_as_handled()
			return
		_:
			return
	var novo := _cursor + d
	if dentro(novo):
		_cursor = novo
		_atualizar_cursor()
	get_viewport().set_input_as_handled()


## Converte "cima/baixo/esquerda/direita da tela" num passo de casa, conforme a câmera.
func _direcao_tela(v: Vector2) -> Vector2i:
	var b := camera.global_transform.basis
	var mundo: Vector3 = b.x * v.x + (-b.z) * (-v.y)
	if absf(mundo.x) >= absf(mundo.z):
		return Vector2i(1 if mundo.x > 0.0 else -1, 0)
	return Vector2i(0, 1 if mundo.z > 0.0 else -1)


# ---------------------------------------------------------------- desenho

func _mostrar_destaques() -> void:
	if _destaques == null:
		return
	var lista: Array = []
	if modo == Modo.MOVER:
		for c in _casas:
			if dentro(c):
				lista.append([c, COR_MOVER])
	elif modo == Modo.ATAQUE or modo == Modo.CONSUMIVEL:
		for fid in _alvos:
			var c: Vector2i = Estado.casa_de(Estado.figuras.get(fid))
			if dentro(c):
				lista.append([c, COR_ALVO])
	_destaques.mesh = _malha_casas(lista, 0.9, LEVANTA_M + 0.01)


## Ordem 13: desenha as casas a arder que o servidor mandou (Estado.fogo.casas). Devolve quantas desenhou.
func mostrar_fogo() -> int:
	if _fogo == null:
		return 0
	var lista: Array = []
	var casas = Estado.fogo.get("casas") if Estado.fogo.get("casas") is Array else []
	for k in casas:
		if not (k is Dictionary):
			continue
		var c := Vector2i(int(k.get("x", -1)), int(k.get("y", -1)))
		if dentro(c) and lista.size() < largura * altura:
			lista.append([c, COR_FOGO])
	_fogo.mesh = _malha_casas(lista, 0.96, LEVANTA_M + 0.005)
	return lista.size()


func _atualizar_cursor() -> void:
	if _marcador == null:
		return
	var ver := modo == Modo.MOVER and dentro(_cursor)
	_marcador.visible = ver
	_rotulo_custo.visible = false
	if not ver:
		return
	_marcador.mesh = _malha_casas([[_cursor, COR_CURSOR]], 0.98, LEVANTA_M + 0.02)
	var custo = _casas.get(_cursor)
	if custo is float or custo is int:
		_rotulo_custo.text = ("%.1f" % float(custo)).replace(".", ",") + " m"
		_rotulo_custo.position = centro_casa(_cursor) + Vector3(0.0, 0.5, 0.0)
		_rotulo_custo.visible = true


func _sincronizar_figuras() -> void:
	var vistos := {}
	for id in Estado.figuras:
		var f: Dictionary = Estado.figuras[id]
		var c: Vector2i = Estado.casa_de(f)
		if not dentro(c):
			continue  # não colocada (ou fora da arena): não existe aqui
		vistos[id] = true
		var no: Node3D = _nos.get(id)
		if no == null:
			no = _criar_figura()
			_nos[id] = no
			no.position = pe_figura(c)
		_atualizar_figura(no, id, f, c)
	for id in _nos.keys():
		if not vistos.has(id):
			_nos[id].queue_free()
			_nos.erase(id)


func _criar_figura() -> Node3D:
	var no := Node3D.new()
	var corpo := MeshInstance3D.new()
	corpo.name = "Corpo"
	corpo.add_to_group(&"figura")  # o AplicadorPerfil liga/desliga o contorno por este grupo
	corpo.add_to_group(Clima.GRUPO_FIGURA)  # ordem 40: a figura responde ao clima (molhada, neve em cima)
	var capsula := CapsuleMesh.new()
	capsula.radius = casa_m * 0.28
	capsula.height = 1.7
	capsula.material = StandardMaterial3D.new()
	corpo.mesh = capsula
	corpo.position = Vector3(0.0, 0.85, 0.0)
	no.add_child(corpo)
	var nome := Label3D.new()
	nome.name = "Nome"
	nome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nome.no_depth_test = true
	nome.font_size = 56
	nome.outline_size = 14
	nome.pixel_size = 0.005
	nome.position = Vector3(0.0, 2.1, 0.0)
	no.add_child(nome)
	_figuras.add_child(no)
	return no


func _atualizar_figura(no: Node3D, id: String, f: Dictionary, c: Vector2i) -> void:
	var destino := pe_figura(c)
	if no.position.distance_to(destino) > 0.01:
		var tw := no.create_tween()
		tw.tween_property(no, "position", destino, 0.25)
	var corpo: MeshInstance3D = no.get_node("Corpo")
	var mat: StandardMaterial3D = (corpo.mesh as CapsuleMesh).material
	# `visivel` (projecao.js visivelDe): de_pe | caida | morta | transformada.
	var visivel = f.get("visivel")
	var cor := COR_CRIATURA
	if id == Estado.minha_figura_id:
		cor = COR_PROPRIA
	elif Estado.e_jogadora(f):
		cor = COR_JOGADORA
	if visivel == "morta":
		cor = COR_MORTA
	elif visivel == "transformada":
		cor = cor.lightened(0.35)  # PROVISÓRIO: o visual da transformação é do Plano B
	mat.albedo_color = cor
	var deitada: bool = visivel == "caida" or visivel == "morta"
	corpo.rotation_degrees = Vector3(0.0, 0.0, 90.0 if deitada else 0.0)
	corpo.position = Vector3(0.0, casa_m * 0.28 if deitada else 0.85, 0.0)
	var ori = f.get("orientacao")
	if ori is String and RUMO_ORIENTACAO.has(ori.to_upper()):
		no.rotation_degrees.y = float(RUMO_ORIENTACAO[ori.to_upper()])
	var rotulo: Label3D = no.get_node("Nome")
	var texto = f.get("nomePublico")
	rotulo.text = texto if texto is String else ""


# ---------------------------------------------------------------- reações ao Estado

func _ao_snapshot() -> void:
	# projecao.js: mapa = {largura, altura, casaM} (conferido contra o servidor).
	var w := _num_ou(Estado.mapa.get("largura"), largura_padrao)
	var h := _num_ou(Estado.mapa.get("altura"), altura_padrao)
	var bruto_casa = Estado.mapa.get("casaM")
	var casa: float = casa_m_padrao
	if (bruto_casa is float or bruto_casa is int) and float(bruto_casa) > 0.0:
		casa = float(bruto_casa)
	if w != largura or h != altura or not is_equal_approx(casa, casa_m):
		for id in _nos:
			_nos[id].queue_free()
		_nos.clear()
		_construir_grelha(w, h, casa)
	_sincronizar_figuras()
	mostrar_fogo()
	if not _focou and Estado.minha_figura_id != "":
		var minha: Vector2i = Estado.casa_de(Estado.figuras.get(Estado.minha_figura_id))
		if dentro(minha):
			camera.focar(centro_casa(minha))
			_focou = true
	_ao_opcoes()


func _ao_evento(_evento: Dictionary) -> void:
	_sincronizar_figuras()
	_mostrar_destaques()
	mostrar_fogo()


## As opções mudaram (ou deixaram de valer): refaz o destaque, sem enviar nada.
func _ao_opcoes() -> void:
	if modo == Modo.MOVER or modo == Modo.ATAQUE:
		_casas.clear()
		_alvos.clear()
		_preencher_do_servidor()
		if modo == Modo.MOVER and not _casas.has(_cursor) and not dentro(_cursor):
			_cursor = Vector2i(_casas.keys()[0])
	elif modo == Modo.CONSUMIVEL:
		var ainda := false
		for o in Estado.lista_opcao("consumiveis"):
			if o is Dictionary and o.get("itemId") == _item.get("itemId"):
				ainda = true
		if not ainda:
			modo = Modo.NENHUM
			_alvos.clear()
	_mostrar_destaques()
	_atualizar_cursor()
	hud.ao_modo_mudou(modo)


func _ao_preferencia(chave: String, valor) -> void:
	match chave:
		"perfil":
			_aplicar_perfil(str(valor))
		"camera":
			camera.definir_modo_por_nome(str(valor))
		"zoom_padrao":
			camera.repor_zoom()
		"clima":
			# Ordem 40: parâmetro de apresentação ("nenhum", "chuva-fraca", "chuva-forte", "neve-fraca", "neve-forte").
			clima.definir_por_nome(str(valor))
		_:
			pass


## Perfis Baixo / Médio / Alto: a tabela é a do AplicadorPerfil (PROVISÓRIA até a V4.4 medir).
## O Sol e o Ambiente da cena estão nos grupos "sol" e "ambiente"; o corpo das figuras no "figura".
func _aplicar_perfil(perfil: String) -> void:
	if not _perfis.aplicar(perfil):
		_perfis.aplicar("medio")


## Ordem 42: o perfil chega também ao mapa — a relva do mapa tem LOD próprio, por isso a densidade da
## folhagem do perfil passa-se ao mapa (não pelo grupo «folhagem_densa»). O número é o da tabela do
## AplicadorPerfil; a arena não tem números próprios.
func _ao_perfil_aplicado(nome: String) -> void:
	if mapa == null or not is_instance_valid(mapa):
		return
	var fonte: Dictionary = _perfis.tabela if not _perfis.tabela.is_empty() else AplicadorPerfil.PERFIS
	var cfg: Dictionary = fonte.get(nome, fonte.get("medio", {}))
	var base: Dictionary = AplicadorPerfil.PERFIS["medio"]
	mapa.definir_densidade_relva(float(cfg.get("folhagem_densidade", base["folhagem_densidade"])))


static func _num_ou(v, padrao: int) -> int:
	if v is int:
		return v
	if v is float:
		return int(v)
	return padrao
