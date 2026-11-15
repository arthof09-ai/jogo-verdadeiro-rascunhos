extends SceneTree
## provar_recusa_no_ecra.gd — Ordem 60. A PROVA de que a recusa do pé (Ordem 58) SE VÊ NO ECRÃ, nas DUAS arenas:
## a do jogador (cenas/arena/arena.tscn, com o HUD de verdade) e a do ecrã do Mestre (cenas/mestre/mestre.tscn).
##
## A reserva 1 da Ordem 58: «A figura recusada desaparece da arena 3D. […] O aviso fica na consola, mas no ecrã ninguém
## é avisado: não há mensagem ao Mestre nem à jogadora.» Esta prova mede, para cada figura numa casa que o mapa bloqueia
## (o juízo do servidor de verdade, servidor/ferramentas/juizo-terreno.mjs):
##   1. NA ARENA 3D: há uma marca visível na casa dela — uma malha (que não é do mapa) por cima da casa e um rótulo 3D com
##      o nome da figura e o motivo; e ela continua sem estar de pé (o `_nos` da Ordem 58 não a tem);
##   2. NO ECRÃ, onde a arena já mostra os seus avisos — jogadora: o «Aviso» do HUD (hud.gd `_mostrar_aviso`); Mestre: os
##      alertas da coluna 1 (mestre.gd `_juntar_alerta`) — um texto visível com o nome e o motivo; e, no Mestre, a linha
##      da figura na folha (aba Figuras) diz que ela não está de pé e porquê.
## E que as colocações legais NÃO MUDAM: nenhuma marca, nenhum aviso, as mesmas posições (bits do double) e as mesmas
## linhas da folha que na medição de antes (`--antes=json`).
##
##   godot --headless --path cliente -s res://cenas/mestre/ferramentas/provar_recusa_no_ecra.gd [-- --json=saída] [--antes=json]
## Sai com 0 se tudo passa, 1 se algo falha. Precisa do Node. Corre também no código de antes da correcção: falha, e o
## JSON tem os números de antes. (Vive em cenas/mestre/ porque lê o modelo do Mestre: canario_privacidade.gd.)

const CENA_MESTRE := "res://cenas/mestre/mestre.tscn"
const CENA_ARENA := "res://cenas/arena/arena.tscn"
const ProvaTerreno := preload("res://cenas/arena/ferramentas/provar_terreno_servidor.gd")
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")
const SEIS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]
## As 5 casas da reserva 3 da Ordem 45 e da Ordem 58 (30 × 30 de 1,5 m).
const CINCO := [Vector2i(27, 0), Vector2i(27, 3), Vector2i(27, 24), Vector2i(24, 27), Vector2i(1, 0)]
## [largura, altura, casaM, conjunto]: «45» = figuras de 3 em 3 casas mais as 6 da encosta; «todas» = uma em cada casa.
const CASOS := [
	[30, 30, 1.5, "45"],
	[20, 20, 1.5, "45"],
	[30, 30, 1.5, "todas"],
	[25, 25, 1.0, "todas"],
]

var _falhas := 0
var _json := {}
var _antes := {}


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, texto: String) -> void:
	if not cond:
		_falhas += 1
	print(("  ok    " if cond else "  FALHA ") + texto)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


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


## O juízo do servidor de verdade: por casa {passavel, motivo}. {} se falhar.
static func _juizo(w: int, h: int, casa: float) -> Dictionary:
	var sv := ProvaTerreno.juizo_do_servidor(w, h, casa, "")
	if not sv.get("juizo") is Dictionary or (sv["juizo"]["casas"] as Array).size() != w * h:
		return {}
	var r := {}
	for c in sv["juizo"]["casas"]:
		r[Vector2i(int(c["x"]), int(c["y"]))] = {"passavel": bool(c["passavel"]), "motivo": str(c["motivo"])}
	return r


static func _debaixo_de(no: Node, pai: Node) -> bool:
	return pai != null and is_instance_valid(pai) and (no == pai or pai.is_ancestor_of(no))


