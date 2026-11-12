extends Node
## Autoload "Rede": ligação WebSocket ao servidor de mesa (Protocolo v2 + erratas v0.2, v0.2.1, v0.2.2).
##
## ALINHADO AO SERVIDOR REAL (rascunhos/servidor/nucleo/sala.js e adaptadores/node/servidor-ws.js).
## Em caso de divergência, o servidor manda; onde ele parece errado face à especificação,
## fica um comentário "# DIVERGÊNCIA:".
##
## - Liga a ws://<mesma origem>/ws (wss se a página for https). Na web a origem vem de
##   location.host; fora dela, do campo do lobby (user://rede.cfg) ou de "-- --servidor=".
## - Reconecta com espera crescente (1 s, 2 s, 4 s ... até 30 s, com variação).
## - Guarda o seatToken em user:// (nunca na URL, nunca no log). PIN e senha: só em memória.
## - Mantém a fila das intenções da jogadora (ENVIADA, DESCONHECIDA, AGUARDANDO_MESTRE ...).
## - O ping é só da camada WebSocket (princípio 6): nada de ping de aplicação.
## - NÃO calcula regra: só transporta intenções e comandos e entrega o que o servidor manda.

signal snapshot_recebido(msg: Dictionary)
signal evento_recebido(msg: Dictionary)
signal opcoes_recebidas(msg: Dictionary)
signal recibo_recebido(intent_id: String, estado: String, msg: Dictionary)
signal recusa_recebida(intent_id: String, motivo: String, texto: String)
## Toda a `revision` que chega fora de eventos/snapshot/opções (ex.: no ROOM_RECEIPT).
signal revisao_vista(revision: int)
signal boas_vindas_recebidas(msg: Dictionary)
signal sala_pausada(motivo: String)
signal sala_retomada
signal ligacao_mudou(estado: int)
signal precisa_entrar(motivo: String)
## ERRO do servidor durante a entrada (credenciais, bloqueado ...). `texto` é a frase do servidor.
signal entrada_recusada(codigo: String, texto: String)
signal erro_recebido(codigo: String, texto: String)
## Só o Mestre: MASTER_VIEW, MASTER_CARD, MASTER_RESULTS, MASTER_ALERTA, MASTER_EXPORT.
signal mestre_recebido(msg: Dictionary)
## Só o Mestre: ROOM_RECEIPT / ROOM_REJECT de um comando (id = cmdId, ou intentId no MASTER_ACT).
signal comando_respondido(id: String, msg: Dictionary)

const FilaIntencoes := preload("res://rede/fila_intencoes.gd")
const Uuid := preload("res://rede/uuid.gd")
const ValidarEntrada := preload("res://rede/validar_entrada.gd")

enum Ligacao { DESLIGADA, A_LIGAR, A_ENTRAR, NA_MESA, A_ESPERAR, PARADA }

const PROTOCOLO := 2
const VERSAO_CLIENTE := "0.2.0-jv3.1"
## O adaptador Node cria o WebSocket com caminhoWs = '/ws' por omissão (servidor-ws.js).
## O rascunho anterior do cliente usava '/mesa': o servidor manda.
const CAMINHO_WS := "/ws"
## O servidor manda um ping WebSocket a cada 20 s e fecha sem pong aos 45 s.
## Fora da web, o Godot também pinga (a propriedade não tem efeito na web: o navegador cuida).
const HEARTBEAT_S := 20.0
const ESPERA_MIN_S := 1.0
const ESPERA_MAX_S := 30.0
const LIMITE_BYTES := 16384  # §2: mensagem do cliente ≤ 16 KB
const LIMITE_COMANDOS_POR_S := 10  # §2: ≤ 10 por segundo (o servidor conta ROOM_INTENT e MASTER_*)
const CODIGO_OUTRO_APARELHO := 4002  # E-P9: o segundo JOIN fecha o primeiro
const ARQ_LUGAR := "user://lugar.cfg"
const ARQ_REDE := "user://rede.cfg"
const ARQ_PENDENTES := "user://pendentes.json"
const CHAVE_HOST := "assimilacao/rede/host_padrao"

