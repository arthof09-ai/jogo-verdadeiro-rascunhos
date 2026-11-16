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
##
## ORDEM 41 — O CLIMA FORTE A SÉRIO (no mesmo módulo; os climas fracos ficam como eram):
##   NEVE FORTE = NEVASCA: o vento ganha rajadas legíveis (força e rumo), a neve AGLOMERA-SE (cantos, bordas,
##     base e sotavento dos obstáculos; o centro fica varrido), as superfícies GELAM com a exposição e ao
##     longe o campo fecha-se num véu. Os obstáculos entram pelo grupo "clima_obstaculo".
##   CHUVA FORTE = ALAGA: com o chão encharcado, a água junta-se nos pontos baixos (as BACIAS — as do mapa
##     entram por definir_bacias()), as bolsas nascem pequenas e crescem, com LAMA à volta; desligada a
##     chuva, as bolsas escoam, a lama perde o brilho e seca.
##   Continua a ser só apresentação: nada disto muda casas, custos, alturas de jogo nem estado.

signal clima_mudou(tipo: String, intensidade: String)

const Integrador := preload("res://arte/clima/integrador_vento.gd")
const SH_FLOCOS: Shader = preload("res://arte/clima/neve_flocos.gdshader")
const SH_GOTAS: Shader = preload("res://arte/clima/chuva_gotas.gdshader")
const SH_SALPICOS: Shader = preload("res://arte/clima/chuva_salpicos.gdshader")
const SH_CHAO: Shader = preload("res://arte/clima/clima_chao.gdshader")
const SH_FIGURA: Shader = preload("res://arte/clima/clima_figura.gdshader")

const GRUPO_CHAO := &"clima_chao"
const GRUPO_FIGURA := &"clima_figura"
## Ordem 41: os obstáculos do campo (pedras, muros, troncos). A neve da nevasca junta-se contra eles e a
## sotavento deles, e eles próprios ganham neve e gelo (a mesma camada das figuras).
const GRUPO_OBSTACULO := &"clima_obstaculo"
const MAX_BACIAS := 8
const MAX_ABRIGOS := 8
const MAX_PES := 8
## Espelhos de clima_terreno.gdshaderinc (CLIMA_ENCHE, CLIMA_MARGEM_LAMA).
const ENCHE := 0.86
const MARGEM_LAMA := 0.12
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
## Ordem 41: o véu da nevasca — cartões grandes e ténues que só se vêem ao longe. Só na neve forte.
const VEU := {"baixo": 0, "medio": 140, "alto": 260}
## Velocidade de queda (m/s).
const QUEDA := {"chuva": {"fraco": 11.0, "forte": 15.0}, "neve": {"fraco": 1.2, "forte": 1.8}}
## Quantos pingos no chão (0..1) e a força do bater (0..1).
const PINGOS := {"fraco": 0.30, "forte": 1.0}
const FORCA_PINGO := {"fraco": 0.30, "forte": 0.95}
## Balanço lateral dos flocos (m/s); a chuva quase não balança.
const BALANCO := {"chuva": 0.04, "neve": 0.32}
const SEMENTE_CHUVA := 4001
const SEMENTE_NEVE := 4085

## O VENTO MANUAL — o de recurso: o que vale para os tipos que não seguem a fonte do vento (seguir_vento), ou
## quando a fonte falta (a bancada sem mapa, os testes). Na arena integrada a chuva segue o vento do mundo.
## Para onde o vento sopra, em graus à volta do Y: 0 = +X (leste), 90 = +Z (sul).
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
@export var segundos_nevar := {"fraco": 90.0, "forte": 45.0}
## Segundos para secar / derreter depois de o clima parar.
@export var segundos_secar: float = 40.0
@export var segundos_derreter: float = 60.0
## Segundos para as partículas entrarem ou saírem quando o clima ou a intensidade mudam.
@export var segundos_transicao: float = 1.5
## Cor do céu que o molhado reflecte (céu encoberto claro; não é o fundo da cena).
@export var cor_reflexo := Color(0.72, 0.80, 0.88)
## A raiz onde se procuram os grupos "clima_chao" e "clima_figura" e o sol (vazio = o pai deste nó).
@export var raiz_alvos: NodePath

@export_group("Nevasca (neve forte)")
## O vento da nevasca: quanto abranda na calma e quanto cresce no pico da rajada (× a força pedida).
@export var nevasca_calma: float = 0.65
@export var nevasca_pico: float = 2.9
## Quantos graus o rumo guina com as rajadas.
@export var nevasca_guinada_graus: float = 26.0
## Segundos para o vento da nevasca se levantar (e para se deitar quando ela acaba).
@export var segundos_levantar: float = 4.0
## Segundos de nevasca, com o vento de referência, até a neve estar toda aglomerada; com mais vento junta-se
## mais depressa (é o vento de cada frame que a arrasta), com menos, mais devagar.
@export var segundos_aglomerar: float = 38.0
@export var vento_referencia: float = 4.0
## Segundos de nevasca até o gelo estar todo formado.
@export var segundos_gelar: float = 70.0
## Quanto as bordas e os cantos do campo juntam neve (0 = campo aberto, sem bordas).
@export_range(0.0, 1.5) var bordas_abrigo: float = 1.0
## O rasto dos flocos nas rajadas (s de exposição: o floco estica-se ao longo da velocidade do frame).
@export var nevasca_rasto_s: float = 0.030
## O véu: onde começa e onde fica cheio, em múltiplos da distância da câmara ao ponto para onde ela olha
## (a zona da câmara fica sempre limpa), e quanto tapa no máximo (0..1).
@export var veu_perto: float = 1.05
@export var veu_longe: float = 1.9
@export_range(0.0, 1.0) var veu_forca: float = 0.8

