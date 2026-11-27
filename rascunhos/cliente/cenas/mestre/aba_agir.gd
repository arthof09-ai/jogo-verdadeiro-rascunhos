extends VBoxContainer
## Aba «Agir» do ecrã do Mestre: jogar a criatura da vez à mão (§12 do desenho JV3.1, I0004 08/11/2026).
##
## - O modo H10 da criatura da vez: «À mão» · «Com o meu Confirmar» · «Automático» (MASTER_MODE).
## - As opções vêm do servidor (ROOM_OPTIONS ao lugar do Mestre na vez de uma criatura, quando não há
##   cartão aberto): o cliente não escolhe casas, custos nem alvos. Mover destaca as casas no tabuleiro;
##   tocar numa delas manda MASTER_ACT {mover}. Cada ataque e cada acção sem parâmetros é um botão.
## - L10: com o cartão de IA aberto, o servidor manda ao Mestre as opções da criatura; o «Escolher outra»
##   do cartão abre esta aba em modo de troca, e a acção escolhida sai como MASTER_APPROVE editar {acao}.

const Textos := preload("res://cenas/mestre/textos_mestre.gd")
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")
const MODOS := ["manual", "semi", "auto"]

## O ecrã do Mestre (mestre.gd): enviar(tipo, campos), destacar(casas) e vista.
var mestre
var a_mover := false
## L10: o cartão de IA cuja proposta se está a trocar ("" = jogar à mão com MASTER_ACT).
var editar_cartao := ""

var _vez := ""
var _titulo: Label
var _linha_modos: HBoxContainer
var _modos: Dictionary = {}  # modo -> Button
var _info: Label
var _botoes: VBoxContainer
var _cancelar: Button
var _casas: Array[Vector2i] = []
## D-AUD-01-CORRECCOES-5 (B2): o «Mover» desarmou por falta de casas nesta vez — o aviso fica no `Info` enquanto as
## opções desta vez não trouxerem `mover` (apaga-se quando trouxerem, ou quando a vez muda).
var _aviso_sem_casas := false


func montar(m) -> void:
	mestre = m
	_titulo = _rotulo("Titulo")
	_linha_modos = HBoxContainer.new()
	_linha_modos.name = "Modos"
	add_child(_linha_modos)
	var l := Label.new()
	l.text = Textos.AGIR_MODO
	_linha_modos.add_child(l)
	for modo in MODOS:
		var b := Button.new()
		b.toggle_mode = true
		b.text = str(Textos.MODO[modo])
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(escolher_modo.bind(modo))
		_linha_modos.add_child(b)
		_modos[modo] = b
	_info = _rotulo("Info")
	_botoes = VBoxContainer.new()
	_botoes.name = "Accoes"
	add_child(_botoes)
	_cancelar = Button.new()
	_cancelar.text = Textos.CANCELAR
	_cancelar.visible = false
	_cancelar.pressed.connect(cancelar_mover)
	add_child(_cancelar)


