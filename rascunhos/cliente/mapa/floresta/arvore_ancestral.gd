extends RefCounted
## arvore_ancestral.gd — Ordem 38 (defeito 2): a ÁRVORE ANCESTRAL, o marco do mapa.
##
## Feita à imagem das 5 referências (referencias-arvore-ancestral/): uma figueira colossal de
## copa em guarda-chuva, tronco de feixe (as raízes sobem por ele como nervuras) com
## raízes-contraforte que se espraiam como um polvo e assentam no chão, o PALÁCIO de três
## telhados pousado na forquilha e quatro dúzias de pagodes em plataformas redondas — uns
## encostados ao tronco em mãos-francesas, outros sobre as raízes em estacas. NADA flutua: cada
## pagode sabe onde tem os pés.
##
## ORIENTAÇÃO (palavra do Mestre: NORTE = frente do palácio): o modelo tem a frente do palácio
## virada a NORTE (−Z do mundo). A árvore está a norte da arena, por isso da arena vê-se a face
## SUL (a da referência «sul»); as outras faces provam-se com a câmara à volta dela
## (ferramentas/provar_ancestral.gd, lado a lado com as referências).
##
## PROPORÇÕES medidas na referência norte (H = altura total, do pé das raízes ao cimo da copa):
##   copa ......... raio 0,78 H; cimo a 1,00 H; orla a 0,66 H; cúpula de almofadas com forro
##   tronco ....... raio 0,17 H a meia altura; forquilha a 0,56 H
##   raízes ....... 14 contrafortes, nascem a 0,30–0,47 H e chegam a 0,66–0,86 H do eixo
##   palácio ...... plataforma a 0,615 H (raio 0,165 H), 0,15 H para norte do eixo; cimo a 0,86 H
##   pagodes ...... 23 na face norte (posições lidas da referência) + 23 nas outras faces
##
## Uma só malha, um só material (shaders/ancestral.gdshader): 1 chamada de desenho.
## UV.x = matéria (0 madeira, 1 folha, 2 construção, 3 luz própria); COLOR.a = sol que chega.

const Paleta := preload("res://mapa/floresta/paleta_floresta.gd")
const Lote := preload("res://mapa/floresta/lote_malha.gd")
const Formas := preload("res://mapa/floresta/formas_floresta.gd")

## 260 m (palavra do Mestre): do pé das raízes ao cimo da copa.
const ALTURA := 260.0
const RAIO_COPA := 0.78          # × ALTURA
const RAIO_OUTEIRO := 1.15       # × ALTURA: até onde vai o mar de copas onde a árvore assenta
const N_RAIZES := 14
const PALACIO := Vector3(0.0, 0.615, -0.15)   # centro da plataforma (× ALTURA); −Z = norte
## O perfil do tronco: [raio, altura] de baixo para cima (× ALTURA).
const PERFIL_TRONCO: Array = [[0.240, -0.04], [0.218, 0.08], [0.192, 0.22], [0.170, 0.38], [0.162, 0.48],
	[0.174, 0.555], [0.150, 0.60]]

## Os pagodes da face NORTE, lidos da referência «norte»: [x NO ECRÃ, altura, raio da plataforma,
## andares]. A câmara da referência está a norte e olha para sul: a esquerda do ecrã (x < 0) é
## LESTE — o construtor troca o sinal ao passar para o mundo.
const PAGODES_NORTE: Array = [
	[-0.247, 0.500, 0.062, 2], [0.236, 0.546, 0.052, 2], [0.110, 0.540, 0.050, 1], [0.011, 0.454, 0.058, 2],
	[-0.144, 0.454, 0.046, 1], [0.218, 0.460, 0.040, 1], [0.207, 0.385, 0.060, 2], [0.300, 0.408, 0.036, 2],
	[-0.224, 0.380, 0.050, 1], [-0.320, 0.385, 0.036, 2], [-0.380, 0.356, 0.044, 2], [-0.130, 0.310, 0.050, 2],
	[0.098, 0.293, 0.052, 2], [0.374, 0.287, 0.056, 2], [-0.448, 0.300, 0.034, 1], [-0.500, 0.264, 0.040, 1],
	[-0.350, 0.247, 0.050, 2], [-0.040, 0.218, 0.056, 2], [-0.253, 0.276, 0.036, 1], [0.150, 0.207, 0.034, 1],
	[0.287, 0.207, 0.040, 1], [0.500, 0.236, 0.036, 1], [0.340, 0.345, 0.034, 1]]

static var _rn: FastNoiseLite


## Ponto a `rho` do eixo, no azimute `az` (0 = norte, positivo para leste), à altura `y`.
static func _pol(rho: float, az: float, y: float) -> Vector3:
	return Vector3(rho * sin(az), y, -rho * cos(az))


## Raio do tronco à altura y (tudo × ALTURA).
static func _raio_tronco(y: float) -> float:
	var p := PERFIL_TRONCO
	if y <= float(p[0][1]):
		return float(p[0][0])
	for i in range(1, p.size()):
		if y <= float(p[i][1]):
			var t := (y - float(p[i - 1][1])) / (float(p[i][1]) - float(p[i - 1][1]))
			return lerpf(float(p[i - 1][0]), float(p[i][0]), t)
	return float(p[p.size() - 1][0])


