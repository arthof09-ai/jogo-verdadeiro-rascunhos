class_name AplicadorPerfil
extends Node
## aplicar_perfil.gd — Assimilação, missão V1.1 (Plano B v1.1). Dono: Claude (arte/).
##
## Aplica um perfil gráfico (Baixo / Médio / Alto) em tempo de execução, sem recarregar o
## jogo (aceite da V4.4). Os números são os de docs/orcamento-perfis.md e são ALVOS
## PROVISÓRIOS até a V4.4 medir no Redmi Note 10 Pro.
##
## Uso:
##   - como autoload (nome sugerido "Perfis"; o class_name não pode ser igual ao nome do
##     autoload), ou como nó filho da cena (a Clareira de prova faz assim);
##   - a ⚙ do HUD só tem de chamar aplicar(nome) com "baixo", "medio"/"médio" ou "alto"
##     (as chaves PERFIS do hud.gd). Este script não mexe no HUD.
##
## O que procura na árvore (por grupo):
##   "sol"            DirectionalLight3D: sombra ligada, modo, distância.
##   "ambiente"       WorldEnvironment: glow e SSAO.
##   "figura"         MeshInstance3D das figuras: o next_pass (contorno) liga ou desliga.
##   "folhagem"       GeometryInstance3D de folhagem: projeta sombra ou não.
##   "folhagem_densa" MultiMeshInstance3D: visible_instance_count = densidade × total.
##                    As instâncias têm de estar EMBARALHADAS na MultiMesh, porque só as
##                    primeiras N se desenham.
##
## APIs usadas, todas conferidas na referência de classes 4.7 (godotengine/godot, ramo 4.7,
## doc/classes): Viewport.msaa_3d / scaling_3d_mode / scaling_3d_scale / mesh_lod_threshold /
## positional_shadow_atlas_size; RenderingServer.directional_shadow_atlas_set_size(size,
## is_16bits) e directional_soft_shadow_filter_set_quality(quality);
## DirectionalLight3D.directional_shadow_mode / directional_shadow_max_distance;
## Light3D.shadow_enabled; Environment.glow_enabled / ssao_enabled;
## GeometryInstance3D.cast_shadow; MultiMesh.visible_instance_count;
## MeshInstance3D.get_active_material(); Material.next_pass.
##
## Porquê definir as sombras aqui, e não pelos overrides ".mobile" do projeto: no export WEB
## aberto no celular, a tag "mobile" NÃO existe (doc "Feature tags": OS.has_feature("mobile")
## dá false na web, mesmo num celular). Por isso directional_shadow/size.mobile e
## soft_shadow_filter_quality.mobile não se aplicam no link do Mestre.

signal perfil_aplicado(nome: String)

const GRUPO_SOL := &"sol"
const GRUPO_AMBIENTE := &"ambiente"
const GRUPO_FIGURA := &"figura"
const GRUPO_FOLHAGEM := &"folhagem"
const GRUPO_FOLHAGEM_DENSA := &"folhagem_densa"

## PROVISÓRIO (alvos; ver docs/orcamento-perfis.md). Uma chave em falta usa o valor do Médio.
const PERFIS: Dictionary = {
	"baixo": {
		"escala_3d": 0.5,
		"msaa_3d": Viewport.MSAA_DISABLED,
		"lod_limiar_px": 4.0,
		"sombra_sol": false,
		"sombra_modo": DirectionalLight3D.SHADOW_ORTHOGONAL,
		"sombra_atlas": 1024,
		"sombra_distancia": 40.0,
		"sombra_filtro": RenderingServer.SHADOW_QUALITY_HARD,
		"contorno": false,
		"glow": false,
		"ssao": false,
		"folhagem_densidade": 0.5,
		"folhagem_sombra": false,
	},
	"medio": {
		"escala_3d": 0.67,
		"msaa_3d": Viewport.MSAA_2X,
		"lod_limiar_px": 2.0,
		"sombra_sol": true,
		"sombra_modo": DirectionalLight3D.SHADOW_ORTHOGONAL,
		"sombra_atlas": 2048,
		"sombra_distancia": 45.0,
		"sombra_filtro": RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW,
		"contorno": true,
		"glow": false,
		"ssao": false,
		"folhagem_densidade": 0.75,
		"folhagem_sombra": true,
	},
	"alto": {
		"escala_3d": 1.0,
		"msaa_3d": Viewport.MSAA_4X,
		"lod_limiar_px": 1.0,
		"sombra_sol": true,
		"sombra_modo": DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,
		"sombra_atlas": 4096,
		"sombra_distancia": 60.0,
		"sombra_filtro": RenderingServer.SHADOW_QUALITY_SOFT_LOW,
		"contorno": true,
		"glow": true,
		"ssao": true,
		"folhagem_densidade": 1.0,
		"folhagem_sombra": true,
	},
}

## Substitui a tabela PERFIS sem mexer no código (por exemplo, a V4.4 carrega os números
## medidos). Mesmo formato: { "baixo": {...}, "medio": {...}, "alto": {...} }.
@export var tabela: Dictionary = {}
## Perfil aplicado no _ready (vazio = não aplica sozinho).
@export var perfil_inicial: String = ""

var atual: String = ""
## Material base -> Material do contorno guardado (para religar depois de desligar).
var _contornos: Dictionary = {}


func _ready() -> void:
	_avisar_vertex_shading()
	if perfil_inicial != "":
		aplicar(perfil_inicial)


