extends SceneTree
## ORDEM-D-AUD-14-LARGURA: a largura do tabuleiro do Mestre, em píxeis reais, nos dois percursos de abertura.
##
##   cd rascunhos/cliente && godot --path . -s <raiz>/provas/ordem-d-aud-14-largura/ferramentas/medir_largura.gd \
##       [-- --saida=<pasta das capturas>]
##
## Percurso A: a janela abre já a 1600×900 e o ecrã do Mestre monta-se lá.
## Percurso B: a janela abre a 800×450, o ecrã monta-se, e a janela passa a 1600×900.
## Percurso C: B e depois 1600×898 → 1600×900 (o «repassado» da INVESTIGA, l11).
## Imprime a largura do tabuleiro e da folha (em píxeis reais) e a largura mínima da barra das abas em cada passo.
## Código de saída 0 se A, B e C dão o mesmo tabuleiro (±1 px) e a folha segue a regra com a letra actual nos três, 1 se não.

const CENA := "res://cenas/mestre/mestre.tscn"
const QUADROS := 6

var _saida := ""


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.substr(8)
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _janela(tam: Vector2i) -> void:
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
		root.size = tam
	else:
		root.size = tam
	await _quadros(QUADROS)


func _medida(m, rotulo: String) -> Dictionary:
	var janela := Vector2(root.size)
	var escala := minf(janela.x / 1920.0, janela.y / 1080.0)
	var tab: float = m._tabuleiro.size.x * escala
	var folha: float = m._folha.size.x * escala
	var barra: Control = m._abas.get_tab_bar()
	var abas: float = barra.get_minimum_size().x
	var fim_barra: float = barra.get_global_rect().end.x
	var fim_ecra: float = root.get_visible_rect().end.x
	# A regra do próprio _ao_redimensionar, com o mínimo da barra na letra de AGORA: a folha é exactamente o máximo de 45 % e
	# coluna 1 + barra + uma letra + 3 margens (com o tecto de 85 % da área).
	var f := float(m._fonte)
	var area: float = m.get_viewport_rect().size.x
	var pedida := minf(maxf(area * 0.45, f * 14.0 + abas + f + f * 0.5 * 3.0), area * 0.85)
	var folha_u: float = m._folha.size.x
	var cabe := absf(folha_u - pedida) <= 0.5 and fim_barra <= fim_ecra + 0.5
	print("  %-30s janela %4d×%-4d letra %2d  tabuleiro %4.0f px  folha %4.0f px (%4.0f unid., a regra pede %4.0f)  barra: mínimo %3.0f unid., acaba em %4.0f de %4.0f  →  %s"
		% [rotulo, root.size.x, root.size.y, m._fonte, tab, folha, folha_u, pedida, abas, fim_barra, fim_ecra, "certa" if cabe else "MEDIDA VELHA"])
	return {"tabuleiro": roundi(tab), "folha": roundi(folha), "cabe": cabe}


func _capturar(nome: String) -> void:
	if _saida == "" or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(_saida)
	img.save_png(_saida.path_join(nome + ".png"))
	print("  captura: %s.png (%d×%d)" % [nome, img.get_width(), img.get_height()])


func _montar():
	var m = (load(CENA) as PackedScene).instantiate()
	m.enviar_fn = func(_t, _c, _r): return ""
	m.pedir_vista_fn = func(): pass
	root.add_child(m)
	await _quadros(QUADROS)
	m._aviso_entendido()
	await _quadros(2)
	return m


func _correr() -> void:
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede.papel = "mestre"
	print("ORDEM-D-AUD-14-LARGURA — o tabuleiro do Mestre a 1600×900 (DisplayServer: %s)" % DisplayServer.get_name())

	print("Percurso A: abertura directa a 1600×900")
	await _janela(Vector2i(1600, 900))
	var m = await _montar()
	var a := _medida(m, "A 1600×900 (directo)")
	await _capturar("a-1600x900-directo")
	m.queue_free()
	await _quadros(2)

	print("Percurso B: abertura a 800×450, depois 1600×900")
	await _janela(Vector2i(800, 450))
	m = await _montar()
	var b1 := _medida(m, "B 800×450")
	await _capturar("b1-800x450")
	await _janela(Vector2i(1600, 900))
	var b := _medida(m, "B 800×450 → 1600×900")
	await _capturar("b2-1600x900-depois-800x450")

	print("Percurso C: a seguir, 1600×898 → 1600×900")
	await _janela(Vector2i(1600, 898))
	await _janela(Vector2i(1600, 900))
	var c := _medida(m, "C … → 1600×898 → 1600×900")
	m.queue_free()
	await _quadros(2)

	var iguais: bool = absi(a["tabuleiro"] - b["tabuleiro"]) <= 1 and absi(a["tabuleiro"] - c["tabuleiro"]) <= 1
	var inteiras: bool = a["cabe"] and b1["cabe"] and b["cabe"] and c["cabe"]
	print("RESULTADO tabuleiro A=%d px  B=%d px  C=%d px  →  %s; folha na regra da letra actual nos quatro passos: %s" % [a["tabuleiro"],
		b["tabuleiro"], c["tabuleiro"], "IGUAIS" if iguais else "DIFERENTES (D-AUD-14)", "sim" if inteiras else "NÃO"])
	quit(0 if iguais and inteiras else 1)