## Cimo da copa (a cúpula do guarda-chuva) à distância rho do eixo.
static func _cimo_copa(rho: float) -> float:
	return 0.985 - 0.33 * pow(clampf(rho / RAIO_COPA, 0.0, 1.2), 2.2)


## O CHÃO onde a árvore assenta (× ALTURA): o outeiro baixo, o mesmo para a malha do outeiro,
## para as raízes (que pousam nele) e para as estacas dos pagodes.
static func _chao(x: float, z: float) -> float:
	if _rn == null:
		_rn = FastNoiseLite.new()
		_rn.seed = 911
		_rn.frequency = 0.02
	var t := clampf((Vector2(x, z).length() - 0.10) / (RAIO_OUTEIRO - 0.10), 0.0, 1.0)
	return -(0.012 + 0.085 * pow(t, 1.7)) + _rn.get_noise_2d(x * ALTURA, z * ALTURA) * 0.008


## Devolve {"malha": ArrayMesh (em metros, pé na origem), "tri": int, "partes": {...},
## "outeiro": ArrayMesh, "outeiro_tri": int, "pagodes": int, "pagodes_no_ar": int}.
static func construir() -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = 3807
	var madeira := Lote.new()
	var folha := Lote.new()
	var obra := Lote.new()
	var lume := Lote.new()
	var apoios: Array = []        # [Vector3 centro, raio]: as amostras das raízes (onde se pousa)
	_tronco(madeira)
	_raizes(madeira, r, apoios)
	_copa(madeira, folha, r)
	_palacio(obra, lume)
	var contas := _pagodes(obra, lume, r, apoios)
	var tudo := Lote.new()
	var escala := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * ALTURA), Vector3.ZERO)
	var materias: Array = [madeira, folha, obra, lume]
	var partes := {}
	for id in materias.size():
		var l: Lote = materias[id]
		for i in l.uv.size():
			l.uv[i] = Vector2(float(id), l.uv[i].y)
		tudo.juntar(l, escala)
		partes[["madeira", "folha", "construcao", "luz"][id]] = l.triangulos()
	_cozer_sol(tudo)
	var monte := _outeiro(apoios)
	return {"malha": tudo.fechar(), "tri": tudo.triangulos(), "partes": partes,
		"outeiro": monte.fechar(), "outeiro_tri": monte.triangulos(),
		"pagodes": contas.x, "pagodes_no_ar": contas.y}


static func _tronco(m: Lote) -> void:
	# o miolo do feixe: fica por dentro das nervuras (um pouco mais fino e mais escuro — os sulcos)
	var funda := Paleta.ANCESTRAL_CASCA_FUNDA.darkened(0.15)
	var casca := Paleta.ANCESTRAL_CASCA.lerp(Paleta.ANCESTRAL_CASCA_FUNDA, 0.55)
	var perfil: Array = []
	for g: Array in PERFIL_TRONCO:
		perfil.append([float(g[0]) * (0.93 if float(g[1]) < 0.5 else 1.0), g[1]])
	perfil.append([0.0, 0.62])
	m.torno(Vector3.ZERO, perfil, 22, funda, casca)


## A altura do eixo de uma raiz a `rho` do eixo (a `s` do caminho, 0 = tronco, 1 = ponta).
## Medido na referência: a crista das raízes cai em exponencial (0,32 H a 0,31 H do eixo · 0,21 a
## 0,44 · 0,09 a 0,63) e só na ponta pousa no chão, meio enterrada, com um arco ou dois pelo caminho.
static func _raiz_y(p: Vector3, s: float, nasce: float, raio: float, fi: float) -> float:
	var rho := Vector2(p.x, p.z).length()
	var chao := _chao(p.x, p.z) + raio * 0.30
	var crista := nasce * exp(-(rho - 0.158) / 0.27)
	var pousa := smoothstep(0.55, 1.0, s)
	var arco := 0.012 * sin(s * PI * 3.0 + fi) * s * (1.0 - s) * 4.0
	return maxf(lerpf(crista, chao, pousa) + arco, chao)


static func _guardar_apoios(apoios: Array, pts: Array, de: int) -> void:
	for i in range(de, pts.size()):
		apoios.append([pts[i][0], pts[i][1]])
		if i + 1 < pts.size():
			apoios.append([((pts[i][0] as Vector3) + (pts[i + 1][0] as Vector3)) * 0.5,
				(float(pts[i][1]) + float(pts[i + 1][1])) * 0.5])


