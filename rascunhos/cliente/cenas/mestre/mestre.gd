extends Control
## Ecrã do Mestre (JV3.1 — desenho aprovado com emendas pelo Muse, CM-000009, 08/11/2026). I0004.
##
## - Só abre para o lugar do Mestre: noutro papel recusa, escreve no registo e volta ao lobby.
## - Tabuleiro à esquerda; à direita a folha do Mestre, a toda a altura, em duas colunas:
##   coluna 1 FIXA (o cartão activo e os botões, a fila, a sala, os alertas) e coluna 2 com abas que
##   rolam por dentro (Figuras, Ambiente, Registo da batalha, Sala). Cabe a 844×390 e a 780×360,
##   com letra de 13 px reais ou mais (testes/medir_mestre.gd).
## - Nada se decide por tempo: os botões só mandam comandos quando o Mestre toca neles.
## - Palavras: cenas/mestre/textos_mestre.gd (as do site e a regra da casa; emenda 1).
## - Terminar/recomeçar a batalha: TODO(N4-TERMINAR) em textos_mestre.gd (emenda 3; não se inventa).
## - Ainda por fazer (ordem do §12 do desenho): a arena 3D, a aba Lobby/Colocar, o «Voltar até
##   aqui» (precisa da L8) e a aba Agir (jogar a criatura à mão; «Escolher outra» no cartão de IA).

const Textos := preload("res://cenas/mestre/textos_mestre.gd")
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")
const Tabuleiro := preload("res://cenas/mestre/tabuleiro_mestre.gd")

const CENA_LOBBY := "res://cenas/lobby/lobby.tscn"
const LARGURA_BASE := 1920.0
const ALTURA_BASE := 1080.0
const FONTE_BASE := 22
const FONTE_MIN_PX_REAIS := 13.0
const FRACAO_TABULEIRO := 0.55
const LINHAS_CARTAO := 6
const ARQ_CFG := "user://mestre.cfg"
const ESPERA_VISTA_S := 0.25

## Ficou recusado (papel que não é o do Mestre). Os testes lêem-no.
var recusado := false
## Por onde saem os comandos: (tipo, campos, revision) -> id. Os testes trocam-no por uma captura.
var enviar_fn: Callable
## Pedido da MASTER_VIEW (os testes trocam-no).
var pedir_vista_fn: Callable

var vista: Dictionary = {}
var cartao: Dictionary = {}
var alertas: Array[String] = []
var som_ligado := true

## O aviso da primeira entrada já foi visto nesta execução (vale também quando não se escreve em disco).
static var _aviso_visto_sessao := false

var _fonte := FONTE_BASE
var _escala := 1.0
var _tema := Theme.new()
var _encolhida := false
var _em_voo := {}  # id do comando -> true
var _armado := ""  # acção à espera do segundo toque
var _espera_vista := -1.0

var _tabuleiro: Control
var _folha: PanelContainer
var _colunas: HBoxContainer
var _col1: VBoxContainer
var _titulo_cartao: Label
var _texto_cartao: Label
var _caixa_botoes: VBoxContainer
var _botoes: Array[Button] = []
var _fila: Label
var _sala: Label
var _alerta: Label
var _encolher: Button
var _abas: TabContainer
var _lista_figuras: VBoxContainer
var _lista_ambiente: VBoxContainer
var _registo_info: Label
var _exportar: Button
var _pausar: Button
var _continuar: Button
var _atualizar: Button
var _som: Button
var _escolha: PanelContainer
var _lista_escolha: VBoxContainer
var _aviso_primeira: PanelContainer


func _ready() -> void:
	if Rede.papel != "mestre":
		recusar("papel «%s»" % Rede.papel)
		return
	if not enviar_fn.is_valid():
		enviar_fn = Callable(Rede, "enviar_mestre")
	if not pedir_vista_fn.is_valid():
		pedir_vista_fn = Callable(Rede, "pedir_vista_mestre")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = _tema
	_montar()
	Rede.mestre_recebido.connect(_ao_mestre)
	Rede.comando_respondido.connect(_ao_resposta)
	Rede.evento_recebido.connect(_ao_evento)
	Rede.sala_pausada.connect(_ao_pausa)
	Rede.sala_retomada.connect(_ao_retomada)
	Rede.ligacao_mudou.connect(_ao_ligacao)
	Rede.precisa_entrar.connect(_ao_precisa_entrar)
	get_viewport().size_changed.connect(_ao_redimensionar)
	_ao_redimensionar()
	if not Rede.ultima_vista_mestre.is_empty():
		aplicar_vista(Rede.ultima_vista_mestre)
	if not Rede.cartao_ativo.is_empty():
		aplicar_cartao(Rede.cartao_ativo)
	_mostrar_aviso_se_preciso()
	pedir_vista_fn.call()


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
			pedir_vista_fn.call()


func _pedir_vista_em_breve() -> void:
	if _espera_vista < 0.0:
		_espera_vista = ESPERA_VISTA_S


# ---------------------------------------------------------------- entrada

func aplicar_vista(msg: Dictionary) -> void:
	vista = msg
	(_tabuleiro as Tabuleiro).vista = msg
	_desenhar_figuras()
	_desenhar_ambiente()
	_registo_info.text = Textos.JOURNAL % int(msg.get("journalSeq", 0))
	_desenhar_cartao()
	if _aviso_primeira.visible and str(msg.get("fase", "")) == "combate":
		_aviso_primeira.visible = false  # emenda 2: nunca por cima da batalha


