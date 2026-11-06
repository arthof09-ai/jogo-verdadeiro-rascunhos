extends Node
## Autoload "Rede": ligação WebSocket à mesa (Protocolo v2 + erratas v0.2 / v0.2.1).
##
## - Liga a ws://<mesma origem>/mesa (wss se a página for https). Na web a origem
##   vem de location.host; fora dela, de um fallback configurável.
## - Reconecta com espera crescente (1 s, 2 s, 4 s ... até 30 s, com variação).
## - Guarda o seatToken em user:// (nunca na URL, nunca no log).
## - Mantém a fila das intenções (ENVIADA, DESCONHECIDA, AGUARDANDO_MESTRE ...).
## - Ping de aplicação "p" a cada 20 s.
## - NÃO calcula regra: só transporta intenções e entrega o que o servidor manda.

signal snapshot_recebido(msg: Dictionary)
signal evento_recebido(msg: Dictionary)
signal opcoes_recebidas(msg: Dictionary)
signal recibo_recebido(intent_id: String, estado: String, msg: Dictionary)
signal recusa_recebida(intent_id: String, motivo: String, texto: String)
signal boas_vindas_recebidas(msg: Dictionary)
signal sala_pausada(motivo: String)
signal sala_retomada
signal ligacao_mudou(estado: int)
signal precisa_entrar(motivo: String)
signal erro_recebido(codigo: String, texto: String)

const FilaIntencoes := preload("res://rede/fila_intencoes.gd")
const Uuid := preload("res://rede/uuid.gd")

enum Ligacao { DESLIGADA, A_LIGAR, A_ENTRAR, NA_MESA, A_ESPERAR, PARADA }

const PROTOCOLO := 2
const VERSAO_CLIENTE := "0.1.0-jv2.1a"
const CAMINHO_WS := "/mesa"
const INTERVALO_PING_S := 20.0
const SILENCIO_MAX_S := 45.0
const ESPERA_MIN_S := 1.0
const ESPERA_MAX_S := 30.0
const LIMITE_BYTES := 16384  # §2: mensagem do cliente ≤ 16 KB
const LIMITE_INTENCOES_POR_S := 10  # §2: ≤ 10 intenções por segundo
const CODIGO_OUTRO_APARELHO := 4002  # E-P9: o segundo JOIN fecha o primeiro
const ARQ_LUGAR := "user://lugar.cfg"
const ARQ_REDE := "user://rede.cfg"
const ARQ_PENDENTES := "user://pendentes.json"
const CHAVE_HOST := "assimilacao/rede/host_padrao"
const CHAVE_SALA := "assimilacao/rede/sala_padrao"

var fila = FilaIntencoes.new()
var estado_ligacao: int = Ligacao.DESLIGADA
## Os testes sem tela desligam a escrita em disco.
var persistir := true

var _ws: WebSocketPeer = null
var _ativo := false
var _room_id := ""
var _seat_id := ""
var _seat_token := ""
var _nome := ""
var _senha := ""  # só em memória, só até ao ROOM_WELCOME
var _entrou_com_token := false
var _ja_esteve_na_mesa := false
var _espera_s := ESPERA_MIN_S
var _relogio_reconexao := 0.0
var _relogio_ping := 0.0
var _silencio_s := 0.0
var _servidor_responde_ping := false
var _envios_recentes: Array = []


func _ready() -> void:
	set_process(false)


# ---------------------------------------------------------------- API pública

## Chamado pela cena principal. Nos testes sem tela ninguém chama: nada liga.
func iniciar() -> void:
	if _ativo:
		return
	_ativo = true
	_room_id = _sala_configurada()
	_carregar_lugar()
	_carregar_pendentes()
	set_process(true)
	if _seat_token != "":
		_ligar()
	else:
		precisa_entrar.emit("")


## Entrada com o nome da personagem e a senha simples (o lobby completo é a JV3.1).
func entrar(nome: String, senha: String) -> void:
	_nome = nome.strip_edges()
	_senha = senha
	if _nome == "":
		precisa_entrar.emit("nome")
		return
	_seat_token = ""
	_guardar_lugar()
	fila.limpar()
	_guardar_pendentes()
	_ativo = true
	set_process(true)
	if _ws != null and estado_ligacao == Ligacao.A_ENTRAR:
		_enviar_join()
		return
	_fechar_socket()
	_espera_s = ESPERA_MIN_S
	_ligar()


