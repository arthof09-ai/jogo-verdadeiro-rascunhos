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
##       (Ordem 66) a cova passou a ser a bacia do LAGO: a água sobe a LAGO_ACIMA do fundo antigo e o leito
##       debaixo dela foi refeito (uma RASA até ao joelho e uma FUNDA de nadar) — ver «o lago», mais abaixo.
##   SE  o TERRAÇO do santuário ....... +3,6 m, escarpa virada ao centro, duas rampas nos flancos,
##                                      encosta de relva pelas costas (do canto da arena)
##   SO  a GARGANTA ................... um lombo de rocha e um tronco tombado: o corredor
##   N   a janela para a Árvore Ancestral (o chão cai para o vale)   ·   S  o monte sobe

## ORDEM DADOS DE APRESENTAÇÃO: o lado da casa vem da tabela única.
const Apresentacao := preload("res://dados/apresentacao.gd")
const CASA_M := Apresentacao.CASA_M
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
# ---- o LAGO (Ordem 66): a água da cova, subida. Fora da água o relevo é o da Ordem 38, vértice a vértice.
const LAGO_ACIMA := 1.25           # o nível do lago acima do fundo da cova da Ordem 38 (m)
const LAGO_RAIO := 11.0            # o lago vive dentro deste raio à volta da COVA (a margem fecha antes)
const LAGO_RASA_M := 0.48          # a fundura da RASA (m): a água pelo joelho de uma figura
const LAGO_FUNDA_M := 2.0          # a fundura da FUNDA (m): não se faz pé
# A FUNDA cabe dentro das casas que a grelha JÁ bloqueava como «água funda»: onde não se faz pé é onde a regra já
# dizia que não se pisa. São três bolhas que se fundem — (x, z, raio de fora, expoente da norma): a do meio enche
# o quadrado de 4 × 4 casas (x de 16,5 a 22,5 · z de −24 a −18); as outras duas são os lóbulos a oeste (as duas
# casas x 15–16,5 · z −22,5 a −19,5) e a sul (a fila z −18 a −16,5 · x 16,5–21): a margem da funda não é um
# quadrado, e não sai das casas bloqueadas.
const LAGO_FUNDA_CENTRO := Vector2(19.5, -21.0)
const LAGO_FUNDA_BOLHAS: Array[Vector4] = [Vector4(19.5, -21.0, 2.85, 2.6), Vector4(16.6, -21.0, 1.45, 2.0),
	Vector4(18.75, -18.2, 1.58, 2.0)]
const LAGO_TALUDE_M := 1.25        # largura do talude entre a funda e a rasa (m): o degrau que se lê no fundo
const LOMBO_A := Vector2(-25.0, 29.0)
const LOMBO_B := Vector2(-22.0, 8.0)
const LOMBO_ALTO := 2.3
const TRONCO_A := Vector2(-16.6, 29.5)
const TRONCO_B := Vector2(-13.4, 9.0)
const TRONCO_RAIO := 1.25

static var _n: FastNoiseLite
static var _fino := PackedFloat32Array()
static var _fino_38 := PackedFloat32Array()   # a zona fina SEM o lago (o relevo da Ordem 38): ver agua() e normal_38()
static var _largo := PackedFloat32Array()
static var _nivel_agua := INF
static var _nivel_lago := INF


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
## duas rampas largas nos flancos, e nas costas uma encosta de relva comprida (13 m) que sobe do
## canto da arena — quem vem do canto chega ao santuário por trás, a ver a arena por cima dele
## (antes as costas eram um talude de rocha a pique colado à vista 07).
static func terraco_descida(px: float, pz: float) -> float:
	var p := Vector2(px, pz)
	if p.length_squared() < 0.0001:
		return 1.3
	var a := absf(p.angle_to(-TERRACO))  # 0 = virado ao centro da arena
	var rampa := exp(-pow((a - deg_to_rad(96.0)) / deg_to_rad(27.0), 2.0))
	var costas := _ss(deg_to_rad(128.0), deg_to_rad(165.0), a)
	return 1.3 + 9.6 * rampa + 12.0 * costas


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
	# Ordem 66: o LAGO. O relevo da Ordem 38 fica guardado tal e qual (_fino_38); o leito do lago só mexe nos
	# vértices que ficam DEBAIXO do nível dele, dentro do raio do lago — a margem e tudo o que está em seco têm
	# exactamente os números de antes.
	_fino_38 = _fino.duplicate()
	var fundo_38 := _interpolar(_fino_38, N_FINO, MEIO_FINO, PASSO_FINO, COVA.x, COVA.y)
	_nivel_agua = fundo_38 + AGUA_ABAIXO
	_nivel_lago = fundo_38 + LAGO_ACIMA
	for j in N_FINO:
		for i in N_FINO:
			var x := -MEIO_FINO + i * PASSO_FINO
			var z := -MEIO_FINO + j * PASSO_FINO
			if Vector2(x - COVA.x, z - COVA.y).length_squared() < LAGO_RAIO * LAGO_RAIO:
				_fino[j * N_FINO + i] = _leito(x, z, _fino_38[j * N_FINO + i])


