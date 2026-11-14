extends SceneTree
## provar_ancestral.gd — Ordem 38 (defeito 2). A PROVA da Árvore Ancestral: a câmara dá a volta à
## árvore e grava as 4 faces (norte, sul, leste, oeste) com o MESMO enquadramento das referências
## do Mestre (câmara a 0,39 H de altura, a olhar para 0,47 H, a árvore a encher 92 % do quadro).
##
##   godot --path cliente --resolution 1920x1080 -s res://mapa/floresta/ferramentas/provar_ancestral.gd
##   (opções depois de «--»:
##      --pasta=capturas/ancestral        onde ficam as 4 faces (JPEG a 95 %)
##      --refs=C:/caminho/das/referencias  se dado, grava também o LADO A LADO (referência à
##                                         esquerda, render à direita) em --lado=capturas/_lado-a-lado
##      --so=norte,sul                     só essas faces)
##
## As referências são material do coordenador e NÃO entram no repositório: por isso o lado a lado
## vai para uma pasta ignorada pelo git, e no repositório ficam só os renders.
## Mostra só o céu, a árvore e o outeiro onde ela assenta (a arena e os anéis escondem-se: daqui
## de cima e de fora, ficariam entre a câmara e a árvore). Precisa de janela (GPU).

const CENA := "res://mapa/floresta/campo_floresta.tscn"
const LARGURA := 1920
const ALTURA := 1080
const FOV := 12.0           # teleobjectiva, como a referência (a copa da frente não cresce)
const ENCHE := 0.90           # fracção da altura do quadro que a árvore ocupa na referência
const OLHOS := 0.39           # altura da câmara (× altura da árvore): onde o horizonte corta o tronco
const MIRA := 0.445           # para onde olha (× altura da árvore)
## face -> azimute de ONDE está a câmara, visto da árvore (graus a partir do norte, + para leste)
const FACES := {"norte": 0.0, "leste": 90.0, "sul": 180.0, "oeste": -90.0}

var _pasta := "res://mapa/floresta/capturas/ancestral"
var _lado := "res://mapa/floresta/capturas/_lado-a-lado"
var _refs := ""
var _so: Array = []


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pasta="):
			_pasta = "res://mapa/floresta/" + a.trim_prefix("--pasta=")
		elif a.begins_with("--lado="):
			_lado = "res://mapa/floresta/" + a.trim_prefix("--lado=")
		elif a.begins_with("--refs="):
			_refs = a.trim_prefix("--refs=")
		elif a.begins_with("--so="):
			_so = Array(a.trim_prefix("--so=").split(","))
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(LARGURA, ALTURA)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var mostra := TextureRect.new()
	mostra.texture = vp.get_texture()
	mostra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mostra.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mostra.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(mostra)
	var cena: Node3D = (load(CENA) as PackedScene).instantiate()
	cena.set("mostrar_medicao", false)
	vp.add_child(cena)
	await _quadros(4)
	var arvore := cena.find_child("ArvoreAncestral", true, false) as MeshInstance3D
	var monte := cena.find_child("OuteiroAncestral", true, false) as MeshInstance3D
	if arvore == null or monte == null:
		push_error("[ancestral] a cena não tem ArvoreAncestral/OuteiroAncestral")
		quit(1)
		return
	(cena.get("arena") as Node3D).visible = false
	for filho in (cena.get("fundo") as Node3D).get_children():
		if filho is Node3D and filho != arvore and filho != monte:
			(filho as Node3D).visible = false
	var h: float = cena.get("medidas")["ancestral_altura_m"]
	var pe := arvore.global_position
	var cam := Camera3D.new()
	cam.fov = FOV
	cam.near = 1.0
	cam.far = 6000.0
	cena.add_child(cam)
	cam.make_current()
	var dist := h / ENCHE / (2.0 * tan(deg_to_rad(FOV) * 0.5))
	var pasta_abs := ProjectSettings.globalize_path(_pasta)
	DirAccess.make_dir_recursive_absolute(pasta_abs)
	var lado_abs := ProjectSettings.globalize_path(_lado)
	var falhas := 0
	for face: String in FACES:
		if not _so.is_empty() and not _so.has(face):
			continue
		var az := deg_to_rad(float(FACES[face])) + arvore.rotation.y * -1.0
		var de := pe + Vector3(sin(az) * dist, h * OLHOS, -cos(az) * dist)
		cam.look_at_from_position(de, pe + Vector3(0, h * MIRA, 0), Vector3.UP)
		await _quadros(6)
		var img := vp.get_texture().get_image()
		var nome := "ancestral_face-%s_camara-a-%dm_olhos-%dm_fov%d.jpg" % [face, int(dist), int(h * OLHOS), int(FOV)]
		img.save_jpg(pasta_abs.path_join(nome), 0.95)
		print("[ancestral] %s" % nome)
		if _refs != "":
			var ref := Image.load_from_file(_refs.path_join("arvore-ancestral-gpt-%s-16x9.webp" % face))
			if ref == null:
				push_error("[ancestral] referência em falta: %s" % face)
				falhas += 1
				continue
			DirAccess.make_dir_recursive_absolute(lado_abs)
			var folha := Image.create_empty(1920, 540, false, Image.FORMAT_RGB8)
			ref.convert(Image.FORMAT_RGB8)
			ref.resize(960, 540, Image.INTERPOLATE_LANCZOS)
			var meu := img.duplicate() as Image
			meu.convert(Image.FORMAT_RGB8)
			meu.resize(960, 540, Image.INTERPOLATE_LANCZOS)
			folha.blit_rect(ref, Rect2i(0, 0, 960, 540), Vector2i(0, 0))
			folha.blit_rect(meu, Rect2i(0, 0, 960, 540), Vector2i(960, 0))
			folha.save_jpg(lado_abs.path_join("lado-a-lado_%s_referencia-ESQ_render-DIR.jpg" % face), 0.92)
	quit(1 if falhas > 0 else 0)
