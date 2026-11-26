extends RefCounted
## ORDEM-D-AUD-06 — o marcador de ALVO, partilhado pela arena da jogadora (arena.gd) e pela do Mestre (arena_mestre.gd).
##
## Antes, o alvo era a mesma malha plana dos destaques do Mover: um quadrado de 0,9 casa colado ao relevo
## (sobre_relevo.gdshader, `depth_draw_never`). Isso tinha três defeitos: tinha a mesma forma das casas alcançáveis
## (só a cor mudava), o tamanho dependia só da distância da câmara, e dentro de água ficava no fundo do lago, debaixo
## da superfície (o lago tem até 2,52 m de fundo).
##
## Este marcador é um nó 3D À ALTURA DA FIGURA, e nada dele assenta no relevo:
##   - «Anel»: um anel horizontal à volta do corpo, à cintura da figura (ALTURA_ANEL_FRAC da altura dela);
##   - «Seta»: uma seta (haste + ponta) que aponta para baixo, por cima da cabeça (a FOLGA_SETA_M do cimo); no lago,
##     o bico fica sempre acima da superfície da água (SETA_SOBRE_AGUA_M), mesmo com a figura no fundo.
## O material é sem luz e SEM TESTE DE PROFUNDIDADE: a água, a relva, o relevo e o próprio corpo não o tapam. Por isso
## vê-se com a figura dentro de água, em qualquer fundura. A forma (anel + seta, no ar) e a cor (COR) distinguem-no do
## destaque do Mover (o quadrado plano azul no chão, na jogadora; o cab577 com contorno, no Mestre).
##
## CANDIDATO: o aspecto (forma, cor, tamanhos) é palavra do Mestre (C-2, Lote 1). Os números estão todos aqui, num
## sítio só, para se poderem trocar sem mexer nas arenas. Só apresentação: os alvos vêm sempre do servidor.

const Apresentacao := preload("res://dados/apresentacao.gd")
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")

## A cor do marcador (o vermelho-alvo da mesa, opaco; o destaque plano usava-o a 50 %).
const COR := Color(Apresentacao.COR_MESA_ALVO.r, Apresentacao.COR_MESA_ALVO.g, Apresentacao.COR_MESA_ALVO.b, 0.95)
## O contorno escuro do anel e da seta (para se ler sobre a água clara e sobre a relva).
const COR_CONTORNO := Color(0.08, 0.03, 0.03, 0.9)
## Raio do anel (m) e a espessura do tubo (m). O corpo das figuras tem ~0,35–0,45 m de raio.
const RAIO_ANEL_M := 0.72
const TUBO_ANEL_M := 0.07
## O anel fica a esta fracção da altura da figura, a contar do pé (a cintura).
const ALTURA_ANEL_FRAC := 0.5
## A seta: o comprimento da ponta e da haste, o raio da ponta e da haste (m), e a folga acima da cabeça (m).
const PONTA_M := 0.42
const RAIO_PONTA_M := 0.26
const HASTE_M := 0.38
const RAIO_HASTE_M := 0.08
const FOLGA_SETA_M := 0.7
## Dentro do lago, o bico da seta fica pelo menos isto acima da superfície da água (m), qualquer que seja a fundura.
const SETA_SOBRE_AGUA_M := 0.3
## A altura de uma figura sem malhas medíveis (m).
const ALTURA_PADRAO_M := 1.8
## Por cima de tudo o que é transparente na cena (a água, os destaques planos).
const PRIORIDADE := 20


## Um marcador novo (ainda sem posição). `cor` troca a cor (por omissão, COR).
static func criar(cor: Color = COR) -> Node3D:
	var raiz := Node3D.new()
	raiz.name = "MarcadorAlvo"
	var anel := MeshInstance3D.new()
	anel.name = "Anel"
	var toro := TorusMesh.new()
	toro.inner_radius = RAIO_ANEL_M - TUBO_ANEL_M
	toro.outer_radius = RAIO_ANEL_M + TUBO_ANEL_M
	toro.rings = 48
	toro.ring_segments = 8
	anel.mesh = toro
	_configurar(anel, cor, 1)
	var contorno := MeshInstance3D.new()
	contorno.name = "AnelContorno"
	var toro2 := TorusMesh.new()
	toro2.inner_radius = RAIO_ANEL_M - TUBO_ANEL_M * 1.7
	toro2.outer_radius = RAIO_ANEL_M + TUBO_ANEL_M * 1.7
	toro2.rings = 48
	toro2.ring_segments = 8
	contorno.mesh = toro2
	_configurar(contorno, COR_CONTORNO, 0)
	raiz.add_child(contorno)
	raiz.add_child(anel)
	var seta := Node3D.new()
	seta.name = "Seta"
	raiz.add_child(seta)
	# A ponta: um cone com o bico para baixo (raio de baixo 0), com a base no topo.
	var ponta := MeshInstance3D.new()
	ponta.name = "Ponta"
	var cone := CylinderMesh.new()
	cone.top_radius = RAIO_PONTA_M
	cone.bottom_radius = 0.0
	cone.height = PONTA_M
	cone.radial_segments = 16
	ponta.mesh = cone
	ponta.position = Vector3(0.0, PONTA_M * 0.5, 0.0)
	_configurar(ponta, cor, 1)
	seta.add_child(ponta)
	var haste := MeshInstance3D.new()
	haste.name = "Haste"
	var cil := CylinderMesh.new()
	cil.top_radius = RAIO_HASTE_M
	cil.bottom_radius = RAIO_HASTE_M
	cil.height = HASTE_M
	cil.radial_segments = 12
	haste.mesh = cil
	haste.position = Vector3(0.0, PONTA_M + HASTE_M * 0.5, 0.0)
	_configurar(haste, cor, 1)
	seta.add_child(haste)
	return raiz


