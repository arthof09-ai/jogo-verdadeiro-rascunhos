extends SceneTree
## Prova (fora do repo): o ecrã do Mestre aberto do zero reconstrói a caixa da ordem a partir da MASTER_VIEW do servidor.

var _f := 0

func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)

func _q(n: int) -> void:
	for i in n:
		await process_frame

func _ok(c: bool, t: String) -> void:
	print(("  ok    " if c else "  FALHA ") + t)
	if not c:
		_f += 1

func _abrir(vista: Dictionary) -> Node:
	var m: Node = (load("res://cenas/mestre/mestre.tscn") as PackedScene).instantiate()
	m.enviar_fn = func(_t, _c, _r): return ""
	m.pedir_vista_fn = func(): pass
	root.add_child(m)
	await _q(2)
	m._aviso_entendido()
	m.aplicar_vista(vista)
	m._ao_redimensionar()
	await _q(2)
	return m

func _correr() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")))
	root.get_node("Rede").persistir = false
	root.get_node("Rede").papel = "mestre"
	root.size = Vector2i(1280, 720)
	var vista: Dictionary = (d["mestre"]["vista"] as Dictionary).duplicate(true)
	var ids := {}
	for f in vista["mestre"]["figuras"]:
		ids[str(f["fichaId"])] = str(f["id"])
	var h: String = ids["heroina-teste"]; var a: String = ids["aliada-teste"]; var o: String = ids["orc-teste"]
	print("iniciativa do servidor: ", vista["iniciativa"])
	# 1.ª sessão do Mestre: os eventos formam a ordem (Aliada, Orc, Heroína — fora da ordem de iniciativa).
	var m1 := await _abrir(vista)
	for ev in [["ataque", {"atacanteId": a, "ataqueDeOportunidade": false}], ["ataque", {"atacanteId": o, "ataqueDeOportunidade": false}], ["movimento", {"figuraId": h}]]:
		m1._ao_evento({"tipo": ev[0], "dados": ev[1]})
	var antes: Array = m1._caixa.ids_mostrados.duplicate()
	print("caixa antes de sair: ", antes, " vez=", m1._caixa.vez_mostrada)
	m1.queue_free()
	await _q(2)
	# 2.ª sessão (o Mestre voltou a entrar): ecrã novo, sem eventos — só a MASTER_VIEW com a ordem que o servidor guardou.
	var v2 := vista.duplicate(true)
	v2["ordemDinamica"] = {"ordem": [a, o, h], "fechada": false, "ultimo": h}
	var m2 := await _abrir(v2)
	print("caixa depois de reentrar: ", m2._caixa.ids_mostrados, " vez=", m2._caixa.vez_mostrada)
	_ok(m2._caixa.visible, "a caixa está à vista em combate")
	_ok(m2._caixa.ids_mostrados == antes, "a caixa reconstrói-se igual (Aliada → Orc → Heroína)")
	_ok(m2._caixa.vez_mostrada == h, "na vez: quem agiu por último (a Heroína)")
	# Controlo: sem a ordem do servidor, o ecrã novo começava vazio (o defeito de antes).
	var m3 := await _abrir(vista.duplicate(true).merged({"ordemDinamica": {"ordem": [], "fechada": false, "ultimo": null}}, true))
	_ok(m3._caixa.ids_mostrados.is_empty(), "controlo: a ordem vazia do servidor dá a caixa vazia")
	print("%d falha(s)" % _f)
	quit(1 if _f > 0 else 0)
