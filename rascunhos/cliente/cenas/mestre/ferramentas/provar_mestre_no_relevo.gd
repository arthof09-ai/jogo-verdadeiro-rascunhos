extends SceneTree
## provar_mestre_no_relevo.gd — Ordem 45. A PROVA do terreno e da grelha no ECRÃ DO MESTRE (cenas/mestre/mestre.tscn,
## a arena 3D do SubViewport), sem janela. Mede o que a Ordem 42 mediu na arena do jogador
## (cenas/arena/ferramentas/provar_assentamento.gd) e compara, casa a casa, com a arena do jogador e com o terreno
## que o servidor lê (servidor/dados/terreno-floresta.json, Ordem 44):
##   1. a grelha no mesmo sítio do mapa: a origem e cada centro de casa contra o relevo, contra a arena do jogador
##      e contra a `alturaM` do servidor;
##   2. cada vértice das camadas coladas ao chão (linhas, destaques, contornos, fogo) contra o relevo;
##   3. o pé de cada figura (o marcador do site): a raiz no `pe_figura` da arena do jogador e no `peM` do servidor;
##      o anel e a sombra de contacto no plano da base; o fundo do corpo no plano; a régua independente (129
##      pontos) do plano contra o relevo, no raio da pegada, no da sombra (0,5) e no do anel (0,56); nas 6 casas
##      da encosta do outeiro e nas outras;
##   4. o toque: o centro de cada casa, visto pela câmara da mesa do Mestre, volta à MESMA casa;
##   5. as casas do jogo que o mapa bloqueia (0, como na arena do jogador);
##   6. um céu só no mundo do Mestre, e é o do mapa;
##
##   godot --headless --path cliente -s res://cenas/mestre/ferramentas/provar_mestre_no_relevo.gd [-- --json=caminho]
## Sai com 0 se tudo passa, 1 se algo falha.

const CENA_MESTRE := "res://cenas/mestre/mestre.tscn"
const CENA_ARENA := "res://cenas/arena/arena.tscn"
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const GrelhaMapa := preload("res://mapa/floresta/grelha_floresta.gd")
const Assentamento := preload("res://cenas/arena/assentamento.gd")
## As 6 casas da encosta do outeiro na grelha 20 × 20 de 1,5 m (Ordens 42 e 44).
const CampoDaMesa := preload("res://cenas/arena/campo_da_mesa.gd")
const SEIS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]

var _falhas := 0
var _json := {}


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		_falhas += 1
	print(("  ok    " if cond else "  FALHA ") + texto)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


## A régua do pé da Ordem 44: [enterra, flutua] do plano de altura `y` no centro (x, z) e inclinação `g`, no centro
## e em 4 anéis de 32 pontos até ao raio `r`.
static func _medir_base(x: float, z: float, y: float, g: Vector2, r: float) -> Array:
	var enterra := 0.0
	var flutua := 0.0
	var pts: Array[Vector2] = [Vector2.ZERO]
	for anel in [0.25, 0.5, 0.75, 1.0]:
		for k in 32:
			var a := TAU * k / 32.0
			pts.append(Vector2(cos(a), sin(a)) * r * anel)
	for q in pts:
		var d := Relevo.altura(x + q.x, z + q.y) - (y + g.dot(q))
		enterra = maxf(enterra, d)
		flutua = maxf(flutua, -d)
	return [enterra, flutua]


