extends SceneTree
## ORDEM AUTOJOGO — O JOGO JOGA SOZINHO PARA EQUILIBRAR. FERRAMENTA DE MEDIÇÃO (não é o jogo, não é a IA do jogo).
##
##   godot --headless --path cliente -s res://autojogo/autojogo.gd -- --autojogo --semente=N --registo=<ficheiro.jsonl>
##         --servidor=127.0.0.1:P [--velocidade=K] [--cenario=<json>] [--motor=<vlab-completo.js>] [--motor-falso]
##         [--node=<binário do node>] [--rodadas-max=60] [--limite-s=600]
##
## O que faz, sem janela e sem jogador:
##   1. lança o servidor de mesa DE VERDADE para uma partida (servidor/autojogo/servidor-autojogo.mjs: a sala e o
##      WebSocket do jogo, dado semeado com N, relógio fixo, criaturas em modo manual) na porta de --servidor;
##   2. o Mestre da bancada entra (lugar próprio), põe as criaturas do cenário no lobby e nas casas delas;
##   3. a heroína 1 entra pela Rede do jogo e a ARENA INTEGRADA (res://cenas/arena/arena.tscn) monta-se sobre ela, como
##      no aparelho de uma jogadora; a heroína 2 entra por um lugar próprio;
##   4. a IA de bancada (ia_bancada.gd) joga as duas heroínas (ROOM_INTENT) e as criaturas (MASTER_ACT); o Mestre da
##      bancada aprova os cartões (desgraça, progresso) tal como vêm;
##   5. no fim da batalha (ou no tecto de rodadas) escreve o resumo e fecha (o servidor fecha-se quando o Mestre sai).
##
## Registo: JSON Lines, uma linha por facto, TODAS com a semente; sem horas nem ids aleatórios (a mesma semente dá o
## mesmo ficheiro, byte a byte). Linhas: inicio · vez · acao · evento · resumo.
## --velocidade=K: pausa de 0,25/K s entre passos (só o ritmo; o resultado não depende dele). 0 = sem pausa.
## Código de saída: 0 com resumo escrito; 1 se a partida não chegou ao fim (erro, tempo esgotado).

const IA := preload("res://autojogo/ia_bancada.gd")
const Lugar := preload("res://autojogo/lugar_bancada.gd")
const CENA_ARENA := "res://cenas/arena/arena.tscn"
const FORMATO := "autojogo/1"
const ACCOES_POR_VEZ_MAX := 8
const RE_UUID := "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"

var _args := {}
var _semente := 1
var _passo_s := 0.25
var _registo: FileAccess = null
var _pid := -1
var _url := ""
var _rede: Node
var _estado: Node
var _mestre  # Lugar
var _h2  # Lugar (heroína 2)
var _cenario: Dictionary = {}
var _info: Dictionary = {}
var _arena: Node = null
var _opcoes_rede: Dictionary = {}
var _respostas_rede: Dictionary = {}
var _eventos_escritos := 0
var _re_uuid := RegEx.new()
var _t0 := 0
var _limite_ms := 600000
var _vezes: Dictionary = {}  # "rodada|figuraId" → {andou, atacou, accoes}
var _ordem_vezes: Array = []
var _parado := false  # uma falha pára tudo (o quit só acontece depois do fecho do servidor)


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


# ------------------------------------------------------------------ utilitários

func _ler_args() -> void:
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			continue
		var i := a.find("=")
		if i < 0:
			_args[a.substr(2)] = true
		else:
			_args[a.substr(2, i - 2)] = a.substr(i + 1)


func _arg(nome: String, padrao: Variant = null) -> Variant:
	return _args.get(nome, padrao)


func _falhar(texto: String) -> void:
	if _parado:
		return
	_parado = true
	printerr("[autojogo] FALHA: ", texto)
	if _registo != null:
		_escrever({"tipo": "falha", "texto": texto})
		_registo.close()
		_registo = null
	_encerrar(1)


func _encerrar(codigo: int) -> void:
	if _mestre != null:
		_mestre.fechar()
	if _h2 != null:
		_h2.fechar()
	if _pid > 0:
		await create_timer(0.3).timeout
		if OS.is_process_running(_pid):
			OS.kill(_pid)
	quit(codigo)


