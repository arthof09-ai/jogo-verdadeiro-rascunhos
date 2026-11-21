extends SceneTree
## foto_lago_maior.gd — ORDEM LAGO-MAIOR (20/11/2026). As capturas para o olho do Mestre, COM render (GPU, janela),
## nunca --headless. A figura das capturas é o MANEQUIM DE REFERÊNCIA DA CASA (regra do Mestre, 18:56): o
## Mannequin_F do UAL2 com o ANDAR v3 (testes/manequim/andar-v3.glb, SHA-256 conferido) — nada de cápsulas nem de
## bichos de enchimento: a arena abre SEM figuras do jogo (o snapshot não traz nenhuma) e o manequim é posto à mão.
## Não é código do jogo: vive em provas/ e corre por uma cópia temporária dentro de cliente/ (res://).
##
##   copiar para cliente/_foto_lago_maior.gd e:
##   godot --path cliente --resolution 1920x1080 -s res://_foto_lago_maior.gd -- --saida=<pasta> [--prefixo=antes_]
##
## As fotos (grelha-mapa 50 × 50 de 1,5 m, a do jogo por omissão):
##   1-mapa-inteiro.png        a arena da jogadora em Panorama: a grelha sobre o mapa todo, o lago e a floresta de
##                             dentro do campo; o manequim na parte funda (pequeno, à escala do mapa);
##   2-funda-pescoco.png       de perto, da margem: o manequim de pé no leito onde a água lhe chega ao pescoço;
##   3-funda-meio.png          de perto: o manequim no meio do lago (2,45 m de água): fica coberto;
##   4-margem-rasa.png         de perto: o manequim na faixa de andar, a água pelo joelho;
##   5-floresta-ne.png         o canto NE do mapa visto de dentro do campo: o lago e as árvores/rochas devolvidas.
## O pé do manequim é o LEITO (Relevo.altura), como o jogo põe hoje uma figura numa casa funda (o pé do servidor);
## não se inventa natação (frente NADO). medicao.json: o sítio, a fundura, a água acima do pé e a altura do manequim.

const CENA := "res://cenas/arena/arena.tscn"
const GLB := "res://testes/manequim/andar-v3.glb"
const GLB_SHA256 := "8413b0395d6b9f161aefe05004999ee5f605d4eb68e81a4767a81f9b56ea3491"
const ANIM := "andar_v3"
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const CAMERA_PANORAMA := 2

var _saida := ""
var _prefixo := ""
var _arena: Node3D
var _lago: Node3D
var _manequim: Node3D
var _altura_manequim := 0.0
var _camara: Camera3D
var _falhas := 0
var _medidas: Array = []


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _gravar(nome: String) -> Dictionary:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		printerr("  FALHA ", nome, ": sem imagem")
		_falhas += 1
		return {"foto": nome, "ok": false}
	var cores := {}
	for j in 36:
		for i in 64:
			cores[img.get_pixel(int((i + 0.5) * img.get_width() / 64.0), int((j + 0.5) * img.get_height() / 36.0)).to_html(false)] = true
	var nome_f := _prefixo + nome
	var erro := img.save_png(_saida.path_join(nome_f))
	if erro != OK or cores.size() < 8:
		printerr("  FALHA ", nome_f, ": erro ", erro, ", ", cores.size(), " cores")
		_falhas += 1
		return {"foto": nome_f, "ok": false}
	print("  ok    ", nome_f, " (", img.get_width(), "×", img.get_height(), ")")
	return {"foto": nome_f, "ok": true, "cores_amostra": cores.size()}


func _por_manequim() -> bool:
	if FileAccess.get_sha256(GLB) != GLB_SHA256:
		printerr("o manequim não é o ANDAR v3 aprovado")
		return false
	var doc := GLTFDocument.new()
	var estado := GLTFState.new()
	if doc.append_from_file(GLB, estado) != OK:
		printerr("o manequim não abriu")
		return false
	_manequim = doc.generate_scene(estado)
	_manequim.name = "ManequimDeReferencia"
	_arena.add_child(_manequim)
	var anim: AnimationPlayer = _manequim.find_child("AnimationPlayer", true, false)
	if anim != null and anim.has_animation(ANIM):
		anim.play(ANIM)
		anim.seek(0.0, true)
		anim.speed_scale = 0.0
	return true


