extends SceneTree
## ORDEM PROVAS-MAPA (prova 2): a JOGADORA da batalha de bancada — o cliente Godot de verdade (a arena do jogo,
## arena.tscn, sem janela) ligado pela WebSocket ao servidor Node (bancada-servidor.mjs), com a GRELHA-MAPA e a
## escala a mudar a meio (o Mestre, bancada-mestre.mjs: 1,5 → 1 → 2 m). Ferramenta de prova, fora de cliente/; o
## código do jogo não muda. Só fichas fictícias.
##
##   godot --headless --path cliente -s <caminho>/bancada_jogadora_mapa.gd -- --servidor=127.0.0.1:8791 --json=<rel>
##
## Em cada escala (depois de a arena refazer a grelha):
##   (1) a grelha da arena = a grelha-mapa dessa escala (50 / 75 / 37 casas, canto NO −37,5 / −37,5 / −37 m);
##   (2) as figuras ficam no MESMO SÍTIO DO MAPA: o nó desenhado de cada figura está a ≤ meia casa nova (em x e em z)
##       de onde estava antes da mudança, e a casa nova é a que contém o ponto de antes; o orc continua NO LAGO;
##   (3) o CAMINHO: as casas de mover que o servidor oferece = um BFS de 4 vizinhos refeito AQUI com o terreno do
##       CLIENTE (a grelha do mapa da arena; a água pisa-se) e as figuras a bloquear, até floor(reserva / casaM) casas,
##       com custo = passos × casaM; a reserva (orcamentoM) = 9 m − o que já andou (em metros, de escala para escala);
##   (4) o ALCANCE: o orc está nos ataques ⇔ o caminho das casas até ele ≤ max(1, 9 m / casaM) (o chicote da ficha
##       fictícia, 9 m — sala.js aoAlcance);
##   (5) um passo (1,5 m: uma casa para o lago; 1 m: idem; 2 m: entra no lago) — APLICADA, a figura desenhada fica no
##       pé da casa nova e a reserva desce o custo;
## e no fim (6) a SONDA DE PRIVACIDADE: todas as mensagens que chegaram a esta jogadora, varridas por números do orc,
##       textos e chaves só do Mestre; nenhuma mensagem de Mestre (mestre_recebido).
## ORDEM-F2 — as provocações e o varrimento dos textos (registadas à parte, em `provocacoes` e `sondaTextos`, para os
## números da batalha continuarem comparáveis com a primeira corrida, comparar-corridas.mjs da CORR9):
##   (7) na vez dela a 2 m, antes do passo, a jogadora PEDE UMA ESCALA (um MASTER_SUPERVISOR montado à mão e mandado
##       cru pela WebSocket — a Rede não o deixa sair de um lugar de jogadora): tem de receber só o ERRO `proibido`
##       «Só o Mestre.», e nada mais muda (linha 4 do contrato, §2f da CORR8);
##   (8) no fim, espera o ROOM_PAUSED (o Mestre sai depois da escala recusada dele, a linha 3);
##   (9) a SONDA varre também os TEXTOS que a Rede não põe nos sinais de mensagem: o texto das recusas
##       (recusa_recebida), o dos ERRO (erro_recebido) e o motivo do ROOM_PAUSED (sala_pausada).
##   A sonda do fio (sonda-fio.mjs, no servidor) varre o fio inteiro e confere os mesmos lotes do lado do servidor.
## ORDEM-F3 — as posições que se gravam (o «antes» depois do passo e o nó de cada fase) só se lêem com os nós QUIETOS:
##   a arena leva a figura ao pé da casa com um tween de 0,25 s (arena.gd `_atualizar_figura`), e o «assente» aceita-a
##   a ≤ 1e-3 m do pé — ainda a deslizar, se um frame cai no último quarto de milissegundo do tween. Depois do
##   «assente» (e da «pronta»), espera-se que a posição de cada nó fique igual em QUIETO_FRAMES leituras seguidas
##   (`_esperar_quietos`); só então se lê. Não é uma verificação nova (os números da batalha continuam comparáveis com
##   a primeira corrida); o registo vai para `quietos`. Se os nós não sossegam em 10 s, é uma FALHA.
## Sai com 0 se tudo passa, 1 se não.

