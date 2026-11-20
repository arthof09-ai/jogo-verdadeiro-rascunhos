extends SceneTree
## medir_mapa_jogavel.gd — ORDEM MAPA-JOGÁVEL. A arena do jogo (a da jogadora, a mesma do exportador do terreno),
## SEM JANELA (só CPU, --headless), aberta como um snapshot do servidor a abriria:
##   - antes: a grelha de 20 × 20 de 1,5 m (a de sempre);
##   - depois: a grelha-mapa — 50 × 50 de 1,5 m (a sala nasce aqui), 75 × 75 de 1 m e 37 × 37 de 2 m.
## Para cada uma: a zona jogável, o que o mapa planta e tira (as medidas do CampoFloresta), o tempo da construção, as
## linhas da grelha e — com uma figura no meio do lago — se ela fica de pé (sem recusa) e se mexe a água.
## Escreve o JSON em `--saida=<ficheiro>` (por omissão, só imprime).
##
##   godot --headless --path cliente -s res://cenas/arena/ferramentas/medir_mapa_jogavel.gd -- --saida=<json>

const CENA := "res://cenas/arena/arena.tscn"
const CampoDaMesa := preload("res://cenas/arena/campo_da_mesa.gd")

## [largura, altura, casaM, a casa do «meio do lago» nessa grelha (a do teste do servidor) ou null]
const CASOS := [
	[20, 20, 1.5, null],
	[50, 50, 1.5, Vector2i(36, 9)],
	[75, 75, 1.0, Vector2i(54, 14)],
	[37, 37, 2.0, Vector2i(27, 6)],
]
const CHAVES_MEDIDAS := ["arvores_arena", "arvores_orla", "rochas", "zona_tirados_arvores", "zona_tirados_rochas",
	"zona_tirados_estrato", "zona_tronco_tombado_m", "casas_bloqueadas", "estrato_tri", "arvores_tri", "relva_tufos"]

var _arena: Node = null
var _seq := 0


func _initialize() -> void:
	_correr.call_deferred()


func _abrir(w: int, h: int, s: float, figuras: Array) -> Node:
	_seq += 1
	root.get_node("/root/Estado").aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "mapa-jogavel", "seq": _seq,
		"revision": _seq, "fase": "combate", "mapa": {"largura": w, "altura": h, "casaM": s}, "figuras": figuras,
		"vezId": null, "ambiente": {}})
	if _arena == null:
		_arena = (load(CENA) as PackedScene).instantiate()
		root.add_child(_arena)
	for i in 3:
		await process_frame
	return _arena


func _correr() -> void:
	root.get_node("/root/Rede")._ativo = true
	var saida := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			saida = a.substr(8)
	var resultados: Array = []
	var falhas := 0
	for caso in CASOS:
		var w: int = caso[0]
		var h: int = caso[1]
		var s: float = caso[2]
		var lago_casa = caso[3]
		var figuras: Array = []
		if lago_casa is Vector2i:
			figuras.append({"id": "f-lago", "nomePublico": "No lago", "x": lago_casa.x, "y": lago_casa.y, "visivel": "de_pe"})
		var t0 := Time.get_ticks_msec()
		var arena = await _abrir(w, h, s, figuras)
		var ms := Time.get_ticks_msec() - t0
		var r := {"grelha": "%dx%d@%s" % [w, h, s], "abriu": arena.largura == w and arena.altura == h and is_equal_approx(arena.casa_m, s),
			"zona_jogo": [arena.mapa.zona_jogo.position.x, arena.mapa.zona_jogo.position.y, arena.mapa.zona_jogo.size.x, arena.mapa.zona_jogo.size.y],
			"construcao_ms": ms}
		var med := {}
		for k in CHAVES_MEDIDAS:
			if arena.mapa.medidas.has(k):
				med[k] = arena.mapa.medidas[k]
		r["mapa"] = med
		var linhas := arena._grelha.get_node_or_null("Linhas") as MeshInstance3D
		# o que as linhas da grelha cobrem no chão (m): a grelha desenhada sobre o mapa
		if linhas != null and linhas.mesh != null:
			var bb: AABB = linhas.mesh.get_aabb()
			r["linhas_cobrem_m"] = [snappedf(bb.position.x, 0.01), snappedf(bb.position.z, 0.01), snappedf(bb.size.x, 0.01), snappedf(bb.size.z, 0.01)]
		if lago_casa is Vector2i:
			var recusas: Dictionary = arena.pes_recusados()
			var no = arena._nos.get("f-lago")
			var lago = arena.mapa.get("lago")
			r["figura_no_lago"] = {
				"casa": [lago_casa.x, lago_casa.y],
				"casa_de_agua": CampoDaMesa.casa_de_agua(arena.mapa, arena.origem, arena.casa_m, lago_casa),
				"recusada": recusas.has("f-lago"),
				"de_pe": no != null,
				"mexe_a_agua": no != null and lago != null and lago.segue(no),
				"pe_y": snappedf((no as Node3D).position.y, 0.001) if no != null else null,
				"nivel_lago": snappedf(lago.nivel(), 0.001) if lago != null else null,
				"agua_acima_do_pe_m": snappedf(lago.nivel() - (no as Node3D).position.y, 0.001) if no != null and lago != null else null,
			}
			if recusas.has("f-lago") or no == null or not lago.segue(no) or not r["figura_no_lago"]["casa_de_agua"]:
				falhas += 1
		if not r["abriu"]:
			falhas += 1
		print(JSON.stringify(r))
		resultados.append(r)
	if saida != "":
		var f := FileAccess.open(saida, FileAccess.WRITE)
		f.store_string(JSON.stringify({"ordem": "MAPA-JOGAVEL", "casos": resultados, "falhas": falhas}, "  ", false))
		f.close()
	print("medir_mapa_jogavel: %d caso(s), %d falha(s)" % [resultados.size(), falhas])
	quit(1 if falhas > 0 else 0)
