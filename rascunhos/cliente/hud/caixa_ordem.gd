extends PanelContainer
## Ordem HUD — a CAIXA DA ORDEM DE TURNOS no ecrã de batalha (desenho = palavra do Mestre, 16/11/2026 11:18).
##
## Mostra a ordem QUE EXISTE — a formada pelas acções (modo dinâmico) ou a do servidor (modo iniciativa) — com o
## RETRATO das figuras (hud/retratos.gd). Nunca adivinha turnos futuros. Só desenha: a ordem vem de
## hud/ordem_turnos.gd e as regras do servidor.
##
## Ordem CAIXA-EXPANDE (regra do Mestre, 21/11/2026 23:10): «A caixinha grande é quem tá jogando agora, a caixinha
## pequena são os próximos a jogar, o nome com outra cor só em quem tá jogando agora; quando quem tá na vez termina de
## jogar, ele sai da caixinha grande e vai para o final da fila; a fila de caixinhas não precisa aparecer todos (só se
## apertar com o dedo ou passar o cursor do mouse em cima, aí pode mostrar tudo)».
## - VISTA COMPACTA: o cartão grande (à esquerda) é SÓ a figura na vez, e o nome a ouro é SÓ o dela. As caixinhas
##   pequenas (MAX_FILA = 4, escolha do coordenador) são os PRÓXIMOS a jogar, pela ordem, a contar de quem está a seguir
##   à vez e dando a volta (a figura na vez nunca aparece nelas; quem acabou de jogar vai para o fim). Todos os nomes
##   das caixinhas são pergaminho. Com menos de 5 figuras há menos caixinhas (nunca se repete ninguém).
## - VISTA EXPANDIDA: com o rato por cima da caixa (ou, nos aparelhos de toque, um toque nela) a caixa cresce e mostra
##   a ORDEM COMPLETA — a figura na vez primeiro (realçada como no cartão grande: moldura grossa, nome a ouro, «na vez»)
##   e depois todas as outras pela ordem em que vão jogar, até dar a volta — todas com o retrato e o nome COMPLETO.
##   Tirar o rato (ou outro toque, na caixa ou fora dela) volta à compacta. Só mostra o que a compacta já mostra: os
##   nomes e a ordem das figuras da luta.
## Os toques e cliques EM CIMA da caixa ficam na caixa (abrem/fecham a vista); fora dela, o tabuleiro recebe-os.

## O Mestre carregou em «Modo iniciativa» (true = ligar).
signal pediu_iniciativa(ligar: bool)
## Ordem CAIXA-EXPANDE: a vista mudou (compacta ↔ expandida); quem a põe no ecrã volta a ancorá-la.
signal vista_mudou(expandida: bool)

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
## Ordem CAIXA-EXPANDE: quantas caixinhas pequenas (os próximos a jogar) a vista compacta mostra. Escolha do
## coordenador, delegada pelo Mestre («3, 4 ou 5»): 4.
const MAX_FILA := 4
## Ordem CAIXA-EXPANDE: o retrato das linhas da vista expandida (letras do ecrã) e a letra do nome completo.
const LADO_LINHA_EM_LETRAS := 2.4
const LETRA_LINHA := 0.8
## Ordem CAIXA-EXPANDE: um toque que anda mais do que isto (em letras) é arrastar (rolar a lista), não abrir/fechar.
const TOQUE_MAX_EM_LETRAS := 0.6
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
var _corpo: HBoxContainer
var _activa_retrato: TextureRect
var _activa_moldura: PanelContainer
var _activa_nome: Label
var _activa: VBoxContainer
## Ordem CAIXA-JANELA (B3): a fila é uma grelha. Sem limite tem uma coluna por caixinha — uma linha só. Com
## `limitar_largura` parte em linhas para caber na largura dada.
var _fila: GridContainer
## A largura máxima da caixa (unidades do ecrã). 0 = sem limite.
var _max_largura := 0.0
## Ordem CAIXA-EXPANDE: a altura máxima da caixa expandida (0 = sem limite). Se a ordem não cabe, a lista rola.
var _max_altura := 0.0
var _vazia: Label
## Uma linha de nome escondida, só para medir a altura da linha de nome das células (tamanho_celula).
var _medida_nome: Label
## Ordem CAIXA-EXPANDE: a vista expandida — uma lista que rola (se for preciso) com uma linha por figura.
var _rolagem: ScrollContainer
var _lista: VBoxContainer
## O tamanho da caixa na vista compacta (o que o ecrã usa para arrumar o resto, mesmo com a expandida aberta).
var _tam_compacto := Vector2.ZERO
## O rato está por cima da caixa / um toque abriu-a.
var _sobre := false
var _aberta_toque := false
## Onde começou o toque em curso (local), ou INF se não há toque a começar na caixa.
var _toque_em := Vector2.INF
## Para os testes e as provas: o que a caixa mostra agora.
## `ids_mostrados`: a ordem completa (a que a expandida mostra); `ids_fila`: as caixinhas pequenas da compacta.
var ids_mostrados: Array[String] = []
var ids_fila: Array[String] = []
var vez_mostrada := ""
## A ordem da expandida (a vez primeiro, depois os próximos até dar a volta) e o nome completo das figuras.
var ids_expandida: Array[String] = []
var _nomes_completos: Dictionary = {}


