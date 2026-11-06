extends Node
## Autoload "Estado": espelho do que o servidor projeta para ESTE lugar.
##
## - Aplica ROOM_EVENT pela ordem do `seq` (fluxo por destinatário, errata E-P4).
## - Evento repetido (seq já aplicado) é descartado.
## - Evento adiantado fica em espera; o buraco faz pedir ROOM_RESYNC (E-C7).
## - ROOM_SNAPSHOT substitui tudo até ao seu `seq` (E-C8).
## - ROOM_OPTIONS só vale na revisão em que foi feito (E-C5).
## - NÃO calcula regra. Só guarda e devolve o que o servidor mandou.
##
## Nomes de campos marcados (PROVISÓRIO) esperam a conferência A-1 contra o TEST34–36.

signal snapshot_aplicado
signal evento_aplicado(evento: Dictionary)
signal opcoes_mudaram
signal resync_necessario(ultimo_seq: int)
signal dano_visto(alvo_id: String, valor: Variant, tipo_dano: String, em_mim: bool)
signal pausa_mudou(pausada: bool)

## Se o RESYNC não fechar o buraco neste tempo, pede outra vez.
const REPETIR_RESYNC_S := 5.0
## Acima disto não se guarda mais: o RESYNC traz o resto.
const MAX_EM_ESPERA := 512

var tem_snapshot := false
var ultimo_seq := 0
var revisao: Variant = null
var fase := ""
var mapa: Dictionary = {}
var figuras: Dictionary = {}  # id -> Dictionary (como o servidor projetou)
var iniciativa: Variant = null
var ambiente: Dictionary = {}
var vez_id := ""
var opcoes: Dictionary = {}
var seat_id := ""
var minha_figura_id := ""
var pausada := false

var _espera: Dictionary = {}  # seq -> mensagem
var _resync_pendente := false
var _tempo_resync := 0.0


func _ready() -> void:
	var rede = get_node_or_null("/root/Rede")
	if rede == null:
		return
	rede.snapshot_recebido.connect(aplicar_snapshot)
	rede.evento_recebido.connect(receber_evento)
	rede.opcoes_recebidas.connect(receber_opcoes)
	rede.boas_vindas_recebidas.connect(_ao_boas_vindas)
	rede.sala_pausada.connect(func(_motivo): _definir_pausa(true))
	rede.sala_retomada.connect(func(): _definir_pausa(false))
	resync_necessario.connect(rede.enviar_resync)


func _process(delta: float) -> void:
	if not _resync_pendente:
		return
	_tempo_resync += delta
	if _tempo_resync >= REPETIR_RESYNC_S:
		_tempo_resync = 0.0
		resync_necessario.emit(ultimo_seq)


# ---------------------------------------------------------------- entrada

func aplicar_snapshot(msg: Dictionary) -> void:
	var s := _int(msg.get("seq"))
	if tem_snapshot and s < ultimo_seq:
		return  # snapshot mais velho do que o que já temos
	tem_snapshot = true
	ultimo_seq = s
	if msg.has("revision"):
		revisao = _num(msg["revision"])
	fase = _texto(msg.get("fase"))
	_definir_pausa(fase == "pausa")
	mapa = _dict(msg.get("mapa"))
	figuras = {}
	var lista = msg.get("figuras")
	if lista is Array:
		for f in lista:
			if f is Dictionary and f.get("id") is String:
				figuras[f["id"]] = f.duplicate(true)
	iniciativa = msg.get("iniciativa")
	vez_id = _vez_da_iniciativa(iniciativa)
	ambiente = _dict(msg.get("ambiente"))
	var mf = msg.get("minhaFiguraId")  # PROVISÓRIO
	if mf is String and mf != "":
		minha_figura_id = mf
	else:
		_deduzir_minha_figura()
	for k in _espera.keys():
		if int(k) <= s:
			_espera.erase(k)
	_resync_pendente = false
	_tempo_resync = 0.0
	snapshot_aplicado.emit()
	_drenar()
	if not _espera.is_empty():
		_pedir_resync()  # ainda há buraco depois do snapshot
	opcoes_mudaram.emit()


