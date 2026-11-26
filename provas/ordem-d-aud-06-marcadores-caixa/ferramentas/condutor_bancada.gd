extends SceneTree
## ORDEM-D-AUD-06-MARCADORES-CAIXA — o condutor de um cliente da bancada de rede (fora do jogo; não entra no CI).
##
##   godot --path rascunhos/cliente --resolution 1280x720 -s <este>.gd -- --servidor=127.0.0.1:8790 \
##         --papel=jogadora|mestre --saida=<pasta> --rotulo=antes|depois [--mover-para=x,y] [--orc-para=x,y]
##
## Abre a CENA PRINCIPAL do cliente (cenas/arena/arena.tscn), como em produção: a Rede lê o lugar que o porteiro da
## bancada deixou no user:// deste cliente e entra sozinha; o lugar do Mestre vai para o ecrã dele (ORDEM-D-AUD-16).
## Depois faz o que a jogadora / o Mestre fariam com o rato (prime os mesmos botões, pelo sinal `pressed`), grava
## capturas do render verdadeiro (a imagem da janela) e MEDE em píxeis da janela:
##   - o rectângulo da caixa da ordem (x, y, largura, altura);
##   - as casas do realce do Mover: quantas há, quantas se vêem no tabuleiro, e quantas ficam DEBAIXO da caixa;
##   - se a figura da vez (o pé e a cabeça) fica debaixo da caixa;
##   - para cada alvo do Ataque: o tamanho do marcador no ecrã e quantos píxeis da cor do alvo há à volta da figura.
## Tudo vai para <saida>/<papel>-<rotulo>-medidas.json. Nada do jogo muda; só os ficheiros na pasta de saída.
##
## A jogadora: espera a vez dela → j01 (início) → «Mover» → j02 → «Ataque» → j03 (+ recortes ×3 de cada alvo) →
##   [--mover-para: anda para essa casa] → «Encerrar» (a vez passa à criatura do Mestre) → espera o fim.
## O Mestre: espera o ecrã dele → m01 → espera a vez da criatura → aba Agir → m02 → «Mover» → m03 (a caixa sobre o
##   realce) → [--orc-para: move a criatura para essa casa → espera as opções novas → m04 (os alvos, + recortes)].

const ESPERA_MAX_S := 150.0
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")

var _saida := ""
var _papel := ""
var _rotulo := ""
var _medidas: Dictionary = {}
var _falhas := 0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _arg(nome: String, omissao: String = "") -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % nome):
			return a.substr(nome.length() + 3)
	return omissao


func _casa_arg(nome: String) -> Vector2i:
	var t := _arg(nome)
	if t == "":
		return Vector2i(-1, -1)
	var p := t.split(",")
	return Vector2i(int(p[0]), int(p[1]))


func _diz(t: String) -> void:
	print("[condutor %s %s] %s" % [_papel, _rotulo, t])


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	await create_timer(s).timeout


func _esperar(cond: Callable, s: float, o_que: String) -> bool:
	var t0 := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t0 > int(s * 1000.0):
			_diz("FALHA: esperei %d s por «%s»" % [int(s), o_que])
			_falhas += 1
			return false
		await process_frame
	return true


func _gravar(nome: String) -> Image:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var caminho := _saida.path_join("%s-%s.png" % [nome, _rotulo])
	img.save_png(caminho)
	_diz("captura %s (%d×%d)" % [caminho.get_file(), img.get_width(), img.get_height()])
	return img


## Rectângulo de um Control em píxeis da janela (a imagem da captura).
func _px(c: Control) -> Rect2:
	return root.get_final_transform() * c.get_global_rect()


func _r(r: Rect2) -> Dictionary:
	return {"x": roundi(r.position.x), "y": roundi(r.position.y), "largura": roundi(r.size.x), "altura": roundi(r.size.y)}