static func _raizes(m: Lote, r: RandomNumberGenerator, apoios: Array) -> void:
	var casca := Paleta.ANCESTRAL_CASCA
	var funda := Paleta.ANCESTRAL_CASCA.lerp(Paleta.ANCESTRAL_CASCA_FUNDA, 0.5)
	for k in N_RAIZES:
		var az0 := TAU * (float(k) + r.randf_range(-0.28, 0.28)) / float(N_RAIZES)
		var alcance := r.randf_range(0.66, 0.86)
		var nasce := r.randf_range(0.30, 0.47)
		var onda := r.randf_range(1.2, 2.2)
		var fi := r.randf() * TAU
		var grosso := r.randf_range(0.040, 0.050)
		var torce := r.randf_range(-0.32, 0.32)
		var cimo := r.randf_range(0.50, 0.56)
		var pts: Array = []
		# a NERVURA: a raiz sobe pelo tronco, torcida, até debaixo da forquilha (o tronco é um feixe)
		var n_nerv := 7
		for i in n_nerv:
			var t := float(i) / float(n_nerv)
			var y := lerpf(cimo, nasce, t)
			var raio := lerpf(0.026, grosso + 0.012, t)
			pts.append([_pol(_raio_tronco(y) - raio * 0.12, az0 + torce * (1.0 - t), y), raio])
		# a RAIZ: larga o tronco e vai pousar longe
		for i in 18:
			var s := float(i) / 17.0
			var rho := lerpf(0.158, alcance, pow(s, 1.5))
			var az := az0 + 0.26 * sin(s * PI * onda + fi) * s + 0.05 * sin(s * 11.0 + fi * 2.0) * s
			var raio := grosso * pow(1.0 - s, 0.9) + 0.012
			var p := _pol(rho, az, 0.0)
			p.y = _raiz_y(p, s, nasce, raio, fi)
			pts.append([p, raio])
		m.tubo(pts, 9, funda, casca, true)
		_guardar_apoios(apoios, pts, n_nerv + 2)
		# a raiz bifurca a meio caminho
		if r.randf() < 0.75:
			var s0 := r.randf_range(0.34, 0.5)
			var lado := -1.0 if r.randf() < 0.5 else 1.0
			var az1 := az0 + 0.26 * sin(s0 * PI * onda + fi) * s0 + 0.05 * sin(s0 * 11.0 + fi * 2.0) * s0
			var alcance2 := alcance * r.randf_range(0.80, 0.98)
			var pts2: Array = []
			for i in 10:
				var t := float(i) / 9.0
				var s := lerpf(s0, 1.0, t)
				var rho := lerpf(0.158, lerpf(alcance, alcance2, t), pow(s, 1.5))
				var az := az1 + lado * (0.06 + 0.30 * t) * pow(t, 0.8) + 0.05 * sin(t * 5.0 + fi)
				var raio := (grosso * pow(1.0 - s, 0.9) + 0.012) * lerpf(0.85, 0.62, minf(t * 3.0, 1.0))
				var p := _pol(rho, az, 0.0)
				p.y = _raiz_y(p, s, nasce, raio, fi + 1.7)
				pts2.append([p, raio])
			m.tubo(pts2, 7, funda, casca, true)
			_guardar_apoios(apoios, pts2, 1)


## O sector do palácio (a norte): ramos e forro da copa afastam-se para ele se ver.
static func _no_sector_do_palacio(az: float, meia_largura: float) -> bool:
	return absf(angle_difference(az, 0.0)) < meia_largura