func receber_evento(msg: Dictionary) -> void:
	var s := _int(msg.get("seq"))
	if s <= 0:
		return
	if not tem_snapshot:
		_guardar(s, msg)  # o JOIN traz o snapshot; até lá, espera
		return
	if s <= ultimo_seq or _espera.has(s):
		return  # repetido
	if s == ultimo_seq + 1:
		_aplicar_evento(msg)
		_drenar()
	else:
		_guardar(s, msg)
		_pedir_resync()


func receber_opcoes(msg: Dictionary) -> void:
	opcoes = msg.duplicate(true)
	opcoes_mudaram.emit()


func limpar() -> void:
	tem_snapshot = false
	ultimo_seq = 0
	revisao = null
	fase = ""
	mapa = {}
	figuras = {}
	iniciativa = null
	ambiente = {}
	vez_id = ""
	opcoes = {}
	seat_id = ""
	minha_figura_id = ""
	_espera.clear()
	_resync_pendente = false
	_definir_pausa(false)
	snapshot_aplicado.emit()
	opcoes_mudaram.emit()


# ---------------------------------------------------------------- consultas (sem regra)

func resync_pendente() -> bool:
	return _resync_pendente


func em_espera() -> int:
	return _espera.size()


## As ROOM_OPTIONS só se as fez o servidor para a revisão corrente; senão {}.
func opcoes_validas() -> Dictionary:
	if opcoes.is_empty() or not tem_snapshot:
		return {}
	if revisao == null:
		return opcoes  # servidor sem revisão: confia no último ROOM_OPTIONS
	if _iguais(_num(opcoes.get("revision")), revisao):
		return opcoes
	return {}


func lista_opcao(chave: String) -> Array:
	var v = opcoes_validas().get(chave)
	return v if v is Array else []


func e_minha_vez() -> bool:
	return minha_figura_id != "" and vez_id == minha_figura_id


func casa_de(f) -> Vector2i:
	if not (f is Dictionary):
		return Vector2i(-1, -1)
	if f.get("x") != null and f.get("y") != null:
		return Vector2i(_int(f["x"]), _int(f["y"]))
	var c = f.get("casa")  # PROVISÓRIO: {x,y}
	if c is Dictionary and c.get("x") != null and c.get("y") != null:
		return Vector2i(_int(c["x"]), _int(c["y"]))
	return Vector2i(-1, -1)


## A figura visível nesta casa (prefere uma que não esteja morta).
func figura_na_casa(c: Vector2i) -> String:
	var morta := ""
	for id in figuras:
		var f: Dictionary = figuras[id]
		if casa_de(f) != c:
			continue
		if _texto(f.get("estado")) == "morta":
			morta = id
			continue
		return id
	return morta


func e_jogadora(f) -> bool:
	if not (f is Dictionary):
		return false
	return f.get("jogadora") == true or _texto(f.get("seatId")) != "" or _texto(f.get("lado")) == "jogadora"


func nome_de(id: String) -> String:
	var f = figuras.get(id)
	if f is Dictionary:
		return _texto(f.get("nome"))
	return ""


## Fração da vida DELA (só a própria vem projetada). -1 se o servidor não mandou.
## Não é regra: é só dividir dois números que o servidor já deu, para a tela vermelha.
func vida_fracao_propria() -> float:
	var f = figuras.get(minha_figura_id)
	if not (f is Dictionary):
		return -1.0
	var fr = f.get("vidaFracao")  # PROVISÓRIO
	if fr is float or fr is int:
		return clampf(float(fr), 0.0, 1.0)
	var vida = f.get("vida")  # PROVISÓRIO
	var maximo = f.get("vidaMax")  # PROVISÓRIO
	if (vida is float or vida is int) and (maximo is float or maximo is int) and float(maximo) > 0.0:
		return clampf(float(vida) / float(maximo), 0.0, 1.0)
	return -1.0


# ---------------------------------------------------------------- interno

func _guardar(s: int, msg: Dictionary) -> void:
	if _espera.size() < MAX_EM_ESPERA:
		_espera[s] = msg


func _pedir_resync() -> void:
	if _resync_pendente:
		return
	_resync_pendente = true
	_tempo_resync = 0.0
	resync_necessario.emit(ultimo_seq)


func _drenar() -> void:
	while _espera.has(ultimo_seq + 1):
		var m: Dictionary = _espera[ultimo_seq + 1]
		_espera.erase(ultimo_seq + 1)
		_aplicar_evento(m)
	for k in _espera.keys():
		if int(k) <= ultimo_seq:
			_espera.erase(k)
	if _espera.is_empty():
		_resync_pendente = false
		_tempo_resync = 0.0