func _tempo_esgotado() -> bool:
	return _parado or Time.get_ticks_msec() - _t0 > _limite_ms


func _poll() -> void:
	if _mestre != null:
		_mestre.poll()
	if _h2 != null:
		_h2.poll()


## Espera até `cond` (ou `segundos`). Devolve se aconteceu.
func _esperar(cond: Callable, segundos: float) -> bool:
	var t := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t > int(segundos * 1000.0) or _tempo_esgotado():
			return false
		await process_frame
		_poll()
	return true


func _pausa() -> void:
	if _passo_s <= 0.0:
		await process_frame
		_poll()
		return
	var t := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t < int(_passo_s * 1000.0):
		await process_frame
		_poll()


## Tira do registo o que não é da partida: carimbos, números de fluxo e ids de intenção (aleatórios na Rede do jogo).
func _limpo(v: Variant) -> Variant:
	if v is Dictionary:
		var r := {}
		var chaves: Array = v.keys()
		chaves.sort()
		for k in chaves:
			if k in ["ts", "seq", "revision", "roomId", "v", "intentId", "cmdId", "intentIdOrigem", "revertidaEm"]:
				continue
			r[k] = _limpo(v[k])
		return r
	if v is Array:
		var a: Array = []
		for x in v:
			a.append(_limpo(x))
		return a
	if v is String and _re_uuid.search(v) != null:
		return "<id>"
	return v


## O JSON do Godot lê todos os números como float: os inteiros voltam a inteiros (22, não 22.0).
func _inteiros(v: Variant) -> Variant:
	if v is float and is_finite(v) and v == floorf(v) and absf(v) < 9.0e15:
		return int(v)
	if v is Dictionary:
		var r := {}
		for k in v:
			r[k] = _inteiros(v[k])
		return r
	if v is Array:
		return (v as Array).map(_inteiros)
	return v


func _escrever(linha: Dictionary) -> void:
	var l := {"semente": _semente}
	l.merge(linha)
	_registo.store_line(JSON.stringify(_inteiros(l), "", false))
	_registo.flush()


# ------------------------------------------------------------------ a partida

