extends SceneTree
## As peças do §12 do desenho JV3.1 no ecrã do Mestre, com mensagens REAIS do servidor (I0004, 08/11/2026).
##
##   godot --headless --path cliente -s res://testes/pecas_mestre.gd
##
## Fixture: rascunhos/servidor/dados-exemplo/mesa-mestre.json (cenários «mestre», «lobby» e «agir»).
## Confere:
## - a arena 3D desenha uma figura por figura colocada e a casa tocada vira coordenadas da grelha;
## - «Voltar até aqui»: um botão por ponto da L8; escolher NÃO manda; só «Voltar até aqui» manda o
##   MASTER_SUPERVISOR voltar com o ateSeq do ponto;
## - aba Mesa: resultados da pesquisa, «Guardar a mesa» (MASTER_LOBBY_SET), «Começar a batalha» com
##   segundo toque (MASTER_START), «Colocar» + casa no tabuleiro (MASTER_PLACE);
## - aba Agir: modos (MASTER_MODE), «Mover» destaca as casas do servidor e só aceita essas
##   (MASTER_ACT mover), ataques e acções (MASTER_ACT); «Jogo eu» no cartão de IA leva à aba Agir.
## Com MESTRE_COMANDOS=<ficheiro> escreve os comandos montados para o CI os conferir com os schemas.

const CENA := "res://cenas/mestre/mestre.tscn"
const Textos := preload("res://cenas/mestre/textos_mestre.gd")

## Os autoloads (Rede, Estado) não são identificadores num script -s: chegam pela árvore no 1.º quadro.
var _rede: Node
var _estado: Node
var _total := 0
var _falhas := 0
var _comandos: Array = []
var _pesquisas: Array = []
var _contador := 0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		printerr("  FALHA ", nome)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _capturar(tipo: String, campos: Dictionary, revision) -> String:
	_contador += 1
	var id := "cmd-pecas-%d" % _contador
	_comandos.append(_rede.montar_comando_mestre(tipo, campos, revision if revision != null else 0, id))
	return id


func _ultimo() -> Dictionary:
	return _comandos.back() if not _comandos.is_empty() else {}


func _responder(c, cmd: Dictionary) -> void:
	c._ao_resposta(str(cmd.get("cmdId", cmd.get("intentId", ""))), {"type": "ROOM_RECEIPT", "estado": "APLICADA"})


