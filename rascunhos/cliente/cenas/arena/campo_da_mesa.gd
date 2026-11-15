extends RefCounted
## campo_da_mesa.gd — Ordem 45. O que as DUAS arenas (a do jogador, cenas/arena/arena.gd, e a do Mestre,
## cenas/mestre/arena_mestre.gd) fazem igual para assentar a mesa no mapa da floresta. Um só sítio: até à
## Ordem 44 isto vivia só em arena.gd (Ordem 42); a Ordem 45 tirou-o de lá, sem mudar uma conta, para o ecrã do
## Mestre usar o MESMO código em vez de uma cópia.
##
##   - `montar_mapa`        o mapa da floresta como chão da arena, com o céu e o sol dela (um só céu);
##   - `ligar_clima`        o clima sobre o mapa: bacias do relevo real, abrigos dos obstáculos reais;
##   - `malha_casas`        os remendos por casa que seguem o relevo (destaques, fogo, cursor);
##   - `linhas_grelha`      as linhas da grelha amostradas no relevo;
##   - `ponto_no_chao`      o raio do toque contra o relevo;
##   - `ligar_perfil`       (Ordem 52) o perfil gráfico do AplicadorPerfil chega à relva do mapa e ao clima.
## Só apresentação e geometria: não lê Estado, Rede nem nada do Mestre (canario_privacidade.gd).

const CampoFloresta := preload("res://mapa/floresta/campo_floresta.gd")
const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
## Ordem 42 (parte 2): os pontos baixos REAIS do relevo, para o alagamento do clima.
const BaciasRelevo := preload("res://cenas/arena/bacias_do_relevo.gd")
const Clima := preload("res://arte/clima/clima.gd")

## Quantos dos obstáculos reais do mapa (os mais perto da zona) dão abrigo à neve (o módulo aceita até 8).
const ABRIGOS_DO_MAPA := 8
## Divisões por lado de cada remendo de casa (os vértices seguem o relevo).
const DIVISOES_CASA := 4
## As malhas reais dos obstáculos do mapa que vestem a camada do clima (neve em cima, gelo).
const MALHAS_OBSTACULO := ["Arena/Pedras", "Arena/MarcoMadeira", "Arena/MarcoSantuario", "Arena/Troncos0",
	"Arena/Troncos1", "Arena/Troncos2", "Arena/Troncos3"]
## O chão do mapa que molha e branqueia (a zona fina e a larga).
const CHAO_DO_MAPA := [^"Arena/Terreno", ^"Fundo/TerrenoLargo"]


## Ordem 42: o mapa é construído para a zona jogável (lá dentro não põe nada que ocupe uma casa sem o servidor
## saber). Cria-o como primeiro filho de `dono`, com o Ambiente, o Sol e a Câmara de `dono` (caminhos relativos
## ao mapa): o mapa monta neles o céu pintado, a névoa e a luz — fica um céu só. O chão do mapa entra no grupo
## do clima. Devolve o mapa.
static func montar_mapa(dono: Node3D, zona: Rect2, ambiente: NodePath, sol: NodePath, camera: NodePath) -> Node3D:
	var mapa: Node3D = CampoFloresta.new()
	mapa.name = "Mapa"
	mapa.no_ambiente = ambiente
	mapa.no_sol = sol
	mapa.no_camera = camera
	mapa.vistas_por_tecla = false
	mapa.mostrar_medicao = false
	mapa.zona_jogo = zona
	dono.add_child(mapa)
	dono.move_child(mapa, 0)
	# Ordem 42 + clima (Ordens 40/41): o chão que molha e branqueia é o do mapa (a zona fina e a larga).
	for caminho in CHAO_DO_MAPA:
		var chao := mapa.get_node_or_null(caminho)
		if chao != null:
			chao.add_to_group(Clima.GRUPO_CHAO)
	return mapa


