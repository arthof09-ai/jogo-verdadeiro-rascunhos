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

	print("== nomes dos tipos de evento no «voltar» (ordem 27, N25-2) ==")
	# Palavra do Mestre (11/11/2026): os seis tipos que apareciam crus passam a ter nome. Conferidos por ponto de código
	# (ç = U+00E7, ã = U+00E3), escritos aqui com escapes para não depender da codificação deste ficheiro.
	var ModeloN = load("res://cenas/mestre/modelo_mestre.gd")
	var nomes_n25_2 := {"cura": "Cura", "acao": "Ação", "ia": "Ação do monstro",
		"erro_motor": "Erro do motor", "escala": "Escalada", "recomeco": "Recomeço"}
	for t in nomes_n25_2:
		_ok(Textos.NOME_EVENTO.get(t, "<sem nome>") == nomes_n25_2[t], "o tipo «%s» chama-se «%s» (está «%s»)" % [t, nomes_n25_2[t], Textos.NOME_EVENTO.get(t, "<sem nome>")])
	var acao_n: String = Textos.NOME_EVENTO.get("acao", "")
	_ok(acao_n.length() == 4 and acao_n.unicode_at(1) == 0x00E7 and acao_n.unicode_at(2) == 0x00E3, "«Ação» com ç U+00E7 e ã U+00E3")
	var linha_n: String = ModeloN.linha_ponto({}, {"rodada": 2, "vezId": "", "tipos": ["cura", "acao", "ia", "erro_motor", "escala", "recomeco"]})
	_ok(linha_n.ends_with(" · Cura, Ação, Ação do monstro, Erro do motor, Escalada, Recomeço"), "a linha do ponto usa os nomes: «%s»" % linha_n)
	var linha_d: String = ModeloN.linha_ponto({}, {"rodada": 1, "vezId": "", "tipos": ["tipo_que_nao_existe", "ataque"]})
	_ok(linha_d.ends_with(" · tipo_que_nao_existe, ataque"), "tipo desconhecido continua cru, os outros como antes: «%s»" % linha_d)

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
	# Ordem 34 (N26-1): o servidor recusa a pesquisa vazia (nunca pesquisa '' por omissão): o campo vazio não manda nada.
	c._aba_mesa.procurar()
	_ok(_pesquisas.size() == 0, "N26-1: «Procurar» com o campo vazio não manda pesquisa")
	c._aba_mesa._procura.text = "   "
	c._aba_mesa.procurar()
	_ok(_pesquisas.size() == 0, "N26-1: só espaços também não manda")
	# Ordem 34 (N26-1): o campo limita a escrita a 64 caracteres, com contador à vista (a recusa do servidor é a rede de trás).
	var procura: LineEdit = c._aba_mesa._procura
	var contador: Label = c._aba_mesa._contador
	_ok(procura.max_length == 64, "N26-1: o campo de pesquisa aceita 64 caracteres no máximo")
	_ok(contador != null and contador.visible and contador.get_parent() == procura.get_parent(), "N26-1: o contador está à vista, ao lado do campo")
	_ok(contador != null and contador.text == "3/64", "N26-1: o contador conta o que está escrito (veio «%s»)" % (contador.text if contador else "?"))
	procura.text = ""
	procura.insert_text_at_caret("a".repeat(70) + "ç".repeat(30))
	procura.text_changed.emit(procura.text)  # o que o LineEdit emite quando se escreve no teclado
	_ok(procura.text.length() == 64, "N26-1: a escrita pára aos 64 (ficou com %d)" % procura.text.length())
	_ok(contador.text == "64/64", "N26-1: o contador mostra 64/64 (veio «%s»)" % contador.text)
	c._aba_mesa.procurar()
	_ok(_pesquisas.size() == 1 and str(_pesquisas.back()) == "a".repeat(64), "N26-1: os 64 que ficaram no campo saem inteiros")
	procura.text = ""
	procura.insert_text_at_caret("ç".repeat(64))
	procura.text_changed.emit(procura.text)
	_ok(procura.text.length() == 64 and contador.text == "64/64", "N26-1: contam-se caracteres, não bytes (64 acentuados cabem)")
	procura.text = " orc "
	c._aba_mesa.procurar()
	_ok(str(_pesquisas.back()) == "orc", "a pesquisa curta sai igual, sem os espaços")
	_ok(_pesquisas.size() == 2, "cada «Procurar» com texto pede uma pesquisa")
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
	await _falha_monstro(c, fx["mestre"]["vista"])
	_exportar(c)
	_join_sem_sala()
	await _aviso_motor(c)
	await _fila_alertas(c)
	await _recibo_perdido(c, fx["mestre"]["cartoes"]["ia"])
	await _nomes_juntos(c, fx["mestre"]["vista"])
	await _camara_livre(c)
	await _clima(c)
	await _perfil_grafico(c)

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
	await _molde_do_mapa()
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
	# Ordem 45: o chão é o relevo do mapa e a grelha começa na origem dela no mapa (não em 0).
	_ok(is_equal_approx(cam.position.y, cam.chao(cam.position.x, cam.position.z) + 1.6) and absf(cam.chao(cam.position.x, cam.position.z) - a.altura_chao(cam.position.x, cam.position.z)) < 0.000001,
		"entra com os olhos a 1,6 do chão (site; o chão é o relevo do mapa, ordem 45)")
	var tam := Vector2(a.largura * a.casa_m, a.altura * a.casa_m)
	_ok(is_equal_approx(cam.position.z, a.origem.y + tam.y), "entra à beira sul da arena")
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
	_ok(is_equal_approx(cam.position.y, cam.chao(cam.position.x, cam.position.z) + 12.0), "o tecto é 12 acima do chão")
	cam.definir_sobe(-1)
	for i in 100:
		cam.passo(0.08)
	cam.definir_sobe(0)
	_ok(is_equal_approx(cam.position.y, cam.chao(cam.position.x, cam.position.z) + 0.4), "o chão empurra: nunca abaixo de 0,4 do relevo")
	# Bordas: arena + 3.
	cam.definir_joy(Vector2(0.0, -1.0))
	for i in 400:
		cam.passo(0.08)
	cam.definir_joy(Vector2.ZERO)
	var o: Vector2 = a.origem
	_ok(cam.position.z >= o.y - 3.0 - 0.001 and cam.position.z <= o.y + tam.y + 3.0 + 0.001 and cam.position.x >= o.x - 3.0 - 0.001 \
		and cam.position.x <= o.x + tam.x + 3.0 + 0.001, "presa às bordas da arena + 3")
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
	# Ordem 45: o clima de jogo que o Mestre escolhe chove (ou neva) no ecrã dele — só apresentação.
	_ok(c._arena.clima.tipo == "chuva" and c._arena.clima.intensidade == "forte", "ordem 45: a tempestade chove forte na arena do Mestre")
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


## Ordem 14 (parte B; paridade com o site, jogo.js atacarIA, série de oportunidade e cartão em modo «monstro»): o
## monstro falha o golpe e a narração diz a falha com o verbo da ficha (verbos.falha). Mecânica nenhuma muda.
func _falha(seq: int, atac: String, alvo: String, resultado: String, oportunidade := false) -> Dictionary:
	return {"type": "ROOM_EVENT", "seq": seq, "tipo": "ataque", "dados": {
		"atacanteId": atac, "alvoId": alvo, "arma": "machado-teste", "resultado": resultado,
		"ataqueDeOportunidade": oportunidade, "soMestre": {"soDoMestre": {}}, "journalSeq": seq}}


