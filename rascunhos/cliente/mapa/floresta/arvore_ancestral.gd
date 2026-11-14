extends RefCounted
## arvore_ancestral.gd — Ordem 38 (defeito 2): a ÁRVORE ANCESTRAL, o marco do mapa.
##
## Feita à imagem das 5 referências (referencias-arvore-ancestral/): uma figueira colossal de
## copa em guarda-chuva, tronco de feixe com raízes-contraforte que se espraiam como um polvo, o
## PALÁCIO de três telhados pousado na forquilha e duas dúzias de pagodes em plataformas à volta
## do tronco e sobre as raízes.
##
## ORIENTAÇÃO (palavra do Mestre: NORTE = frente do palácio): o modelo tem a frente do palácio
## virada a NORTE (−Z do mundo). A árvore está a norte da arena, por isso da arena vê-se a face
## SUL (a da referência «sul»); as outras faces provam-se com a câmara à volta dela
## (ferramentas/provar_ancestral.gd).
##
## PROPORÇÕES medidas na referência norte (H = altura total, do pé das raízes ao cimo da copa):
##   copa ......... raio 0,78 H; cimo a 1,00 H; orla entre 0,63 e 0,75 H; almofadas chatas
##   tronco ....... raio 0,17 H a meia altura; forquilha a 0,56 H
##   raízes ....... 14 contrafortes, nascem a 0,30–0,47 H e chegam a 0,66–0,86 H do eixo
##   palácio ...... plataforma a 0,615 H (raio 0,165 H), 0,15 H para norte do eixo; cimo a 0,85 H
##   pagodes ...... 23 na face norte (posições lidas da referência) + 20 nas outras faces
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

## Os pagodes da face NORTE, lidos da referência: [x (para leste), altura, raio da plataforma, andares].
const PAGODES_NORTE: Array = [
	[-0.247, 0.500, 0.062, 2], [0.236, 0.546, 0.052, 2], [0.110, 0.540, 0.050, 1], [0.011, 0.454, 0.058, 2],
	[-0.144, 0.454, 0.046, 1], [0.218, 0.460, 0.040, 1], [0.207, 0.385, 0.060, 2], [0.300, 0.408, 0.036, 2],
	[-0.224, 0.380, 0.050, 1], [-0.320, 0.385, 0.036, 2], [-0.380, 0.356, 0.044, 2], [-0.130, 0.310, 0.050, 2],
	[0.098, 0.293, 0.052, 2], [0.374, 0.287, 0.056, 2], [-0.448, 0.300, 0.034, 1], [-0.500, 0.264, 0.040, 1],
	[-0.350, 0.247, 0.050, 2], [-0.040, 0.218, 0.056, 2], [-0.253, 0.276, 0.036, 1], [0.150, 0.207, 0.034, 1],
	[0.287, 0.207, 0.040, 1], [0.500, 0.236, 0.036, 1], [0.340, 0.345, 0.034, 1]]


## Ponto a `rho` do eixo, no azimute `az` (0 = norte, positivo para leste), à altura `y`.
static func _pol(rho: float, az: float, y: float) -> Vector3:
	return Vector3(rho * sin(az), y, -rho * cos(az))


## Raio da envolvente tronco + raízes à altura y (tudo × ALTURA).
static func _env(y: float) -> float:
	return 0.235 + pow(maxf(0.45 - y, 0.0), 1.6) * 1.9


## Cimo da copa (a cúpula do guarda-chuva) à distância rho do eixo.
static func _cimo_copa(rho: float) -> float:
	return 0.985 - 0.36 * pow(clampf(rho / RAIO_COPA, 0.0, 1.2), 2.4)


## Devolve {"malha": ArrayMesh (em metros, pé na origem), "tri": int, "outeiro": ArrayMesh, "outeiro_tri": int}.
static func construir() -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = 3807
	var madeira := Lote.new()
	var folha := Lote.new()
	var obra := Lote.new()
	var lume := Lote.new()
	_tronco(madeira)
	_raizes(madeira, r)
	_copa(madeira, folha, r)
	_palacio(obra, lume)
	_pagodes(obra, lume, r)
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
	var monte := _outeiro()
	return {"malha": tudo.fechar(), "tri": tudo.triangulos(), "partes": partes,
		"outeiro": monte.fechar(), "outeiro_tri": monte.triangulos()}


