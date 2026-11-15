extends SceneTree
## provar_terreno_servidor.gd — Ordens 44 e 48. A PROVA de que o cliente e o servidor vêem o MESMO terreno,
## numa grelha MAIOR do que a zona livre (30 × 30 de 1,5 m, e também 30 × 30 de 2 m) e na de sempre (20 × 20).
## Ordem 48: o servidor recorta a grelha viva do mapa inteiro, para QUALQUER tamanho que caiba no mapa. A prova
## junta a 25 × 25 (o tamanho que até aqui caía em «tudo se pisa») nas três escalas, grelhas não quadradas e o mapa
## todo (50 × 50 de 1,5 m, 75 × 75 de 1 m, 37 × 37 de 2 m). Nos casos «auto», as figuras pedidas são TODAS as casas
## que o servidor julga bloqueadas (cada uma tem de ser recusada com o motivo que o cliente desenha) e 9 casas livres.
## A cobertura compara-se onde o servidor a afirma; na faixa da borda (bordaCoberturaM do pacote) ele pode dizer
## null — conta-se quantas, e quantas delas o cliente tem diferente da do mapa de referência (o porquê do null).
##
## Para cada grelha:
##   1. chama o SERVIDOR de verdade (servidor/ferramentas/juizo-terreno.mjs: núcleo sala.js com o pacote
##      dados/terreno-floresta.json): o Mestre coloca uma criatura em cada casa pedida — dentro da zona livre, nas
##      casas da encosta do outeiro, no anel de fora e em cima de marcos (o servidor aceita ou recusa) — e o
##      servidor devolve o que julga de cada casa (altura, pé, se se pisa, motivo, cobertura), onde pôs as figuras e
##      que casas oferece à heroína para mover;
##   2. abre a ARENA DO JOGO com um snapshot dessa grelha e dessas figuras (o que o servidor mandaria);
##   3. compara, casa a casa, o que o cliente DESENHA com o que o servidor JULGA:
##        altura do centro da casa (arena.centro_casa)        vs  alturaM
##        pé da figura na casa (arena.pe_figura)               vs  peM
##        a posição de cada figura desenhada (nó da figura)    vs  peM da casa onde o servidor a pôs
##        casa bloqueada pelo mapa (e o motivo, a cobertura)   vs  passavel / motivo / cobertura (onde afirmada)
##        cada marco do mapa (menir, santuário, lanterna, …)   vs  a casa dele bloqueada no servidor, com o mesmo nome
##        as recusas do servidor                               vs  casas bloqueadas no cliente
##        as casas do mover                                    vs  nenhuma bloqueada no cliente
##      O desvio de altura tem de ser 0: o MESMO double, bit a bit (o servidor manda os 8 bytes de cada altura em
##      hexadecimal, porque o analisador de JSON do Godot erra 1e-16 no último algarismo), dentro e fora da zona livre.
##
##   godot --headless --path cliente -s res://cenas/arena/ferramentas/provar_terreno_servidor.gd [-- --json=caminho]
## Sai com 0 se tudo passa, 1 se algo falha. Precisa do Node (node no PATH).

const CENA := "res://cenas/arena/arena.tscn"
const Assentamento := preload("res://cenas/arena/assentamento.gd")
const GrelhaMapa := preload("res://mapa/floresta/grelha_floresta.gd")
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")

## A zona livre da Ordem 42 (20 × 20 casas de 1,5 m no centro do mapa): x e z em [−15, 15] m.
const ZONA_M := 15.0

## [largura, altura, casaM, figuras pedidas]: dentro da zona, as 6 casas da encosta, o anel de fora e marcos.
## Ordem 48: «auto» = todas as casas bloqueadas e 9 livres (cantos, meios das bordas e o centro, ou a livre seguinte).
const CASOS := [
	[30, 30, 1.5, "5,5;6,5;7,5;5,6;6,6;5,7;15,15;10,20;24,24;0,10;29,0;12,28;28,12;0,29;1,0;3,2;28,28"],
	[30, 30, 2.0, "8,8;15,15;20,10;0,0;29,29;0,15;15,0;29,15;15,29"],
	[20, 20, 1.5, "0,0;1,0;2,0;0,1;1,1;0,2;10,10;19,19;5,15"],
	[25, 25, 1.5, "auto"],
	[25, 25, 1.0, "auto"],
	[25, 25, 2.0, "auto"],
	[21, 17, 1.0, "auto"],
	[33, 27, 2.0, "auto"],
	[44, 20, 1.5, "auto"],
	[50, 50, 1.5, "auto"],
	[50, 50, 1.0, "auto"],
	[37, 37, 2.0, "auto"],
]

