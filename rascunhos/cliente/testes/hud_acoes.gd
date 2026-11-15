extends SceneTree
## As acções da jogadora ONDE O SITE AS TEM (I0004, 08/11/2026; jogo.js renderAcoes, lido no site vivo):
## - a barra de baixo continua Ataque · Mover · Consumível (e Encerrar) — regra do Mestre;
## - no modo Mover: «Sair c/ segurança» (a intenção do Desvincular, que se gasta na partida) e «Correr»;
## - na gaveta do Ataque: «Transformação · N PA», com Confirmar;
## - no chip «FICHA ▸», secção Reacção: «Declarar Defender»;
## - ordem 15: na gaveta do Mover, «Apagar o fogo» (a arder sem chuva; o servidor oferece `apagar_fogo`).
##
##   godot --headless --path cliente -s res://testes/hud_acoes.gd
##
## Código de saída 0 se tudo passa, 1 se algo falha.

## Os modos da arena (cenas/arena/arena.gd `enum Modo`): sem preload, porque a arena usa os autoloads, que num
## script -s ainda não são identificadores na hora de compilar.
var Modo: Dictionary = {}

var _rede: Node
var _estado: Node
var _total := 0
var _falhas := 0
var _pedidas: Array = []


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


func _opcoes(acoes: Array, rev: int = 5) -> void:
	_estado.receber_opcoes({"v": 2, "type": "ROOM_OPTIONS", "revision": rev, "vezId": "fA", "orcamentoM": 9.0,
		"mover": [{"x": 2, "y": 3, "custoM": 1.5}], "ataques": [], "consumiveis": [], "acoes": acoes, "reacoes": []})


