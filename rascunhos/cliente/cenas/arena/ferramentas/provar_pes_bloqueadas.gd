extends SceneTree
## provar_pes_bloqueadas.gd — Ordem 58. A PROVA de que nenhuma figura fica DE PÉ numa casa que o mapa bloqueia
## (menir, santuário, água, escarpa…), nas DUAS arenas: a do jogador (cenas/arena/arena.gd) e a do ecrã do Mestre
## (cenas/mestre/arena_mestre.gd, no mestre.tscn de verdade). As duas assentam as figuras pelo mesmo caminho
## (campo_da_mesa.gd `recusa_do_pe`); a regra do que está bloqueado é a do servidor (o juízo de juizo-terreno.mjs).
##
## A reserva 3 da Ordem 45: na 30 × 30 de 1,5 m, nas 5 casas bloqueadas pelo mapa onde a prova da Ordem 45 põe
## figuras — (27,0), (27,3), (27,24), (24,27), (1,0) — a figura ficava de pé, com o plano da base até 0,30 m do
## relevo (as duas escarpas de 55° e 67°). A correcção: a figura numa casa bloqueada não se põe de pé; a arena
## RECUSA-A COM NOME (FLORESTA-E08-CASA-BLOQUEADA, a casa e o motivo do mapa), como o servidor recusa a colocação
## (CASA_BLOQUEADA) e a grelha do mapa recusa ocupar a casa.
##
## Mede, para cada grelha e para cada arena:
##   A. o conjunto da Ordem 45 (figuras de 3 em 3 casas, mais as 6 da encosta; algumas caídas) — as 5 casas;
##   B. uma figura em CADA casa da grelha, em 20 × 20 e 30 × 30 de 1,5 m, 30 × 30 de 2 m e 25 × 25 de 1 m:
##        - quantas ficam desenhadas em casas bloqueadas (tem de ser 0) e o pior plano da base contra o relevo
##          nelas (a régua da Ordem 44, raio da pegada);
##        - as recusas: uma por casa que o servidor julga bloqueada, nenhuma noutra, todas com o nome e o motivo
##          que o servidor dá;
##        - as figuras nas casas que se pisam: todas desenhadas, no pé da casa (pe_figura = peM do servidor, bit a
##          bit) — e a posição de cada uma vai no JSON, para comparar com a medição de antes (nada mudou nelas).
##   No ecrã do Mestre também: o anel da vez não aparece numa figura recusada.
##
##   godot --headless --path cliente -s res://cenas/arena/ferramentas/provar_pes_bloqueadas.gd [-- --json=caminho]
## Sai com 0 se tudo passa, 1 se algo falha. Precisa do Node (node no PATH). Corre também no código de antes da
## correcção (as arenas sem `pes_recusados`): falha, e o JSON tem os números de antes.

const CENA_MESTRE := "res://cenas/mestre/mestre.tscn"
const CENA_ARENA := "res://cenas/arena/arena.tscn"
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const Assentamento := preload("res://cenas/arena/assentamento.gd")
const ProvaTerreno := preload("res://cenas/arena/ferramentas/provar_terreno_servidor.gd")
const Erros := preload("res://mapa/floresta/erros_floresta.gd")
const SEIS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]
## As 5 casas da reserva 3 da Ordem 45 (30 × 30 de 1,5 m).
const CINCO := [Vector2i(27, 0), Vector2i(27, 3), Vector2i(27, 24), Vector2i(24, 27), Vector2i(1, 0)]
## [largura, altura, casaM, conjunto]: «45» = o conjunto da Ordem 45; «todas» = uma figura em cada casa.
const CASOS := [
	[20, 20, 1.5, "45"],
	[30, 30, 1.5, "45"],
	[20, 20, 1.5, "todas"],
	[30, 30, 1.5, "todas"],
	[30, 30, 2.0, "todas"],
	[25, 25, 1.0, "todas"],
]

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


## A régua do pé da Ordem 44 (a mesma de provar_mestre_no_relevo.gd): [enterra, flutua] do plano de altura `y` no
## centro (x, z) e inclinação `g`, no centro e em 4 anéis de 32 pontos até ao raio `r`.
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


static func _bits(v: float) -> String:
	return PackedFloat64Array([v]).to_byte_array().hex_encode()


