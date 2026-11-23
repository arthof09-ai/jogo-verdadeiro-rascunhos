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
## §10 (Ordem CAIXA-EXPANDE-INTERACAO): com a câmara da mesa a sério por baixo — o toque fora que fecha a expandida não
##    chega ao tabuleiro (D1) e a roda no topo e no fim da lista não lhe dá zoom (D3). Ver `_interacao`.
## §11 (Ordem F27 da sentença da CAIXA-EXPANDE-INTERACAO): o D1 com MOVIMENTO — a ARENA a sério (cenas/arena/arena.tscn:
##    o HUD, a câmara e o `_ao_toque` dela), a jogadora na vez, o Mover aberto pelo botão da barra, e o toque fora a cair
##    numa casa de destino. Com a expandida aberta por toque, o toque fora fecha-a e a figura fica no sítio (nó e casa do
##    Estado iguais, nenhuma intenção na fila); de controlo, com a caixa fechada, o mesmo toque escolhe essa casa e sai a
##    intenção `mover` para ela. Ver `_mover_aberto`.
## Código de saída 0 se tudo passa, 1 se algo falha.

const CameraMesa := preload("res://camera/camera_mesa.gd")

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
	await _interacao(hud)
	hud.queue_free()
	_figs = []
	await process_frame
	await _mover_aberto()
	_figs = []
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)