## Ordem 42 (parte 2): o clima sobre o mapa. As bacias do alagamento são os pontos baixos REAIS do relevo
## (inundação do terreno: cenas/arena/bacias_do_relevo.gd) e os abrigos da nevasca são os obstáculos REAIS
## do mapa (menires, santuário, lanternas, tronco tombado, rochas, árvores — mapa.obstaculos), os mais
## perto da zona. Cada abrigo é uma caixa invisível com a medida do obstáculo (o módulo lê a caixa da malha),
## posta debaixo de `pai`. `altura_chao` é a altura única do relevo (Callable (x, z) -> float).
static func ligar_clima(clima: Clima, mapa: Node3D, zona: Rect2, pai: Node3D, altura_chao: Callable) -> void:
	clima.altura_do_chao = altura_chao
	# A zona jogável do mapa não tem muros: a neve da nevasca não se junta nas bordas dela (um quadrado
	# branco à volta do campo), junta-se contra os obstáculos reais.
	clima.bordas_abrigo = 0.0
	clima.definir_bacias(BaciasRelevo.achar(zona))
	var raiz := Node3D.new()
	raiz.name = "AbrigosDoMapa"
	pai.add_child(raiz)
	var lista: Array = []
	for o: Dictionary in mapa.obstaculos:
		var c: Vector3 = o["c"]
		var m: Vector3 = o["m"]
		var caixa := Rect2(c.x - m.x, c.z - m.z, m.x * 2.0, m.z * 2.0)
		var dx := maxf(maxf(zona.position.x - caixa.end.x, caixa.position.x - zona.end.x), 0.0)
		var dz := maxf(maxf(zona.position.y - caixa.end.y, caixa.position.y - zona.end.y), 0.0)
		lista.append([sqrt(dx * dx + dz * dz), o])
	lista.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	for e: Array in lista.slice(0, ABRIGOS_DO_MAPA):
		var o: Dictionary = e[1]
		var m: Vector3 = o["m"]
		var mi := MeshInstance3D.new()
		mi.name = "Abrigo_" + String(o["nome"]).replace(" ", "_")
		var caixa := BoxMesh.new()
		caixa.size = Vector3(m.x * 2.0, m.y, m.z * 2.0)
		mi.mesh = caixa
		mi.position = (o["c"] as Vector3) + Vector3(0.0, m.y * 0.5, 0.0)
		mi.visible = false  # só a medida: o que se vê é o obstáculo do mapa
		mi.add_to_group(Clima.GRUPO_OBSTACULO)
		raiz.add_child(mi)
	# As malhas reais dos obstáculos vestem a camada do clima (neve em cima, gelo): registadas à mão, depois
	# das caixas — o módulo só dá abrigo aos 8 primeiros, por isso estas não roubam lugar às medidas.
	for caminho in MALHAS_OBSTACULO:
		var no := mapa.get_node_or_null(caminho)
		if no != null:
			clima.registar_obstaculo(no)


## Ordem 52: o perfil gráfico nas duas arenas, pelo MESMO caminho. Quando o AplicadorPerfil `perfis` aplica um
## perfil (perfil_aplicado), o clima passa às contagens desse perfil (clima.definir_perfil) e a relva do mapa à
## densidade da folhagem desse perfil. A relva do mapa tem LOD próprio, por isso a densidade passa-se ao mapa e não
## pelo grupo «folhagem_densa». `mapa_de` dá o mapa de agora (Callable () -> Node3D), porque o mapa refaz-se quando
## a grelha muda de tamanho. Até à Ordem 51 isto vivia só em arena.gd (Ordem 42); saiu de lá sem mudar uma conta.
static func ligar_perfil(perfis: AplicadorPerfil, clima: Clima, mapa_de: Callable) -> void:
	perfis.perfil_aplicado.connect(func(nome: String) -> void: perfil_no_mapa(perfis, mapa_de.call(), nome))
	perfis.perfil_aplicado.connect(clima.definir_perfil)


## A densidade da relva do perfil `nome` passa ao mapa. O número é o da tabela do AplicadorPerfil (ou da tabela
## que lhe puseram); as arenas não têm números próprios. Sem mapa não faz nada.
static func perfil_no_mapa(perfis: AplicadorPerfil, mapa: Node3D, nome: String) -> void:
	if mapa == null or not is_instance_valid(mapa):
		return
	mapa.definir_densidade_relva(densidade_do_perfil(perfis, nome))


## A densidade da folhagem do perfil `nome` na tabela do AplicadorPerfil (a do Médio se faltar).
static func densidade_do_perfil(perfis: AplicadorPerfil, nome: String) -> float:
	var fonte: Dictionary = perfis.tabela if not perfis.tabela.is_empty() else AplicadorPerfil.PERFIS
	var cfg: Dictionary = fonte.get(nome, fonte.get("medio", {}))
	var base: Dictionary = AplicadorPerfil.PERFIS["medio"]
	return float(cfg.get("folhagem_densidade", base["folhagem_densidade"]))


## Ordem 42 (parte 2): a relva do mapa responde ao clima (afoga nas bolsas, enterra-se na neve). Chamar a cada
## quadro; `com_clima` é o estado do quadro anterior (para limpar uma vez quando o clima acaba). Devolve o novo.
static func relva_segue_clima(clima: Clima, mapa: Node3D, com_clima: bool) -> bool:
	if clima == null or not (clima.neve > 0.0 or clima.aglomerado > 0.0 or clima.agua > 0.0 or clima.lama > 0.0 or com_clima):
		return com_clima
	var agora := clima.neve > 0.0 or clima.aglomerado > 0.0 or clima.agua > 0.0 or clima.lama > 0.0
	var m: ShaderMaterial = mapa.materiais_relva()[0]
	if m != null:
		clima.empurrar_terreno_para(m)
	return agora


