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

## ORDEM DADOS DE APRESENTAÇÃO: as cores e os tamanhos de apresentação vêm da tabela única.
const Apresentacao := preload("res://dados/apresentacao.gd")

@export var largura_padrao: int = Apresentacao.GRELHA_LARGURA_PADRAO
@export var altura_padrao: int = Apresentacao.GRELHA_ALTURA_PADRAO
@export var casa_m_padrao: float = Apresentacao.CASA_M

const COR_CHAO := Apresentacao.COR_MESA_CHAO
const COR_LINHAS := Apresentacao.COR_MESA_LINHAS
const COR_MOVER := Apresentacao.COR_MESA_MOVER
const COR_ALVO := Apresentacao.COR_MESA_ALVO
const COR_CURSOR := Apresentacao.COR_MESA_CURSOR
const COR_PROPRIA := Apresentacao.COR_FIGURA_PROPRIA
const COR_JOGADORA := Apresentacao.COR_FIGURA_JOGADORA
const COR_CRIATURA := Apresentacao.COR_FIGURA_CRIATURA
const COR_MORTA := Apresentacao.COR_FIGURA_MORTA
## Ordem 44: a mancha de contacto da base (a do marcador do site: 080c12, opacidade 0,35).
const COR_BASE := Apresentacao.COR_CONTACTO
## Ordem 13: casa a arder (o fogo do ambiente; as casas vêm do servidor, em Estado.fogo).
const COR_FOGO := Apresentacao.COR_FOGO
## Ordem 60: quanto tempo o Aviso do HUD mostra uma recusa do pé (a marca na casa fica enquanto ela durar).
const SEGUNDOS_AVISO_RECUSA := 6.0

const CameraMesa := preload("res://camera/camera_mesa.gd")
## Ordem 42: o mapa da floresta e a sua altura única.
const CampoFloresta := preload("res://mapa/floresta/campo_floresta.gd")
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const GrelhaMapa := preload("res://mapa/floresta/grelha_floresta.gd")
## Ordem 44: a regra única do assentamento (onde fica a grelha, a altura das casas, a base das figuras).
## O exportador do terreno para o servidor chama as mesmas funções.
const Assentamento := preload("res://cenas/arena/assentamento.gd")
const SH_SOBRE := preload("res://cenas/arena/sobre_relevo.gdshader")
## Ordem 42 (parte 2): os pontos baixos REAIS do relevo, para o alagamento do clima.
const BaciasRelevo := preload("res://cenas/arena/bacias_do_relevo.gd")
## Ordem 45: o que esta arena e a do Mestre fazem igual sobre o mapa (montar, clima, remendos, linhas, toque).
const CampoDaMesa := preload("res://cenas/arena/campo_da_mesa.gd")
## Quantos dos obstáculos reais do mapa (os mais perto da zona) dão abrigo à neve (o módulo aceita até 8).
const ABRIGOS_DO_MAPA := CampoDaMesa.ABRIGOS_DO_MAPA
## Quantos metros acima do chão vai o que se cola ao relevo (o resto resolve-o o shader).
const LEVANTA_M := 0.03
## Divisões por lado de cada remendo de casa (os vértices seguem o relevo).
const DIVISOES_CASA := CampoDaMesa.DIVISOES_CASA
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
var casa_m := Apresentacao.CASA_M  # Ordem ESCALA: a escala do mundo nasce da tabela (DADOS)
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
var _relva_com_clima := false
var _rotulo_custo: Label3D
var _nos: Dictionary = {}  # figuraId -> Node3D
var _pes_recusados: Dictionary = {}  # Ordem 58: figuraId -> recusa do pé (casa bloqueada pelo mapa)
var _marcas_recusa: Dictionary = {}  # Ordem 60: figuraId -> a marca da figura recusada (campo_da_mesa.gd)
var _mat_recusa: ShaderMaterial  # Ordem 60: o material das marcas (o dos remendos, cor da instância)
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
		# Ordem 42 (parte 2): a relva do mapa responde ao clima (afoga nas bolsas, enterra-se na neve).
		_relva_com_clima = CampoDaMesa.relva_segue_clima(clima, mapa, _relva_com_clima)
	var rotulos: Array = []
	for no in _nos.values():
		if is_instance_valid(no) and (no as Node).has_node("Nome"):
			rotulos.append((no as Node).get_node("Nome"))
	NomesSemSobrepor.arrumar(rotulos, camera)