const CENA := "res://cenas/arena/arena.tscn"
const CampoDaMesa := preload("res://cenas/arena/campo_da_mesa.gd")
const Assentamento := preload("res://cenas/arena/assentamento.gd")
const SENHA := "CANARIO-SENHA-H"  # a senha fictícia da heroína (servidor/testes/ajudantes.mjs)
const DESLOCAMENTO_M := 9.0      # heroina-teste.deslocamentoBase (dados-exemplo/fichas-ficticias.json)
const ALCANCE_M := 9.0           # chicote-teste.alcanceM (idem)
const FASES := [[1.5, 50, -37.5], [1.0, 75, -37.5], [2.0, 37, -37.0]]
const ESPERA_S := 60.0
const QUIETO_FRAMES := 3  # ORDEM-F3: leituras seguidas iguais (cada frame avança o tween, por isso um nó a deslizar muda)

var _falhas := 0
var _total := 0
var _msgs: Array = []
var _mestre_msgs := 0
var _recibos := {}
var _arena: Node = null
var _rel := {"fases": [], "verificacoes": [], "provocacoes": [], "quietos": []}
var _textos: Array = []  # ORDEM-F2: recusas, ERRO e ROOM_PAUSED como chegaram pelos sinais da Rede
var _erros: Array = []
var _pausada := false


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


## `lista`: "verificacoes" (a batalha) ou "provocacoes" (ORDEM-F2). As duas contam para a saída.
func _ok(cond: bool, texto: String, lista: String = "verificacoes") -> void:
	_total += 1
	if not cond:
		_falhas += 1
	_rel[lista].append({"ok": cond, "texto": texto})
	print(("  ok    " if cond else "  FALHA ") + texto)


func _esperar(cond: Callable, rotulo: String, segundos: float = ESPERA_S, lista: String = "verificacoes") -> bool:
	var t0 := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t0 > int(segundos * 1000.0):
			_ok(false, rotulo + " (tempo esgotado)", lista)
			return false
		await process_frame
	_ok(true, "%s (%.1f s)" % [rotulo, (Time.get_ticks_msec() - t0) / 1000.0], lista)
	return true


## ORDEM-F3: espera que os nós `ids` fiquem quietos — a mesma posição (exacta) em QUIETO_FRAMES frames seguidos.
## Regista em `quietos` o resto de cada nó ao pé da casa no momento em que se começou a esperar (o que o «assente» ou a
## «pronta» aceitaram) e quantos frames foi preciso esperar. Não conta como verificação, salvo se esgota o tempo.
func _esperar_quietos(ids: Array, alvos: Dictionary, rotulo: String, segundos: float = 10.0) -> bool:
	var t0 := Time.get_ticks_msec()
	var resto := {}
	for id in ids:
		resto[id] = var_to_str((_arena._nos[id] as Node3D).position - _arena.pe_figura(alvos[id]))
	var ultima := {}
	var iguais := 0
	var frames := 0
	while true:
		var agora := {}
		var mesmas := not ultima.is_empty()
		for id in ids:
			var no: Node3D = _arena._nos.get(id)
			if no == null:
				mesmas = false
				continue
			agora[id] = no.position
			if mesmas and (not ultima.has(id) or ultima[id] != no.position):
				mesmas = false
		iguais = iguais + 1 if mesmas else 0
		if iguais >= QUIETO_FRAMES - 1:
			break
		if Time.get_ticks_msec() - t0 > int(segundos * 1000.0):
			_ok(false, rotulo + ": os nós não ficaram quietos (tempo esgotado)")
			_rel["quietos"].append({"onde": rotulo, "resto": resto, "frames": frames, "quietos": false})
			return false
		ultima = agora
		await process_frame
		frames += 1
	_rel["quietos"].append({"onde": rotulo, "resto": resto, "frames": frames, "quietos": true})
	return true