func _falha_monstro(c, vista_base: Dictionary) -> void:
	print("== falha do monstro com o verbo da ficha (ordem 14) ==")
	var Modelo = load("res://cenas/mestre/modelo_mestre.gd")
	var v: Dictionary = vista_base.duplicate(true)
	var her := ""
	var orc := ""
	var lobo := ""
	var nome_her := ""
	var nome_orc := ""
	var nome_lobo := ""
	for f in v["mestre"]["figuras"]:
		if her == "" and f.get("lado") == "jogadora":
			her = f["id"]
			nome_her = str(f.get("nome"))
		elif f.get("fichaId") == "orc-teste":
			orc = f["id"]
			nome_orc = str(f.get("nome"))
		elif f.get("fichaId") == "lobo-teste":
			lobo = f["id"]
			nome_lobo = str(f.get("nome"))
	_ok(her != "" and orc != "" and lobo != "", "a fixture tem a heroína, o orc e o lobo")

	# 1) O verbo da falha vem da ficha (os do site para o Orc e o Lobo); sem verbos, o do site: «tentou atacar».
	_ok(Modelo.verbo_falha(v, orc) == "tentou desferir o machado" and Modelo.verbo_falha(v, lobo) == "tentou dar uma patada",
		"cada monstro com o seu verbo de falha (orc: «tentou desferir o machado»; lobo: «tentou dar uma patada»)")
	var sem_verbos: Dictionary = v.duplicate(true)
	for f in sem_verbos["mestre"]["figuras"]:
		if f["id"] == lobo:
			f["verbos"] = null
	_ok(Modelo.verbo_falha(sem_verbos, lobo) == Textos.VERBO_FALHA_PADRAO and Textos.VERBO_FALHA_PADRAO == "tentou atacar",
		"sem verbos na ficha: «tentou atacar» (o do site)")

	c.aplicar_vista(v)
	await _quadros(1)
	var n: int = c.narracao.size()
	var n_alertas: int = c.alertas.size()

	# 2) A vez do monstro: golpe falhado («erra»). Frase do site, com o verbo do orc; registo com a linha.
	var golpe := _falha(950, orc, her, "erro")
	c._ao_evento(golpe)
	var frase := "%s tentou desferir o machado a %s e falhou." % [nome_orc, nome_her]
	_ok(c.narracao.size() == n + 1 and c.alertas.size() == n_alertas + 1 and c.alertas.back() == frase,
		"golpe falhado do orc: «%s»" % frase)
	var reg: Array[String] = c._aba_registo.narracoes_mostradas()
	_ok(reg[0].contains(frase) and reg[0].contains("Ataque falhado: %s contra %s." % [nome_orc, nome_her]),
		"fica no registo com a linha do ataque %s" % [reg[0]])
	c._ao_evento(golpe)
	_ok(c.narracao.size() == n + 1, "o mesmo evento repetido não narra outra vez")

	# 3) O lobo também, com o verbo dele; e sem verbos na ficha, «tentou atacar».
	c._ao_evento(_falha(951, lobo, her, "erro"))
	_ok(c.alertas.back() == "%s tentou dar uma patada a %s e falhou." % [nome_lobo, nome_her], "o lobo com o verbo dele: «%s»" % c.alertas.back())
	c.aplicar_vista(sem_verbos)
	c._ao_evento(_falha(952, lobo, her, "erro"))
	_ok(c.alertas.back() == "%s tentou atacar a %s e falhou." % [nome_lobo, nome_her], "sem verbos: «%s»" % c.alertas.back())
	c.aplicar_vista(v)

	# 4) Golpe de oportunidade falhado: a frase própria do site.
	c._ao_evento(_falha(953, lobo, her, "erro", true))
	_ok(c.alertas.back() == "%s tenta golpeá-la de oportunidade e falha." % nome_lobo, "oportunidade: «%s»" % c.alertas.back())
	_ok(c._aba_registo.narracoes_mostradas()[0].contains("(de oportunidade)"), "o registo marca o golpe de oportunidade")
	n = c.narracao.size()

	# 5) Falha crítica com desgraça aplicada: espera pela `desgraca` (journalSeq + 1) e junta a frase dela, numa só.
	c._ao_evento(_falha(960, orc, her, "falha_critica"))
	_ok(c.narracao.size() == n, "a falha crítica espera pelo evento seguinte")
	c._ao_evento({"type": "ROOM_EVENT", "seq": 961, "tipo": "desgraca", "dados": {
		"figuraId": orc, "efeito": "arma-cai", "soMestre": {}, "journalSeq": 961}})
	frase = "%s tentou desferir o machado a %s e falhou. A arma (machado teste) caiu-lhe da mão." % [nome_orc, nome_her]
	_ok(c.narracao.size() == n + 1 and c.alertas.back() == frase, "falha crítica + desgraça numa frase: «%s»" % c.alertas.back())
	_ok(c._aba_registo.narracoes_mostradas()[0].contains("falha crítica: " + Textos.NOME_DESGRACA["arma-cai"]),
		"o registo diz a desgraça aplicada")

	# 6) Falha crítica sem desgraça («Não acontece nada»): o evento seguinte é outro → «O golpe correu mal.».
	c._ao_evento(_falha(962, orc, her, "falha_critica"))
	c._ao_evento({"type": "ROOM_EVENT", "seq": 963, "tipo": "cartao_fechado", "dados": {"cartaoId": "c-x", "journalSeq": 963}})
	frase = "%s tentou desferir o machado a %s e falhou. O golpe correu mal." % [nome_orc, nome_her]
	_ok(c.narracao.size() == n + 2 and c.alertas.back() == frase, "sem desgraça: «%s»" % c.alertas.back())
	_ok(c._aba_registo.narracoes_mostradas()[0].contains(Textos.REGISTO_FALHA_SEM_DESGRACA), "o registo diz que não houve desgraça")

	# 7) A `desgraca` de OUTRA figura não fecha esta falha; a vista nova fecha-a (fim da transacção).
	c._ao_evento(_falha(964, lobo, her, "falha_critica", true))
	_ok(Modelo.desgraca_da_falha({"tipo": "desgraca", "dados": {"figuraId": orc, "efeito": "cai", "journalSeq": 965}},
		c._falha_pendente).is_empty(), "a desgraça de outro não é a desta falha")
	_ok(Modelo.desgraca_da_falha({"tipo": "desgraca", "dados": {"figuraId": lobo, "efeito": "cai", "journalSeq": 970}},
		c._falha_pendente).is_empty(), "nem a do mesmo, longe no journal")
	c.aplicar_vista(v)
	frase = "%s tenta golpeá-la de oportunidade e falha. O golpe correu mal." % nome_lobo
	_ok(c.narracao.size() == n + 3 and c.alertas.back() == frase and c._falha_pendente.is_empty(),
		"a vista fecha a falha pendente: «%s»" % c.alertas.back())

	# 8) Silêncio: o golpe falhado DELA (frases dela no HUD), o acerto do monstro, e uma figura que a vista não conhece.
	c._ao_evento(_falha(970, her, orc, "erro"))
	c._ao_evento(_falha(971, orc, her, "acerto"))
	c._ao_evento(_falha(972, "f-desconhecida", her, "erro"))
	_ok(c.narracao.size() == n + 3, "a falha dela, o acerto e uma figura desconhecida não narram falha de monstro")

	# 9) O cartão de desgraça de um MONSTRO abre com a frase da falha (site, modo «monstro»); o dela fica como era.
	var vc: Dictionary = v.duplicate(true)
	var interno := {"cartaoId": "c-orc", "estado": "aberto", "tipo": "desgraca", "figuraId": orc, "alvoId": her,
		"tecnicaId": "machado-teste", "proposta": {"tipo": "arma-cai"}, "excluidas": []}
	var interno_aoo: Dictionary = interno.duplicate(true)
	interno_aoo["cartaoId"] = "c-lobo"
	interno_aoo["figuraId"] = lobo
	interno_aoo["ataqueDeOportunidade"] = true
	vc["mestre"]["cartoes"] = [interno, interno_aoo] + vc["mestre"]["cartoes"]
	var card := {"type": "MASTER_CARD", "cartaoId": "c-orc", "tipo": "desgraca", "figuraId": orc,
		"proposta": {"tipo": "arma-cai"}, "desgracas": ["cai", "arma-cai"], "amigos": []}
	var d: Dictionary = Modelo.descrever_cartao(card, vc)
	_ok(d["linhas"][0] == "%s tentou desferir o machado a %s e falhou." % [nome_orc, nome_her],
		"cartão do orc: «%s»" % d["linhas"][0])
	var card_aoo: Dictionary = card.duplicate(true)
	card_aoo["cartaoId"] = "c-lobo"
	card_aoo["figuraId"] = lobo
	d = Modelo.descrever_cartao(card_aoo, vc)
	_ok(d["linhas"][0] == "%s tentou golpeá-la de oportunidade ao sair e falhou." % nome_lobo,
		"cartão do golpe de oportunidade: «%s»" % d["linhas"][0])
	var card_her: Dictionary = card.duplicate(true)
	card_her["cartaoId"] = "c1"
	card_her["figuraId"] = her
	d = Modelo.descrever_cartao(card_her, vc)
	_ok(d["linhas"][0] == Modelo.nome_mestre(Modelo.figura(vc, her)), "o cartão da heroína não ganha frase de falha (o site não a enquadra)")
	# Ordem 15 (parte C): o título do cartão do golpe de oportunidade nomeia-o; os outros ficam como eram.
	_ok(Modelo.descrever_cartao(card_aoo, vc)["titulo"] == "Ataque de oportunidade · falha crítica",
		"título do cartão de oportunidade: «%s»" % Modelo.descrever_cartao(card_aoo, vc)["titulo"])
	_ok(Modelo.descrever_cartao(card, vc)["titulo"] == Textos.TITULO["desgraca"], "o cartão da vez do orc mantém o título")
	_ok(Modelo.descrever_cartao(card_her, vc)["titulo"] == Textos.TITULO["desgraca"], "o cartão da heroína mantém o título")
	c.aplicar_vista(vc)
	c.aplicar_cartao(card_aoo)
	await _quadros(1)
	_ok(c._titulo_cartao.text.begins_with("Ataque de oportunidade"), "o ecrã do Mestre mostra «%s» no título" % c._titulo_cartao.text)
	_ok(c._titulo_cartao.get_line_count() <= c.LINHAS_TITULO, "o título cabe nas linhas medidas do cartão")
	c.cartao = {}
	c._desenhar_cartao()
	c.aplicar_cartao(card)
	await _quadros(1)
	_ok(c._texto_cartao.text.begins_with("%s tentou desferir o machado a %s e falhou." % [nome_orc, nome_her])
		and c._texto_cartao.text.contains("A Party vai ler: «Falha crítica · "), "o ecrã mostra-o no cartão, com a frase da Party por baixo")
	c.cartao = {}
	c._desenhar_cartao()
	c.aplicar_vista(vista_base)
	await _quadros(1)


