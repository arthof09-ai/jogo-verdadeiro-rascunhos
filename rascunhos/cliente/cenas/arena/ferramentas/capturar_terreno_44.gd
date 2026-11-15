extends SceneTree
## capturar_terreno_44.gd — Ordem 44. As CAPTURAS ETIQUETADAS para o veredicto do Mestre, na arena DO JOGO:
##
##   PARTE B — o pé das figuras nas 6 casas da encosta do outeiro (canto NO da grelha 20 × 20 de 1,5 m), ANTES
##     (a regra da Ordem 42: base horizontal à altura mais baixa da pegada, sem mancha de base) e DEPOIS (a base
##     inclinada com a encosta, assentamento.gd): um grande plano de cada casa, de lado (ao longo da curva de
##     nível, onde o enterramento se vê), e duas vistas do grupo.
##   PARTE A — a grelha MAIOR (30 × 30 de 1,5 m) coerente com o servidor: o servidor de verdade
##     (servidor/ferramentas/juizo-terreno.mjs) põe as figuras e diz que casas a heroína pode pisar; o cliente
##     desenha-as. Os postes vermelhos marcam as casas que o SERVIDOR julga bloqueadas, com a base à altura que o
##     servidor dá (alturaM): se o servidor e o cliente estiverem de acordo, o poste nasce do chão desenhado e fica
##     em cima do marco do mapa; os destaques do mover (as casas que o servidor oferece) contornam os marcos.
##
## Cada imagem leva a etiqueta (casa, regra, encosta, enterra/flutua medidos) no canto e no nome do ficheiro.
##   godot --path cliente --resolution 1920x1080 -s res://cenas/arena/ferramentas/capturar_terreno_44.gd [-- --pasta=...]
## Precisa de janela (GPU) e do Node (o servidor). Escreve em provas/ordem-44-terreno/ (raiz do repositório).

const CENA := "res://cenas/arena/arena.tscn"
const Assentamento := preload("res://cenas/arena/assentamento.gd")
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const ProvaTerreno := preload("res://cenas/arena/ferramentas/provar_terreno_servidor.gd")
const ProvaPe := preload("res://cenas/arena/ferramentas/provar_assentamento.gd")
const LARGURA := 1920
const ALTURA := 1080
const MOVER := 1
const SEIS := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)]

var _pasta := ""
var _vp: SubViewport
var _arena: Node3D
var _etiqueta: Label
var _postes: Node3D
var _feitas: Array = []
var _seq := 0


func _init() -> void:
	_pasta = ProjectSettings.globalize_path("res://").path_join("../../provas/ordem-44-terreno").simplify_path()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pasta="):
			_pasta = a.trim_prefix("--pasta=")
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _s(v: float, casas: int = 1) -> String:
	var t := ("%." + str(casas) + "f") % absf(v)
	return ("+" if v >= 0.0 else "-") + t.replace(".", ",")


func _snapshot(lw: int, lh: int, figuras: Array, propria: String) -> void:
	var est = root.get_node("/root/Estado")
	_seq += 1
	var s := {"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "capturas-44", "seq": _seq, "revision": _seq,
		"fase": "combate", "mapa": {"largura": lw, "altura": lh, "casaM": 1.5}, "figuras": figuras,
		"vezId": propria if propria != "" else null, "ambiente": {}}
	if propria != "":
		s["propria"] = {"figuraId": propria}
	est.aplicar_snapshot(s)


func _mesa(modo: int, foco: Vector3, rumo: float, incl: float, zoom: float) -> void:
	var cam = _arena.camera
	cam.set_process(true)
	cam.definir_modo(modo)
	if modo == 1:
		cam.rumo = rumo
		cam.inclinacao = incl
	cam.foco = foco
	cam._limitar()
	cam.definir_zoom(zoom)
	cam._saltar()


func _gravar(nome: String, texto: String) -> void:
	_etiqueta.text = texto
	await _quadros(6)
	var img := _vp.get_texture().get_image()
	var caminho := _pasta.path_join(nome + ".jpg")
	img.save_jpg(caminho, 0.93)
	_feitas.append({"ficheiro": nome + ".jpg", "etiqueta": texto})
	print("[captura44] %s" % nome)