var fila = FilaIntencoes.new()
var estado_ligacao: int = Ligacao.DESLIGADA
## "jogadora" ou "mestre" (o espectador ainda não tem cena: convite do Mestre, JV1.x).
var papel := "jogadora"
## Último motivo pelo qual se pediu a entrada (para a cena do lobby o mostrar ao abrir).
var motivo_entrada := ""
## Última frase de ERRO do servidor (só para mostrar; nunca técnica).
var texto_ultimo_erro := ""
## Só do Mestre: a última MASTER_VIEW e o cartão ativo (podem chegar antes de a cena abrir).
var ultima_vista_mestre: Dictionary = {}
var cartao_ativo: Dictionary = {}
## Os testes sem tela desligam a escrita em disco.
var persistir := true

var _ws: WebSocketPeer = null
var _ativo := false
var _room_id := ""
var _seat_id := ""
var _seat_token := ""
var _nome := ""
var _senha := ""  # só em memória, só até ao ROOM_WELCOME
var _pin := ""  # idem (E-P13: o PIN nunca vai ao disco)
var _entrou_com_token := false
var _ja_esteve_na_mesa := false
var _espera_s := ESPERA_MIN_S
var _relogio_reconexao := 0.0
var _envios_recentes: Array = []


func _ready() -> void:
	set_process(false)


# ---------------------------------------------------------------- API pública

## Chamado pela cena do lobby (e, por segurança, pela arena). Nos testes sem tela ninguém chama.
func iniciar() -> void:
	if _ativo:
		return
	_ativo = true
	_carregar_lugar()
	_carregar_pendentes()
	set_process(true)
	if _seat_token != "":
		_ligar()
	else:
		_pedir_entrada("")


## Entrada da jogadora com o nome da personagem e a senha simples.
## Ordem 34 (N26-2): com um campo fora (nome 1-64, senha 1-128) nada se liga nem se envia — volta a pedir a entrada.
func entrar(nome: String, senha: String) -> void:
	if not ValidarEntrada.jogadora_valida(nome, senha):
		_pedir_entrada("nome" if nome.strip_edges() == "" else "campos")
		return
	_nome = nome.strip_edges()
	_senha = senha
	_pin = ""
	_comecar_entrada("jogadora")


## Entrada do Mestre com o PIN (E-P9: 6 dígitos ou mais; quem confere é o servidor).
## Ordem 34 (N26-2): o PIN que não casa ^[0-9]{6,32}$ não sai do aparelho (0 mensagens, 0 tentativas gastas).
func entrar_mestre(pin: String) -> void:
	if not ValidarEntrada.mestre_valido(pin):
		_pedir_entrada("pin" if pin.strip_edges() == "" else "campos")
		return
	_pin = pin
	_nome = ""
	_senha = ""
	_comecar_entrada("mestre")


## Esquece o lugar neste aparelho.
func sair() -> void:
	_fechar_socket()
	_mudar_estado(Ligacao.DESLIGADA)
	_seat_token = ""
	_seat_id = ""
	_room_id = ""
	_guardar_lugar()
	fila.limpar()
	_guardar_pendentes()
	ultima_vista_mestre = {}
	cartao_ativo = {}
	var est = _estado_no()
	if est != null:
		est.limpar()
	_pedir_entrada("")


## Endereço "IP:porta" do servidor fora da web (campo do lobby). Na web, a origem manda.
func definir_servidor(host: String) -> void:
	var h := host.strip_edges()
	if h == "" or not persistir:
		return
	var cfg := ConfigFile.new()
	cfg.load(ARQ_REDE)  # pode não existir: começa vazio
	cfg.set_value("servidor", "host", h)
	cfg.save(ARQ_REDE)