func _correr() -> void:
	var rede = root.get_node("Rede")
	var est = root.get_node("Estado")
	rede.persistir = false
	rede.snapshot_recebido.connect(func(m): _msgs.append(m))
	rede.evento_recebido.connect(func(m): _msgs.append(m))
	rede.opcoes_recebidas.connect(func(m): _msgs.append(m))
	rede.boas_vindas_recebidas.connect(func(m): _msgs.append(m))
	rede.mestre_recebido.connect(func(m): _mestre_msgs += 1; _msgs.append(m))
	rede.recibo_recebido.connect(func(id, e, m): _recibos[id] = e; _msgs.append(m))
	rede.recusa_recebida.connect(func(id, mot, tx):
		_recibos[id] = "RECUSADA " + mot + " " + tx
		_textos.append({"type": "ROOM_REJECT", "intentId": id, "motivo": mot, "texto": tx}))
	rede.erro_recebido.connect(func(cod, tx):
		_erros.append([cod, tx])
		_textos.append({"type": "ERRO", "codigo": cod, "texto": tx}))
	rede.sala_pausada.connect(func(mot):
		_pausada = true
		_textos.append({"type": "ROOM_PAUSED", "motivo": mot}))
	print("== a jogadora liga-se a ", rede.url_servidor(), " ==")
	rede.entrar("Heroína Teste", SENHA)
	if not await _esperar(func(): return rede.na_mesa() and est.tem_snapshot and est.minha_figura_id != "", "a heroína entrou e recebeu o snapshot"):
		_fim()
		return
	_ok(int(est.mapa.get("largura", 0)) == 50 and int(est.mapa.get("altura", 0)) == 50 and is_equal_approx(float(est.mapa.get("casaM", 0)), 1.5),
		"a sala nasce com a grelha-mapa: a jogadora recebe %s" % [est.mapa])
	print("na-mesa-bancada")  # o guião arranca o Mestre ao ver esta linha
	_arena = (load(CENA) as PackedScene).instantiate()
	root.add_child(_arena)

	var eu: String = est.minha_figura_id
	var andou_m := 0.0
	var antes := {}  # figuraId -> Vector2 (x, z) do nó desenhado antes da mudança
	for fi in FASES.size():
		var cm: float = FASES[fi][0]
		var lado: int = FASES[fi][1]
		var o0: float = FASES[fi][2]
		print("== escala %s m (grelha-mapa %d × %d) ==" % [cm, lado, lado])
		var fase := {"casaM": cm, "lado": lado}
		var pronta := func() -> bool:
			if not (is_equal_approx(float(est.mapa.get("casaM", 0)), cm) and _arena.largura == lado and is_equal_approx(_arena.casa_m, cm)):
				return false
			if not est.e_minha_vez() or est.lista_opcao("mover").is_empty():
				return false
			if est.figuras.size() < 2 or _arena._nos.size() < 2:
				return false
			for id in est.figuras:
				var no: Node3D = _arena._nos.get(id)
				if no == null or no.position.distance_to(_arena.pe_figura(est.casa_de(est.figuras[id]))) > 1e-3:
					return false
			return true
		if not await _esperar(pronta, "%s m: a arena refez a grelha (%d × %d), as figuras assentes e as opções da vez dela" % [cm, lado, lado], 90.0):
			_fim()
			return
		for i in 10:
			await process_frame
		var casas_agora := {}
		for id in est.figuras:
			casas_agora[id] = est.casa_de(est.figuras[id])
		if not await _esperar_quietos(est.figuras.keys(), casas_agora, "%s m: pronta" % cm):
			_fim()
			return
		var orc := ""
		for id in est.figuras:
			if id != eu:
				orc = id
		# (1) a grelha
		_ok(_arena.altura == lado and is_equal_approx(_arena.origem.x, o0) and is_equal_approx(_arena.origem.y, o0),
			"%s m: a grelha da arena é a grelha-mapa — %d × %d, canto NO (%s, %s) m" % [cm, _arena.largura, _arena.altura, _arena.origem.x, _arena.origem.y])
		# (2) o mesmo sítio do mapa
		var figs := {}
		for id in est.figuras:
			var c: Vector2i = est.casa_de(est.figuras[id])
			var no: Node3D = _arena._nos[id]
			var p := Vector2(no.position.x, no.position.z)
			var agua: bool = CampoDaMesa.casa_de_agua(_arena.mapa, _arena.origem, cm, c)
			figs[id] = {"quem": "heroína" if id == eu else "orc", "casa": [c.x, c.y], "noXZ": [p.x, p.y], "agua": agua}
			if antes.has(id):
				var a: Vector2 = antes[id]
				var d := p - a
				var esperada := Vector2i(clampi(floori((a.x - o0) / cm + 1e-9), 0, lado - 1), clampi(floori((a.y - o0) / cm + 1e-9), 0, lado - 1))
				figs[id]["antesXZ"] = [a.x, a.y]
				figs[id]["desvioXZ"] = [d.x, d.y]
				_ok(absf(d.x) <= cm / 2.0 + 1e-6 and absf(d.y) <= cm / 2.0 + 1e-6 and c == esperada,
					"%s m: %s fica no mesmo sítio do mapa — (%.2f, %.2f) → (%.2f, %.2f) m, desvio (%.2f, %.2f) ≤ meia casa %.2f; casa %s (esperada %s)" % [
						cm, figs[id]["quem"], a.x, a.y, p.x, p.y, d.x, d.y, cm / 2.0, c, esperada])
			_ok(no.position.distance_to(_arena.pe_figura(c)) <= 1e-4, "%s m: %s desenhada no pé da casa %s" % [cm, figs[id]["quem"], c])
		_ok(bool(figs[orc]["agua"]), "%s m: o orc está numa casa de água (no lago) — %s" % [cm, figs[orc]["casa"]])
		fase["figuras"] = figs
		# (3) o caminho
		var minha: Vector2i = est.casa_de(est.figuras[eu])
		var c_orc: Vector2i = est.casa_de(est.figuras[orc])
		var reserva: float = est.orcamento_m()
		_ok(absf(reserva - (DESLOCAMENTO_M - andou_m)) < 0.006, "%s m: a reserva em metros continua — %s m (9 − %s andados)" % [cm, reserva, andou_m])
		var max_casas := floori(reserva / cm + 1e-9)
		var bfs := _bfs(minha, {c_orc: true}, max_casas, lado)
		var esperado := {}
		for k in bfs:
			if k != minha and k != c_orc:
				esperado[k] = snappedf(int(bfs[k]) * cm, 0.01)
		var servidor := {}
		for op in est.lista_opcao("mover"):
			servidor[Vector2i(int(op["x"]), int(op["y"]))] = float(op["custoM"])
		var so_srv := 0
		var so_cli := 0
		var custo_dif := 0
		for k in servidor:
			if not esperado.has(k):
				so_srv += 1
			elif absf(float(esperado[k]) - float(servidor[k])) > 0.006:
				custo_dif += 1
		for k in esperado:
			if not servidor.has(k):
				so_cli += 1
		var de_agua := 0
		for k in servidor:
			if CampoDaMesa.casa_de_agua(_arena.mapa, _arena.origem, cm, k):
				de_agua += 1
		_ok(so_srv == 0 and so_cli == 0 and custo_dif == 0,
			"%s m: caminho — o servidor oferece %d casas (%d de água), o BFS do cliente (terreno da arena, %d casas de alcance) dá %d; só no servidor %d, só no cliente %d, custo diferente %d" % [
				cm, servidor.size(), de_agua, max_casas, esperado.size(), so_srv, so_cli, custo_dif])
		# (4) o alcance
		var passos := _distancia(minha, c_orc, lado)
		var alcance_casas := maxf(1.0, ALCANCE_M / cm)
		var ao_alcance := passos <= alcance_casas + 1e-9
		var nos_ataques := false
		for a in est.lista_opcao("ataques"):
			if String(a.get("alvoId", "")) == orc:
				nos_ataques = true
		_ok(nos_ataques == ao_alcance, "%s m: alcance — o orc a %d passos, chicote 9 m = %.2f casas: %s; nos ataques do servidor: %s" % [
			cm, passos, alcance_casas, "ao alcance" if ao_alcance else "fora", nos_ataques])
		fase["caminho"] = {"reservaM": reserva, "maxCasas": max_casas, "servidor": servidor.size(), "cliente": esperado.size(), "deAgua": de_agua,
			"soServidor": so_srv, "soCliente": so_cli, "custoDiferente": custo_dif}
		fase["alcance"] = {"passos": passos, "alcanceCasas": alcance_casas, "aoAlcance": ao_alcance, "nosAtaques": nos_ataques}
		# (5) um passo
		var alvo := Vector2i(-1, -1)
		var melhor := INF
		for k in servidor:
			var agua_k: bool = CampoDaMesa.casa_de_agua(_arena.mapa, _arena.origem, cm, k)
			var nota: float
			if fi == FASES.size() - 1:
				nota = float(servidor[k]) + (0.0 if agua_k else 1000.0)  # a 2 m: a casa de água mais barata
			else:
				nota = INF if absf(float(servidor[k]) - cm) > 0.006 else float(absi(k.x - c_orc.x) + absi(k.y - c_orc.y))  # 1 casa, para o lago
			if nota < melhor or (nota == melhor and (k.y < alvo.y or (k.y == alvo.y and k.x < alvo.x))):
				melhor = nota
				alvo = k
		var custo: float = servidor[alvo]
		if fi == FASES.size() - 1:
			await _pedir_escala(rede, est)
		var id_int: String = ""
		if _arena.enviar_acao({"tipo": "mover", "destino": {"x": alvo.x, "y": alvo.y}}):
			id_int = _arena._ultimo_id
		_ok(id_int != "", "%s m: a heroína pede o passo para %s (custo %s m%s)" % [cm, alvo, custo, ", casa de água" if CampoDaMesa.casa_de_agua(_arena.mapa, _arena.origem, cm, alvo) else ""])
		if id_int == "" or not await _esperar(func(): return _recibos.has(id_int), "%s m: o recibo do passo chegou" % cm):
			_fim()
			return
		_ok(_recibos[id_int] == "APLICADA", "%s m: o passo foi %s" % [cm, _recibos[id_int]])
		andou_m += custo
		var assente := func() -> bool:
			var no: Node3D = _arena._nos.get(eu)
			return est.casa_de(est.figuras[eu]) == alvo and no != null and no.position.distance_to(_arena.pe_figura(alvo)) <= 1e-3
		await _esperar(assente, "%s m: a heroína desenhada no pé da casa %s" % [cm, alvo], 10.0)
		# ORDEM-F3: o «antes» só se lê com a heroína quieta (o «assente» aceita-a a ≤ 1e-3 m, ainda no fim do tween)
		var casas_passo := {}
		for id in est.figuras:
			casas_passo[id] = est.casa_de(est.figuras[id])
		if not await _esperar_quietos(est.figuras.keys(), casas_passo, "%s m: depois do passo" % cm):
			_fim()
			return
		fase["passo"] = {"para": [alvo.x, alvo.y], "custoM": custo, "recibo": _recibos[id_int],
			"agua": CampoDaMesa.casa_de_agua(_arena.mapa, _arena.origem, cm, alvo)}
		for id in est.figuras:
			var no: Node3D = _arena._nos[id]
			antes[id] = Vector2(no.position.x, no.position.z)
		_rel["fases"].append(fase)
	# a reserva final, depois do passo a 2 m
	await _esperar(func(): return est.orcamento_m() >= 0.0 and absf(est.orcamento_m() - (DESLOCAMENTO_M - andou_m)) < 0.006,
		"a reserva no fim: 9 − %s = %s m" % [andou_m, DESLOCAMENTO_M - andou_m], 10.0)
	# (8) ORDEM-F2: o Mestre provoca a escala recusada (3 m) e sai; a jogadora tem de ver a sala pausada
	await _esperar(func(): return _pausada, "F2 (8): o ROOM_PAUSED chegou (o Mestre saiu depois da escala recusada)", 60.0, "provocacoes")
	_fim()


