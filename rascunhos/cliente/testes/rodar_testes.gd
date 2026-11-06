extends SceneTree
## Testes sem tela (runner próprio, sem GUT).
##
##   godot --headless --path cliente -s res://testes/rodar_testes.gd
##
## Sai com código 0 se tudo passa e 1 se algo falha (serve ao CI da JV0.2).
## NAC-OV-05: NÃO rodar no PCDANASA.

const EstadoScript := preload("res://estado/estado.gd")
const RedeScript := preload("res://rede/rede.gd")
const FilaIntencoes := preload("res://rede/fila_intencoes.gd")
const Uuid := preload("res://rede/uuid.gd")

var _total := 0
var _falhas := 0


func _initialize() -> void:
	print("== Testes do cliente (JV2.1a) ==")
	_teste_buraco_pede_resync()
	_teste_evento_repetido_ignorado()
	_teste_snapshot_substitui_espera()
	_teste_eventos_antes_do_snapshot()
	_teste_opcoes_so_na_revisao()
	_teste_dano_so_o_que_vem()
	_teste_recibo_duplicado_ignorado_na_fila()
	_teste_recibo_duplicado_ignorado_na_rede()
	_teste_recibo_alheio_ignorado()
	_teste_desconhecida_reenvia_uma_vez()
	_teste_queda_marca_desconhecida()
	_teste_recusa_duplicada_ignorada()
	_teste_uuid_v4()
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)


# ---------------------------------------------------------------- ajudas

func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		printerr("  FALHA ", nome)


func _snapshot(seq: int, rev: int) -> Dictionary:
	return {
		"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "sala-teste", "seq": seq, "revision": rev,
		"fase": "combate", "mapa": {"largura": 20, "altura": 20},
		"figuras": [{"id": "fA", "nome": "Ong", "x": 1, "y": 1, "seatId": "s1"}],
		"iniciativa": {"vezId": "fA"}, "ambiente": {}
	}


func _evento(seq: int, rev: int = -1, tipo: String = "turno", dados: Dictionary = {}) -> Dictionary:
	var m := {"v": 2, "type": "ROOM_EVENT", "roomId": "sala-teste", "seq": seq, "tipo": tipo, "dados": dados}
	if rev >= 0:
		m["revision"] = rev
	return m


# ---------------------------------------------------------------- Estado

func _teste_buraco_pede_resync() -> void:
	print("Sequência com buraco:")
	var est = EstadoScript.new()
	var pedidos: Array = []
	est.resync_necessario.connect(func(s): pedidos.append(s))
	est.aplicar_snapshot(_snapshot(10, 1))
	est.receber_evento(_evento(11, -1, "movimento", {"figuraId": "fA", "para": {"x": 2, "y": 3}}))
	_ok(est.ultimo_seq == 11, "o 11 aplica logo")
	_ok(est.casa_de(est.figuras["fA"]) == Vector2i(2, 3), "o movimento copia a casa que o servidor disse")
	est.receber_evento(_evento(13))
	_ok(est.ultimo_seq == 11, "o 13 fica em espera (falta o 12)")
	_ok(pedidos.size() == 1 and pedidos[0] == 11, "o buraco pede ROOM_RESYNC com lastSeq 11")
	est.receber_evento(_evento(14))
	_ok(pedidos.size() == 1, "um só pedido enquanto o mesmo buraco existe")
	est.receber_evento(_evento(12))
	_ok(est.ultimo_seq == 14, "o 12 fecha o buraco e aplica 13 e 14 por ordem")
	_ok(not est.resync_pendente() and est.em_espera() == 0, "sem buraco, sem pedido pendente")
	est.free()


func _teste_evento_repetido_ignorado() -> void:
	print("Evento repetido:")
	var est = EstadoScript.new()
	var aplicados: Array = []
	est.evento_aplicado.connect(func(e): aplicados.append(int(e["seq"])))
	est.aplicar_snapshot(_snapshot(5, 1))
	est.receber_evento(_evento(6))
	est.receber_evento(_evento(6))
	est.receber_evento(_evento(4))
	_ok(aplicados == [6], "o 6 repetido e o 4 velho são descartados")
	est.free()


