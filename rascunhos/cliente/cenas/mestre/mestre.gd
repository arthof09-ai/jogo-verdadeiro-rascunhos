extends Control
## Ecrã do Mestre (JV3.1 — desenho aprovado com emendas pelo Muse, CM-000009, 08/11/2026). I0004.
##
## - Só abre para o lugar do Mestre: noutro papel recusa, escreve no registo e volta ao lobby.
## - À esquerda a arena 3D (arena_mestre.gd, num SubViewport); à direita a folha do Mestre, a toda a
##   altura, em duas colunas: coluna 1 FIXA (o cartão activo e os botões, a fila, a sala, os alertas) e
##   coluna 2 com abas que rolam por dentro (Figuras, Agir, Mesa, Ambiente, Registo, Sala). Cabe a
##   844×390 e a 780×360, com letra de 13 px reais ou mais (testes/medir_mestre.gd).
## - Nada se decide por tempo: os botões só mandam comandos quando o Mestre toca neles.
## - Palavras: cenas/mestre/textos_mestre.gd (as do site e a regra da casa; emenda 1).
## - «Terminar batalha» e «Recomeçar» (N4, palavra do Mestre de 08/11, como no site): aba Sala, com segundo toque;
##   MASTER_SUPERVISOR terminar/recomecar.
## - §12 do desenho: arena 3D, aba Mesa (lobby e colocar), «Voltar até aqui» (L8) e aba Agir (jogar a
##   criatura à mão). «Escolher outra» no cartão de IA fica desligado (ver aba_agir.gd).
## - Ordem 13 (dívida E1): a aba Ambiente manda no clima (a chuva), na hora e nos raios, e tem o «⚡ Raio agora»
##   (MASTER_AMBIENTE). O raio e o fogo narram-se aqui, com os números, e ficam no registo; a Party vê o fogo
##   e o raio, nunca o painel, o combustível nem os dados.
## - Ordem 13 (parte D): o «Exportar registo» leva também a narração deste ecrã (Modelo.conteudo_export).

const Textos := preload("res://cenas/mestre/textos_mestre.gd")
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")
const ArenaMestre := preload("res://cenas/mestre/arena_mestre.gd")
const ControlosLivre := preload("res://cenas/mestre/controlos_camara_livre.gd")
const AbaRegisto := preload("res://cenas/mestre/aba_registo.gd")
const AbaMesa := preload("res://cenas/mestre/aba_mesa.gd")
const AbaAgir := preload("res://cenas/mestre/aba_agir.gd")
## Ordem HUD: a caixa da ordem de turnos (dois modos do Mestre) e os retratos dos próprios modelos.
const OrdemTurnos := preload("res://hud/ordem_turnos.gd")
const CaixaOrdem := preload("res://hud/caixa_ordem.gd")
const Retratos := preload("res://hud/retratos.gd")
const CAIXA_LIGADA := "Caixa da ordem: ligada"
const CAIXA_DESLIGADA := "Caixa da ordem: desligada"
## Ordem 52: a escolha do perfil gráfico das definições — a MESMA da ⚙ da jogadora (o mesmo ficheiro, a mesma chave,
## o mesmo seletor «Gráficos»).
const EscolhaPerfil := preload("res://arte/perfis/escolha_perfil.gd")

const CENA_LOBBY := "res://cenas/lobby/lobby.tscn"
## ORDEM DADOS DE APRESENTAÇÃO: os tamanhos de apresentação vêm da tabela única.
const Apresentacao := preload("res://dados/apresentacao.gd")
const LARGURA_BASE := Apresentacao.LARGURA_BASE
const ALTURA_BASE := Apresentacao.ALTURA_BASE
const FONTE_BASE := Apresentacao.FONTE_BASE
const FONTE_MIN_PX_REAIS := Apresentacao.FONTE_MIN_PX_REAIS
const FRACAO_TABULEIRO := 0.55
const LINHAS_CARTAO := 6
const LINHAS_TITULO := 2
const ARQ_CFG := "user://mestre.cfg"
const ESPERA_VISTA_S := 0.25
## Ordem 49 (A): o tecto da nova tentativa do pedido da vista — 40 pedidos que não saem, de ESPERA_VISTA_S em
## ESPERA_VISTA_S (40 × 0,25 s = 10 s). Chega para o limite de 10 envios/s do aparelho (a janela é de 1 s); a ligação
## que cai e volta arma um pedido novo (`_ao_ligacao`), com a conta do zero.
const TENTATIVAS_VISTA_MAX := 40
## O nome da falha ao fim do tecto (vai ao registo do Godot; o alerta do Mestre é Textos.ALERTA["vista_sem_pedido"]).
const FALHA_VISTA := "vista_sem_pedido"

## Ficou recusado (papel que não é o do Mestre). Os testes lêem-no.
var recusado := false
## Por onde saem os comandos: (tipo, campos, revision) -> id. Os testes trocam-no por uma captura.
var enviar_fn: Callable
## Pedido da MASTER_VIEW (os testes trocam-no).
var pedir_vista_fn: Callable
## Pesquisa de fichas, MASTER_SEARCH (os testes trocam-no).
var pesquisar_fn: Callable
## Ordem 29 (V25): RECEIPT_QUERY com os ids dos comandos em voo, ao voltar à mesa (os testes trocam-no).
var consultar_fn: Callable
## Ordem 34 (N32-1): a confirmação dos alertas por id, MASTER_ALERTA_ACK (os testes trocam-no): (ids, perdidos).
var confirmar_alertas_fn: Callable

var vista: Dictionary = {}
var cartao: Dictionary = {}
var alertas: Array[String] = []
## Ordem 12 (caída atingida): o estadoMorte que este ecrã já viu, por figura (vista + eventos entre vistas), para
## comparar com o que o `ataque` traz; e o que já se narrou ao Mestre (frase + linha do registo).
var mortes: Dictionary = {}
var narracao: Array[String] = []
var som_ligado := true
## Ordem 49 (A): a falha nomeada do pedido da vista (FALHA_VISTA) ao fim do tecto, ou "" (os testes lêem-na). Limpa-se
## quando um pedido sai e quando a conta recomeça.
var falha_vista := ""

## O aviso da primeira entrada já foi visto nesta execução (vale também quando não se escreve em disco).
static var _aviso_visto_sessao := false

var _fonte := FONTE_BASE
var _escala := 1.0
var _tema := Theme.new()
var _encolhida := false
var _em_voo := {}  # id do comando -> true
var _armado := ""  # acção à espera do segundo toque
var _espera_vista := -1.0
## Ordem 49 (A): pedidos da vista que não saíram, seguidos, desde o último pedido novo (o tecto é TENTATIVAS_VISTA_MAX).
var _vista_nao_saiu := 0
var _repassar := false

var _tabuleiro: SubViewportContainer
var _arena: ArenaMestre
## Decisão 10 (ordem 6; site REF_29): os controlos da câmara livre, por cima do tabuleiro. Só aqui.
var _livre: ControlosLivre
var _aba_registo: AbaRegisto
var _aba_mesa: AbaMesa
var _aba_agir: AbaAgir
var _folha: PanelContainer
var _colunas: HBoxContainer
var _col1: VBoxContainer
var _titulo_cartao: Label
var _texto_cartao: Label
var _caixa_botoes: VBoxContainer
## Doca do cartão: altura FIXA e corta o que sobra, para os botões nunca mexerem (F5-MESTRE-01).
var _doca: Control
var _botoes: Array[Button] = []
var _fila: Label
var _sala: Label
var _alerta: Label
var _encolher: Button
var _abas: TabContainer
var _lista_figuras: VBoxContainer
var _lista_ambiente: VBoxContainer
## Ordem 13: os controlos do painel Ambiente.
var _botoes_clima: Dictionary = {}  # clima -> Button
var _raios: Button
var _raio_agora: Button
## Os eventos do ambiente já narrados (seq), para o mesmo evento repetido no fio não narrar duas vezes.
var _amb_narrados := {}
## Ordem 14: a falha crítica de um monstro à espera do evento seguinte (a `desgraca` que a fecha, ou nenhuma).
var _falha_pendente: Dictionary = {}
## Os `ataque` falhados já narrados (seq), para o mesmo evento repetido no fio não narrar duas vezes.
var _falhas_narradas := {}
var _pausar: Button
var _terminar: Button
var _recomecar: Button
## N4: o botão de fim à espera do segundo toque ("terminar", "recomecar" ou "").
var armado_fim := ""
## Ordem 8 (item 8): a escala que o Mestre está a escolher (m por casa) e o segundo toque do «Mudar a escala».
## Ordem 11 (paridade P8a, REF_36 do site): só valem 1 / 1,5 / 2 m por casa; os botões − e + andam nesta lista e
## param nas pontas (o servidor recusa qualquer outro valor).
const ESCALAS := Apresentacao.ESCALAS_CASA_M  # Ordem ESCALA: a lista vive na tabela (DADOS), não aqui
var escala_nova := 0.0
var armado_escala := false
var _escala_rotulo: Label
var _escala_valor: Label
var _escala_menos: Button
var _escala_mais: Button
var _escala_mudar: Button
var _continuar: Button
var _atualizar: Button
var _som: Button
## Ordem 52: a linha «Gráficos» da aba Sala (Baixo / Médio / Alto). Sem escolha guardada, nenhum item marcado.
var _graficos: OptionButton
var _escolha: PanelContainer
## Ordem HUD: a ordem (modelo), a caixa no tabuleiro e o interruptor dela na aba Sala.
var ordem_turnos := OrdemTurnos.new()
var caixa_ligada := true
var _caixa: CaixaOrdem
## Ordem CAIXA-PERSISTENTE: o id do último MASTER_SUPERVISOR op 'caixa' que mandámos. Enquanto ele está em voo, a escolha
## que o Mestre acabou de fazer manda sobre a da vista (que pode ser de antes dela); depois, manda a do servidor.
var _caixa_cmd := ""
var _retratos: Retratos
var _b_caixa: Button
var _lista_escolha: VBoxContainer
var _aviso_primeira: PanelContainer
## Ordem 34 (N32-1): o bloco dos avisos de quando o Mestre estava fora (um bloco, um toque para fechar).
var _bloco_avisos: PanelContainer
var _bloco_rolar: ScrollContainer
var _bloco_texto: Label
var _bloco_fechar: Button


