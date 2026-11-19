extends SceneTree
## Ordem NADO: converte o clipe «Swimming» do Mixamo (a fonte escolhida pelo Mestre) para o esqueleto do MANEQUIM
## DE PROVA da casa (Mannequin_F do UAL2, o mesmo do ANDAR v3) e grava o resultado ao lado do andar:
##
##   entrada  testes/manequim/orc-mixamo-swimming.fbx   (esqueleto mixamorig, 41 ossos, clipe «mixamo_com», 4,53 s)
##   entrada  testes/manequim/andar-v3.glb              (o manequim: malha + esqueleto; só os ossos UE deformam)
##   saída    testes/manequim/nado-v1.glb               (o manequim com UM clipe, «nadar_v1», no lugar e em ciclo)
##
##   godot --headless --path cliente -s res://testes/converter_nado.gd
##
## Corre sem janela (não desenha nada) e é determinista: a mesma entrada dá o mesmo clipe. Nada aqui é regra.
##
## A CONVERSÃO (retarget por rotações globais, com as poses de descanso alinhadas):
##  - o Mixamo descansa em pose A (braços a 45°) e o manequim em pose T: para cada osso mapeado calcula-se a
##    rotação A que leva a direcção de descanso do osso-fonte (para o filho dele) à direcção de descanso do
##    osso-alvo; a mão usa também o polegar (um referencial inteiro, não só a direcção) para a palma não rodar;
##  - em cada quadro: rotação global do alvo = Gfonte(t) · Rfonte⁻¹ · A⁻¹ · Ralvo; a local sai do pai já resolvido;
##  - a anca (pelvis) recebe a translação da fonte à escala das alturas da anca (0,9167 / 0,7947), MENOS o avanço:
##    o clipe do Mixamo nada 1,90 m por ciclo e aqui fica NO LUGAR (como o andar_v3) — quem avança é quem o usa;
##  - os dedos médio, anelar e mínimo (que o Mixamo deste clipe não tem) seguem o indicador;
##  - os ossos do rig de controlo (MCH-, ORG-, ik, fk…) não pesam na malha e ficam em descanso.

const FBX := "res://testes/manequim/orc-mixamo-swimming.fbx"

const FBX_BYTES := 5323360
const GLB_MANEQUIM := "res://testes/manequim/andar-v3.glb"
const GLB_MANEQUIM_SHA256 := "8413b0395d6b9f161aefe05004999ee5f605d4eb68e81a4767a81f9b56ea3491"
const SAIDA := "res://testes/manequim/nado-v1.glb"
const CLIPE_FONTE := "mixamo_com"
const CLIPE := "nadar_v1"
const PISTA := "Armature/Skeleton3D:"
const PX := "mixamorig_"

