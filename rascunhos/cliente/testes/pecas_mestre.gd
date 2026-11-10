extends SceneTree
## As peças do §12 do desenho JV3.1 no ecrã do Mestre, com mensagens REAIS do servidor (I0004, 08/11/2026).
##
##   godot --headless --path cliente -s res://testes/pecas_mestre.gd
##
## Fixture: rascunhos/servidor/dados-exemplo/mesa-mestre.json (cenários «mestre», «lobby» e «agir»).
## Confere:
## - a arena 3D desenha uma figura por figura colocada e a casa tocada vira coordenadas da grelha;
## - «Voltar até aqui»: um botão por ponto da L8; escolher NÃO manda; só «Voltar até aqui» manda o
##   MASTER_SUPERVISOR voltar com o ateSeq do ponto;
## - aba Mesa: resultados da pesquisa, «Guardar a mesa» (MASTER_LOBBY_SET), «Começar a batalha» com
##   segundo toque (MASTER_START), «Colocar» + casa no tabuleiro (MASTER_PLACE);
## - aba Agir: modos (MASTER_MODE), «Mover» destaca as casas do servidor e só aceita essas
##   (MASTER_ACT mover), ataques e acções (MASTER_ACT); «Jogo eu» no cartão de IA leva à aba Agir.
## Com MESTRE_COMANDOS=<ficheiro> escreve os comandos montados para o CI os conferir com os schemas.

const MarcadorFig := preload("res://cenas/comum/marcador_figura.gd")
const ArenaMestre := preload("res://cenas/mestre/arena_mestre.gd")
const CENA := "res://cenas/mestre/mestre.tscn"
const Textos := preload("res://cenas/mestre/textos_mestre.gd")

## Os autoloads (Rede, Estado) não são identificadores num script -s: chegam pela árvore no 1.º quadro.
var _rede: Node
var _estado: Node
var _total := 0
var _falhas := 0
var _comandos: Array = []
var _pesquisas: Array = []
var _contador := 0


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


func _capturar(tipo: String, campos: Dictionary, revision) -> String:
	_contador += 1
	var id := "cmd-pecas-%d" % _contador
	_comandos.append(_rede.montar_comando_mestre(tipo, campos, revision if revision != null else 0, id))
	return id


func _ultimo() -> Dictionary:
	return _comandos.back() if not _comandos.is_empty() else {}


func _responder(c, cmd: Dictionary) -> void:
	c._ao_resposta(str(cmd.get("cmdId", cmd.get("intentId", ""))), {"type": "ROOM_RECEIPT", "estado": "APLICADA"})