func _ready() -> void:
	if Rede.papel != "mestre":
		recusar("papel «%s»" % Rede.papel)
		return
	if not enviar_fn.is_valid():
		enviar_fn = Callable(Rede, "enviar_mestre")
	if not pedir_vista_fn.is_valid():
		pedir_vista_fn = Callable(Rede, "pedir_vista_mestre")
	if not pesquisar_fn.is_valid():
		pesquisar_fn = Callable(Rede, "pesquisar_fichas")
	if not consultar_fn.is_valid():
		consultar_fn = Callable(Rede, "consultar_recibos")
	if not confirmar_alertas_fn.is_valid():
		confirmar_alertas_fn = Callable(Rede, "confirmar_alertas")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = _tema
	_montar()
	_aplicar_perfil_escolhido()  # Ordem 52: só se o Mestre já escolheu um perfil nas definições
	Rede.mestre_recebido.connect(_ao_mestre)
	Rede.comando_respondido.connect(_ao_resposta)
	Rede.evento_recebido.connect(_ao_evento)
	Rede.sala_pausada.connect(_ao_pausa)
	Rede.sala_retomada.connect(_ao_retomada)
	Rede.ligacao_mudou.connect(_ao_ligacao)
	Rede.precisa_entrar.connect(_ao_precisa_entrar)
	Estado.opcoes_mudaram.connect(func(): _aba_agir.atualizar())
	get_viewport().size_changed.connect(_ao_redimensionar)
	_ao_redimensionar()
	if not Rede.ultima_vista_mestre.is_empty():
		aplicar_vista(Rede.ultima_vista_mestre)
	if not Rede.cartao_ativo.is_empty():
		aplicar_cartao(Rede.cartao_ativo)
	_mostrar_aviso_se_preciso()
	_pedir_vista_agora()


## Defesa da privacidade (desenho §7 b): fora do lugar do Mestre esta cena não mostra nada.
func recusar(porque: String) -> void:
	recusado = true
	print("ecrã do Mestre recusado: %s" % porque)
	for n in get_children():
		n.queue_free()
	if is_inside_tree() and get_tree().current_scene == self:
		get_tree().change_scene_to_file.call_deferred(CENA_LOBBY)
	else:
		queue_free.call_deferred()


func _process(delta: float) -> void:
	if _espera_vista >= 0.0:
		_espera_vista -= delta
		if _espera_vista < 0.0:
			_tentar_vista()


## Ordem 35 (trabalho 2): o pedido que não saiu (`false`: o limite de 10 envios/s do aparelho, ou fora da mesa) volta
## a ser feito daqui a ESPERA_VISTA_S, até sair. Antes perdia-se calado: depois de uma rajada de toques (ex.: o
## «Voltar até aqui» logo a seguir a «Confirmar»), a vista ficava a do instante antigo até chegar outro evento.
## Quem não diz (`null`, as funções dos testes de ecrã) conta como saído.
## Ordem 49 (A): com tecto. Ao fim de TENTATIVAS_VISTA_MAX pedidos que não saem, seguidos, pára e nomeia a falha
## (`falha_vista`, o alerta uma vez e uma linha no registo do Godot) em vez de tentar para sempre. Só recomeçam a
## conta o abrir, o «Atualizar» e a ligação que volta à mesa; um evento ou recibo arma o pedido mas não a recomeça
## (senão um fluxo de eventos com o pedido sempre a falhar voltava a ser um ciclo sem fim): depois do tecto, cada
## evento dá-lhe uma tentativa, sem alerta novo.
func _pedir_vista_agora() -> void:
	_recomecar_conta_vista()
	_tentar_vista()


func _recomecar_conta_vista() -> void:
	_vista_nao_saiu = 0
	falha_vista = ""


func _pedir_vista_em_breve() -> void:
	if _espera_vista < 0.0:
		_espera_vista = ESPERA_VISTA_S


func _tentar_vista() -> void:
	if pedir_vista_fn.call() != false:
		_vista_nao_saiu = 0
		falha_vista = ""
		return
	_vista_nao_saiu += 1
	if _vista_nao_saiu < TENTATIVAS_VISTA_MAX:
		_pedir_vista_em_breve()
		return
	_espera_vista = -1.0
	if falha_vista != "":
		return  # já nomeada neste episódio
	falha_vista = FALHA_VISTA
	push_warning("MASTER_VIEW: %s — o pedido não saiu %d vezes seguidas (%.0f s); parei" % [FALHA_VISTA,
		_vista_nao_saiu, TENTATIVAS_VISTA_MAX * ESPERA_VISTA_S])
	_juntar_alerta(Textos.ALERTA[FALHA_VISTA] % TENTATIVAS_VISTA_MAX)


# ---------------------------------------------------------------- entrada

## N4: «Terminar batalha» (só em combate), com segundo toque «Sim, terminar», como no site.
func pedir_terminar() -> void:
	if str(vista.get("fase", "")) != "combate":
		return
	if armado_fim != "terminar":
		armado_fim = "terminar"
		_desenhar_fim()
		return
	armado_fim = ""
	_enviar("MASTER_SUPERVISOR", {"op": "terminar"})
	_desenhar_fim()


## N4: «Recomeçar» (a mesma batalha do zero; em combate ou depois do fim), com segundo toque.
func pedir_recomecar() -> void:
	var fase := str(vista.get("fase", ""))
	if fase != "combate" and fase != "fim":
		return
	if armado_fim != "recomecar":
		armado_fim = "recomecar"
		_desenhar_fim()
		return
	armado_fim = ""
	_enviar("MASTER_SUPERVISOR", {"op": "recomecar"})
	_desenhar_fim()


## Ordem 8 (item 8): a escala que vale agora (mapa.casaM da vista; a pré-definida da tabela, 1,5, se ainda não veio).
func escala_atual() -> float:
	var mapa = vista.get("mapa")
	if mapa is Dictionary:
		var c = mapa.get("casaM")
		if (c is float or c is int) and float(c) > 0.0:
			return float(c)
	return Apresentacao.CASA_M


func ajustar_escala(passos: int) -> void:
	escala_nova = ESCALAS[clampi(_indice_escala(escala_nova) + passos, 0, ESCALAS.size() - 1)]
	armado_escala = false
	_desenhar_escala()


## Ordem 8 (item 8): «Mudar a escala» (lobby ou combate), com segundo toque. Sem custo; o servidor é dono da posição.
func pedir_escala() -> void:
	var fase := str(vista.get("fase", ""))
	if fase != "lobby" and fase != "combate":
		return
	if is_equal_approx(escala_nova, escala_atual()):
		return
	if not armado_escala:
		armado_escala = true
		_desenhar_escala()
		return
	armado_escala = false
	_enviar("MASTER_SUPERVISOR", {"op": "escala", "casaM": escala_nova})
	_desenhar_escala()


