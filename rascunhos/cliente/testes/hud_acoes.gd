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

	print("== ordem 15: «Apagar o fogo» na gaveta do Mover ==")
	_ok(not hud._g_apagar.visible, "sem a acção do servidor, não há «Apagar o fogo»")
	_estado.receber_opcoes({"v": 2, "type": "ROOM_OPTIONS", "revision": 61, "vezId": "fA", "orcamentoM": 9.0,
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

	print("== fora da vez dela ==")
	_estado.vez_id = "fB"
	_opcoes(["encerrar", "correr", "desvincular"], 10)
	hud._ao_botao(Modo.MOVER)
	await _quadros(1)
	_ok(not hud._gaveta.visible, "fora da vez dela, nenhuma gaveta")
	hud.queue_free()
	await _quadros(1)
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)
