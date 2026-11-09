extends Control
## Os controlos da CÂMARA LIVRE no ecrã do Mestre (ordem 6 do CM-000009, decisão 10; site REF_29, jogo.js
## «cam-livre-*» e jogo.css). Por cima do tabuleiro (o lado esquerdo), só no ecrã do Mestre.
##
## - «Entrar na câmera livre» no canto do tabuleiro; dentro: «⟲ Voltar à câmera do jogo», a dica, o manípulo
##   (círculo de 132 px com o botão de 56 px que segue o dedo até 34 px), ▲ e ▼ de apertar e segurar (68 px) e
##   o multiplicador 1×/2×/4×. Os tamanhos são os do site em px REAIS (decisão 2: a mesma qualidade no
##   telemóvel, no notebook e no PC), convertidos para as unidades do ecrã, e encolhem se o tabuleiro for baixo.
## - Teclado (WASD/setas para andar, E/Q ou PageUp/PageDown para voar, Shift ×2,2): enquanto a livre está
##   activa, estas teclas são do andar e passam à frente do resto (como o stopImmediatePropagation do site).
## - Arrastar no tabuleiro para olhar: tratado pela própria câmara (camara_livre.gd), dentro da Vista3D.
## O manípulo e o ▲▼ seguem o dedo pelo índice do toque: dá para andar com um dedo e olhar com outro.

const Textos := preload("res://cenas/mestre/textos_mestre.gd")
const CamaraLivre := preload("res://cenas/mestre/camara_livre.gd")

const COR_FUNDO := Color(30.0 / 255.0, 40.0 / 255.0, 48.0 / 255.0, 0.30)
const COR_BORDA := Color(1.0, 1.0, 1.0, 0.55)
const COR_NUB := Color(1.0, 1.0, 1.0, 0.85)
const MANIPULO_PX := 132.0
const NUB_PX := 56.0
const CURSO_NUB_PX := 34.0
const BOTAO_ALTURA_PX := 68.0
const MARGEM_PX := 22.0
const TOQUE_MIN_PX := 44.0
const RATO := -1
const NINGUEM := -2

var arena  # ArenaMestre (arena_mestre.gd)
var entrar_botao: Button
var sair_botao: Button
var dica: Label
var manipulo: Panel
var nub: Panel
var sobe_botao: Panel
var desce_botao: Panel
var vel_caixa: HBoxContainer
var vel_botoes: Array[Button] = []
var _escala := 1.0
var _dedo_manipulo := NINGUEM
var _dedo_altura := NINGUEM
var _valor_altura := 0


func montar(a) -> void:
	arena = a
	name = "CamaraLivre"
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # o arrasto no tabuleiro passa para a Vista3D
	entrar_botao = Button.new()
	entrar_botao.name = "Entrar"
	entrar_botao.text = Textos.CAMARA_LIVRE_ENTRAR
	entrar_botao.pressed.connect(entrar)
	add_child(entrar_botao)
	sair_botao = Button.new()
	sair_botao.name = "Sair"
	sair_botao.text = Textos.CAMARA_LIVRE_SAIR
	sair_botao.pressed.connect(sair)
	add_child(sair_botao)
	dica = Label.new()
	dica.name = "Dica"
	dica.text = Textos.CAMARA_LIVRE_DICA
	dica.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dica.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fundo_dica := StyleBoxFlat.new()
	fundo_dica.bg_color = Color(COR_FUNDO, 0.45)
	fundo_dica.set_corner_radius_all(16)
	fundo_dica.set_content_margin_all(6)
	dica.add_theme_stylebox_override("normal", fundo_dica)
	add_child(dica)
	manipulo = _circulo("Manipulo", COR_FUNDO, true)
	manipulo.gui_input.connect(_ao_manipulo)
	add_child(manipulo)
	nub = _circulo("Nub", COR_NUB, false)
	nub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	manipulo.add_child(nub)
	sobe_botao = _botao_altura("Subir", Textos.CAMARA_LIVRE_SUBIR, 1)
	desce_botao = _botao_altura("Descer", Textos.CAMARA_LIVRE_DESCER, -1)
	vel_caixa = HBoxContainer.new()
	vel_caixa.name = "Velocidade"
	add_child(vel_caixa)
	var grupo := ButtonGroup.new()
	for v in CamaraLivre.VELOCIDADES:
		var b := Button.new()
		b.name = "Vel%d" % v
		b.text = "%d×" % v
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = v == 1
		b.pressed.connect(func(): arena.camara_livre.definir_vel(v))
		vel_caixa.add_child(b)
		vel_botoes.append(b)
	_mostrar(false)