## fonte (sem o prefixo mixamorig_) -> [alvos]
const MAPA := {
	"Hips": ["pelvis"], "Spine": ["spine_01"], "Spine1": ["spine_02"], "Spine2": ["spine_03"],
	"Neck": ["neck_01"], "Head": ["Head"],
	"LeftShoulder": ["clavicle_l"], "LeftArm": ["upperarm_l"], "LeftForeArm": ["lowerarm_l"], "LeftHand": ["hand_l"],
	"LeftHandThumb1": ["thumb_01_l"], "LeftHandThumb2": ["thumb_02_l"], "LeftHandThumb3": ["thumb_03_l"],
	"LeftHandIndex1": ["index_01_l", "middle_01_l", "ring_01_l", "pinky_01_l"],
	"LeftHandIndex2": ["index_02_l", "middle_02_l", "ring_02_l", "pinky_02_l"],
	"LeftHandIndex3": ["index_03_l", "middle_03_l", "ring_03_l", "pinky_03_l"],
	"RightShoulder": ["clavicle_r"], "RightArm": ["upperarm_r"], "RightForeArm": ["lowerarm_r"], "RightHand": ["hand_r"],
	"RightHandThumb1": ["thumb_01_r"], "RightHandThumb2": ["thumb_02_r"], "RightHandThumb3": ["thumb_03_r"],
	"RightHandIndex1": ["index_01_r", "middle_01_r", "ring_01_r", "pinky_01_r"],
	"RightHandIndex2": ["index_02_r", "middle_02_r", "ring_02_r", "pinky_02_r"],
	"RightHandIndex3": ["index_03_r", "middle_03_r", "ring_03_r", "pinky_03_r"],
	"LeftUpLeg": ["thigh_l"], "LeftLeg": ["calf_l"], "LeftFoot": ["foot_l"], "LeftToeBase": ["ball_l"],
	"RightUpLeg": ["thigh_r"], "RightLeg": ["calf_r"], "RightFoot": ["foot_r"], "RightToeBase": ["ball_r"],
}
## Para onde aponta cada osso em descanso (o filho que dá a direcção). A cabeça não tem filho no manequim: sobe.
const MIRA_FONTE := {
	"Hips": "Spine", "Spine": "Spine1", "Spine1": "Spine2", "Spine2": "Neck", "Neck": "Head", "Head": "HeadTop_End",
	"LeftShoulder": "LeftArm", "LeftArm": "LeftForeArm", "LeftForeArm": "LeftHand", "LeftHand": "LeftHandIndex1",
	"LeftHandThumb1": "LeftHandThumb2", "LeftHandThumb2": "LeftHandThumb3", "LeftHandThumb3": "LeftHandThumb4",
	"LeftHandIndex1": "LeftHandIndex2", "LeftHandIndex2": "LeftHandIndex3", "LeftHandIndex3": "LeftHandIndex4",
	"RightShoulder": "RightArm", "RightArm": "RightForeArm", "RightForeArm": "RightHand", "RightHand": "RightHandIndex1",
	"RightHandThumb1": "RightHandThumb2", "RightHandThumb2": "RightHandThumb3", "RightHandThumb3": "RightHandThumb4",
	"RightHandIndex1": "RightHandIndex2", "RightHandIndex2": "RightHandIndex3", "RightHandIndex3": "RightHandIndex4",
	"LeftUpLeg": "LeftLeg", "LeftLeg": "LeftFoot", "LeftFoot": "LeftToeBase", "LeftToeBase": "LeftToe_End",
	"RightUpLeg": "RightLeg", "RightLeg": "RightFoot", "RightFoot": "RightToeBase", "RightToeBase": "RightToe_End",
}
const MIRA_ALVO := {
	"pelvis": "spine_01", "spine_01": "spine_02", "spine_02": "spine_03", "spine_03": "neck_01", "neck_01": "Head",
	"clavicle_l": "upperarm_l", "upperarm_l": "lowerarm_l", "lowerarm_l": "hand_l", "hand_l": "index_01_l",
	"thumb_01_l": "thumb_02_l", "thumb_02_l": "thumb_03_l", "thumb_03_l": "thumb_04_leaf_l",
	"index_01_l": "index_02_l", "index_02_l": "index_03_l", "index_03_l": "index_04_leaf_l",
	"middle_01_l": "middle_02_l", "middle_02_l": "middle_03_l", "middle_03_l": "middle_04_leaf_l",
	"ring_01_l": "ring_02_l", "ring_02_l": "ring_03_l", "ring_03_l": "ring_04_leaf_l",
	"pinky_01_l": "pinky_02_l", "pinky_02_l": "pinky_03_l", "pinky_03_l": "pinky_04_leaf_l",
	"clavicle_r": "upperarm_r", "upperarm_r": "lowerarm_r", "lowerarm_r": "hand_r", "hand_r": "index_01_r",
	"thumb_01_r": "thumb_02_r", "thumb_02_r": "thumb_03_r", "thumb_03_r": "thumb_04_leaf_r",
	"index_01_r": "index_02_r", "index_02_r": "index_03_r", "index_03_r": "index_04_leaf_r",
	"middle_01_r": "middle_02_r", "middle_02_r": "middle_03_r", "middle_03_r": "middle_04_leaf_r",
	"ring_01_r": "ring_02_r", "ring_02_r": "ring_03_r", "ring_03_r": "ring_04_leaf_r",
	"pinky_01_r": "pinky_02_r", "pinky_02_r": "pinky_03_r", "pinky_03_r": "pinky_04_leaf_r",
	"thigh_l": "calf_l", "calf_l": "foot_l", "foot_l": "ball_l", "ball_l": "ball_leaf_l",
	"thigh_r": "calf_r", "calf_r": "foot_r", "foot_r": "ball_r", "ball_r": "ball_leaf_r",
}
## A mão: o referencial inteiro (para o indicador + para o polegar), para a palma ficar como na fonte.
const PALMA := {"LeftHand": ["LeftHandThumb1", "thumb_01_l"], "RightHand": ["RightHandThumb1", "thumb_01_r"]}

