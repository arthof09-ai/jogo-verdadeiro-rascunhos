extends RefCounted
## formas_floresta.gd — Ordem 38 (defeitos 4 e 6): as FORMAS da floresta.
##
## Acabou o carimbo único. Aqui estão as FAMÍLIAS — cada uma com silhueta, casca e verde seus:
##   árvores ... GUARDA_SOL (pinheiro-manso: tronco nu, almofadas chatas; ecoa a Árvore Ancestral)
##               REDONDA   (carvalho velho: tronco grosso, cúpula de massas redondas)
##               CONIFERA  (abeto: tronco direito, saias de cone empilhadas, verde frio e escuro)
##               JOVEM     (vidoeiro: tronco fino e claro, copa leve e alta)
##   estrato intermédio ... ARBUSTO (chamas direitas, silhueta em mão aberta — nunca um calhau),
##               SILVADO (baixo, largo, com bagas), FETO (frondes em arco), FOLHA_LARGA
##   erva ...... tufo fino, tufo largo, espiga, flor, junco
##   marcos .... menir, santuário (ecoa o palácio da Ancestral), lanterna de pedra, tronco tombado
##
## Tudo geometria (sem alfa). As peças escrevem-se em lotes (lote_malha.gd): o mapa junta-as em
## poucas malhas. Nada aqui toca na cena.

const Paleta := preload("res://mapa/floresta/paleta_floresta.gd")
const Lote := preload("res://mapa/floresta/lote_malha.gd")

enum { GUARDA_SOL, REDONDA, CONIFERA, JOVEM }
const NOMES_FAMILIA: Array[String] = ["guarda-sol", "redonda", "conifera", "jovem"]


static func _rf(r: RandomNumberGenerator, a: float, b: float) -> float:
	return r.randf_range(a, b)


## Raio do tronco ao pé (m) de uma árvore de altura h.
static func raio_tronco(familia: int, h: float) -> float:
	match familia:
		REDONDA:
			return h * 0.040
		CONIFERA:
			return h * 0.030
		JOVEM:
			return h * 0.022
	return h * 0.036


## Constrói UMA árvore: tronco e ramos em `lt`, copa em `lc`.
##   pos = pé (já no chão) · h = altura total · detalhe 2 rica / 1 média / 0 pobre (anel)
## Devolve as SOMBRAS da copa: [[centro: Vector3, raio: float], ...] (para o mapa do chão).
static func arvore(lt: Lote, lc: Lote, familia: int, pos: Vector3, h: float, detalhe: int, r: RandomNumberGenerator) -> Array:
	match familia:
		REDONDA:
			return _redonda(lt, lc, pos, h, detalhe, r)
		CONIFERA:
			return _conifera(lt, lc, pos, h, detalhe, r)
		JOVEM:
			return _jovem(lt, lc, pos, h, detalhe, r)
	return _guarda_sol(lt, lc, pos, h, detalhe, r)


## Tronco: raiz alargada que ENTRA no chão (nunca flutua), leve torção. Devolve o cimo.
static func _tronco(lt: Lote, pos: Vector3, topo: float, raio: float, afina: float, incl: Vector3,
		fase: float, casca: Color, detalhe: int, torce: float = 0.22) -> Vector3:
	var niveis := 7 if detalhe == 2 else (5 if detalhe == 1 else 3)
	var lados := 8 if detalhe == 2 else (6 if detalhe == 1 else 5)
	var pts: Array = []
	for i in niveis:
		var t := float(i) / float(niveis - 1)
		var y := -0.45 + t * (topo + 0.45)
		var ya := maxf(y, 0.0)
		var c := pos + Vector3(incl.x * ya + sin(t * 3.0 + fase * 6.0) * torce * t, y, incl.z * ya + cos(t * 2.3 + fase * 4.0) * torce * t)
		var rr := raio * lerpf(1.0, afina, t) * (1.0 + 1.25 * exp(-ya / (raio * 1.7)))
		pts.append([c, rr])
	var base := casca.darkened(0.22)
	lt.tubo(pts, lados, base, casca, false)
	return pts[niveis - 1][0]


