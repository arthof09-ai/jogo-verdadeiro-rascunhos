extends VBoxContainer
## Aba «Mesa» do ecrã do Mestre: montar o lobby e colocar criaturas e NPCs (§12 do desenho JV3.1,
## I0004 08/11/2026).
##
## - Procurar fichas (MASTER_SEARCH → MASTER_RESULTS: nome verdadeiro, nome público, papel, classificação).
## - Marcar as que ficam «Na mesa» e «Guardar a mesa» (MASTER_LOBBY_SET), só no lobby.
## - «Começar a batalha» (MASTER_START), com segundo toque.
## - «Colocar»: escolher a ficha e depois a casa no tabuleiro (MASTER_PLACE, orientação «S», a do servidor
##   por omissão). A figura aparece à Party logo que é colocada: o texto avisa.
## - L5 (D5 do Plano A): «Montar esquema» junta casas (e fichas) numa lista sem mandar nada; «Colocar o
##   esquema» manda-as EM SÉRIE, uma de cada vez, cada uma só depois do recibo da anterior (MASTER_PLACE).
##   Se o servidor recusar uma, o esquema pára e o resto fica na lista. Não há mensagem de lote nova.

const Textos := preload("res://cenas/mestre/textos_mestre.gd")
## Ordem 26 (V22): MASTER_SEARCH.texto tem maxLength 64 (caracteres). O servidor já pesquisava só os primeiros 64.
## Ordem 34 (N26-1): o servidor recusa a pesquisa fora do schema (vazia, só espaços ou com mais de 64 depois de aparada:
## ERRO formato). Aqui o campo não deixa escrever mais de 64 (max_length conta caracteres, não bytes), o contador mostra
## quantos vão, e «Procurar» com o campo vazio não manda nada. A recusa do servidor é a rede de trás.
const MAX_PROCURA := 64

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
var _contador: Label
var _lista_res: VBoxContainer
var _guardar: Button
var _comecar: Button
var _estado: Label
var _lista_colocar: VBoxContainer
var _parar: Button
## L5: o esquema de colocação. Cada item: {fichaId, casa: Vector2i}.
var esquema: Array = []
var esquema_ligado := false
var _em_serie := false
var _id_serie := ""
var _botao_esquema: Button
var _esquema_info: Label
var _colocar_esquema: Button
var _limpar_esquema: Button


func montar(m) -> void:
	mestre = m
	var linha := HBoxContainer.new()
	add_child(linha)
	_procura = LineEdit.new()
	_procura.name = "Procura"
	_procura.placeholder_text = Textos.PROCURAR_DICA
	_procura.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_procura.max_length = MAX_PROCURA
	_procura.text_submitted.connect(func(_t): procurar())
	_procura.text_changed.connect(func(_t): _contar())
	linha.add_child(_procura)
	_contador = Label.new()
	_contador.name = "ContadorProcura"
	linha.add_child(_contador)
	_contar()
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
	_botao_esquema = Button.new()
	_botao_esquema.name = "MontarEsquema"
	_botao_esquema.toggle_mode = true
	_botao_esquema.text = Textos.MONTAR_ESQUEMA
	_botao_esquema.toggled.connect(ligar_esquema)
	add_child(_botao_esquema)
	_esquema_info = Label.new()
	_esquema_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_esquema_info)
	_colocar_esquema = Button.new()
	_colocar_esquema.text = Textos.COLOCAR_ESQUEMA
	_colocar_esquema.pressed.connect(colocar_esquema)
	add_child(_colocar_esquema)
	_limpar_esquema = Button.new()
	_limpar_esquema.text = Textos.LIMPAR_ESQUEMA
	_limpar_esquema.pressed.connect(limpar_esquema)
	add_child(_limpar_esquema)
	_desenhar_esquema()


func procurar() -> void:
	_contar()
	var texto := _procura.text.strip_edges()
	if texto.is_empty() or texto.length() > MAX_PROCURA:
		return  # N26-1: o servidor recusaria; nunca se pesquisa '' nem se corta em silêncio
	mestre.pesquisar(texto)


## N26-1: o contador do campo de pesquisa («12/64»).
func _contar() -> void:
	if _contador:
		_contador.text = Textos.CONTADOR_PROCURA % [_procura.text.length(), MAX_PROCURA]


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
	mestre.armou_colocar()  # D-AUD-01: o toque no tabuleiro passa a ser do «Colocar»; o «Mover» do Agir desarma
	a_colocar = ficha_id
	_estado.text = Textos.COLOCAR_ESCOLHER % _nome(ficha_id)
	_parar.visible = true


## Casa tocada no tabuleiro. Devolve true se a aba a usou (estava a colocar).
func colocar(casa: Vector2i) -> bool:
	if a_colocar == "":
		return false
	if esquema_ligado:
		esquema.append({"fichaId": a_colocar, "casa": casa})
		_desenhar_esquema()
		return true
	mestre.enviar("MASTER_PLACE", {"fichaId": a_colocar, "casa": {"x": casa.x, "y": casa.y}, "orientacao": "S"})
	return true


func ligar_esquema(sim: bool) -> void:
	esquema_ligado = sim
	_botao_esquema.set_pressed_no_signal(sim)
	_desenhar_esquema()


## L5: manda o esquema em série (um MASTER_PLACE de cada vez, à espera do recibo).
func colocar_esquema() -> void:
	if esquema.is_empty() or _em_serie:
		return
	_em_serie = true
	_proximo_do_esquema()


func limpar_esquema() -> void:
	if _em_serie:
		return
	esquema.clear()
	_desenhar_esquema()


## Chamado pelo ecrã do Mestre a cada recibo de comando.
func resposta(id: String, recusada: bool) -> void:
	if not _em_serie or id != _id_serie:
		return
	_id_serie = ""
	if recusada:
		_em_serie = false
		_estado.text = Textos.ESQUEMA_PAROU
		_desenhar_esquema()
		return
	esquema.pop_front()
	_proximo_do_esquema()


func em_serie() -> bool:
	return _em_serie


func _proximo_do_esquema() -> void:
	if esquema.is_empty():
		_em_serie = false
		_desenhar_esquema()
		return
	var item: Dictionary = esquema[0]
	var casa: Vector2i = item["casa"]
	_id_serie = mestre.enviar("MASTER_PLACE", {"fichaId": item["fichaId"], "casa": {"x": casa.x, "y": casa.y}, "orientacao": "S"})
	if _id_serie == "":
		_em_serie = false
	_desenhar_esquema()


func _desenhar_esquema() -> void:
	if _esquema_info == null:
		return
	var linhas := PackedStringArray()
	if esquema_ligado:
		linhas.append(Textos.ESQUEMA_LIGADO)
	if not esquema.is_empty():
		linhas.append(Textos.ESQUEMA % esquema.size())
	_esquema_info.text = "\n".join(linhas)
	_colocar_esquema.visible = not esquema.is_empty()
	_colocar_esquema.disabled = _em_serie
	_limpar_esquema.visible = not esquema.is_empty()
	_limpar_esquema.disabled = _em_serie
	if mestre != null and (esquema_ligado or not esquema.is_empty()):
		var casas: Array[Vector2i] = []
		for item in esquema:
			casas.append(item["casa"])
		mestre.destacar(casas)


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
