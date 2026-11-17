extends SceneTree
## capturar_kit.gd — Ordem 65. As CAPTURAS do kit de arte (céu, cor e rampas), tiradas da Clareira de
## prova (arte/cenas/clareira_prova.tscn) com os materiais que a própria Clareira fabrica. A MESMA
## ferramenta tira o ANTES e o DEPOIS: só muda o que está na árvore (rampas, pincel, color script).
##
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --rendering-driver opengl3 --path cliente \
##     --resolution 1600x900 -s res://arte/ferramentas/capturar_kit.gd -- --etiqueta=antes --saida=<pasta>
##
## Opções: --etiqueta=antes|depois (entra no nome de cada ficheiro e no canto da imagem);
##         --saida=<pasta> (obrigatória); --so=ceu|familias|clareira|folhas (por omissão, tudo);
##         --perfil=baixo|medio|alto (por omissão «alto»: escala 3D a 1, para a captura sair nítida);
##         --sem-pincel (desliga o pincel do céu: o mesmo céu em gradiente liso, para comparar —
##         a etiqueta passa a «<etiqueta>-liso»).
## Sai:  ceu_<hora>_<vista>_<etiqueta>.png       (4 horas × virado ao sol / de costas para o sol)
##       clareira_<hora>_<etiqueta>.png           (4 horas, a Clareira inteira)
##       <familia>_<etiqueta>.png                 (7 famílias: esfera, caixa e cápsula com a rampa da família)
##       familias_todas_<etiqueta>.png            (as 7 lado a lado)
##       folha_rampas_<etiqueta>.png e folha_pincel_<etiqueta>.png (os próprios PNG, se existirem)
##       medidas_<etiqueta>.json                  (o que o color script deu em cada hora-chave)
## Precisa de janela (GPU ou mesa): NÃO corre com --headless. Só apresentação.

const CENA := "res://arte/cenas/clareira_prova.tscn"
const FAMILIAS: Array[String] = ["pele", "tecido", "metal", "pedra", "casca", "folhagem", "chao"]
const NOMES_HORA: Array[String] = ["manha", "tarde", "crepusculo", "noite"]
## Cores de amostra (albedo) das peças do mostruário: uma por família. Não são paleta — só amostras.
const AMOSTRA := {
	"pele": "#c79273", "tecido": "#9c3b33", "metal": "#8d95a3", "pedra": "#8f8b82",
	"casca": "#8a7862", "folhagem": "#58794a", "chao": "#7b664a",
}

var _etiqueta := "antes"
var _saida := ""
var _so := ""
var _perfil := "alto"
var _sem_pincel := false
var _c: Node3D
var _cam: Camera3D
var _rotulo: Label
var _mostruario: Node3D
var _medidas := {}


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--etiqueta="):
			_etiqueta = a.trim_prefix("--etiqueta=")
		elif a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
		elif a.begins_with("--so="):
			_so = a.trim_prefix("--so=")
		elif a.begins_with("--perfil="):
			_perfil = a.trim_prefix("--perfil=")
		elif a == "--sem-pincel":
			_sem_pincel = true
	if _saida == "":
		printerr("[capturar_kit] falta --saida=<pasta>")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_saida)
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quer(parte: String) -> bool:
	return _so == "" or _so == parte


func _correr() -> void:
	var ps := load(CENA) as PackedScene
	if ps == null:
		printerr("[capturar_kit] a cena não carrega")
		quit(1)
		return
	_c = ps.instantiate()
	_c.set("ciclo_automatico", false)
	_c.set("perfil", _perfil)
	root.add_child(_c)
	await _quadros(4)
	(_c.get_node("Medicao") as CanvasLayer).visible = false
	if _sem_pincel:
		_etiqueta += "-liso"
		var ceu := _c.get("_mat_ceu") as ShaderMaterial
		if ceu:
			ceu.set_shader_parameter("forca_pinceladas", 0.0)
	_cam = Camera3D.new()
	_cam.fov = 60.0
	_cam.far = 400.0
	_c.add_child(_cam)
	_cam.make_current()
	var camada := CanvasLayer.new()
	root.add_child(camada)
	_rotulo = Label.new()
	_rotulo.position = Vector2(18, 14)
	_rotulo.add_theme_font_size_override("font_size", 26)
	_rotulo.add_theme_color_override("font_color", Color.WHITE)
	_rotulo.add_theme_color_override("font_outline_color", Color.BLACK)
	_rotulo.add_theme_constant_override("outline_size", 8)
	camada.add_child(_rotulo)

	var horas: Array = _c.get("HORAS_CHAVE")
	if _quer("ceu"):
		for i in horas.size():
			await _hora(horas[i])
			var para_sol := _para_o_sol()
			var az := atan2(para_sol.x, para_sol.z)
			# o sol (ou a lua) fica no terço de cima do quadro
			var elev := rad_to_deg(asin(clampf(para_sol.y, -1.0, 1.0)))
			_olhar_ceu(az + deg_to_rad(18.0), clampf(elev - 14.0, 14.0, 38.0))
			await _foto("ceu_%s_sol" % NOMES_HORA[i], "céu · %s (%s h) · virado ao sol" % [NOMES_HORA[i], _h(horas[i])])
			_olhar_ceu(az + deg_to_rad(165.0), 24.0)
			await _foto("ceu_%s_costas" % NOMES_HORA[i], "céu · %s (%s h) · de costas para o sol" % [NOMES_HORA[i], _h(horas[i])])
	if _quer("clareira"):
		for i in horas.size():
			await _hora(horas[i])
			_cam.fov = 55.0
			_cam.position = Vector3(3.0, 9.5, 27.0)
			_cam.look_at(Vector3(0.0, 2.2, 0.0))
			await _foto("clareira_%s" % NOMES_HORA[i], "Clareira de prova · %s (%s h)" % [NOMES_HORA[i], _h(horas[i])])
	if _quer("familias"):
		await _hora(horas[1])
		await _familias()
	if _quer("folhas"):
		await _folhas()
	var f := FileAccess.open(_saida.path_join("medidas_%s.json" % _etiqueta), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_medidas, "\t"))
		f.close()
	print("[capturar_kit] feito: ", _saida)
	quit(0)


