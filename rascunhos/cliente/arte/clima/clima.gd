extends Node3D
## clima.gd — Ordem 40. O SISTEMA DE CLIMA da arena: chuva e neve a caírem com vento, o chão e as figuras a
## responderem. É um módulo: um nó que a cena liga (a arena da jogadora e a do Mestre ligam-no hoje; o mapa
## da cadeia liga-o da mesma maneira). Ver arte/clima/README.md.
##
## SÓ APRESENTAÇÃO (princípio do cliente: nunca calcula regra). O clima não lê o ROOM_SNAPSHOT nem as
## ROOM_OPTIONS, não muda casas, custos, alvos nem alturas de jogo, e não decide o tempo a partir do estado do
## jogo: ligar/desligar, intensidade e vento são parâmetros de apresentação, como os perfis gráficos.
##
## Uso (3 passos):
##   var clima := Clima.new(); add_child(clima)             # filho da cena da arena
##   clima.configurar_area(centro, tamanho)                 # o campo a cobrir (m)
##   clima.definir("neve", "forte")                         # "nenhum" | "chuva" | "neve"  ×  "fraco" | "forte"
## e pôr o chão no grupo "clima_chao" e os corpos das figuras no grupo "clima_figura" (ou chamar
## registar_chao / registar_figura). O Clima põe-lhes um material_overlay — não troca material nenhum.
##
## Custo: as partículas são MultiMesh com a conta toda no vértice (zero trabalho por partícula na CPU; por
## frame a CPU soma 7 acumuladores). Desligado e seco, o nó não processa e não desenha nada.

signal clima_mudou(tipo: String, intensidade: String)

const Integrador := preload("res://arte/clima/integrador_vento.gd")
const SH_FLOCOS: Shader = preload("res://arte/clima/neve_flocos.gdshader")
const SH_GOTAS: Shader = preload("res://arte/clima/chuva_gotas.gdshader")
const SH_SALPICOS: Shader = preload("res://arte/clima/chuva_salpicos.gdshader")
const SH_CHAO: Shader = preload("res://arte/clima/clima_chao.gdshader")
const SH_FIGURA: Shader = preload("res://arte/clima/clima_figura.gdshader")

const GRUPO_CHAO := &"clima_chao"
const GRUPO_FIGURA := &"clima_figura"
const TIPOS: Array[String] = ["nenhum", "chuva", "neve"]
const INTENSIDADES: Array[String] = ["fraco", "forte"]
const PERFIS: Array[String] = ["baixo", "medio", "alto"]

## Quantas partículas por clima, intensidade e perfil gráfico (Baixo / Médio / Alto).
const CONTAGEM := {
	"chuva": {
		"fraco": {"baixo": 900, "medio": 1600, "alto": 2400},
		"forte": {"baixo": 2800, "medio": 5000, "alto": 8000},
	},
	"neve": {
		"fraco": {"baixo": 1000, "medio": 2000, "alto": 3000},
		"forte": {"baixo": 3000, "medio": 6000, "alto": 9000},
	},
	"salpicos": {
		"fraco": {"baixo": 0, "medio": 120, "alto": 200},
		"forte": {"baixo": 0, "medio": 350, "alto": 600},
	},
}
## Velocidade de queda (m/s).
const QUEDA := {"chuva": {"fraco": 11.0, "forte": 15.0}, "neve": {"fraco": 1.2, "forte": 1.8}}
## Quantos pingos no chão (0..1) e a força do bater (0..1).
const PINGOS := {"fraco": 0.30, "forte": 1.0}
const FORCA_PINGO := {"fraco": 0.30, "forte": 0.95}
## Balanço lateral dos flocos (m/s); a chuva quase não balança.
const BALANCO := {"chuva": 0.04, "neve": 0.32}
const SEMENTE_CHUVA := 4001
const SEMENTE_NEVE := 4085

