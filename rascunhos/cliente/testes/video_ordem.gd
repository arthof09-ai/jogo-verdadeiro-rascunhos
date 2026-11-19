extends SceneTree
## Ordem HUD — o vídeo e as capturas da CAIXA DA ORDEM DE TURNOS (prova do construtor; a conferência é do
## coordenador). O ecrã do Mestre a sério (cenas/mestre/mestre.tscn) com a vista REAL da fixture do servidor
## (dados-exemplo/mesa-mestre.json, cenário «mestre»).
##
##   xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
##     --write-movie <pasta>/ordem-turnos.avi --path cliente -s res://testes/video_ordem.gd -- --saida=<pasta>
##
## Corre COM render, nunca com --headless. Não entra no CI. O guião é de DEMONSTRAÇÃO, posto por esta bancada: os
## eventos são os que o servidor emite (`ataque`, `movimento`, `cura`, com os campos do ROOM_EVENT), mas a sequência
## é escrita aqui; a «Jogadora 3» é uma cópia da Aliada da fixture (marcada «demo») para o exemplo do Mestre ter três
## jogadoras. O guião (exemplo do Mestre, 16/11): as jogadoras surpreendem o monstro — ataca a jogadora 1, depois a
## 2, depois a 3, depois o monstro; a ordem fica 1-2-3-monstro e REPETE-SE. Depois o Mestre carrega em «Modo
## iniciativa» e a caixa passa à ordem de iniciativa que o servidor dá. Por fim desliga a caixa (o ecrã volta ao de
## hoje) e volta a ligá-la.
## Deixa em <pasta>: caixa-dinamica.png, caixa-repete.png, caixa-iniciativa.png, caixa-desligada.png (o ecrã
## inteiro), retrato-<tipo>.png (o retrato de cada tipo de figura, ao lado da figura em cena: retrato-vs-cena-*.png),
## e guiao.json (os passos com os tempos, para a etiqueta do vídeo). Código de saída 0 se tudo sai.

const CENA := "res://cenas/mestre/mestre.tscn"
const PASSO_S := 1.6

var _saida := ""
var _falhas := 0
var _t0 := 0
var _guiao: Array = []
var _m = null
var _vista: Dictionary = {}
var _seq := 1000
var _etiqueta: Label


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _segundos(s: float) -> void:
	await _quadros(int(ceil(s * 30.0)))


func _gravar(nome: String, regiao := Rect2i()) -> Image:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		printerr("  FALHA ", nome, ": sem imagem (o render não correu)")
		_falhas += 1
		return null
	if regiao.size != Vector2i.ZERO:
		img = img.get_region(regiao)
	var erro := img.save_png(_saida.path_join(nome))
	if erro != OK:
		printerr("  FALHA ", nome, ": erro ", erro)
		_falhas += 1
		return null
	print("  ok    ", nome, " (", img.get_width(), "×", img.get_height(), ")")
	return img


func _marcar(texto: String) -> void:
	_etiqueta.text = texto
	_guiao.append({"t": (Time.get_ticks_msec() - _t0) / 1000.0, "passo": texto, "ordem": _m._caixa.ids_mostrados.duplicate(), "vez": _m._caixa.vez_mostrada})
	print("  · ", texto)


func _evento(tipo: String, dados: Dictionary, vez: String) -> void:
	_seq += 1
	_m._ao_evento({"seq": _seq, "tipo": tipo, "dados": dados})
	_vista["vezId"] = vez
	_m.aplicar_vista(_vista)


func _ataque(de: String, a: String) -> Dictionary:
	return {"atacanteId": de, "alvoId": a, "arma": "demo", "resultado": "acerto", "ataqueDeOportunidade": false}