func _h(h: float) -> String:
	return ("%.1f" % h).replace(".", ",")


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _hora(h: float) -> void:
	_c.set("hora", h)
	_c.call("_escrever_hora", true)
	await _quadros(8)
	var cs = _c.get("_cs")
	if cs != null:
		var a: Dictionary = cs.call("amostrar", h)
		var d := {}
		for k in a:
			d[k] = "#" + (a[k] as Color).to_html(false).to_upper() if a[k] is Color else a[k]
		var sol := _c.get_node("Sol") as DirectionalLight3D
		d["sol_rotacao_graus"] = [sol.rotation_degrees.x, sol.rotation_degrees.y]
		_medidas["%.1f" % h] = d


## A direcção PARA o sol (a luz viaja ao longo de -Z do nó; o sol está em +Z).
func _para_o_sol() -> Vector3:
	return (_c.get_node("Sol") as Node3D).global_transform.basis.z.normalized()


func _olhar_ceu(azimute: float, inclinacao_graus: float) -> void:
	_cam.fov = 72.0
	_cam.position = Vector3(0.0, 3.0, 0.0)
	var el := deg_to_rad(inclinacao_graus)
	var dir := Vector3(sin(azimute) * cos(el), sin(el), cos(azimute) * cos(el))
	_cam.look_at(_cam.position + dir)


func _foto(nome: String, legenda: String) -> void:
	_rotulo.text = "ORDEM 65 · %s · %s" % [_etiqueta.to_upper(), legenda]
	await _quadros(6)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var caminho := _saida.path_join("%s_%s.png" % [nome, _etiqueta])
	var erro := img.save_png(caminho)
	print("[capturar_kit] ", caminho, " (", erro, ")")


# ------------------------------------------------------------------ mostruário das famílias