## Esquece o lugar neste aparelho.
func sair() -> void:
	_fechar_socket()
	_mudar_estado(Ligacao.DESLIGADA)
	_seat_token = ""
	_seat_id = ""
	_guardar_lugar()
	fila.limpar()
	_guardar_pendentes()
	var est = _estado_no()
	if est != null:
		est.limpar()
	precisa_entrar.emit("")


## Envia uma ROOM_INTENT com intentId UUID v4. Devolve o intentId, ou "" se não deu.
## `revision` é a revisão que o aparelho viu (a das ROOM_OPTIONS).
func enviar_intencao(acao: Dictionary, revision) -> String:
	if estado_ligacao != Ligacao.NA_MESA or _ws == null:
		return ""
	if fila.tem_em_voo():
		return ""
	if not _dentro_do_limite():
		return ""
	var id := Uuid.v4()
	var msg := {
		"v": PROTOCOLO, "type": "ROOM_INTENT", "roomId": _room_id,
		"intentId": id, "revision": _normalizar(revision), "acao": acao
	}
	var texto := JSON.stringify(msg)
	if texto.to_utf8_buffer().size() > LIMITE_BYTES:
		return ""
	fila.registar(id, texto)
	_guardar_pendentes()
	_enviar_texto(texto)
	return id


## Pede os eventos depois de `ultimo_seq` (fluxo deste lugar, E-P4).
func enviar_resync(ultimo_seq: int) -> void:
	if estado_ligacao != Ligacao.NA_MESA:
		return  # ao religar, o RESYNC sai sozinho
	_enviar_dict({"v": PROTOCOLO, "type": "ROOM_RESYNC", "roomId": _room_id, "lastSeq": ultimo_seq})


func consultar_recibos(ids: Array) -> void:
	if ids.is_empty() or estado_ligacao != Ligacao.NA_MESA:
		return
	_enviar_dict({"v": PROTOCOLO, "type": "RECEIPT_QUERY", "roomId": _room_id, "intentIds": ids})


func na_mesa() -> bool:
	return estado_ligacao == Ligacao.NA_MESA


func ja_esteve_na_mesa() -> bool:
	return _ja_esteve_na_mesa


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
		host = _host_configurado()
	return "%s://%s%s" % [esquema, host, CAMINHO_WS]


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
			_silencio_s = 0.0
			if _ws.was_string_packet():
				_ao_receber(pacote.get_string_from_utf8())
		if _ws == null:
			return
		_relogio_ping += delta
		if _relogio_ping >= INTERVALO_PING_S:
			_relogio_ping = 0.0
			_ws.send_text("p")
		_silencio_s += delta
		# Só se o servidor responde ao "p" é que o silêncio prova uma ligação morta.
		if _servidor_responde_ping and _silencio_s > SILENCIO_MAX_S:
			_ws.close(-1)
	elif st == WebSocketPeer.STATE_CLOSED:
		var codigo := _ws.get_close_code()
		_ws = null
		_ao_fechar(codigo)


func _ligar() -> void:
	var url := url_servidor()
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = 1 << 20  # snapshots grandes cabem
	var err := _ws.connect_to_url(url)
	if err != OK:
		_ws = null
		_agendar_reconexao()
		return
	_relogio_ping = 0.0
	_silencio_s = 0.0
	_servidor_responde_ping = false
	_mudar_estado(Ligacao.A_LIGAR)


func _ao_abrir() -> void:
	_mudar_estado(Ligacao.A_ENTRAR)
	_enviar_join()


func _enviar_join() -> void:
	var msg := {
		"v": PROTOCOLO, "type": "ROOM_JOIN", "roomId": _room_id,
		"papel": "jogadora", "cliente": VERSAO_CLIENTE
	}
	if _seat_token != "":
		msg["seatToken"] = _seat_token  # dentro da mensagem, nunca na URL (E-P9)
		_entrou_com_token = true
	elif _nome != "":
		msg["nome"] = _nome
		msg["senha"] = _senha
		_entrou_com_token = false
	else:
		precisa_entrar.emit("")
		return
	var est = _estado_no()
	if est != null and est.tem_snapshot:
		msg["lastSeq"] = est.ultimo_seq
	_enviar_dict(msg)


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
		precisa_entrar.emit("outro_aparelho")
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


# ---------------------------------------------------------------- receção

