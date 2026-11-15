extends SceneTree
## provar_molde_54.gd — Ordem 54. A PROVA, com render verdadeiro, de que o mapa reutilizado é o mesmo mapa no ecrã do
## Mestre. Abre o ecrã do Mestre três vezes, como a foto 1 do foto_mestre.gd (a vista «mestre» da fixture do
## servidor, o cartão de desgraça aberto), com o relógio dos shaders parado (Engine.time_scale = 0: o vento da relva
## e das copas fica no mesmo instante), e fotografa o ecrã inteiro de cada vez:
##   1. com o molde DESLIGADO: o mapa construído de raiz, como antes da Ordem 54;
##   2. com o molde ligado: o mapa construído de raiz, e o molde guardado;
##   3. com o molde ligado: o mapa VESTIDO do molde (não se constrói).
## Compara as fotos byte a byte e o retrato inteiro do mapa (molde_floresta.gd: nós, malhas, materiais, MultiMesh
## com os buffers que só a GPU guarda, grelha, estado). Diz também quanto custou o mapa em cada abertura.
##
##   godot --path cliente --resolution 1920x1080 -s res://cenas/mestre/ferramentas/provar_molde_54.gd -- --saida=<pasta>
## Precisa de janela (GPU); sem janela não há fotos e só compara os retratos. Sai com 0 se tudo é igual.

const CENA := "res://cenas/mestre/mestre.tscn"
const Molde := preload("res://mapa/floresta/molde_floresta.gd")

var _saida := ""
var _falhas := 0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _correr() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
	if _saida == "":
		_saida = OS.get_user_data_dir().path_join("molde-54")
	DirAccess.make_dir_recursive_absolute(_saida)
	var com_render := DisplayServer.get_name() != "headless"
	print("== o molde do mapa no ecrã do Mestre (ordem 54) · render: %s ==" % (RenderingServer.get_video_adapter_name() if com_render else "nenhum (sem janela)"))
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var fx = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (fx is Dictionary):
		printerr("sem a fixture do servidor")
		quit(1)
		return
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede.papel = "mestre"
	root.size = Vector2i(1920, 1080)
	Engine.time_scale = 0.0
	# (Ordem 57) o quadro em que o time_scale muda ainda corre com um passo de tempo (medido: 1/15 s, sem escala). Antes
	# ninguém o lia; agora o relógio do mundo (Ordem 43) anda com ele — e só a 1.ª abertura o apanhava. Deixa-se passar.
	await _quadros(2)
	var fotos: Array[Image] = []
	var retratos: Array[PackedStringArray] = []
	var nomes := ["1-construido-sem-molde", "2-construido-guarda-o-molde", "3-vestido-do-molde"]
	for i in 3:
		Molde.ligado = i > 0
		var antes: Dictionary = Molde.contas.duplicate()
		var m = (load(CENA) as PackedScene).instantiate()
		m.enviar_fn = func(_t, _c, _r): return ""
		m.pedir_vista_fn = func(): pass
		root.add_child(m)
		await _quadros(2)
		m._aviso_entendido()
		m.aplicar_vista(fx["mestre"]["vista"])
		m.aplicar_cartao(fx["mestre"]["cartoes"]["desgraca"])
		m._ao_redimensionar()
		await _quadros(30)
		var mapa: Node3D = m._arena.mapa
		retratos.append(Molde.retrato(mapa))
		print("  abertura %d (%s): mapa em %d ms · guardados +%d, vestidos +%d · retrato de %d linhas" % [i + 1, nomes[i],
			int(mapa.medidas["carga_ms"]), int(Molde.contas["guardados"]) - int(antes["guardados"]),
			int(Molde.contas["vestidos"]) - int(antes["vestidos"]), retratos[i].size()])
		if com_render:
			await RenderingServer.frame_post_draw
			var img := root.get_texture().get_image()
			img.save_png(_saida.path_join(nomes[i] + ".png"))
			fotos.append(img)
		m.queue_free()
		await _quadros(2)
	Engine.time_scale = 1.0
	_conferir(retratos[1] == retratos[0], "o retrato do mapa construído com o molde ligado é igual ao de sem molde")
	_conferir(retratos[2] == retratos[0], "o retrato do mapa VESTIDO é igual ao do construído de raiz (%d linhas)" % retratos[0].size())
	if com_render:
		for i in [1, 2]:
			var n := _bytes_diferentes(fotos[0], fotos[i])
			_conferir(n == 0, "a foto %d é igual à foto 1 byte a byte: %d bytes diferentes de %d (%d×%d)" % [i + 1, n,
				fotos[0].get_data().size(), fotos[0].get_width(), fotos[0].get_height()])
	print("molde: %d falha(s)" % _falhas)
	quit(1 if _falhas > 0 else 0)


func _conferir(cond: bool, nome: String) -> void:
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		printerr("  FALHA ", nome)


func _bytes_diferentes(a: Image, b: Image) -> int:
	if a.get_size() != b.get_size() or a.get_format() != b.get_format():
		return -1
	var da := a.get_data()
	var db := b.get_data()
	var n := 0
	for i in da.size():
		if da[i] != db[i]:
			n += 1
	return n