static func _tronco(m: Lote) -> void:
	var funda := Paleta.ANCESTRAL_CASCA_FUNDA
	var casca := Paleta.ANCESTRAL_CASCA.lerp(funda, 0.25)
	var perfil: Array = [[0.240, -0.04], [0.218, 0.08], [0.192, 0.22], [0.170, 0.38], [0.162, 0.48],
		[0.174, 0.555], [0.150, 0.60], [0.0, 0.62]]
	m.torno(Vector3.ZERO, perfil, 22, funda, casca)


static func _raizes(m: Lote, r: RandomNumberGenerator) -> void:
	var casca := Paleta.ANCESTRAL_CASCA
	var funda := Paleta.ANCESTRAL_CASCA.lerp(Paleta.ANCESTRAL_CASCA_FUNDA, 0.5)
	for k in N_RAIZES:
		var az0 := TAU * (float(k) + r.randf_range(-0.28, 0.28)) / float(N_RAIZES)
		var alcance := r.randf_range(0.66, 0.86)
		var nasce := r.randf_range(0.30, 0.47)
		var onda := r.randf_range(1.2, 2.2)
		var fi := r.randf() * TAU
		var grosso := r.randf_range(0.052, 0.064)
		var pts: Array = []
		for i in 14:
			var s := float(i) / 13.0
			var rho := lerpf(0.158, alcance, pow(s, 1.9))
			var y := nasce * pow(1.0 - s, 2.2) - 0.016 * s
			var az := az0 + 0.24 * sin(s * PI * onda + fi) * s
			var raio := grosso * pow(1.0 - s, 0.8) + 0.007
			pts.append([_pol(rho, az, y + raio * 0.35), raio])
		m.tubo(pts, 9, funda, casca, true)
		# a raiz bifurca a meio caminho
		if r.randf() < 0.7:
			var s0 := r.randf_range(0.36, 0.5)
			var lado := -1.0 if r.randf() < 0.5 else 1.0
			var az1 := az0 + 0.24 * sin(s0 * PI * onda + fi) * s0
			var pts2: Array = []
			for i in 9:
				var t := float(i) / 8.0
				var s := lerpf(s0, 1.0, t)
				var rho := lerpf(0.158, alcance * r.randf_range(0.80, 0.98), pow(s, 1.9))
				var y := nasce * pow(1.0 - s, 2.2) - 0.016 * s
				var az := az1 + lado * (0.07 + 0.30 * t) * pow(t, 0.8) + 0.05 * sin(t * 5.0 + fi)
				var raio := grosso * 0.62 * pow(1.0 - s, 0.8) + 0.005
				pts2.append([_pol(rho, az, y + raio * 0.35), raio])
			m.tubo(pts2, 7, funda, casca, true)


