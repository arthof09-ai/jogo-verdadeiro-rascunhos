extends SceneTree
## foto_mapa_jogavel.gd — ORDEM CAPTURAS-MAPA (20/11/2026). As fotos da grelha-mapa para o olho do Mestre, COM
## render (GPU, janela), nunca --headless. Junta as duas ferramentas que já havia:
##   - medir_mapa_jogavel.gd  (a arena da jogadora aberta como um snapshot a abriria; as grelhas e as casas do lago);
##   - testes/foto_mestre.gd  (o ecrã do Mestre com a vista REAL da fixture do servidor; a gravação por frame_post_draw).
## Não é código do jogo: vive em provas/ e corre por uma cópia temporária dentro de cliente/ (res://).
##
##   copiar para cliente/cenas/arena/ferramentas/_foto_mapa_jogavel.gd e:
##   godot --path cliente --resolution 1920x1080 -s res://cenas/arena/ferramentas/_foto_mapa_jogavel.gd -- \
##       --saida=<pasta> [--so=jogadora|mestre]
##
## Para cada grelha (50×50@1,5 m · 75×75@1 m · 37×37@2 m):
##   jogadora_<grelha>_1-mapa-todo.png    a arena da jogadora em Panorama: a grelha sobre o mapa inteiro, o lago dentro,
##                                        uma figura numa casa de água (a da prova do servidor);
##   jogadora_<grelha>_2-perto-no-lago.png a figura, de perto, logo depois de ENTRAR no lago (vem da casa seca ao lado:
##                                        o salpico e os anéis da ÁGUA-REAÇÃO);
##   mestre_<grelha>_1-ecra-mapa-todo.png  o ecrã do Mestre (vista da fixture, figuras mudadas para a grelha-mapa, a
##                                        heroína no lago), a aba Sala aberta com o selector da escala.
## Escreve também medicao.json (casas, salpicos, nível da água, cores na amostra). Saída 0 se todas saem.

const CENA_JOGADORA := "res://cenas/arena/arena.tscn"
const CENA_MESTRE := "res://cenas/mestre/mestre.tscn"
const CampoDaMesa := preload("res://cenas/arena/campo_da_mesa.gd")
const Textos := preload("res://cenas/mestre/textos_mestre.gd")
const CAMERA_FIXA := 0
const CAMERA_PANORAMA := 2

## [largura, altura, casaM, a casa no meio do lago (a do teste do servidor / medir_mapa_jogavel.gd)]
const CASOS := [
	[50, 50, 1.5, Vector2i(36, 9)],
	[75, 75, 1.0, Vector2i(54, 14)],
	[37, 37, 2.0, Vector2i(27, 6)],
]

var _saida := ""
var _so := ""
var _falhas := 0
var _seq := 0
var _medidas: Array = []


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	await create_timer(s).timeout


func _nome_grelha(caso: Array) -> String:
	return ("%dx%d_%sm" % [caso[0], caso[1], str(caso[2])]).replace(".", ",")


func _gravar(nome: String) -> Dictionary:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		printerr("  FALHA ", nome, ": sem imagem (o render não correu)")
		_falhas += 1
		return {"foto": nome, "ok": false}
	var cores := {}
	for j in 36:
		for i in 64:
			var c := img.get_pixel(int((i + 0.5) * img.get_width() / 64.0), int((j + 0.5) * img.get_height() / 36.0))
			cores[c.to_html(false)] = true
	var erro := img.save_png(_saida.path_join(nome))
	if erro != OK or cores.size() < 8:
		printerr("  FALHA ", nome, ": erro ", erro, ", ", cores.size(), " cores distintas")
		_falhas += 1
		return {"foto": nome, "ok": false}
	print("  ok    ", nome, " (", img.get_width(), "×", img.get_height(), ", ", cores.size(), " cores na amostra)")
	return {"foto": nome, "ok": true, "cores_amostra": cores.size()}


## Uma casa seca encostada ao lago (vizinha de `c`), para a figura ENTRAR na água à vista.
## Seca a sério: fora das casas de água E sem água por cima do chão no centro (a rasa passa das 21 casas bloqueadas).
func _margem(arena, c: Vector2i, w: int, h: int) -> Vector2i:
	var mapa = arena.mapa
	var origem: Vector2 = arena.origem
	var casa_m: float = arena.casa_m
	var lago = mapa.get("lago")
	for raio in range(1, 9):
		for d in [Vector2i(-raio, 0), Vector2i(0, raio), Vector2i(raio, 0), Vector2i(0, -raio),
				Vector2i(-raio, raio), Vector2i(raio, raio), Vector2i(raio, -raio), Vector2i(-raio, -raio)]:
			var v: Vector2i = c + d
			if v.x < 0 or v.y < 0 or v.x >= w or v.y >= h:
				continue
			if CampoDaMesa.casa_de_agua(mapa, origem, casa_m, v):
				continue
			var p: Vector3 = arena.centro_casa(v)
			if lago != null and lago.fundura(p.x, p.z) > 0.0:
				continue
			if CampoDaMesa.recusa_do_pe(mapa, origem, casa_m, v) == "":
				return v
	return Vector2i(-1, -1)


