extends SceneTree
## gerar_pincel.gd — Assimilação, kit de arte (Ordem 65): o PINCEL da casa, pintado por programa.
##
## Gera, na mesma pasta deste script, as duas texturas em cinzento (8 bits, 0,5 = neutro):
##
##   pincel_mascara.png  256×256, repete nos dois eixos. A MÁSCARA DE PINCELADA: pinceladas curtas,
##                       com cerdas. É o «pincel» do toon_pintado e da folhagem (quebra o terminador
##                       e a borda da sombra) e a «mascara_pincel» do céu (as cerdas na borda dos tons).
##   ceu_pinceladas.png  1024×512, panorâmica (a largura dá a volta ao horizonte e repete; a altura
##                       vai do zénite ao nadir). A TEXTURA DE PINCELADAS DO CÉU: pinceladas largas e
##                       deitadas, mais gordas para o alto. É a «pinceladas» do ceu_pintado.
##
##   godot --headless --path cliente -s res://arte/pincel/gerar_pincel.gd
##
## Os dois PNG estão na árvore; só é preciso voltar a correr isto para mudar o traço. A semente é
## fixa: o resultado é sempre o mesmo, byte a byte.
##
## Como se pinta: cada pincelada é um rectângulo rodado e ligeiramente curvo, dividido em CERDAS ao
## comprido. Cada cerda tem o seu tom, começa e acaba no seu sítio (pontas esfiapadas) e vai ficando
## sem tinta para o fim (pincel seco). As pinceladas tapam-se umas às outras, como tinta.

const SEMENTE := 6501


func _init() -> void:
	var pasta: String = (get_script() as Script).resource_path.get_base_dir()
	var falhas := 0
	falhas += _guardar(mascara(), pasta.path_join("pincel_mascara.png"))
	falhas += _guardar(ceu(), pasta.path_join("ceu_pinceladas.png"))
	quit(1 if falhas > 0 else 0)


func _guardar(img: Image, caminho: String) -> int:
	var erro := img.save_png(ProjectSettings.globalize_path(caminho))
	if erro != OK:
		printerr("[pincel] falhou %s (erro %d)" % [caminho, erro])
		return 1
	print("[pincel] %s (%d×%d)" % [caminho, img.get_width(), img.get_height()])
	return 0


## A máscara de pincelada: 256×256, repete nos dois eixos.
static func mascara() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMENTE
	var larg := 256
	var alt := 256
	var tela := _tela(larg, alt)
	for i in 300:
		var comp := rng.randf_range(34.0, 96.0)
		var esp := rng.randf_range(6.0, 19.0)
		# uma direcção dominante (a mão do pintor), com desvios
		var ang := -0.52 + rng.randfn(0.0, 0.42)
		_pincelada(tela, larg, alt, true, rng, rng.randf() * larg, rng.randf() * alt, ang, comp, esp,
			0.5 + rng.randf_range(-0.40, 0.40), rng.randf_range(0.6, 0.95))
	return _imagem(tela, larg, alt)


## As pinceladas do céu: 1024×512, panorâmica (repete só na largura).
static func ceu() -> Image:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEMENTE + 1
	var larg := 1024
	var alt := 512
	var tela := _tela(larg, alt)
	for i in 560:
		var cy := rng.randf() * alt
		# 0 no horizonte (a meio da altura), 1 no zénite e no nadir: para o alto, pinceladas mais gordas
		var alto := absf(cy / alt - 0.5) * 2.0
		var comp := rng.randf_range(130.0, 420.0) * lerpf(0.8, 1.25, alto)
		var esp := rng.randf_range(9.0, 30.0) * lerpf(0.75, 1.7, alto)
		var ang := rng.randfn(0.0, 0.075)
		_pincelada(tela, larg, alt, false, rng, rng.randf() * larg, cy, ang, comp, esp,
			0.5 + rng.randf_range(-0.42, 0.42), rng.randf_range(0.65, 0.97))
	return _imagem(tela, larg, alt)


