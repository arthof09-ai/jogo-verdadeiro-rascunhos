extends RefCounted
## O marcador de figura do SITE (jogo-t1/cena.js, «Campo3D r3», lido no site vivo a 08/11/2026 pelo I0004):
## enquanto uma figura não tem GLB, o site desenha-a assim, e é isto que a arena do Mestre desenha (Plano B;
## regra-mãe: o layout aprovado é o do site). Os números são os do cena.js, sem nada inventado:
##
## - anel de identificação: RingGeometry(0,56 × 0,85 → 0,56), cor da paleta [87b4b0, e5bb74, b98b9d, b5c3ce,
##   b7b77c] pela ordem em que a figura entra (`units.size % 5`), sem luz, a 0,035 m do chão;
## - sombra de contacto: CircleGeometry(0,5), cor 080c12, opacidade 0,35 (no chão), a 0,018 m;
## - corpo «marcador» (humanoide): pedra mate 817c73; cilindro (topo 0,22, base 0,38, altura = 0,68 × altura,
##   8 lados) com o centro a 0,34 × altura; cabeça icosaedro (raio 0,14 × altura) a 0,86 × altura;
## - corpo «marcador-lobo»: pedra mate 777b79; icosaedro de raio 1 escalado (0,3; 0,5 × altura; 0,7) com o centro
##   a 0,5 × altura;
## - morta: o corpo deita-se (rotação de 90° em z) e assenta no chão com 0,03 m de folga.
##
## A altura vem da ficha (`visual.alturaM`; as figuras do site já vêm ×1,25: a Ong 2,625 m). Sem ela, 2,25 m
## (humano de 1,80 m × 1,25, Plano B §B1). A arena só desenha: nunca calcula regra.

## ORDEM DADOS DE APRESENTAÇÃO: as cores, a altura por omissão e os raios vêm da tabela única.
const Apresentacao := preload("res://dados/apresentacao.gd")
const PALETA := Apresentacao.PALETA_ANEIS
const COR_PEDRA := Apresentacao.COR_PEDRA
const COR_PEDRA_LOBO := Apresentacao.COR_PEDRA_LOBO
const COR_CONTACTO := Apresentacao.COR_CONTACTO  # 080c12, opacidade 0,35
const ALTURA_PADRAO := Apresentacao.ALTURA_PADRAO  # 1,80 × 1,25
const RAIO_ANEL := Apresentacao.RAIO_ANEL
const RAIO_CONTACTO := Apresentacao.RAIO_CONTACTO


## Cria o nó da figura: Marcador (raiz) → Pivo (corpo, que se deita) + Anel + Contacto.
static func criar(altura_m: float, forma: String, indice_cor: int) -> Node3D:
	var altura := altura_m if altura_m > 0.0 else float(Apresentacao.ALTURAS_POR_TIPO.get(forma, ALTURA_PADRAO))
	var raiz := Node3D.new()
	raiz.name = "Marcador"
	raiz.set_meta("altura_m", altura)
	raiz.set_meta("forma", forma)
	var pivo := Node3D.new()
	pivo.name = "Pivo"
	raiz.add_child(pivo)
	if forma == "marcador-lobo":
		var corpo := MeshInstance3D.new()
		corpo.name = "Corpo"
		corpo.mesh = _icosaedro(1.0, _pedra(COR_PEDRA_LOBO))
		corpo.scale = Vector3(0.3, altura * 0.5, 0.7)
		corpo.position.y = altura * 0.5
		pivo.add_child(corpo)
	else:
		var corpo := MeshInstance3D.new()
		corpo.name = "Corpo"
		var cil := CylinderMesh.new()
		cil.top_radius = 0.22
		cil.bottom_radius = 0.38
		cil.height = altura * 0.68
		cil.radial_segments = 8
		cil.rings = 1
		cil.material = _pedra(COR_PEDRA)
		corpo.mesh = cil
		corpo.position.y = altura * 0.34
		pivo.add_child(corpo)
		var cabeca := MeshInstance3D.new()
		cabeca.name = "Cabeca"
		cabeca.mesh = _icosaedro(altura * 0.14, _pedra(COR_PEDRA))
		cabeca.position.y = altura * 0.86
		pivo.add_child(cabeca)
	var anel := MeshInstance3D.new()
	anel.name = "Anel"
	anel.mesh = anel_plano(RAIO_ANEL, cor_da_ordem(indice_cor))
	anel.position.y = 0.035
	raiz.add_child(anel)
	var contacto := MeshInstance3D.new()
	contacto.name = "Contacto"
	var disco := CylinderMesh.new()
	disco.top_radius = RAIO_CONTACTO
	disco.bottom_radius = RAIO_CONTACTO
	disco.height = 0.001
	disco.radial_segments = 24
	disco.rings = 1
	disco.material = _sem_luz(COR_CONTACTO)
	contacto.mesh = disco
	contacto.position.y = 0.018
	raiz.add_child(contacto)
	return raiz


