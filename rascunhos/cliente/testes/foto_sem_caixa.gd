extends SceneTree
## Ordem HUD — prova de que, com a caixa da ordem DESLIGADA, a batalha no ecrã do Mestre fica exactamente como antes
## da missão HUD. Corre a mesma cena e o mesmo guião em duas árvores (a de hoje e a de antes, p. ex. cbe7729, onde se
## copia este ficheiro) e grava o ecrã inteiro no mesmo quadro; a comparação píxel a píxel faz-se fora (python).
##
##   xvfb-run -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 --resolution 1280x720 --fixed-fps 30 \
##     --path cliente -s res://testes/foto_sem_caixa.gd -- --saida=<ficheiro.png>
##
## Corre COM render, nunca com --headless. Não entra no CI. Na árvore de hoje, a caixa fica LIGADA durante as acções
## (forma a ordem e os retratos, como em jogo) e o Mestre DESLIGA-A antes da foto; na de antes a caixa não existe.
## Controlo de sensibilidade: `-- --caixa-ligada` deixa a caixa ligada (a foto tem de sair diferente).

const CENA := "res://cenas/mestre/mestre.tscn"
const QUADROS_ANTES_DA_FOTO := 90

var _saida := ""
var _manter_ligada := false
var _m = null
var _vista: Dictionary = {}
var _seq := 1000


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _quadros(n: int) -> void:
	for i in n:
		await process_frame


func _evento(tipo: String, dados: Dictionary, vez: String) -> void:
	_seq += 1
	_m._ao_evento({"seq": _seq, "tipo": tipo, "dados": dados})
	_vista["vezId"] = vez
	_m.aplicar_vista(_vista)


func _correr() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
		elif a == "--caixa-ligada":
			_manter_ligada = true
	var p := ProjectSettings.globalize_path("res://").path_join("../servidor/dados-exemplo/mesa-mestre.json")
	var d = JSON.parse_string(FileAccess.get_file_as_string(p))
	var rede := root.get_node("Rede")
	rede.persistir = false
	rede.papel = "mestre"
	root.size = Vector2i(1280, 720)
	_vista = (d["mestre"]["vista"] as Dictionary).duplicate(true)
	var ids := {}
	for f in _vista["mestre"]["figuras"]:
		ids[str(f["fichaId"])] = str(f["id"])
	var j1: String = ids["heroina-teste"]
	var j2: String = ids["aliada-teste"]
	var orc: String = ids["orc-teste"]
	_m = (load(CENA) as PackedScene).instantiate()
	# Ordem CAIXA-PERSISTENTE: sem servidor, a escolha da caixa (MASTER_SUPERVISOR op 'caixa') fica «em voo» (um id
	# fixo) — sem o alerta «sem ligação» nas capturas; os outros comandos não saem, como antes.
	_m.enviar_fn = func(_t, c, _r): return "prova-caixa" if c.get("op") == "caixa" else ""
	_m.pedir_vista_fn = func(): pass
	root.add_child(_m)
	await _quadros(2)
	_m._aviso_entendido()
	_m.aplicar_vista(_vista)
	_m._ao_redimensionar()
	var arena = _m._arena
	arena.camera.focar((arena._nos[j1].position + arena._nos[j2].position + arena._nos[orc].position) / 3.0)
	arena.camera.definir_zoom(3.0)
	arena.camera._saltar()
	await _quadros(20)
	var atq := func(de, a): return {"atacanteId": de, "alvoId": a, "arma": "demo", "resultado": "acerto", "ataqueDeOportunidade": false}
	for par in [[j1, orc], [j2, orc], [orc, j1], [j1, orc]]:
		_evento("ataque", atq.call(par[0], par[1]), par[0])
		await _quadros(10)
	var tem_caixa: bool = _m.has_method("ligar_caixa")
	if tem_caixa and not _manter_ligada:
		_m.ligar_caixa(false)
	await _quadros(QUADROS_ANTES_DA_FOTO)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(_saida)
	print("foto_sem_caixa: ", _saida, " · caixa na árvore: ", tem_caixa, " · ligada na foto: ", tem_caixa and _manter_ligada, " · ", img.get_width(), "×", img.get_height())
	quit(0)