static func _copa(m: Lote, f: Lote, r: RandomNumberGenerator) -> void:
	var casca := Paleta.ANCESTRAL_CASCA.lerp(Paleta.ANCESTRAL_CASCA_FUNDA, 0.40)
	var ponta := casca.lerp(Paleta.ANCESTRAL_CASCA_FUNDA, 0.5)
	# ---- os ramos-mestres baixos: em candelabro — largam o tronco a subir e deitam-se por
	# baixo da copa até à orla; a ponta acaba DENTRO das almofadas
	var n1 := 12
	for k in n1:
		var az := TAU * (float(k) + r.randf_range(-0.22, 0.22)) / float(n1)
		if _no_sector_do_palacio(az, 0.42):
			az += 0.42 if az > 0.0 else -0.42
		var alc := r.randf_range(0.50, 0.68)
		var y0 := r.randf_range(0.50, 0.56)
		var y1 := _cimo_copa(alc) - r.randf_range(0.065, 0.095)
		var fi := r.randf() * TAU
		var pts: Array = []
		for i in 10:
			var t := float(i) / 9.0
			var rho := 0.10 + (alc - 0.10) * pow(t, 0.9)
			var y := y0 + (y1 - y0) * (1.0 - pow(1.0 - t, 2.2)) + 0.012 * sin(t * TAU + fi) * t
			var a := az + 0.16 * sin(t * 2.6 + fi) * t
			pts.append([_pol(rho, a, y), 0.050 * pow(1.0 - t, 1.2) + 0.008])
		m.tubo(pts, 8, casca, ponta, true)
		for fq in 3:
			var p0: Vector3 = pts[3 + fq * 2][0]
			var lado := 1.0 if (fq + k) % 2 == 0 else -1.0
			var a2 := az + lado * r.randf_range(0.20, 0.42)
			var rho2 := alc * r.randf_range(0.72, 1.08)
			var p2 := _pol(rho2, a2, _cimo_copa(rho2) - r.randf_range(0.05, 0.08))
			var grosso := 0.026 - 0.005 * float(fq)
			m.tubo([[p0, grosso], [p0.lerp(p2, 0.5) + Vector3(0, 0.022, 0), grosso * 0.62], [p2, 0.006]], 5, casca, ponta, true)
	# ---- os ramos altos: sobem em leque para o miolo da cúpula
	var n2 := 8
	for k in n2:
		var az := TAU * (float(k) + 0.5 + r.randf_range(-0.22, 0.22)) / float(n2)
		if _no_sector_do_palacio(az, 0.36):
			az += 0.36 if az > 0.0 else -0.36
		var alc := r.randf_range(0.18, 0.42)
		var y1 := _cimo_copa(alc) - r.randf_range(0.05, 0.08)
		var fi := r.randf() * TAU
		var pts: Array = []
		for i in 8:
			var t := float(i) / 7.0
			var rho := 0.06 + (alc - 0.06) * t
			var y := 0.57 + (y1 - 0.57) * (1.0 - pow(1.0 - t, 1.5))
			pts.append([_pol(rho, az + 0.10 * sin(t * 3.0 + fi), y), 0.042 * pow(1.0 - t, 1.0) + 0.007])
		m.tubo(pts, 7, casca, ponta, true)
	m.tubo([[Vector3(0.02, 0.58, 0.03), 0.05], [Vector3(-0.02, 0.76, 0.02), 0.03], [Vector3(0.01, 0.93, 0.0), 0.008]], 7, casca, ponta, true)
	# ---- a LENTE: a massa da copa (cúpula por cima, forro por baixo). Sem ela a copa são pires
	# soltos com céu por entre eles; com ela é um corpo, e as almofadas são o relevo desse corpo.
	_lente(f)
	# ---- as almofadas da copa: anéis [distância ao eixo, quantas, raio, subdivisão, 0 cúpula / 1 forro]
	var aneis: Array = [[0.0, 1, 0.150, 2, 0], [0.17, 6, 0.140, 2, 0], [0.32, 9, 0.132, 2, 0], [0.45, 12, 0.122, 2, 0],
		[0.56, 15, 0.110, 2, 0], [0.655, 18, 0.098, 2, 0], [0.735, 20, 0.082, 1, 0],
		[0.40, 8, 0.100, 1, 1], [0.57, 12, 0.090, 1, 1], [0.70, 16, 0.072, 1, 1],
		[0.775, 26, 0.052, 1, 2]]      # 2 = os tufos caídos da orla (a orla não é uma linha)
	var centro_vol := Vector3(0.0, 0.60, 0.0)
	for anel: Array in aneis:
		var rho0: float = anel[0]
		var quantas: int = anel[1]
		var rp0: float = anel[2]
		var sub: int = anel[3]
		var forro: bool = int(anel[4]) == 1
		var rot := r.randf() * TAU
		for k in quantas:
			var az := rot + TAU * (float(k) + r.randf_range(-0.28, 0.28)) / float(quantas)
			var rho := (rho0 + r.randf_range(-0.03, 0.03)) * (1.0 + 0.05 * sin(az * 2.0 + 1.0)) * _baia(az)
			if rho0 == 0.0:
				rho = 0.0
			var rp := rp0 * r.randf_range(0.86, 1.14) * lerpf(_baia(az), 1.0, 0.5)
			var ry := rp * r.randf_range(0.56, 0.70)
			var tinta := Paleta.ANCESTRAL_FOLHA.lerp(Paleta.ANCESTRAL_FOLHA_LUZ, r.randf_range(0.0, 0.55))
			var y := _cimo_copa(rho) - ry * 0.62 + r.randf_range(-0.012, 0.012)
			if forro:
				# o forro: a camada de baixo, escura — dá espessura à copa e esconde as pontas dos ramos
				if _no_sector_do_palacio(az, 0.60):
					continue
				y = _cimo_copa(rho) - 0.118 + r.randf_range(-0.012, 0.012)
				ry *= 0.7
				tinta = tinta.lerp(Paleta.ANCESTRAL_FOLHA_FUNDA, 0.5)
			elif int(anel[4]) == 2:
				y = _cimo_copa(rho) - r.randf_range(0.060, 0.100)
				ry *= r.randf_range(0.9, 1.5)
				tinta = tinta.lerp(Paleta.ANCESTRAL_FOLHA_FUNDA, 0.25)
			f.bolha(_pol(rho, az, y), Vector3(rp, ry, rp), sub, tinta, r.randf_range(0.0, 90.0), centro_vol, 0.0, 0.0, 0.42, 0.34)


## A BAÍA DO PALÁCIO: a norte, a copa recolhe-se (até 58 % do raio) para a frente do palácio se
## ver por baixo da orla — na referência «norte» o palácio vê-se inteiro, com a copa por trás.
static func _baia(az: float) -> float:
	return 1.0 - 0.42 * (1.0 - smoothstep(0.26, 0.60, absf(angle_difference(az, 0.0))))