## A regra da Ordem 42 nas figuras já desenhadas (só para a imagem do ANTES): base horizontal à altura mais baixa
## do centro e de 8 pontos no raio, corpo direito a 0,85 m, sem a mancha da base (a Ordem 42 não a tinha).
func _aplicar_antes() -> void:
	var r := Assentamento.raio_pegada(_arena.casa_m)
	var est = root.get_node("/root/Estado")
	for id in _arena._nos:
		var no: Node3D = _arena._nos[id]
		var c := Vector2i(int(est.figuras[id]["x"]), int(est.figuras[id]["y"]))
		var p: Vector3 = _arena.centro_casa(c)
		no.position = Vector3(p.x, ProvaPe._pe_ordem42(p.x, p.z, p.y, r), p.z)
		(no.get_node("Base") as Node3D).visible = false
		(no.get_node("Corpo") as Node3D).transform = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.85, 0.0))


## Câmara posta à mão (sem a câmara da mesa): no ponto `de`, a olhar para `alvo`.
func _olhar(de: Vector3, alvo: Vector3) -> void:
	var cam: Camera3D = _arena.camera
	cam.set_process(false)
	cam.global_position = de
	cam.look_at(alvo, Vector3.UP)


## A direcção horizontal ao longo da curva de nível na casa `c` (perpendicular ao gradiente), normalizada.
func _ao_longo(c: Vector2i) -> Vector3:
	var g: Vector2 = _arena.pegada_figura(c)["gradiente"]
	var d := Vector3(g.y, 0.0, -g.x)
	return d.normalized() if d.length() > 1e-6 else Vector3.RIGHT


## Só a figura da casa `c` à vista (ou todas, com `c` = (-1, -1)).
func _so_figura(c: Vector2i) -> void:
	var est = root.get_node("/root/Estado")
	for id in _arena._nos:
		var f: Dictionary = est.figuras[id]
		(_arena._nos[id] as Node3D).visible = c == Vector2i(-1, -1) or (int(f["x"]) == c.x and int(f["y"]) == c.y)


## O rumo da câmara (o lado de onde ela olha, como em capturar_arena.gd: −135 = do NO) para ver a casa `c` de lado,
## ao longo da curva de nível; `sinal` escolhe o lado.
func _rumo_de_lado(c: Vector2i, sinal: float) -> float:
	var g: Vector2 = _arena.pegada_figura(c)["gradiente"]
	var perp := Vector2(g.y, -g.x) * sinal
	return rad_to_deg(atan2(perp.x, perp.y))


