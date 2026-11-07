extends RefCounted
## Fila das intenções DESTE aparelho (Protocolo v2 §4.2; erratas E-C1, E-C2, E-C5, E-P8).
##
##   ENVIADA ──recibo──▶ APLICADA | RECUSADA | AGUARDANDO_MESTRE ──▶ APLICADA | RECUSADA
##      │
##      └─caiu a ligação─▶ DESCONHECIDA ─RECEIPT_QUERY─▶ recibo real
##                                        └─ servidor diz DESCONHECIDA → reenviar o MESMO texto
##
## Recibos duplicados, recibos de ids que não são nossos e recusas repetidas
## são IGNORADOS (não voltam a ser sinalizados à tela).

enum Resultado { IGNORADO, NOVO, REENVIAR }

const ENVIADA := "ENVIADA"
const DESCONHECIDA := "DESCONHECIDA"
const APLICADA := "APLICADA"
const RECUSADA := "RECUSADA"
const AGUARDANDO_MESTRE := "AGUARDANDO_MESTRE"

## Quantos ids terminados guardamos para reconhecer duplicados.
const MAX_TERMINADAS := 256
## Depois disto uma ENVIADA sem resposta deixa de travar a barra (a ligação é que decide).
const EM_VOO_MAX_MS := 8000

var _itens: Dictionary = {}  # intentId -> {estado, texto, revertida, seq, criada_ms, motivo}
var _terminadas: Array = []


func registar(intent_id: String, texto: String) -> void:
	_itens[intent_id] = {
		"estado": ENVIADA, "texto": texto, "revertida": false,
		"seq": 0, "criada_ms": Time.get_ticks_msec(), "motivo": ""
	}


func tem(intent_id: String) -> bool:
	return _itens.has(intent_id)


func estado_de(intent_id: String) -> String:
	if not _itens.has(intent_id):
		return ""
	return String(_itens[intent_id]["estado"])


func motivo_de(intent_id: String) -> String:
	if not _itens.has(intent_id):
		return ""
	return String(_itens[intent_id]["motivo"])


func texto_de(intent_id: String) -> String:
	if not _itens.has(intent_id):
		return ""
	return String(_itens[intent_id]["texto"])


## Aplica um ROOM_RECEIPT. Devolve Resultado.
func aplicar_recibo(recibo: Dictionary) -> int:
	var bruto = recibo.get("intentId")
	if not (bruto is String) or not _itens.has(bruto):
		return Resultado.IGNORADO  # id alheio ou desconhecido: ignora
	var id: String = bruto
	var item: Dictionary = _itens[id]
	var atual: String = item["estado"]
	var novo_bruto = recibo.get("estado")
	var novo: String = novo_bruto if novo_bruto is String else ""

	if novo == DESCONHECIDA:
		# O servidor nunca viu: reenviar o MESMO intentId é seguro (dedupe no servidor).
		if atual == DESCONHECIDA:
			item["estado"] = ENVIADA
			item["criada_ms"] = Time.get_ticks_msec()
			return Resultado.REENVIAR
		return Resultado.IGNORADO

	if atual == APLICADA or atual == RECUSADA:
		# Terminal. Só uma novidade conta: o Supervisor reverteu (E-C2).
		if atual == APLICADA and recibo.get("revertidaEm") != null and not item["revertida"]:
			item["revertida"] = true
			return Resultado.NOVO
		return Resultado.IGNORADO  # recibo duplicado

	if novo == atual:
		return Resultado.IGNORADO  # ex.: AGUARDANDO_MESTRE repetido
	if novo != APLICADA and novo != RECUSADA and novo != AGUARDANDO_MESTRE:
		return Resultado.IGNORADO

	item["estado"] = novo
	item["seq"] = _int(recibo.get("seq"))
	# Servidor real: RECUSADA por RECEIPT_QUERY ou por "voltar" do Mestre traz `motivo`
	# (ex.: "revertido", com `revertidaEm`), sem `texto`.
	var m = recibo.get("motivo")
	if m is String:
		item["motivo"] = m
	if novo == APLICADA or novo == RECUSADA:
		_terminar(id)
	return Resultado.NOVO


## Aplica um ROOM_REJECT. Devolve true só na primeira vez.
func aplicar_recusa(intent_id: String, motivo: String) -> bool:
	if not _itens.has(intent_id):
		return false
	var item: Dictionary = _itens[intent_id]
	if item["estado"] == APLICADA or item["estado"] == RECUSADA:
		return false
	item["estado"] = RECUSADA
	item["motivo"] = motivo
	_terminar(intent_id)
	return true


## A ligação caiu: o que estava ENVIADA passa a DESCONHECIDA.
func marcar_desconhecidas() -> int:
	var n := 0
	for id in _itens:
		if _itens[id]["estado"] == ENVIADA:
			_itens[id]["estado"] = DESCONHECIDA
			n += 1
	return n


## Ids a perguntar com RECEIPT_QUERY ao religar.
func ids_para_consulta() -> Array:
	var ids: Array = []
	for id in _itens:
		var e: String = _itens[id]["estado"]
		if e == DESCONHECIDA or e == AGUARDANDO_MESTRE:
			ids.append(id)
	return ids


func tem_em_voo() -> bool:
	var agora := Time.get_ticks_msec()
	for id in _itens:
		var item: Dictionary = _itens[id]
		if item["estado"] == ENVIADA and agora - int(item["criada_ms"]) < EM_VOO_MAX_MS:
			return true
	return false


func aguardando_mestre() -> bool:
	for id in _itens:
		if _itens[id]["estado"] == AGUARDANDO_MESTRE:
			return true
	return false


## Só o que não terminou; nada secreto (o seatToken nunca entra aqui).
func para_guardar() -> Array:
	var lista: Array = []
	for id in _itens:
		var item: Dictionary = _itens[id]
		var e: String = item["estado"]
		if e == ENVIADA or e == DESCONHECIDA or e == AGUARDANDO_MESTRE:
			lista.append({"id": id, "estado": e, "texto": item["texto"]})
	return lista


## Ao reabrir o app, tudo o que estava em voo vira DESCONHECIDA.
func carregar(lista: Array) -> void:
	for e in lista:
		if not (e is Dictionary) or not (e.get("id") is String) or not (e.get("texto") is String):
			continue
		registar(e["id"], e["texto"])
		var est = e.get("estado")
		_itens[e["id"]]["estado"] = AGUARDANDO_MESTRE if est == AGUARDANDO_MESTRE else DESCONHECIDA


func limpar() -> void:
	_itens.clear()
	_terminadas.clear()


func _terminar(id: String) -> void:
	_itens[id]["texto"] = ""
	_terminadas.append(id)
	while _terminadas.size() > MAX_TERMINADAS:
		var velho = _terminadas.pop_front()
		_itens.erase(velho)


static func _int(v) -> int:
	if v is int:
		return v
	if v is float:
		return int(v)
	if v is String and v.is_valid_int():
		return v.to_int()
	return 0
