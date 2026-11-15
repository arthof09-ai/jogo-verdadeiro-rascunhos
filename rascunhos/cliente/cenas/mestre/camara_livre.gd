extends Camera3D
## CÂMARA LIVRE DO MESTRE (ordem 6 do CM-000009, decisão 10 do Mestre; site REF_29, cena.js «cameraLivre»).
##
## Primeira pessoa dentro da arena, com a mecânica da sala/museu copiada valor a valor do site:
## olhar 0,0045 rad por px arrastado (pitch preso a ±1,45) · andar 4,2 u/s · vertical 3,0 u/s · Shift ×2,2 ·
## multiplicador 1×/2×/4× · dt preso a 0,08 · perspectiva 50° (0,1–400) · entrada à beira sul da arena, olhos a
## 1,6 do chão, a olhar para o centro (a 1,3) · bordas = arena + 3 de cada lado · altura entre chão + 0,4 e 12.
## Sem colisão, de propósito (como no site).
## Ordem 45: o chão é o relevo do mapa da floresta (`altura_em`, a altura única do Relevo): os olhos, o «chão + 0,4»
## e o tecto contam-se a partir dele, ponto a ponto. Sem `altura_em`, o chão é plano a 0, como antes.
##
## Só o ecrã do Mestre a constrói (arena_mestre.gd); a vista da Party nem a constrói. A câmara da mesa
## (camera_mesa.gd) fica congelada enquanto esta está activa, por isso sair é exacto por construção.
## Os controlos no ecrã (manípulo, ▲▼, 1×/2×/4×, teclado) estão em controlos_camara_livre.gd.

const OLHAR_RAD_POR_PX := 0.0045
const ANDAR_U_S := 4.2
const VERTICAL_U_S := 3.0
const SHIFT_X := 2.2
const PITCH_MAX := 1.45
const OLHOS_M := 1.6
const OLHAR_ALVO_Y := 1.3
const FOLGA_CHAO := 0.4
const TECTO := 12.0
const FOLGA_BORDA := 3.0
const DT_MAX := 0.08
const VELOCIDADES := [1, 2, 4]
## As teclas do andar (as do site: WASD, setas, E/Q e PageUp/PageDown para voar, Shift para correr).
const TECLAS := {
	KEY_W: "w", KEY_A: "a", KEY_S: "s", KEY_D: "d",
	KEY_UP: "arrowup", KEY_DOWN: "arrowdown", KEY_LEFT: "arrowleft", KEY_RIGHT: "arrowright",
	KEY_E: "e", KEY_Q: "q", KEY_PAGEUP: "pageup", KEY_PAGEDOWN: "pagedown", KEY_SHIFT: "shift",
}

var ativa := false
var yaw := 0.0
var pitch := 0.0
var joy := Vector2.ZERO
var sobe := 0
var vel := 1
var teclas: Dictionary = {}
## Px reais por unidade do ecrã (o olhar do site conta px reais; o ecrã do Mestre trabalha em unidades).
var px_por_unidade := 1.0
var _min := Vector2(-FOLGA_BORDA, -FOLGA_BORDA)
var _max := Vector2(FOLGA_BORDA, FOLGA_BORDA)
## Ordem 45: a altura do chão em (x, z) (Callable (x, z) -> float); sem ela, 0.
var altura_em: Callable = Callable()


func _init() -> void:
	name = "CamaraLivre"
	fov = 50.0
	near = 0.1
	far = 400.0
	current = false


## Entra: à beira sul da arena (z maior), olhos a 1,6, a olhar para o centro (desenho v2 §5 do site).
func entrar(centro: Vector3, tamanho: Vector2) -> void:
	_min = Vector2(centro.x - tamanho.x * 0.5 - FOLGA_BORDA, centro.z - tamanho.y * 0.5 - FOLGA_BORDA)
	_max = Vector2(centro.x + tamanho.x * 0.5 + FOLGA_BORDA, centro.z + tamanho.y * 0.5 + FOLGA_BORDA)
	var zs := centro.z + tamanho.y * 0.5
	position = Vector3(centro.x, chao(centro.x, zs) + OLHOS_M, zs)
	var d := Vector3(centro.x - position.x, chao(centro.x, centro.z) + OLHAR_ALVO_Y - position.y, centro.z - position.z).normalized()
	pitch = asin(clampf(d.y, -1.0, 1.0))
	yaw = atan2(-d.x, -d.z)
	joy = Vector2.ZERO
	sobe = 0
	teclas = {}
	ativa = true
	current = true
	_aplicar()


