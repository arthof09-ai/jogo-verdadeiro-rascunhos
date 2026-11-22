extends RefCounted
## Ordem CAIXA-PADRAO-CORRECOES — os CASOS do enquadramento dos retratos (hud/retratos.gd), partilhados pela suite
## (testes/rodar_testes.gd) e pela prova viva (provas/ordem-caixa-padrao-correcoes/ferramentas/). Não é código do jogo.
##
##   B1  a figura apanhada a meio da passada: o ciclo inteiro do ANDAR v3, quadro a quadro, e uma passada LONGA (as coxas
##       do manequim abertas para a frente e para trás) que pela caixa toda já não contaria como de pé;
##   B2  o que não é corpo: uma arma RÍGIDA empunhada e levantada acima da cabeça (presa à mão), e o braço
##       levantado (que é corpo: limite documentado);
##   B4  o ramo «corpo inteiro»: o manequim DEITADO, um QUADRÚPEDE esfolado (esqueleto + skin, feito aqui em código: o
##       repositório não tem nenhum modelo de quadrúpede) e a caixa zero (nada visível);
##   B5  a validação em repouso (a pose de repouso dá a caixa da malha) e a caixa em pose contra a malha ESFOLADA vértice
##       a vértice: `esfolar_cpu` (a conta do skinning, em qualquer modo) e `esfolar_motor` (a do próprio motor,
##       MeshInstance3D.bake_mesh_from_current_skeleton_pose; só com render — sem ecrã o motor não regista a skin).
## Nenhuma cor nova: o quadrúpede e a arma levam o material por omissão do motor.

const Retratos := preload("res://hud/retratos.gd")
const GLB := "res://testes/manequim/andar-v3.glb"
const ANIM := "andar_v3"
## Os ossos que o caso da passada longa e do braço levantado mexem (só aqui: a regra dos retratos não lê nomes de ossos).
const COXA_E := "thigh_l"
const COXA_D := "thigh_r"
const BRACO_D := "upperarm_r"
const MAO_D := "hand_r"
const CABECA := "Head"


## O manequim de referência numa figura (um Node3D, como a arena o põe), parado em `t` segundos do ANDAR v3.
## Devolve {fig, modelo, anim, esqueleto, malha} ou {} se não abriu.
static func manequim(t := 0.0) -> Dictionary:
	var doc := GLTFDocument.new()
	var est := GLTFState.new()
	if doc.append_from_file(GLB, est) != OK:
		return {}
	var fig := Node3D.new()
	var m := doc.generate_scene(est) as Node3D
	fig.add_child(m)
	var anim := m.find_child("AnimationPlayer", true, false) as AnimationPlayer
	anim.play(ANIM)
	anim.seek(t, true)
	anim.speed_scale = 0.0
	var malha := m.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	return {"fig": fig, "modelo": m, "anim": anim, "esqueleto": malha.get_node(malha.skeleton) as Skeleton3D, "malha": malha}


## Pára a animação (para as poses postas à mão não serem desfeitas no quadro seguinte).
static func parar(d: Dictionary) -> void:
	(d["anim"] as AnimationPlayer).active = false


## B1: as coxas abertas `graus` para a frente e para trás, sobre a pose de agora (uma passada larga, apanhada a meio).
static func passada_longa(d: Dictionary, graus := 55.0) -> void:
	var e := d["esqueleto"] as Skeleton3D
	for par in [[COXA_E, 1.0], [COXA_D, -1.0]]:
		var b := e.find_bone(par[0])
		var eixo := (e.get_bone_global_pose(b).basis.inverse() * Vector3.RIGHT).normalized()
		e.set_bone_pose_rotation(b, e.get_bone_pose_rotation(b) * Quaternion(eixo, deg_to_rad(graus * float(par[1]))))


## B2: o braço direito levantado, a mão acima da cabeça.
static func braco_levantado(d: Dictionary) -> void:
	var e := d["esqueleto"] as Skeleton3D
	var b := e.find_bone(BRACO_D)
	e.set_bone_pose_rotation(b, Quaternion(Vector3.RIGHT, PI) * e.get_bone_pose_rotation(b))


