extends PanelContainer
## Ordem HUD — a CAIXA DA ORDEM DE TURNOS no ecrã de batalha (desenho = palavra do Mestre, 16/11/2026 11:18).
##
## Mostra a ordem QUE EXISTE — a formada pelas acções (modo dinâmico) ou a do servidor (modo iniciativa) — em fila,
## com o RETRATO de cada figura (hud/retratos.gd). À esquerda, o cartão da figura activa (a que está na vez), com o
## retrato maior. Nunca adivinha turnos futuros. Só desenha: a ordem vem de hud/ordem_turnos.gd e as regras do
## servidor. Não apanha toques fora dos botões (o tabuleiro por baixo continua a receber-os).

## O Mestre carregou em «Modo iniciativa» (true = ligar).
signal pediu_iniciativa(ligar: bool)

const TITULO := "Ordem de turnos"
const MODO_DINAMICO := "dinâmica (pelas acções)"
const MODO_INICIATIVA := "iniciativa"
const BOTAO_INICIATIVA := "Modo iniciativa"
const VAZIA := "A ordem forma-se à medida que as figuras agem."
const VAZIA_INICIATIVA := "O servidor ainda não deu a ordem de iniciativa."
const NA_VEZ := "na vez"
## Medidas em múltiplos do tamanho da letra (como o resto do ecrã do Mestre).
## Ordem CAIXA-PADRAO-BUSTO (palavra do Mestre, 21/11/2026 19:52: «tem que ser tudo padronizado»): cada quadradinho
## da fila tem uma CÉLULA DE TAMANHO FIXO — o retrato quadrado deste lado e, por baixo, uma linha de nome da mesma
## largura. O nome nunca alarga a célula: corta-se com «…» dentro dela. O cartão da figura na vez (LADO_ACTIVA) é
## outro elemento e continua maior.
const LADO_RETRATO_EM_LETRAS := 3.4
## A letra do nome por baixo de cada quadradinho (fracção da letra do ecrã).
const LETRA_NOME := 0.75
const LADO_ACTIVA_EM_LETRAS := 4.6
const MAX_LETRAS_NOME := 10
## As cores vêm da tabela de apresentação (dados/apresentacao.gd). Ordem CAIXA-TESTE-ESTETICA (teste visual,
## 21/11/2026): a linguagem do protótipo — painel castanho quase preto a .55, moldura ouro c9a227 a .85, letras
## pergaminho f3e9d2, fundo do retrato rgba(10,8,5,.82). Nenhuma outra cor: a figura na vez destaca-se pela moldura de
## ouro mais grossa (3 contra 1) e pelo nome a ouro; as outras levam o nome a pergaminho.
const Apresentacao := preload("res://dados/apresentacao.gd")
const COR_PAINEL := Apresentacao.COR_CAIXA_PAINEL
const COR_MOLDURA := Apresentacao.COR_CAIXA_MOLDURA
const COR_REALCE := Apresentacao.COR_CAIXA_MOLDURA
const COR_TEXTO := Apresentacao.COR_CAIXA_TEXTO
const COR_FUNDO_RETRATO := Apresentacao.COR_RETRATO_FUNDO

var modo := "dinamico"
var com_botao := false
var _fonte := 22
var _titulo: Label
var _modo_rotulo: Label
var _botao: Button
var _activa_retrato: TextureRect
var _activa_moldura: PanelContainer
var _activa_nome: Label
var _activa: VBoxContainer
## Ordem CAIXA-JANELA (B3): a fila é uma grelha. Sem limite (o ecrã do Mestre) tem uma coluna por figura — uma linha só,
## como antes. Com `limitar_largura` (o HUD da jogadora em ecrãs baixos) parte em linhas para caber na largura dada.
var _fila: GridContainer
## A largura máxima da caixa (unidades do ecrã). 0 = sem limite.
var _max_largura := 0.0
var _vazia: Label
## Uma linha de nome escondida, só para medir a altura da linha de nome das células (tamanho_celula).
var _medida_nome: Label
## Para os testes e as provas: o que a caixa mostra agora.
var ids_mostrados: Array[String] = []
var vez_mostrada := ""