static func _copa(m: Lote, f: Lote, r: RandomNumberGenerator) -> void:
	var casca := Paleta.ANCESTRAL_CASCA.lerp(Paleta.ANCESTRAL_CASCA_FUNDA, 0.40)
	# ---- os ramos-mestres baixos: saem da forquilha quase deitados e levam a orla da copa
	var n1 := 10
	for k in n1:
		var az := TAU * (float(k) + r.randf_range(-0.25, 0.25)) / float(n1)
		var alc := r.randf_range(0.54, 0.70)
		var y0 := r.randf_range(0.50, 0.56)
		var y1 := r.randf_range(0.62, 0.69)
		var fi := r.randf() * TAU
		var pts: Array = []
		for i in 9:
			var t := float(i) / 8.0
			var rho := 0.09 + (alc - 0.09) * pow(t, 0.85)
			var y := y0 + (y1 - y0) * pow(t, 1.4) + 0.012 * sin(t * TAU + fi)
			var a := az + 0.13 * sin(t * 2.6 + fi) * t
			pts.append([_pol(rho, a, y), 0.050 * pow(1.0 - t, 1.1) + 0.009])
		m.tubo(pts, 8, casca, casca, true)
		for fq in 2:
			var p0: Vector3 = pts[4 + fq * 2][0]
			var a2 := az + (float(fq) * 2.0 - 1.0) * r.randf_range(0.18, 0.34)
			var p2 := _pol(alc * r.randf_range(0.80, 1.0), a2, y1 + r.randf_range(0.03, 0.08))
			m.tubo([[p0, 0.022], [p0.lerp(p2, 0.5) + Vector3(0, 0.012, 0), 0.014], [p2, 0.006]], 5, casca, casca, true)
	# ---- os ramos altos: sobem em leque para o miolo da cúpula
	var n2 := 7
	for k in n2:
		var az := TAU * (float(k) + 0.5 + r.randf_range(-0.25, 0.25)) / float(n2)
		var alc := r.randf_range(0.22, 0.44)
		var y1 := r.randf_range(0.78, 0.90)
		var fi := r.randf() * TAU
		var pts: Array = []
		for i in 8:
			var t := float(i) / 7.0
			var rho := 0.06 + (alc - 0.06) * t
			var y := 0.57 + (y1 - 0.57) * pow(t, 0.8)
			pts.append([_pol(rho, az + 0.10 * sin(t * 3.0 + fi), y), 0.042 * pow(1.0 - t, 1.0) + 0.007])
		m.tubo(pts, 7, casca, casca, true)
	m.tubo([[Vector3(0.02, 0.58, 0.03), 0.05], [Vector3(-0.02, 0.76, 0.0), 0.03], [Vector3(0.01, 0.92, -0.01), 0.008]], 7, casca, casca, true)
	# ---- as almofadas da copa: anéis [distância ao eixo, quantas, raio, altura fixa ou −1 = cúpula]
	var aneis: Array = [[0.0, 1, 0.150, -1.0], [0.20, 6, 0.140, -1.0], [0.38, 10, 0.135, -1.0], [0.54, 13, 0.125, -1.0],
		[0.675, 17, 0.112, -1.0], [0.45, 8, 0.100, 0.745], [0.73, 11, 0.082, 0.672]]
	var centro_vol := Vector3(0.0, 0.60, 0.0)
	for anel in aneis:
		var rho0: float = anel[0]
		var quantas: int = anel[1]
		var rp0: float = anel[2]
		var y_fixo: float = anel[3]
		var rot := r.randf() * TAU
		for k in quantas:
			var az := rot + TAU * (float(k) + r.randf_range(-0.28, 0.28)) / float(quantas)
			var rho := (rho0 + r.randf_range(-0.03, 0.03)) * (1.0 + 0.05 * sin(az * 2.0 + 1.0))
			if rho0 == 0.0:
				rho = 0.0
			var rp := rp0 * r.randf_range(0.88, 1.12)
			var ry := rp * r.randf_range(0.38, 0.46)
			var y := (_cimo_copa(rho) - ry * 0.55) if y_fixo < 0.0 else (y_fixo + r.randf_range(-0.018, 0.018))
			var tinta := Paleta.ANCESTRAL_FOLHA.lerp(Paleta.ANCESTRAL_FOLHA_LUZ, r.randf_range(0.0, 0.55))
			if y_fixo > 0.0:
				tinta = tinta.lerp(Paleta.ANCESTRAL_FOLHA_FUNDA, 0.35)
			f.bolha(_pol(rho, az, y), Vector3(rp, ry, rp), 2, tinta, r.randf_range(0.0, 90.0), centro_vol, 0.0, 0.0, 0.40, 0.30)


