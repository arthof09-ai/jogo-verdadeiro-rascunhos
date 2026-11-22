extends SceneTree
## Prova da Ordem CAIXA-PERSISTENTE — o CLIENTE do Mestre (o ecrã a sério, cenas/mestre/mestre.tscn, pela Rede do jogo)
## sai e volta a entrar A MEIO de uma batalha de BANCADA e reconstrói a caixa da ordem de turnos com a escolha que
## tinha feito (guardada no servidor: estado.caixaMestre → MASTER_VIEW caixaMestre).
##
##   node provas/ordem-caixa/ferramentas/servidor-bancada-prova.mjs --porta=8791 --semente=7 --info=<f> --motor=<vlab>
##   xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 \
##     --path rascunhos/cliente -s <esta ferramenta> -- --servidor=127.0.0.1:8791 --saida=<pasta> --pin=<PIN da corrida>
##
## Passos (as jogadas da bancada vão por lugares próprios, como no autojogo; o Mestre que sai e entra é o ecrã a sério):
##   0. o Mestre da bancada põe as criaturas e começa; a IA de bancada joga as primeiras vezes (a ordem dinâmica forma-se
##      no servidor); o Mestre da bancada sai.
##   1. o Mestre entra pelo ecrã a sério: a caixa vem como o servidor a guarda (por omissão: ligada, dinâmico).
##   2. carrega em «Modo iniciativa»; o servidor aceita (MASTER_SUPERVISOR op 'caixa').
##   3. SAI (Rede.sair: o lugar esquecido no aparelho, o ecrã fechado) e VOLTA A ENTRAR com o PIN: a caixa reconstrói-se
##      no modo iniciativa, com a mesma ordem dinâmica.
##   4. desliga a caixa (aba Sala), sai e volta a entrar: a caixa vem desligada (não aparece).
##   5. volta a ligá-la e repõe o modo dinâmico (a sala fica como estava).
## Deixa em <pasta>: 1-entrou.png, 2-iniciativa.png, 3-reentrou-iniciativa.png, 4-reentrou-desligada.png,
## 5-religada.png e relato.txt. Código de saída 0 se todas as verificações passam.

const CENA := "res://cenas/mestre/mestre.tscn"
const IA := preload("res://autojogo/ia_bancada.gd")
const Lugar := preload("res://autojogo/lugar_bancada.gd")
const VEZES_A_JOGAR := 3

var _args := {}
var _saida := ""
var _url := ""
var _pin := ""  # B7-CORRECOES-6 (B1): sem literal — o PIN da corrida vem por --pin= (o lançador gera-o)
var _total := 0
var _falhas := 0
var _relato: PackedStringArray = []
var _rede: Node
var _estado: Node
var _m = null
var _mestre_b  # Lugar do Mestre da bancada (só para montar a batalha)
var _herois := {}  # figuraId → Lugar
var _a_entrar = null  # Lugar de uma heroína que ainda está a entrar (também se sonda)


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _linha(t: String) -> void:
	print(t)
	_relato.append(t)
	# o relato escreve-se linha a linha: uma corrida cortada a meio deixa o que já provou
	if _saida != "":
		var f := FileAccess.open(_saida.path_join("relato.txt"), FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(_relato) + "\n")
			f.close()


func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		_linha("  ok    " + nome)
	else:
		_falhas += 1
		_linha("  FALHA " + nome)
		printerr("  FALHA ", nome)


func _poll() -> void:
	if _mestre_b != null:
		_mestre_b.poll()
	for l in _herois.values():
		l.poll()
	if _a_entrar != null:
		_a_entrar.poll()


func _esperar(cond: Callable, segundos: float = 30.0) -> bool:
	var t := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t > int(segundos * 1000.0):
			return false
		await process_frame
		_poll()
	return true


func _quadros(n: int) -> void:
	for i in n:
		await process_frame
		_poll()


func _gravar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		_ok(false, nome + ": sem imagem (o render não correu)")
		return
	var erro := img.save_png(_saida.path_join(nome))
	_ok(erro == OK, "captura %s (%d×%d)" % [nome, img.get_width(), img.get_height()])


func _ler_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var i := a.find("=")
			if i < 0:
				_args[a.substr(2)] = true
			else:
				_args[a.substr(2, i - 2)] = a.substr(i + 1)