## Para onde o vento sopra, em graus à volta do Y: 0 = +X (leste), 90 = +Z (sul). Um só vento para os dois climas.
@export var vento_direcao_graus: float = 20.0
## Força do vento (m/s).
@export var vento_forca: float = 2.5
## 0..1: quanto a força e o rumo do vento oscilam sozinhos no tempo (rajadas).
@export_range(0.0, 1.0) var rajadas: float = 0.25
## Altura da coluna de clima acima do chão (m) e folga para lá das bordas do campo (m).
@export var altura_m: float = 12.0
@export var margem_m: float = 4.0
## Segundos de chuva até o chão estar todo molhado, e de neve até o chão estar todo branco.
@export var segundos_molhar := {"fraco": 24.0, "forte": 9.0}
@export var segundos_nevar := {"fraco": 150.0, "forte": 45.0}
## Segundos para secar / derreter depois de o clima parar.
@export var segundos_secar: float = 40.0
@export var segundos_derreter: float = 60.0
## Segundos para as partículas entrarem ou saírem quando o clima ou a intensidade mudam.
@export var segundos_transicao: float = 1.5
## Cor do céu que o molhado reflecte (céu encoberto claro; não é o fundo da cena).
@export var cor_reflexo := Color(0.72, 0.80, 0.88)
## A raiz onde se procuram os grupos "clima_chao" e "clima_figura" e o sol (vazio = o pai deste nó).
@export var raiz_alvos: NodePath

var tipo := "nenhum"
var intensidade := "fraco"
var perfil := "medio"
## Estado visual acumulado (0..1): o chão molhado e a neve pousada.
var molhado := 0.0
var neve := 0.0

var _centro := Vector3(15.0, 0.0, 15.0)
var _tamanho := Vector2(30.0, 30.0)
var _grelha_origem := Vector3.ZERO
var _grelha_casa := 0.0
var _tempo := 0.0
var _integ_chuva := Integrador.new()
var _integ_neve := Integrador.new()
var _chuva: MultiMeshInstance3D
var _flocos: MultiMeshInstance3D
var _salpicos: MultiMeshInstance3D
var _mat_chuva: ShaderMaterial
var _mat_flocos: ShaderMaterial
var _mat_salpicos: ShaderMaterial
var _mat_chao: ShaderMaterial
var _mat_figura: ShaderMaterial
var _n_chuva := 0.0
var _n_flocos := 0.0
var _n_salpicos := 0.0
var _vestidos: Dictionary = {}  # instance_id -> WeakRef dos nós a que este Clima pôs o overlay
var _manuais_chao: Array[WeakRef] = []
var _manuais_figura: Array[WeakRef] = []
var _ate_procurar := 0.0
var _sol: DirectionalLight3D


func _ready() -> void:
	set_process(false)
	_ler_linha_de_comando()


# ---------------------------------------------------------------- API

## O campo a cobrir: centro (no chão) e tamanho (x, z) em metros. O clima cobre o campo inteiro mais a folga.
func configurar_area(centro: Vector3, tamanho: Vector2) -> void:
	_centro = centro
	_tamanho = Vector2(maxf(tamanho.x, 1.0), maxf(tamanho.y, 1.0))
	var caixa := caixa_tamanho()
	_integ_chuva.definir_caixa(caixa)
	_integ_neve.definir_caixa(caixa)
	_ajustar_caixas()


## A grelha táctica (opcional): a neve fica rala ao longo das linhas, para a grelha continuar a ler-se.
func definir_grelha(origem: Vector3, casa_m: float) -> void:
	_grelha_origem = origem
	_grelha_casa = maxf(casa_m, 0.0)