func _init() -> void:
	name = "CaixaOrdem"
	# Ordem CAIXA-EXPANDE: a caixa apanha o rato e os toques EM CIMA DELA (abrem a vista expandida); fora dela, o
	# tabuleiro continua a recebê-los. Os filhos não apanham nada (só o botão do Mestre).
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	_corpo = HBoxContainer.new()
	_corpo.name = "Corpo"
	_corpo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_corpo)
	_activa = VBoxContainer.new()
	_activa.name = "Activa"
	_activa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_corpo.add_child(_activa)
	_activa_moldura = _moldura(true)
	_activa.add_child(_activa_moldura)
	_activa_retrato = _activa_moldura.get_child(0) as TextureRect
	_activa_nome = _rotulo(_activa, "NomeActiva", "")
	_activa_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_activa_nome.add_theme_color_override("font_color", COR_REALCE)  # o nome a ouro é SÓ o da figura na vez
	_fila = GridContainer.new()
	_fila.name = "Fila"
	_fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_corpo.add_child(_fila)
	_rolagem = ScrollContainer.new()
	_rolagem.name = "Expandida"
	_rolagem.mouse_filter = Control.MOUSE_FILTER_PASS  # a roda do rato e o arrastar rolam a lista
	_rolagem.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_rolagem.visible = false
	col.add_child(_rolagem)
	_lista = VBoxContainer.new()
	_lista.name = "Lista"
	_lista.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rolagem.add_child(_lista)
	_medida_nome = _rotulo(col, "MedidaNome", "Ág")
	_medida_nome.visible = false
	_vazia = _rotulo(_corpo, "Vazia", VAZIA)
	_vazia.modulate = Color(1, 1, 1, 0.75)
	_vazia.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vazia.size_flags_horizontal = Control.SIZE_EXPAND_FILL


## Ordem CAIXA-EXPANDE: os PRÓXIMOS a jogar — a contar de quem está a seguir à vez, pela ordem, dando a volta; a
## figura na vez nunca entra (acabou de… está a jogar; quando acabar vai para o fim). Sem vez, a ordem desde o início.
static func proximos(ordem: Array[String], vez: String, n: int) -> Array[String]:
	var seq := sequencia(ordem, vez)
	if vez != "" and not seq.is_empty() and seq[0] == vez:
		seq.remove_at(0)
	return seq.slice(0, maxi(n, 0))


## Ordem CAIXA-EXPANDE: a ordem completa a partir de quem está na vez (a vez primeiro, depois os próximos até dar a
## volta). Sem vez (ou se a vez não está na ordem), a ordem tal como é.
static func sequencia(ordem: Array[String], vez: String) -> Array[String]:
	var i := ordem.find(vez) if vez != "" else -1
	if i < 0:
		return ordem.duplicate()
	var out: Array[String] = []
	for k in ordem.size():
		out.append(ordem[(i + k) % ordem.size()])
	return out