func _correr() -> void:
	_t0 = Time.get_ticks_msec()
	_re_uuid.compile(RE_UUID)
	_ler_args()
	if not _args.has("autojogo"):
		_falhar("falta --autojogo (este script só corre no modo de autojogo)")
		return
	_semente = int(str(_arg("semente", "1")))
	var k := float(str(_arg("velocidade", "1")))
	_passo_s = 0.0 if k <= 0.0 else 0.25 / k
	_limite_ms = int(float(str(_arg("limite-s", "600"))) * 1000.0)
	var servidor := str(_arg("servidor", ""))
	if servidor == "" or servidor.find(":") < 0:
		_falhar("falta --servidor=127.0.0.1:PORTA (a Rede do jogo liga-se a ele)")
		return
	var porta := int(servidor.get_slice(":", 1))
	_url = "ws://%s/ws" % servidor
	var caminho_registo := str(_arg("registo", "user://autojogo-s%d.jsonl" % _semente))
	_registo = FileAccess.open(caminho_registo, FileAccess.WRITE)
	if _registo == null:
		_registo = null
		_falhar("não consegui abrir o registo: " + caminho_registo)
		return

	# 1. o servidor de bancada
	var raiz := ProjectSettings.globalize_path("res://").path_join("..")
	var script_srv := raiz.path_join("servidor/autojogo/servidor-autojogo.mjs").simplify_path()
	var caminho_cenario := str(_arg("cenario", raiz.path_join("servidor/autojogo/cenario-bancada.json"))).simplify_path()
	var info_path := caminho_registo + ".info.json"
	if FileAccess.file_exists(info_path):
		DirAccess.remove_absolute(info_path)
	var a_srv := [script_srv, "--porta=%d" % porta, "--semente=%d" % _semente, "--info=" + info_path,
		"--cenario=" + caminho_cenario, "--vida-max-s=%d" % int(_limite_ms / 1000 + 60)]
	if _args.has("motor"):
		a_srv.append("--motor=" + str(_arg("motor")))
	if _args.has("motor-falso"):
		a_srv.append("--motor-falso")
	_pid = OS.create_process(str(_arg("node", "node")), a_srv)
	if _pid <= 0:
		_falhar("não consegui lançar o servidor de bancada (node)")
		return
	if not await _esperar(func(): return FileAccess.file_exists(info_path), 60.0):
		_falhar("o servidor de bancada não ficou pronto em 60 s")
		return
	_info = JSON.parse_string(FileAccess.get_file_as_string(info_path))
	DirAccess.remove_absolute(info_path)
	_cenario = JSON.parse_string(FileAccess.get_file_as_string(caminho_cenario))
	_escrever({"tipo": "inicio", "formato": FORMATO, "motor": _info.get("motor"), "motorSha256": _info.get("motorSha256"),
		"cenario": _info.get("cenario"), "cenarioSha256": _info.get("cenarioSha256"), "fichasSha256": _info.get("fichasSha256"),
		"heroinas": (_cenario["heroinas"] as Array).map(func(h): return h["fichaId"]),
		"criaturas": (_cenario["criaturas"] as Array).map(func(c): return c["fichaId"]),
		"ia": "ia_bancada.gd (aproxima · ataca ao alcance · encerra)",
		"texto": "Partida de autojogo, semente %d, motor %s." % [_semente, _info.get("motor")]})
	print("[autojogo] servidor pronto: ", JSON.stringify(_info))

	# 2. o Mestre da bancada (primeiro: as entradas sempre pela mesma ordem, para o dado semeado andar igual)
	_mestre = Lugar.new("mestre", _semente)
	_mestre.ligar(_url, {"v": 2, "type": "ROOM_JOIN", "papel": "mestre", "pin": str(_cenario["pin"]), "cliente": Lugar.VERSAO})
	if not await _esperar(func(): return _mestre.na_mesa and _mestre.vistas_recebidas > 0, 20.0):
		_falhar("o Mestre da bancada não entrou: %s" % [_mestre.erros])
		return
	var fichas_criaturas: Array = []
	for c in _cenario["criaturas"]:
		if not fichas_criaturas.has(c["fichaId"]):
			fichas_criaturas.append(c["fichaId"])
	if not await _comando_mestre("MASTER_LOBBY_SET", {"mapaId": str(_cenario.get("mapaId", "floresta")),
			"criaturasDisponiveis": fichas_criaturas, "npcsDisponiveis": []}):
		return
	for c in _cenario["criaturas"]:
		if not await _comando_mestre("MASTER_PLACE", {"fichaId": c["fichaId"], "casa": c["casa"]}):
			return

	# 3. a heroína 1 pela Rede do jogo + a arena integrada; a heroína 2 por um lugar próprio
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	_rede.persistir = false
	_rede.opcoes_recebidas.connect(func(m): _opcoes_rede = m)
	_rede.recibo_recebido.connect(func(id, _e, m): _respostas_rede[id] = m)
	_rede.recusa_recebida.connect(func(id, motivo, _t): _respostas_rede[id] = {"type": "ROOM_REJECT", "motivo": motivo})
	var h1: Dictionary = _cenario["heroinas"][0]
	_rede.entrar(str(h1["nome"]), str(h1["senha"]))
	if not await _esperar(func(): return _rede.na_mesa() and _estado.tem_snapshot, 20.0):
		_falhar("a heroína 1 não entrou pela Rede (%s)" % _rede.url_servidor())
		return
	_arena = (load(CENA_ARENA) as PackedScene).instantiate()
	root.add_child(_arena)
	print("[autojogo] arena integrada montada sobre a heroína 1")
	var lugares_h := {}  # figuraId → "rede" | Lugar
	if (_cenario["heroinas"] as Array).size() > 1:
		var h2: Dictionary = _cenario["heroinas"][1]
		_h2 = Lugar.new("heroina-2", _semente)
		_h2.ligar(_url, {"v": 2, "type": "ROOM_JOIN", "papel": "jogadora", "nome": str(h2["nome"]), "senha": str(h2["senha"]), "cliente": Lugar.VERSAO})
		if not await _esperar(func(): return _h2.na_mesa and _h2.figura_id != "", 20.0):
			_falhar("a heroína 2 não entrou: %s" % [_h2.erros])
			return
		lugares_h[_h2.figura_id] = _h2
	lugares_h[str(_estado.minha_figura_id)] = "rede"
	if (_cenario["heroinas"] as Array).size() > 2:
		_falhar("o cenário tem mais de 2 heroínas (a bancada joga até 2)")
		return

	# 4. começar
	if not await _comando_mestre("MASTER_START", {}):
		return

	# 5. jogar
	var rodadas_max := int(str(_arg("rodadas-max", "60")))
	var desfecho := ""
	while true:
		if _parado:
			return
		if _tempo_esgotado():
			_falhar("tempo esgotado (--limite-s) a meio da partida")
			return
		await _pausa()
		var vista := await _vista()
		if vista.is_empty():
			_falhar("o Mestre da bancada deixou de receber a vista")
			return
		_escrever_eventos()
		var fase := str(vista.get("fase", ""))
		if fase == "fim":
			# a vista pode chegar antes do evento `fim` (que traz o desfecho): espera-o
			await _esperar(func(): return _desfecho_do_fim() != "", 10.0)
			desfecho = _desfecho_do_fim()
			if desfecho == "":
				desfecho = "fim-sem-evento"
			break
		if int(vista.get("rodada", 0)) > rodadas_max:
			desfecho = "limite"
			break
		var mv: Dictionary = vista.get("mestre", {})
		var cartoes: Array = mv.get("cartoes", []) if mv.get("cartoes") is Array else []
		if not cartoes.is_empty():
			await _decidir_cartao(cartoes[0])
			continue
		if fase != "combate":
			continue
		var vez_id := str(vista.get("vezId", ""))
		if vez_id == "" or vez_id == "<null>":
			continue
		var figuras: Array = mv.get("figuras", [])
		var quem: Dictionary = {}
		for f in figuras:
			if str(f.get("id", "")) == vez_id:
				quem = f
		if quem.is_empty():
			_falhar("a figura da vez %s não está na vista" % vez_id)
			return
		var chave := "%d|%s" % [int(vista.get("rodada", 0)), vez_id]
		if not _vezes.has(chave):
			_vezes[chave] = {"andou": false, "atacou": false, "accoes": 0}
			_ordem_vezes.append(chave)
			_escrever({"tipo": "vez", "rodada": int(vista.get("rodada", 0)), "turno": _ordem_vezes.size(), "figura": _nome(quem),
				"figuraId": vez_id, "lado": quem.get("lado"), "vida": quem.get("vidaActual"), "x": quem.get("x"), "y": quem.get("y"),
				"texto": "Rodada %d, turno %d: vez de %s (vida %s)." % [int(vista.get("rodada", 0)), _ordem_vezes.size(), _nome(quem), str(quem.get("vidaActual"))]})
		var v: Dictionary = _vezes[chave]
		var lugar = lugares_h.get(vez_id, null) if str(quem.get("lado", "")) == "jogadora" else _mestre
		if lugar == null:
			_falhar("ninguém joga a figura %s" % vez_id)
			return
		var opcoes := await _opcoes_de(lugar, vez_id)
		if opcoes.is_empty():
			_falhar("as opções de %s não chegaram" % _nome(quem))
			return
		var d := IA.decidir(quem, figuras, opcoes, v)
		if int(v["accoes"]) >= ACCOES_POR_VEZ_MAX:
			d = {"acao": {"tipo": "encerrar"}, "razao": "tecto de acções por vez (bancada)"}
		var acao: Dictionary = d["acao"]
		var resp := await _agir(lugar, vez_id, acao)
		v["accoes"] = int(v["accoes"]) + 1
		var estado_r := str(resp.get("estado", resp.get("motivo", "?")))
		if str(resp.get("type", "")) == "ROOM_REJECT":
			estado_r = "RECUSADA:" + str(resp.get("motivo", "?"))
		if acao["tipo"] == "mover" and estado_r == "APLICADA":
			v["andou"] = true
		if acao["tipo"] == "atacar":
			v["atacou"] = true  # aplicado, à espera do Mestre ou recusado: não se tenta de novo nesta vez
		_escrever({"tipo": "acao", "rodada": int(vista.get("rodada", 0)), "turno": _ordem_vezes.size(), "figura": _nome(quem),
			"acao": _acao_legivel(acao, figuras), "razao": d["razao"], "resultado": estado_r,
			"texto": "%s: %s (%s) → %s." % [_nome(quem), _texto_acao(acao, figuras), d["razao"], estado_r]})
		if estado_r.begins_with("RECUSADA") or estado_r == "?":
			if acao["tipo"] == "encerrar":
				_falhar("o servidor recusou o «encerrar» de %s: %s" % [_nome(quem), JSON.stringify(resp)])
				return

	# 6. resumo
	var final := await _vista()
	_escrever_eventos()
	_escrever_resumo(final, desfecho)
	_registo.close()
	_registo = null
	print("[autojogo] partida acabada: semente %d, desfecho %s, %d turnos, %.1f s" % [_semente, desfecho, _ordem_vezes.size(), (Time.get_ticks_msec() - _t0) / 1000.0])
	_encerrar(0)


