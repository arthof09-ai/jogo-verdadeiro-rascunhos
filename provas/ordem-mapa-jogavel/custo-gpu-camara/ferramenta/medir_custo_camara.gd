extends SceneTree
## medir_custo_camara.gd — ORDEM MAPA-JOGÁVEL-CUSTO-CÂMARA (23/11/2026). Cópia de trabalho de
## `provas/ordem-mapa-jogavel/capturas/ferramenta/foto_mapa_jogavel.gd` (a parte «a arena da jogadora»: o mesmo snapshot,
## a mesma figura «No lago», o mesmo perfil «alto», o mesmo Panorama), acrescentada da leitura de `_dist_panorama` e do
## frustum da câmara. Não é código do jogo, não toca em nada do jogo: só lê. Vive SÓ aqui (nunca na ferramenta partilhada).
##
## Corre COM render (GPU, janela), uma grelha por processo:
##   godot --path rascunhos/cliente --resolution 1920x1080 --disable-vsync -s <caminho absoluto deste ficheiro> -- \
##       --grelha=20|50|75|37 --corrida=<n> --saida=<pasta> [--quadros=600] [--aquecer=180]
##
## A1 (custo): depois do aquecimento, `quadros` quadros seguidos com a câmara parada em Panorama a enquadrar a grelha:
##   FPS médio (quadros / tempo de parede), ms/quadro (mediana dos intervalos entre quadros), chamadas de desenho
##   (média por quadro, RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), primitivas, CPU do lago (`LagoFloresta.custo_medio_us()`,
##   o custo médio do `avancar()` em µs/quadro nesse intervalo).
## A2 (câmara): os 16 pontos do critério de `_recalcular_panorama` (4 cantos + 4 meios de borda, a 0 m e a 1,8 m acima do
##   chão do relevo nesse ponto), testados com `is_position_in_frustum` NA CÂMARA REAL, na distância final aplicada
##   (depois da suavização), antes e depois da medição do custo. Regista `_dist_panorama`, a distância real câmara–centro,
##   o número de crescimentos ×1,06 (deduzido de `_dist_panorama`: d0 × 1,06^n × 1,03) e a folga em píxeis de cada ponto
##   à borda do ecrã.
## Com --foto=<ficheiro.png> grava também o quadro do Panorama (a foto de controlo da A2), antes da medição do custo.
## Escreve <saida>/<grelha>-c<n>.json. Saída 0 se a medição correu (o veredicto A2 lê-se no JSON, não no código de saída).

const CENA_JOGADORA := "res://cenas/arena/arena.tscn"
const CampoDaMesa := preload("res://cenas/arena/campo_da_mesa.gd")
const Assentamento := preload("res://cenas/arena/assentamento.gd")
const CAMERA_PANORAMA := 2

## [largura, altura, casaM, a casa no meio do lago (as das provas: foto_mapa_jogavel.gd / provar_terreno_servidor)]
## A 20 × 20 (a referência) não chega ao lago: a casa sai de `_casa_mais_perto(SITIO_LAGO)` e fica registada.
const CASOS := {
	"20": [20, 20, 1.5, Vector2i(-1, -1)],
	"50": [50, 50, 1.5, Vector2i(36, 9)],
	"75": [75, 75, 1.0, Vector2i(54, 14)],
	"37": [37, 37, 2.0, Vector2i(27, 6)],
}
## O centro da casa (36, 9) da grelha-mapa de 1,5 m (canto NO em −37,5 m): o sítio do lago das provas.
const SITIO_LAGO := Vector2(-37.5 + 36.5 * 1.5, -37.5 + 9.5 * 1.5)

var _saida := ""
var _grelha := "50"
var _corrida := 1
var _quadros := 600
var _aquecer := 180
var _foto := ""


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _esperar(n: int) -> void:
	for i in n:
		await process_frame


func _snapshot(w: int, h: int, s: float, c: Vector2i) -> void:
	root.get_node("/root/Estado").aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "custo-camara",
		"seq": 1, "revision": 1, "fase": "combate", "mapa": {"largura": w, "altura": h, "casaM": s},
		"figuras": [{"id": "f-lago", "nomePublico": "No lago", "x": c.x, "y": c.y, "lado": "jogadora",
			"orientacao": "N", "visivel": "de_pe"}], "vezId": null, "ambiente": {}})


