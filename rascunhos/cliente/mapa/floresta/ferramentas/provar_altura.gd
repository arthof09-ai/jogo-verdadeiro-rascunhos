extends SceneTree
## provar_altura.gd — Ordem 38 (defeito 9). A PROVA DA ALTURA ÚNICA, em números: em 6000 pontos
## (4000 ao acaso na zona jogável + 2000 em cima da orla da arena, onde a Ordem 37 divergia até
## 1,4 m) compara a altura da CONSULTA (cena.altura_em → Relevo.altura) com a da COLISÃO (um raio
## a cair no corpo do chão). A malha que se vê é feita dos mesmos triângulos da colisão (confere-se
## aqui também: os vértices da malha «Terreno» contra as faces da forma de colisão).
##
##   godot --path cliente --headless -s res://mapa/floresta/ferramentas/provar_altura.gd
##
## Corre sem janela. Sai com 0 se a maior divergência for ≤ 1 cm e nenhum raio falhar o chão.

const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const CENA := "res://mapa/floresta/campo_floresta.tscn"
const TOLERANCIA := 0.01


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _correr() -> void:
	var cena: Node3D = (load(CENA) as PackedScene).instantiate()
	cena.set("mostrar_medicao", false)
	root.add_child(cena)
	for i in 4:
		await physics_frame
	var espaco := cena.get_world_3d().direct_space_state
	var r := RandomNumberGenerator.new()
	r.seed = 3809
	var pontos: Array[Vector2] = []
	var meio: float = Relevo.MEIO
	for i in 4000:
		pontos.append(Vector2(r.randf_range(-meio, meio), r.randf_range(-meio, meio)))
	for i in 2000:
		var t := r.randf_range(-meio, meio)
		var lado := i % 4
		pontos.append([Vector2(t, -meio), Vector2(t, meio), Vector2(-meio, t), Vector2(meio, t)][lado])
	var maior := 0.0
	var maior_orla := 0.0
	var soma := 0.0
	var falhados := 0
	var onde := Vector2.ZERO
	for i in pontos.size():
		var p := pontos[i]
		var raio := PhysicsRayQueryParameters3D.create(Vector3(p.x, 80.0, p.y), Vector3(p.x, -80.0, p.y))
		var toque := espaco.intersect_ray(raio)
		if toque.is_empty():
			falhados += 1
			continue
		var d := absf(float((toque["position"] as Vector3).y) - float(cena.call("altura_em", p.x, p.y)))
		soma += d
		if d > maior:
			maior = d
			onde = p
		if i >= 4000:
			maior_orla = maxf(maior_orla, d)
	# a malha que se vê contra a colisão: os mesmos triângulos?
	var malha := (cena.find_child("Terreno", true, false) as MeshInstance3D).mesh
	var corpo := cena.find_child("ChaoColisao", true, false) as StaticBody3D
	var forma := (corpo.get_child(0) as CollisionShape3D).shape as ConcavePolygonShape3D
	var faces_malha := malha.get_faces()
	var faces_colisao := forma.get_faces()
	var dif_malha := -1.0
	if faces_malha.size() == faces_colisao.size():
		dif_malha = 0.0
		for i in faces_malha.size():
			dif_malha = maxf(dif_malha, faces_malha[i].distance_to(faces_colisao[i]))
	print("[altura] %d pontos · raios que falharam o chão: %d" % [pontos.size(), falhados])
	print("[altura] consulta − colisão: maior %.5f m (em x=%.2f z=%.2f) · média %.6f m · maior NA ORLA da arena %.5f m" % [
		maior, onde.x, onde.y, soma / float(maxi(pontos.size() - falhados, 1)), maior_orla])
	print("[altura] malha «Terreno» − colisão: %d e %d vértices de face · maior distância %s" % [
		faces_malha.size(), faces_colisao.size(), ("%.6f m" % dif_malha) if dif_malha >= 0.0 else "N.º DIFERENTE"])
	var ok := falhados == 0 and maior <= TOLERANCIA and dif_malha >= 0.0 and dif_malha <= 0.0001
	print("[altura] %s" % ("PASSOU (tolerância %.2f m)" % TOLERANCIA if ok else "FALHOU"))
	quit(0 if ok else 1)