## Mostra a ordem. `nomes`: id -> texto; `retratos`: id -> Texture2D (ou ausente: a moldura fica com o fundo).
func mostrar(ordem: Array[String], vez: String, nomes: Dictionary, retratos: Dictionary, modo_novo: String) -> void:
	modo = modo_novo
	ids_mostrados = ordem.duplicate()
	vez_mostrada = vez if ordem.has(vez) else ""
	ids_fila = proximos(ordem, vez_mostrada, MAX_FILA)
	ids_expandida = sequencia(ordem, vez_mostrada)
	_nomes_completos = {}
	for id in ordem:
		_nomes_completos[id] = str(nomes.get(id, id))
	_modo_rotulo.text = "· " + (MODO_INICIATIVA if modo == "iniciativa" else MODO_DINAMICO)
	_botao.visible = com_botao
	_botao.set_pressed_no_signal(modo == "iniciativa")
	for c in _fila.get_children():
		_fila.remove_child(c)
		c.queue_free()
	var celula := tamanho_celula()
	for id in ids_fila:
		# A célula é um Control de tamanho FIXO (não um contentor que some o que leva): o retrato quadrado em cima, a
		# linha do nome por baixo, postos à mão. Nada do que leva a pode alargar.
		var slot := Control.new()
		slot.name = "Slot_" + id
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.custom_minimum_size = celula
		slot.clip_contents = true
		var m := _moldura(false)  # a figura na vez não está aqui: as caixinhas são todas iguais
		(m.get_child(0) as TextureRect).texture = retratos.get(id)
		slot.add_child(m)
		m.position = Vector2.ZERO
		m.custom_minimum_size = Vector2(celula.x, celula.x)
		m.size = m.custom_minimum_size
		var n := _rotulo(slot, "Nome", _curto(str(nomes.get(id, id))))  # pergaminho (o ouro é só do cartão grande)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.add_theme_font_size_override("font_size", _letra_nome())
		# O nome não mede a célula: corta-se dentro da largura fixa (com «…»). O nome completo vive na expandida.
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		n.position = Vector2(0.0, celula.x)
		n.size = Vector2(celula.x, celula.y - celula.x)
		_fila.add_child(slot)
	_activa.visible = vez_mostrada != ""
	if _activa.visible:
		var la := float(_fonte) * LADO_ACTIVA_EM_LETRAS
		_activa_moldura.custom_minimum_size = Vector2(la, la)
		_activa_retrato.texture = retratos.get(vez_mostrada)
		_activa_nome.text = "%s\n%s" % [_curto(str(nomes.get(vez_mostrada, vez_mostrada))), NA_VEZ]
	_vazia.visible = ordem.is_empty()
	_vazia.text = VAZIA_INICIATIVA if modo == "iniciativa" else VAZIA
	_fila.visible = not ids_fila.is_empty()
	_montar_lista(retratos)
	_aplicar_vista()


## Ordem CAIXA-EXPANDE: a lista da vista expandida — uma linha por figura (retrato + nome completo), a vez primeiro.
func _montar_lista(retratos: Dictionary) -> void:
	for c in _lista.get_children():
		_lista.remove_child(c)
		c.queue_free()
	var lado := roundf(float(_fonte) * LADO_LINHA_EM_LETRAS)
	for id in ids_expandida:
		var na_vez := id == vez_mostrada
		var linha := HBoxContainer.new()
		linha.name = "Linha_" + id
		linha.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := _moldura(na_vez)
		m.custom_minimum_size = Vector2(lado, lado)
		(m.get_child(0) as TextureRect).texture = retratos.get(id)
		linha.add_child(m)
		var textos := VBoxContainer.new()
		textos.name = "Textos"
		textos.mouse_filter = Control.MOUSE_FILTER_IGNORE
		textos.alignment = BoxContainer.ALIGNMENT_CENTER
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha.add_child(textos)
		var n := _rotulo(textos, "Nome", str(_nomes_completos.get(id, id)))  # o nome COMPLETO, sem corte
		n.add_theme_font_size_override("font_size", _letra_linha())
		# Só se a linha não couber nem expandida (mais larga que o ecrã deixa) é que corta — e diz-se (linhas_cortadas).
		n.clip_text = true
		n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if na_vez:
			n.add_theme_color_override("font_color", COR_REALCE)
			var v := _rotulo(textos, "NaVez", NA_VEZ)
			v.add_theme_color_override("font_color", COR_REALCE)
			v.add_theme_font_size_override("font_size", _letra_nome())
		_lista.add_child(linha)


