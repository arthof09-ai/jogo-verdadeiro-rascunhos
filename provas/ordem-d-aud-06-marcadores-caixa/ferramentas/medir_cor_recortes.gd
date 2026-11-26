extends SceneTree
## ORDEM-D-AUD-06: mede a cor de alvo nos recortes ×3 das capturas (fora do jogo; não entra no CI).
##   godot --headless -s <este>.gd -- <recorte.png> [...]
## Para cada recorte (ampliado ×3 por vizinho mais próximo: cada píxel da captura vale 9), conta os píxeis da captura:
##   vivo        r > 0,70, g < 0,45, b < 0,45 e r − g > 0,35 (o vermelho do marcador sem tinta de água);
##   avermelhado r − g > 0,15 e r − b > 0,15 (qualquer vermelho, também o tingido pela água);
## e a vermelhidão máxima, max(r − max(g, b)).
func _init() -> void:
	for f in OS.get_cmdline_user_args():
		var img := Image.load_from_file(f)
		var vivo := 0
		var averm := 0
		var mx := 0.0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.r > 0.7 and c.g < 0.45 and c.b < 0.45 and c.r - c.g > 0.35:
					vivo += 1
				if c.r - c.g > 0.15 and c.r - c.b > 0.15:
					averm += 1
				mx = maxf(mx, c.r - maxf(c.g, c.b))
		print("%s | vivo %d px | avermelhado %d px | vermelhidão máx %.2f" % [f.get_file(), vivo / 9, averm / 9, mx])
	quit()