## §10 (Ordem CAIXA-EXPANDE-INTERACAO): o tabuleiro por baixo da caixa — a CÂMARA DA MESA a sério (camera/camera_mesa.gd,
## a que dá a arena o `toque` → mover/escolher a casa, e a roda → zoom), no HUD a sério, com 12 e 16 figuras em 844×390 e
## 780×360. Os gestos vão pelo Input do motor (Input.parse_input_event, em píxeis da janela), o caminho do aparelho: o
## motor imita o rato a partir do toque e despacha esse rato ANTES do toque.
##   D1  com a expandida aberta por toque, um toque fora fecha-a e o tabuleiro fica QUIETO: o `toque` da câmara não
##       dispara (nenhuma casa escolhida: nenhuma figura movida nem seleccionada) e ela não fica com o toque armado. De
##       controlo: o toque seguinte, com a caixa fechada, chega ao tabuleiro (o `toque` dispara uma vez).
##   D3  a roda em cima da expandida, no topo e no fim da lista, não muda o zoom do tabuleiro (medido antes e depois); a
##       lista rola com ela pelo meio. De controlo: a roda fora da caixa dá zoom.
func _interacao(hud: Node) -> void:
	print("== 10. Ordem CAIXA-EXPANDE-INTERACAO: o tabuleiro por baixo da caixa (toque fora, roda nos fins) ==")
	var cam := CameraMesa.new()
	cam.name = "CameraDaMesa"
	root.add_child(cam)
	cam.configurar_arena(Vector3(15.0, 0.0, 15.0), Vector2(30.0, 30.0))
	var toques: Array = []
	cam.toque.connect(func(p: Vector2): toques.append(p))
	await _quadros(2)
	var cx: Control = hud._caixa
	for n in [12, 16]:
		_figs = []
		var ordem: Array = []
		for i in n:
			var fid := "j1" if i == 0 else ("j2" if i == 1 else "m%d" % (i - 1))
			_figs.append(_figura(fid, NOMES_8[i % NOMES_8.size()], "jogadora" if i < 2 else "criatura", 2 + (i % 16)))
			ordem.append(fid)
		_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ordem, "fechada": true, "ultimo": "j1"}})
		await _quadros(2)
		for tam in [Vector2i(844, 390), Vector2i(780, 360)]:
			root.size = tam
			await process_frame
			if root.size != tam:
				_ok(false, "§10 %d figuras: %s pedida, mas a janela ficou %s: sem medida" % [n, tam, root.size])
				continue
			hud._ao_redimensionar()
			await _quadros(4)
			var rot := "§10 %d figuras %dx%d" % [n, tam.x, tam.y]
			var fora := _fora_da_caixa(hud)
			# D1 — o toque fora que fecha a expandida não chega ao tabuleiro.
			var r0: Rect2 = hud.caixa_mostrada()["rect"]
			_tocar_motor(r0.get_center())
			await _quadros(3)
			var abriu: bool = hud.caixa_mostrada()["expandida"] and (hud.caixa_mostrada()["ordem_expandida"] as Array).size() == n
			var n_toques := toques.size()
			_tocar_motor(fora)
			await _quadros(3)
			var fechou: bool = not hud.caixa_mostrada()["expandida"]
			var depois_fechar := toques.size() - n_toques
			var armado: bool = cam._esq
			_tocar_motor(fora)
			await _quadros(3)
			var depois_controlo := toques.size() - n_toques - depois_fechar
			print("  MEDIDA D1 %s: abriu por toque %s · toque fora em %s u: fechou %s, «toque» do tabuleiro %d vez(es), toque armado %s · controlo (caixa fechada): «toque» %d vez(es)" % [
				rot, abriu, fora, fechou, depois_fechar, armado, depois_controlo])
			_ok(abriu and fechou and depois_fechar == 0 and not armado,
				"%s: [D1] com a expandida aberta, um toque fora fecha-a e o tabuleiro fica quieto (o «toque» da câmara não dispara: %d; não fica armado)" % [rot, depois_fechar])
			_ok(depois_controlo == 1 and not hud.caixa_mostrada()["expandida"],
				"%s: [D1] de controlo, o toque seguinte (caixa fechada) chega ao tabuleiro (o «toque» dispara %d vez)" % [rot, depois_controlo])
			# D3 — a roda nos fins da lista fica na caixa.
			_rato(r0.get_center())
			await _quadros(3)
			var rol := cx.find_child("Expandida", true, false) as ScrollContainer
			var p := rol.get_global_rect().get_center()
			var rola: bool = cx.expandida_rola()
			cam.definir_zoom(cam.ZOOM_PADRAO)
			var z0 := cam.zoom
			# A lista guarda a posição de uma abertura para a outra: leva-se ao topo com a própria roda (para cima até parar).
			var s_aberta := rol.scroll_vertical
			var ultimo := -1
			var subir := 0
			while rol.scroll_vertical != ultimo and subir < 200:
				ultimo = rol.scroll_vertical
				_roda(p, false)
				subir += 1
				await _quadros(1)
			var z_subida := cam.zoom
			var s0 := rol.scroll_vertical
			_roda(p, false)  # no topo, para cima: a lista não rola mais
			await _quadros(2)
			var z_topo := cam.zoom
			var s_topo := rol.scroll_vertical
			ultimo = -1
			var passos := 0
			while rol.scroll_vertical != ultimo and passos < 200:
				ultimo = rol.scroll_vertical
				_roda(p, true)
				passos += 1
				await _quadros(1)
			var s_fim := rol.scroll_vertical
			var z_meio := cam.zoom
			_roda(p, true)  # no fim, para baixo: a lista não rola mais
			await _quadros(2)
			var z_fim := cam.zoom
			var s_fim2 := rol.scroll_vertical
			_rato(fora)
			await _quadros(3)
			_roda(fora, false)  # de controlo: fora da caixa, a roda dá zoom ao tabuleiro
			await _quadros(2)
			var z_controlo := cam.zoom
			cam.definir_zoom(cam.ZOOM_PADRAO)
			print("  MEDIDA D3 %s: rola %s · zoom antes %.3f · abriu na posição %d u, %d passos para cima até ao topo: lista %d u, zoom %.3f · roda para cima no topo: lista %d → %d u, zoom %.3f · %d passos para baixo até ao fim: lista %d u, zoom %.3f · roda para baixo no fim: lista %d → %d u, zoom %.3f · controlo (roda fora da caixa): zoom %.3f" % [
				rot, rola, z0, s_aberta, subir, s0, z_subida, s0, s_topo, z_topo, passos, s_fim, z_meio, s_fim, s_fim2, z_fim, z_controlo])
			_ok(rola and s0 == 0 and s_topo == 0 and s_fim > 0 and s_fim2 == s_fim and z_subida == z0 and z_topo == z0 and z_meio == z0 and z_fim == z0,
				"%s: [D3] a roda no topo e no fim da lista não dá zoom ao tabuleiro (zoom %.3f → %.3f no topo, %.3f no fim; a lista rolou 0 → %d u)" % [rot, z0, z_topo, z_fim, s_fim])
			_ok(not is_equal_approx(z_controlo, z0), "%s: [D3] de controlo, a roda fora da caixa dá zoom ao tabuleiro (%.3f → %.3f)" % [rot, z0, z_controlo])
	cam.queue_free()
	await process_frame


