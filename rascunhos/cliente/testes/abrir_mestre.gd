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
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")

var _total := 0
var _falhas := 0
var _comandos: Array = []
var _pedidos_vista := 0
var _contador := 0


## Os autoloads (Rede, Estado) não são identificadores num script -s: chegam pela árvore no 1.º quadro.
var _rede: Node
var _estado: Node


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
	_comandos.append(_rede.montar_comando_mestre(tipo, campos, revision if revision != null else 0, id))
	return id


func _textos(no: Node, saida: Array) -> void:
	if no is Label or no is Button:
		if (no as CanvasItem).is_visible_in_tree():
			saida.append(no.text)
	for f in no.get_children():
		_textos(f, saida)


func _receber(msg: Dictionary) -> void:
	_rede._ao_receber(JSON.stringify(msg))


func _correr() -> void:
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	var fx := _fixture()
	_ok(not fx.is_empty(), "a fixture do servidor lê-se")
	if fx.is_empty():
		_fim()
		return
	_rede.persistir = false
	_rede._room_id = "sala-teste"
	var ps := load(CENA) as PackedScene
	_ok(ps != null, "a cena do Mestre carrega")

	print("== recusa noutro papel ==")
	_rede.papel = "jogadora"
	var r = ps.instantiate()
	root.add_child(r)
	await _quadros(3)
	_ok(not is_instance_valid(r), "com o papel jogadora a cena recusa e sai")

	print("== Mestre ==")
	_rede.papel = "mestre"
	_rede.ultima_vista_mestre = {}
	_rede.cartao_ativo = {}
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
	# ORDEM-PLANO-2-F1 (D-AUD-12): a criatura colocada tem número no nome verdadeiro e no público (a fixture do servidor).
	var com_orc := linhas.filter(func(t): return t.contains("Orc Verdadeiro Teste 1 (Orc 1)") and t.contains("vida 7777/7777") and t.contains("PA 313/313"))
	_ok(com_orc.size() == 1, "o orc com nome verdadeiro e número, vida a/b e PA a/b (L1, D-AUD-12)")
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
	_ok(rot == [Textos.CONFIRMAR, Textos.ESCOLHER_OUTRA], "botões (sem «Sem desgraça»: no site a rolagem não se deita fora): %s" % [rot])

	await _quadros(120)
	_ok(_comandos.is_empty(), "nada se decide por tempo (120 quadros, zero comandos)")

	c.tocar("sem_desgraca")
	_ok(_comandos.is_empty(), "recusar a desgraça não existe (regra-mãe: vale o site)")
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
	_ok(c._botoes[0].text == Textos.CONTINUAR_RODADA, "marcha pura: o primeiro botão é «Continuar a rodada» (L6)")
	_ok(not c._botoes[1].disabled, "«Escolher outra» da IA ligado (L10)")
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

	# Q12: a escolha do amigo no «acerta-amigo» (só com mais de um amigo elegível).
	var ids: Array = []
	for f in vista["mestre"]["figuras"]:
		ids.append(f["id"])
	var desg2: Dictionary = desg.duplicate(true)
	desg2["cartaoId"] = "c-amigo"
	desg2["amigos"] = [ids[1], ids[0]]
	_ok((desg2["desgracas"] as Array).has("acerta-amigo"), "a lista do cartão tem o «acerta-amigo»")
	_receber(desg2)
	await _quadros(1)
	var n_antes := _comandos.size()
	c.tocar("escolher")
	c.escolher("acerta-amigo")
	var amigos_lista: Array = []
	for n in c._lista_escolha.get_children():
		if n is Button and n.has_meta("amigo") and not n.is_queued_for_deletion():
			amigos_lista.append(n.get_meta("amigo"))
	_ok(_comandos.size() == n_antes and amigos_lista == [ids[1], ids[0]], "com dois amigos, «Acerta um amigo» pergunta qual (do mais perto) %s" % [amigos_lista])
	c.escolher_amigo("nao-e-amigo")
	_ok(_comandos.size() == n_antes, "um amigo fora da lista do cartão não sai")
	c.escolher_amigo(ids[0])
	ult = _comandos.back()
	_ok(ult.get("decisao") == "editar" and ult.get("edicao") == {"desgraca": "acerta-amigo", "aliadoAtingidoId": ids[0]},
		"o amigo escolhido → MASTER_APPROVE editar {acerta-amigo, aliadoAtingidoId}")
	c._ao_resposta(ult.get("cmdId", ""), {"type": "ROOM_RECEIPT", "estado": "APLICADA"})
	var desg3: Dictionary = desg.duplicate(true)
	desg3["cartaoId"] = "c-um-amigo"
	desg3["amigos"] = [ids[0]]
	_receber(desg3)
	await _quadros(1)
	c.escolher("acerta-amigo")
	ult = _comandos.back()
	_ok(ult.get("cartaoId") == "c-um-amigo" and ult.get("edicao") == {"desgraca": "acerta-amigo"}, "com um só amigo, não há pergunta (vale o mais perto)")
	c._ao_resposta(ult.get("cmdId", ""), {"type": "ROOM_RECEIPT", "estado": "APLICADA"})

	# Ordem 8 (item 5; site REF_34): ao recusar a proposta, «Não acontece nada» no fim da lista — só do Mestre.
	var desg4: Dictionary = desg.duplicate(true)
	desg4["cartaoId"] = "c-nada"
	_receber(desg4)
	await _quadros(1)
	c.tocar("escolher")
	var vivos: Array = []
	for n in c._lista_escolha.get_children():
		if n is Button and not n.is_queued_for_deletion():
			vivos.append(n)
	var nada_btn: Button = null
	for b in vivos:
		if b.has_meta("sem_desgraca"):
			nada_btn = b
	_ok(nada_btn != null and nada_btn.text == Textos.NAO_ACONTECE_NADA, "a lista do «Escolher outra» tem «Não acontece nada»")
	_ok(vivos.size() >= 2 and vivos[vivos.size() - 2] == nada_btn and vivos.back().text == Textos.VOLTAR,
		"«Não acontece nada» fica depois das desgraças da tabela e antes do «Voltar»")
	_ok(nada_btn != null and not nada_btn.has_meta("desgraca"), "não é uma linha da tabela")
	var n_nada := _comandos.size()
	if nada_btn != null:
		nada_btn.pressed.emit()
	ult = _comandos.back()
	_ok(_comandos.size() == n_nada + 1 and ult.get("type") == "MASTER_APPROVE" and ult.get("cartaoId") == "c-nada"
		and ult.get("decisao") == "recusar" and ult.get("edicao") == {"semDesgraca": true},
		"«Não acontece nada» → MASTER_APPROVE recusar {semDesgraca: true}")
	_ok(not c._escolha.visible, "a lista fecha depois da escolha")
	c._ao_resposta(ult.get("cmdId", ""), {"type": "ROOM_RECEIPT", "estado": "APLICADA"})
	_ok(Modelo.comando(prog, "nada").is_empty(), "noutro cartão (progresso) o «nada» não manda nada")

	# Ordem 8 (item 8): mudar a escala na aba Sala — só do Mestre, com segundo toque.
	c.aplicar_vista(vista)
	_ok(c._escala_rotulo.text == Textos.ESCALA_ATUAL % "1,5", "a aba Sala mostra a escala actual (%s)" % c._escala_rotulo.text)
	_ok(c._escala_mudar.disabled, "com a mesma escala, «Mudar a escala» fica desligado")
	var n_esc := _comandos.size()
	c.ajustar_escala(3)
	_ok(is_equal_approx(c.escala_nova, 2.0) and not c._escala_mudar.disabled and c._escala_mais.disabled,
		"+ três vezes: pára em 2 m por casa (ordem 11: só 1 / 1,5 / 2)")
	c.pedir_escala()
	_ok(_comandos.size() == n_esc and c._escala_mudar.text == Textos.SIM_MUDAR_ESCALA % "2", "primeiro toque: só pede confirmação («%s»)" % c._escala_mudar.text)
	c.pedir_escala()
	ult = _comandos.back()
	_ok(_comandos.size() == n_esc + 1 and ult.get("type") == "MASTER_SUPERVISOR" and ult.get("op") == "escala"
		and is_equal_approx(float(ult.get("casaM", 0.0)), 2.0), "segundo toque → MASTER_SUPERVISOR escala {casaM: 2}")
	c._ao_resposta(ult.get("cmdId", ""), {"type": "ROOM_RECEIPT", "estado": "APLICADA"})
	for i in 10:
		c.ajustar_escala(-1)
	_ok(is_equal_approx(c.escala_nova, 1.0) and c._escala_menos.disabled, "a escala do ecrã não desce de 1 m (ordem 11)")
	c.ajustar_escala(1)
	_ok(is_equal_approx(c.escala_nova, 1.5), "− e + andam só pelos valores que valem: 1 → 1,5")

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

	# Ordem 35 (trabalho 2): a ponta a ponta falhou uma vez no CI (run 43342487508, tentativa 1) porque o pedido da
	# MASTER_VIEW de depois do «voltar» foi o 11.º envio em menos de 1 s: o limite do aparelho (10/s, §2) deitou-o fora
	# e ninguém o voltou a pedir. O pedido que não sai tem de voltar a ser feito.
	print("== o pedido da vista que não saiu volta a ser pedido (ordem 35) ==")
	_rede.papel = "mestre"
	_rede.estado_ligacao = _rede.Ligacao.NA_MESA
	var agora := Time.get_ticks_msec()
	_rede._envios_recentes.clear()
	for i in _rede.LIMITE_COMANDOS_POR_S:
		_rede._envios_recentes.append(agora)
	_ok(_rede.pedir_vista_mestre() == false, "com a janela de 10 envios/s cheia, a Rede diz que o pedido da vista não saiu")
	_ok(_rede._envios_recentes.size() == _rede.LIMITE_COMANDOS_POR_S, "e não gastou mais nada da janela")
	_rede._envios_recentes.clear()
	_rede.estado_ligacao = _rede.Ligacao.DESLIGADA
	var tentativas := [0]
	var c3 = ps.instantiate()
	c3.enviar_fn = _capturar
	c3.pedir_vista_fn = func():
		tentativas[0] += 1
		return tentativas[0] >= 3  # ao abrir e na 1.ª nova tentativa o limite não deixa sair
	root.add_child(c3)
	await create_timer(1.2).timeout
	_ok(tentativas[0] == 3, "ao abrir: o pedido que não saiu volta a ser feito até sair (%d pedidos)" % tentativas[0])
	_ok(c3._espera_vista < 0.0, "depois de sair, não há mais pedidos à espera")
	tentativas[0] = 1
	c3._pedir_vista_em_breve()  # como depois de um evento (o «revertido»)
	await create_timer(1.2).timeout
	_ok(tentativas[0] == 3, "depois de um evento: o pedido que não saiu volta a ser feito até sair (%d pedidos)" % tentativas[0])
	_ok(c3._espera_vista < 0.0, "e pára quando sai")
	c3.queue_free()

	# Ordem 49 (A, achado leve da Ordem 35): a nova tentativa não tinha tecto — com o pedido a falhar sempre, voltava
	# a pedir para sempre, de 0,25 s em 0,25 s. Agora pára ao fim de TENTATIVAS_VISTA_MAX com a falha nomeada. O relógio
	# anda à mão (`_process` chamado aqui, com o do quadro desligado), para não esperar 10 s de verdade.
	print("== o pedido da vista tem tecto e, ao fim dele, uma falha nomeada (ordem 49) ==")
	var tecto := int((load("res://cenas/mestre/mestre.gd") as Script).get_script_constant_map().get("TENTATIVAS_VISTA_MAX", -1))
	_ok(tecto == 40, "o tecto é de 40 tentativas (40 × 0,25 s = 10 s): %d" % tecto)
	var nunca := [0]
	var c4 = ps.instantiate()
	c4.enviar_fn = _capturar
	c4.pedir_vista_fn = func():
		nunca[0] += 1
		return false  # falha permanente: o limite (ou fora da mesa) nunca deixa sair
	root.add_child(c4)  # o _ready faz o 1.º pedido
	c4.set_process(false)
	var alertas_antes: int = c4.alertas.size()
	for i in 200:  # 50 s de relógio
		c4._process(0.26)
	_ok(nunca[0] == 40, "falha permanente: a nova tentativa pára no tecto (%d pedidos; sem tecto seriam 201)" % nunca[0])
	_ok(c4._espera_vista < 0.0, "ao fim do tecto não fica nenhum pedido à espera (nem ciclo)")
	_ok(c4.get("falha_vista") == "vista_sem_pedido", "ao fim do tecto a falha tem nome: «%s»" % c4.get("falha_vista"))
	var texto_falha = Textos.ALERTA.get("vista_sem_pedido")
	_ok(texto_falha != null and c4.alertas.size() == alertas_antes + 1 and c4.alertas[-1] == texto_falha % 40,
		"e vai ao Mestre num alerta, um só: %s" % [c4.alertas.slice(alertas_antes)])
	nunca[0] = 0
	c4._pedir_vista_em_breve()  # um evento depois do tecto
	for i in 20:
		c4._process(0.26)
	_ok(nunca[0] == 1 and c4.alertas.size() == alertas_antes + 1,
		"depois do tecto, um evento dá-lhe uma tentativa só e nenhum alerta novo (%d pedidos)" % nunca[0])
	nunca[0] = 0
	c4._pedir_vista_agora()  # «Atualizar»: a conta recomeça
	for i in 200:
		c4._process(0.26)
	_ok(nunca[0] == 40 and c4.alertas.size() == alertas_antes + 2,
		"«Atualizar» recomeça a conta: outra vez 40 pedidos e o alerta (%d pedidos)" % nunca[0])
	c4.pedir_vista_fn = func():
		nunca[0] += 1
		return nunca[0] >= 40  # sai mesmo no último antes do tecto
	nunca[0] = 0
	c4._pedir_vista_agora()
	for i in 200:
		c4._process(0.26)
	_ok(nunca[0] == 40 and c4.get("falha_vista") == "" and c4._espera_vista < 0.0 and c4.alertas.size() == alertas_antes + 2,
		"o pedido que sai na 40.ª tentativa chega: sem falha, sem alerta (%d pedidos)" % nunca[0])
	c4.pedir_vista_fn = func():
		nunca[0] += 1
		return true
	nunca[0] = 0
	c4._pedir_vista_agora()
	for i in 20:
		c4._process(0.26)
	_ok(nunca[0] == 1 and c4.get("falha_vista") == "", "o pedido que sai à 1.ª: um pedido só, sem falha (%d)" % nunca[0])
	c4.queue_free()

	# Ordem 54: a arena do Mestre abre depressa outra vez. Abriu-se o ecrã do Mestre quatro vezes (c, c2, c3, c4), sempre
	# na mesma grelha: o mapa da floresta construiu-se só na 1.ª e as outras três vestiram-se do molde dela
	# (mapa/floresta/molde_floresta.gd; a prova de que o mapa vestido é o mesmo está em pecas_mestre.gd).
	print("== o mapa da mesma grelha não se constrói outra vez (ordem 54) ==")
	var Molde = load("res://mapa/floresta/molde_floresta.gd")
	_ok(int(Molde.contas["guardados"]) == 1 and int(Molde.contas["vestidos"]) == 3,
		"4 aberturas do ecrã do Mestre: 1 mapa construído, 3 vestidos do molde (%s)" % [Molde.contas])

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