var _falhas := 0
## A cobertura do mapa de referência (a do pacote), para dizer porque é que o servidor não a afirma na borda.
var _ref_cobertura: Array = []


## Os 8 bytes do double (little-endian) em hexadecimal, como os escreve o servidor (juizo-terreno.mjs `bits`).
static func bits(v: float) -> String:
	var b := PackedFloat64Array([v]).to_byte_array()
	if b.size() != 8:
		return ""
	return b.hex_encode()


## Ordem 48: as figuras pedidas num caso «auto» — todas as casas que o servidor julga bloqueadas e 9 livres (os
## cantos, os meios das bordas e o centro; se a casa estiver bloqueada, a livre seguinte na mesma linha).
static func figuras_auto(sv: Dictionary, lw: int, lh: int) -> String:
	var casas: Array[String] = []
	var livres := {}
	if sv.get("juizo") is Dictionary:
		for c in sv["juizo"]["casas"]:
			if not bool(c["passavel"]):
				casas.append("%d,%d" % [int(c["x"]), int(c["y"])])
			else:
				livres["%d,%d" % [int(c["x"]), int(c["y"])]] = true
	for q in [Vector2i(0, 0), Vector2i(lw - 1, 0), Vector2i(0, lh - 1), Vector2i(lw - 1, lh - 1), Vector2i(lw / 2, 0),
			Vector2i(0, lh / 2), Vector2i(lw - 1, lh / 2), Vector2i(lw / 2, lh - 1), Vector2i(lw / 2, lh / 2)]:
		for d in lw:
			var chave := "%d,%d" % [(q.x + d) % lw, q.y]
			if livres.has(chave) and not casas.has(chave):
				casas.append(chave)
				break
	return ";".join(casas)


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		_falhas += 1
	print(("  ok    " if cond else "  FALHA ") + texto)


## O juízo do servidor (JSON do stdout de juizo-terreno.mjs), ou {} se o Node falhar.
static func juizo_do_servidor(largura: int, altura: int, casa_m: float, figuras: String) -> Dictionary:
	var script := ProjectSettings.globalize_path("res://").path_join("../servidor/ferramentas/juizo-terreno.mjs").simplify_path()
	var args := [script, str(largura), str(altura), "--figuras=" + figuras]
	if not is_equal_approx(casa_m, 1.5):
		args.append("--escala=%s" % casa_m)
	var saida: Array = []
	var codigo := OS.execute("node", args, saida, true)
	if codigo != 0:
		push_error("o servidor falhou (%d): %s" % [codigo, "".join(saida)])
		return {}
	var texto: String = "".join(saida)
	var linhas := texto.strip_edges().split("\n")
	var j = JSON.parse_string(linhas[linhas.size() - 1])
	return j if j is Dictionary else {}