static func _casas(w: int, h: int, conjunto: String) -> Array[Vector2i]:
	var casas: Array[Vector2i] = []
	if conjunto == "todas":
		for y in h:
			for x in w:
				casas.append(Vector2i(x, y))
		return casas
	for y in range(0, h, 3):
		for x in range(0, w, 3):
			casas.append(Vector2i(x, y))
	for c in SEIS:
		if not casas.has(c):
			casas.append(c)
	return casas


## O juízo do servidor de verdade para a grelha: por casa (linha a linha) {passavel, motivo, peBits}. {} se falhar.
static func _juizo(w: int, h: int, casa: float) -> Dictionary:
	var sv := ProvaTerreno.juizo_do_servidor(w, h, casa, "")
	if not sv.get("juizo") is Dictionary or (sv["juizo"]["casas"] as Array).size() != w * h:
		return {}
	var r := {}
	for c in sv["juizo"]["casas"]:
		r[Vector2i(int(c["x"]), int(c["y"]))] = {"passavel": bool(c["passavel"]), "motivo": c["motivo"], "peBits": String(c["peBits"])}
	return r


func _correr() -> void:
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var fx = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (fx is Dictionary):
		printerr("sem a fixture do Mestre")
		quit(1)
		return
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede._ativo = true  # sem rede
	rede.papel = "mestre"
	root.size = Vector2i(1920, 1080)
	var m = (load(CENA_MESTRE) as PackedScene).instantiate()
	m.enviar_fn = func(_t, _c, _r): return ""
	m.pedir_vista_fn = func(): pass
	root.add_child(m)
	await _quadros(2)
	var jog = null
	var est = root.get_node("Estado")
	var seq := 0
	var corrigido: bool = m._arena.has_method("pes_recusados")
	print("== Ordem 58: os pés nas casas bloqueadas do mapa (%s) ==" % ("com a correcção" if corrigido else "SEM a correcção: os números de antes"))
	_json["corrigido"] = corrigido
	for caso in CASOS:
		var w: int = caso[0]
		var h: int = caso[1]
		var casa: float = caso[2]
		var conjunto: String = caso[3]
		var nome := "%dx%d de %s m, %s" % [w, h, str(casa), "uma figura em cada casa" if conjunto == "todas" else "o conjunto da Ordem 45"]
		print("-- grelha %s --" % nome)
		var srv := _juizo(w, h, casa)
		_ok(not srv.is_empty(), "o servidor de verdade julga a grelha %dx%d de %s m" % [w, h, str(casa)])
		if srv.is_empty():
			continue
		var casas := _casas(w, h, conjunto)
		# o ecrã do Mestre: a vista da fixture com estas figuras; a vez numa figura de casa bloqueada, se houver
		var v: Dictionary = (fx["mestre"]["vista"] as Dictionary).duplicate(true)
		v["mapa"] = {"largura": w, "altura": h, "casaM": casa}
		var molde: Dictionary = {}
		for f in v["mestre"]["figuras"]:
			if f.get("colocada") == true:
				molde = f
				break
		var figs_m: Array = []
		var figs_j: Array = []
		var vez := ""
		for k in casas.size():
			var c: Vector2i = casas[k]
			var f: Dictionary = molde.duplicate(true)
			f["id"] = "p58-%d" % k
			f["nome"] = "P%d" % k
			f["x"] = c.x
			f["y"] = c.y
			f["colocada"] = true
			f["vivo"] = true
			f["caido"] = k % 11 == 5
			figs_m.append(f)
			figs_j.append({"id": f["id"], "nomePublico": "P%d" % k, "x": c.x, "y": c.y, "lado": "criatura",
				"visivel": "caida" if k % 11 == 5 else "de_pe"})
			if vez == "" and not bool(srv[c]["passavel"]):
				vez = f["id"]
		v["mestre"]["figuras"] = figs_m
		v["vezId"] = vez if vez != "" else "p58-0"
		m.aplicar_vista(v)
		# a arena do jogador: o snapshot que o servidor mandaria com estas figuras
		seq += 1
		est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "prova-58", "seq": seq, "revision": seq,
			"fase": "combate", "mapa": {"largura": w, "altura": h, "casaM": casa}, "figuras": figs_j, "vezId": null, "ambiente": {}})
		if jog == null:
			jog = (load(CENA_ARENA) as PackedScene).instantiate()
			root.add_child(jog)
		await _quadros(4)
		var reg := {"figuras": casas.size(), "casas_bloqueadas_com_figura": 0}
		var n_bloq := 0
		for c in casas:
			if not bool(srv[c]["passavel"]):
				n_bloq += 1
		reg["casas_bloqueadas_com_figura"] = n_bloq
		for lado in [["mestre", m._arena, figs_m], ["jogador", jog, figs_j]]:
			reg[lado[0]] = _medir_arena(lado[0], lado[1], lado[2], srv, w, h, casa, conjunto)
		if corrigido and vez != "":
			_ok(not m._arena._anel.visible, "Mestre: a vez numa figura recusada (%s) não tem anel" % vez)
		_json[nome] = reg
	if corrigido:
		await _entrar_e_sair(m, jog, est, fx, seq + 1)
	m.queue_free()
	if jog != null:
		jog.queue_free()
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