## O desfecho vem no evento `fim` (vitoria | morte | terminada).
func _desfecho_do_fim() -> String:
	for i in range(_mestre.eventos.size() - 1, -1, -1):
		var e: Dictionary = _mestre.eventos[i]
		if str(e.get("tipo", "")) == "fim" and e.get("dados") is Dictionary:
			return str(e["dados"].get("desfecho", ""))
	return ""


func _nome(f: Dictionary) -> String:
	return str(f.get("nome", f.get("nomePublico", f.get("id", "?"))))


func _nome_id(id: String, figuras: Array) -> String:
	for f in figuras:
		if str(f.get("id", "")) == id:
			return _nome(f)
	return id


func _acao_legivel(acao: Dictionary, figuras: Array) -> Dictionary:
	var a := acao.duplicate(true)
	if a.has("alvoId"):
		a["alvo"] = _nome_id(str(a["alvoId"]), figuras)
	return a


func _texto_acao(acao: Dictionary, figuras: Array) -> String:
	match str(acao.get("tipo", "")):
		"atacar":
			return "ataca %s com %s" % [_nome_id(str(acao["alvoId"]), figuras), acao["arma"]]
		"mover":
			return "anda para (%d, %d)" % [int(acao["destino"]["x"]), int(acao["destino"]["y"])]
		"encerrar":
			return "encerra a vez"
	return str(acao.get("tipo", "?"))


