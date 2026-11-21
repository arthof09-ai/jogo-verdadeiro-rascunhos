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
## De onde a câmara olha (frente a três quartos, um pouco de cima) e a abertura.
const DIRECAO_CAMARA := Vector3(0.45, 0.22, 1.0)
const FOV := 28.0
## Figura de pé: o retrato é do busto (a parte de cima do corpo, esta fracção da altura).
const FRACAO_BUSTO := 0.62

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


## A caixa (no espaço do palco) das malhas visíveis da cópia.
static func caixa_visivel(no: Node3D) -> AABB:
	var caixa := AABB()
	var primeira := true
	for mi in _malhas_visiveis(no, Transform3D.IDENTITY, []):
		var a: AABB = mi[0] * (mi[1] as Mesh).get_aabb()
		if primeira:
			caixa = a
			primeira = false
		else:
			caixa = caixa.merge(a)
	return caixa


static func _malhas_visiveis(no: Node, pai: Transform3D, saida: Array) -> Array:
	var t := pai
	if no is Node3D:
		if not (no as Node3D).visible:
			return saida
		t = pai * (no as Node3D).transform
	if no is MeshInstance3D and (no as MeshInstance3D).mesh != null:
		saida.append([t, (no as MeshInstance3D).mesh])
	for c in no.get_children():
		_malhas_visiveis(c, t, saida)
	return saida


## Enquadramento fixo: de pé, o busto; deitada (ou mais larga do que alta), o corpo inteiro.
static func enquadrar(cam: Camera3D, copia: Node3D) -> void:
	var c := caixa_visivel(copia)
	if c.size == Vector3.ZERO:
		c = AABB(Vector3(-0.5, 0.0, -0.5), Vector3(1.0, 2.0, 1.0))
	var alvo := c.get_center()
	var alto := c.size.y
	var largo := maxf(c.size.x, c.size.z)
	var raio := 0.5 * c.size.length()
	if alto > largo * 1.2:
		var topo := c.end.y
		alto = c.size.y * FRACAO_BUSTO
		alvo.y = topo - alto * 0.5
		raio = 0.5 * Vector2(largo, alto).length()
	var dist := raio / tan(deg_to_rad(FOV * 0.5)) * 1.05
	cam.fov = FOV
	var pos := alvo + DIRECAO_CAMARA.normalized() * dist
	cam.transform = Transform3D(Basis.looking_at(alvo - pos, Vector3.UP), pos)
	cam.near = maxf(0.01, dist - raio * 3.0)
	cam.far = dist + raio * 3.0


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
