extends Node
## Autoload "Estado": espelho do que o servidor projeta para ESTE lugar.
##
## ALINHADO AO SERVIDOR REAL (rascunhos/servidor/nucleo/projecao.js e sala.js):
##   ROOM_SNAPSHOT = {seq, revision, ts, fase, mapa{largura,altura,casaM},
##                    figuras[{id,nomePublico,lado,x,y,orientacao,visivel}],
##                    iniciativa[ids por ordem], vezId, rodada, ambiente{clima,luz},
##                    propria{figuraId,vidaActual,vidaTotal,paLivre,paTotal,estadoMorte,...} (só a jogadora),
##                    mestre{...} (só o Mestre)}
##   ROOM_EVENT    = {seq, revision, ts, tipo, dados} com os campos de CAMPOS_PERMITIDOS.
##
## - Aplica ROOM_EVENT pela ordem do `seq` (fluxo por destinatário, errata E-P4).
## - Evento repetido (seq já aplicado) é descartado.
## - Evento adiantado fica em espera; o buraco faz pedir ROOM_RESYNC (E-C7).
## - ROOM_SNAPSHOT substitui tudo até ao seu `seq` (E-C8).
## - `revision` é um contador por lugar que SÓ SOBE (sala.js atualizarRevisoes). Guarda-se a
##   maior vista; ROOM_OPTIONS só vale se foi feito para essa revisão (E-C5).
## - NÃO calcula regra. Só guarda e devolve o que o servidor mandou.

signal snapshot_aplicado
signal evento_aplicado(evento: Dictionary)
signal opcoes_mudaram
signal resync_necessario(ultimo_seq: int)
signal dano_visto(alvo_id: String, valor: Variant, tipo_dano: String, em_mim: bool)
signal pausa_mudou(pausada: bool)
signal fase_mudou(fase: String)
signal ataque_visto(dados: Dictionary)
## Frase de batalha do site (desgraça, relógio de morte, fim), já pronta para mostrar.
signal frase_batalha(texto: String)

## Se o RESYNC não fechar o buraco neste tempo, pede outra vez.
const Frases := preload("res://hud/frases_batalha.gd")
const REPETIR_RESYNC_S := 5.0
## Acima disto não se guarda mais: o RESYNC traz o resto.
const MAX_EM_ESPERA := 512

var tem_snapshot := false
var ultimo_seq := 0
var revisao: Variant = null
var fase := ""  # lobby | combate | fim (a pausa vai à parte, em `pausada`)
var rodada := 0
var desfecho := ""
var mapa: Dictionary = {}
var figuras: Dictionary = {}  # id -> {id, nomePublico, lado, x, y, orientacao, visivel}
var iniciativa: Array = []  # só a ORDEM (a Party nunca vê os valores)
var ambiente: Dictionary = {}  # só o efeito presente {clima, luz} (E-P12)
## Ordem 13: o fogo que a mesa vê — {casas: [{x,y}], aArder: [ids]} (sem combustível: esse é só do Mestre).
var fogo: Dictionary = {}
var vez_id := ""
var opcoes: Dictionary = {}
var seat_id := ""
var minha_figura_id := ""
## Só a própria jogadora: vida, PA e ficha DELA (projecao.js `propria`).
var propria: Dictionary = {}
## Só o Mestre: o bloco `mestre` do snapshot (figuras não colocadas, lobby, vez, cartões).
var mestre: Dictionary = {}
var pausada := false

var _espera: Dictionary = {}  # seq -> mensagem
var _resync_pendente := false
var _tempo_resync := 0.0
var _arma_de: Dictionary = {}  # figuraId -> id da técnica do último `ataque` (para a frase da desgraça)
var _teste_morte_pendente := false  # houve `teste_morte` DELA: o `estado` seguinte diz se aguentou


