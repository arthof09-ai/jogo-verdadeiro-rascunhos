@tool
extends EditorScript
## gerar_rampas.gd — Assimilação, missão V1.1 (Plano B v1.1, B2.1 item 2)
##
## Gera as rampas PNG 256x1 das 7 famílias, na mesma pasta deste script.
## Como correr: abrir no Script Editor e usar File > Run (Ctrl+Shift+X).
##
## >>> PROVISÓRIO até ao guia V0.1 (Muse). Os valores abaixo são um andaime a partir da
## >>> repintura Arcane aprovada (RV2/RV1/AV2) e serão substituídos pelas rampas da V0.1.
##
## O que a rampa significa (ver toon_pintado.gdshader):
##   x = N·L remapeado para 0..1 (0,5 = terminador), deslocado pela máscara de pincelada.
##   O valor RGB é um FATOR de mistura por canal entre a sombra colorida (0) e a luz (1).
##   Não é cor de albedo. Canais diferentes no meio da rampa = faixa quente/fria no terminador.
##   Ex.: na pele, o vermelho "acende" antes do verde e do azul -> terminador avermelhado.
##
## Importação recomendada dos PNG: Lossless, sem mipmaps (o shader já usa repeat_disable).

const PROVISORIO := true
const LARGURA := 256

## Paradas [posição 0..1, fator em hex]. Entre paradas: smoothstep (transição pintada, sem degraus).
const FAMILIAS := {
	"pele": [
		[0.00, "#000000"], [0.40, "#000000"], [0.50, "#8C3A2E"],
		[0.60, "#E6B49A"], [0.72, "#FFFFFF"], [1.00, "#FFFFFF"],
	],
	"tecido": [
		[0.00, "#000000"], [0.45, "#000000"], [0.55, "#B89C90"],
		[0.64, "#FFFFFF"], [1.00, "#FFFFFF"],
	],
	"metal": [
		[0.00, "#000000"], [0.48, "#000000"], [0.53, "#8E98AE"],
		[0.68, "#C8CEDC"], [0.82, "#FFFFFF"], [1.00, "#FFFFFF"],
	],
	"pedra": [
		[0.00, "#000000"], [0.38, "#000000"], [0.52, "#76708A"],
		[0.66, "#E0DCD6"], [0.80, "#FFFFFF"], [1.00, "#FFFFFF"],
	],
	"casca": [
		[0.00, "#000000"], [0.42, "#000000"], [0.54, "#8A6A50"],
		[0.66, "#E8DCCB"], [0.78, "#FFFFFF"], [1.00, "#FFFFFF"],
	],
	"folhagem": [
		[0.00, "#000000"], [0.30, "#000000"], [0.50, "#7A9A4A"],
		[0.68, "#D8EAB0"], [0.85, "#FFFFFF"], [1.00, "#FFFFFF"],
	],
	"chao": [
		[0.00, "#000000"], [0.35, "#000000"], [0.55, "#A09080"],
		[0.75, "#FFFFFF"], [1.00, "#FFFFFF"],
	],
}


func _run() -> void:
	var pasta: String = get_script().resource_path.get_base_dir()
	var feitos := 0
	for nome in FAMILIAS:
		var img := _gerar(FAMILIAS[nome])
		var caminho := pasta.path_join("rampa_%s.png" % nome)
		var erro := img.save_png(caminho)
		if erro == OK:
			feitos += 1
			print("[rampas] ", caminho)
		else:
			push_error("[rampas] falhou %s (erro %d)" % [caminho, erro])
	EditorInterface.get_resource_filesystem().scan()
	print("[rampas] %d de %d rampas geradas. PROVISÓRIO até ao guia V0.1." % [feitos, FAMILIAS.size()])


func _gerar(paradas: Array) -> Image:
	var img := Image.create_empty(LARGURA, 1, false, Image.FORMAT_RGBA8)
	for px in LARGURA:
		var x := (float(px) + 0.5) / float(LARGURA)
		img.set_pixel(px, 0, _amostrar(paradas, x))
	return img


func _amostrar(paradas: Array, x: float) -> Color:
	if x <= paradas[0][0]:
		return Color.html(paradas[0][1])
	for i in range(paradas.size() - 1):
		var a: Array = paradas[i]
		var b: Array = paradas[i + 1]
		if x <= b[0]:
			var t := smoothstep(a[0], b[0], x)
			# Interpolação direta nos valores (são fatores, não cores sRGB).
			return Color.html(a[1]).lerp(Color.html(b[1]), t)
	return Color.html(paradas[paradas.size() - 1][1])