## Ordem 15 (parte F): com as figuras juntas (a heroína, a aliada e o orc da fixture estão em casas vizinhas), os
## nomes arrumam-se no ecrã: nenhuma caixa toca outra, e pelo menos um subiu da altura de base. A figura não mexe.
func _nomes_juntos(c, vista: Dictionary) -> void:
	print("== nomes das figuras juntas (ordem 15, parte F) ==")
	var a = c._arena
	a.aplicar_vista(vista)
	a.camera.definir_modo(a.camera.Modo.FIXA)
	a.camera.focar(a.centro_da_casa(Vector2i(2, 3)))
	a.camera.definir_zoom(4.0)
	a.camera._saltar()
	await _quadros(3)
	var caixas: Array[Rect2] = a.arrumar_nomes()
	var tocam := 0
	for i in caixas.size():
		for j in range(i + 1, caixas.size()):
			if caixas[i].intersects(caixas[j]):
				tocam += 1
	_ok(caixas.size() >= 3 and tocam == 0, "%d nomes no ecrã, %d pares sobrepostos" % [caixas.size(), tocam])
	var subiram := 0
	var posicoes_ok := true
	for no in a._nos.values():
		var r: Label3D = no.get_node("Rotulo")
		if r.position.y > float(r.get_meta("nome_base_y")) + 0.001:
			subiram += 1
		posicoes_ok = posicoes_ok and is_equal_approx(no.position.y, a.pe_figura(a.casa_de_ponto(no.position)).y)
	_ok(subiram >= 1 and posicoes_ok, "subiu o nome de %d figura(s); as figuras ficam na casa" % subiram)


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
	var tem_falha := false
	for t in narr:
		tem_caida = tem_caida or str(t).contains("piora visivelmente")
		tem_raio = tem_raio or str(t).contains("Um raio atinge")
		tem_falha = tem_falha or str(t).contains("tentou desferir o machado a ")
	_ok(narr.size() == c.narracao.size() and tem_caida and tem_raio and tem_falha,
		"o ficheiro leva a narração: a caída (ordem 12), o raio (ordem 13) e a falha do monstro (ordem 14)")
	DirAccess.remove_absolute(caminho)


## Ordem 21 (N19-2, errata do Mestre): o primeiro ROOM_JOIN não leva roomId (o aparelho só o aprende no ROOM_WELCOME);
## depois de o conhecer, leva-o. Os três JOIN vão para o ficheiro dos comandos, que o CI confere com o schema ROOM_JOIN.
func _join_sem_sala() -> void:
	print("== ROOM_JOIN sem roomId na primeira entrada (ordem 21, N19-2) ==")
	_ok(_rede.has_method("montar_join"), "a Rede monta o ROOM_JOIN numa função à parte (montar_join)")
	if not _rede.has_method("montar_join"):
		return
	var guardado := [_rede.papel, _rede._room_id, _rede._seat_token, _rede._pin, _rede._nome, _rede._senha]
	_rede._seat_token = ""
	_rede._room_id = ""
	_rede.papel = "mestre"
	_rede._pin = "12345678"
	var j1: Dictionary = _rede.montar_join()
	_ok(j1.get("type") == "ROOM_JOIN" and not j1.has("roomId") and j1.get("pin") == "12345678" and j1.get("papel") == "mestre",
		"o primeiro JOIN do Mestre leva o PIN e não leva roomId")
	_rede.papel = "jogadora"
	_rede._pin = ""
	_rede._nome = "Heroína Teste"
	_rede._senha = "<senha-da-heroina>"
	var j2: Dictionary = _rede.montar_join()
	_ok(not j2.has("roomId") and j2.get("nome") == "Heroína Teste" and j2.has("senha"), "o primeiro JOIN da jogadora também não")
	_rede._room_id = "sala-teste"
	_rede._seat_token = "0123456789abcdef0123456789abcdef"
	var j3: Dictionary = _rede.montar_join()
	_ok(j3.get("roomId") == "sala-teste" and j3.get("seatToken") == "0123456789abcdef0123456789abcdef" and not j3.has("senha"),
		"depois do WELCOME, a reentrada leva o roomId e o token")
	_comandos.append_array([j1, j2, j3])
	_rede.papel = guardado[0]
	_rede._room_id = guardado[1]
	_rede._seat_token = guardado[2]
	_rede._pin = guardado[3]
	_rede._nome = guardado[4]
	_rede._senha = guardado[5]


