extends SceneTree
## Ordem 41 — o ESTADO FORTE do clima (nevasca e chuva que alaga), sem janela.
##
##   godot --headless --path cliente -s res://testes/clima_forte.gd
##
## Confere, com a conta do módulo (arte/clima/clima.gd):
## - a nevasca: o aglomerado e o gelo acumulam (com o vento de cada frame) e derretem, cada clima ao seu ritmo;
##   o vento da nevasca levanta-se e deita-se; o véu só existe na neve forte;
## - a chuva que alaga: a água só se junta com o chão encharcado, enche as bacias e escoa nas 3 fases
##   (escoa → lama baça → lama seca); a lama acompanha a água;
## - a API nova: definir_forte, definir_bacias, bacias, abrigos, registar_obstaculo, nevasca(), alaga(),
##   fundura_em, abrigo_em, neve_em, medir_alagamento (e o grupo «clima_obstaculo»);
## - que o clima continua a ser só apresentação: não toca no Estado nem na Rede.
##
## DETERMINÍSTICO (a lição do pecas_mestre, run 43614399996): nada aqui corre pelo _process. Tudo avança à
## mão com clima.avancar(dt) e um dt fixo, dentro de UM só callback (sem await), por isso o passo de tempo
## da máquina não entra em nenhuma conta. Há um teste que o prova (o mesmo guião dá o mesmo estado, e os
## tempos das fases são os mesmos com dt de 1/30, 1/60 e 1/144 s).
##
## Sai com código 0 se tudo passa e 1 se algo falha.

const Clima := preload("res://arte/clima/clima.gd")
const DT := 1.0 / 30.0
## O campo dos testes: 20 × 20 m, centrado em (10, 0, 10).
const CENTRO := Vector3(10.0, 0.0, 10.0)
const CAMPO := Vector2(20.0, 20.0)

var _total := 0
var _falhas := 0


func _init() -> void:
	# No 1.º quadro os autoloads (Rede, Estado) já estão na árvore; tudo corre neste callback, sem await.
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _correr() -> void:
	print("== Clima forte (ordem 41): nevasca e chuva que alaga ==")
	_teste_quem_e_forte()
	_teste_nevasca_acumula()
	_teste_nevasca_vento_de_cada_frame()
	_teste_nevasca_vento_levanta_e_deita()
	_teste_derretimento()
	_teste_fracos_sem_estado_forte()
	_teste_veu()
	_teste_definir_forte()
	_teste_bacias()
	_teste_alaga_enche()
	_teste_drenagem_tres_fases()
	_teste_drenagem_com_outros_climas()
	_teste_fundura_em()
	_teste_medir_alagamento()
	_teste_pes_na_agua()
	_teste_obstaculos_e_abrigos()
	_teste_abrigo_em()
	_teste_neve_em()
	_teste_grupo_obstaculo_na_arvore()
	_teste_dorme_so_com_tudo_a_zero()
	_teste_deterministico()
	_teste_so_apresentacao_codigo()
	_teste_so_apresentacao_estado_e_rede()
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)


# ---------------------------------------------------------------- ajudas

func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		printerr("  FALHA ", nome)


func _perto(a: float, b: float, tol: float) -> bool:
	return absf(a - b) <= tol


## Um Clima solto (fora da árvore: nunca corre pelo _process), sem as rajadas fracas, no campo dos testes.
func _clima(cena: Node3D = null) -> Node3D:
	var c = Clima.new()
	if cena != null:
		cena.add_child(c)
	c.rajadas = 0.0
	c.configurar_area(CENTRO, CAMPO)
	return c


func _passar(c, segundos: float, dt: float = DT) -> void:
	for i in int(round(segundos / dt)):
		c.avancar(dt)


func _libertar(c, cena: Node = null) -> void:
	if cena != null:
		cena.free()
	elif is_instance_valid(c):
		c.free()