## B2: uma arma RÍGIDA (uma lâmina de 1,1 m) presa à mão direita (um nó posto na pose do osso da mão, como um
## BoneAttachment3D a põe — um BoneAttachment3D fora da árvore não se deixa copiar sem avisos) e levantada a direito acima
## da cabeça: a ponta fica a `acima` metros por cima do alto da figura. Devolve a malha da arma.
static func arma_levantada(d: Dictionary, acima := 0.6) -> MeshInstance3D:
	var e := d["esqueleto"] as Skeleton3D
	var presa := Node3D.new()
	presa.name = "Mao"
	e.add_child(presa)
	var arma := MeshInstance3D.new()
	arma.name = "Arma"
	var lamina := BoxMesh.new()
	lamina.size = Vector3(0.06, 1.1, 0.02)
	arma.mesh = lamina
	presa.add_child(arma)
	# A lâmina de pé, com a ponta `acima` m sobre o alto da figura (no espaço do esqueleto, que é o da figura).
	var alto := Retratos.caixa_do_corpo(d["fig"]).end.y
	var mao := e.get_bone_global_pose(e.find_bone(MAO_D))
	presa.transform = mao
	var centro := Vector3(mao.origin.x, alto + acima - 0.55, mao.origin.z)
	arma.transform = Transform3D(mao.basis.inverse(), mao.basis.inverse() * (centro - mao.origin))
	return arma


## B4: a figura deitada de costas (o modelo rodado 90° em x dentro da figura; a cópia do retrato só tira a rotação da
## figura, não a do modelo).
static func deitar(d: Dictionary) -> void:
	(d["modelo"] as Node3D).rotation_degrees.x = -90.0


## B4: um QUADRÚPEDE esfolado, feito em código: tronco de 1,3 m de comprido (em z, a frente é −z), quatro patas, pescoço
## e cabeça, as partes presas uma a uma a um osso de um Skeleton3D por uma Skin (peso 1). As patas da frente vão a meio do passo.
## O motor calcula as caixas por osso (`bone_aabbs`) da superfície, como para o manequim.
static func quadrupede() -> Node3D:
	var fig := Node3D.new()
	fig.name = "Quadrupede"
	var e := Skeleton3D.new()
	e.name = "Esqueleto"
	fig.add_child(e)
	# [nome, centro da parte, tamanho da parte]
	var partes := [
		["tronco", Vector3(0, 0.75, 0), Vector3(0.45, 0.4, 1.3)],
		["pata_fe", Vector3(-0.15, 0.3, -0.5), Vector3(0.12, 0.6, 0.12)],
		["pata_fd", Vector3(0.15, 0.3, -0.5), Vector3(0.12, 0.6, 0.12)],
		["pata_te", Vector3(-0.15, 0.3, 0.5), Vector3(0.12, 0.6, 0.12)],
		["pata_td", Vector3(0.15, 0.3, 0.5), Vector3(0.12, 0.6, 0.12)],
		["pescoco", Vector3(0, 0.95, -0.7), Vector3(0.2, 0.35, 0.25)],
		["cabeca", Vector3(0, 1.1, -0.95), Vector3(0.25, 0.25, 0.4)],
	]
	var skin := Skin.new()
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	var ossos := PackedInt32Array()
	var pesos := PackedFloat32Array()
	var idx := PackedInt32Array()
	for i in partes.size():
		var p: Array = partes[i]
		e.add_bone(p[0])
		e.set_bone_rest(i, Transform3D(Basis.IDENTITY, p[1]))
		e.set_bone_pose_position(i, p[1])
		skin.add_bind(i, Transform3D(Basis.IDENTITY, p[1]).affine_inverse())
		var caixa := BoxMesh.new()
		caixa.size = p[2]
		var arr := caixa.get_mesh_arrays()
		var base := vs.size()
		for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
			vs.append(v + (p[1] as Vector3))
			ossos.append_array([i, 0, 0, 0])
			pesos.append_array([1.0, 0.0, 0.0, 0.0])
		ns.append_array(arr[Mesh.ARRAY_NORMAL])
		for k in (arr[Mesh.ARRAY_INDEX] as PackedInt32Array):
			idx.append(base + k)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vs
	arrays[Mesh.ARRAY_NORMAL] = ns
	arrays[Mesh.ARRAY_BONES] = ossos
	arrays[Mesh.ARRAY_WEIGHTS] = pesos
	arrays[Mesh.ARRAY_INDEX] = idx
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.name = "Corpo"
	mi.mesh = malha
	mi.skin = skin
	e.add_child(mi)
	mi.skeleton = NodePath("..")
	# As patas da frente a meio do passo (uma para a frente, outra para trás), à volta do ombro.
	for par in [[1, 25.0], [2, -25.0]]:
		var b: int = par[0]
		var ombro := Vector3(0, 0.3, 0)  # do centro da pata ao ombro
		var r := Basis(Vector3.RIGHT, deg_to_rad(par[1]))
		e.set_bone_pose_rotation(b, r.get_rotation_quaternion())
		e.set_bone_pose_position(b, (partes[b][1] as Vector3) + ombro - r * ombro)
	return fig