@export_group("Chuva que alaga (chuva forte)")
## O chão tem de estar assim molhado (0..1) antes de a água começar a juntar-se.
@export var molhado_para_alagar: float = 0.7
## Segundos de chuva forte, com o chão já encharcado, até as bolsas estarem cheias.
@export var segundos_alagar: float = 36.0
## Depois da chuva: segundos até as bolsas se sumirem; depois, até a lama perder o brilho; depois, até secar.
@export var segundos_drenar: float = 24.0
@export var segundos_lama_baca: float = 10.0
@export var segundos_lama_secar: float = 24.0

var tipo := "nenhum"
var intensidade := "fraco"
var perfil := "medio"
## Estado visual acumulado (0..1): o chão molhado e a neve pousada.
var molhado := 0.0
var neve := 0.0
## Ordem 41 — o estado visual do clima forte (0..1). Tudo a zero nos climas fracos.
## A neve que a nevasca juntou (cantos, bordas, obstáculos) e o gelo que a exposição formou.
var aglomerado := 0.0
var gelo := 0.0
## O enchimento das bolsas, a marca da lama (até onde a água chegou) e se a lama ainda brilha de molhada.
var agua := 0.0
var lama := 0.0
var lama_humida := 1.0

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
# Ordem 41
var _veu: MultiMeshInstance3D
var _mat_veu: ShaderMaterial
var _n_veu := 0.0
var _nevasca_vento := 0.0            # 0..1: o vento da nevasca levantado
var _vento_lento := Vector2.ZERO     # o rumo do vento, alisado (os montes não rodam com cada rajada)
var _fonte_vento: WeakRef = null     # Ordem 64: o vento do mundo (seguir_vento)
## Ordem 64: os tipos cujo vento é o da fonte (seguir_vento). Os outros usam o vento manual.
var tipos_com_fonte: Array[String] = []
var _d_varre := 0.0                  # m que o vento andou, somados frame a frame (a neve rasteira anda com isto)
var _bacias: Array[Vector4] = []     # x, z, raio, fundura
## Ordem 42: por bacia, o nível de transbordo (m, no mundo) das bacias do RELEVO; NAN = a taça da Ordem 41.
var _bacias_nivel: Array[float] = []
## Ordem 42 (opcional): a altura do chão em (x, z) — só para a medição do alagamento num chão com relevo.
var altura_do_chao: Callable = Callable()
var _bacias_dadas := false
var _abrigos: Array[Vector4] = []    # x, z, meia-largura x, meia-largura z
var _abrigos_alt: Array[float] = []
var _manuais_obstaculo: Array[WeakRef] = []
var _raizes_figura: Array[WeakRef] = []
var _pes: Dictionary = {}            # instance_id -> {"p": Vector3, "a": agitação 0..1, "r": raio dos pés}
var _terreno_mudou := true
var _salpicos_com_terreno := false


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
	if not _bacias_dadas:
		_bacias = _bacias_automaticas()
	_terreno_mudou = true


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


## O vento manual (o de recurso; ver seguir_vento). Mudar o vento só muda o que os flocos andam DAQUI para a frente.
func definir_vento(direcao_graus: float, forca_m_s: float) -> void:
	vento_direcao_graus = direcao_graus
	vento_forca = maxf(forca_m_s, 0.0)


## Ordem 64 — A FONTE DO VENTO: o clima não tem vento seu quando há um vento no mundo. `fonte` é um nó com
## `vetor() -> Vector3` (m/s no plano do chão, x leste, z sul, rajada incluída: mapa/floresta/vento_mundo.gd,
## grupo «vento_mundo»). Para os tipos de `tipos` («chuva», «neve»), o vento de cada frame passa a ser o dela:
## direcção e força, lidas UMA vez por frame e integradas frame a frame como sempre (nada salta quando o vento
## do mundo roda ou dá uma rajada). As rajadas sintéticas do módulo (`rajadas`) não se somam por cima: as do
## mundo já lá vêm. Os outros tipos, e todos se a fonte faltar ou sair da cena, ficam com o vento manual.
## A arena integrada liga hoje só a chuva (CampoDaMesa.ligar_clima); a neve liga-se pondo «neve» na lista.
## `seguir_vento(null)` desliga. Só apresentação: o vento não entra em regra nenhuma.
func seguir_vento(fonte: Node, tipos: Array = ["chuva"]) -> void:
	_fonte_vento = weakref(fonte) if fonte != null else null
	tipos_com_fonte.clear()
	if fonte == null:
		return
	if not fonte.has_method(&"vetor"):
		push_warning("[clima] a fonte do vento não tem vetor(): fica o vento manual")
		_fonte_vento = null
		return
	for t in tipos:
		var s := str(t)
		if TIPOS.has(s) and s != "nenhum" and not tipos_com_fonte.has(s):
			tipos_com_fonte.append(s)


## A fonte do vento, se ainda existe (null: o vento é o manual).
func fonte_do_vento() -> Node:
	if _fonte_vento == null:
		return null
	var no = _fonte_vento.get_ref()
	return no if no != null and is_instance_valid(no) else null


## Verdadeiro se o vento de `para_tipo` (vazio: o tipo de agora) é o da fonte.
func segue_fonte(para_tipo: String = "") -> bool:
	var t := para_tipo if para_tipo != "" else tipo
	return tipos_com_fonte.has(t) and fonte_do_vento() != null


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


## Ordem 41: põe à mão o estado do clima forte (0..1) — para capturas e testes, ou para abrir uma cena já
## alagada / já com a neve aglomerada. `nova_lama` < 0: a lama acompanha a água.
func definir_forte(novo_aglomerado: float, novo_gelo: float, nova_agua: float, nova_lama: float = -1.0) -> void:
	aglomerado = clampf(novo_aglomerado, 0.0, 1.0)
	gelo = clampf(novo_gelo, 0.0, 1.0)
	agua = clampf(nova_agua, 0.0, 1.0)
	lama = clampf(nova_lama, 0.0, 1.0) if nova_lama >= 0.0 else _lama_da_agua(agua)
	lama_humida = 1.0
	if aglomerado > 0.0 or gelo > 0.0 or agua > 0.0 or lama > 0.0:
		set_process(true)
	_vestir_alvos()
	_empurrar_uniformes()


