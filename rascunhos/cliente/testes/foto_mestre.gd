extends SceneTree
## Fotos da arena do Mestre com os marcadores do site, para o olho do Mestre (Plano B §B3; I0004, 08/11/2026).
##
##   xvfb-run -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
##     --path cliente -s res://testes/foto_mestre.gd -- --saida=<pasta>
##
## Corre COM render (Compatibility, OpenGL 3 por Mesa/llvmpipe no CI), nunca com --headless (que não desenha).
## Usa a vista REAL da fixture do servidor (dados-exemplo/mesa-mestre.json, cenário «mestre»: heroína, aliada,
## orc e lobo colocados). Tira:
##   1-ecra-do-mestre.png         o ecrã do Mestre inteiro, com o cartão de desgraça aberto;
##   2-arena-camara-fixa.png      a arena na câmara Fixa com zoom 1,5 (o protocolo de captura do Plano B §B3);
##   3-arena-de-perto.png         a mesma câmara Fixa, de perto, centrada nas figuras;
##   4-demonstracao-estados.png   DEMONSTRAÇÃO (não é uma batalha): o lobo caído e a aliada morta, para se ver
##                                que ambos ficam deitados (palavra do Muse, 08/11 17:03). A marcação é nossa.
## Confere que cada foto não é uma cor só (render verdadeiro). Código de saída 0 se as 4 saem, 1 se não.

const CENA := "res://cenas/mestre/mestre.tscn"
const ArenaMestre := preload("res://cenas/mestre/arena_mestre.gd")

var _saida := ""
var _falhas := 0
var _fx: Dictionary = {}


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _gravar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		printerr("  FALHA ", nome, ": sem imagem (o render não correu)")
		_falhas += 1
		return
	# Uma foto de verdade não é de uma cor só: conta as cores numa grelha de 64×36 pontos.
	var cores := {}
	for j in 36:
		for i in 64:
			var c := img.get_pixel(int((i + 0.5) * img.get_width() / 64.0), int((j + 0.5) * img.get_height() / 36.0))
			cores[c.to_html(false)] = true
	var caminho := _saida.path_join(nome)
	var erro := img.save_png(caminho)
	if erro != OK or cores.size() < 8:
		printerr("  FALHA ", nome, ": erro ", erro, ", ", cores.size(), " cores distintas")
		_falhas += 1
		return
	print("  ok    ", nome, " (", img.get_width(), "×", img.get_height(), ", ", cores.size(), " cores na amostra)")


func _correr() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
	if _saida == "":
		_saida = OS.get_user_data_dir().path_join("fotos")
	DirAccess.make_dir_recursive_absolute(_saida)
	print("== fotos para ", _saida, " · render: ", RenderingServer.get_video_adapter_name(), " ==")
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (d is Dictionary):
		printerr("sem a fixture do servidor")
		quit(1)
		return
	_fx = d
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede.papel = "mestre"
	root.size = Vector2i(1920, 1080)
	var vista: Dictionary = _fx["mestre"]["vista"]

	# 1. O ecrã do Mestre inteiro.
	var m = (load(CENA) as PackedScene).instantiate()
	m.enviar_fn = func(_t, _c, _r): return ""
	m.pedir_vista_fn = func(): pass
	root.add_child(m)
	await _quadros(2)
	m._aviso_entendido()
	m.aplicar_vista(vista)
	m.aplicar_cartao(_fx["mestre"]["cartoes"]["desgraca"])
	m._ao_redimensionar()
	await _quadros(30)
	await _gravar("1-ecra-do-mestre.png")
	m.queue_free()
	await _quadros(2)

	# 2 e 3. A arena sozinha, à largura toda.
	var a = ArenaMestre.new()
	root.add_child(a)
	await _quadros(1)
	a.aplicar_vista(vista)
	a.camera.definir_modo(a.camera.Modo.FIXA)
	a.camera.repor_zoom()
	a.camera._saltar()
	await _quadros(20)
	await _gravar("2-arena-camara-fixa.png")
	# A mesma câmara Fixa (o ângulo aprovado), mais perto, no grupo da heroína.
	a.camera.focar(_centro_das_figuras(a, vista, ["heroina-teste", "aliada-teste", "orc-teste"]))
	a.camera.definir_zoom(4.0)
	a.camera._saltar()
	await _quadros(20)
	await _gravar("3-arena-de-perto.png")

	# 4. Demonstração dos estados (cópia da vista; não é uma batalha).
	var demo: Dictionary = vista.duplicate(true)
	for f in demo["mestre"]["figuras"]:
		if f.get("fichaId") == "lobo-teste":
			f["caido"] = true
		elif f.get("fichaId") == "aliada-teste":
			f["vivo"] = false
	a.aplicar_vista(demo)
	a.camera.focar(_centro_das_figuras(a, vista, []))  # todas, para se verem o lobo caído e a aliada morta
	a.camera.definir_zoom(2.6)
	a.camera._saltar()
	await _quadros(20)
	await _gravar("4-demonstracao-estados.png")
	a.queue_free()
	await _quadros(1)

	print("fotos: %d falha(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _centro_das_figuras(a, vista: Dictionary, fichas: Array) -> Vector3:
	var soma := Vector3.ZERO
	var n := 0
	for f in vista["mestre"]["figuras"]:
		if f.get("colocada") == true and (fichas.is_empty() or f.get("fichaId") in fichas):
			soma += a.centro_da_casa(Vector2i(int(f.get("x", 0)), int(f.get("y", 0))))
			n += 1
	return soma / float(maxi(n, 1))
