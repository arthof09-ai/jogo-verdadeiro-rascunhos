extends SceneTree
## cozer_camadas.gd — Ordem 43. O FORNO das camadas do céu do ciclo do dia: pinta a densidade
## das nuvens com a GPU (shaders/forno_camadas.gdshader) e grava ceu/ceu_camadas_v1.png.
##
##   godot --path cliente -s res://mapa/floresta/ferramentas/cozer_camadas.gd
##
## Precisa de janela (GPU): NÃO corre com --headless. Só volta a correr se a receita das
## nuvens mudar. Sai com 1 se o PNG não gravar ou se a cobertura medida for absurda.

const Erros := preload("res://mapa/floresta/erros_floresta.gd")
const FORNO := preload("res://mapa/floresta/shaders/forno_camadas.gdshader")
const SAIDA := "res://mapa/floresta/ceu/ceu_camadas_v1.png"
const LARGURA := 2048
const ALTURA := 1024
const ELEV_MIN := -6.0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _correr() -> void:
	if DisplayServer.get_name() == "headless":
		Erros.erro(Erros.SEM_GPU, "cozer_camadas.gd precisa de janela")
		quit(1)
		return
	var vp := SubViewport.new()
	vp.size = Vector2i(LARGURA, ALTURA)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(vp)
	var rect := ColorRect.new()
	rect.size = Vector2(LARGURA, ALTURA)
	var mat := ShaderMaterial.new()
	mat.shader = FORNO
	mat.set_shader_parameter("elev_min_graus", ELEV_MIN)
	rect.material = mat
	vp.add_child(rect)
	for i in 4:
		await process_frame
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_L8)
	var erro := img.save_png(ProjectSettings.globalize_path(SAIDA))
	if erro != OK:
		Erros.erro(Erros.FICHEIRO_NAO_GRAVOU, "%s (erro %d)" % [SAIDA, erro])
		quit(1)
		return
	# a cobertura: fracção de píxeis com nuvem (> 0,5) na faixa onde elas vivem
	var com := 0
	var total := 0
	for y in range(0, ALTURA, 4):
		for x in range(0, LARGURA, 4):
			total += 1
			if img.get_pixel(x, y).r > 0.5:
				com += 1
	var cobertura := float(com) / float(total)
	print("[forno] camadas do céu: %s · %d×%d · cobertura de nuvem %.1f %%" % [SAIDA, LARGURA, ALTURA, cobertura * 100.0])
	if cobertura < 0.02 or cobertura > 0.6:
		Erros.erro(Erros.ARGUMENTO_INVALIDO, "cobertura de nuvem fora do razoável: %.3f" % cobertura)
		quit(1)
		return
	quit(0)