var _fk: Skeleton3D
var _tk: Skeleton3D
var _falhas := 0


func _init() -> void:
	var r := _converter()
	quit(0 if r and _falhas == 0 else 1)


func _falha(m: String) -> void:
	printerr("[nado] FALHA: ", m)
	_falhas += 1


func _converter() -> bool:
	print("== Ordem NADO · conversão do clipe Swimming (Mixamo) para o manequim da casa ==")
	var tam := FileAccess.get_file_as_bytes(FBX).size()
	if tam != FBX_BYTES:
		_falha("o FBX não é o da ordem (%d B, esperado %d B)" % [tam, FBX_BYTES])
		return false
	print("[nado] fonte ", FBX, " · ", tam, " B · SHA-256 ", FileAccess.get_sha256(FBX))
	if FileAccess.get_sha256(GLB_MANEQUIM) != GLB_MANEQUIM_SHA256:
		_falha("o manequim não é o ANDAR v3 aprovado")
		return false
	# ---- a fonte
	var fd := FBXDocument.new()
	var fs := FBXState.new()
	var e := fd.append_from_file(FBX, fs)
	if e != OK:
		_falha("o FBX não abriu (FBXDocument.append_from_file = %d)" % e)
		return false
	var fonte: Node = fd.generate_scene(fs)
	_fk = fonte.find_children("*", "Skeleton3D", true, false)[0]
	var fap: AnimationPlayer = fonte.find_child("AnimationPlayer", true, false)
	if fap == null or not fap.has_animation(CLIPE_FONTE):
		_falha("o FBX não traz o clipe %s" % CLIPE_FONTE)
		return false
	var a: Animation = fap.get_animation(CLIPE_FONTE)
	# ---- o alvo
	var gd := GLTFDocument.new()
	var gs := GLTFState.new()
	e = gd.append_from_file(GLB_MANEQUIM, gs)
	if e != OK:
		_falha("o manequim não abriu (%d)" % e)
		return false
	var alvo: Node = gd.generate_scene(gs)
	_tk = alvo.find_children("*", "Skeleton3D", true, false)[0]
	var tap: AnimationPlayer = alvo.find_child("AnimationPlayer", true, false)
	# ---- os ossos
	for s: String in MAPA:
		if _fk.find_bone(PX + s) < 0:
			_falha("a fonte não tem o osso %s%s" % [PX, s])
		for t: String in MAPA[s]:
			if _tk.find_bone(t) < 0:
				_falha("o manequim não tem o osso %s" % t)
	if _falhas > 0:
		return false
	# Os ossos que deformam: a árvore do «root» (a convenção UE do Mannequin_F). Ordem: pais antes dos filhos.
	var raiz := _tk.find_bone("root")
	var deformam: Array[int] = []
	for i in _tk.get_bone_count():
		var p := i
		while p >= 0 and p != raiz:
			p = _tk.get_bone_parent(p)
		if p == raiz:
			deformam.append(i)
	deformam.sort()   # o Skeleton3D guarda os pais antes dos filhos
	# ---- as rotações de alinhamento (descanso da fonte -> descanso do alvo), por alvo
	var alinha := {}   # alvo -> Quaternion A
	var fonte_de := {} # alvo -> osso-fonte
	for s: String in MAPA:
		for t: String in MAPA[s]:
			alinha[t] = _alinhamento(s, t)
			fonte_de[t] = _fk.find_bone(PX + s)
	# ---- os quadros
	var passo := a.step if a.step > 0.0 else 1.0 / 30.0
	var n := int(round(a.length / passo))
	var hips := _fk.find_bone(PX + "Hips")
	var pista_pos := a.find_track(NodePath("Skeleton3D:" + PX + "Hips"), Animation.TYPE_POSITION_3D)
	var p0: Vector3 = a.position_track_interpolate(pista_pos, 0.0)
	var p1: Vector3 = a.position_track_interpolate(pista_pos, a.length)
	var avanco := p1 - p0
	avanco.y = 0.0
	var escala := _tk.get_bone_global_rest(_tk.find_bone("pelvis")).origin.y / _fk.get_bone_global_rest(hips).origin.y
	print("[nado] clipe fonte %s: %s s, %d quadros, avanço da fonte por ciclo %s m (tirado: fica no lugar), escala da anca %s" % [
		CLIPE_FONTE, a.length, n + 1, avanco.length(), escala])
	var anim := Animation.new()
	anim.length = a.length
	anim.step = passo
	anim.loop_mode = Animation.LOOP_LINEAR
	var pistas_rot := {}
	for b in deformam:
		var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tr, NodePath(PISTA + _tk.get_bone_name(b)))
		pistas_rot[b] = tr
	var pelvis := _tk.find_bone("pelvis")
	var tr_pos := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(tr_pos, NodePath(PISTA + "pelvis"))
	var rest_f := {}
	for i in _fk.get_bone_count():
		rest_f[i] = _fk.get_bone_global_rest(i).basis.get_rotation_quaternion()
	var anca_y_min := INF
	var anca_y_max := -INF
	var anca_y_soma := 0.0
	var pelvis_rest := _tk.get_bone_global_rest(pelvis)
	var hips_rest := _fk.get_bone_global_rest(hips)
	for q in n + 1:
		var t := minf(q * passo, a.length)
		var gf := _globais_fonte(a, t)
		var gt := {}  # osso alvo -> Quaternion global
		for b in deformam:
			var par := _tk.get_bone_parent(b)
			var gpar := Quaternion.IDENTITY
			if gt.has(par):
				gpar = gt[par]
			elif par >= 0:
				gpar = _tk.get_bone_global_rest(par).basis.get_rotation_quaternion()
			var nome := _tk.get_bone_name(b)
			var g: Quaternion
			if fonte_de.has(nome):
				var sf: int = fonte_de[nome]
				var A: Quaternion = alinha[nome]
				var rt := _tk.get_bone_global_rest(b).basis.get_rotation_quaternion()
				g = ((gf[sf] as Quaternion) * (rest_f[sf] as Quaternion).inverse() * A.inverse() * rt).normalized()
			else:
				g = (gpar * _tk.get_bone_rest(b).basis.get_rotation_quaternion()).normalized()
			gt[b] = g
			var local := (gpar.inverse() * g).normalized()
			anim.rotation_track_insert_key(pistas_rot[b], t, local)
		# a anca: a translação da fonte à escala, sem o avanço (no lugar)
		var pf: Vector3 = a.position_track_interpolate(pista_pos, t)
		var desloc := (pf - hips_rest.origin - avanco * (t / a.length)) * escala
		var pg := pelvis_rest.origin + desloc
		var par_p := _tk.get_bone_global_rest(_tk.get_bone_parent(pelvis))
		anim.position_track_insert_key(tr_pos, t, par_p.affine_inverse() * pg)
		anca_y_min = minf(anca_y_min, pg.y)
		anca_y_max = maxf(anca_y_max, pg.y)
		anca_y_soma += pg.y
	var anca_media := anca_y_soma / float(n + 1)
	print("[nado] clipe %s: %d pistas de rotação + 1 de posição (pelvis), %s s, em ciclo; a anca entre %s e %s m (média %s m) acima da base" % [
		CLIPE, deformam.size(), anim.length, snappedf(anca_y_min, 0.001), snappedf(anca_y_max, 0.001), snappedf(anca_media, 0.001)])
	print("[nado] velocidade natural do clipe (o avanço da fonte à escala / ciclo): %s m/s" % snappedf(avanco.length() * escala / a.length, 0.001))
	# ---- o manequim com só o clipe novo
	var lib := AnimationLibrary.new()
	lib.add_animation(CLIPE, anim)
	for nome_lib in tap.get_animation_library_list():
		tap.remove_animation_library(nome_lib)
	tap.add_animation_library("", lib)
	alvo.name = "nado-v1"
	var ed := GLTFDocument.new()
	var es := GLTFState.new()
	e = ed.append_from_scene(alvo, es)
	if e != OK:
		_falha("o GLTFDocument não exportou a cena (%d)" % e)
		return false
	e = ed.write_to_filesystem(es, ProjectSettings.globalize_path(SAIDA))
	if e != OK:
		_falha("não consegui gravar %s (%d)" % [SAIDA, e])
		return false
	print("[nado] gravado ", SAIDA, " · ", FileAccess.get_file_as_bytes(SAIDA).size(), " B · SHA-256 ", FileAccess.get_sha256(SAIDA))
	_conferir_saida(anim)
	fonte.free()
	alvo.free()
	return true


