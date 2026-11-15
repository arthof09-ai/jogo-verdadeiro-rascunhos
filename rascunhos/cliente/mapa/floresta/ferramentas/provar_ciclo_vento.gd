extends SceneTree
## provar_ciclo_vento.gd — Ordem 43. A MEDIÇÃO EM NÚMEROS do ciclo do dia e do vento do mundo
## (sem render: corre com --headless).
##
##   godot --headless --path cliente -s res://mapa/floresta/ferramentas/provar_ciclo_vento.gd
##
## Grava capturas/ciclo43/curvas_ciclo_vento.json e imprime o resumo:
##   · a CURVA DO VENTO por hora: força-base, rumo do dia (de onde sopra), e — com o vento a correr
##     120 s em tempo real a cada hora — a força mínima / média / máxima, o nº de rajadas (subidas acima
##     de 1,2 × a força média da hora, com histerese), o intervalo entre rajadas e o desvio da direcção (desvio-padrão
##     e máximo, em graus, contra o rumo do dia);
##   · a DERIVA da direcção: graus por hora, hora a hora, e a volta total em 24 h;
##   · os TEMPOS DAS TRANSIÇÕES: nascer/pôr do sol e da lua (elevação 0°), e quanto dura cada
##     passagem (do crepúsculo astronómico −18° ao sol a +6°; etc.), em horas do mundo e em
##     segundos reais (dia de 24 min e modo de prova);
##   · a CONTINUIDADE: o maior salto, de um passo de 1 minuto do mundo para o seguinte, em cada
##     cor e número que sai da hora (prova de que nada muda de um quadro para o outro).

const Ciclo := preload("res://mapa/floresta/ciclo_dia.gd")
const Vento := preload("res://mapa/floresta/vento_mundo.gd")
const SAIDA := "res://mapa/floresta/capturas/ciclo43/curvas_ciclo_vento.json"


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _correr() -> void:
	var ciclo: Node = Ciclo.new()
	ciclo.set("parado", true)
	root.add_child(ciclo)
	var vento: Node = Vento.new()
	vento.set("parado", true)
	vento.set("relogio", ciclo)
	root.add_child(vento)
	await process_frame
	var saida := {}
	saida["vento_por_hora"] = _vento_por_hora(ciclo, vento)
	saida["deriva"] = _deriva()
	saida["transicoes"] = _transicoes()
	saida["continuidade"] = _continuidade()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA).get_base_dir())
	var f := FileAccess.open(SAIDA, FileAccess.WRITE)
	f.store_string(JSON.stringify(saida, "\t"))
	f.close()
	print("[prova] gravado %s" % SAIDA)
	quit(0)


func _vento_por_hora(ciclo: Node, vento: Node) -> Array:
	var linhas: Array = []
	var dt := 1.0 / 30.0
	for hh in 24:
		var h := float(hh)
		ciclo.call("definir_hora", h)
		var dia: Dictionary = Vento.curva_do_dia(h)
		for i in 300:          # 10 s para assentar
			vento.call("avancar", dt)
		var fmin := 99.0
		var fmax := 0.0
		var soma := 0.0
		var n := 0
		var desv2 := 0.0
		var desv_max := 0.0
		var picos: Array[float] = []
		var armado := false
		var base := float(dia["forca"])
		# a força média desta hora (para o limiar das rajadas): 1.º passe, 120 s à parte
		var media := 0.0
		for i in 3600:
			vento.call("avancar", dt)
			media += float(vento.get("forca"))
		media /= 3600.0
		for i in 3600:         # 120 s em tempo real
			vento.call("avancar", dt)
			var fo: float = vento.get("forca")
			fmin = minf(fmin, fo)
			fmax = maxf(fmax, fo)
			soma += fo
			n += 1
			var d := wrapf(float(vento.get("azimute_para")) - float(dia["azimute_para"]), -180.0, 180.0)
			desv2 += d * d
			desv_max = maxf(desv_max, absf(d))
			# uma RAJADA: a força sobe acima de 1,2 × a média da hora (com histerese: só conta outra
			# depois de voltar abaixo da média)
			if armado and fo > media * 1.2:
				picos.append(float(i) * dt)
				armado = false
			elif fo < media:
				armado = true
		var intervalos: Array[float] = []
		for k in range(1, picos.size()):
			intervalos.append(picos[k] - picos[k - 1])
		var imin := 0.0
		var imax := 0.0
		var imed := 0.0
		if intervalos.size() > 0:
			imin = intervalos.min()
			imax = intervalos.max()
			for x in intervalos:
				imed += x
			imed /= float(intervalos.size())
		linhas.append({
			"hora": Ciclo.texto_de(h),
			"forca_base": snappedf(base, 0.01),
			"de_onde_sopra": "%s (%03.0f°)" % [Vento.rumo(float(dia["azimute_de"])), fposmod(float(dia["azimute_de"]), 360.0)],
			"forca_min": snappedf(fmin, 0.01), "forca_media": snappedf(soma / float(n), 0.01), "forca_max": snappedf(fmax, 0.01),
			"kmh_min": snappedf(fmin * Vento.VEL_REF_MS * 3.6, 0.1), "kmh_media": snappedf(soma / float(n) * Vento.VEL_REF_MS * 3.6, 0.1),
			"kmh_max": snappedf(fmax * Vento.VEL_REF_MS * 3.6, 0.1),
			"rajadas_em_120s": picos.size(),
			"intervalo_rajadas_s": [snappedf(imin, 0.1), snappedf(imed, 0.1), snappedf(imax, 0.1)],
			"desvio_direcao_graus": {"dp": snappedf(sqrt(desv2 / float(n)), 0.1), "max": snappedf(desv_max, 0.1)},
		})
		print("[prova] vento %s" % JSON.stringify(linhas[-1]))
	return linhas