func _ready() -> void:
	# Ordem 42: o Sol já não se roda aqui — a direcção é a da luz pintada do mapa (paleta).
	camera.altura_em = altura_chao
	clima = CampoDaMesa.criar_clima()
	clima.name = "Clima"
	add_child(clima)
	# Ordem 52: a relva do mapa e as contagens do clima seguem o perfil gráfico, pelo código partilhado com o ecrã
	# do Mestre (as mesmas duas ligações de antes, pela mesma ordem).
	CampoDaMesa.ligar_perfil(_perfis, clima, func() -> Node3D: return mapa)
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
	casa_m = c if c > 0.0 else Apresentacao.CASA_M
	for n in _grelha.get_children():
		# Ordem 49 (C), como o ecrã do Mestre (arena_mestre.gd, Ordem 45): sai já da árvore. Só com o queue_free o
		# velho ficava até ao fim do quadro e o «Linhas» novo (e o Fogo, os Destaques, o Cursor) nascia com outro nome.
		_grelha.remove_child(n)
		n.queue_free()
	var tam := Vector2(largura * casa_m, altura * casa_m)
	origem = _origem_no_mapa(tam)
	_garantir_mapa(Rect2(origem, tam))

	# Sem chão próprio: o chão é o do mapa (e é ele que responde ao clima: ver _garantir_mapa).
	# As linhas seguem o relevo (amostra a cada 1/4 de casa).
	var im := CampoDaMesa.linhas_grelha(origem, casa_m, largura, altura, _material_sobre(COR_LINHAS, false), LEVANTA_M)
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
	_ligar_clima_ao_mapa(Rect2(origem, tam))
	_mostrar_destaques()
	mostrar_fogo()


## Ordem 42: onde fica a grelha no mapa. Centrada no centro da arena do mapa (0, 0) e, se as casas
## forem de 1,5 m, encostada às linhas da grelha do mapa (−37,5 + k × 1,5): cada casa do jogo é
## uma casa do mapa (20 × 20 → casas 15–34 do mapa).
func _origem_no_mapa(tam: Vector2) -> Vector2:
	return Assentamento.origem_no_mapa(tam, casa_m)


## O mapa é construído para a zona jogável (lá dentro não põe nada que ocupe uma casa sem o servidor
## saber). Se o snapshot mudar o tamanho da grelha, o mapa refaz-se para a zona nova.
func _garantir_mapa(zona: Rect2) -> void:
	if mapa != null and is_instance_valid(mapa) and mapa.zona_jogo.is_equal_approx(zona):
		return
	if mapa != null and is_instance_valid(mapa):
		remove_child(mapa)
		mapa.free()
	mapa = CampoDaMesa.montar_mapa(self, zona, ^"../Ambiente", ^"../Sol", ^"../Camera")
	if _perfis.atual != "":
		_ao_perfil_aplicado(_perfis.atual)


## Ordem 42 (parte 2): o clima sobre o mapa. As bacias do alagamento são os pontos baixos REAIS do relevo
## (inundação do terreno: cenas/arena/bacias_do_relevo.gd) e os abrigos da nevasca são os obstáculos REAIS
## do mapa (menires, santuário, lanternas, tronco tombado, rochas, árvores — mapa.obstaculos), os mais
## perto da zona. Cada abrigo é uma caixa invisível com a medida do obstáculo (o módulo lê a caixa da malha).
func _ligar_clima_ao_mapa(zona: Rect2) -> void:
	CampoDaMesa.ligar_clima(clima, mapa, zona, _grelha, altura_chao)


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
	return CampoDaMesa.malha_casas(origem, casa_m, casas, escala, levanta)