## A rotação que leva o descanso do osso-fonte `s` ao descanso do osso-alvo `t` (no espaço dos esqueletos; os
## dois olham para +Z, com a esquerda em +X).
func _alinhamento(s: String, t: String) -> Quaternion:
	var ds := _direcao_fonte(s)
	var dt := _direcao_alvo(t)
	if PALMA.has(s) and t.begins_with("hand_"):
		var ss := _fk.get_bone_global_rest(_fk.find_bone(PX + PALMA[s][0])).origin - _fk.get_bone_global_rest(_fk.find_bone(PX + s)).origin
		var st := _tk.get_bone_global_rest(_tk.find_bone(PALMA[s][1])).origin - _tk.get_bone_global_rest(_tk.find_bone(t)).origin
		return (_referencial(dt, st) * _referencial(ds, ss).inverse()).get_rotation_quaternion()
	return Quaternion(ds, dt)


func _referencial(prim: Vector3, sec: Vector3) -> Basis:
	var x := prim.normalized()
	var z := x.cross(sec).normalized()
	var y := z.cross(x).normalized()
	return Basis(x, y, z)


func _direcao_fonte(s: String) -> Vector3:
	var a := _fk.get_bone_global_rest(_fk.find_bone(PX + s)).origin
	var b := _fk.get_bone_global_rest(_fk.find_bone(PX + String(MIRA_FONTE[s]))).origin
	return (b - a).normalized()


