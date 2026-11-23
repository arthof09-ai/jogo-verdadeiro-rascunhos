extends SceneTree
## Ordem CAIXA-HUD-JOGADORA — a caixa da ordem de turnos no HUD da jogadora (hud/hud.gd), sem servidor e sem ecrã.
##
##   godot --headless --path cliente -s res://testes/caixa_jogadora.gd
##
## O HUD a sério recebe o tráfego pela Rede (ROOM_WELCOME, ROOM_SNAPSHOT com `caixa`, ROOM_EVENT) e a caixa mostra a
## escolha do Mestre: ligada/desligada, modo dinâmico (a ordem da Party, adiantada pelos eventos) ou iniciativa
## (`iniciativa` + `vezId`). Sem o campo, na sala de espera ou no lobby, não aparece. Não tapa a ⚙, a ficha nem a barra.
## §7 (Ordem CAIXA-JANELA): os eventos que chegam entre o snapshot e a abertura do HUD aparecem na caixa ao abrir.
## §8 (Ordem CAIXA-HUD-JOGADORA-MEDICAO-8-FIGURAS): 8 figuras na ordem, em 844×390 e 780×360 (e 1920×1080 de controlo):
##    a caixa não tapa a ⚙/ficha, a barra nem a faixa e nada fica cortado (contam); a faixa centrada mede-se e regista-se
##    (REGISTO ..., não conta: com a caixa larga, a faixa centra-se entre a ⚙ e a caixa, por desenho da CAIXA-JANELA B3).
##    As medidas saem no registo (MEDIDA ...). O critério está em provas/ordem-caixa-hud-jogadora/medicao-8-figuras/CRITERIO.md.
##    Ordem CAIXA-HUD-JOGADORA-TECTO-DESVIO-PONTO-4: o desvio do centro da faixa tem um TECTO por resolução (não pior que
##    hoje: 539,0 / 576,0 / 350,5 u), que conta. É um tripwire, não a fasquia (a fasquia do critério é ≤ 1 u); quando o
##    EXPANDE entrar, o tecto actualiza-se com a nova medição.
##    Ordem CAIXA-PADRAO-CORRECOES (B9): os tectos passam a 542,5 / 587,5 / 343,5 u — não pior que a caixa do
##    padrão-busto. Ordem CAIXA-EXPANDE (F4): a caixa compacta (4 caixinhas) e a recentragem da faixa baixam-nos para
##    0,0 / 11,5 / 0,0 u (ver TECTO_DESVIO_8). A variante estrita (o ponto 4 a contar, ≤ 1 u, em vez do
##    tecto) corre-se com `-- --estrita` (o CI corre sem a opção):
##      godot --headless --path cliente -s res://testes/caixa_jogadora.gd -- --estrita
## §9 (Ordem CAIXA-EXPANDE): a recentragem da faixa (hud.gd faixa_recentrada) em casos puros, e o toque na caixa no HUD
##    a sério (844×390, 8 figuras): um toque abre a vista expandida, outro fecha, um toque fora fecha; a faixa não mexe.
## Código de saída 0 se tudo passa, 1 se algo falha.

var _total := 0
var _falhas := 0
var _rede: Node
var _estado: Node
var _seq := 0
## §8: as figuras do snapshot (vazio = as 3 de sempre).
var _figs: Array = []
## §8: nomes públicos genéricos, até 10 letras (o corte da caixa), para encher a fila.
const NOMES_8 := ["Espadachim", "Arqueira", "Criatura", "Criatura", "Personagem", "Criatura", "Criatura", "Criatura"]
## §8: o tecto do desvio do centro da faixa (u), por resolução: o desvio medido (não pior que hoje).
## Ordem CAIXA-PADRAO-CORRECOES (B9) tinha 542,5 / 587,5 / 343,5 u — os da caixa do padrão-busto (8 caixinhas, uma por
## figura) com a faixa «centrada entre a ⚙ e a caixa».
## Ordem CAIXA-EXPANDE (F4, a recentragem): NÃO PIOR QUE A CAIXA COMPACTA RECENTRADA. Duas mudanças, medidas uma a uma:
## (1) a caixa compacta mostra só o cartão grande e os 4 próximos — 1193 → 689 u (844×390), 1292 → 744 u (780×360),
## 753 → 437 u (1920×1080); só com isto, pela regra antiga, o desvio seria 0,0 / 313,5 / 0,0 u (a 780×360 a faixa
## larga centrada não cabe por 23 u e ia para o meio entre a ⚙ e a caixa); (2) a recentragem (hud.gd
## faixa_recentrada): a faixa fica o mais perto do centro que o espaço livre deixa, sem encolher a caixa — a 780×360
## encosta-se à caixa com a largura que precisa (788 u) e o desvio fica 11,5 u. Medido: 0,0 / 11,5 / 0,0 u. A guarda
## dispara se se baixar 0,5 u um tecto qualquer (provas/ordem-caixa-expande/tecto/sensibilidade.log).
const TECTO_DESVIO_8 := {Vector2i(844, 390): 0.0, Vector2i(780, 360): 11.5, Vector2i(1920, 1080): 0.0}
## §8: a variante estrita (`-- --estrita`): o ponto 4 conta com a fasquia do critério (≤ 1 u), em vez do tecto.
var _estrita := OS.get_cmdline_user_args().has("--estrita")


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


