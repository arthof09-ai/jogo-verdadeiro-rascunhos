extends SceneTree
## gerar_rampas.gd — Assimilação, kit de arte (missão V1.1; fechado na Ordem 65).
##
## Gera as rampas PNG 256x1 das 7 famílias, na mesma pasta deste script. Corre SEM janela:
##
##   godot --headless --path cliente -s res://arte/rampas/gerar_rampas.gd
##
## Os 7 PNG estão na árvore; só é preciso voltar a correr isto se as tabelas abaixo mudarem
## (o resultado é sempre o mesmo, byte a byte). Depois de gerar, o Godot importa-os com as
## definições dos .png.import que estão ao lado (Lossless, sem mipmaps, sem «detect 3D»).
##
## O que a rampa significa (ver toon_pintado.gdshader):
##   x = N·L remapeado para 0..1 (0,5 = terminador), deslocado pela máscara de pincelada.
##   O valor RGB é um FATOR de mistura por canal entre a sombra colorida (0) e a luz (1).
##   Não é cor de albedo. Canais diferentes num patamar = faixa quente/fria nessa zona da luz.
##   Ex.: na pele, o vermelho "acende" antes do verde e do azul -> terminador avermelhado.
##
## A FORMA (Ordem 65): a luz parte-se em DEGRAUS — patamares de valor constante, separados por
## bordas curtas. A borda nunca é de 1 px: tem a largura «borda» da família (pintada, sem serrilha)
## e é a máscara de pincelada que a quebra no ecrã. As TINTAS dos patamares são as da repintura
## aprovada (RV2/RV1/AV2) que já vinham no andaime desta tabela; a ordem dos patamares é sempre
## sombra -> terminador (a tinta da família) -> meia-tinta -> luz.

const LARGURA := 256

## Por família: «borda» = largura da passagem entre patamares (em x, 0..1) e «patamares» =
## [início, fator em hex]; cada patamar vale desde o seu início até ao início do seguinte.
const FAMILIAS := {
	# Pele: bordas macias; o terminador é vermelho (o sangue por baixo), a meia-tinta é quente.
	"pele": {"borda": 0.035, "patamares": [
		[0.00, "#000000"], [0.455, "#8C3A2E"], [0.555, "#E6B49A"], [0.715, "#FFFFFF"],
	]},
	# Tecido: dois degraus e uma meia-tinta larga e neutra (o pano espalha a luz).
	"tecido": {"borda": 0.028, "patamares": [
		[0.00, "#000000"], [0.455, "#B89C90"], [0.635, "#FFFFFF"],
	]},
	# Metal: bordas duras, quatro degraus frios e um reflexo curto dentro da sombra.
	"metal": {"borda": 0.012, "patamares": [
		[0.00, "#000000"], [0.14, "#232836"], [0.27, "#000000"], [0.495, "#8E98AE"],
		[0.60, "#C8CEDC"], [0.815, "#FFFFFF"],
	]},
	# Pedra: terminador frio (violeta), meia-tinta de cal, degraus firmes.
	"pedra": {"borda": 0.020, "patamares": [
		[0.00, "#000000"], [0.40, "#76708A"], [0.545, "#E0DCD6"], [0.76, "#FFFFFF"],
	]},
	# Casca: terminador castanho quente, meia-tinta de madeira clara.
	"casca": {"borda": 0.026, "patamares": [
		[0.00, "#000000"], [0.435, "#8A6A50"], [0.565, "#E8DCCB"], [0.755, "#FFFFFF"],
	]},
	# Folhagem: a luz atravessa a folha — o verde-amarelo acende cedo e os patamares são largos.
	"folhagem": {"borda": 0.032, "patamares": [
		[0.00, "#000000"], [0.31, "#7A9A4A"], [0.515, "#D8EAB0"], [0.74, "#FFFFFF"],
	]},
	# Chão: quase plano, por isso um só degrau largo e macio (a hora do dia escolhe o patamar).
	"chao": {"borda": 0.060, "patamares": [
		[0.00, "#000000"], [0.375, "#A09080"], [0.64, "#FFFFFF"],
	]},
}


func _init() -> void:
	var pasta: String = (get_script() as Script).resource_path.get_base_dir()
	var feitos := 0
	for nome in FAMILIAS:
		var img := gerar(FAMILIAS[nome])
		var caminho := ProjectSettings.globalize_path(pasta.path_join("rampa_%s.png" % nome))
		var erro := img.save_png(caminho)
		if erro == OK:
			feitos += 1
			print("[rampas] ", caminho)
		else:
			printerr("[rampas] falhou %s (erro %d)" % [caminho, erro])
	print("[rampas] %d de %d rampas geradas." % [feitos, FAMILIAS.size()])
	quit(0 if feitos == FAMILIAS.size() else 1)


static func gerar(familia: Dictionary) -> Image:
	var img := Image.create_empty(LARGURA, 1, false, Image.FORMAT_RGB8)
	for px in LARGURA:
		var x := (float(px) + 0.5) / float(LARGURA)
		img.set_pixel(px, 0, amostrar(familia, x))
	return img


## O fator da rampa em x: patamares constantes; à volta de cada início, uma borda smoothstep.
static func amostrar(familia: Dictionary, x: float) -> Color:
	var patamares: Array = familia["patamares"]
	var meia: float = float(familia["borda"]) * 0.5
	# Interpolação direta nos valores (são fatores, não cores sRGB).
	var cor := Color.html(patamares[0][1])
	for i in range(1, patamares.size()):
		var inicio: float = patamares[i][0]
		cor = cor.lerp(Color.html(patamares[i][1]), smoothstep(inicio - meia, inicio + meia, x))
	return cor