func _correr() -> void:
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	_rede.persistir = false
	_rede.papel = "jogadora"
	_rede.estado_ligacao = _rede.Ligacao.NA_MESA
	_estado.aplicar_snapshot({
		"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "sala-teste", "seq": 1, "revision": 5, "fase": "combate",
		"mapa": {"largura": 20, "altura": 20}, "iniciativa": ["fA", "fB"], "vezId": "fA", "rodada": 1, "ambiente": {},
		"figuras": [
			{"id": "fA", "nomePublico": "Ong", "lado": "jogadora", "x": 2, "y": 2},
			{"id": "fB", "nomePublico": "Lobo", "lado": "criatura", "x": 3, "y": 2},
		],
		"propria": {"figuraId": "fA", "paLivre": 40, "estadoMorte": null, "ficha": {"transformacao": {"custo": 12}}},
	})
	var hud = (load("res://hud/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	Modo = hud.Arena.Modo
	await _quadros(2)
	hud.acao_pedida.connect(func(a): _pedidas.append(a))
	var modos: Array = []
	hud.modo_pedido.connect(func(m, _e): modos.append(m))

	print("== a barra de baixo não muda ==")
	_opcoes(["encerrar", "correr", "defender", "desvincular", "transformar"])
	await _quadros(1)
	var nomes: Array = []
	for b in hud._barra.get_children():
		nomes.append(str(b.name))
	_ok(nomes == ["BotaoAtaque", "BotaoMover", "BotaoConsumivel", "BotaoEncerrar"], "a barra continua Ataque, Mover, Consumível e Encerrar %s" % [nomes])
	_ok(not hud._gaveta.visible, "sem modo, não há gaveta")

	print("== modo Mover: «Sair c/ segurança» e «Correr» ==")
	hud._ao_botao(Modo.MOVER)
	await _quadros(1)
	_ok(hud._gaveta.visible and hud._g_seguranca.visible and hud._g_correr.visible and not hud._g_transformar.visible,
		"a gaveta do Mover tem «Sair c/ segurança» e «Correr» (e não a Transformação)")
	hud._g_seguranca.pressed.emit()
	_ok(hud.sair_com_seguranca and hud._g_seguranca.text.ends_with("✓") and _pedidas.is_empty(),
		"«Sair c/ segurança» é uma declaração: liga sem mandar nada ao servidor")
	hud._g_seguranca.pressed.emit()
	_ok(not hud.sair_com_seguranca, "e desliga outra vez")
	hud._g_correr.pressed.emit()
	_ok(_pedidas.size() == 1 and _pedidas[0] == {"tipo": "correr"}, "«Correr» manda a intenção correr")
	hud._ao_recibo("x", "APLICADA", {})
	_opcoes(["encerrar", "defender"], 6)
	await _quadros(1)
	_ok(hud._a_correr and hud._g_correr.text.ends_with("A correr ✓") and hud._g_correr.disabled, "depois de correr: «A correr ✓», como no site")
	_ok(modos.back() == Modo.MOVER, "e volta ao modo Mover com o orçamento novo")

	print("== gaveta do Ataque: Transformação ==")
	_opcoes(["encerrar", "transformar"], 7)
	hud.fechar_gaveta()
	hud.ao_modo_mudou(Modo.NENHUM)
	await _quadros(1)
	_ok(not hud._b_ataque.disabled, "o Ataque abre mesmo sem alvos, quando há Transformação")
	hud._ao_botao(Modo.ATAQUE)
	await _quadros(1)
	_ok(hud._g_transformar.visible and hud._g_transformar.text == "✦ Transformação · 12 PA" and not hud._g_seguranca.visible,
		"a gaveta do Ataque tem «Transformação · 12 PA» (o custo da ficha dela)")
	var antes := _pedidas.size()
	hud._g_transformar.pressed.emit()
	_ok(_pedidas.size() == antes and hud._painel_escolha.visible and hud._titulo_escolha.text.contains("custa 12 PA dos 40 livres"),
		"a Transformação pede Confirmar primeiro (custa 12 PA dos 40 livres)")
	for n in hud._caixa_escolha.get_children():
		if n is Button and n.text == "Confirmar":
			n.pressed.emit()
	_ok(_pedidas.back() == {"tipo": "transformar"} and not hud._gaveta.visible, "Confirmar → transformar, e a gaveta fecha")

	print("== a ficha: Declarar Defender ==")
	_opcoes(["encerrar", "defender"], 8)
	await _quadros(1)
	_ok(hud._b_ficha.visible and not hud._painel_ficha.visible, "o chip «FICHA ▸» está à vista; a ficha fechada")
	hud._b_ficha.pressed.emit()
	await _quadros(1)
	_ok(hud._painel_ficha.visible and hud._b_defender.visible and not hud._b_defender.disabled, "na ficha: «Declarar Defender», na vez dela")
	hud._b_defender.pressed.emit()
	_ok(_pedidas.back() == {"tipo": "defender"} and not hud._painel_ficha.visible, "Declarar Defender → defender")
	_opcoes(["encerrar"], 9)
	hud._b_ficha.pressed.emit()
	await _quadros(1)
	_ok(not hud._b_defender.visible and hud._texto_defender.text.begins_with("DEFENDER — não está disponível"), "sem a reacção, a ficha diz porquê e não desenha botão morto")

	print("== ordem 15: «Apagar o fogo» na gaveta do Mover ==")
	_ok(not hud._g_apagar.visible, "sem a acção do servidor, não há «Apagar o fogo»")
	_estado.receber_opcoes({"v": 2, "type": "ROOM_OPTIONS", "revision": 10, "vezId": "fA", "orcamentoM": 9.0,
		"mover": [], "ataques": [], "consumiveis": [], "acoes": ["encerrar", "apagar_fogo"], "reacoes": []})
	hud.fechar_gaveta()
	hud.ao_modo_mudou(Modo.NENHUM)
	await _quadros(1)
	_ok(not hud._b_mover.disabled, "o Mover abre mesmo sem casas, quando ela pode apagar o fogo")
	hud._ao_botao(Modo.MOVER)
	await _quadros(1)
	_ok(hud._gaveta.visible and hud._g_apagar.visible and hud._g_apagar.text == "Apagar o fogo" and not hud._g_apagar.disabled,
		"a gaveta do Mover tem «Apagar o fogo»")
	hud._g_apagar.pressed.emit()
	_ok(_pedidas.back() == {"tipo": "apagar_fogo"} and not hud._gaveta.visible, "«Apagar o fogo» manda apagar_fogo e a gaveta fecha")
	nomes = []
	for b in hud._barra.get_children():
		nomes.append(str(b.name))
	_ok(nomes == ["BotaoAtaque", "BotaoMover", "BotaoConsumivel", "BotaoEncerrar"], "a barra continua com as quatro")
	hud._ao_recibo("x", "APLICADA", {})

	print("== fora da vez dela ==")
	_estado.vez_id = "fB"
	_opcoes(["encerrar", "correr", "desvincular"], 11)
	hud._ao_botao(Modo.MOVER)
	await _quadros(1)
	_ok(not hud._gaveta.visible, "fora da vez dela, nenhuma gaveta")

	print("== ordem 33: «Correr» recusado não fica pendurado ==")
	_estado.vez_id = "fA"
	_opcoes(["encerrar", "correr", "defender"], 12)
	hud.fechar_gaveta()
	hud.ao_modo_mudou(Modo.NENHUM)
	await _quadros(1)
	hud._a_correr = false
	hud._ao_botao(Modo.MOVER)
	await _quadros(1)
	hud._g_correr.pressed.emit()
	_ok(_pedidas.back() == {"tipo": "correr"}, "«Correr» manda a intenção correr")
	hud._ao_recusa("c-1", "revisao_antiga", "O tabuleiro mudou. Escolha de novo.")
	_opcoes(["encerrar", "correr", "defender"], 13)
	await _quadros(1)
	# Ela escolhe outra coisa (Declarar Defender) e o servidor aceita.
	hud._ao_recibo("d-1", "APLICADA", {})
	_opcoes(["encerrar", "correr"], 14)
	await _quadros(1)
	_ok(not hud._a_correr and not hud._g_correr.text.ends_with("A correr ✓"),
		"o recibo da acção seguinte não marca «A correr ✓» depois do Correr recusado")
	_ok(not hud._aviso.visible or not hud._aviso.text.begins_with("Você corre"), "e não diz «Você corre…»")
	hud.queue_free()
	await _quadros(1)
	await _teste_seguranca_na_arena()
	await _teste_grelha_refeita_guarda_os_nomes()
	await _teste_pe_em_casa_bloqueada()
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)


# ---------------------------------------------------------------- ordem 33: o movimento do «Sair c/ segurança»
## A arena manda primeiro o Desvincular e guarda o movimento (`_mover_depois`) para quando o recibo dele vier
## APLICADA. A recusa do servidor chega como ROOM_REJECT (Rede.recusa_recebida), não como recibo: o movimento
## tem de cair aí — e só o recibo DO Desvincular o pode soltar. Com um servidor WebSocket local (loopback), para se
## ver o que sai mesmo pelo fio.

var _srv: TCPServer
var _par: WebSocketPeer


func _ligar_loopback() -> bool:
	_srv = TCPServer.new()
	if _srv.listen(0, "127.0.0.1") != OK:
		return false
	var ws := WebSocketPeer.new()
	if ws.connect_to_url("ws://127.0.0.1:%d" % _srv.get_local_port()) != OK:
		return false
	_rede._ws = ws
	_rede.set_process(true)
	for i in 300:
		await process_frame
		if _par == null and _srv.is_connection_available():
			_par = WebSocketPeer.new()
			_par.accept_stream(_srv.take_connection())
		if _par != null:
			_par.poll()
			if _par.get_ready_state() == WebSocketPeer.STATE_OPEN and ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
				return true
	return false


## O que chegou ao «servidor» (ROOM_INTENT), depois de alguns quadros.
func _recebidas(quadros: int = 6) -> Array:
	var r: Array = []
	for i in quadros:
		await process_frame
		_par.poll()
		while _par.get_available_packet_count() > 0:
			var d = JSON.parse_string(_par.get_packet().get_string_from_utf8())
			if d is Dictionary and d.get("type") == "ROOM_INTENT":
				r.append(d)
	return r


func _e_mover_2_3(a) -> bool:
	return a is Dictionary and a.get("tipo") == "mover" and a.get("destino") is Dictionary 		and int(a["destino"].get("x", -1)) == 2 and int(a["destino"].get("y", -1)) == 3


func _servidor_manda(msg: Dictionary) -> void:
	_par.send_text(JSON.stringify(msg))
	for i in 4:
		_par.poll()
		await process_frame


func _opcoes_seguranca(rev: int) -> void:
	_estado.receber_opcoes({"v": 2, "type": "ROOM_OPTIONS", "revision": rev, "vezId": "fA", "orcamentoM": 9.0,
		"mover": [{"x": 2, "y": 3, "custoM": 1.5}], "ataques": [], "consumiveis": [],
		"acoes": ["encerrar", "defender", "desvincular"], "reacoes": []})


func _sair_com_seguranca_para_2_3(arena) -> void:
	arena.hud.sair_com_seguranca = true
	arena.definir_modo(Modo.MOVER)
	arena._escolher_casa(Vector2i(2, 3))


## Ordem 49 (C): o defeito latente das «Linhas» na arena do jogador (reserva 9 da Ordem 45). Ao refazer a grelha, os
## filhos velhos da Grelha só saíam na fila de libertação: o «Linhas» novo (e os outros) nascia com outro nome
## («@MeshInstance3D@…») e `Grelha/Linhas` dava o velho até ao fim do quadro e nada depois. O ecrã do Mestre já tirava
## os velhos da árvore antes (arena_mestre.gd); a arena do jogador passa a fazer o mesmo.
func _teste_grelha_refeita_guarda_os_nomes() -> void:
	print("== ordem 49: a grelha refeita da arena do jogador guarda os nomes (Linhas, Fogo, Destaques, Cursor) ==")
	_rede._ativo = true  # como acima: sem ir ao lobby
	var arena = (load("res://cenas/arena/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	await _quadros(2)
	var nomes := ["Linhas", "Fogo", "Destaques", "Cursor"]
	var velhos := {}
	for nome in nomes:
		velhos[nome] = arena.get_node_or_null("Grelha/" + nome)
	_ok(nomes.all(func(n): return velhos[n] != null), "a grelha de arranque tem os quatro nós %s" % [velhos.values()])
	# Os nomes dados pela arena, antes de refazer (o rótulo do custo nunca teve nome: fica «@Label3D@…» desde o início).
	var dados_antes := _nomes_dados(arena.get_node("Grelha"))
	var sem_nome_antes: int = arena.get_node("Grelha").get_child_count() - dados_antes.size()
	var mapa_antes: Dictionary = _estado.mapa.duplicate()
	# O caminho de verdade: um snapshot com outro tamanho refaz a grelha (arena.gd, _ao_snapshot).
	_estado.mapa = {"largura": 24, "altura": 22, "casaM": 1.5}
	arena._ao_snapshot()
	_ok(arena.largura == 24 and arena.altura == 22, "o snapshot refez a grelha em 24 × 22 (%d × %d)" % [arena.largura, arena.altura])
	var ja: Node = arena.get_node_or_null("Grelha/Linhas")
	_ok(ja != null and ja != velhos["Linhas"], "no mesmo quadro, «Grelha/Linhas» já é o nó novo, não o velho à espera de sair")
	await _quadros(2)
	var linhas: Node = arena.get_node_or_null("Grelha/Linhas")
	_ok(linhas is MeshInstance3D and linhas == ja, "depois da fila de libertação, «Grelha/Linhas» continua lá e é o mesmo nó")
	var g: Node = arena.get_node("Grelha")
	var dados_depois := _nomes_dados(g)
	var sem_nome_depois: int = g.get_child_count() - dados_depois.size()
	var de_linhas: Array = g.get_children().filter(func(n): return str(n.name) == "Linhas" or (n is MeshInstance3D and (n as MeshInstance3D).mesh is ImmediateMesh))
	_ok(dados_depois == dados_antes and sem_nome_depois == sem_nome_antes,
		"a Grelha refeita tem os mesmos nomes de antes %s, e nenhum nome inventado a mais (%d → %d)" % [dados_depois, sem_nome_antes, sem_nome_depois])
	_ok(de_linhas.size() == 1, "uma só malha de linhas na Grelha (%d)" % de_linhas.size())
	var proprios := {"Fogo": arena._fogo, "Destaques": arena._destaques, "Cursor": arena._marcador}
	for nome in proprios:
		var n: Node = arena.get_node_or_null("Grelha/" + nome)
		_ok(n != null and n == proprios[nome], "«Grelha/%s» é a camada nova que a arena usa" % nome)
	if linhas is MeshInstance3D and (linhas as MeshInstance3D).mesh != null:
		var v: PackedVector3Array = (linhas as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for q in v:
			lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.z))
			hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.z))
		var o: Vector2 = arena.origem
		var fim := o + Vector2(24, 22) * 1.5
		_ok(lo.distance_to(o) < 0.001 and hi.distance_to(fim) < 0.001,
			"as linhas desse nó cobrem a grelha nova: (%.2f, %.2f)–(%.2f, %.2f), esperado (%.2f, %.2f)–(%.2f, %.2f)"
			% [lo.x, lo.y, hi.x, hi.y, o.x, o.y, fim.x, fim.y])
	else:
		_ok(false, "as linhas desse nó cobrem a grelha nova (sem malha)")
	_estado.mapa = mapa_antes
	arena.queue_free()
	await _quadros(2)