## Uma cópia da captura com um rectângulo desenhado (contorno de 3 px) — só para o olho; a medida está no JSON.
func _anotar(img: Image, rects: Array, nome: String) -> void:
	var a := img.duplicate() as Image
	for par in rects:
		var r: Rect2 = par[0]
		var cor: Color = par[1]
		for k in 3:
			var x0 := clampi(int(r.position.x) + k, 0, a.get_width() - 1)
			var y0 := clampi(int(r.position.y) + k, 0, a.get_height() - 1)
			var x1 := clampi(int(r.end.x) - 1 - k, 0, a.get_width() - 1)
			var y1 := clampi(int(r.end.y) - 1 - k, 0, a.get_height() - 1)
			for x in range(x0, x1 + 1):
				a.set_pixel(x, y0, cor)
				a.set_pixel(x, y1, cor)
			for y in range(y0, y1 + 1):
				a.set_pixel(x0, y, cor)
				a.set_pixel(x1, y, cor)
	a.save_png(_saida.path_join("%s-%s.png" % [nome, _rotulo]))


## Um recorte ×3 à volta de um ponto da captura (para se ver o marcador de perto).
func _recorte(img: Image, centro: Vector2, meio: int, nome: String) -> Rect2i:
	var r := Rect2i(int(centro.x) - meio, int(centro.y) - meio, meio * 2, meio * 2)
	r = r.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if r.size.x <= 0 or r.size.y <= 0:
		return r
	var c := img.get_region(r)
	c.resize(r.size.x * 3, r.size.y * 3, Image.INTERPOLATE_NEAREST)
	c.save_png(_saida.path_join("%s-%s.png" % [nome, _rotulo]))
	return r


## Píxeis «cor de alvo» (vermelho forte: r alto, g e b baixos) num rectângulo da captura.
func _pixeis_alvo(img: Image, r: Rect2i) -> int:
	var n := 0
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			var c := img.get_pixel(x, y)
			if c.r > 0.7 and c.g < 0.45 and c.b < 0.45 and c.r - c.g > 0.35:
				n += 1
	return n


## A caixa (em píxeis) dos pontos 3D projectados por `proj` (Callable Vector3 -> Vector2 ou null).
func _caixa_de_pontos(pontos: Array, proj: Callable) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in pontos:
		var s = proj.call(p)
		if s == null:
			continue
		lo = Vector2(minf(lo.x, s.x), minf(lo.y, s.y))
		hi = Vector2(maxf(hi.x, s.x), maxf(hi.y, s.y))
	return Rect2(lo, hi - lo) if lo.x < INF else Rect2()


## As casas da grelha (largura × altura) cujo centro, no ecrã, fica dentro de `rc` (e dentro de `area`): quantas, e o
## rectângulo de casas que ocupam (x mín–máx, y mín–máx).
func _casas_sob(w: int, h: int, centro: Callable, proj: Callable, rc: Rect2, area: Rect2) -> Dictionary:
	var n := 0
	var lo := Vector2i(9999, 9999)
	var hi := Vector2i(-1, -1)
	for y in h:
		for x in w:
			var s = proj.call(centro.call(Vector2i(x, y)))
			if s != null and area.has_point(s) and rc.has_point(s):
				n += 1
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	return {"casas": n, "x": [lo.x, hi.x] if n > 0 else [], "y": [lo.y, hi.y] if n > 0 else []}


func _cantos(aabb: AABB) -> Array:
	var r: Array = []
	for i in 8:
		r.append(aabb.position + Vector3(aabb.size.x * (i & 1), aabb.size.y * ((i >> 1) & 1), aabb.size.z * ((i >> 2) & 1)))
	return r


## Os cantos (no mundo) das malhas visíveis de um nó.
func _pontos_malhas(no: Node) -> Array:
	var r: Array = []
	var pilha: Array = [no]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as MeshInstance3D).is_visible_in_tree():
			var mi := n as MeshInstance3D
			r.append_array(_cantos(mi.global_transform * mi.mesh.get_aabb()))
		for f in n.get_children():
			pilha.append(f)
	return r