## O que há de visível na arena 3D (fora do mapa da floresta), por casa: {Vector2i: {"malhas": n, "rotulos": [textos]}}.
## Uma malha conta se a caixa dela (no mundo) tem no máximo 2 casas de lado e cobre o centro da casa; um rótulo 3D conta
## se está a menos de 0,6 casa do centro, na horizontal. As figuras de pé (o `_nos` da Ordem 58) contam à parte.
static func _visivel_na_arena(a: Node3D, casa_m: float, centros: Dictionary) -> Dictionary:
	var r := {}
	var pilha: Array = [a]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		if n == a.mapa:
			continue
		for f in n.get_children():
			pilha.append(f)
		if not (n is VisualInstance3D) or n.is_queued_for_deletion() or not (n as Node3D).is_visible_in_tree():
			continue
		if n is Label3D:
			var p: Vector3 = (n as Node3D).global_position
			var t := (n as Label3D).text
			if t == "":
				continue
			for c in centros:
				var ct: Vector3 = centros[c]
				if Vector2(p.x - ct.x, p.z - ct.z).length() < casa_m * 0.6:
					r[c] = r.get(c, {"malhas": 0, "rotulos": []})
					r[c]["rotulos"].append(t)
		elif n is GeometryInstance3D:
			var g := n as GeometryInstance3D
			var caixa: AABB = g.global_transform * g.get_aabb()
			if caixa.size.x > 2.0 * casa_m or caixa.size.z > 2.0 * casa_m:
				continue
			for c in centros:
				var ct: Vector3 = centros[c]
				if ct.x >= caixa.position.x and ct.x <= caixa.end.x and ct.z >= caixa.position.z and ct.z <= caixa.end.z:
					r[c] = r.get(c, {"malhas": 0, "rotulos": []})
					r[c]["malhas"] += 1
	return r


## Os textos visíveis (Label, RichTextLabel, Button) debaixo de `tela`, sem entrar no SubViewport da arena 3D.
static func _textos_visiveis(tela: Node) -> Array:
	var r: Array = []
	var pilha: Array = [tela]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		if n is SubViewport:
			continue
		for f in n.get_children():
			pilha.append(f)
		if not (n is Control) or not (n as Control).is_visible_in_tree():
			continue
		var t := ""
		if n is Label:
			t = (n as Label).text
		elif n is RichTextLabel:
			t = (n as RichTextLabel).get_parsed_text()
		elif n is Button:
			t = (n as Button).text
		if t != "":
			r.append(t)
	return r


static func _tem(textos: Array, partes: Array) -> bool:
	for t in textos:
		var todas := true
		for p in partes:
			if not str(t).contains(str(p)):
				todas = false
				break
		if todas:
			return true
	return false