static func _guarda_sol(lt: Lote, lc: Lote, pos: Vector3, h: float, detalhe: int, r: RandomNumberGenerator) -> Array:
	var raio := raio_tronco(GUARDA_SOL, h) * _rf(r, 0.9, 1.1)
	var topo := h * _rf(r, 0.56, 0.64)
	var incl := Vector3(_rf(r, -0.11, 0.11), 0.0, _rf(r, -0.11, 0.11))
	var fase := r.randf()
	var casca := Paleta.CASCA.lerp(Paleta.CASCA_CLARA, _rf(r, 0.15, 0.55))
	var cimo := _tronco(lt, pos, topo, raio, 0.60, incl, fase, casca, detalhe)
	var sombras: Array = []
	var sub := detalhe
	var n := r.randi_range(5, 6) if detalhe > 0 else 3
	var centro_vol := cimo + Vector3(0, h * 0.10, 0)
	for b in n + 1:
		var c: Vector3
		var rb: float
		if b < n:
			var ang := TAU * (float(b) + _rf(r, -0.3, 0.3)) / float(n)
			var dist := h * _rf(r, 0.17, 0.29)
			c = cimo + Vector3(cos(ang) * dist, h * _rf(r, 0.07, 0.18), sin(ang) * dist)
			rb = h * _rf(r, 0.17, 0.23)
		else:
			c = cimo + Vector3(_rf(r, -0.5, 0.5), h * _rf(r, 0.24, 0.30), _rf(r, -0.5, 0.5))
			rb = h * _rf(r, 0.18, 0.24)
		if detalhe > 0:
			var base_ramo := cimo - Vector3(0, _rf(r, 0.0, 0.16) * topo, 0)
			var meio := base_ramo.lerp(c, 0.55) + Vector3(0, -0.05 * h, 0)
			lt.tubo([[base_ramo, raio * 0.44], [meio, raio * 0.30], [c, raio * 0.13]], 5 if detalhe == 2 else 4, casca, casca, false)
		var tinta := Paleta.COPA_GUARDA_SOL_A.lerp(Paleta.COPA_GUARDA_SOL_B, r.randf())
		if r.randf() < 0.10:
			tinta = tinta.lerp(Paleta.COPA_OURO, _rf(r, 0.25, 0.5))
		lc.bolha(c, Vector3(rb, rb * _rf(r, 0.40, 0.50), rb), sub, tinta, _rf(r, 0.0, 90.0), centro_vol, fase, 1.0, 0.30, 0.32)
		sombras.append([c, rb])
	return sombras


static func _redonda(lt: Lote, lc: Lote, pos: Vector3, h: float, detalhe: int, r: RandomNumberGenerator) -> Array:
	var raio := raio_tronco(REDONDA, h) * _rf(r, 0.9, 1.15)
	var topo := h * _rf(r, 0.36, 0.44)
	var incl := Vector3(_rf(r, -0.07, 0.07), 0.0, _rf(r, -0.07, 0.07))
	var fase := r.randf()
	var casca := Paleta.CASCA.lerp(Paleta.CASCA_CLARA, _rf(r, 0.0, 0.25))
	var cimo := _tronco(lt, pos, topo, raio, 0.70, incl, fase, casca, detalhe, 0.30)
	var sombras: Array = []
	var n := r.randi_range(6, 7) if detalhe > 0 else 3
	var centro_vol := cimo + Vector3(0, h * 0.16, 0)
	for b in n + 1:
		var c: Vector3
		var rb: float
		if b < n:
			var ang := TAU * (float(b) + _rf(r, -0.3, 0.3)) / float(n)
			var dist := h * _rf(r, 0.16, 0.27)
			c = cimo + Vector3(cos(ang) * dist, h * _rf(r, 0.06, 0.26), sin(ang) * dist)
			rb = h * _rf(r, 0.19, 0.25)
		else:
			c = cimo + Vector3(_rf(r, -0.6, 0.6), h * _rf(r, 0.34, 0.40), _rf(r, -0.6, 0.6))
			rb = h * _rf(r, 0.21, 0.26)
		if detalhe > 0:
			var base_ramo := cimo - Vector3(0, _rf(r, 0.0, 0.3) * topo, 0)
			var meio := base_ramo.lerp(c, 0.5) + Vector3(0, 0.03 * h, 0)
			lt.tubo([[base_ramo, raio * 0.42], [meio, raio * 0.30], [c, raio * 0.12]], 5 if detalhe == 2 else 4, casca, casca, false)
		var tinta := Paleta.COPA_REDONDA_A.lerp(Paleta.COPA_REDONDA_B, r.randf())
		lc.bolha(c, Vector3(rb, rb * _rf(r, 0.78, 0.92), rb), detalhe, tinta, _rf(r, 0.0, 90.0), centro_vol, fase, 0.9, 0.32)
		sombras.append([c, rb])
	return sombras