func _figura(id: String, nome: String, lado: String, x: int) -> Dictionary:
	return {"id": id, "nomePublico": nome, "lado": lado, "x": x, "y": 2, "orientacao": "S", "visivel": "de_pe"}


func _snapshot(caixa, fase := "combate", vez := "j1") -> void:
	_seq += 1
	var s := {
		"type": "ROOM_SNAPSHOT", "seq": _seq, "revision": 5, "ts": "2026-11-20T12:00:00.000Z", "fase": fase,
		"mapa": {"largura": 20, "altura": 20, "casaM": 1.5},
		"figuras": _figs if not _figs.is_empty() else [_figura("j1", "Heroína", "jogadora", 2), _figura("j2", "Aliada", "jogadora", 3), _figura("m1", "Criatura", "criatura", 6)],
		"iniciativa": _figs.map(func(f): return f["id"]) if not _figs.is_empty() else ["m1", "j1", "j2"], "vezId": vez, "rodada": 1,
		"ambiente": {"clima": null, "luz": null}, "fogo": {"casas": [], "aArder": []},
		"propria": {"figuraId": "j1", "vidaActual": 10, "vidaTotal": 10, "paLivre": 1, "paTotal": 1, "estadoMorte": null,
			"armaCaida": false, "armaQuebrada": false, "corpoPartido": false, "ficha": {}},
	}
	if caixa != null:
		s["caixa"] = caixa
	_receber(s)