## O índice, em ESCALAS, do valor que vale mais perto de `v` (um valor de fora cai no mais próximo).
static func _indice_escala(v: float) -> int:
	var melhor := 0
	for i in ESCALAS.size():
		if absf(float(ESCALAS[i]) - v) < absf(float(ESCALAS[melhor]) - v):
			melhor = i
	return melhor


static func _metros(v: float) -> String:
	# «3» e não «3.0»; «1,5» com vírgula (centésimos no máximo).
	var cent := int(roundf(v * 100.0))
	var txt := str(cent / 100)
	var resto := cent % 100
	if resto != 0:
		txt += "," + (str(resto).pad_zeros(2).trim_suffix("0") if resto % 10 == 0 else str(resto).pad_zeros(2))
	return txt


func _desenhar_escala() -> void:
	if _escala_rotulo == null:
		return
	if escala_nova <= 0.0:
		escala_nova = escala_atual()
	var fase := str(vista.get("fase", ""))
	var pode := fase == "lobby" or fase == "combate"
	_escala_rotulo.text = Textos.ESCALA_ATUAL % _metros(escala_atual())
	_escala_valor.text = Textos.ESCALA_NOVA % _metros(escala_nova)
	_escala_menos.disabled = not pode or escala_nova <= float(ESCALAS[0]) + 0.001
	_escala_mais.disabled = not pode or escala_nova >= float(ESCALAS.back()) - 0.001
	_escala_mudar.disabled = not pode or is_equal_approx(escala_nova, escala_atual())
	_escala_mudar.text = (Textos.SIM_MUDAR_ESCALA % _metros(escala_nova)) if armado_escala else Textos.MUDAR_ESCALA


func _desenhar_fim() -> void:
	if _terminar == null:
		return
	var fase := str(vista.get("fase", ""))
	_terminar.disabled = fase != "combate"
	_recomecar.disabled = fase != "combate" and fase != "fim"
	_terminar.text = Textos.SIM_TERMINAR if armado_fim == "terminar" else Textos.TERMINAR_BATALHA
	_recomecar.text = Textos.SIM_RECOMECAR if armado_fim == "recomecar" else Textos.RECOMECAR


func aplicar_vista(msg: Dictionary) -> void:
	_fechar_falha({})  # a vista chega depois dos eventos da transacção: uma falha crítica sem `desgraca` fecha-se aqui
	vista = msg
	mortes = Modelo.mortes_da_vista(msg)
	_arena.aplicar_vista(msg)
	_desenhar_figuras()
	_desenhar_ambiente()
	ordem_turnos.carregar_do_servidor(msg.get("ordemDinamica"))  # Ordem INICIATIVA NO SERVIDOR: o servidor é o dono
	_carregar_caixa_do_servidor(msg.get("caixaMestre"))  # Ordem CAIXA-PERSISTENTE: a escolha da caixa também
	_desenhar_ordem()
	_aba_registo.atualizar(msg)
	_aba_mesa.atualizar(msg)
	_aba_agir.atualizar(msg)
	_desenhar_fim()
	_avisar_motor_da_vista(msg)  # ordem 22 (N21-1)
	if not armado_escala:
		escala_nova = escala_atual()  # a vista nova manda; uma escolha a meio (armada) fica até ao segundo toque
	_desenhar_escala()
	_desenhar_cartao()
	if _aviso_primeira.visible and str(msg.get("fase", "")) == "combate":
		_aviso_primeira.visible = false  # emenda 2: nunca por cima da batalha


func aplicar_cartao(msg: Dictionary) -> void:
	var mesmo: bool = not cartao.is_empty() and cartao.get("cartaoId") == msg.get("cartaoId")
	cartao = msg
	if not mesmo:
		_armado = ""
		_fechar_escolha()
		_aba_agir.editar("")
		if som_ligado:
			_avisar_cartao()
	_desenhar_cartao()


func _ao_mestre(msg: Dictionary) -> void:
	match str(msg.get("type", "")):
		"MASTER_VIEW":
			aplicar_vista(msg)
		"MASTER_CARD":
			aplicar_cartao(msg)
		"MASTER_ALERTA":
			_receber_alerta(msg)
		"MASTER_ALERTAS":
			_receber_bloco(msg)
		"MASTER_RESULTS":
			_aba_mesa.receber_resultados(msg)
		"MASTER_EXPORT":
			_guardar_export(msg)
		_:
			pass


func _ao_evento(msg: Dictionary) -> void:
	if ordem_turnos.registar_evento(msg):
		_desenhar_ordem()
	_narrar_falha(msg)
	_narrar_caida(msg)
	_narrar_ambiente(msg)
	_avisar_motor(msg)
	_avisar_figuras_bloqueadas(msg)
	if str(msg.get("tipo", "")) == "cartao_fechado":
		var d = msg.get("dados")
		if d is Dictionary and not cartao.is_empty() and d.get("cartaoId") == cartao.get("cartaoId"):
			cartao = {}
			_armado = ""
			_fechar_escolha()
			_aba_agir.editar("")
			_desenhar_cartao()
	_pedir_vista_em_breve()


## Ordem 62: o servidor recusou a mudança de escala (ou o «Recomeçar») porque deixava figuras em casas que o mapa
## bloqueia — a regra da colocação (CASA_BLOQUEADA). O evento `recusa` (só ao Mestre) traz a lista em
## soMestre.figuras; vai aos alertas com o nome, a casa e o motivo de cada figura, como a recusa do pé da Ordem 60, para
## o Mestre saber quem tirar do caminho. O recibo recusado já dá o alerta genérico («O servidor não aceitou…»); este
## diz porquê. Um alerta por evento (o mesmo seq repetido no fio não o repete).
func _avisar_figuras_bloqueadas(msg: Dictionary) -> void:
	if str(msg.get("tipo", "")) != "recusa":
		return
	var d = msg.get("dados")
	var so = d.get("soMestre") if d is Dictionary else null
	var texto := texto_figuras_bloqueadas(so if so is Dictionary else {}, vista)
	var chave := "bloqueadas:seq:" + str(msg.get("seq", ""))
	if texto == "" or _amb_narrados.has(chave):
		return
	_amb_narrados[chave] = true
	_juntar_alerta(texto)


## Ordem 62: o texto do alerta de uma recusa com figuras em casas bloqueadas ("" se a recusa não traz figuras). Os
## nomes vêm da vista (o nome do Mestre); uma figura que a vista ainda não tem fica com o id.
static func texto_figuras_bloqueadas(so: Dictionary, vista_atual: Dictionary) -> String:
	var lista = so.get("figuras")
	if not (lista is Array) or lista.is_empty():
		return ""
	var partes: Array[String] = []
	for e in lista:
		if not (e is Dictionary):
			continue
		var id := str(e.get("figuraId", ""))
		var f: Dictionary = Modelo.figura(vista_atual, id)
		var nome: String = Modelo.nome_mestre(f) if not f.is_empty() else id
		partes.append("«%s» (%d,%d) %s" % [nome if nome != "" else id, int(e.get("x", 0)), int(e.get("y", 0)), str(e.get("motivo", ""))])
	if partes.is_empty():
		return ""
	var chave := "recomeco_bloqueado" if str(so.get("detalhe", "")).begins_with("RECOMECAR") else "escala_bloqueada"
	return Textos.ALERTA[chave] % "; ".join(partes)


## Ordem 21 (N18-2, decisão do Mestre): o servidor restaurou a sala no fim com um motor de outra versão; o «Recomeçar»
## vai ser recusado (17-3). O journal traz o evento `aviso_motor` (só ao Mestre): vai aos alertas.
## Ordem 22 (N21-1, decisão do Mestre): o mesmo aviso vem também na MASTER_VIEW (`avisoMotor`), para o Mestre que entra
## de fresco (sem lastSeq não recebe eventos). Um alerta por par de versões (gravada → agora), venha pelo fluxo ou pela
## vista: a vista repete-se a cada pedido e o evento pode chegar depois dela.
func _avisar_motor(msg: Dictionary) -> void:
	if str(msg.get("tipo", "")) != "aviso_motor":
		return
	var d = msg.get("dados")
	var so = d.get("soMestre") if d is Dictionary else null
	_alertar_motor(so if so is Dictionary else {}, str(msg.get("seq", "")))


func _avisar_motor_da_vista(msg: Dictionary) -> void:
	var a = msg.get("avisoMotor")
	if a is Dictionary:
		_alertar_motor(a, "")


func _alertar_motor(aviso: Dictionary, seq_reserva: String) -> void:
	var chave := "motor:%s>%s" % [str(aviso.get("motorGravado", "")), str(aviso.get("motorAgora", ""))]
	if not aviso.has("motorGravado") and not aviso.has("motorAgora"):
		chave = "motor:seq:" + seq_reserva  # evento sem soMestre (não devia acontecer): como na ordem 21, por seq
	if _amb_narrados.has(chave):
		return
	_amb_narrados[chave] = true
	_juntar_alerta(texto_aviso_motor(aviso))


