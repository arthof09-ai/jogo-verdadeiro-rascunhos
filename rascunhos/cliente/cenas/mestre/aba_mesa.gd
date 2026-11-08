extends VBoxContainer
## Aba «Mesa» do ecrã do Mestre: montar o lobby e colocar criaturas e NPCs (§12 do desenho JV3.1,
## I0004 08/11/2026).
##
## - Procurar fichas (MASTER_SEARCH → MASTER_RESULTS: nome verdadeiro, nome público, papel, classificação).
## - Marcar as que ficam «Na mesa» e «Guardar a mesa» (MASTER_LOBBY_SET), só no lobby.
## - «Começar a batalha» (MASTER_START), com segundo toque.
## - «Colocar»: escolher a ficha e depois a casa no tabuleiro (MASTER_PLACE, orientação «S», a do servidor
##   por omissão). Uma de cada vez, à espera do recibo (L5: o lote por esquema fica para quando a série
##   se mostrar lenta). A figura aparece à Party logo que é colocada: o texto avisa.

const Textos := preload("res://cenas/mestre/textos_mestre.gd")

## O ecrã do Mestre (mestre.gd): enviar(tipo, campos) e pesquisar(texto).
var mestre
## Ficha à espera de casa no tabuleiro ("" = nenhuma).
var a_colocar := ""

var _resultados: Dictionary = {}  # fichaId -> {fichaId, nome, nomePublico, papel, classificacao}
var _marcadas: Dictionary = {}  # fichaId -> papel
var _lobby_visto := ""  # JSON do último lobby que veio na vista (para não apagar as marcas do Mestre)
var _fase := ""
var _armado_comecar := false
var _procura: LineEdit
var _lista_res: VBoxContainer
var _guardar: Button
var _comecar: Button
var _estado: Label
var _lista_colocar: VBoxContainer
var _parar: Button


func montar(m) -> void:
	mestre = m
	var linha := HBoxContainer.new()
	add_child(linha)
	_procura = LineEdit.new()
	_procura.name = "Procura"
	_procura.placeholder_text = Textos.PROCURAR_DICA
	_procura.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_procura.text_submitted.connect(func(_t): procurar())
	linha.add_child(_procura)
	var b := Button.new()
	b.text = Textos.PROCURAR
	b.pressed.connect(procurar)
	linha.add_child(b)
	_lista_res = VBoxContainer.new()
	_lista_res.name = "Resultados"
	add_child(_lista_res)
	_guardar = Button.new()
	_guardar.name = "Guardar"
	_guardar.text = Textos.GUARDAR_MESA
	_guardar.pressed.connect(guardar)
	add_child(_guardar)
	_comecar = Button.new()
	_comecar.name = "Comecar"
	_comecar.text = Textos.COMECAR
	_comecar.pressed.connect(comecar)
	add_child(_comecar)
	add_child(HSeparator.new())
	_estado = Label.new()
	_estado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_estado)
	_lista_colocar = VBoxContainer.new()
	_lista_colocar.name = "Colocar"
	add_child(_lista_colocar)
	_parar = Button.new()
	_parar.text = Textos.PARAR_COLOCAR
	_parar.visible = false
	_parar.pressed.connect(parar)
	add_child(_parar)


func procurar() -> void:
	mestre.pesquisar(_procura.text.strip_edges())


func receber_resultados(msg: Dictionary) -> void:
	var lista = msg.get("resultados")
	for n in _lista_res.get_children():
		n.queue_free()
	if not (lista is Array) or lista.is_empty():
		var l := Label.new()
		l.text = Textos.SEM_RESULTADOS
		_lista_res.add_child(l)
		return
	for r in lista:
		if not (r is Dictionary):
			continue
		var id := str(r.get("fichaId", ""))
		_resultados[id] = r
		var c := CheckBox.new()
		c.text = Textos.RESULTADO % [_nome(id), str(Textos.PAPEL_FICHA.get(str(r.get("papel", "")), r.get("papel", ""))),
			str(r.get("classificacao", ""))]
		c.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		c.set_meta("ficha", id)
		c.button_pressed = _marcadas.has(id)
		c.disabled = _fase != "lobby"
		c.toggled.connect(marcar.bind(id))
		_lista_res.add_child(c)
	_desenhar_colocar(mestre.vista)