## Ordem 41: os PONTOS BAIXOS do chão onde a água da chuva forte se junta. Cada bacia é um Vector4
## (x, z, raio em m, fundura em m) ou um Dictionary {"x", "z", "raio", "fundura"}; até 8. É por aqui que as
## poças previstas no desenho do mapa (P1–P4) entram, sem mexer no módulo. Sem isto, o módulo sorteia 5
## bacias no campo (sempre as mesmas para o mesmo campo). Lista vazia = volta às sorteadas.
## Num chão com relevo de verdade, a altura da malha entra sozinha na conta (as covas reais também enchem).
## Ordem 42: um Dictionary com "nivel" (m, no mundo) é uma bacia do RELEVO — um ponto baixo de verdade do mapa
## (ver cenas/arena/bacias_do_relevo.gd): a água sobe com a superfície plana do fundo (nivel − fundura) até ao
## nível de transbordo, e é o relevo que lhe dá a forma; o raio só limita até onde ela conta.
func definir_bacias(lista: Array) -> void:
	var novas: Array[Vector4] = []
	var niveis: Array[float] = []
	for b in lista:
		if novas.size() >= MAX_BACIAS:
			break
		if b is Vector4:
			novas.append(Vector4(b.x, b.y, maxf(b.z, 0.1), maxf(b.w, 0.005)))
			niveis.append(NAN)
		elif b is Dictionary:
			novas.append(Vector4(float(b.get("x", 0.0)), float(b.get("z", 0.0)), maxf(float(b.get("raio", 2.0)), 0.1), maxf(float(b.get("fundura", 0.08)), 0.005)))
			niveis.append(float(b["nivel"]) if b.has("nivel") else NAN)
	_bacias_dadas = not novas.is_empty()
	_bacias = novas if _bacias_dadas else _bacias_automaticas()
	if not _bacias_dadas:
		niveis.clear()
	_bacias_nivel = niveis
	_terreno_mudou = true


## Ordem 42: o nível de transbordo de cada bacia em uso (NAN = taça da Ordem 41).
func bacias_nivel() -> Array[float]:
	var r: Array[float] = []
	for i in _bacias.size():
		r.append(_bacias_nivel[i] if i < _bacias_nivel.size() else NAN)
	return r


## As bacias em uso (x, z, raio, fundura).
func bacias() -> Array[Vector4]:
	return _bacias.duplicate()


## Os abrigos (caixas dos obstáculos) que a nevasca está a usar: x, z, meia-largura x, meia-largura z.
func abrigos() -> Array[Vector4]:
	return _abrigos.duplicate()


## Chão ou figura fora dos grupos (a raiz e os MeshInstance3D debaixo dela).
func registar_chao(no: Node) -> void:
	_manuais_chao.append(weakref(no))


## Ordem 41: um obstáculo fora do grupo "clima_obstaculo".
func registar_obstaculo(no: Node) -> void:
	_manuais_obstaculo.append(weakref(no))


func registar_figura(no: Node) -> void:
	_manuais_figura.append(weakref(no))


## Quantas partículas o clima pedido desenha neste perfil (o alvo; a transição chega lá em ~1,5 s).
func contagem_alvo(qual: String) -> int:
	if qual == "chuva" or qual == "salpicos":
		return int(CONTAGEM[qual][intensidade][perfil]) if tipo == "chuva" else 0
	if qual == "neve":
		return int(CONTAGEM["neve"][intensidade][perfil]) if tipo == "neve" else 0
	if qual == "veu":
		return int(VEU[perfil]) if nevasca() else 0
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
		"veu":
			return int(_n_veu)
	return 0


## Ordem 41: a neve forte é a nevasca; a chuva forte é a que alaga.
func nevasca() -> bool:
	return tipo == "neve" and intensidade == "forte"


func alaga() -> bool:
	return tipo == "chuva" and intensidade == "forte"


## O vento deste frame (m/s no chão: x, z), já com as rajadas. `para_tipo` (vazio: o tipo de agora) diz se é o
## da fonte do vento (Ordem 64, seguir_vento) ou o manual.
func vento_do_frame(para_tipo: String = "") -> Vector2:
	var forca := vento_forca
	var rumo := deg_to_rad(vento_direcao_graus)
	var t := para_tipo if para_tipo != "" else tipo
	var do_mundo := segue_fonte(t)
	if do_mundo:
		var v: Vector3 = fonte_do_vento().vetor()
		forca = Vector2(v.x, v.z).length()
		if forca > 1e-5:
			rumo = atan2(v.z, v.x)
	elif rajadas > 0.0:
		forca *= 1.0 + rajadas * (0.6 * sin(0.37 * _tempo) + 0.4 * sin(0.83 * _tempo + 1.3))
		rumo += deg_to_rad(10.0) * rajadas * sin(0.21 * _tempo + 0.5)
	# Ordem 64: a chuva que segue o vento do mundo não herda as rajadas da nevasca que ainda se está a deitar
	# (a nevasca é da neve; se a neve seguir o mundo, as rajadas dela somam-se por cima do vento do mundo).
	if _nevasca_vento > 0.0 and not (do_mundo and t == "chuva"):
		# A nevasca: o vento abranda na calma e dispara na rajada, e o rumo guina com ela. É o MESMO vento
		# (o que a chuva usaria): só o que cada frame soma muda — nada salta (integrador_vento.gd).
		var g := rajada_da_nevasca(_tempo)
		forca *= lerpf(1.0, lerpf(nevasca_calma, nevasca_pico, g), _nevasca_vento)
		rumo += deg_to_rad(nevasca_guinada_graus) * _nevasca_vento * (0.55 * sin(0.23 * _tempo + 1.1) + 0.45 * g * sin(0.61 * _tempo))
	return Vector2(cos(rumo), sin(rumo)) * maxf(forca, 0.0)


