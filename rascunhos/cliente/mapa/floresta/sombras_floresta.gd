extends SubViewport
## sombras_floresta.gd — Ordem 43. O FORNO VIVO das sombras do mapa da floresta.
##
## A Ordem 38 cozia as sombras UMA vez no mapa do chão (canais R e B), para a luz fixa da tarde.
## Com o ciclo do dia a luz anda: este SubViewport volta a pintar esses dois canais sempre que a
## direcção da luz muda — a sombra do relevo (shaders/sombra_relevo.gdshader, 1 quadrado) e os
## carimbos de tudo o que faz sombra (shaders/sombra_carimbo.gdshader, 1 malha) — vistos de
## cima, em projecção ortogonal, no mesmo enquadramento do mapa do chão ([-meio, meio]²).
## A textura (textura()) entra nos shaders como `mapa_sombra` (luz_floresta.gdshaderinc).
## Custo: 2 chamadas de desenho num alvo de LADO², só nos quadros em que a luz mudou.

const SH_CARIMBO := preload("res://mapa/floresta/shaders/sombra_carimbo.gdshader")
const SH_RELEVO := preload("res://mapa/floresta/shaders/sombra_relevo.gdshader")
const LADO := 768
## A luz tem de rodar mais do que isto (graus) para o forno voltar a pintar.
const LIMIAR_GRAUS := 0.04

var lancadores := 0
var pinturas := 0

var _mat_carimbo := ShaderMaterial.new()
var _mat_relevo := ShaderMaterial.new()
var _dir := Vector3.ZERO


## `dados`: 9 números por lançador (x, altura acima do chão, z, raio de través, força, a, b, c,
## só-copas). `alturas`: o relevo em [-meio, meio]² (n×n, metros).
func montar(dados: PackedFloat32Array, alturas: PackedFloat32Array, n_alturas: int, meio: float) -> void:
	name = "ForroSombras"
	size = Vector2i(LADO, LADO)
	own_world_3d = true
	transparent_bg = false
	msaa_3d = Viewport.MSAA_DISABLED
	positional_shadow_atlas_size = 0
	render_target_update_mode = SubViewport.UPDATE_ONCE
	var amb := Environment.new()
	amb.background_mode = Environment.BG_COLOR
	amb.background_color = Color.WHITE
	amb.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	amb.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.0 * meio
	cam.near = 1.0
	cam.far = 400.0
	cam.environment = amb
	add_child(cam)
	# de cima, com o norte (-Z) para o cimo da imagem: a textura fica como o mapa do chão
	cam.look_at_from_position(Vector3(0.0, 200.0, 0.0), Vector3.ZERO, Vector3(0.0, 0.0, -1.0))
	cam.make_current()
	# ---- o fundo: a sombra do relevo
	var img := Image.create_from_data(n_alturas, n_alturas, false, Image.FORMAT_RF, alturas.to_byte_array())
	img.convert(Image.FORMAT_RH)
	_mat_relevo.shader = SH_RELEVO
	_mat_relevo.set_shader_parameter("alturas", ImageTexture.create_from_image(img))
	_mat_relevo.set_shader_parameter("meio", meio)
	_mat_relevo.render_priority = -1
	var plano := PlaneMesh.new()
	plano.size = Vector2(2.0 * meio, 2.0 * meio)
	var mi_relevo := MeshInstance3D.new()
	mi_relevo.mesh = plano
	mi_relevo.material_override = _mat_relevo
	mi_relevo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi_relevo)
	# ---- os carimbos: 4 vértices por lançador
	lancadores = dados.size() / 9
	if lancadores > 0:
		var v := PackedVector3Array()
		var uv2 := PackedVector2Array()
		var c0 := PackedFloat32Array()
		var idx := PackedInt32Array()
		v.resize(lancadores * 4)
		uv2.resize(lancadores * 4)
		c0.resize(lancadores * 16)
		idx.resize(lancadores * 6)
		for i in lancadores:
			var o := i * 9
			var p := Vector3(dados[o], dados[o + 1], dados[o + 2])
			var u := Vector2(dados[o + 3], dados[o + 4])
			for k in 4:
				v[i * 4 + k] = p
				uv2[i * 4 + k] = u
				var q := (i * 4 + k) * 4
				c0[q] = dados[o + 5]
				c0[q + 1] = dados[o + 6]
				c0[q + 2] = dados[o + 7]
				c0[q + 3] = dados[o + 8]
			var b := i * 4
			var t := i * 6
			idx[t] = b
			idx[t + 1] = b + 1
			idx[t + 2] = b + 2
			idx[t + 3] = b + 1
			idx[t + 4] = b + 3
			idx[t + 5] = b + 2
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_TEX_UV2] = uv2
		arr[Mesh.ARRAY_CUSTOM0] = c0
		arr[Mesh.ARRAY_INDEX] = idx
		var malha := ArrayMesh.new()
		malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr, [], {},
			Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT)
		_mat_carimbo.shader = SH_CARIMBO
		var mi := MeshInstance3D.new()
		mi.mesh = malha
		mi.material_override = _mat_carimbo
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.custom_aabb = AABB(Vector3(-meio, -1.0, -meio), Vector3(2.0 * meio, 2.0, 2.0 * meio))
		add_child(mi)


func textura() -> Texture2D:
	return get_texture()


## A direcção PARA a luz (sol ou lua). Só volta a pintar se ela mudou.
func definir_luz(dir: Vector3) -> void:
	dir = dir.normalized()
	if _dir != Vector3.ZERO and rad_to_deg(_dir.angle_to(dir)) < LIMIAR_GRAUS:
		return
	_dir = dir
	_mat_carimbo.set_shader_parameter("dir_luz", dir)
	_mat_relevo.set_shader_parameter("dir_luz", dir)
	render_target_update_mode = SubViewport.UPDATE_ONCE
	pinturas += 1