func _teste_snapshot_substitui_espera() -> void:
	print("Snapshot no RESYNC:")
	var est = EstadoScript.new()
	est.aplicar_snapshot(_snapshot(10, 1))
	est.receber_evento(_evento(15))
	est.receber_evento(_evento(21))
	_ok(est.em_espera() == 2, "15 e 21 em espera")
	est.aplicar_snapshot(_snapshot(20, 7))
	_ok(est.ultimo_seq == 21, "o snapshot 20 substitui tudo até 20 e o 21 aplica a seguir")
	_ok(est.em_espera() == 0 and not est.resync_pendente(), "espera limpa")
	est.aplicar_snapshot(_snapshot(18, 6))
	_ok(est.ultimo_seq == 21, "um snapshot mais velho é ignorado")
	est.free()


func _teste_eventos_antes_do_snapshot() -> void:
	print("Eventos antes do snapshot:")
	var est = EstadoScript.new()
	est.receber_evento(_evento(3))
	est.receber_evento(_evento(4))
	_ok(est.ultimo_seq == 0, "sem snapshot nada se aplica")
	est.aplicar_snapshot(_snapshot(3, 1))
	_ok(est.ultimo_seq == 4, "depois do snapshot 3, o 4 guardado aplica")
	est.free()


func _teste_opcoes_so_na_revisao() -> void:
	print("ROOM_OPTIONS por revisão:")
	var est = EstadoScript.new()
	est.aplicar_snapshot(_snapshot(1, 40))
	est.receber_opcoes({"type": "ROOM_OPTIONS", "revision": 40, "mover": [{"x": 2, "y": 1, "custoM": 1.5}]})
	_ok(est.lista_opcao("mover").size() == 1, "valem na revisão em que foram feitas")
	est.receber_evento(_evento(2, 41))
	_ok(est.lista_opcao("mover").is_empty(), "deixam de valer quando a revisão muda")
	est.free()


func _teste_dano_so_o_que_vem() -> void:
	print("Números de dano:")
	var est = EstadoScript.new()
	var vistos: Array = []
	est.dano_visto.connect(func(a, v, t, mim): vistos.append([a, v, t, mim]))
	est.aplicar_snapshot(_snapshot(1, 1))
	est.minha_figura_id = "fA"
	est.receber_evento(_evento(2, -1, "dano", {"alvoId": "fA", "partes": [{"tipo": "agua", "valor": 3}, {"tipo": "fisico", "valor": 2}]}))
	est.receber_evento(_evento(3, -1, "dano", {"alvoId": "fX"}))
	_ok(vistos.size() == 2, "um número por tipo; sem valor projetado, nada aparece")
	_ok(vistos.size() > 0 and vistos[0][3] == true, "golpe recebido marcado como dela")
	est.free()


# ---------------------------------------------------------------- Fila e Rede

func _recibo(id: String, estado: String, seq: int = 57) -> Dictionary:
	return {"v": 2, "type": "ROOM_RECEIPT", "roomId": "sala-teste", "intentId": id, "estado": estado, "seq": seq, "revision": 42}


func _teste_recibo_duplicado_ignorado_na_fila() -> void:
	print("Recibo duplicado (fila):")
	var fila = FilaIntencoes.new()
	fila.registar("i-1", "{}")
	_ok(fila.aplicar_recibo(_recibo("i-1", "APLICADA")) == FilaIntencoes.Resultado.NOVO, "o primeiro recibo conta")
	_ok(fila.aplicar_recibo(_recibo("i-1", "APLICADA")) == FilaIntencoes.Resultado.IGNORADO, "o duplicado é ignorado")
	_ok(fila.aplicar_recibo(_recibo("i-1", "RECUSADA")) == FilaIntencoes.Resultado.IGNORADO, "terminal não muda")
	fila.registar("i-2", "{}")
	_ok(fila.aplicar_recibo(_recibo("i-2", "AGUARDANDO_MESTRE")) == FilaIntencoes.Resultado.NOVO, "AGUARDANDO_MESTRE conta")
	_ok(fila.aplicar_recibo(_recibo("i-2", "AGUARDANDO_MESTRE")) == FilaIntencoes.Resultado.IGNORADO, "AGUARDANDO_MESTRE repetido é ignorado")
	_ok(fila.aplicar_recibo(_recibo("i-2", "APLICADA")) == FilaIntencoes.Resultado.NOVO, "o Mestre decide e passa a APLICADA")


