extends Camera3D
## Câmera da mesa (JV2.2).
##
## Modos:
##   FIXA      — ângulo fixo, ZOOM 1,5 COMO PADRÃO (palavra do Mestre). Arrastar desloca.
##   LIVRE_360 — gira em volta do foco (arrastar ou botão direito), inclinação limitada.
##   PANORAMA  — vista de cima que enquadra a arena inteira (possibilidade a mais).
## Gestos: roda do rato e pinça (dois dedos, ou gesto de trackpad) fazem zoom;
## dois dedos arrastados deslocam. Um toque curto, sem arrasto, é emitido como `toque`.
##
## PROVISÓRIO: os ângulos da FIXA saem da Régua R0 (aceite ±2°, ±0,05 no zoom).

signal toque(posicao: Vector2)

enum Modo { FIXA, LIVRE_360, PANORAMA }

## ORDEM DADOS DE APRESENTAÇÃO: o zoom por omissão vem da tabela única.
const Apresentacao := preload("res://dados/apresentacao.gd")
const ZOOM_PADRAO := Apresentacao.ZOOM_PADRAO  # palavra do Mestre
const NOMES_MODO := {"fixa": Modo.FIXA, "360": Modo.LIVRE_360, "panorama": Modo.PANORAMA}

@export var zoom_min: float = 0.6
@export var zoom_max: float = 3.0
## Distância ao foco (m) com zoom 1,0. Com o padrão 1,5 fica 2/3 disto.
@export var distancia_no_zoom_1: float = 27.0
@export var inclinacao_fixa_graus: float = 55.0  # PROVISÓRIO (R0)
@export var rumo_fixa_graus: float = 0.0  # PROVISÓRIO (R0)
@export var inclinacao_panorama_graus: float = 78.0
@export var inclinacao_min_graus: float = 20.0
@export var inclinacao_max_graus: float = 85.0
@export var limiar_arrasto_px: float = 12.0
@export var suavidade: float = 10.0
@export var sensibilidade_orbita: float = 0.3
@export var passo_roda: float = 1.1

## Ordem 42: a altura do chão em (x, z) — a arena dá a do relevo do mapa. Sem ela, o chão é y = 0.
var altura_em: Callable = Callable()

var modo: int = Modo.FIXA
var zoom: float = ZOOM_PADRAO
var foco := Vector3.ZERO
var rumo := 0.0
var inclinacao := 55.0

var _centro := Vector3.ZERO
var _tamanho := Vector2(30.0, 30.0)
var _dist_panorama := 40.0

var _s_foco := Vector3.ZERO
var _s_rumo := 0.0
var _s_incl := 55.0
var _s_dist := 18.0

var _toques: Dictionary = {}
var _pinca_dist := 0.0
var _pinca_meio := Vector2.ZERO
var _esq := false
var _dir := false
var _arrastando := false
var _inicio := Vector2.ZERO
var _fim_multitoque_ms := -100000
var _houve_multitoque := false


func _ready() -> void:
	rumo = rumo_fixa_graus
	inclinacao = inclinacao_fixa_graus
	get_viewport().size_changed.connect(_recalcular_panorama)
	_saltar()


func _process(delta: float) -> void:
	var k := 1.0 - exp(-suavidade * delta)
	_s_foco = _s_foco.lerp(_foco_alvo(), k)
	_s_rumo = rad_to_deg(lerp_angle(deg_to_rad(_s_rumo), deg_to_rad(_rumo_alvo()), k))
	_s_incl = lerpf(_s_incl, _incl_alvo(), k)
	_s_dist = lerpf(_s_dist, _dist_alvo(), k)
	_posicionar(_s_foco, _s_rumo, _s_incl, _s_dist)


# ---------------------------------------------------------------- API

func configurar_arena(centro: Vector3, tamanho: Vector2) -> void:
	_centro = centro
	_tamanho = tamanho
	if foco == Vector3.ZERO:
		foco = centro
	_limitar()
	_recalcular_panorama()
	_saltar()


func focar(p: Vector3) -> void:
	foco = p
	_limitar()


func definir_modo(m: int) -> void:
	modo = m
	match m:
		Modo.FIXA:
			rumo = rumo_fixa_graus
			inclinacao = inclinacao_fixa_graus
		Modo.PANORAMA:
			_recalcular_panorama()
		_:
			pass


## O ponto para onde a câmara está a olhar agora (já suavizado).
func foco_atual() -> Vector3:
	return _s_foco


func definir_modo_por_nome(nome: String) -> void:
	definir_modo(int(NOMES_MODO.get(nome, Modo.FIXA)))


func definir_zoom(z: float) -> void:
	zoom = clampf(z, zoom_min, zoom_max)


func repor_zoom() -> void:
	zoom = ZOOM_PADRAO


# ---------------------------------------------------------------- alvos

func _foco_alvo() -> Vector3:
	return _centro if modo == Modo.PANORAMA else foco


func _rumo_alvo() -> float:
	return rumo_fixa_graus if modo == Modo.PANORAMA else rumo


func _incl_alvo() -> float:
	return inclinacao_panorama_graus if modo == Modo.PANORAMA else inclinacao


func _dist_alvo() -> float:
	if modo == Modo.PANORAMA:
		return _dist_panorama
	return distancia_no_zoom_1 / zoom