## A altura do manequim (m): a caixa das malhas, depois de posto (pose do quadro 0 do ANDAR v3).
func _medir_altura() -> float:
	var lo := INF
	var hi := -INF
	for mi in _manequim.find_children("*", "MeshInstance3D", true, false):
		var caixa: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		lo = minf(lo, caixa.position.y)
		hi = maxf(hi, caixa.end.y)
	return hi - lo


## Põe o manequim de pé no LEITO em (x, z), virado para `para` (x, z). O lago larga-o antes e volta a segui-lo
## depois (a esteira da ÁGUA-REAÇÃO não liga duas poses: o manequim não andou de uma para a outra).
func _por_em(p: Vector2, para: Vector2) -> Dictionary:
	if _lago != null and _lago.segue(_manequim):
		_lago.deixar(_manequim)
	var y := Relevo.altura(p.x, p.y)
	_manequim.position = Vector3(p.x, y, p.y)
	if _lago != null:
		_lago.seguir(_manequim, 0.21)
	var d := para - p
	_manequim.rotation = Vector3(0.0, atan2(d.x, d.y), 0.0)
	var f := Relevo.lago_fundura(p.x, p.y)
	return {"x": snappedf(p.x, 0.01), "z": snappedf(p.y, 0.01), "fundura_m": snappedf(f, 0.01),
		"agua_acima_do_pe_m": snappedf(maxf(Relevo.nivel_lago() - y, 0.0), 0.01),
		"agua_em_fraccao_da_altura": snappedf(maxf(Relevo.nivel_lago() - y, 0.0) / _altura_manequim, 0.01) if _altura_manequim > 0.0 else null}


## O ponto do raio margem → centro (rumo `graus`, a partir de LAGO_CENTRO) onde a fundura chega a `alvo` m.
func _ponto_com_fundura(graus: float, alvo: float) -> Vector2:
	var a := deg_to_rad(graus)
	var u := Vector2(sin(a), -cos(a))
	var r := Relevo.margem_raio(a) - 0.05
	while r > 0.0:
		var p := Relevo.LAGO_CENTRO + u * r
		if Relevo.lago_fundura(p.x, p.y) >= alvo:
			return p
		r -= 0.05
	return Relevo.LAGO_CENTRO


## Espera a água acalmar à volta do manequim acabado de pôr (o salpico de entrar morre; fica a linha de água).
func _acalmar() -> void:
	await create_timer(4.0).timeout
	await _quadros(5)


func _olhar(de: Vector3, para: Vector3, fov: float) -> void:
	_camara.make_current()
	_camara.fov = fov
	_camara.look_at_from_position(de, para, Vector3.UP)