func _correr() -> void:
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var fx = JSON.parse_string(FileAccess.get_file_as_string(p))
	_ok(fx is Dictionary and fx.has("agir") and fx.has("lobby"), "a fixture do servidor tem os cenários «agir» e «lobby»")
	if not (fx is Dictionary and fx.has("agir") and fx.has("lobby")):
		_fim()
		return
	_rede.persistir = false
	_rede.papel = "mestre"
	_rede._room_id = "sala-teste"
	_rede.ultima_vista_mestre = {}
	_rede.cartao_ativo = {}
	var c = (load(CENA) as PackedScene).instantiate()
	c.enviar_fn = _capturar
	c.pedir_vista_fn = func(): pass
	c.pesquisar_fn = func(t): _pesquisas.append(t)
	root.add_child(c)
	await _quadros(3)
	c._aviso_entendido()

	print("== arena 3D ==")
	var vista: Dictionary = fx["agir"]["vista"]
	c.aplicar_vista(vista)
	await _quadros(2)
	var colocadas := 0
	for f in vista["mestre"]["figuras"]:
		if f.get("colocada") == true:
			colocadas += 1
	_ok(c._arena.figuras_desenhadas() == colocadas, "uma figura 3D por figura colocada (%d)" % colocadas)
	_ok(c._arena.casa_de_ponto(c._arena.centro_da_casa(Vector2i(3, 4))) == Vector2i(3, 4), "o centro de uma casa volta à mesma casa")
	_ok(c._arena.largura == int(vista["mapa"]["largura"]) and c._arena.altura == int(vista["mapa"]["altura"]), "a grelha tem o tamanho do mapa")

	print("== «Voltar até aqui» (L8) ==")
	var pontos: Array = vista["pontos"]
	_ok(pontos.size() > 0 and c._aba_registo.pontos_mostrados() == pontos.size(), "um botão por ponto (%d)" % pontos.size())
	var antes := _comandos.size()
	var alvo := int(pontos[1]["journalSeq"]) if pontos.size() > 1 else int(pontos[0]["journalSeq"])
	c._aba_registo.escolher(alvo)
	_ok(_comandos.size() == antes and c._aba_registo._confirmar.visible, "escolher o ponto só pergunta («Voltar até aqui?»)")
	c._aba_registo.confirmar()
	var u := _ultimo()
	_ok(u.get("type") == "MASTER_SUPERVISOR" and u.get("op") == "voltar" and int(u.get("ateSeq", -1)) == alvo,
		"«Voltar até aqui» → MASTER_SUPERVISOR voltar ateSeq %d" % alvo)
	_responder(c, u)

	print("== aba Agir ==")
	var opcoes: Dictionary = fx["agir"]["opcoes"]
	_estado.limpar()
	_estado.tem_snapshot = true
	_rede._ao_receber(JSON.stringify(opcoes))
	c.aplicar_vista(vista)
	await _quadros(1)
	var botoes: Array = c._aba_agir.botoes_de_accao()
	var esperados := 1 + opcoes["ataques"].size() + opcoes["acoes"].size()  # Mover + ataques + acções
	_ok(botoes.size() == esperados, "um botão por opção do servidor (%d)" % esperados)
	c._aba_agir.escolher_modo("semi")
	u = _ultimo()
	_ok(u.get("type") == "MASTER_MODE" and u.get("modo") == "semi" and u.get("figuraId") == vista["vezId"], "modo → MASTER_MODE")
	_responder(c, u)
	c._aba_agir.iniciar_mover()
	_ok(c._arena.casas_destacadas().size() == opcoes["mover"].size(), "«Mover» destaca as %d casas do servidor" % opcoes["mover"].size())
	antes = _comandos.size()
	c.casa_tocada(Vector2i(19, 19))
	_ok(_comandos.size() == antes, "uma casa fora das opções não manda nada")
	var destino := Vector2i(int(opcoes["mover"][0]["x"]), int(opcoes["mover"][0]["y"]))
	c.casa_tocada(destino)
	u = _ultimo()
	_ok(u.get("type") == "MASTER_ACT" and u.get("acao", {}).get("tipo") == "mover"
		and int(u["acao"]["destino"]["x"]) == destino.x and int(u["acao"]["destino"]["y"]) == destino.y, "tocar numa casa → MASTER_ACT mover")
	_ok(c._arena.casas_destacadas().is_empty(), "depois de mover os destaques saem")
	_responder(c, u)
	if not opcoes["ataques"].is_empty():
		var a: Dictionary = opcoes["ataques"][0]
		c._aba_agir.agir({"tipo": "atacar", "alvoId": a["alvoId"], "arma": a["arma"]})
		u = _ultimo()
		_ok(u.get("type") == "MASTER_ACT" and u.get("acao", {}).get("tipo") == "atacar", "ataque → MASTER_ACT atacar")
		_responder(c, u)
	c._aba_agir.agir({"tipo": "encerrar"})
	u = _ultimo()
	_ok(u.get("type") == "MASTER_ACT" and u.get("acao", {}).get("tipo") == "encerrar", "«Encerrar a vez» → MASTER_ACT encerrar")
	_responder(c, u)
	var rotulos: Array = []
	for b in c._aba_agir.botoes_de_accao():
		rotulos.append(b.text)
	_ok(rotulos.has(Textos.MOVER) and rotulos.has(Textos.NOME_ACAO["encerrar"]), "rótulos com as palavras da casa %s" % [rotulos])

	print("== «Jogo eu» leva à aba Agir ==")
	_rede._ao_receber(JSON.stringify(fx["mestre"]["cartoes"]["ia"]))
	await _quadros(1)
	c._abas.current_tab = 0
	c.tocar("jogo_eu")
	c.tocar("jogo_eu")
	_ok(c._abas.get_tab_control(c._abas.current_tab) == c._aba_agir.get_parent(), "depois de «Jogo eu» a aba Agir fica à frente")
	_responder(c, _ultimo())

	print("== aba Mesa ==")
	var lobby_vista: Dictionary = fx["lobby"]["vista"]
	c.aplicar_vista(lobby_vista)
	c._aba_mesa.procurar()
	_ok(_pesquisas.size() == 1, "«Procurar» pede a pesquisa ao servidor")
	_rede._ao_receber(JSON.stringify(fx["lobby"]["resultados"]))
	await _quadros(1)
	var caixas: Array = []
	for n in c._aba_mesa._lista_res.get_children():
		if n is CheckBox and not n.is_queued_for_deletion():
			caixas.append(n)
	var res: Array = fx["lobby"]["resultados"]["resultados"]
	_ok(caixas.size() == res.size(), "uma linha por resultado (%d)" % res.size())
	var marcadas := caixas.filter(func(x): return x.button_pressed)
	_ok(marcadas.size() == 3, "as fichas já na mesa vêm marcadas (3)")
	_ok(caixas.any(func(x): return x.text.contains("Orc Verdadeiro Teste (Orc)")), "o Mestre vê o nome verdadeiro e o público")
	c._aba_mesa.marcar(false, "lobo-teste")
	c._aba_mesa.guardar()
	u = _ultimo()
	_ok(u.get("type") == "MASTER_LOBBY_SET" and u.get("criaturasDisponiveis") == ["orc-teste"] and u.get("npcsDisponiveis") == ["bandido-teste"],
		"«Guardar a mesa» → MASTER_LOBBY_SET com o que está marcado")
	_responder(c, u)
	antes = _comandos.size()
	c._aba_mesa.comecar()
	_ok(_comandos.size() == antes, "«Começar a batalha» pede o segundo toque")
	c._aba_mesa.comecar()
	_ok(_ultimo().get("type") == "MASTER_START", "segundo toque → MASTER_START")
	_responder(c, _ultimo())
	antes = _comandos.size()
	c.casa_tocada(Vector2i(5, 5))
	_ok(_comandos.size() == antes, "sem ficha escolhida, tocar no tabuleiro não coloca nada")
	c._aba_mesa.escolher_colocar("orc-teste")
	_ok(c._aba_mesa._estado.text.contains("Aparece à Party"), "o «Colocar» avisa que a figura aparece à Party")
	c.casa_tocada(Vector2i(5, 6))
	u = _ultimo()
	_ok(u.get("type") == "MASTER_PLACE" and u.get("fichaId") == "orc-teste" and int(u["casa"]["x"]) == 5 and int(u["casa"]["y"]) == 6,
		"casa no tabuleiro → MASTER_PLACE")
	_responder(c, u)
	c._aba_mesa.parar()
	_ok(c._aba_mesa.a_colocar == "", "«Parar de colocar»")

	var todos: Array = []
	_textos(c, todos)
	var proibidas := todos.filter(func(t): return t.to_lower().contains("prime") or t.to_lower().contains("carreg"))
	_ok(proibidas.is_empty(), "nenhum texto visível com «prime» ou «carregar» %s" % [proibidas])

	var saida := OS.get_environment("MESTRE_COMANDOS")
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		for m in _comandos:
			f.store_line(JSON.stringify(m))
		f.close()
		print("comandos escritos em ", saida, ": ", _comandos.size())
	c.queue_free()
	await _quadros(1)
	_fim()


func _textos(no: Node, saida: Array) -> void:
	if no is Label or no is Button:
		if (no as CanvasItem).is_visible_in_tree():
			saida.append(no.text)
	for f in no.get_children():
		_textos(f, saida)


func _fim() -> void:
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)