func _ready() -> void:
	var rede = get_node_or_null("/root/Rede")
	if rede == null:
		return
	rede.snapshot_recebido.connect(aplicar_snapshot)
	rede.evento_recebido.connect(receber_evento)
	rede.opcoes_recebidas.connect(receber_opcoes)
	rede.boas_vindas_recebidas.connect(_ao_boas_vindas)
	rede.sala_pausada.connect(_ao_pausar)
	rede.sala_retomada.connect(_ao_retomar)
	rede.revisao_vista.connect(ver_revisao)
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
	var fase_antes := fase
	tem_snapshot = true
	ultimo_seq = s
	if msg.has("revision"):
		_subir_revisao(msg["revision"])
	rodada = _int(msg.get("rodada"))
	var f_bruta := _texto(msg.get("fase"))
	if f_bruta == "pausa":
		# DIVERGÊNCIA: em pausa o snapshot traz fase "pausa" e perde a fase de antes
		# (projecao.js usa mundo.fase; sala.js guarda pausa.faseAnterior só para o Mestre).
		# O cliente não inventa: a rodada só passa de 0 no MASTER_START, logo rodada > 0 = combate.
		# Sugestão para o servidor: projetar `faseAnterior` (ou `pausada: true`) no snapshot.
		fase = "combate" if rodada > 0 else "lobby"
		_definir_pausa(true)
	else:
		fase = f_bruta
		_definir_pausa(false)
	mapa = _dict(msg.get("mapa"))
	figuras = {}
	var lista = msg.get("figuras")
	if lista is Array:
		for f in lista:
			if f is Dictionary and f.get("id") is String:
				figuras[f["id"]] = f.duplicate(true)
	var ini = msg.get("iniciativa")
	iniciativa = ini.duplicate() if ini is Array else []
	vez_id = _texto(msg.get("vezId"))
	ambiente = _dict(msg.get("ambiente")).duplicate(true)
	fogo = _dict(msg.get("fogo")).duplicate(true)
	propria = _dict(msg.get("propria")).duplicate(true)
	var mf = propria.get("figuraId")
	if mf is String and mf != "":
		minha_figura_id = mf
	# Privacidade (desenho JV3.1 §7): o bloco do Mestre só se guarda no lugar do Mestre. O servidor nunca o
	# manda à Party; isto é a segunda tranca, provada por testes/canario_privacidade.gd.
	mestre = _dict(msg.get("mestre")).duplicate(true) if _no_lugar_do_mestre() else {}
	if fase != "fim":
		desfecho = ""  # DIVERGÊNCIA menor: o snapshot não projeta o `desfecho` (só o evento `fim`)
	for k in _espera.keys():
		if int(k) <= s:
			_espera.erase(k)
	_resync_pendente = false
	_tempo_resync = 0.0
	snapshot_aplicado.emit()
	if fase != fase_antes:
		fase_mudou.emit(fase)
	_drenar()
	if not _espera.is_empty():
		_pedir_resync()  # ainda há buraco depois do snapshot
	opcoes_mudaram.emit()


## O papel vem da Rede pela árvore (e não pelo identificador do autoload), para este script continuar a
## compilar nos testes que o carregam antes de os autoloads existirem (testes/rodar_testes.gd).
func _no_lugar_do_mestre() -> bool:
	if not is_inside_tree():
		return false
	var rede = get_node_or_null("/root/Rede")
	return rede != null and rede.papel == "mestre"


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


## ROOM_OPTIONS {revision, vezId, orcamentoM, mover[], ataques[], consumiveis[], acoes[], reacoes[]}.
func receber_opcoes(msg: Dictionary) -> void:
	var r = _num(msg.get("revision"))
	if _e_numero(r) and revisao != null and float(r) < float(revisao):
		return  # feitas para uma revisão já passada
	opcoes = msg.duplicate(true)
	if _e_numero(r):
		_subir_revisao(r)
	opcoes_mudaram.emit()


## Uma revisão vista fora de eventos (ex.: no ROOM_RECEIPT). Só conta se for maior.
## Caso real: com um cartão aberto ou em pausa, a revisão dela sobe sem ROOM_EVENT nenhum.
func ver_revisao(r) -> void:
	if _subir_revisao(r):
		opcoes_mudaram.emit()


