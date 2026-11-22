extends Node
## Ordem HUD — os RETRATOS DOS PRÓPRIOS MODELOS (palavra do Mestre, 16/11/2026 11:18).
##
## Cada figura da caixa da ordem de turnos mostra um retrato RENDERIZADO DO PRÓPRIO MODELO 3D dela: este nó
## copia o nó do modelo que está em cena (`Node.duplicate`: as mesmas malhas e os mesmos materiais) para um palco
## à parte — um SubViewport com mundo próprio, câmara de enquadramento fixo, luz fixa e o fundo da paleta — e
## desenha-o uma vez. Nunca uma imagem à parte: o retrato é sempre a figura que está em cena, por isso não pode
## divergir dela. Figuras provisórias (o marcador do site, a cápsula da arena) dão o retrato do modelo provisório.
##
## Um palco por figura; o retrato só se volta a desenhar quando a `chave` do pedido muda (ex.: a figura caiu). No
## CI (--headless) o motor não desenha: a textura existe mas fica vazia, e nada mais muda.

signal mudou(id: String)

## O lado do retrato em píxeis (quadrado).
const TAMANHO := 160
## Fundo quando o modelo não traz cor de identificação (o anel do marcador do site).
## A cor de identificação já vem da tabela de apresentação (Apresentacao.PALETA_ANEIS, pelo material do anel do
## marcador). Este fundo de recurso também vem da tabela: o raro, opaco (Ordem PALETA-C ponto 2, palavra do Mestre,
## 21/11/2026).
const Apresentacao := preload("res://dados/apresentacao.gd")
const COR_FUNDO_PADRAO := Apresentacao.COR_RETRATO_FUNDO
## Quanto o fundo escurece a cor de identificação, para a pedra do corpo se ler por cima.
const ESCURECER_FUNDO := 0.45
## Nós do modelo em cena que não entram no retrato: o que pertence ao chão e os rótulos.
const NAO_ENTRAM := ["Anel", "Contacto", "Base", "Nome", "Rotulo"]
## De onde a câmara olha (frente a três quartos, um pouco de cima) e a abertura. A FRENTE de uma figura é -Z (a arena
## roda o nó com essa convenção, cenas/arena/arena.gd RUMO_ORIENTACAO): a câmara fica desse lado, para ver o ROSTO.
## (Ordem CAIXA-PADRAO-BUSTO: antes estava em +Z — com a cápsula, simétrica, não se via; com o manequim eram as costas.)
const DIRECAO_CAMARA := Vector3(0.45, 0.22, -1.0)
const FOV := 28.0
## Figura de pé: o retrato é do BUSTO — rosto e peitoral (palavra do Mestre, 21/11/2026 19:52: «mais fechada no rosto e
## peitoral»). A janela vai do alto da cabeça até esta fracção da altura da figura EM POSE (cabeça ≈ 0,13; peito até
## ≈ 0,30), e é quadrada: a largura dos braços não a abre.
const FRACAO_BUSTO := 0.30
## Folga por cima da cabeça (fracção da altura), para o alto da cabeça não tocar na moldura.
const FOLGA_CIMA := 0.03
## Folga à volta da janela do busto (1 = justa).
const FOLGA_BUSTO := 1.08
## De pé = a figura em pose é mais alta do que larga por este factor; senão (deitada, quadrúpede), o corpo inteiro.
const DE_PE := 1.2
## Ordem CAIXA-PADRAO-CORRECOES (B1): a largura que conta para o «de pé» é a do TRONCO — as partes da figura acima desta
## fracção da altura (de cima para baixo: a metade de cima). As pernas e os pés de quem dá um passo ficam fora da medida.
## Medido no ANDAR v3 inteiro (42 quadros): o fundo da figura toda chega a 1,008 m (quadro 0), a 0,466 m do limiar
## (1,769 / 1,2 = 1,474 m); o tronco não passa de 0,653 m. Uma figura deitada ou um quadrúpede são largos também em cima.
const FRACAO_TRONCO := 0.5

var _palcos := {}  # id -> SubViewport
var _chaves := {}  # id -> String


## A textura do retrato de `id` (null se ainda não foi pedido).
func textura(id: String) -> Texture2D:
	var sv: SubViewport = _palcos.get(id)
	return sv.get_texture() if sv != null else null


func tem(id: String) -> bool:
	return _palcos.has(id)