func _correr() -> void:
	DirAccess.make_dir_recursive_absolute(_pasta)
	root.get_node("/root/Rede")._ativo = true
	_vp = SubViewport.new()
	_vp.size = Vector2i(LARGURA, ALTURA)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	var mostra := TextureRect.new()
	mostra.texture = _vp.get_texture()
	mostra.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mostra.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(mostra)
	var camada := CanvasLayer.new()
	_vp.add_child(camada)
	_etiqueta = Label.new()
	_etiqueta.position = Vector2(28, 84)
	_etiqueta.add_theme_font_size_override("font_size", 30)
	_etiqueta.add_theme_color_override("font_color", Color(1, 1, 1))
	_etiqueta.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_etiqueta.add_theme_constant_override("outline_size", 9)
	camada.add_child(_etiqueta)

	# ---------------------------------------------------------------- PARTE B: as 6 casas da encosta
	var figs: Array = []
	var k := 0
	for c in SEIS + [Vector2i(5, 3), Vector2i(4, 1)]:
		figs.append({"id": "e%d" % k, "nomePublico": "(%d,%d)" % [c.x, c.y], "x": c.x, "y": c.y, "lado": "criatura" if k % 2 else "jogadora",
			"orientacao": "S", "visivel": "de_pe"})
		k += 1
	_snapshot(20, 20, figs, "")
	_arena = (load(CENA) as PackedScene).instantiate()
	_vp.add_child(_arena)
	await _quadros(4)
	_arena._perfis.aplicar("alto")
	await _quadros(30)  # os tweens das figuras (0,25 s) acabam
	var r := Assentamento.raio_pegada(_arena.casa_m)
	var n := 1
	for fase in ["DEPOIS", "ANTES"]:
		if fase == "ANTES":
			_aplicar_antes()
		var nn := n
		for c: Vector2i in SEIS:
			var p: Vector3 = _arena.centro_casa(c)
			var pg: Dictionary = _arena.pegada_figura(c)
			var enc := rad_to_deg(atan((pg["gradiente"] as Vector2).length()))
			var m: Array
			if fase == "ANTES":
				m = ProvaPe._medir_base(p.x, p.z, ProvaPe._pe_ordem42(p.x, p.z, p.y, r), Vector2.ZERO, r)
			else:
				m = ProvaPe._medir_base(p.x, p.z, float(pg["y"]), pg["gradiente"], r)
			# de lado, a 2,8 m e 1,3 m acima do pé, um pouco de cima (a relva alta da encosta tapa o rasante): o lado de cima da base fica à esquerda ou à direita, o chão de perfil
			_so_figura(c)
			var pe: Vector3 = _arena._nos.values().filter(func(no): return no.visible)[0].position
			_olhar(pe + _ao_longo(c) * 2.8 + Vector3(0, 1.3, 0), pe + Vector3(0, 0.3, 0))
			var nome := "B%02d_casa-%d-%d_%s_encosta%s_enterra%sm_flutua%sm" % [nn, c.x, c.y, fase, _s(enc, 0), _s(m[0], 2), _s(m[1], 2)]
			var regra := "base horizontal ao ponto mais baixo (Ordem 42)" if fase == "ANTES" else "base inclinada com a encosta (Ordem 44)"
			await _gravar(nome, "PARTE B · %s · casa (%d, %d) · encosta %.0f°\n%s\nenterra %.2f m · flutua %.2f m (régua de 129 pontos)" % [fase, c.x, c.y, enc, regra, m[0], m[1]])
			nn += 1
		# o grupo: de lado e de baixo para cima
		_so_figura(Vector2i(-1, -1))
		var foco: Vector3 = _arena.centro_casa(Vector2i(1, 1))
		_olhar(foco + _ao_longo(Vector2i(1, 1)) * 6.0 + Vector3(0, 1.2, 0), foco + Vector3(0, 0.3, 0))
		await _gravar("B%02d_grupo-encosta-NO_de-lado_%s" % [nn, fase], "PARTE B · %s · as 6 casas da encosta do outeiro, de lado" % fase)
		nn += 1
		var g: Vector2 = _arena.pegada_figura(Vector2i(1, 1))["gradiente"]
		var desce := Vector3(-g.x, 0.0, -g.y).normalized()
		var de := foco + desce * 6.5
		_olhar(Vector3(de.x, _arena.altura_chao(de.x, de.z) + 1.4, de.z), foco + Vector3(0, 0.3, 0))
		await _gravar("B%02d_grupo-encosta-NO_de-baixo_%s" % [nn, fase], "PARTE B · %s · as 6 casas da encosta do outeiro, de baixo" % fase)
		n = nn + 1

	# ---------------------------------------------------------------- PARTE A: a grelha maior, coerente com o servidor
	var pedidas := "5,5;6,5;7,5;5,6;6,6;5,7;15,15;10,20;24,24;0,10;12,28;28,12;0,29;1,0;3,2;28,28;29,0"
	var sv := ProvaTerreno.juizo_do_servidor(30, 30, 1.5, pedidas)
	if sv.is_empty():
		push_error("o servidor não respondeu")
		quit(1)
		return
	var figs30: Array = []
	var heroina := ""
	for f in sv["figuras"]:
		figs30.append({"id": f["id"], "nomePublico": "S(%d,%d)" % [int(f["x"]), int(f["y"])], "x": int(f["x"]), "y": int(f["y"]),
			"lado": f["lado"], "orientacao": "S", "visivel": "de_pe"})
		if f["lado"] == "jogadora":
			heroina = String(f["id"])
	_snapshot(30, 30, figs30, heroina)
	root.get_node("/root/Estado").receber_opcoes({"v": 2, "type": "ROOM_OPTIONS", "revision": _seq, "vezId": heroina,
		"mover": sv["mover"], "ataques": [], "consumiveis": [], "acoes": [], "reacoes": []})
	await _quadros(30)
	_arena.definir_modo(MOVER)
	# os postes do que o SERVIDOR julga bloqueado, com a base na altura que o servidor dá
	_postes = Node3D.new()
	_arena.add_child(_postes)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.12, 0.10)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.05, 0.03)
	var poste := CylinderMesh.new()
	poste.top_radius = 0.06
	poste.bottom_radius = 0.06
	poste.height = 2.4
	poste.material = mat
	var bloq := 0
	for c in sv["juizo"]["casas"]:
		if bool(c["passavel"]):
			continue
		bloq += 1
		var mi := MeshInstance3D.new()
		mi.mesh = poste
		var p: Vector3 = _arena.centro_casa(Vector2i(int(c["x"]), int(c["y"])))
		mi.position = Vector3(p.x, float(c["alturaM"]) + 1.2, p.z)
		_postes.add_child(mi)
	var j: Dictionary = sv["juizo"]
	var leg := "postes vermelhos: as %d casas que o SERVIDOR julga bloqueadas, de pé na altura que ele dá\ndestaques azuis: as %d casas que o servidor oferece à heroína (azul) para mover" % [bloq, (sv["mover"] as Array).size()]
	var cNO: Vector3 = _arena.centro_casa(Vector2i(3, 2))
	_mesa(2, _arena.centro_casa(Vector2i(15, 15)), 0.0, 78.0, 1.0)
	await _gravar("A%02d_grelha-30x30_panorama_PANORAMA" % n, "PARTE A · grelha 30 × 30 de 1,5 m (maior que a zona livre 20 × 20)\n" + leg)
	n += 1
	_mesa(1, cNO, -150.0, 38.0, 1.8)
	await _gravar("A%02d_grelha-30x30_menires-NO_mover-contorna_360" % n, "PARTE A · 30 × 30 · a roda dos menires (fora da zona livre)\nheroína em (2, 2): o mover do servidor contorna os menires\n" + leg)
	n += 1
	_mesa(1, cNO, 60.0, 16.0, 2.6)
	await _gravar("A%02d_grelha-30x30_menires-NO_rasante_360" % n, "PARTE A · 30 × 30 · rasante aos menires\ncada poste nasce do chão desenhado (desvio cliente−servidor 0 m)")
	n += 1
	var cSE: Vector3 = _arena.centro_casa(Vector2i(27, 27))
	_mesa(1, cSE, 135.0, 30.0, 1.6)
	await _gravar("A%02d_grelha-30x30_santuario-SE_360" % n, "PARTE A · 30 × 30 · o santuário (canto SE, fora da zona livre)\nbloqueado no servidor; colocar em (28, 28) é recusado: «santuário»")
	n += 1
	var cE: Vector3 = _arena.centro_casa(Vector2i(6, 6))
	_mesa(1, cE, -135.0, 14.0, 2.4)
	await _gravar("A%02d_grelha-30x30_encosta-dentro-da-zona_360" % n, "PARTE A · 30 × 30 · as figuras que o servidor pôs na encosta (casas 5–7 = as 6 casas da Parte B)\npé desenhado = peM do servidor (0 m)")
	n += 1
	var f := FileAccess.open(_pasta.path_join("capturas.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"ordem": 44, "ferramenta": "cliente/cenas/arena/ferramentas/capturar_terreno_44.gd",
		"gpu": RenderingServer.get_video_adapter_name(), "resolucao": [LARGURA, ALTURA], "capturas": _feitas,
		"servidor": {"figuras": sv["figuras"], "recusas": sv["recusas"], "moverOferecidas": (sv["mover"] as Array).size(), "bloqueadas": bloq}}, " ", false))
	f.close()
	print("[captura44] fim: %d capturas em %s" % [_feitas.size(), _pasta])
	quit(0)