func _vista() -> Dictionary:
	var alvo: int = _mestre.pedir_vista()
	if not await _esperar(func(): return _mestre.vistas_recebidas >= alvo, 10.0):
		return {}
	return _mestre.vista


func _comando_mestre(tipo: String, campos: Dictionary) -> bool:
	await _vista()  # a revisão do Mestre em dia
	var id: String = _mestre.comando(tipo, campos)
	if not await _esperar(func(): return _mestre.respostas.has(id), 10.0):
		_falhar("%s sem resposta do servidor" % tipo)
		return false
	var r: Dictionary = _mestre.respostas[id]
	if str(r.get("estado", "")) != "APLICADA":
		_falhar("%s não foi aceite: %s" % [tipo, JSON.stringify(_limpo(r))])
		return false
	return true


## As opções do lugar que joga esta vez (as da revisão corrente desse lugar).
func _opcoes_de(lugar, vez_id: String) -> Dictionary:
	if lugar is String:  # a Rede do jogo
		var ok := await _esperar(_opcoes_rede_prontas.bind(vez_id), 5.0)
		return _opcoes_rede if ok else {}
	var ok2 := await _esperar(_opcoes_lugar_prontas.bind(lugar, vez_id), 5.0)
	return lugar.opcoes if ok2 else {}


func _opcoes_rede_prontas(vez_id: String) -> bool:
	var rev = _estado.revisao
	return str(_opcoes_rede.get("vezId", "")) == vez_id and rev != null and int(_opcoes_rede.get("revision", -1)) == int(rev)