func limpar() -> void:
	tem_snapshot = false
	ultimo_seq = 0
	revisao = null
	fase = ""
	rodada = 0
	desfecho = ""
	mapa = {}
	figuras = {}
	iniciativa = []
	ambiente = {}
	fogo = {}
	vez_id = ""
	opcoes = {}
	seat_id = ""
	minha_figura_id = ""
	propria = {}
	mestre = {}
	_arma_de.clear()
	_teste_morte_pendente = false
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


## `acoes` do ROOM_OPTIONS (encerrar, correr, defender, desvincular, transformar).
func tem_acao(tipo: String) -> bool:
	return lista_opcao("acoes").has(tipo)


## Orçamento de movimento em metros, como o servidor o mandou; -1 se não veio.
func orcamento_m() -> float:
	var o = opcoes_validas().get("orcamentoM")
	return float(o) if _e_numero(o) else -1.0


func e_minha_vez() -> bool:
	return minha_figura_id != "" and vez_id == minha_figura_id


func casa_de(f) -> Vector2i:
	if not (f is Dictionary):
		return Vector2i(-1, -1)
	if _e_numero(f.get("x")) and _e_numero(f.get("y")):
		return Vector2i(_int(f["x"]), _int(f["y"]))
	return Vector2i(-1, -1)


## A figura visível nesta casa (prefere uma que não esteja morta).
func figura_na_casa(c: Vector2i) -> String:
	var morta := ""
	for id in figuras:
		var f: Dictionary = figuras[id]
		if casa_de(f) != c:
			continue
		if _texto(f.get("visivel")) == "morta":
			morta = id
			continue
		return id
	return morta


func e_jogadora(f) -> bool:
	if not (f is Dictionary):
		return false
	return _texto(f.get("lado")) == "jogadora"


## Nome legível de uma técnica a partir do id que o servidor manda («chicote-teste» → «chicote teste»).
static func arma_legivel(id: String) -> String:
	return id.replace("-", " ").replace("_", " ").strip_edges()


## Relógio de morte DELA (frases do site): cair, aguentar-se, piorar.
func _frase_relogio_morte(antes, depois) -> void:
	if not (depois is Dictionary):
		return
	var nome := nome_de(minha_figura_id)
	var estava := antes is Dictionary and _texto(antes.get("fase")) != ""
	if _teste_morte_pendente:
		_teste_morte_pendente = false
		var suc_antes := _int(antes.get("sucessos")) if antes is Dictionary else 0
		var fal_antes := _int(antes.get("falhas")) if antes is Dictionary else 0
		if _texto(depois.get("fase")) == "estabilizado":
			frase_batalha.emit(Frases.estabilizou(nome))  # Q4 (REF_31): estabilizou, a batalha continua
		elif _int(depois.get("sucessos")) > suc_antes:
			frase_batalha.emit(Frases.aguenta(nome))
		elif _int(depois.get("falhas")) > fal_antes:
			frase_batalha.emit(Frases.piora(nome))
	elif _texto(depois.get("fase")) == "aMorrer" and not estava:
		frase_batalha.emit(Frases.caiu(nome))


## Frases de fim do site. A cláusula «Aperte Recomeçar…» só entra quando o botão existir.
func _frase_fim(d: String) -> void:
	var nome := nome_de(minha_figura_id)
	if d == "vitoria":
		frase_batalha.emit(Frases.fim_vitoria(nome))
	elif d == "terminada":
		frase_batalha.emit(Frases.fim_terminada())  # N4: o Mestre terminou a batalha (a todos)
	elif minha_figura_id == "":
		return
	elif d == "morte":
		frase_batalha.emit(Frases.fim_morte(nome))
	# Q4 (decisão 4 do Mestre; site REF_31): o servidor já não manda o desfecho «estabilizada».


## Nome que a Party pode ver (o servidor já o projeta: "Criatura", "Personagem" ou o público).
func nome_de(id: String) -> String:
	var f = figuras.get(id)
	if f is Dictionary:
		return _texto(f.get("nomePublico"))
	return ""