# ---------------------------------------------------------------- a arena da jogadora

func _snapshot(w: int, h: int, s: float, figuras: Array) -> void:
	_seq += 1
	root.get_node("/root/Estado").aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "capturas-mapa",
		"seq": _seq, "revision": _seq, "fase": "combate", "mapa": {"largura": w, "altura": h, "casaM": s},
		"figuras": figuras, "vezId": null, "ambiente": {}})


func _fig(c: Vector2i) -> Dictionary:
	return {"id": "f-lago", "nomePublico": "No lago", "x": c.x, "y": c.y, "lado": "jogadora", "orientacao": "N",
		"visivel": "de_pe"}


func _jogadora() -> void:
	print("== a arena da jogadora ==")
	root.get_node("/root/Rede")._ativo = true  # sem servidor: a arena não vai ao lobby (como em medir_mapa_jogavel.gd)
	var arena: Node = null
	for caso in CASOS:
		var w: int = caso[0]
		var h: int = caso[1]
		var s: float = caso[2]
		var lago_casa: Vector2i = caso[3]
		var g := _nome_grelha(caso)
		_snapshot(w, h, s, [_fig(lago_casa)])
		if arena == null:
			arena = (load(CENA_JOGADORA) as PackedScene).instantiate()
			root.add_child(arena)
		await _quadros(4)
		arena._perfis.aplicar("alto")
		var r := {"vista": "jogadora", "grelha": g, "abriu": arena.largura == w and arena.altura == h and is_equal_approx(arena.casa_m, s),
			"casa_lago": [lago_casa.x, lago_casa.y],
			"casa_de_agua": CampoDaMesa.casa_de_agua(arena.mapa, arena.origem, arena.casa_m, lago_casa),
			"recusada": arena.pes_recusados().has("f-lago")}
		# 1. a grelha sobre o mapa todo (Panorama: a câmara enquadra a arena inteira)
		arena.camera.set_process(true)
		arena.camera.definir_modo(CAMERA_PANORAMA)
		arena.camera._saltar()
		await _quadros(20)
		r["mapa_todo"] = await _gravar("jogadora_%s_1-mapa-todo.png" % g)
		# 2. de perto: da casa seca da margem para dentro do lago — o salpico ao entrar
		var margem := _margem(arena, lago_casa, w, h)
		r["casa_margem"] = [margem.x, margem.y]
		var lago = arena.mapa.get("lago")
		if margem.x >= 0 and lago != null:
			_snapshot(w, h, s, [_fig(margem)])
			await _quadros(4)
			await _segundos(1.0)
			var antes: int = lago.salpicos
			arena.camera.definir_modo(CAMERA_FIXA)
			arena.camera.focar(arena.centro_casa(lago_casa))
			arena.camera.definir_zoom(3.0)
			arena.camera._saltar()
			_snapshot(w, h, s, [_fig(lago_casa)])
			# o passo (o tween de 0,25 s por casa) e os primeiros anéis do salpico: à espera do salpico, até 3 s
			var t := 0.0
			while lago.salpicos == antes and t < 3.0:
				await _segundos(0.05)
				t += 0.05
			await _segundos(0.35)
			r["salpicos_ao_entrar"] = lago.salpicos - antes
			var no = arena._nos.get("f-lago")
			if no != null:
				r["agua_acima_do_pe_m"] = snappedf(lago.nivel() - (no as Node3D).position.y, 0.001)
			r["perto"] = await _gravar("jogadora_%s_2-perto-no-lago.png" % g)
		else:
			printerr("  FALHA %s: sem casa seca na margem do lago" % g)
			_falhas += 1
		print(JSON.stringify(r))
		_medidas.append(r)
	arena.queue_free()
	await _quadros(3)


# ---------------------------------------------------------------- o ecrã do Mestre