func _correr() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--antes="):
			var a = JSON.parse_string(FileAccess.get_file_as_string(arg.trim_prefix("--antes=")))
			_antes = a if a is Dictionary else {}
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
	var est = root.get_node("Estado")
	var jog = null
	var seq := 0
	print("== Ordem 60: a recusa do pé vê-se no ecrã (as duas arenas) ==")
	var molde: Dictionary = {}
	for f in fx["mestre"]["vista"]["mestre"]["figuras"]:
		if f.get("colocada") == true:
			molde = f
			break
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
		var v: Dictionary = (fx["mestre"]["vista"] as Dictionary).duplicate(true)
		v["mapa"] = {"largura": w, "altura": h, "casaM": casa}
		var figs_m: Array = []
		var figs_j: Array = []
		for k in casas.size():
			var c: Vector2i = casas[k]
			var f: Dictionary = molde.duplicate(true)
			f["id"] = "p60-%d-%d" % [seq, k]
			f["nome"] = "P%d" % k
			f["x"] = c.x
			f["y"] = c.y
			f["colocada"] = true
			f["vivo"] = true
			f["caido"] = k % 11 == 5
			figs_m.append(f)
			figs_j.append({"id": f["id"], "nomePublico": "P%d" % k, "x": c.x, "y": c.y, "lado": "criatura",
				"visivel": "caida" if k % 11 == 5 else "de_pe"})
		v["mestre"]["figuras"] = figs_m
		v["vezId"] = figs_m[0]["id"]
		if jog != null:
			jog.hud._aviso.visible = false  # o aviso de um caso não conta no seguinte
		var alertas_antes: int = m.alertas.size()
		m.aplicar_vista(v)
		seq += 1
		est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "prova-60", "seq": seq, "revision": seq,
			"fase": "combate", "mapa": {"largura": w, "altura": h, "casaM": casa}, "figuras": figs_j, "vezId": null, "ambiente": {}})
		if jog == null:
			jog = (load(CENA_ARENA) as PackedScene).instantiate()
			root.add_child(jog)
		await _quadros(4)
		var reg := {}
		reg["mestre"] = _medir("mestre", m._arena, m, figs_m, srv, casa, conjunto == "45" and w == 30, nome, m.alertas.slice(alertas_antes))
		reg["jogador"] = _medir("jogador", jog, jog.hud, figs_j, srv, casa, conjunto == "45" and w == 30, nome, [])
		# A mesma vista outra vez: nenhum aviso novo (a recusa não se repete a cada snapshot).
		var n_alertas: int = m.alertas.size()
		jog.hud._aviso.visible = false
		m.aplicar_vista(v)
		est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "prova-60", "seq": seq + 1, "revision": seq + 1,
			"fase": "combate", "mapa": {"largura": w, "altura": h, "casaM": casa}, "figuras": figs_j, "vezId": null, "ambiente": {}})
		seq += 1
		await _quadros(2)
		_ok(m.alertas.size() == n_alertas and not jog.hud._aviso.visible,
			"a mesma vista outra vez: nenhum aviso novo (Mestre +%d alertas; jogadora: aviso %s)" % [m.alertas.size() - n_alertas, "visível" if jog.hud._aviso.visible else "escondido"])
		_json[nome] = reg
	await _entrar_e_sair(m, jog, est, fx, molde, seq + 1)
	m.queue_free()
	jog.queue_free()
	await _quadros(2)
	var saida := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--json="):
			saida = arg.trim_prefix("--json=")
	if saida != "":
		var fj := FileAccess.open(saida, FileAccess.WRITE)
		fj.store_string(JSON.stringify(_json, " "))
		fj.close()
		print("medição escrita em %s" % saida)
	print("%s" % ("TUDO PASSOU" if _falhas == 0 else "%d FALHAS" % _falhas))
	quit(1 if _falhas > 0 else 0)