func dentro(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < largura and c.y < altura


## Centro da casa, em cima do chão do mapa (a altura do relevo nesse ponto).
func centro_casa(c: Vector2i) -> Vector3:
	return Assentamento.centro_casa(origem, casa_m, c)


## Ordem 44 (parte B): onde pousa o pé de uma figura na casa — no centro, à altura da BASE INCLINADA com a
## encosta (o plano que melhor se encosta ao relevo debaixo da pegada; ver assentamento.gd para o critério).
## Até à Ordem 42 era a altura mais baixa da pegada, com a base horizontal: nas 6 casas do outeiro o lado de
## cima entrava até 0,60 m no chão.
func pe_figura(c: Vector2i) -> Vector3:
	var p := centro_casa(c)
	return Vector3(p.x, float(pegada_figura(c)["y"]), p.z)


## A base de uma figura na casa `c`: {y, gradiente, normal, enterra, flutua} (assentamento.gd `pegada`).
func pegada_figura(c: Vector2i) -> Dictionary:
	var p := centro_casa(c)
	return Assentamento.pegada(p.x, p.z, Assentamento.raio_pegada(casa_m))


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
	return CampoDaMesa.ponto_no_chao(o, d)


## Posição na tela da cabeça de uma figura (para os números de dano), ou null.
func posicao_tela(figura_id: String):
	var no = _nos.get(figura_id)
	if no == null:
		return null
	var p: Vector3 = no.global_position + Vector3(0.0, 2.0, 0.0)
	if camera.is_position_behind(p):
		return null
	return camera.unproject_position(p)


## Ordem CAIXA-HUD-JOGADORA: o nó da figura `id` em cena (o retrato da caixa do HUD é a cópia dele), ou null.
func modelo_da_figura(id: String) -> Node3D:
	return _nos.get(id) as Node3D


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
	var recusados := {}
	var marcas := {}
	var novas: Array = []
	for id in Estado.figuras:
		var f: Dictionary = Estado.figuras[id]
		var c: Vector2i = Estado.casa_de(f)
		if not dentro(c):
			continue  # não colocada (ou fora da arena): não existe aqui
		# Ordem 58: numa casa que o mapa bloqueia a figura não se põe de pé (recusa com nome: campo_da_mesa.gd).
		# Ordem 60: mas não some em silêncio — fica marcada na casa dela, e a recusa nova aparece no Aviso do HUD.
		var recusa := CampoDaMesa.recusa_do_pe(mapa, origem, casa_m, c)
		if recusa != "":
			var nome_publico = f.get("nomePublico")
			var e := {"nome": nome_publico if nome_publico is String else str(id), "casa": c, "recusa": recusa}
			marcas[str(id)] = e
			if CampoDaMesa.anotar_recusa(_pes_recusados, recusados, str(id), recusa):
				novas.append(e)
			continue
		vistos[id] = true
		var no: Node3D = _nos.get(id)
		if no == null:
			no = _criar_figura()
			_nos[id] = no
			no.position = pe_figura(c)
		_atualizar_figura(no, id, f, c)
		# ORDEM MAPA-JOGÁVEL: a casa de água pisa-se; a figura mexe o lago (salpico, anéis — ORDEM ÁGUA-REAÇÃO).
		CampoDaMesa.seguir_na_agua(mapa, no, casa_m * Assentamento.RAIO_PEGADA_FRAC)
	for id in _nos.keys():
		if not vistos.has(id):
			_nos[id].queue_free()
			_nos.erase(id)
	_pes_recusados = recusados
	if _mat_recusa == null:
		_mat_recusa = _material_sobre(Color.WHITE, true)
		_mat_recusa.render_priority = 2
	CampoDaMesa.marcar_recusas(self, _marcas_recusa, marcas, origem, casa_m, _mat_recusa)
	var aviso := CampoDaMesa.aviso_das_recusas(novas, false)
	if aviso != "":
		hud.mostrar_aviso(aviso, SEGUNDOS_AVISO_RECUSA)


## Ordem 58: as figuras que o servidor tem em casas que o mapa bloqueia e que por isso não se põem de pé aqui:
## figuraId -> «FLORESTA-E08-CASA-BLOQUEADA: (x,y) motivo» (campo_da_mesa.gd `recusa_do_pe`).
func pes_recusados() -> Dictionary:
	return _pes_recusados.duplicate()


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
	# Ordem 44: a BASE da figura — a mancha de contacto (como a do marcador do site, 080c12 a 35 %), que se
	# inclina com a encosta e se cola ao chão por cima da relva (o shader dos remendos).
	var base := MeshInstance3D.new()
	base.name = "Base"
	var disco := CylinderMesh.new()
	disco.top_radius = casa_m * Assentamento.RAIO_PEGADA_FRAC
	disco.bottom_radius = disco.top_radius
	disco.height = 0.001
	disco.radial_segments = 24
	disco.rings = 1
	disco.material = _material_sobre(COR_BASE, false)
	base.mesh = disco
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	no.add_child(base)
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


## Ordem 44 (parte B): a base inclina-se com a encosta (no plano da pegada); o corpo de pé fica a prumo e
## sobe o justo para a cápsula tocar o plano sem o atravessar; o corpo caído deita-se no plano da base.
func _assentar_corpo(no: Node3D, c: Vector2i, deitada: bool) -> void:
	var pg := pegada_figura(c)
	var r := casa_m * Assentamento.RAIO_PEGADA_FRAC
	# a normal do plano, no espaço da figura (que só roda à volta do Y, pela orientação)
	var n: Vector3 = no.basis.inverse() * (pg["normal"] as Vector3)
	var inclina := Basis(Quaternion(Vector3.UP, n.normalized()))
	var base: MeshInstance3D = no.get_node("Base")
	base.transform = Transform3D(inclina, n.normalized() * 0.02)
	var corpo: MeshInstance3D = no.get_node("Corpo")
	if deitada:
		corpo.transform = Transform3D(inclina * Basis(Vector3.BACK, PI * 0.5), n.normalized() * r)
	else:
		corpo.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.85 + Assentamento.subida_do_corpo(pg["gradiente"], r), 0.0))


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
	var ori = f.get("orientacao")
	if ori is String and RUMO_ORIENTACAO.has(ori.to_upper()):
		no.rotation_degrees.y = float(RUMO_ORIENTACAO[ori.to_upper()])
	_assentar_corpo(no, c, deitada)
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
## AplicadorPerfil; a arena não tem números próprios. Ordem 52: a conta vive em campo_da_mesa.gd (a mesma no
## ecrã do Mestre); aqui fica só o reaplicar quando o mapa se refaz.
func _ao_perfil_aplicado(nome: String) -> void:
	CampoDaMesa.perfil_no_mapa(_perfis, mapa, nome)


static func _num_ou(v, padrao: int) -> int:
	if v is int:
		return v
	if v is float:
		return int(v)
	return padrao