## Liga, troca ou desliga o clima sem reiniciar a cena. Devolve false se os nomes não existem.
func definir(novo_tipo: String, nova_intensidade: String = "") -> bool:
	var t := novo_tipo.strip_edges().to_lower()
	var i := nova_intensidade.strip_edges().to_lower() if nova_intensidade != "" else intensidade
	if not TIPOS.has(t) or not INTENSIDADES.has(i):
		push_warning("[clima] clima desconhecido: %s %s" % [novo_tipo, nova_intensidade])
		return false
	var mudou := t != tipo or i != intensidade
	tipo = t
	intensidade = i
	if tipo != "nenhum":
		set_process(true)
	if mudou:
		clima_mudou.emit(tipo, intensidade)
	return true


## "nenhum", "chuva-fraca", "chuva-forte", "neve-fraca", "neve-forte" (também "chuva fraco", "neve:forte"…).
func definir_por_nome(nome: String) -> bool:
	var n := nome.strip_edges().to_lower().replace("_", "-").replace(" ", "-").replace(":", "-")
	if n == "" or n == "nenhum" or n == "sem-clima" or n == "desligado":
		return definir("nenhum")
	var partes := n.split("-", false)
	var t: String = partes[0]
	var i := intensidade
	if partes.size() > 1:
		i = "forte" if str(partes[1]).begins_with("fort") else ("fraco" if str(partes[1]).begins_with("frac") else str(partes[1]))
	return definir(t, i)


func desligar() -> void:
	definir("nenhum")


## O mesmo vento para a chuva e para a neve. Mudar o vento só muda o que os flocos andam DAQUI para a frente.
func definir_vento(direcao_graus: float, forca_m_s: float) -> void:
	vento_direcao_graus = direcao_graus
	vento_forca = maxf(forca_m_s, 0.0)


## O perfil gráfico da casa ("baixo", "medio"/"médio", "alto"): muda as contagens sem reiniciar.
## Liga-se ao sinal do AplicadorPerfil: perfis.perfil_aplicado.connect(clima.definir_perfil).
func definir_perfil(nome: String) -> void:
	var p := nome.strip_edges().to_lower().replace("é", "e")
	if PERFIS.has(p):
		perfil = p


## Põe o estado acumulado à mão (0..1): para capturas, ou para abrir uma cena já molhada / já nevada.
func definir_acumulacao(novo_molhado: float, nova_neve: float) -> void:
	molhado = clampf(novo_molhado, 0.0, 1.0)
	neve = clampf(nova_neve, 0.0, 1.0)
	if molhado > 0.0 or neve > 0.0:
		set_process(true)
	_vestir_alvos()
	_empurrar_uniformes()


## Chão ou figura fora dos grupos (a raiz e os MeshInstance3D debaixo dela).
func registar_chao(no: Node) -> void:
	_manuais_chao.append(weakref(no))


func registar_figura(no: Node) -> void:
	_manuais_figura.append(weakref(no))


## Quantas partículas o clima pedido desenha neste perfil (o alvo; a transição chega lá em ~1,5 s).
func contagem_alvo(qual: String) -> int:
	if qual == "chuva" or qual == "salpicos":
		return int(CONTAGEM[qual][intensidade][perfil]) if tipo == "chuva" else 0
	if qual == "neve":
		return int(CONTAGEM["neve"][intensidade][perfil]) if tipo == "neve" else 0
	return 0


## Quantas se desenham AGORA.
func contagem_atual(qual: String) -> int:
	match qual:
		"chuva":
			return int(_n_chuva)
		"neve":
			return int(_n_flocos)
		"salpicos":
			return int(_n_salpicos)
	return 0


## O vento deste frame (m/s no chão: x, z), já com as rajadas.
func vento_do_frame() -> Vector2:
	var forca := vento_forca
	var rumo := deg_to_rad(vento_direcao_graus)
	if rajadas > 0.0:
		forca *= 1.0 + rajadas * (0.6 * sin(0.37 * _tempo) + 0.4 * sin(0.83 * _tempo + 1.3))
		rumo += deg_to_rad(10.0) * rajadas * sin(0.21 * _tempo + 0.5)
	return Vector2(cos(rumo), sin(rumo)) * maxf(forca, 0.0)