## §11 (Ordem F27): a casa da jogadora no §11 — no meio da grelha 20×20, para as casas de destino caírem à volta dela
## no ecrã (a câmara da arena foca-a no primeiro snapshot).
const CASA_DELA_11 := Vector2i(10, 10)


## §11: as `n` figuras do §11 — a dela (j1) em CASA_DELA_11; as outras nas filas y = 2 e y = 17, longe das casas de destino.
func _figuras_11(n: int) -> Array:
	var figs: Array = []
	for i in n:
		var fid := "j1" if i == 0 else ("j2" if i == 1 else "m%d" % (i - 1))
		var f := _figura(fid, NOMES_8[i % NOMES_8.size()], "jogadora" if i < 2 else "criatura", 2 + ((i - 1) % 8))
		if i == 0:
			f["x"] = CASA_DELA_11.x
			f["y"] = CASA_DELA_11.y
		elif i > 8:
			f["y"] = 17
		figs.append(f)
	return figs


## §11: o ROOM_OPTIONS da vez dela, como o servidor o manda: as casas a até 3 casas da dela (sem figura), com o custo.
func _opcoes_mover_11() -> Array:
	var ocupadas := {}
	for f in _figs:
		ocupadas[Vector2i(int(f["x"]), int(f["y"]))] = true
	var mover: Array = []
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var c := CASA_DELA_11 + Vector2i(dx, dy)
			if c == CASA_DELA_11 or ocupadas.has(c) or c.x < 0 or c.y < 0 or c.x >= 20 or c.y >= 20:
				continue
			mover.append({"x": c.x, "y": c.y, "custoM": 1.5 * maxi(absi(dx), absi(dy))})
	_receber({"type": "ROOM_OPTIONS", "revision": 5, "vezId": "j1", "orcamentoM": 4.5, "mover": mover, "ataques": [],
		"consumiveis": [], "acoes": ["encerrar"], "reacoes": []})
	return mover


## §11: o que um toque no tabuleiro pode mudar — onde estão as figuras (o nó em cena e a casa do Estado), o modo da
## arena e as intenções (a última que saiu e as que estão na fila da Rede).
func _tabuleiro_11(arena: Node) -> Dictionary:
	var nos := {}
	for id in arena._nos:
		var no: Node3D = arena._nos[id]
		nos[id] = "%.2f,%.2f,%.2f" % [no.global_position.x, no.global_position.y, no.global_position.z]
	var casas := {}
	for id in _estado.figuras:
		casas[str(id)] = "%s,%s" % [_estado.figuras[id].get("x"), _estado.figuras[id].get("y")]
	return {"nos": nos, "casas": casas, "modo": arena.modo, "ultima_intencao": arena._ultimo_id,
		"fila": (_rede.fila._itens as Dictionary).keys(), "cursor": arena._cursor}


## §11: o sítio do ecrã (unidades do HUD) de uma casa de destino que um toque escolhe e que fica fora da caixa (`r`, a
## expandida aberta), da ⚙/ficha, da barra, da faixa e da gaveta do Mover: o centro da casa projectado pela câmara da
## arena, e só se a arena, com um toque aí, der essa mesma casa. Prefere a mais próxima do sítio «fora» do §10. [casa, sítio] ou [].
func _destino_fora(hud: Node, arena: Node, r: Rect2) -> Array:
	var evitar: Array = [r.grow(8.0)]
	for p in ["Raiz/Seguro/Camadas/ColunaEsquerda", "Raiz/Seguro/Camadas/Barra", "Raiz/Seguro/Camadas/Faixa"]:
		var n := hud.get_node(p) as Control
		if n.visible:
			evitar.append(n.get_global_rect().grow(8.0))
	if hud._gaveta.is_visible_in_tree():
		evitar.append((hud._gaveta as Control).get_global_rect().grow(8.0))
	var tela := root.get_visible_rect().grow(-12.0)
	var alvo := _fora_da_caixa(hud)
	var melhor: Array = []
	var dist := INF
	var casas: Array = arena._casas.keys()
	casas.sort()
	for c in casas:
		var mundo: Vector3 = arena.centro_casa(c)
		if arena.camera.is_position_behind(mundo):
			continue
		var p: Vector2 = arena.camera.unproject_position(mundo)
		if not tela.has_point(p) or evitar.any(func(e: Rect2): return e.has_point(p)) or arena.casa_em_tela(p) != c:
			continue
		if p.distance_to(alvo) < dist:
			dist = p.distance_to(alvo)
			melhor = [c, p]
	return melhor


