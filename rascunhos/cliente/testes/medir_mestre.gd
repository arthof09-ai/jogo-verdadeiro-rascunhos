extends SceneTree
## F5-MESTRE-01: o ecrã do Mestre cabe em ecrãs baixos sem cortar o painel (desenho JV3.1 §8). I0004.
##
##   godot --headless --path cliente -s res://testes/medir_mestre.gd
##
## Irmão do medir_painel_config.gd (REF_20). Em três janelas (844×390 e 780×360 deitadas num
## telemóvel baixo, e a base 1920×1080) mede, com a vista e o cartão REAIS do servidor (fixture):
## - os botões do cartão activo ficam inteiros dentro da área visível;
## - a barra das abas fica inteira dentro da área visível;
## - a letra dá 13 px reais ou mais;
## - com o texto de cartão mais longo (razão comprida) e 4 cartões na fila, os botões não mexem;
## - com a folha encolhida, o cartão e os botões continuam à vista.
## Código de saída 0 se couber nas três, 1 se não couber, 2 se não der para medir.
##
## N3 RESPONDIDA (palavra do Mestre, 2026-11-08 20:37 -03): «Vou usar todos, acredito que talvez um pouco mais o
## celular, mas todos tem que ter a mesma qualidade e ser funcional.» As três janelas ficam no CI como prova
## permanente: celular deitado (844×390, 780×360) e computador (1920×1080), com a mesma régua para todos.

const CENA := "res://cenas/mestre/mestre.tscn"
const JANELAS := [Vector2i(844, 390), Vector2i(780, 360), Vector2i(1920, 1080)]
const MIN_PX_REAIS := 13.0

var _falhas := 0
var _sem_medida := 0
var _fx: Dictionary = {}


## Os autoloads (Rede, Estado) não são identificadores num script -s: chegam pela árvore no 1.º quadro.
var _rede: Node
var _estado: Node


func _init() -> void:
	process_frame.connect(_medir_todas, CONNECT_ONE_SHOT)


func _medir_todas() -> void:
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (d is Dictionary):
		printerr("sem a fixture do servidor")
		quit(2)
		return
	_fx = d
	_rede.persistir = false
	_rede.papel = "mestre"
	for j in JANELAS:
		await _medir(j)
	print("ecrã do Mestre: %d falha(s), %d sem medida" % [_falhas, _sem_medida])
	quit(1 if _falhas > 0 else (2 if _sem_medida > 0 else 0))


func _verificar(cond: bool, texto: String) -> void:
	print(("  ok    " if cond else "  FALHA ") + texto)
	if not cond:
		_falhas += 1


func _dentro(c: Control, visivel: Rect2) -> bool:
	var r := c.get_global_rect()
	return r.position.x >= visivel.position.x - 0.5 and r.position.y >= visivel.position.y - 0.5 \
		and r.end.x <= visivel.end.x + 0.5 and r.end.y <= visivel.end.y + 0.5


func _botoes_visiveis(m) -> Array:
	var saida: Array = []
	for b in m._botoes:
		if b.visible:
			saida.append(b)
	return saida