## Ordem 34 (N27-2): o texto do aviso do motor. Com `quaisDiferem` (os nomes dos campos que diferem), cada um em
## palavra simples e todos de uma vez, num alerta só («a versão de dano mudou», «… e …»). Sem o campo (evento de um
## journal de antes desta ordem), o texto de sempre. O hash (motorGravado/motorAgora) nunca entra no texto.
static func texto_aviso_motor(aviso: Dictionary) -> String:
	var frases: Array[String] = []
	var quais = aviso.get("quaisDiferem")
	if quais is Array:
		for nome in ["vlabSha", "dmgVersao", "levelupSha"]:  # a ordem fixa do contrato
			if quais.has(nome):
				frases.append(Textos.MOTOR_MUDOU[nome])
	if frases.is_empty():
		return Textos.ALERTA["aviso_motor"]
	var junto := frases[0]
	if frases.size() == 2:
		junto = "%s e %s" % [frases[0], frases[1]]
	elif frases.size() == 3:
		junto = "%s, %s e %s" % [frases[0], frases[1], frases[2]]
	return Textos.ALERTA["aviso_motor_qual"] % junto


## Ordem 12 (paridade com o site, REF_35): a heroína já caída levou um golpe e o motor subiu-lhe as falhas. O site
## narra «ela, caída, piora visivelmente» e regista a falha por golpe; aqui o mesmo, SÓ neste ecrã (o lugar da jogadora
## nunca carrega cenas/mestre/). Nada de regra: compara o estadoMorte de antes com o que o servidor mandou.
func _narrar_caida(msg: Dictionary) -> void:
	var r := Modelo.falha_por_golpe(msg, mortes, vista)
	var novas := Modelo.mortes_do_evento(msg)
	for k in novas:
		mortes[k] = novas[k]  # o mesmo evento repetido já não volta a narrar (as falhas deixam de subir)
	if r.is_empty():
		return
	var frase := Modelo.frase_caida_piora(vista, r)
	var linha := Modelo.linha_registo_caida(vista, r)
	narracao.append(frase + "\n" + linha)
	_juntar_alerta(frase)
	_aba_registo.narrar(frase, linha)


## Ordem 14 (paridade com o site, jogo.js atacarIA e série de oportunidade): o monstro falhou o golpe. A frase do site
## com o verbo da ficha (verbos.falha), ao Mestre (alerta + registo). Na falha crítica espera-se o evento seguinte: a
## `desgraca` do mesmo atacante junta a frase dela; qualquer outro evento (ou a vista) fecha com «O golpe correu mal.».
func _narrar_falha(msg: Dictionary) -> void:
	if not _falha_pendente.is_empty():
		var desg := Modelo.desgraca_da_falha(msg, _falha_pendente)
		_fechar_falha(desg)
		if not desg.is_empty():
			return
	var r := Modelo.falha_do_monstro(msg, vista)
	if r.is_empty():
		return
	var chave := str(msg.get("seq", ""))  # como no ambiente: o mesmo evento repetido no fio traz o mesmo seq
	if chave != "" and _falhas_narradas.has(chave):
		return
	if chave != "":
		_falhas_narradas[chave] = true
	if r.get("critica") == true:
		_falha_pendente = r
		return
	_escrever_falha(r, {})


func _fechar_falha(desg: Dictionary) -> void:
	if _falha_pendente.is_empty():
		return
	var r := _falha_pendente
	_falha_pendente = {}
	_escrever_falha(r, desg)


func _escrever_falha(r: Dictionary, desg: Dictionary) -> void:
	var frase := Modelo.frase_falha_monstro(vista, r, desg)
	var linha := Modelo.linha_registo_falha(vista, r, desg)
	narracao.append(frase + "\n" + linha)
	_juntar_alerta(frase)
	_aba_registo.narrar(frase, linha)


## Ordem 13 (dívida E1): o raio, o fogo e quem se apagou, narrados ao Mestre (frase do site + linha com os números).
func _narrar_ambiente(msg: Dictionary) -> void:
	var lista := Modelo.narrar_ambiente(msg, vista)
	if lista.is_empty():
		return
	var chave := str(msg.get("seq", ""))
	if chave != "" and _amb_narrados.has(chave):
		return
	if chave != "":
		_amb_narrados[chave] = true
	for n in lista:
		var frase: String = n["frase"]
		var linha: String = n["linha"]
		narracao.append(linha if frase == "" else frase + "\n" + linha)
		if frase != "":
			_juntar_alerta(frase)
		_aba_registo.narrar(frase, linha)


# ---------------------------------------------------------------- painel Ambiente (ordem 13)

func mudar_clima(clima: String) -> void:
	_enviar("MASTER_AMBIENTE", {"clima": clima})


func mudar_hora(passo: int) -> void:
	_enviar("MASTER_AMBIENTE", Modelo.hora_mais(vista, passo))


func alternar_raios() -> void:
	_enviar("MASTER_AMBIENTE", Modelo.alternar_raios(vista))


## «⚡ Raio agora»: um raio ao acaso no começo da rodada seguinte (o servidor confere e sorteia).
func pedir_raio() -> void:
	if not Modelo.raio_agora_possivel(vista):
		return
	if _enviar("MASTER_AMBIENTE", {"raioAgora": true}) != "":
		_juntar_alerta(Textos.RAIO_PEDIDO)


func _ao_resposta(id: String, msg: Dictionary) -> void:
	if not _em_voo.has(id):
		return
	_em_voo.erase(id)
	var recusada := str(msg.get("type", "")) == "ROOM_REJECT" or str(msg.get("estado", "")) == "RECUSADA"
	# Ordem 29 (V25): DESCONHECIDA (resposta à consulta depois de a ligação cair) = o servidor não o aplicou. Não é
	# recusa (nenhum alerta): destranca o cartão; no esquema conta como não feita (pára e a colocação fica na lista).
	var desconhecida := str(msg.get("estado", "")) == "DESCONHECIDA"
	if recusada:
		var texto := str(msg.get("texto", "")) if msg.get("texto") is String else str(msg.get("motivo", ""))
		_juntar_alerta(Textos.ALERTA["recusa"] % texto)
	_aba_mesa.resposta(id, recusada or desconhecida)  # L5: o esquema de colocação segue (ou pára) com cada recibo
	_desenhar_cartao()
	_pedir_vista_em_breve()


func _ao_pausa(_motivo: String) -> void:
	_juntar_alerta(Textos.ALERTA["pausa"])
	_pedir_vista_em_breve()


func _ao_retomada() -> void:
	_pedir_vista_em_breve()


func _ao_ligacao(_e: int) -> void:
	if not Rede.na_mesa():
		_juntar_alerta(Textos.ALERTA["ligacao"])
	else:
		_consultar_em_voo()
		_recomecar_conta_vista()  # Ordem 49 (A): de volta à mesa, a conta do tecto recomeça
		_pedir_vista_em_breve()


## Ordem 29 (V25): a ligação caiu com comandos em voo e os recibos deles podem ter-se perdido. Sem eles o `_em_voo`
## nunca se esvaziava (botões do cartão desligados até ao fim da sessão, esquema parado). Ao voltar à mesa pergunta-se
## por eles (RECEIPT_QUERY, que o servidor responde aos cmdId/intentId do Mestre); a resposta chega por `_ao_resposta`.
func _consultar_em_voo() -> void:
	if _em_voo.is_empty():
		return
	consultar_fn.call(_em_voo.keys())


func _ao_precisa_entrar(_motivo: String) -> void:
	if is_inside_tree() and get_tree().current_scene == self:
		get_tree().change_scene_to_file.call_deferred(CENA_LOBBY)


# ---------------------------------------------------------------- comandos

## Para as abas: manda um comando do Mestre (com cmdId/intentId e revisão) e devolve o id ("" se não saiu).
func enviar(tipo: String, campos: Dictionary) -> String:
	return _enviar(tipo, campos)


func pesquisar(texto: String) -> void:
	pesquisar_fn.call(texto)


## Destaca casas na arena (as que o servidor mandou nas opções).
func destacar(casas: Array[Vector2i]) -> void:
	_arena.destacar(casas)


## Casa tocada na arena: primeiro o «Colocar» da aba Mesa, depois o «Mover» da aba Agir.
func casa_tocada(casa: Vector2i) -> void:
	if _aba_mesa.colocar(casa):
		return
	_aba_agir.mover(casa)