## A lente da copa: de baixo (eixo → orla, o forro) para cima (orla → eixo, a cúpula), com a
## baía do palácio. Normais lisas, somadas das faces.
static func _lente(f: Lote) -> void:
	var lados := 36
	var perfil: Array = []        # [fracção do raio da copa, quanto abaixo do cimo, é cúpula?]
	for i in 7:
		perfil.append([0.94 * float(i) / 6.0, 0.112, false])
	perfil.append([0.975, 0.088, false])
	for i in 9:
		perfil.append([0.94 * float(8 - i) / 8.0, 0.058, true])
	var base := f.v.size()
	var niveis := perfil.size()
	for i in niveis:
		var cima: bool = perfil[i][2]
		var tinta := Paleta.ANCESTRAL_FOLHA.lerp(Paleta.ANCESTRAL_FOLHA_FUNDA, 0.35 if cima else 0.75)
		for k in lados:
			var az := TAU * float(k) / float(lados)
			var rho := float(perfil[i][0]) * RAIO_COPA * _baia(az)
			f.v.append(_pol(rho, az, _cimo_copa(rho) - float(perfil[i][1])))
			f.n.append(Vector3.ZERO)
			f.c.append(Color(tinta.r, tinta.g, tinta.b, 0.80 if cima else 0.50))
			f.uv.append(Vector2.ZERO)
	var de := f.idx.size()
	for i in niveis - 1:
		for k in lados:
			var a0 := base + i * lados + k
			var a1 := base + i * lados + (k + 1) % lados
			for tri: Array in [[a0, a0 + lados, a1], [a1, a0 + lados, a1 + lados]]:
				var nf := (f.v[int(tri[1])] - f.v[int(tri[0])]).cross(f.v[int(tri[2])] - f.v[int(tri[0])])
				if nf.length_squared() < 1e-14:
					continue
				for o: int in tri:
					f.n[o] += nf
					f.idx.append(o)
	# O sentido confere-se pelo cimo: no Godot a frente é horária, por isso a normal geométrica
	# (anti-horária) da cúpula tem de olhar para BAIXO; se olhar para cima, viram-se os triângulos.
	var geom_para_cima := f.n[base + (niveis - 3) * lados].y > 0.0
	if geom_para_cima:
		for k in range(de, f.idx.size(), 3):
			var troca := f.idx[k + 1]
			f.idx[k + 1] = f.idx[k + 2]
			f.idx[k + 2] = troca
	for i in range(base, f.v.size()):
		var nv := f.n[i]
		if nv.length_squared() < 1e-20:
			nv = Vector3.UP
		f.n[i] = nv.normalized() * (1.0 if geom_para_cima else -1.0)


## Um andar de pagode: parede de madeira com a faixa das janelas ACESA entre colunas escuras,
## lintel e telhado de 4 águas. Devolve a altura onde assenta o andar seguinte.
static func _andar(obra: Lote, lume: Lote, base: Vector3, mx: float, mz: float, alt: float, tx: float, tz: float,
		alt_telhado: float, rot: float = 0.0, colunas: int = 4) -> float:
	var b := Basis(Vector3.UP, rot)
	var ouro := Paleta.ANCESTRAL_OURO
	var madeira := Paleta.ANCESTRAL_MADEIRA
	var escuro := madeira.darkened(0.42)
	obra.caixa(base + Vector3(0, alt * 0.5, 0), Vector3(mx, alt * 0.5, mz), b, madeira.darkened(0.12))
	lume.caixa(base + Vector3(0, alt * 0.56, 0), Vector3(mx * 1.012, alt * 0.30, mz * 1.012), b, ouro)
	for i in colunas:
		var x := lerpf(-mx, mx, float(i) / float(colunas - 1))
		for sz: float in [-1.0, 1.0]:
			obra.caixa(base + b * Vector3(x, alt * 0.5, sz * mz * 1.03), Vector3(mx * 0.045, alt * 0.5, mz * 0.06), b, escuro)
	obra.caixa(base + Vector3(0, alt * 0.96, 0), Vector3(mx * 1.05, alt * 0.07, mz * 1.07), b, madeira)
	Formas.telhado(obra, base + Vector3(0, alt, 0), tx, tz, alt_telhado, Paleta.ANCESTRAL_TELHA, -rot)
	return base.y + alt + alt_telhado * 0.55


static func _palacio(obra: Lote, lume: Lote) -> void:
	var p := PALACIO
	var madeira := Paleta.ANCESTRAL_MADEIRA
	var escuro := madeira.darkened(0.45)
	var ouro := Paleta.ANCESTRAL_OURO
	var oval := Vector2(1.0, 0.80)
	# a plataforma (forro escuro por baixo, soalho por cima) e a balaustrada de ouro
	obra.torno(p, [[0.0, -0.022], [0.120, -0.022], [0.160, -0.004], [0.166, 0.0]], 18, escuro, madeira.darkened(0.2), false, 0.0, oval)
	obra.torno(p, [[0.166, 0.0], [0.168, 0.008], [0.160, 0.009], [0.0, 0.010]], 18, madeira, madeira.lightened(0.10), false, 0.0, oval)
	lume.torno(p + Vector3(0, 0.008, 0), [[0.164, 0.0], [0.164, 0.010]], 18, ouro.darkened(0.2), ouro, false, 0.0, oval)
	# as mãos-francesas: da orla da plataforma ao tronco, por baixo
	var y_pe := 0.505
	for i in 16:
		var ang := TAU * (float(i) + 0.5) / 16.0
		var q := p + Vector3(cos(ang) * 0.148 * oval.x, -0.016, sin(ang) * 0.148 * oval.y)
		var d := Vector2(q.x, q.z)
		if d.length() < _raio_tronco(y_pe):
			continue
		d = d.normalized() * _raio_tronco(y_pe) * 0.96
		obra.tubo([[Vector3(d.x, y_pe, d.y), 0.0085], [q, 0.0060]], 4, escuro, escuro, false)
	var y := p.y + 0.010
	# os três andares, de telhados altos
	y = _andar(obra, lume, Vector3(p.x, y, p.z), 0.105, 0.058, 0.046, 0.152, 0.100, 0.052, 0.0, 6)
	y = _andar(obra, lume, Vector3(p.x, y, p.z), 0.068, 0.040, 0.034, 0.104, 0.070, 0.044, 0.0, 5)
	y = _andar(obra, lume, Vector3(p.x, y, p.z), 0.040, 0.026, 0.030, 0.066, 0.048, 0.046, 0.0, 4)
	lume.torno(Vector3(p.x, y + 0.018, p.z), [[0.006, 0.0], [0.010, 0.006], [0.004, 0.013], [0.006, 0.019], [0.0, 0.034]], 6, ouro, ouro.lightened(0.2))
	# a porta grande, acesa, virada a norte
	lume.caixa(Vector3(p.x, p.y + 0.010 + 0.021, p.z - 0.0595), Vector3(0.022, 0.021, 0.002), Basis.IDENTITY, Color("#ffe9a8"))
	# as duas alas baixas
	for sx: float in [-1.0, 1.0]:
		_andar(obra, lume, Vector3(p.x + sx * 0.128, p.y + 0.010, p.z + 0.012), 0.026, 0.026, 0.026, 0.044, 0.044, 0.030, 0.0, 3)