func _deriva() -> Dictionary:
	var por_hora: Array = []
	var total := 0.0
	var maior_passo := 0.0
	var a0: float = Vento.curva_do_dia(0.0)["azimute_para"]
	for hh in 24:
		var a: float = Vento.curva_do_dia(float(hh))["azimute_para"]
		var b: float = Vento.curva_do_dia(float(hh + 1))["azimute_para"]
		var d := wrapf(b - a, -180.0, 180.0)
		por_hora.append(snappedf(d, 0.1))
		total += d
	# o maior passo de um minuto do mundo (prova: a deriva não salta)
	for m in 1440:
		var a: float = Vento.curva_do_dia(float(m) / 60.0)["azimute_para"]
		var b: float = Vento.curva_do_dia(float(m + 1) / 60.0)["azimute_para"]
		maior_passo = maxf(maior_passo, absf(wrapf(b - a, -180.0, 180.0)))
	return {"graus_por_hora_00_a_23": por_hora, "volta_em_24h_graus": snappedf(total, 0.1),
		"maior_passo_por_minuto_do_mundo_graus": snappedf(maior_passo, 0.001), "azimute_para_as_00h": snappedf(a0, 0.1)}


## A hora (por bissecção) em que f(h) cruza `alvo`, entre h0 e h1.
func _cruza(astro: String, alvo: float, h0: float, h1: float) -> float:
	var f := func(h: float) -> float:
		var v: Vector2 = Ciclo.sol(h) if astro == "sol" else Ciclo.lua(h)
		return v.y - alvo
	var a := h0
	var b := h1
	var fa: float = f.call(a)
	for i in 60:
		var m := 0.5 * (a + b)
		var fm: float = f.call(m)
		if signf(fm) == signf(fa):
			a = m
			fa = fm
		else:
			b = m
	return fposmod(0.5 * (a + b), 24.0)