## Uma malha com um remendo por casa: (DIVISOES_CASA + 1)² vértices por casa, cada um à altura do
## relevo + `levanta`. `casas` = [[Vector2i, Color], ...]; `escala` = fracção da casa coberta.
static func malha_casas(origem: Vector2, casa_m: float, casas: Array, escala: float, levanta: float) -> ArrayMesh:
	if casas.is_empty():
		return null
	var n := DIVISOES_CASA
	var v := PackedVector3Array()
	var cores := PackedColorArray()
	var idx := PackedInt32Array()
	var lado := casa_m * escala
	for e: Array in casas:
		var c: Vector2i = e[0]
		var cor: Color = e[1]
		var x0 := origem.x + (c.x + 0.5) * casa_m - lado * 0.5
		var z0 := origem.y + (c.y + 0.5) * casa_m - lado * 0.5
		var base := v.size()
		for j in n + 1:
			for i in n + 1:
				v.append(no_chao(x0 + lado * i / n, z0 + lado * j / n, levanta))
				cores.append(cor)
		for j in n:
			for i in n:
				var a := base + j * (n + 1) + i
				idx.append_array([a, a + 1, a + n + 1, a + 1, a + n + 2, a + n + 1])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_COLOR] = cores
	arr[Mesh.ARRAY_INDEX] = idx
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return malha


## As linhas da grelha (largura × altura casas a partir de `origem`), amostradas a cada 1/DIVISOES_CASA de casa,
## à altura do relevo + `levanta`.
static func linhas_grelha(origem: Vector2, casa_m: float, largura: int, altura: int, material: Material, levanta: float) -> ImmediateMesh:
	var tam := Vector2(largura * casa_m, altura * casa_m)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, material)
	var passos_x := largura * DIVISOES_CASA
	var passos_z := altura * DIVISOES_CASA
	for i in range(largura + 1):
		var x := origem.x + i * casa_m
		for k in passos_z:
			im.surface_add_vertex(no_chao(x, origem.y + tam.y * k / passos_z, levanta))
			im.surface_add_vertex(no_chao(x, origem.y + tam.y * (k + 1) / passos_z, levanta))
	for j in range(altura + 1):
		var z := origem.y + j * casa_m
		for k in passos_x:
			im.surface_add_vertex(no_chao(origem.x + tam.x * k / passos_x, z, levanta))
			im.surface_add_vertex(no_chao(origem.x + tam.x * (k + 1) / passos_x, z, levanta))
	im.surface_end()
	return im


static func no_chao(x: float, z: float, levanta: float) -> Vector3:
	return Vector3(x, Relevo.altura(x, z) + levanta, z)


## O primeiro ponto onde o raio (o, d) toca o chão do mapa, ou null. O raio desce até ao primeiro ponto abaixo
## do relevo (passos de 0,25 m) e afina-se por bisseção.
## Ordem 51: o raio que só RASA um cimo do relevo (tangente, a ver o centro de uma casa no horizonte do chão)
## cabe entre dois passos e não fica abaixo do relevo em nenhum: cada mínimo da folga (altura do raio − relevo)
## entre passos afina-se por secção áurea, e uma folga de até TOQUE_RASANTE_M conta como toque nesse ponto.
const TOQUE_RASANTE_M := 0.001

static func ponto_no_chao(o: Vector3, d: Vector3):
	if d.y > -0.0005:
		return null
	# começa onde o raio desce abaixo dos 12 m (o relevo da arena do mapa fica muito abaixo disso)
	var t := maxf((o.y - 12.0) / -d.y, 0.0)
	var passo := 0.25
	var antes := t
	var folga_2 := INF  # a folga dois passos atrás
	var folga_1 := INF  # a folga no passo anterior (em `antes`)
	for i in 4000:
		var q := o + d * t
		var folga := q.y - Relevo.altura(q.x, q.z)
		if folga <= 0.0:
			var a := antes
			var b := t
			for k in 14:
				var m := (a + b) * 0.5
				var qm := o + d * m
				if qm.y <= Relevo.altura(qm.x, qm.z):
					b = m
				else:
					a = m
			return o + d * b
		# a folga desceu e voltou a subir: o raio passou rente a um cimo entre t − 2·passo e t
		if folga_1 < folga_2 and folga_1 <= folga and folga_1 < passo:
			var tr = _rasante(o, d, maxf(antes - passo, 0.0), t)
			if tr != null:
				return o + d * tr
		if q.y < -40.0:
			return null
		folga_2 = folga_1
		folga_1 = folga
		antes = t
		t += passo
	return null


## O t do ponto de folga mínima do raio em [a, b] (secção áurea), se essa folga for ≤ TOQUE_RASANTE_M; senão null.
static func _rasante(o: Vector3, d: Vector3, a: float, b: float):
	const R := 0.6180339887
	var c := b - (b - a) * R
	var e := a + (b - a) * R
	var fc := _folga(o, d, c)
	var fe := _folga(o, d, e)
	for k in 40:
		if fc < fe:
			b = e
			e = c
			fe = fc
			c = b - (b - a) * R
			fc = _folga(o, d, c)
		else:
			a = c
			c = e
			fc = fe
			e = a + (b - a) * R
			fe = _folga(o, d, e)
	var tm := (a + b) * 0.5
	return tm if _folga(o, d, tm) <= TOQUE_RASANTE_M else null


static func _folga(o: Vector3, d: Vector3, t: float) -> float:
	var q := o + d * t
	return q.y - Relevo.altura(q.x, q.z)
