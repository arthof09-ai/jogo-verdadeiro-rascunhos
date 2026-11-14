extends RefCounted
## lote_malha.gd — Ordem 37/38: um LOTE de geometria que se funde numa só malha (1 draw call).
## Guarda vértices, normais, cores e UV; no fim, fechar() devolve uma ArrayMesh.
## Peças: tubo (troncos, ramos), bolha (copas), rocha (facetada), torno (sólidos de revolução:
## cones de conífera, telhados, colunas), caixa, lâmina (folhas e frondes), juntar (carimbar).

var v := PackedVector3Array()
var n := PackedVector3Array()
var c := PackedColorArray()
var uv := PackedVector2Array()
var idx := PackedInt32Array()

static var _ico: Array = []  # por subdivisão: [PackedVector3Array vértices, PackedInt32Array índices]
static var _ruido: FastNoiseLite


static func _r3() -> FastNoiseLite:
	if _ruido == null:
		_ruido = FastNoiseLite.new()
		_ruido.seed = 370
		_ruido.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_ruido.frequency = 1.0
	return _ruido


## Icosfera unitária com `sub` subdivisões (0 = 20 triângulos, 1 = 80, 2 = 320).
static func icosfera(sub: int) -> Array:
	while _ico.size() <= sub:
		_ico.append(null)
	if _ico[sub] != null:
		return _ico[sub]
	var t := (1.0 + sqrt(5.0)) * 0.5
	var vs: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for i in vs.size():
		vs[i] = vs[i].normalized()
	var fs: Array[int] = [0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
		3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1]
	for s in sub:
		var meio := {}
		var nf: Array[int] = []
		for k in range(0, fs.size(), 3):
			var tri := [fs[k], fs[k + 1], fs[k + 2]]
			var m := [0, 0, 0]
			for e in 3:
				var a: int = tri[e]
				var b: int = tri[(e + 1) % 3]
				var chave := mini(a, b) * 100000 + maxi(a, b)
				if not meio.has(chave):
					meio[chave] = vs.size()
					vs.append(((vs[a] + vs[b]) * 0.5).normalized())
				m[e] = meio[chave]
			nf.append_array([tri[0], m[0], m[2], tri[1], m[1], m[0], tri[2], m[2], m[1], m[0], m[1], m[2]])
		fs = nf
	_ico[sub] = [PackedVector3Array(vs), PackedInt32Array(fs)]
	return _ico[sub]


## Tubo ao longo de pontos [centro: Vector3, raio: float]; cor por nível (escurece na base).
func tubo(pts: Array, lados: int, cor_base: Color, cor_topo: Color, fechar_topo: bool = true) -> void:
	var base := v.size()
	var niveis := pts.size()
	for i in niveis:
		var centro: Vector3 = pts[i][0]
		var raio: float = pts[i][1]
		var eixo: Vector3
		if i == 0:
			eixo = (pts[1][0] as Vector3) - centro
		elif i == niveis - 1:
			eixo = centro - (pts[i - 1][0] as Vector3)
		else:
			eixo = (pts[i + 1][0] as Vector3) - (pts[i - 1][0] as Vector3)
		eixo = eixo.normalized()
		var lado := eixo.cross(Vector3(0.31, 0.2, 0.93)).normalized()
		var frente := eixo.cross(lado)
		var cor := cor_base.lerp(cor_topo, float(i) / float(niveis - 1))
		for k in lados:
			var a := TAU * float(k) / float(lados)
			var dir := lado * cos(a) + frente * sin(a)
			v.append(centro + dir * raio)
			n.append(dir)
			c.append(cor)
			uv.append(Vector2(float(k) / lados, float(i) / (niveis - 1)))
	for i in niveis - 1:
		for k in lados:
			var a0 := base + i * lados + k
			var a1 := base + i * lados + (k + 1) % lados
			var b0 := a0 + lados
			var b1 := a1 + lados
			idx.append_array([a0, b0, a1, a1, b0, b1])
	if fechar_topo:
		var topo := v.size()
		v.append(pts[niveis - 1][0])
		n.append(Vector3.UP)
		c.append(cor_topo)
		uv.append(Vector2(0.5, 1.0))
		var ult := base + (niveis - 1) * lados
		for k in lados:
			idx.append_array([ult + k, topo, ult + (k + 1) % lados])