func _correr() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
	if _saida == "":
		_saida = OS.get_user_data_dir().path_join("ordem")
	DirAccess.make_dir_recursive_absolute(_saida)
	print("== ordem de turnos para ", _saida, " · render: ", RenderingServer.get_video_adapter_name(), " ==")
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (d is Dictionary):
		printerr("sem a fixture do servidor")
		quit(1)
		return
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede.papel = "mestre"
	root.size = Vector2i(1280, 720)
	_vista = (d["mestre"]["vista"] as Dictionary).duplicate(true)
	# Ordem INICIATIVA NO SERVIDOR: a fixture traz a ordem dinâmica do servidor (vazia, antes de alguém agir). Este
	# guião não corre o servidor — os eventos são inventados aqui —, por isso a vista do guião vai sem ela.
	_vista.erase("ordemDinamica")
	var figs: Array = _vista["mestre"]["figuras"]
	var ids := {}
	for f in figs:
		ids[str(f["fichaId"])] = str(f["id"])
	var j1: String = ids["heroina-teste"]
	var j2: String = ids["aliada-teste"]
	var orc: String = ids["orc-teste"]
	# DEMONSTRAÇÃO: a terceira jogadora é uma cópia da Aliada, ao lado dela.
	var j3 := "jogadora3-demo"
	for f in figs:
		if str(f["id"]) == j2:
			var c: Dictionary = (f as Dictionary).duplicate(true)
			c["id"] = j3
			c["fichaId"] = "jogadora3-demo"
			c["nome"] = "Jogadora 3 (demo)"
			c["nomePublico"] = "Jogadora 3"
			c["x"] = 3
			c["y"] = 4
			figs.append(c)
			break
	(_vista["iniciativa"] as Array).insert(2, j3)

	_m = (load(CENA) as PackedScene).instantiate()
	_m.enviar_fn = func(_t, _c, _r): return ""
	_m.pedir_vista_fn = func(): pass
	root.add_child(_m)
	await _quadros(2)
	_m._aviso_entendido()
	_m.aplicar_vista(_vista)
	_m._ao_redimensionar()
	_etiqueta = Label.new()
	_etiqueta.add_theme_color_override("font_outline_color", Color.BLACK)
	_etiqueta.add_theme_constant_override("outline_size", 6)
	_etiqueta.position = Vector2(20, root.get_visible_rect().size.y - 110)
	_etiqueta.add_theme_font_size_override("font_size", 30)
	root.add_child(_etiqueta)
	var arena = _m._arena
	var centro := Vector3.ZERO
	for id in [j1, j2, j3, orc]:
		centro += arena._nos[id].position
	arena.camera.focar(centro / 4.0)
	arena.camera.definir_zoom(3.0)
	arena.camera._saltar()
	_t0 = Time.get_ticks_msec()
	await _quadros(20)

	_marcar("DEMONSTRAÇÃO · modo dinâmico (sem iniciativa): a ordem ainda não existe")
	await _segundos(PASSO_S)
	_evento("ataque", _ataque(j1, orc), j1)
	_marcar("A jogadora 1 (Heroína) surpreende o Orc")
	await _segundos(PASSO_S)
	_evento("movimento", {"figuraId": j2, "de": {"x": 2, "y": 4}, "para": {"x": 2, "y": 4}, "caminho": []}, j2)
	_evento("ataque", _ataque(j2, orc), j2)
	_marcar("Depois a jogadora 2 (Aliada)")
	await _segundos(PASSO_S)
	_evento("ataque", _ataque(j3, orc), j3)
	_marcar("Depois a jogadora 3")
	await _segundos(PASSO_S)
	_evento("ataque", _ataque(orc, j2), orc)
	_marcar("Depois o monstro: a ordem ficou 1-2-3-monstro")
	await _segundos(PASSO_S * 0.6)
	await _gravar("caixa-dinamica.png")
	await _segundos(PASSO_S * 0.4)
	var nome_curto := {j1: "jogadora 1 (Heroína)", j2: "jogadora 2 (Aliada)", j3: "jogadora 3", orc: "o monstro (Orc)"}
	for par in [[j1, orc], [j2, orc], [j3, orc], [orc, j1]]:
		_evento("ataque", _ataque(par[0], par[1]), par[0])
		_marcar("Segunda volta: repete-se — na vez: %s" % nome_curto.get(_m._caixa.vez_mostrada, _m._caixa.vez_mostrada))
		await _segundos(PASSO_S * 0.8)
	await _gravar("caixa-repete.png")
	_m._caixa._botao.button_pressed = true  # o Mestre carrega em «Modo iniciativa»
	_marcar("O Mestre liga o «Modo iniciativa»: a caixa passa à ordem de iniciativa do servidor")
	await _segundos(PASSO_S * 0.6)
	await _gravar("caixa-iniciativa.png")
	await _segundos(PASSO_S * 1.4)
	_m._caixa._botao.button_pressed = false
	_marcar("Desliga a iniciativa: volta a ordem formada pelas acções")
	await _segundos(PASSO_S)
	_m.ligar_caixa(false)
	_marcar("Caixa desligada (aba Sala): o ecrã é o de hoje")
	await _segundos(PASSO_S * 0.6)
	await _gravar("caixa-desligada.png")
	await _segundos(PASSO_S * 0.4)
	_m.ligar_caixa(true)
	_marcar("Caixa ligada outra vez")
	await _segundos(PASSO_S)

	# Os retratos: um de cada tipo de figura presente na arena, ao lado da figura em cena.
	for par in [["humanoide", j1], ["orc", orc], ["lobo", ids["lobo-teste"]]]:
		var tex: Texture2D = _m._retratos.textura(par[1])
		if tex == null:
			_m._retratos.pedir(par[1], "prova", arena.modelo_da_figura(par[1]))
			await _quadros(3)
			tex = _m._retratos.textura(par[1])
		var img := tex.get_image() if tex != null else null
		if img == null or img.is_empty():
			printerr("  FALHA retrato-", par[0], ": sem imagem")
			_falhas += 1
			continue
		img.save_png(_saida.path_join("retrato-%s.png" % par[0]))
		print("  ok    retrato-", par[0], ".png")
		arena.camera.focar(arena._nos[par[1]].position)
		arena.camera.definir_zoom(5.0)
		arena.camera._saltar()
		_marcar("Retrato (%s) e a figura em cena" % par[0])
		await _quadros(15)
		var ecra := await _gravar("_cena-%s.png" % par[0])
		if ecra != null:
			var lado := ecra.get_height()
			var lado_a_lado := Image.create(lado * 2, lado, false, Image.FORMAT_RGBA8)
			var r := img.duplicate() as Image
			r.convert(Image.FORMAT_RGBA8)
			r.resize(lado, lado)
			lado_a_lado.blit_rect(r, Rect2i(0, 0, lado, lado), Vector2i.ZERO)
			var meio := ecra.get_region(Rect2i((ecra.get_width() - lado) / 2 - int(ecra.get_width() * 0.12), 0, lado, lado))
			meio.convert(Image.FORMAT_RGBA8)
			lado_a_lado.blit_rect(meio, Rect2i(0, 0, lado, lado), Vector2i(lado, 0))
			lado_a_lado.save_png(_saida.path_join("retrato-vs-cena-%s.png" % par[0]))
			DirAccess.remove_absolute(_saida.path_join("_cena-%s.png" % par[0]))
		await _segundos(1.0)

	var f := FileAccess.open(_saida.path_join("guiao.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(_guiao, "  "))
	f.close()
	print("ordem: %d falha(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)