func _saltar() -> void:
	_s_foco = _foco_alvo()
	_s_rumo = _rumo_alvo()
	_s_incl = _incl_alvo()
	_s_dist = _dist_alvo()
	if is_inside_tree():
		_posicionar(_s_foco, _s_rumo, _s_incl, _s_dist)


func _posicionar(alvo: Vector3, rumo_g: float, incl_g: float, dist: float) -> void:
	if not is_inside_tree():
		return
	var desvio: Vector3 = Basis(Vector3.UP, deg_to_rad(rumo_g)) * (Basis(Vector3.RIGHT, -deg_to_rad(incl_g)) * Vector3(0.0, 0.0, dist))
	look_at_from_position(alvo + desvio, alvo, Vector3.UP)


func _chao(x: float, z: float) -> float:
	return float(altura_em.call(x, z)) if altura_em.is_valid() else 0.0


## Afasta até os cantos da arena (no chão e à altura das cabeças) caberem no ecrã.
## Ordem 42: os cantos e os meios das bordas à altura do relevo nesse ponto (o chão não é plano).
func _recalcular_panorama() -> void:
	if not is_inside_tree():
		return
	var meio := _tamanho * 0.5
	var cantos: Array = []
	for altura in [0.0, 1.8]:
		for f: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
			var x := _centro.x + meio.x * f.x
			var z := _centro.z + meio.y * f.y
			cantos.append(Vector3(x, _chao(x, z) + altura, z))
	var guardado := global_transform
	var d := maxf(_tamanho.x, _tamanho.y) * 0.5
	for i in 60:
		_posicionar(_centro, rumo_fixa_graus, inclinacao_panorama_graus, d)
		var cabe := true
		for p in cantos:
			if not is_position_in_frustum(p):
				cabe = false
				break
		if cabe:
			break
		d *= 1.06
	_dist_panorama = d * 1.03
	global_transform = guardado


func _limitar() -> void:
	var meio := _tamanho * 0.5
	foco.x = clampf(foco.x, _centro.x - meio.x, _centro.x + meio.x)
	foco.z = clampf(foco.z, _centro.z - meio.y, _centro.z + meio.y)
	foco.y = _chao(foco.x, foco.z)


# ---------------------------------------------------------------- gestos

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_toques[event.index] = event.position
		else:
			_toques.erase(event.index)
		if _toques.size() >= 2:
			_arrastando = true  # nunca vira toque
			_houve_multitoque = true
			_iniciar_pinca()
		elif _houve_multitoque and not event.pressed:
			_fim_multitoque_ms = Time.get_ticks_msec()
			if _toques.is_empty():
				_houve_multitoque = false
		return

	if event is InputEventScreenDrag:
		_toques[event.index] = event.position
		if _toques.size() >= 2:
			_atualizar_pinca()
			get_viewport().set_input_as_handled()
		return

	if event is InputEventMagnifyGesture:
		if modo != Modo.PANORAMA:
			definir_zoom(zoom * event.factor)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventPanGesture:
		_deslocar(-event.delta * 12.0)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed and modo != Modo.PANORAMA:
					definir_zoom(zoom * passo_roda)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed and modo != Modo.PANORAMA:
					definir_zoom(zoom / passo_roda)
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_esq = true
					_arrastando = _toques.size() >= 2
					_inicio = event.position
				else:
					var foi_toque := _esq and not _arrastando and _toques.size() < 2 \
						and Time.get_ticks_msec() - _fim_multitoque_ms > 250
					_esq = false
					_arrastando = false
					if foi_toque:
						toque.emit(event.position)
			MOUSE_BUTTON_RIGHT:
				_dir = event.pressed
		return

	if event is InputEventMouseMotion:
		if _toques.size() >= 2:
			return
		if _dir:
			_orbitar(event.relative)
		elif _esq:
			if not _arrastando and event.position.distance_to(_inicio) > limiar_arrasto_px:
				_arrastando = true
			if _arrastando:
				if modo == Modo.LIVRE_360:
					_orbitar(event.relative)
				else:
					_deslocar(event.relative)


func _pontos_pinca() -> Array:
	var pts: Array = _toques.values()
	var a: Vector2 = pts[0]
	var b: Vector2 = pts[1]
	return [a.distance_to(b), (a + b) * 0.5]


func _iniciar_pinca() -> void:
	var e := _pontos_pinca()
	_pinca_dist = e[0]
	_pinca_meio = e[1]


func _atualizar_pinca() -> void:
	var e := _pontos_pinca()
	var dist: float = e[0]
	var meio: Vector2 = e[1]
	if _pinca_dist > 1.0 and modo != Modo.PANORAMA:
		definir_zoom(zoom * dist / _pinca_dist)
	_deslocar(meio - _pinca_meio)
	_pinca_dist = dist
	_pinca_meio = meio


func _deslocar(rel: Vector2) -> void:
	if modo == Modo.PANORAMA:
		return
	var b := global_transform.basis
	var direita := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var frente := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	var k := _dist_alvo() * 0.0014
	foco += (-direita * rel.x + frente * rel.y) * k
	_limitar()


func _orbitar(rel: Vector2) -> void:
	if modo != Modo.LIVRE_360:
		return
	rumo = fmod(rumo - rel.x * sensibilidade_orbita, 360.0)
	inclinacao = clampf(inclinacao + rel.y * sensibilidade_orbita * 0.6, inclinacao_min_graus, inclinacao_max_graus)
