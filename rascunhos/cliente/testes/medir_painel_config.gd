extends SceneTree
## REF_20 do lado do cliente (I0004, 08/11/2026): o painel ⚙ cabe inteiro em ecrãs baixos?
## No site, a 844×390 só 29% do painel se via. Aqui mede-se o painel do HUD aberto em três
## janelas (deitado num telemóvel baixo, mais baixo ainda, e o ecrã de base) e falha-se se a
## última linha («Fechar») sair da área visível.
##
##   godot --headless --path cliente -s res://testes/medir_painel_config.gd
##
## Código de saída 0 se couber nas três, 1 se não couber, 2 se não der para medir.

const JANELAS := [Vector2i(844, 390), Vector2i(780, 360), Vector2i(1920, 1080)]

var _falhas := 0
var _sem_medida := 0


func _init() -> void:
	# Os autoloads (Rede, Estado) só existem a partir do primeiro quadro.
	process_frame.connect(_medir_todas, CONNECT_ONE_SHOT)


func _medir_todas() -> void:
	for j in JANELAS:
		await _medir(j)
	print("painel ⚙: %d falha(s), %d sem medida" % [_falhas, _sem_medida])
	quit(1 if _falhas > 0 else (2 if _sem_medida > 0 else 0))


func _medir(janela: Vector2i) -> void:
	root.size = janela
	await process_frame
	if root.size != janela:
		printerr("%s pedida, mas a janela ficou %s: sem medida" % [janela, root.size])
		_sem_medida += 1
		return
	var hud: Control = (load("res://hud/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	hud._ao_redimensionar()
	hud._alternar_config()
	for i in 4:
		await process_frame
	var visivel := root.get_visible_rect()
	var painel: Control = hud._painel_config
	var ultima: Control = null
	for n in painel.get_child(0).get_children():
		ultima = n as Control
	if ultima == null or not painel.is_visible_in_tree():
		printerr("não deu para medir a %s" % [janela])
		_falhas += 1
	else:
		var fundo := ultima.get_global_rect().end.y
		var cabe := fundo <= visivel.end.y + 0.5
		print("%s pedida, %s real: área visível %.0f × %.0f unidades; fonte %d; fundo de «%s» em %.0f → %s" % [
			janela, root.size, visivel.size.x, visivel.size.y, hud._fonte, (ultima as Button).text if ultima is Button else ultima.name,
			fundo, "CABE" if cabe else "NÃO CABE"])
		if not cabe:
			_falhas += 1
	hud.queue_free()
	await process_frame