func _teste_recibo_duplicado_ignorado_na_rede() -> void:
	print("Recibo duplicado (Rede, mensagem inteira):")
	var rede = RedeScript.new()
	rede.persistir = false
	var sinais: Array = []
	rede.recibo_recebido.connect(func(id, e, _m): sinais.append([id, e]))
	rede.fila.registar("i-9", "{}")
	var texto := JSON.stringify(_recibo("i-9", "APLICADA"))
	rede._ao_receber(texto)
	rede._ao_receber(texto)
	_ok(sinais.size() == 1 and sinais[0] == ["i-9", "APLICADA"], "recibo_recebido sai uma vez só")
	rede._ao_receber("q")  # resposta ao ping
	_ok(sinais.size() == 1, "o ping não é tratado como mensagem")
	rede.free()


func _teste_recibo_alheio_ignorado() -> void:
	print("Recibo de id alheio:")
	var fila = FilaIntencoes.new()
	_ok(fila.aplicar_recibo(_recibo("de-outra", "APLICADA")) == FilaIntencoes.Resultado.IGNORADO, "id que não é nosso é ignorado")
	_ok(fila.aplicar_recibo({"estado": "APLICADA"}) == FilaIntencoes.Resultado.IGNORADO, "recibo sem id é ignorado")


func _teste_desconhecida_reenvia_uma_vez() -> void:
	print("DESCONHECIDA e reenvio:")
	var fila = FilaIntencoes.new()
	fila.registar("i-3", "{\"intentId\":\"i-3\"}")
	fila.marcar_desconhecidas()
	_ok(fila.ids_para_consulta() == ["i-3"], "a pendente entra no RECEIPT_QUERY")
	_ok(fila.aplicar_recibo(_recibo("i-3", "DESCONHECIDA")) == FilaIntencoes.Resultado.REENVIAR, "servidor não viu: reenviar")
	_ok(fila.texto_de("i-3") == "{\"intentId\":\"i-3\"}", "reenvia o MESMO texto (mesmo intentId)")
	_ok(fila.aplicar_recibo(_recibo("i-3", "DESCONHECIDA")) == FilaIntencoes.Resultado.IGNORADO, "resposta repetida não reenvia duas vezes")


func _teste_queda_marca_desconhecida() -> void:
	print("Queda da ligação:")
	var fila = FilaIntencoes.new()
	fila.registar("i-4", "{}")
	fila.registar("i-5", "{}")
	fila.aplicar_recibo(_recibo("i-5", "AGUARDANDO_MESTRE"))
	_ok(fila.marcar_desconhecidas() == 1, "só a ENVIADA vira DESCONHECIDA")
	_ok(fila.estado_de("i-4") == "DESCONHECIDA" and fila.estado_de("i-5") == "AGUARDANDO_MESTRE", "estados certos")
	_ok(fila.ids_para_consulta().size() == 2, "as duas são consultadas ao religar")


func _teste_recusa_duplicada_ignorada() -> void:
	print("Recusa duplicada:")
	var fila = FilaIntencoes.new()
	fila.registar("i-6", "{}")
	_ok(fila.aplicar_recusa("i-6", "revisao_antiga"), "a primeira recusa conta")
	_ok(not fila.aplicar_recusa("i-6", "revisao_antiga"), "a repetida é ignorada")
	_ok(fila.aplicar_recibo(_recibo("i-6", "APLICADA")) == FilaIntencoes.Resultado.IGNORADO, "depois da recusa, nada a aplica")


func _teste_uuid_v4() -> void:
	print("intentId UUID v4:")
	var re := RegEx.create_from_string("^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
	var vistos := {}
	var todos_validos := true
	for i in 200:
		var u: String = Uuid.v4()
		if re.search(u) == null:
			todos_validos = false
		vistos[u] = true
	_ok(todos_validos, "formato v4 (versão 4, variante RFC 4122)")
	_ok(vistos.size() == 200, "200 ids sem repetição")