## Fração da vida DELA (só a própria vem projetada). -1 se o servidor não mandou.
## Não é regra: é só dividir dois números que o servidor já deu, para a tela vermelha.
func vida_fracao_propria() -> float:
	var vida = propria.get("vidaActual")
	var total = propria.get("vidaTotal")
	if _e_numero(vida) and _e_numero(total) and float(total) > 0.0:
		return clampf(float(vida) / float(total), 0.0, 1.0)
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
		rev_mudou = _subir_revisao(msg["revision"])
	var tipo := _texto(msg.get("tipo"))
	var dados := _dict(msg.get("dados"))
	var fid := _texto(dados.get("figuraId"))
	var fase_antes := fase

	match tipo:
		"colocacao":
			# {figuraId, nomePublico, lado, x, y, orientacao, visivel}: a figura passa a existir.
			if fid != "":
				figuras[fid] = {
					"id": fid, "nomePublico": dados.get("nomePublico"), "lado": dados.get("lado"),
					"x": dados.get("x"), "y": dados.get("y"),
					"orientacao": dados.get("orientacao"), "visivel": dados.get("visivel"),
				}
		"turno":
			# {figuraId, rodada, narra}. O servidor só emite `turno` em combate: o MASTER_START
			# não manda snapshot novo (sala.js), por isso é o primeiro `turno` que tira do lobby.
			vez_id = fid
			if _e_numero(dados.get("rodada")):
				rodada = _int(dados["rodada"])
			if fase == "lobby" or fase == "":
				fase = "combate"
		"movimento":
			# {figuraId, de, para, caminho} (+ custoM, reservaM se for ela).
			var para = dados.get("para")
			if figuras.has(fid) and para is Dictionary:
				figuras[fid]["x"] = para.get("x")
				figuras[fid]["y"] = para.get("y")
			if fid != "" and fid == minha_figura_id and dados.has("reservaM"):
				propria["reservaM"] = dados["reservaM"]
		"estado":
			# {figuraId, visivel} (+ vidaActual, paLivre, estadoMorte se for ela).
			var v = dados.get("visivel")
			if figuras.has(fid) and v is String:
				figuras[fid]["visivel"] = v
			if fid != "" and fid == minha_figura_id:
				if dados.has("estadoMorte"):
					_frase_relogio_morte(propria.get("estadoMorte"), dados["estadoMorte"])
				# Q8 / site: a arma estava no chão e deixou de estar → ela apanhou-a (frase do site).
				if propria.get("armaCaida") == true and dados.get("armaCaida") == false:
					frase_batalha.emit(Frases.apanhou_arma(nome_de(fid), arma_legivel(_texto(_arma_de.get(fid, "")))))
				for k in ["vidaActual", "paLivre", "estadoMorte", "armaCaida", "armaQuebrada", "corpoPartido"]:
					if dados.has(k):
						propria[k] = dados[k]
		"ataque":
			# {atacanteId, alvoId, arma, resultado, ataqueDeOportunidade} (+ total, faces, expressao se for dela).
			if dados.get("arma") is String:
				_arma_de[_texto(dados.get("atacanteId"))] = dados["arma"]
			ataque_visto.emit(dados)
		"dano":
			_emitir_dano(dados)
		"raio":
			# Ordem 13: {x, y, alvoId?, desfecho?}. A queda dela a morrer narra-se pelo `estado` (frase da queda).
			var alvo_raio := _texto(dados.get("alvoId"))
			if alvo_raio == "":
				frase_batalha.emit(Frases.raio_na_arena())
			elif _texto(dados.get("desfecho")) != "aMorrer":
				frase_batalha.emit(Frases.raio_atinge(nome_de(alvo_raio), e_jogadora(figuras.get(alvo_raio)), _texto(dados.get("desfecho"))))
		"dano_ambiente":
			# {alvoId, origem, desfecho} (+ valor e tipos só a quem o sofreu): o número sai como o de qualquer dano.
			_emitir_dano(dados)
			var quem_amb := _texto(dados.get("alvoId"))
			if _texto(dados.get("origem")) == "fogo" and _texto(dados.get("desfecho")) != "aMorrer":
				frase_batalha.emit(Frases.fogo_morde(nome_de(quem_amb), e_jogadora(figuras.get(quem_amb)), _texto(dados.get("desfecho"))))
		"fogo":
			# {casas, aArder, apagados?}: o fogo novo, por inteiro.
			fogo = {"casas": _lista(dados.get("casas")), "aArder": _lista(dados.get("aArder"))}
			for apagado in _lista(dados.get("apagados")):
				if apagado is Dictionary:
					var fa := _texto(apagado.get("figuraId"))
					frase_batalha.emit(Frases.fogo_apagado(nome_de(fa), e_jogadora(figuras.get(fa)), _texto(apagado.get("porque"))))
		"ambiente":
			var efeito = dados.get("efeito")
			if efeito is Dictionary:
				ambiente = efeito.duplicate(true)
		"fim":
			fase = "fim"
			desfecho = _texto(dados.get("desfecho"))
			vez_id = ""
			_frase_fim(desfecho)
		"desgraca":
			# {figuraId, efeito} a todos (+ perdeQuarto só à própria, REF_19). Frase igual à do site.
			var quem = figuras.get(fid)
			var frase: String = Frases.desgraca(_texto(dados.get("efeito")), nome_de(fid), e_jogadora(quem),
					arma_legivel(_texto(_arma_de.get(fid, ""))), dados.get("perdeQuarto") == true)
			frase_batalha.emit(Frases.com_cabecalho(frase))
		"teste_morte":
			# {figuraId}: a Party só sabe QUE houve teste. Se é dela, o `estado` que vem a seguir traz o
			# estadoMorte novo, e é aí que se escolhe «aguenta-se» ou «piora».
			if fid != "" and fid == minha_figura_id:
				_teste_morte_pendente = true
		_:
			pass  # entrada, reacao, consumivel, revertido (o snapshot vem a seguir)

	evento_aplicado.emit(msg)
	if fase != fase_antes:
		fase_mudou.emit(fase)
	if rev_mudou:
		opcoes_mudaram.emit()