static func cor_da_ordem(indice: int) -> Color:
	return PALETA[posmod(indice, PALETA.size())]


## Morta: o corpo deita-se (90° em z) e assenta no chão com 0,03 m de folga (cena.js `pose`). Viva: de pé.
static func deitar(raiz: Node3D, deitada: bool) -> void:
	var pivo := raiz.get_node("Pivo") as Node3D
	pivo.rotation = Vector3(0.0, 0.0, PI * 0.5 if deitada else 0.0)
	pivo.position.y = 0.0
	if deitada:
		var minimo := _y_minimo(pivo)
		pivo.position.y = -minimo + 0.03


## Anel plano no chão (RingGeometry do three.js: interior = 0,85 × raio), sem luz.
static func anel_plano(raio: float, cor: Color) -> Mesh:
	var im := ImmediateMesh.new()
	var segs := 32
	var dentro := raio * 0.85
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, _sem_luz(cor))
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var p0 := Vector3(cos(a0), 0.0, sin(a0))
		var p1 := Vector3(cos(a1), 0.0, sin(a1))
		im.surface_add_vertex(p0 * dentro)
		im.surface_add_vertex(p0 * raio)
		im.surface_add_vertex(p1 * raio)
		im.surface_add_vertex(p0 * dentro)
		im.surface_add_vertex(p1 * raio)
		im.surface_add_vertex(p1 * dentro)
	im.surface_end()
	return im


static func _y_minimo(pivo: Node3D) -> float:
	var minimo := INF
	var base := pivo.transform
	for f in pivo.get_children():
		if f is MeshInstance3D and (f as MeshInstance3D).mesh != null:
			var mi := f as MeshInstance3D
			var caixa: AABB = (base * mi.transform) * mi.mesh.get_aabb()
			minimo = minf(minimo, caixa.position.y)
	return 0.0 if minimo == INF else minimo


## Icosaedro com uma subdivisão (IcosahedronGeometry(r, 1) do three.js), sombreado plano.
static func _icosaedro(raio: float, material: Material) -> Mesh:
	var t := (1.0 + sqrt(5.0)) * 0.5
	var v: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var faces := [
		[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6],
		[7, 1, 8], [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10],
		[8, 6, 7], [9, 8, 1]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	for f in faces:
		var a: Vector3 = v[f[0]].normalized()
		var b: Vector3 = v[f[1]].normalized()
		var c: Vector3 = v[f[2]].normalized()
		var ab := ((a + b) * 0.5).normalized()
		var bc := ((b + c) * 0.5).normalized()
		var ca := ((c + a) * 0.5).normalized()
		for tri in [[a, ab, ca], [ab, b, bc], [ca, bc, c], [ab, bc, ca]]:
			# Ordem dos vértices para o Godot (frente no sentido dos ponteiros do relógio).
			for p in [tri[0], tri[2], tri[1]]:
				st.add_vertex((p as Vector3) * raio)
	st.generate_normals()
	return st.commit()


static func _pedra(cor: Color) -> StandardMaterial3D:
	# Pedra mate (MeshLambertMaterial do site): sem brilho.
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 1.0
	m.metallic_specular = 0.0
	return m


static func _sem_luz(cor: Color) -> StandardMaterial3D:
	# MeshBasicMaterial do site: sem luz, dos dois lados, sem escrever profundidade.
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	if cor.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