func _evento(tipo: String, dados: Dictionary) -> void:
	_seq += 1
	_receber({"type": "ROOM_EVENT", "seq": _seq, "revision": 5, "ts": "2026-11-20T12:00:01.000Z", "tipo": tipo, "dados": dados})


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	root.size = Vector2i(1920, 1080)  # sem ecrã a janela nasce pequena (ver medir_painel_config.gd)
	await process_frame
	_rede.persistir = false
	_rede.papel = "jogadora"
	_receber({"type": "ROOM_WELCOME", "seatId": "s1", "seatToken": "t", "papel": "jogadora"})

	print("== 1. o snapshot chega ANTES de o HUD abrir (a jogadora entra pelo lobby) ==")
	_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ["j2", "j1"], "fechada": false, "ultimo": "j1"}})
	var hud = (load("res://hud/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	hud._ao_redimensionar()
	await _quadros(3)
	var c: Dictionary = hud.caixa_mostrada()
	_ok(c["visivel"] and c["modo"] == "dinamico", "a caixa aparece ligada, no modo dinâmico, com o snapshot de antes do HUD")
	_ok(c["ids"] == ["j2", "j1"] and c["vez"] == "j1", "a ordem e a vez são as do servidor (%s, vez %s)" % [c["ids"], c["vez"]])

	print("== 2. os eventos que ela recebe adiantam a caixa (as mesmas regras do servidor) ==")
	_evento("movimento", {"figuraId": "m1", "de": {"x": 6, "y": 2}, "para": {"x": 6, "y": 3}, "caminho": []})
	await _quadros(2)
	c = hud.caixa_mostrada()
	_ok(c["ids"] == ["j2", "j1", "m1"] and c["vez"] == "m1", "quem age pela 1.ª vez entra no fim e fica na vez (%s)" % [c["ids"]])
	_evento("ataque", {"atacanteId": "j2", "alvoId": "m1", "arma": "x", "resultado": "erro", "ataqueDeOportunidade": true})
	await _quadros(2)
	_ok(hud.caixa_mostrada()["vez"] == "m1", "o ataque de oportunidade não é «ir»")
	_evento("ataque", {"atacanteId": "j2", "alvoId": "m1", "arma": "x", "resultado": "erro", "ataqueDeOportunidade": false})
	await _quadros(2)
	c = hud.caixa_mostrada()
	_ok(c["ids"] == ["j2", "j1", "m1"] and c["vez"] == "j2", "quem volta a agir fecha a volta (vez %s)" % c["vez"])

	print("== 3. o Mestre escolhe o modo iniciativa ==")
	_snapshot({"ligada": true, "ordemPor": "iniciativa", "ordemDinamica": {"ordem": ["j2", "j1", "m1"], "fechada": true, "ultimo": "j2"}}, "combate", "m1")
	await _quadros(2)
	c = hud.caixa_mostrada()
	_ok(c["visivel"] and c["modo"] == "iniciativa" and c["ids"] == ["m1", "j1", "j2"] and c["vez"] == "m1",
		"a caixa mostra a ordem de iniciativa e a vez do servidor (%s, vez %s)" % [c["ids"], c["vez"]])
	_evento("turno", {"figuraId": "j1", "rodada": 1, "narra": "x"})
	await _quadros(2)
	_ok(hud.caixa_mostrada()["vez"] == "j1", "no modo iniciativa a vez segue o `turno` do servidor")

	print("== 4. o Mestre desliga a caixa; sem o campo; fora do combate ==")
	_snapshot({"ligada": false, "ordemPor": "iniciativa", "ordemDinamica": {"ordem": [], "fechada": false, "ultimo": null}})
	await _quadros(2)
	_ok(not hud.caixa_mostrada()["visivel"], "desligada pelo Mestre: a caixa não aparece")
	_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ["j1"], "fechada": false, "ultimo": "j1"}})
	await _quadros(2)
	_ok(hud.caixa_mostrada()["visivel"], "religada: volta a aparecer")
	_snapshot(null)
	await _quadros(2)
	_ok(not hud.caixa_mostrada()["visivel"], "snapshot sem `caixa` (sala de espera, servidor de antes): não aparece")
	_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": [], "fechada": false, "ultimo": null}}, "lobby", "")
	await _quadros(2)
	_ok(not hud.caixa_mostrada()["visivel"], "no lobby a caixa não aparece (só em combate e em pausa)")

	print("== 5. uma MASTER_VIEW a chegar ao aparelho dela não mexe na caixa ==")
	_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ["j1", "j2"], "fechada": false, "ultimo": "j2"}})
	await _quadros(2)
	_receber({"type": "MASTER_VIEW", "caixaMestre": {"ligada": false, "modo": "iniciativa"}, "ordemDinamica": {"ordem": ["m1"], "fechada": true, "ultimo": "m1"}})
	await _quadros(2)
	c = hud.caixa_mostrada()
	_ok(c["visivel"] and c["modo"] == "dinamico" and c["ids"] == ["j1", "j2"], "a caixa continua a do snapshot dela")

	print("== 6. o sítio: não tapa a ⚙, a ficha, a barra nem a faixa ==")
	for tam in [Vector2i(1920, 1080), Vector2i(1280, 720), Vector2i(844, 390), Vector2i(780, 360)]:
		root.size = tam
		await process_frame
		if root.size != tam:
			_ok(false, "%s pedida, mas a janela ficou %s: sem medida" % [tam, root.size])
			continue
		hud._ao_redimensionar()
		await _quadros(4)
		c = hud.caixa_mostrada()
		var r: Rect2 = c["rect"]
		var tapa: Array = []
		for p in ["Raiz/Seguro/Camadas/ColunaEsquerda", "Raiz/Seguro/Camadas/Barra", "Raiz/Seguro/Camadas/Faixa"]:
			var n := hud.get_node(p) as Control
			if n.visible and n.get_global_rect().intersects(r):
				tapa.append(p.get_file())
		var tela := root.get_visible_rect()
		_ok(c["visivel"] and tapa.is_empty() and tela.encloses(r), "%dx%d (fonte %d): a caixa %s cabe no ecrã %s e não tapa nada %s" % [tam.x, tam.y, hud._fonte, r, tela, tapa])
	hud.queue_free()
	await process_frame

	print("== 7. Ordem CAIXA-JANELA: eventos ANTES de o HUD abrir (a batalha anda entre o snapshot e o _ready) ==")
	# O §1 só cobre o snapshot de antes do HUD. Aqui, depois do snapshot e antes de a arena abrir, a Criatura anda e a
	# Aliada ataca: a caixa tem de os mostrar logo ao abrir, sem esperar pelo snapshot seguinte.
	root.size = Vector2i(1920, 1080)
	await process_frame
	_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ["j1"], "fechada": false, "ultimo": "j1"}})
	_evento("movimento", {"figuraId": "m1", "de": {"x": 6, "y": 2}, "para": {"x": 6, "y": 3}, "caminho": []})
	_evento("ataque", {"atacanteId": "j2", "alvoId": "m1", "arma": "x", "resultado": "erro", "ataqueDeOportunidade": false})
	hud = (load("res://hud/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	hud._ao_redimensionar()
	await _quadros(3)
	c = hud.caixa_mostrada()
	_ok(c["visivel"] and c["ids"] == ["j1", "m1", "j2"] and c["vez"] == "j2",
		"os eventos de antes do HUD estão na caixa ao abrir (%s, vez %s), sem esperar pelo snapshot seguinte" % [c["ids"], c["vez"]])
	_evento("movimento", {"figuraId": "j1", "de": {"x": 2, "y": 2}, "para": {"x": 2, "y": 3}, "caminho": []})
	await _quadros(2)
	c = hud.caixa_mostrada()
	_ok(c["ids"] == ["j1", "m1", "j2"] and c["vez"] == "j1" and hud.ordem_turnos.fechada,
		"e os de depois seguem pelo sinal: a Heroína volta a agir e a volta fecha (vez %s)" % c["vez"])
	hud.queue_free()
	await process_frame

	print("== 8. Ordem CAIXA-HUD-JOGADORA-MEDICAO-8-FIGURAS: 8 figuras, ecrãs baixos e o controlo ==")
	_figs = []
	var ordem8: Array = []
	for i in 8:
		var id8 := "j1" if i == 0 else ("j2" if i == 1 else "m%d" % (i - 1))
		_figs.append(_figura(id8, NOMES_8[i], "jogadora" if i < 2 else "criatura", 2 + i))
		ordem8.append(id8)
	root.size = Vector2i(1920, 1080)
	await process_frame
	_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ordem8, "fechada": true, "ultimo": "j1"}})
	hud = (load("res://hud/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	hud._ao_redimensionar()
	await _quadros(3)
	for tam in [Vector2i(844, 390), Vector2i(780, 360), Vector2i(1920, 1080)]:
		await _medir_8(hud, tam)

	print("== 9. Ordem CAIXA-EXPANDE: a recentragem da faixa (F4) e o toque na caixa ==")
	# A conta pura: (largura, ⚙, caixa, precisa) -> margens. Centrada se cabe; senão, o mais perto do centro.
	var m1: Vector2 = hud.faixa_recentrada(1000.0, 100.0, 300.0, 400.0)
	var m2: Vector2 = hud.faixa_recentrada(1000.0, 100.0, 400.0, 400.0)
	var m3: Vector2 = hud.faixa_recentrada(1000.0, 100.0, 400.0, 600.0)
	_ok(m1 == Vector2(300, 300), "F4: se a faixa larga centrada cabe, as margens são iguais (desvio 0) %s" % m1)
	_ok(m2 == Vector2(200, 400), "F4: se não cabe centrada, fica com a largura que precisa, encostada à caixa, o mais perto do centro (desvio 100 u; a regra antiga dava 150 u) %s" % m2)
	_ok(m3 == Vector2(100, 400), "F4: se nem a largura que precisa cabe, ocupa o espaço livre todo (a regra antiga) %s" % m3)
	# O toque na caixa, no HUD a sério (844×390, 8 figuras): abre e fecha a mesma vista expandida; a faixa não se mexe.
	root.size = Vector2i(844, 390)
	await process_frame
	hud._ao_redimensionar()
	await _quadros(4)
	var faixa9 := hud.get_node("Raiz/Seguro/Camadas/Faixa") as Label
	var margens9 := Vector2(faixa9.offset_left, faixa9.offset_right)
	var r9: Rect2 = hud.caixa_mostrada()["rect"]
	_tocar(r9.get_center())
	await _quadros(3)
	c = hud.caixa_mostrada()
	var r_aberta: Rect2 = c["rect"]
	_ok(c["expandida"] and (c["ordem_expandida"] as Array).size() == 8 and r_aberta.size.y > r9.size.y and is_equal_approx(r_aberta.end.x, r9.end.x)
		and Vector2(faixa9.offset_left, faixa9.offset_right) == margens9,
		"toque: um toque na caixa abre a ordem inteira (%d), encostada à direita (%s), e a faixa não se mexe" % [(c["ordem_expandida"] as Array).size(), r_aberta])
	_tocar(r_aberta.get_center())
	await _quadros(3)
	c = hud.caixa_mostrada()
	_ok(not c["expandida"] and (c["rect"] as Rect2).is_equal_approx(r9), "toque: outro toque na caixa fecha-a (volta a %s)" % [c["rect"]])
	_tocar(r9.get_center())
	await _quadros(2)
	_tocar(Vector2(root.get_visible_rect().size.x * 0.5, root.get_visible_rect().size.y * 0.5))
	await _quadros(2)
	_ok(not hud.caixa_mostrada()["expandida"], "toque: com a caixa aberta, um toque fora dela fecha-a")
	hud.queue_free()
	_figs = []
	await process_frame
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)


## §9: um toque (carrega e levanta no mesmo sítio), em coordenadas da janela.
func _tocar(p: Vector2) -> void:
	for k in 2:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.pressed = k == 0
		t.position = p
		root.push_input(t, true)


## §8: mede a caixa com 8 figuras numa resolução, contra os 5 pontos do CRITERIO.md.
func _medir_8(hud: Node, tam: Vector2i) -> void:
	root.size = tam
	await process_frame
	if root.size != tam:
		_ok(false, "8 figuras: %s pedida, mas a janela ficou %s: sem medida" % [tam, root.size])
		return
	hud._ao_redimensionar()
	await _quadros(4)
	var faixa := hud.get_node("Raiz/Seguro/Camadas/Faixa") as Label
	faixa.text = hud.FAIXA_MAIS_LONGA  # a frase mais comprida que a faixa mostra (a da pausa)
	hud._posicionar_caixa()
	await _quadros(2)
	var c: Dictionary = hud.caixa_mostrada()
	var r: Rect2 = c["rect"]
	var tela := root.get_visible_rect()
	var escala: float = hud._escala
	var rf := faixa.get_global_rect()
	var pai := faixa.get_parent() as Control
	var livre := pai.size.x - faixa.offset_left + faixa.offset_right
	var precisa: float = hud.largura_faixa_precisa()
	var desvio_margens := absf(faixa.offset_left + faixa.offset_right)  # esq − dir (offset_right é negativo)
	var desvio_centro := absf(rf.get_center().x - tela.get_center().x)
	var coluna := hud.get_node("Raiz/Seguro/Camadas/ColunaEsquerda") as Control
	var barra := hud.get_node("Raiz/Seguro/Camadas/Barra") as Control
	var tapa_coluna := coluna.visible and coluna.get_global_rect().intersects(r)
	var tapa_barra := barra.visible and barra.get_global_rect().intersects(r)
	var tapa_faixa := faixa.visible and rf.intersects(r)
	var fila: Node = hud._caixa.find_child("Fila", true, false)
	var slots_fora: Array = []
	for s in fila.get_children():
		if not r.grow(0.5).encloses((s as Control).get_global_rect()):
			slots_fora.append(s.name)
	var centrada := desvio_margens <= 1.0 and desvio_centro <= 1.0
	# Ordem CAIXA-EXPANDE (F4): o desvio que a regra ANTIGA (a faixa «centrada entre a ⚙ e a caixa», CAIXA-JANELA B3)
	# daria com esta mesma caixa — para separar o que a caixa compacta mudou do que a recentragem mudou.
	var esq_min := float(hud._fonte) * 3.5
	var dir_caixa := maxf(esq_min, (hud._caixa.tamanho_compacto() as Vector2).x + float(hud._fonte) * 0.5)
	var desvio_antigo := 0.0 if pai.size.x - 2.0 * dir_caixa >= precisa else (dir_caixa - esq_min) * 0.5
	var cabe := tela.encloses(r) and slots_fora.is_empty() and livre >= precisa
	var sobrepoe := tapa_coluna or tapa_barra or tapa_faixa
	print("  MEDIDA 8 figuras · %dx%d (tela %dx%d u, escala %.3f, fonte %d): caixa %dx%d u = %dx%d px reais (altura %.0f%% do ecrã) · %d por linha · faixa livre %d u (precisa %d u), margens esq %d / dir %d u, desvio do centro %.1f u (pela regra antiga, com esta caixa: %.1f u) · sobreposição %s (ficha %s, barra %s, faixa %s) · centrada %s · cortado %s" % [
		tam.x, tam.y, int(tela.size.x), int(tela.size.y), escala, hud._fonte, int(r.size.x), int(r.size.y),
		int(round(r.size.x * escala)), int(round(r.size.y * escala)), 100.0 * r.size.y / tela.size.y, hud._caixa.colunas_fila(),
		int(livre), int(precisa), int(faixa.offset_left), int(-faixa.offset_right), desvio_centro, desvio_antigo,
		"SIM" if sobrepoe else "NÃO", tapa_coluna, tapa_barra, tapa_faixa, "SIM" if centrada else "NÃO", "NÃO" if cabe else "SIM"])
	_ok(c["visivel"] and (c["ids"] as Array).size() == 8 and (c["fila"] as Array).size() == 4 and not (c["fila"] as Array).has(c["vez"]),
		"8 figuras %dx%d: a caixa tem as 8 (%d) — na compacta, a vez no cartão grande e os 4 próximos %s" % [tam.x, tam.y, (c["ids"] as Array).size(), c["fila"]])
	_ok(not tapa_coluna, "8 figuras %dx%d: não tapa a ⚙/ficha" % [tam.x, tam.y])
	_ok(not tapa_barra and barra.visible, "8 figuras %dx%d: não tapa a barra inferior (barra visível %s)" % [tam.x, tam.y, barra.visible])
	_ok(not tapa_faixa, "8 figuras %dx%d: não tapa a faixa de cima (faixa %s, caixa %s)" % [tam.x, tam.y, rf, r])
	# O ponto 4 do critério (a faixa centrada) MEDE-SE e regista-se, mas não conta para o código de saída: com a caixa
	# larga a faixa centrava-se entre a ⚙ e a caixa POR DESENHO (Ordem CAIXA-JANELA B3). A 1.ª corrida, com ele a contar,
	# está em provas/.../medicao-8-figuras/corrida-1-criterio.log. Ordem CAIXA-EXPANDE: com a caixa compacta e a
	# recentragem, 844×390 e 1920×1080 ficam centradas (0,0 u); 780×360 fica a 11,5 u (a faixa larga centrada não cabe).
	print("  REGISTO (não conta) 8 figuras %dx%d: a faixa centrada no ecrã? %s (margens %d / %d u, desvio %.1f u)" % [
		tam.x, tam.y, "SIM" if centrada else "NÃO", int(faixa.offset_left), int(-faixa.offset_right), desvio_centro])
	# Ordem CAIXA-HUD-JOGADORA-TECTO-DESVIO-PONTO-4: o tecto (tripwire), não pior que hoje. Se a centragem piorar, falha.
	# Na variante estrita (`-- --estrita`) conta a fasquia do critério (≤ 1 u) em vez do tecto: com o EXPANDE dá 41/42 (só 780×360).
	if _estrita:
		_ok(centrada, "8 figuras %dx%d: [estrita] a faixa continua centrada (desvio %.1f u ≤ 1 u, margens %d / %d u)" % [
			tam.x, tam.y, desvio_centro, int(faixa.offset_left), int(-faixa.offset_right)])
	else:
		var tecto: float = TECTO_DESVIO_8[tam]
		_ok(desvio_centro <= tecto, "8 figuras %dx%d: o desvio do centro da faixa não piora (%.1f u ≤ tecto %.1f u; não pior que a caixa compacta recentrada)" % [
			tam.x, tam.y, desvio_centro, tecto])
	_ok(cabe, "8 figuras %dx%d: nada cortado (caixa no ecrã %s, quadradinhos fora %s, faixa %d ≥ %d u)" % [tam.x, tam.y, tela.encloses(r), slots_fora, int(livre), int(precisa)])