## (7) ORDEM-F2: a jogadora pede uma escala (só o Mestre pode). Linha 4 do contrato: recebe só o ERRO proibido.
func _pedir_escala(rede: Node, est: Node) -> void:
	var n_msgs := _msgs.size()
	var n_textos := _textos.size()
	var n_erros := _erros.size()
	var msg: Dictionary = rede.montar_comando_mestre("MASTER_SUPERVISOR", {"op": "escala", "casaM": 1.0}, est.revisao, "f2-jogadora-pede-escala")
	var saiu: bool = rede._enviar_dict(msg)
	_ok(saiu, "F2 (7): a jogadora manda um MASTER_SUPERVISOR escala 1 m (cru, pela WebSocket)", "provocacoes")
	if not saiu:
		return
	if not await _esperar(func(): return _erros.size() > n_erros, "F2 (7): a resposta ao pedido da escala chegou", 10.0, "provocacoes"):
		return
	for i in 20:
		await process_frame  # o que viesse junto com o ERRO chegava aqui
	var e: Array = _erros[n_erros]
	_ok(e[0] == "proibido" and e[1] == "Só o Mestre." and _erros.size() == n_erros + 1 and _textos.size() == n_textos + 1 and _msgs.size() == n_msgs
		and is_equal_approx(float(est.mapa.get("casaM", 0)), 2.0),
		"F2 (7): só o ERRO %s «%s» (%d ERRO, %d textos, %d mensagens novas); a escala continua %s m" % [
			e[0], e[1], _erros.size() - n_erros, _textos.size() - n_textos, _msgs.size() - n_msgs, est.mapa.get("casaM")], "provocacoes")
	_rel["pedidoEscala"] = {"erro": e, "mensagensNovas": _msgs.size() - n_msgs}


