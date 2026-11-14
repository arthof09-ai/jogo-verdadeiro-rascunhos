extends RefCounted
## relevo_floresta.gd — o RELEVO do campo de batalha da floresta (Ordem 37, corrigido na 38).
##
## UMA ALTURA FINAL ÚNICA (Ordem 38, defeito 9): altura(x, z) é a altura que a malha desenha,
## que a colisão sente e que a consulta devolve — as três lêem a MESMA grelha cozida, com a
## MESMA triangulação. A fórmula do desenho (forma()) só serve para cozer essa grelha uma vez;
## ninguém mais lhe toca. Não há «afundar a malha na orla»: o chão é contínuo da arena ao anel.
##
##   zona fina  — passo 0,75 m, |x|,|z| ≤ 42 m: a arena jogável (±37,5 m) mais 4,5 m de margem.
##                É aqui que há colisão. Cada casa de 1,5 m tem um vértice no centro e nos cantos.
##   zona larga — passo 3 m, até ±126 m: a floresta da orla e do anel (ninguém lá joga).
##
## Mundo: -Z = norte, +X = leste, metros. A arena jogável é o quadrado de 75×75 m
## (50×50 casas de 1,5 m — palavra do Mestre) centrado na origem. O contrato mundo↔casa está
## em grelha_floresta.gd.
##
## O desenho (lê-se sem medidor — defeito 8): um marco de relevo por quadrante.
##   NO  o OUTEIRO dos menires ........ +3,3 m, topo plano: terreno alto para defender
##   NE  a COVA do charco ............. −2,6 m, com água no fundo: travessia em desvantagem
##   SE  o TERRAÇO do santuário ....... +3,6 m, escarpa virada ao centro, duas rampas nos flancos
##   SO  a GARGANTA ................... um lombo de rocha e um tronco tombado: o corredor
##   N   a janela para a Árvore Ancestral (o chão cai para o vale)   ·   S  o monte sobe

const CASA_M := 1.5
const LADO_CASAS := 50
const LADO := 75.0
const MEIO := 37.5

const PASSO_FINO := 0.75
const MEIO_FINO := 42.0
const N_FINO := 113            # 2 × 42 / 0,75 + 1
const PASSO_LARGO := 3.0
const MEIO_LARGO := 126.0
const N_LARGO := 85            # 2 × 126 / 3 + 1
const COSTURA_M := 3.0         # largura da faixa onde a zona fina se cose à larga (39–42 m)

## Distâncias «para fora da arena» (ver fora()).
const ORLA_FORA := 24.0        # até aqui a floresta é a rica (árvores inteiras, relva, arbustos)
const ANEL_FORA := 80.0        # até aqui vai a floresta pobre do anel
const CHAO_FORA := 88.0        # onde a malha do chão acaba (já atrás da crista)

## Azimute (graus, a partir do norte) da Árvore Ancestral e da janela aberta na orla.
const ANCORA_AZIMUTE := -7.0
const JANELA_MEIA_LARGURA := 16.0

# ---- os marcos de relevo (um por quadrante)
const OUTEIRO := Vector2(-20.0, -19.0)
const OUTEIRO_ALTO := 3.3
const OUTEIRO_TOPO := 4.2          # raio do topo plano
const OUTEIRO_PE := 11.5           # raio do pé
const TERRACO := Vector2(20.5, 20.0)
const TERRACO_ALTO := 3.6
const TERRACO_TOPO := 6.0
const COVA := Vector2(19.5, -19.0)
const COVA_FUNDO := 2.6
const COVA_RAIO := 8.0
const AGUA_ABAIXO := 0.75          # a água fica a esta altura acima do fundo da cova
const LOMBO_A := Vector2(-25.0, 29.0)
const LOMBO_B := Vector2(-22.0, 8.0)
const LOMBO_ALTO := 2.3
const TRONCO_A := Vector2(-16.6, 29.5)
const TRONCO_B := Vector2(-13.4, 9.0)
const TRONCO_RAIO := 1.25

static var _n: FastNoiseLite
static var _fino := PackedFloat32Array()
static var _largo := PackedFloat32Array()
static var _nivel_agua := INF


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


static func na_janela(x: float, z: float, folga_graus: float = 0.0) -> bool:
	return absf(angle_difference(deg_to_rad(azimute(x, z)), deg_to_rad(ANCORA_AZIMUTE))) < deg_to_rad(JANELA_MEIA_LARGURA + folga_graus)