func _enviar(tipo: String, campos: Dictionary) -> String:
	var id: String = enviar_fn.call(tipo, campos, Estado.revisao)
	if id == "":
		_juntar_alerta(Textos.ALERTA["sem_envio"])
		return ""
	_em_voo[id] = true
	return id


## Toque num botão do cartão. As acções «duas_vezes» só mandam ao segundo toque.
func tocar(acao: String) -> void:
	if cartao.is_empty() or not _em_voo.is_empty():
		return
	var desc := Modelo.descrever_cartao(cartao, vista)
	var botao: Dictionary = {}
	for b in desc["botoes"]:
		if b["acao"] == acao:
			botao = b
	if botao.is_empty() or botao.get("ligado") != true:
		return
	if acao == "escolher":
		if str(cartao.get("tipo", "")) == "ia":
			# L10: o servidor manda as opções da criatura com o cartão aberto; escolhe-se na aba Agir.
			_aba_agir.editar(str(cartao.get("cartaoId", "")))
			mostrar_aba(_aba_agir)
		else:
			_abrir_escolha()
		return
	if botao["duas_vezes"] and _armado != acao:
		_armado = acao
		_desenhar_cartao()
		return
	_armado = ""
	var cmd := Modelo.comando(cartao, acao)
	if not cmd.is_empty():
		_enviar(cmd["tipo"], cmd["campos"])
		if acao == "jogo_eu":
			mostrar_aba(_aba_agir)  # a IA pára: a vez passa à mão do Mestre
	_desenhar_cartao()


func mostrar_aba(aba: Control) -> void:
	var rolar := aba.get_parent()
	for i in _abas.get_tab_count():
		if _abas.get_tab_control(i) == rolar:
			_abas.current_tab = i


## Escolha na lista do «Escolher outra» (L2: só a lista do cartão).
func escolher(desgraca: String) -> void:
	if cartao.is_empty() or not _em_voo.is_empty():
		return
	if desgraca == "acerta-amigo" and not Modelo.amigos_para_escolher(cartao).is_empty():
		_abrir_escolha_amigo()  # Q12: mais de um amigo ao alcance — o Mestre declara qual
		return
	var cmd := Modelo.comando(cartao, "escolha", desgraca)
	if cmd.is_empty():
		return
	_fechar_escolha()
	_enviar(cmd["tipo"], cmd["campos"])
	_desenhar_cartao()


## Ordem 8 (item 5): «Não acontece nada» na lista do «Escolher outra» → MASTER_APPROVE recusar {semDesgraca}.
func escolher_nada() -> void:
	if cartao.is_empty() or not _em_voo.is_empty():
		return
	var cmd := Modelo.comando(cartao, "nada")
	if cmd.is_empty():
		return
	_fechar_escolha()
	_enviar(cmd["tipo"], cmd["campos"])
	_desenhar_cartao()


func exportar_registo() -> void:
	# «exportar» é isento de revisão e não tem recibo: a resposta é o MASTER_EXPORT.
	enviar_fn.call("MASTER_SUPERVISOR", {"op": "exportar"}, Estado.revisao)


func _guardar_export(msg: Dictionary) -> String:
	var nome := "user://registo-MESTRE-ONLY-%s.json" % Time.get_datetime_string_from_system().replace(":", "-")
	var f := FileAccess.open(nome, FileAccess.WRITE)
	if f != null:
		# Ordem 13 (parte D): o registo do servidor, intacto, e a narração deste ecrã.
		f.store_string(JSON.stringify(Modelo.conteudo_export(msg.get("conteudo", {}), narracao)))
		f.close()
	_aba_registo.mostrar_export(nome.get_file())
	return nome


# ---------------------------------------------------------------- desenho

func _desenhar_cartao() -> void:
	if _titulo_cartao == null:
		return
	var desc := Modelo.descrever_cartao(cartao, vista)
	_titulo_cartao.text = desc["titulo"]
	_texto_cartao.text = "\n".join(PackedStringArray(desc["linhas"]))
	var botoes: Array = desc["botoes"]
	for i in _botoes.size():
		var b := _botoes[i]
		if i < botoes.size():
			var d: Dictionary = botoes[i]
			b.visible = true
			b.text = Textos.DE_NOVO_PARA % d["rotulo"] if _armado == d["acao"] else d["rotulo"]
			if not _em_voo.is_empty():
				b.text = Textos.A_ENVIAR if i == 0 else b.text
			b.disabled = d.get("ligado") != true or not _em_voo.is_empty()
			b.set_meta("acao", d["acao"])
		else:
			b.visible = false
	var abertos := Modelo.cartoes_abertos(vista).size()
	_fila.text = Textos.FILA % (abertos - 1) if abertos > 1 else ""
	_fila.visible = abertos > 1
	_sala.text = Modelo.linha_sala(vista) if not vista.is_empty() else ""


func _desenhar_figuras() -> void:
	for n in _lista_figuras.get_children():
		n.queue_free()
	for f in Modelo.figuras_por_ordem(vista):
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.text = Modelo.linha_figura(vista, f)
		# Ordem 60: a figura que o mapa não deixa pôr de pé diz porquê na folha (a recusa do pé: arena_mestre.gd).
		var motivo: String = _arena.motivo_do_pe_recusado(str(f.get("id", "")))
		if motivo != "":
			l.text += Textos.NAO_DE_PE % motivo
		l.set_meta("figura", str(f.get("id", "")))
		_lista_figuras.add_child(l)


func _desenhar_ambiente() -> void:
	for n in _lista_ambiente.get_children():
		n.queue_free()
	for linha in Modelo.linhas_ambiente(vista):
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.text = linha
		_lista_ambiente.add_child(l)
	if _raios == null:
		return
	var a := Modelo.painel_ambiente(vista)
	_raios.text = Textos.DESLIGAR_RAIOS if a.get("raios") == true else Textos.LIGAR_RAIOS
	_raio_agora.disabled = not Modelo.raio_agora_possivel(vista)
	for c in _botoes_clima:
		(_botoes_clima[c] as Button).disabled = str(a.get("clima", "")) == c


func _juntar_alerta(texto: String) -> void:
	if texto == "":
		return
	alertas.append(texto)
	_alerta.text = Textos.ALERTAS % alertas.size() + "\n" + texto


## Ordem 34 (N32-1): o alerta ao vivo. Confirma-se ao servidor pelo id (sai da fila); o mesmo id outra vez (a ligação
## caiu antes de a confirmação chegar) não aparece duas vezes, mas confirma-se outra vez.
func _receber_alerta(msg: Dictionary) -> void:
	var id := str(msg.get("id", "")) if msg.get("id") is String else ""
	if id == "":
		_juntar_alerta(Modelo.texto_alerta(msg))  # servidor de antes da fila: como sempre
		return
	confirmar_alertas_fn.call([id], 0)
	if Rede.alertas_vistos.has(id):
		return
	Rede.alertas_vistos[id] = true
	_juntar_alerta(Modelo.texto_alerta(msg))


## Ordem 34 (N32-1): o bloco dos avisos de quando estava fora (vem com a MASTER_VIEW). Um bloco, por ordem: primeiro
## «perdidos por limite: N» (se houve perdas), depois «N avisos enquanto estavas fora:» e um aviso por linha, com a
## hora. Tudo se confirma (ids e perdidos); o que já foi mostrado (o mesmo id; os mesmos perdidos) não se repete.
func _receber_bloco(msg: Dictionary) -> void:
	var lista: Array = msg.get("alertas") if msg.get("alertas") is Array else []
	var perdidos := int(msg.get("perdidos")) if (msg.get("perdidos") is int or msg.get("perdidos") is float) else 0
	var ids: Array = []
	var novos: Array = []
	for a in lista:
		if not (a is Dictionary) or not (a.get("id") is String):
			continue
		var id := str(a.get("id"))
		ids.append(id)
		if not Rede.alertas_vistos.has(id):
			Rede.alertas_vistos[id] = true
			novos.append(a)
	if not ids.is_empty() or perdidos > 0:
		confirmar_alertas_fn.call(ids, perdidos)
	var mostrar_perdidos := perdidos > 0 and perdidos != Rede.perdidos_mostrados
	Rede.perdidos_mostrados = perdidos
	if novos.is_empty() and not mostrar_perdidos:
		return
	var linhas: Array[String] = []
	if mostrar_perdidos:
		linhas.append(Textos.PERDIDOS_LIMITE % perdidos)
	if not novos.is_empty():
		linhas.append(Textos.AVISOS_FORA_1 if novos.size() == 1 else Textos.AVISOS_FORA % novos.size())
		for a in novos:
			linhas.append(Textos.LINHA_AVISO % [hora_local(str(a.get("hora", ""))), Modelo.texto_alerta(a)])
	var texto := "\n".join(linhas)
	if _bloco_avisos.visible and _bloco_texto.text != "":
		texto = _bloco_texto.text + "\n" + texto  # ainda aberto: junta-se ao mesmo bloco, nunca outra janela
	_bloco_texto.text = texto
	_bloco_avisos.visible = true
	_ao_redimensionar()