## BFS de 4 vizinhos (sala.js bfs): dentro da grelha, casas que o CLIENTE desenha como pisáveis (a água pisa-se), as
## `bloqueia` não se atravessam. Devolve casa -> passos (até `max_casas`).
func _bfs(de: Vector2i, bloqueia: Dictionary, max_casas: int, lado: int) -> Dictionary:
	var dist := {de: 0}
	var fila: Array[Vector2i] = [de]
	var i := 0
	while i < fila.size():
		var c: Vector2i = fila[i]
		i += 1
		if int(dist[c]) >= max_casas:
			continue
		for v in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + v
			if dist.has(n) or bloqueia.has(n) or not _pisavel(n, lado):
				continue
			dist[n] = int(dist[c]) + 1
			fila.append(n)
	return dist


func _pisavel(c: Vector2i, lado: int) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= lado or c.y >= lado:
		return false
	var g = _arena.mapa.grelha
	var cm := Assentamento.casa_do_mapa(_arena.origem, _arena.casa_m, c)
	return not g.bloqueada(cm) or CampoDaMesa.MOTIVOS_DE_AGUA.has(g.motivo_bloqueio(cm))


## sala.js distanciaCasas: passos pelo caminho das casas até ao alvo (o alvo conta como destino).
func _distancia(a: Vector2i, b: Vector2i, lado: int) -> int:
	var d := _bfs(a, {}, 100000, lado)
	return int(d.get(b, 1 << 30))