## A vista de prova: a fixture do servidor (cenário «mestre»), com as figuras de 3 em 3 casas, mais as 6 da
## encosta, um fogo, a vez na primeira.
func _vista(base: Dictionary, w: int, h: int, casa: float) -> Dictionary:
	var v: Dictionary = base.duplicate(true)
	v["mapa"] = {"largura": w, "altura": h, "casaM": casa}
	var molde: Dictionary = {}
	for f in v["mestre"]["figuras"]:
		if f.get("colocada") == true:
			molde = f
			break
	var figuras: Array = []
	var casas: Array[Vector2i] = []
	for y in range(0, h, 3):
		for x in range(0, w, 3):
			casas.append(Vector2i(x, y))
	for c in SEIS:
		if not casas.has(c):
			casas.append(c)
	var k := 0
	for c in casas:
		var f: Dictionary = molde.duplicate(true)
		f["id"] = "prova-%d" % k
		f["nome"] = "P%d" % k
		f["x"] = c.x
		f["y"] = c.y
		f["colocada"] = true
		f["vivo"] = true
		f["caido"] = k % 11 == 5  # algumas caídas: deitam-se no plano da base
		figuras.append(f)
		k += 1
	v["mestre"]["figuras"] = figuras
	v["mestre"]["fogo"] = {"casas": [{"x": 5, "y": 5, "combustivel": 2}, {"x": 0, "y": 0, "combustivel": 1}], "aArder": []}
	v["vezId"] = "prova-0"
	return v


func _correr() -> void:
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var fx = JSON.parse_string(FileAccess.get_file_as_string(p))
	var pt := ProjectSettings.globalize_path("res://").path_join("../servidor/dados/terreno-floresta.json")
	var terreno = JSON.parse_string(FileAccess.get_file_as_string(pt))
	if not (fx is Dictionary) or not (terreno is Dictionary):
		printerr("sem a fixture do Mestre ou sem o terreno do servidor")
		quit(1)
		return
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede._ativo = true  # sem rede: a arena do jogador (para comparar) não tenta ligar-se
	rede.papel = "mestre"
	root.size = Vector2i(1920, 1080)
	var m = (load(CENA_MESTRE) as PackedScene).instantiate()
	m.enviar_fn = func(_t, _c, _r): return ""
	m.pedir_vista_fn = func(): pass
	root.add_child(m)
	await _quadros(2)
	var a = m._arena
	for grelha in [[20, 20, 1.5], [30, 30, 1.5]]:
		await _medir_grelha(m, a, fx["mestre"]["vista"], terreno, grelha[0], grelha[1], grelha[2])
	m.queue_free()
	await _quadros(2)

	var saida := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--json="):
			saida = arg.trim_prefix("--json=")
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		f.store_string(JSON.stringify(_json, " "))
		f.close()
		print("medição escrita em %s" % saida)
	print("%s" % ("TUDO PASSOU" if _falhas == 0 else "%d FALHAS" % _falhas))
	quit(1 if _falhas > 0 else 0)