## Ordem 41: a rajada da nevasca no instante t — 0 (calma) … 1 (pico). Duas séries de rajadas que chegam,
## enchem e passam, com ritmos diferentes (7 s e 11 s), para não parecer um metrónomo.
static func rajada_da_nevasca(t: float) -> float:
	return maxf(_pulso(t + 4.6, 7.0, 3.2), 0.8 * _pulso(t + 0.5, 11.0, 3.8))


static func _pulso(t: float, periodo: float, largura: float) -> float:
	var x := fposmod(t, periodo) / largura
	if x >= 1.0:
		return 0.0
	var s := sin(PI * x)
	return s * s


## Quanto o vento da nevasca está levantado (0..1).
func vento_da_nevasca() -> float:
	return _nevasca_vento


func caixa_minimo() -> Vector3:
	return Vector3(_centro.x - _tamanho.x * 0.5 - margem_m, _centro.y, _centro.z - _tamanho.y * 0.5 - margem_m)


func caixa_tamanho() -> Vector3:
	return Vector3(_tamanho.x + 2.0 * margem_m, altura_m, _tamanho.y + 2.0 * margem_m)


## Verdadeiro se não há nada a cair nem nada pousado (o nó dorme).
func parado() -> bool:
	return (tipo == "nenhum" and molhado <= 0.0 and neve <= 0.0 and _n_chuva <= 0.0 and _n_flocos <= 0.0 and _n_salpicos <= 0.0
			and aglomerado <= 0.0 and gelo <= 0.0 and agua <= 0.0 and lama <= 0.0 and _n_veu <= 0.0 and _nevasca_vento <= 0.0)


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
	_nevasca_vento = move_toward(_nevasca_vento, 1.0 if nevasca() else 0.0, dt / maxf(segundos_levantar, 0.01))
	var vento := vento_do_frame()
	# O rumo alisado (para os montes e as fitas) e o caminho que o vento andou — somados frame a frame.
	if vento.length_squared() > 1e-6:
		var rumo_agora := vento.normalized()
		_vento_lento = rumo_agora if _vento_lento == Vector2.ZERO else _vento_lento.lerp(rumo_agora, clampf(dt / 3.5, 0.0, 1.0))
		_vento_lento = rumo_agora if _vento_lento.length_squared() < 1e-6 else _vento_lento.normalized()
	_d_varre = fposmod(_d_varre + vento.length() * dt, 4096.0)

	# Quantas partículas: sobem e descem até ao alvo, sem estalo.
	var passo := dt / maxf(segundos_transicao, 0.01)
	_n_chuva = move_toward(_n_chuva, float(contagem_alvo("chuva")), passo * float(CONTAGEM["chuva"]["forte"][perfil]))
	_n_flocos = move_toward(_n_flocos, float(contagem_alvo("neve")), passo * float(CONTAGEM["neve"]["forte"][perfil]))
	_n_salpicos = move_toward(_n_salpicos, float(contagem_alvo("salpicos")), passo * maxf(float(CONTAGEM["salpicos"]["forte"][perfil]), 1.0))
	_n_veu = move_toward(_n_veu, float(contagem_alvo("veu")), passo * maxf(float(VEU[perfil]), 1.0))

	# O deslocamento, integrado frame a frame com o vento DESTE frame (integrador_vento.gd).
	# Ordem 64: cada nuvem com o vento do seu tipo (o da fonte, se o segue; senão o manual) — lido uma vez.
	if _n_chuva > 0.0:
		var v_chuva := vento if (tipo == "chuva" or segue_fonte("chuva") == segue_fonte()) else vento_do_frame("chuva")
		_integ_chuva.avancar(dt, v_chuva, float(QUEDA["chuva"][intensidade]), float(BALANCO["chuva"]))
	if _n_flocos > 0.0:
		var v_neve := vento if (tipo == "neve" or segue_fonte("neve") == segue_fonte()) else vento_do_frame("neve")
		_integ_neve.avancar(dt, v_neve, float(QUEDA["neve"][intensidade]), float(BALANCO["neve"]))

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
	_avancar_forte(dt, vento)

	_ate_procurar -= dt
	if _ate_procurar <= 0.0:
		_ate_procurar = 0.5
		_vestir_alvos()
	_atualizar_particulas()
	_empurrar_uniformes()

	if parado():
		_despir_tudo()
		set_process(false)


# ---------------------------------------------------------------- ordem 41: o clima forte

