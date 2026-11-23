extends SceneTree
## Ordem CAIXA-JANELA — a janela lobby→arena (B1) e a caixa com 8+ figuras em ecrãs baixos (B3), sem servidor e sem ecrã.
##
##   godot --headless --path cliente -s res://testes/caixa_janela.gd
##
## B1: o `Estado.evento_aplicado` é fogo-e-esquece; o HUD nasce com a arena DEPOIS do snapshot do lobby. Os eventos que
##     chegam entre o snapshot e o `_ready` do HUD têm de aparecer na caixa logo ao abrir, sem esperar pelo snapshot
##     seguinte (o Estado guarda os eventos desde o snapshot; o HUD repete-os).
## B3: com 8, 12 e 16 figuras na ordem, em 844×390 e 780×360 (e 1280×720 como referência): a caixa cabe no ecrã, não tapa
##     a ⚙, a ficha nem a barra, e a faixa de cima continua com largura para a frase mais comprida que mostra, numa linha,
##     sem passar por baixo da caixa. As medidas saem no registo (MEDIDA ...).
##     Ordem CAIXA-EXPANDE: a compacta mostra só os 4 próximos (os slots); e, em todas as medições, a VISTA EXPANDIDA — o rato
##     por cima (eventos a sério) abre a ordem inteira com os nomes completos (um nome de 33 letras incluído), encostada à
##     direita, acima da barra, sem tapar a faixa nem a ⚙; o que não cabe rola por dentro (MEDIDA EXPANDIDA ...).
## Código de saída 0 se tudo passa, 1 se algo falha.

## As frases mais compridas que a faixa mostra em combate (hud.gd `_texto_faixa`), com um nome de 10 letras e 10,5 m.
const FRASES_FAIXA := [
	"A mesa está em pausa. O Mestre já volta.",
	"A sua vez · você pode andar até 10,5 m",
	"Vez de Espadachim",
	"O Mestre narra",
]
const NOMES := ["Espadachim", "Arqueira", "Criatura das Brumas do Lago Velho", "Criatura", "Criatura", "Criatura", "Personagem", "Criatura",
	"Criatura", "Criatura", "Personagem", "Criatura"]

var _total := 0
var _falhas := 0
var _rede: Node
var _estado: Node
var _seq := 0
var _n_figuras := 8


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		printerr("  FALHA ", nome)


func _receber(msg: Dictionary) -> void:
	msg["v"] = 2
	msg["roomId"] = "sala-teste"
	_rede._ao_receber(JSON.stringify(msg))


func _id(i: int) -> String:
	return "f%d" % (i + 1)


func _figuras() -> Array:
	var out: Array = []
	for i in _n_figuras:
		var lado := "jogadora" if i < 2 else "criatura"
		out.append({"id": _id(i), "nomePublico": NOMES[i] if i < NOMES.size() else "Criatura", "lado": lado, "x": 2 + i, "y": 2 + (i % 3), "orientacao": "S", "visivel": "de_pe"})
	return out


func _snapshot(caixa: Dictionary) -> void:
	_seq += 1
	var ini: Array = []
	for i in _n_figuras:
		ini.append(_id(i))
	_receber({
		"type": "ROOM_SNAPSHOT", "seq": _seq, "revision": 5, "ts": "2026-11-21T12:00:00.000Z", "fase": "combate",
		"mapa": {"largura": 20, "altura": 20, "casaM": 1.5}, "figuras": _figuras(),
		"iniciativa": ini, "vezId": _id(0), "rodada": 1,
		"ambiente": {"clima": null, "luz": null}, "fogo": {"casas": [], "aArder": []},
		"propria": {"figuraId": "f1", "vidaActual": 10, "vidaTotal": 10, "paLivre": 1, "paTotal": 1, "estadoMorte": null,
			"armaCaida": false, "armaQuebrada": false, "corpoPartido": false, "ficha": {}},
		"caixa": caixa,
	})