func _correr() -> void:
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var fx = JSON.parse_string(FileAccess.get_file_as_string(p))
	_ok(fx is Dictionary and fx.has("agir") and fx.has("lobby"), "a fixture do servidor tem os cenários «agir» e «lobby»")
	if not (fx is Dictionary and fx.has("agir") and fx.has("lobby")):
		_fim()
		return
	_rede.persistir = false
	_rede.papel = "mestre"
	_rede._room_id = "sala-teste"
	_rede.ultima_vista_mestre = {}
	_rede.cartao_ativo = {}
	var c = (load(CENA) as PackedScene).instantiate()
	c.enviar_fn = _capturar
	c.pedir_vista_fn = func(): pass
	c.pesquisar_fn = func(t): _pesquisas.append(t)
	root.add_child(c)
	await _quadros(3)
	c._aviso_entendido()

	print("== arena 3D ==")
	var vista: Dictionary = fx["agir"]["vista"]
	c.aplicar_vista(vista)
	await _quadros(2)
	var colocadas := 0
	for f in vista["mestre"]["figuras"]:
		if f.get("colocada") == true:
			colocadas += 1
	_ok(c._arena.figuras_desenhadas() == colocadas, "uma figura 3D por figura colocada (%d)" % colocadas)
	_ok(c._arena.casa_de_ponto(c._arena.centro_da_casa(Vector2i(3, 4))) == Vector2i(3, 4), "o centro de uma casa volta à mesma casa")
	_ok(c._arena.largura == int(vista["mapa"]["largura"]) and c._arena.altura == int(vista["mapa"]["altura"]), "a grelha tem o tamanho do mapa")

	print("== marcadores do site (Plano B; cena.js) ==")
	# A vista «mestre» da fixture tem as quatro figuras colocadas (heroína, aliada, orc e lobo).
	var vista_m: Dictionary = fx["mestre"]["vista"]
	var arena_m = ArenaMestre.new()
	root.add_child(arena_m)
	await _quadros(1)
	arena_m.aplicar_vista(vista_m)
	var orc_f: Dictionary = {}
	var lobo_f: Dictionary = {}
	for f in vista_m["mestre"]["figuras"]:
		if f.get("fichaId") == "orc-teste":
			orc_f = f
		elif f.get("fichaId") == "lobo-teste":
			lobo_f = f
	var no_orc: Node3D = arena_m._nos.get(str(orc_f.get("id", "")))
	var no_lobo: Node3D = arena_m._nos.get(str(lobo_f.get("id", "")))
	_ok(no_orc != null and no_lobo != null, "o orc e o lobo estão na arena")
	if no_orc != null and no_lobo != null:
		var m_orc := no_orc.get_node("Marcador") as Node3D
		var m_lobo := no_lobo.get_node("Marcador") as Node3D
		_ok(is_equal_approx(float(m_orc.get_meta("altura_m")), 3.6), "a altura do orc vem da ficha (3,6 m, como no site)")
		var cil = (m_orc.get_node("Pivo/Corpo") as MeshInstance3D).mesh
		_ok(cil is CylinderMesh and is_equal_approx(cil.top_radius, 0.22) and is_equal_approx(cil.bottom_radius, 0.38)
			and is_equal_approx(cil.height, 3.6 * 0.68) and cil.radial_segments == 8, "corpo «marcador»: cilindro 0,22/0,38, 0,68 × altura, 8 lados")
		_ok(is_equal_approx((m_orc.get_node("Pivo/Cabeca") as Node3D).position.y, 3.6 * 0.86), "cabeça a 0,86 × altura")
		_ok(str(m_lobo.get_meta("forma")) == "marcador-lobo" and not m_lobo.has_node("Pivo/Cabeca")
			and (m_lobo.get_node("Pivo/Corpo") as Node3D).scale.is_equal_approx(Vector3(0.3, 1.35 * 0.5, 0.7)), "o lobo usa o «marcador-lobo» (icosaedro 0,3 × 0,5·altura × 0,7)")
		var cores: Array = []
		for f in vista_m["mestre"]["figuras"]:
			var n: Node3D = arena_m._nos.get(str(f.get("id", "")))
			if n != null:
				var anel := (n.get_node("Marcador/Anel") as MeshInstance3D).mesh
				cores.append((anel.surface_get_material(0) as StandardMaterial3D).albedo_color.to_html(false))
		_ok(cores.size() >= 4 and cores.slice(0, 4) == ["87b4b0", "e5bb74", "b98b9d", "b5c3ce"], "anéis com a paleta do site pela ordem de entrada %s" % [cores])
		var contacto := (m_orc.get_node("Contacto") as MeshInstance3D)
		_ok(is_equal_approx((contacto.mesh as CylinderMesh).top_radius, 0.5) and is_equal_approx(contacto.position.y, 0.018), "sombra de contacto de 0,5 m")
		MarcadorFig.deitar(m_orc, true)
		var pivo := m_orc.get_node("Pivo") as Node3D
		_ok(is_equal_approx(pivo.rotation.z, PI * 0.5) and is_equal_approx(MarcadorFig._y_minimo(pivo) + 0.0, 0.03), "morta: deitada e assente no chão com 0,03 m de folga")
		MarcadorFig.deitar(m_orc, false)
		_ok(is_zero_approx(pivo.rotation.z) and is_zero_approx(pivo.position.y), "viva: de pé outra vez")
	arena_m.queue_free()

	print("== «Voltar até aqui» (L8) ==")
	var pontos: Array = vista["pontos"]
	_ok(pontos.size() > 0 and c._aba_registo.pontos_mostrados() == pontos.size(), "um botão por ponto (%d)" % pontos.size())
	var antes := _comandos.size()
	var alvo := int(pontos[1]["journalSeq"]) if pontos.size() > 1 else int(pontos[0]["journalSeq"])
	c._aba_registo.escolher(alvo)
	_ok(_comandos.size() == antes and c._aba_registo._confirmar.visible, "escolher o ponto só pergunta («Voltar até aqui?»)")
	c._aba_registo.confirmar()
	var u := _ultimo()
	_ok(u.get("type") == "MASTER_SUPERVISOR" and u.get("op") == "voltar" and int(u.get("ateSeq", -1)) == alvo,
		"«Voltar até aqui» → MASTER_SUPERVISOR voltar ateSeq %d" % alvo)
	_responder(c, u)

	print("== aba Agir ==")
	var opcoes: Dictionary = fx["agir"]["opcoes"]
	_estado.limpar()
	_estado.tem_snapshot = true
	_rede._ao_receber(JSON.stringify(opcoes))
	c.aplicar_vista(vista)
	await _quadros(1)
	var botoes: Array = c._aba_agir.botoes_de_accao()
	var esperados: int = 1 + opcoes["ataques"].size() + opcoes["acoes"].size()  # Mover + ataques + acções
	_ok(botoes.size() == esperados, "um botão por opção do servidor (%d)" % esperados)
	c._aba_agir.escolher_modo("semi")
	u = _ultimo()
	_ok(u.get("type") == "MASTER_MODE" and u.get("modo") == "semi" and u.get("figuraId") == vista["vezId"], "modo → MASTER_MODE")
	_responder(c, u)
	c._aba_agir.iniciar_mover()
	_ok(c._arena.casas_destacadas().size() == opcoes["mover"].size(), "«Mover» destaca as %d casas do servidor" % opcoes["mover"].size())
	antes = _comandos.size()
	c.casa_tocada(Vector2i(19, 19))
	_ok(_comandos.size() == antes, "uma casa fora das opções não manda nada")
	var destino := Vector2i(int(opcoes["mover"][0]["x"]), int(opcoes["mover"][0]["y"]))
	c.casa_tocada(destino)
	u = _ultimo()
	_ok(u.get("type") == "MASTER_ACT" and u.get("acao", {}).get("tipo") == "mover"
		and int(u["acao"]["destino"]["x"]) == destino.x and int(u["acao"]["destino"]["y"]) == destino.y, "tocar numa casa → MASTER_ACT mover")
	_ok(c._arena.casas_destacadas().is_empty(), "depois de mover os destaques saem")
	_responder(c, u)
	if not opcoes["ataques"].is_empty():
		var a: Dictionary = opcoes["ataques"][0]
		c._aba_agir.agir({"tipo": "atacar", "alvoId": a["alvoId"], "arma": a["arma"]})
		u = _ultimo()
		_ok(u.get("type") == "MASTER_ACT" and u.get("acao", {}).get("tipo") == "atacar", "ataque → MASTER_ACT atacar")
		_responder(c, u)
	c._aba_agir.agir({"tipo": "encerrar"})
	u = _ultimo()
	_ok(u.get("type") == "MASTER_ACT" and u.get("acao", {}).get("tipo") == "encerrar", "«Encerrar a vez» → MASTER_ACT encerrar")
	_responder(c, u)
	var rotulos: Array = []
	for b in c._aba_agir.botoes_de_accao():
		rotulos.append(b.text)
	_ok(rotulos.has(Textos.MOVER) and rotulos.has(Textos.NOME_ACAO["encerrar"]), "rótulos com as palavras da casa %s" % [rotulos])

	print("== L10: «Escolher outra» no cartão de IA ==")
	var ia_vez := {"v": 2, "type": "MASTER_CARD", "roomId": "sala-teste", "cartaoId": "c7", "tipo": "ia",
		"figuraId": vista["vezId"], "proposta": {"tipo": "atacar", "alvoId": "x", "arma": "y"}, "razao": "teste",
		"faces": null, "intentIdOrigem": null, "desgracas": null}
	_rede._ao_receber(JSON.stringify(ia_vez))
	await _quadros(1)
	_ok(c._botoes[0].text == Textos.CONFIRMAR, "proposta de ataque: o primeiro botão é «Confirmar» (não é marcha pura)")
	c._abas.current_tab = 0
	c.tocar("escolher")
	_ok(c._abas.get_tab_control(c._abas.current_tab) == c._aba_agir.get_parent() and c._aba_agir.editar_cartao == "c7",
		"«Escolher outra» abre a aba Agir em modo de troca")
	c._aba_agir.agir({"tipo": "encerrar"})
	u = _ultimo()
	_ok(u.get("type") == "MASTER_APPROVE" and u.get("cartaoId") == "c7" and u.get("decisao") == "editar"
		and u.get("edicao", {}).get("acao", {}).get("tipo") == "encerrar", "a acção escolhida → MASTER_APPROVE editar {acao}")
	_ok(c._aba_agir.editar_cartao == "", "depois de escolher, a aba sai do modo de troca")
	_responder(c, u)
	_rede._ao_receber(JSON.stringify({"v": 2, "type": "ROOM_EVENT", "roomId": "sala-teste", "seq": 9999, "revision": 999,
		"ts": "2026-11-08T00:00:00Z", "tipo": "cartao_fechado", "dados": {"cartaoId": "c7", "decisao": "editar"}}))
	await _quadros(1)

	print("== L6: «Continuar a rodada» ==")
	_rede._ao_receber(JSON.stringify(fx["mestre"]["cartoes"]["ia"]))
	await _quadros(1)
	_ok(c._botoes[0].text == Textos.CONTINUAR_RODADA, "marcha pura → «Continuar a rodada»")
	c.tocar("continuar_rodada")
	u = _ultimo()
	_ok(u.get("type") == "MASTER_APPROVE" and u.get("decisao") == "aprovar" and u.get("rodada") == true, "→ MASTER_APPROVE aprovar {rodada: true}")
	_responder(c, u)

	print("== L9: selo TESTE e estatísticas ==")
	var com_selo: Dictionary = vista.duplicate(true)
	com_selo["selo"] = "TESTE"
	com_selo["estatisticas"] = {"eventos": 9, "rodada": 1, "ataques": {vista["vezId"]: 2}, "danoCausado": {vista["vezId"]: 1176},
		"danoSofrido": {}, "cartoes": {"aprovar": 1, "revertido": 1}}
	c.aplicar_vista(com_selo)
	await _quadros(1)
	_ok(c._sala.text.begins_with("[TESTE] "), "o selo TESTE aparece no ecrã do Mestre")
	var est: Array = []
	for n in c._aba_registo._estat.get_children():
		if not n.is_queued_for_deletion():
			est.append(n.text)
	_ok(est.size() == 2 and str(est[0]).contains("2 ataque(s)") and str(est[0]).contains("dano causado 1176")
		and str(est[1]).contains("confirmados 1"), "as estatísticas por figura e por decisão %s" % [est])
	c.aplicar_vista(vista)

	print("== N4: «Terminar batalha» e «Recomeçar» (palavra do Mestre, como no site) ==")
	antes = _comandos.size()
	c.pedir_terminar()
	_ok(_comandos.size() == antes and c._terminar.text == Textos.SIM_TERMINAR, "«Terminar batalha» pede «Sim, terminar»")
	c.pedir_terminar()
	u = _ultimo()
	_ok(u.get("type") == "MASTER_SUPERVISOR" and u.get("op") == "terminar", "«Sim, terminar» → MASTER_SUPERVISOR terminar")
	_responder(c, u)
	c.pedir_recomecar()
	_ok(c._recomecar.text == Textos.SIM_RECOMECAR, "«Recomeçar» pede «Sim, recomeçar»")
	c.pedir_recomecar()
	u = _ultimo()
	_ok(u.get("type") == "MASTER_SUPERVISOR" and u.get("op") == "recomecar", "«Sim, recomeçar» → MASTER_SUPERVISOR recomecar")
	_responder(c, u)

	print("== «Jogo eu» leva à aba Agir ==")
	_rede._ao_receber(JSON.stringify(fx["mestre"]["cartoes"]["ia"]))
	await _quadros(1)
	c._abas.current_tab = 0
	c.tocar("jogo_eu")
	c.tocar("jogo_eu")
	_ok(c._abas.get_tab_control(c._abas.current_tab) == c._aba_agir.get_parent(), "depois de «Jogo eu» a aba Agir fica à frente")
	_responder(c, _ultimo())

	print("== aba Mesa ==")
	var lobby_vista: Dictionary = fx["lobby"]["vista"]
	c.aplicar_vista(lobby_vista)
	_ok(c._terminar.disabled and c._recomecar.disabled, "no lobby, «Terminar batalha» e «Recomeçar» estão desligados")
	c._aba_mesa.procurar()
	_ok(_pesquisas.size() == 1, "«Procurar» pede a pesquisa ao servidor")
	_rede._ao_receber(JSON.stringify(fx["lobby"]["resultados"]))
	await _quadros(1)
	var caixas: Array = []
	for n in c._aba_mesa._lista_res.get_children():
		if n is CheckBox and not n.is_queued_for_deletion():
			caixas.append(n)
	var res: Array = fx["lobby"]["resultados"]["resultados"]
	_ok(caixas.size() == res.size(), "uma linha por resultado (%d)" % res.size())
	var marcadas := caixas.filter(func(x): return x.button_pressed)
	_ok(marcadas.size() == 3, "as fichas já na mesa vêm marcadas (3)")
	_ok(caixas.any(func(x): return x.text.contains("Orc Verdadeiro Teste (Orc)")), "o Mestre vê o nome verdadeiro e o público")
	c._aba_mesa.marcar(false, "lobo-teste")
	c._aba_mesa.guardar()
	u = _ultimo()
	_ok(u.get("type") == "MASTER_LOBBY_SET" and u.get("criaturasDisponiveis") == ["orc-teste"] and u.get("npcsDisponiveis") == ["bandido-teste"],
		"«Guardar a mesa» → MASTER_LOBBY_SET com o que está marcado")
	_responder(c, u)
	antes = _comandos.size()
	c._aba_mesa.comecar()
	_ok(_comandos.size() == antes, "«Começar a batalha» pede o segundo toque")
	c._aba_mesa.comecar()
	_ok(_ultimo().get("type") == "MASTER_START", "segundo toque → MASTER_START")
	_responder(c, _ultimo())
	antes = _comandos.size()
	c.casa_tocada(Vector2i(5, 5))
	_ok(_comandos.size() == antes, "sem ficha escolhida, tocar no tabuleiro não coloca nada")
	c._aba_mesa.escolher_colocar("orc-teste")
	_ok(c._aba_mesa._estado.text.contains("Aparece à Party"), "o «Colocar» avisa que a figura aparece à Party")
	c.casa_tocada(Vector2i(5, 6))
	u = _ultimo()
	_ok(u.get("type") == "MASTER_PLACE" and u.get("fichaId") == "orc-teste" and int(u["casa"]["x"]) == 5 and int(u["casa"]["y"]) == 6,
		"casa no tabuleiro → MASTER_PLACE")
	_responder(c, u)
	print("== L5: esquema de colocação em série ==")
	c._aba_mesa.ligar_esquema(true)
	antes = _comandos.size()
	c.casa_tocada(Vector2i(7, 7))
	c.casa_tocada(Vector2i(8, 7))
	_ok(_comandos.size() == antes and c._aba_mesa.esquema.size() == 2, "com o esquema ligado, as casas juntam-se sem mandar nada")
	_ok(c._arena.casas_destacadas().size() == 2, "as casas do esquema ficam destacadas na arena")
	c._aba_mesa.colocar_esquema()
	u = _ultimo()
	_ok(_comandos.size() == antes + 1 and int(u["casa"]["x"]) == 7, "«Colocar o esquema» manda só a primeira")
	_responder(c, u)
	u = _ultimo()
	_ok(_comandos.size() == antes + 2 and int(u["casa"]["x"]) == 8, "o recibo da primeira manda a segunda")
	_responder(c, u)
	_ok(c._aba_mesa.esquema.is_empty() and not c._aba_mesa.em_serie(), "o esquema acabou")
	c.casa_tocada(Vector2i(9, 7))
	c.casa_tocada(Vector2i(10, 7))
	c._aba_mesa.colocar_esquema()
	u = _ultimo()
	c._ao_resposta(str(u.get("cmdId", "")), {"type": "ROOM_REJECT", "motivo": "acao_invalida", "texto": "Essa acção não é possível."})
	_ok(not c._aba_mesa.em_serie() and c._aba_mesa.esquema.size() == 2 and c._aba_mesa._estado.text == Textos.ESQUEMA_PAROU,
		"uma recusa pára o esquema e o resto fica na lista")
	c._aba_mesa.limpar_esquema()
	c._aba_mesa.ligar_esquema(false)
	c._aba_mesa.parar()
	_ok(c._aba_mesa.a_colocar == "", "«Parar de colocar»")

	await _caida_atingida(c, fx["mestre"]["vista"])
	_verbo_padrao(fx["mestre"]["vista"])
	await _ambiente(c, fx["mestre"]["vista"])
	_exportar(c)
	await _camara_livre(c)

	var todos: Array = []
	_textos(c, todos)
	var proibidas := todos.filter(func(t): return t.to_lower().contains("prime") or t.to_lower().contains("carreg"))
	_ok(proibidas.is_empty(), "nenhum texto visível com «prime» ou «carregar» %s" % [proibidas])

	var saida := OS.get_environment("MESTRE_COMANDOS")
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		for m in _comandos:
			f.store_line(JSON.stringify(m))
		f.close()
		print("comandos escritos em ", saida, ": ", _comandos.size())
	c.queue_free()
	await _quadros(1)
	_fim()


