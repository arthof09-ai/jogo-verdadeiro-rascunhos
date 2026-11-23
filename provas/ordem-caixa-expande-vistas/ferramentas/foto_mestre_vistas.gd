extends SceneTree
## Ordem CAIXA-EXPANDE-VISTAS (22/11/2026, F15 da sentença da CAIXA-EXPANDE), D4: o ecrã do Mestre com 12 e 16 figuras
## em ecrã baixo (844×390 e 780×360), com a vista expandida ABERTA pelo rato a sério, fotografado com render.
##
##   <godot.exe> --resolution 844x390 --path rascunhos/cliente -s <repo>/provas/ordem-caixa-expande-vistas/ferramentas/foto_mestre_vistas.gd \
##     -- --saida=<pasta> [--prefixo=<texto>]
##
## Corre COM render (nunca --headless). A vista é a da fixture do servidor (dados-exemplo/mesa-mestre.json, «mestre»)
## com criaturas de ensaio a mais até 12 e 16 figuras, em modo iniciativa — as mesmas de testes/medir_mestre.gd. Por
## ecrã e por número de figuras:
##   <p>mestre-aberta-N-figuras-WxH.png        a expandida aberta pelo rato, a lista no topo;
##   <p>mestre-fim-N-figuras-WxH.png           a mesma, com a lista levada ao fim pela roda do rato;
##   <p>mestre-rato-na-folha-N-figuras-WxH.png o rato passou para a folha, à altura da caixa (onde a expandida sem
##                                              tecto ia parar): a caixa volta à compacta e a folha recebe o clique.
## E <p>mestre-livre-aberta-16-figuras-1920x1080.png: na câmara livre, a expandida aberta não tapa o manípulo.
## Em todos os momentos escreve a MEDIDA (rectângulos em unidades do ecrã, linhas inteiras à vista) e confere o que a
## suite confere (a caixa dentro do tabuleiro e do ecrã; a folha recebe o rato e o clique; os controlos de andar
## livres). Não escreve nomes de figuras. Código de saída 0 se tudo confere e as capturas saem, 1 se não.

const CENA := "res://cenas/mestre/mestre.tscn"
const JANELAS := [Vector2i(844, 390), Vector2i(780, 360)]
const FIGURAS := [12, 16]

var _saida := ""
var _prefixo := ""
var _fx: Dictionary = {}
var _total := 0
var _falhas := 0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, texto: String) -> void:
	_total += 1
	print(("  ok    " if cond else "  FALHA ") + texto)
	if not cond:
		_falhas += 1


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _gravar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		_ok(false, nome + ": sem imagem (o render não correu)")
		return
	var erro := img.save_png(_saida.path_join(_prefixo + nome))
	_ok(erro == OK, "captura %s%s (%d×%d)" % [_prefixo, nome, img.get_width(), img.get_height()])


func _r(r: Rect2) -> String:
	return "(%.0f,%.0f %.0f×%.0f)" % [r.position.x, r.position.y, r.size.x, r.size.y]