func _mover(fid: String) -> void:
	_seq += 1
	_receber({"type": "ROOM_EVENT", "seq": _seq, "revision": 5, "ts": "2026-11-21T12:00:01.000Z", "tipo": "movimento",
		"dados": {"figuraId": fid, "de": {"x": 1, "y": 1}, "para": {"x": 1, "y": 2}, "caminho": []}})


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _abrir_hud() -> Node:
	var hud = (load("res://hud/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	hud._ao_redimensionar()
	await _quadros(4)
	return hud


func _fechar_hud(hud: Node) -> void:
	hud.queue_free()
	await process_frame


func _correr() -> void:
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	root.size = Vector2i(1920, 1080)
	await process_frame
	_rede.persistir = false
	_rede.papel = "jogadora"
	_receber({"type": "ROOM_WELCOME", "seatId": "s1", "seatToken": "t", "papel": "jogadora"})

	print("== B1. eventos aplicados ANTES de o HUD abrir (a batalha anda enquanto a arena abre) ==")
	_n_figuras = 4
	_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ["f2", "f1"], "fechada": false, "ultimo": "f1"}})
	_mover("f3")  # entra no fim e fica na vez
	_mover("f4")
	_ok(_estado.eventos_desde_snapshot.size() == 2, "o Estado guardou os 2 eventos de depois do snapshot")
	var hud := await _abrir_hud()
	var c: Dictionary = hud.caixa_mostrada()
	_ok(c["visivel"] and c["ids"] == ["f2", "f1", "f3", "f4"] and c["vez"] == "f4",
		"ao abrir, a caixa já tem os eventos de antes do HUD (%s, vez %s), sem esperar pelo snapshot seguinte" % [c["ids"], c["vez"]])
	_mover("f2")  # volta quem já estava: a volta fecha — o sinal continua ligado depois da repetição
	await _quadros(2)
	c = hud.caixa_mostrada()
	_ok(c["ids"] == ["f2", "f1", "f3", "f4"] and c["vez"] == "f2", "depois de abrir, os eventos seguem pelo sinal, sem repetir os de antes (vez %s)" % c["vez"])
	_ok(hud.ordem_turnos.vezes == 3, "cada evento contou uma só vez (repetidos no _ready: 2; pelo sinal: 1) — vezes %d" % hud.ordem_turnos.vezes)
	await _fechar_hud(hud)
	_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ["f1"], "fechada": false, "ultimo": "f1"}})
	_ok(_estado.eventos_desde_snapshot.is_empty(), "um snapshot novo é o ponto de partida: a lista de depois dele recomeça vazia")
	hud = await _abrir_hud()
	c = hud.caixa_mostrada()
	_ok(c["ids"] == ["f1"] and c["vez"] == "f1", "sem eventos depois do snapshot, a caixa é a do snapshot (%s)" % [c["ids"]])
	await _fechar_hud(hud)

	print("== B3. 8, 12 e 16 figuras na ordem, em ecrãs baixos ==")
	for n in [8, 12, 16]:
		_n_figuras = n
		var ordem: Array = []
		for i in n:
			ordem.append(_id(i))
		_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ordem, "fechada": true, "ultimo": _id(0)}})
		hud = await _abrir_hud()
		for tam in [Vector2i(1280, 720), Vector2i(844, 390), Vector2i(780, 360)]:
			await _medir(hud, n, tam)
		await _fechar_hud(hud)
		root.size = Vector2i(1920, 1080)
		await process_frame
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)


