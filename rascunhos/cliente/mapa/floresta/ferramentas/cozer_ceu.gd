extends SceneTree
## cozer_ceu.gd — Ordem 37, refeito na 38. O FORNO da pintura do céu: pinta o panorama com a
## GPU (shaders/forno_ceu.gdshader), grava o PNG e MEDE o que pintou: o diâmetro dos discos
## (a lua tem de ser MENOR que o sol), a lua mais clara que o céu à volta (lua de dia) e a
## cor do zénite nos 4 rumos (um só céu: tem de ser a mesma).
##
##   godot --path cliente -s res://mapa/floresta/ferramentas/cozer_ceu.gd
##
## Precisa de janela (GPU): NÃO corre com --headless. Volta a correr sempre que a
## COR_HORIZONTE, as cores do céu ou os astros da paleta mudarem. Sai com 1 se alguma medida
## falhar ou se o PNG não gravar (erro nomeado).

const Paleta := preload("res://mapa/floresta/paleta_floresta.gd")
const Erros := preload("res://mapa/floresta/erros_floresta.gd")
const FORNO := preload("res://mapa/floresta/shaders/forno_ceu.gdshader")
const SAIDA := "res://mapa/floresta/ceu/ceu_floresta_v3.png"
const LARGURA := 2048
const ALTURA := 1024
const ELEV_MIN := -6.0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _v3(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)


func _correr() -> void:
	if DisplayServer.get_name() == "headless":
		Erros.erro(Erros.SEM_GPU, "cozer_ceu.gd precisa de janela")
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
	mat.set_shader_parameter("cor_horizonte", _v3(Paleta.COR_HORIZONTE))
	mat.set_shader_parameter("cor_zenite", _v3(Paleta.CEU_ZENITE))
	mat.set_shader_parameter("cor_meio", _v3(Paleta.CEU_MEIO))
	mat.set_shader_parameter("cor_baixo", _v3(Paleta.CEU_BAIXO))
	mat.set_shader_parameter("dir_sol", Paleta.dir_luz())
	mat.set_shader_parameter("dir_lua", Paleta.dir_lua())
	mat.set_shader_parameter("sol_raio_graus", Paleta.SOL_DIAMETRO * 0.5)
	mat.set_shader_parameter("lua_raio_graus", Paleta.LUA_DIAMETRO * 0.5)
	mat.set_shader_parameter("elev_min_graus", ELEV_MIN)
	rect.material = mat
	vp.add_child(rect)
	for i in 4:
		await process_frame
	var img := vp.get_texture().get_image()
	var erro := img.save_png(ProjectSettings.globalize_path(SAIDA))
	if erro != OK:
		Erros.erro(Erros.FICHEIRO_NAO_GRAVOU, "%s (erro %d)" % [SAIDA, erro])
	# ---- as medidas
	var sol_d := _diametro_disco(img, Paleta.SOL_AZIMUTE, Paleta.SOL_ELEVACAO, 0.97)
	var lua_c := _luma(_pixel(img, Paleta.LUA_AZIMUTE + 0.6, Paleta.LUA_ELEVACAO + 0.9))
	var lua_fora := _luma(_pixel(img, Paleta.LUA_AZIMUTE, Paleta.LUA_ELEVACAO + Paleta.LUA_DIAMETRO * 1.2))
	var zen: Array = []
	var meio: Array = []
	for az in [0.0, 90.0, 180.0, -90.0]:
		zen.append(_pixel(img, az, 86.0))
		meio.append(_pixel(img, az, 60.0))
	var desvio_zen := 0.0
	for c in zen:
		desvio_zen = maxf(desvio_zen, _dist(c, zen[0]))
	print("[forno] %s gravado, %dx%d" % [SAIDA, img.get_width(), img.get_height()])
	print("[forno] sol Ø pintado %.2f° (medido %.2f°) · lua Ø pintado %.2f° · lua < sol: %s" % [
		Paleta.SOL_DIAMETRO, sol_d, Paleta.LUA_DIAMETRO, "SIM" if Paleta.LUA_DIAMETRO < Paleta.SOL_DIAMETRO else "NÃO"])
	print("[forno] lua de dia: luma do disco %.3f contra %.3f do céu ao lado (%s)" % [lua_c, lua_fora,
		"mais clara" if lua_c > lua_fora else "MAIS ESCURA"])
	print("[forno] zénite (86°) a N/L/S/O: %s · maior desvio %.1f/255" % [
		" ".join(zen.map(func(c): return "#" + (c as Color).to_html(false))), desvio_zen * 255.0])
	print("[forno] 60° a N/L/S/O: %s" % " ".join(meio.map(func(c): return "#" + (c as Color).to_html(false))))
	print("[forno] estrelas: nenhuma (o pincel já não as pinta)")
	var ok := erro == OK and Paleta.LUA_DIAMETRO < Paleta.SOL_DIAMETRO and lua_c > lua_fora and desvio_zen * 255.0 <= 6.0
	if not ok and erro == OK:
		Erros.erro(Erros.ARGUMENTO_INVALIDO, "o céu cozido falhou uma medida (ver linhas acima)")
	quit(0 if ok else 1)


func _pixel(img: Image, az: float, el: float) -> Color:
	var x := int(fposmod(az / 360.0 + 0.5, 1.0) * LARGURA) % LARGURA
	var y := clampi(int((90.0 - el) / (90.0 - ELEV_MIN) * ALTURA), 0, ALTURA - 1)
	return img.get_pixel(x, y)


func _luma(c: Color) -> float:
	return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b


func _dist(a: Color, b: Color) -> float:
	return maxf(absf(a.r - b.r), maxf(absf(a.g - b.g), absf(a.b - b.b)))


## Diâmetro (graus) do disco em (az, el): conta, na vertical do centro, os píxeis de luma ≥ limiar.
func _diametro_disco(img: Image, az: float, el: float, limiar: float) -> float:
	var n := 0
	for k in range(-80, 81):
		if _luma(_pixel(img, az, el + k * 0.05)) >= limiar:
			n += 1
	return n * 0.05
