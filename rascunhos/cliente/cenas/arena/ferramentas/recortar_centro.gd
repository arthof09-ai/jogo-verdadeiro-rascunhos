extends SceneTree
## recortar_centro.gd — Ordem Neve (17/11): ajuda de OLHO (não mede nada). Junta lado a lado o centro
## (x 0,38–0,62 · y 0,38–0,62, a ampliação do Crítico 1) de vários PNG, ampliado 2×, num só ficheiro.
##   Godot --headless --path . -s res://cenas/arena/ferramentas/recortar_centro.gd -- --saida=X.png A.png B.png …
func _init() -> void:
	var saida := ""
	var fontes: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			saida = a.trim_prefix("--saida=")
		else:
			fontes.append(a)
	var partes: Array[Image] = []
	for f in fontes:
		var img := Image.load_from_file(f)
		var w := img.get_width()
		var h := img.get_height()
		var r := img.get_region(Rect2i(int(0.38 * w), int(0.38 * h), int(0.24 * w), int(0.24 * h)))
		r.resize(r.get_width() * 2, r.get_height() * 2, Image.INTERPOLATE_NEAREST)
		partes.append(r)
	var pw := partes[0].get_width()
	var ph := partes[0].get_height()
	var out := Image.create(pw * partes.size() + 8 * (partes.size() - 1), ph, false, Image.FORMAT_RGB8)
	out.fill(Color.BLACK)
	for i in partes.size():
		partes[i].convert(Image.FORMAT_RGB8)
		out.blit_rect(partes[i], Rect2i(0, 0, pw, ph), Vector2i(i * (pw + 8), 0))
	out.save_png(saida)
	quit(0)
