extends SceneTree
## provar_assentamento.gd — Ordem 42. A PROVA do assentamento da grelha no relevo, na arena DO JOGO
## (cenas/arena/arena.tscn), sem janela. Mede, para a grelha do snapshot de demonstração:
##   1. cada centro de casa contra a altura do relevo (Relevo.altura = malha = colisão);
##   2. cada vértice dos remendos (destaques, fogo, cursor) e das linhas contra o relevo — nada abaixo
##      do chão, nada mais do que LEVANTA_M + 2 cm acima;
##   3. cada figura: o pé contra o relevo debaixo da pegada (nenhum ponto da base no ar);
##   4. o toque: o raio de cada centro de casa, visto pela câmara da mesa, volta à MESMA casa;
##   5. o desvio mapa-grelha: as casas do jogo que o mapa bloqueia (tem de dar 0);
##   6. um céu só: quantos WorldEnvironment e DirectionalLight3D há na árvore.
##
##   godot --headless --path cliente -s res://cenas/arena/ferramentas/provar_assentamento.gd
## Sai com 0 se tudo passa, 1 se algo falha.

const CENA := "res://cenas/arena/arena.tscn"
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const GrelhaMapa := preload("res://mapa/floresta/grelha_floresta.gd")

var _falhas := 0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		_falhas += 1
	print(("  ok    " if cond else "  FALHA ") + texto)


