extends SceneTree
## Abre a Clareira de prova sem janela e confere o que ela monta (I0004, 08/11/2026).
##
##   godot --headless --path cliente -s res://testes/abrir_clareira.gd
##
## Confere: a cena abre e o _ready corre; os nós que o script espera existem; os grupos que o
## AplicadorPerfil usa estão cheios; as 4 horas-chave aplicam-se; os 3 perfis aplicam-se e
## apagam/repõem o contorno; o pontilhado das copas está DESLIGADO (REF_23, à espera do Mestre).
## Código de saída 0 se tudo passa, 1 se algo falha.

const CENA := "res://arte/cenas/clareira_prova.tscn"

var _total := 0
var _falhas := 0


func _init() -> void:
	# Os autoloads só existem a partir do primeiro quadro (e a cena pode precisar deles).
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		printerr("  FALHA ", nome)


func _correr() -> void:
	print("== Clareira de prova ==")
	var ps := load(CENA) as PackedScene
	_ok(ps != null, "a cena carrega")
	if ps == null:
		_fim()
		return
	var c = ps.instantiate()
	c.ciclo_automatico = false
	root.add_child(c)
	for i in 3:
		await process_frame

	for caminho in ["Ambiente", "Sol", "Camera", "Perfis", "Medicao/Rotulo"]:
		_ok(c.has_node(caminho), "tem o nó %s" % caminho)
	_ok(c._mat_ceu != null, "o céu é o shader pintado")
	_ok(get_nodes_in_group(&"sol").size() == 1, "um sol no grupo «sol»")
	_ok(get_nodes_in_group(&"ambiente").size() == 1, "um ambiente no grupo «ambiente»")
	_ok(get_nodes_in_group(&"figura").size() == 5, "5 figuras no grupo «figura» (4 + a besta)")
	_ok(get_nodes_in_group(&"folhagem").size() == 8, "8 no grupo «folhagem» (7 copas + arbustos)")
	_ok(get_nodes_in_group(&"folhagem_densa").size() == 1, "os arbustos no grupo «folhagem_densa»")
	_ok(c._perfis.atual == "medio", "o perfil inicial (médio) foi aplicado")

	# REF_23: copas sem pontilhado por defeito.
	var com_pontilhado := 0
	var folhagens := 0
	for n in get_nodes_in_group(&"folhagem"):
		var m := (n as GeometryInstance3D).material_override as ShaderMaterial
		if m != null:
			folhagens += 1
			if bool(m.get_shader_parameter("usar_alpha_hash")):
				com_pontilhado += 1
	_ok(folhagens == 8 and com_pontilhado == 0, "nenhuma copa com pontilhado (REF_23: à espera do Mestre)")

	# As 4 horas-chave.
	for h in c.HORAS_CHAVE:
		c.hora = h
		c._escrever_hora(true)
		await process_frame
	_ok(is_equal_approx(c._hora_escrita, 22.0), "as 4 horas-chave aplicam-se (fica nas 22 h)")
	_ok(c._sol.rotation_degrees.x < 0.0, "o sol aponta para baixo")

	# Os 3 perfis: o contorno some no Baixo e volta no Alto.
	var figura := get_nodes_in_group(&"figura")[0] as MeshInstance3D
	var mat_fig := figura.material_override as Material
	_ok(c._perfis.aplicar("baixo") and mat_fig.next_pass == null, "Baixo: aplica e tira o contorno")
	_ok(c._perfis.aplicar("alto") and mat_fig.next_pass != null, "Alto: aplica e repõe o contorno")
	_ok(c._perfis.aplicar("Médio") and c._perfis.atual == "medio", "«Médio» da ⚙ aplica-se")
	var mm := (get_nodes_in_group(&"folhagem_densa")[0] as MultiMeshInstance3D).multimesh
	c._perfis.aplicar("baixo")
	_ok(mm.visible_instance_count == int(round(mm.instance_count * 0.5)), "Baixo: metade dos arbustos")
	c._perfis.aplicar("alto")
	_ok(mm.visible_instance_count == -1, "Alto: todos os arbustos")

	# O rótulo actualiza-se a cada 0,5 s de jogo; sem janela os quadros podem ser muito curtos.
	for i in 3000:
		if c._rotulo.text.begins_with("PLACEHOLDERS |"):
			break
		await process_frame
	_ok(c._rotulo.text.begins_with("PLACEHOLDERS |"), "o rótulo de medição actualiza-se")
	c.queue_free()
	await process_frame
	_fim()


func _fim() -> void:
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)