static func _conifera(lt: Lote, lc: Lote, pos: Vector3, h: float, detalhe: int, r: RandomNumberGenerator) -> Array:
	var raio := raio_tronco(CONIFERA, h) * _rf(r, 0.9, 1.1)
	var incl := Vector3(_rf(r, -0.03, 0.03), 0.0, _rf(r, -0.03, 0.03))
	var fase := r.randf()
	var casca := Paleta.CASCA_CONIFERA.lerp(Paleta.CASCA, _rf(r, 0.0, 0.5))
	_tronco(lt, pos, h * 0.80, raio, 0.30, incl, fase, casca, mini(detalhe, 1), 0.05)
	var sombras: Array = []
	var saias := 6 if detalhe == 2 else (5 if detalhe == 1 else 3)
	var lados := 9 if detalhe == 2 else (7 if detalhe == 1 else 6)
	var y0 := h * _rf(r, 0.20, 0.27)
	var largo := h * _rf(r, 0.20, 0.25)
	for s in saias:
		var t := float(s) / float(saias)
		var t1 := float(s + 1) / float(saias)
		var base_y := lerpf(y0, h, t)
		var alto := (h - y0) / float(saias) * 1.75
		if s == saias - 1:
			alto = h - base_y
		var rr := largo * lerpf(1.0, 0.26, pow(t, 0.85)) * _rf(r, 0.92, 1.08)
		var c := pos + Vector3(incl.x * base_y, base_y, incl.z * base_y)
		var tinta := Paleta.COPA_CONIFERA_A.lerp(Paleta.COPA_CONIFERA_B, clampf(t1 + _rf(r, -0.2, 0.2), 0.0, 1.0))
		var dentro := Color(tinta.r * 0.80, tinta.g * 0.80, tinta.b * 0.80, 0.50)
		var fora := Color(tinta.r, tinta.g, tinta.b, 1.0)
		# a saia: pontas caídas (a orla desce abaixo da base), ombro, e fecha no tronco
		var perfil: Array = [[0.0, alto * 0.16], [rr, -alto * 0.10], [rr * 0.62, alto * 0.38], [rr * 0.20, alto * 0.86], [0.0, alto]]
		lc.torno(c, perfil, lados, dentro, fora, false, _rf(r, 0.0, TAU), Vector2(_rf(r, 0.9, 1.1), _rf(r, 0.9, 1.1)), fase)
		if s % 2 == 0:
			sombras.append([c + Vector3(0, alto * 0.2, 0), rr * 0.9])
	return sombras


static func _jovem(lt: Lote, lc: Lote, pos: Vector3, h: float, detalhe: int, r: RandomNumberGenerator) -> Array:
	var raio := raio_tronco(JOVEM, h) * _rf(r, 0.9, 1.15)
	var topo := h * _rf(r, 0.58, 0.68)
	var incl := Vector3(_rf(r, -0.14, 0.14), 0.0, _rf(r, -0.14, 0.14))
	var fase := r.randf()
	var casca := Paleta.CASCA_CLARA.lerp(Color("#c9c2ae"), _rf(r, 0.2, 0.7))
	var cimo := _tronco(lt, pos, topo, raio, 0.45, incl, fase, casca, detalhe, 0.35)
	var sombras: Array = []
	var n := r.randi_range(5, 6) if detalhe > 0 else 3
	var centro_vol := cimo - Vector3(0, h * 0.05, 0)
	for b in n:
		var t := float(b) / float(maxi(n - 1, 1))
		# massas pequenas em espiral larga à volta do tronco: copa leve, com céu por entre elas
		var ang := TAU * (float(b) * 0.40 + r.randf() * 0.12)
		var dist := h * _rf(r, 0.13, 0.21) * (1.0 - 0.78 * t * t)
		var c := cimo + Vector3(cos(ang) * dist, h * lerpf(-0.22, 0.27, t), sin(ang) * dist)
		var rb := h * _rf(r, 0.10, 0.135) * lerpf(1.0, 0.78, t)
		if detalhe > 0 and b < n - 1:
			lt.tubo([[cimo - Vector3(0, (0.45 - 0.3 * t) * topo, 0), raio * 0.36], [c, raio * 0.12]], 4, casca, casca, false)
		var tinta := Paleta.COPA_JOVEM.lerp(Paleta.COPA_REDONDA_B, _rf(r, 0.0, 0.6))
		if r.randf() < 0.18:
			tinta = tinta.lerp(Paleta.COPA_OURO, _rf(r, 0.3, 0.6))
		lc.bolha(c, Vector3(rb * 1.25, rb * _rf(r, 0.80, 1.0), rb * 1.25), detalhe, tinta, _rf(r, 0.0, 90.0), centro_vol, fase, 1.2, 0.36)
		sombras.append([c, rb * 0.85])
	return sombras


