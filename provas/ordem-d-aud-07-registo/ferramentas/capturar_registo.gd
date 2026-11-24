extends SceneTree
## ORDEM-D-AUD-07-REGISTO: fotografa a aba Registo do ecrã do Mestre com a vista REAL do servidor
## (gerar-vista-registo.mjs) e confere o texto das linhas.
##
##   godot --path rascunhos/cliente --resolution 1600x900 -s <esta>.gd -- --vista=<vista.json> --saida=<pasta>
##
## Corre COM render (não --headless). Tira duas fotos da mesma vista:
##   registo-depois.png  a vista tal como o servidor a manda hoje (com autorId/rodadaAutor): o rótulo diz quem jogou;
##   registo-antes.png   a mesma vista SEM os dois campos novos: é o rótulo de antes desta ordem (rodada/vez DEPOIS).
## Código de saída 0 se as verificações passam e as duas fotos saem.

const CENA := "res://cenas/mestre/mestre.tscn"
const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")

var _falhas := 0
var _total := 0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		printerr("  FALHA ", nome)


func _arg(nome: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--%s=" % nome):
			return a.substr(nome.length() + 3)
	return ""


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _foto(c, vista: Dictionary, caminho: String) -> Array:
	c.aplicar_vista(vista)
	c.mostrar_aba(c._aba_registo)
	await _quadros(8)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var erro := img.save_png(caminho)
	_ok(erro == OK and img.get_width() > 0, "foto %s (%dx%d)" % [caminho.get_file(), img.get_width(), img.get_height()])
	var linhas: Array = []
	for b in c._aba_registo._lista.get_children():
		if b is Button and not b.is_queued_for_deletion():
			linhas.append(b.text)
	return linhas


func _correr() -> void:
	var rede = root.get_node("Rede")
	var vista = JSON.parse_string(FileAccess.get_file_as_string(_arg("vista")))
	var saida := _arg("saida")
	_ok(vista is Dictionary and vista.get("pontos") is Array, "a vista do servidor tem pontos")
	if not (vista is Dictionary):
		quit(1)
		return
	rede.persistir = false
	rede.papel = "mestre"
	rede._room_id = "sala-teste"
	var c = (load(CENA) as PackedScene).instantiate()
	c.enviar_fn = func(_t, _c, _r): return ""
	c.pedir_vista_fn = func(): pass
	c.pesquisar_fn = func(_t): pass
	root.add_child(c)
	await _quadros(3)
	c._aviso_entendido()

	var antiga: Dictionary = vista.duplicate(true)
	for p in antiga["pontos"]:
		p.erase("autorId")
		p.erase("rodadaAutor")
	print("== antes (sem autorId/rodadaAutor: o rótulo de antes da ordem) ==")
	var l_antes: Array = await _foto(c, antiga, saida.path_join("registo-antes.png"))
	for l in l_antes:
		print("    ", l)
	print("== depois (a vista de hoje) ==")
	var l_depois: Array = await _foto(c, vista, saida.path_join("registo-depois.png"))
	for l in l_depois:
		print("    ", l)

	var orc := ""
	var her := ""
	for f in vista["mestre"]["figuras"]:
		if f.get("fichaId") == "orc-teste":
			orc = Modelo.nome_mestre(f)
		elif f.get("fichaId") == "heroina-teste":
			her = Modelo.nome_mestre(f)
	var ia_fim := "Ação do monstro, vez nova"
	_ok(l_antes.has("Rodada 2 · vez de %s · %s" % [her, ia_fim]), "ANTES: o defeito reproduzido — «Rodada 2 · vez de %s · %s»" % [her, ia_fim])
	_ok(l_depois.has("Rodada 1 · vez de %s · %s" % [orc, ia_fim]), "DEPOIS: «Rodada 1 · vez de %s · %s»" % [orc, ia_fim])
	_ok(not l_depois.has("Rodada 2 · vez de %s · %s" % [her, ia_fim]), "DEPOIS: a linha errada já não aparece")
	_ok(l_depois.has("Rodada 1 · vez de %s · vez nova" % her) and l_depois.has("Rodada 2 · vez de %s · vez nova" % her),
		"DEPOIS: os dois encerrar da heroína dizem a heroína (rodadas 1 e 2)")
	_ok(not l_depois.has("Rodada 1 · vez de %s · vez nova" % orc), "DEPOIS: nenhum encerrar da heroína rotulado com o orc")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(0 if _falhas == 0 else 1)
