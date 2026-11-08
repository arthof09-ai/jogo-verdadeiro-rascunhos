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
	_verificar(botoes.size() == 3, "%s três botões no cartão de desgraça" % [janela])
	var fundos_antes: Array = []
	for b in botoes:
		_verificar(_dentro(b, visivel), "%s botão «%s» inteiro à vista (fundo em %.0f de %.0f)" % [janela, b.text, b.get_global_rect().end.y, visivel.end.y])
		fundos_antes.append(b.get_global_rect().position)
	var barra: Control = m._abas.get_tab_bar()
	_verificar(_dentro(barra, visivel), "%s barra das abas inteira à vista" % [janela])
	_verificar(m._fila.visible and m._fila.text != "", "%s contador da fila visível («%s»)" % [janela, m._fila.text])

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
