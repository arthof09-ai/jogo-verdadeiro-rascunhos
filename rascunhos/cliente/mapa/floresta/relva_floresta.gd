extends Node3D
## relva_floresta.gd — Ordem 38 (defeitos 7, 6 e 10): a RELVA do mapa da floresta.
##
## COBERTURA SEM CARECAS (defeito 7): os tufos saem de uma grelha tremida (um tufo por célula de
## 0,42 m, deslocado ao acaso dentro dela) — nunca fica um buraco maior que uma célula, ao
## contrário da sementeira ao acaso da Ordem 37. Só não há relva onde não deve haver: terra
## batida, rocha a pique, água, pé dos troncos.
##
## FAMÍLIAS (defeito 6): tufo fino (prado ao sol), tufo largo (sombra e beira-água), e por cima
## as hastes — espigas no prado, flores por quadrante (cada quadrante a sua cor), juncos no charco.
##
## LOD POR ANÉIS DE DISTÂNCIA (defeito 10): cada bloco de 25 m guarda os tufos baralhados; o
## tufo de ordem k/n fica enquanto k/n ≤ manter(distância). A cada passo da câmara a CPU corta o
## número de instâncias desenhadas de cada bloco (visible_instance_count) pela distância do bloco;
## o shader faz o resto por tufo: encolhe o que está a sair e alarga o que fica (sem salto e sem
## abrir carecas ao longe). manter() é a MESMA conta nos dois lados.

const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const Paleta := preload("res://mapa/floresta/paleta_floresta.gd")
const Formas := preload("res://mapa/floresta/formas_floresta.gd")

const BLOCO := 25.0
const PASSO := 0.42
const LIMITE := 62.5             # a relva vai até aqui (|x|, |z|): arena + orla rica
const LOD_PERTO := 16.0
const LOD_LONGE := 90.0
const LOD_MIN := 0.10

var densidade := 1.0
var lod_ligado := true
var medidas: Dictionary = {}

var _blocos: Array = []          # {mm: MultiMesh, x0, z0, x1, z1, n}
var _mat: ShaderMaterial
var _ultima := Vector3(1e9, 0, 0)
var _sujo := true


## A fracção de tufos que fica à distância d (igual à de shaders/relva.gdshader).
static func manter(d: float) -> float:
	var t := clampf((d - LOD_PERTO) / (LOD_LONGE - LOD_PERTO), 0.0, 1.0)
	return lerpf(1.0, LOD_MIN, pow(t, 0.55))