# ------------------------------------------------------------------ 0. a batalha de bancada a meio

func _vista_b() -> Dictionary:
	var alvo: int = _mestre_b.pedir_vista()
	if not await _esperar(func(): return _mestre_b.vistas_recebidas >= alvo, 10.0):
		return {}
	return _mestre_b.vista


func _comando_b(tipo: String, campos: Dictionary) -> bool:
	await _vista_b()
	var id: String = _mestre_b.comando(tipo, campos)
	if not await _esperar(func(): return _mestre_b.respostas.has(id), 10.0):
		return false
	return str(_mestre_b.respostas[id].get("estado", "")) == "APLICADA"


func _montar_batalha(cenario: Dictionary) -> bool:
	_mestre_b = Lugar.new("mestre-bancada", 7)
	_mestre_b.ligar(_url, {"v": 2, "type": "ROOM_JOIN", "papel": "mestre", "pin": _pin, "cliente": Lugar.VERSAO})
	if not await _esperar(func(): return _mestre_b.na_mesa and _mestre_b.vistas_recebidas > 0, 20.0):
		_ok(false, "o Mestre da bancada entrou")
		return false
	var fichas: Array = []
	for c in cenario["criaturas"]:
		if not fichas.has(c["fichaId"]):
			fichas.append(c["fichaId"])
	if not await _comando_b("MASTER_LOBBY_SET", {"mapaId": str(cenario.get("mapaId", "floresta")), "criaturasDisponiveis": fichas, "npcsDisponiveis": []}):
		_ok(false, "MASTER_LOBBY_SET aceite")
		return false
	for c in cenario["criaturas"]:
		if not await _comando_b("MASTER_PLACE", {"fichaId": c["fichaId"], "casa": c["casa"]}):
			_ok(false, "MASTER_PLACE %s aceite" % c["fichaId"])
			return false
	var i := 0
	for h in cenario["heroinas"]:
		i += 1
		var l = Lugar.new("heroina-%d" % i, 7)
		l.ligar(_url, {"v": 2, "type": "ROOM_JOIN", "papel": "jogadora", "nome": str(h["nome"]), "senha": str(h["senha"]), "cliente": Lugar.VERSAO})
		_a_entrar = l
		var entrou := await _esperar(func(): return l.na_mesa and l.figura_id != "", 20.0)
		_a_entrar = null
		if not entrou:
			_ok(false, "a heroína %d entrou" % i)
			return false
		_herois[l.figura_id] = l
	if not await _comando_b("MASTER_START", {}):
		_ok(false, "MASTER_START aceite")
		return false
	# a IA de bancada joga as primeiras vezes (sem cartões: param-se as jogadas se algum abrir)
	var vezes_vistas: Array = []
	var accoes := 0
	while vezes_vistas.size() <= VEZES_A_JOGAR and accoes < 20:
		var v := await _vista_b()
		var mv: Dictionary = v.get("mestre", {})
		if mv.get("cartoes") is Array and not (mv["cartoes"] as Array).is_empty():
			break
		var vez_id := str(v.get("vezId", "")) if v.get("vezId") is String else ""
		if vez_id == "" or str(v.get("fase", "")) != "combate":
			break
		if not vezes_vistas.has(vez_id):
			vezes_vistas.append(vez_id)
			if vezes_vistas.size() > VEZES_A_JOGAR:
				break
		var figuras: Array = mv.get("figuras", [])
		var quem: Dictionary = {}
		for f in figuras:
			if str(f.get("id", "")) == vez_id:
				quem = f
		var lugar = _herois.get(vez_id, _mestre_b)
		var pronto := func(): return str(lugar.opcoes.get("vezId", "")) == vez_id and int(lugar.opcoes.get("revision", -1)) == lugar.revision
		await _esperar(pronto, 5.0)
		var d := IA.decidir(quem, figuras, lugar.opcoes, {"andou": false, "atacou": false, "accoes": 0})
		var acao: Dictionary = d["acao"]
		# uma jogada de movimento por vez e depois encerra (o bastante para a ordem dinâmica se formar)
		var id := ""
		for passo in [acao, {"tipo": "encerrar"}]:
			if lugar.papel == "mestre":
				id = lugar.comando("MASTER_ACT", {"figuraId": vez_id, "acao": passo})
			else:
				id = lugar.intencao(passo)
			await _esperar(func(): return lugar.respostas.has(id), 10.0)
			accoes += 1
			_linha("  bancada: %s → %s (%s)" % [str(quem.get("nome", vez_id)), JSON.stringify(passo), str(lugar.respostas.get(id, {}).get("estado", lugar.respostas.get(id, {}).get("motivo", "?")))])
			if passo.get("tipo") == "encerrar":
				break
			await _vista_b()
			await _esperar(func(): return int(lugar.opcoes.get("revision", -1)) == lugar.revision, 5.0)
	var fim := await _vista_b()
	var od = fim.get("ordemDinamica", {})
	_linha("  a batalha a meio: fase %s, rodada %s, vez de %s, ordem dinâmica %s" % [fim.get("fase"), fim.get("rodada"), fim.get("vezId"), JSON.stringify(od.get("ordem", []) if od is Dictionary else [])])
	_ok(str(fim.get("fase", "")) == "combate" and od is Dictionary and (od.get("ordem", []) as Array).size() >= 2,
		"batalha de bancada a meio: em combate e com a ordem dinâmica formada no servidor (≥ 2 figuras)")
	_mestre_b.fechar()
	await _quadros(10)
	_mestre_b = null
	return true


