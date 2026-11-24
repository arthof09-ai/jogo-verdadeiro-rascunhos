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
## Ordem 40: o clima (chuva e neve) — módulo de apresentação.
const Clima := preload("res://arte/clima/clima.gd")
const IntegradorVento := preload("res://arte/clima/integrador_vento.gd")
const VentoMundo := preload("res://mapa/floresta/vento_mundo.gd")
## Ordem 44: o terreno do mapa que o servidor lê (gerado pelo exportador, a partir da arena).
const ExportarTerreno := preload("res://cenas/arena/ferramentas/exportar_terreno.gd")
const Assentamento := preload("res://cenas/arena/assentamento.gd")
const GrelhaMapa := preload("res://mapa/floresta/grelha_floresta.gd")
## Ordem HUD: o modelo da caixa da ordem de turnos (dinâmico e iniciativa).
const OrdemTurnos := preload("res://hud/ordem_turnos.gd")
const Retratos := preload("res://hud/retratos.gd")
const CaixaOrdem := preload("res://hud/caixa_ordem.gd")
## Ordem CAIXA-PADRAO-CORRECOES: os casos do enquadramento dos retratos (passada, arma, braço, deitada, quadrúpede, esfola).
const CasosRetrato := preload("res://testes/casos_retrato.gd")
const MarcadorSite := preload("res://cenas/comum/marcador_figura.gd")
## Ordem ÁGUA-REAÇÃO: o lago reage ao estado das figuras (salpico, agito que acalma).
const LagoFloresta := preload("res://mapa/floresta/lago_floresta.gd")
const RelevoFloresta := preload("res://mapa/floresta/relevo_floresta.gd")
## Ordem ESCALA: a escala do mundo (1 · 1,5 · 2 m por casa; pré-definida 1,5) vive na tabela DADOS.
const Apresentacao := preload("res://dados/apresentacao.gd")
## ORDEM MAPA-JOGÁVEL: o que as duas arenas fazem igual (a água não recusa o pé; a figura mexe o lago).
const CampoDaMesaT := preload("res://cenas/arena/campo_da_mesa.gd")


## ORDEM MAPA-JOGÁVEL: um mapa de prova — só a grelha do mapa e o lago (o que campo_da_mesa.gd lê do CampoFloresta).
class MapaDeProva extends Node3D:
	var grelha
	var lago

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
	_teste_arranque_do_mestre()
	_teste_sala_de_espera()
	_teste_aguardando_mestre_desconhecida()
	_teste_validacao_da_entrada()
	_teste_lobby_valida_antes_de_enviar()
	_teste_clima_frame_a_frame()
	_teste_clima_modulo()
	_teste_chuva_vento_do_mundo()
	_teste_neve_arena_vento_e_estados()
	_teste_terreno_do_servidor_em_dia()
	_teste_pe_na_encosta()
	_teste_ordem_turnos_dinamica()
	_teste_ordem_turnos_iniciativa()
	_teste_retratos_do_modelo()
	_teste_retrato_busto_em_pose()
	_teste_retrato_casos_passada()
	_teste_retrato_casos_corpo()
	_teste_retrato_casos_corpo_inteiro()
	_teste_retrato_casos_esfola()
	_teste_escala_do_mundo()
	# ORDEM MAPA-JOGÁVEL: a grelha é o mapa inteiro e a água pisa-se (o lago segue nós na árvore: depois do quadro).
	_teste_mapa_jogavel_geometria()
	# Ordem ÁGUA-REAÇÃO: o lago segue nós que estão na árvore — e no _initialize a raiz ainda não está; um quadro.
	await process_frame
	_teste_agua_reacao()
	_teste_mapa_jogavel_agua()
	# Ordem CAIXA-EXPANDE: a caixa lê o rato e os toques (make_input_local) — precisa de estar na árvore: depois do quadro.
	await _teste_caixa_ordem()
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
	# Ordem 52: a lista da ⚙ vive em arte/perfis/escolha_perfil.gd (partilhada com o ecrã do Mestre); o HUD usa-a.
	var escolha := FileAccess.get_file_as_string("res://arte/perfis/escolha_perfil.gd")
	_ok(hud.contains("const PERFIS := EscolhaPerfil.PERFIS")
			and escolha.contains('const PERFIS: Array[String] = ["baixo", "medio", "alto"]'), "a ⚙ do HUD oferece as mesmas três chaves")


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
## ORDEM-D-AUD-16: o cliente cujo lugar guardado é o do Mestre abre directo no ecrã dele; o resto fica como era.
func _lugar_de_prova(servidor: String, token: String, papel: String) -> ConfigFile:
	var c := ConfigFile.new()
	c.set_value("lugar", "servidor", servidor)
	c.set_value("lugar", "seatToken", token)
	c.set_value("lugar", "papel", papel)
	return c


func _teste_arranque_do_mestre() -> void:
	print("Arranque do cliente pelo lugar guardado (ORDEM-D-AUD-16):")
	var srv := "ws://127.0.0.1:8790/ws"
	_ok(RedeScript.papel_do_lugar(_lugar_de_prova(srv, "tok-m", "mestre"), srv) == "mestre", "lugar do Mestre com token → «mestre»")
	_ok(RedeScript.papel_do_lugar(_lugar_de_prova(srv, "tok-j", "jogadora"), srv) == "jogadora", "lugar da jogadora → «jogadora» (a arena fica)")
	_ok(RedeScript.papel_do_lugar(_lugar_de_prova("ws://10.0.0.9:8790/ws", "tok-m", "mestre"), srv) == "", "lugar de outro servidor → vazio (não serve)")
	_ok(RedeScript.papel_do_lugar(_lugar_de_prova(srv, "", "mestre"), srv) == "", "lugar do Mestre sem token → vazio (a Rede pede a entrada, como antes)")
	_ok(RedeScript.papel_do_lugar(_lugar_de_prova(srv, "tok", "outro"), srv) == "", "papel desconhecido → vazio")
	_ok(RedeScript.papel_do_lugar(ConfigFile.new(), srv) == "", "sem lugar → vazio")
	var rede = RedeScript.new()
	rede.persistir = false
	_ok(rede.papel_do_arranque() == "", "sem disco (testes) → vazio")
	rede.persistir = true
	rede.modo_medicao = true
	_ok(rede.papel_do_arranque() == "", "no link de medição → vazio")
	rede.modo_medicao = false
	rede._ativo = true
	_ok(rede.papel_do_arranque() == "", "a Rede já arrancou (veio do lobby) → vazio")
	rede.free()
	var fonte := FileAccess.get_file_as_string("res://cenas/arena/arena.gd")
	_ok(fonte.contains('const CENA_ARRANQUE_MESTRE := "res://cenas/mestre/mestre.tscn"'), "predefinição: o Mestre abre directo em mestre.tscn (C-7, reversível)")
	_ok(fonte.contains('get_tree().current_scene == self and Rede.papel_do_arranque() == "mestre"'), "o desvio só vale no arranque (cena principal)")
	_ok(ResourceLoader.exists("res://cenas/mestre/mestre.tscn"), "mestre.tscn existe")


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


## Ordem 24 (varredura do cliente, V19): a intenção estava AGUARDANDO_MESTRE (cartão aberto) e o servidor foi restaurado
## de um journal a que falta o fim (ordem 17, B1; o caso da V12): ao religar, o RECEIPT_QUERY responde DESCONHECIDA.
## Antes, a fila ignorava a resposta: a intenção ficava AGUARDANDO_MESTRE para sempre e a barra da HUD trancada (nem
## reabrir a app resolvia). O servidor diz que nunca a viu: reenvia-se o MESMO texto, como numa DESCONHECIDA (E-C1).
func _teste_aguardando_mestre_desconhecida() -> void:
	print("AGUARDANDO_MESTRE que o servidor restaurado não conhece (ordem 24, V19):")
	var fila = FilaIntencoes.new()
	fila.registar("i-7", "{\"intentId\":\"i-7\"}")
	fila.aplicar_recibo(_recibo("i-7", "AGUARDANDO_MESTRE"))
	_ok(fila.ids_para_consulta() == ["i-7"], "a que espera o Mestre entra no RECEIPT_QUERY")
	_ok(fila.aplicar_recibo(_recibo("i-7", "DESCONHECIDA")) == FilaIntencoes.Resultado.REENVIAR, "servidor não a viu: reenviar")
	_ok(fila.texto_de("i-7") == "{\"intentId\":\"i-7\"}", "o MESMO texto (mesmo intentId)")
	_ok(not fila.aguardando_mestre(), "já não tranca a barra à espera do Mestre")
	_ok(fila.aplicar_recibo(_recibo("i-7", "DESCONHECIDA")) == FilaIntencoes.Resultado.IGNORADO, "resposta repetida não reenvia duas vezes")
	# A mensagem inteira pela Rede: o mesmo, e sem sinal à tela (o recibo real vem do reenvio).
	var rede = RedeScript.new()
	rede.persistir = false
	var sinais: Array = []
	rede.recibo_recebido.connect(func(id, e, _m): sinais.append([id, e]))
	rede.fila.registar("i-8", "{}")
	rede.fila.aplicar_recibo(_recibo("i-8", "AGUARDANDO_MESTRE"))
	rede._ao_receber(JSON.stringify(_recibo("i-8", "DESCONHECIDA")))
	_ok(not rede.aguardando_mestre() and rede.fila.estado_de("i-8") == "ENVIADA", "Rede: volta a ENVIADA, a barra destranca")
	_ok(sinais.is_empty(), "Rede: nenhum recibo mostrado à jogadora")
	rede.free()
	# Controlo: um AGUARDANDO_MESTRE com resposta real continua como antes.
	var f2 = FilaIntencoes.new()
	f2.registar("i-9", "{}")
	f2.aplicar_recibo(_recibo("i-9", "AGUARDANDO_MESTRE"))
	_ok(f2.aplicar_recibo(_recibo("i-9", "AGUARDANDO_MESTRE")) == FilaIntencoes.Resultado.IGNORADO and f2.aguardando_mestre(), "controlo: AGUARDANDO_MESTRE repetido continua à espera")