## Interface da ⚙: aplica "baixo", "medio" (ou "médio") ou "alto". Devolve false se o
## nome não existe.
func aplicar(nome: String) -> bool:
	if not is_inside_tree():
		push_warning("[perfis] aplicar() chamado fora da árvore; ignorado.")
		return false
	var chave := normalizar(nome)
	var fonte: Dictionary = tabela if not tabela.is_empty() else PERFIS
	if not fonte.has(chave):
		push_warning("[perfis] perfil desconhecido: %s" % nome)
		return false
	var cfg: Dictionary = (PERFIS["medio"] as Dictionary).duplicate()
	cfg.merge(fonte[chave] as Dictionary, true)
	aplicar_dicionario(cfg)
	atual = chave
	perfil_aplicado.emit(chave)
	return true


## Reaplica o perfil atual (chamar depois de pôr figuras ou folhagem novas na cena).
func atualizar() -> void:
	if atual != "":
		aplicar(atual)


## Guarda à mão o par base -> contorno (para figuras fora do grupo "figura").
func registrar_contorno(base: Material, contorno: Material) -> void:
	if base != null and contorno != null:
		_contornos[base] = contorno


static func normalizar(nome: String) -> String:
	return nome.strip_edges().to_lower().replace("é", "e")


func aplicar_dicionario(cfg: Dictionary) -> void:
	_aplicar_viewport(cfg)
	_aplicar_sombras(cfg)
	_aplicar_ambiente(cfg)
	_aplicar_contorno(bool(cfg.get("contorno", true)))
	_aplicar_folhagem(float(cfg.get("folhagem_densidade", 1.0)), bool(cfg.get("folhagem_sombra", true)))


func _aplicar_viewport(cfg: Dictionary) -> void:
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	# Compatibility: só bilinear (o FSR cai para bilinear fora do Forward+; doc ProjectSettings).
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	vp.scaling_3d_scale = clampf(float(cfg.get("escala_3d", 1.0)), 0.25, 2.0)
	vp.msaa_3d = int(cfg.get("msaa_3d", Viewport.MSAA_DISABLED)) as Viewport.MSAA
	vp.mesh_lod_threshold = float(cfg.get("lod_limiar_px", 1.0))
	# Tochas sem sombra em todos os perfis (B2.2): o atlas de sombras posicionais não é preciso.
	vp.positional_shadow_atlas_size = 0


func _aplicar_sombras(cfg: Dictionary) -> void:
	var ligada := bool(cfg.get("sombra_sol", true))
	if ligada:
		# 16 bits: o padrão do projeto (directional_shadow/16_bits = true).
		RenderingServer.directional_shadow_atlas_set_size(int(cfg.get("sombra_atlas", 2048)), true)
		RenderingServer.directional_soft_shadow_filter_set_quality(
				int(cfg.get("sombra_filtro", RenderingServer.SHADOW_QUALITY_HARD)) as RenderingServer.ShadowQuality)
	for n in get_tree().get_nodes_in_group(GRUPO_SOL):
		var sol := n as DirectionalLight3D
		if sol == null:
			continue
		sol.shadow_enabled = ligada
		sol.directional_shadow_mode = int(cfg.get("sombra_modo", DirectionalLight3D.SHADOW_ORTHOGONAL)) as DirectionalLight3D.ShadowMode
		sol.directional_shadow_max_distance = float(cfg.get("sombra_distancia", 45.0))


func _aplicar_ambiente(cfg: Dictionary) -> void:
	for n in get_tree().get_nodes_in_group(GRUPO_AMBIENTE):
		var we := n as WorldEnvironment
		if we == null or we.environment == null:
			continue
		# Compatibility: o glow usa outra implementação (glow_levels sem efeito, mistura sempre
		# SCREEN) e o buffer é RGBA8 LDR: o limiar tem de ficar abaixo de 1 (doc Environment).
		we.environment.glow_enabled = bool(cfg.get("glow", false))
		# SSAO existe no Compatibility 4.7 (doc Environment: "Forward+ and Compatibility").
		we.environment.ssao_enabled = bool(cfg.get("ssao", false))


func _aplicar_contorno(ligado: bool) -> void:
	for n in get_tree().get_nodes_in_group(GRUPO_FIGURA):
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var m: Material = mi.get_active_material(i)
			if m != null and m.next_pass != null and not _contornos.has(m):
				_contornos[m] = m.next_pass
	for base in _contornos:
		var mat := base as Material
		if mat != null:
			mat.next_pass = (_contornos[base] as Material) if ligado else null


func _aplicar_folhagem(densidade: float, sombra: bool) -> void:
	var d := clampf(densidade, 0.0, 1.0)
	for n in get_tree().get_nodes_in_group(GRUPO_FOLHAGEM_DENSA):
		var mmi := n as MultiMeshInstance3D
		if mmi == null or mmi.multimesh == null:
			continue
		var mm: MultiMesh = mmi.multimesh
		mm.visible_instance_count = -1 if d >= 0.999 else int(round(mm.instance_count * d))
	var modo: GeometryInstance3D.ShadowCastingSetting = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if sombra:
		modo = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for n in get_tree().get_nodes_in_group(GRUPO_FOLHAGEM):
		var gi := n as GeometryInstance3D
		if gi != null:
			gi.cast_shadow = modo


## Com Force Vertex Shading ligado o light() não corre (doc do spatial shader) e a sombra
## colorida some. O padrão na 4.7 é false e não há variante .mobile (referência ProjectSettings).
func _avisar_vertex_shading() -> void:
	if bool(ProjectSettings.get_setting("rendering/shading/overrides/force_vertex_shading", false)):
		push_warning("[perfis] force_vertex_shading está ligado: o light() do kit não corre. Desligue no project.godot.")
