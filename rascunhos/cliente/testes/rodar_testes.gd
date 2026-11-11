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
const Perfis := preload("res://arte/perfis/aplicar_perfil.gd")
const Frases := preload("res://hud/frases_batalha.gd")

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
	_teste_uma_tabela_de_perfis()
	_teste_frases_do_site()
	_teste_frases_no_estado()
	_teste_ambiente_na_party()
	_teste_reentrada_servidor_restaurado()
	_teste_sala_de_espera()
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


## I0004 (08/11): uma só tabela de perfis gráficos. A arena usa o AplicadorPerfil e não tem números
## próprios; as chaves do AplicadorPerfil são as que a ⚙ do HUD oferece (hud.gd PERFIS).
func _teste_uma_tabela_de_perfis() -> void:
	print("Uma só tabela de perfis gráficos:")
	var chaves: Array = Perfis.PERFIS.keys()
	chaves.sort()
	_ok(chaves == ["alto", "baixo", "medio"], "o AplicadorPerfil tem baixo, medio e alto")
	_ok(Perfis.normalizar(" Médio ") == "medio", "«Médio» da ⚙ chega como «medio»")
	var cena := FileAccess.get_file_as_string("res://cenas/arena/arena.tscn")
	_ok(cena.contains("res://arte/perfis/aplicar_perfil.gd") and cena.contains('[node name="Perfis"'),
			"a arena tem o nó Perfis com o AplicadorPerfil")
	_ok(cena.contains('name="Sol" type="DirectionalLight3D" parent="." groups=["sol"]'), "o Sol está no grupo «sol»")
	_ok(cena.contains('name="Ambiente" type="WorldEnvironment" parent="." groups=["ambiente"]'), "o Ambiente está no grupo «ambiente»")
	var arena := FileAccess.get_file_as_string("res://cenas/arena/arena.gd")
	_ok(not arena.contains("msaa_3d") and not arena.contains("scaling_3d_scale"), "a arena não tem números de perfil próprios")
	var hud := FileAccess.get_file_as_string("res://hud/hud.gd")
	_ok(hud.contains('const PERFIS := ["baixo", "medio", "alto"]'), "a ⚙ do HUD oferece as mesmas três chaves")


## I0004 (08/11): frases IGUAIS às do site vivo (jogo.js REF_25: vlabFraseDesgraca, relógio de morte, fim).
func _teste_frases_do_site() -> void:
	print("Frases do site (texto exacto):")
	var casos := [
		["cai", true, false, "a Ong foi ao chão com o golpe falhado."],
		["arma-cai", true, false, "A arma (chicote) caiu-lhe da mão."],
		["arma-quebra", true, false, "A arma (chicote) quebrou — fica inutilizável até ser consertada."],
		["acerta-se", true, false, "a Ong atingiu-se a si própria com o próprio golpe."],
		["acerta-se", false, false, "Lobo atingiu-se a si próprio com o próprio golpe."],
		["quebra-corpo", true, false, "a Ong quebrou algo no corpo — os golpes dela ficam prejudicados e anda metade até ao fim do combate."],
		["quebra-corpo", true, true, "a Ong quebrou algo no corpo — os golpes dela ficam prejudicados e anda metade até ao fim do combate. Perde um quarto da vida que tem agora."],
		["quebra-corpo", false, false, "Lobo quebrou algo no corpo — os golpes dele ficam prejudicados e anda metade até ao fim do combate."],
		["acerta-amigo", true, false, "O golpe atingiu um aliado sem querer."],
		["outra-coisa", true, false, "O golpe correu mal."],
	]
	for c in casos:
		var nome := "Ong" if c[1] else "Lobo"
		_ok(Frases.desgraca(c[0], nome, c[1], "chicote", c[2]) == c[3], "%s (%s%s)" % [c[0], nome, ", perde" if c[2] else ""])
	_ok(Frases.apanhou_arma("Ong", "chicote") == "A Ong apanha o chicote do chão — isso gasta o movimento desta vez.", "apanhar a arma (Q8)")
	_ok(Frases.caiu("Ong") == "A Ong caiu — a batalha continua à volta dela.", "cair")
	_ok(Frases.aguenta("Ong") == "A Ong, caída, aguenta-se — continua a respirar.", "teste ganho")
	_ok(Frases.piora("Ong") == "A Ong, caída, piora visivelmente.", "teste perdido")
	# Regra-mãe e N4 (08/11): a frase completa do site volta a valer (há «Recomeçar» no ecrã do Mestre).
	# Decisão 9 do Mestre (ordem 6) e site REF_30: forma «você» («Aperte»).
	# Decisão 4 (Q4) e site REF_31: estabilizar já não é fim — a frase diz a regra (1 de Vida, caída até à cura).
	_ok(Frases.estabilizou("Ong") == "A Ong caiu, mas estabilizou — ela volta com 1 de Vida e fica caída, sem lutar, até receber uma cura. A cura soma por cima desse 1.", "estabilizou (frase do site REF_31, sem fim)")
	_ok(Frases.continua_caida("Ong") == "A Ong continua caída — estabilizou, mas só uma cura a levanta.", "estabilizada continua caída (site REF_31)")
	_ok(Frases.fim_morte("Ong") == "A Ong caiu — fim desta batalha. Aperte Recomeçar para jogar outra vez.", "fim por morte (frase completa do site)")
	_ok(Frases.fim_vitoria("Ong") == "Os inimigos caíram todos — vitória da Ong nesta batalha. Aperte Recomeçar para jogar outra vez.", "vitória (frase completa do site)")
	_ok(Frases.fim_terminada() == "A batalha terminou — a mesa fechou este encontro. Aperte Recomeçar para jogar outra vez.", "fim declarado pelo Mestre (terminarBatalha do site)")
	_ok(Frases.HA_BOTAO_RECOMECAR, "a cláusula do Recomeçar está ligada (N4)")


