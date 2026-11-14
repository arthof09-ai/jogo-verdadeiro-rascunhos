extends SceneTree
## sonda_zona.gd — Ordem 42. Mede o que o mapa da floresta tem DENTRO da zona jogável do jogo
## (W × H casas de casaM, centrada no centro da arena do mapa): o relevo (mín./máx., maior degrau
## numa casa) e as casas que o MAPA bloqueia (tronco, rocha, menir, água, escarpa).
##   godot --headless --path cliente -s res://cenas/arena/ferramentas/sonda_zona.gd -- --w=20 --h=20
const CENA := "res://mapa/floresta/campo_floresta.tscn"
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const Grelha := preload("res://mapa/floresta/grelha_floresta.gd")

func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)

func _correr() -> void:
	var w := 20
	var h := 20
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--w="): w = int(a.trim_prefix("--w="))
		if a.begins_with("--h="): h = int(a.trim_prefix("--h="))
	var limpar := OS.get_cmdline_user_args().has("--limpar")
	var mapa = (load(CENA) as PackedScene).instantiate()
	mapa.mostrar_medicao = false
	if limpar:  # como a arena faz: a zona jogável livre do que o servidor não conhece
		mapa.zona_jogo = Rect2(-w * 0.75, -h * 0.75, w * 1.5, h * 1.5)
	root.add_child(mapa)
	await process_frame
	var g = mapa.grelha
	var c0 := Vector2i((Grelha.LADO - w) / 2, (Grelha.LADO - h) / 2)
	var lo := INF
	var hi := -INF
	var degrau_max := 0.0
	var bloq: Array = []
	for l in h:
		for c in w:
			var casa := c0 + Vector2i(c, l)
			var p: Vector3 = Grelha.centro(casa)
			lo = minf(lo, p.y); hi = maxf(hi, p.y)
			degrau_max = maxf(degrau_max, Grelha.degrau(casa))
			if g.bloqueada(casa):
				bloq.append("%s->%s(%s)" % [Vector2i(c, l), casa, g.motivo_bloqueio(casa)])
	print("zona %dx%d: casas do mapa %s..%s" % [w, h, c0, c0 + Vector2i(w - 1, h - 1)])
	print("relevo: min %.2f max %.2f (desnivel %.2f m), maior degrau numa casa %.2f m" % [lo, hi, hi - lo, degrau_max])
	print("bloqueadas pelo mapa: %d" % bloq.size())
	for b in bloq: print("  ", b)
	quit(0)