func _medir_arena(lado: String, a, figs: Array, srv: Dictionary, w: int, h: int, casa: float, conjunto: String) -> Dictionary:
	var r_pe: float = Assentamento.raio_pegada(casa)
	var recusas: Dictionary = a.pes_recusados() if a.has_method("pes_recusados") else {}
	var de_pe_bloq := 0       # desenhadas em casas bloqueadas
	var pior_bloq := [0.0, 0.0]
	var livres_ok := 0
	var livres_mal: Array = []
	var recusas_certas := 0
	var recusas_erradas: Array = []
	var cinco: Array = []
	var posicoes := {}
	for f in figs:
		var id := str(f["id"])
		var c := Vector2i(int(f["x"]), int(f["y"]))
		var j: Dictionary = srv[c]
		var no: Node3D = a._nos.get(id)
		if no != null and no.is_queued_for_deletion():
			no = null
		var pg: Dictionary = a.pegada_figura(c)
		var pe: Vector3 = a.pe_figura(c)
		var md := _medir_base(pe.x, pe.z, pe.y, pg["gradiente"], r_pe)
		posicoes[id] = _bits(no.position.x) + _bits(no.position.y) + _bits(no.position.z) if no != null else null
		if not bool(j["passavel"]):
			var texto := str(recusas.get(id, ""))
			var esperado := "%s: (%d,%d) %s" % [Erros.CASA_BLOQUEADA, c.x, c.y, str(j["motivo"])]
			if no != null:
				de_pe_bloq += 1
				pior_bloq = [maxf(pior_bloq[0], md[0]), maxf(pior_bloq[1], md[1])]
			if texto == esperado and no == null:
				recusas_certas += 1
			else:
				recusas_erradas.append("(%d,%d) «%s»" % [c.x, c.y, texto])
			if conjunto == "45" and is_equal_approx(casa, 1.5) and w == 30:
				cinco.append({"x": c.x, "y": c.y, "motivo": j["motivo"], "desenhada_de_pe": no != null, "recusa": texto if texto != "" else null,
					"inclinacao_graus": snappedf(rad_to_deg(atan((pg["gradiente"] as Vector2).length())), 0.1),
					"pegada_enterraM": md[0], "pegada_flutuaM": md[1]})
		else:
			if no != null and no.position == pe and _bits(no.position.y) == str(j["peBits"]) and not recusas.has(id):
				livres_ok += 1
			else:
				livres_mal.append("(%d,%d)" % [c.x, c.y])
	var n_bloq := recusas_certas + recusas_erradas.size()
	var n_livres := figs.size() - n_bloq
	_ok(de_pe_bloq == 0, "%s: figuras de pé em casas bloqueadas %d de %d%s" % [lado, de_pe_bloq, n_bloq,
		(" (o plano da base contra o relevo nelas: enterra %.3f / flutua %.3f m, raio da pegada)" % pior_bloq) if de_pe_bloq > 0 else ""])
	_ok(recusas_certas == n_bloq and recusas.size() == n_bloq, "%s: %d recusas com nome (%s), uma por casa bloqueada, com o motivo do servidor; %d no total%s" % [
		lado, recusas_certas, Erros.CASA_BLOQUEADA, recusas.size(), (" · erradas: %s" % ", ".join(recusas_erradas.slice(0, 8))) if not recusas_erradas.is_empty() else ""])
	_ok(livres_ok == n_livres, "%s: %d de %d figuras nas casas que se pisam desenhadas no pé da casa (= peM do servidor, bit a bit)%s" % [
		lado, livres_ok, n_livres, (" · mal: %s" % ", ".join(livres_mal.slice(0, 8))) if not livres_mal.is_empty() else ""])
	if lado == "mestre":
		_ok(a.figuras_desenhadas() == n_livres, "mestre: figuras desenhadas %d = figuras nas casas que se pisam %d" % [a.figuras_desenhadas(), n_livres])
	if not cinco.is_empty():
		var casas_cinco: Array = cinco.map(func(e): return Vector2i(e["x"], e["y"]))
		_ok(casas_cinco.size() == CINCO.size() and CINCO.all(func(c): return casas_cinco.has(c)),
			"%s: as casas bloqueadas com figura são as 5 da reserva 3 da Ordem 45 %s" % [lado, casas_cinco])
	for e in cinco:
		print("        (%d,%d) %s, %.1f°: %s · %s: enterra %.3f / flutua %.3f m" % [e["x"], e["y"], e["motivo"], e["inclinacao_graus"],
			"DE PÉ" if e["desenhada_de_pe"] else "recusada «%s»" % e["recusa"],
			"o plano da base contra o relevo" if e["desenhada_de_pe"] else "o plano que a base teria (não se desenha)", e["pegada_enterraM"], e["pegada_flutuaM"]])
	return {"desenhadas_em_bloqueadas": de_pe_bloq, "pior_bloqueadas_pegada": pior_bloq, "recusas": recusas.size(), "recusas_certas": recusas_certas,
		"livres": n_livres, "livres_no_pe": livres_ok, "cinco_da_ordem_45": cinco, "posicoes_bits": posicoes}