## Árvore morta (o cepo do charco): tronco partido e dois braços nus. Só tronco.
static func arvore_morta(lt: Lote, pos: Vector3, h: float, incl: Vector3, r: RandomNumberGenerator) -> void:
	var cor := Paleta.MADEIRA_MORTA
	var raio := h * 0.045
	var pts: Array = []
	for i in 6:
		var t := float(i) / 5.0
		var y := -0.4 + t * (h + 0.4)
		var ya := maxf(y, 0.0)
		pts.append([pos + Vector3(incl.x * ya + sin(t * 4.0) * 0.18, y, incl.z * ya + cos(t * 3.1) * 0.18), raio * lerpf(1.0, 0.42, t) * (1.0 + 1.1 * exp(-ya / (raio * 1.7)))])
	lt.tubo(pts, 7, cor.darkened(0.25), cor, true)
	for b in 3:
		var t := _rf(r, 0.45, 0.85)
		var base: Vector3 = (pts[2][0] as Vector3).lerp(pts[5][0], t)
		var ang := _rf(r, 0.0, TAU)
		var comp := h * _rf(r, 0.22, 0.38)
		var ponta := base + Vector3(cos(ang) * comp, comp * _rf(r, 0.25, 0.7), sin(ang) * comp)
		lt.tubo([[base, raio * 0.42], [base.lerp(ponta, 0.55) + Vector3(0, comp * 0.12, 0), raio * 0.26], [ponta, raio * 0.07]], 5, cor, cor, true)


# ------------------------------------------------------------------ estrato intermédio

## ARBUSTO: 6 «chamas» direitas que abrem de um pé comum, com os caules à vista.
## Feito na origem, altura ≈ 1,5 m. cor.a = oclusão.
static func arbusto(semente: int) -> Lote:
	var r := RandomNumberGenerator.new()
	r.seed = semente
	var l := Lote.new()
	var caule := Paleta.CASCA.lerp(Paleta.CASCA_CLARA, 0.3)
	var pe := Vector3(0, -0.1, 0)
	for b in 6:
		var ang := TAU * (float(b) + _rf(r, -0.3, 0.3)) / 6.0
		var fora := Vector3(cos(ang), 0.0, sin(ang))
		var abre := _rf(r, 0.22, 0.46) if b > 0 else 0.05
		var alto := _rf(r, 0.80, 1.20) if b > 0 else 1.30
		var c := fora * abre + Vector3(0, alto * 0.62, 0)
		var tinta := Paleta.ARBUSTO_A.lerp(Paleta.ARBUSTO_B, r.randf())
		l.tubo([[pe + fora * 0.04, 0.035], [c - Vector3(0, alto * 0.25, 0), 0.02]], 4, caule, caule, false)
		l.bolha(c, Vector3(0.24, alto * 0.50, 0.24) * _rf(r, 0.9, 1.15), 1, tinta, _rf(r, 0.0, 60.0), Vector3(0, 0.2, 0), r.randf(), 0.55, 0.42, 0.9)
	return l