func _correr() -> void:
	_saida = _arg("saida")
	_papel = _arg("papel")
	_rotulo = _arg("rotulo", "depois")
	DirAccess.make_dir_recursive_absolute(_saida)
	_medidas = {"papel": _papel, "rotulo": _rotulo, "janela": [root.size.x, root.size.y], "capturas": {}}
	# A sessão 0 (serviço) deste PC tem um ecrã virtual de 1024×768, que corta o --resolution: a janela é posta no
	# tamanho da bancada à mão (jogadora 1280×720, Mestre 1600×900), antes de a cena abrir.
	var jt := _arg("janela", "")
	if jt != "":
		var wh := jt.split("x")
		DisplayServer.window_set_max_size(Vector2i(4096, 4096))
		DisplayServer.window_set_size(Vector2i(int(wh[0]), int(wh[1])))
		await _quadros(3)
	_medidas["janela"] = [root.size.x, root.size.y]
	change_scene_to_file("res://cenas/arena/arena.tscn")
	await _quadros(3)
	if _papel == "mestre":
		await _mestre()
	else:
		await _jogadora()
	_medidas["falhas"] = _falhas
	var f := FileAccess.open(_saida.path_join("%s-%s-medidas.json" % [_papel, _rotulo]), FileAccess.WRITE)
	f.store_string(JSON.stringify(_medidas, "  ", false))
	f.close()
	_diz("fim (%d falha(s))" % _falhas)
	quit(1 if _falhas > 0 else 0)


# ---------------------------------------------------------------- a jogadora

func _arena():
	var c = current_scene
	return c if c != null and c.has_method("definir_modo") else null