## B5: a malha esfolada vértice a vértice, no espaço de `raiz` (o da cópia do retrato): os vértices levados pelos ossos que os
## movem, com os seus pesos — a conta do skinning que o motor faz para desenhar. Funciona em qualquer modo.
static func esfolar_cpu(raiz: Node3D, mi: MeshInstance3D) -> AABB:
	var e := mi.get_node(mi.skeleton) as Skeleton3D
	var t_esq := Retratos._no_espaco_de(raiz, e)
	var skin := mi.skin
	var mats: Array[Transform3D] = []
	for i in skin.get_bind_count():
		var b := skin.get_bind_bone(i)
		if b < 0:
			b = e.find_bone(skin.get_bind_name(i))
		mats.append(t_esq * e.get_bone_global_pose(b) * skin.get_bind_pose(i))
	var caixa := AABB()
	var primeira := true
	for s in mi.mesh.get_surface_count():
		var arr := mi.mesh.surface_get_arrays(s)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bs: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var ws: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		var k := bs.size() / maxi(1, vs.size())
		for v in vs.size():
			var p := Vector3.ZERO
			for j in k:
				var w := ws[v * k + j]
				if w > 0.0:
					p += (mats[bs[v * k + j]] * vs[v]) * w
			if primeira:
				caixa = AABB(p, Vector3.ZERO)
				primeira = false
			else:
				caixa = caixa.expand(p)
	return caixa


## B5: a malha esfolada pelo PRÓPRIO MOTOR (bake_mesh_from_current_skeleton_pose), no espaço de `raiz`. Só com render:
## sem ecrã (--headless) o motor não regista a skin e devolve AABB() — quem chama usa então `esfolar_cpu`.
static func esfolar_motor(raiz: Node3D, mi: MeshInstance3D) -> AABB:
	if DisplayServer.get_name() == "headless":
		return AABB()
	var cozida := mi.bake_mesh_from_current_skeleton_pose()
	if cozida == null:
		return AABB()
	return Retratos._no_espaco_de(raiz, mi) * cozida.get_aabb()


## A câmara do retrato vê o ponto `p`? Conta-se à mão, com o quadro QUADRADO do retrato (hud/retratos.gd TAMANHO ×
## TAMANHO): a câmara destes casos não está num mundo (Camera3D.is_position_in_frustum precisa de um).
static func ve(cam: Camera3D, p: Vector3) -> bool:
	var l := cam.transform.affine_inverse() * p
	var fundo := -l.z
	if fundo <= cam.near or fundo >= cam.far:
		return false
	var meia := tan(deg_to_rad(cam.fov * 0.5)) * fundo
	return absf(l.x) <= meia and absf(l.y) <= meia


## O enquadramento da cópia: {cam, corpo (a caixa do corpo), de_pe, busto (a janela, se de pé)}. A câmara fica
## numa nova Camera3D (quem chama liberta-a com `cam.free()`).
static func enquadramento(copia: Node3D) -> Dictionary:
	var cam := Camera3D.new()
	Retratos.enquadrar(cam, copia)
	var caixas := Retratos.caixas_do_corpo(copia)
	var c := Retratos.caixa_do_corpo(copia)
	var dp := Retratos.de_pe(c, caixas) if c.size != Vector3.ZERO else false
	return {"cam": cam, "corpo": c, "de_pe": dp, "busto": Retratos.janela_busto(caixas, c) if dp else AABB()}


## Os pontos de controlo de um busto numa figura de pé (`c`: a caixa do corpo): alto da cabeça, rosto e peito no quadro;
## cintura, joelhos e pés fora. Devolve {dentro: bool, fora: bool, falta: [...]}.
static func conferir_busto(cam: Camera3D, c: AABB) -> Dictionary:
	var h := c.size.y
	var cx := c.get_center().x
	var cz := c.get_center().z
	var pontos := {
		"topo": [Vector3(cx, c.end.y - h * 0.02, cz), true], "rosto": [Vector3(cx, c.end.y - h * 0.07, cz), true],
		"peito": [Vector3(cx, c.end.y - h * 0.22, cz), true], "cintura": [Vector3(cx, c.end.y - h * 0.45, cz), false],
		"joelho": [Vector3(cx, c.position.y + h * 0.28, cz), false], "pe": [Vector3(cx, c.position.y + h * 0.02, cz), false],
	}
	var falta: Array = []
	var dentro := true
	var fora := true
	for k in pontos:
		var v := ve(cam, pontos[k][0])
		if v != pontos[k][1]:
			falta.append(k)
			if pontos[k][1]:
				dentro = false
			else:
				fora = false
	return {"dentro": dentro, "fora": fora, "falta": falta}


## Os oito cantos de uma caixa todos no quadro da câmara? (o corpo inteiro)
static func caixa_no_quadro(cam: Camera3D, c: AABB) -> bool:
	for i in 8:
		if not ve(cam, c.get_endpoint(i)):
			return false
	return true