## SILVADO: baixo e largo, pontas para todo o lado, com bagas vermelhas.
static func silvado(semente: int) -> Lote:
	var r := RandomNumberGenerator.new()
	r.seed = semente
	var l := Lote.new()
	for b in 8:
		var ang := TAU * (float(b) + _rf(r, -0.35, 0.35)) / 8.0
		var sobe := _rf(r, 0.25, 0.9)
		var fora := Vector3(cos(ang), sobe, sin(ang)).normalized()
		var comp := _rf(r, 0.45, 0.70)
		var c := fora * comp * 0.72 + Vector3(0, 0.12, 0)
		var tinta := Paleta.ARBUSTO_B.lerp(Paleta.FOLHA_LARGA, r.randf())
		# massa alongada segundo «fora»
		var b3 := Basis.looking_at(fora, Vector3(0.1, 1.0, 0.2))
		var peca := Lote.new()
		peca.bolha(Vector3.ZERO, Vector3(0.20, 0.20, comp * 0.62), 1, tinta, _rf(r, 0.0, 60.0), Vector3(0, 0, 0.4), r.randf(), 0.5, 0.40, 1.0)
		l.juntar(peca, Transform3D(b3, c))
		if b % 2 == 0:
			var baga := c + fora * comp * 0.30 + Vector3(_rf(r, -0.08, 0.08), 0.10, _rf(r, -0.08, 0.08))
			var cb := Paleta.BAGA
			l.bolha(baga, Vector3(0.055, 0.055, 0.055), 0, cb, 1.0, baga - Vector3(0, 0.2, 0), 0.0, 0.3, 0.0, 1.0)
	l.bolha(Vector3(0, 0.22, 0), Vector3(0.42, 0.26, 0.42), 1, Paleta.ARBUSTO_A, 7.0, Vector3(0, -0.2, 0), 0.4, 0.4, 0.34, 0.6)
	return l


## FETO: 9 frondes em arco, de orla serrilhada.
static func feto(semente: int) -> Lote:
	var r := RandomNumberGenerator.new()
	r.seed = semente
	var l := Lote.new()
	for f in 9:
		var ang := TAU * (float(f) + _rf(r, -0.3, 0.3)) / 9.0
		var fora := Vector3(cos(ang), 0.0, sin(ang))
		var lado := Vector3(-sin(ang), 0.0, cos(ang))
		var comp := _rf(r, 0.70, 1.0)
		var alto := _rf(r, 0.42, 0.62)
		var pts := PackedVector3Array()
		var larg := PackedFloat32Array()
		for i in 8:
			var t := float(i) / 7.0
			pts.append(fora * (0.04 + comp * t) + Vector3(0, alto * sin(t * PI * 0.72) * (1.0 - 0.25 * t), 0))
			var w := 0.15 * sin(clampf(t * 1.15, 0.0, 1.0) * PI) + 0.012
			larg.append(w * (1.0 if i % 2 == 1 else 0.58))
		var base := Paleta.FETO.darkened(0.30)
		base.a = 0.62
		var ponta := Paleta.FETO.lerp(Paleta.COPA_JOVEM, _rf(r, 0.0, 0.5))
		l.lamina(pts, larg, lado, base, ponta, r.randf(), 0.45)
	return l


## FOLHA LARGA: 6 folhas grandes e direitas (planta de sombra, verde-azulado).
static func folha_larga(semente: int) -> Lote:
	var r := RandomNumberGenerator.new()
	r.seed = semente
	var l := Lote.new()
	for f in 6:
		var ang := TAU * (float(f) + _rf(r, -0.3, 0.3)) / 6.0
		var fora := Vector3(cos(ang), 0.0, sin(ang))
		var lado := Vector3(-sin(ang), 0.0, cos(ang))
		var alto := _rf(r, 0.65, 1.0)
		var abre := _rf(r, 0.30, 0.55)
		var pts := PackedVector3Array([fora * 0.03, fora * abre * 0.25 + Vector3(0, alto * 0.42, 0),
			fora * abre * 0.62 + Vector3(0, alto * 0.82, 0), fora * abre + Vector3(0, alto * 0.98, 0), fora * abre * 1.25 + Vector3(0, alto * 0.90, 0)])
		var larg := PackedFloat32Array([0.02, 0.10, 0.19, 0.15, 0.01])
		var base := Paleta.FOLHA_LARGA.darkened(0.28)
		base.a = 0.6
		l.lamina(pts, larg, lado, base, Paleta.FOLHA_LARGA.lerp(Paleta.ARBUSTO_B, r.randf() * 0.6), r.randf(), 0.30)
	return l


# ------------------------------------------------------------------ erva

static func _malha_simples(v: PackedVector3Array, uv: PackedVector2Array, idx: PackedInt32Array) -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