## Ordem 34 (N26-2, sentença da bancada de 2026-11-12): o ROOM_JOIN valida-se no aparelho, antes de enviar.
## Nome 1-64 caracteres (caracteres, não bytes), senha 1-128, PIN a casar exactamente ^[0-9]{6,32}$.
## Antes: o lobby mandava tudo ao servidor (senha vazia, PIN com letras…) e cada envio gastava uma tentativa do travão.
func _teste_validacao_da_entrada() -> void:
	print("Validação da entrada no aparelho (ordem 34, N26-2):")
	var caminho := "res://rede/validar_entrada.gd"
	_ok(ResourceLoader.exists(caminho), "existe o validador da entrada (rede/validar_entrada.gd)")
	if not ResourceLoader.exists(caminho):
		return
	var V = load(caminho)
	_ok(V.dica_nome("Ong") == "" and V.dica_nome("a".repeat(64)) == "", "nome de 1 a 64 letras: sem dica")
	_ok(V.dica_nome("ã".repeat(64)) == "", "64 letras com acento valem 64 (caracteres, não bytes)")
	_ok(V.dica_nome("a".repeat(65)) == "Nome: até 64 letras", "65 letras: «Nome: até 64 letras»")
	_ok(V.dica_nome("") != "" and V.dica_nome("   ") != "", "nome vazio (ou só espaços): fora")
	_ok(V.dica_senha("") == "Falta a senha", "senha vazia: «Falta a senha»")
	_ok(V.dica_senha("s") == "" and V.dica_senha("s".repeat(128)) == "", "senha de 1 a 128: sem dica")
	_ok(V.dica_senha("s".repeat(129)) == "Senha: até 128 letras", "129: «Senha: até 128 letras»")
	var dica_pin := "PIN: só números, 6 a 32"
	_ok(V.dica_pin("123456") == "" and V.dica_pin("1".repeat(32)) == "", "PIN de 6 a 32 algarismos: sem dica")
	var maus := ["", "12345", "1".repeat(33), "12345a", " 123456", "123456 ", "123456
", "12 3456", "١٢٣٤٥٦", "１２３４５６", "-123456", "1234.5"]
	var todos := true
	for pin in maus:
		if V.dica_pin(pin) != dica_pin:
			todos = false
			printerr("    PIN aceite ou com outra dica: ", JSON.stringify(pin))
	_ok(todos, "PIN fora de ^[0-9]{6,32}$ (curto, comprido, letras, espaços, algarismos de outra escrita): «%s»" % dica_pin)
	_ok(V.jogadora_valida("Ong", "s") and not V.jogadora_valida("Ong", "") and not V.jogadora_valida("", "s"), "a entrada da jogadora só vale com os dois campos dentro")

	# A Rede é a última porta do aparelho: campo fora = nada se liga, nada se envia, nada se gasta.
	var rede = RedeScript.new()
	var pedidos: Array = []
	rede.precisa_entrar.connect(func(m: String): pedidos.append(m))
	rede.entrar("a".repeat(65), "senha")
	rede.entrar("Ong", "")
	rede.entrar("Ong", "s".repeat(129))
	rede.entrar_mestre("12345")
	rede.entrar_mestre("abcdef")
	rede.entrar_mestre(" 123456")
	_ok(rede._ws == null and not rede._ativo, "Rede: com um campo fora, 0 ligações e 0 mensagens (nem o socket se abre)")
	_ok(pedidos.size() == 6, "Rede: cada tentativa com um campo fora volta a pedir a entrada (%d de 6)" % pedidos.size())
	rede.free()


func _teste_lobby_valida_antes_de_enviar() -> void:
	print("Lobby: botão inactivo, campo marcado e dica debaixo do campo (ordem 34, N26-2):")
	var rede = root.get_node_or_null("Rede")
	_ok(rede != null, "a Rede (autoload) existe")
	if rede == null:
		return
	# Fora da árvore: o _ready (que chama Rede.iniciar()) não corre; monta-se o formulário à mão.
	var lobby = load("res://cenas/lobby/lobby.tscn").instantiate()
	if lobby.has_method("_validar_campos"):
		lobby._montar()
		lobby._validar_campos()
	var tem: bool = lobby.get("_b_entrar") != null and lobby.get("_dica_nome") != null and lobby.get("_dica_pin") != null
	_ok(tem, "o lobby tem os botões e as dicas por campo")
	if tem:
		_ok(lobby._b_entrar.disabled and lobby._b_mestre.disabled, "campos vazios: os dois botões de entrar inactivos")
		lobby._campo_nome.text = "Ong"
		lobby._campo_senha.text = ""
		lobby._validar_campos()
		_ok(lobby._b_entrar.disabled and lobby._dica_senha.text == "Falta a senha" and lobby._dica_senha.visible, "sem senha: botão inactivo e «Falta a senha» debaixo da senha")
		_ok(lobby._dica_nome.text == "" and not lobby._dica_nome.visible, "o nome está dentro: sem dica nesse campo")
		_ok(lobby._campo_senha.has_theme_stylebox_override("normal") and not lobby._campo_nome.has_theme_stylebox_override("normal"), "o campo fora fica marcado; o que está dentro não")
		lobby._campo_senha.text = "segredo"
		lobby._campo_nome.text = "a".repeat(65)
		lobby._validar_campos()
		_ok(lobby._b_entrar.disabled and lobby._dica_nome.text == "Nome: até 64 letras" and lobby._dica_nome.visible, "nome com 65: botão inactivo e «Nome: até 64 letras»")
		lobby._campo_nome.text = "ã".repeat(64)
		lobby._validar_campos()
		_ok(not lobby._b_entrar.disabled and not lobby._dica_nome.visible and not lobby._dica_senha.visible, "tudo dentro (64 letras com acento): botão activo, sem dicas")
		lobby._campo_senha.text = "s".repeat(129)
		lobby._validar_campos()
		_ok(lobby._b_entrar.disabled and lobby._dica_senha.text == "Senha: até 128 letras", "senha com 129: «Senha: até 128 letras»")
		lobby._campo_pin.text = "12345a"
		lobby._validar_campos()
		_ok(lobby._b_mestre.disabled and lobby._dica_pin.text == "PIN: só números, 6 a 32" and lobby._dica_pin.visible, "PIN com letra: botão inactivo e «PIN: só números, 6 a 32»")
		lobby._campo_pin.text = "123456"
		lobby._validar_campos()
		_ok(not lobby._b_mestre.disabled and not lobby._dica_pin.visible, "PIN dentro: botão activo, sem dica")
		# Enter no campo (ou o toque que escape ao botão inactivo) com um campo fora: nada sai do aparelho.
		var socket_antes = rede._ws
		var estado_antes: int = rede.estado_ligacao
		lobby._campo_pin.text = "12345"
		lobby._ao_enviar_pin("12345")
		lobby._campo_nome.text = "Ong"
		lobby._campo_senha.text = ""
		lobby._ao_enviar_senha("")
		lobby._ao_entrar()
		lobby._ao_entrar_mestre()
		_ok(rede._ws == socket_antes and rede.estado_ligacao == estado_antes, "Enter com um campo fora: 0 ligações, 0 mensagens")
		_ok(lobby._campo_pin.text == "12345", "e o que ela escreveu fica no campo, para corrigir")
	lobby.free()


# ---------------------------------------------------------------- ordem 40: clima (chuva e neve)

## O vento da medição: roda 150° e ganha força a meio (aos 0,5 s), com rajadas pelo caminho.
func _vento_que_muda(t: float) -> Vector2:
	var rumo := deg_to_rad(20.0 + (150.0 if t > 0.5 else 0.0) + 10.0 * sin(0.9 * t))
	return Vector2(cos(rumo), sin(rumo)) * (2.5 * (1.7 if t > 0.5 else 1.0) * (1.0 + 0.25 * sin(2.3 * t)))


## A lição da REF_85: o movimento de cada floco integra-se FRAME A FRAME (posição += (vento do frame + queda) × dt).
func _teste_clima_frame_a_frame() -> void:
	print("Clima (ordem 40): o deslocamento integra-se frame a frame — nenhum floco contra o vento")
	var integ := IntegradorVento.new()
	integ.definir_caixa(Vector3(38.0, 12.0, 38.0))
	var m: Dictionary = integ.medir(3000, 60, 1.0 / 60.0, _vento_que_muda, 1.8, 0.32)
	_ok(int(m["deslocamentos"]) > 170000, "3000 flocos × 60 frames com o vento a rodar 150° a meio: %d deslocamentos medidos" % int(m["deslocamentos"]))
	_ok(int(m["contra_o_vento"]) == 0, "0 deslocamentos contra o vento do frame (%.1f%%)" % float(m["percent_contra"]))
	_ok(int(m["subiram"]) == 0, "nenhum floco sobe")
	_ok(float(m["salto_max_m"]) < 0.25, "salto máximo entre frames abaixo de 0,25 m (%.3f m)" % float(m["salto_max_m"]))
	# O mesmo, 10 s seguidos (as rajadas sobem e descem muitas vezes): continua a zero.
	var longo := IntegradorVento.new()
	longo.definir_caixa(Vector3(38.0, 12.0, 38.0))
	var m10: Dictionary = longo.medir(300, 600, 1.0 / 60.0, _vento_que_muda, 1.8, 0.32)
	_ok(int(m10["contra_o_vento"]) == 0 and int(m10["subiram"]) == 0, "300 flocos × 600 frames (10 s de rajadas): 0 contra o vento, nenhum sobe (%d deslocamentos)" % int(m10["deslocamentos"]))
	# Controlo: a fórmula ERRADA da REF_85 («vento actual × tempo total»), com o mesmo vento nos mesmos 10 s,
	# anda contra ele sempre que a rajada abranda (o produto encolhe e a nuvem inteira recua).
	var contra := 0
	var total := 0
	var antes := Vector2.ZERO
	for q in 600:
		var t := float(q + 1) / 60.0
		var v := _vento_que_muda(t)
		var p := v * t
		if q > 0:
			total += 1
			if (p - antes).dot(v) < -1e-7:
				contra += 1
		antes = p
	_ok(contra > 60, "controlo: a fórmula errada («vento × tempo total») anda contra este mesmo vento em %d de %d frames (%.1f%%)" % [contra, total, 100.0 * contra / float(total)])
	# Mudar o vento não mexe no que já se andou: o acumulado só cresce com o vento de cada frame.
	var i2 := IntegradorVento.new()
	i2.definir_caixa(Vector3(38.0, 12.0, 38.0))
	i2.avancar(1.0 / 60.0, Vector2(3.0, 0.0), 1.8, 0.0)
	var antes_x: float = i2.d_vento[0].x
	i2.avancar(1.0 / 60.0, Vector2(0.0, 0.0), 1.8, 0.0)
	_ok(antes_x > 0.0 and is_equal_approx(i2.d_vento[0].x, antes_x), "o vento cai para zero: o que o floco já andou fica onde está")
	# Os pesos cabem em inteiros pequenos (exactos na GPU) e o ganho do vento é sempre positivo.
	var s: Dictionary = IntegradorVento.sortear(500, 7, true)
	var pesos_bons := true
	for i in 500:
		var w: Vector3i = s["w"][i]
		var l: Vector3i = s["l"][i]
		var k: int = s["k"][i]
		if w.x < 0 or w.y < 0 or w.z < 0 or w.x + w.y + w.z < 12 or w.x + w.y + w.z > 16 or k < 10 or k > 16:
			pesos_bons = false
		if absi(l.x) > 8 or absi(l.y) > 8 or absi(l.z) > 8:
			pesos_bons = false
		var c: Color = IntegradorVento.empacotar(k, w, l, int(s["r"][i]))
		if c.r > 2047.0 or c.g > 2047.0 or c.b > 2047.0 or c.a > 2047.0 or c.r < 0.0 or c.g < 0.0 or c.b < 0.0 or c.a < 0.0:
			pesos_bons = false
	_ok(pesos_bons, "os pesos de 500 flocos: vento ≥ 0 (soma 12..16), queda 10..16, balanço −8..8, empacotados em inteiros até 2047")


## O módulo: desligado não custa nada; liga, troca e regula sem reiniciar; o chão e as figuras respondem.
func _teste_clima_modulo() -> void:
	print("Clima (ordem 40): liga, troca de clima, intensidade e perfil sem reiniciar; chão e figuras respondem")
	var cena := Node3D.new()
	root.add_child(cena)
	var chao := MeshInstance3D.new()
	chao.mesh = PlaneMesh.new()
	chao.add_to_group(Clima.GRUPO_CHAO)
	cena.add_child(chao)
	var figura := Node3D.new()
	figura.add_to_group(Clima.GRUPO_FIGURA)
	cena.add_child(figura)
	var corpo := MeshInstance3D.new()
	corpo.mesh = CapsuleMesh.new()
	(corpo.mesh as CapsuleMesh).material = StandardMaterial3D.new()
	figura.add_child(corpo)
	var anel := MeshInstance3D.new()
	anel.mesh = PlaneMesh.new()
	var sem_luz := StandardMaterial3D.new()
	sem_luz.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	(anel.mesh as PlaneMesh).material = sem_luz
	figura.add_child(anel)
	var c = Clima.new()
	cena.add_child(c)
	# Aqui a cena ainda não está na árvore (o _initialize corre antes de a raiz entrar), por isso os alvos
	# registam-se à mão; a procura pelos grupos, com a arena de verdade, prova-se no testes/pecas_mestre.gd.
	c.registar_chao(chao)
	c.registar_figura(figura)
	c.rajadas = 0.0
	c.configurar_area(Vector3(15.0, 0.0, 15.0), Vector2(30.0, 30.0))
	c.definir_grelha(Vector3.ZERO, 1.5)
	_ok(c.parado() and not c.is_processing() and c.get_child_count() == 0 and chao.material_overlay == null, "desligado: não processa, não cria nós, não veste nada")
	_ok(c.caixa_minimo().is_equal_approx(Vector3(-4.0, 0.0, -4.0)) and c.caixa_tamanho().is_equal_approx(Vector3(38.0, 12.0, 38.0)), "a caixa do clima cobre o campo inteiro (30×30 m) mais 4 m de folga, 12 m de altura")
	_ok(not c.definir("granizo", "forte") and not c.definir("neve", "media") and c.tipo == "nenhum", "clima ou intensidade desconhecidos: recusa e fica como estava")

	# Neve forte, perfil médio.
	_ok(c.definir("neve", "forte") and c.is_processing(), "neve forte: liga sem reiniciar a cena")
	var neve_antes := 0.0
	var sempre_a_subir := true
	for i in 90:
		c.avancar(1.0 / 30.0)
		if c.neve < neve_antes:
			sempre_a_subir = false
		neve_antes = c.neve
	_ok(c.contagem_atual("neve") == 6000 and c.contagem_atual("chuva") == 0, "neve forte no perfil Médio: 6000 flocos (%d)" % c.contagem_atual("neve"))
	_ok(sempre_a_subir and c.neve > 0.05 and c.neve < 0.08, "a neve acumula aos poucos: 3 s de neve forte = %.3f (45 s até cobrir)" % c.neve)
	_ok(chao.material_overlay != null and corpo.material_overlay != null, "o chão e o corpo da figura ganham a camada do clima (material_overlay)")
	_ok(anel.material_overlay == null and corpo.get_active_material(0) is StandardMaterial3D and chao.get_active_material(0) == null, "o anel sem luz fica de fora e nenhum material da cena foi trocado")
	_ok(c.vestidos().size() == 2, "2 nós vestidos (chão e corpo)")
	c.definir("neve", "fraco")
	for i in 60:
		c.avancar(1.0 / 30.0)
	_ok(c.contagem_atual("neve") == 2000, "neve fraca, sem reiniciar: 2000 flocos (%d)" % c.contagem_atual("neve"))
	c.definir_perfil("alto")
	for i in 60:
		c.avancar(1.0 / 30.0)
	_ok(c.contagem_atual("neve") == 3000, "perfil Alto: 3000 flocos (%d)" % c.contagem_atual("neve"))
	c.definir_perfil("Baixo")
	for i in 60:
		c.avancar(1.0 / 30.0)
	_ok(c.contagem_atual("neve") == 1000, "perfil Baixo: 1000 flocos (%d)" % c.contagem_atual("neve"))

	# Troca para chuva forte: a neve sai, a chuva entra, a neve pousada derrete e o chão molha.
	var neve_pousada: float = c.neve
	c.definir_perfil("medio")
	_ok(c.definir_por_nome("chuva-forte") and c.tipo == "chuva" and c.intensidade == "forte", "«chuva-forte» pelo nome")
	for i in 90:
		c.avancar(1.0 / 30.0)
	_ok(c.contagem_atual("chuva") == 5000 and c.contagem_atual("salpicos") == 350 and c.contagem_atual("neve") == 0, "chuva forte no Médio: 5000 gotas e 350 salpicos; os flocos saíram (%d, %d, %d)" % [c.contagem_atual("chuva"), c.contagem_atual("salpicos"), c.contagem_atual("neve")])
	_ok(c.molhado > 0.3 and c.neve < neve_pousada, "o chão molha (%.2f) e a neve pousada derrete (%.3f → %.3f)" % [c.molhado, neve_pousada, c.neve])
	c.definir("chuva", "fraco")
	for i in 60:
		c.avancar(1.0 / 30.0)
	_ok(c.contagem_atual("chuva") == 1600 and c.contagem_atual("salpicos") == 120, "chuva fraca: 1600 gotas e 120 salpicos (%d, %d)" % [c.contagem_atual("chuva"), c.contagem_atual("salpicos")])

	# Um só vento para os dois climas.
	c.definir_vento(90.0, 4.0)
	var v: Vector2 = c.vento_do_frame()
	_ok(absf(v.x) < 0.001 and is_equal_approx(v.y, 4.0), "o vento é um só: 90° e 4 m/s → (0, 4) no chão, para a chuva e para a neve")

	# Desliga: a chuva sai, o chão seca e o módulo volta a dormir.
	c.desligar()
	c.segundos_secar = 1.0
	c.segundos_derreter = 1.0
	for i in 120:
		c.avancar(1.0 / 30.0)
	_ok(c.parado() and not c.is_processing(), "desligado e seco: o módulo dorme outra vez")
	_ok(chao.material_overlay == null and corpo.material_overlay == null and c.vestidos().is_empty(), "e tira a camada do chão e da figura")
	var visiveis := 0
	for n in c.get_children():
		if (n as Node3D).visible:
			visiveis += 1
	_ok(visiveis == 0, "nenhuma partícula à vista")

	# Só apresentação: o módulo não lê o estado do jogo nem a rede.
	var limpo := true
	for ficheiro in ["clima.gd", "integrador_vento.gd"]:
		var codigo := FileAccess.get_file_as_string("res://arte/clima/" + ficheiro)
		if codigo == "" or codigo.contains("Estado.") or codigo.contains("Rede.") or codigo.contains("enviar_"):
			limpo = false
	_ok(limpo, "o código do clima não toca no Estado nem na Rede (só apresentação)")
	cena.free()


# ---------------------------------------------------------------- Ordem 64: a chuva cai com o vento do mundo

## A chuva da arena integrada não tem vento seu: segue o vento do mundo (Ordem 43, vento_mundo.gd) — direcção e
## força dele, lidas uma vez por frame e integradas frame a frame. A neve fica no vento manual (a frente dela
## liga-se depois). Sem fonte (ou com a fonte apagada) volta o vento manual.
func _teste_chuva_vento_do_mundo() -> void:
	print("Clima (ordem 64): a chuva segue o vento do mundo; a neve e a falta da fonte ficam no vento manual")
	var vm = VentoMundo.new()
	vm.parado = true
	vm.hora_fixa = 16.25
	for i in 20:
		vm.avancar(0.1)
	var c = Clima.new()
	c.rajadas = 0.0
	c.definir_vento(200.0, 1.0)  # o manual, de propósito longe do do mundo
	c.configurar_area(Vector3(15.0, 0.0, 15.0), Vector2(30.0, 30.0))
	c.seguir_vento(vm, ["chuva", "nenhum", "granizo"])
	_ok(c.tipos_com_fonte == ["chuva"], "só os tipos que existem entram na lista (%s)" % str(c.tipos_com_fonte))
	var w: Vector3 = vm.vetor()
	_ok(w.length() > 3.0, "o vento do mundo às 16:15 sopra a sério (%.2f m/s)" % w.length())
	var vc: Vector2 = c.vento_do_frame("chuva")
	_ok(vc.is_equal_approx(Vector2(w.x, w.z)), "a chuva: o vento do frame é o do mundo — (%.3f, %.3f) = (%.3f, %.3f)" % [vc.x, vc.y, w.x, w.z])
	var vn: Vector2 = c.vento_do_frame("neve")
	_ok(vn.is_equal_approx(Vector2(cos(deg_to_rad(200.0)), sin(deg_to_rad(200.0)))), "a neve fica no vento manual (200°, 1 m/s)")
	# Frame a frame: o vento do mundo roda e dá rajadas; cada frame da chuva soma o vento DESSE frame.
	c.definir("chuva", "fraco")
	var alinhados := 0
	var quadros := 90
	for i in quadros:
		vm.avancar(1.0 / 30.0)
		c.avancar(1.0 / 30.0)
		var agora: Vector3 = vm.vetor()
		var vv: Vector2 = c._integ_chuva.v_vento[0]
		if vv.normalized().dot(Vector2(agora.x, agora.z).normalized()) > 0.9999:
			alinhados += 1
	_ok(alinhados == quadros, "3 s de chuva fraca: em %d de %d frames a gota anda com o vento do mundo desse frame" % [alinhados, quadros])
	# A fonte com outro vento (o rumo roda 90°): a chuva roda com ela.
	vm.azimute_para = wrapf(vm.azimute_para + 90.0, -180.0, 180.0)
	var w2: Vector3 = vm.vetor()
	_ok(c.vento_do_frame().is_equal_approx(Vector2(w2.x, w2.z)), "o vento do mundo roda 90°: a chuva roda com ele")
	# Sem fonte: volta o vento manual.
	c.seguir_vento(null)
	_ok(not c.segue_fonte("chuva") and c.vento_do_frame("chuva").is_equal_approx(Vector2(cos(deg_to_rad(200.0)), sin(deg_to_rad(200.0)))), "seguir_vento(null): a chuva volta ao vento manual")
	c.seguir_vento(vm)
	_ok(c.segue_fonte("chuva"), "seguir_vento(fonte) sem lista: liga a chuva")
	vm.free()
	_ok(not c.segue_fonte("chuva") and c.vento_do_frame("chuva").is_equal_approx(Vector2(cos(deg_to_rad(200.0)), sin(deg_to_rad(200.0)))), "a fonte apagada: a chuva volta ao vento manual, sem erro")
	var sem_vetor := Node.new()
	c.seguir_vento(sem_vetor)
	_ok(c.fonte_do_vento() == null and c.tipos_com_fonte.is_empty(), "uma fonte sem vetor() é recusada (fica o vento manual)")
	sem_vetor.free()
	c.free()


## Ordem Neve (Fatia 1): neve_fraca e nevasca seguem o vento do mundo na arena integrada e trocam entre os 4 estados
## (limpo ↔ neve_fraca ↔ nevasca ↔ chuva) sem erro nem reinício.
func _teste_neve_arena_vento_e_estados() -> void:
	print("Clima (Ordem Neve, Fatia 1): neve_fraca e nevasca com o vento do mundo + troca viva dos 4 estados")
	var CampoDaMesa = load("res://cenas/arena/campo_da_mesa.gd")
	var vm = VentoMundo.new()
	vm.parado = true
	vm.hora_fixa = 16.25
	for i in 20:
		vm.avancar(0.1)
	var c = CampoDaMesa.criar_clima()
	c.configurar_area(Vector3(0.0, 0.0, 0.0), Vector2(30.0, 30.0))
	c.seguir_vento(vm, CampoDaMesa.TIPOS_COM_VENTO_DO_MUNDO)
	_ok(c.segue_fonte("chuva") and c.segue_fonte("neve"), "CampoDaMesa liga tanto a chuva como a neve ao vento do mundo")
	_ok(c.definir_por_nome("neve_fraca") and c.estado_clima() == "neve_fraca", "estado neve_fraca liga sem reiniciar")
	var w: Vector3 = vm.vetor()
	var vn_fraca: Vector2 = c.vento_do_frame("neve")
	_ok(vn_fraca.normalized().dot(Vector2(w.x, w.z).normalized()) > 0.999 and vn_fraca.length() > 0.5,
		"neve_fraca deriva exactamente no rumo do vento do mundo (%.2f m/s)" % vn_fraca.length())
	_ok(c.definir_por_nome("nevasca") and c.nevasca() and c.estado_clima() == "nevasca", "troca viva neve_fraca → nevasca")
	for i in 130:
		c.avancar(1.0 / 30.0)
	var f_min := INF
	var f_max := 0.0
	var salto_max := 0.0
	var v_antes: Vector2 = c.vento_do_frame("neve")
	for i in 360:
		c.avancar(1.0 / 30.0)
		var vv: Vector2 = c.vento_do_frame("neve")
		var vf: float = vv.length()
		f_min = minf(f_min, vf)
		f_max = maxf(f_max, vf)
		salto_max = maxf(salto_max, (vv - v_antes).length())
		v_antes = vv
	# Correcção 2 (17/11): a rajada é variação CONTÍNUA pelo canal dos flocos (vento_do_frame) — nada de saltos.
	# (A força VISUAL da rajada mede-se nos píxeis dos renders, não aqui: ver ferramentas/medir_pixeis_neve.gd.)
	_ok(f_max > f_min * 2.2 and salto_max < 0.25,
		"na nevasca o vento da queda varia de forma contínua entre calma e rajada (%.2f → %.2f m/s; maior passo por quadro %.3f m/s)" % [f_min, f_max, salto_max])
	_ok(c.definir_por_nome("chuva") and c.estado_clima() == "chuva", "troca viva nevasca → chuva sem reiniciar")
	_ok(c.definir_por_nome("limpo") and c.estado_clima() == "limpo", "troca viva chuva → limpo sem reiniciar")
	# Fatia 2: correcção de 14/11 — na nevasca consolidada (neve=1, aglomerado=1) o centro está coberto a sério
	# (>= 0,85, nunca 0,33) e os cantos/abrigos têm manto mais espesso (> centro).
	c.bordas_abrigo = 0.65
	c.definir_acumulacao(0.0, 1.0)
	c.definir_forte(1.0, 1.0, 0.0)
	var neve_centro: float = c.neve_em(Vector2.ZERO)
	var neve_canto: float = c.neve_em(Vector2(-14.2, -14.2))
	_ok(neve_centro >= 0.85 and neve_canto > neve_centro + 0.25,
		"Fatia 2: a FÓRMULA neve_em dá centro >= 0,85 em F=1 e canto mais espesso (%.2f; %.2f) — teste da fórmula, não medição visual" % [neve_centro, neve_canto])
	# Fatia 3: factor F imponível deterministicamente (t0=0, t1=0,5, t2=1) e transições graduais sem cortes secos.
	c.impor_fator_f(0.0)
	_ok(is_zero_approx(c.fator_f()) and is_zero_approx(c.neve) and is_zero_approx(c.aglomerado) and is_zero_approx(c.congelamento),
		"Fatia 3: F = 0 imposto deterministicamente (t0)")
	c.impor_fator_f(0.5)
	_ok(is_equal_approx(c.fator_f(), 0.5) and is_equal_approx(c.neve, 0.5) and is_equal_approx(c.aglomerado, 0.5) and is_equal_approx(c.congelamento, 0.5),
		"Fatia 3: F = 0,5 imposto deterministicamente (t1)")
	c.impor_fator_f(1.0)
	_ok(is_equal_approx(c.fator_f(), 1.0) and is_equal_approx(c.neve, 1.0) and is_equal_approx(c.aglomerado, 1.0) and is_equal_approx(c.congelamento, 1.0),
		"Fatia 3: F = 1,0 imposto deterministicamente (t2)")
	c.libertar_fator_f()
	c.definir_por_nome("chuva")
	c.avancar(1.0)
	_ok(c.neve < 1.0 and c.neve > 0.85 and c.congelamento < 1.0 and c.congelamento > 0.85 and c.molhado > 0.0,
		"Fatia 3: transição nevasca → chuva derrete neve/congelamento gradualmente sem corte seco (neve %.2f, cong %.2f, molhado %.2f)" % [c.neve, c.congelamento, c.molhado])
	# Correcção 1c (17/11, decisão do coordenador): o chão recebe a geometria da lagoa para não pintar neve debaixo de
	# água (a água fica com o comportamento dela; o gelo da água é trabalho futuro).
	c.impor_fator_f(1.0)
	var Relevo = load("res://mapa/floresta/relevo_floresta.gd")
	var lcr = c._mat_chao.get_shader_parameter(&"lago_centro_raio") if c._mat_chao != null else null
	_ok(lcr is Vector3 and is_equal_approx(lcr.z, Relevo.LAGO_RAIO) and is_equal_approx(float(c._mat_chao.get_shader_parameter(&"lago_nivel")), Relevo.nivel_lago()),
		"Correcção 1c: o chão da neve recebe a cova e o nível da lagoa (máscara da água)")
	c.libertar_fator_f()
	vm.free()
	c.free()


# ---------------------------------------------------------------- Ordem 44: o terreno no servidor e o pé na encosta

## O pacote do terreno que o servidor lê (servidor/dados/terreno-floresta.json) foi gerado a partir das fontes de
## HOJE: o SHA de cada ficheiro de que o terreno depende (relevo, grelha do mapa, campo, formas, regra do assentamento
## e o próprio exportador) tem de ser o que vai no pacote. Se alguém mudar o relevo, a regra ou o exportador sem correr
## o exportador, fica vermelho aqui (a conferência completa, que refaz o pacote, é servidor/ferramentas/conferir-terreno.mjs).
## Ordem 48: o pacote é o mapa inteiro (terreno/2) e a tabela das origens é a regra da arena, lado a lado.
func _teste_terreno_do_servidor_em_dia() -> void:
	var texto := FileAccess.get_file_as_string(ExportarTerreno.caminho_saida())
	var pacote = JSON.parse_string(texto)
	_ok(pacote is Dictionary and pacote.get("cabecalho", {}).get("formato") == ExportarTerreno.FORMATO,
		"o pacote do terreno do servidor lê-se (%s)" % ExportarTerreno.FORMATO)
	if not pacote is Dictionary:
		return
	var no_pacote: Dictionary = pacote["cabecalho"].get("fontes", {})
	var hoje := ExportarTerreno.sha_fontes()
	var diferentes: Array = []
	for f in hoje:
		if String(no_pacote.get(f, "")) != String(hoje[f]):
			diferentes.append(f)
	_ok(diferentes.is_empty() and no_pacote.size() == hoje.size(),
		"o terreno do servidor está em dia com as fontes do cliente (refazer com exportar_terreno.gd): %s" % (", ".join(diferentes) if diferentes else "%d fontes iguais" % hoje.size()))
	var tabela_ok := 0
	var lados: Array = []
	for e in pacote.get("escalas", []):
		var s := float(e["casaM"])
		var tab: Array = e["origensM"]
		lados.append("%s m: 1–%d" % [s, tab.size()])
		if tab == ExportarTerreno.origens(s):
			tabela_ok += 1
	_ok(tabela_ok == ExportarTerreno.ESCALAS.size() and (pacote.get("escalas", []) as Array).size() == ExportarTerreno.ESCALAS.size(),
		"as origens do pacote são as da arena, nas %d escalas (%s casas de lado)" % [tabela_ok, ", ".join(lados)])
	var mapa: Dictionary = pacote.get("mapa", {})
	_ok(int(mapa.get("lado", 0)) == GrelhaMapa.LADO and (mapa.get("bloqueadas", []) as Array).size() == GrelhaMapa.LADO * GrelhaMapa.LADO
		and (pacote.get("redes", []) as Array).size() == 9,
		"o pacote leva o mapa inteiro (%d × %d casas) e %d redes" % [GrelhaMapa.LADO, GrelhaMapa.LADO, (pacote.get("redes", []) as Array).size()])


## A regra do pé (assentamento.gd): num chão plano a base fica no chão e direita; numa encosta inclina-se com ela
## (nem flutua nem se enterra mais de 0,10 m), e o corpo de pé sobe o justo para a cápsula tocar o plano.
func _teste_pe_na_encosta() -> void:
	var r := Assentamento.raio_pegada(1.5)
	_ok(is_equal_approx(r, 0.42), "a pegada tem 0,42 m de raio nas casas de 1,5 m")
	# o centro da zona é quase plano
	var p := Assentamento.pegada(0.0, 0.0, r)
	_ok(float(p["enterra"]) <= 0.10 and float(p["flutua"]) <= 0.10, "no centro do prado a base assenta (enterra %.3f, flutua %.3f m)" % [p["enterra"], p["flutua"]])
	# a casa (0, 0) da grelha de sempre: a encosta do outeiro (a pior da Ordem 42, 0,60 m enterrada)
	var c := Assentamento.centro_casa(Assentamento.origem_no_mapa(Vector2(30, 30), 1.5), 1.5, Vector2i(0, 0))
	var e := Assentamento.pegada(c.x, c.z, r)
	var inclina := rad_to_deg(atan((e["gradiente"] as Vector2).length()))
	_ok(inclina > 30.0, "a casa (0, 0) é a encosta do outeiro (%.1f°)" % inclina)
	_ok(float(e["enterra"]) <= 0.10 and float(e["flutua"]) <= 0.10, "lá a base inclinada nem se enterra nem flutua (%.3f / %.3f m; antes 0,60 m)" % [e["enterra"], e["flutua"]])
	_ok(is_zero_approx(Assentamento.subida_do_corpo(Vector2.ZERO, r)), "no plano o corpo não sobe")
	var sobe := Assentamento.subida_do_corpo(e["gradiente"], r)
	_ok(sobe > 0.0 and sobe < 0.15, "na encosta o corpo sobe %.3f m para a cápsula tocar o plano sem o atravessar" % sobe)


# ---------------------------------------------------------------- Ordem HUD: a caixa da ordem de turnos

static func _ev(tipo: String, dados: Dictionary) -> Dictionary:
	return {"tipo": tipo, "dados": dados}


## O exemplo do Mestre (16/11): ataca a jogadora 1, depois a 2, depois a 3, depois o monstro → 1-2-3-monstro, e repete.
func _teste_ordem_turnos_dinamica() -> void:
	var o = OrdemTurnos.new()
	var figs := {"j1": {}, "j2": {}, "j3": {}, "m": {}}
	_ok(o.modo == OrdemTurnos.DINAMICO, "ordem HUD: por defeito o modo é o dinâmico (sem iniciativa)")
	_ok(o.ordem_visivel([], figs).is_empty(), "ordem HUD: sem acções, a caixa não inventa ordem nenhuma")
	o.registar_evento(_ev("ataque", {"atacanteId": "j1", "alvoId": "m", "ataqueDeOportunidade": false}))
	o.registar_evento(_ev("movimento", {"figuraId": "j1"}))  # mais uma acção da mesma vez
	o.registar_evento(_ev("ataque", {"atacanteId": "j2", "alvoId": "m", "ataqueDeOportunidade": false}))
	o.registar_evento(_ev("ataque", {"atacanteId": "m", "alvoId": "j2", "ataqueDeOportunidade": true}))  # reacção: não é ir
	o.registar_evento(_ev("cura", {"curadorId": "j3", "alvoId": "j2"}))
	o.registar_evento(_ev("ataque", {"atacanteId": "m", "alvoId": "j1", "ataqueDeOportunidade": false}))
	_ok(o.ordem_visivel([], figs) == ["j1", "j2", "j3", "m"], "ordem HUD: a ordem emerge da sequência (1-2-3-monstro)")
	_ok(not o.fechada and o.na_vez("j1") == "m", "ordem HUD: quem agiu por último está na vez; a volta ainda não fechou")
	o.registar_evento(_ev("ataque", {"atacanteId": "j1", "alvoId": "m", "ataqueDeOportunidade": false}))
	_ok(o.fechada and o.ordem_visivel([], figs) == ["j1", "j2", "j3", "m"], "ordem HUD: a jogadora 1 volta a agir — a ordem repete-se igual")
	o.registar_evento(_ev("ataque", {"atacanteId": "j3", "alvoId": "m", "ataqueDeOportunidade": false}))
	_ok(o.ordem_visivel([], figs) == ["j1", "j3", "j2", "m"], "ordem HUD: o Mestre dita outra sequência — a caixa segue a que aconteceu")
	_ok(o.ordem_visivel([], {"j1": {}, "m": {}}) == ["j1", "m"], "ordem HUD: só figuras que existem no espelho")
	o.registar_evento(_ev("recomeco", {}))
	_ok(o.ordem_dinamica.is_empty() and o.ultimo == "", "ordem HUD: o Recomeçar limpa a ordem formada")
	_ok(OrdemTurnos.actor_do_evento(_ev("dano", {"alvoId": "j1", "autorId": "m"})) == "", "ordem HUD: dano não é acção de ninguém")
	_ok(OrdemTurnos.actor_do_evento(_ev("acao", {"figuraId": "j2", "tipo": "correr"})) == "j2", "ordem HUD: correr é a figura a agir")
	_ok(OrdemTurnos.actor_do_evento(_ev("acao", {"figuraId": "j2", "tipo": "sem_desgraca"})) == "", "ordem HUD: a decisão do Mestre não é ir")


## Modo iniciativa: a ordem é a do servidor (só a ORDEM) e a vez é o vezId; desligar volta à ordem dinâmica.
func _teste_ordem_turnos_iniciativa() -> void:
	var o = OrdemTurnos.new()
	var figs := {"j1": {}, "j2": {}, "m": {}}
	o.registar_acao("j2")
	o.registar_acao("j1")
	o.definir_modo(OrdemTurnos.INICIATIVA)
	_ok(o.ordem_visivel(["m", "j1", "j2", "fora"], figs) == ["m", "j1", "j2"], "ordem HUD: modo iniciativa mostra a ordem do servidor")
	_ok(o.na_vez("m") == "m", "ordem HUD: modo iniciativa — na vez está o vezId do servidor")
	o.definir_modo(OrdemTurnos.DINAMICO)
	_ok(o.ordem_visivel(["m", "j1", "j2"], figs) == ["j2", "j1"], "ordem HUD: desligar a iniciativa volta à ordem formada pelas acções")


## O retrato é uma cópia do PRÓPRIO modelo em cena: as mesmas malhas, sem o chão nem rótulos, sem grupos.
func _teste_retratos_do_modelo() -> void:
	var modelo := MarcadorSite.criar(2.25, "marcador", 1)
	modelo.add_to_group(&"figura_clima_teste")
	modelo.transform = Transform3D(Basis(Vector3.RIGHT, 0.3), Vector3(5, 1, 5))
	var copia := Retratos.copiar_modelo(modelo)
	var corpo_o := modelo.get_node("Pivo/Corpo") as MeshInstance3D
	var corpo_c := copia.get_node("Pivo/Corpo") as MeshInstance3D
	_ok(corpo_c != null and corpo_c.mesh == corpo_o.mesh, "retrato: a cópia usa a MESMA malha do modelo em cena")
	_ok(not (copia.get_node("Anel") as Node3D).visible and not (copia.get_node("Contacto") as Node3D).visible, "retrato: o anel e o contacto (do chão) não entram")
	_ok(copia.get_groups().is_empty(), "retrato: a cópia não fica em grupos do jogo (clima, perfil)")
	_ok(copia.transform == Transform3D.IDENTITY, "retrato: a cópia assenta na origem do palco")
	var fundo := Retratos.cor_de_fundo(modelo)
	_ok(fundo.is_equal_approx(MarcadorSite.cor_da_ordem(1).darkened(Retratos.ESCURECER_FUNDO)), "retrato: o fundo é a cor de identificação da figura (paleta do site), escurecida")
	var cam := Camera3D.new()
	Retratos.enquadrar(cam, copia)
	var o := cam.transform.origin
	var fw := -cam.transform.basis.z
	var h := Vector2(fw.x, fw.z).length()
	var alvo_y := o.y + fw.y * (Vector2(o.x, o.z).length() / h)
	_ok(alvo_y > 1.6 and alvo_y < 2.25, "retrato: de pé, o enquadramento é o do busto — rosto e peitoral (olha a %.2f m de 2,25)" % alvo_y)
	_ok(o.z < 0.0, "retrato: a câmara está do lado da frente da figura (-Z, a convenção da arena), a ver o rosto")
	cam.free()
	var r := Retratos.new()
	get_root().add_child(r)
	r.pedir("a", "1", modelo)
	var t1 := r.textura("a")
	r.pedir("a", "1", modelo)
	_ok(r.textura("a") == t1 and r.get_child_count() == 1, "retrato: a mesma chave não volta a desenhar")
	r.esquecer_ausentes({})
	_ok(not r.tem("a"), "retrato: a figura que saiu larga o retrato")
	r.queue_free()
	copia.free()
	modelo.free()


## Ordem CAIXA-PADRAO-BUSTO: o retrato de uma figura ESFOLADA mede-se na pose, não na malha em T. O manequim de
## referência (Mannequin_F, ANDAR v3) tem a malha em T (1,76 m de largo × 1,81 de alto): pela caixa da malha não estaria
## «de pé» e o retrato dava o corpo inteiro. Em pose (quadro 0 do ANDAR) é estreito e alto: busto, rosto e peitoral.
func _teste_retrato_busto_em_pose() -> void:
	var doc := GLTFDocument.new()
	var est := GLTFState.new()
	if doc.append_from_file("res://testes/manequim/andar-v3.glb", est) != OK:
		_ok(false, "retrato em pose: o manequim de referência abriu")
		return
	var fig := Node3D.new()
	fig.rotation_degrees.y = 90.0  # rodada na arena: a cópia do retrato assenta na origem, a rotação da figura sai
	var m := doc.generate_scene(est) as Node3D
	fig.add_child(m)
	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	anim.play("andar_v3")
	anim.seek(0.0, true)
	anim.speed_scale = 0.0
	get_root().add_child(fig)
	var copia := Retratos.copiar_modelo(fig)
	var malha := m.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var em_t := malha.mesh.get_aabb()
	var pose := Retratos.caixa_visivel(copia)
	_ok(not Retratos.de_pe(em_t), "retrato em pose: pela malha em T (%.2f × %.2f m) o manequim NÃO estaria de pé — era o erro" % [em_t.size.x, em_t.size.y])
	_ok(Retratos.de_pe(pose) and pose.size.x < 0.8, "retrato em pose: em pose o manequim está de pé (%.2f de largo × %.2f de alto)" % [pose.size.x, pose.size.y])
	var cam := Camera3D.new()
	Retratos.enquadrar(cam, copia)
	var o := cam.transform.origin
	var fw := -cam.transform.basis.z
	var alvo_y := o.y + fw.y * (Vector2(o.x, o.z).length() / Vector2(fw.x, fw.z).length())
	var j := Retratos.janela_busto(Retratos.caixas_em_pose(copia), pose)
	_ok(alvo_y > pose.end.y - pose.size.y * 0.3 and alvo_y < pose.end.y,
		"retrato em pose: a câmara olha para o rosto e o peito (%.2f m numa figura de %.2f)" % [alvo_y, pose.size.y])
	_ok(j.position.y > pose.position.y + pose.size.y * 0.6 and j.size.y < pose.size.y * 0.4,
		"retrato em pose: a janela é o busto (de %.2f a %.2f m), não o corpo inteiro" % [j.position.y, j.end.y])
	_ok(o.z < 0.0, "retrato em pose: a câmara está à frente da figura (-Z), do lado do rosto")
	cam.free()
	copia.free()
	fig.free()


## Ordem CAIXA-PADRAO-CORRECOES (B1): o «de pé» não cai a meio da passada. (a) O ciclo inteiro do ANDAR v3, quadro a
## quadro (30 q/s): a profundidade máxima da figura toda e a margem ao limiar (altura / DE_PE), e o tronco. (b) Uma passada
## LONGA (as coxas abertas 60° para a frente e para trás): pela caixa toda já não contaria como de pé; pelo tronco conta,
## e o retrato continua a ser o busto.
func _teste_retrato_casos_passada() -> void:
	var d := CasosRetrato.manequim(0.0)
	if d.is_empty():
		_ok(false, "casos (B1): o manequim de referência abriu")
		return
	get_root().add_child(d["fig"])
	var anim: AnimationPlayer = d["anim"]
	var a := anim.get_animation(CasosRetrato.ANIM)
	var n := int(round(a.length * 30.0))
	var fundo_max := 0.0
	var q_max := -1
	var limiar_q := 0.0
	var tronco_max := 0.0
	var margem_min := 99.0
	var todos := true
	for i in n + 1:
		anim.seek(minf(a.length, float(i) / 30.0), true)
		var cpq := Retratos.copiar_modelo(d["fig"])
		var cxs := Retratos.caixas_do_corpo(cpq)
		var cq := Retratos.caixa_do_corpo(cpq)
		var fundo := maxf(cq.size.x, cq.size.z)
		if fundo > fundo_max:
			fundo_max = fundo
			q_max = i
			limiar_q = cq.size.y / Retratos.DE_PE
		margem_min = minf(margem_min, cq.size.y / Retratos.DE_PE - fundo)
		tronco_max = maxf(tronco_max, Retratos.largura_tronco(cxs, cq))
		todos = todos and Retratos.de_pe(cq, cxs) and Retratos.de_pe(cq)
		cpq.free()
	_ok(todos and n + 1 >= 40,
		"casos (B1): nos %d quadros do ANDAR a figura está sempre de pé, pela caixa toda e pelo tronco" % (n + 1))
	_ok(margem_min > 0.4,
		"casos (B1): a profundidade máxima do ANDAR é %.3f m (quadro %d), a %.3f m do limiar %.3f m; margem mínima no ciclo %.3f m; o tronco não passa de %.3f m" % [
			fundo_max, q_max, limiar_q - fundo_max, limiar_q, margem_min, tronco_max])
	# (b) a passada longa, sobre o quadro mais estreito do ciclo
	anim.seek(0.3, true)
	CasosRetrato.parar(d)
	CasosRetrato.passada_longa(d, 60.0)
	var cp := Retratos.copiar_modelo(d["fig"])
	var caixas := Retratos.caixas_do_corpo(cp)
	var c := Retratos.caixa_do_corpo(cp)
	_ok(not Retratos.de_pe(c) and Retratos.de_pe(c, caixas),
		"casos (B1): a meio de uma passada longa (%.2f m de fundo, %.2f de alto) a caixa toda já não diria «de pé» (%s); pelo tronco (%.2f m) diz (%s)" % [
			maxf(c.size.x, c.size.z), c.size.y, Retratos.de_pe(c), Retratos.largura_tronco(caixas, c), Retratos.de_pe(c, caixas)])
	var e := CasosRetrato.enquadramento(cp)
	var b := CasosRetrato.conferir_busto(e["cam"], c)
	_ok(e["de_pe"] and b["dentro"] and b["fora"] and (e["cam"] as Camera3D).transform.origin.z < c.get_center().z,
		"casos (B1): e nessa passada o retrato é o busto — alto da cabeça, rosto e peito no quadro; cintura, joelhos e pés fora; de frente %s" % [b["falta"]])
	(e["cam"] as Camera3D).free()
	cp.free()
	(d["fig"] as Node).free()


## Ordem CAIXA-PADRAO-CORRECOES (B2): o que não é corpo fica fora da faixa e da altura. Uma arma RÍGIDA empunhada e
## levantada acima da cabeça desenha-se, mas não sobe a janela do busto. O braço levantado É corpo: sobe a altura; o rosto
## fica no quadro e o peito pode sair (o limite, medido e documentado em hud/retratos.gd `caixas_do_corpo`).
func _teste_retrato_casos_corpo() -> void:
	var d := CasosRetrato.manequim(0.3)
	if d.is_empty():
		_ok(false, "casos (B2): o manequim de referência abriu")
		return
	get_root().add_child(d["fig"])
	CasosRetrato.parar(d)
	var cp0 := Retratos.copiar_modelo(d["fig"])
	var c0 := Retratos.caixa_do_corpo(cp0)
	var j0 := Retratos.janela_busto(Retratos.caixas_do_corpo(cp0), c0)
	cp0.free()
	CasosRetrato.arma_levantada(d, 0.6)
	var cp := Retratos.copiar_modelo(d["fig"])
	var tudo := Retratos.caixa_visivel(cp)
	var c := Retratos.caixa_do_corpo(cp)
	var j := Retratos.janela_busto(Retratos.caixas_do_corpo(cp), c)
	var j_tudo := Retratos.janela_busto(Retratos.caixas_em_pose(cp), tudo)
	_ok(tudo.end.y > c.end.y + 0.5 and c.is_equal_approx(c0) and j.is_equal_approx(j0),
		"casos (B2): com a arma levantada (a ponta a %.2f m, a cabeça a %.2f m), o corpo e a janela do busto não mudam (janela de %.2f a %.2f m; contando a arma iria de %.2f a %.2f m)" % [
			tudo.end.y, c.end.y, j.position.y, j.end.y, j_tudo.position.y, j_tudo.end.y])
	var e := CasosRetrato.enquadramento(cp)
	var b := CasosRetrato.conferir_busto(e["cam"], c)
	var arma := cp.find_child("Arma", true, false) as Node3D
	_ok(e["de_pe"] and b["dentro"] and b["fora"] and arma != null and arma.visible,
		"casos (B2): e o retrato com a arma continua o busto (rosto e peito no quadro, cintura e pés fora %s); a arma desenha-se (é a figura em cena)" % [b["falta"]])
	(e["cam"] as Camera3D).free()
	cp.free()
	(d["fig"] as Node).free()
	# O braço levantado (corpo): o limite.
	d = CasosRetrato.manequim(0.3)
	get_root().add_child(d["fig"])
	CasosRetrato.parar(d)
	var esq := d["esqueleto"] as Skeleton3D
	var cabeca := Retratos._no_espaco_de(d["fig"], esq) * esq.get_bone_global_pose(esq.find_bone(CasosRetrato.CABECA)).origin
	CasosRetrato.braco_levantado(d)
	cp = Retratos.copiar_modelo(d["fig"])
	c = Retratos.caixa_do_corpo(cp)
	e = CasosRetrato.enquadramento(cp)
	var cam := e["cam"] as Camera3D
	var peito := cabeca + Vector3(0, -0.25, 0)
	_ok(e["de_pe"] and CasosRetrato.ve(cam, cabeca + Vector3(0, 0.1, 0)) and CasosRetrato.ve(cam, cabeca + Vector3(0, 0.2, 0)),
		"casos (B2, limite): com o braço levantado a figura sobe a %.2f m (era %.2f); continua de pé e o rosto fica no quadro; o peito %s (limite documentado)" % [
			c.end.y, c0.end.y, "também" if CasosRetrato.ve(cam, peito) else "sai do quadro"])
	cam.free()
	cp.free()
	(d["fig"] as Node).free()


## Ordem CAIXA-PADRAO-CORRECOES (B4): o ramo «corpo inteiro». O manequim DEITADO e um QUADRÚPEDE esfolado (feito em código:
## o repositório não tem um modelo de quadrúpede) não estão de pé: o retrato é o corpo inteiro, todo no quadro. Sem nada
## visível (caixa zero), o enquadramento usa a figura de recurso e a câmara fica bem posta.
func _teste_retrato_casos_corpo_inteiro() -> void:
	var d := CasosRetrato.manequim(0.0)
	if d.is_empty():
		_ok(false, "casos (B4): o manequim de referência abriu")
		return
	get_root().add_child(d["fig"])
	CasosRetrato.parar(d)
	CasosRetrato.deitar(d)
	var cp := Retratos.copiar_modelo(d["fig"])
	var e := CasosRetrato.enquadramento(cp)
	var c: AABB = e["corpo"]
	_ok(not e["de_pe"] and CasosRetrato.caixa_no_quadro(e["cam"], c),
		"casos (B4): o manequim deitado (%.2f × %.2f × %.2f m) não está de pé e o retrato é o corpo inteiro, todo no quadro" % [c.size.x, c.size.y, c.size.z])
	(e["cam"] as Camera3D).free()
	cp.free()
	(d["fig"] as Node).free()
	var q := CasosRetrato.quadrupede()
	get_root().add_child(q)
	var cq := Retratos.copiar_modelo(q)
	var mi := cq.find_child("Corpo", true, false) as MeshInstance3D
	var ossos := Retratos._caixas_dos_ossos(cq, mi)
	e = CasosRetrato.enquadramento(cq)
	c = e["corpo"]
	_ok(ossos.size() == 7 and Retratos.caixas_do_corpo(cq).size() == 7,
		"casos (B4): o quadrúpede é ESFOLADO — o motor dá as caixas dos seus 7 ossos (%d) e o corpo mede-se por elas" % ossos.size())
	_ok(not e["de_pe"] and not Retratos.de_pe(c) and CasosRetrato.caixa_no_quadro(e["cam"], c),
		"casos (B4): o quadrúpede (%.2f de largo × %.2f de alto × %.2f de comprido) não está de pé (nem pelo tronco: %.2f m) e o retrato é o corpo inteiro, todo no quadro" % [
			c.size.x, c.size.y, c.size.z, Retratos.largura_tronco(Retratos.caixas_do_corpo(cq), c)])
	(e["cam"] as Camera3D).free()
	cq.free()
	q.free()
	var nada := Node3D.new()
	var cam := Camera3D.new()
	Retratos.enquadrar(cam, nada)
	var o := cam.transform.origin
	var fw := -cam.transform.basis.z
	var alvo_y := o.y + fw.y * (Vector2(o.x, o.z).length() / Vector2(fw.x, fw.z).length())
	_ok(Retratos.caixa_visivel(nada).size == Vector3.ZERO and o.is_finite() and o.z < 0.0 and alvo_y > 1.3 and alvo_y < 2.0 and cam.near > 0.0 and cam.far > cam.near,
		"casos (B4): caixa zero (nada visível) — a figura de recurso de 2 m: a câmara à frente, a olhar o busto (%.2f m), planos %.2f–%.2f m" % [alvo_y, cam.near, cam.far])
	cam.free()
	nada.free()


## Ordem CAIXA-PADRAO-CORRECOES (B5): (a) em pose, a caixa do retrato contra a malha ESFOLADA vértice a vértice: tem de a
## conter, com pouca folga. Sem ecrã (o CI) a referência é a esfola por CPU (a mesma conta do motor); com render, também a
## do próprio motor (bake_mesh_from_current_skeleton_pose) — a prova viva confronta as duas. (b) A validação em repouso,
## cometida: com a pose de repouso, a conta por ossos dá a caixa da malha do ficheiro (a pose em T).
func _teste_retrato_casos_esfola() -> void:
	var d := CasosRetrato.manequim(0.0)
	if d.is_empty():
		_ok(false, "casos (B5): o manequim de referência abriu")
		return
	get_root().add_child(d["fig"])
	var mi := d["malha"] as MeshInstance3D
	var anim: AnimationPlayer = d["anim"]
	var linhas: Array = []
	var contem := true
	var folga_max := 0.0
	var motor_igual := true
	var com_motor := 0
	for t in [0.0, 0.3, 0.6, 1.0]:
		anim.seek(t, true)
		var cpt := Retratos.copiar_modelo(d["fig"])
		var ct := Retratos.caixa_do_corpo(cpt)
		var esf := CasosRetrato.esfolar_cpu(cpt, cpt.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D)
		var mot := CasosRetrato.esfolar_motor(d["fig"], mi)
		if mot.size != Vector3.ZERO:
			com_motor += 1
			motor_igual = motor_igual and mot.position.distance_to(esf.position) < 0.002 and mot.size.distance_to(esf.size) < 0.002
		contem = contem and ct.grow(0.001).encloses(esf)
		var folga := ct.size - esf.size
		folga_max = maxf(folga_max, maxf(folga.x, maxf(folga.y, folga.z)))
		linhas.append("%.1f s: %.3f×%.3f×%.3f contra %.3f×%.3f×%.3f" % [t, ct.size.x, ct.size.y, ct.size.z, esf.size.x, esf.size.y, esf.size.z])
		cpt.free()
	# A folga é a das caixas por osso (uma por osso: a caixa dos vértices que ele move, levada inteira): medida ≤ 0,143 m.
	_ok(contem and folga_max < 0.2 and motor_igual,
		"casos (B5): em pose, a caixa do retrato contém a malha esfolada vértice a vértice, com folga ≤ %.3f m (%s; esfola %s)" % [
			folga_max, "; ".join(linhas), ("do motor igual à de CPU em %d poses" % com_motor) if com_motor > 0 else "por CPU — sem ecrã o motor não coze a malha"])
	CasosRetrato.parar(d)
	(d["esqueleto"] as Skeleton3D).reset_bone_poses()
	var cp := Retratos.copiar_modelo(d["fig"])
	var r := Retratos.caixa_do_corpo(cp)
	var micp := cp.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var m := mi.mesh.get_aabb()
	var esf_r := CasosRetrato.esfolar_cpu(cp, micp)
	_ok(r.position.distance_to(m.position) < 0.001 and r.size.distance_to(m.size) < 0.001 and esf_r.size.distance_to(m.size) < 0.001
		and not Retratos.de_pe(r, Retratos.caixas_do_corpo(cp)),
		"casos (B5): em repouso a conta por ossos dá a caixa da malha do ficheiro (%.3f × %.3f × %.3f contra %.3f × %.3f × %.3f m; a esfola também) — a pose em T, que não está de pé" % [
			r.size.x, r.size.y, r.size.z, m.size.x, m.size.y, m.size.z])
	cp.free()
	(d["fig"] as Node).free()


func _teste_caixa_ordem() -> void:
	var c := CaixaOrdem.new()
	get_root().add_child(c)
	var ordem: Array[String] = ["j1", "j2", "m"]
	c.mostrar(ordem, "j2", {"j1": "Ong", "j2": "Ruiva", "m": "Lobo"}, {}, "dinamico")
	_ok(c.ids_mostrados == ordem and c.vez_mostrada == "j2", "caixa: mostra a ordem e quem está na vez")
	# Ordem CAIXA-EXPANDE: as caixinhas pequenas são só os PRÓXIMOS (a vez não aparece nelas), a contar de quem vem a seguir.
	var fila0 := c.find_child("Fila", true, false)
	_ok(c.ids_fila == ["m", "j1"] and fila0.get_child_count() == 2 and fila0.find_child("Slot_j2", false, false) == null,
		"caixa: as caixinhas são os próximos a jogar, sem a figura na vez (%s)" % [c.ids_fila])
	# Ordem CAIXA-PADRAO-BUSTO: todos os quadradinhos do mesmo tamanho, seja qual for o nome.
	var ordem5: Array[String] = ["a", "b", "c", "d", "e"]
	var nomes5 := {"a": "Arqueira de Prata Longa", "b": "Urso", "c": "Espadachim", "d": "Ab", "e": "Gigante"}
	c.mostrar(ordem5, "c", nomes5, {}, "iniciativa")
	_ok(c.ids_fila == ["d", "e", "a", "b"], "caixa: com 5 figuras, as 4 caixinhas são os 4 próximos a seguir à vez, dando a volta (%s)" % [c.ids_fila])
	var tamanhos := {}
	for slot in c.find_child("Fila", true, false).get_children():
		var t: Vector2 = (slot as Control).get_combined_minimum_size()
		tamanhos["%dx%d" % [int(t.x), int(t.y)]] = true
	var cel := c.tamanho_celula()
	_ok(tamanhos.size() == 1 and tamanhos.has("%dx%d" % [int(cel.x), int(cel.y)]),
		"caixa: os 4 quadradinhos têm o MESMO tamanho, nomes curtos ou longos (%s; célula %dx%d)" % [tamanhos.keys(), int(cel.x), int(cel.y)])
	# Ordem CAIXA-PADRAO-CORRECOES (B3): o que a linha de nome MOSTRA (cortado com «…» na largura da célula), não o `text`.
	var visiveis: Array = []
	var cortes_ok := true
	var cores_ok := true
	for slot in c.find_child("Fila", true, false).get_children():
		var l := slot.get_node("Nome") as Label
		var v := CaixaOrdem.texto_visivel(l)
		visiveis.append(v)
		var fonte := l.get_theme_font("font")
		var tam := l.get_theme_font_size("font_size")
		if v != l.text:
			# cortado: é o começo do nome com «…»; com mais uma letra já não caberia na célula
			var sem := v.trim_suffix(l.ellipsis_char)
			var mais := l.text.substr(0, sem.length() + 1) + l.ellipsis_char
			cortes_ok = cortes_ok and v.ends_with(l.ellipsis_char) and l.text.begins_with(sem) and fonte.get_string_size(mais, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x > l.size.x
		else:
			cortes_ok = cortes_ok and fonte.get_string_size(v, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x <= l.size.x
		cores_ok = cores_ok and l.get_theme_color("font_color") == CaixaOrdem.COR_TEXTO
		var est := (slot.get_node("Moldura") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
		cores_ok = cores_ok and est.border_width_top == 1
	_ok(cortes_ok and visiveis[0] == "Ab" and (visiveis[2] as String).length() < 10,
		"caixa: os nomes à vista são os cortados na célula %s (não o texto anterior ao corte)" % [visiveis])
	# Ordem CAIXA-EXPANDE: o nome a ouro (e a moldura grossa) é SÓ o do cartão grande; nas caixinhas, tudo pergaminho.
	var activa := c.find_child("NomeActiva", true, false) as Label
	_ok(cores_ok and activa.get_theme_color("font_color") == CaixaOrdem.COR_REALCE and activa.text.begins_with("Espadachim"),
		"caixa: o nome a ouro só no cartão grande (%s); nas caixinhas todos pergaminho, moldura fina" % [activa.text.replace("\n", " · ")])
	# Quando a vez passa, quem jogou sai do cartão grande e vai para o fim da fila; a fila anda.
	c.mostrar(ordem5, "d", nomes5, {}, "iniciativa")
	_ok(c.ids_fila == ["e", "a", "b", "c"] and activa.text.begins_with("Ab"),
		"caixa: a vez passa à seguinte — quem jogou (Espadachim) vai para o fim da fila (%s)" % [c.ids_fila])
	# Ordem CAIXA-EXPANDE: a vista expandida — a ordem completa, a vez primeiro e realçada, os nomes inteiros.
	var compacta := c.size
	c.definir_sobre(true)
	await process_frame  # os contentores arrumam as linhas no fim do quadro (só então se mede o texto à vista)
	var lista := c.find_child("Lista", true, false)
	var linhas: Array = []
	for l in lista.get_children():
		linhas.append(str(l.name).trim_prefix("Linha_"))
	var nome_a := lista.get_node("Linha_a/Textos/Nome") as Label
	var vez_l := lista.get_node("Linha_d")
	_ok(c.expandida() and linhas == ["d", "e", "a", "b", "c"] and c.ids_expandida == ["d", "e", "a", "b", "c"],
		"caixa: com o rato por cima cresce e mostra a ordem completa a partir da vez (%s)" % [linhas])
	_ok(c.linhas_cortadas().is_empty() and CaixaOrdem.texto_visivel(nome_a) == "Arqueira de Prata Longa",
		"caixa: na expandida os nomes são completos, sem corte («%s»)" % CaixaOrdem.texto_visivel(nome_a))
	_ok(vez_l.has_node("Textos/NaVez") and (vez_l.get_node("Textos/Nome") as Label).get_theme_color("font_color") == CaixaOrdem.COR_REALCE
		and nome_a.get_theme_color("font_color") == CaixaOrdem.COR_TEXTO and not lista.get_node("Linha_a").has_node("Textos/NaVez"),
		"caixa: na expandida a figura na vez vem realçada como no cartão grande (ouro, «na vez»); as outras a pergaminho")
	_ok(c.size.x >= compacta.x and c.size.y > compacta.y and c.tamanho_compacto() == compacta,
		"caixa: a expandida é maior que a compacta (%s ⊇ %s) e o tamanho compacto continua sabido" % [c.size, compacta])
	c.definir_sobre(false)
	_ok(not c.expandida() and c.size == compacta and not (c.find_child("Expandida", true, false) as Control).visible,
		"caixa: ao tirar o rato volta ao tamanho compacto (%s)" % [c.size])
	# O rato a sério (eventos do motor), o rato imitado a partir de um toque e o toque.
	c.position = Vector2(40, 40)
	var dentro := c.get_global_rect().get_center()
	var fora := c.get_global_rect().end + Vector2(30, 30)
	_mover_rato(dentro, 0)
	var abriu_rato := c.expandida()
	_mover_rato(fora, 0)
	var fechou_rato := not c.expandida()
	_mover_rato(dentro, InputEvent.DEVICE_ID_EMULATION)
	var imitado := c.expandida()
	_ok(abriu_rato and fechou_rato and not imitado,
		"caixa: o rato por cima abre e fora fecha; o rato que o motor imita a partir de um toque não abre (%s/%s/%s)" % [abriu_rato, fechou_rato, imitado])
	_tocar(dentro, dentro)
	var abriu_toque := c.expandida()
	_tocar(dentro, dentro)
	var fechou_toque := not c.expandida()
	_tocar(dentro, dentro)
	_tocar(fora, fora)
	var fechou_fora := not c.expandida()
	_tocar(dentro, dentro + Vector2(0, 200))
	var arrastou := c.expandida()
	_ok(abriu_toque and fechou_toque and fechou_fora and not arrastou,
		"caixa: um toque abre e outro fecha; um toque fora fecha; arrastar não abre (%s/%s/%s/%s)" % [abriu_toque, fechou_toque, fechou_fora, arrastou])
	var vazia: Array[String] = []
	c.mostrar(vazia, "", {}, {}, "dinamico")
	_ok(c.vez_mostrada == "" and (c.find_child("Vazia", true, false) as Label).visible, "caixa: sem acções, diz que a ordem se forma — nada inventado")
	var filhos_ignoram := true
	for n in c.find_children("*", "Control", true, false):
		if n.name != "ModoIniciativa" and n.name != "Expandida" and not (n is ScrollBar) and (n as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			filhos_ignoram = false
	_ok(c.mouse_filter == Control.MOUSE_FILTER_STOP and filhos_ignoram,
		"caixa: só o painel apanha o rato/toque (em cima dela abre a vista); fora dela o tabuleiro recebe-os")
	c.queue_free()


## Ordem CAIXA-EXPANDE: um movimento do rato (device 0 = rato a sério; DEVICE_ID_EMULATION = imitado de um toque).
func _mover_rato(p: Vector2, dispositivo: int) -> void:
	var e := InputEventMouseMotion.new()
	e.device = dispositivo
	e.position = p
	e.global_position = p
	get_root().push_input(e, true)  # já em coordenadas da janela (sem o esticar do ecrã)


## Ordem CAIXA-EXPANDE: um toque (carrega em `a`, levanta em `b`).
func _tocar(a: Vector2, b: Vector2) -> void:
	for k in 2:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.pressed = k == 0
		t.position = a if k == 0 else b
		get_root().push_input(t, true)


# ---------------------------------------------------------------- Ordem ÁGUA-REAÇÃO (o lago reage às figuras)

## Anda `fig` de `a` para `b` (x, z) a `v` m/s, quadro a quadro (30 q/s), com os pés como o lago os põe
## (LagoFloresta.pe_na_agua); devolve o número de quadros.
func _agua_andar(lago, fig: Node3D, a: Vector2, b: Vector2, v: float) -> int:
	var dt := 1.0 / 30.0
	var n := maxi(int(ceil(a.distance_to(b) / (v * dt))), 1)
	for i in range(1, n + 1):
		var q := a.lerp(b, float(i) / float(n))
		fig.position = Vector3(q.x, LagoFloresta.pe_na_agua(q.x, q.y), q.y)
		lago.avancar(dt)
	return n


func _agua_parar(lago, s: float) -> void:
	for i in int(round(s * 30.0)):
		lago.avancar(1.0 / 30.0)


func _teste_agua_reacao() -> void:
	var lago = LagoFloresta.new()
	lago.set_process(false)   # o relógio da água anda à mão
	root.add_child(lago)
	var fig := Node3D.new()
	root.add_child(fig)
	# LAGO-MAIOR: o lago cresceu — rasa_b (14,6; −18,6) caiu na parte de nadar; a nova fica na faixa de andar, ao
	# longo da margem (a 1,1 m da água, como rasa_a). Os outros três sítios continuam a ser o que eram.
	var seco := Vector2(9.2, -15.6)
	var rasa_a := Vector2(13.4, -17.4)
	var rasa_b := Vector2(13.85, -15.75)
	var funda := Vector2(19.5, -21.0)
	_ok(RelevoFloresta.lago_fundura(seco.x, seco.y) <= 0.0 and RelevoFloresta.lago_fundura(rasa_a.x, rasa_a.y) > 0.05
		and not LagoFloresta.a_nadar(rasa_b.x, rasa_b.y) and LagoFloresta.a_nadar(funda.x, funda.y),
		"água-reação: os sítios da prova (seco, rasa, funda) são o que dizem ser (lago_fundura / a_nadar)")
	fig.position = Vector3(seco.x, RelevoFloresta.altura(seco.x, seco.y), seco.y)
	lago.seguir(fig)
	_agua_parar(lago, 0.5)
	_ok(lago.salpicos == 0 and lago.pulsos_vivos() == 0 and is_zero_approx(lago.agito_de(fig)), "água-reação: em seco a água não reage")
	# ---- ENTRAR: o salpico nasce no ponto de contacto, em SALPICO_ANEIS anéis
	var dt := 1.0 / 30.0
	var entrada := -1
	var n := maxi(int(ceil(seco.distance_to(rasa_a) / (0.7 * dt))), 1)
	for i in range(1, n + 1):
		var q := seco.lerp(rasa_a, float(i) / float(n))
		fig.position = Vector3(q.x, LagoFloresta.pe_na_agua(q.x, q.y), q.y)
		lago.avancar(dt)
		if entrada < 0 and lago.salpicos > 0:
			entrada = i
			_ok(lago.imersao(q.x, q.y, fig.position.y) > 0.02, "água-reação: o salpico nasce no quadro em que a figura entra na água")
			_ok(lago.pulsos_vivos() == LagoFloresta.SALPICO_ANEIS, "água-reação: ao entrar, %d anéis (o salpico)" % LagoFloresta.SALPICO_ANEIS)
			_ok(is_equal_approx(lago.agito_de(fig), 1.0), "água-reação: ao entrar, o agito vai a 1")
	_ok(entrada > 0 and lago.salpicos == 1, "água-reação: uma entrada, um salpico")
	# ---- VADEAR: a ondulação acompanha o movimento (proporcional à velocidade)
	_agua_andar(lago, fig, rasa_a, rasa_b, 0.7)
	_ok(lago.agito_de(fig) > 0.99 and lago.pulsos_vivos() > LagoFloresta.SALPICO_ANEIS, "água-reação: a vadear, agito 1 e anéis pelo caminho")
	_agua_parar(lago, LagoFloresta.CALMA_S + 0.2)
	_agua_andar(lago, fig, rasa_b, rasa_a, 0.09)
	var lento: float = lago.agito_de(fig)
	_ok(lento > 0.1 and lento < 0.3, "água-reação: devagar (0,09 m/s) o agito é pequeno (%s): cresce com a velocidade" % snappedf(lento, 0.01))
	# ---- PARADA: a ondulação acalma até sumir
	_agua_andar(lago, fig, rasa_a, rasa_b, 0.7)
	_agua_parar(lago, LagoFloresta.CALMA_S * 0.5)
	var meio: float = lago.agito_de(fig)
	_ok(meio > 0.4 and meio < 0.6, "água-reação: parada há %s s, o agito vai a meio (%s)" % [LagoFloresta.CALMA_S * 0.5, snappedf(meio, 0.01)])
	_agua_parar(lago, LagoFloresta.CALMA_S * 0.5 + 0.1)
	_ok(is_zero_approx(lago.agito_de(fig)), "água-reação: parada há mais de %s s, o agito é 0 (a água acalmou)" % LagoFloresta.CALMA_S)
	_agua_parar(lago, LagoFloresta.VIDA_PULSO_S + 0.5)
	_ok(lago.pulsos_vivos() == 0, "água-reação: parada, os anéis morrem e não nascem outros (só fica o vento)")
	_ok(lago.salpicos == 1, "água-reação: andar e parar dentro de água não salpica")
	# ---- NADAR: ao passar a nadar (LagoFloresta.a_nadar, a fronteira do NADO), outro salpico
	var antes_nado: int = lago.salpicos
	var no_salpico := Vector2.INF
	n = maxi(int(ceil(rasa_b.distance_to(funda) / (0.6 * dt))), 1)
	for i in range(1, n + 1):
		var q := rasa_b.lerp(funda, float(i) / float(n))
		fig.position = Vector3(q.x, LagoFloresta.pe_na_agua(q.x, q.y), q.y)
		lago.avancar(dt)
		if no_salpico == Vector2.INF and lago.salpicos > antes_nado:
			no_salpico = q
	_ok(lago.salpicos == antes_nado + 1 and no_salpico != Vector2.INF and LagoFloresta.a_nadar(no_salpico.x, no_salpico.y),
		"água-reação: ao passar a nadar (a_nadar do NADO), um salpico — e só um")
	_ok(lago.agito_de(fig) > 0.99, "água-reação: a nadar, agito 1")
	# ---- quem já começa dentro de água não entrou: não salpica; e fora da água o agito é 0
	var outra := Node3D.new()
	root.add_child(outra)
	outra.position = Vector3(funda.x, LagoFloresta.pe_na_agua(funda.x, funda.y), funda.y)
	var s0: int = lago.salpicos
	lago.seguir(outra)
	_agua_parar(lago, 0.5)
	_ok(lago.salpicos == s0 and is_zero_approx(lago.agito_de(outra)), "água-reação: posta já dentro de água (parada) não salpica e a água fica calma")
	fig.position = Vector3(seco.x, RelevoFloresta.altura(seco.x, seco.y), seco.y)
	_agua_parar(lago, 0.1)
	_ok(is_zero_approx(lago.agito_de(fig)), "água-reação: fora da água o agito é 0")
	# ---- o shader recebe o agito de cada corpo
	var sh := load("res://mapa/floresta/shaders/agua.gdshader") as Shader
	var tem := false
	for u: Dictionary in sh.get_shader_uniform_list():
		if String(u["name"]) == "corpos_agito":
			tem = true
	_ok(tem, "água-reação: o shader da água tem o uniforme corpos_agito")
	lago.queue_free()
	fig.queue_free()
	outra.queue_free()


# ---------------------------------------------------------------- Ordem ESCALA: a escala do mundo

## A escala do mundo é um parâmetro (1 · 1,5 · 2 m por casa, pré-definida 1,5), numa fonte só por lado: a tabela DADOS
## no cliente e sala.js no servidor. Prova: (1) a tabela; (2) o servidor diz o mesmo; (3) o selector do Mestre e o
## terreno do servidor cobrem exactamente essas escalas; (4) nenhum consumidor guarda um 1,5 solto; (5) as contas em
## metros passam pela escala: 6 m cobrem 6 casas a 1 m, 4 a 1,5 m e 3 a 2 m, medido na geometria da arena.
func _teste_escala_do_mundo() -> void:
	print("Escala do mundo (Ordem ESCALA):")
	var tabela: Array = Apresentacao.ESCALAS_CASA_M
	_ok(tabela == [1.0, 1.5, 2.0], "a tabela tem as escalas 1 · 1,5 · 2 m (veio %s)" % [tabela])
	_ok(is_equal_approx(Apresentacao.CASA_M, 1.5) and tabela.has(Apresentacao.CASA_M), "a pré-definida é 1,5 m e é uma das que valem")

	# (2) o servidor: export const ESCALAS_CASA_M = Object.freeze([1, 1.5, 2]); export const CASA_M = 1.5;
	var sala_js := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../servidor/nucleo/sala.js").simplify_path())
	var do_servidor: Array = []
	var marca_lista := "export const ESCALAS_CASA_M = Object.freeze(["
	var k := sala_js.find(marca_lista)
	if k >= 0:
		var fim := sala_js.find("]", k)
		for v in sala_js.substr(k + marca_lista.length(), fim - k - marca_lista.length()).split(","):
			do_servidor.append(float(v.strip_edges()))
	var marca_padrao := "export const CASA_M = "
	var kp := sala_js.find(marca_padrao)
	var padrao_servidor := -1.0
	if kp >= 0:
		padrao_servidor = float(sala_js.substr(kp + marca_padrao.length(), sala_js.find(";", kp) - kp - marca_padrao.length()))
	_ok(do_servidor == tabela, "o servidor (sala.js ESCALAS_CASA_M) diz o mesmo que a tabela (%s)" % [do_servidor])
	_ok(is_equal_approx(padrao_servidor, Apresentacao.CASA_M), "o servidor nasce na mesma escala pré-definida (sala.js CASA_M)")

	# (3) o selector do Mestre anda nesta lista; o terreno do servidor tem uma tabela por escala (a mesma lista).
	var Mestre = load("res://cenas/mestre/mestre.gd")
	_ok(Mestre.ESCALAS == tabela, "o selector do Mestre (mestre.gd ESCALAS) é a lista da tabela")
	_ok(ExportarTerreno.ESCALAS == tabela, "o terreno do servidor é exportado para cada escala da tabela (exportar_terreno.ESCALAS)")
	var pacote = JSON.parse_string(FileAccess.get_file_as_string(ExportarTerreno.caminho_saida()))
	var no_terreno: Array = []
	if pacote is Dictionary:
		for e in pacote.get("escalas", []):
			no_terreno.append(float(e.get("casaM", 0.0)))
	_ok(no_terreno == tabela, "o pacote do terreno do servidor serve as três escalas (%s)" % [no_terreno])
	var mestre = Mestre.new()
	mestre.vista = {}
	_ok(is_equal_approx(mestre.escala_atual(), Apresentacao.CASA_M), "sem escala do servidor, o Mestre vê a pré-definida (1,5)")
	for v in tabela:
		mestre.vista = {"mapa": {"largura": 20, "altura": 20, "casaM": v}}
		_ok(is_equal_approx(mestre.escala_atual(), v), "o Mestre vê a escala viva que o servidor mandou (%s m)" % v)
	mestre.free()

	# (4) nenhum 1,5 solto nos consumidores (o que resta de 1,5 no cliente é a malha do mapa — ver PENDENCIAS).
	for f in ["res://cenas/arena/arena.gd", "res://cenas/mestre/arena_mestre.gd", "res://cenas/mestre/mestre.gd",
			"res://hud/hud.gd", "res://estado/estado.gd"]:
		_ok(not FileAccess.get_file_as_string(f).contains("1.5"), "%s não guarda um 1,5 solto: lê a escala viva ou a tabela" % f.get_file())

	# (5) metros = casas × escala, na geometria da arena (a mesma que arena.gd e arena_mestre.gd usam).
	var esperado := {1.0: 6, 1.5: 4, 2.0: 3}
	for s in tabela:
		var lado := Apresentacao.GRELHA_LARGURA_PADRAO
		var origem := Assentamento.origem_no_mapa(Vector2(lado * s, lado * s), s)
		var casas: int = floori(6.0 / s + 0.0001)
		var a := Assentamento.centro_casa(origem, s, Vector2i(0, 0))
		var b := Assentamento.centro_casa(origem, s, Vector2i(casas, 0))
		var d := Vector2(b.x - a.x, b.z - a.z).length()
		_ok(casas == int(esperado[s]) and is_equal_approx(d, 6.0),
			"a %s m por casa, 6 m cobrem %d casas (no mundo da arena: %.3f m)" % [s, casas, d])
		var c_fim := Assentamento.centro_casa(origem, s, Vector2i(lado - 1, 0))
		_ok(is_equal_approx(c_fim.x - a.x, (lado - 1) * s), "a %s m por casa, a grelha de %d casas mede %s m" % [s, lado, lado * s])


# ---------------------------------------------------------------- ORDEM MAPA-JOGÁVEL

## ORDEM MAPA-JOGÁVEL (palavra do Mestre, 20/11/2026: «Eu quero que todo o mapa seja jogável» — água incluída).
## A geometria da decisão escala × malha: a grelha-mapa (o maior quadrado que cabe no mapa) em cada escala, com a
## regra da arena (Assentamento.origem_no_mapa) = a tabela do servidor; e o lago dentro dela, casa a casa.
func _teste_mapa_jogavel_geometria() -> void:
	print("Todo o mapa jogável (ORDEM MAPA-JOGÁVEL) — a grelha-mapa:")
	var pacote = JSON.parse_string(FileAccess.get_file_as_string(ExportarTerreno.caminho_saida()))
	var lado_mapa := GrelhaMapa.LADO * GrelhaMapa.CASA_M
	_ok(is_equal_approx(lado_mapa, 75.0) and GrelhaMapa.LADO == 50, "o mapa é 50 × 50 casas de 1,5 m = 75 m (a malha do relevo)")
	# o lado da grelha-mapa por escala e a origem (canto NO): a decisão (75 / 50 / 37; −37,5 / −37,5 / −37)
	var decisao := {1.0: [75, -37.5], 1.5: [50, -37.5], 2.0: [37, -37.0]}
	var motivos: Dictionary = pacote["mapa"]["motivos"] if pacote is Dictionary else {}
	var agua_esperada := {1.0: 301, 1.5: 131, 2.0: 75}   # LAGO-MAIOR (antes: 50 / 21 / 13)
	for e in (pacote.get("escalas", []) if pacote is Dictionary else []):
		var s := float(e["casaM"])
		var lado: int = (e["origensM"] as Array).size()
		_ok(lado == int(decisao[s][0]), "a %s m a grelha-mapa tem %d casas de lado (o servidor: ladoMax)" % [s, lado])
		_ok(lado * s <= lado_mapa + 0.0001 and lado_mapa - lado * s < s, "a %s m cabe no mapa e o que sobra (%.1f m) é menos do que uma casa" % [s, lado_mapa - lado * s])
		var origem := Assentamento.origem_no_mapa(Vector2(lado * s, lado * s), s)
		_ok(origem.is_equal_approx(Vector2(decisao[s][1], decisao[s][1])) and is_equal_approx(float(e["origensM"][lado - 1]), origem.x),
			"a %s m a arena põe a grelha-mapa onde o servidor a tem (origem %s)" % [s, origem])
		# o lago dentro da grelha: as casas do jogo cujo centro cai numa casa do mapa de «água funda» (a regra do servidor)
		var agua := 0
		for y in lado:
			for x in lado:
				var cm := Assentamento.casa_do_mapa(origem, s, Vector2i(x, y))
				if str(motivos.get("%d,%d" % [cm.x, cm.y], "")) in CampoDaMesaT.MOTIVOS_DE_AGUA:
					agua += 1
		_ok(agua == int(agua_esperada[s]), "a %s m o lago tem %d casas de água dentro da grelha (o servidor conta %d)" % [s, agua, agua_esperada[s]])
	# A lista dos motivos de água é a mesma no servidor e é o motivo que o mapa escreve.
	var terreno_js := FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../servidor/nucleo/terreno.js").simplify_path())
	_ok(terreno_js.contains("export const MOTIVOS_DE_AGUA = Object.freeze(['água funda']);") and CampoDaMesaT.MOTIVOS_DE_AGUA == ["água funda"],
		"os motivos de água são os mesmos no cliente e no servidor (terreno.js MOTIVOS_DE_AGUA)")
	_ok(FileAccess.get_file_as_string("res://mapa/floresta/campo_floresta.gd").contains("grelha.bloquear(casa, \"água funda\")"),
		"é esse o motivo que o mapa escreve no lago (campo_floresta.gd)")


## ORDEM MAPA-JOGÁVEL: a casa de água não recusa o pé (as outras bloqueadas sim) e a figura mexe o lago (uma vez).
func _teste_mapa_jogavel_agua() -> void:
	print("Todo o mapa jogável (ORDEM MAPA-JOGÁVEL) — a água:")
	var mapa := MapaDeProva.new()
	mapa.grelha = GrelhaMapa.new()
	for wy in range(9, 12):
		for wx in range(35, 38):
			mapa.grelha.bloquear(Vector2i(wx, wy), "água funda")  # um lago de 3 × 3 casas do mapa, à volta de (36,10)
	mapa.grelha.bloquear(Vector2i(2, 2), "menir")
	# 1,5 m, a grelha-mapa: a casa do jogo é a casa do mapa
	var origem := Assentamento.origem_no_mapa(Vector2(75.0, 75.0), 1.5)
	_ok(CampoDaMesaT.recusa_do_pe(mapa, origem, 1.5, Vector2i(36, 10)) == "", "na casa de água a figura põe-se de pé (não há recusa)")
	_ok(CampoDaMesaT.casa_de_agua(mapa, origem, 1.5, Vector2i(36, 10)), "e a casa é de água")
	var r := CampoDaMesaT.recusa_do_pe(mapa, origem, 1.5, Vector2i(2, 2))
	_ok(r.ends_with("(2,2) menir") and not CampoDaMesaT.casa_de_agua(mapa, origem, 1.5, Vector2i(2, 2)), "o menir continua a recusar (veio «%s»)" % r)
	_ok(CampoDaMesaT.recusa_do_pe(mapa, origem, 1.5, Vector2i(10, 10)) == "" and not CampoDaMesaT.casa_de_agua(mapa, origem, 1.5, Vector2i(10, 10)),
		"a casa seca livre: nem recusa nem água")
	# a 1 m e a 2 m a casa do jogo é a do mapa debaixo do centro: a casa de água (36,10) do mapa (centro 17,25 / −21,75)
	for s in [1.0, 2.0]:
		var lado := 75 if s == 1.0 else 37
		var o := Assentamento.origem_no_mapa(Vector2(lado * s, lado * s), s)
		var c := Vector2i(floori((17.25 - o.x) / s), floori((-21.75 - o.y) / s))
		_ok(CampoDaMesaT.casa_de_agua(mapa, o, s, c) and CampoDaMesaT.recusa_do_pe(mapa, o, s, c) == "",
			"a %s m a casa %s (sobre a água do mapa) é de água e não recusa o pé" % [s, c])
	# a figura mexe o lago: ligada uma vez, por muitas sincronizações; um lago novo (mapa refeito) volta a ligá-la
	var lago := LagoFloresta.new()
	mapa.lago = lago
	root.add_child(mapa)
	mapa.add_child(lago)
	var no := Node3D.new()
	mapa.add_child(no)
	for i in 3:
		CampoDaMesaT.seguir_na_agua(mapa, no, 0.42)
	_ok(lago.segue(no) and lago.a_seguir() == 1, "a figura mexe o lago — ligada uma vez em 3 sincronizações")
	var lago2 := LagoFloresta.new()
	mapa.add_child(lago2)
	mapa.lago = lago2
	CampoDaMesaT.seguir_na_agua(mapa, no, 0.42)
	_ok(lago2.segue(no), "o lago de um mapa refeito também a segue")
	CampoDaMesaT.seguir_na_agua(null, no, 0.42)
	_ok(lago2.a_seguir() == 1, "sem mapa não faz nada")
	# a figura que a arena liberta sai do lago sozinha, sem erro (avancar confere antes de a usar)
	no.free()
	lago2.avancar(0.016)
	_ok(lago2.a_seguir() == 0, "a figura libertada sai do lago no passo seguinte")
	mapa.free()