## O que o clima forte acumula neste frame. Nos climas fracos nada disto cresce (fraca = sem bolsas e sem
## aglomeração): o que houver vai-se embora aos poucos.
func _avancar_forte(dt: float, vento: Vector2) -> void:
	var derrete := dt / maxf(segundos_derreter, 0.01)
	if nevasca():
		# É o vento de cada frame que arrasta a neve: na rajada junta-se mais depressa, na calma mais devagar.
		var ganho := clampf(vento.length() / maxf(vento_referencia, 0.1), 0.25, 2.0)
		aglomerado = minf(1.0, aglomerado + ganho * dt / maxf(segundos_aglomerar, 0.01))
		gelo = minf(1.0, gelo + dt / maxf(segundos_gelar, 0.01))
	elif tipo == "neve":
		aglomerado = maxf(0.0, aglomerado - 0.5 * derrete)
		gelo = maxf(0.0, gelo - 0.5 * derrete)
	elif tipo == "chuva":
		aglomerado = maxf(0.0, aglomerado - 2.0 * derrete)
		gelo = maxf(0.0, gelo - 3.0 * derrete)
	else:
		aglomerado = maxf(0.0, aglomerado - 0.8 * derrete)  # os montes duram mais do que o manto
		gelo = maxf(0.0, gelo - derrete)

	# A água só se junta com chuva FORTE e o chão já encharcado; sem ela, escoa.
	if alaga():
		if molhado >= molhado_para_alagar:
			agua = minf(1.0, agua + dt / maxf(segundos_alagar, 0.01))
	elif tipo == "chuva":
		agua = maxf(0.0, agua - 0.5 * dt / maxf(segundos_drenar, 0.01))
	else:
		agua = maxf(0.0, agua - dt / maxf(segundos_drenar, 0.01))
	# A lama acompanha a água a subir (vai um pouco à frente dela). A descer, fica onde a água chegou:
	# primeiro perde o brilho, depois seca (encolhe para o fundo da bacia).
	if agua > 0.0:
		lama = maxf(lama, _lama_da_agua(agua))
	if lama <= 0.0:
		lama_humida = 1.0
	elif agua > 0.02 or tipo == "chuva":
		lama_humida = minf(1.0, lama_humida + dt / 2.0)
	else:
		lama_humida = maxf(0.0, lama_humida - dt / maxf(segundos_lama_baca, 0.01))
		if lama_humida <= 0.0:
			lama = maxf(0.0, lama - dt / maxf(segundos_lama_secar, 0.01))
	_atualizar_pes(dt)


func _lama_da_agua(a: float) -> float:
	return minf(1.0, a * 1.10 + 0.04) if a > 0.0 else 0.0


## As figuras com os pés dentro de uma bolsa, e se se mexeram (o anel à volta dos pés). Só apresentação:
## lê a posição do nó na cena, nada do estado do jogo.
func _atualizar_pes(dt: float) -> void:
	if agua <= 0.0:
		if not _pes.is_empty():
			_pes.clear()
		return
	var vivos := {}
	for ref in _raizes_figura:
		var no := ref.get_ref() as Node3D
		if no == null:
			continue
		var id := no.get_instance_id()
		var p := _global_de(no).origin
		vivos[id] = true
		if not _pes.has(id):
			var caixa := _caixa_de(no)
			_pes[id] = {"p": p, "a": 0.0, "r": clampf(0.5 * maxf(caixa.size.x, caixa.size.z), 0.15, 0.8)}
			continue
		var e: Dictionary = _pes[id]
		if (e["p"] as Vector3).distance_to(p) > 0.003:
			e["a"] = 1.0
		else:
			e["a"] = maxf(0.0, float(e["a"]) - dt / 1.4)
		e["p"] = p
	for id in _pes.keys():
		if not vivos.has(id):
			_pes.erase(id)


## Sorteia as bacias do campo quando ninguém as deu: 5 pontos baixos, sempre os mesmos para o mesmo campo.
func _bacias_automaticas() -> Array[Vector4]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4141
	var r: Array[Vector4] = []
	var lado := minf(_tamanho.x, _tamanho.y)
	var tentativas := 0
	while r.size() < 5 and tentativas < 200:
		tentativas += 1
		var raio := lado * rng.randf_range(0.065, 0.115)
		var x := _centro.x + _tamanho.x * rng.randf_range(-0.36, 0.36)
		var z := _centro.z + _tamanho.y * rng.randf_range(-0.36, 0.36)
		var livre := true
		for b in r:
			if Vector2(b.x - x, b.y - z).length() < (b.z + raio) * 0.8:
				livre = false
		if livre:
			r.append(Vector4(x, z, raio, rng.randf_range(0.06, 0.10)))
	return r


## A torção do plano (espelho de clima_torcer no shader): a margem da bolsa não é um círculo de compasso.
static func torcer(p: Vector2) -> Vector2:
	return p + 0.55 * Vector2(sin(p.y * 0.83 + 1.3) + 0.5 * sin(p.x * 1.71 + 4.1), sin(p.x * 0.77 + 2.9) + 0.5 * sin(p.y * 1.93 + 0.4))


## A água (m) por cima do ponto (x, z) — espelho de clima_fundura no shader. Negativo = seco.
## `enchimento` < 0 usa a água de agora; `margem` alarga a conta (a faixa da lama).
func fundura_em(xz: Vector2, enchimento: float = -1.0, margem: float = 0.0, y_rel: float = 0.0) -> float:
	var a := (agua if enchimento < 0.0 else enchimento) * ENCHE
	var q := torcer(xz)
	var d := -1.0 + y_rel  # Ordem 42: seco onde nenhuma bacia conta, também num chão com relevo
	for i in _bacias.size():
		var b := _bacias[i]
		if i < _bacias_nivel.size() and not is_nan(_bacias_nivel[i]):
			# Ordem 42: bacia do relevo (espelho de clima_fundura no shader)
			var v0 := (xz - Vector2(b.x, b.y)) / maxf(b.z, 0.01)
			var y_abs := y_rel + _centro.y
			if v0.length_squared() < 1.0 and y_abs > _bacias_nivel[i] - b.w - 0.03:
				var nivel := _bacias_nivel[i] - b.w + (a + margem) * b.w
				d = maxf(d, nivel - y_abs + y_rel)
			continue
		var v := (q - Vector2(b.x, b.y)) / maxf(b.z, 0.01)
		var u2 := minf(v.length_squared(), 1.0)
		var taca := (1.0 - u2) * (1.0 - u2)
		d = maxf(d, b.w * (taca - (1.0 - a) + margem))
	return d - y_rel


static func _sd_caixa(p: Vector2, c: Vector4) -> float:
	var d := Vector2(absf(p.x - c.x) - c.z, absf(p.y - c.y) - c.w)
	return Vector2(maxf(d.x, 0.0), maxf(d.y, 0.0)).length() + minf(maxf(d.x, d.y), 0.0)