## Ordem 21 (N18-2, decisão do Mestre): servidor restaurado no fim com um motor de outra versão → o journal ganha o
## evento `aviso_motor` (só ao Mestre). O ecrã do Mestre põe-no nos alertas, uma vez (o mesmo seq repetido no fio não
## repete o alerta), e o registo tem nome para ele.
func _aviso_motor(c) -> void:
	print("== Aviso do motor de outra versão ao restaurar (ordem 21, N18-2) ==")
	# Um evento neutro primeiro: fecha a falha do monstro que a secção anterior possa ter deixado à espera.
	c._ao_evento({"v": 2, "type": "ROOM_EVENT", "roomId": "sala-teste", "seq": 990, "revision": 9, "ts": "2026-11-11T12:00:00.000Z",
		"tipo": "lobby", "dados": {"journalSeq": 76, "soMestre": null}})
	await _quadros(1)
	var n: int = c.alertas.size()
	var ev := {"v": 2, "type": "ROOM_EVENT", "roomId": "sala-teste", "seq": 991, "revision": 9, "ts": "2026-11-11T12:00:00.000Z",
		"tipo": "aviso_motor", "dados": {"journalSeq": 77, "soMestre": {"codigo": "MOTOR_DIFERENTE", "recomecar": "recusado",
		"motorGravado": "a".repeat(64), "motorAgora": "e".repeat(64)}}}
	c._ao_evento(ev)
	await _quadros(1)
	_ok(c.alertas.size() == n + 1 and c.alertas.back() == Textos.ALERTA.get("aviso_motor", "<sem texto>"),
		"o aviso vai aos alertas do Mestre: «%s»" % [c.alertas.back() if c.alertas.size() > 0 else ""])
	c._ao_evento(ev.duplicate(true))
	await _quadros(1)
	_ok(c.alertas.size() == n + 1, "o mesmo evento repetido no fio não repete o alerta")
	_ok(Textos.NOME_EVENTO.get("aviso_motor", "") != "", "o registo tem nome para o aviso_motor")
	# Ordem 22 (N21-1, decisão do Mestre): o Mestre que entra de fresco (sem lastSeq) não recebe o evento; o aviso vem na
	# MASTER_VIEW (`avisoMotor`). Vai aos alertas uma vez; a vista repetida, ou o evento das mesmas versões, não o repetem.
	var n2: int = c.alertas.size()
	var vista: Dictionary = c.vista.duplicate(true) if c.vista is Dictionary and not c.vista.is_empty() else {"type": "MASTER_VIEW", "fase": "fim"}
	vista["avisoMotor"] = {"codigo": "MOTOR_DIFERENTE", "recomecar": "recusado", "motorGravado": "b".repeat(64), "motorAgora": "f".repeat(64)}
	c.aplicar_vista(vista)
	await _quadros(1)
	_ok(c.alertas.size() == n2 + 1 and c.alertas.back() == Textos.ALERTA.get("aviso_motor", "<sem texto>"),
		"Mestre de fresco: o avisoMotor da vista vai aos alertas")
	c.aplicar_vista(vista.duplicate(true))
	await _quadros(1)
	_ok(c.alertas.size() == n2 + 1, "a vista seguinte com o mesmo aviso não o repete")
	var ev2 := {"v": 2, "type": "ROOM_EVENT", "roomId": "sala-teste", "seq": 995, "revision": 9, "ts": "2026-11-11T12:00:00.000Z",
		"tipo": "aviso_motor", "dados": {"journalSeq": 78, "soMestre": vista["avisoMotor"].duplicate(true)}}
	c._ao_evento(ev2)
	await _quadros(1)
	_ok(c.alertas.size() == n2 + 1, "o evento do mesmo aviso (pelo fluxo) também não o repete")
	var sem: Dictionary = vista.duplicate(true)
	sem["avisoMotor"] = null
	c.aplicar_vista(sem)
	await _quadros(1)
	_ok(c.alertas.size() == n2 + 1, "avisoMotor null: nada")
	# Ordem 34 (N27-2): o aviso diz QUAL versão mudou (quaisDiferem: nomes dos campos), em palavras simples; o hash cru
	# nunca vai ao ecrã. Dois (ou três) diferentes: um alerta só, com todos de uma vez.
	var n3: int = c.alertas.size()
	var so_dano: Dictionary = vista.duplicate(true)
	so_dano["avisoMotor"] = {"codigo": "MOTOR_DIFERENTE", "recomecar": "recusado", "motorGravado": "c".repeat(64),
		"motorAgora": "c".repeat(64), "quaisDiferem": ["dmgVersao"]}
	c.aplicar_vista(so_dano)
	await _quadros(1)
	var t1: String = c.alertas.back() if c.alertas.size() > n3 else ""
	_ok(c.alertas.size() == n3 + 1, "N27-2: só o dmgVersao diferente — um alerta")
	_ok(t1.contains("a versão de dano mudou"), "N27-2: o alerta diz «a versão de dano mudou» (veio «%s»)" % t1)
	_ok(not t1.contains("cccccccc") and not t1.contains("dmgVersao"), "N27-2: nem o hash nem o nome do campo no ecrã")
	var dois := {"v": 2, "type": "ROOM_EVENT", "roomId": "sala-teste", "seq": 996, "revision": 9, "ts": "2026-11-11T12:00:00.000Z",
		"tipo": "aviso_motor", "dados": {"journalSeq": 79, "soMestre": {"codigo": "MOTOR_DIFERENTE", "recomecar": "recusado",
		"motorGravado": "1".repeat(64), "motorAgora": "2".repeat(64), "quaisDiferem": ["vlabSha", "levelupSha"]}}}
	c._ao_evento(dois)
	await _quadros(1)
	var t2: String = c.alertas.back() if c.alertas.size() > n3 + 1 else ""
	_ok(c.alertas.size() == n3 + 2, "N27-2: dois diferentes — um alerta só (não um por campo)")
	_ok(t2.contains("o motor (VLAB) mudou") and t2.contains("a versão de subida de nível mudou"),
		"N27-2: os dois de uma vez (veio «%s»)" % t2)
	_ok(not t2.contains("1111") and not t2.contains("2222"), "N27-2: o hash cru não vai ao ecrã")
	var tres: Dictionary = vista.duplicate(true)
	tres["avisoMotor"] = {"codigo": "MOTOR_DIFERENTE", "recomecar": "recusado", "motorGravado": "3".repeat(64),
		"motorAgora": "4".repeat(64), "quaisDiferem": ["vlabSha", "dmgVersao", "levelupSha"]}
	c.aplicar_vista(tres)
	await _quadros(1)
	var t3: String = c.alertas.back() if c.alertas.size() > n3 + 2 else ""
	_ok(c.alertas.size() == n3 + 3 and t3.contains("o motor (VLAB) mudou") and t3.contains("a versão de dano mudou")
		and t3.contains("a versão de subida de nível mudou"), "N27-2: os três de uma vez (veio «%s»)" % t3)