## Servidor real: {alvoId, autorId} (+ valor, tipos só a quem causou ou recebeu, v0.2.1).
## DIVERGÊNCIA: o Mestre aprovou "números de dano por tipo", mas o servidor manda UM `valor`
## (o total) e a lista `tipos` da técnica. O cliente mostra um número, com a cor do 1.º tipo.
## Se o servidor passar a mandar `partes` [{tipo, valor}], sai um número por tipo.
func _emitir_dano(dados: Dictionary) -> void:
	var alvo := _texto(dados.get("alvoId"))
	var em_mim := alvo != "" and alvo == minha_figura_id
	var partes = dados.get("partes")
	if partes is Array:
		for p in partes:
			if p is Dictionary and p.get("valor") != null:
				dano_visto.emit(alvo, p["valor"], _texto(p.get("tipo")), em_mim)
		return
	if dados.get("valor") == null:
		return  # outra jogadora ou espectador: o servidor não mandou o número
	var tipo := ""
	var tipos = dados.get("tipos")
	if tipos is Array and not tipos.is_empty() and tipos[0] is String:
		tipo = tipos[0]
	dano_visto.emit(alvo, dados["valor"], tipo, em_mim)


## A revisão só sobe. Devolve true se mudou.
func _subir_revisao(r) -> bool:
	var n = _num(r)
	if not _e_numero(n):
		return false
	if revisao == null or float(n) > float(revisao):
		revisao = n
		return true
	return false


func _ao_boas_vindas(msg: Dictionary) -> void:
	seat_id = _texto(msg.get("seatId"))


func _ao_pausar(_motivo: String) -> void:
	_definir_pausa(true)


func _ao_retomar() -> void:
	_definir_pausa(false)


func _definir_pausa(p: bool) -> void:
	if p == pausada:
		return
	pausada = p
	pausa_mudou.emit(p)


static func _e_numero(v) -> bool:
	return v is int or v is float


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


static func _lista(v) -> Array:
	return (v as Array).duplicate(true) if v is Array else []


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