## As frases saem do Estado ao aplicar os eventos que o servidor projeta.
func _teste_frases_no_estado() -> void:
	print("Frases a partir dos eventos:")
	var est = EstadoScript.new()
	var frases: Array = []
	est.frase_batalha.connect(func(t): frases.append(t))
	est.aplicar_snapshot({
		"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "sala-teste", "seq": 1, "revision": 1, "fase": "combate",
		"mapa": {"largura": 20, "altura": 20}, "iniciativa": ["fA", "fB"], "vezId": "fA", "rodada": 1, "ambiente": {},
		"figuras": [
			{"id": "fA", "nomePublico": "Ong", "lado": "jogadora", "x": 1, "y": 1},
			{"id": "fB", "nomePublico": "Lobo", "lado": "criatura", "x": 2, "y": 1},
		],
		"propria": {"figuraId": "fA", "estadoMorte": null},
	})
	est.receber_evento(_evento(2, -1, "ataque", {"atacanteId": "fA", "alvoId": "fB", "arma": "chicote-teste", "resultado": "falha_critica"}))
	est.receber_evento(_evento(3, -1, "desgraca", {"figuraId": "fA", "efeito": "quebra-corpo", "perdeQuarto": true}))
	_ok(frases.back() == "Falha crítica · a Ong quebrou algo no corpo — os golpes dela ficam prejudicados e anda metade até ao fim do combate. Perde um quarto da vida que tem agora.",
			"quebrar o corpo, com a perda só porque veio perdeQuarto")
	est.receber_evento(_evento(4, -1, "desgraca", {"figuraId": "fA", "efeito": "arma-cai"}))
	_ok(frases.back() == "Falha crítica · A arma (chicote teste) caiu-lhe da mão.", "a arma é a do último ataque dela")
	est.receber_evento(_evento(5, -1, "estado", {"figuraId": "fA", "visivel": "normal", "armaCaida": true}))
	est.receber_evento(_evento(6, -1, "estado", {"figuraId": "fA", "visivel": "normal", "armaCaida": false}))
	_ok(frases.back() == "A Ong apanha o chicote teste do chão — isso gasta o movimento desta vez.", "apanhar a arma: a frase do site sai quando a arma volta à mão")
	est.receber_evento(_evento(7, -1, "desgraca", {"figuraId": "fB", "efeito": "acerta-se"}))
	_ok(frases.back() == "Falha crítica · Lobo atingiu-se a si próprio com o próprio golpe.", "a desgraça do monstro, no masculino")
	est.receber_evento(_evento(8, -1, "estado", {"figuraId": "fA", "visivel": "caida", "vidaActual": 0,
			"estadoMorte": {"fase": "aMorrer", "sucessos": 0, "falhas": 0}}))
	_ok(frases.back() == "A Ong caiu — a batalha continua à volta dela.", "ao cair")
	var n := frases.size()
	est.receber_evento(_evento(9, -1, "estado", {"figuraId": "fA", "visivel": "caida",
			"estadoMorte": {"fase": "aMorrer", "sucessos": 0, "falhas": 0}}))
	_ok(frases.size() == n, "sem teste de morte nem mudança, nenhuma frase nova")
	est.receber_evento(_evento(10, -1, "teste_morte", {"figuraId": "fA"}))
	est.receber_evento(_evento(11, -1, "estado", {"figuraId": "fA", "visivel": "caida",
			"estadoMorte": {"fase": "aMorrer", "sucessos": 1, "falhas": 0}}))
	_ok(frases.back() == "A Ong, caída, aguenta-se — continua a respirar.", "teste ganho")
	est.receber_evento(_evento(12, -1, "teste_morte", {"figuraId": "fA"}))
	est.receber_evento(_evento(13, -1, "estado", {"figuraId": "fA", "visivel": "caida",
			"estadoMorte": {"fase": "aMorrer", "sucessos": 1, "falhas": 1}}))
	_ok(frases.back() == "A Ong, caída, piora visivelmente.", "teste perdido")
	est.receber_evento(_evento(14, -1, "fim", {"desfecho": "morte"}))
	_ok(frases.back() == "A Ong caiu — fim desta batalha. Aperte Recomeçar para jogar outra vez.", "fim por morte (frase completa do site)")
	est.receber_evento(_evento(15, -1, "fim", {"desfecho": "terminada"}))
	_ok(frases.back() == Frases.fim_terminada(), "fim declarado pelo Mestre → a frase do site")
	var sem_numeros := true
	for t in frases:
		if (t as String).contains("0") or (t as String).contains("1"):
			sem_numeros = false
	_ok(sem_numeros, "nenhuma frase leva números")
	est.free()
	# Q4 (decisão 4; site REF_31): o teste de morte que estabiliza dá a frase da regra, e não há fim.
	var est2 = EstadoScript.new()
	var frases2: Array = []
	est2.frase_batalha.connect(func(t): frases2.append(t))
	est2.aplicar_snapshot({
		"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "sala-teste", "seq": 1, "revision": 1, "fase": "combate",
		"mapa": {"largura": 20, "altura": 20}, "iniciativa": ["fA", "fB"], "vezId": "fA", "rodada": 1, "ambiente": {},
		"figuras": [
			{"id": "fA", "nomePublico": "Ong", "lado": "jogadora", "x": 1, "y": 1},
			{"id": "fB", "nomePublico": "Lobo", "lado": "criatura", "x": 2, "y": 1},
		],
		"propria": {"figuraId": "fA", "estadoMorte": {"fase": "aMorrer", "sucessos": 2, "falhas": 0}},
	})
	est2.receber_evento(_evento(2, -1, "teste_morte", {"figuraId": "fA"}))
	est2.receber_evento(_evento(3, -1, "estado", {"figuraId": "fA", "visivel": "caida", "vidaActual": 1,
			"estadoMorte": {"fase": "estabilizado", "sucessos": 3, "falhas": 0}}))
	_ok(frases2.size() > 0 and frases2.back() == Frases.estabilizou("Ong"), "estabilizou: a frase da regra Q4")
	_ok(est2.fase == "combate", "estabilizou: a batalha continua")
	est2.free()


