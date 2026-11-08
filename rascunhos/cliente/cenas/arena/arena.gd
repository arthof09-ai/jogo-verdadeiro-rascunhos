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

const CameraMesa := preload("res://camera/camera_mesa.gd")

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
var modo: int = Modo.NENHUM

var _item: Dictionary = {}
var _casas: Dictionary = {}  # Vector2i -> custoM (como veio do servidor)
var _alvos: Dictionary = {}  # figuraId -> Array de opções de ataque, ou true
var _cursor := Vector2i(-1, -1)
var _destaques: MultiMeshInstance3D
var _marcador: MeshInstance3D
var _rotulo_custo: Label3D
var _nos: Dictionary = {}  # figuraId -> Node3D
var _focou := false
var _saindo := false


func _ready() -> void:
	_sol.rotation_degrees = Vector3(-55.0, 35.0, 0.0)
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

	var chao := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = tam
	var mat_chao := StandardMaterial3D.new()
	mat_chao.albedo_color = COR_CHAO
	plano.material = mat_chao
	chao.mesh = plano
	chao.position = Vector3(tam.x * 0.5, 0.0, tam.y * 0.5)
	_grelha.add_child(chao)

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _material_sem_luz(COR_LINHAS))
	for i in range(largura + 1):
		im.surface_add_vertex(Vector3(i * casa_m, 0.02, 0.0))
		im.surface_add_vertex(Vector3(i * casa_m, 0.02, tam.y))
	for j in range(altura + 1):
		im.surface_add_vertex(Vector3(0.0, 0.02, j * casa_m))
		im.surface_add_vertex(Vector3(tam.x, 0.02, j * casa_m))
	im.surface_end()
	var linhas := MeshInstance3D.new()
	linhas.mesh = im
	_grelha.add_child(linhas)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var quad := PlaneMesh.new()
	quad.size = Vector2(casa_m * 0.9, casa_m * 0.9)
	var mat_q := _material_sem_luz(Color.WHITE)
	mat_q.vertex_color_use_as_albedo = true
	quad.material = mat_q
	mm.mesh = quad
	mm.instance_count = largura * altura
	mm.visible_instance_count = 0
	_destaques = MultiMeshInstance3D.new()
	_destaques.multimesh = mm
	_grelha.add_child(_destaques)

	_marcador = MeshInstance3D.new()
	var q2 := PlaneMesh.new()
	q2.size = Vector2(casa_m * 0.98, casa_m * 0.98)
	q2.material = _material_sem_luz(COR_CURSOR)
	_marcador.mesh = q2
	_marcador.visible = false
	_grelha.add_child(_marcador)

	_rotulo_custo = Label3D.new()
	_rotulo_custo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_rotulo_custo.no_depth_test = true
	_rotulo_custo.font_size = 64
	_rotulo_custo.outline_size = 16
	_rotulo_custo.pixel_size = 0.006
	_rotulo_custo.visible = false
	_grelha.add_child(_rotulo_custo)

	camera.configurar_arena(Vector3(tam.x * 0.5, 0.0, tam.y * 0.5), tam)
	_mostrar_destaques()


func _material_sem_luz(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = cor
	return m


func dentro(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < largura and c.y < altura


func centro_casa(c: Vector2i) -> Vector3:
	return Vector3((c.x + 0.5) * casa_m, 0.0, (c.y + 0.5) * casa_m)


## Casa sob um ponto da tela, ou (-1,-1). É só geometria de ecrã → chão.
func casa_em_tela(p: Vector2) -> Vector2i:
	var origem := camera.project_ray_origin(p)
	var direcao := camera.project_ray_normal(p)
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(origem, direcao)
	if hit == null:
		return Vector2i(-1, -1)
	var c := Vector2i(floori(hit.x / casa_m), floori(hit.z / casa_m))
	return c if dentro(c) else Vector2i(-1, -1)


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
	modo = Modo.NENHUM
	_casas.clear()
	_alvos.clear()
	_mostrar_destaques()
	_atualizar_cursor()
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
				enviar_acao({"tipo": "mover", "destino": {"x": c.x, "y": c.y}})
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
	var mm := _destaques.multimesh
	var n := 0
	if modo == Modo.MOVER:
		for c in _casas:
			if dentro(c) and n < mm.instance_count:
				mm.set_instance_transform(n, Transform3D(Basis(), centro_casa(c) + Vector3(0.0, 0.03, 0.0)))
				mm.set_instance_color(n, COR_MOVER)
				n += 1
	elif modo == Modo.ATAQUE or modo == Modo.CONSUMIVEL:
		for fid in _alvos:
			var c: Vector2i = Estado.casa_de(Estado.figuras.get(fid))
			if dentro(c) and n < mm.instance_count:
				mm.set_instance_transform(n, Transform3D(Basis(), centro_casa(c) + Vector3(0.0, 0.03, 0.0)))
				mm.set_instance_color(n, COR_ALVO)
				n += 1
	mm.visible_instance_count = n


func _atualizar_cursor() -> void:
	if _marcador == null:
		return
	var ver := modo == Modo.MOVER and dentro(_cursor)
	_marcador.visible = ver
	_rotulo_custo.visible = false
	if not ver:
		return
	_marcador.position = centro_casa(_cursor) + Vector3(0.0, 0.04, 0.0)
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
			no.position = centro_casa(c)
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
	var destino := centro_casa(c)
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
	if not _focou and Estado.minha_figura_id != "":
		var minha: Vector2i = Estado.casa_de(Estado.figuras.get(Estado.minha_figura_id))
		if dentro(minha):
			camera.focar(centro_casa(minha))
			_focou = true
	_ao_opcoes()


func _ao_evento(_evento: Dictionary) -> void:
	_sincronizar_figuras()
	_mostrar_destaques()


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
		_:
			pass


## Perfis Baixo / Médio / Alto: a tabela é a do AplicadorPerfil (PROVISÓRIA até a V4.4 medir).
## O Sol e o Ambiente da cena estão nos grupos "sol" e "ambiente"; o corpo das figuras no "figura".
func _aplicar_perfil(perfil: String) -> void:
	if not _perfis.aplicar(perfil):
		_perfis.aplicar("medio")


static func _num_ou(v, padrao: int) -> int:
	if v is int:
		return v
	if v is float:
		return int(v)
	return padrao