## Semeia tudo. `terra_em`(x, z) → 0–1 terra à mostra; `coberto_em`(x, z) → 0–1 sombra de copa.
func semear(mat_relva: ShaderMaterial, mat_haste: ShaderMaterial, terra_em: Callable, coberto_em: Callable, semente: int) -> void:
	_mat = mat_relva
	mat_relva.set_shader_parameter("lod_perto", LOD_PERTO)
	mat_relva.set_shader_parameter("lod_longe", LOD_LONGE)
	mat_relva.set_shader_parameter("lod_min", LOD_MIN)
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var rn := Relevo.ruido()
	var tufos: Array[ArrayMesh] = [Formas.tufo(false), Formas.tufo(true)]
	var nb := int(ceil(2.0 * LIMITE / BLOCO))
	var por_bloco := int(BLOCO / PASSO)
	var total := 0
	var hastes := {"espiga": [], "flor": [], "junco": []}
	for bj in nb:
		for bi in nb:
			var x0 := -LIMITE + bi * BLOCO
			var z0 := -LIMITE + bj * BLOCO
			var listas: Array = [[], []]
			for cj in por_bloco:
				for ci in por_bloco:
					var x := x0 + (ci + rng.randf()) * PASSO * (BLOCO / (por_bloco * PASSO))
					var z := z0 + (cj + rng.randf()) * PASSO * (BLOCO / (por_bloco * PASSO))
					var f := Relevo.fora(x, z)
					if f > Relevo.ORLA_FORA + 1.0:
						continue
					var terra: float = terra_em.call(x, z)
					if terra > 0.55:
						continue
					var agua := Relevo.agua(x, z)
					if agua > 0.10:
						if agua < 0.45 and rng.randf() < 0.55:
							hastes["junco"].append([x, z, Paleta.JUNCO_CABECA, rng.randf_range(1.1, 1.7)])
						continue
					var nrm := Relevo.normal(x, z)
					if nrm.y < 0.80:
						continue
					var coberto: float = coberto_em.call(x, z)
					# densidade: cheia na arena; debaixo da floresta rareia (mas nunca abre clareiras de chão liso
					# dentro da arena: aí a densidade só baixa com a terra à mostra)
					var dens := 1.0 - 0.75 * terra
					if f > 0.0:
						dens *= lerpf(0.92, 0.30, clampf(f / Relevo.ORLA_FORA, 0.0, 1.0)) * lerpf(1.0, 0.65, coberto)
					if rng.randf() > dens:
						continue
					var mancha := rn.get_noise_2d(x * 6.0 + 300.0, z * 6.0)
					var beira := 1.0 - smoothstep(0.0, 3.0, Vector2(x - Relevo.COVA.x, z - Relevo.COVA.y).length() - 5.2)
					var largo := rng.randf() < clampf(0.10 + 0.55 * coberto + 0.55 * beira + 0.25 * mancha, 0.0, 0.9)
					var alto: float
					var larg: float
					if largo:
						alto = rng.randf_range(0.42, 0.70)
						larg = rng.randf_range(1.0, 1.45)
					else:
						alto = rng.randf_range(0.48, 0.88) * (1.0 + 0.30 * mancha)
						larg = rng.randf_range(0.85, 1.35)
					var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(larg, alto, larg))
					var seca := clampf(0.5 + rn.get_noise_2d(x * 3.0 - 200.0, z * 3.0 + 70.0) * 1.4, 0.0, 1.0) * rng.randf_range(0.5, 1.0)
					if largo:
						seca *= 0.3
					listas[1 if largo else 0].append([Transform3D(b, Vector3(x, Relevo.altura(x, z) - 0.04, z)),
						Color(0.0, seca * 0.8, rng.randf(), 1.0),
						Color(nrm.x * 0.5 + 0.5, nrm.z * 0.5 + 0.5, coberto * smoothstep(-8.0, 4.0, f), 1.0)])
					# as hastes por cima da relva (só dentro e à beira da arena, ao sol)
					if f < 5.0 and coberto < 0.35 and terra < 0.2 and beira < 0.3:
						var prado := rn.get_noise_2d(x * 4.5 + 900.0, z * 4.5 - 400.0)
						var canteiro := rn.get_noise_2d(x * 7.0 - 700.0, z * 7.0 + 250.0)
						if prado > 0.12 and rng.randf() < 0.20:
							hastes["espiga"].append([x, z, Paleta.ESPIGA, rng.randf_range(0.85, 1.25)])
						elif canteiro > 0.22 and rng.randf() < 0.16:
							hastes["flor"].append([x, z, _cor_flor(x, z, rng), rng.randf_range(0.45, 0.80)])
			for tipo in 2:
				var lista: Array = listas[tipo]
				if lista.is_empty():
					continue
				# baralha (Fisher–Yates com a semente do mapa): a ordem k/n é o número de LOD do tufo
				for i in range(lista.size() - 1, 0, -1):
					var j := rng.randi_range(0, i)
					var tmp = lista[i]
					lista[i] = lista[j]
					lista[j] = tmp
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.use_custom_data = true
				mm.use_colors = true
				mm.mesh = tufos[tipo]
				mm.instance_count = lista.size()
				for i in lista.size():
					var e: Array = lista[i]
					var custom: Color = e[1]
					custom.r = (float(i) + 0.5) / float(lista.size())
					mm.set_instance_transform(i, e[0])
					mm.set_instance_custom_data(i, custom)
					mm.set_instance_color(i, e[2])
				var mmi := MultiMeshInstance3D.new()
				mmi.name = "Relva_%d_%d_%s" % [bi, bj, "larga" if tipo == 1 else "fina"]
				mmi.multimesh = mm
				mmi.material_override = mat_relva
				mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mmi.extra_cull_margin = 1.5
				add_child(mmi)
				_blocos.append({"mm": mm, "x0": x0, "z0": z0, "x1": x0 + BLOCO, "z1": z0 + BLOCO, "n": lista.size()})
				total += lista.size()
	medidas["relva_tufos"] = total
	medidas["relva_blocos"] = _blocos.size()
	medidas["relva_tri"] = total * 18
	_semear_hastes(hastes, mat_haste, rng)
	_sujo = true