## Ordem 13 (dívida E1): o raio, o fogo e o dano do ambiente na Party — as frases do site, o fogo guardado e o
## número só a quem o sofreu (o servidor já não o manda a mais ninguém; aqui confere-se que o cliente o mostra).
func _teste_ambiente_na_party() -> void:
	print("Raio e fogo na Party (ordem 13):")
	var est = EstadoScript.new()
	var frases: Array = []
	var danos: Array = []
	est.frase_batalha.connect(func(t): frases.append(t))
	est.dano_visto.connect(func(a, v, t, eu): danos.append([a, v, t, eu]))
	est.aplicar_snapshot({
		"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "sala-teste", "seq": 1, "revision": 1, "fase": "combate",
		"mapa": {"largura": 20, "altura": 20}, "iniciativa": ["fA", "fB"], "vezId": "fA", "rodada": 2, "ambiente": {},
		"fogo": {"casas": [{"x": 5, "y": 5}], "aArder": []},
		"figuras": [
			{"id": "fA", "nomePublico": "Ong", "lado": "jogadora", "x": 1, "y": 1},
			{"id": "fB", "nomePublico": "Lobo", "lado": "criatura", "x": 2, "y": 1},
		],
		"propria": {"figuraId": "fA", "estadoMorte": null},
	})
	_ok(est.fogo.get("casas", []).size() == 1, "o snapshot traz as casas a arder")
	est.receber_evento(_evento(2, -1, "raio", {"x": 1, "y": 1, "alvoId": "fA", "desfecho": "arde"}))
	_ok(frases.back() == "Um raio atinge a Ong em cheio — ela fica a arder.", "raio nela (frase do site)")
	est.receber_evento(_evento(3, -1, "dano_ambiente", {"alvoId": "fA", "origem": "raio", "desfecho": "arde", "valor": 15, "tipos": ["eletrico"]}))
	_ok(danos.size() == 1 and danos[0][1] == 15 and danos[0][3] == true, "o número do raio sai como o de qualquer dano, nela")
	_ok(frases.size() == 1, "o dano do raio não repete a frase")
	est.receber_evento(_evento(4, -1, "fogo", {"casas": [{"x": 1, "y": 1}, {"x": 1, "y": 2}], "aArder": ["fA"]}))
	_ok(est.fogo["casas"].size() == 2 and est.fogo["aArder"] == ["fA"], "o evento `fogo` substitui o fogo inteiro")
	est.receber_evento(_evento(5, -1, "dano_ambiente", {"alvoId": "fB", "origem": "fogo", "desfecho": "arde"}))
	_ok(frases.back() == "Lobo está a arder — o fogo morde." and danos.size() == 1, "tick no lobo: a frase, sem número (não é dela)")
	est.receber_evento(_evento(6, -1, "dano_ambiente", {"alvoId": "fA", "origem": "fogo", "desfecho": "arde", "valor": 5, "tipos": ["fogo"]}))
	_ok(frases.back() == "A Ong está a arder — o fogo morde." and danos.back()[1] == 5, "tick nela: a frase e o número dela")
	est.receber_evento(_evento(7, -1, "fogo", {"casas": [], "aArder": [], "apagados": [{"figuraId": "fA", "porque": "saiu"}]}))
	_ok(frases.back() == "A Ong sai da casa em chamas — a chuva apaga o fogo dela." and est.fogo["casas"].is_empty(), "sair para a chuva")
	est.receber_evento(_evento(8, -1, "fogo", {"casas": [], "aArder": [], "apagados": [{"figuraId": "fB", "porque": "chuva-casa"}]}))
	_ok(frases.back() == "A chuva apaga a casa — e o fogo de Lobo.", "a chuva apaga a casa do lobo")
	est.receber_evento(_evento(9, -1, "raio", {"x": 9, "y": 9}))
	_ok(frases.back() == "Um raio cai na arena — uma cruz de casas fica a arder.", "raio sem ninguém")
	est.receber_evento(_evento(10, -1, "raio", {"x": 2, "y": 1, "alvoId": "fB", "desfecho": "caiu"}))
	_ok(frases.back() == "Um raio atinge Lobo em cheio — e ele cai.", "raio que mata o lobo")
	var n := frases.size()
	est.receber_evento(_evento(11, -1, "raio", {"x": 1, "y": 1, "alvoId": "fA", "desfecho": "aMorrer"}))
	_ok(frases.size() == n, "raio que a deita: a frase da queda vem pelo `estado` dela, não aqui")
	_ok(Frases.fogo_apagado("Ong", true, "chuva") == "A chuva apaga o fogo da Ong.", "a chuva apaga quem arde fora do fogo")
	_ok(Frases.fogo_morde("Lobo", false, "caiu") == "Lobo cai, a arder.", "o fogo deita o monstro")
	est.free()