## Envia uma ROOM_INTENT com intentId UUID v4. Devolve o intentId, ou "" se não deu.
## `revision` é a revisão que o aparelho viu (a das ROOM_OPTIONS).
func enviar_intencao(acao: Dictionary, revision) -> String:
	if estado_ligacao != Ligacao.NA_MESA or _ws == null or papel != "jogadora":
		return ""
	if fila.tem_em_voo():
		return ""
	if not _dentro_do_limite():
		return ""
	var id := Uuid.v4()
	var texto := JSON.stringify(montar_intencao(acao, revision, id))
	if texto.to_utf8_buffer().size() > LIMITE_BYTES:
		return ""
	fila.registar(id, texto)
	_guardar_pendentes()
	_enviar_texto(texto)
	return id


## Monta a ROOM_INTENT exatamente como o servidor a valida (sala.js tratarIntencao).
func montar_intencao(acao: Dictionary, revision, id: String) -> Dictionary:
	var msg := {
		"v": PROTOCOLO, "type": "ROOM_INTENT",
		"intentId": id, "revision": _normalizar(revision), "acao": acao
	}
	if _room_id != "":
		msg["roomId"] = _room_id
	return msg


## Só o Mestre. Envia um MASTER_* com revisão. Devolve o id (cmdId, ou intentId no MASTER_ACT).
func enviar_mestre(tipo: String, campos: Dictionary, revision) -> String:
	if estado_ligacao != Ligacao.NA_MESA or _ws == null or papel != "mestre":
		return ""
	if not _dentro_do_limite():
		return ""
	var id := Uuid.v4()
	var texto := JSON.stringify(montar_comando_mestre(tipo, campos, revision, id))
	if texto.to_utf8_buffer().size() > LIMITE_BYTES:
		return ""
	return id if _enviar_texto(texto) else ""


## Monta um MASTER_* como o servidor o valida (sala.js tratarMestre): `cmdId` em todos,
## menos no MASTER_ACT, que usa `intentId`. Todos os que mudam estado levam `revision` (E-C3).
func montar_comando_mestre(tipo: String, campos: Dictionary, revision, id: String) -> Dictionary:
	var msg: Dictionary = campos.duplicate(true)
	msg["v"] = PROTOCOLO
	msg["type"] = tipo
	msg["revision"] = _normalizar(revision)
	if tipo == "MASTER_ACT":
		msg["intentId"] = id
	else:
		msg["cmdId"] = id
	if _room_id != "":
		msg["roomId"] = _room_id
	return msg


## Só o Mestre: pede a MASTER_VIEW (isenta de revisão e de recibo, E-C3).
func pedir_vista_mestre() -> void:
	if papel != "mestre" or estado_ligacao != Ligacao.NA_MESA or not _dentro_do_limite():
		return
	_enviar_dict(_com_sala({"v": PROTOCOLO, "type": "MASTER_VIEW"}))


## Só o Mestre: MASTER_SEARCH (pesquisa de criatura ou NPC por nome; "" lista tudo).
func pesquisar_fichas(texto: String) -> void:
	if papel != "mestre" or estado_ligacao != Ligacao.NA_MESA or not _dentro_do_limite():
		return
	_enviar_dict(_com_sala({"v": PROTOCOLO, "type": "MASTER_SEARCH", "texto": texto}))


## Pede os eventos depois de `ultimo_seq` (fluxo deste lugar, E-P4).
## Um `ultimo_seq` negativo faz o servidor mandar um ROOM_SNAPSHOT inteiro
## (sala.js mensagensDeSincronizacao: lastSeq fora do intervalo → snapshot).
func enviar_resync(ultimo_seq: int) -> void:
	if estado_ligacao != Ligacao.NA_MESA:
		return  # ao religar, o próprio ROOM_JOIN traz a sincronização
	_enviar_dict(_com_sala({"v": PROTOCOLO, "type": "ROOM_RESYNC", "lastSeq": ultimo_seq}))


func consultar_recibos(ids: Array) -> void:
	if ids.is_empty() or estado_ligacao != Ligacao.NA_MESA:
		return
	_enviar_dict(_com_sala({"v": PROTOCOLO, "type": "RECEIPT_QUERY", "intentIds": ids.slice(0, 50)}))