## Bolha de copa: icosfera deslocada por ruído, achatada por baixo, com normais «de volume»
## (puxadas para fora do centro da árvore) e cor/AO cozinhados. UV = (fase do vento, peso do vento).
func bolha(centro: Vector3, escala: Vector3, sub: int, cor: Color, semente: float,
		centro_volume: Vector3, fase: float, peso_vento: float, rugoso: float = 0.30, baixo: float = 0.55) -> void:
	var ico := icosfera(sub)
	var vs: PackedVector3Array = ico[0]
	var fs: PackedInt32Array = ico[1]
	var r3 := _r3()
	var base := v.size()
	for p in vs:
		var d := 1.0 + rugoso * r3.get_noise_3d(p.x * 1.3 + semente, p.y * 1.3 - semente * 0.7, p.z * 1.3 + semente * 1.9) \
				+ rugoso * 0.45 * r3.get_noise_3d(p.x * 3.1 - semente, p.y * 3.1 + semente, p.z * 3.1)
		var q := p * d
		if q.y < 0.0:
			q.y *= baixo
		var pos := centro + Vector3(q.x * escala.x, q.y * escala.y, q.z * escala.z)
		v.append(pos)
		var nv := (pos - centro_volume).normalized()
		n.append((p * 0.55 + nv * 0.45).normalized())
		# AO cozinhado: por baixo e para dentro da árvore fica mais escuro.
		var ao := clampf(0.62 + 0.38 * (p.y * 0.5 + 0.5) + 0.10 * (d - 1.0) / maxf(rugoso, 0.01), 0.35, 1.0)
		c.append(Color(cor.r, cor.g, cor.b, ao))
		uv.append(Vector2(fase, peso_vento * (0.6 + 0.4 * (p.y * 0.5 + 0.5))))
	# A icosfera vem em sentido anti-horário; o Godot quer a frente em sentido horário.
	for k in range(0, fs.size(), 3):
		idx.append_array([base + fs[k], base + fs[k + 2], base + fs[k + 1]])


## Rocha FACETADA: icosfera deslocada, com vértices por face (normal dura, pincelada de pedra).
## UV.x = quanto a superfície lisa olha para cima (o musgo não segue as facetas).
func rocha(centro: Vector3, escala: Vector3, rot: Basis, sub: int, cor: Color, semente: float, rugoso: float = 0.34) -> void:
	var ico := icosfera(sub)
	var vs: PackedVector3Array = ico[0]
	var fs: PackedInt32Array = ico[1]
	var r3 := _r3()
	var pos := PackedVector3Array()
	pos.resize(vs.size())
	var lisa := PackedVector3Array()  # normal da forma LISA (para o musgo e para amaciar as facetas)
	lisa.resize(vs.size())
	for i in vs.size():
		var p := vs[i]
		lisa[i] = (rot * Vector3(p.x / escala.x, p.y / escala.y, p.z / escala.z)).normalized()
		var d := 1.0 + rugoso * r3.get_noise_3d(p.x * 0.9 + semente, p.y * 0.9 + semente * 1.3, p.z * 0.9 - semente) \
				+ rugoso * 0.5 * r3.get_noise_3d(p.x * 2.3 - semente, p.y * 2.3, p.z * 2.3 + semente)
		# degraus: a pedra racha em planos
		d = lerpf(d, snappedf(d, 0.11), 0.55)
		var q := p * d
		pos[i] = centro + rot * Vector3(q.x * escala.x, q.y * escala.y, q.z * escala.z)
	for k in range(0, fs.size(), 3):
		var a := pos[fs[k]]
		var b := pos[fs[k + 1]]
		var cc := pos[fs[k + 2]]
		var nf := (b - a).cross(cc - a).normalized()
		var base := v.size()
		v.append_array([a, cc, b])
		# faceta com a aresta amaciada: 60% plano, 40% forma lisa
		n.append_array([nf.lerp(lisa[fs[k]], 0.4).normalized(), nf.lerp(lisa[fs[k + 2]], 0.4).normalized(), nf.lerp(lisa[fs[k + 1]], 0.4).normalized()])
		var tom := 0.90 + 0.20 * r3.get_noise_3d(a.x * 0.8 + float(k), a.y * 0.8, a.z * 0.8)
		var cf := Color(cor.r * tom, cor.g * tom, cor.b * tom, 1.0)
		c.append_array([cf, cf, cf])
		uv.append_array([Vector2(lisa[fs[k]].y, 1.0), Vector2(lisa[fs[k + 2]].y, 1.0), Vector2(lisa[fs[k + 1]].y, 1.0)])
		idx.append_array([base, base + 1, base + 2])


