extends SceneTree
## filmar_ancestral.gd — Ordem 38 (defeito 2, adenda do coordenador de 14/11): o FILME da Árvore
## Ancestral. A câmara dá uma volta inteira à árvore (órbita, a começar e a acabar na face norte —
## a frente do palácio) e depois aproxima-se do palácio. 32 s a 30 quadros por segundo.
##
##   godot --path cliente --resolution 1920x1080 -s res://mapa/floresta/ferramentas/filmar_ancestral.gd ##     -- --avi=C:/caminho/filme.avi
##   (depois de «--»:  --avi=…      onde gravar o filme (AVI com imagem MJPEG, 1920×1080, 30 q/s)
##                     --amostras   em vez de filmar, grava um quadro de 4 em 4 s em
##                                  capturas/_ensaio/filme — para conferir o enquadramento)
##
## PORQUE NÃO o --write-movie do Godot: experimentado na sucessão 3 — o Movie Maker grava a JANELA,
## e nesta máquina a janela não passa de 1028×749 (o ecrã é pequeno): o filme saía a 1920×1080 mas
## esticado e mole, e com 5 quadros da arena no arranque. Aqui cada quadro sai do SubViewport de
## 1920×1080 (o mesmo das capturas) e o AVI é escrito por esta ferramenta, quadro a quadro.
##
## Como na prova (provar_ancestral.gd), mostra só o céu, a árvore e o outeiro onde ela assenta: a
## arena e os anéis foram feitos para se verem de DENTRO; de fora e de cima ficariam entre a câmara
## e a árvore. O filme NÃO entra no repositório (é pesado e é material de bancada).
## Precisa de janela (GPU).

const CENA := "res://mapa/floresta/campo_floresta.tscn"
const QPS := 30.0
const T_ORBITA := 21.0        # s: a volta inteira
const T_CHEGAR := 8.5         # s: a aproximação ao palácio
const T_PARAR := 2.5          # s: parado, de frente para o palácio
const FOV := 34.0