## A SONDA DE PRIVACIDADE no que chegou à jogadora.
func _sonda() -> void:
	var numeros := [7777.0, 313.0, 9137.0]  # orc-teste: vidaTotal, paTotal, ca
	var textos := ["ESCALA_", "CANARIO-FANTASMA", "CANARIO-DESGRACA", "CANARIO-SENHA", "Orc Verdadeiro", "90210777"]
	var chaves := ["casaMAntes", "grelhaAntes", "casasQuePaga", "soMestre"]
	var achados: Array = []
	for i in _msgs.size():
		_varrer(_msgs[i], "", i, numeros, textos, chaves, achados)
	var mapas := {}
	for m in _msgs:
		if m is Dictionary and m.get("type") == "ROOM_SNAPSHOT" and m.get("mapa") is Dictionary:
			mapas[JSON.stringify(m["mapa"])] = true
	_rel["sonda"] = {"mensagens": _msgs.size(), "mensagensDeMestre": _mestre_msgs, "achados": achados.slice(0, 20), "nAchados": achados.size(),
		"mapasVistos": mapas.keys(), "canarios": {"numeros": numeros, "textos": textos, "chaves": chaves}}
	_ok(achados.is_empty() and _mestre_msgs == 0, "privacidade: %d mensagens à jogadora, %d achados, %d mensagens de Mestre; mapas vistos %s" % [
		_msgs.size(), achados.size(), _mestre_msgs, ", ".join(mapas.keys())])
	# (9) ORDEM-F2: os textos das recusas, dos ERRO e do ROOM_PAUSED, com os mesmos canários
	var achados_t: Array = []
	for i in _textos.size():
		_varrer(_textos[i], "", i, numeros, textos, chaves, achados_t)
	var tipos := {}
	for t in _textos:
		tipos[t["type"]] = int(tipos.get(t["type"], 0)) + 1
	_rel["sondaTextos"] = {"textos": _textos, "porType": tipos, "achados": achados_t}
	_ok(achados_t.is_empty() and tipos.has("ERRO") and tipos.has("ROOM_PAUSED"),
		"F2 (9): privacidade nos textos — %d (%s), %d achados" % [_textos.size(), JSON.stringify(tipos), achados_t.size()], "provocacoes")


func _varrer(v, chave: String, i: int, numeros: Array, textos: Array, chaves: Array, achados: Array) -> void:
	if v is Dictionary:
		for k in v:
			if chaves.has(String(k)):
				achados.append({"msg": i, "chave": k, "porque": "chave só do Mestre"})
			_varrer(v[k], String(k), i, numeros, textos, chaves, achados)
	elif v is Array:
		for x in v:
			_varrer(x, chave, i, numeros, textos, chaves, achados)
	elif v is float or v is int:
		if numeros.has(float(v)):
			achados.append({"msg": i, "chave": chave, "valor": v})
	elif v is String:
		for t in textos:
			if (v as String).contains(t):
				achados.append({"msg": i, "chave": chave, "texto": t})


func _fim() -> void:
	_sonda()
	print("")
	print("bancada da jogadora: %d de %d verificações passaram." % [_total - _falhas, _total])
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--json="):
			var f := FileAccess.open(a.trim_prefix("--json="), FileAccess.WRITE)
			f.store_string(JSON.stringify(_rel, " ", false, true))
			f.close()
	quit(1 if _falhas > 0 else 0)