## Sólido de revolução em volta de `centro`: perfil = [[raio, y], ...] de baixo para cima.
## `duro` = faces vivas (telhados de 4 águas, prismas, colunas de pedra); senão liso.
## `oval` estica o raio em X e Z (telhado rectangular); `rot` roda em volta de Y (radianos).
## cor.a passa tal qual (os shaders lêem-no como oclusão ou como «luz própria»).
func torno(centro: Vector3, perfil: Array, lados: int, cor_base: Color, cor_topo: Color,
		duro: bool = false, rot: float = 0.0, oval: Vector2 = Vector2.ONE, uv_x: float = 0.0) -> void:
	var niveis := perfil.size()
	var anel: Array[PackedVector3Array] = []
	for i in niveis:
		var r: float = perfil[i][0]
		var y: float = perfil[i][1]
		var pts := PackedVector3Array()
		for k in lados:
			var a := rot + TAU * float(k) / float(lados)
			pts.append(centro + Vector3(cos(a) * r * oval.x, y, sin(a) * r * oval.y))
		anel.append(pts)
	if duro:
		for i in niveis - 1:
			var t0 := float(i) / float(niveis - 1)
			var t1 := float(i + 1) / float(niveis - 1)
			for k in lados:
				var k1 := (k + 1) % lados
				var a0 := anel[i][k]
				var a1 := anel[i][k1]
				var b0 := anel[i + 1][k]
				var b1 := anel[i + 1][k1]
				var nf := (b0 - a0).cross(a1 - a0)
				if nf.length_squared() < 1e-12:
					nf = (b1 - a1).cross(a1 - a0)
				if nf.length_squared() < 1e-12:
					# o perfil COMEÇA no eixo (a0 = a1): o forro de um telhado, uma tampa. Antes esta
					# fatia era saltada e o telhado, visto de baixo, era só o aro da beira contra o céu.
					nf = (b0 - a0).cross(b1 - a0)
				if nf.length_squared() < 1e-12:
					continue
				nf = nf.normalized()
				var base := v.size()
				v.append_array([a0, a1, b0, b1])
				n.append_array([nf, nf, nf, nf])
				var c0 := cor_base.lerp(cor_topo, t0)
				var c1 := cor_base.lerp(cor_topo, t1)
				c.append_array([c0, c0, c1, c1])
				uv.append_array([Vector2(uv_x, t0), Vector2(uv_x, t0), Vector2(uv_x, t1), Vector2(uv_x, t1)])
				idx.append_array([base, base + 1, base + 2, base + 1, base + 3, base + 2])
		return
	var base2 := v.size()
	for i in niveis:
		var ia := maxi(i - 1, 0)
		var ib := mini(i + 1, niveis - 1)
		var dr: float = float(perfil[ib][0]) - float(perfil[ia][0])
		var dy: float = float(perfil[ib][1]) - float(perfil[ia][1])
		var t := float(i) / float(niveis - 1)
		for k in lados:
			var a := rot + TAU * float(k) / float(lados)
			var nr := Vector3(cos(a) * dy / maxf(oval.x, 0.001), -dr, sin(a) * dy / maxf(oval.y, 0.001))
			if nr.length_squared() < 1e-10:
				nr = Vector3.UP
			v.append(anel[i][k])
			n.append(nr.normalized())
			c.append(cor_base.lerp(cor_topo, t))
			uv.append(Vector2(uv_x, t))
	for i in niveis - 1:
		for k in lados:
			var a0 := base2 + i * lados + k
			var a1 := base2 + i * lados + (k + 1) % lados
			idx.append_array([a0, a1, a0 + lados, a1, a1 + lados, a0 + lados])