func _rato(p: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = p
	ev.global_position = p
	root.push_input(ev, true)


func _botao(p: Vector2, indice: MouseButton, carregado: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = indice
	ev.pressed = carregado
	ev.factor = 1.0
	ev.position = p
	ev.global_position = p
	root.push_input(ev, true)


func _dentro_de(n: Node, pai: Node) -> bool:
	return n != null and (n == pai or pai.is_ancestor_of(n))


## A mesma vista de testes/medir_mestre.gd (_vista_cheia): a fixture e criaturas de ensaio até `total`, em iniciativa.
func _vista_cheia(total: int) -> Dictionary:
	var vista: Dictionary = _fx["mestre"]["vista"].duplicate(true)
	var figs: Array = vista["mestre"]["figuras"]
	var molde: Dictionary = figs[figs.size() - 1].duplicate(true)
	var i := 0
	while figs.size() < total:
		var f: Dictionary = molde.duplicate(true)
		f["id"] = "fensaio%02d" % i
		f["nome"] = "Vigia de ensaio %d" % (i + 1)
		f["nomePublico"] = "Sombra comprida de ensaio %d" % (i + 1)
		f["x"] = 4 + i % 4
		f["y"] = 5 + int(i / 4)
		figs.append(f)
		i += 1
	var ordem: Array = []
	for f in figs:
		ordem.append(f["id"])
	vista["iniciativa"] = ordem
	vista["vezId"] = ordem[0]
	vista["caixaMestre"] = {"ligada": true, "modo": "iniciativa"}
	return vista


## As linhas da lista inteiras dentro da vista dela, e a primeira cortada (índice e fracção à vista), agora.
func _linhas(cx) -> Dictionary:
	var rol: ScrollContainer = cx._rolagem
	var vr := rol.get_global_rect()
	var inteiras := 0
	var cortada := -1
	var fraccao := 0.0
	var k := 0
	for l in cx._lista.get_children():
		var lr := (l as Control).get_global_rect()
		if vr.grow(0.5).encloses(lr):
			inteiras += 1
		elif vr.intersects(lr) and cortada < 0:
			cortada = k
			fraccao = vr.intersection(lr).size.y / lr.size.y
		k += 1
	return {"inteiras": inteiras, "cortada": cortada, "fraccao": fraccao}


func _rodar_ate_parar(rol: ScrollContainer, para_baixo: bool) -> int:
	var p := rol.get_global_rect().get_center()
	var ultimo := -1
	var passos := 0
	var b := MOUSE_BUTTON_WHEEL_DOWN if para_baixo else MOUSE_BUTTON_WHEEL_UP
	while rol.scroll_vertical != ultimo and passos < 200:
		ultimo = rol.scroll_vertical
		_botao(p, b, true)
		_botao(p, b, false)
		passos += 1
		await _quadros(2)
	return passos


func _abrir_mestre(tam: Vector2i, total: int):
	root.size = tam
	await _quadros(6)
	var m = (load(CENA) as PackedScene).instantiate()
	m.enviar_fn = func(_t, _c, _r): return ""
	m.pedir_vista_fn = func(): pass
	root.add_child(m)
	await process_frame
	m._aviso_entendido()
	m.aplicar_vista(_vista_cheia(total))
	m.aplicar_cartao(_fx["mestre"]["cartoes"]["desgraca"])
	m._ao_redimensionar()
	await _quadros(30)  # os retratos desenham-se nos quadros seguintes
	m._ao_redimensionar()
	await _quadros(6)
	return m


func _momento(tam: Vector2i, total: int) -> void:
	var m = await _abrir_mestre(tam, total)
	var rot := "%dx%d %d figuras" % [tam.x, tam.y, total]
	if root.size != tam:
		_ok(false, "%s: a janela ficou %dx%d — sem medida" % [rot, root.size.x, root.size.y])
		m.queue_free()
		return
	var cx = m._caixa
	var visivel := root.get_visible_rect()
	var compacta: Rect2 = cx.get_global_rect()
	_rato(compacta.get_center())
	await _quadros(6)
	var r: Rect2 = cx.get_global_rect()
	var tab: Rect2 = m._tabuleiro.get_global_rect()
	var folha: Rect2 = m._folha.get_global_rect()
	var li := _linhas(cx)
	print("  MEDIDA %s: compacta %s · aberta %s · tabuleiro %s · folha %s · linhas inteiras à vista sem rolar %d de %d · cortada a meio: linha %d (%.0f por cento à vista) · nomes cortados com «…» %d" % [
		rot, _r(compacta), _r(r), _r(tab), _r(folha), li["inteiras"], cx._lista.get_child_count(), li["cortada"] + 1, li["fraccao"] * 100.0, cx.linhas_cortadas().size()])
	_ok(cx.expandida() and cx.ids_mostrados.size() == total, "%s: a expandida aberta pelo rato, com as %d figuras" % [rot, total])
	_ok(r.end.x <= tab.end.x + 0.5 and not r.intersects(folha), "%s: a caixa aberta não passa para a folha (direita %.0f, folha a partir de %.0f)" % [rot, r.end.x, folha.position.x])
	_ok(r.end.y <= visivel.end.y + 0.5, "%s: a caixa aberta não passa do fundo do ecrã (%.0f ≤ %.0f)" % [rot, r.end.y, visivel.end.y])
	await _gravar("mestre-aberta-%d-figuras-%dx%d.png" % [total, tam.x, tam.y])
	var passos := await _rodar_ate_parar(cx._rolagem, true)
	var ul := cx._lista.get_child(cx._lista.get_child_count() - 1) as Control
	print("  MEDIDA %s: a roda leva a lista ao fim em %d passos (%d u) · última linha inteira à vista %s" % [
		rot, passos, cx._rolagem.scroll_vertical, cx._rolagem.get_global_rect().grow(0.5).encloses(ul.get_global_rect())])
	await _gravar("mestre-fim-%d-figuras-%dx%d.png" % [total, tam.x, tam.y])
	await _rodar_ate_parar(cx._rolagem, false)
	# O rato passa para a folha, à altura da caixa (o ponto da suite).
	var px := folha.position.x + float(m._fonte) * 0.5
	if r.end.x > folha.position.x:
		px = (folha.position.x + r.end.x) * 0.5
	var p := Vector2(px, clampf(r.get_center().y, folha.position.y + 1.0, folha.end.y - 1.0))
	_rato(p)
	await _quadros(4)
	var por_cima: Control = root.gui_get_hovered_control()
	var cliques := [0]
	var contar := func(e: InputEvent):
		if e is InputEventMouseButton and (e as InputEventMouseButton).pressed:
			cliques[0] += 1
	if por_cima != null:
		por_cima.gui_input.connect(contar)
	m._em_voo["foto-d4"] = true  # o clique não dá ordem ao cartão (o «tocar» não age com comandos em voo)
	_botao(p, MOUSE_BUTTON_LEFT, true)
	_botao(p, MOUSE_BUTTON_LEFT, false)
	await _quadros(4)
	m._em_voo.erase("foto-d4")
	if por_cima != null:
		por_cima.gui_input.disconnect(contar)
	print("  MEDIDA %s: rato na folha em (%.0f,%.0f): controlo da folha por baixo %s · cliques recebidos %d · caixa aberta %s" % [
		rot, p.x, p.y, _dentro_de(por_cima, m._folha), cliques[0], cx.expandida()])
	_ok(_dentro_de(por_cima, m._folha) and cliques[0] == 1 and not cx.expandida(), "%s: o rato e o clique na folha vão à folha e a caixa volta à compacta" % rot)
	await _gravar("mestre-rato-na-folha-%d-figuras-%dx%d.png" % [total, tam.x, tam.y])
	m.queue_free()
	await _quadros(4)


## Câmara livre em 1920×1080 com 16 figuras: a expandida aberta não tapa o manípulo nem os outros controlos de andar.
func _livre() -> void:
	var tam := Vector2i(1920, 1080)
	var m = await _abrir_mestre(tam, 16)
	var ctl = m._livre
	ctl.entrar()
	m._ao_redimensionar()
	await _quadros(6)
	var cx = m._caixa
	_rato(cx.get_global_rect().get_center())
	await _quadros(6)
	var r: Rect2 = cx.get_global_rect()
	var tapa: Array = []
	for n in [ctl.sair_botao, ctl.dica, ctl.manipulo, ctl.sobe_botao, ctl.desce_botao, ctl.vel_caixa]:
		if cx.visible and r.intersects((n as Control).get_global_rect()):
			tapa.append(str((n as Node).name))
	var li := _linhas(cx)
	print("  MEDIDA câmara livre 1920x1080 16 figuras: aberta %s %s · manípulo %s · linhas inteiras à vista %d de 16 · tapa %s" % [
		cx.expandida(), _r(r), _r(ctl.manipulo.get_global_rect()), li["inteiras"], tapa])
	_ok(cx.visible and cx.expandida() and tapa.is_empty(), "câmara livre 1920x1080 16 figuras: a expandida aberta não tapa o «Voltar», a dica nem os controlos de andar %s" % [tapa])
	await _gravar("mestre-livre-aberta-16-figuras-1920x1080.png")
	m.queue_free()
	await _quadros(4)


func _correr() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
		elif a.begins_with("--prefixo="):
			_prefixo = a.trim_prefix("--prefixo=")
	if _saida == "":
		printerr("falta --saida=<pasta>")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_saida)
	print("== ORDEM-CAIXA-EXPANDE-VISTAS (D4): o ecrã do Mestre com a expandida aberta · render: %s ==" % RenderingServer.get_video_adapter_name())
	var caminho := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var d = JSON.parse_string(FileAccess.get_file_as_string(caminho))
	if not (d is Dictionary):
		printerr("sem a fixture do servidor")
		quit(2)
		return
	_fx = d
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede.papel = "mestre"
	for tam in JANELAS:
		for total in FIGURAS:
			await _momento(tam, total)
	await _livre()
	print("foto do Mestre (vistas): %d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 or _total == 0 else 0)