func _ao_receber(texto: String) -> void:
	if not texto.begins_with("{"):
		_servidor_responde_ping = true  # resposta ao "p" (auto-resposta do servidor)
		return
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
			evento_recebido.emit(msg)
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
	_guardar_lugar()
	_nome = ""
	_senha = ""
	_espera_s = ESPERA_MIN_S
	_ja_esteve_na_mesa = true
	_mudar_estado(Ligacao.NA_MESA)
	boas_vindas_recebidas.emit(msg)
	# E-C7: ao religar, sempre RESYNC; depois, perguntar pelas intenções pendentes.
	var est = _estado_no()
	if est != null and est.tem_snapshot:
		enviar_resync(est.ultimo_seq)
	consultar_recibos(fila.ids_para_consulta())


func _ao_recibo(msg: Dictionary) -> void:
	var id := _texto(msg.get("intentId"))
	var r: int = fila.aplicar_recibo(msg)
	if r == FilaIntencoes.Resultado.REENVIAR:
		var t: String = fila.texto_de(id)
		if t != "":
			_enviar_texto(t)  # MESMO intentId, MESMO texto: o servidor deduplica
	elif r == FilaIntencoes.Resultado.NOVO:
		recibo_recebido.emit(id, fila.estado_de(id), msg)
	# IGNORADO: recibo duplicado ou alheio, não se mostra nada.
	_guardar_pendentes()


func _ao_recusa(msg: Dictionary) -> void:
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


func _ao_erro(msg: Dictionary) -> void:
	var codigo := _texto(msg.get("codigo"))
	if codigo == "versao":
		_parar_por_versao()
		return
	if estado_ligacao == Ligacao.A_ENTRAR:
		_fechar_socket()
		_mudar_estado(Ligacao.DESLIGADA)
		if _entrou_com_token:
			_seat_token = ""
			_guardar_lugar()
			fila.limpar()
			_guardar_pendentes()
			precisa_entrar.emit("token")
		else:
			precisa_entrar.emit("senha")
		return
	erro_recebido.emit(codigo, _texto(msg.get("texto")))


func _parar_por_versao() -> void:
	_fechar_socket()
	_mudar_estado(Ligacao.PARADA)
	erro_recebido.emit("versao", "")


# ---------------------------------------------------------------- envio

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
	if _envios_recentes.size() >= LIMITE_INTENCOES_POR_S:
		return false
	_envios_recentes.append(agora)
	return true


func _mudar_estado(novo: int) -> void:
	if novo == estado_ligacao:
		return
	estado_ligacao = novo
	ligacao_mudou.emit(novo)


# ---------------------------------------------------------------- configuração e disco

func _host_configurado() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--servidor="):
			return arg.substr("--servidor=".length())
	var cfg := ConfigFile.new()
	if cfg.load(ARQ_REDE) == OK:
		var h = cfg.get_value("servidor", "host", "")
		if h is String and h != "":
			return h
	return str(ProjectSettings.get_setting(CHAVE_HOST, "127.0.0.1:8080"))


func _sala_configurada() -> String:
	if OS.has_feature("web"):
		var s = JavaScriptBridge.eval("new URLSearchParams(location.search).get('sala') || ''", true)
		if s is String and s != "":
			return s
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sala="):
			return arg.substr("--sala=".length())
	var cfg := ConfigFile.new()
	if cfg.load(ARQ_REDE) == OK:
		var v = cfg.get_value("servidor", "sala", "")
		if v is String and v != "":
			return v
	return str(ProjectSettings.get_setting(CHAVE_SALA, "mesa"))


func _carregar_lugar() -> void:
	if not persistir:
		return
	var cfg := ConfigFile.new()
	if cfg.load(ARQ_LUGAR) != OK:
		return
	var sala = cfg.get_value("lugar", "roomId", "")
	if sala != _room_id:
		return  # o token é de outra sala: não serve
	_seat_id = _texto(cfg.get_value("lugar", "seatId", ""))
	_seat_token = _texto(cfg.get_value("lugar", "seatToken", ""))


func _guardar_lugar() -> void:
	if not persistir:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("lugar", "roomId", _room_id)
	cfg.set_value("lugar", "seatId", _seat_id)
	cfg.set_value("lugar", "seatToken", _seat_token)
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


static func _texto(v) -> String:
	return v if v is String else ""


static func _int(v) -> int:
	if v is int:
		return v
	if v is float:
		return int(v)
	return 0


static func _normalizar(v):
	if v is float and v == floorf(v):
		return int(v)
	return v