func _direcao_alvo(t: String) -> Vector3:
	if not MIRA_ALVO.has(t):
		return Vector3.UP   # a cabeça
	var a := _tk.get_bone_global_rest(_tk.find_bone(t)).origin
	var b := _tk.get_bone_global_rest(_tk.find_bone(String(MIRA_ALVO[t]))).origin
	return (b - a).normalized()


## As rotações globais (espaço do esqueleto) de todos os ossos da fonte no instante `t`.
func _globais_fonte(a: Animation, t: float) -> Dictionary:
	var g := {}
	for i in _fk.get_bone_count():
		var r := _fk.get_bone_rest(i).basis.get_rotation_quaternion()
		var tr := a.find_track(NodePath("Skeleton3D:" + _fk.get_bone_name(i)), Animation.TYPE_ROTATION_3D)
		if tr >= 0:
			r = a.rotation_track_interpolate(tr, t)
		var par := _fk.get_bone_parent(i)
		g[i] = ((g[par] as Quaternion) * r).normalized() if par >= 0 else r
	return g


## Relê o .glb gravado e confere que o clipe voltou igual (nome, duração, pistas e um quadro do meio).
func _conferir_saida(original: Animation) -> void:
	var d := GLTFDocument.new()
	var st := GLTFState.new()
	if d.append_from_file(SAIDA, st) != OK:
		_falha("o .glb gravado não reabre")
		return
	var cena: Node = d.generate_scene(st)
	var ap: AnimationPlayer = cena.find_child("AnimationPlayer", true, false)
	if ap == null or not ap.has_animation(CLIPE):
		_falha("o .glb gravado não traz o clipe %s" % CLIPE)
		cena.free()
		return
	var b: Animation = ap.get_animation(CLIPE)
	var sk: Skeleton3D = cena.find_children("*", "Skeleton3D", true, false)[0]
	var malhas := cena.find_children("*", "MeshInstance3D", true, false)
	print("[nado] relido: clipe %s, %s s, %d pistas; esqueleto %d ossos; %d malha(s)" % [CLIPE, b.length, b.get_track_count(), sk.get_bone_count(), malhas.size()])
	if absf(b.length - original.length) > 0.05:
		_falha("a duração mudou no .glb (%s -> %s)" % [original.length, b.length])
	if sk.get_bone_count() != _tk.get_bone_count() or malhas.is_empty():
		_falha("o manequim do .glb gravado não é o mesmo (ossos ou malha)")
	# um quadro do meio: a rotação da coxa esquerda
	var t := original.length * 0.5
	var ta := original.find_track(NodePath(PISTA + "thigh_l"), Animation.TYPE_ROTATION_3D)
	var tb := b.find_track(NodePath(PISTA + "thigh_l"), Animation.TYPE_ROTATION_3D)
	if tb < 0:
		_falha("o clipe relido não tem a pista da coxa")
	else:
		var qa := original.rotation_track_interpolate(ta, t)
		var qb := b.rotation_track_interpolate(tb, t)
		var dif := rad_to_deg(qa.angle_to(qb))
		print("[nado] coxa esquerda a meio do ciclo: diferença original/relido %s°" % snappedf(dif, 0.01))
		if dif > 1.0:
			_falha("a coxa relida difere %s°" % dif)
	cena.free()