func _fechar_bloco() -> void:
	_bloco_avisos.visible = false
	_bloco_texto.text = ""


## Ordem 34 (N32-1): «HH:MM» na hora deste aparelho, a partir da hora ISO do servidor (UTC). Sem hora legível: «--:--».
static func hora_local(iso: String) -> String:
	if iso.length() < 16 or iso[13] != ":":
		return "--:--"
	var h := iso.substr(11, 2)
	var m := iso.substr(14, 2)
	if not (h.is_valid_int() and m.is_valid_int()):
		return "--:--"
	var bias := int(Time.get_time_zone_from_system().get("bias", 0))
	var minutos := posmod(int(h) * 60 + int(m) + bias, 24 * 60)
	return "%02d:%02d" % [floori(minutos / 60.0), minutos % 60]


func _avisar_cartao() -> void:
	# Aviso só neste aparelho: vibra no telemóvel (o som entra com os assets da V2.1).
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(200)


func _abrir_escolha() -> void:
	for n in _lista_escolha.get_children():
		n.queue_free()
	var titulo := Label.new()
	titulo.text = Textos.ESCOLHER_TITULO
	_lista_escolha.add_child(titulo)
	var lista = cartao.get("desgracas")
	if lista is Array:
		for d in lista:
			var b := Button.new()
			b.text = str(Textos.NOME_DESGRACA.get(str(d), str(d)))
			b.set_meta("desgraca", str(d))
			b.pressed.connect(escolher.bind(str(d)))
			_lista_escolha.add_child(b)
	# Ordem 8 (item 5; REF_34): ao recusar a proposta, «Não acontece nada» — fora da tabela, só do Mestre.
	var nada := Button.new()
	nada.name = "NaoAconteceNada"
	nada.text = Textos.NAO_ACONTECE_NADA
	nada.set_meta("sem_desgraca", true)
	nada.pressed.connect(escolher_nada)
	_lista_escolha.add_child(nada)
	var voltar := Button.new()
	voltar.text = Textos.VOLTAR
	voltar.pressed.connect(_fechar_escolha)
	_lista_escolha.add_child(voltar)
	_escolha.visible = true


## Q12: a segunda lista do «Escolher outra» → «Acerta um amigo»: os amigos elegíveis, do mais perto.
func _abrir_escolha_amigo() -> void:
	for n in _lista_escolha.get_children():
		n.queue_free()
	var titulo := Label.new()
	titulo.text = Textos.ESCOLHER_AMIGO
	_lista_escolha.add_child(titulo)
	var nomes := {}
	for f in Modelo.figuras(vista):
		if f is Dictionary:
			nomes[str(f.get("id", ""))] = Modelo.nome_mestre(f)
	for a in Modelo.amigos_para_escolher(cartao):
		var b := Button.new()
		b.text = str(nomes.get(str(a), str(a)))
		b.set_meta("amigo", str(a))
		b.pressed.connect(escolher_amigo.bind(str(a)))
		_lista_escolha.add_child(b)
	var voltar := Button.new()
	voltar.text = Textos.VOLTAR
	voltar.pressed.connect(_abrir_escolha)
	_lista_escolha.add_child(voltar)
	_escolha.visible = true


func escolher_amigo(aliado_id: String) -> void:
	if cartao.is_empty() or not _em_voo.is_empty():
		return
	var cmd := Modelo.comando(cartao, "amigo", aliado_id)
	if cmd.is_empty():
		return
	_fechar_escolha()
	_enviar(cmd["tipo"], cmd["campos"])
	_desenhar_cartao()


func _fechar_escolha() -> void:
	if _escolha != null:
		_escolha.visible = false


func _mostrar_aviso_se_preciso() -> void:
	var visto := _aviso_visto_sessao
	if not visto and Rede.persistir:
		var cfg := ConfigFile.new()
		if cfg.load(ARQ_CFG) == OK:
			visto = cfg.get_value("ecra", "aviso_visto", false) == true
	var fase := str(vista.get("fase", Estado.fase))
	_aviso_primeira.visible = not visto and fase != "combate"


func _aviso_entendido() -> void:
	_aviso_visto_sessao = true
	_aviso_primeira.visible = false
	if Rede.persistir:
		var cfg := ConfigFile.new()
		cfg.load(ARQ_CFG)
		cfg.set_value("ecra", "aviso_visto", true)
		cfg.save(ARQ_CFG)


func _alternar_folha() -> void:
	_encolhida = not _encolhida
	_ao_redimensionar()


# ---------------------------------------------------------------- montagem e tamanho