## Mede uma arena: `a` é a arena 3D, `tela` o que se vê por cima dela (o HUD da jogadora; o ecrã do Mestre).
## `alertas_novos`: os alertas que o Mestre ganhou com esta vista ([] na jogadora).
func _medir(lado: String, a, tela: Node, figs: Array, srv: Dictionary, casa_m: float, sao_as_cinco: bool, caso: String, alertas_novos: Array) -> Dictionary:
	var centros := {}
	for f in figs:
		var c := Vector2i(int(f["x"]), int(f["y"]))
		centros[c] = a.centro_da_casa(c) if lado == "mestre" else a.centro_casa(c)
	var na_arena := _visivel_na_arena(a, casa_m, centros)
	var textos := _textos_visiveis(tela)
	var aviso_lugar: Label = tela._aviso if lado == "jogador" else tela._alerta
	var aviso_texto: String = aviso_lugar.text if aviso_lugar.is_visible_in_tree() else ""
	var folha: Array = []
	if lado == "mestre":
		for l in tela._lista_figuras.get_children():
			if l is Label and not l.is_queued_for_deletion() and (l as Label).is_visible_in_tree():
				folha.append((l as Label).text)
	var bloq := {"total": 0, "de_pe": 0, "marcadas_na_arena": 0, "com_nome_na_arena": 0, "aviso_no_ecra": 0, "na_folha": 0}
	var livres := {"total": 0, "marcadas": 0, "no_aviso": 0, "posicoes_bits": {}, "folha": {}}
	var cinco: Array = []
	var mal: Array = []
	for f in figs:
		var id := str(f["id"])
		var c := Vector2i(int(f["x"]), int(f["y"]))
		var nome_fig: String = Modelo.nome_mestre(f) if lado == "mestre" else str(f["nomePublico"])
		var no: Node3D = a._nos.get(id)
		if no != null and no.is_queued_for_deletion():
			no = null
		var vis: Dictionary = na_arena.get(c, {"malhas": 0, "rotulos": []})
		var linha_folha := ""
		for t in folha:
			if str(t).begins_with(nome_fig + " ") or str(t).begins_with(nome_fig + "·") or str(t) == nome_fig or str(t).begins_with(nome_fig + " ·"):
				linha_folha = t
				break
		if not bool(srv[c]["passavel"]):
			var motivo: String = srv[c]["motivo"]
			bloq["total"] += 1
			var de_pe := no != null
			var marcada: bool = vis["malhas"] > 0
			var com_nome := _tem(vis["rotulos"], [nome_fig, motivo])
			# o aviso: onde a arena já mostra os seus avisos (o «Aviso» do HUD; os alertas do Mestre — o último na
			# coluna 1, a conta e a lista em `alertas`), com o nome e o motivo
			var avisada := _tem([aviso_texto], [nome_fig, motivo]) if lado == "jogador" else _tem(alertas_novos, [nome_fig, motivo])
			var na_folha := linha_folha.contains(motivo) if lado == "mestre" else true
			bloq["de_pe"] += 1 if de_pe else 0
			bloq["marcadas_na_arena"] += 1 if marcada else 0
			bloq["com_nome_na_arena"] += 1 if com_nome else 0
			bloq["aviso_no_ecra"] += 1 if avisada else 0
			bloq["na_folha"] += 1 if (lado == "mestre" and na_folha) else 0
			if de_pe or not marcada or not com_nome or not avisada or not na_folha:
				mal.append("(%d,%d)%s%s%s%s%s" % [c.x, c.y, " de pé" if de_pe else "", "" if marcada else " sem marca", "" if com_nome else " sem rótulo",
					"" if avisada else " sem aviso", "" if na_folha else " folha sem motivo"])
			if sao_as_cinco:
				cinco.append({"x": c.x, "y": c.y, "motivo": motivo, "nome": nome_fig, "de_pe": de_pe, "malhas_na_casa": vis["malhas"],
					"rotulos_na_casa": vis["rotulos"], "aviso_no_ecra": avisada, "linha_da_folha": linha_folha if lado == "mestre" else null})
		else:
			livres["total"] += 1
			if no != null:
				livres["posicoes_bits"][id] = _bits(no.position.x) + _bits(no.position.y) + _bits(no.position.z)
			else:
				livres["posicoes_bits"][id] = null
			if lado == "mestre":
				livres["folha"][id] = linha_folha
			# uma figura de pé tem o seu próprio corpo e rótulo na casa; a marca de recusa é outra coisa: conta-se
			# como marcada a livre que tem um rótulo com «✕» ou um texto de recusa
			if _tem(vis["rotulos"], ["✕"]) or _tem(vis["rotulos"], ["casa bloqueada"]):
				livres["marcadas"] += 1
			if _tem([aviso_texto] if lado == "jogador" else alertas_novos, [nome_fig + " "]) or _tem([aviso_texto] if lado == "jogador" else alertas_novos, ["«%s»" % nome_fig]):
				livres["no_aviso"] += 1
	var n := int(bloq["total"])
	_ok(bloq["de_pe"] == 0, "%s: de pé em casas bloqueadas %d de %d (a regra da Ordem 58 fica)" % [lado, bloq["de_pe"], n])
	_ok(bloq["marcadas_na_arena"] == n and bloq["com_nome_na_arena"] == n,
		"%s: figuras recusadas VISÍVEIS na arena 3D, na casa delas: %d de %d com marca, %d de %d com o nome e o motivo%s" % [
			lado, bloq["marcadas_na_arena"], n, bloq["com_nome_na_arena"], n, (" · mal: %s" % ", ".join(mal.slice(0, 6))) if not mal.is_empty() else ""])
	_ok(bloq["aviso_no_ecra"] == n, "%s: recusas avisadas NO ECRÃ (%s) com o nome e o motivo: %d de %d" % [
		lado, "o «Aviso» do HUD" if lado == "jogador" else "os alertas da coluna 1", bloq["aviso_no_ecra"], n])
	if lado == "mestre":
		_ok(bloq["na_folha"] == n, "mestre: a linha da folha (aba Figuras) diz porque não está de pé: %d de %d" % [bloq["na_folha"], n])
		if n == 0:
			_ok(alertas_novos.is_empty(), "mestre: sem casas bloqueadas, nenhum alerta novo (%d)" % alertas_novos.size())
	else:
		if n == 0:
			_ok(aviso_texto == "", "jogador: sem casas bloqueadas, nenhum aviso no HUD («%s»)" % aviso_texto)
	_ok(livres["marcadas"] == 0 and livres["no_aviso"] == 0, "%s: %d figuras nas casas que se pisam: nenhuma marcada como recusada (%d), nenhuma no aviso (%d)" % [
		lado, livres["total"], livres["marcadas"], livres["no_aviso"]])
	var de_pe_livres := 0
	for id in livres["posicoes_bits"]:
		de_pe_livres += 1 if livres["posicoes_bits"][id] != null else 0
	_ok(de_pe_livres == livres["total"], "%s: as %d nas casas que se pisam estão de pé (%d)" % [lado, livres["total"], de_pe_livres])
	var antes = _antes.get(caso, {}).get(lado, {}).get("livres", {}) if _antes.get(caso) is Dictionary else {}
	if antes is Dictionary and not antes.is_empty():
		var iguais := 0
		var folha_igual := 0
		for id in livres["posicoes_bits"]:
			if antes.get("posicoes_bits", {}).get(id) == livres["posicoes_bits"][id]:
				iguais += 1
			if lado == "mestre" and antes.get("folha", {}).get(id) == livres["folha"][id]:
				folha_igual += 1
		_ok(iguais == livres["total"], "%s: posição igual à da medição de antes, bit a bit: %d de %d" % [lado, iguais, livres["total"]])
		if lado == "mestre":
			_ok(folha_igual == livres["total"], "mestre: linha da folha igual à de antes: %d de %d" % [folha_igual, livres["total"]])
	if sao_as_cinco:
		var casas_cinco: Array = cinco.map(func(e): return Vector2i(e["x"], e["y"]))
		_ok(casas_cinco.size() == CINCO.size() and CINCO.all(func(c): return casas_cinco.has(c)),
			"%s: as casas bloqueadas com figura são as 5 da Ordem 58 %s" % [lado, casas_cinco])
		for e in cinco:
			print("        (%d,%d) %s «%s»: %s · na arena: %d malha(s), rótulos %s · no ecrã: %s%s" % [e["x"], e["y"], e["motivo"], e["nome"],
				"DE PÉ" if e["de_pe"] else "não está de pé", e["malhas_na_casa"], e["rotulos_na_casa"], "AVISADA" if e["aviso_no_ecra"] else "nada",
				(" · folha «%s»" % e["linha_da_folha"]) if lado == "mestre" else ""])
		print("        o aviso %s: «%s»" % ["do HUD" if lado == "jogador" else "da coluna 1", aviso_texto.replace("\n", " ⏎ ")])
	return {"bloqueadas": bloq, "livres": livres, "cinco": cinco, "aviso_visivel": aviso_texto, "alertas_novos": alertas_novos,
		"textos_visiveis_com_motivo": textos.filter(func(t): return str(t).contains("bloquead") or str(t).contains("escarpa") or str(t).contains("água funda"))}