## Pede o retrato de `id` a partir do nó do modelo em cena. Só desenha outra vez se `chave` mudou.
func pedir(id: String, chave: String, modelo: Node3D) -> void:
	if modelo == null or id == "":
		return
	if _palcos.has(id) and _chaves.get(id) == chave:
		return
	_chaves[id] = chave
	var sv: SubViewport = _palcos.get(id)
	if sv == null:
		sv = _novo_palco(id)
		_palcos[id] = sv
		add_child(sv)
	var palco := sv.get_node("Palco") as Node3D
	for c in palco.get_children():
		palco.remove_child(c)
		c.queue_free()
	var copia := copiar_modelo(modelo)
	palco.add_child(copia)
	var amb := (sv.get_node("Ambiente") as WorldEnvironment).environment
	amb.background_color = cor_de_fundo(modelo)
	enquadrar(sv.get_node("Camera") as Camera3D, copia)
	sv.render_target_update_mode = SubViewport.UPDATE_ONCE
	mudou.emit(id)


## Larga os retratos das figuras que já não existem (`vivos`: id -> qualquer coisa).
func esquecer_ausentes(vivos: Dictionary) -> void:
	for id in _palcos.keys():
		if not vivos.has(id):
			(_palcos[id] as Node).queue_free()
			_palcos.erase(id)
			_chaves.erase(id)


## A cópia do modelo para o palco: as mesmas malhas e materiais, sem grupos (o clima e o perfil gráfico mexem em
## figuras pelos grupos: a cópia não é figura do jogo), sem o que é do chão e sem rótulos, assente na origem.
static func copiar_modelo(modelo: Node3D) -> Node3D:
	var copia := modelo.duplicate(Node.DUPLICATE_SCRIPTS | Node.DUPLICATE_SIGNALS) as Node3D
	copia.transform = Transform3D.IDENTITY
	_limpar(copia)
	return copia


static func _limpar(no: Node) -> void:
	for g in no.get_groups():
		no.remove_from_group(g)
	if no is Label3D or NAO_ENTRAM.has(str(no.name)):
		(no as Node3D).visible = false
	for c in no.get_children():
		_limpar(c)


## O fundo da paleta: a cor de identificação da figura (o anel do marcador do site), escurecida; sem ela, o padrão.
static func cor_de_fundo(modelo: Node3D) -> Color:
	var anel := modelo.find_child("Anel", true, false) as MeshInstance3D
	if anel != null and anel.mesh != null and anel.mesh.get_surface_count() > 0:
		var mat := anel.mesh.surface_get_material(0) as StandardMaterial3D
		if mat != null:
			return mat.albedo_color.darkened(ESCURECER_FUNDO)
	return COR_FUNDO_PADRAO


## A caixa (no espaço do palco) das malhas visíveis da cópia, NA POSE EM QUE ESTÃO (ver `caixas_em_pose`).
static func caixa_visivel(no: Node3D) -> AABB:
	return _juntar(caixas_em_pose(no))


## Ordem CAIXA-PADRAO-CORRECOES (B2): a caixa do CORPO da figura em pose (ver `caixas_do_corpo`) — a que o enquadramento
## mede (a altura, a faixa do busto e o «de pé»).
static func caixa_do_corpo(no: Node3D) -> AABB:
	return _juntar(caixas_do_corpo(no))


## Ordem CAIXA-PADRAO-CORRECOES (B2): as caixas do que é CORPO. Se a figura tem malhas esfoladas (um corpo com esqueleto,
## como o manequim), o corpo são elas; as malhas RÍGIDAS que leva (uma arma empunhada, um escudo, um adereço preso a um
## osso) não são corpo: desenham-se no retrato, mas não contam para a altura nem para a faixa — uma espada levantada
## não sobe a janela do busto. Uma figura só de malhas rígidas (a cápsula, o marcador) é toda corpo.
## Limites (documentados, não resolvidos): uma capa ESFOLADA conta como corpo; um braço levantado É corpo e sobe a
## altura (o rosto fica no quadro, o peito pode sair: medido no teste `_teste_retrato_casos_corpo`).
static func caixas_do_corpo(no: Node3D) -> Array[AABB]:
	var esfoladas: Array[AABB] = []
	var rigidas: Array[AABB] = []
	for mi in _malhas_visiveis(no, Transform3D.IDENTITY, []):
		var ossos := _caixas_dos_ossos(no, mi[2] as MeshInstance3D)
		if ossos.is_empty():
			rigidas.append((mi[0] as Transform3D) * (mi[1] as Mesh).get_aabb())
		else:
			esfoladas.append_array(ossos)
	return esfoladas if not esfoladas.is_empty() else rigidas


