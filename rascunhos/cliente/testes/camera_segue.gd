extends SceneTree
## ORDEM-PLANO-2-F1, item 1 — D-AUD-05: a câmara da jogadora mostra e segue a figura dela (cenas/arena/arena.gd).
##
##   godot --headless --path cliente -s res://testes/camera_segue.gd
##
## A ARENA a sério (cenas/arena/arena.tscn: a câmara da mesa, o HUD, o Estado e a Rede), sem servidor. O caminho do defeito
## (RELATORIO-LOCALIZACAO do D-AUD-INVESTIGA): a batalha começa com ela JÁ na arena — o único snapshot é o do lobby, com a
## heroína por colocar, e a colocação dela chega depois como EVENTO. Antes da correcção a câmara ficava no centro da grelha.
##   1. snapshot do lobby (sem figuras) → a câmara no centro da grelha (nada a focar);
##   2. evento `colocacao` da própria → o foco vai à casa dela; com a câmara assente, ela fica no terço central;
##   3. a colocação de OUTRA figura não mexe na câmara;
##   4. `movimento` dela de 1 casa (fica no terço central) → a câmara não mexe (conserva o enquadramento);
##   5. `movimento` dela para longe → o foco vai ao destino, e ela fica no terço central;
##   6. o arrasto da jogadora conserva-se: com o foco arrastado à mão, 1 casa dentro do terço central não o desfaz;
##   7. o movimento de OUTRA figura não mexe na câmara;
##   8. no Panorama nada muda (o Panorama não usa o foco: camera_mesa.gd `_foco_alvo`);
##   9. o snapshot com ela já colocada (o caminho da bancada preparada, que já funcionava) foca como antes.
##  10. a colocação dela numa casa que já cai no terço central: a primeira vez foca na mesma (só o foco do evento o faz).
## Grelha 50×50 @ 1,5 m (a grelha-mapa da linha), janela 1280×720 (a da jogadora na bancada).
## Código de saída 0 se tudo passa, 1 se algo falha.

const CameraMesa := preload("res://camera/camera_mesa.gd")
const CASA_DELA := Vector2i(38, 4)  # a casa da heroína da bancada (ORDEM-D-AUD-04-BANCADA)

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


func _figura(id: String, nome: String, lado: String, c: Vector2i) -> Dictionary:
	return {"id": id, "nomePublico": nome, "lado": lado, "x": c.x, "y": c.y, "orientacao": "S", "visivel": "de_pe"}


func _snapshot(fase: String, figuras: Array, vez: String) -> void:
	_seq += 1
	_receber({
		"type": "ROOM_SNAPSHOT", "seq": _seq, "revision": 5, "ts": "2026-11-23T21:00:00.000Z", "fase": fase,
		"mapa": {"largura": 50, "altura": 50, "casaM": 1.5}, "figuras": figuras,
		"iniciativa": figuras.map(func(f): return f["id"]), "vezId": vez, "rodada": 1 if fase == "combate" else 0,
		"ambiente": {"clima": null, "luz": null}, "fogo": {"casas": [], "aArder": []},
		"propria": {"figuraId": "j1", "vidaActual": 22, "vidaTotal": 22, "paLivre": 6, "paTotal": 6, "estadoMorte": null,
			"armaCaida": false, "armaQuebrada": false, "corpoPartido": false, "ficha": {}},
	})


func _evento(tipo: String, dados: Dictionary) -> void:
	_seq += 1
	_receber({"type": "ROOM_EVENT", "seq": _seq, "revision": 5, "ts": "2026-11-23T21:00:01.000Z", "tipo": tipo, "dados": dados})


func _mover(id: String, de: Vector2i, para: Vector2i) -> void:
	_evento("movimento", {"figuraId": id, "de": {"x": de.x, "y": de.y}, "para": {"x": para.x, "y": para.y}, "caminho": []})


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


## Onde a casa se vê na imagem (fracção 0..1), com a câmara já assente no foco que tem.
func _no_ecra(arena: Node, c: Vector2i) -> Vector2:
	var cam: Camera3D = arena.camera
	arena.camera._saltar()
	var tam := cam.get_viewport().get_visible_rect().size
	var e := cam.unproject_position(arena.centro_casa(c))
	return Vector2(e.x / tam.x, e.y / tam.y)