func caixa_minimo() -> Vector3:
	return Vector3(_centro.x - _tamanho.x * 0.5 - margem_m, _centro.y, _centro.z - _tamanho.y * 0.5 - margem_m)


func caixa_tamanho() -> Vector3:
	return Vector3(_tamanho.x + 2.0 * margem_m, altura_m, _tamanho.y + 2.0 * margem_m)


## Verdadeiro se não há nada a cair nem nada pousado (o nó dorme).
func parado() -> bool:
	return tipo == "nenhum" and molhado <= 0.0 and neve <= 0.0 and _n_chuva <= 0.0 and _n_flocos <= 0.0 and _n_salpicos <= 0.0


## Os nós que têm hoje o overlay deste Clima (para os testes).
func vestidos() -> Array[Node]:
	var r: Array[Node] = []
	for id in _vestidos:
		var no = (_vestidos[id] as WeakRef).get_ref()
		if no != null:
			r.append(no)
	return r


# ---------------------------------------------------------------- frame a frame

func _process(delta: float) -> void:
	avancar(delta)


## Um frame do clima (o _process chama-o; os testes também, sem janela).
func avancar(delta: float) -> void:
	var dt := clampf(delta, 0.0, Integrador.DT_MAXIMO)
	_tempo += dt
	var vento := vento_do_frame()

	# Quantas partículas: sobem e descem até ao alvo, sem estalo.
	var passo := dt / maxf(segundos_transicao, 0.01)
	_n_chuva = move_toward(_n_chuva, float(contagem_alvo("chuva")), passo * float(CONTAGEM["chuva"]["forte"][perfil]))
	_n_flocos = move_toward(_n_flocos, float(contagem_alvo("neve")), passo * float(CONTAGEM["neve"]["forte"][perfil]))
	_n_salpicos = move_toward(_n_salpicos, float(contagem_alvo("salpicos")), passo * maxf(float(CONTAGEM["salpicos"]["forte"][perfil]), 1.0))

	# O deslocamento, integrado frame a frame com o vento DESTE frame (integrador_vento.gd).
	if _n_chuva > 0.0:
		_integ_chuva.avancar(dt, vento, float(QUEDA["chuva"][intensidade]), float(BALANCO["chuva"]))
	if _n_flocos > 0.0:
		_integ_neve.avancar(dt, vento, float(QUEDA["neve"][intensidade]), float(BALANCO["neve"]))

	# O que fica pousado: a chuva molha (e derrete a neve); a neve acumula (e o molhado seca).
	match tipo:
		"chuva":
			molhado = minf(1.0, molhado + dt / maxf(float(segundos_molhar[intensidade]), 0.01))
			neve = maxf(0.0, neve - 2.0 * dt / maxf(segundos_derreter, 0.01))
		"neve":
			neve = minf(1.0, neve + dt / maxf(float(segundos_nevar[intensidade]), 0.01))
			molhado = maxf(0.0, molhado - dt / maxf(segundos_secar, 0.01))
		_:
			molhado = maxf(0.0, molhado - dt / maxf(segundos_secar, 0.01))
			neve = maxf(0.0, neve - dt / maxf(segundos_derreter, 0.01))

	_ate_procurar -= dt
	if _ate_procurar <= 0.0:
		_ate_procurar = 0.5
		_vestir_alvos()
	_atualizar_particulas()
	_empurrar_uniformes()

	if parado():
		_despir_tudo()
		set_process(false)


# ---------------------------------------------------------------- partículas