## Cada quadrante a sua flor: NO lilás (o outeiro dos menires), NE branca (o charco),
## SE ouro (o santuário), SO branca e lilás (a garganta).
func _cor_flor(x: float, z: float, rng: RandomNumberGenerator) -> Color:
	var acaso := rng.randf()
	if x < 0.0 and z < 0.0:
		return Paleta.FLOR_LILAS if acaso < 0.85 else Paleta.FLOR_BRANCA
	if x >= 0.0 and z < 0.0:
		return Paleta.FLOR_BRANCA if acaso < 0.85 else Paleta.FLOR_OURO
	if x >= 0.0:
		return Paleta.FLOR_OURO if acaso < 0.85 else Paleta.FLOR_BRANCA
	return Paleta.FLOR_BRANCA if acaso < 0.6 else Paleta.FLOR_LILAS


func _semear_hastes(hastes: Dictionary, mat: ShaderMaterial, rng: RandomNumberGenerator) -> void:
	var tri := 0
	for tipo: String in hastes:
		var malha := Formas.haste(tipo)
		var tri_malha := (malha.surface_get_arrays(0)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		# por quadrante: o corte por frustum tira os que estão atrás da câmara
		var quadrantes: Array = [[], [], [], []]
		for h in hastes[tipo]:
			quadrantes[(0 if h[0] < 0.0 else 1) + (0 if h[1] < 0.0 else 2)].append(h)
		for q in 4:
			var lista: Array = quadrantes[q]
			if lista.is_empty():
				continue
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.use_custom_data = true
			mm.use_colors = true
			mm.mesh = malha
			mm.instance_count = lista.size()
			for i in lista.size():
				var e: Array = lista[i]
				var x: float = e[0]
				var z: float = e[1]
				var alto: float = e[3]
				var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(alto, alto, alto))
				mm.set_instance_transform(i, Transform3D(b, Vector3(x, Relevo.altura(x, z) - 0.03, z)))
				mm.set_instance_color(i, e[2])
				mm.set_instance_custom_data(i, Color(rng.randf(), 0.0, rng.randf(), 1.0))
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "Hastes_%s_%d" % [tipo, q]
			mmi.multimesh = mm
			mmi.material_override = mat
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mmi.extra_cull_margin = 1.0
			add_child(mmi)
			tri += lista.size() * tri_malha
		medidas["hastes_" + tipo] = (hastes[tipo] as Array).size()
	medidas["hastes_tri"] = tri


func definir_densidade(f: float) -> void:
	densidade = clampf(f, 0.1, 1.0)
	if _mat != null:
		_mat.set_shader_parameter("densidade", densidade)
	_sujo = true


func ligar_lod(ligar: bool) -> void:
	lod_ligado = ligar
	if _mat != null:
		_mat.set_shader_parameter("lod_ligado", 1.0 if ligar else 0.0)
	_sujo = true


## Quantos tufos estão a ser desenhados agora (depois do corte por distância; antes do frustum).
func tufos_ativos() -> int:
	var n := 0
	for b in _blocos:
		var mm: MultiMesh = b["mm"]
		n += mm.instance_count if mm.visible_instance_count < 0 else mm.visible_instance_count
	return n


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var p := cam.global_position
	if not _sujo and p.distance_squared_to(_ultima) < 1.0:
		return
	_ultima = p
	_sujo = false
	atualizar_lod(p)


## Corta o número de tufos desenhados de cada bloco pela distância da câmara ao bloco.
func atualizar_lod(p: Vector3) -> void:
	for b in _blocos:
		var mm: MultiMesh = b["mm"]
		var n: int = b["n"]
		var k := densidade
		if lod_ligado:
			var dx := maxf(maxf(float(b["x0"]) - p.x, p.x - float(b["x1"])), 0.0)
			var dz := maxf(maxf(float(b["z0"]) - p.z, p.z - float(b["z1"])), 0.0)
			k *= manter(sqrt(dx * dx + dz * dz))
		mm.visible_instance_count = -1 if k >= 0.999 else clampi(int(ceil(float(n) * k)), 1, n)