func _init() -> void:
	name = "CaixaOrdem"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = COR_PAINEL
	fundo.set_corner_radius_all(8)
	fundo.set_content_margin_all(8)
	add_theme_stylebox_override("panel", fundo)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	var cabeca := HBoxContainer.new()
	cabeca.name = "Cabeca"
	cabeca.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(cabeca)
	_titulo = _rotulo(cabeca, "Titulo", TITULO)
	_modo_rotulo = _rotulo(cabeca, "Modo", "")
	_modo_rotulo.modulate = Color(1, 1, 1, 0.7)
	_modo_rotulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_botao = Button.new()
	_botao.name = "ModoIniciativa"
	_botao.text = BOTAO_INICIATIVA
	_botao.toggle_mode = true
	_botao.visible = false
	_botao.toggled.connect(func(b: bool): pediu_iniciativa.emit(b))
	cabeca.add_child(_botao)
	var corpo := HBoxContainer.new()
	corpo.name = "Corpo"
	corpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(corpo)
	_activa = VBoxContainer.new()
	_activa.name = "Activa"
	_activa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corpo.add_child(_activa)
	_activa_moldura = _moldura(true)
	_activa.add_child(_activa_moldura)
	_activa_retrato = _activa_moldura.get_child(0) as TextureRect
	_activa_nome = _rotulo(_activa, "NomeActiva", "")
	_activa_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fila = GridContainer.new()
	_fila.name = "Fila"
	_fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corpo.add_child(_fila)
	_medida_nome = _rotulo(col, "MedidaNome", "Ág")
	_medida_nome.visible = false
	_vazia = _rotulo(corpo, "Vazia", VAZIA)
	_vazia.modulate = Color(1, 1, 1, 0.75)
	_vazia.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vazia.size_flags_horizontal = Control.SIZE_EXPAND_FILL


## Mostra a ordem. `nomes`: id -> texto; `retratos`: id -> Texture2D (ou ausente: a moldura fica com o fundo).
func mostrar(ordem: Array[String], vez: String, nomes: Dictionary, retratos: Dictionary, modo_novo: String) -> void:
	modo = modo_novo
	ids_mostrados = ordem.duplicate()
	vez_mostrada = vez if ordem.has(vez) else ""
	_modo_rotulo.text = "· " + (MODO_INICIATIVA if modo == "iniciativa" else MODO_DINAMICO)
	_botao.visible = com_botao
	_botao.set_pressed_no_signal(modo == "iniciativa")
	for c in _fila.get_children():
		_fila.remove_child(c)
		c.queue_free()
	var celula := tamanho_celula()
	for id in ordem:
		# A célula é um Control de tamanho FIXO (não um contentor que some o que leva): o retrato quadrado em cima, a
		# linha do nome por baixo, postos à mão. Nada do que leva a pode alargar.
		var slot := Control.new()
		slot.name = "Slot_" + id
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.custom_minimum_size = celula
		slot.clip_contents = true
		var m := _moldura(id == vez_mostrada)
		(m.get_child(0) as TextureRect).texture = retratos.get(id)
		slot.add_child(m)
		m.position = Vector2.ZERO
		m.custom_minimum_size = Vector2(celula.x, celula.x)
		m.size = m.custom_minimum_size
		var n := _rotulo(slot, "Nome", _curto(str(nomes.get(id, id))))
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.add_theme_font_size_override("font_size", _letra_nome())
		# O nome não mede a célula: corta-se dentro da largura fixa (com «…»).
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		n.position = Vector2(0.0, celula.x)
		n.size = Vector2(celula.x, celula.y - celula.x)
		if id == vez_mostrada:
			n.add_theme_color_override("font_color", COR_REALCE)
		_fila.add_child(slot)
	_activa.visible = vez_mostrada != ""
	if _activa.visible:
		var la := float(_fonte) * LADO_ACTIVA_EM_LETRAS
		_activa_moldura.custom_minimum_size = Vector2(la, la)
		_activa_retrato.texture = retratos.get(vez_mostrada)
		_activa_nome.text = "%s\n%s" % [_curto(str(nomes.get(vez_mostrada, vez_mostrada))), NA_VEZ]
	_vazia.visible = ordem.is_empty()
	_vazia.text = VAZIA_INICIATIVA if modo == "iniciativa" else VAZIA
	_fila.visible = not ordem.is_empty()
	_ajustar_colunas()