func atualizar(_vista: Dictionary = {}) -> void:
	var vista: Dictionary = mestre.vista
	var vez := str(vista.get("vezId", "")) if vista.get("vezId") is String else ""
	# Rede de segurança: as opções chegam normalmente primeiro e a guarda morre no parar_mover() de «sem opções».
	if vez != _vez:
		parar_mover()
		_aviso_sem_casas = false
	_vez = vez
	for n in _botoes.get_children():
		n.queue_free()
	var f := Modelo.figura(vista, vez)
	if f.is_empty() or str(f.get("lado", "")) == "jogadora":
		_titulo.text = Textos.AGIR_SEM_VEZ
		_linha_modos.visible = false
		_info.text = ""
		parar_mover()
		_marcar_alvos([])
		return
	_titulo.text = Textos.AGIR_VEZ % Modelo.nome_mestre(f)
	_linha_modos.visible = true
	for modo in MODOS:
		(_modos[modo] as Button).set_pressed_no_signal(str(f.get("modo", "")) == modo)
	var op := _opcoes()
	if op.is_empty():
		_info.text = Textos.AGIR_SEM_OPCOES
		parar_mover()
		_marcar_alvos([])
		return
	_info.text = ""
	if editar_cartao != "":
		_info.text = Textos.AGIR_EDITAR
	var m = vista.get("mestre")
	if m is Dictionary and m.get("marchaLivreRodada") != null and int(m.get("marchaLivreRodada")) == int(vista.get("rodada", -1)):
		_info.text = (_info.text + "\n" if _info.text != "" else "") + Textos.AGIR_MARCHA_LIVRE
	var tem_mover: bool = op.get("mover") is Array and not op["mover"].is_empty()
	if a_mover and not tem_mover:
		# D-AUD-01-CORRECCOES-4 (B1): opções novas da MESMA vez sem «Mover» — as casas armadas já não valem (cada
		# toque seria um MASTER_ACT recusado). Desarma (casas, destaque, «Cancelar» e a ficha guardada do «Colocar»)
		# e diz ao Mestre porque o destaque saiu.
		parar_mover()
		_aviso_sem_casas = true
	if tem_mover:
		_aviso_sem_casas = false
	if _aviso_sem_casas:
		_info.text = (_info.text + "\n" if _info.text != "" else "") + Textos.MOVER_SEM_CASAS
	if a_mover and tem_mover:
		# D-AUD-01-CORRECCOES-5 (caso vizinho (a)): opções novas da MESMA vez com `mover`, mas com outras casas (p.ex.
		# depois de aprovar um cartão de IA). As casas armadas passam a ser as novas: uma casa que saiu deixa de mandar
		# um MASTER_ACT que o servidor recusa e uma que entrou deixa de ser engolida. Fica armado (e a ficha guardada
		# do «Colocar» também); o `Info` mostra a contagem nova (fim desta função).
		# D-AUD-01-CORRECCOES-6 (J1): o destaque é reposto SEMPRE, mesmo com as mesmas casas — outro desenho (p.ex. o
		# do esquema da Mesa) pode tê-lo trocado entretanto, e o «Mover» armado tem de mostrar as casas que aceita.
		var novas := _casas_de(op)
		_casas = novas
		mestre.destacar(_casas)
	if tem_mover:
		_botao(Textos.MOVER, iniciar_mover)
	# ORDEM-D-AUD-06: os alvos dos ataques ficam marcados na arena (o mesmo marcador da jogadora).
	var alvos: Array = []
	for a in op.get("ataques", []):
		if a is Dictionary and str(a.get("alvoId", "")) != "" and not alvos.has(str(a.get("alvoId", ""))):
			alvos.append(str(a.get("alvoId", "")))
	_marcar_alvos(alvos)
	for a in op.get("ataques", []):
		if a is Dictionary:
			var alvo := Modelo.nome_mestre(Modelo.figura(vista, str(a.get("alvoId", ""))))
			var arma := str(a.get("arma", "")).replace("-", " ").replace("_", " ")
			_botao(Textos.ATACAR % [alvo, arma], agir.bind({"tipo": "atacar", "alvoId": str(a.get("alvoId", "")), "arma": str(a.get("arma", ""))}))
	for t in op.get("acoes", []):
		_botao(str(Textos.NOME_ACAO.get(str(t), str(t))), agir.bind({"tipo": str(t)}))
	if a_mover:
		_info.text = Textos.MOVER_ESCOLHER % _casas.size()


## As opções do servidor para a criatura da vez (vazias se forem de outra revisão ou de outra figura).
func _opcoes() -> Dictionary:
	var op: Dictionary = Estado.opcoes_validas()
	if op.is_empty() or str(op.get("vezId", "")) != _vez:
		return {}
	return op


