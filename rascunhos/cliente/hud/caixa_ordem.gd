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
const LADO_RETRATO_EM_LETRAS := 2.8
const LADO_ACTIVA_EM_LETRAS := 4.6
const MAX_LETRAS_NOME := 10
## Ordem CAIXA-PERSISTENTE: a tabela de apresentação da Ordem DADOS (dados/apresentacao.gd) aplica-se onde ela já
## define a cor: o realce da figura na vez é o anel de destino do site (Apresentacao.COR_MESTRE_ANEL = ffd28b, o mesmo
## literal de antes, por isso o ecrã fica igual). O fundo do painel (sangue) e a moldura da caixa (ouro) vêm da tabela
## desde a Ordem PALETA-C ponto 2 (palavra do Mestre, 21/11/2026), com a transparência de antes (0.78 e 0.18).
const Apresentacao := preload("res://dados/apresentacao.gd")
const COR_PAINEL := Apresentacao.COR_CAIXA_PAINEL
const COR_REALCE := Apresentacao.COR_MESTRE_ANEL
const COR_MOLDURA := Apresentacao.COR_CAIXA_MOLDURA

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
var _fila: HBoxContainer
var _vazia: Label
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
	_fila = HBoxContainer.new()
	_fila.name = "Fila"
	_fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corpo.add_child(_fila)
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
	var lado := float(_fonte) * LADO_RETRATO_EM_LETRAS
	for id in ordem:
		var slot := VBoxContainer.new()
		slot.name = "Slot_" + id
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := _moldura(id == vez_mostrada)
		m.custom_minimum_size = Vector2(lado, lado)
		(m.get_child(0) as TextureRect).texture = retratos.get(id)
		slot.add_child(m)
		var n := _rotulo(slot, "Nome", _curto(str(nomes.get(id, id))))
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.add_theme_font_size_override("font_size", maxi(1, int(round(_fonte * 0.75))))
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
	s.bg_color = Color(0, 0, 0, 0.35)
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
	pai.add_child(l)
	return l