## Ordem 19 (V12): o servidor restaurado de um journal a que faltava o fim (a gravação em disco falhou) volta com o
## seq e a revisão DESTE lugar mais baixos do que o aparelho viu. Ao ROOM_JOIN com lastSeq acima do seq dele, o servidor
## responde com um ROOM_SNAPSHOT (sala.js mensagensDeSincronizacao). Antes o cliente deitava-o fora (mais velho do que
## o que tinha) e ficava preso: os eventos novos pareciam repetidos e as opções nunca valiam (revisão só a subir).
func _teste_reentrada_servidor_restaurado() -> void:
	print("Reentrada num servidor restaurado (ordem 19, V12):")
	var est = EstadoScript.new()
	est.aplicar_snapshot(_snapshot(20, 9))
	est.receber_evento(_evento(21, 10, "movimento", {"figuraId": "fA", "para": {"x": 5, "y": 5}}))
	_ok(est.ultimo_seq == 21 and est.revisao == 10, "antes da queda: seq 21, revisão 10")
	est._ao_boas_vindas({"type": "ROOM_WELCOME", "seatId": "s1"})
	est.aplicar_snapshot(_snapshot(15, 6))
	_ok(est.ultimo_seq == 15, "o snapshot da reentrada manda, mesmo com seq mais baixo")
	_ok(est.revisao == 6, "a revisão passa a ser a do servidor")
	_ok(est.casa_de(est.figuras["fA"]) == Vector2i(1, 1), "a figura volta à casa que o servidor tem")
	est.receber_evento(_evento(16, 7))
	_ok(est.ultimo_seq == 16, "o evento seguinte do servidor aplica (não é tomado por repetido)")
	est.receber_opcoes({"type": "ROOM_OPTIONS", "revision": 7, "mover": [{"x": 2, "y": 1, "custoM": 1.5}]})
	_ok(est.lista_opcao("mover").size() == 1, "as opções da revisão do servidor valem")
	est.aplicar_snapshot(_snapshot(12, 5))
	_ok(est.ultimo_seq == 16, "fora da reentrada, um snapshot mais velho continua ignorado")
	est.free()