## Um pagode pequeno numa plataforma redonda. `pes` = [[de, até], ...]: as estacas ou
## mãos-francesas, da orla da plataforma ao apoio.
static func _pagode(obra: Lote, lume: Lote, c: Vector3, s: float, az: float, andares: int, pes: Array) -> void:
	var madeira := Paleta.ANCESTRAL_MADEIRA
	var escuro := madeira.darkened(0.45)
	var ouro := Paleta.ANCESTRAL_OURO
	obra.torno(c, [[0.0, -0.10 * s], [0.78 * s, -0.10 * s], [1.0 * s, 0.0]], 10, escuro, madeira.darkened(0.25))
	obra.torno(c, [[1.0 * s, 0.0], [1.0 * s, 0.07 * s], [0.0, 0.075 * s]], 10, madeira, madeira.lightened(0.12))
	lume.torno(c + Vector3(0, 0.07 * s, 0), [[0.97 * s, 0.0], [0.97 * s, 0.09 * s]], 10, ouro.darkened(0.30), ouro.darkened(0.10))
	for pe: Array in pes:
		obra.tubo([[pe[1], 0.050 * s], [pe[0], 0.036 * s]], 4, escuro, escuro, false)
	var y := _andar(obra, lume, c + Vector3(0, 0.075 * s, 0), 0.50 * s, 0.50 * s, 0.42 * s, 0.92 * s, 0.92 * s, 0.50 * s, -az, 3)
	if andares >= 2:
		y = _andar(obra, lume, Vector3(c.x, y, c.z), 0.30 * s, 0.30 * s, 0.26 * s, 0.58 * s, 0.58 * s, 0.42 * s, -az, 2)
	lume.torno(Vector3(c.x, y + 0.12 * s, c.z), [[0.05 * s, 0.0], [0.0, 0.30 * s]], 5, ouro, ouro)


## As mãos-francesas de um pagode encostado ao tronco: da orla de fora da plataforma ao tronco.
static func _pes_tronco(c: Vector3, s: float) -> Array:
	var pes: Array = []
	var y_pe := c.y - 1.5 * s
	for i in 6:
		var ang := TAU * float(i) / 6.0
		var q := c + Vector3(cos(ang) * 0.82 * s, -0.08 * s, sin(ang) * 0.82 * s)
		var d := Vector2(q.x, q.z)
		if d.length() < _raio_tronco(c.y) + 0.15 * s:
			continue      # este canto já está dentro do tronco
		d = d.normalized() * _raio_tronco(y_pe) * 0.96
		pes.append([q, Vector3(d.x, y_pe, d.y)])
	return pes


## As estacas de um pagode pousado numa raiz (ou no chão): descem da plataforma até ao apoio.
static func _pes_estacas(c: Vector3, s: float, apoios: Array) -> Array:
	var pes: Array = []
	for i in 6:
		var ang := TAU * float(i) / 6.0
		var q := c + Vector3(cos(ang) * 0.80 * s, -0.08 * s, sin(ang) * 0.80 * s)
		var pe := Vector3(lerpf(q.x, c.x, 0.35), 0.0, lerpf(q.z, c.z, 0.35))
		pe.y = minf(_apoio(pe.x, pe.z, apoios, 0.0), q.y) - 0.006
		pes.append([q, pe])
	return pes


## A altura do apoio debaixo de (x, z): o cimo da raiz que lá passa, ou o chão.
static func _apoio(x: float, z: float, apoios: Array, folga: float) -> float:
	var melhor := _chao(x, z)
	for a: Array in apoios:
		var p: Vector3 = a[0]
		var raio: float = a[1]
		var dx := p.x - x
		var dz := p.z - z
		var lim := raio + folga
		if dx * dx + dz * dz < lim * lim:
			melhor = maxf(melhor, p.y + raio * 0.7)
	return melhor


static func _ha_vizinho(postos: Array, c: Vector3, s: float) -> bool:
	for o: Array in postos:
		if (o[0] as Vector3).distance_to(c) < (float(o[1]) + s) * 1.05:
			return true
	return false


