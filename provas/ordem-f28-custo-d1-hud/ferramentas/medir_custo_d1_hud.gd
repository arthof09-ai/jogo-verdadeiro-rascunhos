extends SceneTree
## Ordem F28 da sentença da CAIXA-EXPANDE-INTERACAO — o CUSTO do D1 nos botões do HUD. SÓ MEDE: não muda o jogo.
##
##   godot --headless --path rascunhos/cliente -s <caminho absoluto>/medir_custo_d1_hud.gd
##
## O D1 (F14, hud/caixa_ordem.gd `_fechar_por_toque_fora` + `_engolir`): com a expandida aberta por toque, o toque fora
## que a fecha fica na caixa — o carregar, o arrastar e o levantar desse dedo, e o rato que o motor imita dele. Esta
## ferramenta mede o que isso custa botão a botão no HUD da jogadora, e no resto (gestos no tabuleiro, rato, roda).
##
## O palco é o do §11 da suite caixa_jogadora (F27): a ARENA a sério (cenas/arena/arena.tscn: o HUD, a câmara e o
## `_ao_toque` dela), sem servidor, com a Rede «na mesa» e um WebSocketPeer por ligar (a intenção regista-se na fila e o
## envio do texto falha sem erro). 12 figuras, a jogadora na vez, um ROOM_OPTIONS que liga todos os botões. Os toques
## vão pelo Input do motor (Input.parse_input_event, em píxeis da janela): o motor imita o rato a partir do toque, como
## no aparelho. Em 844×390 e 780×360.
##
## Por botão: (1) o estado de partida (p. ex. o Mover aberto, para os botões da gaveta); (2) a expandida aberta por
## toque; (3) toques no centro do botão até a acção sair (máx. 4). Regista-se o 1.º toque (fechou a lista? o botão
## recebeu o `pressed`? a acção saiu?) e quantos toques foram precisos. De controlo, o mesmo com a caixa fechada.
## Saída: linhas MEDIDA (uma por caso) e TABELA no fim. O código de saída é 0 se a medição correu (não é um teste).
##
## F61 (segunda corrida, a pedido da F64): a câmara repõe-se entre casos. O `_repor` volta a pôr o modo, o foco, o zoom,
## o rumo e a inclinação que a câmara tinha quando a arena ficou pronta, e salta para lá sem a suavização.
##
## F64 (sentença da F28, L1–L3; a L4, a câmara reposta, é a da F61 acima). Só acrescenta linhas ao registo; as linhas
## TABELA e a contagem de casos ficam as mesmas.
## - L1, a casa: `_casa` mede o toque numa casa do Mover, com a lista aberta por toque e de controlo, no mesmo ponto, e
##   escreve uma linha `MEDIDA CASA` com o resultado: a casa fecha a lista sem mover a figura, ou move-a (a intenção
##   «mover» vai para a fila; sem servidor o movimento não se aplica).
## - L2, a pinça: a linha `MEDIDA PINÇA` passa a dizer também quanto o foco da câmara andou (m) e o rumo e a inclinação.
##   Como a pinça desta ferramenta é simétrica (o meio fica parado), `_pinca_a_deslocar` junta uma 2.ª pinça cujo meio
##   anda 60 u para a esquerda: no controlo a câmara tem de se deslocar, para o 0 com a lista aberta ser medido e não
##   apenas lido no código. Linha `MEDIDA PINÇA A DESLOCAR`.
## - L3, o estado de partida: antes do gesto medido, uma linha `PARTIDA` diz o estado (a caixa, o modo da arena, a gaveta,
##   os painéis, a figura dela e a casa onde está, o cursor, a declaração do Mover, a fila e a câmara). Depois, linhas
##   `DEPOIS` dizem o que mudou em relação à partida (ao 1.º toque e no fim).
##
## F78/F79/F81 (sentença da F64). Só a prova muda; as linhas TABELA ficam as mesmas.
## - F78: o `_repor` repõe também o cursor da arena (o (-1, -1) com que ela nasce): a partida é neutra em todos os casos.
## - F79: a gaveta escreve «à vista, do Mover» (era «de o Mover»).
## - F81: a `MEDIDA PINÇA A DESLOCAR` traz o rumo e a inclinação, como a `MEDIDA PINÇA`. Em todos os casos a ordem é a
##   mesma: PARTIDA, as DEPOIS e só então a MEDIDA (nos botões a MEDIDA junta a lista aberta e o controlo, e sai no fim).
## - O gesto da pinça a deslocar (22 u e 2 u por passo, o meio a andar 60 u) é arbitrário, escolhido para o controlo dar
##   um número grande; os 0,854 m dele não são um gesto real (ver o README).

const NOMES := ["Espadachim", "Arqueira", "Criatura", "Criatura", "Personagem", "Criatura", "Criatura", "Criatura"]
const CASA_DELA := Vector2i(10, 10)
const MAX_TOQUES := 4

var _rede: Node
var _estado: Node
var _seq := 0
var _figs: Array = []
var arena: Node
var hud: Node
var _pressed := {}  # nome do botão -> quantas vezes o `pressed` saiu
var _tabela: Array = []
var _erros := 0
var _cam0 := {}  # o estado da câmara quando a arena ficou pronta (F61: repõe-se entre casos)


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _receber(msg: Dictionary) -> void:
	msg["v"] = 2
	msg["roomId"] = "sala-teste"
	_rede._ao_receber(JSON.stringify(msg))


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _figuras(n: int) -> Array:
	var figs: Array = []
	for i in n:
		var fid := "j1" if i == 0 else ("j2" if i == 1 else "m%d" % (i - 1))
		var f := {"id": fid, "nomePublico": NOMES[i % NOMES.size()], "lado": "jogadora" if i < 2 else "criatura",
			"x": 2 + ((i - 1) % 8), "y": 2, "orientacao": "S", "visivel": "de_pe"}
		if i == 0:
			f["x"] = CASA_DELA.x
			f["y"] = CASA_DELA.y
		elif i > 8:
			f["y"] = 17
		figs.append(f)
	return figs