static func _no_terco_central(f: Vector2) -> bool:
	return f.x >= 1.0 / 3.0 and f.x <= 2.0 / 3.0 and f.y >= 1.0 / 3.0 and f.y <= 2.0 / 3.0


static func _perto(a: Vector3, b: Vector3) -> bool:
	return Vector2(a.x, a.z).distance_to(Vector2(b.x, b.z)) < 0.01


func _correr() -> void:
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	root.size = Vector2i(1280, 720)
	await process_frame
	_rede.persistir = false
	_rede.papel = "jogadora"
	_rede._ativo = true  # a arena chama Rede.iniciar(): sem isto, ia ligar-se a um servidor
	_rede.estado_ligacao = _rede.Ligacao.NA_MESA
	_rede._ws = WebSocketPeer.new()
	_receber({"type": "ROOM_WELCOME", "seatId": "s1", "seatToken": "t", "papel": "jogadora"})

	print("== 1. o snapshot do lobby (ela por colocar): a câmara no centro da grelha ==")
	_snapshot("lobby", [], "")
	var arena = (load("res://cenas/arena/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena)
	await _quadros(4)
	var cam = arena.camera
	var meio := Vector3(arena.origem.x + arena.largura * arena.casa_m * 0.5, 0.0, arena.origem.y + arena.altura * arena.casa_m * 0.5)
	_ok(arena.largura == 50 and arena.altura == 50 and is_equal_approx(arena.casa_m, 1.5), "a grelha é a 50×50 @ 1,5 m (%d×%d @ %s)" % [arena.largura, arena.altura, arena.casa_m])
	_ok(_perto(cam.foco, meio), "sem figura dela, o foco é o centro da grelha (%s)" % cam.foco)
	_ok(arena.SEGUIR_SEMPRE == false, "o modo de seguir é «só quando sai do terço central» (decisão do coordenador)")

	print("== 2. o evento `colocacao` dela (MASTER_START com ela já na arena): o foco vai à casa dela ==")
	_evento("colocacao", {"figuraId": "j1", "nomePublico": "Arqueira de Bancada", "lado": "jogadora", "x": CASA_DELA.x, "y": CASA_DELA.y, "orientacao": "S", "visivel": "de_pe"})
	_evento("turno", {"figuraId": "j1", "rodada": 1})
	await _quadros(2)
	_ok(_perto(cam.foco, arena.centro_casa(CASA_DELA)), "o foco é a casa dela %s (foco %s)" % [CASA_DELA, cam.foco])
	var f := _no_ecra(arena, CASA_DELA)
	print("  MEDIDA arranque: a casa dela vê-se em (%.3f, %.3f) da imagem" % [f.x, f.y])
	_ok(_no_terco_central(f), "no arranque ela está no terço central da imagem (%.3f, %.3f)" % [f.x, f.y])

	print("== 3. a colocação de outra figura não mexe na câmara ==")
	var foco0: Vector3 = cam.foco
	_evento("colocacao", {"figuraId": "m1", "nomePublico": "Lobo 1", "lado": "criatura", "x": 5, "y": 45, "orientacao": "S", "visivel": "de_pe"})
	await _quadros(2)
	_ok(_perto(cam.foco, foco0), "o lobo colocado longe não puxa a câmara (foco %s)" % cam.foco)

	print("== 4. ela anda 1 casa e fica no terço central: a câmara não mexe ==")
	var c1 := CASA_DELA + Vector2i(-1, 0)
	_mover("j1", CASA_DELA, c1)
	await _quadros(2)
	_ok(_perto(cam.foco, foco0), "1 casa: o foco fica (%s)" % cam.foco)
	f = _no_ecra(arena, c1)
	_ok(_no_terco_central(f), "e ela continua no terço central (%.3f, %.3f)" % [f.x, f.y])

	print("== 5. ela anda para longe: o foco vai ao destino ==")
	var c2 := Vector2i(30, 12)
	_mover("j1", c1, c2)
	await _quadros(2)
	_ok(_perto(cam.foco, arena.centro_casa(c2)), "o foco é o destino %s (foco %s)" % [c2, cam.foco])
	f = _no_ecra(arena, c2)
	print("  MEDIDA depois do movimento: a casa dela vê-se em (%.3f, %.3f) da imagem" % [f.x, f.y])
	_ok(_no_terco_central(f), "depois do movimento ela está no terço central (%.3f, %.3f)" % [f.x, f.y])

	print("== 6. o arrasto dela conserva-se ==")
	cam._deslocar(Vector2(60.0, 0.0))  # um arrasto pequeno com o rato (60 px)
	var arrastado: Vector3 = cam.foco
	_ok(not _perto(arrastado, arena.centro_casa(c2)), "o arrasto mexeu o foco (%s)" % arrastado)
	var c3 := c2 + Vector2i(0, 1)
	f = _no_ecra(arena, c3)
	_mover("j1", c2, c3)
	await _quadros(2)
	_ok(_no_terco_central(f) and _perto(cam.foco, arrastado), "1 casa dentro do terço central (%.3f, %.3f) não desfaz o arrasto (foco %s)" % [f.x, f.y, cam.foco])

	print("== 7. o movimento de outra figura não mexe na câmara ==")
	_mover("m1", Vector2i(5, 45), Vector2i(5, 40))
	await _quadros(2)
	_ok(_perto(cam.foco, arrastado), "o lobo a andar não puxa a câmara (foco %s)" % cam.foco)

	print("== 8. no Panorama nada muda ==")
	cam.definir_modo(CameraMesa.Modo.PANORAMA)
	var c4 := Vector2i(10, 40)
	_mover("j1", c3, c4)
	await _quadros(2)
	_ok(_perto(cam.foco, arrastado), "no Panorama o movimento dela não mexe no foco (foco %s)" % cam.foco)
	cam.definir_modo(CameraMesa.Modo.FIXA)
	_mover("j1", c4, c4 + Vector2i(1, 0))
	await _quadros(2)
	_ok(_perto(cam.foco, arena.centro_casa(c4 + Vector2i(1, 0))), "de volta à Fixa, o passo seguinte traz a câmara até ela (foco %s)" % cam.foco)

	arena.queue_free()
	await _quadros(2)

	print("== 9. o snapshot com ela já colocada (bancada preparada) foca como antes ==")
	_snapshot("combate", [_figura("j1", "Arqueira de Bancada", "jogadora", Vector2i(12, 30)), _figura("m1", "Lobo 1", "criatura", Vector2i(5, 45))], "j1")
	var arena2 = (load("res://cenas/arena/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena2)
	await _quadros(4)
	_ok(_perto(arena2.camera.foco, arena2.centro_casa(Vector2i(12, 30))), "o foco é a casa dela (foco %s)" % arena2.camera.foco)
	f = _no_ecra(arena2, Vector2i(12, 30))
	_ok(_no_terco_central(f), "e ela está no terço central (%.3f, %.3f)" % [f.x, f.y])
	arena2.queue_free()
	await _quadros(2)

	# ORDEM-PLANO-2-F1 (mutação SEM-FOCO-NO-EVENTO, 26/11): o caso 2 cai fora do terço central e o seguir também o apanha;
	# só este prova o «focar a primeira vez» no evento — a casa dela já cai no terço central do enquadramento de partida,
	# o seguir não mexeria, e a câmara tem de ir mesmo assim à casa dela.
	print("== 10. a colocação dela já dentro do terço central: a primeira vez foca na mesma ==")
	_snapshot("lobby", [], "")
	var arena3 = (load("res://cenas/arena/arena.tscn") as PackedScene).instantiate()
	root.add_child(arena3)
	await _quadros(4)
	var perto := Vector2i(26, 26)
	var g := _no_ecra(arena3, perto)
	_evento("colocacao", {"figuraId": "j1", "nomePublico": "Arqueira de Bancada", "lado": "jogadora", "x": perto.x, "y": perto.y, "orientacao": "S", "visivel": "de_pe"})
	await _quadros(2)
	_ok(_no_terco_central(g), "a casa %s já se via no terço central antes de ela chegar (%.3f, %.3f)" % [perto, g.x, g.y])
	_ok(_perto(arena3.camera.foco, arena3.centro_casa(perto)), "o foco é a casa dela %s (foco %s)" % [perto, arena3.camera.foco])
	arena3.queue_free()
	await _quadros(2)

	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)