## Devolve Vector2i(quantos pagodes, quantos ficaram com alguma estaca sem apoio = no ar).
static func _pagodes(obra: Lote, lume: Lote, r: RandomNumberGenerator, apoios: Array) -> Vector2i:
	var postos: Array = []      # [centro, raio]
	var no_ar := 0
	# ---- a face NORTE: posições lidas da referência
	for g: Array in PAGODES_NORTE:
		var wx := -float(g[0])      # ecrã → mundo: a esquerda do ecrã é leste
		var y: float = g[1]
		var s: float = g[2]
		var rt := _raio_tronco(y)
		if absf(wx) < rt * 0.92:
			# encostado ao tronco, em mãos-francesas
			var rho := rt + s * 0.55
			var az := asin(clampf(wx / rho, -1.0, 1.0))
			var c := _pol(rho, az, y)
			_pagode(obra, lume, c, s, az, int(g[3]), _pes_tronco(c, s))
			postos.append([c, s])
			continue
		# sobre uma raiz: a amostra de raiz da metade norte que passa por baixo deste ponto do ecrã
		var melhor := -1
		var nota := INF
		for i in apoios.size():
			var p: Vector3 = apoios[i][0]
			if p.z > 0.02:
				continue
			var topo := p.y + float(apoios[i][1]) * 0.7
			var estaca := y - topo
			var n := absf(p.x - wx) * 3.0 + absf(estaca - 0.030) + (0.5 if estaca < 0.008 else 0.0)
			if n < nota and not _ha_vizinho(postos, Vector3(p.x, maxf(y, topo + 0.012), p.z), s):
				nota = n
				melhor = i
		if melhor < 0:
			continue
		var pa: Vector3 = apoios[melhor][0]
		var topo_a := pa.y + float(apoios[melhor][1]) * 0.7
		var ca := Vector3(lerpf(wx, pa.x, 0.7), clampf(y, topo_a + 0.012, topo_a + 0.060), pa.z)
		_pagode(obra, lume, ca, s, atan2(ca.x, -ca.z), int(g[3]), _pes_estacas(ca, s, apoios))
		postos.append([ca, s])
	# ---- as outras faces (leste, sul, oeste): a mesma densidade
	# encostados ao tronco
	for k in 9:
		var az := deg_to_rad(78.0 + 204.0 * (float(k) + r.randf_range(0.2, 0.8)) / 9.0)
		var y := 0.33 + 0.21 * fposmod(float(k) * 0.618034 + 0.2, 1.0)
		var s := r.randf_range(0.040, 0.060)
		var c := _pol(_raio_tronco(y) + s * 0.55, az, y)
		if _ha_vizinho(postos, c, s):
			continue
		_pagode(obra, lume, c, s, az, 2 if s > 0.047 else 1, _pes_tronco(c, s))
		postos.append([c, s])
	# sobre as raízes
	var feitos := 0
	var tent := 0
	while feitos < 13 and tent < 500:
		tent += 1
		var a: Array = apoios[r.randi_range(0, apoios.size() - 1)]
		var p: Vector3 = a[0]
		var rho := Vector2(p.x, p.z).length()
		if p.z < 0.04 or rho < 0.25 or rho > 0.62:
			continue
		var s := r.randf_range(0.036, 0.056)
		var topo := p.y + float(a[1]) * 0.7
		var c := Vector3(p.x, topo + r.randf_range(0.022, 0.050), p.z)
		if _ha_vizinho(postos, c, s):
			continue
		_pagode(obra, lume, c, s, atan2(c.x, -c.z), 2 if s > 0.046 else 1, _pes_estacas(c, s, apoios))
		postos.append([c, s])
		feitos += 1
	# a face sul tem a sua casa grande debaixo da forquilha (as costas do palácio, na referência «sul»)
	var cs := _pol(_raio_tronco(0.555) + 0.080 * 0.5, PI, 0.555)
	_pagode(obra, lume, cs, 0.080, PI, 2, _pes_tronco(cs, 0.080))
	postos.append([cs, 0.080])
	# ---- a prova de que nada flutua: cada pagode tem o tronco ou um apoio a menos de 0,1 H por baixo
	for o: Array in postos:
		var c: Vector3 = o[0]
		var s: float = o[1]
		var no_tronco := Vector2(c.x, c.z).length() < _raio_tronco(c.y) + s
		if not no_tronco and c.y - _apoio(c.x, c.z, apoios, s * 0.6) > 0.10:
			no_ar += 1
	return Vector2i(postos.size(), no_ar)