func _correr() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
		elif a.begins_with("--prefixo="):
			_prefixo = a.trim_prefix("--prefixo=")
	if DisplayServer.get_name() == "headless":
		printerr("as capturas precisam de janela (GPU): não correm com --headless")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(_saida)
	root.size = Vector2i(1920, 1080)
	print("== capturas LAGO-MAIOR para ", _saida, " · render: ", RenderingServer.get_video_adapter_name(), " ==")
	var rede = root.get_node("/root/Rede")
	rede.persistir = false
	rede._ativo = true   # sem servidor: a arena não vai ao lobby
	# a grelha-mapa (o jogo por omissão: o mapa inteiro, 50 × 50 de 1,5 m) e NENHUMA figura do jogo
	root.get_node("/root/Estado").aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "lago-maior", "seq": 1,
		"revision": 1, "fase": "combate", "mapa": {"largura": 50, "altura": 50, "casaM": 1.5}, "figuras": [],
		"vezId": null, "ambiente": {}})
	_arena = (load(CENA) as PackedScene).instantiate()
	root.add_child(_arena)
	await _quadros(4)
	_arena._perfis.aplicar("alto")
	_lago = _arena.mapa.get("lago")
	if not _por_manequim():
		quit(1)
		return
	await _quadros(2)
	_altura_manequim = _medir_altura()
	_camara = Camera3D.new()
	_camara.near = _arena.camera.near
	_camara.far = _arena.camera.far
	root.add_child(_camara)
	var c := Relevo.LAGO_CENTRO
	var nivel := Relevo.nivel_lago()
	var cab := {"ordem": "LAGO-MAIOR", "render": RenderingServer.get_video_adapter_name(), "prefixo": _prefixo,
		"manequim": "Mannequin_F (UAL2) · ANDAR v3 · " + GLB, "manequim_altura_m": snappedf(_altura_manequim, 0.01),
		"nivel_lago_m": snappedf(nivel, 0.001), "lago_centro": [c.x, c.y]}
	print(JSON.stringify(cab))
	# 1. o mapa inteiro, a vista da jogadora (Panorama); o manequim no meio da parte funda
	var r := {"foto": "1-mapa-inteiro", "manequim": _por_em(_ponto_com_fundura(250.0, 1.45), c)}
	_arena.camera.set_process(true)
	_arena.camera.definir_modo(CAMERA_PANORAMA)
	_arena.camera._saltar()
	await _quadros(30)
	r["png"] = await _gravar("1-mapa-inteiro.png")
	_medidas.append(r)
	# daqui em diante a câmara é da bancada (como a do vídeo do lago): o HUD fica fora do quadro
	var hud = _arena.get_node_or_null("HUD")
	if hud != null:
		hud.visible = false
	# 2. a parte funda, a água pelo pescoço: no raio de oeste-sudoeste (a margem de onde se entra)
	var p2 := _ponto_com_fundura(250.0, 1.45)
	r = {"foto": "2-funda-pescoco", "manequim": _por_em(p2, c)}
	var u2 := (p2 - c).normalized()
	_olhar(Vector3(p2.x + u2.x * 4.2, nivel + 1.9, p2.y + u2.y * 4.2) + Vector3(-u2.y, 0, u2.x) * 1.4,
		Vector3(p2.x, nivel + 0.1, p2.y), 50.0)
	await _acalmar()
	r["png"] = await _gravar("2-funda-pescoco.png")
	_medidas.append(r)
	# 3. o meio do lago (2,45 m): o manequim fica coberto — a câmara um pouco mais alta, a ver para dentro de água
	var p3 := c
	r = {"foto": "3-funda-meio", "manequim": _por_em(p3, p3 + Vector2(-1, 1))}
	_olhar(Vector3(p3.x - 4.0, nivel + 3.4, p3.y + 4.0), Vector3(p3.x, nivel - 0.8, p3.y), 50.0)
	await _acalmar()
	r["png"] = await _gravar("3-funda-meio.png")
	_medidas.append(r)
	# 4. a margem rasa: o manequim na faixa de andar, a água pelo joelho (no mesmo raio de oeste-sudoeste)
	var p4 := _ponto_com_fundura(250.0, 0.42)
	r = {"foto": "4-margem-rasa", "manequim": _por_em(p4, c)}
	var u4 := (p4 - c).normalized()
	_olhar(Vector3(p4.x + u4.x * 3.6, nivel + 1.6, p4.y + u4.y * 3.6) + Vector3(-u4.y, 0, u4.x) * 1.6,
		Vector3(p4.x, nivel + 0.5, p4.y), 50.0)
	await _acalmar()
	r["png"] = await _gravar("4-margem-rasa.png")
	_medidas.append(r)
	# 5. o canto NE visto de dentro do campo: o lago inteiro e a floresta devolvida à volta dele (manequim na margem)
	var p5 := _ponto_com_fundura(230.0, 0.30)
	r = {"foto": "5-floresta-ne", "manequim": _por_em(p5, c)}
	_olhar(Vector3(-2.0, Relevo.altura(-2.0, 4.0) + 9.0, 4.0), Vector3(c.x, nivel, c.y), 55.0)
	await _acalmar()
	r["png"] = await _gravar("5-floresta-ne.png")
	_medidas.append(r)
	var f := FileAccess.open(_saida.path_join(_prefixo + "medicao.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"cabecalho": cab, "medidas": _medidas, "falhas": _falhas}, "  ", false))
	f.close()
	print("foto_lago_maior: %d foto(s), %d falha(s)" % [_medidas.size(), _falhas])
	quit(1 if _falhas > 0 else 0)