## As caixas das partes visíveis da cópia, no espaço do palco e na pose em que a figura está.
## Uma malha rígida dá a sua caixa. Uma malha ESFOLADA (com esqueleto e skin) não pode usar `Mesh.get_aabb()`: essa é a
## caixa da pose de repouso do ficheiro (num manequim, a pose em T, braços abertos: 1,76 m de largo). Em vez dela, cada
## osso que deforma a malha dá a caixa dos vértices que move (`bone_aabbs` da superfície, a mesma conta que o motor faz
## para a caixa da malha esfolada) levada pela pose actual desse osso. Assim o retrato enquadra a figura como ela está.
static func caixas_em_pose(no: Node3D) -> Array[AABB]:
	var saida: Array[AABB] = []
	for mi in _malhas_visiveis(no, Transform3D.IDENTITY, []):
		var t: Transform3D = mi[0]
		var inst: MeshInstance3D = mi[2]
		var ossos := _caixas_dos_ossos(no, inst)
		if ossos.is_empty():
			saida.append(t * (mi[1] as Mesh).get_aabb())
		else:
			saida.append_array(ossos)
	return saida


static func _juntar(caixas: Array[AABB]) -> AABB:
	var caixa := AABB()
	var primeira := true
	for a in caixas:
		if primeira:
			caixa = a
			primeira = false
		else:
			caixa = caixa.merge(a)
	return caixa


## A malha esfolada em pose: uma caixa por osso que a deforma, no espaço de `raiz`. Vazio se a malha não é esfolada
## (ou o motor não deu as caixas dos ossos): quem chama usa então a caixa da malha.
static func _caixas_dos_ossos(raiz: Node3D, inst: MeshInstance3D) -> Array[AABB]:
	var saida: Array[AABB] = []
	if inst.skin == null or inst.mesh == null or inst.skeleton.is_empty():
		return saida
	var esq := inst.get_node_or_null(inst.skeleton) as Skeleton3D
	if esq == null:
		return saida
	var t_esq := _no_espaco_de(raiz, esq)
	var skin := inst.skin
	for s in inst.mesh.get_surface_count():
		var sup: Dictionary = RenderingServer.mesh_get_surface(inst.mesh.get_rid(), s)
		var caixas: Array = sup.get("bone_aabbs", [])
		for i in mini(caixas.size(), skin.get_bind_count()):
			var a: AABB = caixas[i]
			if a.size.x < 0.0 or a.size.y < 0.0 or a.size.z < 0.0:
				continue  # osso que não mexe nenhum vértice desta superfície
			var b := skin.get_bind_bone(i)
			if b < 0:
				b = esq.find_bone(skin.get_bind_name(i))
			if b < 0 or b >= esq.get_bone_count():
				continue
			saida.append(t_esq * esq.get_bone_global_pose(b) * skin.get_bind_pose(i) * a)
	return saida


