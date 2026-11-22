extends SceneTree
## Ordem CAIXA-RELATO-CORRECOES-2 (B4 da conferência da CAIXA-RELATO-CORRECOES) — o MÉTODO da comparação ao píxel das
## capturas, cometido para que os números se reproduzam.
##
## Para cada par de capturas com o mesmo nome (1-entrou-dinamica.png … 5-reentrou.png) em <pasta-a> e <pasta-b>: a
## percentagem de píxeis em que ALGUM canal R, G ou B difere mais do que o limiar (por omissão 0,06, na escala 0–1;
## o alfa não conta) — `--metodo=canal`, o por omissão, o da conferência. As duas imagens têm de ter o mesmo tamanho
## (senão: «tamanhos diferentes», código 1).
##
## `--metodo=soma` reproduz o método NÃO COMETIDO do executor da CAIXA-RELATO-CORRECOES (o seu tmp/comparar.gd): conta
## um píxel quando a SOMA |ΔR|+|ΔG|+|ΔB| passa o limiar — é um critério mais apertado, e foi dele que saíram os
## «54–65 %» e «7–38 %» que a conferência não reproduziu. Fica aqui só para que essa diferença se possa ver.
##
## Correr (na raiz do repo; não precisa de projecto nem de ecrã):
##   godot --headless -s provas/ordem-caixa-relato/ferramentas/comparar_capturas.gd -- <pasta-a> <pasta-b> [--limiar=0.06] [--metodo=canal|soma]
## Os pares que entraram no ESTADO-FINAL da CAIXA-RELATO-CORRECOES (§4.2) e no README (B5):
##   HUD:      provas/ordem-caixa-hud-jogadora/cliente   provas/ordem-caixa-relato/correcoes/cliente-hud
##   MANEQUIM: provas/ordem-caixa-manequim/cliente       provas/ordem-caixa-relato/correcoes/cliente-manequim

const NOMES := ["1-entrou-dinamica.png", "2-iniciativa.png", "3-desligada.png", "4-religada-avancou.png", "5-reentrou.png"]


func _init() -> void:
	var pastas: Array = []
	var limiar := 0.06
	var metodo := "canal"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--limiar="):
			limiar = float(a.trim_prefix("--limiar="))
		elif a.begins_with("--metodo="):
			metodo = a.trim_prefix("--metodo=")
		else:
			pastas.append(a)
	if pastas.size() != 2 or not (metodo in ["canal", "soma"]):
		printerr("uso: godot --headless -s comparar_capturas.gd -- <pasta-a> <pasta-b> [--limiar=0.06] [--metodo=canal|soma]")
		quit(2)
		return
	print("comparar capturas (%s > %.3f): %s ↔ %s" % ["algum canal RGB" if metodo == "canal" else "soma |ΔR|+|ΔG|+|ΔB|", limiar, pastas[0], pastas[1]])
	var rc := 0
	var pcts: Array = []
	for n in NOMES:
		var ia := Image.load_from_file(str(pastas[0]).path_join(n))
		var ib := Image.load_from_file(str(pastas[1]).path_join(n))
		if ia == null or ib == null:
			print("  %-24s em falta" % n)
			rc = 1
			continue
		if ia.get_size() != ib.get_size():
			print("  %-24s tamanhos diferentes (%s ≠ %s)" % [n, ia.get_size(), ib.get_size()])
			rc = 1
			continue
		ia.convert(Image.FORMAT_RGBA8)
		ib.convert(Image.FORMAT_RGBA8)
		var da := ia.get_data()
		var db := ib.get_data()
		var lim := limiar * 255.0  # o limiar em níveis de 0–255 (conta se a diferença for MAIOR)
		var diferentes := 0
		var total := ia.get_width() * ia.get_height()
		for i in range(0, da.size(), 4):
			var dr := absi(da[i] - db[i])
			var dg := absi(da[i + 1] - db[i + 1])
			var dbl := absi(da[i + 2] - db[i + 2])
			if metodo == "canal":
				if dr > lim or dg > lim or dbl > lim:
					diferentes += 1
			elif dr + dg + dbl > lim:
				diferentes += 1
		var pct := 100.0 * diferentes / total
		pcts.append(pct)
		print("  %-24s %6.1f %%  (%d de %d píxeis, %d×%d)" % [n, pct, diferentes, total, ia.get_width(), ia.get_height()])
	if not pcts.is_empty():
		print("  intervalo: %.1f–%.1f %%" % [pcts.min(), pcts.max()])
	quit(rc)
