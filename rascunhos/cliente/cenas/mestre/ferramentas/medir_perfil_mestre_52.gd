extends SceneTree
## medir_perfil_mestre_52.gd — Ordem 52. A MEDIÇÃO do perfil gráfico nas duas arenas, sem janela. Conta, na arena do
## ecrã do Mestre (mestre.tscn) e na arena do jogador (arena.tscn), para a grelha 20 × 20 de 1,5 m:
##   - a relva do mapa: a densidade, os tufos semeados (todos) e os tufos desenhados vistos da câmara da mesa
##     (depois do LOD por distância, antes do frustum);
##   - o clima: para chuva fraca/forte e neve fraca/forte, as contagens-alvo (chuva, neve, salpicos, véu) e as
##     partículas desenhadas nas MultiMesh depois de 3 s (a transição dura ~1,5 s).
## No Mestre: primeiro SEM escolha (como abre), depois com cada perfil escolhido pela linha «Gráficos» da aba Sala
## (mestre.escolher_perfil, sem guardar). No jogador: como abre (a preferência do HUD) e com cada perfil da ⚙.
## Corre também na árvore de antes da Ordem 52: aí o Mestre não tem escolha e só se mede o «sem escolha».
##
##   godot --headless --path cliente -s res://cenas/mestre/ferramentas/medir_perfil_mestre_52.gd [-- --json=caminho]
## Sai com 0 (é uma medição; as verificações estão em testes/pecas_mestre.gd).

const CENA_MESTRE := "res://cenas/mestre/mestre.tscn"
const CENA_ARENA := "res://cenas/arena/arena.tscn"
const CLIMAS := ["chuva-fraca", "chuva-forte", "neve-fraca", "neve-forte"]

var _json := {}


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _medir(arena) -> Dictionary:
	var r := {}
	var mapa = arena.mapa
	var relva = mapa.relva
	var semeados := 0
	for b in relva._blocos:
		semeados += (b["mm"] as MultiMesh).instance_count
	relva.atualizar_lod(arena.camera.global_position)
	r["relva"] = {"densidade": snappedf(mapa.densidade_relva, 0.001), "semeados": semeados, "desenhados": relva.tufos_ativos()}
	var cl = arena.clima
	r["clima_perfil"] = cl.perfil
	var climas := {}
	for nome in CLIMAS:
		cl.definir_por_nome(nome)
		for i in 30:
			cl.avancar(0.1)
		var desenhadas := {}
		for mmi in cl.find_children("*", "MultiMeshInstance3D", true, false):
			var mm: MultiMesh = (mmi as MultiMeshInstance3D).multimesh
			if mm != null:
				desenhadas[String(mmi.name)] = mm.visible_instance_count if (mmi as Node3D).visible else 0
		climas[nome] = {
			"alvo": {"chuva": cl.contagem_alvo("chuva"), "neve": cl.contagem_alvo("neve"),
				"salpicos": cl.contagem_alvo("salpicos"), "veu": cl.contagem_alvo("veu")},
			"desenhadas": desenhadas}
	cl.definir_por_nome("nenhum")
	for i in 30:
		cl.avancar(0.1)
	r["clima"] = climas
	return r


func _linha(rotulo: String, m: Dictionary) -> void:
	var rel: Dictionary = m["relva"]
	var partes: Array[String] = []
	for nome in CLIMAS:
		var a: Dictionary = m["clima"][nome]["alvo"]
		partes.append("%s %d/%d/%d/%d" % [nome, a["chuva"], a["neve"], a["salpicos"], a["veu"]])
	print("  %-26s relva %.2f · %d semeados · %d desenhados | clima «%s»: %s" % [rotulo, rel["densidade"],
		rel["semeados"], rel["desenhados"], m["clima_perfil"], " · ".join(partes)])


func _correr() -> void:
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede._ativo = true  # sem rede: as arenas não tentam ligar-se
	rede.papel = "mestre"
	root.size = Vector2i(1920, 1080)

	print("== ecrã do Mestre (alvos do clima: chuva/neve/salpicos/véu) ==")
	var m = (load(CENA_MESTRE) as PackedScene).instantiate()
	m.enviar_fn = func(_t, _c, _r): return ""
	m.pedir_vista_fn = func(): pass
	root.add_child(m)
	await _quadros(3)
	var a = m._arena
	var mestre := {}
	mestre["sem_escolha"] = _medir(a)
	_linha("sem escolha", mestre["sem_escolha"])
	if m.has_method("escolher_perfil"):
		for nome in ["baixo", "medio", "alto"]:
			m.escolher_perfil(nome, false)
			await _quadros(1)
			mestre[nome] = _medir(a)
			_linha("perfil " + nome, mestre[nome])
	else:
		print("  (árvore sem a Ordem 52: o ecrã do Mestre não tem escolha de perfil)")
	_json["mestre"] = mestre
	m.queue_free()
	await _quadros(2)

	print("== arena do jogador ==")
	var est = root.get_node("Estado")
	est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "medir-52", "seq": 1, "revision": 1,
		"fase": "combate", "mapa": {"largura": 20, "altura": 20, "casaM": 1.5}, "figuras": [], "ambiente": {}})
	var jog = (load(CENA_ARENA) as PackedScene).instantiate()
	root.add_child(jog)
	await _quadros(3)
	var jogador := {}
	jogador["como_abre"] = _medir(jog)
	jogador["como_abre"]["perfil_do_hud"] = str(jog.hud.pref.get("perfil", ""))
	_linha("como abre (HUD «%s»)" % jogador["como_abre"]["perfil_do_hud"], jogador["como_abre"])
	for nome in ["baixo", "medio", "alto"]:
		jog._aplicar_perfil(nome)
		await _quadros(1)
		jogador[nome] = _medir(jog)
		_linha("perfil " + nome, jogador[nome])
	_json["jogador"] = jogador
	jog.queue_free()
	await _quadros(2)

	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--json="):
			var f := FileAccess.open(arg.trim_prefix("--json="), FileAccess.WRITE)
			f.store_string(JSON.stringify(_json, " ", true))
			f.close()
			print("medição escrita em %s" % arg.trim_prefix("--json="))
	quit(0)
