extends SceneTree
## Corrida de PONTA A PONTA do ecrã do Mestre (I0004, 08/11/2026): o cliente Godot, sem janela, faz de
## Mestre pela ligação de verdade (WebSocket) contra o servidor Node (servidor/e2e/servidor-e2e.mjs),
## enquanto uma jogadora em Node (servidor/e2e/jogadora-e2e.mjs) ataca.
##
##   node servidor/e2e/servidor-e2e.mjs 8765 &
##   node servidor/e2e/jogadora-e2e.mjs 8765 &
##   godot --headless --path cliente -s res://testes/e2e_mestre.gd -- --servidor=127.0.0.1:8765
##
## Usa a cena do Mestre como ela é (comandos pela Rede, nada capturado) e só toca nos botões que o Mestre
## tocaria: lobby (procurar, marcar, «Guardar a mesa», «Começar a batalha» ×2) → colocar o orc ao lado da
## heroína → o cartão de desgraça do golpe dela → «Confirmar» → «Voltar até aqui» (escolher + confirmar).
## Código de saída 0 se tudo acontecer, 1 se não.

const CENA := "res://cenas/mestre/mestre.tscn"
const PIN := "90210777"  # o PIN fictício dos testes do servidor (testes/ajudantes.mjs)
const ESPERA_S := 30.0

var _rede: Node
var _estado: Node
var _total := 0
var _falhas := 0
var _eventos: Array = []
var _m  # a cena do Mestre


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		printerr("  FALHA ", nome)


## Espera até `cond` ser verdade (ou o tempo acabar). Conta como uma verificação.
func _esperar(cond: Callable, rotulo: String, segundos: float = ESPERA_S) -> bool:
	var t0 := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t0 > int(segundos * 1000.0):
			_ok(false, rotulo + " (tempo esgotado)")
			return false
		await process_frame
	_ok(true, "%s (%.1f s)" % [rotulo, (Time.get_ticks_msec() - t0) / 1000.0])
	return true


func _correr() -> void:
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	_rede.persistir = false
	_rede.evento_recebido.connect(func(msg): _eventos.append(str(msg.get("tipo", ""))))
	print("== ligar como Mestre a ", _rede.url_servidor(), " ==")
	_rede.entrar_mestre(PIN)
	if not (await _esperar(func(): return _rede.na_mesa() and not _rede.ultima_vista_mestre.is_empty(),
			"entrou como Mestre e recebeu a MASTER_VIEW")):
		_fim()
		return
	_m = (load(CENA) as PackedScene).instantiate()
	root.add_child(_m)
	if not (await _esperar(func(): return str(_m.vista.get("fase", "")) == "lobby", "o ecrã do Mestre abriu no lobby")):
		_fim()
		return
	var mesa = _m._aba_mesa

	print("== lobby ==")
	mesa.procurar()
	if not (await _esperar(func(): return mesa._resultados.has("orc-teste"), "a pesquisa trouxe o orc (MASTER_RESULTS)")):
		_fim()
		return
	mesa.marcar(true, "orc-teste")
	mesa.guardar()
	if not (await _esperar(func(): return _lobby_tem("orc-teste"), "«Guardar a mesa» chegou ao servidor (o orc está na mesa)")):
		_fim()
		return
	mesa.comecar()
	mesa.comecar()
	if not (await _esperar(func(): return str(_m.vista.get("fase", "")) == "combate", "«Começar a batalha» ×2 → combate")):
		_fim()
		return

	print("== colocar ==")
	mesa.escolher_colocar("orc-teste")
	_m.casa_tocada(Vector2i(2, 3))
	if not (await _esperar(func(): return _m._arena.figuras_desenhadas() == 2, "o orc colocado ao lado dela aparece na arena 3D")):
		_fim()
		return
	mesa.parar()

	print("== o cartão do golpe dela ==")
	if not (await _esperar(func(): return str(_m.cartao.get("tipo", "")) == "desgraca", "chegou o cartão de desgraça (a jogadora atacou)")):
		_fim()
		return
	_ok(_m._texto_cartao.text.contains("A Party vai ler: «Falha crítica · "), "o cartão mostra a frase que a Party vai ler")
	_m.tocar("confirmar")
	if not (await _esperar(func(): return _m.cartao.is_empty() and _eventos.has("cartao_fechado"), "«Confirmar» fechou o cartão no servidor")):
		_fim()
		return

	print("== voltar até aqui ==")
	if not (await _esperar(func(): return _m.vista.get("pontos", []).size() >= 2, "a vista traz pontos de «voltar» (L8)")):
		_fim()
		return
	var alvo := int(_m.vista["pontos"][1]["journalSeq"])
	_m._aba_registo.escolher(alvo)
	_ok(not _eventos.has("revertido"), "escolher o ponto ainda não voltou")
	# A vista de antes do «voltar»: a de depois pode chegar logo a seguir ao evento (sem corrida de leitura).
	var seq_voltar := int(_m.vista.get("journalSeq", 0))
	_m._aba_registo.confirmar()
	await _esperar(func(): return _eventos.has("revertido"), "«Voltar até aqui» → o servidor voltou (evento revertido)")

	print("== terminar e recomeçar (N4) ==")
	var vista_nova := func(): return int(_m.vista.get("journalSeq", 0)) != seq_voltar and _m._espera_vista < 0.0
	await _esperar(vista_nova, "a vista depois do «voltar» chegou")
	print("  fase=", _m.vista.get("fase"), " revisao=", _estado.revisao, " alertas=", _m.alertas)
	_m.pedir_terminar()
	_m.pedir_terminar()
	if not (await _esperar(func(): return str(_m.vista.get("fase", "")) == "fim" and _eventos.has("fim"), "«Terminar batalha» → a batalha acabou")):
		print("  fase=", _m.vista.get("fase"), " revisao=", _estado.revisao, " alertas=", _m.alertas, " eventos=", _eventos.slice(-8))
		_fim()
		return
	_m.pedir_recomecar()
	_m.pedir_recomecar()
	var recomecou := func(): return str(_m.vista.get("fase", "")) == "combate" and int(_m.vista.get("rodada", 0)) == 1 and _eventos.has("recomeco")
	await _esperar(recomecou, "«Recomeçar» → a mesma batalha do zero (combate, rodada 1)")

	var recusas: Array = _m.alertas.filter(func(t): return str(t).begins_with("O servidor não aceitou"))
	_ok(recusas.is_empty(), "nenhum comando do Mestre foi recusado %s" % [recusas])
	_fim()


func _lobby_tem(ficha: String) -> bool:
	var m = _m.vista.get("mestre")
	if not (m is Dictionary) or not (m.get("lobby") is Dictionary):
		return false
	return ficha in m["lobby"].get("criaturasDisponiveis", [])


func _fim() -> void:
	print("")
	print("ponta a ponta: %d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)