## Uma caixa de 1 m de lado (o «obstáculo»), com a base no chão.
func _caixa(pai: Node3D, x: float, z: float, lado: float = 1.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(lado, lado, lado)
	mi.mesh = bm
	mi.position = Vector3(x, lado * 0.5, z)
	pai.add_child(mi)
	return mi


## O ponto mais fundo de uma bacia (a margem é torcida: procura-se numa grelha de 5 cm à volta do centro).
func _ponto_mais_fundo(c, b: Vector4, enchimento: float) -> Vector2:
	var melhor := Vector2(b.x, b.y)
	var d_melhor := -INF
	var alcance := b.z + 1.5
	var passo := 0.05
	var n := int(ceil(2.0 * alcance / passo))
	for j in n:
		for i in n:
			var p := Vector2(b.x - alcance + i * passo, b.y - alcance + j * passo)
			var d: float = c.fundura_em(p, enchimento)
			if d > d_melhor:
				d_melhor = d
				melhor = p
	return melhor


# ---------------------------------------------------------------- nevasca

func _teste_quem_e_forte() -> void:
	print("Quem é o clima forte:")
	var c = _clima()
	var casos := [["nenhum", "fraco", false, false], ["chuva", "fraco", false, false], ["chuva", "forte", false, true],
		["neve", "fraco", false, false], ["neve", "forte", true, false]]
	var bons := true
	for k in casos:
		c.definir(k[0], k[1])
		if c.nevasca() != k[2] or c.alaga() != k[3]:
			bons = false
	_ok(bons, "nevasca() só na neve forte; alaga() só na chuva forte (nenhum, fracos e o outro forte: false)")
	_libertar(c)


func _teste_nevasca_acumula() -> void:
	print("Nevasca: o aglomerado e o gelo acumulam")
	var c = _clima()
	# Com a calma e o pico a 1, o vento da nevasca é o vento pedido: 4 m/s = o vento de referência (ganho 1).
	c.nevasca_calma = 1.0
	c.nevasca_pico = 1.0
	c.definir_vento(0.0, c.vento_referencia)
	c.definir("neve", "forte")
	var sobe := true
	var antes_a := 0.0
	var antes_g := 0.0
	for i in 570:  # 19 s
		c.avancar(DT)
		if c.aglomerado < antes_a or c.gelo < antes_g:
			sobe = false
		antes_a = c.aglomerado
		antes_g = c.gelo
	_ok(sobe and _perto(c.aglomerado, 19.0 / 38.0, 0.002), "com o vento de referência, 19 s de nevasca = metade do aglomerado (%.4f; cheio aos 38 s)" % c.aglomerado)
	_ok(_perto(c.gelo, 19.0 / 70.0, 0.002), "e o gelo vai mais devagar: 19 s = %.4f (cheio aos 70 s)" % c.gelo)
	_passar(c, 19.5)
	_ok(c.aglomerado == 1.0 and c.gelo < 1.0, "aos 38,5 s o aglomerado está cheio (1,0) e o gelo ainda não (%.3f)" % c.gelo)
	_passar(c, 32.0)
	_ok(c.aglomerado == 1.0 and c.gelo == 1.0, "aos 70,5 s o gelo também está cheio; nada passa de 1,0")
	_ok(c.neve == 1.0 and c.agua == 0.0 and c.lama == 0.0, "a nevasca também pousa o manto (neve 1,0) e não junta água nem lama")
	_libertar(c)
	# O ganho do vento: o dobro do vento, o dobro da pressa; sem vento, o mínimo (×0,25).
	var c2 = _clima()
	c2.nevasca_calma = 1.0
	c2.nevasca_pico = 1.0
	c2.definir_vento(0.0, 2.0 * c2.vento_referencia)
	c2.definir("neve", "forte")
	_passar(c2, 9.5)
	var c3 = _clima()
	c3.nevasca_calma = 1.0
	c3.nevasca_pico = 1.0
	c3.definir_vento(0.0, 0.0)
	c3.definir("neve", "forte")
	_passar(c3, 9.5)
	_ok(_perto(c2.aglomerado, 0.5, 0.002) and _perto(c3.aglomerado, 0.25 * 9.5 / 38.0, 0.002),
		"com 8 m/s junta-se a dobrar (9,5 s = %.3f); sem vento, a ×0,25 (9,5 s = %.4f)" % [c2.aglomerado, c3.aglomerado])
	_ok(_perto(c2.gelo, c3.gelo, 1e-6), "o gelo não depende do vento (só da exposição): %.4f = %.4f" % [c2.gelo, c3.gelo])
	_libertar(c2)
	_libertar(c3)


func _teste_nevasca_vento_de_cada_frame() -> void:
	print("Nevasca: as rajadas e o vento de cada frame")
	# A rajada é uma função do tempo (não do relógio da máquina): 0 na calma … 1 no pico.
	var mn := 1.0
	var mx := 0.0
	var fora := false
	for q in 1540:  # 77 s (7 × 11) de 0,05 em 0,05 s
		var g := Clima.rajada_da_nevasca(q * 0.05)
		mn = minf(mn, g)
		mx = maxf(mx, g)
		if g < 0.0 or g > 1.0:
			fora = true
	_ok(not fora and mn == 0.0 and mx > 0.98, "rajada_da_nevasca(t) fica em 0..1, tem calma (0) e chega ao pico (%.3f) num ciclo de 77 s" % mx)
	_ok(Clima.rajada_da_nevasca(12.34) == Clima.rajada_da_nevasca(12.34) and _perto(Clima.rajada_da_nevasca(12.34), Clima.rajada_da_nevasca(12.34 + 77.0), 1e-4),
		"e é uma conta pura do tempo do clima: o mesmo t dá a mesma rajada, e repete-se a cada 77 s")
	var c = _clima()
	c.definir_vento(30.0, 4.0)
	c.definir("neve", "forte")
	_passar(c, 4.5)  # o vento da nevasca já está levantado
	var fmin := INF
	var fmax := 0.0
	var guina := 0.0
	var inc_pico := -1.0
	var inc_calma := INF
	for i in 2400:  # 80 s
		var antes: float = c.aglomerado
		c.avancar(DT)
		var v: Vector2 = c.vento_do_frame()
		fmin = minf(fmin, v.length())
		fmax = maxf(fmax, v.length())
		guina = maxf(guina, absf(rad_to_deg(angle_difference(deg_to_rad(30.0), v.angle()))))
		if c.aglomerado < 1.0:
			var inc: float = c.aglomerado - antes
			var g := Clima.rajada_da_nevasca(c._tempo)
			if g > 0.95:
				inc_pico = maxf(inc_pico, inc)
			elif g == 0.0:
				inc_calma = minf(inc_calma, inc)
	_ok(fmin >= 0.65 * 4.0 - 0.01 and fmax <= 2.9 * 4.0 + 0.01 and fmin < 0.7 * 4.0 and fmax > 2.8 * 4.0,
		"a força vai da calma (×0,65 = %.2f m/s) ao pico (×2,9 = %.2f m/s) da força pedida (4 m/s)" % [fmin, fmax])
	_ok(guina <= 26.0 + 0.01 and guina > 12.0, "o rumo guina com as rajadas, até 26° (%.1f°)" % guina)
	_ok(inc_pico > 0.0 and inc_calma < INF and inc_pico > 2.0 * inc_calma,
		"é o vento do frame que arrasta a neve: no pico junta-se %.1f× mais depressa do que na calma" % (inc_pico / maxf(inc_calma, 1e-9)))
	_libertar(c)


func _teste_nevasca_vento_levanta_e_deita() -> void:
	print("Nevasca: o vento levanta-se e deita-se em segundos_levantar")
	var c = _clima()
	_ok(c.vento_da_nevasca() == 0.0, "antes da nevasca, o vento da nevasca está deitado (0)")
	c.definir("neve", "forte")
	_passar(c, 2.0)
	var meio: float = c.vento_da_nevasca()
	_passar(c, 2.1)
	_ok(_perto(meio, 0.5, 0.01) and c.vento_da_nevasca() == 1.0, "levanta-se em 4 s: 2 s = %.3f, 4,1 s = 1,0" % meio)
	c.definir("neve", "fraco")
	_passar(c, 2.0)
	var desce: float = c.vento_da_nevasca()
	_passar(c, 2.1)
	_ok(_perto(desce, 0.5, 0.01) and c.vento_da_nevasca() == 0.0, "passa a neve fraca: deita-se em 4 s (2 s = %.3f, 4,1 s = 0)" % desce)
	# Sem o vento da nevasca, o vento do frame é o vento pedido (com rajadas 0): nada da nevasca sobra.
	var v: Vector2 = c.vento_do_frame()
	_ok(v.is_equal_approx(Vector2(cos(deg_to_rad(c.vento_direcao_graus)), sin(deg_to_rad(c.vento_direcao_graus))) * c.vento_forca),
		"com o vento da nevasca deitado, o vento do frame volta a ser o pedido")
	_libertar(c)


func _teste_derretimento() -> void:
	print("Derretimento do aglomerado e do gelo (segundos_derreter = 60 s)")
	# [clima, intensidade, segundos, aglomerado esperado, gelo esperado]
	var casos := [
		["neve", "fraco", 30.0, 1.0 - 0.5 * 30.0 / 60.0, 1.0 - 0.5 * 30.0 / 60.0, "neve fraca: a metade do ritmo (30 s → 0,75 e 0,75)"],
		["chuva", "fraco", 10.0, 1.0 - 2.0 * 10.0 / 60.0, 1.0 - 3.0 * 10.0 / 60.0, "chuva: o dobro no aglomerado e o triplo no gelo (10 s → 0,667 e 0,5)"],
		["nenhum", "fraco", 30.0, 1.0 - 0.8 * 30.0 / 60.0, 1.0 - 30.0 / 60.0, "sem clima: os montes a ×0,8 e o gelo a ×1 (30 s → 0,6 e 0,5)"],
	]
	for k in casos:
		var c = _clima()
		c.definir(k[0], k[1])
		c.definir_forte(1.0, 1.0, 0.0, 0.0)
		_passar(c, k[2])
		_ok(_perto(c.aglomerado, k[3], 0.002) and _perto(c.gelo, k[4], 0.002), "%s: %.3f e %.3f" % [k[5], c.aglomerado, c.gelo])
		_libertar(c)
	# Os montes duram mais do que o manto (sem clima).
	var c2 = _clima()
	c2.definir_acumulacao(0.0, 1.0)
	c2.definir_forte(1.0, 0.0, 0.0, 0.0)
	_passar(c2, 30.0)
	_ok(c2.aglomerado > c2.neve and _perto(c2.neve, 0.5, 0.002), "os montes duram mais do que o manto: 30 s depois, aglomerado %.3f > neve %.3f" % [c2.aglomerado, c2.neve])
	_passar(c2, 45.1)
	_ok(c2.aglomerado == 0.0 and c2.gelo == 0.0 and c2.neve == 0.0, "e acabam por ir todos (75 s: 0, 0, 0)")
	_libertar(c2)


func _teste_fracos_sem_estado_forte() -> void:
	print("Os climas fracos ficam como eram (sem estado forte)")
	var c = _clima()
	c.definir("neve", "fraco")
	_passar(c, 60.0)
	_ok(c.aglomerado == 0.0 and c.gelo == 0.0 and c.vento_da_nevasca() == 0.0 and c.contagem_atual("veu") == 0,
		"60 s de neve fraca: sem aglomerado, sem gelo, sem vento da nevasca, sem véu (neve %.2f)" % c.neve)
	_libertar(c)
	var c2 = _clima()
	c2.definir_acumulacao(1.0, 0.0)
	c2.definir("chuva", "fraco")
	_passar(c2, 60.0)
	_ok(c2.molhado == 1.0 and c2.agua == 0.0 and c2.lama == 0.0, "60 s de chuva fraca com o chão encharcado: a água não se junta e não há lama")
	_libertar(c2)


func _teste_veu() -> void:
	print("O véu da nevasca: só na neve forte, por perfil")
	var c = _clima()
	var bons := true
	var lido := []
	for p in ["baixo", "medio", "alto"]:
		c.definir_perfil(p)
		c.definir("neve", "forte")
		_passar(c, 2.0)
		lido.append(c.contagem_atual("veu"))
		if c.contagem_alvo("veu") != int(Clima.VEU[p]) or c.contagem_atual("veu") != int(Clima.VEU[p]):
			bons = false
	_ok(bons and lido == [0, 140, 260], "nevasca: 0 / 140 / 260 cartões do véu no Baixo / Médio / Alto (%s)" % str(lido))
	var veu: MultiMeshInstance3D = c.get_node_or_null("Veu")
	_ok(veu != null and veu.visible and veu.multimesh.visible_instance_count == 260, "o véu é uma MultiMesh própria (1 draw call), com 260 à vista no Alto")
	c.definir("neve", "fraco")
	_passar(c, 2.0)
	_ok(c.contagem_alvo("veu") == 0 and c.contagem_atual("veu") == 0 and not veu.visible, "neve fraca: o véu sai (0) e a nuvem esconde-se")
	c.definir("chuva", "forte")
	_passar(c, 2.0)
	_ok(c.contagem_alvo("veu") == 0 and c.contagem_atual("veu") == 0, "chuva forte: nunca há véu")
	_libertar(c)


func _teste_definir_forte() -> void:
	print("definir_forte(): o estado forte posto à mão")
	var c = _clima()
	_ok(c.parado() and not c.is_processing(), "um Clima novo está parado")
	c.definir_forte(1.7, -0.4, 0.5)
	_ok(c.aglomerado == 1.0 and c.gelo == 0.0 and c.agua == 0.5, "os valores ficam em 0..1 (1,7 → 1, −0,4 → 0)")
	_ok(_perto(c.lama, 0.5 * 1.10 + 0.04, 1e-6) and c.lama_humida == 1.0, "sem lama dada, a lama acompanha a água (0,5 → %.2f) e está húmida" % c.lama)
	_ok(c.is_processing() and not c.parado(), "com estado forte posto, o módulo acorda")
	c.definir_forte(0.0, 0.0, 0.3, 0.9)
	_ok(c.agua == 0.3 and c.lama == 0.9, "a lama dada vale por si (0,9 com água 0,3)")
	c.definir_forte(0.0, 0.0, 0.0)
	_ok(c.lama == 0.0 and c.agua == 0.0, "sem água e sem lama dada: lama 0")
	_libertar(c)


# ---------------------------------------------------------------- chuva que alaga

func _teste_bacias() -> void:
	print("Bacias: as sorteadas e as dadas (definir_bacias / bacias)")
	var c = _clima()
	var auto: Array[Vector4] = c.bacias()
	var c2 = _clima()
	_ok(auto.size() == 5 and auto == c2.bacias(), "sem bacias dadas, o módulo sorteia 5, sempre as mesmas para o mesmo campo")
	var dentro := true
	var separadas := true
	for i in auto.size():
		var b: Vector4 = auto[i]
		if absf(b.x - CENTRO.x) > 0.36 * CAMPO.x + 1e-4 or absf(b.y - CENTRO.z) > 0.36 * CAMPO.y + 1e-4:
			dentro = false
		if b.z < 20.0 * 0.065 - 1e-4 or b.z > 20.0 * 0.115 + 1e-4 or b.w < 0.06 - 1e-6 or b.w > 0.10 + 1e-6:
			dentro = false
		for j in range(i + 1, auto.size()):
			var o: Vector4 = auto[j]
			if Vector2(b.x - o.x, b.y - o.y).length() < (b.z + o.z) * 0.8:
				separadas = false
	_ok(dentro and separadas, "as sorteadas ficam dentro do campo (±36 %), com raio 6,5–11,5 % do lado e fundura 6–10 cm, sem se sobreporem")
	var copia: Array[Vector4] = c.bacias()
	copia.clear()
	_ok(c.bacias().size() == 5, "bacias() devolve uma cópia (mexer nela não muda o módulo)")
	c.definir_bacias([Vector4(4.0, 5.0, 2.5, 0.09), {"x": 15.0, "z": 12.0, "raio": 3.0, "fundura": 0.07}, {"x": 8.0, "z": 16.0}])
	var b: Array[Vector4] = c.bacias()
	_ok(b.size() == 3 and b[0] == Vector4(4.0, 5.0, 2.5, 0.09) and b[1] == Vector4(15.0, 12.0, 3.0, 0.07),
		"as bacias dadas entram como Vector4 ou como Dictionary {x, z, raio, fundura}")
	_ok(b[2].is_equal_approx(Vector4(8.0, 16.0, 2.0, 0.08)), "um Dictionary sem raio nem fundura leva 2 m e 8 cm")
	c.configurar_area(CENTRO, CAMPO)
	_ok(c.bacias().size() == 3, "configurar a área outra vez não apaga as bacias dadas")
	c.definir_bacias([Vector4(1.0, 1.0, 0.0, -1.0)])
	_ok(c.bacias()[0].is_equal_approx(Vector4(1.0, 1.0, 0.1, 0.005)), "raio e fundura têm mínimos (0,1 m e 5 mm)")
	var muitas := []
	for i in 11:
		muitas.append(Vector4(1.0 + i, 2.0, 1.0, 0.05))
	c.definir_bacias(muitas)
	_ok(c.bacias().size() == Clima.MAX_BACIAS and c.bacias()[7].x == 8.0, "no máximo 8 bacias: as primeiras 8 de 11")
	c.definir_bacias([])
	_ok(c.bacias() == auto, "lista vazia: volta às 5 sorteadas")
	c.definir_bacias(["lixo", 3, null])
	_ok(c.bacias() == auto, "só lixo na lista: também volta às sorteadas")
	_libertar(c)
	_libertar(c2)


func _teste_alaga_enche() -> void:
	print("Chuva que alaga: a água só se junta com o chão encharcado")
	var c = _clima()
	c.definir_bacias([Vector4(6.0, 6.0, 2.5, 0.09), Vector4(14.0, 13.0, 3.0, 0.08)])
	c.definir("chuva", "forte")
	# molhado sobe 1/9 por segundo: 0,7 aos 6,3 s.
	_passar(c, 6.2)
	_ok(c.molhado < c.molhado_para_alagar and c.agua == 0.0, "aos 6,2 s o chão ainda não está encharcado (%.3f < 0,7): água 0" % c.molhado)
	_passar(c, 0.3)
	_ok(c.molhado >= c.molhado_para_alagar and c.agua > 0.0 and c.agua <= 0.25 / 36.0 + 1e-6, "aos 6,5 s (molhado %.3f) a água começou a juntar-se (%.4f)" % [c.molhado, c.agua])
	var lama_acompanha := true
	var humida := true
	var sobe := true
	var antes := 0.0
	var t_cheia := -1.0
	var t := 6.5
	for i in 1080:  # mais 36 s
		c.avancar(DT)
		t += DT
		if c.agua < antes:
			sobe = false
		antes = c.agua
		if c.lama < c.agua or not _perto(c.lama, minf(1.0, c.agua * 1.10 + 0.04), 1e-5):
			lama_acompanha = false
		if c.lama_humida != 1.0:
			humida = false
		if t_cheia < 0.0 and c.agua >= 1.0:
			t_cheia = t
	_ok(sobe and t_cheia > 42.2 and t_cheia < 42.7, "a água só sobe e as bolsas ficam cheias aos %.2f s (6,3 s a encharcar + 36 s a encher)" % t_cheia)
	_ok(lama_acompanha, "a lama vai um pouco à frente da água (lama = água × 1,1 + 0,04), sempre ≥ água")
	_ok(humida, "enquanto chove, a lama brilha (lama_humida = 1)")
	_ok(c.agua == 1.0 and c.lama == 1.0, "cheias: água 1,0 e lama 1,0")
	_libertar(c)


## Mede os instantes das 3 fases depois de a chuva parar, a partir de bolsas cheias e do chão encharcado.
func _fases_da_drenagem(dt: float) -> Dictionary:
	var c = _clima()
	c.definir_bacias([Vector4(6.0, 6.0, 2.5, 0.09), Vector4(14.0, 13.0, 3.0, 0.08)])
	c.definir_acumulacao(1.0, 0.0)
	c.definir_forte(0.0, 0.0, 1.0, 1.0)
	c.desligar()
	var r := {"seca_agua": -1.0, "baca_comeca": -1.0, "baca": -1.0, "seca_comeca": -1.0, "seco": -1.0, "chao_seco": -1.0,
		"lama_mexeu_a_escoar": false, "lama_mexeu_a_bacar": false, "agua_meio": -1.0, "humida_meio": -1.0, "lama_meio": -1.0,
		"area_lama_baca": -1.0, "area_lama_meio": -1.0, "area_agua_baca": -1.0, "dorme": false}
	var t := 0.0
	var passos := int(round(70.0 / dt))
	for i in passos:
		c.avancar(dt)
		t += dt
		if r["seca_agua"] < 0.0 and c.agua <= 0.0:
			r["seca_agua"] = t
		if r["baca_comeca"] < 0.0 and c.lama_humida < 1.0:
			r["baca_comeca"] = t
		if r["baca"] < 0.0 and c.lama_humida <= 0.0:
			r["baca"] = t
		if r["seca_comeca"] < 0.0 and c.lama < 1.0:
			r["seca_comeca"] = t
		if r["seco"] < 0.0 and c.lama <= 0.0:
			r["seco"] = t
		if r["chao_seco"] < 0.0 and c.molhado <= 0.0:
			r["chao_seco"] = t
		if c.lama < 1.0 and c.agua > 0.0:
			r["lama_mexeu_a_escoar"] = true
		if c.lama < 1.0 and c.lama > 0.0 and c.lama_humida > 0.0:
			r["lama_mexeu_a_bacar"] = true
		if r["agua_meio"] < 0.0 and t >= 12.0 - dt * 0.5:
			r["agua_meio"] = c.agua
		if r["humida_meio"] < 0.0 and t >= 28.52 - dt * 0.5:
			r["humida_meio"] = c.lama_humida
		if r["area_lama_baca"] < 0.0 and t >= 30.0 - dt * 0.5:
			var m: Dictionary = c.medir_alagamento(0.25)
			r["area_lama_baca"] = m["area_lama_m2"]
			r["area_agua_baca"] = m["area_agua_m2"]
		if r["lama_meio"] < 0.0 and t >= 45.52 - dt * 0.5:
			r["lama_meio"] = c.lama
			r["area_lama_meio"] = c.medir_alagamento(0.25)["area_lama_m2"]
	r["dorme"] = c.parado() and not c.is_processing()
	r["humida_no_fim"] = c.lama_humida
	_libertar(c)
	return r


func _teste_drenagem_tres_fases() -> void:
	print("Drenagem nas 3 fases (segundos_drenar 24, lama_baca 10, lama_secar 24)")
	var r := _fases_da_drenagem(DT)
	var tol := 2.0 * DT
	_ok(_perto(r["agua_meio"], 0.5, 0.003), "1.ª fase, ESCOA: a água desce a 1/24 por segundo (12 s → %.3f)" % r["agua_meio"])
	_ok(_perto(r["seca_agua"], 24.0, tol) and not r["lama_mexeu_a_escoar"], "as bolsas somem-se aos %.2f s, e enquanto há água a lama fica onde a água chegou" % r["seca_agua"])
	_ok(_perto(r["baca_comeca"], 24.0 * 0.98, tol), "a lama começa a perder o brilho quando a água fica abaixo de 2 %% (%.2f s)" % r["baca_comeca"])
	_ok(_perto(r["humida_meio"], 0.5, 0.01), "2.ª fase, LAMA BAÇA: o brilho vai-se em 10 s (5 s depois: %.3f)" % r["humida_meio"])
	_ok(_perto(r["baca"], 33.52, tol) and not r["lama_mexeu_a_bacar"], "a lama fica baça aos %.2f s, e só então começa a secar" % r["baca"])
	_ok(r["area_agua_baca"] == 0.0 and r["area_lama_baca"] > 0.0, "na lama baça (30 s) não há água à vista e a lama ocupa %.1f m²" % r["area_lama_baca"])
	_ok(_perto(r["lama_meio"], 0.5, 0.01) and r["area_lama_meio"] < r["area_lama_baca"],
		"3.ª fase, LAMA SECA: a lama encolhe para o fundo da bacia (12 s depois: %.3f, %.1f m² → %.1f m²)" % [r["lama_meio"], r["area_lama_baca"], r["area_lama_meio"]])
	_ok(_perto(r["seco"], 57.52, tol) and _perto(r["chao_seco"], 40.0, tol), "seco aos %.2f s (o chão molhado secou aos %.2f s)" % [r["seco"], r["chao_seco"]])
	_ok(r["dorme"] and r["humida_no_fim"] == 1.0, "tudo seco: o módulo dorme e a lama volta ao estado inicial (lama_humida 1)")


func _teste_drenagem_com_outros_climas() -> void:
	print("Drenagem com outros climas a seguir")
	var c = _clima()
	c.definir_acumulacao(1.0, 0.0)
	c.definir_forte(0.0, 0.0, 1.0, 1.0)
	c.definir("chuva", "fraco")
	_passar(c, 24.0)
	_ok(_perto(c.agua, 0.5, 0.003), "com chuva fraca as bolsas escoam a meio ritmo (24 s → %.3f; somem-se aos 48 s)" % c.agua)
	_passar(c, 30.0)
	_ok(c.agua == 0.0 and c.lama == 1.0 and c.lama_humida == 1.0, "e enquanto chove a lama não perde o brilho nem seca")
	c.definir_forte(0.0, 0.0, 1.0, 1.0)
	c.definir("neve", "fraco")
	_passar(c, 12.0)
	_ok(_perto(c.agua, 0.5, 0.003), "com neve, escoam ao ritmo inteiro (12 s → %.3f)" % c.agua)
	_libertar(c)


func _teste_fundura_em() -> void:
	print("fundura_em(): a água por cima de um ponto")
	var c = _clima()
	var b := Vector4(10.0, 10.0, 3.0, 0.1)
	c.definir_bacias([b])
	var fundo := _ponto_mais_fundo(c, b, 1.0)
	var d_cheia: float = c.fundura_em(fundo, 1.0)
	_ok(_perto(d_cheia, b.w * Clima.ENCHE, 0.002), "cheia, o fundo tem %.1f cm (fundura × ENCHE = %.1f cm)" % [d_cheia * 100.0, b.w * Clima.ENCHE * 100.0])
	var seco_em_todo_o_lado := true
	var longe_seco := true
	for j in 41:
		for i in 41:
			var p := Vector2(i * 0.5, j * 0.5)
			if c.fundura_em(p, 0.0) > 0.0:
				seco_em_todo_o_lado = false
			if p.distance_to(Vector2(b.x, b.y)) > b.z + 1.8 and c.fundura_em(p, 1.0) > 0.0:
				longe_seco = false
	_ok(seco_em_todo_o_lado, "vazia (enchimento 0), não há água em ponto nenhum do campo")
	_ok(longe_seco, "cheia, fora da bacia (mais de raio + 1,8 m da torção) continua seco")
	var sobe := true
	var anterior := -INF
	for e in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var d: float = c.fundura_em(fundo, e)
		if d <= anterior:
			sobe = false
		anterior = d
	_ok(sobe, "no mesmo ponto, a fundura cresce com o enchimento")
	_ok(_perto(c.fundura_em(fundo, 0.5, 0.12), c.fundura_em(fundo, 0.5) + b.w * 0.12, 1e-6), "a margem alarga a conta em fundura × margem (a faixa da lama)")
	_ok(_perto(c.fundura_em(fundo, 0.5, 0.0, 0.03), c.fundura_em(fundo, 0.5) - 0.03, 1e-6), "y_rel tira a altura do ponto (um chão mais alto fica mais seco)")
	c.definir_forte(0.0, 0.0, 0.6)
	_ok(c.fundura_em(fundo) == c.fundura_em(fundo, 0.6), "sem enchimento dado, usa a água de agora")
	_ok(Clima.torcer(Vector2(3.0, 4.0)) == Clima.torcer(Vector2(3.0, 4.0)) and Clima.torcer(Vector2(3.0, 4.0)).distance_to(Vector2(3.0, 4.0)) < 1.2,
		"a torção da margem é uma conta pura e desloca menos de 1,2 m")
	_libertar(c)


func _teste_medir_alagamento() -> void:
	print("medir_alagamento(): área com água e com lama")
	var c = _clima()
	c.definir_bacias([Vector4(5.0, 5.0, 2.5, 0.09), Vector4(15.0, 14.0, 3.0, 0.08)])
	var m0: Dictionary = c.medir_alagamento(0.2)
	_ok(m0["area_agua_m2"] == 0.0 and m0["area_lama_m2"] == 0.0 and m0["fundura_max_m"] == 0.0 and m0["bacias"] == 2,
		"seco: 0 m² de água, 0 m² de lama, fundura 0, 2 bacias")
	var areas := []
	var lama_cobre := true
	var max_ok := true
	var pct_ok := true
	for a in [0.25, 0.5, 0.75, 1.0]:
		c.definir_forte(0.0, 0.0, a)
		var m: Dictionary = c.medir_alagamento(0.2)
		areas.append(float(m["area_agua_m2"]))
		if float(m["area_lama_m2"]) < float(m["area_agua_m2"]):
			lama_cobre = false
		if float(m["fundura_max_m"]) > 0.09 * Clima.ENCHE + 1e-6:
			max_ok = false
		if not _perto(float(m["percent_agua"]), 100.0 * float(m["area_agua_m2"]) / 400.0, 1e-4):
			pct_ok = false
	_ok(areas[0] < areas[1] and areas[1] < areas[2] and areas[2] < areas[3], "a área com água cresce com o enchimento: %s m²" % str(areas.map(func(x): return snappedf(x, 0.01))))
	_ok(lama_cobre, "a lama cobre sempre pelo menos a área da água")
	_ok(max_ok and pct_ok, "a fundura máxima nunca passa da da bacia × ENCHE, e a % é a área ÷ 400 m²")
	var m1: Dictionary = c.medir_alagamento(0.2)
	var m2: Dictionary = c.medir_alagamento(0.2)
	_ok(m1 == m2, "medir não muda nada: duas medições seguidas dão o mesmo")
	_ok(_perto(float(m1["raio_medio_m"]), sqrt(float(m1["area_agua_m2"]) / (PI * 2.0)), 1e-5), "o raio médio é o de um círculo com a área ÷ n.º de bacias (%.2f m)" % float(m1["raio_medio_m"]))
	var fina: Dictionary = c.medir_alagamento(0.05)
	_ok(_perto(float(fina["area_agua_m2"]), float(m1["area_agua_m2"]), 0.05 * float(m1["area_agua_m2"])), "o passo da varredura só muda a precisão (0,2 m: %.2f m² · 0,05 m: %.2f m²)" % [float(m1["area_agua_m2"]), float(fina["area_agua_m2"])])
	_libertar(c)


func _teste_pes_na_agua() -> void:
	print("Pés na água: as figuras dentro de uma bolsa")
	var cena := Node3D.new()
	var chao := MeshInstance3D.new()
	chao.mesh = PlaneMesh.new()
	cena.add_child(chao)
	var fig := Node3D.new()
	var corpo := MeshInstance3D.new()
	corpo.mesh = CapsuleMesh.new()
	fig.add_child(corpo)
	cena.add_child(fig)
	var c = _clima(cena)
	var b := Vector4(10.0, 10.0, 3.0, 0.1)
	c.definir_bacias([b])
	c.registar_chao(chao)
	c.registar_figura(fig)
	var fundo := _ponto_mais_fundo(c, b, 1.0)
	fig.position = Vector3(fundo.x, 0.0, fundo.y)
	c.definir_forte(0.0, 0.0, 1.0)
	c.avancar(DT)
	c.avancar(DT)
	var mat := chao.material_overlay as ShaderMaterial
	_ok(mat != null and int(mat.get_shader_parameter(&"n_pes")) == 1, "uma figura parada no fundo da bolsa tem os pés na água (n_pes 1)")
	var pes: PackedVector4Array = mat.get_shader_parameter(&"pes")
	_ok(pes[0].w == 0.0, "parada, sem anel (agitação 0)")
	fig.position.x += 0.1
	c.avancar(DT)
	pes = mat.get_shader_parameter(&"pes")
	_ok(pes[0].w == 1.0, "mexe-se: o anel acende (agitação 1)")
	_passar(c, 1.5)
	pes = mat.get_shader_parameter(&"pes")
	_ok(pes[0].w == 0.0, "parada outra vez, o anel apaga-se em 1,4 s")
	fig.position = Vector3(1.0, 0.0, 1.0)
	c.avancar(DT)
	_ok(int(mat.get_shader_parameter(&"n_pes")) == 0, "fora da bolsa: n_pes 0")
	fig.position = Vector3(fundo.x, 0.0, fundo.y)
	c.definir_forte(0.0, 0.0, 0.0, 0.5)
	c.avancar(DT)
	_ok(int(mat.get_shader_parameter(&"n_pes")) == 0, "sem água, não há pés na água (mesmo com lama)")
	_libertar(c, cena)


# ---------------------------------------------------------------- obstáculos e abrigos

func _teste_obstaculos_e_abrigos() -> void:
	print("Obstáculos: registar_obstaculo e abrigos()")
	var cena := Node3D.new()
	var pedra := _caixa(cena, 6.0, 10.0)
	var c = _clima(cena)
	c.registar_obstaculo(pedra)
	_ok(c.abrigos().is_empty(), "antes de o clima ligar, ainda não há abrigos")
	c.definir("neve", "forte")
	c.avancar(DT)
	var ab: Array[Vector4] = c.abrigos()
	_ok(ab.size() == 1 and ab[0].is_equal_approx(Vector4(6.0, 10.0, 0.5, 0.5)), "o obstáculo dá um abrigo: a caixa dele no chão (x, z, meias-larguras) = %s" % str(ab))
	_ok(pedra.material_overlay != null and pedra.material_overlay == c._mat_figura, "e veste a camada das figuras (neve e gelo nele próprio)")
	var copia: Array[Vector4] = c.abrigos()
	copia.clear()
	_ok(c.abrigos().size() == 1, "abrigos() devolve uma cópia")
	pedra.position.x = 8.0
	_passar(c, 0.6)
	_ok(c.abrigos()[0].is_equal_approx(Vector4(8.0, 10.0, 0.5, 0.5)), "o obstáculo mexe-se: o abrigo segue-o (procura de 0,5 em 0,5 s)")
	pedra.free()
	_passar(c, 0.6)
	_ok(c.abrigos().is_empty(), "o obstáculo sai da cena: o abrigo também")
	var muitas := []
	for i in 10:
		var o := _caixa(cena, 2.0 + 1.6 * i, 3.0, 0.8)
		c.registar_obstaculo(o)
		muitas.append(o)
	_passar(c, 0.6)
	var todos_vestidos := true
	for o in muitas:
		if (o as MeshInstance3D).material_overlay == null:
			todos_vestidos = false
	_ok(c.abrigos().size() == Clima.MAX_ABRIGOS and todos_vestidos, "10 obstáculos: os 10 vestem a camada, mas só 8 dão abrigo (MAX_ABRIGOS)")
	var vazio := Node3D.new()
	cena.add_child(vazio)
	for o in muitas:
		o.free()
	c.registar_obstaculo(vazio)
	_passar(c, 0.6)
	_ok(c.abrigos().is_empty(), "um obstáculo sem malha não dá abrigo")
	_libertar(c, cena)


func _teste_abrigo_em() -> void:
	print("abrigo_em(): onde a neve se junta")
	var cena := Node3D.new()
	var pedra := _caixa(cena, 6.0, 10.0)
	var c = _clima(cena)
	c.registar_obstaculo(pedra)
	c.definir("neve", "forte")
	c.avancar(DT)
	var leste := Vector2.RIGHT  # o vento sopra para +X
	var canto: float = c.abrigo_em(Vector2(0.3, 0.3), leste)
	var borda: float = c.abrigo_em(Vector2(14.0, 0.3), leste)
	var centro: float = c.abrigo_em(Vector2(14.0, 14.0), leste)
	var sota: float = c.abrigo_em(Vector2(7.3, 10.0), leste)
	var barla: float = c.abrigo_em(Vector2(4.7, 10.0), leste)
	var base: float = c.abrigo_em(Vector2(6.0, 10.6), leste)
	_ok(canto > borda and borda > centro and centro < 0.05, "canto %.2f > borda %.2f > centro aberto %.3f (varrido)" % [canto, borda, centro])
	_ok(sota > barla and barla > centro, "obstáculo: sotavento %.2f > barlavento %.2f > campo aberto" % [sota, barla])
	_ok(base > 0.4, "a base do obstáculo junta neve (%.2f)" % base)
	var oeste: float = c.abrigo_em(Vector2(0.3, 5.0), leste)
	var este: float = c.abrigo_em(Vector2(19.7, 5.0), leste)
	_ok(oeste > este, "a borda de onde o vento vem abriga mais do que a borda para onde vai (%.2f > %.2f)" % [oeste, este])
	var vira: float = c.abrigo_em(Vector2(4.7, 10.0), Vector2.LEFT)
	_ok(_perto(vira, sota, 0.05), "o vento vira para −X: o lado de lá do obstáculo passa a ser o abrigado (%.2f ≈ %.2f)" % [vira, sota])
	var maximo := 0.0
	for j in 41:
		for i in 41:
			maximo = maxf(maximo, c.abrigo_em(Vector2(i * 0.5, j * 0.5), leste))
	_ok(maximo <= 1.6 and maximo > 1.0, "em todo o campo, o abrigo fica em 0..1,6 (máximo %.2f)" % maximo)
	c.bordas_abrigo = 0.0
	pedra.free()
	_passar(c, 0.6)
	var zero := true
	for j in 21:
		for i in 21:
			if c.abrigo_em(Vector2(i, j), leste) != 0.0:
				zero = false
	_ok(zero, "sem bordas (bordas_abrigo 0) e sem obstáculos, o abrigo é 0 em todo o lado")
	_libertar(c, cena)


func _teste_neve_em() -> void:
	print("neve_em(): quanta neve há num ponto")
	var cena := Node3D.new()
	var pedra := _caixa(cena, 6.0, 10.0)
	var c = _clima(cena)
	c.registar_obstaculo(pedra)
	c.nevasca_guinada_graus = 0.0  # o rumo fica fixo em +X (os montes não rodam)
	c.definir_vento(0.0, 4.0)
	c.definir("neve", "forte")
	c.avancar(DT)
	c.definir_acumulacao(0.0, 0.8)
	c.definir_forte(0.0, 0.0, 0.0)
	var igual := true
	for p in [Vector2(0.3, 0.3), Vector2(14.0, 14.0), Vector2(7.3, 10.0)]:
		if c.neve_em(p) != c.neve:
			igual = false
	_ok(igual, "sem aglomerado, a neve é igual em todo o lado (= neve pousada, 0,8)")
	c.definir_acumulacao(0.0, 1.0)
	c.definir_forte(1.0, 0.0, 0.0)
	var canto: float = c.neve_em(Vector2(0.3, 0.3))
	var borda: float = c.neve_em(Vector2(14.0, 0.3))
	var sota: float = c.neve_em(Vector2(7.3, 10.0))
	var barla: float = c.neve_em(Vector2(4.7, 10.0))
	var centro: float = c.neve_em(Vector2(14.0, 14.0))
	_ok(canto > borda and borda > sota and sota > barla and barla > centro,
		"nevasca formada: canto %.2f > borda %.2f > sotavento %.2f > barlavento %.2f > centro %.2f" % [canto, borda, sota, barla, centro])
	_ok(canto > 1.0 and _perto(centro, 0.33, 0.03), "o canto faz monte (> 1) e o centro fica varrido (~0,33 do manto)")
	c.definir_forte(0.5, 0.0, 0.0)
	_ok(c.neve_em(Vector2(14.0, 14.0)) > centro and c.neve_em(Vector2(0.3, 0.3)) < canto, "a meio da aglomeração, o centro tem mais e o canto menos")
	_libertar(c, cena)


func _teste_grupo_obstaculo_na_arvore() -> void:
	print("O grupo «clima_obstaculo» (na árvore, com raiz_alvos)")
	var cena := Node3D.new()
	var a := Node3D.new()
	a.name = "A"
	var b := Node3D.new()
	b.name = "B"
	cena.add_child(a)
	cena.add_child(b)
	var pa := _caixa(a, 6.0, 10.0)
	var pb := _caixa(b, 14.0, 4.0)
	pa.add_to_group(Clima.GRUPO_OBSTACULO)
	pb.add_to_group(Clima.GRUPO_OBSTACULO)
	var c = Clima.new()
	c.raiz_alvos = NodePath("../A")
	cena.add_child(c)
	root.add_child(cena)  # entra na árvore; nada corre pelo _process (o callback não larga o quadro)
	c.rajadas = 0.0
	c.configurar_area(CENTRO, CAMPO)
	c.definir("neve", "forte")
	c.avancar(DT)
	var ab: Array[Vector4] = c.abrigos()
	_ok(ab.size() == 1 and ab[0].is_equal_approx(Vector4(6.0, 10.0, 0.5, 0.5)), "só o obstáculo do grupo debaixo da raiz dos alvos dá abrigo (%d)" % ab.size())
	_ok(pa.material_overlay != null and pb.material_overlay == null, "e só esse veste a camada")
	c.raiz_alvos = NodePath()
	_passar(c, 0.6)
	_ok(c.abrigos().size() == 2 and pb.material_overlay != null, "sem raiz_alvos (o pai): os dois")
	c.registar_obstaculo(pa)
	_passar(c, 0.6)
	_ok(c.abrigos().size() == 2, "um obstáculo no grupo e registado à mão conta uma vez")
	root.remove_child(cena)
	cena.free()


# ---------------------------------------------------------------- dormir, determinismo, só apresentação

func _teste_dorme_so_com_tudo_a_zero() -> void:
	print("O módulo só dorme com o estado forte todo a zero")
	var bons := true
	var nomes := ["aglomerado", "gelo", "água", "lama"]
	for k in 4:
		var c = _clima()
		var v := [0.0, 0.0, 0.0, 0.0]
		v[k] = 0.3
		c.definir_forte(v[0], v[1], v[2], v[3])
		c.avancar(DT)
		if c.parado() or not c.is_processing():
			bons = false
			printerr("        acordado falhou com ", nomes[k])
		_libertar(c)
	_ok(bons, "com só aglomerado, só gelo, só água ou só lama por derreter/escoar, o módulo fica acordado")
	var cena := Node3D.new()
	var chao := MeshInstance3D.new()
	chao.mesh = PlaneMesh.new()
	cena.add_child(chao)
	var c2 = _clima(cena)
	c2.registar_chao(chao)
	c2.segundos_transicao = 0.01
	c2.definir("neve", "forte")
	_passar(c2, 5.0)
	c2.desligar()
	c2.definir_acumulacao(0.0, 0.0)
	c2.definir_forte(0.0, 0.0, 0.0, 0.0)
	c2.avancar(DT)
	_ok(not c2.parado() and c2.vento_da_nevasca() > 0.9, "a nevasca acabou e tudo foi a zero, mas o vento da nevasca ainda sopra (%.2f): acordado" % c2.vento_da_nevasca())
	_passar(c2, 4.1)
	_ok(c2.parado() and not c2.is_processing() and chao.material_overlay == null and c2.vestidos().is_empty(),
		"deitado o vento (4 s), o módulo dorme e tira a camada do chão")
	_libertar(c2, cena)


## Um guião completo (nevasca → derrete → alaga → escoa) com um dado dt; devolve o estado ao longo do tempo.
func _guiao(dt: float) -> Array:
	var c = _clima()
	c.definir_bacias([Vector4(6.0, 6.0, 2.5, 0.09), Vector4(14.0, 13.0, 3.0, 0.08)])
	var r := []
	var plano := [["neve", "forte", 40.0], ["nenhum", "fraco", 10.0], ["chuva", "forte", 50.0], ["nenhum", "fraco", 60.0]]
	for etapa in plano:
		c.definir(etapa[0], etapa[1])
		for s in int(etapa[2] / 5.0):
			_passar(c, 5.0, dt)
			r.append([c.neve, c.molhado, c.aglomerado, c.gelo, c.agua, c.lama, c.lama_humida, c.vento_da_nevasca()])
	_libertar(c)
	return r


func _teste_deterministico() -> void:
	print("Determinístico: nada depende do passo de tempo da máquina")
	var a := _guiao(DT)
	var b := _guiao(DT)
	_ok(a == b and a.size() == 32, "o mesmo guião (nevasca 40 s → 10 s → alaga 50 s → 60 s) duas vezes: o mesmo estado, número a número")
	# As fases da drenagem com 3 passos diferentes: os mesmos instantes (a menos de um frame do passo maior).
	var f30 := _fases_da_drenagem(1.0 / 30.0)
	var f60 := _fases_da_drenagem(1.0 / 60.0)
	var f144 := _fases_da_drenagem(1.0 / 144.0)
	var iguais := true
	for k in ["seca_agua", "baca", "seco", "chao_seco"]:
		if absf(f30[k] - f60[k]) > 1.0 / 30.0 + 1e-3 or absf(f30[k] - f144[k]) > 1.0 / 30.0 + 1e-3:
			iguais = false
	_ok(iguais, "drenagem com dt 1/30, 1/60 e 1/144 s: água some aos %.2f / %.2f / %.2f s, lama baça aos %.2f / %.2f / %.2f, seco aos %.2f / %.2f / %.2f"
		% [f30["seca_agua"], f60["seca_agua"], f144["seca_agua"], f30["baca"], f60["baca"], f144["baca"], f30["seco"], f60["seco"], f144["seco"]])
	# A acumulação da nevasca e do alagamento, aos 30 s, com 1/30 e 1/144 s.
	var g30 := _guiao(1.0 / 30.0)
	var g144 := _guiao(1.0 / 144.0)
	var perto := true
	var pior := 0.0
	for i in g30.size():
		for k in g30[i].size():
			pior = maxf(pior, absf(float(g30[i][k]) - float(g144[i][k])))
	if pior > 0.02:
		perto = false
	_ok(perto, "o guião inteiro com dt 1/30 e 1/144 s: a maior diferença em qualquer valor é %.4f (≤ 0,02)" % pior)


## Tira os comentários de uma linha de GDScript (o # fora de aspas).
func _sem_comentario(linha: String) -> String:
	var aspas := ""
	var escapa := false
	for i in linha.length():
		var ch := linha[i]
		if aspas != "":
			if escapa:
				escapa = false
			elif ch == "\\":
				escapa = true
			elif ch == aspas:
				aspas = ""
		elif ch == "\"" or ch == "'":
			aspas = ch
		elif ch == "#":
			return linha.substr(0, i)
	return linha


func _teste_so_apresentacao_codigo() -> void:
	print("Só apresentação: o código do clima")
	var proibidos := RegEx.create_from_string("\\b(Estado|Rede|EstadoScript|RedeScript|FilaIntencoes)\\b|ROOM_|MASTER_|/root/|enviar_|montar_comando|get_singleton|WebSocket|HTTPRequest|FileAccess\\.open|ConfigFile")
	var achados := []
	var ficheiros := ["clima.gd", "integrador_vento.gd"]
	for ficheiro in ficheiros:
		var codigo := FileAccess.get_file_as_string("res://arte/clima/" + ficheiro)
		if codigo == "":
			achados.append(ficheiro + ": vazio")
			continue
		var n := 0
		for linha in codigo.split("\n"):
			n += 1
			var m := proibidos.search(_sem_comentario(linha))
			if m != null:
				achados.append("%s:%d «%s»" % [ficheiro, n, m.get_string()])
	_ok(achados.is_empty(), "clima.gd e integrador_vento.gd (sem os comentários): nenhuma referência ao Estado, à Rede, a mensagens do protocolo, a ficheiros ou à rede %s" % ("" if achados.is_empty() else str(achados)))
	var pre := RegEx.create_from_string("(preload|load)\\(\"([^\"]+)\"\\)")
	var deps := []
	for m in pre.search_all(FileAccess.get_file_as_string("res://arte/clima/clima.gd")):
		deps.append(m.get_string(2))
	var so_clima := true
	for d in deps:
		if not str(d).begins_with("res://arte/clima/"):
			so_clima = false
	_ok(so_clima and deps.size() >= 6, "clima.gd só carrega ficheiros do próprio módulo (%d: integrador e shaders)" % deps.size())


func _estado_de(no: Node) -> Dictionary:
	var r := {}
	for p in no.get_property_list():
		if int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			r[p["name"]] = var_to_str(no.get(p["name"]))
	return r


func _teste_so_apresentacao_estado_e_rede() -> void:
	print("Só apresentação: o Estado e a Rede não mexem com o clima forte")
	var estado := root.get_node_or_null("Estado")
	var rede := root.get_node_or_null("Rede")
	_ok(estado != null and rede != null, "os autoloads Estado e Rede estão na árvore")
	if estado == null or rede == null:
		return
	var sinais := [0]
	var conta := func(_a = null, _b = null, _c = null, _d = null): sinais[0] += 1
	for no in [estado, rede]:
		for s in no.get_signal_list():
			if no.get_script() != null and (no.get_script() as Script).has_script_signal(s["name"]):
				no.connect(s["name"], conta)
	var estado_antes := _estado_de(estado)
	var rede_antes := _estado_de(rede)
	# Uma arena pequena na árvore: chão, figura, obstáculo, bacias. O guião todo do clima forte, à mão.
	var cena := Node3D.new()
	var chao := MeshInstance3D.new()
	chao.mesh = PlaneMesh.new()
	chao.add_to_group(Clima.GRUPO_CHAO)
	cena.add_child(chao)
	var fig := Node3D.new()
	fig.add_to_group(Clima.GRUPO_FIGURA)
	var corpo := MeshInstance3D.new()
	corpo.mesh = CapsuleMesh.new()
	var mat_corpo := StandardMaterial3D.new()
	(corpo.mesh as CapsuleMesh).material = mat_corpo
	fig.add_child(corpo)
	fig.position = Vector3(6.0, 0.0, 6.0)
	cena.add_child(fig)
	var pedra := _caixa(cena, 12.0, 8.0)
	pedra.add_to_group(Clima.GRUPO_OBSTACULO)
	var c = Clima.new()
	cena.add_child(c)
	root.add_child(cena)
	c.configurar_area(CENTRO, CAMPO)
	c.definir_bacias([{"x": 6.0, "z": 6.0, "raio": 2.5, "fundura": 0.09}])
	var filhos_antes := cena.get_child_count()
	var pos_antes := fig.global_position
	c.definir("neve", "forte")
	_passar(c, 45.0)
	c.neve_em(Vector2(1.0, 1.0))
	c.abrigo_em(Vector2(12.5, 8.0))
	c.definir("chuva", "forte")
	_passar(c, 50.0)
	c.medir_alagamento(0.25)
	c.fundura_em(Vector2(6.0, 6.0))
	c.desligar()
	_passar(c, 30.0)
	c.definir_forte(1.0, 1.0, 1.0, 1.0)
	c.definir_acumulacao(1.0, 1.0)
	_passar(c, 1.0)
	_ok(sinais[0] == 0, "nenhum sinal do Estado nem da Rede disparou durante nevasca, alagamento e drenagem (%d)" % sinais[0])
	_ok(_estado_de(estado) == estado_antes, "o Estado ficou igual, variável a variável (%d variáveis)" % estado_antes.size())
	_ok(_estado_de(rede) == rede_antes, "a Rede ficou igual: nada na fila, nada enviado, a mesma ligação (%d variáveis)" % rede_antes.size())
	_ok(cena.get_child_count() == filhos_antes and fig.global_position == pos_antes and corpo.get_active_material(0) == mat_corpo and chao.get_active_material(0) == null,
		"na cena: nenhum nó novo fora do clima, a figura no mesmo sítio, nenhum material trocado (só overlays)")
	for no in [estado, rede]:
		for s in no.get_signal_list():
			if no.is_connected(s["name"], conta):
				no.disconnect(s["name"], conta)
	root.remove_child(cena)
	cena.free()