## Ordem 34 (N32-1): os avisos que o Mestre perdeu chegam num só bloco (MASTER_ALERTAS, com a MASTER_VIEW): «perdidos
## por limite: N» primeiro, depois «N avisos enquanto estavas fora:» com a hora de cada; um toque fecha. Cada alerta
## confirma-se ao servidor por id (MASTER_ALERTA_ACK); o duplicado (a ligação caiu antes da confirmação) resolve-se
## pelo id — não volta a aparecer, mas confirma-se outra vez.
func _fila_alertas(c) -> void:
	print("== Fila de avisos do Mestre (ordem 34, N32-1) ==")
	var acks: Array = []
	c.confirmar_alertas_fn = func(ids, perdidos): acks.append([ids, perdidos])
	var bloco := {"v": 2, "type": "MASTER_ALERTAS", "roomId": "sala-teste", "perdidos": 3, "alertas": [
		{"id": "al-1", "ordem": 4, "hora": "2026-11-12T21:05:00.000Z", "motivo": "bloqueio_join", "alvo": "ip"},
		{"id": "al-2", "ordem": 5, "hora": "2026-11-12T21:07:00.000Z", "motivo": "segunda_ligacao", "papel": "jogadora", "nome": "Heroína Teste"},
	]}
	_rede._ao_receber(JSON.stringify(bloco))
	await _quadros(1)
	var painel: Control = c._bloco_avisos
	var texto: String = c._bloco_texto.text if c._bloco_texto else ""
	_ok(painel != null and painel.visible, "N32-1: o bloco de avisos aparece")
	var linhas := texto.split("\n")
	_ok(linhas.size() >= 4 and linhas[0] == "perdidos por limite: 3", "N32-1: o bloco abre com «perdidos por limite: 3» (veio «%s»)" % texto)
	_ok(linhas.size() >= 4 and linhas[1] == "2 avisos enquanto estavas fora:", "N32-1: «2 avisos enquanto estavas fora:» (veio «%s»)" % texto)
	var re := RegEx.create_from_string("^\\d\\d:\\d\\d — ")
	_ok(linhas.size() >= 4 and re.search(linhas[2]) != null and re.search(linhas[3]) != null, "N32-1: cada aviso com a hora")
	var ModeloA = load("res://cenas/mestre/modelo_mestre.gd")
	_ok(texto.contains(ModeloA.texto_alerta(bloco["alertas"][0])) and texto.contains(ModeloA.texto_alerta(bloco["alertas"][1])),
		"N32-1: os dois avisos no mesmo bloco, por ordem")
	_ok(acks.size() == 1 and acks[0][0] == ["al-1", "al-2"] and acks[0][1] == 3, "N32-1: confirma ao servidor os dois ids e os perdidos (veio %s)" % [acks])
	# O mesmo bloco outra vez (a ligação caiu antes de a confirmação chegar): não aparece de novo, confirma-se outra vez.
	var antes: String = c._bloco_texto.text
	_rede._ao_receber(JSON.stringify(bloco))
	await _quadros(1)
	_ok(c._bloco_texto.text == antes, "N32-1: o duplicado (os mesmos ids) não repete os avisos")
	_ok(acks.size() == 2 and acks[1][0] == ["al-1", "al-2"], "N32-1: o duplicado também se confirma")
	# Um toque fecha.
	c._bloco_fechar.pressed.emit()
	await _quadros(1)
	_ok(not painel.visible, "N32-1: um toque fecha o bloco")
	# Ao vivo: o MASTER_ALERTA com id vai aos alertas e confirma-se; o mesmo id outra vez não repete.
	var n: int = c.alertas.size()
	var vivo := {"v": 2, "type": "MASTER_ALERTA", "roomId": "sala-teste", "id": "al-9", "ordem": 9, "hora": "2026-11-12T21:30:00.000Z",
		"motivo": "segunda_ligacao", "papel": "jogadora", "nome": "Heroína Teste"}
	_rede._ao_receber(JSON.stringify(vivo))
	await _quadros(1)
	_ok(c.alertas.size() == n + 1 and acks.size() == 3 and acks[2][0] == ["al-9"], "N32-1: o alerta ao vivo aparece e confirma-se pelo id")
	_rede._ao_receber(JSON.stringify(vivo))
	await _quadros(1)
	_ok(c.alertas.size() == n + 1, "N32-1: o mesmo alerta ao vivo repetido não aparece duas vezes")
	_ok(not painel.visible, "N32-1: o alerta ao vivo não abre o bloco")
	# Um bloco só com perdidos (tudo o resto expirou): mostra-se na mesma — perda silenciosa nunca.
	_rede._ao_receber(JSON.stringify({"v": 2, "type": "MASTER_ALERTAS", "roomId": "sala-teste", "perdidos": 2, "alertas": []}))
	await _quadros(1)
	_ok(painel.visible and c._bloco_texto.text.begins_with("perdidos por limite: 2"), "N32-1: só perdidos também se mostra (veio «%s»)" % c._bloco_texto.text)
	_ok(acks.size() == 5 and acks[3][0] == ["al-9"] and acks[4][0] == [] and acks[4][1] == 2,
		"N32-1: o alerta ao vivo repetido confirma-se outra vez, e o bloco só de perdidos confirma os perdidos (veio %s)" % [acks])
	c._bloco_fechar.pressed.emit()
	await _quadros(1)
	# Bloco vazio (nada pendente): nada aparece.
	_rede._ao_receber(JSON.stringify({"v": 2, "type": "MASTER_ALERTAS", "roomId": "sala-teste", "perdidos": 0, "alertas": []}))
	await _quadros(1)
	_ok(not painel.visible, "N32-1: bloco vazio não abre nada")
	# Fora do lugar do Mestre, a Rede não entrega o bloco (privacidade, desenho §7).
	var vistos: Array = []
	var ouvir := func(m): vistos.append(str(m.get("type", "")))
	_rede.mestre_recebido.connect(ouvir)
	_rede.papel = "jogadora"
	_rede._ao_receber(JSON.stringify(bloco))
	_rede.papel = "mestre"
	_rede.mestre_recebido.disconnect(ouvir)
	_ok(not vistos.has("MASTER_ALERTAS"), "N32-1: fora do lugar do Mestre o bloco não passa da Rede")