func _mestre() -> void:
	print("== o ecrã do Mestre ==")
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var fx = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (fx is Dictionary):
		printerr("sem a fixture do servidor")
		_falhas += 1
		return
	var rede := root.get_node("Rede")
	rede._ativo = false
	rede.persistir = false
	rede.papel = "mestre"
	for caso in CASOS:
		var w: int = caso[0]
		var h: int = caso[1]
		var s: float = caso[2]
		var lago_casa: Vector2i = caso[3]
		var g := _nome_grelha(caso)
		var vista: Dictionary = (fx["mestre"]["vista"] as Dictionary).duplicate(true)
		vista["mapa"] = {"largura": w, "altura": h, "casaM": s}
		vista.erase("fogo")  # as casas a arder da fixture são de 20 × 20
		(vista["mestre"] as Dictionary).erase("fogo")
		var m = (load(CENA_MESTRE) as PackedScene).instantiate()
		m.enviar_fn = func(_t, _c, _r): return ""
		m.pedir_vista_fn = func(): pass
		root.add_child(m)
		await _quadros(2)
		m._aviso_entendido()
		# primeiro a grelha (para saber as casas secas da margem), depois as figuras à volta do lago
		m._arena.aplicar_vista({"mapa": vista["mapa"], "mestre": {"figuras": []}, "figuras": []})
		await _quadros(2)
		var a = m._arena
		var livres: Array = []
		for raio in range(1, 8):
			for dy in range(-raio, raio + 1):
				for dx in range(-raio, raio + 1):
					if maxi(absi(dx), absi(dy)) != raio:
						continue
					var v := lago_casa + Vector2i(dx, dy)
					if v.x < 0 or v.y < 0 or v.x >= w or v.y >= h or livres.has(v):
						continue
					if not CampoDaMesa.casa_de_agua(a.mapa, a.origem, a.casa_m, v) and CampoDaMesa.recusa_do_pe(a.mapa, a.origem, a.casa_m, v) == "":
						livres.append(v)
		var k := 0
		var casas := {}
		for f in vista["mestre"]["figuras"]:
			if f.get("colocada") != true:
				continue
			var c: Vector2i
			if f.get("fichaId") == "heroina-teste":
				c = lago_casa
			else:
				c = livres[mini(k * 3, livres.size() - 1)]
				k += 1
			f["x"] = c.x
			f["y"] = c.y
			casas[str(f.get("id"))] = c
		for f in vista.get("figuras", []):
			if f is Dictionary and casas.has(str(f.get("id"))):
				f["x"] = casas[str(f.get("id"))].x
				f["y"] = casas[str(f.get("id"))].y
		m.aplicar_vista(vista)
		m._ao_redimensionar()
		# a aba Sala aberta: o selector da escala à vista
		for i in m._abas.get_tab_count():
			if m._abas.get_tab_title(i) == Textos.ABA_SALA:
				m._abas.current_tab = i
		a.camera.set_process(true)
		a.camera.definir_modo(CAMERA_PANORAMA)
		a.camera._saltar()
		await _quadros(30)
		var lago = a.mapa.get("lago")
		var r := {"vista": "mestre", "grelha": g, "casa_heroina": [lago_casa.x, lago_casa.y],
			"casa_de_agua": CampoDaMesa.casa_de_agua(a.mapa, a.origem, a.casa_m, lago_casa),
			"recusas": a.pes_recusados().size(), "figuras_de_pe": a.figuras_desenhadas(),
			"escala_rotulo": m._escala_rotulo.text, "escala_nova": m._escala_valor.text,
			"salpicos": lago.salpicos if lago != null else null}
		r["ecra"] = await _gravar("mestre_%s_1-ecra-mapa-todo.png" % g)
		print(JSON.stringify(r))
		_medidas.append(r)
		m.queue_free()
		await _quadros(3)


func _correr() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
		elif a.begins_with("--so="):
			_so = a.trim_prefix("--so=")
	if _saida == "":
		_saida = OS.get_user_data_dir().path_join("capturas-mapa")
	DirAccess.make_dir_recursive_absolute(_saida)
	root.size = Vector2i(1920, 1080)
	print("== capturas para ", _saida, " · render: ", RenderingServer.get_video_adapter_name(), " ==")
	if _so in ["", "jogadora"]:
		await _jogadora()
	if _so in ["", "mestre"]:
		await _mestre()
	var f := FileAccess.open(_saida.path_join("medicao%s.json" % ("" if _so == "" else "-" + _so)), FileAccess.WRITE)
	f.store_string(JSON.stringify({"ordem": "CAPTURAS-MAPA", "render": RenderingServer.get_video_adapter_name(),
		"medidas": _medidas, "falhas": _falhas}, "  ", false))
	f.close()
	print("foto_mapa_jogavel: %d medida(s), %d falha(s)" % [_medidas.size(), _falhas])
	quit(1 if _falhas > 0 else 0)