var _t := 0.0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _suave(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _correr() -> void:
	var amostras := OS.get_cmdline_user_args().has("--amostras")
	var caminho_avi := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--avi="):
			caminho_avi = a.trim_prefix("--avi=")
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
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
	var arvore := cena.find_child("ArvoreAncestral", true, false) as MeshInstance3D
	var monte := cena.find_child("OuteiroAncestral", true, false) as MeshInstance3D
	if arvore == null or monte == null:
		push_error("[filme] a cena não tem ArvoreAncestral/OuteiroAncestral")
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
	var total := T_ORBITA + T_CHEGAR + T_PARAR
	var avi: FileAccess = null
	var tamanhos := PackedInt32Array()
	if caminho_avi != "":
		avi = FileAccess.open(caminho_avi, FileAccess.WRITE)
		if avi == null:
			push_error("[filme] não consegui abrir %s" % caminho_avi)
			quit(1)
			return
		_avi_cabecalho(avi, 0, 0)
	# o palácio: 0,15 H a norte do eixo, plataforma a 0,615 H
	var palacio := pe + Vector3(0.0, h * 0.68, -h * 0.15)
	while _t < total:
		var az: float
		var dist: float
		var olhos: float
		var mira: Vector3
		if _t < T_ORBITA:
			# a órbita: de norte, por leste, sul e oeste, de volta a norte; a câmara desce um
			# pouco a sul (vêem-se as raízes) e volta a subir
			var u := _t / T_ORBITA
			az = TAU * (u + 0.10 * sin(u * TAU) / TAU)      # um nadinha mais lenta nas faces norte
			dist = h * lerpf(2.55, 2.25, _suave(u))
			olhos = h * (0.42 - 0.14 * sin(u * PI))
			mira = pe + Vector3(0, h * 0.50, 0)
		else:
			# a aproximação: da face norte até à varanda do palácio
			var u := _suave((_t - T_ORBITA) / T_CHEGAR)
			az = 0.10 * (1.0 - u) * sin(u * PI)
			dist = h * lerpf(2.25, 0.72, u)
			olhos = h * lerpf(0.42, 0.70, u)
			mira = (pe + Vector3(0, h * 0.50, 0)).lerp(palacio, u)
		var de := pe + Vector3(sin(az) * dist, olhos, -cos(az) * dist)
		cam.look_at_from_position(de, mira, Vector3.UP)
		await RenderingServer.frame_post_draw
		if avi != null:
			var jpg := vp.get_texture().get_image().save_jpg_to_buffer(0.90)
			avi.store_buffer("00dc".to_ascii_buffer())
			avi.store_32(jpg.size())
			avi.store_buffer(jpg)
			if jpg.size() % 2 == 1:
				avi.store_8(0)
			tamanhos.append(jpg.size())
		if amostras and int(round(_t * QPS)) % 120 == 0:
			var pasta := ProjectSettings.globalize_path("res://mapa/floresta/capturas/_ensaio/filme")
			DirAccess.make_dir_recursive_absolute(pasta)
			vp.get_texture().get_image().save_jpg(pasta.path_join("filme_t%02d.jpg" % int(round(_t))), 0.9)
		_t += 1.0 / QPS
	if avi != null:
		_avi_fechar(avi, tamanhos)
		print("[filme] FILME OK · %s · %d quadros · %.2f s · %d×%d · %.1f MB" % [caminho_avi, tamanhos.size(),
			float(tamanhos.size()) / QPS, vp.size.x, vp.size.y, float(FileAccess.get_file_as_bytes(caminho_avi).size()) / 1048576.0])
	quit(0)


## O cabeçalho do AVI (RIFF · hdrl · começo de movi): 224 bytes certos. Escreve-se duas vezes — no
## princípio com zeros, e no fim outra vez, já com o número de quadros e os tamanhos.
func _avi_cabecalho(f: FileAccess, quadros: int, bytes_movi: int) -> void:
	var maior := 0
	f.seek(0)
	f.store_buffer("RIFF".to_ascii_buffer())
	f.store_32(4 + (8 + 192) + (8 + 4 + bytes_movi) + (8 + 16 * quadros))
	f.store_buffer("AVI ".to_ascii_buffer())
	f.store_buffer("LIST".to_ascii_buffer())
	f.store_32(192)
	f.store_buffer("hdrl".to_ascii_buffer())
	f.store_buffer("avih".to_ascii_buffer())
	f.store_32(56)
	f.store_32(int(1000000.0 / QPS))      # microssegundos por quadro
	f.store_32(maior)                       # bytes por segundo (indicativo)
	f.store_32(0)
	f.store_32(0x10)                        # tem índice
	f.store_32(quadros)
	f.store_32(0)
	f.store_32(1)                           # 1 fluxo (imagem)
	f.store_32(1048576)
	f.store_32(1920)
	f.store_32(1080)
	for i in 4:
		f.store_32(0)
	f.store_buffer("LIST".to_ascii_buffer())
	f.store_32(116)
	f.store_buffer("strl".to_ascii_buffer())
	f.store_buffer("strh".to_ascii_buffer())
	f.store_32(56)
	f.store_buffer("vids".to_ascii_buffer())
	f.store_buffer("MJPG".to_ascii_buffer())
	f.store_32(0)
	f.store_32(0)
	f.store_32(0)
	f.store_32(1)                           # escala
	f.store_32(int(QPS))                    # ritmo: 30 quadros por segundo
	f.store_32(0)
	f.store_32(quadros)
	f.store_32(1048576)
	f.store_32(0xFFFFFFFF)
	f.store_32(0)
	f.store_16(0)
	f.store_16(0)
	f.store_16(1920)
	f.store_16(1080)
	f.store_buffer("strf".to_ascii_buffer())
	f.store_32(40)
	f.store_32(40)
	f.store_32(1920)
	f.store_32(1080)
	f.store_16(1)
	f.store_16(24)
	f.store_buffer("MJPG".to_ascii_buffer())
	f.store_32(1920 * 1080 * 3)
	for i in 4:
		f.store_32(0)
	f.store_buffer("LIST".to_ascii_buffer())
	f.store_32(4 + bytes_movi)
	f.store_buffer("movi".to_ascii_buffer())


## Fecha o AVI: o índice (idx1) no fim e o cabeçalho outra vez, com as contas certas.
func _avi_fechar(f: FileAccess, tamanhos: PackedInt32Array) -> void:
	var bytes_movi := 0
	for t in tamanhos:
		bytes_movi += 8 + t + (t % 2)
	f.seek_end(0)
	f.store_buffer("idx1".to_ascii_buffer())
	f.store_32(16 * tamanhos.size())
	var onde := 4      # a contar do «movi»
	for t in tamanhos:
		f.store_buffer("00dc".to_ascii_buffer())
		f.store_32(0x10)      # quadro-chave (no MJPEG são todos)
		f.store_32(onde)
		f.store_32(t)
		onde += 8 + t + (t % 2)
	_avi_cabecalho(f, tamanhos.size(), bytes_movi)
	f.close()