func _jogadora() -> void:
	var est: Node = root.get_node("Estado")
	var rede: Node = root.get_node("Rede")
	var pronta := func():
		var a = _arena()
		return a != null and est.fase == "combate" and est.minha_figura_id != "" and a._nos.has(est.minha_figura_id) \
			and str(est.vez_id) == est.minha_figura_id and not est.opcoes_validas().is_empty()
	if not await _esperar(pronta, ESPERA_MAX_S, "a vez dela, com opções"):
		return
	await _segundos(3.0)  # a câmara assenta na figura dela (D-AUD-05)
	var a = _arena()
	var hud = a.hud
	var cam: Camera3D = a.camera
	var proj := func(p: Vector3):
		return null if cam.is_position_behind(p) else root.get_final_transform() * cam.unproject_position(p)
	var area := Rect2(Vector2.ZERO, Vector2(root.size))
	await _gravar("j01-jog-inicio")
	var caixa: Control = hud._caixa
	var rc := _px(caixa)
	_medidas["caixa_inicio"] = _r(rc)
	_medidas["grelha_debaixo_da_caixa_inicio"] = _casas_sob(a.largura, a.altura, a.centro_casa, proj, rc, area)

	# Mover: o realce das casas alcançáveis e a caixa.
	hud._b_mover.pressed.emit()
	await _segundos(1.0)
	var img := await _gravar("j02-jog-mover")
	rc = _px(caixa)
	var casas: Array = a._casas.keys()
	var sob := []
	var no_ecra := 0
	for c in casas:
		var s = proj.call(a.centro_casa(c))
		if s != null and area.has_point(s):
			no_ecra += 1
			if rc.has_point(s):
				sob.append([c.x, c.y])
	var me: Node3D = a._nos.get(est.minha_figura_id)
	var pe = proj.call(me.global_position)
	var cabeca = proj.call(me.global_position + Vector3(0, 1.9, 0))
	_medidas["mover"] = {"caixa": _r(rc), "casas_realce": casas.size(), "casas_no_ecra": no_ecra,
		"grelha_debaixo_da_caixa": _casas_sob(a.largura, a.altura, a.centro_casa, proj, rc, area),
		"casas_debaixo_da_caixa": sob.size(), "quais": sob,
		"figura_pe_px": [roundi(pe.x), roundi(pe.y)] if pe != null else null,
		"figura_debaixo_da_caixa": (pe != null and rc.has_point(pe)) or (cabeca != null and rc.has_point(cabeca))}
	_anotar(img, [[rc, Color(1, 0, 1)]], "j02a-jog-mover-caixa-medida")
	_diz("mover: %s" % JSON.stringify(_medidas["mover"]))

	# Andar para perto do alvo debaixo de água (o orc no fundo do lago está a mais de 9 m, o alcance dela): a casa do
	# realce mais perto da criatura mais funda; empate → a mais funda. A opção é do servidor.
	if _arg("andar-antes") == "auto":
		var Rl = load("res://mapa/floresta/relevo_floresta.gd")
		var alvo_c := Vector2i(-1, -1)
		var fmax := -1.0
		for fid in est.figuras:
			var ff: Dictionary = est.figuras[fid]
			if fid == est.minha_figura_id or str(ff.get("lado", "")) == "jogadora":
				continue
			var cc: Vector2i = est.casa_de(ff)
			var pp: Vector3 = a.centro_casa(cc)
			if Rl.lago_fundura(pp.x, pp.z) > fmax:
				fmax = Rl.lago_fundura(pp.x, pp.z)
				alvo_c = cc
		var melhor := Vector2i(-1, -1)
		var chave := [INF, INF]
		for c in a._casas:
			var d := maxi(absi(c.x - alvo_c.x), absi(c.y - alvo_c.y))
			var pc: Vector3 = a.centro_casa(c)
			var k := [float(d), -Rl.lago_fundura(pc.x, pc.z)]
			if d >= 1 and (k[0] < chave[0] or (k[0] == chave[0] and k[1] < chave[1])):
				chave = k
				melhor = c
		_diz("andar para %s (a %d casas da criatura em %s, %.2f m de água)" % [melhor, int(chave[0]), alvo_c, -chave[1]])
		var rev0 = est.revisao
		a.enviar_acao({"tipo": "mover", "destino": {"x": melhor.x, "y": melhor.y}})
		await _esperar(func(): return est.revisao != rev0 and est.casa_de(est.figuras.get(est.minha_figura_id)) == melhor 			and not est.opcoes_validas().is_empty(), 20.0, "andar para %s" % melhor)
		await _segundos(2.0)
		var pm: Vector3 = a.centro_casa(melhor)
		_medidas["andou"] = {"casa": [melhor.x, melhor.y], "fundura_agua_m": snappedf(Rl.lago_fundura(pm.x, pm.z), 0.01)}
		await _gravar("j03-jog-andou")

	# Ataque: os marcadores de alvo.
	if not hud._b_ataque.disabled:
		hud._b_ataque.pressed.emit()
		await _segundos(1.0)
		img = await _gravar("j04-jog-ataque-alvos")
		var alvos := {}
		var Relevo = load("res://mapa/floresta/relevo_floresta.gd")
		for fid in a._alvos:
			var no: Node3D = a._nos.get(fid)
			if no == null:
				continue
			var p: Vector3 = no.global_position
			var fundura: float = Relevo.lago_fundura(p.x, p.z)
			var pontos: Array = []
			var marcas: Dictionary = a.marcadores_alvo() if a.has_method("marcadores_alvo") else {}
			if marcas.has(fid):
				pontos = _pontos_malhas(marcas[fid])
			else:
				# antes: o quadrado plano de 0,9 casa no relevo
				var cc: Vector3 = a.centro_casa(est.casa_de(est.figuras.get(fid)))
				var m: float = a.casa_m * 0.45
				for d in [Vector2(-m, -m), Vector2(m, -m), Vector2(m, m), Vector2(-m, m)]:
					pontos.append(Vector3(cc.x + d.x, a.altura_chao(cc.x + d.x, cc.z + d.y), cc.z + d.y))
			var rm := _caixa_de_pontos(pontos, proj)
			var centro = proj.call(p + Vector3(0, 1.0, 0))
			var rr := Rect2i()
			if centro != null:
				rr = _recorte(img, centro, 70, "j04z-jog-alvo-%s-x3" % str(est.figuras[fid].get("nomePublico", fid)).validate_node_name())
			alvos[fid] = {"nome": est.figuras[fid].get("nomePublico", ""), "casa": [int(est.figuras[fid].get("x")), int(est.figuras[fid].get("y"))],
				"fundura_agua_m": snappedf(fundura, 0.01), "pe_y_m": snappedf(p.y, 0.01), "nivel_agua_m": snappedf(Relevo.nivel_lago(), 0.001),
				"marcador": "anel+seta" if marcas.has(fid) else "quadrado plano no relevo",
				"marcador_px": [roundi(rm.size.x), roundi(rm.size.y)], "pixeis_cor_de_alvo_no_recorte": _pixeis_alvo(img, rr) if rr.size.x > 0 else 0}
		_medidas["ataque"] = {"alvos": alvos}
		_diz("ataque: %s" % JSON.stringify(alvos))
	else:
		_diz("sem ataques nas opções")
		if _arg("exigir-ataque") == "1":
			_falhas += 1

	# Encerrar: a vez passa à criatura (o Mestre joga-a à mão).
	await _esperar(func(): return not est.opcoes_validas().is_empty(), 10.0, "opções para encerrar")
	var rev2 = est.revisao
	a.enviar_acao({"tipo": "encerrar"})
	await _esperar(func(): return str(est.vez_id) != est.minha_figura_id, 20.0, "a vez passar")
	_diz("encerrou; a vez é de %s" % est.vez_id)
	# Fica ligada até o Mestre acabar (o ficheiro de fim dele), para a mesa não pausar por falta dela.
	var fim := _saida.path_join("fim-mestre-%s.txt" % _rotulo)
	var ficar := float(_arg("ficar-s", "120"))
	var t0 := Time.get_ticks_msec()
	while not FileAccess.file_exists(fim) and Time.get_ticks_msec() - t0 < int(ficar * 1000.0):
		await _segundos(0.5)
	await _gravar("j05-jog-fim")


