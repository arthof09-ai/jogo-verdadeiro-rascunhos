extends SceneTree
## Abre o ecrã do Mestre sem janela e confere-o com mensagens REAIS do servidor (I0004, 08/11/2026).
##
##   godot --headless --path cliente -s res://testes/abrir_mestre.gd
##
## A fixture vem do servidor (rascunhos/servidor/dados-exemplo/mesa-mestre.json, gerada e conferida
## por servidor/testes/fixture-mestre.test.mjs). Confere:
## - recusa abrir para quem não é Mestre (desenho §7 b);
## - pede a vista ao abrir; mostra todas as figuras com vida e PA a/b (L1), o ambiente, o cartão;
## - os 4 tipos de cartão: botões com as palavras do site (emenda 1) e o comando certo de cada um;
##   «Escolher outra» só da lista do cartão (L2); os toques de confirmação dupla;
## - nada se decide por tempo; um cartão reaberto não se duplica; o aviso da 1.ª entrada (emenda 2);
## - nenhum texto visível com «prime» ou «carregar».
## Com MESTRE_COMANDOS=<ficheiro>, escreve os comandos montados (um JSON por linha) para o CI os
## conferir contra os schemas do protocolo v2. Código de saída 0 se tudo passa, 1 se algo falha.

const CENA := "res://cenas/mestre/mestre.tscn"
const Textos := preload("res://cenas/mestre/textos_mestre.gd")

var _total := 0
var _falhas := 0
var _comandos: Array = []
var _pedidos_vista := 0
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


func _fixture() -> Dictionary:
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var t := FileAccess.get_file_as_string(p)
	var d = JSON.parse_string(t)
	return d if d is Dictionary else {}


func _capturar(tipo: String, campos: Dictionary, revision) -> String:
	_contador += 1
	var id := "cmd-teste-%d" % _contador
	_comandos.append(Rede.montar_comando_mestre(tipo, campos, revision if revision != null else 0, id))
	return id


func _textos(no: Node, saida: Array) -> void:
	if no is Label or no is Button:
		if (no as CanvasItem).is_visible_in_tree():
			saida.append(no.text)
	for f in no.get_children():
		_textos(f, saida)


func _receber(msg: Dictionary) -> void:
	Rede._ao_receber(JSON.stringify(msg))


