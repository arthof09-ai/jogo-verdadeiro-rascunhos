extends RefCounted
## relevo_floresta.gd — Ordem 37: o RELEVO do campo de batalha da floresta (uma só função).
##
## altura(x, z) é a única fonte da forma do chão: serve a malha do terreno 3D, a colisão,
## o assentar das árvores/pedras/relva E a saia do anel próximo (a mesma função, em malha
## pobre) — por isso o chão real e o fundo nunca abrem costura de forma.
##
## Mundo: -Z = norte, +X = leste, metros. A arena jogável é o quadrado de 60×60 m
## (40×40 casas de 1,5 m) centrado na origem.
##
## O desenho (palavra do Mestre: «Sim, desenha relevo no mapa novo»):
##   - a clareira assenta num OMBRO de encosta: a sul o monte sobe, a norte o chão cai
##     para o vale (a vista preparada da referência 07: a árvore-âncora fica a norte);
##   - dentro da arena: um cômoro a oeste, um terraço de rocha a sueste, uma cova a
##     nordeste e duas lombas nos cantos — declives suaves, jogáveis;
##   - além da arena: o vale a norte, a encosta a sul, cristas a leste/oeste e a crista
##     do anel próximo.

const LADO := 60.0
const MEIO := 30.0
const CASA_M := 1.5
const LADO_CASAS := 40
## Meio-lado da grelha do terreno 3D real (m). O terreno real acaba onde o anel começa.
const MEIO_3D := 52.0
## Distâncias «para fora da arena» (ver fora()): onde o anel próximo começa e acaba.
const ANEL_DENTRO := 16.0
const ANEL_FORA := 62.0
## Azimute (graus, a partir do norte) da árvore-âncora e da janela aberta na orla.
const ANCORA_AZIMUTE := -7.0
const JANELA_MEIA_LARGURA := 19.0

static var _n: FastNoiseLite


static func ruido() -> FastNoiseLite:
	if _n == null:
		_n = FastNoiseLite.new()
		_n.seed = 37
		_n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_n.frequency = 0.01
		_n.fractal_type = FastNoiseLite.FRACTAL_NONE
	return _n


## «Raio» de quadrado arredondado (norma 8): vale MEIO sobre a orla da arena.
static func quadrado(x: float, z: float) -> float:
	var a := absf(x)
	var b := absf(z)
	var m := maxf(a, b)
	if m < 0.0001:
		return 0.0
	var q := minf(a, b) / m
	return m * pow(1.0 + pow(q, 8.0), 0.125)


## Metros para FORA da orla da arena (negativo = dentro).
static func fora(x: float, z: float) -> float:
	return quadrado(x, z) - MEIO


## Azimute em graus (0 = norte, positivo para leste).
static func azimute(x: float, z: float) -> float:
	return rad_to_deg(atan2(x, -z))


static func na_janela(x: float, z: float) -> bool:
	return absf(angle_difference(deg_to_rad(azimute(x, z)), deg_to_rad(ANCORA_AZIMUTE))) < deg_to_rad(JANELA_MEIA_LARGURA)


static func _ss(a: float, b: float, v: float) -> float:
	var t := clampf((v - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _g(dx: float, dz: float, raio: float) -> float:
	return exp(-(dx * dx + dz * dz) / (raio * raio))


static func altura(x: float, z: float) -> float:
	var n := ruido()
	var h := 0.0
	# ---- macro: o ombro da encosta
	h += 0.028 * clampf(z, -40.0, 40.0)
	h -= 13.0 * _ss(-23.0, -80.0, z)
	h += 10.0 * _ss(24.0, 82.0, z)
	h += 6.0 * _ss(30.0, 86.0, x) * (0.6 + 0.4 * sin(z * 0.045 + 1.0))
	h += 4.0 * _ss(34.0, 90.0, -x) * (0.55 + 0.45 * cos(z * 0.05))
	# ---- dentro da arena
	h += 2.3 * _g(x + 13.0, z - 8.0, 8.5)            # cômoro (oeste)
	var t := _ss(9.5, 4.5, Vector2(x - 17.0, (z - 16.0) * 1.15).length())
	h += 2.7 * t                                      # terraço de rocha (sueste)
	h -= 1.4 * _g(x - 8.0, z + 11.0, 7.5)            # cova (nordeste)
	h += 1.3 * _g(x + 21.0, z + 20.0, 6.0)           # lomba (noroeste)
	h += 1.0 * _g(x - 23.0, z + 22.0, 7.0)           # lomba (nordeste, à beira da janela)
	h += 0.9 * _g(x + 3.0, z - 24.0, 9.0)            # sobe para a encosta (sul)
	# ---- ruído em 3 escalas (45 m, 14 m, 4,5 m)
	h += n.get_noise_2d(x * 2.2, z * 2.2) * 0.9
	h += n.get_noise_2d(x * 7.0 + 100.0, z * 7.0) * 0.35
	h += n.get_noise_2d(x * 22.0, z * 22.0 + 50.0) * 0.10
	# ---- a crista do anel próximo (mais alta a sul, mais baixa a norte: o vale fica aberto)
	var f := fora(x, z)
	if f > 24.0:
		var ang := atan2(x, -z)
		var crista := 7.0 + 5.0 * n.get_noise_2d(cos(ang) * 160.0, sin(ang) * 160.0) + 4.0 * (0.5 - 0.5 * cos(ang))
		h += crista * _ss(24.0, 58.0, f)
	return h


static func normal(x: float, z: float) -> Vector3:
	var e := 0.5
	var dx := altura(x + e, z) - altura(x - e, z)
	var dz := altura(x, z + e) - altura(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()


## Centro (no chão) da casa (i, j) da grelha de 40×40 — para a integração com a arena do jogo.
static func centro_casa(i: int, j: int) -> Vector3:
	var x := (float(i) - (LADO_CASAS - 1) * 0.5) * CASA_M
	var z := (float(j) - (LADO_CASAS - 1) * 0.5) * CASA_M
	return Vector3(x, altura(x, z), z)