## Decisão 10 do Mestre (ordem 6 do CM-000009; site REF_29): a câmara livre — primeira pessoa dentro da arena,
## só no ecrã do Mestre (arrastar para olhar, manípulo ou WASD para andar, ▲▼ para voar). Na Party nem se constrói.
func _camara_livre(c) -> void:
	print("== câmara livre do Mestre (decisão 10; site REF_29) ==")
	var a = c._arena
	var cam = a.camara_livre
	var ctl = c._livre
	_ok(cam != null and ctl != null, "a câmara livre e os controlos existem no ecrã do Mestre")
	if cam == null or ctl == null:
		return
	_ok(ctl.entrar_botao.visible and ctl.entrar_botao.text == Textos.CAMARA_LIVRE_ENTRAR, "«Entrar na câmera livre» à vista, com o texto do site")
	_ok(not ctl.manipulo.visible and not ctl.sair_botao.visible, "fora da livre, o manípulo e o «Voltar» não aparecem")
	var mesa_antes: Transform3D = a.camera.global_transform
	ctl.entrar_botao.pressed.emit()
	await _quadros(1)
	_ok(a.camara_livre_ativa() and cam.current, "entrar: a câmara livre passa a ser a câmara da arena")
	_ok(ctl.manipulo.visible and ctl.sair_botao.visible and ctl.sobe_botao.visible and ctl.desce_botao.visible and ctl.vel_caixa.visible,
		"dentro: manípulo, ▲▼, 1×/2×/4× e «Voltar à câmera do jogo»")
	_ok(is_equal_approx(cam.position.y, 1.6), "entra com os olhos a 1,6 do chão (site)")
	var tam := Vector2(a.largura * a.casa_m, a.altura * a.casa_m)
	_ok(is_equal_approx(cam.position.z, tam.y), "entra à beira sul da arena")
	var frente: Vector3 = cam.direcao()
	_ok(frente.z < 0.0, "entra a olhar para o centro")
	# Andar em frente 1 s com o manípulo (joyY = −1): 4,2 u/s, em passos de 0,08 (o dt máximo do site).
	cam.definir_tecla("shift", false)
	var p0: Vector3 = cam.position
	cam.definir_joy(Vector2(0.0, -1.0))
	for i in 10:
		cam.passo(0.1)  # preso a 0,08 → 10 × 0,08 × 4,2 = 3,36
	cam.definir_joy(Vector2.ZERO)
	var andou := Vector2(cam.position.x - p0.x, cam.position.z - p0.z)
	_ok(absf(andou.length() - 3.36) < 0.01, "manípulo: 4,2 u/s com o dt preso a 0,08 (andou %.2f)" % andou.length())
	_ok(Vector2(frente.x, frente.z).normalized().dot(andou.normalized()) > 0.99, "anda para onde olha")
	# WASD: D anda para a direita (perpendicular), Shift ×2,2, velocidade 2×.
	var p1: Vector3 = cam.position
	cam.definir_vel(2)
	cam.definir_tecla("d", true)
	cam.definir_tecla("shift", true)
	cam.passo(0.05)
	cam.definir_tecla("d", false)
	cam.definir_tecla("shift", false)
	cam.definir_vel(1)
	var lado := Vector2(cam.position.x - p1.x, cam.position.z - p1.z)
	_ok(absf(lado.length() - 4.2 * 2.0 * 2.2 * 0.05) < 0.01, "WASD: D com Shift (×2,2) a 2× (andou %.3f)" % lado.length())
	_ok(absf(Vector2(frente.x, frente.z).normalized().dot(lado.normalized())) < 0.01, "D anda de lado")
	# Voar: ▲ sobe 3,0 u/s; a altura fica presa a [0,4 · 12].
	var y0: float = cam.position.y
	cam.definir_sobe(1)
	cam.passo(0.05)
	_ok(is_equal_approx(cam.position.y, y0 + 0.15), "▲ sobe 3,0 u/s")
	for i in 100:
		cam.passo(0.08)
	_ok(is_equal_approx(cam.position.y, 12.0), "o tecto é 12")
	cam.definir_sobe(-1)
	for i in 100:
		cam.passo(0.08)
	cam.definir_sobe(0)
	_ok(is_equal_approx(cam.position.y, 0.4), "o chão empurra: nunca abaixo de 0,4")
	# Bordas: arena + 3.
	cam.definir_joy(Vector2(0.0, -1.0))
	for i in 400:
		cam.passo(0.08)
	cam.definir_joy(Vector2.ZERO)
	_ok(cam.position.z >= -3.0 - 0.001 and cam.position.z <= tam.y + 3.0 + 0.001 and cam.position.x >= -3.0 - 0.001 \
		and cam.position.x <= tam.x + 3.0 + 0.001, "presa às bordas da arena + 3")
	# Olhar: 0,0045 rad por px real; o pitch fica em ±1,45.
	cam.px_por_unidade = 1.0
	var yaw0: float = cam.yaw
	cam.olhar(100.0, 0.0)
	_ok(is_equal_approx(cam.yaw, yaw0 - 0.45), "arrastar 100 px gira 0,45 rad")
	cam.olhar(0.0, -100000.0)
	_ok(is_equal_approx(cam.pitch, 1.45), "o pitch fica preso a 1,45")
	# O manípulo no ecrã: tocar na ponta de cima anda para a frente; largar pára.
	var raio: float = ctl.manipulo.size.x * 0.5
	var toque := InputEventScreenTouch.new()
	toque.index = 0
	toque.pressed = true
	toque.position = Vector2(raio, 0.0)
	ctl._ao_manipulo(toque)
	_ok(cam.joy.is_equal_approx(Vector2(0.0, -1.0)), "o manípulo do ecrã dá joy (0, −1) na ponta de cima")
	toque.pressed = false
	ctl._ao_manipulo(toque)
	_ok(cam.joy == Vector2.ZERO, "largar o manípulo pára")
	# Teclado pelo ecrã: W (keycode) só conta com a livre activa.
	var w := InputEventKey.new()
	w.keycode = KEY_W
	w.pressed = true
	ctl._input(w)
	_ok(cam.teclas.has("w"), "a tecla W chega ao andar com a livre activa")
	w.pressed = false
	ctl._input(w)
	_ok(not cam.teclas.has("w"), "largar W")
	# Sair: volta à câmara do jogo, exactamente como estava.
	ctl.sair_botao.pressed.emit()
	_ok(a.camera.global_transform.is_equal_approx(mesa_antes), "a câmara do jogo ficou congelada e intacta")
	await _quadros(1)
	_ok(not a.camara_livre_ativa() and a.camera.current and not cam.current, "sair: volta à câmara do jogo")
	_ok(ctl.entrar_botao.visible and not ctl.manipulo.visible, "fora outra vez: só o «Entrar»")
	var w2 := InputEventKey.new()
	w2.keycode = KEY_W
	w2.pressed = true
	ctl._input(w2)
	_ok(not cam.teclas.has("w"), "fora da livre, o W não é do andar")
	# Na vista da Party nem se constrói: nenhum script da Party fala da câmara livre.
	var da_party := ["res://cenas/arena/arena.gd", "res://hud/hud.gd", "res://camera/camera_mesa.gd", "res://cenas/lobby/lobby.gd"]
	var limpos := true
	for s in da_party:
		var codigo := FileAccess.get_file_as_string(s)
		if codigo == "" or codigo.contains("camara_livre") or codigo.contains("CamaraLivre"):
			limpos = false
			printerr("  a Party fala da câmara livre (ou não se leu): ", s)
	_ok(limpos, "a vista da Party nem constrói a câmara livre")