func na_mesa() -> bool:
	return estado_ligacao == Ligacao.NA_MESA


func a_ligar() -> bool:
	return estado_ligacao == Ligacao.A_LIGAR or estado_ligacao == Ligacao.A_ENTRAR \
		or estado_ligacao == Ligacao.A_ESPERAR


func ja_esteve_na_mesa() -> bool:
	return _ja_esteve_na_mesa


func tem_token() -> bool:
	return _seat_token != ""


func room_id() -> String:
	return _room_id


func ha_intencao_em_voo() -> bool:
	return fila.tem_em_voo()


func aguardando_mestre() -> bool:
	return fila.aguardando_mestre()


func url_servidor() -> String:
	var host := ""
	var esquema := "ws"
	if OS.has_feature("web"):
		var h = JavaScriptBridge.eval("location.host", true)
		if h is String and h != "":
			host = h
		var p = JavaScriptBridge.eval("location.protocol", true)
		if p is String and p == "https:":
			esquema = "wss"  # E-P9: wss sempre que houver TLS
	if host == "":
		host = host_configurado()
	return "%s://%s%s" % [esquema, host, CAMINHO_WS]


## "IP:porta" fora da web: argumento "--servidor=", depois user://rede.cfg, depois o project.godot.
func host_configurado() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--servidor="):
			return arg.substr("--servidor=".length())
	var cfg := ConfigFile.new()
	if cfg.load(ARQ_REDE) == OK:
		var h = cfg.get_value("servidor", "host", "")
		if h is String and h != "":
			return h
	return str(ProjectSettings.get_setting(CHAVE_HOST, "127.0.0.1:8080"))


# ---------------------------------------------------------------- laço

func _process(delta: float) -> void:
	if _ws == null:
		if estado_ligacao == Ligacao.A_ESPERAR:
			_relogio_reconexao -= delta
			if _relogio_reconexao <= 0.0:
				_ligar()
		return

	_ws.poll()
	var st := _ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN:
		if estado_ligacao == Ligacao.A_LIGAR:
			_ao_abrir()
		while _ws != null and _ws.get_available_packet_count() > 0:
			var pacote := _ws.get_packet()
			if _ws != null and _ws.was_string_packet():
				_ao_receber(pacote.get_string_from_utf8())
	elif st == WebSocketPeer.STATE_CLOSED:
		var codigo := _ws.get_close_code()
		_ws = null
		_ao_fechar(codigo)


func _comecar_entrada(novo_papel: String) -> void:
	papel = novo_papel
	_seat_token = ""
	_seat_id = ""
	_room_id = ""
	_guardar_lugar()
	fila.limpar()
	_guardar_pendentes()
	ultima_vista_mestre = {}
	cartao_ativo = {}
	var est = _estado_no()
	if est != null:
		est.limpar()  # o lastSeq de outro lugar não serve (E-P4: seq por destinatário)
	_ativo = true
	set_process(true)
	if _ws != null and estado_ligacao == Ligacao.A_ENTRAR:
		_enviar_join()
		return
	_fechar_socket()
	_espera_s = ESPERA_MIN_S
	_ligar()


func _ligar() -> void:
	var url := url_servidor()
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = 1 << 20  # snapshots grandes cabem
	if not OS.has_feature("web"):
		_ws.heartbeat_interval = HEARTBEAT_S
	var err := _ws.connect_to_url(url)
	if err != OK:
		_ws = null
		_agendar_reconexao()
		return
	_mudar_estado(Ligacao.A_LIGAR)


func _ao_abrir() -> void:
	_mudar_estado(Ligacao.A_ENTRAR)
	_enviar_join()


func _enviar_join() -> void:
	var msg := montar_join()
	if msg.is_empty():
		_fechar_socket()
		_mudar_estado(Ligacao.DESLIGADA)
		_pedir_entrada("")
		return
	_entrou_com_token = msg.has("seatToken")
	_enviar_dict(msg)