# ---------------------------------------------------------------- o Mestre

func _mestre() -> void:
	var est: Node = root.get_node("Estado")
	var e_mestre := func():
		var c = current_scene
		return c != null and c.has_method("aplicar_vista") and c.get("_arena") != null and not (c.vista as Dictionary).is_empty()
	if not await _esperar(e_mestre, ESPERA_MAX_S, "o ecrã do Mestre com a vista"):
		return
	var m = current_scene
	await _segundos(2.0)
	if m._aviso_primeira != null and m._aviso_primeira.visible:
		m._aviso_entendido()  # o «Entendi» do aviso da 1.ª vez
		await _quadros(2)
	await _gravar("m01-mestre-inicio")
	# Espera a vez da criatura, com as opções dela.
	var vez_criatura := func():
		var v = m.vista
		var vez := str(v.get("vezId", "")) if v.get("vezId") is String else ""
		var f: Dictionary = Modelo.figura(v, vez) if vez != "" else {}
		var op: Dictionary = est.opcoes_validas()
		return not f.is_empty() and str(f.get("lado", "")) != "jogadora" and str(op.get("vezId", "")) == vez
	if not await _esperar(vez_criatura, ESPERA_MAX_S, "a vez da criatura, com opções"):
		_fim_mestre()
		return
	var vez := str(m.vista.get("vezId"))
	m.mostrar_aba(m._aba_agir)
	await _segundos(2.0)
	await _gravar("m02-mestre-agir")
	var arena = m._arena
	var cam: Camera3D = arena.camera
	var tab: Control = m._tabuleiro
	var sv: SubViewport = tab.get_child(0) as SubViewport
	var proj := func(p: Vector3):
		if cam.is_position_behind(p):
			return null
		var s: Vector2 = cam.unproject_position(p) * (tab.size / Vector2(sv.size))
		return root.get_final_transform() * (tab.get_global_rect().position + s)
	var rt := _px(tab)
	_medidas["tabuleiro"] = _r(rt)
	# Mover: o realce do Mover e a caixa da ordem (C1-3).
	m._aba_agir.iniciar_mover()
	await _segundos(1.0)
	var img := await _gravar("m03-mestre-mover")
	var rc := _px(m._caixa)
	var casas: Array = arena.casas_destacadas()
	var sob := []
	var no_ecra := 0
	for c in casas:
		var s = proj.call(arena.centro_da_casa(c))
		if s != null and rt.has_point(s):
			no_ecra += 1
			if rc.has_point(s):
				sob.append([c.x, c.y])
	var no: Node3D = arena._nos.get(vez)
	var pe = proj.call(no.global_position) if no != null else null
	var cabeca = proj.call(no.global_position + Vector3(0, 1.9, 0)) if no != null else null
	_medidas["mover"] = {"caixa": _r(rc), "casas_realce": casas.size(), "casas_no_tabuleiro": no_ecra,
		"grelha_debaixo_da_caixa": _casas_sob(arena.largura, arena.altura, arena.centro_da_casa, proj, rc, rt),
		"casas_debaixo_da_caixa": sob.size(), "quais": sob, "figura_da_vez": vez,
		"figura_pe_px": [roundi(pe.x), roundi(pe.y)] if pe != null else null,
		"figura_debaixo_da_caixa": (pe != null and rc.has_point(pe)) or (cabeca != null and rc.has_point(cabeca))}
	_anotar(img, [[rc, Color(1, 0, 1)], [rt, Color(0, 1, 1)]], "m03a-mestre-mover-caixa-medida")
	_diz("mover: %s" % JSON.stringify(_medidas["mover"]))
	# Opcional: mover a criatura para uma casa e mostrar os alvos dela.
	var para := _casa_arg("orc-para") if _arg("orc-para") != "auto" else Vector2i(-1, -1)
	if _arg("orc-para") == "auto":
		# a casa do realce ao lado de uma jogadora (a mais funda); se nenhuma, a mais perto dela
		var Rl = load("res://mapa/floresta/relevo_floresta.gd")
		var chave := [INF, INF]
		for f in Modelo.figuras(m.vista):
			if not (f is Dictionary) or str(f.get("lado", "")) != "jogadora" or f.get("colocada") != true:
				continue
			var cj := Vector2i(int(f.get("x")), int(f.get("y")))
			for c in casas:
				var d := maxi(absi(c.x - cj.x), absi(c.y - cj.y))
				var pc: Vector3 = arena.centro_da_casa(c)
				var k := [float(d), -Rl.lago_fundura(pc.x, pc.z)]
				if d >= 1 and (k[0] < chave[0] or (k[0] == chave[0] and k[1] < chave[1])):
					chave = k
					para = c
		_diz("a criatura anda para %s (a %d casas de uma jogadora)" % [para, int(chave[0])])
	if para.x >= 0:
		var rev = est.revisao
		m.casa_tocada(para)  # o toque do Mestre na casa (o «Mover» está armado)
		var com_ataques := func():
			var op: Dictionary = est.opcoes_validas()
			return est.revisao != rev and str(op.get("vezId", "")) == vez and op.get("ataques") is Array and not op["ataques"].is_empty()
		if await _esperar(com_ataques, 20.0, "as opções com ataques depois de mover"):
			await _segundos(1.5)
			img = await _gravar("m04-mestre-alvos")
			var alvos := {}
			var Relevo = load("res://mapa/floresta/relevo_floresta.gd")
			var marcas: Dictionary = arena.marcadores_alvo() if arena.has_method("marcadores_alvo") else {}
			for at in est.opcoes_validas().get("ataques", []):
				var fid := str(at.get("alvoId", ""))
				var nf: Node3D = arena._nos.get(fid)
				if nf == null or alvos.has(fid):
					continue
				var p: Vector3 = nf.global_position
				var rm := _caixa_de_pontos(_pontos_malhas(marcas[fid]), proj) if marcas.has(fid) else Rect2()
				var centro = proj.call(p + Vector3(0, 1.0, 0))
				var rr := Rect2i()
				if centro != null:
					rr = _recorte(img, centro, 80, "m04z-mestre-alvo-x3")
				alvos[fid] = {"fundura_agua_m": snappedf(Relevo.lago_fundura(p.x, p.z), 0.01), "pe_y_m": snappedf(p.y, 0.01),
					"marcador": "anel+seta" if marcas.has(fid) else "nenhum (só o botão «Atacar» na aba Agir)",
					"marcador_px": [roundi(rm.size.x), roundi(rm.size.y)], "pixeis_cor_de_alvo_no_recorte": _pixeis_alvo(img, rr) if rr.size.x > 0 else 0,
					"caixa": _r(_px(m._caixa))}
			_medidas["alvos"] = alvos
			_diz("alvos: %s" % JSON.stringify(alvos))
	_fim_mestre()


func _fim_mestre() -> void:
	var f := FileAccess.open(_saida.path_join("fim-mestre-%s.txt" % _rotulo), FileAccess.WRITE)
	f.store_string("fim")
	f.close()