func _aplicar_evento(msg: Dictionary) -> void:
	ultimo_seq = _int(msg.get("seq"))
	var rev_mudou := false
	if msg.has("revision"):
		var r = _num(msg["revision"])
		rev_mudou = not _iguais(r, revisao)
		revisao = r
	var tipo := _texto(msg.get("tipo"))
	var dados := _dict(msg.get("dados"))

	# Remendos genéricos de figura: o servidor diz o que mudou, o cliente copia.
	if dados.get("figura") is Dictionary:
		_remendar_figura(dados["figura"])
	var varias = dados.get("figuras")
	if varias is Array:
		for p in varias:
			if p is Dictionary:
				_remendar_figura(p)

	match tipo:
		"movimento":
			var fid := _texto(dados.get("figuraId"))
			var para = dados.get("para", dados.get("destino"))  # PROVISÓRIO
			if figuras.has(fid) and para is Dictionary:
				figuras[fid]["x"] = para.get("x")
				figuras[fid]["y"] = para.get("y")
		"estado":
			var fid := _texto(dados.get("figuraId"))
			var e = dados.get("estado")
			if figuras.has(fid) and e is String:
				figuras[fid]["estado"] = e
		"turno":
			vez_id = _texto(dados.get("vezId", dados.get("figuraId")))
		"dano":
			_emitir_dano(dados)
		"ambiente":
			ambiente.merge(dados, true)
		"fim":
			fase = "fim"
		_:
			pass  # entrada, colocacao, ataque, reacao, consumivel, desgraca, revertido: só remendos

	if minha_figura_id == "":
		_deduzir_minha_figura()
	evento_aplicado.emit(msg)
	if rev_mudou:
		opcoes_mudaram.emit()


func _emitir_dano(dados: Dictionary) -> void:
	var alvo := _texto(dados.get("alvoId"))
	var em_mim := alvo != "" and alvo == minha_figura_id
	var partes = dados.get("partes")  # PROVISÓRIO: [{tipo, valor}] um número por tipo
	if partes is Array:
		for p in partes:
			if p is Dictionary and p.get("valor") != null:
				dano_visto.emit(alvo, p["valor"], _texto(p.get("tipo")), em_mim)
		return
	if dados.get("valor") != null:  # só chega se ela pode ver (projeção do servidor)
		dano_visto.emit(alvo, dados["valor"], _texto(dados.get("tipoDano")), em_mim)


func _remendar_figura(p: Dictionary) -> void:
	var id := _texto(p.get("id"))
	if id == "":
		return
	if figuras.has(id):
		figuras[id].merge(p.duplicate(true), true)
	else:
		figuras[id] = p.duplicate(true)


func _deduzir_minha_figura() -> void:
	if seat_id == "":
		return
	for id in figuras:
		if _texto(figuras[id].get("seatId")) == seat_id:
			minha_figura_id = id
			return


func _vez_da_iniciativa(ini) -> String:
	if ini is Dictionary:
		for k in ["vezId", "vez", "figuraId"]:  # PROVISÓRIO
			var v = ini.get(k)
			if v is String:
				return v
	return ""


func _ao_boas_vindas(msg: Dictionary) -> void:
	seat_id = _texto(msg.get("seatId"))
	var fid := _texto(msg.get("figuraId"))  # PROVISÓRIO
	if fid != "":
		minha_figura_id = fid
	else:
		_deduzir_minha_figura()


func _definir_pausa(p: bool) -> void:
	if p == pausada:
		return
	pausada = p
	pausa_mudou.emit(p)


static func _int(v) -> int:
	if v is int:
		return v
	if v is float:
		return int(v)
	if v is String and v.is_valid_int():
		return v.to_int()
	return 0


static func _num(v):
	if v is float and v == floorf(v):
		return int(v)
	return v


static func _texto(v) -> String:
	return v if v is String else ""


static func _dict(v) -> Dictionary:
	return v if v is Dictionary else {}


static func _iguais(a, b) -> bool:
	var a_num := a is int or a is float
	var b_num := b is int or b is float
	if a_num and b_num:
		return float(a) == float(b)
	if typeof(a) != typeof(b):
		return false
	return a == b