## A entra numa casa bloqueada e B sai dela (30 × 30 de 1,5 m, a escarpa (27,24)): a marca e o aviso seguem quem entra;
## quem sai volta a estar de pé, sem marca.
func _entrar_e_sair(m, jog, est, fx: Dictionary, molde: Dictionary, seq: int) -> void:
	print("-- uma figura entra numa casa bloqueada e outra sai dela (30x30 de 1.5 m) --")
	var srv := _juizo(30, 30, 1.5)
	var bloq := Vector2i(27, 24)
	var livre := Vector2i(-1, -1)
	for x in 30:
		if bool(srv[Vector2i(x, 24)]["passavel"]):
			livre = Vector2i(x, 24)
	for passo in [[bloq, livre], [livre, bloq]]:
		var v: Dictionary = (fx["mestre"]["vista"] as Dictionary).duplicate(true)
		v["mapa"] = {"largura": 30, "altura": 30, "casaM": 1.5}
		var figs_m: Array = []
		var figs_j: Array = []
		for k in 2:
			var c: Vector2i = passo[k]
			var f: Dictionary = molde.duplicate(true)
			f["id"] = ["A", "B"][k]
			f["nome"] = ["Alfa", "Bravo"][k]
			f["x"] = c.x
			f["y"] = c.y
			f["colocada"] = true
			f["vivo"] = true
			f["caido"] = false
			figs_m.append(f)
			figs_j.append({"id": f["id"], "nomePublico": f["nome"], "x": c.x, "y": c.y, "lado": "criatura", "visivel": "de_pe"})
		v["mestre"]["figuras"] = figs_m
		v["vezId"] = "A"
		jog.hud._aviso.visible = false
		var alertas_antes: int = m.alertas.size()
		m.aplicar_vista(v)
		est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "prova-60", "seq": seq, "revision": seq,
			"fase": "combate", "mapa": {"largura": 30, "altura": 30, "casaM": 1.5}, "figuras": figs_j, "vezId": null, "ambiente": {}})
		seq += 1
		await _quadros(3)
		var quem_entra: Dictionary = figs_m[0] if passo[0] == bloq else figs_m[1]
		var quem_sai: Dictionary = figs_m[1] if passo[0] == bloq else figs_m[0]
		var novos: Array = m.alertas.slice(alertas_antes)
		for lado in [["mestre", m._arena, Modelo.nome_mestre(quem_entra), Modelo.nome_mestre(quem_sai)], ["jogador", jog, str(quem_entra["nome"]), str(quem_sai["nome"])]]:
			var a = lado[1]
			var cent := {bloq: a.centro_da_casa(bloq) if lado[0] == "mestre" else a.centro_casa(bloq),
				livre: a.centro_da_casa(livre) if lado[0] == "mestre" else a.centro_casa(livre)}
			var vis := _visivel_na_arena(a, 1.5, cent)
			var vb: Dictionary = vis.get(bloq, {"malhas": 0, "rotulos": []})
			var vl: Dictionary = vis.get(livre, {"malhas": 0, "rotulos": []})
			var aviso: String = (jog.hud._aviso.text if jog.hud._aviso.visible else "") if lado[0] == "jogador" else "\n".join(novos)
			var ns = a._nos.get(quem_sai["id"])
			_ok(ns != null and not a._nos.has(quem_entra["id"]) and vb["malhas"] > 0 and _tem(vb["rotulos"], [lado[2], "escarpa"])
				and not _tem(vl["rotulos"], ["✕"]) and aviso.contains(lado[2]) and aviso.contains("escarpa") and not aviso.contains(lado[3]),
				"%s: %s na escarpa (27,24) marcada e avisada («%s»); %s de pé em %s, sem marca nem aviso" % [lado[0], lado[2], aviso.replace("\n", " ⏎ "), lado[3], livre])