## Quanto a neve se junta no ponto (x, z) — espelho de clima_abrigo no shader (sem o grão das dunas):
## 0 = campo varrido … 1,6 = canto com obstáculo. `rumo` = para onde o vento sopra (vazio: o de agora).
func abrigo_em(xz: Vector2, rumo: Vector2 = Vector2.ZERO) -> float:
	var w := rumo.normalized() if rumo != Vector2.ZERO else (_vento_lento if _vento_lento != Vector2.ZERO else Vector2.RIGHT)
	var c := Vector2(_centro.x, _centro.z)
	var meio := _tamanho * 0.5
	var e := Vector2(maxf(meio.x - absf(xz.x - c.x), 0.0), maxf(meio.y - absf(xz.y - c.y), 0.0))
	var lado := Vector2(signf(xz.x - c.x), signf(xz.y - c.y))
	var peso := Vector2(1.0 - 0.45 * lado.x * w.x, 1.0 - 0.45 * lado.y * w.y)
	var b := Vector2(exp(-e.x / 1.15) * peso.x, exp(-e.y / 1.15) * peso.y)
	var canto := exp(-(e.x + e.y) / 2.4) * 0.5 * (peso.x + peso.y)
	var soma := bordas_abrigo * (0.55 * maxf(b.x, b.y) + 0.95 * canto)
	for i in _abrigos.size():
		var cx := _abrigos[i]
		var alcance := clampf(_abrigos_alt[i] * 2.6, 0.9, 5.5)
		var d := xz - Vector2(cx.x, cx.y)
		var s := clampf(d.dot(w), 0.0, alcance)
		var f := s / alcance
		var meia := minf(cx.z, cx.w)
		var d0 := _sd_caixa(xz, cx)
		var d1 := _sd_caixa(xz - w * s, cx) + f * (0.25 + 0.6 * meia)
		var lado_abrigado := 0.5 + 0.5 * clampf(d.dot(w) / (0.6 + meia), -1.0, 1.0)
		var base := exp(-maxf(d0, 0.0) / 0.38) * lerpf(0.45, 0.95, lado_abrigado)
		var cauda := smoothstep(0.30, -0.20, d1) * (1.0 - f) * (1.0 - f)
		soma += maxf(base, cauda)
	return minf(soma, 1.6)


## Quanta neve há no ponto (x, z), como o chão a desenha (sem o grão): a base é igual em todo o lado; com a
## nevasca, o centro exposto perde e os abrigos ganham.
func neve_em(xz: Vector2) -> float:
	if aglomerado <= 0.0:
		return neve
	var ab := abrigo_em(xz)
	var exposto := 1.0 - clampf(ab * 1.4, 0.0, 1.0)
	return neve * (1.0 - aglomerado * exposto * 0.67) + aglomerado * ab * 1.05


## A medição do alagamento com a conta do jogo: varre o campo de `passo_m` em `passo_m` e soma a área com
## água e a área com lama (m² e % do campo), a fundura máxima e o raio médio das bolsas.
func medir_alagamento(passo_m: float = 0.1) -> Dictionary:
	var passo := maxf(passo_m, 0.02)
	var nx := int(ceil(_tamanho.x / passo))
	var nz := int(ceil(_tamanho.y / passo))
	var x0 := _centro.x - _tamanho.x * 0.5
	var z0 := _centro.z - _tamanho.y * 0.5
	var com_agua := 0
	var com_lama := 0
	var fundura_max := 0.0
	for j in nz:
		for i in nx:
			var p := Vector2(x0 + (i + 0.5) * passo, z0 + (j + 0.5) * passo)
			var y_rel := (float(altura_do_chao.call(p.x, p.y)) - _centro.y) if altura_do_chao.is_valid() else 0.0
			var d := fundura_em(p, -1.0, 0.0, y_rel)
			if d > 0.0:
				com_agua += 1
				fundura_max = maxf(fundura_max, d)
			if lama > 0.0 and fundura_em(p, lama, MARGEM_LAMA, y_rel) > 0.0055:
				com_lama += 1
	var celula := passo * passo
	var campo := _tamanho.x * _tamanho.y
	var area := com_agua * celula
	var n := maxi(_bacias.size(), 1)
	return {
		"agua": agua, "lama": lama, "bacias": _bacias.size(),
		"area_agua_m2": area, "percent_agua": 100.0 * area / campo,
		"area_lama_m2": com_lama * celula, "percent_lama": 100.0 * com_lama * celula / campo,
		"fundura_max_m": fundura_max, "raio_medio_m": sqrt(area / (PI * n)),
	}


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
	if _n_veu > 0.0 and _veu == null:
		_mat_veu = _material(SH_FLOCOS, 21)
		_mat_veu.set_shader_parameter(&"tamanho_m", 2.1)
		_mat_veu.set_shader_parameter(&"px_minimo", 0.0)
		_mat_veu.set_shader_parameter(&"macio", 1.0)
		_mat_veu.set_shader_parameter(&"cor", Color(0.90, 0.93, 0.97, 0.13))
		_veu = _criar_nuvem("Veu", _mat_veu, int(VEU["alto"]), SEMENTE_NEVE + 1, true, Vector2(1.0, 1.0))
	_mostrar(_chuva, _n_chuva)
	_mostrar(_flocos, _n_flocos)
	_mostrar(_salpicos, _n_salpicos)
	_mostrar(_veu, _n_veu)


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
	for no in [_chuva, _flocos, _salpicos, _veu]:
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
	var precisa := molhado > 0.0 or neve > 0.0 or tipo != "nenhum" or aglomerado > 0.0 or gelo > 0.0 or agua > 0.0 or lama > 0.0
	if not precisa:
		return
	if _mat_chao == null:
		_mat_chao = _material(SH_CHAO, -20)
		_mat_figura = _material(SH_FIGURA, 0)
	var vistos := {}
	# Os grupos procuram-se na árvore da cena (debaixo da raiz dos alvos); os registados à mão valem sempre.
	var raiz := _raiz() if is_inside_tree() else null
	var figuras: Array[WeakRef] = []
	var obstaculos: Array[Node] = []
	if raiz != null:
		for n in get_tree().get_nodes_in_group(GRUPO_CHAO):
			if raiz == n or raiz.is_ancestor_of(n):
				_vestir(n, _mat_chao, vistos, false)
		for n in get_tree().get_nodes_in_group(GRUPO_FIGURA):
			if raiz == n or raiz.is_ancestor_of(n):
				_vestir(n, _mat_figura, vistos, true)
				figuras.append(weakref(n))
		for n in get_tree().get_nodes_in_group(GRUPO_OBSTACULO):
			if raiz == n or raiz.is_ancestor_of(n):
				obstaculos.append(n)
	_vestir_manuais(_manuais_chao, _mat_chao, vistos, false)
	_vestir_manuais(_manuais_figura, _mat_figura, vistos, true)
	for ref in _manuais_figura:
		figuras.append(ref)
	_raizes_figura = figuras
	# Ordem 41: os obstáculos vestem a camada das figuras (neve em cima e a sotavento, gelo) e dão as
	# caixas dos abrigos ao chão (onde a neve da nevasca se junta).
	for i in range(_manuais_obstaculo.size() - 1, -1, -1):
		var o = _manuais_obstaculo[i].get_ref()
		if o == null:
			_manuais_obstaculo.remove_at(i)
		elif not obstaculos.has(o):
			obstaculos.append(o)
	var novos: Array[Vector4] = []
	var novas_alt: Array[float] = []
	for o in obstaculos:
		_vestir(o, _mat_figura, vistos, false)
		if novos.size() < MAX_ABRIGOS:
			var caixa := _caixa_de(o)
			if caixa.size.x > 0.0 and caixa.size.z > 0.0:
				var c := caixa.get_center()
				novos.append(Vector4(c.x, c.z, caixa.size.x * 0.5, caixa.size.z * 0.5))
				novas_alt.append(maxf(caixa.end.y - _centro.y, 0.1))
	if novos != _abrigos or novas_alt != _abrigos_alt:
		_abrigos = novos
		_abrigos_alt = novas_alt
		_terreno_mudou = true
	# Quem saiu da cena (ou morreu) sai da lista.
	for id in _vestidos.keys():
		if not vistos.has(id):
			var no = (_vestidos[id] as WeakRef).get_ref()
			if no != null and (no as GeometryInstance3D).material_overlay in [_mat_chao, _mat_figura]:
				(no as GeometryInstance3D).material_overlay = null
			_vestidos.erase(id)
	if raiz != null and (_sol == null or not is_instance_valid(_sol)):
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