## Tufo de relva. `largo` = false: 6 lâminas finas e direitas (a relva alta do prado);
## true: 5 lâminas largas e caídas (a erva mole da sombra e da beira-água).
## Altura normalizada (UV.y: 0 pé, 1 ponta).
static func tufo(largo: bool) -> ArrayMesh:
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	var r := RandomNumberGenerator.new()
	r.seed = 4243 if largo else 4242
	var n := 5 if largo else 6
	for b in n:
		var ang := TAU * (float(b) + r.randf_range(-0.35, 0.35)) / float(n)
		var fora := Vector3(cos(ang), 0.0, sin(ang))
		var lado := Vector3(-sin(ang + r.randf_range(-0.5, 0.5)), 0.0, cos(ang))
		var larg := r.randf_range(0.055, 0.075) if largo else r.randf_range(0.030, 0.045)
		var alt := r.randf_range(0.55, 0.80) if largo else r.randf_range(0.62, 1.0)
		var abre := r.randf_range(0.30, 0.55) if largo else r.randf_range(0.10, 0.34)
		var pe := fora * r.randf_range(0.02, 0.13)
		var cai := 0.22 if largo else 0.0
		var meio := pe + fora * abre * 0.38 + Vector3(0, alt * 0.58, 0)
		var ponta := pe + fora * abre + Vector3(0, alt * (1.0 - cai), 0)
		var base := v.size()
		v.append_array([pe - lado * larg, pe + lado * larg, meio - lado * larg * 0.78, meio + lado * larg * 0.78, ponta])
		uv.append_array([Vector2(0, 0), Vector2(1, 0), Vector2(0, 0.55 * alt), Vector2(1, 0.55 * alt), Vector2(0.5, alt)])
		idx.append_array([base, base + 1, base + 2, base + 1, base + 3, base + 2, base + 2, base + 3, base + 4])
	return _malha_simples(v, uv, idx)


## Haste com cabeça (shaders/haste.gdshader): UV.y altura, UV.x < 0,5 haste / ≥ 0,5 cabeça.
##   "espiga" — cabeça em losango comprido · "flor" — estrela de 5 pétalas · "junco" — charuto
static func haste(tipo: String) -> ArrayMesh:
	var v := PackedVector3Array()
	var uv := PackedVector2Array()
	var idx := PackedInt32Array()
	# a haste: duas fitas cruzadas
	var w := 0.012
	for k in 2:
		var lado := Vector3(1, 0, 0) if k == 0 else Vector3(0, 0, 1)
		var b := v.size()
		v.append_array([-lado * w, lado * w, lado * w * 0.6 + Vector3(0.04, 0.84, 0.02), -lado * w * 0.6 + Vector3(0.04, 0.84, 0.02)])
		uv.append_array([Vector2(0, 0), Vector2(0, 0), Vector2(0, 0.84), Vector2(0, 0.84)])
		idx.append_array([b, b + 1, b + 2, b, b + 2, b + 3])
	var topo := Vector3(0.04, 0.84, 0.02)
	if tipo == "flor":
		var c := v.size()
		v.append(topo + Vector3(0, 0.05, 0))
		uv.append(Vector2(1, 0.9))
		for p in 5:
			var a := TAU * float(p) / 5.0
			var a2 := a + TAU / 10.0
			v.append(topo + Vector3(cos(a) * 0.085, 0.10, sin(a) * 0.085))
			v.append(topo + Vector3(cos(a2) * 0.035, 0.07, sin(a2) * 0.035))
			uv.append_array([Vector2(1, 1.0), Vector2(1, 0.95)])
		for p in 5:
			var p0 := c + 1 + p * 2
			var p1 := c + 2 + p * 2
			var p2 := c + 1 + ((p + 1) % 5) * 2
			idx.append_array([c, p0, p1, c, p1, p2])
	else:
		# losango (espiga) ou charuto (junco): 4 gomos, dois níveis
		var raio := 0.020 if tipo == "espiga" else 0.032
		var comp := 0.16 if tipo == "espiga" else 0.20
		var b2 := v.size()
		v.append(topo)
		uv.append(Vector2(1, 0.84))
		for nivel in 2:
			var y := comp * (0.30 if nivel == 0 else 0.72)
			for q in 4:
				var a := TAU * float(q) / 4.0
				v.append(topo + Vector3(cos(a) * raio, y, sin(a) * raio))
				uv.append(Vector2(1, 0.84 + y))
		v.append(topo + Vector3(0, comp, 0))
		uv.append(Vector2(1, 1.0))
		var fim := b2 + 9
		for q in 4:
			var q1 := (q + 1) % 4
			idx.append_array([b2, b2 + 1 + q, b2 + 1 + q1])
			idx.append_array([b2 + 1 + q, b2 + 5 + q, b2 + 1 + q1, b2 + 1 + q1, b2 + 5 + q, b2 + 5 + q1])
			idx.append_array([b2 + 5 + q, fim, b2 + 5 + q1])
	return _malha_simples(v, uv, idx)