func sair() -> void:
	ativa = false
	joy = Vector2.ZERO
	sobe = 0
	teclas = {}
	current = false


## Arrastar para olhar (px do ecrã do Mestre). Fora do modo livre é inerte.
func olhar(dx: float, dy: float) -> void:
	if not ativa or not is_finite(dx) or not is_finite(dy):
		return
	yaw -= dx * px_por_unidade * OLHAR_RAD_POR_PX
	pitch = clampf(pitch - dy * px_por_unidade * OLHAR_RAD_POR_PX, -PITCH_MAX, PITCH_MAX)
	_aplicar()


func definir_joy(v: Vector2) -> void:
	joy = Vector2(clampf(v.x, -1.0, 1.0), clampf(v.y, -1.0, 1.0)) if v.is_finite() else Vector2.ZERO


func definir_sobe(s: int) -> void:
	sobe = signi(s)


func definir_vel(v: int) -> void:
	if v in VELOCIDADES:
		vel = v


func definir_tecla(nome: String, premida: bool) -> void:
	if not (nome in TECLAS.values()):
		return
	if premida:
		teclas[nome] = true
	else:
		teclas.erase(nome)


## O passo de andar: a matemática do ciclo da sala (manípulo + teclas → (mx, mz) normalizado; frente e direita
## só do yaw, no plano do chão; vertical à parte), com os clamps das bordas e da altura.
func passo(dt: float) -> void:
	if not ativa:
		return
	dt = clampf(dt, 0.0, DT_MAX)
	var t := teclas
	var mx := joy.x + (1.0 if (t.has("d") or t.has("arrowright")) else 0.0) - (1.0 if (t.has("a") or t.has("arrowleft")) else 0.0)
	var mz := joy.y + (1.0 if (t.has("s") or t.has("arrowdown")) else 0.0) - (1.0 if (t.has("w") or t.has("arrowup")) else 0.0)
	var mm := sqrt(mx * mx + mz * mz)
	if mm > 1.0:
		mx /= mm
		mz /= mm
	var p := position
	if mx != 0.0 or mz != 0.0:
		var s := sin(yaw)
		var c := cos(yaw)
		var v := ANDAR_U_S * vel * (SHIFT_X if t.has("shift") else 1.0)
		p.x = clampf(p.x + (c * mx + s * mz) * v * dt, _min.x, _max.x)
		p.z = clampf(p.z + (c * mz - s * mx) * v * dt, _min.y, _max.y)
	var su := sobe + (1 if (t.has("e") or t.has("pageup")) else 0) - (1 if (t.has("q") or t.has("pagedown")) else 0)
	if su != 0:
		p.y += su * VERTICAL_U_S * vel * dt
	var h := chao(p.x, p.z)
	p.y = clampf(p.y, h + FOLGA_CHAO, h + TECTO)  # ordem 45: o chão é o relevo, ponto a ponto
	position = p
	_aplicar()


## A altura do chão em (x, z): o relevo do mapa (ordem 45) ou 0.
func chao(x: float, z: float) -> float:
	return float(altura_em.call(x, z)) if altura_em.is_valid() else 0.0


func direcao() -> Vector3:
	var cp := cos(pitch)
	return Vector3(-sin(yaw) * cp, sin(pitch), -cos(yaw) * cp)


func _aplicar() -> void:
	transform = Transform3D(Basis.looking_at(direcao(), Vector3.UP), position)


func _process(delta: float) -> void:
	if ativa:
		passo(delta)


## Olhar: arrastar no tabuleiro (rato com botão, ou um dedo). O rato que o Godot emula a partir do toque
## (device = DEVICE_ID_EMULATION) não conta, para o mesmo dedo não olhar duas vezes.
func _unhandled_input(event: InputEvent) -> void:
	if not ativa:
		return
	if event is InputEventScreenDrag:
		olhar(event.relative.x, event.relative.y)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION:
		if event.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT):
			olhar(event.relative.x, event.relative.y)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventMagnifyGesture \
			or event is InputEventPanGesture:
		get_viewport().set_input_as_handled()  # na livre não há toque em casa nem zoom (aproxima-se andando)