## Ordem 12 do CM-000009 (parte C; paridade REF_35 do site): a heroína já caída leva um golpe e o motor sobe-lhe as
## falhas. O servidor só o diz no `ataque` (soMestre.soDoMestre.alvoDepois; não sai `estado` — contrato fixado em
## servidor/testes/ordem12-caida-atingida.test.mjs). O ecrã do Mestre narra a frase do site e regista-a.
func _ataque(seq: int, atac: String, alvo: String, em_depois: Dictionary, oportunidade := false, extra := {}) -> Dictionary:
	var dep := {"vidaActual": 0, "estadoMorte": em_depois}
	dep.merge(extra, true)
	return {"type": "ROOM_EVENT", "seq": seq, "tipo": "ataque", "dados": {
		"atacanteId": atac, "alvoId": alvo, "arma": "machado-teste", "resultado": "acerto",
		"ataqueDeOportunidade": oportunidade, "soMestre": {"soDoMestre": {"alvoDepois": dep}}, "journalSeq": seq}}


func _caida_atingida(c, vista_base: Dictionary) -> void:
	print("== caída atingida: narração ao Mestre (ordem 12) ==")
	var vista_antes: Dictionary = c.vista  # a câmara livre, a seguir, continua com a vista que tinha
	var v: Dictionary = vista_base.duplicate(true)
	var her := ""
	var nome_her := ""
	var orc := ""
	var nome_orc := ""
	for f in v["mestre"]["figuras"]:
		if her == "" and f.get("lado") == "jogadora":
			her = f["id"]
			nome_her = str(f.get("nome"))
			f["vidaActual"] = 0
			f["caido"] = true
			f["estadoMorte"] = {"fase": "aMorrer", "sucessos": 1, "falhas": 0}
		elif f.get("fichaId") == "orc-teste":
			orc = f["id"]
			nome_orc = str(f.get("nome"))
	_ok(her != "" and orc != "", "a fixture tem a heroína e o orc")
	c.aplicar_vista(v)
	await _quadros(1)
	var n_alertas: int = c.alertas.size()
	_ok(c.mortes.get(her) is Dictionary and int(c.mortes[her]["falhas"]) == 0, "o ecrã guarda o estadoMorte da vista")

	# 1) Golpe da vez (não de oportunidade) nela já a morrer: falhas 0 → 1.
	var golpe := _ataque(900, orc, her, {"fase": "aMorrer", "sucessos": 1, "falhas": 1})
	c._ao_evento(golpe)
	await _quadros(1)
	# Ordem 13 (parte C): o verbo é o da ficha do orc (fixture: «desferiu o machado», o do site para o Orc).
	var frase := Textos.CAIDA_PIORA % [nome_orc, "desferiu o machado", nome_her]
	_ok(c.narracao.size() == 1, "narra uma vez a caída atingida")
	_ok(frase.begins_with(nome_orc + " desferiu o machado a "), "o verbo do golpe vem da ficha do monstro: «%s»" % frase)
	_ok(c.alertas.size() == n_alertas + 1 and c.alertas.back() == frase, "a frase do site chega ao Mestre: «%s»" % frase)
	_ok(frase.ends_with("piora visivelmente."), "o núcleo do site: «piora visivelmente.»")
	var reg: Array[String] = c._aba_registo.narracoes_mostradas()
	_ok(reg.size() == 1 and reg[0].contains(frase) and reg[0].contains("sucessos 1, falhas 1"),
		"fica no registo com os contadores %s" % [reg])
	_ok(int(c.mortes[her]["falhas"]) == 1, "o espelho sobe para 1 falha (não há `estado` a seguir)")

	# 2) O mesmo evento outra vez (repetido no fio): não narra de novo.
	c._ao_evento(golpe)
	_ok(c.narracao.size() == 1, "evento repetido não narra outra vez")

	# 3) Golpe de oportunidade: falhas 1 → 2, frase própria do AoO; sem vista nova pelo meio (o espelho chega).
	c._ao_evento(_ataque(901, orc, her, {"fase": "aMorrer", "sucessos": 1, "falhas": 2}, true))
	var frase_aoo := Textos.CAIDA_PIORA_OPORTUNIDADE % [nome_orc, nome_her]
	_ok(c.narracao.size() == 2 and c.alertas.back() == frase_aoo, "golpe de oportunidade: «%s»" % frase_aoo)
	reg = c._aba_registo.narracoes_mostradas()
	_ok(reg.size() == 2 and reg[0].contains("(de oportunidade)") and reg[0].contains("falhas 2"), "o mais novo fica no topo do registo")

	# 4) O golpe que a mata (3.ª falha, morteAdjudicada): não é «piora» — a morte narra-se pelo fim.
	c._ao_evento(_ataque(902, orc, her, {"fase": "aMorrer", "sucessos": 1, "falhas": 3}, false, {"morteAdjudicada": true}))
	_ok(c.narracao.size() == 2, "o golpe que a mata não narra «piora»")

	# 5) Queda nova (antes não estava a morrer): não é falha por golpe.
	c.aplicar_vista(vista_base)
	var outra := _ataque(903, orc, her, {"fase": "aMorrer", "sucessos": 0, "falhas": 0})
	c._ao_evento(outra)
	_ok(c.narracao.size() == 2, "a queda nova não é narrada como «piora»")

	# 6) Falhas sobem por um `estado` (teste de morte), não por golpe: o espelho segue, sem narrar.
	c._ao_evento({"type": "ROOM_EVENT", "seq": 904, "tipo": "estado", "dados": {
		"figuraId": her, "visivel": "caida", "estadoMorte": {"fase": "aMorrer", "sucessos": 0, "falhas": 1}}})
	_ok(c.narracao.size() == 2 and int(c.mortes[her]["falhas"]) == 1, "o `estado` actualiza o espelho e não narra")

	# 7) Golpe num monstro nunca narra; nem um ataque sem soMestre (o que a Party receberia).
	c._ao_evento(_ataque(905, her, orc, {"fase": "aMorrer", "sucessos": 0, "falhas": 9}))
	var sem_so := _ataque(906, orc, her, {"fase": "aMorrer", "sucessos": 0, "falhas": 2})
	sem_so["dados"].erase("soMestre")
	c._ao_evento(sem_so)
	_ok(c.narracao.size() == 2, "monstro atingido ou ataque sem soMestre: silêncio")
	c.aplicar_vista(vista_antes)
	await _quadros(1)