func _correr() -> void:
	var fx := _fixture()
	_ok(not fx.is_empty(), "a fixture do servidor lê-se")
	if fx.is_empty():
		_fim()
		return
	Rede.persistir = false
	Rede._room_id = "sala-teste"
	var ps := load(CENA) as PackedScene
	_ok(ps != null, "a cena do Mestre carrega")

	print("== recusa noutro papel ==")
	Rede.papel = "jogadora"
	var r = ps.instantiate()
	root.add_child(r)
	await _quadros(3)
	_ok(not is_instance_valid(r), "com o papel jogadora a cena recusa e sai")

	print("== Mestre ==")
	Rede.papel = "mestre"
	Rede.ultima_vista_mestre = {}
	Rede.cartao_ativo = {}
	var c = ps.instantiate()
	c.enviar_fn = _capturar
	c.pedir_vista_fn = func(): _pedidos_vista += 1
	root.add_child(c)
	await _quadros(3)
	_ok(is_instance_valid(c) and not c.recusado, "com o papel mestre a cena abre")
	_ok(_pedidos_vista >= 1, "pede a MASTER_VIEW ao abrir")
	_ok(c._aviso_primeira.visible, "aviso da 1.ª entrada visível fora da batalha")
	c._aviso_entendido()
	_ok(not c._aviso_primeira.visible, "«Entendido» esconde o aviso")

	var vista: Dictionary = fx["mestre"]["vista"]
	_receber(vista)
	await _quadros(2)
	var linhas: Array = []
	for l in c._lista_figuras.get_children():
		linhas.append(l.text)
	_ok(linhas.size() == vista["mestre"]["figuras"].size(), "uma linha por figura do Mestre (%d)" % linhas.size())
	var com_orc := linhas.filter(func(t): return t.contains("Orc Verdadeiro Teste (Orc)") and t.contains("vida 7777/7777") and t.contains("PA 313/313"))
	_ok(com_orc.size() == 1, "o orc com nome verdadeiro, vida a/b e PA a/b (L1)")
	var com_her := linhas.filter(func(t): return t.contains("Heroína Teste") and t.contains("/5150"))
	_ok(com_her.size() == 1, "a heroína com a vida total")
	var amb: Array = []
	for l in c._lista_ambiente.get_children():
		amb.append(l.text)
	_ok(amb.has("Hora: 03:33") and amb.any(func(t): return t.begins_with("A Party vê: ")), "ambiente: hora exacta e o que a Party vê")

	# Cartão de desgraça.
	var desg: Dictionary = fx["mestre"]["cartoes"]["desgraca"]
	_receber(desg)
	await _quadros(2)
	_ok(c._titulo_cartao.text == Textos.TITULO["desgraca"], "título do cartão de desgraça")
	_ok(c._texto_cartao.text.contains("A Party vai ler: «Falha crítica · "), "mostra a frase que a Party vai ler")
	var rot: Array = []
	for b in c._botoes:
		if b.visible:
			rot.append(b.text)
	_ok(rot == [Textos.CONFIRMAR, Textos.ESCOLHER_OUTRA, Textos.SEM_DESGRACA], "botões: %s" % [rot])

	await _quadros(120)
	_ok(_comandos.is_empty(), "nada se decide por tempo (120 quadros, zero comandos)")

	c.tocar("sem_desgraca")
	_ok(_comandos.is_empty() and c._botoes[2].text == Textos.DE_NOVO_PARA % Textos.SEM_DESGRACA, "«Sem desgraça» pede o segundo toque")
	c._armado = ""
	c.tocar("escolher")
	_ok(c._escolha.visible, "«Escolher outra» abre a lista por cima da coluna 2")
	var escolhas: Array = []
	for n in c._lista_escolha.get_children():
		if n is Button and n.has_meta("desgraca"):
			escolhas.append(n.get_meta("desgraca"))
	_ok(escolhas == desg["desgracas"], "a lista é a do cartão (L2)")
	c.escolher("voar")
	_ok(_comandos.is_empty(), "uma desgraça fora da lista não sai")
	c.escolher("cai")
	var ult: Dictionary = _comandos.back() if not _comandos.is_empty() else {}
	_ok(ult.get("type") == "MASTER_APPROVE" and ult.get("decisao") == "editar" and ult.get("edicao", {}).get("desgraca") == "cai",
		"editar → MASTER_APPROVE editar {desgraca: cai}")
	c.tocar("confirmar")
	_ok(_comandos.size() == 1, "com um comando em voo, os botões não mandam outro")
	c._ao_resposta(ult.get("cmdId", ""), {"type": "ROOM_RECEIPT", "estado": "APLICADA"})
	c.tocar("confirmar")
	ult = _comandos.back()
	_ok(ult.get("type") == "MASTER_APPROVE" and ult.get("decisao") == "aprovar", "Confirmar → MASTER_APPROVE aprovar")
	c._ao_resposta(ult.get("cmdId", ""), {"type": "ROOM_REJECT", "motivo": "acao_invalida", "texto": "Essa acção não é possível."})
	_ok(c._alerta.text.contains("Essa acção não é possível."), "a recusa do servidor vai para os alertas")

	_receber(desg)
	_receber(desg)
	await _quadros(1)
	_ok(not c._fila.visible, "o mesmo cartão a chegar outra vez não se duplica")

	# Cartão de IA.
	_receber(fx["mestre"]["cartoes"]["ia"])
	await _quadros(1)
	_ok(c._titulo_cartao.text == Textos.TITULO["ia"] and c._texto_cartao.text.contains("Razão: "), "cartão de IA com a razão")
	_ok(c._botoes[1].disabled, "«Escolher outra» da IA desligado até à aba Agir")
	var antes := _comandos.size()
	c.tocar("jogo_eu")
	c.tocar("jogo_eu")
	ult = _comandos.back()
	_ok(_comandos.size() == antes + 1 and ult.get("decisao") == "recusar", "«Jogo eu» (dois toques) → recusar")
	c._ao_resposta(ult.get("cmdId", ""), {"type": "ROOM_RECEIPT", "estado": "APLICADA"})

	# Cartão de dados.
	var dados: Dictionary = fx["mestre"]["cartoes"]["dados"]
	_receber(dados)
	await _quadros(1)
	c.tocar("aceitar_dados")
	ult = _comandos.back()
	_ok(ult.get("type") == "MASTER_CONFIRM_DICE" and ult.get("aceitar") == true and ult.get("intentId") == dados["intentIdOrigem"],
		"dados: Confirmar → MASTER_CONFIRM_DICE aceitar")
	c._ao_resposta(ult.get("cmdId", ""), {"type": "ROOM_RECEIPT", "estado": "APLICADA"})

	# Cartão de progresso (a forma do MASTER_CARD, com o texto que o servidor usa).
	var prog := {"v": 2, "type": "MASTER_CARD", "roomId": "sala-teste", "cartaoId": "c9", "tipo": "progresso",
		"figuraId": desg["figuraId"], "proposta": {"tipo": "encerrar"}, "razao": "Duas recusas neste turno.", "faces": null,
		"intentIdOrigem": null, "desgracas": null}
	_receber(prog)
	await _quadros(1)
	c.tocar("encerrar")
	ult = _comandos.back()
	_ok(ult.get("cartaoId") == "c9" and ult.get("decisao") == "aprovar", "progresso: «Encerrar a vez» → aprovar")
	c._ao_resposta(ult.get("cmdId", ""), {"type": "ROOM_RECEIPT", "estado": "APLICADA"})

	# Fecho do cartão pelo evento.
	_receber({"v": 2, "type": "ROOM_EVENT", "roomId": "sala-teste", "seq": 999, "revision": 99, "ts": "2026-11-08T00:00:00Z",
		"tipo": "cartao_fechado", "dados": {"cartaoId": "c9", "decisao": "aprovar"}})
	await _quadros(1)
	_ok(c._titulo_cartao.text == Textos.SEM_CARTAO, "o cartão sai quando o servidor o fecha")

	# Palavras (emenda 1).
	var todos: Array = []
	_textos(c, todos)
	var proibidas := todos.filter(func(t): return t.to_lower().contains("prime") or t.to_lower().contains("carreg"))
	_ok(proibidas.is_empty(), "nenhum texto visível com «prime» ou «carregar» %s" % [proibidas])

	# O aviso não volta (emenda 2).
	c.queue_free()
	await _quadros(1)
	var c2 = ps.instantiate()
	c2.enviar_fn = _capturar
	c2.pedir_vista_fn = func(): pass
	root.add_child(c2)
	await _quadros(2)
	_ok(not c2._aviso_primeira.visible, "o aviso da 1.ª entrada não volta depois de «Entendido»")
	c2.queue_free()

	var saida := OS.get_environment("MESTRE_COMANDOS")
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		for m in _comandos:
			f.store_line(JSON.stringify(m))
		f.close()
		print("comandos escritos em ", saida, ": ", _comandos.size())
	_fim()


func _fim() -> void:
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)
