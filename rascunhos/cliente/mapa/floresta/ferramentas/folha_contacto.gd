extends SceneTree
## folha_contacto.gd — Ordem 37. Junta as capturas de uma pasta em folhas de contacto 2×2
## (cada captura a 960×540) para a bancada as ver de uma vez. Corre sem janela:
##
##   godot --path cliente --headless -s res://mapa/floresta/ferramentas/folha_contacto.gd -- --pasta=capturas

const W := 960
const H := 540


func _init() -> void:
	var pasta := "res://mapa/floresta/capturas"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pasta="):
			pasta = "res://mapa/floresta/" + a.trim_prefix("--pasta=")
	var abs_pasta := ProjectSettings.globalize_path(pasta)
	var nomes: Array = []
	for f in DirAccess.get_files_at(abs_pasta):
		if f.ends_with(".png") and not f.contains("SO-FUNDO"):
			nomes.append(f)
	nomes.sort()
	var folha_n := 0
	for k in range(0, nomes.size(), 4):
		var folha := Image.create_empty(W * 2, H * 2, false, Image.FORMAT_RGB8)
		for i in mini(4, nomes.size() - k):
			var img := Image.load_from_file(abs_pasta.path_join(nomes[k + i]))
			img.convert(Image.FORMAT_RGB8)
			img.resize(W, H, Image.INTERPOLATE_LANCZOS)
			folha.blit_rect(img, Rect2i(0, 0, W, H), Vector2i((i % 2) * W, (i / 2) * H))
		folha_n += 1
		folha.save_jpg(abs_pasta.path_join("_folha_%d.jpg" % folha_n), 0.88)
		print("_folha_%d.jpg: %s" % [folha_n, ", ".join(nomes.slice(k, k + 4).map(func(n): return n.left(26)))])
	quit(0)