static func _tela(larg: int, alt: int) -> PackedFloat32Array:
	var tela := PackedFloat32Array()
	tela.resize(larg * alt)
	tela.fill(0.5)
	return tela


## Passa a tela a imagem de 8 bits, com a média acertada em 0,5 (o neutro dos shaders).
static func _imagem(tela: PackedFloat32Array, larg: int, alt: int) -> Image:
	var soma := 0.0
	for v in tela:
		soma += v
	var desvio := 0.5 - soma / float(tela.size())
	var dados := PackedByteArray()
	dados.resize(tela.size())
	for i in tela.size():
		dados[i] = clampi(int(round((tela[i] + desvio) * 255.0)), 0, 255)
	return Image.create_from_data(larg, alt, false, Image.FORMAT_L8, dados)


## Uma pincelada: centro (cx, cy), ângulo, comprimento e espessura em píxeis, tom 0..1, opacidade.
static func _pincelada(tela: PackedFloat32Array, larg: int, alt: int, repete_y: bool,
		rng: RandomNumberGenerator, cx: float, cy: float, ang: float, comp: float, esp: float,
		tom: float, opac: float) -> void:
	var n_cerdas := maxi(3, int(esp / 2.2))
	var c_tom := PackedFloat32Array()
	var c_ini := PackedFloat32Array()
	var c_fim := PackedFloat32Array()
	var c_seco := PackedFloat32Array()
	for k in n_cerdas:
		c_tom.append(rng.randf_range(-0.07, 0.07))
		c_ini.append(rng.randf_range(0.0, 0.10))
		c_fim.append(1.0 - rng.randf_range(0.0, 0.26))
		c_seco.append(rng.randf_range(0.0, 1.0))
	var falhas := PackedFloat32Array()  # o pincel seco: onde a cerda larga menos tinta
	for k in 64:
		falhas.append(rng.randf())
	var curva := rng.randf_range(-0.22, 0.22)
	var co := cos(ang)
	var si := sin(ang)
	var meio_c := comp * 0.5
	var meio_e := esp * 0.5
	var folga := absf(curva) * comp * 0.25 + 1.0
	var rx := int(ceil(absf(co) * meio_c + absf(si) * (meio_e + folga))) + 1
	var ry := int(ceil(absf(si) * meio_c + absf(co) * (meio_e + folga))) + 1
	var x0 := int(floor(cx))
	var y0 := int(floor(cy))
	for dy in range(-ry, ry + 1):
		var py := y0 + dy
		if repete_y:
			py = posmod(py, alt)
		elif py < 0 or py >= alt:
			continue
		var fy := float(y0 + dy) + 0.5 - cy
		for dx in range(-rx, rx + 1):
			var fx := float(x0 + dx) + 0.5 - cx
			var u := fx * co + fy * si
			if absf(u) > meio_c:
				continue
			var s := u / comp + 0.5  # 0 no início da pincelada, 1 no fim
			var v := -fx * si + fy * co - curva * (s - 0.5) * (s - 0.5) * comp
			if absf(v) > meio_e:
				continue
			var k := mini(n_cerdas - 1, int((v / esp + 0.5) * n_cerdas))
			var a := smoothstep(c_ini[k], c_ini[k] + 0.05, s) * (1.0 - smoothstep(c_fim[k] - 0.07, c_fim[k], s))
			if a <= 0.0:
				continue
			a *= smoothstep(0.0, 0.14, 0.5 - absf(v) / esp)  # a borda de lado
			var seco := falhas[(k * 7 + int(u * 0.33 + 4096.0)) & 63]
			a *= 1.0 - s * c_seco[k] * seco * 0.85
			var idx := py * larg + posmod(x0 + dx, larg)
			tela[idx] = lerpf(tela[idx], tom + c_tom[k], a * opac)