# ------------------------------------------------------------------ 1–5. o Mestre a sério entra, escolhe, sai, volta

func _entrar_mestre(rotulo: String) -> bool:
	_rede.entrar_mestre(_pin)
	if not await _esperar(func(): return _rede.na_mesa() and not _rede.ultima_vista_mestre.is_empty(), 30.0):
		_ok(false, rotulo + ": entrou como Mestre e recebeu a MASTER_VIEW")
		return false
	_m = (load(CENA) as PackedScene).instantiate()
	root.add_child(_m)
	# A sala pausa-se sozinha quando o Mestre sai (ausência do Mestre): quem volta encontra-a em combate ou em pausa —
	# as duas são «a meio da batalha» e a caixa aparece nas duas.
	var a_meio := func(): return str(_m.vista.get("fase", "")) in ["combate", "pausa"]
	var ok: bool = await _esperar(a_meio, 150.0)
	_ok(ok, rotulo + ": o ecrã do Mestre abriu a meio da batalha (fase %s, rodada %s)" % [_m.vista.get("fase"), _m.vista.get("rodada")])
	await _quadros(40)  # os retratos (SubViewport) desenham-se
	return ok


func _sair_mestre(rotulo: String) -> void:
	_m.queue_free()
	_m = null
	await _quadros(2)
	_rede.sair()
	await _quadros(20)
	_ok(not _rede.na_mesa(), rotulo + ": o Mestre saiu (lugar esquecido no aparelho, ecrã fechado)")


func _escolha_no_servidor_e(ligada: bool, modo: String) -> bool:
	var feito := func():
		var c = _rede.ultima_vista_mestre.get("caixaMestre")
		return c is Dictionary and c.get("ligada") == ligada and str(c.get("modo", "")) == modo and _m._caixa_cmd == ""
	return await _esperar(feito, 15.0)


func _caixa_e(ligada: bool, modo: String) -> String:
	return "caixa_ligada=%s modo=%s visível=%s (pedido: %s, %s)" % [_m.caixa_ligada, _m.ordem_turnos.modo, _m._caixa.visible, ligada, modo]