## Ordem 29 (V25): a ligação cai com um comando do Mestre em voo e o recibo perde-se. Antes, `_em_voo` só se esvaziava
## com o recibo: os botões do cartão ficavam em «A enviar…» e desligados até ao fim da sessão, e o esquema de colocação
## parado. O contrato já tem a resposta (como na V19 da jogadora): ao voltar à mesa, RECEIPT_QUERY com os ids em voo
## (o servidor responde aos cmdId/intentId do Mestre); o recibo destranca; DESCONHECIDA (não aplicado) também, e no
## esquema conta como não aplicada (pára; a colocação fica na lista).
func _recibo_perdido(c, card_ia: Dictionary) -> void:
	print("== V25: recibo do Mestre perdido na queda da ligação ==")
	var consultas: Array = []
	var tem: bool = "consultar_fn" in c
	_ok(tem, "o ecrã do Mestre tem por onde consultar recibos (consultar_fn)")
	if tem:
		c.consultar_fn = func(ids): consultas.append(ids.duplicate())
	var estado_antes: int = _rede.estado_ligacao
	var cair_e_voltar := func():
		_rede.estado_ligacao = _rede.Ligacao.A_ESPERAR
		_rede.ligacao_mudou.emit(_rede.estado_ligacao)
		_rede.estado_ligacao = _rede.Ligacao.NA_MESA
		_rede.ligacao_mudou.emit(_rede.estado_ligacao)
	var card := card_ia.duplicate(true)
	card["cartaoId"] = "c-o29"
	_rede._ao_receber(JSON.stringify(card))
	await _quadros(1)
	var acao: String = str(c._botoes[0].get_meta("acao", ""))
	c.tocar(acao)
	if c._botoes[0].text.begins_with(Textos.DE_NOVO_PARA.split("%")[0]) and Textos.DE_NOVO_PARA.split("%")[0] != "":
		c.tocar(acao)  # acção de dois toques
	var u := _ultimo()
	var id := str(u.get("cmdId", u.get("intentId", "")))
	_ok(c._botoes[0].disabled, "com o comando em voo, os botões do cartão ficam desligados")
	cair_e_voltar.call()
	_ok(consultas.size() == 1 and consultas[0] is Array and (consultas[0] as Array).has(id),
		"ao voltar à mesa, pergunta pelo recibo do comando em voo (%s)" % [consultas])
	var n_alertas: int = c.alertas.size()
	_rede._ao_receber(JSON.stringify({"v": 2, "type": "ROOM_RECEIPT", "roomId": "sala-teste", "intentId": id, "estado": "DESCONHECIDA"}))
	await _quadros(1)
	_ok(not c._botoes[0].disabled, "DESCONHECIDA (o servidor não o tem): os botões do cartão voltam")
	_ok(c.alertas.size() == n_alertas, "DESCONHECIDA não é recusa: nenhum alerta")
	_rede._ao_receber(JSON.stringify({"v": 2, "type": "ROOM_EVENT", "roomId": "sala-teste", "seq": 9990, "revision": 990,
		"ts": "2026-11-12T00:00:00Z", "tipo": "cartao_fechado", "dados": {"cartaoId": "c-o29", "decisao": "aprovar"}}))
	await _quadros(1)

	# Esquema de colocação: o recibo APLICADA que chega pela consulta segue o esquema; DESCONHECIDA pára-o.
	c._aba_mesa.escolher_colocar("orc-teste")
	c._aba_mesa.ligar_esquema(true)
	c.casa_tocada(Vector2i(11, 7))
	c.casa_tocada(Vector2i(12, 7))
	c.casa_tocada(Vector2i(13, 7))
	c._aba_mesa.colocar_esquema()
	u = _ultimo()
	var antes := _comandos.size()
	cair_e_voltar.call()
	_ok(consultas.size() == 2 and (consultas[1] as Array).has(str(u.get("cmdId", ""))), "esquema: pergunta pelo recibo da colocação em voo")
	_rede._ao_receber(JSON.stringify({"v": 2, "type": "ROOM_RECEIPT", "roomId": "sala-teste", "cmdId": str(u.get("cmdId", "")),
		"estado": "APLICADA", "seq": 9991, "revision": 991}))
	await _quadros(1)
	u = _ultimo()
	_ok(_comandos.size() == antes + 1 and int(u.get("casa", {}).get("x", -1)) == 12, "o recibo da consulta manda a colocação seguinte")
	cair_e_voltar.call()
	_rede._ao_receber(JSON.stringify({"v": 2, "type": "ROOM_RECEIPT", "roomId": "sala-teste", "intentId": str(u.get("cmdId", "")), "estado": "DESCONHECIDA"}))
	await _quadros(1)
	_ok(not c._aba_mesa.em_serie() and c._aba_mesa.esquema.size() == 2 and c._aba_mesa._estado.text == Textos.ESQUEMA_PAROU,
		"DESCONHECIDA pára o esquema e a colocação não feita fica na lista (como numa recusa)")
	cair_e_voltar.call()
	_ok(consultas.size() == 3, "sem nada em voo, não pergunta por nada (%d consultas)" % consultas.size())
	c._aba_mesa.limpar_esquema()
	c._aba_mesa.ligar_esquema(false)
	c._aba_mesa.parar()
	_rede.estado_ligacao = estado_antes


## Ordem 40: o clima na arena do Mestre — liga sem reiniciar, o chão e os corpos das figuras ganham a camada
## (pelos grupos, com a arena de verdade), nada do jogo muda, e desligado tudo volta ao que era.
func _clima(c) -> void:
	print("== clima (ordem 40) ==")
	var a = c._arena
	var cl = a.clima
	_ok(cl != null and cl.parado() and not cl.is_processing(), "a arena do Mestre tem o módulo do clima, desligado e a dormir")
	var chao: Array[Node] = []
	for n in get_nodes_in_group(&"clima_chao"):
		if a.is_ancestor_of(n):
			chao.append(n)
	var figuras: Array[Node] = []
	for n in get_nodes_in_group(&"clima_figura"):
		if a.is_ancestor_of(n):
			figuras.append(n)
	# Ordem 45: o chão é o do mapa (a zona fina e a larga), como na arena do jogador.
	_ok(chao.size() == 2 and figuras.size() == a.figuras_desenhadas(), "o chão do mapa (2) e as figuras (%d) estão nos grupos do clima" % figuras.size())
	var tam := Vector2(a.largura * a.casa_m, a.altura * a.casa_m)
	_ok(cl.caixa_minimo().x <= 0.0 and cl.caixa_minimo().z <= 0.0 and cl.caixa_tamanho().x >= tam.x and cl.caixa_tamanho().z >= tam.y,
		"a caixa do clima cobre o campo inteiro (%d×%d m)" % [int(tam.x), int(tam.y)])
	var comandos_antes := _comandos.size()
	var destaques_antes: int = a.casas_destacadas().size()
	var desenhadas_antes: int = a.figuras_desenhadas()
	# Ordem 45: a aba Ambiente (teste anterior) já ligou e desligou a chuva neste ecrã; o módulo procura os alvos de
	# 0,5 em 0,5 s, e esse relógio ficou a meio. Começa-se do zero para os 4 quadros chegarem (sem janela o passo de
	# tempo é curto e varia de máquina para máquina).
	cl._ate_procurar = 0.0
	_ok(cl.definir("neve", "forte"), "neve forte: liga sem reiniciar a cena")
	await _quadros(4)
	var vestidos: Array[Node] = cl.vestidos()
	var corpos := 0
	var sem_luz := 0
	for n in vestidos:
		if n != chao[0]:
			corpos += 1
			var m := (n as MeshInstance3D).get_active_material(0) as BaseMaterial3D
			if m != null and m.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				sem_luz += 1
	_ok((chao[0] as MeshInstance3D).material_overlay != null and vestidos.has(chao[0]), "o chão ganha a camada do clima (material_overlay)")
	_ok(corpos >= figuras.size() and sem_luz == 0, "os corpos das figuras também (%d malhas); anéis e sombras de contacto ficam de fora" % corpos)
	_ok(cl.neve > 0.0 and cl.contagem_atual("neve") > 0, "a neve cai (%d flocos) e começa a pousar" % cl.contagem_atual("neve"))
	_ok(cl.definir("chuva", "fraco") and cl.tipo == "chuva", "troca para chuva fraca sem reiniciar")
	await _quadros(4)
	_ok(cl.molhado > 0.0 and cl.contagem_atual("chuva") > 0, "a chuva cai (%d gotas) e o chão começa a molhar" % cl.contagem_atual("chuva"))
	_ok(_comandos.size() == comandos_antes and a.casas_destacadas().size() == destaques_antes and a.figuras_desenhadas() == desenhadas_antes,
		"o clima não manda comando nenhum nem mexe em casas, destaques ou figuras (só apresentação)")
	cl.desligar()
	cl.definir_acumulacao(0.0, 0.0)
	cl.segundos_transicao = 0.01
	# Ordem 41: o que a neve forte juntou (aglomerado, gelo) derrete devagar, de propósito — com isso por
	# derreter o módulo continua acordado (posto à mão: quanto sobra depois de 4 quadros depende do passo
	# de tempo da máquina). «Seco» é também o estado forte a zero; e o vento da nevasca acalma em
	# segundos_levantar (encurtado aqui, como a transição).
	cl.definir_forte(0.5, 0.0, 0.0, 0.0)
	await _quadros(4)
	_ok(cl.aglomerado > 0.0 and not cl.parado() and cl.is_processing(), "ordem 41: com neve aglomerada por derreter, o módulo não dorme")
	cl.segundos_levantar = 0.01
	cl.definir_forte(0.0, 0.0, 0.0, 0.0)
	await _quadros(4)
	var limpos := (chao[0] as MeshInstance3D).material_overlay == null
	for n in vestidos:
		if is_instance_valid(n) and (n as MeshInstance3D).material_overlay != null:
			limpos = false
	_ok(limpos and cl.parado() and not cl.is_processing(), "desligado e seco: a camada sai do chão e das figuras e o módulo dorme")


