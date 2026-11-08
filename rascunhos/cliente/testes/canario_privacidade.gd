extends SceneTree
## Canário de privacidade do lado do cliente (desenho JV3.1 §7 c; revisão do Muse, 08/11/2026). I0004.
##
##   godot --headless --path cliente -s res://testes/canario_privacidade.gd
##
## O servidor nunca manda à Party o que é do Mestre (servidor/testes/privacidade.test.mjs e
## fixture-mestre.test.mjs). Isto prova a SEGUNDA tranca, no aparelho da jogadora:
## 1. a jogadora recebe o seu tráfego real (da fixture do servidor) e o HUD não mostra nenhum canário;
## 2. mesmo que lhe cheguem mensagens do Mestre (MASTER_VIEW, MASTER_CARD, snapshot com bloco
##    `mestre`), o cliente não as guarda e nenhum texto visível mostra os canários;
## 3. nenhum script fora de cenas/mestre/ (tirando o transporte e o estado, que têm guarda) lê o que
##    é do Mestre.
## Código de saída 0 se tudo passa, 1 se algo falha.

## Ficheiros que podem tocar no que é do Mestre: o transporte e o estado (com guarda de papel) e a cena.
const PERMITIDOS := ["res://rede/rede.gd", "res://estado/estado.gd"]
const PASTA_MESTRE := "res://cenas/mestre/"
const PROIBIDOS := ["ultima_vista_mestre", "cartao_ativo", "Estado.mestre", "modelo_mestre", "textos_mestre"]

var _total := 0
var _falhas := 0


## Os autoloads (Rede, Estado) não são identificadores num script -s: chegam pela árvore no 1.º quadro.
var _rede: Node
var _estado: Node


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		printerr("  FALHA ", nome)


func _textos(no: Node, saida: Array) -> void:
	if no is Label or no is Button or no is RichTextLabel or no is LineEdit:
		saida.append(no.text)
	for f in no.get_children():
		_textos(f, saida)


func _canarios_em(textos: Array, canarios: Array) -> Array:
	var achados: Array = []
	for t in textos:
		for c in canarios:
			if str(t).contains(c):
				achados.append("%s em «%s»" % [c, t])
	return achados


func _correr() -> void:
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var fx = JSON.parse_string(FileAccess.get_file_as_string(p))
	_ok(fx is Dictionary, "a fixture do servidor lê-se")
	if not (fx is Dictionary):
		_fim()
		return
	var canarios: Array = fx["canarios"]
	_rede.persistir = false
	_rede.papel = "jogadora"
	_rede.ultima_vista_mestre = {}
	_rede.cartao_ativo = {}
	var hud = (load("res://hud/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame

	print("== 1. o tráfego real da jogadora ==")
	for m in fx["jogadora"]["mensagens"]:
		_rede._ao_receber(JSON.stringify(m))
	for i in 3:
		await process_frame
	_ok(_rede.papel == "jogadora", "o lugar continua a ser o da jogadora")
	var textos: Array = []
	_textos(root, textos)
	var achados := _canarios_em(textos, canarios)
	_ok(achados.is_empty(), "nenhum canário no ecrã da jogadora %s" % [achados])
	_ok(_estado.figuras.size() > 0, "a jogadora vê as figuras públicas (%d)" % _estado.figuras.size())

	print("== 2. mensagens do Mestre a chegar ao aparelho da jogadora ==")
	_rede._ao_receber(JSON.stringify(fx["mestre"]["vista"]))
	for k in fx["mestre"]["cartoes"]:
		_rede._ao_receber(JSON.stringify(fx["mestre"]["cartoes"][k]))
	var snap: Dictionary = fx["mestre"]["snapshot"].duplicate(true)
	snap["seq"] = 100000  # mais novo do que tudo, para o estado o aplicar
	_rede._ao_receber(JSON.stringify(snap))
	for i in 3:
		await process_frame
	_ok(_rede.ultima_vista_mestre.is_empty(), "a MASTER_VIEW não se guarda fora do lugar do Mestre")
	_ok(_rede.cartao_ativo.is_empty(), "o MASTER_CARD não se guarda fora do lugar do Mestre")
	_ok(_estado.mestre.is_empty(), "o bloco `mestre` do snapshot não se guarda fora do lugar do Mestre")
	textos.clear()
	_textos(root, textos)
	achados = _canarios_em(textos, canarios)
	_ok(achados.is_empty(), "nenhum canário no ecrã da jogadora depois das mensagens do Mestre %s" % [achados])
	var figs_texto := JSON.stringify(_estado.figuras)
	_ok(_canarios_em([figs_texto], canarios).is_empty(), "nenhum canário nas figuras que o estado guarda")

	print("== 3. quem lê o que é do Mestre ==")
	var caminhos: Array[String] = []
	_juntar("res://", caminhos)
	var fora: Array = []
	for c in caminhos:
		if c.begins_with(PASTA_MESTRE) or PERMITIDOS.has(c) or c.begins_with("res://testes/"):
			continue
		var t := FileAccess.get_file_as_string(c)
		for palavra in PROIBIDOS:
			if t.contains(palavra):
				fora.append("%s: %s" % [c, palavra])
	_ok(fora.is_empty(), "nenhum script fora de cenas/mestre/ lê o que é do Mestre %s" % [fora])
	hud.queue_free()
	await process_frame
	_fim()


func _juntar(pasta: String, saida: Array[String]) -> void:
	var d := DirAccess.open(pasta)
	if d == null:
		return
	for f in d.get_files():
		if f.ends_with(".gd"):
			saida.append(pasta.path_join(f))
	for sub in d.get_directories():
		if not sub.begins_with("."):
			_juntar(pasta.path_join(sub), saida)


func _fim() -> void:
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)