## Uma figura que entra numa casa bloqueada deixa de estar de pé (e fica recusada); a que sai dela volta a pôr-se de pé
## no pé da casa nova, sem recusa. Na 30 × 30 de 1,5 m: A começa na escarpa (27,24) e B na casa livre seguinte da
## mesma linha; depois trocam.
func _entrar_e_sair(m, jog, est, fx: Dictionary, seq: int) -> void:
	print("-- uma figura entra numa casa bloqueada e outra sai dela (30x30 de 1.5 m) --")
	var srv := _juizo(30, 30, 1.5)
	var bloq := Vector2i(27, 24)
	var livre := Vector2i(-1, -1)
	for x in 30:
		if bool(srv[Vector2i(x, 24)]["passavel"]):
			livre = Vector2i(x, 24)
	var molde: Dictionary = {}
	for f in fx["mestre"]["vista"]["mestre"]["figuras"]:
		if f.get("colocada") == true:
			molde = f
			break
	for passo in [[bloq, livre], [livre, bloq]]:
		var v: Dictionary = (fx["mestre"]["vista"] as Dictionary).duplicate(true)
		v["mapa"] = {"largura": 30, "altura": 30, "casaM": 1.5}
		var figs_m: Array = []
		var figs_j: Array = []
		for k in 2:
			var c: Vector2i = passo[k]
			var f: Dictionary = molde.duplicate(true)
			f["id"] = ["A", "B"][k]
			f["x"] = c.x
			f["y"] = c.y
			f["colocada"] = true
			f["vivo"] = true
			f["caido"] = false
			figs_m.append(f)
			figs_j.append({"id": f["id"], "nomePublico": f["id"], "x": c.x, "y": c.y, "lado": "criatura", "visivel": "de_pe"})
		v["mestre"]["figuras"] = figs_m
		v["vezId"] = "A"
		m.aplicar_vista(v)
		est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "prova-58", "seq": seq, "revision": seq,
			"fase": "combate", "mapa": {"largura": 30, "altura": 30, "casaM": 1.5}, "figuras": figs_j, "vezId": null, "ambiente": {}})
		seq += 1
		await _quadros(3)
		var no_livre := "A" if passo[0] == livre else "B"
		var no_bloq := "B" if no_livre == "A" else "A"
		for lado in [["mestre", m._arena], ["jogador", jog]]:
			var a = lado[1]
			var nl: Node3D = a._nos.get(no_livre)
			var nb = a._nos.get(no_bloq)
			var rec: Dictionary = a.pes_recusados()
			_ok(nl != null and nl.position == a.pe_figura(livre) and (nb == null or (nb as Node).is_queued_for_deletion())
				and rec.size() == 1 and str(rec.get(no_bloq, "")).begins_with(Erros.CASA_BLOQUEADA + ": (27,24)"),
				"%s: %s na casa livre %s de pé no pé da casa; %s na escarpa (27,24) recusada (%s)" % [lado[0], no_livre, livre, no_bloq, rec.get(no_bloq, "")])
		_ok(m._arena._anel.visible == (no_livre == "A"), "Mestre: o anel da vez (A) só aparece com A de pé")