## Ordem CAIXA-PADRAO-BUSTO: o tamanho (largura × altura) de CADA quadradinho da fila — o mesmo para todas as figuras,
## qualquer que seja o nome: o retrato quadrado (LADO_RETRATO_EM_LETRAS letras) mais uma linha de nome.
func tamanho_celula() -> Vector2:
	var lado := roundf(float(_fonte) * LADO_RETRATO_EM_LETRAS)
	# A altura de uma linha de nome medida por uma Label a sério (fonte, espaçamento e margens do tema).
	_medida_nome.add_theme_font_size_override("font_size", _letra_nome())
	return Vector2(lado, lado + ceilf(_medida_nome.get_minimum_size().y))


## Ordem CAIXA-PADRAO-CORRECOES (B3): o texto que uma linha de nome MOSTRA de facto — depois do corte com «…» dentro da
## largura fixa da célula —, e não o `text` (o nome antes desse corte, só cortado aos MAX_LETRAS_NOME). Faz a mesma conta
## que a Label faz para desenhar: a linha com a fonte, a letra e a largura dela, cortada com o mesmo `text_overrun_behavior`.
static func texto_visivel(l: Label) -> String:
	var linha := TextLine.new()
	linha.add_string(l.text, l.get_theme_font("font"), l.get_theme_font_size("font_size"))
	var est := l.get_theme_stylebox("normal")
	linha.width = l.size.x - (est.get_minimum_size().x if est != null else 0.0)
	linha.text_overrun_behavior = l.text_overrun_behavior
	linha.ellipsis_char = l.ellipsis_char
	linha.get_size()  # a linha só se molda (e corta) quando se lhe pede uma medida
	var corte := TextServerManager.get_primary_interface().shaped_text_get_trim_pos(linha.get_rid())
	if corte < 0 or corte >= l.text.length():
		return l.text
	return l.text.substr(0, corte) + l.ellipsis_char


func _letra_nome() -> int:
	return maxi(1, int(round(_fonte * LETRA_NOME)))


## Ordem CAIXA-JANELA (B3): a caixa não passa desta largura (0 = sem limite): a fila parte em mais linhas.
func limitar_largura(max_largura: float) -> void:
	_max_largura = maxf(0.0, max_largura)
	_ajustar_colunas()


## Quantas figuras por linha a fila tem agora (para os testes e as medidas).
func colunas_fila() -> int:
	return _fila.columns


func _ajustar_colunas() -> void:
	var n := maxi(1, _fila.get_child_count())
	_fila.columns = n
	if _max_largura > 0.0:
		while _fila.columns > 1 and get_combined_minimum_size().x > _max_largura:
			_fila.columns -= 1
	size = get_combined_minimum_size()


## A letra do ecrã (o Mestre e o HUD mudam-na com o tamanho da janela).
func ajustar(fonte: int) -> void:
	_fonte = maxi(fonte, 8)
	_titulo.add_theme_font_size_override("font_size", _fonte)
	_modo_rotulo.add_theme_font_size_override("font_size", maxi(1, int(round(_fonte * 0.8))))
	_vazia.add_theme_font_size_override("font_size", maxi(1, int(round(_fonte * 0.8))))
	_activa_nome.add_theme_font_size_override("font_size", maxi(1, int(round(_fonte * 0.8))))
	_botao.add_theme_font_size_override("font_size", maxi(1, int(round(_fonte * 0.8))))
	_vazia.custom_minimum_size = Vector2(float(_fonte) * 12.0, 0.0)


func _curto(t: String) -> String:
	return t if t.length() <= MAX_LETRAS_NOME else t.substr(0, MAX_LETRAS_NOME - 1) + "…"


func _moldura(realce: bool) -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "Moldura"
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := StyleBoxFlat.new()
	s.bg_color = COR_FUNDO_RETRATO
	s.border_color = COR_REALCE if realce else COR_MOLDURA
	s.set_border_width_all(3 if realce else 1)
	s.set_corner_radius_all(6)
	s.set_content_margin_all(3)
	p.add_theme_stylebox_override("panel", s)
	var t := TextureRect.new()
	t.name = "Retrato"
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.size_flags_vertical = Control.SIZE_EXPAND_FILL
	p.add_child(t)
	return p


func _rotulo(pai: Node, nome: String, texto: String) -> Label:
	var l := Label.new()
	l.name = nome
	l.text = texto
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_color_override("font_color", COR_TEXTO)
	pai.add_child(l)
	return l