func _opcoes_lugar_prontas(lugar, vez_id: String) -> bool:
	return str(lugar.opcoes.get("vezId", "")) == vez_id and int(lugar.opcoes.get("revision", -1)) == lugar.revision


## Manda a acção pelo lugar certo e espera a resposta do servidor.
func _agir(lugar, vez_id: String, acao: Dictionary) -> Dictionary:
	if lugar is String:
		var caixa := {"id": ""}  # os lambdas do GDScript capturam por valor: o id volta numa caixa
		if not await _esperar(_enviar_pela_rede.bind(acao, caixa), 5.0):
			return {"type": "ROOM_REJECT", "motivo": "a Rede não enviou"}
		var id: String = caixa["id"]
		await _esperar(func(): return _respostas_rede.has(id), 10.0)
		return _respostas_rede.get(id, {})
	var id2 := ""
	if lugar.papel == "mestre":
		id2 = lugar.comando("MASTER_ACT", {"figuraId": vez_id, "acao": acao})
	else:
		id2 = lugar.intencao(acao)
	await _esperar(func(): return lugar.respostas.has(id2), 10.0)
	return lugar.respostas.get(id2, {})


func _enviar_pela_rede(acao: Dictionary, caixa: Dictionary) -> bool:
	caixa["id"] = _rede.enviar_intencao(acao, _estado.revisao)
	return caixa["id"] != ""


func _decidir_cartao(c: Dictionary) -> void:
	var tipo := str(c.get("tipo", ""))
	var id := ""
	if tipo == "dados":
		_falhar("cartão de dados físicos na bancada (não devia existir)")
		return
	id = _mestre.comando("MASTER_APPROVE", {"cartaoId": str(c.get("cartaoId", "")), "decisao": "aprovar"})
	await _esperar(func(): return _mestre.respostas.has(id), 10.0)
	var r: Dictionary = _mestre.respostas.get(id, {})
	_escrever({"tipo": "cartao", "cartao": tipo, "proposta": _limpo(c.get("proposta")), "decisao": "aprovar",
		"resultado": str(r.get("estado", r.get("motivo", "?"))),
		"texto": "O Mestre da bancada aprovou o cartão de %s tal como veio." % tipo})


func _escrever_eventos() -> void:
	while _eventos_escritos < _mestre.eventos.size():
		var e: Dictionary = _mestre.eventos[_eventos_escritos]
		_eventos_escritos += 1
		_escrever({"tipo": "evento", "evento": str(e.get("tipo", "")), "dados": _limpo(e.get("dados", {}))})


func _escrever_resumo(vista: Dictionary, desfecho: String) -> void:
	var mv: Dictionary = vista.get("mestre", {})
	var est: Dictionary = vista.get("estatisticas", {})
	var dc: Dictionary = est.get("danoCausado", {})
	var ds: Dictionary = est.get("danoSofrido", {})
	var at: Dictionary = est.get("ataques", {})
	var figs: Array = []
	for f in mv.get("figuras", []):
		if not bool(f.get("colocada", false)):
			continue
		var id := str(f.get("id", ""))
		figs.append({"figura": _nome(f), "figuraId": id, "fichaId": f.get("fichaId"), "lado": f.get("lado"),
			"vidaTotal": f.get("vidaTotal"), "vidaRestante": f.get("vidaActual"), "viva": f.get("vivo"),
			"danoCausado": dc.get(id, 0), "danoSofrido": ds.get(id, 0), "ataques": at.get(id, 0)})
	figs.sort_custom(func(a, b): return str(a["fichaId"]) < str(b["fichaId"]))
	var vencedor := "heroinas" if desfecho == "vitoria" else ("criaturas" if desfecho == "morte" else "nenhum")
	_escrever({"tipo": "resumo", "turnos": _ordem_vezes.size(), "rodadas": int(vista.get("rodada", 0)),
		"desfecho": desfecho, "vencedor": vencedor, "figuras": figs,
		"texto": "Semente %d: %s em %d turnos (%d rodadas)." % [_semente, "vencem as " + vencedor if vencedor != "nenhum" else "sem vencedor (" + desfecho + ")", _ordem_vezes.size(), int(vista.get("rodada", 0))]})