func _casa_mais_perto(w: int, h: int, s: float, p: Vector2) -> Vector2i:
	var o := Assentamento.origem_no_mapa(Vector2(w * s, h * s), s)
	return Vector2i(clampi(int(floor((p.x - o.x) / s)), 0, w - 1), clampi(int(floor((p.y - o.y) / s)), 0, h - 1))


## Os 16 pontos, exactamente como `_recalcular_panorama` os monta (centro, tamanho e chão da própria câmara).
func _pontos(cam) -> Array:
	var meio: Vector2 = cam._tamanho * 0.5
	var centro: Vector3 = cam._centro
	var r: Array = []
	for altura in [0.0, 1.8]:
		for f: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
			var x := centro.x + meio.x * f.x
			var z := centro.z + meio.y * f.y
			r.append({"f": [f.x, f.y], "altura_m": altura, "p": Vector3(x, cam._chao(x, z) + altura, z)})
	return r


func _frustum(cam) -> Dictionary:
	var vp: Vector2 = Vector2(root.get_visible_rect().size)
	var dentro := 0
	var folga_min := INF
	var pts: Array = []
	for e in _pontos(cam):
		var p: Vector3 = e["p"]
		var ok: bool = cam.is_position_in_frustum(p)
		var px: Vector2 = cam.unproject_position(p)
		var folga := minf(minf(px.x, vp.x - px.x), minf(px.y, vp.y - px.y))
		folga_min = minf(folga_min, folga)
		if ok:
			dentro += 1
		pts.append({"f": e["f"], "altura_m": e["altura_m"], "dentro": ok,
			"ecra_px": [snappedf(px.x, 0.1), snappedf(px.y, 0.1)], "folga_px": snappedf(folga, 0.1)})
	var d0: float = maxf(cam._tamanho.x, cam._tamanho.y) * 0.5
	var dp: float = cam._dist_panorama
	var n := int(round(log(dp / 1.03 / d0) / log(1.06)))
	return {"dentro": dentro, "total": pts.size(), "folga_min_px": snappedf(folga_min, 0.1),
		"dist_panorama_m": snappedf(dp, 0.001), "dist_real_m": snappedf(cam.global_position.distance_to(cam._centro), 0.001),
		"d0_m": snappedf(d0, 0.001), "crescimentos_x1_06": n, "iteracoes_do_ciclo": mini(n + 1, 60), "tecto_60_atingido": n >= 60,
		"residuo_formula": snappedf(dp - d0 * pow(1.06, n) * 1.03, 0.0001),
		"viewport_px": [int(vp.x), int(vp.y)], "camera_fov_graus": cam.fov, "camera_keep_aspect": cam.keep_aspect,
		"pontos": pts}