## Ordem 13 (parte C): sem `verbos` na ficha, a frase diz «acerta» (o JV de antes); o verbo nunca muda mecânica.
func _verbo_padrao(vista_base: Dictionary) -> void:
	print("== verbo do golpe por monstro (ordem 13, parte C) ==")
	var Modelo = load("res://cenas/mestre/modelo_mestre.gd")
	var v: Dictionary = vista_base.duplicate(true)
	var her := ""
	var orc := ""
	var lobo := ""
	for f in v["mestre"]["figuras"]:
		if her == "" and f.get("lado") == "jogadora":
			her = f["id"]
		elif f.get("fichaId") == "orc-teste":
			orc = f["id"]
		elif f.get("fichaId") == "lobo-teste":
			lobo = f["id"]
	_ok(Modelo.verbo_acerto(v, orc) == "desferiu o machado" and Modelo.verbo_acerto(v, lobo) == "deu uma patada",
		"cada monstro com o seu verbo (orc: «desferiu o machado»; lobo: «deu uma patada»)")
	var r := {"alvoId": her, "atacanteId": lobo, "oportunidade": false}
	_ok(Modelo.frase_caida_piora(v, r).contains(" deu uma patada a "), "a frase da caída usa o verbo do lobo: «%s»" % Modelo.frase_caida_piora(v, r))
	for f in v["mestre"]["figuras"]:
		if f["id"] == lobo:
			f["verbos"] = null
	_ok(Modelo.verbo_acerto(v, lobo) == Textos.VERBO_ACERTO_PADRAO and Modelo.frase_caida_piora(v, r).contains(" acerta a "),
		"sem verbos na ficha: «acerta»")
	r["oportunidade"] = true
	_ok(Modelo.frase_caida_piora(v, r).contains("golpeia a ") and Modelo.frase_caida_piora(v, r).contains("de oportunidade"),
		"o golpe de oportunidade guarda a frase própria do site")