## §11 (Ordem F27): o D1 com movimento. A arena a sério (o HUD dela, a câmara dela e o `_ao_toque` que transforma o
## «toque» numa casa e a casa numa intenção), a jogadora na vez com o Mover aberto pelo botão da barra (por toque), com
## 12 e 16 figuras em 844×390 e 780×360:
##   D1  com a expandida aberta por toque, um toque fora — num sítio que cai numa casa de destino — fecha-a e a figura
##       fica no sítio: o nó dela e a casa do Estado iguais, o Mover ainda aberto, nenhuma intenção na fila nem enviada.
##   controlo  com a caixa fechada, o MESMO toque chega ao tabuleiro: escolhe essa casa e sai a intenção
##       `{"tipo": "mover", "destino": casa}` (a figura move-se quando o servidor a aplica; aqui não há servidor — a
##       prova viva, passo 13, mede a figura a andar com o servidor real).
## A Rede fica «na mesa» com um WebSocketPeer por ligar: a intenção regista-se na fila e o envio do texto falha sem erro.
func _mover_aberto() -> void:
	print("== 11. Ordem F27: o D1 com o Mover aberto — a arena a sério, a jogadora na vez, o toque fora numa casa de destino ==")
	root.size = Vector2i(1920, 1080)
	await process_frame
	var ativo_antes: bool = _rede._ativo
	var ligacao_antes: int = _rede.estado_ligacao
	_rede._ativo = true  # a arena chama Rede.iniciar(): sem isto, ia ligar-se a um servidor
	_rede.estado_ligacao = _rede.Ligacao.NA_MESA
	_rede._ws = WebSocketPeer.new()
	_figs = _figuras_11(12)
	var ordem: Array = _figs.map(func(f): return f["id"])
	_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ordem, "fechada": true, "ultimo": "j1"}})
	var arena = (load("res://cenas/arena/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	await _quadros(4)
	var hud = arena.hud
	var toques: Array = []
	arena.camera.toque.connect(func(p: Vector2): toques.append(p))
	var MOVER: int = arena.Modo.MOVER
	for n in [12, 16]:
		_figs = _figuras_11(n)
		ordem = _figs.map(func(f): return f["id"])
		_snapshot({"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": ordem, "fechada": true, "ultimo": "j1"}})
		await _quadros(2)
		for tam in [Vector2i(844, 390), Vector2i(780, 360)]:
			root.size = tam
			await process_frame
			var rot := "§11 %d figuras %dx%d" % [n, tam.x, tam.y]
			if root.size != tam:
				_ok(false, "%s: a janela ficou %s: sem medida" % [rot, root.size])
				continue
			hud._ao_redimensionar()
			await _quadros(4)
			_rede.fila._itens.clear()
			_rede._envios_recentes.clear()
			var opcoes := _opcoes_mover_11()
			await _quadros(2)
			# A vez dela, o Mover aberto pelo botão da barra (um toque, como no aparelho).
			var bm: Control = hud._b_mover
			await _tocar_motor(bm.get_global_rect().get_center())
			await _quadros(3)
			var vez_dela: bool = _estado.e_minha_vez()
			var mover_aberto: bool = arena.modo == MOVER and arena._casas.size() == opcoes.size()
			# A expandida aberta por toque.
			await _tocar_motor((hud.caixa_mostrada()["rect"] as Rect2).get_center())
			await _quadros(3)
			var c: Dictionary = hud.caixa_mostrada()
			var aberta: bool = c["expandida"] and (c["ordem_expandida"] as Array).size() == n
			var destino := _destino_fora(hud, arena, c["rect"])
			_ok(vez_dela and mover_aberto and aberta and not destino.is_empty(),
				"%s: a jogadora na vez (%s), o Mover aberto pelo botão (modo %d, %d casas de destino), a expandida aberta por toque (%s) e um sítio fora dela que cai numa casa de destino %s" % [
					rot, vez_dela, arena.modo, arena._casas.size(), aberta, destino])
			if destino.is_empty():
				continue
			var casa: Vector2i = destino[0]
			var sitio: Vector2 = destino[1]
			# D1 — o toque fora, em cima da casa de destino.
			var t0 := _tabuleiro_11(arena)
			var n0 := toques.size()
			await _tocar_motor(sitio)
			await _quadros(4)
			var t1 := _tabuleiro_11(arena)
			var fechou: bool = not hud.caixa_mostrada()["expandida"]
			var disparou := toques.size() - n0
			print("  MEDIDA D1-MOVER %s: a dela em %s · toque fora em %s u, sobre a casa de destino %s · antes: nó %s, casa %s, modo %d, fila %d, cursor %s · depois: fechou %s, «toque» %d, nó %s, casa %s, modo %d, fila %d, cursor %s, última intenção igual %s" % [
				rot, CASA_DELA_11, sitio, casa, t0["nos"]["j1"], t0["casas"]["j1"], t0["modo"], (t0["fila"] as Array).size(), t0["cursor"],
				fechou, disparou, t1["nos"]["j1"], t1["casas"]["j1"], t1["modo"], (t1["fila"] as Array).size(), t1["cursor"], t0["ultima_intencao"] == t1["ultima_intencao"]])
			_ok(fechou and disparou == 0 and t0 == t1 and t1["modo"] == MOVER and (t1["fila"] as Array).is_empty(),
				"%s: [D1 com o Mover aberto] o toque fora sobre a casa %s fecha a expandida e a figura fica no sítio (nó e casa do Estado iguais, o Mover ainda aberto, nenhuma intenção: fila %d)" % [
					rot, casa, (t1["fila"] as Array).size()])
			# De controlo: com a caixa fechada, o mesmo toque escolhe a casa e sai a intenção de mover para ela.
			await _tocar_motor(sitio)
			await _quadros(4)
			var t2 := _tabuleiro_11(arena)
			var novas: Array = (t2["fila"] as Array).filter(func(id): return not (t1["fila"] as Array).has(id))
			var acao := {}
			if novas.size() == 1:
				acao = (JSON.parse_string(_rede.fila._itens[novas[0]]["texto"]) as Dictionary).get("acao", {})
			var certa: bool = acao.get("tipo") == "mover" and acao.get("destino") is Dictionary \
				and int(acao["destino"].get("x", -1)) == casa.x and int(acao["destino"].get("y", -1)) == casa.y
			print("  MEDIDA CONTROLO-MOVER %s: caixa fechada · o mesmo toque em %s u: «toque» %d · intenções novas %d %s · modo %d → %d" % [
				rot, sitio, toques.size() - n0, novas.size(), JSON.stringify(acao), t1["modo"], t2["modo"]])
			_ok(toques.size() - n0 == 1 and novas.size() == 1 and certa and t2["ultima_intencao"] == novas[0] and t2["modo"] != MOVER,
				"%s: [D1 controlo] com a caixa fechada o mesmo toque chega ao tabuleiro e escolhe a casa %s (sai «mover» para ela: %s)" % [rot, casa, JSON.stringify(acao)])
	_rede.fila._itens.clear()
	_rede._ws = null
	_rede.estado_ligacao = ligacao_antes
	_rede._ativo = ativo_antes
	arena.queue_free()
	await _quadros(2)


## §10: um sítio do tabuleiro fora da caixa, da ⚙/ficha, da barra e da faixa (o meio do ecrã, um pouco abaixo da faixa).
func _fora_da_caixa(hud: Node) -> Vector2:
	var v := root.get_visible_rect().size
	return Vector2(v.x * 0.4, v.y * 0.55)


## §10: um toque pelo Input do motor (carrega e levanta no mesmo sítio), dado em unidades do HUD e enviado em píxeis
## da janela — o motor imita o rato a partir dele, como no aparelho.
func _tocar_motor(p: Vector2) -> void:
	var px: Vector2 = root.get_final_transform() * p
	for k in 2:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.pressed = k == 0
		t.position = px
		Input.parse_input_event(t)
		Input.flush_buffered_events()
		await process_frame


## §10: um movimento do rato a sério, em coordenadas da janela (unidades do HUD).
func _rato(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	root.push_input(e, true)


## §10: um passo da roda do rato a sério (carregar e largar), em coordenadas da janela (unidades do HUD).
func _roda(p: Vector2, para_baixo: bool) -> void:
	for carregado in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_WHEEL_DOWN if para_baixo else MOUSE_BUTTON_WHEEL_UP
		e.pressed = carregado
		e.factor = 1.0
		e.position = p
		e.global_position = p
		root.push_input(e, true)


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