func _montar() -> void:
	# Arena 3D num SubViewport (o lado esquerdo). stretch: o SubViewport segue o tamanho do contentor.
	_tabuleiro = SubViewportContainer.new()
	_tabuleiro.name = "Tabuleiro"
	_tabuleiro.stretch = true
	add_child(_tabuleiro)
	var sv := SubViewport.new()
	sv.name = "Vista3D"
	sv.own_world_3d = true
	sv.handle_input_locally = true
	_tabuleiro.add_child(sv)
	_arena = ArenaMestre.new()
	_arena.name = "ArenaMestre"
	sv.add_child(_arena)
	_arena.casa_tocada.connect(casa_tocada)
	_arena.recusas_novas.connect(_juntar_alerta)  # Ordem 60: a recusa do pé vê-se nos alertas
	_livre = ControlosLivre.new()
	add_child(_livre)
	_livre.montar(_arena)
	# Ordem HUD: a caixa da ordem de turnos, por cima do tabuleiro (em cima, à esquerda).
	_retratos = Retratos.new()
	_retratos.name = "Retratos"
	add_child(_retratos)
	_caixa = CaixaOrdem.new()
	_caixa.com_botao = true
	_caixa.visible = false
	_caixa.pediu_iniciativa.connect(definir_modo_iniciativa)
	add_child(_caixa)
	# A caixa fica por baixo dos controlos de cima do tabuleiro: ao entrar/sair da câmara livre, muda de sítio
	# (em diferido: o «Entrar» muda antes dos outros controlos da câmara livre).
	_livre.entrar_botao.visibility_changed.connect(_desenhar_ordem, CONNECT_DEFERRED)

	_folha = PanelContainer.new()
	_folha.name = "Folha"
	add_child(_folha)
	_colunas = HBoxContainer.new()
	_folha.add_child(_colunas)

	# Coluna 1: fixa, nunca rola.
	_col1 = VBoxContainer.new()
	_col1.name = "Coluna1"
	_col1.clip_contents = true
	_colunas.add_child(_col1)
	_doca = Control.new()
	_doca.name = "Doca"
	_doca.clip_contents = true
	_col1.add_child(_doca)
	var dentro := VBoxContainer.new()
	dentro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_doca.add_child(dentro)
	_titulo_cartao = _rotulo(dentro, "TituloCartao")
	_titulo_cartao.max_lines_visible = LINHAS_TITULO
	_texto_cartao = _rotulo(dentro, "TextoCartao")
	_texto_cartao.max_lines_visible = LINHAS_CARTAO
	_texto_cartao.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_caixa_botoes = VBoxContainer.new()
	_caixa_botoes.name = "Botoes"
	_col1.add_child(_caixa_botoes)
	for i in 3:
		var b := Button.new()
		b.name = "Botao%d" % i
		b.visible = false
		b.pressed.connect(func(): tocar(str(b.get_meta("acao", ""))))
		_caixa_botoes.add_child(b)
		_botoes.append(b)
	_fila = _rotulo(_col1, "Fila")
	_sala = _rotulo(_col1, "Sala")
	_alerta = _rotulo(_col1, "Alerta")
	_alerta.max_lines_visible = 2
	_encolher = Button.new()
	_encolher.name = "Encolher"
	_encolher.pressed.connect(_alternar_folha)
	_col1.add_child(_encolher)

	# Coluna 2: abas que rolam por dentro.
	var col2 := Control.new()
	col2.name = "Coluna2"
	col2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_colunas.add_child(col2)
	_abas = TabContainer.new()
	_abas.name = "Abas"
	_abas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_abas.clip_tabs = false
	col2.add_child(_abas)
	_lista_figuras = _aba(Textos.ABA_FIGURAS)
	_aba_agir = _aba_com(Textos.ABA_AGIR, AbaAgir.new()) as AbaAgir
	_aba_agir.montar(self)
	_aba_mesa = _aba_com(Textos.ABA_MESA, AbaMesa.new()) as AbaMesa
	_aba_mesa.montar(self)
	_montar_ambiente(_aba(Textos.ABA_AMBIENTE))
	_aba_registo = _aba_com(Textos.ABA_REGISTO_CURTA, AbaRegisto.new()) as AbaRegisto
	_aba_registo.montar(self)
	var sala := _aba(Textos.ABA_SALA)
	_terminar = _botao(sala, Textos.TERMINAR_BATALHA, pedir_terminar)
	_recomecar = _botao(sala, Textos.RECOMECAR, pedir_recomecar)
	_pausar = _botao(sala, Textos.PAUSAR, func(): _enviar("MASTER_PAUSE", {}))
	_continuar = _botao(sala, Textos.CONTINUAR, func(): _enviar("MASTER_RESUME", {}))
	_atualizar = _botao(sala, Textos.ATUALIZAR, func(): _pedir_vista_agora())
	_som = _botao(sala, Textos.SOM_LIGADO, _alternar_som)
	_b_caixa = _botao(sala, CAIXA_LIGADA, func(): ligar_caixa(not caixa_ligada))
	_b_caixa.name = "LigarCaixaOrdem"
	# Ordem 52: «Gráficos», o mesmo seletor da ⚙ da jogadora (arte/perfis/escolha_perfil.gd).
	var linha_graficos := HBoxContainer.new()
	linha_graficos.name = "LinhaGraficos"
	sala.add_child(linha_graficos)
	var rotulo_graficos := _rotulo(linha_graficos, "GraficosRotulo")
	rotulo_graficos.text = Textos.GRAFICOS
	rotulo_graficos.autowrap_mode = TextServer.AUTOWRAP_OFF
	_graficos = EscolhaPerfil.seletor()
	_graficos.name = "Graficos"
	_graficos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graficos.item_selected.connect(_ao_graficos)
	linha_graficos.add_child(_graficos)
	# Ordem 8 (item 8): mudar a escala a meio da batalha.
	_escala_rotulo = _rotulo(sala, "EscalaAtual")
	var linha_escala := HBoxContainer.new()
	linha_escala.name = "LinhaEscala"
	sala.add_child(linha_escala)
	_escala_menos = _botao(linha_escala, Textos.ESCALA_MENOS, ajustar_escala.bind(-1))
	_escala_valor = _rotulo(linha_escala, "EscalaNova")
	_escala_valor.autowrap_mode = TextServer.AUTOWRAP_OFF
	_escala_valor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_escala_mais = _botao(linha_escala, Textos.ESCALA_MAIS, ajustar_escala.bind(1))
	_escala_mudar = _botao(sala, Textos.MUDAR_ESCALA, pedir_escala)

	# «Escolher outra»: por cima da coluna 2, nunca empurra os botões da coluna 1.
	_escolha = PanelContainer.new()
	_escolha.name = "Escolha"
	_escolha.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_escolha.visible = false
	col2.add_child(_escolha)
	var rolar := ScrollContainer.new()
	_escolha.add_child(rolar)
	_lista_escolha = VBoxContainer.new()
	_lista_escolha.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolar.add_child(_lista_escolha)

	# Aviso da primeira entrada (emenda 2): uma vez só, curto.
	_aviso_primeira = PanelContainer.new()
	_aviso_primeira.name = "AvisoPrimeira"
	_aviso_primeira.visible = false
	add_child(_aviso_primeira)
	var caixa := VBoxContainer.new()
	_aviso_primeira.add_child(caixa)
	_rotulo(caixa, "AvisoTexto").text = Textos.AVISO_PRIMEIRA
	_botao(caixa, Textos.ENTENDIDO, _aviso_entendido)

	# Ordem 34 (N32-1): o bloco dos avisos de quando o Mestre estava fora — um bloco só, a rolar se for comprido, e um
	# toque («Fechar») para o fechar.
	_bloco_avisos = PanelContainer.new()
	_bloco_avisos.name = "BlocoAvisos"
	_bloco_avisos.visible = false
	add_child(_bloco_avisos)
	var caixa_bloco := VBoxContainer.new()
	_bloco_avisos.add_child(caixa_bloco)
	_bloco_rolar = ScrollContainer.new()
	_bloco_rolar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	caixa_bloco.add_child(_bloco_rolar)
	_bloco_texto = Label.new()
	_bloco_texto.name = "BlocoTexto"
	_bloco_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bloco_texto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bloco_rolar.add_child(_bloco_texto)
	_bloco_fechar = _botao(caixa_bloco, Textos.FECHAR_AVISOS, _fechar_bloco)
	_bloco_fechar.name = "FecharAvisos"
	_desenhar_cartao()


## Ordem 13: a aba Ambiente — as linhas do painel e, por baixo, os controlos (clima, hora, raios, «⚡ Raio agora»).
func _montar_ambiente(aba: VBoxContainer) -> void:
	_lista_ambiente = VBoxContainer.new()
	_lista_ambiente.name = "LinhasAmbiente"
	aba.add_child(_lista_ambiente)
	var climas := HFlowContainer.new()
	climas.name = "Climas"
	aba.add_child(climas)
	for c in Textos.CLIMA_BOTOES:
		var b := _botao(climas, str(Textos.NOME_CLIMA.get(c, c)), mudar_clima.bind(c))
		b.name = "Clima_" + c
		_botoes_clima[c] = b
	var horas := HBoxContainer.new()
	horas.name = "Horas"
	aba.add_child(horas)
	_botao(horas, Textos.HORA_MENOS, mudar_hora.bind(-1)).name = "HoraMenos"
	_botao(horas, Textos.HORA_MAIS, mudar_hora.bind(1)).name = "HoraMais"
	_raios = _botao(aba, Textos.LIGAR_RAIOS, alternar_raios)
	_raios.name = "Raios"
	_raio_agora = _botao(aba, Textos.RAIO_AGORA, pedir_raio)
	_raio_agora.name = "RaioAgora"
	_raio_agora.disabled = true


func _aba(titulo: String) -> VBoxContainer:
	return _aba_com(titulo, VBoxContainer.new())


## Uma aba que rola por dentro, com `conteudo` lá dentro.
func _aba_com(titulo: String, conteudo: VBoxContainer) -> VBoxContainer:
	var rolar := ScrollContainer.new()
	rolar.name = titulo
	rolar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_abas.add_child(rolar)
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolar.add_child(conteudo)
	return conteudo


func _rotulo(pai: Node, nome: String) -> Label:
	var l := Label.new()
	l.name = nome
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pai.add_child(l)
	return l


func _botao(pai: Node, texto: String, acao: Callable) -> Button:
	var b := Button.new()
	b.text = texto
	b.pressed.connect(acao)
	pai.add_child(b)
	return b


## Ordem 52: o perfil que ficou escolhido nas definições (user://preferencias.cfg [pref] perfil, a chave da ⚙ da
## jogadora) aplica-se à arena do Mestre ao abrir. Sem escolha guardada, ou sem disco (Rede.persistir falso, como o
## mestre.cfg), não se aplica nada: a relva fica a 1,0 e o clima no Médio, como antes.
func _aplicar_perfil_escolhido() -> void:
	var nome := EscolhaPerfil.escolhido() if Rede.persistir else ""
	if nome != "":
		escolher_perfil(nome, false)


## Ordem 52: o Mestre escolhe um perfil na linha «Gráficos». A arena dele obedece (o mesmo AplicadorPerfil da arena
## do jogador) e a escolha fica guardada na mesma chave da ⚙ da jogadora. Devolve false se o nome não é um perfil.
func escolher_perfil(nome: String, guardar := true) -> bool:
	var chave := AplicadorPerfil.normalizar(nome)
	if not EscolhaPerfil.PERFIS.has(chave) or not _arena.aplicar_perfil(chave):
		return false
	_graficos.select(EscolhaPerfil.PERFIS.find(chave))
	if guardar and Rede.persistir:
		EscolhaPerfil.guardar(chave)
	return true


func _ao_graficos(i: int) -> void:
	if i >= 0 and i < EscolhaPerfil.PERFIS.size():
		escolher_perfil(EscolhaPerfil.PERFIS[i])


func _alternar_som() -> void:
	som_ligado = not som_ligado
	_som.text = Textos.SOM_LIGADO if som_ligado else Textos.SOM_DESLIGADO