## Um andar de pagode: paredes acesas entre colunas escuras, lintel e telhado de 4 águas.
## Devolve a altura onde assenta o andar seguinte.
static func _andar(obra: Lote, lume: Lote, base: Vector3, mx: float, mz: float, alt: float, tx: float, tz: float,
		alt_telhado: float, rot: float = 0.0, colunas: int = 4) -> float:
	var b := Basis(Vector3.UP, rot)
	var ouro := Paleta.ANCESTRAL_OURO
	var escuro := Paleta.ANCESTRAL_MADEIRA.darkened(0.42)
	lume.caixa(base + Vector3(0, alt * 0.5, 0), Vector3(mx, alt * 0.5, mz), b, ouro)
	for i in colunas:
		var x := lerpf(-mx, mx, float(i) / float(colunas - 1))
		for sz: float in [-1.0, 1.0]:
			obra.caixa(base + b * Vector3(x, alt * 0.5, sz * mz * 1.03), Vector3(mx * 0.045, alt * 0.5, mz * 0.06), b, escuro)
	obra.caixa(base + Vector3(0, alt * 0.96, 0), Vector3(mx * 1.05, alt * 0.07, mz * 1.07), b, Paleta.ANCESTRAL_MADEIRA)
	Formas.telhado(obra, base + Vector3(0, alt, 0), tx, tz, alt_telhado, Paleta.ANCESTRAL_TELHA, -rot)
	return base.y + alt + alt_telhado * 0.55


static func _palacio(obra: Lote, lume: Lote) -> void:
	var p := PALACIO
	var madeira := Paleta.ANCESTRAL_MADEIRA
	var escuro := madeira.darkened(0.45)
	var ouro := Paleta.ANCESTRAL_OURO
	var oval := Vector2(1.0, 0.80)
	# as escoras que descem até à forquilha, a plataforma e a balaustrada de ouro
	obra.torno(p, [[0.06, -0.115], [0.10, -0.045], [0.150, -0.008], [0.165, 0.0]], 12, escuro, madeira, false, 0.0, oval)
	obra.torno(p, [[0.165, 0.0], [0.168, 0.012], [0.160, 0.013], [0.0, 0.014]], 16, madeira, madeira.lightened(0.10), false, 0.0, oval)
	lume.torno(p + Vector3(0, 0.012, 0), [[0.163, 0.0], [0.163, 0.011]], 16, ouro.darkened(0.15), ouro, false, 0.0, oval)
	var y := p.y + 0.014
	# os três andares
	y = _andar(obra, lume, Vector3(p.x, y, p.z), 0.105, 0.058, 0.046, 0.150, 0.098, 0.040, 0.0, 6)
	y = _andar(obra, lume, Vector3(p.x, y, p.z), 0.066, 0.040, 0.034, 0.100, 0.068, 0.034, 0.0, 5)
	y = _andar(obra, lume, Vector3(p.x, y, p.z), 0.040, 0.026, 0.030, 0.064, 0.046, 0.036, 0.0, 4)
	lume.torno(Vector3(p.x, y + 0.012, p.z), [[0.006, 0.0], [0.010, 0.008], [0.004, 0.018], [0.006, 0.026], [0.0, 0.050]], 6, ouro, ouro.lightened(0.2))
	# a porta grande, acesa, virada a norte
	lume.caixa(Vector3(p.x, p.y + 0.014 + 0.021, p.z - 0.059), Vector3(0.022, 0.021, 0.002), Basis.IDENTITY, Color("#ffe9a8"))
	# as duas alas baixas
	for sx: float in [-1.0, 1.0]:
		_andar(obra, lume, Vector3(p.x + sx * 0.128, p.y + 0.014, p.z + 0.012), 0.026, 0.026, 0.026, 0.044, 0.044, 0.026, 0.0, 3)


## Um pagode pequeno numa plataforma redonda sobre escoras.
static func _pagode(obra: Lote, lume: Lote, c: Vector3, s: float, az: float, andares: int) -> void:
	var madeira := Paleta.ANCESTRAL_MADEIRA
	var escuro := madeira.darkened(0.45)
	obra.torno(c, [[0.20 * s, -1.30 * s], [0.50 * s, -0.32 * s], [0.98 * s, -0.02 * s]], 7, escuro, madeira.darkened(0.2))
	obra.torno(c, [[0.98 * s, -0.02 * s], [1.02 * s, 0.05 * s], [0.96 * s, 0.06 * s], [0.0, 0.065 * s]], 10, madeira, madeira.lightened(0.12))
	var y := _andar(obra, lume, c + Vector3(0, 0.065 * s, 0), 0.50 * s, 0.50 * s, 0.44 * s, 0.94 * s, 0.94 * s, 0.46 * s, -az, 3)
	if andares >= 2:
		y = _andar(obra, lume, Vector3(c.x, y, c.z), 0.28 * s, 0.28 * s, 0.26 * s, 0.56 * s, 0.56 * s, 0.36 * s, -az, 2)
	lume.torno(Vector3(c.x, y + 0.10 * s, c.z), [[0.05 * s, 0.0], [0.0, 0.30 * s]], 5, Paleta.ANCESTRAL_OURO, Paleta.ANCESTRAL_OURO)