func _correr() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
		elif a.begins_with("--grelha="):
			_grelha = a.trim_prefix("--grelha=")
		elif a.begins_with("--corrida="):
			_corrida = int(a.trim_prefix("--corrida="))
		elif a.begins_with("--quadros="):
			_quadros = int(a.trim_prefix("--quadros="))
		elif a.begins_with("--foto="):
			_foto = a.trim_prefix("--foto=")
		elif a.begins_with("--aquecer="):
			_aquecer = int(a.trim_prefix("--aquecer="))
	DirAccess.make_dir_recursive_absolute(_saida)
	var caso: Array = CASOS[_grelha]
	var w: int = caso[0]
	var h: int = caso[1]
	var s: float = caso[2]
	var c: Vector2i = caso[3]
	if c.x < 0:
		c = _casa_mais_perto(w, h, s, SITIO_LAGO)
	Engine.max_fps = 0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = Vector2i(1920, 1080)
	print("== custo/câmara · grelha %dx%d @ %s m · corrida %d · render: %s ==" % [w, h, str(s), _corrida, RenderingServer.get_video_adapter_name()])
	root.get_node("/root/Rede")._ativo = true  # sem servidor: a arena não vai ao lobby (como em foto_mapa_jogavel.gd)
	_snapshot(w, h, s, c)
	var arena: Node = (load(CENA_JOGADORA) as PackedScene).instantiate()
	root.add_child(arena)
	await _esperar(4)
	arena._perfis.aplicar("alto")
	var cam = arena.camera
	cam.set_process(true)
	cam.definir_modo(CAMERA_PANORAMA)
	cam._saltar()
	await _esperar(60)
	var lago = arena.mapa.get("lago")
	var r := {"ordem": "MAPA-JOGAVEL-CUSTO-CAMARA", "grelha": "%dx%d_%sm" % [w, h, str(s).replace(".", ",")],
		"corrida": _corrida, "render": RenderingServer.get_video_adapter_name(),
		"versao_godot": Engine.get_version_info().get("string", ""),
		"vsync": DisplayServer.window_get_vsync_mode(), "max_fps": Engine.max_fps,
		"janela_px": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"perfil": arena._perfis.atual,
		"abriu": arena.largura == w and arena.altura == h and is_equal_approx(arena.casa_m, s),
		"casa_figura": [c.x, c.y],
		"casa_de_agua": CampoDaMesa.casa_de_agua(arena.mapa, arena.origem, arena.casa_m, c),
		"recusada": arena.pes_recusados().has("f-lago")}
	var no = arena._nos.get("f-lago")
	if no != null and lago != null:
		r["agua_acima_do_pe_m"] = snappedf(lago.nivel() - (no as Node3D).position.y, 0.001)
	r["camera_antes"] = _frustum(cam)
	if _foto != "":
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		r["foto"] = {"ficheiro": _foto.get_file(), "ok": img != null and not img.is_empty() and img.save_png(_foto) == OK,
			"px": [img.get_width(), img.get_height()] if img != null else null}
	# A1: o custo
	await _esperar(_aquecer)
	if lago != null:
		lago.custo_medio_us()  # zera a conta
	var tempos := PackedFloat64Array()
	var chamadas := 0.0
	var primitivas := 0.0
	var t_ini := Time.get_ticks_usec()
	var t_ant := t_ini
	for i in _quadros:
		await process_frame
		var t := Time.get_ticks_usec()
		tempos.append(float(t - t_ant) / 1000.0)
		t_ant = t
		chamadas += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
		primitivas += RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	var total_s := float(t_ant - t_ini) / 1e6
	var ord := Array(tempos)
	ord.sort()
	var mediana: float = (ord[ord.size() / 2] + ord[(ord.size() - 1) / 2]) * 0.5
	r["custo"] = {"quadros": _quadros, "aquecimento": _aquecer, "tempo_s": snappedf(total_s, 0.0001),
		"fps_medio": snappedf(_quadros / total_s, 0.1), "ms_quadro_mediana": snappedf(mediana, 0.001),
		"ms_quadro_min": snappedf(ord[0], 0.001), "ms_quadro_max": snappedf(ord[ord.size() - 1], 0.001),
		"ms_quadro_p95": snappedf(ord[int(ord.size() * 0.95)], 0.001),
		"chamadas_de_desenho": snappedf(chamadas / _quadros, 0.1), "primitivas": int(primitivas / _quadros),
		"lago_avancar_us_por_quadro": snappedf(lago.custo_medio_us(), 0.01) if lago != null else null,
		"memoria_video_mb": snappedf(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576.0, 0.1)}
	r["camera_depois"] = _frustum(cam)
	print(JSON.stringify(r["custo"]))
	print("A2 antes %d/%d · depois %d/%d · _dist_panorama %.3f m · crescimentos %d" % [r["camera_antes"]["dentro"], r["camera_antes"]["total"],
		r["camera_depois"]["dentro"], r["camera_depois"]["total"], r["camera_depois"]["dist_panorama_m"], r["camera_depois"]["crescimentos_x1_06"]])
	var f := FileAccess.open(_saida.path_join("%s-c%d.json" % [_grelha, _corrida]), FileAccess.WRITE)
	f.store_string(JSON.stringify(r, "  ", false))
	f.close()
	arena.queue_free()
	await _esperar(3)
	quit(0 if r["abriu"] else 1)