func _atualizar_particulas() -> void:
	if _n_chuva > 0.0 and _chuva == null:
		_mat_chuva = _material(SH_GOTAS, 20)
		_chuva = _criar_nuvem("Chuva", _mat_chuva, int(CONTAGEM["chuva"]["forte"]["alto"]), SEMENTE_CHUVA, false, Vector2(1.0, 1.0))
	if _n_flocos > 0.0 and _flocos == null:
		_mat_flocos = _material(SH_FLOCOS, 20)
		_flocos = _criar_nuvem("Neve", _mat_flocos, int(CONTAGEM["neve"]["forte"]["alto"]), SEMENTE_NEVE, true, Vector2(1.0, 1.0))
	if _n_salpicos > 0.0 and _salpicos == null:
		_mat_salpicos = _material(SH_SALPICOS, 19)
		_salpicos = _criar_salpicos(int(CONTAGEM["salpicos"]["forte"]["alto"]))
	_mostrar(_chuva, _n_chuva)
	_mostrar(_flocos, _n_flocos)
	_mostrar(_salpicos, _n_salpicos)


func _mostrar(nuvem: MultiMeshInstance3D, n: float) -> void:
	if nuvem == null:
		return
	var quantos := mini(int(n), nuvem.multimesh.instance_count)
	nuvem.visible = quantos > 0
	nuvem.multimesh.visible_instance_count = quantos


