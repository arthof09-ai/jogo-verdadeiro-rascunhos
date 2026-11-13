extends RefCounted
## paleta_floresta.gd — Ordem 37: a paleta ÚNICA do campo de batalha da floresta.
##
## REGRA DE OURO ANTI-COSTURA (ESTUDO-ELDEN.md): COR_HORIZONTE é a única variável que
## alimenta ao mesmo tempo
##   (a) a faixa baixa do céu pintado  (shaders/ceu_panorama.gdshader, uniform cor_horizonte)
##   (b) a cor da névoa de profundidade (Environment.fog_light_color)
##   (c) a tinta cozinhada dos anéis    (vertex colors geradas em campo_floresta.gd)
## Se a paleta mudar, muda AQUI e só aqui. O forno do céu (ferramentas/cozer_ceu.gd) lê a
## mesma constante: depois de a mudar, volta a cozer a pintura.

## A cor do ar da floresta: verde-dourado (alvo: referência 07).
const COR_HORIZONTE := Color("#d7d09a")

# ---------------------------------------------------------------- céu (pintura v2)
## Mundo: -Z = norte, +X = leste. Azimute em graus a partir do norte, positivo para leste.
const SOL_AZIMUTE := -34.0
const SOL_ELEVACAO := 13.0
## Diâmetros angulares da pintura aprovada (paleta v2).
const SOL_DIAMETRO := 5.75
const LUA_DIAMETRO := 7.17
## Brilho (mediana da luma sRGB do disco) da lua aprovado na v2.
const LUA_BRILHO := 0.410
const LUA_AZIMUTE := 138.0
const LUA_ELEVACAO := 33.0
## Faixa (em EYEDIR.y) onde o céu pintado se funde na cor do horizonte (fórmula da v2: 0,15).
const FAIXA_HORIZONTE := 0.15

# ---------------------------------------------------------------- luz da arena
## A luz-chave da arena segue o azimute do sol pintado, mas mais alta («batota de pintor»:
## com o sol a 13° as sombras das árvores comiam a clareira inteira).
const LUZ_ELEVACAO := 34.0
const COR_SOL := Color("#ffe2a8")
const COR_SOMBRA := Color("#5a6f8c")  # sombra colorida (nunca preto), fria contra o ouro
const COR_CEU_AMBIENTE := Color("#a9b98f")

# ---------------------------------------------------------------- névoa
## A névoa começa DEPOIS da arena e satura antes do anel longe.
const NEVOA_INICIO := 40.0
const NEVOA_FIM := 112.0
const NEVOA_TECTO := 0.90  # opacidade máxima (fog_density no modo profundidade)

# ---------------------------------------------------------------- vegetação e chão
const RELVA_BASE := Color("#3f5a26")
const RELVA_PONTA := Color("#a9b85a")
const RELVA_SECA := Color("#c9b867")
const CHAO_RELVA := Color("#4c6429")
const CHAO_TERRA := Color("#6e5a3c")
const CHAO_MUSGO := Color("#5d7a33")
const PEDRA := Color("#8a8778")
const PEDRA_MUSGO := Color("#66803a")
const CASCA := Color("#5b4a38")
const COPA_A := Color("#476b2c")
const COPA_B := Color("#6f8a35")
const COPA_OURO := Color("#b3a646")

## Tinta dos anéis ANTES do ar (o ar é misturado por distância em campo_floresta.gd).
const ANEL_FLORESTA := Color("#51703a")
const ANEL_MONTE := Color("#6f8f86")


static func dir_de(azimute_graus: float, elevacao_graus: float) -> Vector3:
	var az := deg_to_rad(azimute_graus)
	var el := deg_to_rad(elevacao_graus)
	return Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))


static func dir_sol_pintado() -> Vector3:
	return dir_de(SOL_AZIMUTE, SOL_ELEVACAO)


static func dir_lua() -> Vector3:
	return dir_de(LUA_AZIMUTE, LUA_ELEVACAO)


## Direcção PARA a luz-chave da arena.
static func dir_luz() -> Vector3:
	return dir_de(SOL_AZIMUTE, LUZ_ELEVACAO)


## O ar entre a câmara e a tinta: quanto (0–1) da cor do horizonte entra a esta distância.
static func ar(cor: Color, quanto: float) -> Color:
	return cor.lerp(COR_HORIZONTE, clampf(quanto, 0.0, 1.0))