## Ordem 13 (parte B, dívida E1): o painel Ambiente (só o Mestre), o fogo na arena e a narração do raio e do fogo.
func _ambiente(c, vista_base: Dictionary) -> void:
	print("== ambiente: raio e fogo (ordem 13) ==")
	var Modelo = load("res://cenas/mestre/modelo_mestre.gd")
	var v: Dictionary = vista_base.duplicate(true)
	var her := ""
	var orc := ""
	var nome_her := ""
	var nome_orc := ""
	for f in v["mestre"]["figuras"]:
		if her == "" and f.get("lado") == "jogadora":
			her = f["id"]
			nome_her = str(f.get("nome"))
		elif f.get("fichaId") == "orc-teste":
			orc = f["id"]
			nome_orc = str(f.get("nome"))
	v["fase"] = "combate"
	v["rodada"] = 2
	v["mestre"]["ambiente"] = {"hora": "03:33", "clima": "tempestade", "futuro": null, "raios": true, "raioPendente": false, "raioPedidoRodada": 1}
	v["mestre"]["fogo"] = {"casas": [{"x": 2, "y": 2, "combustivel": 4}, {"x": 2, "y": 3, "combustivel": 1}], "aArder": [her]}
	c.aplicar_vista(v)
	await _quadros(1)
	var linhas: Array = Modelo.linhas_ambiente(v)
	var juntas := "\n".join(PackedStringArray(linhas))
	_ok(juntas.contains(Textos.CHUVA % "forte") and juntas.contains(Textos.RAIOS % Textos.RAIOS_LIGADOS),
		"o painel diz a chuva e os raios %s" % [linhas])
	_ok(juntas.contains("(2,2) mais 4") and juntas.contains("(2,3) mais 1"), "o combustível de cada casa, só no ecrã do Mestre")
	_ok(juntas.contains(Textos.A_ARDER % nome_her), "quem arde, com o nome verdadeiro")
	_ok(c._arena.casas_a_arder().size() == 2, "a arena do Mestre pinta as 2 casas a arder")
	_ok(not c._raio_agora.disabled and c._raios.text == Textos.DESLIGAR_RAIOS, "«⚡ Raio agora» aceso; o botão dos raios diz «Desligar»")

	c.pedir_raio()
	var u := _ultimo()
	_ok(u.get("type") == "MASTER_AMBIENTE" and u.get("raioAgora") == true, "«⚡ Raio agora» → MASTER_AMBIENTE {raioAgora: true}")
	_ok(c.alertas.back() == Textos.RAIO_PEDIDO, "a frase do site ao pedir: «%s»" % Textos.RAIO_PEDIDO)
	_responder(c, u)
	c.alternar_raios()
	u = _ultimo()
	_ok(u.get("type") == "MASTER_AMBIENTE" and u.get("raios") == false, "«Desligar os raios» → MASTER_AMBIENTE {raios: false}")
	_responder(c, u)
	c.mudar_clima("chuva")
	u = _ultimo()
	_ok(u.get("type") == "MASTER_AMBIENTE" and u.get("clima") == "chuva", "clima → MASTER_AMBIENTE {clima}")
	_responder(c, u)
	c.mudar_hora(1)
	u = _ultimo()
	_ok(u.get("hora") == "04:33", "+1 h: 03:33 → 04:33")
	_responder(c, u)
	_ok(Modelo.hora_mais({"mestre": {"ambiente": {"hora": "23:10"}}}, 1).get("hora") == "00:10", "a hora dá a volta às 24")

	# Com o raio já pedido (ou nesta rodada), o botão apaga-se e nada sai.
	var antes := _comandos.size()
	v["mestre"]["ambiente"]["raioPendente"] = true
	c.aplicar_vista(v)
	c.pedir_raio()
	_ok(_comandos.size() == antes and c._raio_agora.disabled, "com um raio à espera, «⚡ Raio agora» apagado e nada sai")
	_ok("\n".join(PackedStringArray(Modelo.linhas_ambiente(v))).contains(Textos.RAIO_PENDENTE), "o painel diz que há um raio à espera")
	v["mestre"]["ambiente"]["raioPendente"] = false
	v["mestre"]["ambiente"]["clima"] = "limpo"
	_ok(not Modelo.raio_agora_possivel(v), "sem chuva não há «⚡ Raio agora»")

	# Narração: o que o servidor manda ao Mestre (com soMestre).
	var n0: int = c.narracao.size()
	var raio := {"type": "ROOM_EVENT", "seq": 950, "tipo": "raio", "dados": {"x": 2, "y": 2, "alvoId": her, "desfecho": "arde",
		"soMestre": {"origem": "pedido", "combustivel": 4, "cruz": [{"x": 2, "y": 1}, {"x": 2, "y": 3}, {"x": 1, "y": 2}, {"x": 3, "y": 2}],
			"tipo": "eletrico", "bruto": 15, "rd": 0, "dano": 15}, "journalSeq": 950}}
	c._ao_evento(raio)
	var frase_raio := "Um raio atinge a %s em cheio — ela fica a arder." % nome_her
	_ok(c.narracao.size() == n0 + 1 and c.alertas.back() == frase_raio, "o raio narrado com a frase do site: «%s»" % frase_raio)
	_ok(c.narracao.back().contains("pedido pelo Mestre") and c.narracao.back().contains("leva 15 (raio, fixo, sem RD)")
		and c.narracao.back().contains("arde por 4 rodadas") and c.narracao.back().contains("acende 4 vizinhas"),
		"a linha do registo leva a origem, o dano sem RD e o combustível: %s" % c.narracao.back())
	c._ao_evento(raio)
	_ok(c.narracao.size() == n0 + 1, "o mesmo evento repetido não narra outra vez")
	c._ao_evento({"type": "ROOM_EVENT", "seq": 951, "tipo": "dano_ambiente", "dados": {"alvoId": her, "origem": "raio", "desfecho": "arde",
		"valor": 15, "soMestre": {"dano": 15}, "journalSeq": 951}})
	_ok(c.narracao.size() == n0 + 1, "o dano do raio não se narra duas vezes (já veio com o raio)")
	c._ao_evento({"type": "ROOM_EVENT", "seq": 952, "tipo": "dano_ambiente", "dados": {"alvoId": orc, "origem": "fogo", "desfecho": "arde",
		"valor": 6, "soMestre": {"faces": [6], "dano": 6, "pegouFogo": true}, "journalSeq": 952}})
	_ok(c.alertas.back() == "%s está a arder — o fogo morde." % nome_orc, "o tick: «%s»" % c.alertas.back())
	_ok(c.narracao.back().contains("leva 6 (1d8 = 6, sem RD)") and c.narracao.back().contains("pegou fogo"), "a linha do tick com o dado")
	c._ao_evento({"type": "ROOM_EVENT", "seq": 953, "tipo": "fogo", "dados": {"casas": [], "aArder": [],
		"apagados": [{"figuraId": her, "porque": "saiu"}],
		"soMestre": {"fogo": {"casas": [], "aArder": []}, "extintas": [{"x": 2, "y": 3, "porque": "combustivel"}]}, "journalSeq": 953}})
	var frase_saiu := "A %s sai da casa em chamas — a chuva apaga o fogo dela." % nome_her
	_ok(c.alertas.back() == frase_saiu, "sair para a chuva: «%s»" % frase_saiu)
	_ok(c.narracao.back() == Textos.REGISTO_EXTINTA % [2, 3, "acabou o combustível"], "a casa que se apaga entra só no registo")
	c._ao_evento({"type": "ROOM_EVENT", "seq": 954, "tipo": "raio", "dados": {"x": 9, "y": 9,
		"soMestre": {"origem": "automatico", "combustivel": 2, "cruz": []}, "journalSeq": 954}})
	_ok(c.alertas.back() == "Um raio cai na arena — uma cruz de casas fica a arder.", "o raio que não atinge ninguém")
	var reg: Array[String] = c._aba_registo.narracoes_mostradas()
	_ok(reg.size() >= 5 and reg[0].contains("da tempestade"), "tudo fica na narração do registo (o mais novo no topo)")
	c.aplicar_vista(vista_base)
	await _quadros(1)


