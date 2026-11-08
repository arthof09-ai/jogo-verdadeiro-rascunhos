extends VBoxContainer
## Aba «Agir» do ecrã do Mestre: jogar a criatura da vez à mão (§12 do desenho JV3.1, I0004 08/11/2026).
##
## - O modo H10 da criatura da vez: «À mão» · «Com o meu Confirmar» · «Automático» (MASTER_MODE).
## - As opções vêm do servidor (ROOM_OPTIONS ao lugar do Mestre na vez de uma criatura, quando não há
##   cartão aberto): o cliente não escolhe casas, custos nem alvos. Mover destaca as casas no tabuleiro;
##   tocar numa delas manda MASTER_ACT {mover}. Cada ataque e cada acção sem parâmetros é um botão.
## - «Escolher outra» no cartão de IA continua desligado: enquanto um cartão está aberto o servidor não
##   manda opções (sala.js opcoesDoLugar). O caminho é «Jogo eu» (a IA pára) e depois esta aba.

const Textos := preload("res://cenas/mestre/textos_mestre.gd")
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")
const MODOS := ["manual", "semi", "auto"]

## O ecrã do Mestre (mestre.gd): enviar(tipo, campos), destacar(casas) e vista.
var mestre
var a_mover := false

var _vez := ""
var _titulo: Label
var _linha_modos: HBoxContainer
var _modos: Dictionary = {}  # modo -> Button
var _info: Label
var _botoes: VBoxContainer
var _cancelar: Button
var _casas: Array[Vector2i] = []


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
	_cancelar.pressed.connect(parar_mover)
	add_child(_cancelar)


func atualizar(_vista: Dictionary = {}) -> void:
	var vista: Dictionary = mestre.vista
	var vez := str(vista.get("vezId", "")) if vista.get("vezId") is String else ""
	if vez != _vez:
		parar_mover()
	_vez = vez
	for n in _botoes.get_children():
		n.queue_free()
	var f := Modelo.figura(vista, vez)
	if f.is_empty() or str(f.get("lado", "")) == "jogadora":
		_titulo.text = Textos.AGIR_SEM_VEZ
		_linha_modos.visible = false
		_info.text = ""
		parar_mover()
		return
	_titulo.text = Textos.AGIR_VEZ % Modelo.nome_mestre(f)
	_linha_modos.visible = true
	for modo in MODOS:
		(_modos[modo] as Button).set_pressed_no_signal(str(f.get("modo", "")) == modo)
	var op := _opcoes()
	if op.is_empty():
		_info.text = Textos.AGIR_SEM_OPCOES
		parar_mover()
		return
	_info.text = ""
	if op.get("mover") is Array and not op["mover"].is_empty():
		_botao(Textos.MOVER, iniciar_mover)
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
	var op := _opcoes()
	_casas.clear()
	for c in op.get("mover", []):
		if c is Dictionary:
			_casas.append(Vector2i(int(c.get("x", -1)), int(c.get("y", -1))))
	a_mover = not _casas.is_empty()
	mestre.destacar(_casas)
	_cancelar.visible = a_mover
	_info.text = Textos.MOVER_ESCOLHER % _casas.size()


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
	mestre.enviar("MASTER_ACT", {"figuraId": _vez, "acao": acao})


func parar_mover() -> void:
	a_mover = false
	_casas.clear()
	if mestre != null:
		mestre.destacar(_casas)
	if _cancelar != null:
		_cancelar.visible = false


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