func _transicoes() -> Dictionary:
	var c := Ciclo.new()
	var dia_s: float = c.get("duracao_dia_s")
	c.free()
	var seg := func(dh: float) -> Array:
		return [snappedf(dh * dia_s / 24.0, 0.1), snappedf(dh * Ciclo.DURACAO_PROVA_S / 24.0, 0.1)]
	var t := {}
	var s_m18 := _cruza("sol", -18.0, 0.5, 12.5)
	var s_m6 := _cruza("sol", -6.0, 0.5, 12.5)
	var s_0 := _cruza("sol", 0.0, 0.5, 12.5)
	var s_6 := _cruza("sol", 6.0, 0.5, 12.5)
	var p_6 := _cruza("sol", 6.0, 12.5, 24.5)
	var p_0 := _cruza("sol", 0.0, 12.5, 24.5)
	var p_m6 := _cruza("sol", -6.0, 12.5, 24.5)
	var p_m18 := _cruza("sol", -18.0, 12.5, 24.5)
	var l_n := _cruza("lua", 0.0, 12.5, 24.5)
	var l_p := _cruza("lua", 0.0, 0.5, 12.5)
	t["sol_nasce"] = Ciclo.texto_de(s_0)
	t["sol_poe"] = Ciclo.texto_de(p_0)
	t["sol_culmina"] = "%s (elev %.1f°, az %.0f°)" % [Ciclo.texto_de(Ciclo.SOL_CULMINA), Ciclo.sol(Ciclo.SOL_CULMINA).y, fposmod(Ciclo.sol(Ciclo.SOL_CULMINA).x, 360.0)]
	t["sol_nasce_azimute"] = snappedf(fposmod(Ciclo.sol(s_0).x, 360.0), 0.1)
	t["sol_poe_azimute"] = snappedf(fposmod(Ciclo.sol(p_0).x, 360.0), 0.1)
	t["lua_nasce"] = Ciclo.texto_de(l_n)
	t["lua_poe"] = Ciclo.texto_de(l_p)
	t["lua_culmina"] = "%s (elev %.1f°)" % [Ciclo.texto_de(Ciclo.LUA_CULMINA), Ciclo.lua(Ciclo.LUA_CULMINA).y]
	var passagens := {
		"amanhecer_noite_a_madrugada (sol −18° → −6°)": [s_m18, s_m6],
		"aurora (sol −6° → +6°: madrugada rosa/dourada, a luz troca da lua para o sol)": [s_m6, s_6],
		"por_do_sol (sol +6° → −6°: laranja/vermelho, a luz troca do sol para a lua)": [p_6, p_m6],
		"cair_da_noite (sol −6° → −18°)": [p_m6, p_m18],
	}
	var lista := {}
	for k: String in passagens:
		var a: float = passagens[k][0]
		var b: float = passagens[k][1]
		var dh := fposmod(b - a, 24.0)
		lista[k] = {"de": Ciclo.texto_de(a), "a": Ciclo.texto_de(b), "horas_do_mundo": snappedf(dh, 0.01),
			"segundos_reais_dia_24min_e_modo_prova": seg.call(dh)}
	t["passagens"] = lista
	# as fases por nome ao longo do dia (onde mudam)
	var mudas: Array = []
	var f0 := Ciclo.fase_de(0.0)
	for m in range(1, 1441):
		var f := Ciclo.fase_de(float(m) / 60.0)
		if f != f0:
			mudas.append("%s → %s às %s" % [f0, f, Ciclo.texto_de(float(m) / 60.0)])
			f0 = f
	t["fases"] = mudas
	# as luzes artificiais (lume): acendem / apagam
	var lume_on := -1.0
	var lume_off := -1.0
	var l0: float = Ciclo.calcular(12.0)["lume"]
	for m in range(721, 721 + 1440):
		var l: float = Ciclo.calcular(float(m) / 60.0)["lume"]
		if l0 < 0.5 and l >= 0.5 and lume_on < 0.0:
			lume_on = float(m) / 60.0
		if l0 >= 0.5 and l < 0.5 and lume_off < 0.0:
			lume_off = float(m) / 60.0
		l0 = l
	t["lume_acende_a_meio"] = Ciclo.texto_de(lume_on)
	t["lume_apaga_a_meio"] = Ciclo.texto_de(lume_off)
	t["duracao_do_dia_s"] = dia_s
	t["modo_prova_s"] = Ciclo.DURACAO_PROVA_S
	print("[prova] transições %s" % JSON.stringify(t))
	return t


## O maior salto, de um minuto do mundo para o seguinte, em cada saída da hora.
func _continuidade() -> Dictionary:
	var maior := {}
	var onde := {}
	var antes: Dictionary = Ciclo.calcular(0.0)
	for m in range(1, 1441):
		var e: Dictionary = Ciclo.calcular(float(m) / 60.0)
		for k: String in e:
			var a: Variant = antes[k]
			var b: Variant = e[k]
			var d := 0.0
			if a is Color:
				var ca: Color = a
				var cb: Color = b
				d = maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), absf(ca.b - cb.b))
			elif a is Vector3:
				d = (a as Vector3).distance_to(b as Vector3)
			elif a is float and k != "hora" and not k.ends_with("azimute"):
				d = absf(float(a) - float(b))
			else:
				continue
			if d > float(maior.get(k, 0.0)):
				maior[k] = d
				onde[k] = Ciclo.texto_de(float(m) / 60.0)
		antes = e
	var pior := ""
	var pior_v := 0.0
	for k: String in maior:
		maior[k] = snappedf(float(maior[k]), 0.0001)
		if k.begins_with("cor_") and float(maior[k]) > pior_v:
			pior_v = maior[k]
			pior = k
	print("[prova] continuidade: maior salto de cor por minuto do mundo = %.4f (%s às %s)" % [pior_v, pior, onde.get(pior, "")])
	return {"nota": "maior diferença entre minutos seguidos do mundo (cores: 0–1 por canal; direcções: distância de vectores unitários; números: absoluta). Com o dia de 24 min, 1 min real = 1 h do mundo e 1 s real = 1 min do mundo: no jogo, a 60 q/s, cada valor desta tabela espalha-se por 60 quadros (no timelapse --dia, por 1,25 quadros).",
		"maior_salto_por_minuto": maior, "a_que_hora": onde, "pior_cor": pior}