func _correr() -> void:
	root.get_node("/root/Rede")._ativo = true
	var est = root.get_node("/root/Estado")
	var figuras: Array = []
	var k := 0
	for y in range(0, 20, 3):
		for x in range(0, 20, 3):
			figuras.append({"id": "f%d" % k, "nomePublico": "F%d" % k, "x": x, "y": y, "lado": "criatura", "visivel": "de_pe"})
			k += 1
	est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "prova-42", "seq": 1, "revision": 1,
		"fase": "combate", "mapa": {"largura": 20, "altura": 20, "casaM": 1.5}, "figuras": figuras,
		"vezId": "f0", "propria": {"figuraId": "f0"}, "fogo": {"casas": [{"x": 5, "y": 5}]}, "ambiente": {}})
	var todas: Array = []
	for y in 20:
		for x in 20:
			todas.append({"x": x, "y": y, "custoM": 1.5})
	est.receber_opcoes({"v": 2, "type": "ROOM_OPTIONS", "revision": 1, "vezId": "f0", "mover": todas,
		"ataques": [], "consumiveis": [], "acoes": [], "reacoes": []})
	var arena = (load(CENA) as PackedScene).instantiate()
	root.add_child(arena)
	for i in 4:
		await process_frame
	arena.definir_modo(1)
	arena._cursor = Vector2i(7, 7)
	arena._atualizar_cursor()
	print("== Ordem 42: a grelha assenta no relevo ==")
	print("grelha %d×%d casas de %.1f m; origem (canto NO) x=%.2f z=%.2f" % [arena.largura, arena.altura, arena.casa_m, arena.origem.x, arena.origem.y])

	# 1. centros
	var d1 := 0.0
	for y in arena.altura:
		for x in arena.largura:
			var p: Vector3 = arena.centro_casa(Vector2i(x, y))
			d1 = maxf(d1, absf(p.y - Relevo.altura(p.x, p.z)))
	_ok(d1 < 0.001, "centro de casa − relevo: maior %.5f m (400 casas)" % d1)

	# 2. remendos e linhas
	for nome in ["Destaques", "Fogo", "Cursor", "Linhas"]:
		var mi: MeshInstance3D = arena.get_node("Grelha/" + nome)
		if mi.mesh == null:
			_ok(false, "%s sem malha" % nome)
			continue
		var v: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var lo := INF
		var hi := -INF
		for q in v:
			var dh := q.y - Relevo.altura(q.x, q.z)
			lo = minf(lo, dh)
			hi = maxf(hi, dh)
		_ok(lo >= 0.0 and hi <= arena.LEVANTA_M + 0.02 + 0.0001, "%s: %d vértices, acima do relevo entre %.3f e %.3f m" % [nome, v.size(), lo, hi])
	# a casa do meio de cada remendo de destaque: nenhum ponto da casa abaixo do remendo (a meio dos triângulos)
	var pior := 0.0
	for y in arena.altura:
		for x in arena.largura:
			var c: Vector3 = arena.centro_casa(Vector2i(x, y))
			for a in 16:
				var ang := TAU * a / 16.0
				var r: float = arena.casa_m * 0.4
				var px: float = c.x + cos(ang) * r
				var pz: float = c.z + sin(ang) * r
				# o remendo é interpolado entre vértices a 0,34 m: quanto fica abaixo do relevo, no pior ponto?
				var passo: float = arena.casa_m * 0.9 / arena.DIVISOES_CASA
				var x0: float = c.x - arena.casa_m * 0.45
				var z0: float = c.z - arena.casa_m * 0.45
				var i := clampi(floori((px - x0) / passo), 0, arena.DIVISOES_CASA - 1)
				var j := clampi(floori((pz - z0) / passo), 0, arena.DIVISOES_CASA - 1)
				var fx: float = (px - x0) / passo - i
				var fz: float = (pz - z0) / passo - j
				var h00 := Relevo.altura(x0 + i * passo, z0 + j * passo)
				var h10 := Relevo.altura(x0 + (i + 1) * passo, z0 + j * passo)
				var h01 := Relevo.altura(x0 + i * passo, z0 + (j + 1) * passo)
				var h11 := Relevo.altura(x0 + (i + 1) * passo, z0 + (j + 1) * passo)
				var hr: float = lerpf(lerpf(h00, h10, fx), lerpf(h01, h11, fx), fz) + arena.LEVANTA_M + 0.01
				pior = maxf(pior, Relevo.altura(px, pz) - hr)
	_ok(pior < 0.45, "entre vértices, o relevo sobe acima do remendo no máximo %.3f m (o shader puxa 0,45 m)" % pior)

	# 3. figuras
	var no_ar := 0.0
	var enterra := 0.0
	for id in arena._nos:
		var no: Node3D = arena._nos[id]
		var c := Vector2i(int(est.figuras[id]["x"]), int(est.figuras[id]["y"]))
		var destino: Vector3 = arena.pe_figura(c)
		var r: float = arena.casa_m * 0.28
		for a in 16:
			var ang := TAU * a / 16.0
			var h := Relevo.altura(destino.x + cos(ang) * r, destino.z + sin(ang) * r)
			no_ar = maxf(no_ar, destino.y - h)
			enterra = maxf(enterra, h - destino.y)
		if not no.position.is_equal_approx(destino):
			_ok(false, "figura %s fora do sítio: %s em vez de %s" % [id, no.position, destino])
	_ok(no_ar < 0.01, "pé das %d figuras: o ponto da base mais alto acima do chão %.3f m (nada no ar)" % [arena._nos.size(), no_ar])
	print("        o lado de cima da base entra no chão até %.3f m (a relva pisada tapa)" % enterra)
	# e em TODAS as casas (não só onde há figura): quanto entra o lado de cima da base?
	var conta := [0, 0, 0]
	var pior_casa := Vector2i(-1, -1)
	var pior_e := 0.0
	for y in arena.altura:
		for x in arena.largura:
			var pe: Vector3 = arena.pe_figura(Vector2i(x, y))
			var e := 0.0
			for a in 16:
				var ang := TAU * a / 16.0
				e = maxf(e, Relevo.altura(pe.x + cos(ang) * arena.casa_m * 0.28, pe.z + sin(ang) * arena.casa_m * 0.28) - pe.y)
			if e > 0.10: conta[0] += 1
			if e > 0.20: conta[1] += 1
			if e > 0.35: conta[2] += 1
			if e > pior_e:
				pior_e = e
				pior_casa = Vector2i(x, y)
	print("        nas 400 casas: base a entrar > 0,10 m em %d · > 0,20 m em %d · > 0,35 m em %d; pior %.3f m na casa %s (degrau da casa %.2f m)" % [conta[0], conta[1], conta[2], pior_e, pior_casa, GrelhaMapa.degrau(pior_casa + Vector2i(15, 15))])

	# 4. o toque, pela câmara da mesa (Fixa, Panorama, 360° rasante)
	var cam: Camera3D = arena.camera
	for modo in [[0, 0.0, 55.0, 1.5], [2, 0.0, 78.0, 1.5], [1, 135.0, 20.0, 0.6]]:
		cam.definir_modo(modo[0])
		if modo[0] == 1:
			cam.rumo = modo[1]
			cam.inclinacao = modo[2]
		cam.definir_zoom(modo[3])
		cam._saltar()
		await process_frame
		var certas := 0
		var vistas := 0
		for y in arena.altura:
			for x in arena.largura:
				var p: Vector3 = arena.centro_casa(Vector2i(x, y))
				if cam.is_position_behind(p) or not cam.is_position_in_frustum(p):
					continue
				vistas += 1
				if arena.casa_em_tela(cam.unproject_position(p)) == Vector2i(x, y):
					certas += 1
		_ok(certas == vistas and vistas > 0, "toque no modo %d: %d de %d casas à vista voltam à mesma casa" % [modo[0], certas, vistas])

	# 5. desvio mapa-grelha
	var g = arena.mapa.grelha
	var bloq := 0
	var c0 := Vector2i(roundi((arena.origem.x + GrelhaMapa.MEIO) / GrelhaMapa.CASA_M), roundi((arena.origem.y + GrelhaMapa.MEIO) / GrelhaMapa.CASA_M))
	for y in arena.altura:
		for x in arena.largura:
			if g.bloqueada(c0 + Vector2i(x, y)):
				bloq += 1
	_ok(bloq == 0, "casas do jogo que o mapa bloqueia: %d (casa do jogo (0,0) = casa do mapa %s)" % [bloq, c0])
	print("        o mapa tirou da zona: %s" % JSON.stringify({"rochas": arena.mapa.medidas.get("zona_tirados_rochas", 0),
		"arvores": arena.mapa.medidas.get("zona_tirados_arvores", 0), "estrato": arena.mapa.medidas.get("zona_tirados_estrato", 0),
		"tronco_tombado_m": arena.mapa.medidas.get("zona_tronco_tombado_m", 0)}))

	# 6. um céu só
	var ambientes := root.find_children("*", "WorldEnvironment", true, false).size()
	var sois := root.find_children("*", "DirectionalLight3D", true, false).size()
	var env: Environment = arena.get_node("Ambiente").environment
	_ok(ambientes == 1 and sois == 1, "um céu só: %d WorldEnvironment, %d DirectionalLight3D" % [ambientes, sois])
	_ok(env.background_mode == Environment.BG_SKY and env.sky != null and env.fog_enabled, "o Ambiente da arena é o do mapa (céu pintado e névoa)")
	_ok(arena.mapa.medidas.get("erros", -1) == 0, "o mapa construiu-se com 0 erros")

	# 7. perfis: a densidade da folhagem chega à relva do mapa
	for nome in ["baixo", "medio", "alto"]:
		arena._aplicar_perfil(nome)
		var d: float = arena.mapa.densidade_relva
		_ok(is_equal_approx(d, float(AplicadorPerfil.PERFIS[nome]["folhagem_densidade"])), "perfil %s: relva do mapa a %.2f" % [nome, d])

	print("%s" % ("TUDO PASSOU" if _falhas == 0 else "%d FALHAS" % _falhas))
	quit(1 if _falhas > 0 else 0)