## Caixa orientada (faces vivas). `meias` = meias medidas; `base` roda-a.
func caixa(centro: Vector3, meias: Vector3, base: Basis, cor: Color, uv_x: float = 0.0) -> void:
	var eixos: Array[Vector3] = [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
	for e in 3:
		for sinal: float in [-1.0, 1.0]:
			var nrm: Vector3 = eixos[e] * sinal
			var u: Vector3 = eixos[(e + 1) % 3]
			var w: Vector3 = eixos[(e + 2) % 3]
			var b0 := v.size()
			for q: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				var loc: Vector3 = nrm + u * q.x + w * q.y
				v.append(centro + base * Vector3(loc.x * meias.x, loc.y * meias.y, loc.z * meias.z))
				n.append((base * nrm).normalized())
				c.append(cor)
				uv.append(Vector2(uv_x, 0.5 + 0.5 * loc.y))
			if sinal > 0.0:
				idx.append_array([b0, b0 + 2, b0 + 1, b0 + 1, b0 + 2, b0 + 3])
			else:
				idx.append_array([b0, b0 + 1, b0 + 2, b0 + 1, b0 + 3, b0 + 2])


## Lâmina (folha, fronde): fita ao longo de `pts`, com as larguras dadas, deitada segundo `lado`.
## Sai com as DUAS faces (os shaders de massa cortam as costas). UV = (fase, peso do vento).
func lamina(pts: PackedVector3Array, larguras: PackedFloat32Array, lado: Vector3, cor_base: Color,
		cor_ponta: Color, fase: float = 0.0, peso_vento: float = 0.5) -> void:
	var m := pts.size()
	for face in 2:
		var base := v.size()
		for i in m:
			var t := float(i) / float(m - 1)
			var dir := (pts[mini(i + 1, m - 1)] - pts[maxi(i - 1, 0)]).normalized()
			var nrm := lado.cross(dir).normalized() * (1.0 if face == 0 else -1.0)
			var cor := cor_base.lerp(cor_ponta, t)
			v.append_array([pts[i] - lado * larguras[i], pts[i] + lado * larguras[i]])
			n.append_array([nrm, nrm])
			c.append_array([cor, cor])
			uv.append_array([Vector2(fase, peso_vento * t), Vector2(fase, peso_vento * t)])
		for i in m - 1:
			var a := base + i * 2
			if face == 0:
				idx.append_array([a, a + 2, a + 1, a + 1, a + 2, a + 3])
			else:
				idx.append_array([a, a + 1, a + 2, a + 1, a + 3, a + 2])


## Junta outro lote a este, transformado (para carimbar uma peça feita na origem).
func juntar(outro: RefCounted, t: Transform3D = Transform3D.IDENTITY) -> void:
	var base := v.size()
	var ov: PackedVector3Array = outro.get("v")
	var on: PackedVector3Array = outro.get("n")
	var nb := t.basis.inverse().transposed()
	for i in ov.size():
		v.append(t * ov[i])
		n.append((nb * on[i]).normalized())
	c.append_array(outro.get("c"))
	uv.append_array(outro.get("uv"))
	var oi: PackedInt32Array = outro.get("idx")
	for i in oi:
		idx.append(base + i)


func triangulos() -> int:
	return idx.size() / 3


func vazio() -> bool:
	return idx.is_empty()


func fechar() -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = n
	arr[Mesh.ARRAY_COLOR] = c
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = idx
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m