## A transformação no mundo, mesmo fora da árvore (os testes sem janela montam cenas soltas).
func _global_de(no: Node3D) -> Transform3D:
	if no.is_inside_tree():
		return no.global_transform
	var t := no.transform
	var pai := no.get_parent()
	while pai != null:
		if pai is Node3D:
			t = (pai as Node3D).transform * t
		pai = pai.get_parent()
	return t


## A caixa (no mundo) das malhas do nó e do que está debaixo dele. Tamanho zero se não houver malhas.
func _caixa_de(no: Node) -> AABB:
	var r := AABB()
	var tem := false
	var fila: Array[Node] = [no]
	while not fila.is_empty():
		var n: Node = fila.pop_back()
		var mi := n as MeshInstance3D
		if mi != null and mi.mesh != null:
			var c: AABB = _global_de(mi) * mi.mesh.get_aabb()
			r = r.merge(c) if tem else c
			tem = true
		for f in n.get_children():
			if f is Node3D and not (f is Label3D):
				fila.append(f)
	return r


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
	for nuvem in [_chuva, _flocos, _salpicos, _veu]:
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
	var rajada := rajada_da_nevasca(_tempo) if _nevasca_vento > 0.0 else 0.0
	var veu_agora := veu_forca * _nevasca_vento * (0.55 + 0.45 * rajada)
	var veu_dist := _distancias_do_veu()
	if _mat_flocos != null and _n_flocos > 0.0:
		_empurrar_nuvem(_mat_flocos, _integ_neve, cmin, ctam)
		_mat_flocos.set_shader_parameter(&"exposicao_s", nevasca_rasto_s * _nevasca_vento)
	if _mat_veu != null and _n_veu > 0.0:
		_empurrar_nuvem(_mat_veu, _integ_neve, cmin, ctam)
		_mat_veu.set_shader_parameter(&"exposicao_s", 2.0 * nevasca_rasto_s * _nevasca_vento)
		_mat_veu.set_shader_parameter(&"opacidade", veu_agora)
		_mat_veu.set_shader_parameter(&"veu_perto_m", veu_dist.x)
		_mat_veu.set_shader_parameter(&"veu_longe_m", veu_dist.y)
	if _mat_salpicos != null and _n_salpicos > 0.0:
		_mat_salpicos.set_shader_parameter(&"caixa_min", Vector3(cmin.x + margem_m, cmin.y, cmin.z + margem_m))
		_mat_salpicos.set_shader_parameter(&"caixa_tam", Vector3(_tamanho.x, ctam.y, _tamanho.y))
		_mat_salpicos.set_shader_parameter(&"chao_y", _centro.y + 0.02)
		_mat_salpicos.set_shader_parameter(&"tempo", _tempo)
		_mat_salpicos.set_shader_parameter(&"forca", float(FORCA_PINGO[intensidade]))
		_mat_salpicos.set_shader_parameter(&"agua", agua)
	if _mat_chao == null:
		return
	# Ordem 41: o terreno (bacias, abrigos, campo) só se manda quando muda; o resto, a cada frame.
	if _terreno_mudou:
		_terreno_mudou = false
		_salpicos_com_terreno = _mat_salpicos != null
		for m in [_mat_chao, _mat_figura, _mat_salpicos]:
			if m != null:
				_empurrar_terreno(m)
	elif _mat_salpicos != null and not _salpicos_com_terreno:
		_salpicos_com_terreno = true
		_empurrar_terreno(_mat_salpicos)  # os salpicos nasceram depois do chão
	var rumo_lento := _vento_lento if _vento_lento != Vector2.ZERO else Vector2.RIGHT
	var pes_lista := PackedVector4Array()
	pes_lista.resize(MAX_PES)
	var n_pes := 0
	if agua > 0.0:
		for id in _pes:
			if n_pes >= MAX_PES:
				break
			var e: Dictionary = _pes[id]
			var p: Vector3 = e["p"]
			if fundura_em(Vector2(p.x, p.z)) > 0.0:
				pes_lista[n_pes] = Vector4(p.x, p.z, float(e["r"]), float(e["a"]))
				n_pes += 1
	for m in [_mat_chao, _mat_figura]:
		m.set_shader_parameter(&"vento_abrigo", rumo_lento)
		m.set_shader_parameter(&"aglomerado", aglomerado)
		m.set_shader_parameter(&"gelo", gelo)
		m.set_shader_parameter(&"agua", agua)
	_mat_figura.set_shader_parameter(&"tempo", _tempo)
	_mat_chao.set_shader_parameter(&"lama", lama)
	_mat_chao.set_shader_parameter(&"lama_humida", lama_humida)
	_mat_chao.set_shader_parameter(&"rasteira", _nevasca_vento * clampf((vento_do_frame().length() - 2.0) / 5.0, 0.12, 1.0))
	_mat_chao.set_shader_parameter(&"d_varre", _d_varre)
	_mat_chao.set_shader_parameter(&"veu", veu_agora)
	_mat_chao.set_shader_parameter(&"veu_perto_m", veu_dist.x)
	_mat_chao.set_shader_parameter(&"veu_longe_m", veu_dist.y)
	_mat_chao.set_shader_parameter(&"pes", pes_lista)
	_mat_chao.set_shader_parameter(&"n_pes", n_pes)
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
	_mat_chao.set_shader_parameter(&"qualidade", PERFIS.find(perfil))
	_mat_figura.set_shader_parameter(&"molhado", molhado)
	_mat_figura.set_shader_parameter(&"neve", neve)
	_mat_figura.set_shader_parameter(&"luz_dir", luz_dir)
	_mat_figura.set_shader_parameter(&"luz_cor", luz_cor)
	_mat_figura.set_shader_parameter(&"cor_reflexo", cor_reflexo)