## Ordem 13 (parte D): o «Exportar registo» leva o registo do servidor INTACTO e a secção de narração.
func _exportar(c) -> void:
	print("== «Exportar registo» com a narração (ordem 13, parte D) ==")
	var Modelo = load("res://cenas/mestre/modelo_mestre.gd")
	var registo := "{\"formato\":\"journal/1\",\"marca\":\"MESTRE-ONLY\"}\nsha256:abc\n"
	var x: Dictionary = Modelo.conteudo_export(registo, c.narracao)
	_ok(x.get("registo") == registo and x.get("marca") == "MESTRE-ONLY", "o registo do servidor vai intacto (é texto assinado)")
	_ok(x.get("narracao") == c.narracao and c.narracao.size() > 0, "a narração vai inteira (%d entradas)" % c.narracao.size())
	var caminho: String = c._guardar_export({"conteudo": registo})
	var lido = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	_ok(lido is Dictionary and lido.get("registo") == registo, "o ficheiro tem o registo, byte a byte")
	var narr: Array = lido.get("narracao", []) if lido is Dictionary else []
	var tem_caida := false
	var tem_raio := false
	for t in narr:
		tem_caida = tem_caida or str(t).contains("piora visivelmente")
		tem_raio = tem_raio or str(t).contains("Um raio atinge")
	_ok(narr.size() == c.narracao.size() and tem_caida and tem_raio, "o ficheiro leva a narração: a caída (ordem 12) e o raio (ordem 13)")
	DirAccess.remove_absolute(caminho)


func _textos(no: Node, saida: Array) -> void:
	if no is Label or no is Button:
		if (no as CanvasItem).is_visible_in_tree():
			saida.append(no.text)
	for f in no.get_children():
		_textos(f, saida)


func _fim() -> void:
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)