## Monta o ROOM_JOIN (sala.js entrar): papel + (seatToken) ou (nome+senha) ou (pin); lastSeq opcional.
## Ordem 21 (N19-2, errata do schema ROOM_JOIN): o roomId não é exigido; só vai se já o conhecemos de um
## ROOM_WELCOME anterior. Vazio = não há com que entrar (pede-se a entrada outra vez).
func montar_join() -> Dictionary:
	var msg := _com_sala({"v": PROTOCOLO, "type": "ROOM_JOIN", "papel": papel, "cliente": VERSAO_CLIENTE})
	if _seat_token != "":
		msg["seatToken"] = _seat_token  # dentro da mensagem, nunca na URL (E-P9)
		var est = _estado_no()
		if est != null and est.tem_snapshot:
			msg["lastSeq"] = est.ultimo_seq  # o mesmo lugar: o fluxo é o mesmo
	elif papel == "mestre" and _pin != "":
		msg["pin"] = _pin
	elif papel != "mestre" and _nome != "":
		msg["nome"] = _nome
		msg["senha"] = _senha
	else:
		return {}
	return msg


func _ao_fechar(codigo: int) -> void:
	fila.marcar_desconhecidas()
	_guardar_pendentes()
	if estado_ligacao == Ligacao.PARADA or estado_ligacao == Ligacao.DESLIGADA:
		return
	if codigo == CODIGO_OUTRO_APARELHO:
		# Outro aparelho entrou com este lugar: não brigar por ele.
		_seat_token = ""
		_guardar_lugar()
		_mudar_estado(Ligacao.PARADA)
		_pedir_entrada("outro_aparelho")
		return
	_agendar_reconexao()


func _agendar_reconexao() -> void:
	_mudar_estado(Ligacao.A_ESPERAR)
	_relogio_reconexao = _espera_s * randf_range(0.8, 1.2)
	_espera_s = minf(_espera_s * 2.0, ESPERA_MAX_S)


func _fechar_socket() -> void:
	if _ws != null:
		_ws.close()
		_ws = null
		fila.marcar_desconhecidas()
		_guardar_pendentes()


func _pedir_entrada(motivo: String) -> void:
	motivo_entrada = motivo
	precisa_entrar.emit(motivo)


# ---------------------------------------------------------------- receção

func _ao_receber(texto: String) -> void:
	if not texto.begins_with("{"):
		return  # o servidor só fala JSON; qualquer outra coisa é ignorada
	var dados = JSON.parse_string(texto)
	if not (dados is Dictionary):
		return
	var msg: Dictionary = dados
	if _int(msg.get("v")) > PROTOCOLO:
		_parar_por_versao()
		return
	match _texto(msg.get("type")):
		"ROOM_WELCOME":
			_ao_boas_vindas(msg)
		"ROOM_SNAPSHOT":
			snapshot_recebido.emit(msg)
		"ROOM_EVENT":
			_ao_evento(msg)
		"ROOM_OPTIONS":
			opcoes_recebidas.emit(msg)
		"ROOM_RECEIPT":
			_ao_recibo(msg)
		"ROOM_REJECT":
			_ao_recusa(msg)
		"ROOM_PAUSED":
			sala_pausada.emit(_texto(msg.get("motivo")))
		"ROOM_RESUMED":
			sala_retomada.emit()
		"ERRO":
			_ao_erro(msg)
		"MASTER_VIEW", "MASTER_CARD", "MASTER_RESULTS", "MASTER_ALERTA", "MASTER_EXPORT" when papel != "mestre":
			pass  # privacidade (desenho JV3.1 §7): fora do lugar do Mestre, nada do Mestre se guarda nem se mostra
		"MASTER_VIEW":
			ultima_vista_mestre = msg
			mestre_recebido.emit(msg)
		"MASTER_CARD":
			cartao_ativo = msg
			mestre_recebido.emit(msg)
		"MASTER_RESULTS", "MASTER_ALERTA", "MASTER_EXPORT":
			mestre_recebido.emit(msg)  # o MASTER_EXPORT nunca se escreve em log
		_:
			pass