## Ordem CAIXA-EXPANDE: a vista expandida está aberta (rato por cima, ou um toque abriu-a)?
func expandida() -> bool:
	return (_sobre or _aberta_toque) and not ids_mostrados.is_empty()


## O tamanho da caixa na vista COMPACTA (mesmo com a expandida aberta): é por ele que o ecrã arruma a faixa e o resto.
func tamanho_compacto() -> Vector2:
	return _tam_compacto


## Põe a vista certa (compacta ou expandida), mede-a e acerta o tamanho (e a âncora).
func _aplicar_vista() -> void:
	_ajustar_colunas_fila()
	_corpo.visible = true
	_rolagem.visible = false
	_tam_compacto = get_combined_minimum_size()
	var abrir := expandida()
	if abrir:
		_corpo.visible = false
		_rolagem.visible = true
		var resto := _tam_compacto.x - _corpo.get_combined_minimum_size().x  # margens do painel
		var teto := INF if _max_largura <= 0.0 else maxf(1.0, _max_largura - resto)
		# Os nomes pedem a largura do texto inteiro; só se a linha passar o que o ecrã deixa é que se corta (e diz-se).
		var barra_rolar := _rolagem.get_v_scroll_bar().get_combined_minimum_size().x
		for linha in _lista.get_children():
			var n := linha.get_node("Textos/Nome") as Label
			var fixo := (linha as Control).get_combined_minimum_size().x - n.get_combined_minimum_size().x
			n.custom_minimum_size.x = minf(_largura_texto(n), maxf(0.0, teto - fixo - barra_rolar))
		var lista := _lista.get_combined_minimum_size()
		var largura := maxf(lista.x + barra_rolar, _corpo.get_combined_minimum_size().x)  # nunca mais estreita que a compacta
		largura = minf(largura, teto)
		var altura := lista.y
		if _max_altura > 0.0:
			var fora := get_combined_minimum_size().y - _rolagem.get_combined_minimum_size().y
			altura = minf(altura, maxf(float(_fonte) * LADO_LINHA_EM_LETRAS, _max_altura - fora))
		_rolagem.custom_minimum_size = Vector2(largura, altura)
	size = get_combined_minimum_size()  # quem a pôs no ecrã volta a ancorá-la (sinal vista_mudou)


## Ordem CAIXA-EXPANDE: as linhas da expandida que não cabem e mostram o nome cortado (id -> texto à vista).
## Vazio = todos os nomes completos à vista.
func linhas_cortadas() -> Dictionary:
	var out := {}
	for linha in _lista.get_children():
		var n := linha.get_node("Textos/Nome") as Label
		var v := texto_visivel(n)
		if v != n.text:
			out[str(linha.name).trim_prefix("Linha_")] = v
	return out


## Ordem CAIXA-EXPANDE: a lista da expandida rola (a ordem não cabe na altura que o ecrã deixa)?
func expandida_rola() -> bool:
	return _rolagem.visible and _lista.get_combined_minimum_size().y > _rolagem.custom_minimum_size.y + 0.5


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


## A largura que uma Label precisa para o texto inteiro numa linha (fonte, letra e margens dela).
static func _largura_texto(l: Label) -> float:
	var est := l.get_theme_stylebox("normal")
	var w := l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.get_theme_font_size("font_size")).x
	return ceilf(w + (est.get_minimum_size().x if est != null else 0.0)) + 1.0


func _letra_nome() -> int:
	return maxi(1, int(round(_fonte * LETRA_NOME)))


func _letra_linha() -> int:
	return maxi(1, int(round(_fonte * LETRA_LINHA)))


## Ordem CAIXA-JANELA (B3): a caixa não passa desta largura (0 = sem limite): a fila parte em mais linhas.
func limitar_largura(max_largura: float) -> void:
	_max_largura = maxf(0.0, max_largura)
	_aplicar_vista()