func _peca(mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	_mostruario.add_child(mi)
	return mi


## Esfera, caixa e cápsula com o material que a Clareira fabrica para a família (rampa incluída).
func _trio(familia: String, centro: Vector3, escala: float) -> void:
	var cor := Color(AMOSTRA[familia])
	var mat: Material
	if familia == "folhagem":
		mat = _c.call("_mat_folhagem", cor, -100.0, 1.0)  # presa muito abaixo: o vento mexe tudo por igual
	else:
		mat = _c.call("_mat_toon", familia, cor)
	var esfera := SphereMesh.new()
	esfera.radius = 0.9 * escala
	esfera.height = 1.8 * escala
	esfera.radial_segments = 48
	esfera.rings = 24
	_peca(esfera, mat, centro + Vector3(0.0, 0.9 * escala, 0.0))
	var caixa := BoxMesh.new()
	caixa.size = Vector3(1.1, 1.1, 1.1) * escala
	var cx := _peca(caixa, mat, centro + Vector3(-1.75 * escala, 0.55 * escala, 0.2 * escala))
	cx.rotation_degrees = Vector3(0.0, 32.0, 0.0)
	var capsula := CapsuleMesh.new()
	capsula.radius = 0.32 * escala
	capsula.height = 1.9 * escala
	_peca(capsula, mat, centro + Vector3(1.6 * escala, 0.95 * escala, 0.2 * escala))


func _limpar_mostruario() -> void:
	if _mostruario:
		_mostruario.queue_free()
	_mostruario = Node3D.new()
	_c.add_child(_mostruario)


func _familias() -> void:
	# Só o chão, o céu e a luz: os placeholders da Clareira e as tochas saem de cena.
	for n in _c.get_children():
		if n is OmniLight3D:
			(n as OmniLight3D).visible = false
		elif n is GeometryInstance3D and not String(n.name).begins_with("Chao"):
			(n as GeometryInstance3D).visible = false
	# A câmara fica de lado em relação ao sol: o terminador (a passagem luz → sombra) fica à vista.
	var s := _para_o_sol()
	var lado := Vector3(s.z, 0.0, -s.x).normalized()
	var frente := (lado * 0.97 + Vector3(s.x, 0.0, s.z).normalized() * 0.24).normalized()
	for familia in FAMILIAS:
		_limpar_mostruario()
		_mostruario.basis = Basis.looking_at(-frente, Vector3.UP)
		_trio(familia, Vector3.ZERO, 1.0)
		_cam.fov = 38.0
		_cam.position = frente * 8.2 + Vector3(0.0, 2.3, 0.0)
		_cam.look_at(Vector3(0.0, 0.85, 0.0))
		await _foto(familia, "família «%s» · tarde" % familia)
	_limpar_mostruario()
	_mostruario.basis = Basis.looking_at(-frente, Vector3.UP)
	for i in FAMILIAS.size():
		var x := (float(i) - 3.0) * 2.4
		var mat: Material
		if FAMILIAS[i] == "folhagem":
			mat = _c.call("_mat_folhagem", Color(AMOSTRA[FAMILIAS[i]]), -100.0, 1.0)
		else:
			mat = _c.call("_mat_toon", FAMILIAS[i], Color(AMOSTRA[FAMILIAS[i]]))
		var esfera := SphereMesh.new()
		esfera.radius = 1.0
		esfera.height = 2.0
		esfera.radial_segments = 48
		esfera.rings = 24
		_peca(esfera, mat, Vector3(x, 1.0, 0.0))
		var nome := Label3D.new()
		nome.text = FAMILIAS[i]
		nome.font_size = 96
		nome.outline_size = 24
		nome.pixel_size = 0.005
		nome.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		nome.no_depth_test = true
		nome.position = Vector3(x, 2.5, 0.0)
		_mostruario.add_child(nome)
	_cam.fov = 40.0
	_cam.position = frente * 24.0 + Vector3(0.0, 4.0, 0.0)
	_cam.look_at(Vector3(0.0, 1.1, 0.0))
	await _foto("familias_todas", "as 7 famílias · tarde")
	_limpar_mostruario()


# ------------------------------------------------------------------ os próprios ficheiros

## Os PNG tal como são (sem luz nem shader): as 7 rampas esticadas e as duas texturas do pincel.
func _folhas() -> void:
	var camada := CanvasLayer.new()
	camada.layer = 5
	root.add_child(camada)
	var fundo := ColorRect.new()
	fundo.color = Color("#30323a")
	fundo.set_anchors_preset(Control.PRESET_FULL_RECT)
	camada.add_child(fundo)
	var caixa := Control.new()
	camada.add_child(caixa)
	var tam := Vector2(root.size)
	var havia := false
	for i in FAMILIAS.size():
		var caminho := "res://arte/rampas/rampa_%s.png" % FAMILIAS[i]
		if not ResourceLoader.exists(caminho):
			continue
		havia = true
		var tr := TextureRect.new()
		tr.texture = load(caminho)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tr.position = Vector2(260, 90 + i * 110)
		tr.size = Vector2(tam.x - 320, 80)
		caixa.add_child(tr)
		var l := Label.new()
		l.text = FAMILIAS[i]
		l.add_theme_font_size_override("font_size", 30)
		l.position = Vector2(40, 108 + i * 110)
		caixa.add_child(l)
	if havia:
		await _foto("folha_rampas", "os 7 PNG das rampas (256×1, esticados; esquerda = sombra, direita = luz)")
	for n in caixa.get_children():
		n.queue_free()
	havia = false
	var pinceis := ["res://arte/pincel/pincel_mascara.png", "res://arte/pincel/ceu_pinceladas.png"]
	var x := 40.0
	for caminho in pinceis:
		if not ResourceLoader.exists(caminho):
			continue
		havia = true
		var tex := load(caminho) as Texture2D
		var tr := TextureRect.new()
		tr.texture = tex
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		var largura := 480.0 if tex.get_width() == tex.get_height() else tam.x - x - 40.0
		tr.position = Vector2(x, 110)
		tr.size = Vector2(largura, tam.y - 190)
		caixa.add_child(tr)
		var l := Label.new()
		l.text = "%s  (%d×%d)" % [caminho.get_file(), tex.get_width(), tex.get_height()]
		l.add_theme_font_size_override("font_size", 24)
		l.position = Vector2(x, 70)
		caixa.add_child(l)
		x += largura + 40.0
	if havia:
		await _foto("folha_pincel", "as duas texturas do pincel (os próprios PNG)")
	camada.queue_free()