func ativa() -> bool:
	return arena != null and arena.camara_livre_ativa()


func entrar() -> void:
	arena.entrar_camara_livre()
	_mostrar(true)


func sair() -> void:
	_largar_manipulo()
	_largar_altura()
	arena.sair_camara_livre()
	_mostrar(false)


func _mostrar(dentro: bool) -> void:
	entrar_botao.visible = not dentro
	for n in [sair_botao, dica, manipulo, sobe_botao, desce_botao, vel_caixa]:
		(n as CanvasItem).visible = dentro


## Põe os controlos por cima do tabuleiro `r` (unidades do ecrã), com `escala` px reais por unidade.
func ajustar(r: Rect2, escala: float) -> void:
	_escala = escala if escala > 0.0 else 1.0
	position = r.position
	size = r.size
	if arena != null:
		arena.camara_livre.px_por_unidade = _escala
	var m := _u(MARGEM_PX)
	# O manípulo e os botões de altura encolhem juntos se o tabuleiro for baixo ou estreito (nunca abaixo
	# do toque mínimo de 44 px reais).
	var k := minf(1.0, minf(size.y * 0.42 / _u(MANIPULO_PX), size.x * 0.4 / _u(MANIPULO_PX)))
	k = maxf(k, TOQUE_MIN_PX / MANIPULO_PX)
	var d := _u(MANIPULO_PX) * k
	manipulo.size = Vector2(d, d)
	manipulo.position = Vector2(m, size.y - m - d)
	_arredondar(manipulo, d)
	var dn := _u(NUB_PX) * k
	nub.size = Vector2(dn, dn)
	_arredondar(nub, dn)
	_por_nub(Vector2.ZERO)
	var h := maxf(_u(BOTAO_ALTURA_PX) * k, _u(TOQUE_MIN_PX))
	for b in [sobe_botao, desce_botao]:
		(b as Panel).size = Vector2(h, h)
		_arredondar(b, h)
		var l := (b as Panel).get_node("Seta") as Label
		l.add_theme_font_size_override("font_size", maxi(1, int(round(h * 30.0 / BOTAO_ALTURA_PX))))
		l.position = Vector2.ZERO
		l.size = Vector2(h, h)
	desce_botao.position = Vector2(size.x - m - h, size.y - m - h)
	sobe_botao.position = Vector2(size.x - m - h, desce_botao.position.y - _u(14.0) - h)
	var tam_vel := vel_caixa.get_combined_minimum_size()
	vel_caixa.size = tam_vel
	vel_caixa.position = Vector2(size.x - m - tam_vel.x, sobe_botao.position.y - _u(14.0) - tam_vel.y)
	for b in [entrar_botao, sair_botao]:
		(b as Button).custom_minimum_size = Vector2(0.0, _u(TOQUE_MIN_PX))
		(b as Button).size = (b as Button).get_combined_minimum_size()
	entrar_botao.position = Vector2(_u(14.0), _u(14.0))
	sair_botao.position = Vector2(maxf(_u(14.0), (size.x - sair_botao.size.x) * 0.5), _u(14.0))
	var largura_dica := maxf(_u(120.0), size.x - _u(28.0))
	dica.custom_minimum_size = Vector2(largura_dica, 0.0)
	dica.size = Vector2(largura_dica, 0.0)
	dica.size = Vector2(largura_dica, dica.get_combined_minimum_size().y)
	dica.position = Vector2((size.x - largura_dica) * 0.5, sair_botao.position.y + sair_botao.size.y + _u(10.0))


## Px reais → unidades do ecrã.
func _u(px: float) -> float:
	return px / _escala


# ---------------------------------------------------------------- teclado

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or arena == null:
		return
	var nome = CamaraLivre.TECLAS.get(event.keycode)
	if nome == null:
		return
	var cam = arena.camara_livre
	var foco := get_viewport().gui_get_focus_owner()
	if event.pressed and (foco is LineEdit or foco is TextEdit):
		return  # a escrever na pesquisa: as letras são do texto
	if event.pressed:
		if not ativa():
			return
		if not event.echo:
			cam.definir_tecla(nome, true)
		get_viewport().set_input_as_handled()
	elif cam.teclas.has(nome):
		cam.definir_tecla(nome, false)
		if ativa():
			get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and arena != null:
		arena.camara_livre.teclas = {}


