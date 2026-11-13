extends Camera3D
## camera_livre.gd — Ordem 37: a câmara de PASSEIO do mapa da floresta (só para ver e provar o
## mapa; a câmara do jogo é a camera_mesa.gd e não é tocada aqui).
##
##   WASD ............ andar (a pé: os olhos seguem o relevo)      Shift ... correr
##   botão direito ... olhar (arrastar)       setas ... olhar      Q / E ... descer / subir (voo)
##   R ............... voltar ao chão         G ....... girar 360° sozinha (a prova dos cartões)

const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")

@export var velocidade: float = 6.0
@export var altura_olhos: float = 1.7
@export var sensibilidade: float = 0.25
## Até onde se pode andar (m para fora da orla da arena): a orla real, nunca o anel pintado.
@export var limite_fora: float = 12.0

var _rumo := 0.0        # graus, 0 = norte, positivo para leste
var _inclinacao := 0.0  # graus, positivo = olhar para cima
var _voo := 0.0         # metros acima da altura dos olhos
var _girar := false


func _ready() -> void:
	ler_transformacao()


## Depois de alguém pousar a câmara (campo_floresta.ir_para_vista), lê de volta rumo e inclinação.
func ler_transformacao() -> void:
	_rumo = -rad_to_deg(rotation.y)
	_inclinacao = rad_to_deg(rotation.x)
	_voo = position.y - Relevo.altura(position.x, position.z) - altura_olhos
	if absf(_voo) < 0.05:
		_voo = 0.0


func _unhandled_input(event: InputEvent) -> void:
	var m := event as InputEventMouseMotion
	if m != null and (m.button_mask & MOUSE_BUTTON_MASK_RIGHT) != 0:
		_rumo += m.relative.x * sensibilidade
		_inclinacao = clampf(_inclinacao - m.relative.y * sensibilidade, -80.0, 80.0)
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo:
		if k.keycode == KEY_R:
			_voo = 0.0
		elif k.keycode == KEY_G:
			_girar = not _girar


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_LEFT):
		_rumo -= 70.0 * delta
	if Input.is_key_pressed(KEY_RIGHT):
		_rumo += 70.0 * delta
	if Input.is_key_pressed(KEY_UP):
		_inclinacao = minf(_inclinacao + 50.0 * delta, 80.0)
	if Input.is_key_pressed(KEY_DOWN):
		_inclinacao = maxf(_inclinacao - 50.0 * delta, -80.0)
	if _girar:
		_rumo += 24.0 * delta
	var anda := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		anda.y += 1.0
	if Input.is_key_pressed(KEY_S):
		anda.y -= 1.0
	if Input.is_key_pressed(KEY_D):
		anda.x += 1.0
	if Input.is_key_pressed(KEY_A):
		anda.x -= 1.0
	if Input.is_key_pressed(KEY_E):
		_voo += velocidade * delta
	if Input.is_key_pressed(KEY_Q):
		_voo = maxf(_voo - velocidade * delta, 0.0)
	var az := deg_to_rad(_rumo)
	var frente := Vector3(sin(az), 0.0, -cos(az))
	var lado := Vector3(cos(az), 0.0, sin(az))
	var p := position
	if anda != Vector2.ZERO:
		var v := velocidade * (2.5 if Input.is_key_pressed(KEY_SHIFT) else 1.0)
		var passo := (frente * anda.y + lado * anda.x).normalized() * v * delta
		var novo := p + passo
		if Relevo.fora(novo.x, novo.z) <= limite_fora:
			p = novo
	p.y = Relevo.altura(p.x, p.z) + altura_olhos + _voo
	position = p
	rotation = Vector3(deg_to_rad(_inclinacao), -az, 0.0)