## A transformação de `no` no espaço em que `_malhas_visiveis` mede (o pai de `raiz`; a cópia assenta na origem do
## palco). A cópia pode ainda não estar na árvore.
static func _no_espaco_de(raiz: Node3D, no: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var n: Node = no
	while n != null:
		if n is Node3D:
			t = (n as Node3D).transform * t
		if n == raiz:
			break
		n = n.get_parent()
	return t


static func _malhas_visiveis(no: Node, pai: Transform3D, saida: Array) -> Array:
	var t := pai
	if no is Node3D:
		if not (no as Node3D).visible:
			return saida
		t = pai * (no as Node3D).transform
	if no is MeshInstance3D and (no as MeshInstance3D).mesh != null:
		saida.append([t, (no as MeshInstance3D).mesh, no])
	for c in no.get_children():
		_malhas_visiveis(c, t, saida)
	return saida


## Ordem CAIXA-PADRAO-BUSTO: a figura está de pé? Mede-se na POSE (não na malha em T): mais alta do que larga.
## Ordem CAIXA-PADRAO-CORRECOES (B1): com as `caixas` da figura, a largura é a do TRONCO (`largura_tronco`): a passada
## (as pernas abertas para a frente e para trás) já não conta. Sem elas, a largura é a da caixa toda (como antes).
static func de_pe(c: AABB, caixas: Array[AABB] = []) -> bool:
	return c.size.y > largura_tronco(caixas, c) * DE_PE


## Ordem CAIXA-PADRAO-CORRECOES (B1): a largura (o maior de x e z) das partes da figura acima de FRACAO_TRONCO da altura
## (a metade de cima: cabeça, tronco e braços), sem as pernas nem os pés. Sem `caixas`, a da caixa toda.
static func largura_tronco(caixas: Array[AABB], c: AABB) -> float:
	var cima := _faixa(caixas, c.end.y - c.size.y * FRACAO_TRONCO)
	if cima.size == Vector3.ZERO:
		return maxf(c.size.x, c.size.z)
	return maxf(cima.size.x, cima.size.z)


## As partes das `caixas` acima de `base`, cortadas em `base` e juntas numa caixa (vazia se nenhuma chega lá).
static func _faixa(caixas: Array[AABB], base: float) -> AABB:
	var faixa := AABB()
	var primeira := true
	for a in caixas:
		if a.end.y <= base:
			continue
		var corte := AABB(Vector3(a.position.x, maxf(a.position.y, base), a.position.z),
			Vector3(a.size.x, a.end.y - maxf(a.position.y, base), a.size.z))
		if primeira:
			faixa = corte
			primeira = false
		else:
			faixa = faixa.merge(corte)
	return faixa


## A janela do busto (rosto e peitoral): do alto da figura em pose (mais FOLGA_CIMA) para baixo, FRACAO_BUSTO da
## altura; quadrada; centrada (em x e z) nas partes da figura que entram nessa faixa — a cabeça e o peito, não os pés
## de quem dá um passo.
static func janela_busto(caixas: Array[AABB], c: AABB) -> AABB:
	var alto := c.size.y * FRACAO_BUSTO
	var base := c.end.y - alto
	var faixa := _faixa(caixas, base)
	if faixa.size == Vector3.ZERO:
		faixa = AABB(Vector3(c.position.x, base, c.position.z), Vector3(c.size.x, alto, c.size.z))
	var centro := faixa.get_center()
	var lado := alto + c.size.y * FOLGA_CIMA
	return AABB(Vector3(centro.x - lado * 0.5, base, centro.z - lado * 0.5), Vector3(lado, lado, lado))


## Enquadramento fixo: de pé, o BUSTO (rosto e peitoral, ver `janela_busto`); deitada (ou mais larga do que alta), o corpo
## inteiro. Tudo medido no CORPO da figura EM POSE (`caixas_do_corpo`: sem as armas e os adereços rígidos; B2).
## Sem nada visível (caixa zero), enquadra uma figura de recurso de 1 × 2 × 1 m assente na origem.
static func enquadrar(cam: Camera3D, copia: Node3D) -> void:
	var caixas := caixas_do_corpo(copia)
	var c := _juntar(caixas)
	if c.size == Vector3.ZERO:
		c = AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 2.0, 1.0))
		caixas.clear()
		caixas.append(c)
	var alvo := c.get_center()
	var raio := 0.5 * c.size.length()
	if de_pe(c, caixas):
		var j := janela_busto(caixas, c)
		alvo = j.get_center()
		raio = 0.5 * j.size.y * FOLGA_BUSTO
	var dist := raio / tan(deg_to_rad(FOV * 0.5)) * 1.05
	cam.fov = FOV
	var pos := alvo + DIRECAO_CAMARA.normalized() * dist
	cam.transform = Transform3D(Basis.looking_at(alvo - pos, Vector3.UP), pos)
	cam.near = maxf(0.01, dist - maxf(raio, 0.5 * c.size.length()) * 3.0)
	cam.far = dist + maxf(raio, 0.5 * c.size.length()) * 3.0


func _novo_palco(id: String) -> SubViewport:
	var sv := SubViewport.new()
	sv.name = "Retrato_" + id
	sv.size = Vector2i(TAMANHO, TAMANHO)
	sv.own_world_3d = true
	sv.transparent_bg = false
	sv.msaa_3d = Viewport.MSAA_4X
	sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var ambiente := WorldEnvironment.new()
	ambiente.name = "Ambiente"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = COR_FUNDO_PADRAO
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	ambiente.environment = env
	sv.add_child(ambiente)
	var luz := DirectionalLight3D.new()
	luz.name = "Luz"
	luz.rotation_degrees = Vector3(-40.0, 35.0, 0.0)
	luz.light_energy = 1.1
	sv.add_child(luz)
	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.current = true
	sv.add_child(cam)
	var palco := Node3D.new()
	palco.name = "Palco"
	sv.add_child(palco)
	return sv