## Ordem 66 — o LEITO do lago em (x, z), dado o relevo da Ordem 38 nesse ponto (`h38`). Em seco (h38 ≥ nível)
## devolve h38 sem lhe tocar: a linha de água é a curva de nível da cova antiga, e a margem não muda.
## Debaixo de água o fundo é desenhado: a RASA (entra-se devagar e fica-se com a água pelo joelho, LAGO_RASA_M,
## com um ondulado leve de areia) e a FUNDA (LAGO_FUNDA_M, dentro das casas que a grelha já bloqueava — ver
## LAGO_FUNDA_BOLHAS), separadas por um TALUDE de LAGO_TALUDE_M — o degrau que se lê no fundo.
static func _leito(x: float, z: float, h38: float) -> float:
	var a := _nivel_lago - h38  # quanto a cova antiga ficava abaixo do nível: 0 na margem, cresce para o meio
	if a <= 0.0:
		return h38
	var n := ruido()
	var rasa := LAGO_RASA_M * tanh(a / 0.37)
	rasa += 0.035 * n.get_noise_2d(x * 60.0 + 500.0, z * 60.0) * _ss(0.15, 0.45, a)
	var funda := 0.0
	var torce := 1.0 + 0.05 * n.get_noise_2d(x * 14.0 - 300.0, z * 14.0 + 120.0)
	for b in LAGO_FUNDA_BOLHAS:
		var d := pow(pow(absf(x - b.x), b.w) + pow(absf(z - b.y), b.w), 1.0 / b.w) * torce
		funda = maxf(funda, 1.0 - _ss(b.z - LAGO_TALUDE_M, b.z, d))
	funda *= _ss(0.30, 0.62, a)
	return _nivel_lago - lerpf(rasa, LAGO_FUNDA_M, funda)


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


## Nível da água do charco da cova da Ordem 38 (m). Desde a Ordem 66 quem desenha a água é o lago (nivel_lago);
## este nível continua a ser o que o GERADOR do mapa e a GRELHA lêem (ver agua()).
static func nivel_agua() -> float:
	if _fino.is_empty():
		_cozer()
	return _nivel_agua


## A profundidade do CHARCO DA ORDEM 38 neste ponto (0 = seco), medida no relevo da Ordem 38 — exactamente o
## número de antes do lago. É o que o gerador do mapa e a grelha continuam a ler, de propósito (Ordem 66):
##   - a grelha bloqueia «água funda» nas MESMAS casas de antes: o que a água do lago custa a quem a atravessa
##     (no cânone é terreno difícil, não parede) é decisão do servidor, não deste cliente, e o pacote do terreno
##     não muda de casas por causa do lago;
##   - o gerador gasta a semente como antes: o resto do mapa não muda de sítio.
## A água que se VÊ e onde se molha os pés é a do lago: lago_fundura().
static func agua(x: float, z: float) -> float:
	if Vector2(x - COVA.x, z - COVA.y).length_squared() > COVA_RAIO * COVA_RAIO:
		return 0.0
	return maxf(nivel_agua() - altura_38(x, z), 0.0)


## O relevo da Ordem 38 (sem o leito do lago) em (x, z). Fora da água do lago é igual a altura().
static func altura_38(x: float, z: float) -> float:
	if _fino.is_empty():
		_cozer()
	if absf(x) <= MEIO_FINO and absf(z) <= MEIO_FINO:
		return _interpolar(_fino_38, N_FINO, MEIO_FINO, PASSO_FINO, x, z)
	return _interpolar(_largo, N_LARGO, MEIO_LARGO, PASSO_LARGO, x, z)


## A normal do relevo da Ordem 38 (sem o leito do lago): para as decisões do gerador do mapa (ver agua()).
static func normal_38(x: float, z: float) -> Vector3:
	var e := 0.75
	var dx := altura_38(x + e, z) - altura_38(x - e, z)
	var dz := altura_38(x, z + e) - altura_38(x, z - e)
	return Vector3(-dx, 2.0 * e, -dz).normalized()


## Ordem 66 — o nível da água do LAGO (m).
static func nivel_lago() -> float:
	if _fino.is_empty():
		_cozer()
	return _nivel_lago


## Ordem 66 — a FUNDURA do lago em (x, z): metros de água por cima do leito (0 = em seco). Só apresentação:
## nenhuma regra a lê.
static func lago_fundura(x: float, z: float) -> float:
	if Vector2(x - COVA.x, z - COVA.y).length_squared() >= LAGO_RAIO * LAGO_RAIO:
		return 0.0
	return maxf(nivel_lago() - altura(x, z), 0.0)


## Ordem 66 — a altura do que se VÊ de cima em (x, z): a superfície da água sobre o lago, o chão no resto.
## É a que a sombra do relevo usa (a sombra cai na água, não no leito).
static func altura_a_vista(x: float, z: float) -> float:
	var h := altura(x, z)
	if Vector2(x - COVA.x, z - COVA.y).length_squared() < LAGO_RAIO * LAGO_RAIO:
		return maxf(h, nivel_lago())
	return h