## Ordem 22 (17-2, decisão do Mestre): sala restaurada a meio da batalha, a jogadora entra antes do Mestre → o servidor
## manda-lhe um snapshot de LOBBY (sem figuras, sem vez). Quando o Mestre entra, manda o snapshot da batalha com o MESMO
## seq (nada lhe foi entregue entretanto). O cliente tem de o aceitar e sair do lobby para a batalha.
func _teste_sala_de_espera() -> void:
	print("Sala de espera antes do Mestre (ordem 22, 17-2):")
	var est = EstadoScript.new()
	est._ao_boas_vindas({"type": "ROOM_WELCOME", "seatId": "s1"})
	var lobby := _snapshot(5, 4)
	lobby["fase"] = "lobby"
	lobby["figuras"] = []
	lobby["iniciativa"] = []
	lobby["vezId"] = null
	lobby["rodada"] = 0
	est.aplicar_snapshot(lobby)
	_ok(est.fase == "lobby" and est.figuras.is_empty(), "antes do Mestre: no lobby, sem figuras")
	var batalha := _snapshot(5, 4)
	batalha["rodada"] = 1
	est.aplicar_snapshot(batalha)
	_ok(est.fase == "combate", "com o Mestre dentro: o snapshot da batalha (mesmo seq) tira-a do lobby")
	_ok(est.figuras.has("fA") and est.ultimo_seq == 5, "e traz as figuras")
	est.free()
