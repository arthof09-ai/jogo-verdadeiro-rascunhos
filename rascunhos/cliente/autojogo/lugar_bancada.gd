extends RefCounted
## ORDEM AUTOJOGO — um lugar da mesa jogado pela bancada (FERRAMENTA DE MEDIÇÃO; só o autojogo o usa).
## Um WebSocket próprio, ao lado da Rede do jogo (que no autojogo é a heroína 1 com a arena montada): a heroína 2 e o
## Mestre da bancada entram por aqui, pelo protocolo v2 de verdade (ROOM_JOIN, ROOM_INTENT, MASTER_*).
## Os ids das intenções são da bancada e deterministas (semente + contador), no formato UUID v4 que o servidor aceita.

const PROTOCOLO := 2
const VERSAO := "autojogo-bancada/1"

var rotulo := ""
var papel := ""
var seat_id := ""
var figura_id := ""
var room_id := ""
var revision := 0
var opcoes: Dictionary = {}
var vista: Dictionary = {}  # a última MASTER_VIEW (só o Mestre)
var vistas_recebidas := 0
var respostas: Dictionary = {}  # id → mensagem (ROOM_RECEIPT / ROOM_REJECT / ERRO)
var eventos: Array = []  # ROOM_EVENT pela ordem de chegada (o registo do Mestre)
var erros: Array = []
var na_mesa := false

var _ws: WebSocketPeer = null
var _join: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _init(nome_rotulo: String, semente: int) -> void:
	rotulo = nome_rotulo
	_rng.seed = hash("%s|%d" % [nome_rotulo, semente])


func ligar(url: String, join: Dictionary) -> void:
	_join = join.duplicate(true)
	papel = str(join.get("papel", ""))
	_ws = WebSocketPeer.new()
	_ws.inbound_buffer_size = 1 << 21
	_ws.connect_to_url(url)


func fechar() -> void:
	if _ws != null:
		_ws.close(1000, "fim do autojogo")


func ligado() -> bool:
	return _ws != null and _ws.get_ready_state() == WebSocketPeer.STATE_OPEN


func poll() -> void:
	if _ws == null:
		return
	_ws.poll()
	var st := _ws.get_ready_state()
	if st == WebSocketPeer.STATE_OPEN and not _join.is_empty():
		_enviar(_join)
		_join = {}
	while _ws.get_ready_state() == WebSocketPeer.STATE_OPEN and _ws.get_available_packet_count() > 0:
		var texto := _ws.get_packet().get_string_from_utf8()
		var d = JSON.parse_string(texto)
		if d is Dictionary:
			_receber(d)


func _receber(m: Dictionary) -> void:
	if m.get("revision") != null and int(m["revision"]) > revision:
		revision = int(m["revision"])
	var tipo := str(m.get("type", ""))
	match tipo:
		"ROOM_WELCOME":
			seat_id = str(m.get("seatId", ""))
			room_id = str(m.get("roomId", ""))
			na_mesa = true
		"ROOM_SNAPSHOT":
			if m.get("propria") is Dictionary:
				figura_id = str(m["propria"].get("figuraId", ""))
		"ROOM_OPTIONS":
			opcoes = m
		"MASTER_VIEW":
			vista = m
			vistas_recebidas += 1
		"ROOM_EVENT":
			eventos.append(m)
		"ROOM_RECEIPT", "ROOM_REJECT":
			var id := str(m.get("intentId", m.get("cmdId", "")))
			if id != "":
				respostas[id] = m
		"ERRO":
			erros.append(m)
			var id2 := str(m.get("cmdId", m.get("intentId", "")))
			if id2 != "":
				respostas[id2] = m


func _enviar(msg: Dictionary) -> void:
	if ligado():
		_ws.send_text(JSON.stringify(msg))


## UUID v4 determinista (o servidor exige o formato, não o acaso).
func novo_id() -> String:
	var b := PackedByteArray()
	for i in 16:
		b.append(_rng.randi() & 0xFF)
	b[6] = (b[6] & 0x0F) | 0x40
	b[8] = (b[8] & 0x3F) | 0x80
	var h := b.hex_encode()
	return "%s-%s-%s-%s-%s" % [h.substr(0, 8), h.substr(8, 4), h.substr(12, 4), h.substr(16, 4), h.substr(20, 12)]


## ROOM_INTENT (jogadora). Devolve o intentId.
func intencao(acao: Dictionary) -> String:
	var id := novo_id()
	_enviar({"v": PROTOCOLO, "type": "ROOM_INTENT", "roomId": room_id, "intentId": id, "revision": revision, "acao": acao})
	return id


## MASTER_* (Mestre). `cmdId` em todos menos no MASTER_ACT (intentId). Devolve o id.
func comando(tipo: String, campos: Dictionary) -> String:
	var id := novo_id()
	var msg := campos.duplicate(true)
	msg["v"] = PROTOCOLO
	msg["type"] = tipo
	msg["roomId"] = room_id
	msg["revision"] = revision
	msg["intentId" if tipo == "MASTER_ACT" else "cmdId"] = id
	_enviar(msg)
	return id


## Pede a MASTER_VIEW (isenta de revisão). Devolve o contador a esperar.
func pedir_vista() -> int:
	_enviar({"v": PROTOCOLO, "type": "MASTER_VIEW", "roomId": room_id})
	return vistas_recebidas + 1