# ---------------------------------------------------------------- manípulo

func _ao_manipulo(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed and _dedo_manipulo == NINGUEM:
			_dedo_manipulo = ev.index
			_mexer(ev.position)
		elif not ev.pressed and ev.index == _dedo_manipulo:
			_largar_manipulo()
	elif ev is InputEventScreenDrag:
		if ev.index == _dedo_manipulo:
			_mexer(ev.position)
	elif ev is InputEventMouseButton and ev.device != InputEvent.DEVICE_ID_EMULATION and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed and _dedo_manipulo == NINGUEM:
			_dedo_manipulo = RATO
			_mexer(ev.position)
		elif not ev.pressed and _dedo_manipulo == RATO:
			_largar_manipulo()
	elif ev is InputEventMouseMotion and ev.device != InputEvent.DEVICE_ID_EMULATION and _dedo_manipulo == RATO:
		_mexer(ev.position)
	manipulo.accept_event()


## `p` local ao manípulo: joy normalizado (módulo preso a 1), como o manípulo() do site.
func _mexer(p: Vector2) -> void:
	var raio := manipulo.size.x * 0.5
	if raio <= 0.0:
		return
	var d := ((p - Vector2(raio, raio)) / raio).limit_length(1.0)
	arena.camara_livre.definir_joy(d)
	_por_nub(d)


func _largar_manipulo() -> void:
	_dedo_manipulo = NINGUEM
	if arena != null:
		arena.camara_livre.definir_joy(Vector2.ZERO)
	_por_nub(Vector2.ZERO)


func _por_nub(d: Vector2) -> void:
	var raio := manipulo.size.x * 0.5
	nub.position = Vector2(raio, raio) - nub.size * 0.5 + d * (CURSO_NUB_PX / MANIPULO_PX) * manipulo.size.x


# ---------------------------------------------------------------- subir e descer (apertar e segurar)

func _botao_altura(nome: String, seta: String, valor: int) -> Panel:
	var b := _circulo(nome, COR_FUNDO, true)
	var l := Label.new()
	l.name = "Seta"
	l.text = seta
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(l)
	b.gui_input.connect(func(ev): _ao_altura(ev, valor, b))
	b.mouse_exited.connect(_saiu_altura.bind(valor))
	add_child(b)
	return b


func _ao_altura(ev: InputEvent, valor: int, b: Panel) -> void:
	if ev is InputEventScreenTouch:
		if ev.pressed:
			_dedo_altura = ev.index
			_premir_altura(valor)
		elif ev.index == _dedo_altura and _valor_altura == valor:
			_largar_altura()
	elif ev is InputEventMouseButton and ev.device != InputEvent.DEVICE_ID_EMULATION and ev.button_index == MOUSE_BUTTON_LEFT:
		if ev.pressed:
			_dedo_altura = RATO
			_premir_altura(valor)
		elif _dedo_altura == RATO and _valor_altura == valor:
			_largar_altura()
	b.accept_event()


## Como o pointerleave do site: com o rato, sair do botão larga-o.
func _saiu_altura(valor: int) -> void:
	if _dedo_altura == RATO and _valor_altura == valor:
		_largar_altura()


func _premir_altura(valor: int) -> void:
	_valor_altura = valor
	arena.camara_livre.definir_sobe(valor)


func _largar_altura() -> void:
	_dedo_altura = NINGUEM
	_valor_altura = 0
	if arena != null:
		arena.camara_livre.definir_sobe(0)


# ---------------------------------------------------------------- desenho

func _circulo(nome: String, cor: Color, com_borda: bool) -> Panel:
	var p := Panel.new()
	p.name = nome
	var sb := StyleBoxFlat.new()
	sb.bg_color = cor
	if com_borda:
		sb.border_color = COR_BORDA
		sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	return p


func _arredondar(p: Panel, diametro: float) -> void:
	var sb := p.get_theme_stylebox("panel") as StyleBoxFlat
	if sb != null:
		sb.set_corner_radius_all(int(ceilf(diametro * 0.5)))
