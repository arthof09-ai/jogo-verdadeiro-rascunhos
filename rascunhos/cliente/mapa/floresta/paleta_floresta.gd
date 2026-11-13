extends RefCounted
## paleta_floresta.gd — a paleta ÚNICA do campo de batalha da floresta (Ordem 37; refeita na 38).
##
## REGRA DE OURO ANTI-COSTURA (ESTUDO-ELDEN.md): COR_HORIZONTE é a única variável que
## alimenta ao mesmo tempo
##   (a) a faixa baixa do céu pintado  (shaders/ceu_panorama.gdshader, uniform cor_horizonte)
##   (b) a cor da névoa de profundidade (Environment.fog_light_color)
##   (c) o ar pintado do fundo          (anéis, Árvore Ancestral, orla do chão)
## Se a paleta mudar, muda AQUI e só aqui. O forno do céu (ferramentas/cozer_ceu.gd) lê a
## mesma constante: depois de a mudar, volta a cozer a pintura.
##
## ORDEM 38 (defeito 3 — monocromia verde-lima): a paleta passa a ser POR FUNÇÃO. Três
## famílias que o olho separa sem pensar, todas de saturação contida:
##   COMBATE   — o chão onde se joga: verde-OURO quente e claro (relva, palha, terra batida)
##   COBERTURA — o que tapa e bloqueia: verdes FRIOS e escuros (copas, arbustos, fetos),
##               castanho de casca e cinza de pedra
##   FUNDO     — o que não se alcança: azul-esverdeado que o ar leva para a cor do horizonte
## A relva nunca é mais saturada que 0,45 (HSV); nenhuma cor de vegetação passa de 0,50.

## A cor do ar da floresta: ouro pálido (o verde-ouro da receita, com a saturação contida).
const COR_HORIZONTE := Color("#d6d0ab")

# ---------------------------------------------------------------- céu (pintura v3: UMA hora)
## Mundo: -Z = norte, +X = leste. Azimute em graus a partir do norte, positivo para leste.
## Ordem 38 (defeito 5): um só céu e uma só hora nos 360° — meio da tarde, sol a oés-sudoeste.
## O sol pintado e a luz da arena são a MESMA direcção (acabou a «batota de pintor»).
const SOL_AZIMUTE := -112.0
const SOL_ELEVACAO := 31.0
## Diâmetros angulares dos discos pintados: a lua é MENOR que o sol.
const SOL_DIAMETRO := 5.75
const LUA_DIAMETRO := 3.9
## Lua de dia: pálida, mais clara que o céu à volta, sem estrelas.
const LUA_AZIMUTE := 62.0
const LUA_ELEVACAO := 37.0
## Faixa (em EYEDIR.y) onde o céu pintado se funde na cor do horizonte.
const FAIXA_HORIZONTE := 0.15
## Cores do gradiente do céu (as mesmas em todos os azimutes): zénite e meia altura.
const CEU_ZENITE := Color("#3f73b4")
const CEU_MEIO := Color("#7fa6cf")
const CEU_BAIXO := Color("#bccbc4")

# ---------------------------------------------------------------- luz
const COR_SOL := Color("#ffe6b4")
const COR_SOMBRA := Color("#52658a")   # sombra colorida (nunca preto), fria contra o ouro
const COR_CEU_AMBIENTE := Color("#a3b4bd")

# ---------------------------------------------------------------- névoa
## A névoa começa DEPOIS da arena e satura antes do anel longe.
const NEVOA_INICIO := 48.0
const NEVOA_FIM := 150.0
const NEVOA_TECTO := 0.80  # opacidade máxima (fog_density no modo profundidade)
const NEVOA_CURVA := 1.15