func _correr() -> void:
	root.get_node("/root/Rede")._ativo = true
	var est = root.get_node("/root/Estado")
	var arena: Node = null
	var relatorio: Array = []
	var seq := 0
	print("== Ordens 44 e 48: o terreno do mapa no cliente e no servidor ==")
	var pacote = JSON.parse_string(FileAccess.get_file_as_string(
		ProjectSettings.globalize_path("res://").path_join("../servidor/dados/terreno-floresta.json")))
	if pacote is Dictionary and pacote.get("mapa") is Dictionary:
		_ref_cobertura = pacote["mapa"]["cobertura"]
	for caso in CASOS:
		var lw: int = caso[0]
		var lh: int = caso[1]
		var cm: float = caso[2]
		var pedidas: String = caso[3]
		if pedidas == "auto":
			pedidas = figuras_auto(juizo_do_servidor(lw, lh, cm, ""), lw, lh)
		var sv := juizo_do_servidor(lw, lh, cm, pedidas)
		if sv.is_empty() or sv.get("juizo") == null:
			_ok(false, "grelha %d×%d de %s m: o servidor não devolveu juízo do terreno" % [lw, lh, cm])
			continue
		var juizo: Dictionary = sv["juizo"]
		_ok(int(juizo["largura"]) == lw and int(juizo["altura"]) == lh and is_equal_approx(float(juizo["casaM"]), cm),
			"grelha %d×%d de %s m: o servidor julga esta grelha" % [lw, lh, cm])
		# o snapshot que o servidor mandaria: a grelha viva e as figuras onde ele as pôs
		var figs: Array = []
		for f in sv["figuras"]:
			figs.append({"id": f["id"], "nomePublico": String(f["id"]).substr(0, 4), "x": int(f["x"]), "y": int(f["y"]),
				"lado": f["lado"], "visivel": "de_pe"})
		seq += 1
		est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "prova-44", "seq": seq, "revision": seq,
			"fase": "combate", "mapa": {"largura": lw, "altura": lh, "casaM": cm}, "figuras": figs,
			"vezId": null, "ambiente": {}})
		if arena == null:
			arena = (load(CENA) as PackedScene).instantiate()
			root.add_child(arena)
		for i in 4:
			await process_frame
		_ok(arena.largura == lw and arena.altura == lh and is_equal_approx(arena.casa_m, cm), "a arena abriu a mesma grelha")
		var o: Array = juizo["origemM"]
		_ok(is_equal_approx(arena.origem.x, float(o[0])) and is_equal_approx(arena.origem.y, float(o[1])),
			"origem no mapa: cliente (%s, %s), servidor (%s, %s)" % [arena.origem.x, arena.origem.y, o[0], o[1]])

		# 3a. casa a casa
		var g = arena.mapa.grelha
		var d_alt := [0.0, 0.0]      # [dentro da zona livre, fora]
		var d_pe := [0.0, 0.0]
		var n_casas := [0, 0]
		var difere_bloq := 0
		var difere_motivo := 0
		var difere_cob := 0
		var cob_nula := 0            # casas da faixa da borda onde o servidor não afirma a cobertura (null)
		var cob_nula_diferente := 0  # … e onde o cliente tem mesmo outra cobertura que a do mapa de referência
		var bloq_srv := 0
		var casas_rel: Array = []
		for c in juizo["casas"]:
			var cc := Vector2i(int(c["x"]), int(c["y"]))
			var p: Vector3 = arena.centro_casa(cc)
			var pe: Vector3 = arena.pe_figura(cc)
			var k := 0 if (absf(p.x) < ZONA_M and absf(p.z) < ZONA_M) else 1
			n_casas[k] += 1
			# o desvio é 0 se os bits forem iguais; senão é a diferença (o que o Godot lê do JSON)
			var da := 0.0 if bits(p.y) == String(c["alturaBits"]) else maxf(absf(p.y - float(c["alturaM"])), 1e-300)
			var dp := 0.0 if bits(pe.y) == String(c["peBits"]) else maxf(absf(pe.y - float(c["peM"])), 1e-300)
			d_alt[k] = maxf(d_alt[k], da)
			d_pe[k] = maxf(d_pe[k], dp)
			var cmapa := Assentamento.casa_do_mapa(arena.origem, arena.casa_m, cc)
			var bloq_cli: bool = g.bloqueada(cmapa)
			if not bool(c["passavel"]):
				bloq_srv += 1
			if bloq_cli == bool(c["passavel"]):
				difere_bloq += 1
			if bloq_cli and g.motivo_bloqueio(cmapa) != String(c["motivo"] if c["motivo"] != null else ""):
				difere_motivo += 1
			if c["cobertura"] == null:
				cob_nula += 1
				if not _ref_cobertura.is_empty() and g.cobertura(cmapa) != int(_ref_cobertura[GrelhaMapa.indice(cmapa)]):
					cob_nula_diferente += 1
			elif g.cobertura(cmapa) != int(c["cobertura"]):
				difere_cob += 1
			if lw == 25 and lh == 25:  # o detalhe casa a casa só na prova da ordem (as 25 × 25)
				casas_rel.append({"x": cc.x, "y": cc.y, "zona": "dentro" if k == 0 else "fora",
					"cliente": {"alturaM": p.y, "peM": pe.y, "bloqueada": bloq_cli, "motivo": g.motivo_bloqueio(cmapa) if bloq_cli else null,
						"cobertura": g.cobertura(cmapa)},
					"servidor": {"alturaM": c["alturaM"], "peM": c["peM"], "alturaBits": c["alturaBits"], "peBits": c["peBits"],
						"bloqueada": not bool(c["passavel"]), "motivo": c["motivo"], "cobertura": c["cobertura"]},
					"desvioAlturaM": da, "desvioPeM": dp})
		_ok(d_alt[0] == 0.0 and d_alt[1] == 0.0, "altura do centro da casa: desvio cliente−servidor %s m nas %d casas dentro da zona livre, %s m nas %d fora" % [d_alt[0], n_casas[0], d_alt[1], n_casas[1]])
		_ok(d_pe[0] == 0.0 and d_pe[1] == 0.0, "pé da figura: desvio cliente−servidor %s m dentro, %s m fora" % [d_pe[0], d_pe[1]])
		_ok(difere_bloq == 0 and difere_motivo == 0 and difere_cob == 0,
			"casas bloqueadas: %d no servidor, %d com juízo diferente; motivos diferentes %d; cobertura afirmada diferente %d (não afirmada na borda: %d casas, %d com a do cliente ≠ a do mapa de referência)" % [
				bloq_srv, difere_bloq, difere_motivo, difere_cob, cob_nula, cob_nula_diferente])

		# 3b. as figuras desenhadas
		var d_fig := 0.0
		var fig_rel: Array = []
		for f in sv["figuras"]:
			var no: Node3D = arena._nos.get(String(f["id"]))
			if no == null:
				_ok(false, "figura %s não foi desenhada" % f["id"])
				continue
			var cc := Vector2i(int(f["x"]), int(f["y"]))
			var centro: Vector3 = arena.centro_casa(cc)
			var d := 0.0 if bits(no.position.y) == String(f["peBits"]) else maxf(absf(no.position.y - float(f["peM"])), 1e-300)
			d_fig = maxf(d_fig, d)
			if absf(no.position.x - centro.x) > 1e-4 or absf(no.position.z - centro.z) > 1e-4:
				_ok(false, "figura %s fora do centro da casa %s" % [f["id"], cc])
			var pg: Dictionary = arena.pegada_figura(cc)
			fig_rel.append({"id": f["id"], "x": cc.x, "y": cc.y, "zona": "dentro" if absf(centro.x) < ZONA_M and absf(centro.z) < ZONA_M else "fora",
				"desenhadaY": no.position.y, "servidorPeM": f["peM"], "desvioM": d,
				"encostaGraus": rad_to_deg(atan((pg["gradiente"] as Vector2).length())), "enterraM": pg["enterra"], "flutuaM": pg["flutua"]})
		_ok(d_fig == 0.0, "as %d figuras desenhadas: desvio da altura do pé contra o peM do servidor %s m" % [fig_rel.size(), d_fig])

		# 3c. as recusas do servidor são casas bloqueadas no cliente, com o mesmo nome
		var rec_ok := 0
		for r in sv["recusas"]:
			var cmapa := Assentamento.casa_do_mapa(arena.origem, arena.casa_m, Vector2i(int(r["x"]), int(r["y"])))
			var det := String(r["detalhe"]) if r["detalhe"] != null else ""
			if g.bloqueada(cmapa) and det.ends_with(" " + g.motivo_bloqueio(cmapa)):
				rec_ok += 1
		_ok(rec_ok == (sv["recusas"] as Array).size(), "recusas do servidor: %d, todas em casas que o cliente desenha bloqueadas e com o mesmo motivo (%s)" % [rec_ok,
			", ".join((sv["recusas"] as Array).map(func(r): return "(%d,%d) %s" % [r["x"], r["y"], String(r["detalhe"]).get_slice(" ", 2)]))])

		# 3d. as casas que o servidor oferece para mover: nenhuma bloqueada no cliente
		var mover_bloq := 0
		for c in sv["mover"]:
			if g.bloqueada(Assentamento.casa_do_mapa(arena.origem, arena.casa_m, Vector2i(int(c["x"]), int(c["y"])))):
				mover_bloq += 1
		_ok(mover_bloq == 0, "mover: o servidor oferece %d casas, %d bloqueadas no cliente" % [(sv["mover"] as Array).size(), mover_bloq])

		# 3e. os marcos e obstáculos do mapa dentro da grelha: a casa de cada um está bloqueada no servidor, com o nome dele
		var marcos_dentro := 0
		var marcos_ok := 0
		var marcos_rel: Array = []
		for ob in arena.mapa.obstaculos:
			var pc: Vector3 = ob["c"]
			var cx := floori((pc.x - arena.origem.x) / arena.casa_m)
			var cz := floori((pc.z - arena.origem.y) / arena.casa_m)
			if cx < 0 or cz < 0 or cx >= lw or cz >= lh:
				continue
			var cmapa := GrelhaMapa.casa_em(pc.x, pc.z)
			if not g.bloqueada(cmapa) or g.motivo_bloqueio(cmapa) != String(ob["nome"]):
				continue  # o que o mapa não bloqueia (menir deitado, tronco que só dá cobertura, …) não conta
			# a casa do mapa do marco pode não ser a do centro da casa do jogo (casas de 2 m); procura a casa do jogo
			var casa_srv = null
			for c in juizo["casas"]:
				if Assentamento.casa_do_mapa(arena.origem, arena.casa_m, Vector2i(int(c["x"]), int(c["y"]))) == cmapa:
					casa_srv = c
					break
			if casa_srv == null:
				continue  # casas de 2 m: o marco está numa casa do mapa que não é o centro de nenhuma casa do jogo
			marcos_dentro += 1
			var bate: bool = not bool(casa_srv["passavel"]) and String(casa_srv["motivo"]) == String(ob["nome"])
			if bate:
				marcos_ok += 1
			marcos_rel.append({"nome": ob["nome"], "pontoM": [pc.x, pc.y, pc.z], "relevoNoPontoM": Relevo.altura(pc.x, pc.z),
				"casa": [int(casa_srv["x"]), int(casa_srv["y"])], "servidor": {"bloqueada": not bool(casa_srv["passavel"]), "motivo": casa_srv["motivo"],
				"alturaM": casa_srv["alturaM"]}, "cliente": {"alturaM": arena.centro_casa(Vector2i(int(casa_srv["x"]), int(casa_srv["y"]))).y}})
		_ok(marcos_ok == marcos_dentro, "marcos do mapa na grelha (que bloqueiam): %d, %d com a casa bloqueada no servidor e o mesmo nome" % [marcos_dentro, marcos_ok])

		relatorio.append({"grelha": {"largura": lw, "altura": lh, "casaM": cm, "origemM": [arena.origem.x, arena.origem.y]},
			"casasDentroZonaLivre": n_casas[0], "casasFora": n_casas[1],
			"desvioMaxAlturaM": {"dentro": d_alt[0], "fora": d_alt[1]}, "desvioMaxPeM": {"dentro": d_pe[0], "fora": d_pe[1]},
			"desvioMaxFigurasM": d_fig, "casasBloqueadas": bloq_srv, "juizoDiferente": difere_bloq, "motivosDiferentes": difere_motivo,
			"coberturaAfirmadaDiferente": difere_cob, "coberturaNaoAfirmada": cob_nula, "coberturaNaoAfirmadaClienteDifereDaReferencia": cob_nula_diferente,
			"recusas": sv["recusas"], "moverOferecidas": (sv["mover"] as Array).size(), "moverBloqueadas": mover_bloq,
			"figuras": fig_rel, "marcos": marcos_rel, "casas": casas_rel})

	var saida := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--json="):
			saida = a.trim_prefix("--json=")
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		f.store_string(JSON.stringify({"ordem": 48, "prova": "cliente/cenas/arena/ferramentas/provar_terreno_servidor.gd",
			"servidor": "servidor/ferramentas/juizo-terreno.mjs (núcleo sala.js + dados/terreno-floresta.json)",
			"zonaLivre": "x e z em [−15, 15] m (a grelha 20 × 20 de 1,5 m da Ordem 42)", "grelhas": relatorio}, " ", false, true))
		f.close()
		print("medição escrita em %s" % saida)
	print("%s" % ("TUDO PASSOU" if _falhas == 0 else "%d FALHAS" % _falhas))
	quit(1 if _falhas > 0 else 0)