## Ordem 52: o perfil gráfico no ecrã do Mestre. A escolha é a das definições (a mesma da ⚙ da jogadora:
## arte/perfis/escolha_perfil.gd), o efeito é o do mesmo AplicadorPerfil pelo código das duas arenas
## (campo_da_mesa.gd ligar_perfil). Sem escolha, a arena do Mestre fica como antes: relva a 1,0, clima no Médio.
func _perfil_grafico(c) -> void:
	print("== perfil gráfico (ordem 52) ==")
	var EscolhaPerfil = load("res://arte/perfis/escolha_perfil.gd")
	var a = c._arena
	var cl = a.clima
	cl.definir_por_nome("nenhum")
	var real_existia := FileAccess.file_exists(EscolhaPerfil.ARQ)
	var real_antes := FileAccess.get_file_as_string(EscolhaPerfil.ARQ) if real_existia else ""

	# O mesmo caminho, sem cópia: as duas arenas ligam o perfil pelo código partilhado e não têm números próprios.
	var cod_m := FileAccess.get_file_as_string("res://cenas/mestre/arena_mestre.gd")
	var cod_j := FileAccess.get_file_as_string("res://cenas/arena/arena.gd")
	var cod_hud := FileAccess.get_file_as_string("res://hud/hud.gd")
	var cod_ecra := FileAccess.get_file_as_string("res://cenas/mestre/mestre.gd")
	_ok(cod_m.contains("CampoDaMesa.ligar_perfil(") and cod_j.contains("CampoDaMesa.ligar_perfil("),
		"as duas arenas ligam o perfil pelo mesmo código (campo_da_mesa.gd ligar_perfil)")
	_ok(not cod_m.contains("folhagem_densidade") and not cod_m.contains("CONTAGEM") and not cod_ecra.contains("folhagem_densidade"),
		"o ecrã do Mestre não tem números de perfil próprios")
	_ok(cod_hud.contains("EscolhaPerfil.PERFIS") and cod_hud.contains("EscolhaPerfil.seletor()") and cod_ecra.contains("EscolhaPerfil.seletor()"),
		"a ⚙ da jogadora e a do Mestre montam o mesmo seletor «Gráficos» da mesma lista")

	# Sem escolha: como antes da ordem 52.
	var relva = a.mapa.relva
	relva.atualizar_lod(a.camera.global_position)
	var tufos_sem: int = relva.tufos_ativos()
	_ok(a.perfil_atual() == "" and is_equal_approx(a.mapa.densidade_relva, 1.0) and cl.perfil == "medio",
		"sem escolha: nenhum perfil aplicado, relva a %.2f, clima «%s» (como antes)" % [a.mapa.densidade_relva, cl.perfil])
	cl.definir_por_nome("chuva-forte")
	var chuva_sem: int = cl.contagem_alvo("chuva")
	cl.definir_por_nome("nenhum")
	_ok(chuva_sem == 5000, "sem escolha: a chuva forte pede as 5000 gotas do Médio (%d)" % chuva_sem)
	var op: OptionButton = c.find_child("Graficos", true, false)
	_ok(op != null and op.item_count == 3 and op.selected == -1, "a aba Sala tem a linha «Gráficos», 3 perfis, nenhum marcado")
	var nomes: Array = []
	for i in (op.item_count if op != null else 0):
		nomes.append(op.get_item_text(i))
	_ok(nomes == Array(EscolhaPerfil.NOMES) and nomes == ["Baixo", "Médio", "Alto"], "os nomes da ⚙ da jogadora: %s" % [nomes])

	# A escolha guardada: o mesmo ficheiro e a mesma chave da ⚙ (num ficheiro de prova, para não mexer no verdadeiro).
	var arq := "user://prova-ordem52-perfil.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(arq))
	_ok(EscolhaPerfil.escolhido(arq) == "", "sem ficheiro: sem escolha")
	var cfg := ConfigFile.new()
	cfg.set_value("pref", "camera", "360")
	cfg.save(arq)
	_ok(EscolhaPerfil.escolhido(arq) == "", "ficheiro sem a chave do perfil: sem escolha")
	_ok(EscolhaPerfil.guardar("Baixo", arq) and EscolhaPerfil.escolhido(arq) == "baixo", "guardar «Baixo» e lê-lo como «baixo»")
	var cfg2 := ConfigFile.new()
	cfg2.load(arq)
	_ok(str(cfg2.get_value("pref", "camera", "")) == "360" and str(cfg2.get_value("pref", "perfil", "")) == "baixo",
		"guardar escreve [pref] perfil e deixa as outras preferências")
	cfg2.set_value("pref", "perfil", "ultra")
	cfg2.save(arq)
	_ok(EscolhaPerfil.escolhido(arq) == "" and not EscolhaPerfil.guardar("ultra", arq), "um nome que não é perfil não é escolha")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(arq))

	# O Mestre escolhe «Baixo» na linha «Gráficos»: a arena obedece.
	op.select(0)
	op.item_selected.emit(0)
	await _quadros(1)
	relva.atualizar_lod(a.camera.global_position)
	var tufos_baixo: int = relva.tufos_ativos()
	_ok(a.perfil_atual() == "baixo" and a.perfis.atual == "baixo" and op.selected == 0, "«Baixo» na linha «Gráficos» aplica o perfil baixo")
	_ok(is_equal_approx(a.mapa.densidade_relva, float(AplicadorPerfil.PERFIS["baixo"]["folhagem_densidade"])) and tufos_baixo < tufos_sem,
		"baixo: relva a %.2f, %d tufos desenhados (sem escolha: %d)" % [a.mapa.densidade_relva, tufos_baixo, tufos_sem])
	var alvos := {}
	for nome in ["chuva-fraca", "chuva-forte", "neve-fraca", "neve-forte"]:
		cl.definir_por_nome(nome)
		alvos[nome] = [cl.contagem_alvo("chuva"), cl.contagem_alvo("neve"), cl.contagem_alvo("salpicos"), cl.contagem_alvo("veu")]
	cl.definir_por_nome("nenhum")
	_ok(cl.perfil == "baixo" and alvos == {"chuva-fraca": [900, 0, 0, 0], "chuva-forte": [2800, 0, 0, 0],
		"neve-fraca": [0, 1000, 0, 0], "neve-forte": [0, 3000, 0, 0]}, "baixo: as contagens do clima descem às do Baixo %s" % [alvos])
	_ok(FileAccess.file_exists(EscolhaPerfil.ARQ) == real_existia
		and (FileAccess.get_file_as_string(EscolhaPerfil.ARQ) if real_existia else "") == real_antes,
		"sem disco (Rede.persistir falso) a escolha não se escreve no ficheiro verdadeiro")

	# O mapa refaz-se (outra grelha) e volta à densidade escolhida; depois a grelha de antes.
	var w: int = a.largura
	var h: int = a.altura
	var casa: float = a.casa_m
	a.construir_grelha(w + 2, h + 2, casa)
	_ok(is_equal_approx(a.mapa.densidade_relva, 0.5), "o mapa refeito para outra grelha fica com a relva do perfil escolhido")
	a.construir_grelha(w, h, casa)

	# «Alto» e um nome estranho.
	_ok(c.escolher_perfil("Alto", false) and is_equal_approx(a.mapa.densidade_relva, 1.0) and cl.perfil == "alto" and op.selected == 2,
		"«Alto»: relva a 1,0 e clima no Alto")
	_ok(not c.escolher_perfil("ultra", false) and a.perfil_atual() == "alto", "um nome que não é perfil não muda nada")