## O sol que chega a cada vértice: a copa faz sombra ao tronco e às raízes do lado de lá do sol.
static func _cozer_sol(l: Lote) -> void:
	var sol := Paleta.dir_luz()
	var s2 := Vector2(sol.x, sol.z)
	for i in l.v.size():
		var p := l.v[i] / ALTURA
		var id := int(l.uv[i].x + 0.5)
		var cor := l.c[i]
		if id == 1:
			# folha: fica a oclusão da própria almofada; as almofadas de baixo levam a sombra das de cima
			var tapada := smoothstep(0.0, 0.10, _cimo_copa(Vector2(p.x, p.z).length()) - p.y - 0.07)
			cor.a = clampf(cor.a * lerpf(1.0, 0.55, tapada), 0.0, 1.0)
		elif id == 3:
			cor.a = 1.0
		else:
			var sombra := 0.0
			if p.y < 0.70:
				var q := Vector2(p.x, p.z) + s2 * ((0.70 - p.y) / sol.y)
				sombra = 1.0 - smoothstep(0.80, 1.10, q.length() / RAIO_COPA)
			# debaixo da cúpula, junto à forquilha, a luz é coada mesmo do lado do sol
			var forquilha := smoothstep(0.46, 0.60, p.y) * (1.0 - smoothstep(0.0, 0.45, Vector2(p.x, p.z).length()))
			cor.a = lerpf(1.0, 0.42, maxf(sombra, forquilha * 0.8))
		l.c[i] = cor


## A sombra que a árvore deita no outeiro (0–1) em (x, z) × ALTURA: a oclusão junto ao tronco e
## o lóbulo da copa para o lado de lá do sol. É o CONTACTO da árvore com o chão.
static func _sombra_no_chao(x: float, z: float) -> float:
	var sol := Paleta.dir_luz()
	var s2 := Vector2(sol.x, sol.z).normalized()
	var contacto := 1.0 - smoothstep(0.18, 0.62, Vector2(x, z).length())
	var lobulo := Vector2(x, z) + s2 * 0.62
	return maxf(contacto * 0.75, (1.0 - smoothstep(0.45, 0.95, lobulo.length())) * 0.60)


## O outeiro onde a árvore assenta: o chão (o mesmo de _chao) e um MAR DE COPAS por cima — a
## floresta de onde a árvore sai, como na referência. A sombra da árvore vem pintada (o contacto).
## Tinta cozida no vértice (shaders/anel_longe.gdshader).
static func _outeiro(apoios: Array) -> Lote:
	var l := Lote.new()
	var na := 48
	var nr := 10
	for j in nr + 1:
		var t := float(j) / float(nr)
		var rho := lerpf(0.10, RAIO_OUTEIRO, t)
		for i in na:
			var ang := TAU * float(i) / float(na)
			var x := cos(ang) * rho
			var z := sin(ang) * rho
			l.v.append(Vector3(x, _chao(x, z), z) * ALTURA)
			l.n.append(Vector3.UP)
			var bossa := _rn.get_noise_2d(x * ALTURA * 2.3, z * ALTURA * 2.3)
			var cor := Paleta.ANEL_FLORESTA.lerp(Paleta.ANCESTRAL_FOLHA_FUNDA, 0.60 + 0.3 * bossa)
			cor = cor.darkened(_sombra_no_chao(x, z) * 0.55)
			var ar := lerpf(0.40, 0.62, t)
			if j == nr:
				ar = 1.0
			l.c.append(Paleta.ar(cor, ar))
			l.uv.append(Vector2.ZERO)
	for j in nr:
		for i in na:
			var a := j * na + i
			var b := j * na + (i + 1) % na
			l.idx.append_array([a, a + na, b, b, a + na, b + na])
	# ---- o mar de copas: árvores da floresta entre as raízes e à volta (não nascem dentro de uma raiz)
	var r := RandomNumberGenerator.new()
	r.seed = 912
	var copas := Lote.new()
	var sol := Paleta.dir_luz()
	var postas := 0
	var tent := 0
	while postas < 260 and tent < 800:
		tent += 1
		var rho := lerpf(0.22, 1.04, sqrt(r.randf()))
		var p := _pol(rho, r.randf() * TAU, 0.0)
		var rp := r.randf_range(0.016, 0.028)
		p.y = _chao(p.x, p.z)
		var livre := true
		for a: Array in apoios:
			var q: Vector3 = a[0]
			var raio: float = a[1]
			if q.y - raio < p.y + rp * 1.3 and Vector2(q.x - p.x, q.z - p.z).length() < raio + rp * 0.55:
				livre = false
				break
		if not livre:
			continue
		var de := copas.v.size()
		var tinta := Paleta.ANEL_FLORESTA.lerp(Paleta.ANCESTRAL_FOLHA, r.randf_range(0.15, 0.6))
		copas.bolha(p + Vector3(0, rp * 0.42, 0), Vector3(rp, rp * r.randf_range(0.62, 0.9), rp), 1, tinta,
			r.randf_range(0.0, 90.0), p - Vector3(0, rp, 0), 0.0, 0.0, 0.36, 0.5)
		# a luz cozida na tinta: cimo ao sol, barriga em sombra, a sombra da árvore e o ar
		var sombra := _sombra_no_chao(p.x, p.z)
		var ar := lerpf(0.40, 0.62, clampf((rho - 0.10) / (RAIO_OUTEIRO - 0.10), 0.0, 1.0))
		for i in range(de, copas.v.size()):
			var c := copas.c[i]
			var luz := (0.50 + 0.85 * smoothstep(-0.25, 0.85, copas.n[i].dot(sol))) * lerpf(0.55, 1.0, c.a)
			var cor := Color(c.r * luz, c.g * luz, c.b * luz * 0.96, 1.0).darkened(sombra * 0.5)
			copas.c[i] = Paleta.ar(cor, ar)
		postas += 1
	l.juntar(copas, Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * ALTURA), Vector3.ZERO))
	return l