func marcar(sim: bool, ficha_id: String) -> void:
	if sim:
		_marcadas[ficha_id] = str(_resultados.get(ficha_id, {}).get("papel", "criatura"))
	else:
		_marcadas.erase(ficha_id)


func atualizar(vista: Dictionary) -> void:
	_fase = str(vista.get("fase", ""))
	var lobby = vista.get("mestre", {}).get("lobby") if vista.get("mestre") is Dictionary else null
	var texto_lobby := JSON.stringify(lobby)
	if texto_lobby != _lobby_visto:
		_lobby_visto = texto_lobby
		_marcadas.clear()
		if lobby is Dictionary:
			for id in lobby.get("criaturasDisponiveis", []):
				_marcadas[str(id)] = "criatura"
			for id in lobby.get("npcsDisponiveis", []):
				_marcadas[str(id)] = "npc"
	_guardar.disabled = _fase != "lobby"
	_comecar.visible = _fase == "lobby"
	if _fase != "lobby":
		_armado_comecar = false
	_comecar.text = Textos.DE_NOVO_PARA % Textos.COMECAR if _armado_comecar else Textos.COMECAR
	for c in _lista_res.get_children():
		if c is CheckBox:
			c.set_pressed_no_signal(_marcadas.has(str(c.get_meta("ficha"))))
			c.disabled = _fase != "lobby"
	_desenhar_colocar(vista)


func guardar() -> void:
	if _fase != "lobby":
		return
	var criaturas: Array = []
	var npcs: Array = []
	for id in _marcadas:
		if _marcadas[id] == "npc":
			npcs.append(id)
		else:
			criaturas.append(id)
	criaturas.sort()
	npcs.sort()
	var lobby = mestre.vista.get("mestre", {}).get("lobby") if mestre.vista.get("mestre") is Dictionary else null
	var mapa = lobby.get("mapaId") if lobby is Dictionary else null
	mestre.enviar("MASTER_LOBBY_SET", {"mapaId": mapa, "criaturasDisponiveis": criaturas, "npcsDisponiveis": npcs})


func comecar() -> void:
	if _fase != "lobby":
		return
	if not _armado_comecar:
		_armado_comecar = true
		_comecar.text = Textos.DE_NOVO_PARA % Textos.COMECAR
		return
	_armado_comecar = false
	_comecar.text = Textos.COMECAR
	mestre.enviar("MASTER_START", {})


func escolher_colocar(ficha_id: String) -> void:
	a_colocar = ficha_id
	_estado.text = Textos.COLOCAR_ESCOLHER % _nome(ficha_id)
	_parar.visible = true


## Casa tocada no tabuleiro. Devolve true se a aba a usou (estava a colocar).
func colocar(casa: Vector2i) -> bool:
	if a_colocar == "":
		return false
	mestre.enviar("MASTER_PLACE", {"fichaId": a_colocar, "casa": {"x": casa.x, "y": casa.y}, "orientacao": "S"})
	return true


func parar() -> void:
	a_colocar = ""
	_estado.text = ""
	_parar.visible = false


func _desenhar_colocar(vista: Dictionary) -> void:
	for n in _lista_colocar.get_children():
		n.queue_free()
	var lobby = vista.get("mestre", {}).get("lobby") if vista.get("mestre") is Dictionary else null
	if not (lobby is Dictionary) or (_fase != "lobby" and _fase != "combate"):
		return
	var ids: Array = []
	ids.append_array(lobby.get("criaturasDisponiveis", []))
	ids.append_array(lobby.get("npcsDisponiveis", []))
	for id in ids:
		var b := Button.new()
		b.text = Textos.COLOCAR % _nome(str(id))
		b.set_meta("ficha", str(id))
		b.pressed.connect(escolher_colocar.bind(str(id)))
		_lista_colocar.add_child(b)


func _nome(ficha_id: String) -> String:
	var r: Dictionary = _resultados.get(ficha_id, {})
	var nome := str(r.get("nome", ""))
	var publico = r.get("nomePublico")
	if nome == "":
		return ficha_id
	if publico is String and publico != "" and publico != nome:
		return "%s (%s)" % [nome, publico]
	return nome