func _ao_redimensionar() -> void:
	if _folha == null:
		return
	var janela := Vector2(get_window().size)
	_escala = minf(janela.x / LARGURA_BASE, janela.y / ALTURA_BASE)
	if _escala <= 0.0:
		_escala = 1.0
	# canvas_items + expand: 1 unidade = _escala px reais. Garante ≥ 13 px reais (como o HUD).
	_fonte = maxi(FONTE_BASE, ceili(FONTE_MIN_PX_REAIS / _escala))
	_tema.default_font_size = _fonte
	var area := get_viewport_rect().size
	var largura_col1 := float(_fonte) * 14.0
	_col1.custom_minimum_size = Vector2(largura_col1, 0.0)
	for b in _botoes:
		b.custom_minimum_size = Vector2(0.0, _fonte * 2.2)
	var fonte_res := get_theme_default_font()
	var altura_linha := fonte_res.get_height(_fonte) if fonte_res != null else float(_fonte) * 1.4
	_doca.custom_minimum_size = Vector2(0.0, ceilf(altura_linha * (LINHAS_TITULO + LINHAS_CARTAO) + float(_fonte) * 0.5))
	var margem := float(_fonte) * 0.5
	var largura_folha := area.x * (1.0 - FRACAO_TABULEIRO)
	if _encolhida:
		largura_folha = largura_col1 + margem * 2.0
	# A barra das abas nunca se corta: a folha alarga o que for preciso (o tabuleiro encolhe).
	if not _encolhida:
		var largura_abas := _abas.get_tab_bar().get_minimum_size().x + float(_fonte)
		largura_folha = maxf(largura_folha, largura_col1 + largura_abas + margem * 3.0)
		largura_folha = minf(largura_folha, area.x * 0.85)
	largura_folha = maxf(largura_folha, largura_col1 + margem * 2.0)
	_folha.position = Vector2(area.x - largura_folha, 0.0)
	_folha.size = Vector2(largura_folha, area.y)
	(_colunas.get_child(1) as Control).visible = not _encolhida
	_encolher.text = "▸" if _encolhida else "◂"
	_tabuleiro.position = Vector2.ZERO
	_tabuleiro.size = Vector2(area.x - largura_folha, area.y)
	_livre.ajustar(Rect2(_tabuleiro.position, _tabuleiro.size), _escala)
	_caixa.ajustar(_fonte)
	_desenhar_ordem()
	_aviso_primeira.position = Vector2(margem * 2.0, margem * 2.0)
	_aviso_primeira.custom_minimum_size = Vector2(minf(area.x - largura_folha - margem * 4.0, float(_fonte) * 18.0), 0.0)
	_aviso_primeira.size = _aviso_primeira.custom_minimum_size
	# Ordem 34 (N32-1): o bloco dos avisos por cima do tabuleiro; a lista rola até metade da altura.
	if _bloco_avisos:
		var largura_bloco := maxf(minf(area.x - largura_folha - margem * 4.0, float(_fonte) * 24.0), float(_fonte) * 10.0)
		var n_linhas := maxi(_bloco_texto.text.count("\n") + 1, 1)
		var alto := minf(altura_linha * float(n_linhas) * 1.3 + float(_fonte) * 0.5, area.y * 0.5)
		_bloco_rolar.custom_minimum_size = Vector2(largura_bloco - margem * 2.0, alto)
		_bloco_avisos.position = Vector2(margem * 2.0, margem * 2.0)
		_bloco_avisos.custom_minimum_size = Vector2(largura_bloco, 0.0)
		_bloco_avisos.size = _bloco_avisos.get_combined_minimum_size()
	# A letra nova só muda o tamanho mínimo da barra das abas no quadro seguinte: uma segunda passagem.
	if _repassar:
		_repassar = false
	else:
		_repassar = true
		_ao_redimensionar.call_deferred()


# ---------------------------------------------------------------- Ordem HUD: a caixa da ordem de turnos

## O Mestre liga ou desliga a caixa (aba Sala). Desligada, o ecrã fica como antes; a ordem continua a formar-se
## por baixo, para aparecer certa quando ele a voltar a ligar.
func ligar_caixa(ligar: bool) -> void:
	_mostrar_caixa_ligada(ligar)
	_desenhar_ordem()
	_guardar_caixa()


func _mostrar_caixa_ligada(ligar: bool) -> void:
	caixa_ligada = ligar
	if _b_caixa != null:
		_b_caixa.text = CAIXA_LIGADA if ligar else CAIXA_DESLIGADA


## O botão «Modo iniciativa» da caixa. Ligado: a ordem é a de iniciativa que o servidor dá (`iniciativa` da vista —
## só a ordem; os valores vêm da configuração da sala, o cliente não rola nem inventa a fórmula). Desligado: manda o
## modo dinâmico, com a ordem formada pelas acções.
func definir_modo_iniciativa(ligar: bool) -> void:
	ordem_turnos.definir_modo(OrdemTurnos.INICIATIVA if ligar else OrdemTurnos.DINAMICO)
	_desenhar_ordem()
	_guardar_caixa()


## Ordem CAIXA-PERSISTENTE: a escolha da caixa (ligada, modo) vai para o servidor, que a guarda no estado da sala e a
## devolve em cada MASTER_VIEW — o Mestre que sai e volta a entrar a meio da batalha reconstrói a caixa com ela.
func _guardar_caixa() -> void:
	_caixa_cmd = _enviar("MASTER_SUPERVISOR", {"op": "caixa", "caixa": {"ligada": caixa_ligada, "modo": ordem_turnos.modo}})


## Ordem CAIXA-PERSISTENTE: a escolha da vista (`caixaMestre` {ligada, modo}) passa a ser a da caixa. Não mexe se a
## vista não a traz (servidor de antes desta ordem) nem enquanto a escolha que o Mestre acabou de fazer está em voo.
func _carregar_caixa_do_servidor(c) -> void:
	if _caixa_cmd != "" and _em_voo.has(_caixa_cmd):
		return
	_caixa_cmd = ""
	if not (c is Dictionary) or not (c.get("ligada") is bool):
		return
	_mostrar_caixa_ligada(c["ligada"])
	ordem_turnos.definir_modo(str(c.get("modo", "")))


## Ordem HUD: a caixa fica no canto de cima, à esquerda, mas POR BAIXO dos controlos de cima do tabuleiro — o
## «Entrar na câmera livre» e, dentro da câmara livre, o «Voltar à câmera do jogo» e a dica —, para nunca os tapar.
## Se, dentro da câmara livre, ainda assim tocar num controlo de andar (ecrãs baixos), sai de cena até o Mestre sair
## da câmara livre: nunca tapa um controlo.
func _posicionar_caixa() -> void:
	if _caixa == null or _livre == null:
		return
	var margem := float(_fonte) * 0.5
	var y := margem * 2.0
	for n in [_livre.entrar_botao, _livre.sair_botao, _livre.dica]:
		var c := n as Control
		if c.visible:
			y = maxf(y, _livre.position.y + c.position.y + c.size.y + margem)
	_caixa.position = Vector2(margem * 2.0, y)
	_caixa.size = _caixa.get_combined_minimum_size()
	var r := Rect2(_caixa.position, _caixa.size)
	for n in [_livre.manipulo, _livre.sobe_botao, _livre.desce_botao, _livre.vel_caixa]:
		var c := n as Control
		if c.visible and r.intersects(Rect2(_livre.position + c.position, c.size)):
			_caixa.visible = false
			return


func _desenhar_ordem() -> void:
	if _caixa == null:
		return
	var fase := str(vista.get("fase", ""))
	_caixa.visible = caixa_ligada and (fase == "combate" or fase == "pausa")
	if not _caixa.visible:
		return
	var figs := {}
	var nomes := {}
	for f in Modelo.figuras(vista):
		if f is Dictionary and f.get("colocada") == true:
			var id := str(f.get("id", ""))
			figs[id] = f
			nomes[id] = Modelo.nome_mestre(f)
	var ini = vista.get("iniciativa")
	var ordem := ordem_turnos.ordem_visivel(ini if ini is Array else [], figs)
	var vez_id := str(vista.get("vezId")) if vista.get("vezId") is String else ""
	var retratos := {}
	for id in ordem:
		var f: Dictionary = figs[id]
		var chave := "%s|%s|%s|%s" % [f.get("marcador"), f.get("alturaM"), f.get("caido") == true, f.get("vivo") == false]
		_retratos.pedir(id, chave, _arena.modelo_da_figura(id))
		if _retratos.tem(id):
			retratos[id] = _retratos.textura(id)
	_retratos.esquecer_ausentes(figs)
	_caixa.mostrar(ordem, ordem_turnos.na_vez(vez_id), nomes, retratos, ordem_turnos.modo)
	_posicionar_caixa()