static func _pagodes(obra: Lote, lume: Lote, r: RandomNumberGenerator) -> void:
	for g in PAGODES_NORTE:
		var x: float = g[0]
		var y: float = g[1]
		var s: float = g[2]
		var rho := maxf(absf(x) * 1.04, _env(y) + s * 0.5)
		var az := asin(clampf(x / rho, -1.0, 1.0))
		_pagode(obra, lume, _pol(rho, az, y), s, az, int(g[3]))
	# as outras faces (leste, sul, oeste): a mesma densidade, espalhada pela mesma envolvente
	var n := 20
	for k in n:
		var az := deg_to_rad(96.0 + 168.0 * (float(k) + r.randf_range(0.15, 0.85)) / float(n))
		var y := 0.205 + 0.34 * fposmod(float(k) * 0.618034 + 0.31, 1.0)
		var s := r.randf_range(0.036, 0.060)
		var rho := _env(y) + s * 0.5 + r.randf_range(0.0, 0.05) * (1.0 if y < 0.32 else 0.2)
		_pagode(obra, lume, _pol(rho, az, y), s, az, 2 if s > 0.045 else 1)
	# a face sul tem a sua casa grande na forquilha (as costas do palácio, na referência «sul»)
	_pagode(obra, lume, _pol(0.20, PI, 0.585), 0.085, PI, 2)


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
			var tapada := smoothstep(0.0, 0.10, _cimo_copa(Vector2(p.x, p.z).length()) - p.y - 0.09)
			cor.a = clampf(cor.a * lerpf(1.0, 0.62, tapada), 0.0, 1.0)
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


## O outeiro onde a árvore assenta: um mar de copas baixo, com a sombra da árvore pintada
## (o contacto). Tinta cozida no vértice (shaders/anel_longe.gdshader).
static func _outeiro() -> Lote:
	var l := Lote.new()
	var rn := FastNoiseLite.new()
	rn.seed = 911
	rn.frequency = 0.02
	var sol := Paleta.dir_luz()
	var s2 := Vector2(sol.x, sol.z).normalized()
	var na := 44
	var nr := 9
	for j in nr + 1:
		var t := float(j) / float(nr)
		var rho := ALTURA * lerpf(0.10, RAIO_OUTEIRO, t)
		for i in na:
			var ang := TAU * float(i) / float(na)
			var x := cos(ang) * rho
			var z := sin(ang) * rho
			var bossa := rn.get_noise_2d(x, z)
			var y := -ALTURA * (0.015 + 0.14 * pow(t, 1.7)) + bossa * ALTURA * 0.018
			l.v.append(Vector3(x, y, z))
			l.n.append(Vector3.UP)
			var cor := Paleta.ANEL_FLORESTA.lerp(Paleta.ANCESTRAL_FOLHA_FUNDA, 0.45 + 0.4 * bossa)
			cor = cor.lerp(Paleta.ANCESTRAL_FOLHA, clampf(bossa * 1.2, 0.0, 0.5))
			# a sombra: oclusão junto ao tronco e o lóbulo da copa para o lado de lá do sol
			var contacto := 1.0 - smoothstep(0.18, 0.62, rho / ALTURA)
			var lobulo := Vector2(x, z) / ALTURA + s2 * 0.62
			var sombra := maxf(contacto * 0.75, (1.0 - smoothstep(0.45, 0.95, lobulo.length())) * 0.60)
			cor = cor.darkened(sombra * 0.55)
			var ar := lerpf(0.42, 0.62, t)
			if j == nr:
				ar = 1.0
			l.c.append(Paleta.ar(cor, ar))
			l.uv.append(Vector2.ZERO)
	for j in nr:
		for i in na:
			var a := j * na + i
			var b := j * na + (i + 1) % na
			l.idx.append_array([a, a + na, b, b, a + na, b + na])
	return l