func escolher_modo(modo: String) -> void:
	if _vez == "":
		return
	mestre.enviar("MASTER_MODE", {"figuraId": _vez, "modo": modo})


func iniciar_mover() -> void:
	_casas = _casas_de(_opcoes())
	a_mover = not _casas.is_empty()
	if a_mover:
		mestre.armou_mover()  # D-AUD-01: o toque no tabuleiro passa a ser do «Mover»; o «Colocar» da Mesa desarma
	mestre.destacar(_casas)
	_cancelar.visible = a_mover
	_info.text = Textos.MOVER_ESCOLHER % _casas.size()


## As casas do `mover` das opções (vazio se não houver).
## D-AUD-01-CORRECCOES-6 (J8): um `mover` que não seja lista dá vazio; casas sem `x`/`y` saltam (antes davam a
## casa-fantasma (-1,-1)) e as repetidas contam uma vez.
func _casas_de(op: Dictionary) -> Array[Vector2i]:
	var casas: Array[Vector2i] = []
	var lista = op.get("mover", [])
	if not (lista is Array):
		return casas
	for c in lista:
		if c is Dictionary and c.has("x") and c.has("y"):
			var casa := Vector2i(int(c.get("x")), int(c.get("y")))
			if not casas.has(casa):
				casas.append(casa)
	return casas


## Casa tocada no tabuleiro. Devolve true se a aba a usou (estava a mover).
func mover(casa: Vector2i) -> bool:
	if not a_mover:
		return false
	if not _casas.has(casa):
		return true  # só as casas que o servidor mandou
	agir({"tipo": "mover", "destino": {"x": casa.x, "y": casa.y}})
	return true


func agir(acao: Dictionary) -> void:
	if _vez == "":
		return
	parar_mover()
	if editar_cartao != "":
		# L10: «Escolher outra» no cartão de IA — a acção escolhida troca a proposta da criatura.
		var id := editar_cartao
		editar_cartao = ""
		mestre.enviar("MASTER_APPROVE", {"cartaoId": id, "decisao": "editar", "edicao": {"acao": acao}})
		return
	mestre.enviar("MASTER_ACT", {"figuraId": _vez, "acao": acao})


## L10: entra (id) ou sai ("") do modo de trocar a proposta de um cartão de IA.
func editar(cartao_id: String) -> void:
	editar_cartao = cartao_id
	if mestre != null and mestre.vista is Dictionary:
		atualizar()


## «Cancelar» do Mover: desarma e, se o «Mover» tinha desarmado o «Colocar» da Mesa, o «Colocar» volta
## (D-AUD-01-CORRECCOES).
## D-AUD-01-CORRECCOES-2: repõe ANTES de parar — o parar_mover() apaga a ficha guardada (desarmou_mover).
func cancelar_mover() -> void:
	if a_mover and mestre != null:
		mestre.cancelou_mover()
	parar_mover()


func parar_mover() -> void:
	a_mover = false
	_casas.clear()
	if mestre != null:
		mestre.destacar(_casas)
		mestre.desarmou_mover()  # D-AUD-01-CORRECCOES-2: a ficha guardada pelo «Mover» deixa de valer
	if _cancelar != null:
		_cancelar.visible = false


## ORDEM-D-AUD-06: os alvos que esta aba marcou na arena (os `alvoId` dos ataques da criatura da vez).
var alvos_marcados: Array = []


func _marcar_alvos(ids: Array) -> void:
	alvos_marcados = ids.duplicate()
	if mestre != null and mestre.has_method("marcar_alvos"):
		mestre.marcar_alvos(ids)


func botoes_de_accao() -> Array:
	var saida: Array = []
	for b in _botoes.get_children():
		if b is Button and not b.is_queued_for_deletion():
			saida.append(b)
	return saida


func _botao(texto: String, acao: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(acao)
	_botoes.add_child(b)


func _rotulo(nome: String) -> Label:
	var l := Label.new()
	l.name = nome
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(l)
	return l