func _ao_boas_vindas(msg: Dictionary) -> void:
	_seat_id = _texto(msg.get("seatId"))
	var token := _texto(msg.get("seatToken"))
	if token != "":
		_seat_token = token  # roda a cada JOIN (E-P9)
	var sala := _texto(msg.get("roomId"))
	if sala != "":
		_room_id = sala
	var p := _texto(msg.get("papel"))
	if p != "":
		papel = p
	_guardar_lugar()
	_nome = ""
	_senha = ""
	_pin = ""
	_espera_s = ESPERA_MIN_S
	_ja_esteve_na_mesa = true
	motivo_entrada = ""
	_mudar_estado(Ligacao.NA_MESA)
	boas_vindas_recebidas.emit(msg)
	# E-C7 ("ao religar, sempre RESYNC"): o servidor já junta a sincronização à resposta do
	# ROOM_JOIN (sala.js entrar → mensagensDeSincronizacao), por isso não se pede outra vez.
	# Falta só perguntar pelas intenções que ficaram sem recibo.
	if papel == "jogadora":
		consultar_recibos(fila.ids_para_consulta())


func _ao_evento(msg: Dictionary) -> void:
	# Só do Mestre: o cartão fecha com o evento `cartao_fechado` (sala.js fecharCartao).
	if not cartao_ativo.is_empty() and _texto(msg.get("tipo")) == "cartao_fechado":
		var d = msg.get("dados")
		if d is Dictionary and d.get("cartaoId") == cartao_ativo.get("cartaoId"):
			cartao_ativo = {}
	evento_recebido.emit(msg)


func _ao_recibo(msg: Dictionary) -> void:
	if msg.get("revision") != null:
		revisao_vista.emit(_int(msg.get("revision")))
	if papel == "mestre":
		comando_respondido.emit(_id_de(msg), msg)
		return
	var id := _texto(msg.get("intentId"))
	var r: int = fila.aplicar_recibo(msg)
	if r == FilaIntencoes.Resultado.REENVIAR:
		var t: String = fila.texto_de(id)
		if t != "":
			_enviar_texto(t)  # MESMO intentId, MESMO texto: o servidor deduplica (E-C1)
	elif r == FilaIntencoes.Resultado.NOVO:
		recibo_recebido.emit(id, fila.estado_de(id), msg)
	# IGNORADO: recibo duplicado ou alheio, não se mostra nada.
	_guardar_pendentes()


func _ao_recusa(msg: Dictionary) -> void:
	if papel == "mestre":
		comando_respondido.emit(_id_de(msg), msg)
		return
	var id := _texto(msg.get("intentId"))
	var motivo := _texto(msg.get("motivo"))
	var texto := _texto(msg.get("texto"))
	if id == "":
		recusa_recebida.emit("", motivo, texto)
		return
	if fila.aplicar_recusa(id, motivo):
		_guardar_pendentes()
		recusa_recebida.emit(id, motivo, texto)
	# Recusa repetida ou de id que não é nosso: ignora.


## Códigos reais do servidor: formato, versao, proibido, credenciais, bloqueado, interno, sem_lugar.
func _ao_erro(msg: Dictionary) -> void:
	var codigo := _texto(msg.get("codigo"))
	var texto := _texto(msg.get("texto"))
	texto_ultimo_erro = texto
	if codigo == "versao":
		_parar_por_versao()
		return
	if estado_ligacao == Ligacao.A_ENTRAR:
		_fechar_socket()
		_mudar_estado(Ligacao.DESLIGADA)
		entrada_recusada.emit(codigo, texto)
		if codigo == "credenciais" and _entrou_com_token:
			# O token já não vale: esquece-o e pede o nome e a senha (ou o PIN).
			_seat_token = ""
			_guardar_lugar()
			fila.limpar()
			_guardar_pendentes()
			_pedir_entrada("token")
		elif codigo == "credenciais":
			_pedir_entrada("senha")
		else:
			_pedir_entrada(codigo)  # ex.: "bloqueado" — o token (se houver) fica guardado
		return
	erro_recebido.emit(codigo, texto)


