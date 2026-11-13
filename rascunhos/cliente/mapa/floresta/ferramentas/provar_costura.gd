extends SceneTree
## provar_costura.gd — Ordem 37. A PROVA DA COR ÚNICA, em números: esconde a arena e o anel
## próximo, olha para os 4 rumos e lê a coluna central do ecrã, de cima para baixo, através da
## base do anel longe (que é pintada com COR_HORIZONTE) até ao céu por baixo dela (cuja faixa
## baixa é COR_HORIZONTE). Se a tinta, a névoa e o céu forem a MESMA cor, não há degrau.
##
##   godot --path cliente --resolution 1280x720 -s res://mapa/floresta/ferramentas/provar_costura.gd
##
## Precisa de janela (GPU). Sai com 0 se o maior degrau for ≤ 2/255 por canal.

const Paleta := preload("res://mapa/floresta/paleta_floresta.gd")
const CENA := "res://mapa/floresta/campo_floresta.tscn"


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _correr() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(1920, 1080)
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var cena: Node3D = (load(CENA) as PackedScene).instantiate()
	cena.set("mostrar_medicao", false)
	vp.add_child(cena)
	for i in 8:
		await process_frame
	cena.call("so_fundo", true)
	(cena.get_node("Fundo/AnelPerto") as Node3D).visible = false
	var alvo := Paleta.COR_HORIZONTE
	print("[costura] COR_HORIZONTE = #%s (%d %d %d)" % [alvo.to_html(false), alvo.r8, alvo.g8, alvo.b8])
	var pior := 0
	for vista in 4:
		cena.call("ir_para_vista", vista)
		for i in 4:
			await process_frame
		var img := vp.get_texture().get_image()
		var linha := ""
		var antes := Color()
		var degrau := 0
		var desvio := 0
		# da base das capas (y≈700) até ao céu por baixo delas (y≈1000), de 20 em 20 píxeis
		for y in range(700, 1001, 20):
			var c := img.get_pixel(960, y)
			linha += "%d:#%s " % [y, c.to_html(false)]
			if y > 700:
				degrau = maxi(degrau, maxi(absi(c.r8 - antes.r8), maxi(absi(c.g8 - antes.g8), absi(c.b8 - antes.b8))))
			if y >= 860:
				desvio = maxi(desvio, maxi(absi(c.r8 - alvo.r8), maxi(absi(c.g8 - alvo.g8), absi(c.b8 - alvo.b8))))
			antes = c
		print("[costura] vista %d: %s" % [vista, linha])
		print("[costura] vista %d: maior degrau entre amostras = %d/255 · maior desvio à COR_HORIZONTE abaixo de y=860 = %d/255" % [vista, degrau, desvio])
		pior = maxi(pior, desvio)
	print("[costura] RESULTADO: pior desvio = %d/255 (%s)" % [pior, "SEM COSTURA" if pior <= 2 else "COSTURA ABERTA"])
	quit(0 if pior <= 2 else 1)