func _correr() -> void:
	_ler_args()
	_saida = str(_args.get("saida", ""))
	var srv := str(_args.get("servidor", ""))
	if _saida == "" or srv.find(":") < 0:
		printerr("uso: -- --servidor=127.0.0.1:PORTA --saida=<pasta>")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_saida)
	_url = "ws://%s/ws" % srv
	_pin = str(_args.get("pin", _pin))
	if _pin.length() < 6 or not _pin.lstrip("0123456789").is_empty():
		printerr("falta --pin=<PIN da corrida> (6 dígitos ou mais; o lançador gera-o — já não há PIN no repositório)")
		quit(2)
		return
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	_rede.persistir = false
	_rede.definir_servidor(srv)
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var cenario = JSON.parse_string(FileAccess.get_file_as_string(raiz.path_join("servidor/autojogo/cenario-bancada.json")))
	_linha("== Ordem CAIXA-PERSISTENTE — o Mestre sai e volta a entrar a meio de uma batalha de bancada ==")
	_linha("servidor %s · render %s" % [_url, RenderingServer.get_video_adapter_name()])

	_linha("== 0. batalha de bancada (IA de bancada, lugares próprios) ==")
	if not await _montar_batalha(cenario):
		_fim()
		return

	_linha("== 1. o Mestre entra pelo ecrã a sério ==")
	if not await _entrar_mestre("1"):
		_fim()
		return
	var ordem_antes = _rede.ultima_vista_mestre.get("ordemDinamica", {}).get("ordem", [])
	_ok(_m.caixa_ligada and _m.ordem_turnos.modo == "dinamico" and _m._caixa.visible,
		"1: a caixa vem como o servidor a guarda (omissão: ligada, dinâmico) — " + _caixa_e(true, "dinamico"))
	await _gravar("1-entrou.png")

	_linha("== 2. «Modo iniciativa» ==")
	_m.definir_modo_iniciativa(true)
	_ok(await _escolha_no_servidor_e(true, "iniciativa"), "2: o servidor guardou a escolha (MASTER_VIEW caixaMestre = ligada, iniciativa)")
	await _quadros(10)
	await _gravar("2-iniciativa.png")

	_linha("== 3. sai e volta a entrar ==")
	await _sair_mestre("3")
	if not await _entrar_mestre("3"):
		_fim()
		return
	_ok(_m.caixa_ligada and _m.ordem_turnos.modo == "iniciativa" and _m._caixa.visible and _m._caixa.modo == "iniciativa",
		"3: a caixa reconstruiu-se com a escolha anterior — " + _caixa_e(true, "iniciativa"))
	var ordem_depois = _rede.ultima_vista_mestre.get("ordemDinamica", {}).get("ordem", [])
	_ok(ordem_depois == ordem_antes and not (ordem_depois as Array).is_empty(),
		"3: a ordem dinâmica é a mesma depois de reentrar %s" % JSON.stringify(ordem_depois))
	await _gravar("3-reentrou-iniciativa.png")

	_linha("== 4. desliga a caixa, sai e volta a entrar ==")
	_m.ligar_caixa(false)
	_ok(await _escolha_no_servidor_e(false, "iniciativa"), "4: o servidor guardou a caixa desligada")
	await _sair_mestre("4")
	if not await _entrar_mestre("4"):
		_fim()
		return
	_ok(not _m.caixa_ligada and not _m._caixa.visible and _m.ordem_turnos.modo == "iniciativa",
		"4: a caixa voltou desligada (não aparece) — " + _caixa_e(false, "iniciativa"))
	await _gravar("4-reentrou-desligada.png")

	_linha("== 5. volta a ligar e repõe o modo dinâmico ==")
	_m.ligar_caixa(true)
	_ok(await _escolha_no_servidor_e(true, "iniciativa"), "5: caixa ligada no servidor")
	_m.definir_modo_iniciativa(false)
	_ok(await _escolha_no_servidor_e(true, "dinamico"), "5: modo dinâmico no servidor")
	_ok(_m._caixa.visible and _m.ordem_turnos.modo == "dinamico", "5: " + _caixa_e(true, "dinamico"))
	await _quadros(10)
	await _gravar("5-religada.png")

	var recusas: Array = _m.alertas.filter(func(t): return str(t).begins_with("O servidor não aceitou"))
	_ok(recusas.is_empty(), "nenhum comando do Mestre foi recusado %s" % [recusas])
	for l in _herois.values():
		var viu := false
		for e in l.eventos:
			if JSON.stringify(e).contains("caixaMestre"):
				viu = true
		_ok(not viu and JSON.stringify(l.opcoes).find("caixaMestre") < 0, "a heroína %s nunca recebeu caixaMestre" % l.figura_id)
	_fim()


func _fim() -> void:
	_linha("")
	_linha("prova da caixa (cliente): %d de %d verificações passaram." % [_total - _falhas, _total])
	for l in _herois.values():
		l.fechar()
	await _quadros(5)
	quit(1 if _falhas > 0 or _total == 0 else 0)