func _parar_por_versao() -> void:
	_fechar_socket()
	_mudar_estado(Ligacao.PARADA)
	erro_recebido.emit("versao", "")


# ---------------------------------------------------------------- envio

func _com_sala(msg: Dictionary) -> Dictionary:
	if _room_id != "":
		msg["roomId"] = _room_id
	return msg


func _enviar_dict(msg: Dictionary) -> bool:
	return _enviar_texto(JSON.stringify(msg))


func _enviar_texto(texto: String) -> bool:
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return false
	return _ws.send_text(texto) == OK


func _dentro_do_limite() -> bool:
	var agora := Time.get_ticks_msec()
	while not _envios_recentes.is_empty() and agora - int(_envios_recentes[0]) > 1000:
		_envios_recentes.pop_front()
	if _envios_recentes.size() >= LIMITE_COMANDOS_POR_S:
		return false
	_envios_recentes.append(agora)
	return true


func _mudar_estado(novo: int) -> void:
	if novo == estado_ligacao:
		return
	estado_ligacao = novo
	ligacao_mudou.emit(novo)


# ---------------------------------------------------------------- disco

## O lugar só vale para o mesmo servidor (o roomId é dado pelo servidor no WELCOME).
func _carregar_lugar() -> void:
	if not persistir:
		return
	var cfg := ConfigFile.new()
	if cfg.load(ARQ_LUGAR) != OK:
		return
	if _texto(cfg.get_value("lugar", "servidor", "")) != url_servidor():
		return  # token de outro servidor: não serve
	_room_id = _texto(cfg.get_value("lugar", "roomId", ""))
	_seat_id = _texto(cfg.get_value("lugar", "seatId", ""))
	_seat_token = _texto(cfg.get_value("lugar", "seatToken", ""))
	var p := _texto(cfg.get_value("lugar", "papel", ""))
	if p == "jogadora" or p == "mestre":
		papel = p


func _guardar_lugar() -> void:
	if not persistir:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("lugar", "servidor", url_servidor())
	cfg.set_value("lugar", "roomId", _room_id)
	cfg.set_value("lugar", "seatId", _seat_id)
	cfg.set_value("lugar", "seatToken", _seat_token)
	cfg.set_value("lugar", "papel", papel)
	cfg.save(ARQ_LUGAR)


func _guardar_pendentes() -> void:
	if not persistir:
		return
	var f := FileAccess.open(ARQ_PENDENTES, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"roomId": _room_id, "seatId": _seat_id, "itens": fila.para_guardar()}))
	f.close()


func _carregar_pendentes() -> void:
	if not persistir or _seat_token == "" or not FileAccess.file_exists(ARQ_PENDENTES):
		return
	var f := FileAccess.open(ARQ_PENDENTES, FileAccess.READ)
	if f == null:
		return
	var dados = JSON.parse_string(f.get_as_text())
	f.close()
	if not (dados is Dictionary):
		return
	if dados.get("roomId") != _room_id or dados.get("seatId") != _seat_id:
		return
	var itens = dados.get("itens")
	if itens is Array:
		fila.carregar(itens)


# ---------------------------------------------------------------- utilitários

func _estado_no() -> Node:
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/Estado")


## Id de um recibo ou recusa: `cmdId` (comandos do Mestre) ou `intentId`.
static func _id_de(msg: Dictionary) -> String:
	var c = msg.get("cmdId")
	if c is String and c != "":
		return c
	var i = msg.get("intentId")
	return i if i is String else ""


static func _texto(v) -> String:
	return v if v is String else ""


static func _int(v) -> int:
	if v is int:
		return v
	if v is float:
		return int(v)
	return 0


## O JSON do Godot devolve números como float; o servidor exige inteiros (Number.isInteger).
static func _normalizar(v):
	if v is float and v == floorf(v):
		return int(v)
	return v