func _snapshot() -> void:
	_seq += 1
	var ordem: Array = _figs.map(func(f): return f["id"])
	_receber({
		"type": "ROOM_SNAPSHOT", "seq": _seq, "revision": 5, "ts": "2026-11-23T12:00:00.000Z", "fase": "combate",
		"mapa": {"largura": 20, "altura": 20, "casaM": 1.5}, "figuras": _figs, "iniciativa": ordem, "vezId": "j1", "rodada": 1,
		"ambiente": {"clima": null, "luz": null}, "fogo": {"casas": [], "aArder": []},
		"propria": {"figuraId": "j1", "vidaActual": 10, "vidaTotal": 10, "paLivre": 3, "paTotal": 3, "estadoMorte": null,
			"armaCaida": false, "armaQuebrada": false, "corpoPartido": false, "ficha": {"transformacao": {"custo": 2}}},
		"caixa": {"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ordem, "fechada": true, "ultimo": "j1"}},
	})


## O ROOM_OPTIONS que liga todos os botões do HUD dela: casas do Mover, um ataque, um consumível com 2 alvos (abre o
## modo Consumível) e as acções encerrar, defender, correr, desvincular, apagar_fogo e transformar.
func _opcoes() -> void:
	var ocupadas := {}
	for f in _figs:
		ocupadas[Vector2i(int(f["x"]), int(f["y"]))] = true
	var mover: Array = []
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var c := CASA_DELA + Vector2i(dx, dy)
			if c == CASA_DELA or ocupadas.has(c):
				continue
			mover.append({"x": c.x, "y": c.y, "custoM": 1.5 * maxi(absi(dx), absi(dy))})
	_receber({"type": "ROOM_OPTIONS", "revision": 5, "vezId": "j1", "orcamentoM": 4.5, "mover": mover,
		"ataques": [{"alvoId": "m1", "arma": "espada-teste", "nome": "Espada"}],
		"consumiveis": [{"itemId": "pocao-teste", "nome": "Poção", "alvos": [{"id": "j1"}, {"id": "j2"}]}],
		"acoes": ["encerrar", "defender", "correr", "desvincular", "apagar_fogo", "transformar"], "reacoes": []})


## Volta ao estado neutro: a caixa fechada, a arena sem modo, os painéis fechados, a fila vazia, as opções de novo.
func _repor() -> void:
	var cx = hud._caixa
	if cx._aberta_toque:
		cx.alternar_toque()
	cx.definir_sobre(false)
	if "_engolir_toque" in cx:  # o caixa_ordem.gd de antes da F14 (a corrida sem-d1/) não o tem
		cx._engolir_toque = -1
	_rede.fila._itens.clear()
	_rede._envios_recentes.clear()
	arena._cursor = Vector2i(-1, -1)  # F78: o cursor de quando a arena nasce (arena.gd), para a partida ser neutra
	arena.definir_modo(arena.Modo.NENHUM)
	hud._gaveta_de = arena.Modo.NENHUM
	_declarar_saida(false)
	hud._a_correr = false
	hud._correr_pedido = false
	hud._painel_config.visible = false
	hud._painel_escolha.visible = false
	hud._painel_ficha.visible = false
	_opcoes()
	hud._atualizar()
	_repor_camara()
	await _quadros(3)


## F61: guarda-se o estado da câmara logo que a arena fica pronta; o `_repor` volta a pô-lo antes de todos os casos.
func _guardar_camara() -> void:
	var c = arena.camera
	_cam0 = {"modo": c.modo, "foco": c.foco, "zoom": c.zoom, "rumo": c.rumo, "inclinacao": c.inclinacao}


func _repor_camara() -> void:
	var c = arena.camera
	c.modo = _cam0["modo"]
	c.foco = _cam0["foco"]
	c.zoom = _cam0["zoom"]
	c.rumo = _cam0["rumo"]
	c.inclinacao = _cam0["inclinacao"]
	c._saltar()


## A declaração «Sair c/ …» do Mover (hud.gd: a propriedade `sair_com_*`, o 1.º botão da gaveta). Sem argumento, lê-a;
## com `valor`, põe-na. Procura-se pelo começo do nome para estas linhas não repetirem a palavra (ver o ESTADO-FINAL, §6).
func _declarar_saida(valor = null) -> bool:
	for p in hud.get_property_list():
		if str(p["name"]).begins_with("sair_com_"):
			if valor != null:
				hud.set(p["name"], valor)
			return bool(hud.get(p["name"]))
	return false


func _fila() -> int:
	return (_rede.fila._itens as Dictionary).size()


## F64 (L3): o estado do HUD e da arena, só lido (não espera quadros nem mexe em nada).
func _estado_agora() -> Dictionary:
	var cx = hud._caixa
	var caixa := "compacta"
	if hud.caixa_mostrada()["expandida"]:
		caixa = "expandida por toque" if ("_aberta_toque" in cx and cx._aberta_toque) else "expandida"
	var M = arena.Modo
	var paineis: Array = []
	for par in [["Configurações", hud._painel_config], ["escolha", hud._painel_escolha], ["ficha", hud._painel_ficha]]:
		if (par[1] as Control).visible:
			paineis.append(par[0])
	var gaveta := "fechada"
	if (hud._gaveta as Control).is_visible_in_tree():
		var de := "de nenhum modo" if hud._gaveta_de == M.NENHUM else "do " + str(M.find_key(hud._gaveta_de)).capitalize()
		gaveta = "à vista, %s" % de  # F79: «do Mover» (era «de o Mover»)
	var minha: String = _estado.minha_figura_id
	var cam = arena.camera
	var f: Vector3 = cam.foco
	var acao := _acao_na_fila()
	return {"caixa": caixa, "modo": str(M.find_key(arena.modo)).capitalize(), "gaveta": gaveta,
		"painéis": "nenhum" if paineis.is_empty() else " + ".join(paineis),
		"figura": "%s (a dela) na casa %s" % [minha, _estado.casa_de(_estado.figuras.get(minha))],
		"cursor": str(arena._cursor), "declaração do Mover": _sim(_declarar_saida()),
		"fila": "vazia" if _fila() == 0 else "%d (%s)" % [_fila(), acao if acao != "" else "sem acção"],
		"câmara": "foco (%.3f, %.3f, %.3f), zoom %.3f, rumo %.1f, inclinação %.1f" % [f.x, f.y, f.z, cam.zoom, cam.rumo, cam.inclinacao]}


func _texto_estado(e: Dictionary) -> String:
	var partes: Array = []
	for k in e:
		partes.append("%s %s" % [k, e[k]])
	return " · ".join(partes)


## O que mudou de `a` (a partida) para `b`.
func _mudou(a: Dictionary, b: Dictionary) -> String:
	var partes: Array = []
	for k in a:
		if a[k] != b.get(k):
			partes.append("%s: %s → %s" % [k, a[k], b.get(k)])
	return "nada" if partes.is_empty() else "; ".join(partes)


func _partida(rot: String) -> Dictionary:
	var e := _estado_agora()
	print("  PARTIDA %s: %s" % [rot, _texto_estado(e)])
	return e


func _depois(rot: String, quando: String, e0: Dictionary) -> void:
	print("  DEPOIS %s (%s): mudou %s" % [rot, quando, _mudou(e0, _estado_agora())])


func _acao_na_fila() -> String:
	for id in _rede.fila._itens:
		var t = _rede.fila._itens[id].get("texto")
		if t is String:
			var d = JSON.parse_string(t)
			if d is Dictionary and d.get("acao") is Dictionary:
				return str(d["acao"].get("tipo"))
	return ""


## Um toque pelo Input do motor (carrega e levanta no mesmo sítio), em unidades do HUD → píxeis da janela.
func _tocar(p: Vector2, indice := 0) -> void:
	var px: Vector2 = root.get_final_transform() * p
	for k in 2:
		var t := InputEventScreenTouch.new()
		t.index = indice
		t.pressed = k == 0
		t.position = px
		Input.parse_input_event(t)
		Input.flush_buffered_events()
		await process_frame


## O rato a sério (device 0): mover para `p` e, se `clicar`, carregar e largar o botão esquerdo aí.
func _rato(p: Vector2, clicar: bool) -> void:
	var px: Vector2 = root.get_final_transform() * p
	var m := InputEventMouseMotion.new()
	m.position = px
	m.global_position = px
	m.device = 0
	Input.parse_input_event(m)
	Input.flush_buffered_events()
	await process_frame
	if not clicar:
		return
	for carregado in [true, false]:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = carregado
		b.button_mask = MOUSE_BUTTON_MASK_LEFT if carregado else 0
		b.position = px
		b.global_position = px
		b.device = 0
		Input.parse_input_event(b)
		Input.flush_buffered_events()
		await process_frame


func _abrir_por_toque() -> bool:
	await _tocar((hud.caixa_mostrada()["rect"] as Rect2).get_center())
	await _quadros(3)
	return hud.caixa_mostrada()["expandida"] and hud._caixa._aberta_toque


func _botao_por_texto(pai: Node, texto: String) -> Button:
	for b in pai.find_children("*", "BaseButton", true, false):
		if b is Button and (b as Button).text == texto and (b as Button).is_visible_in_tree():
			return b
	return null


func _contar_pressed(b: BaseButton, nome: String) -> void:
	if not _pressed.has(nome):
		_pressed[nome] = 0
	var k := "_f28_ligado"
	if not b.has_meta(k):
		b.set_meta(k, true)
		b.pressed.connect(func(): _pressed[nome] += 1)


## Os casos: [nome, preparação (Callable async), botão (Callable → Control), a acção saiu? (Callable → bool), descrição da acção].
func _casos() -> Array:
	var M = arena.Modo
	return [
		["Mover", func(): pass, func(): return hud._b_mover, func(): return arena.modo == M.MOVER, "abre o Mover (casas a azul)"],
		["Ataque", func(): pass, func(): return hud._b_ataque, func(): return arena.modo == M.ATAQUE, "abre o Ataque (alvos)"],
		["Consumível", func(): pass, func(): return hud._b_consumivel, func(): return arena.modo == M.CONSUMIVEL, "abre o Consumível (alvos)"],
		["Encerrar", func(): pass, func(): return hud._b_encerrar, func(): return hud._painel_escolha.visible, "abre «Encerrar a sua vez?»"],
		["⚙ (config.)", func(): pass, func(): return hud._botao_config, func(): return hud._painel_config.visible, "abre as Configurações"],
		["FICHA ▸", func(): pass, func(): return hud._b_ficha, func(): return hud._painel_ficha.visible, "abre a ficha"],
		["Declarar Defender (na ficha)", func(): await _premir_controlo(hud._b_ficha), func(): return hud._b_defender,
			func(): return _acao_na_fila() == "defender", "envia «defender»"],
		["» Correr (gaveta do Mover)", func(): await _premir_controlo(hud._b_mover), func(): return hud._g_correr,
			func(): return _acao_na_fila() == "correr", "envia «correr»"],
		["↩ Sair c/ segurança (gaveta do Mover)", func(): await _premir_controlo(hud._b_mover), func(): return hud._gaveta.get_child(0),
			func(): return _declarar_saida(), "liga a declaração"],
		["Apagar o fogo (gaveta do Mover)", func(): await _premir_controlo(hud._b_mover), func(): return hud._g_apagar,
			func(): return _acao_na_fila() == "apagar_fogo", "envia «apagar_fogo»"],
		["✦ Transformação (gaveta do Ataque)", func(): await _premir_controlo(hud._b_ataque), func(): return hud._g_transformar,
			func(): return hud._painel_escolha.visible, "abre a confirmação"],
		["Sim, encerrar (painel de escolha)", func(): await _premir_controlo(hud._b_encerrar),
			func(): return _botao_por_texto(hud._painel_escolha, "Sim, encerrar"),
			func(): return _acao_na_fila() == "encerrar", "envia «encerrar»"],
		["Cancelar (painel de escolha)", func(): await _premir_controlo(hud._b_encerrar),
			func(): return _botao_por_texto(hud._painel_escolha, "Cancelar"),
			func(): return not hud._painel_escolha.visible, "fecha o painel"],
		["Fechar (Configurações)", func(): await _premir_controlo(hud._botao_config),
			func(): return _botao_por_texto(hud._painel_config, "Fechar"),
			func(): return not hud._painel_config.visible, "fecha as Configurações"],
		["Repor o zoom (Configurações)", func():
				await _premir_controlo(hud._botao_config)
				arena.camera.definir_zoom(arena.camera.ZOOM_PADRAO * 1.5),
			func(): return _botao_por_texto(hud._painel_config, "Repor o zoom"),
			func(): return is_equal_approx(arena.camera.zoom, arena.camera.ZOOM_PADRAO), "repõe o zoom"],
	]


## A preparação de um caso: um toque no botão com a caixa fechada (como a jogadora faria antes de abrir a lista).
func _premir_controlo(b: Control) -> void:
	await _tocar(b.get_global_rect().get_center())
	await _quadros(3)


## Mede um caso. `abrir`: "toque" (a expandida aberta por toque antes), "nenhuma" (controlo: a caixa fechada).
## Devolve {primeiro: {fechou, pressed, saiu}, toques, saiu, sobreposto}.
func _medir(caso: Array, abrir: String, rot := "") -> Dictionary:
	await _repor()
	await caso[1].call()
	await _quadros(2)
	var b: Control = caso[2].call()
	if b == null or not b.is_visible_in_tree():
		return {"erro": "o botão não está à vista"}
	if b is BaseButton and (b as BaseButton).disabled:
		return {"erro": "o botão está desactivado"}
	_contar_pressed(b, caso[0])
	if caso[3].call():
		return {"erro": "a acção já estava feita antes do toque"}
	var aberta := false
	if abrir == "toque":
		aberta = await _abrir_por_toque()
		if not aberta:
			return {"erro": "a expandida não abriu por toque"}
	var r_exp: Rect2 = hud.caixa_mostrada()["rect"]
	var centro := b.get_global_rect().get_center()
	var sobreposto := aberta and r_exp.has_point(centro)
	var p0: int = _pressed[caso[0]]
	var primeiro := {}
	var toques := 0
	var saiu := false
	var r_e := "%s (%s)" % [rot, "lista aberta por toque" if abrir == "toque" else "controlo, caixa fechada"]
	var e0 := _partida(r_e)
	while toques < MAX_TOQUES and not saiu:
		await _tocar(centro)
		await _quadros(3)
		toques += 1
		saiu = caso[3].call()
		if toques == 1:
			primeiro = {"fechou": not hud.caixa_mostrada()["expandida"], "pressed": _pressed[caso[0]] - p0, "saiu": saiu}
			_depois(r_e, "ao 1.º toque", e0)
	_depois(r_e, "no fim, %d toques" % toques, e0)
	return {"primeiro": primeiro, "toques": toques if saiu else -1, "saiu": saiu, "sobreposto": sobreposto,
		"pressed": _pressed[caso[0]] - p0, "sitio": centro, "caixa": r_exp}


func _sim(v: bool) -> String:
	return "sim" if v else "não"


func _botoes(tam: Vector2i) -> void:
	for caso in _casos():
		var rot := "%s · %dx%d" % [caso[0], tam.x, tam.y]
		var com: Dictionary = await _medir(caso, "toque", rot)
		var sem: Dictionary = await _medir(caso, "nenhuma", rot)
		if com.has("erro") or sem.has("erro"):
			_erros += 1
			printerr("  ERRO %s: com a lista aberta %s · controlo %s" % [rot, com.get("erro", "ok"), sem.get("erro", "ok")])
			_tabela.append([caso[0], tam, "ERRO", com.get("erro", ""), "", "", ""])
			continue
		var p: Dictionary = com["primeiro"]
		print("  MEDIDA %s: lista aberta por toque · botão em %s u, sob a expandida %s · 1.º toque: fechou a lista %s, «pressed» %d, acção saiu %s · toques até a acção sair: %d («pressed» total %d) · CONTROLO (caixa fechada): 1.º toque acção saiu %s, toques %d" % [
			rot, com["sitio"], _sim(com["sobreposto"]), _sim(p["fechou"]), p["pressed"], _sim(p["saiu"]), com["toques"], com["pressed"],
			_sim(sem["primeiro"]["saiu"]), sem["toques"]])
		_tabela.append([caso[0], tam, "fecha só a lista" if (p["fechou"] and not p["saiu"]) else ("fecha e executa" if p["fechou"] and p["saiu"] else ("executa, lista aberta" if p["saiu"] else "nada")),
			com["toques"], sem["toques"], com["toques"] - sem["toques"], caso[4], com["sobreposto"]])


## O resto: o primeiro gesto no tabuleiro após abrir a lista por toque (arrastar, pinça), a roda e o rato.
func _resto(tam: Vector2i) -> void:
	var cam = arena.camera
	var v := root.get_visible_rect().size
	var fora := Vector2(v.x * 0.4, v.y * 0.55)
	for abrir in ["toque", "nenhuma"]:
		# Arrastar um dedo no tabuleiro (deslocar a câmara): 6 passos de 15 u para a esquerda.
		await _repor()
		if abrir == "toque":
			await _abrir_por_toque()
		var r_a := "ARRASTAR %dx%d (%s)" % [tam.x, tam.y, "lista aberta por toque" if abrir == "toque" else "controlo, caixa fechada"]
		var e_a := _partida(r_a)
		var foco0: Vector3 = cam.foco
		var px0: Vector2 = root.get_final_transform() * fora
		var esc: float = root.get_final_transform().get_scale().x
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.pressed = true
		t.position = px0
		Input.parse_input_event(t)
		Input.flush_buffered_events()
		await process_frame
		for k in 6:
			var d := InputEventScreenDrag.new()
			d.index = 0
			d.position = px0 - Vector2(15.0 * (k + 1) * esc, 0.0)
			d.relative = Vector2(-15.0 * esc, 0.0)
			Input.parse_input_event(d)
			Input.flush_buffered_events()
			await process_frame
		t = InputEventScreenTouch.new()
		t.index = 0
		t.pressed = false
		t.position = px0 - Vector2(90.0 * esc, 0.0)
		Input.parse_input_event(t)
		Input.flush_buffered_events()
		await _quadros(3)
		var andou: float = (cam.foco as Vector3).distance_to(foco0)
		var fechou: bool = not hud.caixa_mostrada()["expandida"]
		_depois(r_a, "no fim", e_a)
		print("  MEDIDA ARRASTAR %dx%d (%s): 1 dedo arrastado 90 u no tabuleiro · a câmara deslocou-se %.3f m · lista fechada no fim %s" % [
			tam.x, tam.y, "lista aberta por toque" if abrir == "toque" else "controlo, caixa fechada", andou, _sim(fechou)])
		_tabela.append(["arrastar 1 dedo (deslocar a câmara)", tam, "lista" if abrir == "toque" else "controlo", andou, 0, 0, "câmara desloca-se", false])
		# A pinça (2 dedos que se afastam): o 1.º dedo carrega primeiro.
		await _repor()
		if abrir == "toque":
			await _abrir_por_toque()
		cam.definir_zoom(cam.ZOOM_PADRAO)
		var z0: float = cam.zoom
		var r_p := "PINÇA %dx%d (%s)" % [tam.x, tam.y, "lista aberta por toque" if abrir == "toque" else "controlo, caixa fechada"]
		var e_p := _partida(r_p)
		var fp0: Vector3 = cam.foco
		var rumo0: float = cam.rumo
		var incl0: float = cam.inclinacao
		var a := root.get_final_transform() * (fora - Vector2(30, 0))
		var bb := root.get_final_transform() * (fora + Vector2(30, 0))
		for idx in [0, 1]:
			var tt := InputEventScreenTouch.new()
			tt.index = idx
			tt.pressed = true
			tt.position = a if idx == 0 else bb
			Input.parse_input_event(tt)
			Input.flush_buffered_events()
			await process_frame
		for k in 5:
			for idx in [0, 1]:
				var d2 := InputEventScreenDrag.new()
				d2.index = idx
				var s := (-1.0 if idx == 0 else 1.0) * 10.0 * (k + 1) * esc
				d2.position = (a if idx == 0 else bb) + Vector2(s, 0)
				d2.relative = Vector2((-1.0 if idx == 0 else 1.0) * 10.0 * esc, 0)
				Input.parse_input_event(d2)
				Input.flush_buffered_events()
			await process_frame
		for idx in [1, 0]:
			var tt := InputEventScreenTouch.new()
			tt.index = idx
			tt.pressed = false
			tt.position = a if idx == 0 else bb
			Input.parse_input_event(tt)
			Input.flush_buffered_events()
			await process_frame
		await _quadros(3)
		var z1: float = cam.zoom
		_depois(r_p, "no fim", e_p)
		print("  MEDIDA PINÇA %dx%d (%s): 2 dedos afastam-se 100 u · zoom %.3f → %.3f · a câmara deslocou-se %.3f m (foco), rumo %.1f → %.1f, inclinação %.1f → %.1f · lista fechada no fim %s" % [
			tam.x, tam.y, "lista aberta por toque" if abrir == "toque" else "controlo, caixa fechada", z0, z1,
			(cam.foco as Vector3).distance_to(fp0), rumo0, cam.rumo, incl0, cam.inclinacao, _sim(not hud.caixa_mostrada()["expandida"])])
		_tabela.append(["pinça 2 dedos (zoom)", tam, "lista" if abrir == "toque" else "controlo", z1 / z0, 0, 0, "zoom muda", false])
		cam.definir_zoom(cam.ZOOM_PADRAO)
	# A roda do rato sobre a caixa (a F14 registou-a engolida: D3, mouse_force_pass_scroll_events) e fora dela.
	# «compacta»: a roda chega sem o rato se ter mexido por cima (a caixa fica compacta); «expandida pelo rato»: o rato
	# entra na caixa (abre a expandida, como num PC) e só depois roda; «fora»: o controlo, no tabuleiro.
	await _repor()
	for sitio in ["compacta", "expandida pelo rato", "fora"]:
		cam.definir_zoom(cam.ZOOM_PADRAO)
		var z0: float = cam.zoom
		var p: Vector2 = fora if sitio == "fora" else (hud.caixa_mostrada()["rect"] as Rect2).get_center()
		if sitio == "expandida pelo rato":
			await _rato(p, false)
			await _quadros(2)
			p = (hud.caixa_mostrada()["rect"] as Rect2).get_center()
		var r_r := "RODA %dx%d sobre %s" % [tam.x, tam.y, sitio]
		var e_r := _partida(r_r)
		var px: Vector2 = root.get_final_transform() * p
		for carregado in [true, false]:
			var w := InputEventMouseButton.new()
			w.button_index = MOUSE_BUTTON_WHEEL_UP
			w.pressed = carregado
			w.factor = 1.0
			w.position = px
			w.global_position = px
			Input.parse_input_event(w)
			Input.flush_buffered_events()
		await _quadros(2)
		_depois(r_r, "no fim", e_r)
		print("  MEDIDA RODA %dx%d sobre %s: 1 passo para cima · zoom %.3f → %.3f · a expandida está aberta %s" % [
			tam.x, tam.y, {"compacta": "a caixa compacta (sem o rato ter passado por cima)",
				"expandida pelo rato": "a caixa, depois de o rato entrar nela (abre a expandida)", "fora": "o tabuleiro (controlo)"}[sitio],
			z0, cam.zoom, _sim(hud.caixa_mostrada()["expandida"])])
		_tabela.append(["roda do rato (zoom)", tam, sitio, cam.zoom / z0, 0, 0, "zoom muda", false])
		await _rato(fora, false)
		await _quadros(2)
	cam.definir_zoom(cam.ZOOM_PADRAO)


## O rato: (a) só o rato — a expandida abre-se por cima, o rato sai para o botão (fecha-a) e clica; (b) a lista aberta
## por TOQUE e depois o rato a sério (aparelho híbrido: portátil com ecrã de toque).
func _rato_botoes(tam: Vector2i) -> void:
	var M = arena.Modo
	var casos := [["Mover", func(): return hud._b_mover, func(): return arena.modo == M.MOVER],
		["Encerrar", func(): return hud._b_encerrar, func(): return hud._painel_escolha.visible],
		["⚙ (config.)", func(): return hud._botao_config, func(): return hud._painel_config.visible]]
	for caso in casos:
		for via in ["rato", "toque-depois-rato"]:
			await _repor()
			var b: Control = caso[1].call()
			_contar_pressed(b, caso[0])
			var r: Rect2 = hud.caixa_mostrada()["rect"]
			var abriu := false
			if via == "rato":
				await _rato(r.get_center(), false)
				await _quadros(2)
				abriu = hud.caixa_mostrada()["expandida"]
			else:
				abriu = await _abrir_por_toque()
			var centro := b.get_global_rect().get_center()
			await _rato(centro, false)  # o rato chega ao botão
			await _quadros(2)
			var fechou_ao_sair: bool = not hud.caixa_mostrada()["expandida"]
			var r_m := "RATO %s · %dx%d (%s)" % [caso[0], tam.x, tam.y, via]
			var e_m := _partida(r_m)
			var p0: int = _pressed[caso[0]]
			var cliques := 0
			var saiu := false
			while cliques < MAX_TOQUES and not saiu:
				await _rato(centro, true)
				await _quadros(3)
				cliques += 1
				saiu = caso[2].call()
			_depois(r_m, "no fim, %d cliques" % cliques, e_m)
			var aberta_fim: bool = hud.caixa_mostrada()["expandida"]
			print("  MEDIDA RATO %s · %dx%d (%s): abriu %s · o rato saiu da caixa para o botão: a lista fechou %s · cliques até a acção sair %d («pressed» %d) · a lista continua aberta no fim %s" % [
				caso[0], tam.x, tam.y, "só o rato, a expandida pelo rato por cima" if via == "rato" else "a lista aberta por TOQUE, depois o rato a sério",
				_sim(abriu), _sim(fechou_ao_sair), cliques if saiu else -1, _pressed[caso[0]] - p0, _sim(aberta_fim)])
			_tabela.append(["rato · " + caso[0], tam, via, cliques if saiu else -1, 1, (cliques if saiu else -1) - 1,
				"lista aberta no fim: %s; fechou ao sair: %s" % [_sim(aberta_fim), _sim(fechou_ao_sair)], false])
		# o rato a sério é device 0; volta a pô-lo fora
		await _rato(Vector2(root.get_visible_rect().size.x * 0.4, root.get_visible_rect().size.y * 0.55), false)


## A jogadora numa vez típica: mover para uma casa e encerrar. Conta os toques, sem e com «ver a ordem» (abrir a lista
## por toque) em dois momentos: no começo da vez e com o Mover já aberto.
func _jogada(tam: Vector2i) -> void:
	for quando in ["nunca", "no começo da vez", "com o Mover aberto"]:
		await _repor()
		var r_j := "JOGADA %dx%d (ver a ordem: %s)" % [tam.x, tam.y, quando]
		var e_j := _partida(r_j)
		var toques := 0
		var passos: Array = []
		if quando == "no começo da vez":
			await _abrir_por_toque()
			toques += 1
			passos.append("abrir a lista 1")
		# Mover
		var n := 0
		while arena.modo != arena.Modo.MOVER and n < MAX_TOQUES:
			await _tocar(hud._b_mover.get_global_rect().get_center())
			await _quadros(3)
			n += 1
		toques += n
		passos.append("Mover %d" % n)
		if quando == "com o Mover aberto":
			await _abrir_por_toque()
			toques += 1
			passos.append("abrir a lista 1")
		# a casa de destino: a primeira casa do Mover que um toque dá e fica fora do HUD (como o §11 da suite)
		var sitio := _sitio_casa()
		n = 0
		while _acao_na_fila() != "mover" and n < MAX_TOQUES and sitio != Vector2.INF:
			await _tocar(sitio)
			await _quadros(4)
			n += 1
		toques += n
		passos.append("casa %d" % n)
		# o servidor aceitou: a fila esvazia-se e vêm as opções de novo (aqui sem casas do Mover gastas: as mesmas)
		_rede.fila._itens.clear()
		_rede._envios_recentes.clear()
		_opcoes()
		hud._atualizar()
		await _quadros(3)
		n = 0
		while not hud._painel_escolha.visible and n < MAX_TOQUES:
			await _tocar(hud._b_encerrar.get_global_rect().get_center())
			await _quadros(3)
			n += 1
		toques += n
		passos.append("Encerrar %d" % n)
		await _quadros(2)
		var sim := _botao_por_texto(hud._painel_escolha, "Sim, encerrar")
		n = 0
		while sim != null and _acao_na_fila() != "encerrar" and n < MAX_TOQUES:
			await _tocar(sim.get_global_rect().get_center())
			await _quadros(3)
			n += 1
		toques += n
		passos.append("Sim, encerrar %d" % n)
		var completa := _acao_na_fila() == "encerrar"
		_depois(r_j, "no fim", e_j)
		print("  MEDIDA JOGADA %dx%d (ver a ordem: %s): %d toques [%s] · completa %s" % [tam.x, tam.y, quando, toques, ", ".join(passos), _sim(completa)])
		_tabela.append(["jogada típica (mover + encerrar)", tam, quando, toques if completa else -1, 0, 0, ", ".join(passos), false])


## F64 (L1): o toque numa casa do Mover, com a lista aberta por toque e de controlo (a caixa fechada), no MESMO ponto
## do ecrã: o que a lista aberta escolhe (`_sitio_casa`, fora do HUD e da expandida), reusado no controlo. Toques até a
## intenção «mover» sair (máx. 4). Não entra na TABELA (a contagem de casos fica a da F28).
func _casa(tam: Vector2i) -> void:
	var sitio := Vector2.INF
	var alvo := Vector2i(-1, -1)
	for abrir in ["toque", "nenhuma"]:
		var r_c := "CASA %dx%d (%s)" % [tam.x, tam.y, "lista aberta por toque" if abrir == "toque" else "controlo, caixa fechada"]
		await _repor()
		await _premir_controlo(hud._b_mover)
		await _quadros(2)
		if arena.modo != arena.Modo.MOVER:
			_erros += 1
			printerr("  ERRO %s: o Mover não abriu" % r_c)
			continue
		if abrir == "toque" and not await _abrir_por_toque():
			_erros += 1
			printerr("  ERRO %s: a expandida não abriu por toque" % r_c)
			continue
		if sitio == Vector2.INF:
			sitio = _sitio_casa()
			alvo = arena.casa_em_tela(sitio) if sitio != Vector2.INF else Vector2i(-1, -1)
		if sitio == Vector2.INF or arena.casa_em_tela(sitio) != alvo or not arena._casas.has(alvo):
			_erros += 1
			printerr("  ERRO %s: não há casa do Mover à vista fora do HUD" % r_c)
			continue
		var aberta: bool = hud.caixa_mostrada()["expandida"]
		var e0 := _partida(r_c)
		var toques := 0
		var saiu := false
		var fechou1 := false
		var saiu1 := false
		while toques < MAX_TOQUES and not saiu:
			await _tocar(sitio)
			await _quadros(4)
			toques += 1
			saiu = _acao_na_fila() == "mover"
			if toques == 1:
				fechou1 = aberta and not hud.caixa_mostrada()["expandida"]
				saiu1 = saiu
				_depois(r_c, "ao 1.º toque", e0)
		_depois(r_c, "no fim, %d toques" % toques, e0)
		var resultado := "nada"
		if saiu1:
			resultado = "a casa fecha a lista e move a figura" if fechou1 else "a casa move a figura"
		elif fechou1:
			resultado = "a casa fecha a lista sem mover a figura"
		print("  MEDIDA CASA %dx%d (%s): toque na casa %s do Mover, em %s u · 1.º toque: %s (fechou a lista %s, a intenção «mover» saiu %s) · toques até a figura ser mandada mover: %d" % [
			tam.x, tam.y, "lista aberta por toque" if abrir == "toque" else "controlo, caixa fechada", alvo, sitio,
			resultado, _sim(fechou1), _sim(saiu1), toques if saiu else -1])


## F64 (L2): a pinça cujo meio anda. O 1.º dedo vai 22 u para a esquerda por passo e o 2.º 2 u: afastam-se 20 u por
## passo, como na pinça do `_resto`, e o meio anda 12 u por passo (60 u em 5 passos). No controlo a câmara tem de se
## deslocar; com a lista aberta mede-se se se desloca.
func _pinca_a_deslocar(tam: Vector2i) -> void:
	var cam = arena.camera
	var v := root.get_visible_rect().size
	var fora := Vector2(v.x * 0.4, v.y * 0.55)
	for abrir in ["toque", "nenhuma"]:
		var r_p := "PINÇA A DESLOCAR %dx%d (%s)" % [tam.x, tam.y, "lista aberta por toque" if abrir == "toque" else "controlo, caixa fechada"]
		await _repor()
		if abrir == "toque" and not await _abrir_por_toque():
			_erros += 1
			printerr("  ERRO %s: a expandida não abriu por toque" % r_p)
			continue
		cam.definir_zoom(cam.ZOOM_PADRAO)
		var e0 := _partida(r_p)
		var z0: float = cam.zoom
		var f0: Vector3 = cam.foco
		var rumo0: float = cam.rumo
		var incl0: float = cam.inclinacao
		var esc: float = root.get_final_transform().get_scale().x
		var a := root.get_final_transform() * (fora - Vector2(30, 0))
		var bb := root.get_final_transform() * (fora + Vector2(30, 0))
		for idx in [0, 1]:
			var tt := InputEventScreenTouch.new()
			tt.index = idx
			tt.pressed = true
			tt.position = a if idx == 0 else bb
			Input.parse_input_event(tt)
			Input.flush_buffered_events()
			await process_frame
		var passo := [Vector2(-22.0 * esc, 0.0), Vector2(-2.0 * esc, 0.0)]
		for k in 5:
			for idx in [0, 1]:
				var d2 := InputEventScreenDrag.new()
				d2.index = idx
				d2.position = (a if idx == 0 else bb) + passo[idx] * (k + 1)
				d2.relative = passo[idx]
				Input.parse_input_event(d2)
				Input.flush_buffered_events()
			await process_frame
		for idx in [1, 0]:
			var tt := InputEventScreenTouch.new()
			tt.index = idx
			tt.pressed = false
			tt.position = (a if idx == 0 else bb) + passo[idx] * 5
			Input.parse_input_event(tt)
			Input.flush_buffered_events()
			await process_frame
		await _quadros(3)
		_depois(r_p, "no fim", e0)
		print("  MEDIDA PINÇA A DESLOCAR %dx%d (%s): 2 dedos afastam-se 100 u e o meio anda 60 u para a esquerda · zoom %.3f → %.3f · a câmara deslocou-se %.3f m (foco), rumo %.1f → %.1f, inclinação %.1f → %.1f · lista fechada no fim %s" % [
			tam.x, tam.y, "lista aberta por toque" if abrir == "toque" else "controlo, caixa fechada", z0, cam.zoom,
			(cam.foco as Vector3).distance_to(f0), rumo0, cam.rumo, incl0, cam.inclinacao, _sim(not hud.caixa_mostrada()["expandida"])])
		cam.definir_zoom(cam.ZOOM_PADRAO)


func _sitio_casa() -> Vector2:
	var evitar: Array = []
	for p in ["Raiz/Seguro/Camadas/ColunaEsquerda", "Raiz/Seguro/Camadas/Barra", "Raiz/Seguro/Camadas/Faixa"]:
		var n := hud.get_node(p) as Control
		if n.visible:
			evitar.append(n.get_global_rect().grow(8.0))
	evitar.append((hud.caixa_mostrada()["rect"] as Rect2).grow(8.0))  # a caixa como está agora (compacta ou aberta)
	if hud._gaveta.is_visible_in_tree():
		evitar.append((hud._gaveta as Control).get_global_rect().grow(8.0))
	var v := root.get_visible_rect().size
	var alvo := Vector2(v.x * 0.4, v.y * 0.55)
	var tela := root.get_visible_rect().grow(-12.0)
	var melhor := Vector2.INF
	var casas: Array = arena._casas.keys()
	casas.sort()
	for c in casas:
		var mundo: Vector3 = arena.centro_casa(c)
		if arena.camera.is_position_behind(mundo):
			continue
		var p: Vector2 = arena.camera.unproject_position(mundo)
		if not tela.has_point(p) or evitar.any(func(e: Rect2): return e.has_point(p)) or arena.casa_em_tela(p) != c:
			continue
		if hud._caixa.expandida() == false and p.x > v.x * 0.55:
			continue  # com a caixa compacta, fica-se na metade esquerda: longe de onde a expandida cresceria
		if p.distance_to(alvo) < melhor.distance_to(alvo):
			melhor = p
	return melhor


func _correr() -> void:
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	root.size = Vector2i(1920, 1080)
	await process_frame
	_rede.persistir = false
	_rede.papel = "jogadora"
	_receber({"type": "ROOM_WELCOME", "seatId": "s1", "seatToken": "t", "papel": "jogadora"})
	_rede._ativo = true
	_rede.estado_ligacao = _rede.Ligacao.NA_MESA
	_rede._ws = WebSocketPeer.new()
	_figs = _figuras(12)
	_snapshot()
	arena = (load("res://cenas/arena/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	await _quadros(4)
	hud = arena.hud
	_guardar_camara()
	print("== F28: o custo do D1 nos botões do HUD (12 figuras, a jogadora na vez; arena a sério, sem servidor) ==")
	print("== F61: a câmara repõe-se entre casos (modo %d, foco %s, zoom %.3f, rumo %.1f, inclinação %.1f) ==" % [
		_cam0["modo"], _cam0["foco"], _cam0["zoom"], _cam0["rumo"], _cam0["inclinacao"]])
	print("== F64: linhas MEDIDA CASA e MEDIDA PINÇA A DESLOCAR; o deslocamento da câmara na pinça; PARTIDA e DEPOIS em todos os casos ==")
	print("== F78/F79/F81: o cursor reposto entre casos; «do Mover»; rumo e inclinação na pinça a deslocar; PARTIDA, DEPOIS e MEDIDA por esta ordem ==")
	for tam in [Vector2i(844, 390), Vector2i(780, 360)]:
		root.size = tam
		await process_frame
		if root.size != tam:
			_erros += 1
			printerr("  ERRO %s pedida, a janela ficou %s" % [tam, root.size])
			continue
		hud._ao_redimensionar()
		await _quadros(4)
		_snapshot()
		await _quadros(2)
		print("-- %dx%d: botão a botão --" % [tam.x, tam.y])
		await _botoes(tam)
		print("-- %dx%d: o resto (gestos e roda) --" % [tam.x, tam.y])
		await _resto(tam)
		print("-- %dx%d: o rato --" % [tam.x, tam.y])
		await _rato_botoes(tam)
		print("-- %dx%d: a jogada típica --" % [tam.x, tam.y])
		await _jogada(tam)
		print("-- %dx%d: F64 — o toque numa casa e a pinça a deslocar --" % [tam.x, tam.y])
		await _casa(tam)
		await _pinca_a_deslocar(tam)
	print("")
	print("TABELA (caso | ecrã | 1.º toque com a lista aberta | toques com a lista aberta | toques com a caixa fechada | custo | acção | sob a expandida)")
	for l in _tabela:
		print("TABELA | %s | %dx%d | %s | %s | %s | %s | %s | %s" % [l[0], l[1].x, l[1].y, l[2], str(l[3]), str(l[4]), str(l[5]), l[6], str(l[7]) if l.size() > 7 else ""])
	print("")
	print("Medição acabada: %d casos, %d erros de medição." % [_tabela.size(), _erros])
	_rede.fila._itens.clear()
	_rede._ws = null
	arena.queue_free()
	await _quadros(2)
	quit(0 if _erros == 0 else 2)