func aplicar_cartao(msg: Dictionary) -> void:
	var mesmo: bool = not cartao.is_empty() and cartao.get("cartaoId") == msg.get("cartaoId")
	cartao = msg
	if not mesmo:
		_armado = ""
		_fechar_escolha()
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
			_juntar_alerta(Modelo.texto_alerta(msg))
		"MASTER_EXPORT":
			_guardar_export(msg)
		_:
			pass


func _ao_evento(msg: Dictionary) -> void:
	if str(msg.get("tipo", "")) == "cartao_fechado":
		var d = msg.get("dados")
		if d is Dictionary and not cartao.is_empty() and d.get("cartaoId") == cartao.get("cartaoId"):
			cartao = {}
			_armado = ""
			_fechar_escolha()
			_desenhar_cartao()
	_pedir_vista_em_breve()


func _ao_resposta(id: String, msg: Dictionary) -> void:
	if not _em_voo.has(id):
		return
	_em_voo.erase(id)
	var recusada := str(msg.get("type", "")) == "ROOM_REJECT" or str(msg.get("estado", "")) == "RECUSADA"
	if recusada:
		var texto := str(msg.get("texto", "")) if msg.get("texto") is String else str(msg.get("motivo", ""))
		_juntar_alerta(Textos.ALERTA["recusa"] % texto)
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
		_pedir_vista_em_breve()


func _ao_precisa_entrar(_motivo: String) -> void:
	if is_inside_tree() and get_tree().current_scene == self:
		get_tree().change_scene_to_file.call_deferred(CENA_LOBBY)


# ---------------------------------------------------------------- comandos

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
	_desenhar_cartao()


## Escolha na lista do «Escolher outra» (L2: só a lista do cartão).
func escolher(desgraca: String) -> void:
	if cartao.is_empty() or not _em_voo.is_empty():
		return
	var cmd := Modelo.comando(cartao, "escolha", desgraca)
	if cmd.is_empty():
		return
	_fechar_escolha()
	_enviar(cmd["tipo"], cmd["campos"])
	_desenhar_cartao()


func _exportar_registo() -> void:
	# «exportar» é isento de revisão e não tem recibo: a resposta é o MASTER_EXPORT.
	enviar_fn.call("MASTER_SUPERVISOR", {"op": "exportar"}, Estado.revisao)


func _guardar_export(msg: Dictionary) -> void:
	var nome := "user://registo-MESTRE-ONLY-%s.json" % Time.get_datetime_string_from_system().replace(":", "-")
	var f := FileAccess.open(nome, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(msg.get("conteudo", {})))
		f.close()
	_registo_info.text = Textos.REGISTO_EXPORTADO % nome.get_file()


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


func _juntar_alerta(texto: String) -> void:
	if texto == "":
		return
	alertas.append(texto)
	_alerta.text = Textos.ALERTAS % alertas.size() + "\n" + texto


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
	var voltar := Button.new()
	voltar.text = Textos.VOLTAR
	voltar.pressed.connect(_fechar_escolha)
	_lista_escolha.add_child(voltar)
	_escolha.visible = true


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
	_tabuleiro = Tabuleiro.new()
	_tabuleiro.name = "Tabuleiro"
	add_child(_tabuleiro)

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
	_titulo_cartao = _rotulo(_col1, "TituloCartao")
	_texto_cartao = _rotulo(_col1, "TextoCartao")
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
	_lista_ambiente = _aba(Textos.ABA_AMBIENTE)
	var registo := _aba(Textos.ABA_REGISTO)
	_registo_info = _rotulo(registo, "RegistoInfo")
	_exportar = _botao(registo, Textos.EXPORTAR_REGISTO, _exportar_registo)
	_rotulo(registo, "VoltarFalta").text = Textos.VOLTAR_ATE_AQUI_FALTA
	var sala := _aba(Textos.ABA_SALA)
	_pausar = _botao(sala, Textos.PAUSAR, func(): _enviar("MASTER_PAUSE", {}))
	_continuar = _botao(sala, Textos.CONTINUAR, func(): _enviar("MASTER_RESUME", {}))
	_atualizar = _botao(sala, Textos.ATUALIZAR, func(): pedir_vista_fn.call())
	_som = _botao(sala, Textos.SOM_LIGADO, _alternar_som)

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
	_desenhar_cartao()


func _aba(titulo: String) -> VBoxContainer:
	var rolar := ScrollContainer.new()
	rolar.name = titulo
	rolar.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_abas.add_child(rolar)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rolar.add_child(v)
	return v


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
	_texto_cartao.custom_minimum_size = Vector2(0.0, float(_fonte) * 1.45 * LINHAS_CARTAO)
	var margem := float(_fonte) * 0.5
	var largura_folha := area.x * (1.0 - FRACAO_TABULEIRO)
	if _encolhida:
		largura_folha = largura_col1 + margem * 2.0
	largura_folha = maxf(largura_folha, largura_col1 + margem * 2.0)
	_folha.position = Vector2(area.x - largura_folha, 0.0)
	_folha.size = Vector2(largura_folha, area.y)
	(_colunas.get_child(1) as Control).visible = not _encolhida
	_encolher.text = "▸" if _encolhida else "◂"
	_tabuleiro.position = Vector2.ZERO
	_tabuleiro.size = Vector2(area.x - largura_folha, area.y)
	_aviso_primeira.position = Vector2(margem * 2.0, margem * 2.0)
	_aviso_primeira.custom_minimum_size = Vector2(minf(area.x - largura_folha - margem * 4.0, float(_fonte) * 18.0), 0.0)
	_aviso_primeira.size = _aviso_primeira.custom_minimum_size