## Ordem 54: a arena do Mestre abre depressa outra vez. O mapa da floresta de uma zona constrói-se UMA vez; os mapas
## seguintes da mesma zona nascem de uma cópia do molde dele (mapa/floresta/molde_floresta.gd). A prova de que nada
## muda: o RETRATO inteiro do mapa vestido (nós, transformações, malhas, materiais com todos os parâmetros, MultiMesh,
## grelha, estado dos scripts, o céu montado no dono) é igual, linha a linha, ao de um mapa construído de raiz.
func _molde_do_mapa() -> void:
	print("== o mapa reutilizado é o mesmo mapa (ordem 54) ==")
	var Molde = load("res://mapa/floresta/molde_floresta.gd")
	var Assentamento = load("res://cenas/arena/assentamento.gd")
	var CampoFlorestaS = load("res://mapa/floresta/campo_floresta.gd")
	var sozinho = CampoFlorestaS.new()
	_ok(sozinho.reutilizar_molde == false, "o mapa sozinho (filmes, medições) constrói-se sempre: reutilizar_molde nasce desligado")
	sozinho.free()
	_ok(FileAccess.get_file_as_string("res://cenas/arena/campo_da_mesa.gd").contains("mapa.reutilizar_molde = true"),
		"as duas arenas pedem o molde pelo módulo partilhado (campo_da_mesa.montar_mapa)")
	var tam := Vector2(17 * 1.5, 13 * 1.5)  # uma zona que nenhuma arena deste teste usou
	var zona := Rect2(Assentamento.origem_no_mapa(tam, 1.5), tam)

	Molde.ligado = false
	var a := _mapa_novo(zona)
	var ra: PackedStringArray = Molde.retrato(a)
	var n_mut_a: int = Molde.mutaveis(a).size()
	var ms_construido: int = a.medidas["carga_ms"]
	a.get_parent().free()
	Molde.ligado = true
	var g0: int = Molde.contas["guardados"]
	var v0: int = Molde.contas["vestidos"]
	var b := _mapa_novo(zona)
	_ok(Molde.contas["guardados"] == g0 + 1 and Molde.contas["vestidos"] == v0, "a 1.ª construção da zona guarda o molde")
	_ok(_iguais(Molde.retrato(b), ra), "guardar o molde não muda o mapa que o guardou (%d linhas do retrato)" % ra.size())
	# O jogo mexe no mapa vivo: o perfil, o recorte da câmara, a neve e a água na relva, a camada do clima no chão,
	# o LOD da relva, a ocupação da grelha, as medidas. Nada disto pode chegar ao molde.
	b.definir_densidade_relva(0.5)
	b.definir_recorte_vista(Vector3(1.0, 2.0, 3.0), 9.0)
	(b.materiais_relva()[0] as ShaderMaterial).set_shader_parameter("neve", 0.7)
	(b.get_node("Arena/Terreno") as GeometryInstance3D).material_overlay = StandardMaterial3D.new()
	b.relva.atualizar_lod(Vector3(40.0, 0.0, 40.0))
	b.grelha.ocupar(Vector2i(10, 10), "figura-teste")
	b.obstaculos.append({"nome": "teste"})
	b.medidas["teste"] = 1
	var c := _mapa_novo(zona)
	_ok(Molde.contas["vestidos"] == v0 + 1 and Molde.contas["guardados"] == g0 + 1,
		"o mapa seguinte da mesma zona veste-se do molde (não se constrói outra vez)")
	_ok(_iguais(Molde.retrato(c), ra, true),
		"o mapa vestido é IGUAL ao construído de raiz: %d linhas do retrato, nós, malhas, materiais, MultiMesh, grelha, estado, céu" % ra.size())
	var mut_b: Array = Molde.mutaveis(b)
	var mut_c: Array = Molde.mutaveis(c)
	var comuns := mut_c.filter(func(o): return o in mut_b)
	_ok(comuns.is_empty() and mut_c.size() == n_mut_a,
		"o vestido não partilha nada que mude com o outro mapa vivo (%d objectos seus: materiais, MultiMesh, grelha, lotes, acaso)" % mut_c.size())
	_ok(c.grelha.livre(Vector2i(10, 10)) and is_equal_approx(c.densidade_relva, 1.0) and not c.medidas.has("teste")
		and (c.get_node("Arena/Terreno") as GeometryInstance3D).material_overlay == null,
		"o que o jogo mexeu no outro mapa não chegou ao vestido (grelha livre, relva a 1,0, sem camada, medidas limpas)")
	var ms_vestido: int = c.medidas["carga_ms"]
	_ok(ms_vestido * 5 < ms_construido, "vestir é muito mais rápido do que construir (%d ms contra %d ms)" % [ms_vestido, ms_construido])
	c.definir_densidade_relva(0.5)
	c.grelha.ocupar(Vector2i(3, 3), "outra")
	(c.materiais_relva()[1] as ShaderMaterial).set_shader_parameter("agua", 0.4)
	var d := _mapa_novo(zona)
	_ok(_iguais(Molde.retrato(d), ra), "mexer num mapa vestido também não chega ao molde: o seguinte continua igual ao construído")
	for m in [b, c, d]:
		m.get_parent().free()


func _mapa_novo(zona: Rect2) -> Node3D:
	var CampoDaMesa = load("res://cenas/arena/campo_da_mesa.gd")
	var dono := Node3D.new()
	var amb := WorldEnvironment.new()
	amb.name = "Ambiente"
	amb.environment = Environment.new()
	dono.add_child(amb)
	var sol := DirectionalLight3D.new()
	sol.name = "Sol"
	dono.add_child(sol)
	var cam := Camera3D.new()
	cam.name = "Camera"
	dono.add_child(cam)
	root.add_child(dono)
	return CampoDaMesa.montar_mapa(dono, zona, ^"../Ambiente", ^"../Sol", ^"../Camera")


## Compara dois retratos; se diferirem, mostra a primeira linha diferente (e o total, com `contar`).
func _iguais(x: PackedStringArray, y: PackedStringArray, contar := false) -> bool:
	if x == y:
		return true
	var n := 0
	for i in maxi(x.size(), y.size()):
		var lx := x[i] if i < x.size() else "<nada>"
		var ly := y[i] if i < y.size() else "<nada>"
		if lx != ly:
			n += 1
			if n == 1:
				printerr("    retrato, linha %d:\n      %s\n      %s" % [i, lx.left(600), ly.left(600)])
	if contar:
		printerr("    %d linhas diferentes (de %d / %d)" % [n, x.size(), y.size()])
	return false


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