func _medir(janela: Vector2i) -> void:
	root.size = janela
	await process_frame
	if root.size != janela:
		printerr("%s pedida, mas a janela ficou %s: sem medida" % [janela, root.size])
		_sem_medida += 1
		return
	var m = (load(CENA) as PackedScene).instantiate()
	m.enviar_fn = func(_t, _c, _r): return ""
	m.pedir_vista_fn = func(): pass
	root.add_child(m)
	await process_frame
	m._aviso_entendido()
	# A vista real com 4 cartões abertos (para o contador da fila) e o cartão de IA com uma razão comprida.
	var vista: Dictionary = _fx["mestre"]["vista"].duplicate(true)
	var cartoes: Array = vista["mestre"]["cartoes"]
	while cartoes.size() < 4:
		var extra: Dictionary = (cartoes[0] if not cartoes.is_empty() else {"tipo": "ia"}).duplicate(true)
		extra["cartaoId"] = "extra-%d" % cartoes.size()
		cartoes.append(extra)
	m.aplicar_vista(vista)
	var curto: Dictionary = _fx["mestre"]["cartoes"]["desgraca"]
	m.aplicar_cartao(curto)
	m._ao_redimensionar()
	for i in 3:
		await process_frame
	var visivel := root.get_visible_rect()
	var escala := minf(float(janela.x) / 1920.0, float(janela.y) / 1080.0)
	print("%s: área %.0f × %.0f unidades; letra %d (= %.1f px reais)" % [janela, visivel.size.x, visivel.size.y, m._fonte, m._fonte * escala])
	_verificar(m._fonte * escala >= MIN_PX_REAIS - 0.01, "%s letra ≥ 13 px reais" % [janela])
	var botoes := _botoes_visiveis(m)
	_verificar(botoes.size() == 2, "%s dois botões no cartão de desgraça (Confirmar, Escolher outra)" % [janela])
	var fundos_antes: Array = []
	for b in botoes:
		_verificar(_dentro(b, visivel), "%s botão «%s» inteiro à vista (fundo em %.0f de %.0f)" % [janela, b.text, b.get_global_rect().end.y, visivel.end.y])
		fundos_antes.append(b.get_global_rect().position)
	var barra: Control = m._abas.get_tab_bar()
	_verificar(_dentro(barra, visivel), "%s barra das abas inteira à vista" % [janela])
	_verificar(m._fila.visible and m._fila.text != "", "%s contador da fila visível («%s»)" % [janela, m._fila.text])

	# Decisões 2 e 10 do Mestre (ordem 6): a câmara livre com a mesma qualidade nas três janelas — os controlos
	# cabem no tabuleiro, os de tocar têm 44 px reais ou mais e não se tapam uns aos outros.
	var tab: Rect2 = m._tabuleiro.get_global_rect()
	var ctl = m._livre
	_verificar(_dentro(ctl.entrar_botao, tab), "%s «Entrar na câmera livre» dentro do tabuleiro" % [janela])
	# Ordem HUD: a caixa da ordem de turnos (à vista em combate) não tapa o «Entrar na câmera livre».
	_verificar(m._caixa.visible and not m._caixa.get_global_rect().intersects(ctl.entrar_botao.get_global_rect()),
		"%s caixa da ordem à vista e sem tapar o «Entrar na câmera livre»" % [janela])
	# Ordem CAIXA-EXPANDE-VISTAS (D4): o ecrã do Mestre com FIGURAS_EXPANDIDA figuras e a vista expandida ABERTA (o rato
	# a sério por cima da caixa). As medidas de sobreposição usam o rectângulo da vista aberta, não o da compacta.
	for n in FIGURAS_EXPANDIDA:
		await _medir_expandida(m, janela, n)
	ctl.entrar()
	m._ao_redimensionar()
	for i in 3:
		await process_frame
	tab = m._tabuleiro.get_global_rect()
	var de_tocar: Array = [ctl.manipulo, ctl.sobe_botao, ctl.desce_botao, ctl.sair_botao, ctl.vel_caixa]
	for n in de_tocar + [ctl.dica]:
		_verificar((n as Control).visible and _dentro(n, tab), "%s câmara livre: «%s» dentro do tabuleiro" % [janela, (n as Node).name])
	for n in [ctl.manipulo, ctl.sobe_botao, ctl.desce_botao, ctl.sair_botao]:
		var lado := minf((n as Control).size.x, (n as Control).size.y) * escala
		_verificar(lado >= 44.0 - 0.5, "%s câmara livre: «%s» com %.0f px reais (≥ 44)" % [janela, (n as Node).name, lado])
	var tapados := false
	for i in de_tocar.size():
		for j in range(i + 1, de_tocar.size()):
			if (de_tocar[i] as Control).get_global_rect().intersects((de_tocar[j] as Control).get_global_rect()):
				tapados = true
				printerr("  %s tapa %s" % [(de_tocar[i] as Node).name, (de_tocar[j] as Node).name])
	_verificar(not tapados, "%s câmara livre: nenhum controlo tapa outro" % [janela])
	# Ordem HUD: dentro da câmara livre, a caixa da ordem desce para baixo do «Voltar» e da dica (e não chega aos de andar).
	var tapa_caixa: Array = []
	for n in [ctl.sair_botao, ctl.dica, ctl.manipulo, ctl.sobe_botao, ctl.desce_botao, ctl.vel_caixa]:
		if m._caixa.get_global_rect().intersects((n as Control).get_global_rect()):
			tapa_caixa.append((n as Node).name)
	_verificar(not m._caixa.visible or tapa_caixa.is_empty(), "%s câmara livre: a caixa da ordem não tapa o «Voltar», a dica nem os controlos de andar (%s) %s"
		% [janela, "à vista" if m._caixa.visible else "sem lugar: sai de cena", tapa_caixa])
	# Ordem CAIXA-EXPANDE-VISTAS (D4): a mesma medida com a vista ABERTA (o rato por cima da caixa): o rectângulo
	# expandido também não tapa o «Voltar», a dica nem os controlos de andar.
	if m._caixa.visible:
		_rato(m._caixa.get_global_rect().get_center())
		await process_frame
		var aberta_livre: bool = m._caixa.expandida()
		var r_livre: Rect2 = m._caixa.get_global_rect()
		var tapa_aberta: Array = []
		for n in [ctl.sair_botao, ctl.dica, ctl.manipulo, ctl.sobe_botao, ctl.desce_botao, ctl.vel_caixa]:
			if m._caixa.visible and r_livre.intersects((n as Control).get_global_rect()):
				tapa_aberta.append((n as Node).name)
		print("  MEDIDA MESTRE-LIVRE %s aberta=%s caixa=%s à vista=%s" % [janela, aberta_livre, _r(r_livre), m._caixa.visible])
		_verificar(tapa_aberta.is_empty(), "%s câmara livre, vista aberta (%s): a caixa da ordem não tapa o «Voltar», a dica nem os controlos de andar %s"
			% [janela, "à vista" if m._caixa.visible else "sem lugar: sai de cena", tapa_aberta])
		_rato(Vector2(1.0, root.get_visible_rect().end.y - 1.0))
		await process_frame
	ctl.sair()
	await process_frame
	_verificar(m._caixa.visible and not m._caixa.get_global_rect().intersects(ctl.entrar_botao.get_global_rect()),
		"%s fora da câmara livre: a caixa da ordem volta, sem tapar o «Entrar»" % [janela])

	# Texto de cartão mais longo: os botões não mexem.
	var longo: Dictionary = _fx["mestre"]["cartoes"]["ia"].duplicate(true)
	longo["cartaoId"] = curto["cartaoId"]  # o mesmo sítio, outro conteúdo
	longo["razao"] = "Razão comprida para medir. ".repeat(40)
	m.aplicar_cartao(longo)
	for i in 2:
		await process_frame
	var mexeu := false
	var bs := _botoes_visiveis(m)
	for i in mini(bs.size(), fundos_antes.size()):
		if bs[i].get_global_rect().position.distance_to(fundos_antes[i]) > 0.5:
			mexeu = true
	_verificar(not mexeu, "%s com o texto mais longo os botões não mexem" % [janela])
	for b in bs:
		_verificar(_dentro(b, visivel), "%s (texto longo) botão «%s» à vista" % [janela, b.text])

	# Folha encolhida.
	m._alternar_folha()
	for i in 2:
		await process_frame
	for b in _botoes_visiveis(m):
		_verificar(_dentro(b, visivel), "%s (folha encolhida) botão «%s» à vista" % [janela, b.text])
	_verificar(_dentro(m._titulo_cartao, visivel), "%s (folha encolhida) título do cartão à vista" % [janela])
	m.queue_free()
	await process_frame


