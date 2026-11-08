extends SceneTree
## Abre (compila) TODOS os .gd do projeto, sem os executar, e falha se algum não abrir.
## Serve para o CI apanhar erros de sintaxe e de tipos nos scripts que nenhum teste toca
## (Clareira de prova, perfis, color script, rampas, lobby). I0004, 08/11/2026.
##
##   godot --headless --path cliente --import          # uma vez: regista os class_name
##   godot --headless --path cliente -s res://testes/abrir_scripts.gd
##
## Código de saída 0 se todos abrirem, 1 se algum falhar.

## gerar_rampas.gd é um EditorScript: só existe dentro do editor, não no jogo.
const IGNORAR := ["res://.godot", "res://testes/abrir_scripts.gd", "res://arte/rampas/gerar_rampas.gd"]


func _init() -> void:
	# No _init os autoloads (Rede, Estado) ainda não existem e os scripts que os usam não compilam;
	# no primeiro quadro já existem.
	process_frame.connect(_verificar, CONNECT_ONE_SHOT)


func _verificar() -> void:
	var caminhos: Array[String] = []
	_juntar("res://", caminhos)
	caminhos.sort()
	var falhas := 0
	for p in caminhos:
		var s := ResourceLoader.load(p, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
		if s == null or not s.can_instantiate():
			falhas += 1
			printerr("FALHA ", p)
		else:
			print("ok    ", p)
	print("%d scripts, %d falhas" % [caminhos.size(), falhas])
	quit(1 if falhas > 0 else 0)


func _juntar(pasta: String, saida: Array[String]) -> void:
	var d := DirAccess.open(pasta)
	if d == null:
		return
	for f in d.get_files():
		var p := pasta.path_join(f)
		if f.ends_with(".gd") and not IGNORAR.has(p):
			saida.append(p)
	for sub in d.get_directories():
		var p := pasta.path_join(sub)
		if not IGNORAR.has(p) and not sub.begins_with("."):
			_juntar(p, saida)