## Põe o marcador na figura `no` (o nó dela na cena): o anel à cintura, a seta por cima da cabeça. A altura vem das
## malhas da própria figura (a cápsula da jogadora, o marcador do site no Mestre, a figura caída deitada), por isso
## segue a figura dentro de água (a bóiar ou no fundo) e a figura alta ou baixa.
static func seguir(marcador: Node3D, no: Node3D) -> void:
	if marcador == null or no == null or not is_instance_valid(no):
		return
	var pe := no.global_position
	var cimo := topo_de(no)
	if not is_finite(cimo) or cimo <= pe.y + 0.2:
		cimo = pe.y + ALTURA_PADRAO_M
	marcador.global_position = pe
	var anel: Node3D = marcador.get_node("Anel")
	var contorno: Node3D = marcador.get_node("AnelContorno")
	var y_anel := (cimo - pe.y) * ALTURA_ANEL_FRAC
	anel.position = Vector3(0.0, y_anel, 0.0)
	contorno.position = anel.position
	var y_seta := cimo + FOLGA_SETA_M
	# No lago (até 2,52 m de fundo), a seta sai sempre acima da superfície da água, mesmo com a figura no fundo.
	if Relevo.lago_fundura(pe.x, pe.z) > 0.0:
		y_seta = maxf(y_seta, Relevo.nivel_lago() + SETA_SOBRE_AGUA_M)
	(marcador.get_node("Seta") as Node3D).position = Vector3(0.0, y_seta - pe.y, 0.0)


## O cimo (y no mundo) das malhas de uma figura, sem os rótulos (Label3D) e sem marcadores de alvo. INF se não houver.
static func topo_de(no: Node3D) -> float:
	var cimo := -INF
	var pilha: Array = [no]
	while not pilha.is_empty():
		var n: Node = pilha.pop_back()
		if n is Node3D and str(n.name) == "MarcadorAlvo":
			continue
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as MeshInstance3D).visible:
			var mi := n as MeshInstance3D
			var caixa: AABB = mi.global_transform * mi.mesh.get_aabb()
			cimo = maxf(cimo, caixa.end.y)
		for f in n.get_children():
			pilha.append(f)
	return cimo if cimo > -INF else INF


## O material do marcador: sem luz, sem teste de profundidade (nada o tapa: nem a água, nem o relevo, nem a relva),
## desenhado depois do que é transparente.
static func material(cor: Color, ordem: int) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = cor
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.no_depth_test = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.render_priority = PRIORIDADE + ordem
	return m


static func _configurar(mi: MeshInstance3D, cor: Color, ordem: int) -> void:
	mi.material_override = material(cor, ordem)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Acerta o conjunto de marcadores em `pai` com os ids de `alvos` (Array de String): cria os que faltam, tira os que
## sobram e põe cada um na sua figura (`no_de.call(id)` devolve o nó da figura, ou null). Devolve quantos ficaram.
static func sincronizar(pai: Node3D, alvos: Array, no_de: Callable) -> int:
	var querer := {}
	for id in alvos:
		querer[str(id)] = true
	for f in pai.get_children():
		var id := str(f.get_meta("alvo_id", ""))
		if not querer.has(id):
			pai.remove_child(f)
			f.queue_free()
	var tem := {}
	for f in pai.get_children():
		tem[str(f.get_meta("alvo_id", ""))] = f
	var n := 0
	for id in querer:
		var no = no_de.call(id)
		var m: Node3D = tem.get(id)
		if no == null or not is_instance_valid(no):
			if m != null:
				pai.remove_child(m)
				m.queue_free()
			continue
		if m == null:
			m = criar()
			m.set_meta("alvo_id", id)
			m.name = "Alvo_%s" % id.validate_node_name()
			pai.add_child(m)
		seguir(m, no)
		n += 1
	return n
