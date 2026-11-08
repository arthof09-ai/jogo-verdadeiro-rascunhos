extends VBoxContainer
## Aba «Registo» do ecrã do Mestre: o «Registo da batalha», o «Exportar registo» e o «Voltar até aqui»
## (§12 do desenho JV3.1, I0004 08/11/2026), e as estatísticas da batalha (L9, C-28: só no papel Mestre). Os pontos vêm do servidor (MASTER_VIEW.pontos, L8): o cliente
## não inventa pontos nem calcula nada. Voltar pede dois passos: escolher o ponto e confirmar.

const Textos := preload("res://cenas/mestre/textos_mestre.gd")
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")

## O ecrã do Mestre (mestre.gd): enviar(tipo, campos) e exportar_registo().
var mestre
## journalSeq escolhido à espera de confirmação (-1: nenhum).
var escolhido := -1

var _info: Label
var _confirmar: VBoxContainer
var _pergunta: Label
var _lista: VBoxContainer
var _estat: VBoxContainer


func montar(m) -> void:
	mestre = m
	_rotulo(Textos.ABA_REGISTO)
	_info = _rotulo("")
	var exportar := Button.new()
	exportar.name = "Exportar"
	exportar.text = Textos.EXPORTAR_REGISTO
	exportar.pressed.connect(func(): mestre.exportar_registo())
	add_child(exportar)
	_confirmar = VBoxContainer.new()
	_confirmar.name = "Confirmar"
	_confirmar.visible = false
	add_child(_confirmar)
	_pergunta = Label.new()
	_pergunta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirmar.add_child(_pergunta)
	var sim := Button.new()
	sim.name = "VoltarAteAqui"
	sim.text = Textos.VOLTAR_ATE_AQUI
	sim.pressed.connect(confirmar)
	_confirmar.add_child(sim)
	var nao := Button.new()
	nao.text = Textos.CANCELAR
	nao.pressed.connect(cancelar)
	_confirmar.add_child(nao)
	_lista = VBoxContainer.new()
	_lista.name = "Pontos"
	add_child(_lista)
	add_child(HSeparator.new())
	_rotulo(Textos.ESTATISTICAS)
	_estat = VBoxContainer.new()
	_estat.name = "Estatisticas"
	add_child(_estat)


func atualizar(vista: Dictionary) -> void:
	_info.text = Textos.JOURNAL % int(vista.get("journalSeq", 0))
	for n in _estat.get_children():
		n.queue_free()
	for linha in Modelo.linhas_estatisticas(vista):
		_rotulo_em(_estat, linha)
	for n in _lista.get_children():
		n.queue_free()
	var pontos = vista.get("pontos")
	if not (pontos is Array) or pontos.is_empty():
		_rotulo_em(_lista, Textos.SEM_PONTOS)
		cancelar()
		return
	var ainda_existe := false
	for p in pontos:
		if not (p is Dictionary):
			continue
		var seq := int(p.get("journalSeq", -1))
		ainda_existe = ainda_existe or seq == escolhido
		var b := Button.new()
		b.text = Modelo.linha_ponto(vista, p)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.set_meta("seq", seq)
		b.pressed.connect(escolher.bind(seq))
		_lista.add_child(b)
	if not ainda_existe:
		cancelar()


func pontos_mostrados() -> int:
	var n := 0
	for c in _lista.get_children():
		if c is Button and c.has_meta("seq") and not c.is_queued_for_deletion():
			n += 1
	return n


func escolher(seq: int) -> void:
	escolhido = seq
	_pergunta.text = Textos.VOLTAR_PERGUNTA
	_confirmar.visible = true


func confirmar() -> void:
	if escolhido < 0:
		return
	mestre.enviar("MASTER_SUPERVISOR", {"op": "voltar", "ateSeq": escolhido})
	cancelar()


func cancelar() -> void:
	escolhido = -1
	if _confirmar != null:
		_confirmar.visible = false


func mostrar_export(nome: String) -> void:
	_info.text = Textos.REGISTO_EXPORTADO % nome


func _rotulo(texto: String) -> Label:
	return _rotulo_em(self, texto)


func _rotulo_em(pai: Node, texto: String) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.text = texto
	pai.add_child(l)
	return l
