extends RefCounted
## lote_malha.gd — Ordem 37: um LOTE de geometria que se funde numa só malha (1 draw call).
## Guarda vértices, normais, cores e UV; no fim, fechar() devolve uma ArrayMesh.
## Peças: tubo (troncos, ramos), bolha (copas), rocha (facetada), mais triângulos soltos.

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
		centro_volume: Vector3, fase: float, peso_vento: float, rugoso: float = 0.30) -> void:
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
			q.y *= 0.55
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
	var cima := PackedFloat32Array()  # quanto a superfície LISA olha para cima (para o musgo)
	cima.resize(vs.size())
	for i in vs.size():
		var p := vs[i]
		cima[i] = (rot * Vector3(p.x / escala.x, p.y / escala.y, p.z / escala.z)).normalized().y
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
		n.append_array([nf, nf, nf])
		var tom := 0.86 + 0.28 * r3.get_noise_3d(a.x * 0.8 + float(k), a.y * 0.8, a.z * 0.8)
		var cf := Color(cor.r * tom, cor.g * tom, cor.b * tom, 1.0)
		c.append_array([cf, cf, cf])
		uv.append_array([Vector2(cima[fs[k]], 1.0), Vector2(cima[fs[k + 2]], 1.0), Vector2(cima[fs[k + 1]], 1.0)])
		idx.append_array([base, base + 1, base + 2])


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
