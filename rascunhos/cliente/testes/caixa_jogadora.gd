extends SceneTree
## Ordem CAIXA-HUD-JOGADORA — a caixa da ordem de turnos no HUD da jogadora (hud/hud.gd), sem servidor e sem ecrã.
##
##   godot --headless --path cliente -s res://testes/caixa_jogadora.gd
##
## O HUD a sério recebe o tráfego pela Rede (ROOM_WELCOME, ROOM_SNAPSHOT com `caixa`, ROOM_EVENT) e a caixa mostra a
## escolha do Mestre: ligada/desligada, modo dinâmico (a ordem da Party, adiantada pelos eventos) ou iniciativa
## (`iniciativa` + `vezId`). Sem o campo, na sala de espera ou no lobby, não aparece. Não tapa a ⚙, a ficha nem a barra.
## §7 (Ordem CAIXA-JANELA): os eventos que chegam entre o snapshot e a abertura do HUD aparecem na caixa ao abrir.
## Código de saída 0 se tudo passa, 1 se algo falha.

var _total := 0
var _falhas := 0
var _rede: Node
var _estado: Node
var _seq := 0


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
		"figuras": [_figura("j1", "Heroína", "jogadora", 2), _figura("j2", "Aliada", "jogadora", 3), _figura("m1", "Criatura", "criatura", 6)],
		"iniciativa": ["m1", "j1", "j2"], "vezId": vez, "rodada": 1,
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
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)