# ---------------------------------------------------------------- COMBATE (o chão onde se joga)
const RELVA_BASE := Color("#566535")
const RELVA_PONTA := Color("#b3ad6a")
const RELVA_SECA := Color("#cbb97c")
const RELVA_SOMBRA := Color("#4b6a4a")   # a relva debaixo da floresta: mais fria e escura
const CHAO_RELVA := Color("#67733e")
const CHAO_TERRA := Color("#7b664a")
const CHAO_MUSGO := Color("#5c7046")
const CHAO_FLORESTA := Color("#4e5a3a")  # folhada: o chão debaixo das copas
const FLOR_BRANCA := Color("#ece6cf")
const FLOR_OURO := Color("#e0b94e")
const FLOR_LILAS := Color("#a48ac0")
const ESPIGA := Color("#d2bf85")
const JUNCO := Color("#5f7048")
const JUNCO_CABECA := Color("#6a4a30")
const AGUA := Color("#3d6670")
const AGUA_RASA := Color("#7d9a86")

# ---------------------------------------------------------------- COBERTURA (o que tapa)
const PEDRA := Color("#8f8b82")
const PEDRA_QUENTE := Color("#a39a86")
const PEDRA_MUSGO := Color("#5f7346")
const CASCA := Color("#4f4034")
const CASCA_CLARA := Color("#8a7862")
const CASCA_CONIFERA := Color("#5c3f30")
const MADEIRA_MORTA := Color("#9a8e7c")
## Copas por família (defeito 6): cada família tem o seu verde.
const COPA_GUARDA_SOL_A := Color("#4d6b3c")
const COPA_GUARDA_SOL_B := Color("#6d8347")
const COPA_REDONDA_A := Color("#3f6243")
const COPA_REDONDA_B := Color("#58794a")
const COPA_CONIFERA_A := Color("#2f4f47")
const COPA_CONIFERA_B := Color("#3f6455")
const COPA_JOVEM := Color("#76893f")
const COPA_OURO := Color("#a99c57")
## O estrato intermédio (arbustos): verdes frios, mais escuros que a relva.
const ARBUSTO_A := Color("#3b5a48")
const ARBUSTO_B := Color("#4e6e4c")
const FETO := Color("#587a45")
const FOLHA_LARGA := Color("#3f6b52")
const BAGA := Color("#b5483c")
## Os marcos (o santuário ecoa o palácio da Árvore Ancestral).
const TELHA := Color("#56636f")
const OURO_VELHO := Color("#c99a3f")
const MADEIRA_LACADA := Color("#8a3b2c")
const PEDRA_LANTERNA := Color("#a09a8c")
const LUME := Color("#ffcf7a")

# ---------------------------------------------------------------- FUNDO (o que não se alcança)
const ANEL_FLORESTA := Color("#4a6a52")
const ANEL_MONTE := Color("#6f8f9a")
const ANEL_SERRA := Color("#8aa3b8")

# ---------------------------------------------------------------- a Árvore Ancestral
const ANCESTRAL_CASCA := Color("#bfae8a")
const ANCESTRAL_CASCA_FUNDA := Color("#7f6f58")
const ANCESTRAL_MUSGO := Color("#5f7a36")
const ANCESTRAL_FOLHA_LUZ := Color("#86a23c")
const ANCESTRAL_FOLHA := Color("#56802f")
const ANCESTRAL_FOLHA_FUNDA := Color("#2f4d26")
const ANCESTRAL_TELHA := Color("#5a6876")
const ANCESTRAL_OURO := Color("#e0a63a")
const ANCESTRAL_MADEIRA := Color("#9c6a36")


static func dir_de(azimute_graus: float, elevacao_graus: float) -> Vector3:
	var az := deg_to_rad(azimute_graus)
	var el := deg_to_rad(elevacao_graus)
	return Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))


static func dir_lua() -> Vector3:
	return dir_de(LUA_AZIMUTE, LUA_ELEVACAO)


## Direcção PARA o sol: a do disco pintado no céu E a da luz de tudo (uma só hora).
static func dir_luz() -> Vector3:
	return dir_de(SOL_AZIMUTE, SOL_ELEVACAO)


## O ar entre a câmara e a tinta: quanto (0–1) da cor do horizonte entra a esta distância.
static func ar(cor: Color, quanto: float) -> Color:
	return cor.lerp(COR_HORIZONTE, clampf(quanto, 0.0, 1.0))