func _medir_grelha(m, a, base: Dictionary, terreno: Dictionary, w: int, h: int, casa: float) -> void:
	var nome := "%dx%d de %s m" % [w, h, str(casa)]
	print("== Ordem 45: o ecrã do Mestre no relevo — grelha %s ==" % nome)
	var vista := _vista(base, w, h, casa)
	m.aplicar_vista(vista)
	var opcoes: Array[Vector2i] = []
	for y in h:
		for x in w:
			opcoes.append(Vector2i(x, y))
	await _quadros(3)
	var reg := {}

	# A arena do jogador com a mesma grelha (para comparar casa a casa): o mesmo mapa, a mesma regra.
	var est = root.get_node("Estado")
	est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "prova-45", "seq": 1, "revision": 1,
		"fase": "combate", "mapa": {"largura": w, "altura": h, "casaM": casa}, "figuras": [], "ambiente": {}})
	var jog = (load(CENA_ARENA) as PackedScene).instantiate()
	root.add_child(jog)
	await _quadros(3)
	var srv: Dictionary = {}
	for g in terreno["grelhas"]:
		if int(g["largura"]) == w and int(g["altura"]) == h and is_equal_approx(float(g["casaM"]), casa):
			srv = g
	_ok(not srv.is_empty(), "o servidor tem esta grelha no pacote do terreno")

	# 1. a grelha no mesmo sítio
	var tam := Vector2(w * casa, h * casa)
	_ok(a.origem == Assentamento.origem_no_mapa(tam, casa) and a.origem == jog.origem,
		"origem da grelha (canto NO): Mestre (%.2f, %.2f) = jogador (%.2f, %.2f)" % [a.origem.x, a.origem.y, jog.origem.x, jog.origem.y])
	_ok(a.mapa != null and a.mapa.zona_jogo.is_equal_approx(Rect2(a.origem, tam)) and a.mapa.zona_jogo.is_equal_approx(jog.mapa.zona_jogo),
		"o mapa do Mestre foi feito para a mesma zona jogável do jogador %s" % [a.mapa.zona_jogo])
	var d_relevo := 0.0
	var d_jog := 0.0
	var d_srv := 0.0
	for y in h:
		for x in w:
			var c := Vector2i(x, y)
			var q: Vector3 = a.centro_da_casa(c)
			d_relevo = maxf(d_relevo, absf(q.y - Relevo.altura(q.x, q.z)))
			d_jog = maxf(d_jog, (q - jog.centro_casa(c)).length())
			if not srv.is_empty():
				d_srv = maxf(d_srv, absf(q.y - float(srv["alturaM"][y * w + x])))
	_ok(d_relevo == 0.0, "centro de casa − relevo: maior %.6f m (%d casas)" % [d_relevo, w * h])
	_ok(d_jog == 0.0, "centro de casa Mestre − jogador: maior %.6f m (%d casas)" % [d_jog, w * h])
	_ok(d_srv < 1e-9, "centro de casa Mestre − alturaM do servidor: maior %s m" % str(d_srv))
	reg["centro_menos_relevo_m"] = d_relevo
	reg["centro_mestre_menos_jogador_m"] = d_jog
	reg["centro_mestre_menos_servidor_m"] = d_srv

	# 2. o que se cola ao chão (os destaques pedem-se aqui: o ecrã do Mestre limpa-os quando a vista muda)
	a.destacar(opcoes)
	var camadas := {"Linhas": [a.get_node("Grelha/Linhas"), a.LEVANTA_LINHAS], "Destaques": [a.get_node("Destaques"), a.LEVANTA_DESTAQUE],
		"ContornosDestaques": [a.get_node("ContornosDestaques"), a.LEVANTA_CONTORNO], "Fogo": [a.get_node("Fogo"), a.LEVANTA_FOGO]}
	var reg_camadas := {}
	for nm in camadas:
		var mi: MeshInstance3D = camadas[nm][0]
		var lev: float = camadas[nm][1]
		if mi.mesh == null:
			_ok(false, "%s sem malha" % nm)
			continue
		var v: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var lo := INF
		var hi := -INF
		for q in v:
			var dh := q.y - Relevo.altura(q.x, q.z)
			lo = minf(lo, dh)
			hi = maxf(hi, dh)
		_ok(absf(lo - lev) < 0.0001 and absf(hi - lev) < 0.0001, "%s: %d vértices, todos a %.3f m do relevo (de %.4f a %.4f)" % [nm, v.size(), lev, lo, hi])
		reg_camadas[nm] = {"vertices": v.size(), "acima_min_m": lo, "acima_max_m": hi}
	reg["camadas"] = reg_camadas
	# as linhas do Mestre e as do jogador: os mesmos vértices (a mesma função, outro levantamento)
	var vm: PackedVector3Array = (a.get_node("Grelha/Linhas") as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	# (na arena do jogador, a grelha refeita deixa o «Linhas» novo com outro nome enquanto o velho espera pela
	# fila de libertação: procura-se a malha de linhas viva)
	var linhas_j: MeshInstance3D = null
	for n in jog.get_node("Grelha").get_children():
		if n is MeshInstance3D and (n as MeshInstance3D).mesh is ImmediateMesh and not n.is_queued_for_deletion():
			linhas_j = n
	var vj: PackedVector3Array = linhas_j.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var d_linhas := 0.0
	if vm.size() == vj.size():
		for i in vm.size():
			d_linhas = maxf(d_linhas, (vm[i] - Vector3(0.0, a.LEVANTA_LINHAS, 0.0) - (vj[i] - Vector3(0.0, jog.LEVANTA_M, 0.0))).length())
	_ok(vm.size() == vj.size() and d_linhas < 0.000001, "linhas da grelha Mestre − jogador: %d / %d vértices, maior desvio %.6f m" % [vm.size(), vj.size(), d_linhas])
	reg["linhas_mestre_menos_jogador_m"] = d_linhas

	# 3. o pé das figuras (Ordem 44, parte B, no marcador do site)
	var r_pe: float = Assentamento.raio_pegada(casa)
	var fora := 0
	var d_pe_jog := 0.0
	var d_pe_srv := 0.0
	var plano_corpo := 0.0
	var pior := {"pegada": [0.0, 0.0], "contacto": [0.0, 0.0], "anel": [0.0, 0.0]}
	var pior_bloq := {"pegada": [0.0, 0.0], "contacto": [0.0, 0.0], "anel": [0.0, 0.0]}
	var n_bloq := 0
	var pior_seis := {"pegada": [0.0, 0.0], "contacto": [0.0, 0.0], "anel": [0.0, 0.0]}
	var casas_fig: Array = []
	for f in vista["mestre"]["figuras"]:
		var id := str(f["id"])
		var c := Vector2i(int(f["x"]), int(f["y"]))
		var no: Node3D = a._nos.get(id)
		if no == null:
			fora += 1
			continue
		var pe: Vector3 = a.pe_figura(c)
		var pg: Dictionary = a.pegada_figura(c)
		var nrm: Vector3 = pg["normal"]
		if not no.position.is_equal_approx(pe):
			fora += 1
		d_pe_jog = maxf(d_pe_jog, (no.position - jog.pe_figura(c)).length())
		if not srv.is_empty():
			d_pe_srv = maxf(d_pe_srv, absf(no.position.y - float(srv["peM"][c.y * w + c.x])))
		var mk: Node3D = no.get_node("Marcador")
		for filho in ["Anel", "Contacto"]:
			var nb: Vector3 = ((mk.get_node(filho) as Node3D).global_transform.basis * Vector3.UP).normalized()
			if nb.angle_to(nrm) > 0.0005:
				fora += 1
		var deitada: bool = f.get("caido") == true
		if not deitada:
			# o fundo do corpo (o cilindro do site, raio 0,38, ou o icosaedro do lobo) contra o plano da base
			var corpo: MeshInstance3D = mk.get_node("Pivo/Corpo")
			var t: Transform3D = corpo.global_transform
			var caixa: AABB = corpo.mesh.get_aabb()
			var g: Vector2 = pg["gradiente"]
			for k in 16:
				var ang := TAU * k / 16.0
				var local := Vector3(cos(ang) * 0.38, caixa.position.y, sin(ang) * 0.38) if corpo.mesh is CylinderMesh else Vector3(0.0, caixa.position.y, 0.0)
				var mundo: Vector3 = t * local
				var plano := pe.y + g.x * (mundo.x - pe.x) + g.y * (mundo.z - pe.z)
				plano_corpo = maxf(plano_corpo, absf(mundo.y - plano))
			# o corpo de pé a prumo: o eixo do corpo é vertical
			if absf(t.basis.y.x) > 0.000001 or absf(t.basis.y.z) > 0.000001:
				fora += 1
		var bloqueada: bool = not srv.is_empty() and int(srv["bloqueadas"][c.y * w + c.x]) == 1
		if bloqueada:
			n_bloq += 1
		var linha := {"x": c.x, "y": c.y, "caida": deitada, "bloqueada": bloqueada, "inclinacao_graus": snappedf(rad_to_deg(atan((pg["gradiente"] as Vector2).length())), 0.1), "peM": no.position.y}
		for raio_nome in [["pegada", r_pe], ["contacto", 0.5], ["anel", 0.56]]:
			var md := _medir_base(pe.x, pe.z, pe.y, pg["gradiente"], raio_nome[1])
			linha[raio_nome[0]] = {"raioM": raio_nome[1], "enterraM": md[0], "flutuaM": md[1]}
			var alvo: Dictionary = pior_seis if SEIS.has(c) and w == 20 and is_equal_approx(casa, 1.5) else (pior_bloq if bloqueada else pior)
			alvo[raio_nome[0]] = [maxf(alvo[raio_nome[0]][0], md[0]), maxf(alvo[raio_nome[0]][1], md[1])]
		casas_fig.append(linha)
	var n_fig: int = vista["mestre"]["figuras"].size()
	_ok(fora == 0 and a.figuras_desenhadas() == n_fig, "as %d figuras estão no pé da casa; anel e sombra de contacto no plano da encosta; corpo de pé a prumo" % n_fig)
	_ok(d_pe_jog == 0.0, "pé das figuras Mestre − jogador (pe_figura): maior %.6f m" % d_pe_jog)
	_ok(d_pe_srv < 1e-9, "pé das figuras Mestre − peM do servidor: maior %s m" % str(d_pe_srv))
	_ok(plano_corpo < 0.0001, "fundo do corpo de pé − plano da base: maior %.6f m (o cilindro assenta inteiro no plano)" % plano_corpo)
	for k in ["pegada", "contacto", "anel"]:
		print("        régua do plano contra o relevo, raio %s: enterra %.3f / flutua %.3f m (casas que se pisam)%s%s" % [k, pior[k][0], pior[k][1],
			("; nas 6 da encosta: enterra %.3f / flutua %.3f m" % pior_seis[k]) if w == 20 else "",
			("; nas %d bloqueadas pelo mapa (o servidor recusa-as): enterra %.3f / flutua %.3f m" % [n_bloq, pior_bloq[k][0], pior_bloq[k][1]]) if n_bloq > 0 else ""])
	# O limite da Ordem 44 vale nas casas que se pisam (as bloqueadas — menires, santuário, água — o servidor recusa).
	_ok(pior["pegada"][0] <= 0.10 and pior["pegada"][1] <= 0.10 and pior_seis["pegada"][0] <= 0.10 and pior_seis["pegada"][1] <= 0.10,
		"no raio da pegada (%.2f m), nas casas que se pisam: dentro do limite da Ordem 44 (0,10 m)" % r_pe)
	reg["pe"] = {"figuras": n_fig, "em_casas_bloqueadas": n_bloq, "pior_bloqueadas": pior_bloq, "pe_mestre_menos_jogador_m": d_pe_jog, "pe_mestre_menos_servidor_m": d_pe_srv,
		"fundo_do_corpo_menos_plano_m": plano_corpo, "pior_outras": pior, "pior_seis_da_encosta": pior_seis, "casas": casas_fig}

	# 4. o toque, pela câmara da mesa do Mestre (Fixa, 360° rasante, Panorama) — e o mesmo na do jogador
	var reg_toque := {}
	for modo in [[0, 0.0, 55.0, 1.5], [2, 0.0, 78.0, 1.5], [1, 135.0, 20.0, 0.6]]:
		var rm: Dictionary = await _toque(a, a.camera, modo, w, h)
		var rj: Dictionary = await _toque(jog, jog.camera, modo, w, h)
		_ok(rm["certas"] == rm["vistas"] and rm["vistas"] > 0 or rm["erradas"] == rj["erradas"] and rm["certas"] == rj["certas"],
			"toque no modo %d: Mestre %d de %d casas à vista voltam à mesma casa (%d tapadas pelo relevo) · jogador %d de %d (%d tapadas)%s" % [modo[0],
			rm["certas"], rm["vistas"], rm["tapadas"], rj["certas"], rj["vistas"], rj["tapadas"],
			("" if rm["erradas"].is_empty() else " · erradas no Mestre %s, no jogador %s" % [rm["erradas"], rj["erradas"]])])
		reg_toque[str(modo[0])] = {"mestre": rm, "jogador": rj}
	reg["toque"] = reg_toque

	# 5. desvio mapa-grelha
	var gm = a.mapa.grelha
	var bloq := 0
	var bloq_jog := 0
	var c0 := Vector2i(roundi((a.origem.x + GrelhaMapa.MEIO) / GrelhaMapa.CASA_M), roundi((a.origem.y + GrelhaMapa.MEIO) / GrelhaMapa.CASA_M))
	for y in h:
		for x in w:
			if gm.bloqueada(c0 + Vector2i(x, y)):
				bloq += 1
			if jog.mapa.grelha.bloqueada(c0 + Vector2i(x, y)):
				bloq_jog += 1
	var bloq_srv := 0
	if not srv.is_empty():
		for b in srv["bloqueadas"]:
			bloq_srv += int(b)
	_ok(bloq == bloq_jog and bloq == bloq_srv, "casas do jogo que o mapa bloqueia: Mestre %d = jogador %d = servidor %d" % [bloq, bloq_jog, bloq_srv])
	reg["bloqueadas"] = {"mestre": bloq, "jogador": bloq_jog, "servidor": bloq_srv}

	# 6. um céu só no mundo do Mestre (o SubViewport tem mundo próprio)
	var amb: Array = a.find_children("*", "WorldEnvironment", true, false)
	var sois: Array = a.find_children("*", "DirectionalLight3D", true, false)
	var env: Environment = a.get_node("Ambiente").environment
	var envj: Environment = jog.get_node("Ambiente").environment
	_ok(amb.size() == 1 and sois.size() == 1, "um céu só no ecrã do Mestre: %d WorldEnvironment, %d DirectionalLight3D" % [amb.size(), sois.size()])
	_ok(env.background_mode == Environment.BG_SKY and env.sky != null and env.fog_enabled, "o Ambiente do Mestre é o do mapa (céu pintado e névoa)")
	var sol_m: DirectionalLight3D = a.get_node("Sol")
	var sol_j: DirectionalLight3D = jog.get_node("Sol")
	_ok(env.sky.sky_material.get_class() == envj.sky.sky_material.get_class() and env.fog_light_color.is_equal_approx(envj.fog_light_color)
		and is_equal_approx(env.fog_density, envj.fog_density) and sol_m.global_basis.z.is_equal_approx(sol_j.global_basis.z)
		and sol_m.light_color.is_equal_approx(sol_j.light_color) and is_equal_approx(sol_m.light_energy, sol_j.light_energy),
		"o céu, a névoa e o sol do Mestre são os da arena do jogador")
	_ok(a.mapa.medidas.get("erros", -1) == 0, "o mapa do Mestre construiu-se com 0 erros")
	reg["ceu"] = {"worldenvironment": amb.size(), "directionallight": sois.size(), "fundo": "BG_SKY" if env.background_mode == Environment.BG_SKY else str(env.background_mode)}

	jog.queue_free()
	await _quadros(2)
	_json[nome] = reg


## O toque numa arena (a do Mestre ou a do jogador), com a câmara da mesa no `modo` [modo, rumo, inclinação, zoom]:
## o centro de cada casa à vista volta à mesma casa? As casas cujo centro o relevo tapa não contam.
func _toque(arena, cam, modo: Array, w: int, h: int) -> Dictionary:
	cam.definir_modo(modo[0])
	if modo[0] == 1:
		cam.rumo = modo[1]
		cam.inclinacao = modo[2]
	cam.definir_zoom(modo[3])
	cam._saltar()
	await _quadros(1)
	var certas := 0
	var vistas := 0
	var tapadas := 0
	var erradas: Array = []
	for y in h:
		for x in w:
			var q: Vector3 = arena.centro_casa(Vector2i(x, y)) if arena.has_method("centro_casa") else arena.centro_da_casa(Vector2i(x, y))
			if cam.is_position_behind(q) or not cam.is_position_in_frustum(q):
				continue
			var o: Vector3 = cam.global_position
			var hit = CampoDaMesa.ponto_no_chao(o, (q - o).normalized())
			if hit != null and (hit - o).length() < (q - o).length() - 0.05:
				tapadas += 1
				continue
			vistas += 1
			var t: Vector2i = arena.casa_em_tela(cam.unproject_position(q))
			if t == Vector2i(x, y):
				certas += 1
			else:
				erradas.append("(%d,%d)→(%d,%d)" % [x, y, t.x, t.y])
	return {"certas": certas, "vistas": vistas, "tapadas": tapadas, "erradas": erradas}