func _medir(hud: Node, n: int, tam: Vector2i) -> void:
	root.size = tam
	await process_frame
	if root.size != tam:
		_ok(false, "%s pedida, mas a janela ficou %s: sem medida" % [tam, root.size])
		return
	hud._ao_redimensionar()
	await _quadros(4)
	var c: Dictionary = hud.caixa_mostrada()
	var r: Rect2 = c["rect"]
	var tela := root.get_visible_rect()
	var escala: float = hud._escala
	var tapa: Array = []
	for p in ["Raiz/Seguro/Camadas/ColunaEsquerda", "Raiz/Seguro/Camadas/Barra"]:
		var no := hud.get_node(p) as Control
		if no.visible and no.get_global_rect().intersects(r):
			tapa.append(p.get_file())
	var faixa := hud.get_node("Raiz/Seguro/Camadas/Faixa") as Label
	var fonte: Font = faixa.get_theme_font("font")
	var tam_letra: int = faixa.get_theme_font_size("font_size")
	var precisa := 0.0
	for t in FRASES_FAIXA:
		precisa = maxf(precisa, fonte.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, tam_letra).x)
	# A largura que a faixa TEM entre as margens (sem o mínimo do texto: é o que sobra entre a ⚙ e a caixa).
	var pai := faixa.get_parent() as Control
	var livre := pai.size.x - faixa.offset_left + faixa.offset_right
	faixa.text = FRASES_FAIXA[0]
	await _quadros(2)
	var rf := faixa.get_global_rect()
	var px_letra := float(tam_letra) * escala
	var linhas_ok := r.size.y <= tela.size.y * 0.5
	var fila: Node = hud._caixa.get_node("VBoxContainer/Corpo/Fila") if hud._caixa.has_node("VBoxContainer/Corpo/Fila") else hud._caixa.find_child("Fila", true, false)
	var slot0: Node = fila.get_child(0)
	var lado_retrato: float = (slot0.get_node("Moldura") as Control).size.y
	var letra_nome: int = (slot0.get_node("Nome") as Label).get_theme_font_size("font_size")
	print("  MEDIDA %d figuras · %dx%d (unidades %dx%d, escala %.3f): caixa %dx%d u = %dx%d px reais (%.0f%% da largura, %.0f%% da altura) · retrato %d u = %.0f px · nome %d u = %.1f px · letra %d u = %.1f px · %d por linha · faixa livre %d u (precisa %d u) = %d px reais" % [
		n, tam.x, tam.y, int(tela.size.x), int(tela.size.y), escala, int(r.size.x), int(r.size.y), int(r.size.x * escala), int(r.size.y * escala),
		100.0 * r.size.x / tela.size.x, 100.0 * r.size.y / tela.size.y, int(lado_retrato), lado_retrato * escala, letra_nome, float(letra_nome) * escala, tam_letra, px_letra,
		hud._caixa.colunas_fila(), int(livre), int(precisa), int(livre * escala)])
	_ok(c["visivel"] and (c["ids"] as Array).size() == n, "%d figuras %dx%d: a caixa mostra as %d (%d)" % [n, tam.x, tam.y, n, (c["ids"] as Array).size()])
	_ok(tela.encloses(r), "%d figuras %dx%d: a caixa %s cabe no ecrã %s" % [n, tam.x, tam.y, r, tela])
	_ok(tapa.is_empty(), "%d figuras %dx%d: a caixa não tapa a ⚙/ficha nem a barra %s" % [n, tam.x, tam.y, tapa])
	_ok(linhas_ok, "%d figuras %dx%d: a caixa não passa de metade da altura (%d de %d u)" % [n, tam.x, tam.y, int(r.size.y), int(tela.size.y)])
	_ok(livre >= precisa and not rf.intersects(r), "%d figuras %dx%d: a faixa tem %d u livres para a frase mais comprida (%d u), numa linha, sem passar por baixo da caixa (faixa %s)" % [
		n, tam.x, tam.y, int(livre), int(precisa), rf])
	# Ordem CAIXA-PADRAO-BUSTO: o lado mede-se pela constante da caixa (hoje 3,4 letras; era 2,8).
	var em_letras: float = hud._caixa.LADO_RETRATO_EM_LETRAS
	_ok(absf(lado_retrato - float(hud._fonte) * em_letras) <= 1.0, "%d figuras %dx%d: a fila segue a letra de agora (retrato %d u = %.1f × %d)" % [n, tam.x, tam.y, int(lado_retrato), em_letras, hud._fonte])
	_ok(px_letra >= 13.0 - 0.01, "%d figuras %dx%d: a letra da faixa tem %.1f px reais (≥ 13)" % [n, tam.x, tam.y, px_letra])
	# Ordem CAIXA-PADRAO-CORRECOES (B6): a LARGURA RENDERIZADA slot a slot (não só a altura da moldura do 1.º):
	# o rectângulo que um quadradinho ocupa no ecrã, e a moldura nele, têm sempre a largura da célula fixa da caixa.
	var cel: Vector2 = hud._caixa.tamanho_celula()
	var larguras := {}
	var maus: Array = []
	for s in fila.get_children():
		var rs := (s as Control).get_global_rect()
		var rm := (s.get_node("Moldura") as Control).get_global_rect()
		larguras["%.1f" % rs.size.x] = true
		if absf(rs.size.x - cel.x) > 0.5 or absf(rm.size.x - cel.x) > 0.5 or absf(rm.size.y - cel.x) > 0.5:
			maus.append("%s %.1f/%.1f" % [s.name, rs.size.x, rm.size.x])
	# Ordem CAIXA-EXPANDE: as caixinhas pequenas são só os 4 próximos (a vez fica no cartão grande, não aqui).
	var n_fila := mini(hud._caixa.MAX_FILA, n - 1)
	_ok(maus.is_empty() and larguras.size() == 1 and fila.get_child_count() == n_fila and not fila.has_node("Slot_" + str(c["vez"])),
		"%d figuras %dx%d: os %d slots (os próximos, sem a vez) renderizam com a largura da célula (%s u = %.1f px reais por slot; moldura quadrada) %s" % [
			n, tam.x, tam.y, fila.get_child_count(), larguras.keys(), cel.x * escala, maus])
	await _medir_expandida(hud, n, tam)