## Ordem CAIXA-EXPANDE: a caixa expandida não passa desta altura (0 = sem limite): a lista rola por dentro.
func limitar_altura(max_altura: float) -> void:
	_max_altura = maxf(0.0, max_altura)
	if expandida():
		_aplicar_vista()


## Quantas figuras por linha a fila tem agora (para os testes e as medidas).
func colunas_fila() -> int:
	return _fila.columns


func _ajustar_colunas_fila() -> void:
	var n := maxi(1, _fila.get_child_count())
	_fila.columns = n
	if _max_largura > 0.0:
		var corpo_vis := _corpo.visible
		var rol_vis := _rolagem.visible
		_corpo.visible = true
		_rolagem.visible = false
		while _fila.columns > 1 and get_combined_minimum_size().x > _max_largura:
			_fila.columns -= 1
		_corpo.visible = corpo_vis
		_rolagem.visible = rol_vis


## A letra do ecrã (o Mestre e o HUD mudam-na com o tamanho da janela).
func ajustar(fonte: int) -> void:
	_fonte = maxi(fonte, 8)
	_titulo.add_theme_font_size_override("font_size", _fonte)
	_modo_rotulo.add_theme_font_size_override("font_size", maxi(1, int(round(_fonte * 0.8))))
	_vazia.add_theme_font_size_override("font_size", maxi(1, int(round(_fonte * 0.8))))
	_activa_nome.add_theme_font_size_override("font_size", maxi(1, int(round(_fonte * 0.8))))
	_botao.add_theme_font_size_override("font_size", maxi(1, int(round(_fonte * 0.8))))
	_vazia.custom_minimum_size = Vector2(float(_fonte) * 12.0, 0.0)


# ---------------------------------------------------------------- Ordem CAIXA-EXPANDE: o rato e o toque

## Abre/fecha a vista expandida como se o rato entrasse/saísse (para as provas e os testes, além do rato a sério).
func definir_sobre(dentro: bool) -> void:
	if dentro == _sobre:
		return
	var antes := expandida()
	_sobre = dentro
	_mudar_vista(antes)


## Abre/fecha a vista expandida como um toque na caixa (aparelhos de toque).
func alternar_toque() -> void:
	var antes := expandida()
	_aberta_toque = not _aberta_toque
	_mudar_vista(antes)


func _mudar_vista(antes: bool) -> void:
	if expandida() == antes:
		return
	_aplicar_vista()
	vista_mudou.emit(expandida())


func _contem(ev: InputEvent) -> bool:
	var l := make_input_local(ev)
	var p := Vector2.INF
	if l is InputEventMouse:
		p = (l as InputEventMouse).position
	elif l is InputEventScreenTouch:
		p = (l as InputEventScreenTouch).position
	return Rect2(Vector2.ZERO, size).has_point(p)


## O rato a sério (não o que o motor imita a partir de um toque) por cima ou fora da caixa; o toque abre/fecha. Lê-se
## no _input (antes do tabuleiro e dos botões) sem consumir nada: quem consome os cliques em cima da caixa é o
## mouse_filter dela; o arrastar continua a chegar à lista para rolar.
func _input(ev: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if ev is InputEventMouseMotion and ev.device != InputEvent.DEVICE_ID_EMULATION:
		definir_sobre(_contem(ev))
	elif ev is InputEventScreenTouch:
		var t := ev as InputEventScreenTouch
		var dentro := _contem(t)
		if t.pressed:
			_toque_em = t.position if dentro else Vector2.INF
			if not dentro and _aberta_toque:
				alternar_toque()  # um toque fora fecha a expandida (e o tabuleiro recebe-o)
		else:
			var tocou := _toque_em != Vector2.INF and dentro and t.position.distance_to(_toque_em) <= float(_fonte) * TOQUE_MAX_EM_LETRAS
			_toque_em = Vector2.INF
			if tocou:
				alternar_toque()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_MOUSE_EXIT:
		definir_sobre(false)  # o rato saiu da janela
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		var antes := expandida()
		_sobre = false
		_aberta_toque = false
		_toque_em = Vector2.INF
		_mudar_vista(antes)


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