# ---------------------------------------------------------------- Ordem CAIXA-EXPANDE-VISTAS (D4)

## Quantas figuras tem a ordem nas medidas da vista expandida (8+ da ordem: 12 e 16, os casos da prova viva; a última
## fica no ecrã para a medida da câmara livre).
const FIGURAS_EXPANDIDA := [12, 16]


func _r(r: Rect2) -> String:
	return "(%.0f,%.0f %.0f×%.0f)" % [r.position.x, r.position.y, r.size.x, r.size.y]


## O rato a sério (não o imitado de um toque) a mexer para `p` (coordenadas do ecrã).
func _rato(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	root.push_input(ev, true)


func _clique(p: Vector2) -> void:
	for carregado in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = carregado
		ev.position = p
		ev.global_position = p
		root.push_input(ev, true)


func _dentro_de(n: Node, pai: Node) -> bool:
	return n != null and (n == pai or pai.is_ancestor_of(n))


## A vista do fixture com `total` figuras (as do fixture e mais criaturas de ensaio, de nome comprido) em modo
## iniciativa, para a caixa ter uma ordem cheia.
func _vista_cheia(total: int) -> Dictionary:
	var vista: Dictionary = _fx["mestre"]["vista"].duplicate(true)
	var figs: Array = vista["mestre"]["figuras"]
	var molde: Dictionary = figs[figs.size() - 1].duplicate(true)
	var i := 0
	while figs.size() < total:
		var f: Dictionary = molde.duplicate(true)
		f["id"] = "fensaio%02d" % i
		f["nome"] = "Vigia de ensaio %d" % (i + 1)
		f["nomePublico"] = "Sombra comprida de ensaio %d" % (i + 1)
		f["x"] = 4 + i % 4
		f["y"] = 5 + int(i / 4)
		figs.append(f)
		i += 1
	var ordem: Array = []
	for f in figs:
		ordem.append(f["id"])
	vista["iniciativa"] = ordem
	vista["vezId"] = ordem[0]
	vista["caixaMestre"] = {"ligada": true, "modo": "iniciativa"}
	return vista


## D4: com a vista expandida aberta pelo rato, (1) a caixa não passa para a folha (fica dentro do tabuleiro) nem abaixo
## do fundo do ecrã; (2) a folha continua clicável à altura da caixa — o rato e o clique lá vão à folha, e a caixa fecha.
func _medir_expandida(m, janela: Vector2i, total: int) -> void:
	m.aplicar_vista(_vista_cheia(total))
	m._ao_redimensionar()
	for i in 3:
		await process_frame
	var cx: Control = m._caixa
	var visivel := root.get_visible_rect()
	_verificar(cx.visible and cx.ids_mostrados.size() == total, "%s caixa da ordem com %d figuras (%d)" % [janela, total, cx.ids_mostrados.size()])
	var compacta: Rect2 = cx.get_global_rect()
	_rato(compacta.get_center())
	await process_frame
	await process_frame
	var r: Rect2 = cx.get_global_rect()
	var tab: Rect2 = m._tabuleiro.get_global_rect()
	var folha: Rect2 = m._folha.get_global_rect()
	var rol: ScrollContainer = cx._rolagem
	var linhas := 0
	for l in cx._lista.get_children():
		if (l as Control).position.y + (l as Control).size.y <= rol.size.y + 0.5:
			linhas += 1
	print("  MEDIDA MESTRE-EXPANDIDA %s figuras=%d compacta=%s aberta=%s tabuleiro=%s folha=%s linhas inteiras à vista=%d de %d rola=%s nomes cortados com «…»=%d"
		% [janela, cx.ids_mostrados.size(), _r(compacta), _r(r), _r(tab), _r(folha), linhas, cx._lista.get_child_count(), cx.expandida_rola(), cx.linhas_cortadas().size()])
	_verificar(cx.expandida(), "%s %d figuras: vista expandida aberta pelo rato" % [janela, total])
	_verificar(r.end.x <= tab.end.x + 0.5 and not r.intersects(folha), "%s %d figuras, vista aberta: a caixa não passa para a folha (direita %.0f ≤ %.0f, início da folha %.0f)" % [janela, total, r.end.x, tab.end.x, folha.position.x])
	_verificar(r.end.y <= visivel.end.y + 0.5, "%s %d figuras, vista aberta: a caixa não passa do fundo do ecrã (%.0f ≤ %.0f)" % [janela, total, r.end.y, visivel.end.y])
	_verificar(r.end.x >= compacta.end.x - 0.5, "%s %d figuras, vista aberta: a caixa nunca é mais estreita que a compacta (%.0f ≥ %.0f)" % [janela, total, r.end.x, compacta.end.x])
	# A folha à altura da caixa, logo à direita do tabuleiro: é aí que a expandida sem tecto ia parar. Se a caixa entra
	# na folha, o ponto fica no meio da parte que ela tapa (o pior sítio); senão, meia letra para dentro da folha.
	var px := folha.position.x + float(m._fonte) * 0.5
	if r.end.x > folha.position.x:
		px = (folha.position.x + r.end.x) * 0.5
	var p := Vector2(px, clampf(r.get_center().y, folha.position.y + 1.0, folha.end.y - 1.0))
	_rato(p)
	await process_frame
	var por_cima: Control = root.gui_get_hovered_control()
	var aberta_depois: bool = cx.expandida()
	# O clique: conta-se o carregar que chega ao controlo da folha debaixo do rato. Para a medida não dar uma ordem ao
	# cartão (as verificações seguintes precisam dele como está), um comando finge estar em voo (o «tocar» do Mestre não
	# age com comandos em voo) e, se o ponto cair no «encolher», a folha volta a abrir-se.
	var cliques := [0]
	var contar := func(e: InputEvent):
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			cliques[0] += 1
	if por_cima != null:
		por_cima.gui_input.connect(contar)
	var encolhida_antes: bool = m._encolhida
	m._em_voo["medida-d4"] = true
	_clique(p)
	await process_frame
	m._em_voo.erase("medida-d4")
	if por_cima != null:
		por_cima.gui_input.disconnect(contar)
	if m._encolhida != encolhida_antes:
		m._alternar_folha()
		await process_frame
	print("  MEDIDA MESTRE-FOLHA %s ponto=(%.0f,%.0f) por baixo do rato=%s cliques recebidos=%d caixa aberta=%s" % [janela, p.x, p.y, por_cima.name if por_cima != null else "nada", cliques[0], aberta_depois])
	_verificar(_dentro_de(por_cima, m._folha) and cliques[0] == 1, "%s %d figuras, vista aberta: a folha à altura da caixa recebe o rato e o clique (%s, %d clique)" % [janela, total, por_cima.name if por_cima != null else "nada", cliques[0]])
	_verificar(not aberta_depois, "%s %d figuras: com o rato na folha a caixa volta à compacta" % [janela, total])
