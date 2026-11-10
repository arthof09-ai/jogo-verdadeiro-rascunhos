extends RefCounted
## Nomes das figuras legíveis com figuras juntas (ordem 15 do CM-000009, parte F; 2026-11-10).
##
## Os nomes são Label3D por cima de cada figura, todos à mesma altura: com figuras vizinhas, ou umas atrás das outras
## na câmara Fixa, os textos caem uns em cima dos outros (fotos 1 e 3 da arena do Mestre). Isto arruma-os NO ECRÃ:
## projecta a caixa de cada nome pela câmara activa e, quando duas se tocam, sobe a de trás (a mais acima no ecrã,
## que é a mais longe) até ficar por cima da outra, com uma folga. Só mexe na altura do Label3D; a figura, a casa e
## a mecânica não mudam. Corre a cada quadro (a câmara mexe-se: 360°, panorama, zoom, câmara livre).
##
## A altura de base de cada nome fica no meta "nome_base_y" (posta na primeira vez); quem muda a altura de base
## (ex.: outra figura) deve actualizar o meta.

const META_BASE := "nome_base_y"
## Folga entre dois nomes, em px do ecrã.
const FOLGA_PX := 4.0
## Teto de voltas por nome (cada volta passa por cima de um nome que lhe tocava).
const MAX_VOLTAS := 32


## Arruma os `rotulos` (Label3D) para a câmara `cam`. Devolve as caixas finais no ecrã (Rect2 por rótulo arrumado),
## na mesma ordem em que foram arrumados (para os testes).
static func arrumar(rotulos: Array, cam: Camera3D) -> Array[Rect2]:
	var itens: Array = []
	for r in rotulos:
		var l := r as Label3D
		if l == null or not is_instance_valid(l) or not l.is_inside_tree():
			continue
		if not l.has_meta(META_BASE):
			l.set_meta(META_BASE, l.position.y)
		var base_y: float = l.get_meta(META_BASE)
		if cam == null or not l.is_visible_in_tree() or l.text.strip_edges() == "":
			l.position.y = base_y
			continue
		var pai := l.get_parent() as Node3D
		var ancora: Vector3 = (pai.global_transform if pai != null else Transform3D.IDENTITY) * Vector3(l.position.x, base_y, l.position.z)
		if cam.is_position_behind(ancora):
			l.position.y = base_y
			continue
		var p := cam.unproject_position(ancora)
		# Px do ecrã por unidade do mundo, para cima (o eixo em que o nome sobe) e na direcção da câmara (o
		# billboard do nome está virado para ela).
		var px_cima := absf(cam.unproject_position(ancora + Vector3.UP).y - p.y)
		var px_dir := cam.unproject_position(ancora + cam.global_basis.x).distance_to(p)
		var px_cam_cima := cam.unproject_position(ancora + cam.global_basis.y).distance_to(p)
		if px_cima < 0.001 or px_dir < 0.001:
			l.position.y = base_y
			continue
		var tam := _tamanho_mundo(l)
		var caixa := Rect2(p - Vector2(tam.x * px_dir, tam.y * px_cam_cima) * 0.5, Vector2(tam.x * px_dir, tam.y * px_cam_cima))
		itens.append({"l": l, "base": base_y, "caixa": caixa, "px_cima": px_cima, "nome": str(l.get_path())})
	# Primeiro os de baixo no ecrã (os mais perto da câmara ficam onde estão); empate: o caminho do nó (estável).
	itens.sort_custom(func(a, b):
		var ya: float = (a["caixa"] as Rect2).position.y
		var yb: float = (b["caixa"] as Rect2).position.y
		return ya > yb if absf(ya - yb) > 0.01 else str(a["nome"]) < str(b["nome"]))
	var postas: Array[Rect2] = []
	for it in itens:
		var caixa: Rect2 = it["caixa"]
		var y0 := caixa.position.y
		for _volta in MAX_VOLTAS:
			var bate := false
			for outra in postas:
				if caixa.grow(FOLGA_PX * 0.5).intersects(outra.grow(FOLGA_PX * 0.5)):
					caixa.position.y = outra.position.y - caixa.size.y - FOLGA_PX
					bate = true
			if not bate:
				break
		postas.append(caixa)
		var l: Label3D = it["l"]
		l.position.y = float(it["base"]) + (y0 - caixa.position.y) / float(it["px_cima"])
	return postas


## Largura e altura do texto do nome, em unidades do mundo (o Label3D mede font_size × pixel_size por px de letra).
static func _tamanho_mundo(l: Label3D) -> Vector2:
	var fonte: Font = l.font if l.font != null else ThemeDB.fallback_font
	var px := fonte.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, l.font_size)
	var contorno := float(l.outline_size)
	return Vector2(px.x + contorno, maxf(px.y, fonte.get_height(l.font_size)) + contorno) * l.pixel_size