## Ordem CAIXA-EXPANDE: a vista expandida com n figuras num ecrã: o rato por cima (eventos a sério) abre-a; mostra a
## ordem inteira, com os nomes completos; cabe no ecrã sem descer abaixo do topo da barra (se não couber, a lista rola);
## a borda direita fica no sítio; a faixa não se mexe; tirar o rato volta à compacta.
func _medir_expandida(hud: Node, n: int, tam: Vector2i) -> void:
	var cx: Control = hud._caixa
	var faixa := hud.get_node("Raiz/Seguro/Camadas/Faixa") as Label
	var barra := hud.get_node("Raiz/Seguro/Camadas/Barra") as Control
	var r0 := cx.get_global_rect()
	var margens0 := Vector2(faixa.offset_left, faixa.offset_right)
	_rato(r0.get_center())
	await _quadros(3)
	var r := cx.get_global_rect()
	var tela := root.get_visible_rect()
	var c: Dictionary = hud.caixa_mostrada()
	var lista: Node = cx.find_child("Lista", true, false)
	var rol := cx.find_child("Expandida", true, false) as ScrollContainer
	var linha0 := lista.get_child(0) as Control
	var cortadas: Dictionary = cx.linhas_cortadas()
	var rola: bool = cx.expandida_rola()
	var sep := float(lista.get_theme_constant("separation"))
	var cabem := n if not rola else int(floor((rol.size.y + sep + 0.5) / (linha0.size.y + sep)))
	var topo_barra := barra.get_global_rect().position.y
	print("  MEDIDA EXPANDIDA %d figuras · %dx%d: caixa %dx%d u = %dx%d px reais (compacta %dx%d u) · %d linhas de %d u (retrato %d u) · à vista sem rolar %d · rola %s · nomes cortados %s · fundo %d u (topo da barra %d u)" % [
		n, tam.x, tam.y, int(r.size.x), int(r.size.y), int(r.size.x * hud._escala), int(r.size.y * hud._escala), int(r0.size.x), int(r0.size.y),
		lista.get_child_count(), int(linha0.size.y), int((linha0.get_child(0) as Control).size.x), mini(cabem, n), "SIM" if rola else "NÃO", cortadas, int(r.end.y), int(topo_barra)])
	_ok(c["expandida"] and c["ordem_expandida"].size() == n and lista.get_child_count() == n and c["ordem_expandida"][0] == c["vez"],
		"%d figuras %dx%d: [expandida] o rato por cima abre a ordem inteira, a vez primeiro (%d linhas)" % [n, tam.x, tam.y, lista.get_child_count()])
	_ok(cortadas.is_empty(), "%d figuras %dx%d: [expandida] todos os nomes completos à vista, sem corte %s" % [n, tam.x, tam.y, cortadas])
	var coluna := hud.get_node("Raiz/Seguro/Camadas/ColunaEsquerda") as Control
	var tapa := faixa.get_global_rect().intersects(r) or (coluna.visible and coluna.get_global_rect().intersects(r))
	_ok(tela.encloses(r) and r.end.y <= topo_barra + 0.5 and absf(r.end.x - r0.end.x) <= 0.5 and r.size.x >= r0.size.x and r.size.y >= r0.size.y and not tapa,
		"%d figuras %dx%d: [expandida] cresce para baixo, encostada à direita, cabe no ecrã acima da barra e não tapa a faixa nem a ⚙ (%s; barra em y %d)" % [n, tam.x, tam.y, r, int(topo_barra)])
	_ok(rola == (lista.get_combined_minimum_size().y > rol.size.y + 0.5) and Vector2(faixa.offset_left, faixa.offset_right) == margens0,
		"%d figuras %dx%d: [expandida] o que não cabe rola por dentro (rola %s) e a faixa não se mexe" % [n, tam.x, tam.y, rola])
	_rato(r.end + Vector2(40, 40) if r.end.x + 40.0 < tela.end.x else r.position - Vector2(40, -40))
	await _quadros(3)
	_ok(not hud.caixa_mostrada()["expandida"] and cx.get_global_rect().is_equal_approx(r0),
		"%d figuras %dx%d: [expandida] tirar o rato volta à compacta (%s)" % [n, tam.x, tam.y, cx.get_global_rect()])


## Ordem CAIXA-EXPANDE: um movimento do rato a sério, em coordenadas da janela.
func _rato(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	root.push_input(e, true)
