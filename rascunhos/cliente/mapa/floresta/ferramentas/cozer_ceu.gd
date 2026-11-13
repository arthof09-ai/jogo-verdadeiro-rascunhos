extends SceneTree
## cozer_ceu.gd — Ordem 37. O FORNO da pintura do céu: pinta o panorama com a GPU
## (shaders/forno_ceu.gdshader), grava o PNG e MEDE o brilho da lua (alvo v2: 0,410).
##
##   godot --path cliente -s res://mapa/floresta/ferramentas/cozer_ceu.gd
##
## Precisa de janela (GPU): NÃO corre com --headless. Volta a correr sempre que a
## COR_HORIZONTE ou os astros da paleta mudarem.

const Paleta := preload("res://mapa/floresta/paleta_floresta.gd")
const FORNO := preload("res://mapa/floresta/shaders/forno_ceu.gdshader")
const SAIDA := "res://mapa/floresta/ceu/ceu_floresta_v2.png"
const LARGURA := 2048
const ALTURA := 1024
const ELEV_MIN := -6.0

var _vp: SubViewport
var _mat: ShaderMaterial


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _pintar(ganho: float) -> Image:
	_mat.set_shader_parameter("lua_ganho", ganho)
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	for i in 3:
		await process_frame
	return _vp.get_texture().get_image()


func _correr() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(LARGURA, ALTURA)
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(_vp)
	var rect := ColorRect.new()
	rect.size = Vector2(LARGURA, ALTURA)
	_mat = ShaderMaterial.new()
	_mat.shader = FORNO
	var h := Paleta.COR_HORIZONTE
	_mat.set_shader_parameter("cor_horizonte", Vector3(h.r, h.g, h.b))
	_mat.set_shader_parameter("dir_sol", Paleta.dir_sol_pintado())
	_mat.set_shader_parameter("dir_lua", Paleta.dir_lua())
	_mat.set_shader_parameter("sol_raio_graus", Paleta.SOL_DIAMETRO * 0.5)
	_mat.set_shader_parameter("lua_raio_graus", Paleta.LUA_DIAMETRO * 0.5)
	_mat.set_shader_parameter("elev_min_graus", ELEV_MIN)
	rect.material = _mat
	_vp.add_child(rect)

	# Afinar o ganho da lua até a mediana da luma do disco pousar em LUA_BRILHO (±0,004).
	var ganho := 0.62
	var img: Image
	var mediana := 0.0
	for volta in 8:
		img = await _pintar(ganho)
		mediana = _mediana_lua(img)
		print("[forno] volta %d: ganho %.4f -> mediana da lua %.4f" % [volta, ganho, mediana])
		if absf(mediana - Paleta.LUA_BRILHO) <= 0.004 or mediana <= 0.0:
			break
		ganho *= Paleta.LUA_BRILHO / mediana
	var erro := img.save_png(ProjectSettings.globalize_path(SAIDA))
	print("[forno] %s gravado (erro=%d) %dx%d | lua: ganho %.4f, mediana %.4f (alvo %.3f) | sol Ø %.2f° lua Ø %.2f°" % [
		SAIDA, erro, img.get_width(), img.get_height(), ganho, mediana, Paleta.LUA_BRILHO,
		Paleta.SOL_DIAMETRO, Paleta.LUA_DIAMETRO])
	quit(0 if erro == OK else 1)


## Mediana da luma (sRGB, Rec.709) dos píxeis dentro de 90% do raio do disco da lua.
func _mediana_lua(img: Image) -> float:
	var l := Paleta.dir_lua()
	var raio := deg_to_rad(Paleta.LUA_DIAMETRO * 0.5) * 0.90
	var lumas := PackedFloat32Array()
	var v0 := int((90.0 - Paleta.LUA_ELEVACAO - Paleta.LUA_DIAMETRO) / (90.0 - ELEV_MIN) * ALTURA)
	var v1 := int((90.0 - Paleta.LUA_ELEVACAO + Paleta.LUA_DIAMETRO) / (90.0 - ELEV_MIN) * ALTURA)
	for y in range(maxi(v0, 0), mini(v1, ALTURA)):
		var el := deg_to_rad(lerpf(90.0, ELEV_MIN, (float(y) + 0.5) / ALTURA))
		for x in LARGURA:
			var az := ((float(x) + 0.5) / LARGURA - 0.5) * TAU
			var d := Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))
			if d.angle_to(l) <= raio:
				var c := img.get_pixel(x, y)
				lumas.append(0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b)
	if lumas.is_empty():
		return 0.0
	lumas.sort()
	return lumas[lumas.size() / 2]