## Ordem 58: na arena do jogador, uma figura numa casa que o mapa bloqueia não se põe de pé: recusa com nome
## (campo_da_mesa.gd `recusa_do_pe`, o mesmo caminho do ecrã do Mestre). Na 30 × 30 de 1,5 m, a (27,24) é uma escarpa
## de 55° (a reserva 3 da Ordem 45) e a (29,24) pisa-se. Quando as duas figuras trocam de casa, a que sai da escarpa
## volta a pôr-se de pé e a que entra deixa de estar. A prova completa (contra o servidor de verdade):
## cenas/arena/ferramentas/provar_pes_bloqueadas.gd.
func _teste_pe_em_casa_bloqueada() -> void:
	print("== ordem 58: a figura numa casa que o mapa bloqueia não se põe de pé (arena do jogador) ==")
	_rede._ativo = true  # como acima: sem ir ao lobby
	var mapa_antes: Dictionary = _estado.mapa.duplicate()
	var figuras_antes: Dictionary = _estado.figuras.duplicate(true)
	_estado.mapa = {"largura": 30, "altura": 30, "casaM": 1.5}
	_estado.figuras = {"pA": {"id": "pA", "nomePublico": "A", "x": 27, "y": 24, "lado": "criatura", "visivel": "de_pe"},
		"pB": {"id": "pB", "nomePublico": "B", "x": 29, "y": 24, "lado": "criatura", "visivel": "de_pe"}}
	var arena = (load("res://cenas/arena/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	await _quadros(2)
	arena._ao_snapshot()
	var rec: Dictionary = arena.pes_recusados()
	var nb: Node3D = arena._nos.get("pB")
	_ok(not arena._nos.has("pA") and str(rec.get("pA", "")) == "FLORESTA-E08-CASA-BLOQUEADA: (27,24) escarpa" and rec.size() == 1,
		"na escarpa (27,24) a figura não se põe de pé: recusa com nome «%s»" % rec.get("pA", ""))
	_ok(nb != null and nb.position == arena.pe_figura(Vector2i(29, 24)), "a da casa livre (29,24) está de pé no pé da casa")
	_ok(arena.posicao_tela("pA") == null, "a recusada não tem posição na tela (os números de dano caem no sítio de sempre)")
	_estado.figuras["pA"]["x"] = 29
	_estado.figuras["pB"]["x"] = 27
	arena._ao_evento({})
	await _quadros(1)
	rec = arena.pes_recusados()
	var na: Node3D = arena._nos.get("pA")
	_ok(na != null and na.position == arena.pe_figura(Vector2i(29, 24)) and not arena._nos.has("pB")
		and str(rec.get("pB", "")) == "FLORESTA-E08-CASA-BLOQUEADA: (27,24) escarpa" and rec.size() == 1,
		"trocadas: A sai da escarpa e põe-se de pé; B entra nela e fica recusada")
	_estado.mapa = mapa_antes
	_estado.figuras = figuras_antes
	arena.queue_free()
	await _quadros(2)


## Os nomes dos filhos que não foram inventados pelo Godot (os «@Tipo@n»), por ordem.
func _nomes_dados(no: Node) -> Array:
	var r: Array = []
	for n in no.get_children():
		if not str(n.name).begins_with("@"):
			r.append(str(n.name))
	r.sort()
	return r


func _teste_seguranca_na_arena() -> void:
	print("== ordem 33: o movimento do «Sair c/ segurança» só segue o recibo DO Desvincular ==")
	_estado.vez_id = "fA"
	_rede._ativo = true  # a arena chama Rede.iniciar(); com isto não vai ao lobby
	var arena = (load("res://cenas/arena/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	await _quadros(2)
	var ligou: bool = await _ligar_loopback()
	_ok(ligou, "servidor WebSocket local ligado à Rede")
	if not ligou:
		return
	var rev := 20

	# Controlo: Desvincular aceite → o movimento segue, com a revisão nova.
	_opcoes_seguranca(rev)
	_sair_com_seguranca_para_2_3(arena)
	var r: Array = await _recebidas()
	_ok(r.size() == 1 and r[0]["acao"] == {"tipo": "desvincular"}, "controlo: sai primeiro o Desvincular %s" % [r])
	if r.size() == 1:
		await _servidor_manda({"v": 2, "type": "ROOM_RECEIPT", "roomId": "sala-teste", "intentId": r[0]["intentId"],
			"estado": "APLICADA", "seq": 30, "revision": rev + 1})
	r = await _recebidas()
	_ok(r.size() == 1 and _e_mover_2_3(r[0]["acao"]) and int(r[0]["revision"]) == rev + 1,
		"controlo: aceite o Desvincular, segue o movimento com a revisão nova %s" % [r])
	if r.size() == 1:
		await _servidor_manda({"v": 2, "type": "ROOM_RECEIPT", "roomId": "sala-teste", "intentId": r[0]["intentId"],
			"estado": "APLICADA", "seq": 31, "revision": rev + 2})
	rev += 2

	# O defeito: Desvincular recusado (ROOM_REJECT) → o movimento não pode sair, nem agora nem depois.
	_opcoes_seguranca(rev)
	_sair_com_seguranca_para_2_3(arena)
	r = await _recebidas()
	_ok(r.size() == 1 and r[0]["acao"] == {"tipo": "desvincular"}, "sai o Desvincular %s" % [r])
	if r.size() == 1:
		await _servidor_manda({"v": 2, "type": "ROOM_REJECT", "roomId": "sala-teste", "intentId": r[0]["intentId"],
			"motivo": "revisao_antiga", "texto": "O tabuleiro mudou. Escolha de novo."})
	r = await _recebidas()
	_ok(r.is_empty(), "recusado o Desvincular, nada mais sai %s" % [r])
	# Ela escolhe outra coisa (Defender) e o servidor aceita: só o Defender sai — o movimento de antes não.
	_opcoes_seguranca(rev + 1)
	arena.enviar_acao({"tipo": "defender"})
	r = await _recebidas()
	_ok(r.size() == 1 and r[0]["acao"] == {"tipo": "defender"}, "a acção seguinte sai sozinha %s" % [r])
	if r.size() == 1:
		await _servidor_manda({"v": 2, "type": "ROOM_RECEIPT", "roomId": "sala-teste", "intentId": r[0]["intentId"],
			"estado": "APLICADA", "seq": 32, "revision": rev + 2})
	r = await _recebidas()
	_ok(r.is_empty(), "o recibo do Defender não solta o movimento do Desvincular recusado %s" % [r])

	_rede.set_process(false)
	_rede._ws = null
	_par.close()
	_srv.stop()
	arena.queue_free()
	await _quadros(2)