static func _ss(a: float, b: float, v: float) -> float:
	var t := clampf((v - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func _g(dx: float, dz: float, raio: float) -> float:
	return exp(-(dx * dx + dz * dz) / (raio * raio))


## Distância de p ao segmento a–b, e a posição (0–1) ao longo dele.
static func ao_segmento(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return Vector2(p.distance_to(a + ab * t), t)


## A largura da descida do terraço conforme o lado: escarpa (1,3 m) virada ao centro da arena,
## duas rampas largas nos flancos, encosta média nas costas.
static func terraco_descida(px: float, pz: float) -> float:
	var p := Vector2(px, pz)
	if p.length_squared() < 0.0001:
		return 1.3
	var a := absf(p.angle_to(-TERRACO))  # 0 = virado ao centro da arena
	var rampa := exp(-pow((a - deg_to_rad(96.0)) / deg_to_rad(27.0), 2.0))
	var costas := _ss(deg_to_rad(128.0), deg_to_rad(165.0), a)
	return 1.3 + 9.6 * rampa + 3.4 * costas


## A FÓRMULA do desenho. Só o forno da grelha (_cozer) a chama.
static func forma(x: float, z: float) -> float:
	var n := ruido()
	var h := 0.0
	# ---- macro: o ombro da encosta (a sul o monte, a norte o vale)
	h += 0.022 * clampf(z, -50.0, 50.0)
	h -= 14.0 * _ss(-34.0, -112.0, z)
	h += 11.0 * _ss(38.0, 112.0, z)
	h += 6.0 * _ss(42.0, 112.0, x) * (0.6 + 0.4 * sin(z * 0.04 + 1.0))
	h += 4.5 * _ss(44.0, 112.0, -x) * (0.55 + 0.45 * cos(z * 0.045))
	# ---- NO: o outeiro (topo plano, vertente franca)
	var d_out := Vector2(x - OUTEIRO.x, z - OUTEIRO.y).length()
	d_out *= 1.0 + 0.10 * n.get_noise_2d(x * 9.0 + 40.0, z * 9.0)
	h += OUTEIRO_ALTO * _ss(OUTEIRO_PE, OUTEIRO_TOPO, d_out)
	# ---- SE: o terraço (escarpa + rampas)
	var tx := x - TERRACO.x
	var tz := z - TERRACO.y
	var d_ter := Vector2(tx, tz).length()
	h += TERRACO_ALTO * _ss(TERRACO_TOPO + terraco_descida(tx, tz), TERRACO_TOPO, d_ter)
	# ---- NE: a cova (com um rebordo do lado do centro: de fora não se vê o fundo)
	var d_cova := Vector2(x - COVA.x, z - COVA.y).length()
	h -= COVA_FUNDO * exp(-(d_cova * d_cova) / (COVA_RAIO * COVA_RAIO))
	h += 0.55 * exp(-pow((d_cova - 11.0) / 2.4, 2.0)) * _ss(-0.2, 0.7, Vector2(x - COVA.x, z - COVA.y).normalized().dot(-COVA.normalized()))
	# ---- SO: o lombo de rocha (o tronco tombado é malha, não relevo) e o chão gasto do corredor
	var sl := ao_segmento(Vector2(x, z), LOMBO_A, LOMBO_B)
	h += LOMBO_ALTO * exp(-pow(sl.x / 2.7, 2.0)) * (0.55 + 0.45 * sin(sl.y * PI)) * (0.8 + 0.5 * n.get_noise_2d(x * 14.0, z * 14.0 + 80.0))
	var meio_corredor := (LOMBO_A + LOMBO_B + TRONCO_A + TRONCO_B) * 0.25
	h -= 0.45 * exp(-pow((x - meio_corredor.x - (z - meio_corredor.y) * -0.15) / 2.6, 2.0)) * _ss(34.0, 26.0, z) * _ss(4.0, 10.0, z)
	# ---- a sul o chão começa a subir para o monte
	h += 1.0 * _g(x - 2.0, z - 35.0, 10.0)
	# ---- ruído em 3 escalas; o miolo da clareira fica mais liso (é a arena)
	var miolo := lerpf(0.30, 1.0, _ss(9.0, 24.0, Vector2(x, z).length()))
	h += n.get_noise_2d(x * 2.2, z * 2.2) * 0.75 * miolo
	h += n.get_noise_2d(x * 7.0 + 100.0, z * 7.0) * 0.28 * miolo
	h += n.get_noise_2d(x * 22.0, z * 22.0 + 50.0) * 0.07
	# ---- a crista do anel (mais alta a sul, mais baixa a norte: o vale fica aberto)
	var f := fora(x, z)
	if f > 30.0:
		var ang := atan2(x, -z)
		var crista := 7.0 + 5.0 * n.get_noise_2d(cos(ang) * 160.0, sin(ang) * 160.0) + 4.0 * (0.5 - 0.5 * cos(ang))
		# na janela da Árvore Ancestral não há crista: o vale fica aberto até ela
		var fecho := _ss(deg_to_rad(JANELA_MEIA_LARGURA * 0.7), deg_to_rad(JANELA_MEIA_LARGURA * 2.2), absf(angle_difference(ang, deg_to_rad(ANCORA_AZIMUTE))))
		h += crista * _ss(30.0, 72.0, f) * lerpf(0.10, 1.0, fecho)
	return h


static func _cozer() -> void:
	_largo.resize(N_LARGO * N_LARGO)
	for j in N_LARGO:
		for i in N_LARGO:
			_largo[j * N_LARGO + i] = forma(-MEIO_LARGO + i * PASSO_LARGO, -MEIO_LARGO + j * PASSO_LARGO)
	# A zona fina COSE-SE à larga: nos últimos 3 m (já fora da arena jogável, que acaba aos
	# 37,5 m) a altura fina desliza para a superfície da grelha larga, e na borda é exactamente
	# ela — sem degrau nem fresta entre as duas malhas, e a consulta é contínua.
	_fino.resize(N_FINO * N_FINO)
	for j in N_FINO:
		for i in N_FINO:
			var x := -MEIO_FINO + i * PASSO_FINO
			var z := -MEIO_FINO + j * PASSO_FINO
			var h := forma(x, z)
			var borda := _ss(MEIO_FINO - COSTURA_M, MEIO_FINO, maxf(absf(x), absf(z)))
			if borda > 0.0:
				h = lerpf(h, _interpolar(_largo, N_LARGO, MEIO_LARGO, PASSO_LARGO, x, z), borda)
			_fino[j * N_FINO + i] = h
	_nivel_agua = _interpolar(_fino, N_FINO, MEIO_FINO, PASSO_FINO, COVA.x, COVA.y) + AGUA_ABAIXO


## A grelha fina cozida (N_FINO × N_FINO, linha a linha de norte para sul): a malha do chão e a
## colisão são feitas DESTES números.
static func grelha_fina() -> PackedFloat32Array:
	if _fino.is_empty():
		_cozer()
	return _fino


static func grelha_larga() -> PackedFloat32Array:
	if _largo.is_empty():
		_cozer()
	return _largo


## Altura da superfície de triângulos de uma grelha regular. A diagonal de cada quadrado vai
## de (i+1, j) a (i, j+1) — a mesma da malha (campo_floresta._criar_terreno) e a mesma da
## colisão, que é feita dos MESMOS triângulos (provado por raio em ferramentas/provar_grelha.gd).
static func _interpolar(g: PackedFloat32Array, n: int, meio: float, passo: float, x: float, z: float) -> float:
	var fx := clampf((x + meio) / passo, 0.0, float(n - 1) - 0.00001)
	var fz := clampf((z + meio) / passo, 0.0, float(n - 1) - 0.00001)
	var i := int(fx)
	var j := int(fz)
	var u := fx - float(i)
	var v := fz - float(j)
	var k := j * n + i
	if u + v <= 1.0:
		var h00 := g[k]
		return h00 + u * (g[k + 1] - h00) + v * (g[k + n] - h00)
	var h11 := g[k + n + 1]
	return h11 + (1.0 - u) * (g[k + n] - h11) + (1.0 - v) * (g[k + 1] - h11)


static func na_zona_fina(x: float, z: float) -> bool:
	return absf(x) <= MEIO_FINO and absf(z) <= MEIO_FINO


## A ALTURA FINAL ÚNICA do chão em (x, z).
static func altura(x: float, z: float) -> float:
	if _fino.is_empty():
		_cozer()
	if absf(x) <= MEIO_FINO and absf(z) <= MEIO_FINO:
		return _interpolar(_fino, N_FINO, MEIO_FINO, PASSO_FINO, x, z)
	return _interpolar(_largo, N_LARGO, MEIO_LARGO, PASSO_LARGO, x, z)


static func normal(x: float, z: float) -> Vector3:
	var e := 0.75
	var dx := altura(x + e, z) - altura(x - e, z)
	var dz := altura(x, z + e) - altura(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()


## Nível da água do charco da cova (m).
static func nivel_agua() -> float:
	if _fino.is_empty():
		_cozer()
	return _nivel_agua


## Há água (charco) por cima do chão neste ponto? Devolve a profundidade (0 = seco).
static func agua(x: float, z: float) -> float:
	if Vector2(x - COVA.x, z - COVA.y).length_squared() > COVA_RAIO * COVA_RAIO:
		return 0.0
	return maxf(nivel_agua() - altura(x, z), 0.0)