# ------------------------------------------------------------------ marcos

## MENIR: pedra alta e estreita, quase a prumo. `alto` em metros.
static func menir(l: Lote, pe: Vector3, alto: float, r: RandomNumberGenerator, deitado: bool = false) -> void:
	var esc := Vector3(alto * _rf(r, 0.20, 0.27), alto * 0.58, alto * _rf(r, 0.13, 0.18))
	var rot := Basis(Vector3.UP, _rf(r, 0.0, TAU)) * Basis(Vector3.RIGHT, _rf(r, -0.09, 0.09))
	var c := pe + Vector3(0, alto * 0.40, 0)
	if deitado:
		rot = Basis(Vector3.UP, _rf(r, 0.0, TAU)) * Basis(Vector3.RIGHT, deg_to_rad(82.0))
		c = pe + Vector3(0, esc.z * 0.55, 0)
	l.rocha(c, esc, rot, 2, Paleta.PEDRA_QUENTE.lerp(Paleta.PEDRA, r.randf()), _rf(r, 0.0, 60.0), 0.20)


## Telhado de 4 águas com os beirais arrebitados (meias medidas mx × mz, altura alt).
static func telhado(l: Lote, centro: Vector3, mx: float, mz: float, alt: float, cor: Color, rot: float = 0.0, uv_x: float = 0.0) -> void:
	var q := sqrt(2.0)
	var beira := Color(cor.r * 0.80, cor.g * 0.80, cor.b * 0.80, cor.a)
	var perfil: Array = [[q, alt * 0.10], [q * 0.90, 0.0], [q * 0.56, alt * 0.30], [q * 0.26, alt * 0.74], [q * 0.12, alt]]
	l.torno(centro, perfil, 4, beira, cor, true, rot + PI * 0.25, Vector2(mx, mz), uv_x)
	# por baixo fecha (quem olha de baixo vê o forro, não o céu)
	var forro := Color(cor.r * 0.78, cor.g * 0.78, cor.b * 0.78, cor.a)
	l.torno(centro, [[0.0, alt * 0.06], [q * 0.90, 0.0], [q, alt * 0.10]], 4, forro, forro, true, rot + PI * 0.25, Vector2(mx, mz), uv_x)
	# a cumeeira fecha em cima
	l.torno(centro, [[q * 0.12, alt], [0.0, alt * 1.04]], 4, cor, cor, true, rot + PI * 0.25, Vector2(mx, mz), uv_x)


## SANTUÁRIO (o marco do terraço): pagode pequeno de dois telhados — ardósia, laca vermelha e
## ouro, como o palácio da Árvore Ancestral. Feito na origem, virado para −Z. ≈ 4,6 × 4 × 6,2 m.
## cor.a = 0 marca LUZ PRÓPRIA (as janelas acesas).
static func santuario() -> Lote:
	var l := Lote.new()
	var pedra := Paleta.PEDRA_LANTERNA
	var laca := Paleta.MADEIRA_LACADA
	var telha := Paleta.TELHA
	var ouro := Paleta.OURO_VELHO
	var lume := Color(Paleta.LUME.r, Paleta.LUME.g, Paleta.LUME.b, 0.0)
	var b := Basis.IDENTITY
	l.caixa(Vector3(0, 0.05, 0), Vector3(2.5, 0.45, 2.15), b, pedra)
	l.caixa(Vector3(0, -0.10, -2.45), Vector3(1.1, 0.30, 0.35), b, pedra.darkened(0.08))
	l.caixa(Vector3(0, -0.28, -3.05), Vector3(1.1, 0.30, 0.35), b, pedra.darkened(0.14))
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			l.torno(Vector3(sx * 1.75, 0.5, sz * 1.45), [[0.17, 0.0], [0.15, 2.3]], 8, laca.darkened(0.15), laca)
	# a cela: madeira escura, com a porta e as frestas acesas
	l.caixa(Vector3(0, 1.55, 0.15), Vector3(1.25, 1.05, 1.0), b, Paleta.CASCA.lerp(laca, 0.35))
	l.caixa(Vector3(0, 1.35, -0.87), Vector3(0.48, 0.80, 0.03), b, lume)
	for sx: float in [-1.0, 1.0]:
		l.caixa(Vector3(sx * 0.92, 1.75, -0.87), Vector3(0.16, 0.34, 0.03), b, lume)
		l.caixa(Vector3(sx * 1.27, 1.75, 0.15), Vector3(0.03, 0.34, 0.5), b, lume)
	# o friso de ouro e o primeiro telhado
	l.caixa(Vector3(0, 2.72, 0), Vector3(2.05, 0.09, 1.75), b, ouro)
	telhado(l, Vector3(0, 2.80, 0), 2.75, 2.40, 1.25, telha)
	# o andar de cima
	l.caixa(Vector3(0, 3.95, 0), Vector3(0.80, 0.42, 0.68), b, laca)
	l.caixa(Vector3(0, 3.95, -0.70), Vector3(0.42, 0.24, 0.03), b, lume)
	l.caixa(Vector3(0, 4.40, 0), Vector3(1.0, 0.06, 0.86), b, ouro)
	telhado(l, Vector3(0, 4.45, 0), 1.55, 1.35, 0.95, telha)
	l.torno(Vector3(0, 5.38, 0), [[0.10, 0.0], [0.16, 0.14], [0.06, 0.30], [0.10, 0.44], [0.0, 0.85]], 6, ouro, ouro.lightened(0.15))
	return l