## Ordem 42: o mesmo, para um material de fora do módulo que inclua clima_terreno.gdshaderinc (a relva do
## mapa): as bacias, os abrigos e o campo, e o estado (neve, aglomerado, água, lama).
func empurrar_terreno_para(m: ShaderMaterial) -> void:
	_empurrar_terreno(m)
	m.set_shader_parameter(&"vento_abrigo", _vento_lento.normalized() if _vento_lento != Vector2.ZERO else Vector2.RIGHT)
	m.set_shader_parameter(&"clima_neve", neve)
	m.set_shader_parameter(&"clima_aglomerado", aglomerado)
	m.set_shader_parameter(&"clima_agua", agua)
	m.set_shader_parameter(&"clima_lama", lama)


## Ordem 41: as bacias, os abrigos e o campo (clima_terreno.gdshaderinc) para um material.
func _empurrar_terreno(m: ShaderMaterial) -> void:
	var b := PackedVector4Array()
	b.resize(MAX_BACIAS)
	var tipos := PackedInt32Array()
	tipos.resize(MAX_BACIAS)
	var niveis := PackedFloat32Array()
	niveis.resize(MAX_BACIAS)
	for i in mini(_bacias.size(), MAX_BACIAS):
		b[i] = _bacias[i]
		if i < _bacias_nivel.size() and not is_nan(_bacias_nivel[i]):
			tipos[i] = 1
			niveis[i] = _bacias_nivel[i]
	var ab := PackedVector4Array()
	ab.resize(MAX_ABRIGOS)
	var alt := PackedFloat32Array()
	alt.resize(MAX_ABRIGOS)
	for i in mini(_abrigos.size(), MAX_ABRIGOS):
		ab[i] = _abrigos[i]
		alt[i] = _abrigos_alt[i]
	m.set_shader_parameter(&"bacias", b)
	m.set_shader_parameter(&"n_bacias", mini(_bacias.size(), MAX_BACIAS))
	m.set_shader_parameter(&"bacias_tipo", tipos)
	m.set_shader_parameter(&"bacias_nivel", niveis)
	m.set_shader_parameter(&"abrigos", ab)
	m.set_shader_parameter(&"abrigos_alt", alt)
	m.set_shader_parameter(&"n_abrigos", mini(_abrigos.size(), MAX_ABRIGOS))
	m.set_shader_parameter(&"campo", Vector4(_centro.x, _centro.z, _tamanho.x * 0.5, _tamanho.y * 0.5))
	m.set_shader_parameter(&"chao_ref_y", _centro.y)
	m.set_shader_parameter(&"bordas", bordas_abrigo)


## Ordem 41: onde o véu começa e onde fica cheio (m da câmara). Mede-se pela câmara de agora: a distância
## dela ao ponto do chão para onde olha — a zona da câmara fica sempre limpa.
func _distancias_do_veu() -> Vector2:
	var foco := 30.0
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam != null:
		var o := cam.global_position
		var d := -cam.global_transform.basis.z
		foco = o.distance_to(_centro)
		if d.y < -0.01:
			var t := (_centro.y - o.y) / d.y
			if t > 0.0:
				foco = t
	foco = clampf(foco, 4.0, 400.0)
	return Vector2(foco * veu_perto, foco * veu_longe)


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