func _material(shader: Shader, prioridade: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	# As partículas desenham-se depois dos outros transparentes (destaques, anéis); o chão molhado, antes.
	m.render_priority = prioridade
	return m


## Uma MultiMesh de cartões: a origem de cada instância é a base do floco (fracções 0..1 da caixa) e o
## INSTANCE_CUSTOM leva os pesos. As instâncias são sorteadas, por isso «as primeiras N» são uma amostra justa.
func _criar_nuvem(nome: String, material: ShaderMaterial, maximo: int, semente: int, com_balanco: bool, tamanho_quad: Vector2) -> MultiMeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = tamanho_quad
	quad.material = material
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = maximo
	var s := Integrador.sortear(maximo, semente, com_balanco)
	var bases: PackedVector3Array = s["bases"]
	var ks: PackedInt32Array = s["k"]
	var ws: Array[Vector3i] = s["w"]
	var ls: Array[Vector3i] = s["l"]
	var rs: PackedInt32Array = s["r"]
	for i in maximo:
		mm.set_instance_transform(i, Transform3D(Basis(), bases[i]))
		mm.set_instance_custom_data(i, Integrador.empacotar(ks[i], ws[i], ls[i], rs[i]))
	mm.visible_instance_count = 0
	return _por_nuvem(nome, mm)


func _criar_salpicos(maximo: int) -> MultiMeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	quad.material = _mat_salpicos
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = maximo
	for i in maximo:
		mm.set_instance_transform(i, Transform3D())
		mm.set_instance_custom_data(i, Color(float(i + 1), 0.0, 0.0, 0.0))
	mm.visible_instance_count = 0
	return _por_nuvem("Salpicos", mm)


func _por_nuvem(nome: String, mm: MultiMesh) -> MultiMeshInstance3D:
	var no := MultiMeshInstance3D.new()
	no.name = nome
	no.multimesh = mm
	no.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	no.top_level = true  # as contas são no mundo: o nó não herda a transformação de ninguém
	add_child(no)
	no.global_transform = Transform3D.IDENTITY
	_ajustar_caixa_de(no)
	return no


func _ajustar_caixas() -> void:
	for no in [_chuva, _flocos, _salpicos]:
		if no != null:
			_ajustar_caixa_de(no)


## As instâncias guardam fracções, não posições: a caixa de recorte tem de ser dita à mão.
func _ajustar_caixa_de(no: MultiMeshInstance3D) -> void:
	no.custom_aabb = AABB(caixa_minimo() - Vector3(1.0, 1.0, 1.0), caixa_tamanho() + Vector3(2.0, 2.0, 2.0))


# ---------------------------------------------------------------- chão e figuras

func _raiz() -> Node:
	if not raiz_alvos.is_empty() and has_node(raiz_alvos):
		return get_node(raiz_alvos)
	return get_parent()


func _vestir_alvos() -> void:
	if not is_inside_tree():
		return
	var raiz := _raiz()
	if raiz == null:
		return
	var precisa := molhado > 0.0 or neve > 0.0 or tipo != "nenhum"
	if not precisa:
		return
	if _mat_chao == null:
		_mat_chao = _material(SH_CHAO, -20)
		_mat_figura = _material(SH_FIGURA, 0)
	var vistos := {}
	for n in get_tree().get_nodes_in_group(GRUPO_CHAO):
		if raiz == n or raiz.is_ancestor_of(n):
			_vestir(n, _mat_chao, vistos, false)
	for n in get_tree().get_nodes_in_group(GRUPO_FIGURA):
		if raiz == n or raiz.is_ancestor_of(n):
			_vestir(n, _mat_figura, vistos, true)
	_vestir_manuais(_manuais_chao, _mat_chao, vistos, false)
	_vestir_manuais(_manuais_figura, _mat_figura, vistos, true)
	# Quem saiu da cena (ou morreu) sai da lista.
	for id in _vestidos.keys():
		if not vistos.has(id):
			var no = (_vestidos[id] as WeakRef).get_ref()
			if no != null and (no as GeometryInstance3D).material_overlay in [_mat_chao, _mat_figura]:
				(no as GeometryInstance3D).material_overlay = null
			_vestidos.erase(id)
	if _sol == null or not is_instance_valid(_sol):
		_sol = _achar_sol(raiz)


func _vestir_manuais(lista: Array[WeakRef], material: ShaderMaterial, vistos: Dictionary, e_figura: bool) -> void:
	for i in range(lista.size() - 1, -1, -1):
		var no = lista[i].get_ref()
		if no == null:
			lista.remove_at(i)
		else:
			_vestir(no, material, vistos, e_figura)


## Põe o overlay no nó e nos MeshInstance3D debaixo dele. Nas figuras saltam-se os enfeites sem luz (o anel
## e a sombra de contacto do marcador): a neve e o molhado são para o corpo.
func _vestir(no: Node, material: ShaderMaterial, vistos: Dictionary, e_figura: bool) -> void:
	var mi := no as MeshInstance3D
	if mi != null and mi.mesh != null and not (e_figura and _sem_luz(mi)):
		var id := mi.get_instance_id()
		if mi.material_overlay == null or mi.material_overlay == material:
			mi.material_overlay = material
			_vestidos[id] = weakref(mi)
			vistos[id] = true
	for f in no.get_children():
		if f is Node3D and not (f is Label3D):
			_vestir(f, material, vistos, e_figura)


func _sem_luz(mi: MeshInstance3D) -> bool:
	if mi.mesh.get_surface_count() == 0:
		return true
	var m := mi.get_active_material(0) as BaseMaterial3D
	return m != null and m.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED


func _despir_tudo() -> void:
	for id in _vestidos:
		var no = (_vestidos[id] as WeakRef).get_ref()
		if no != null and (no as GeometryInstance3D).material_overlay in [_mat_chao, _mat_figura]:
			(no as GeometryInstance3D).material_overlay = null
	_vestidos.clear()
	for nuvem in [_chuva, _flocos, _salpicos]:
		if nuvem != null:
			nuvem.visible = false


func _achar_sol(raiz: Node) -> DirectionalLight3D:
	for n in get_tree().get_nodes_in_group(&"sol"):
		if n is DirectionalLight3D and (raiz == n or raiz.is_ancestor_of(n)):
			return n
	for n in raiz.get_children():
		if n is DirectionalLight3D:
			return n
	return null


# ---------------------------------------------------------------- uniformes

func _empurrar_uniformes() -> void:
	var cmin := caixa_minimo()
	var ctam := caixa_tamanho()
	if _mat_chuva != null and _n_chuva > 0.0:
		_empurrar_nuvem(_mat_chuva, _integ_chuva, cmin, ctam)
	if _mat_flocos != null and _n_flocos > 0.0:
		_empurrar_nuvem(_mat_flocos, _integ_neve, cmin, ctam)
	if _mat_salpicos != null and _n_salpicos > 0.0:
		_mat_salpicos.set_shader_parameter(&"caixa_min", Vector3(cmin.x + margem_m, cmin.y, cmin.z + margem_m))
		_mat_salpicos.set_shader_parameter(&"caixa_tam", Vector3(_tamanho.x, ctam.y, _tamanho.y))
		_mat_salpicos.set_shader_parameter(&"chao_y", _centro.y + 0.02)
		_mat_salpicos.set_shader_parameter(&"tempo", _tempo)
		_mat_salpicos.set_shader_parameter(&"forca", float(FORCA_PINGO[intensidade]))
	if _mat_chao == null:
		return
	var luz_dir := Vector3(0.4, 0.8, 0.45).normalized()
	var luz_cor := Color(1.0, 0.95, 0.85)
	if _sol != null and is_instance_valid(_sol):
		luz_dir = _sol.global_transform.basis.z.normalized()  # a luz viaja em −Z: o sol está em +Z
		luz_cor = _sol.light_color
	# Os pingos acompanham a chuva que está de facto a cair (entram e saem com ela).
	var cheio := float(CONTAGEM["chuva"][intensidade][perfil])
	var a_cair := clampf(_n_chuva / maxf(cheio, 1.0), 0.0, 1.0) if tipo == "chuva" else clampf(_n_chuva / maxf(float(CONTAGEM["chuva"]["forte"][perfil]), 1.0), 0.0, 1.0)
	_mat_chao.set_shader_parameter(&"molhado", molhado)
	_mat_chao.set_shader_parameter(&"neve", neve)
	_mat_chao.set_shader_parameter(&"pingos", float(PINGOS[intensidade]) * a_cair)
	_mat_chao.set_shader_parameter(&"forca_pingo", float(FORCA_PINGO[intensidade]))
	_mat_chao.set_shader_parameter(&"tempo", _tempo)
	_mat_chao.set_shader_parameter(&"luz_dir", luz_dir)
	_mat_chao.set_shader_parameter(&"luz_cor", luz_cor)
	_mat_chao.set_shader_parameter(&"cor_reflexo", cor_reflexo)
	_mat_chao.set_shader_parameter(&"grelha_origem", _grelha_origem)
	_mat_chao.set_shader_parameter(&"grelha_casa_m", _grelha_casa)
	_mat_chao.set_shader_parameter(&"qualidade", 0 if perfil == "baixo" else 1)
	_mat_figura.set_shader_parameter(&"molhado", molhado)
	_mat_figura.set_shader_parameter(&"neve", neve)
	_mat_figura.set_shader_parameter(&"luz_dir", luz_dir)
	_mat_figura.set_shader_parameter(&"luz_cor", luz_cor)
	_mat_figura.set_shader_parameter(&"cor_reflexo", cor_reflexo)


func _empurrar_nuvem(m: ShaderMaterial, integ: Integrador, cmin: Vector3, ctam: Vector3) -> void:
	m.set_shader_parameter(&"caixa_min", cmin)
	m.set_shader_parameter(&"caixa_tam", ctam)
	m.set_shader_parameter(&"d_queda", integ.d_queda)
	m.set_shader_parameter(&"d_vento", integ.d_vento)
	m.set_shader_parameter(&"d_lado", integ.d_lado)
	m.set_shader_parameter(&"v_queda", integ.v_queda)
	m.set_shader_parameter(&"v_vento", integ.v_vento)


# ---------------------------------------------------------------- bancada

## Parâmetros de apresentação pela linha de comando (bancada e capturas):
##   godot --path cliente -- --clima=neve-forte --vento=30,3.5
func _ler_linha_de_comando() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--clima="):
			definir_por_nome(a.trim_prefix("--clima="))
		elif a.begins_with("--vento="):
			var p := a.trim_prefix("--vento=").split(",")
			if p.size() == 2 and p[0].is_valid_float() and p[1].is_valid_float():
				definir_vento(float(p[0]), float(p[1]))