## LANTERNA de pedra (≈ 1,9 m), com o lume aceso. Feita na origem.
static func lanterna() -> Lote:
	var l := Lote.new()
	var pedra := Paleta.PEDRA_LANTERNA
	var lume := Color(Paleta.LUME.r, Paleta.LUME.g, Paleta.LUME.b, 0.0)
	l.torno(Vector3.ZERO, [[0.36, -0.2], [0.36, 0.14], [0.15, 0.26], [0.13, 0.98], [0.30, 1.08], [0.30, 1.14]], 6, pedra.darkened(0.12), pedra, true)
	l.caixa(Vector3(0, 1.31, 0), Vector3(0.16, 0.17, 0.16), Basis.IDENTITY, lume)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			l.caixa(Vector3(sx * 0.19, 1.31, sz * 0.19), Vector3(0.035, 0.17, 0.035), Basis.IDENTITY, pedra)
	telhado(l, Vector3(0, 1.48, 0), 0.46, 0.46, 0.36, pedra.darkened(0.10))
	return l


## TRONCO TOMBADO gigante (o muro do corredor da garganta): feito ao comprido de +Y, com o
## prato das raízes na ponta de baixo. `comp` e `raio` em metros.
static func tronco_tombado(comp: float, raio: float) -> Lote:
	var l := Lote.new()
	var cor := Paleta.MADEIRA_MORTA
	var cerne := Color("#b9a987")
	var escuro := cor.darkened(0.30)
	var perfil: Array = [[0.0, 0.0], [raio * 0.62, 0.0], [raio * 1.16, 0.25], [raio * 1.04, 1.4], [raio * 0.98, comp * 0.30],
		[raio * 0.90, comp * 0.62], [raio * 0.80, comp * 0.90], [raio * 0.74, comp - 0.05], [raio * 0.50, comp], [0.0, comp + 0.02]]
	l.torno(Vector3.ZERO, perfil, 12, cerne, cor, false, 0.0, Vector2(1.0, 0.94))
	var r := RandomNumberGenerator.new()
	r.seed = 3838
	# o prato das raízes
	for k in 8:
		var a := TAU * (float(k) + _rf(r, -0.3, 0.3)) / 8.0
		var fora := Vector3(cos(a), 0.0, sin(a))
		var c := _rf(r, 1.5, 2.5) * raio
		l.tubo([[fora * raio * 0.5 + Vector3(0, 0.5, 0), raio * 0.30], [fora * (raio * 0.9 + c * 0.5) + Vector3(0, 0.05, 0), raio * 0.18],
			[fora * (raio + c) + Vector3(0, -_rf(r, 0.2, 0.9), 0), raio * 0.05]], 6, escuro, cor, true)
	# cotos de ramo
	for k in 4:
		var y := comp * _rf(r, 0.35, 0.92)
		var a := _rf(r, 0.0, TAU)
		var fora := Vector3(cos(a), 0.0, sin(a))
		var c := _rf(r, 0.9, 2.2)
		l.tubo([[fora * raio * 0.6 + Vector3(0, y, 0), raio * 0.24], [fora * (raio * 0.8 + c) + Vector3(0, y + c * 0.4, 0), raio * 0.13]], 6, cor, cor, true)
	return l
