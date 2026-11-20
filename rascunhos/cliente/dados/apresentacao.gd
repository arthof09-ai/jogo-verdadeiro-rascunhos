extends RefCounted
## apresentacao.gd — ORDEM DADOS DE APRESENTAÇÃO: a TABELA ÚNICA dos dados de APRESENTAÇÃO do cliente.
##
## Um ficheiro, todos os números e cores de apresentação com nome (padrão: o `dados.gd` do jogo do ViktorKav).
## Os consumidores lêem DAQUI (`const Apresentacao := preload("res://dados/apresentacao.gd")`).
##
## Esta tabela ORGANIZA, não afina: cada valor é o que já estava no código no dia da consolidação
## (fable/integracao-50 @ cbe7729), copiado tal e qual — o mesmo literal, para o ecrã ficar igual pixel a pixel.
## Valor que pareça errado NÃO se corrige aqui: regista-se como pendência (ver PENDENCIAS, no fim).
##
## FRONTEIRA DURA: nada de COMBATE (vida, ataque, defesa, PA, custos) — isso é do servidor e do cânone (fichas).
##
## A PALETA DO AMBIENTE (luz do sol, sombra, contorno, neblina, céu × 4 horas) NÃO se copia para aqui: a fonte
## única é o color_script fechado na Ordem 65 (res://arte/ambiente/color_script.gd). A tabela só aponta para ele.

# ================================================================ ambiente (fonte: Ordem 65)

## O color script das 4 horas — fonte única da paleta do ambiente (fechado na Ordem 65).
const COLOR_SCRIPT := "res://arte/ambiente/color_script.gd"

# ================================================================ paleta da interface (papéis)
# Os papéis com valor são os que o cliente já usa. Os papéis sem valor fechado (bronze, ouro, sangue, lendário,
# raro, mágico) ficam em PENDENCIAS: a Ordem 65 não os fechou e esta tabela não inventa hexadecimais.

## Fundo do ecrã de entrada (lobby).
const COR_FUNDO := Color(0.10, 0.13, 0.18)
## Opacidade dos painéis e dos botões em repouso.
const OPACIDADE_PAINEL := 0.55
## Painel (PanelContainer) do HUD e do lobby.
const COR_PAINEL := Color(0.06, 0.07, 0.10, OPACIDADE_PAINEL)
## Botões do HUD: repouso, por cima, carregado, desligado.
const COR_BOTAO := Color(0.10, 0.12, 0.16, OPACIDADE_PAINEL)
const COR_BOTAO_POR_CIMA := Color(0.16, 0.19, 0.25, OPACIDADE_PAINEL + 0.1)
const COR_BOTAO_CARREGADO := Color(0.20, 0.40, 0.65, 0.85)
const COR_BOTAO_DESLIGADO := Color(0.10, 0.12, 0.16, 0.35)
## O miolo da engrenagem ⚙ (a cor do botão em repouso, opaca).
const COR_BOTAO_OPACO := Color(0.10, 0.12, 0.16, 1.0)
## Moldura do foco (teclado/comando) nos botões.
const COR_FOCO := Color(1.0, 0.9, 0.4)
## Texto, texto fraco (botão desligado) e o contorno escuro das faixas.
const COR_TEXTO := Color.WHITE
const COR_TEXTO_FRACO := Color(1, 1, 1, 0.45)
const COR_CONTORNO_TEXTO := Color(0, 0, 0, 0.9)
## Aviso do lobby (texto amarelo).
const COR_AVISO := Color(1.0, 0.85, 0.45)
## Campo do lobby fora dos limites: a borda/dica e o fundo.
const COR_FORA := Color(1.0, 0.55, 0.45)
const COR_FUNDO_FORA := Color(0.20, 0.09, 0.08, 0.9)
## Contorno dos números de dano: quando o golpe é em mim (vermelho escuro) e quando não é (preto).
const COR_CONTORNO_DANO_EM_MIM := Color(0.55, 0.0, 0.0)
const COR_CONTORNO_DANO := Color(0.0, 0.0, 0.0)

## Cores dos números de dano por tipo (PROVISÓRIO desde o HUD: a paleta final é da V1.2, Plano B).
## As chaves "cortante" e "perfurante" são as das fichas de exemplo do servidor.
const CORES_DANO := {
	"fisico": Color(1.0, 0.96, 0.88),
	"corte": Color(1.0, 0.85, 0.80),
	"cortante": Color(1.0, 0.85, 0.80),
	"perfuracao": Color(1.0, 0.90, 0.75),
	"perfurante": Color(1.0, 0.90, 0.75),
	"impacto": Color(0.95, 0.90, 0.80),
	"contundente": Color(0.95, 0.90, 0.80),
	"agua": Color(0.40, 0.75, 1.0),
	"fogo": Color(1.0, 0.55, 0.15),
	"eletrico": Color(1.0, 0.95, 0.30),
	"gelo": Color(0.75, 0.95, 1.0),
	"veneno": Color(0.55, 0.95, 0.35),
	"cura": Color(0.45, 1.0, 0.60),
}
## Tipo de dano sem cor na tabela.
const COR_DANO_SEM_TIPO := Color.WHITE

## Controlos da câmara livre do Mestre: fundo 1e2830 a 30% (a dica usa-o a 45%), borda e o «nub» do manípulo.
const COR_CAMARA_LIVRE_FUNDO := Color(30.0 / 255.0, 40.0 / 255.0, 48.0 / 255.0, 0.30)
const COR_CAMARA_LIVRE_BORDA := Color(1.0, 1.0, 1.0, 0.55)
const COR_CAMARA_LIVRE_NUB := Color(1.0, 1.0, 1.0, 0.85)

# ================================================================ paleta da mesa (arena da jogadora)

const COR_MESA_CHAO := Color(0.30, 0.42, 0.26)
const COR_MESA_LINHAS := Color(0.0, 0.0, 0.0, 0.35)
const COR_MESA_MOVER := Color(0.30, 0.75, 1.0, 0.45)
const COR_MESA_ALVO := Color(1.0, 0.30, 0.25, 0.50)
const COR_MESA_CURSOR := Color(1.0, 0.90, 0.30, 0.65)
## Figuras: a minha, das outras jogadoras, das criaturas, mortas.
const COR_FIGURA_PROPRIA := Color(0.35, 0.60, 1.0)
const COR_FIGURA_JOGADORA := Color(0.40, 0.85, 0.50)
const COR_FIGURA_CRIATURA := Color(0.85, 0.35, 0.30)
const COR_FIGURA_MORTA := Color(0.35, 0.35, 0.35)
## Casa a arder (a mesma na arena da jogadora e na do Mestre).
const COR_FOGO := Color(1.0, 0.45, 0.10, 0.55)
## A marca da casa recusada ao pé (Ordem 60) e o rótulo dela.
const COR_RECUSA := Color(0.80, 0.10, 0.36, 0.60)
const COR_RECUSA_ROTULO := Color(1.0, 0.78, 0.84)

# ================================================================ paleta da mesa do Mestre

const COR_MESTRE_LINHAS := Color(0.788, 0.761, 0.655, 0.5)  # c9c2a7
const COR_MESTRE_DESTAQUE := Color(0.792, 0.710, 0.467, 0.5)  # cab577 a 50%
const COR_MESTRE_CONTORNO_DESTAQUE := Color("f5d59b")
const COR_MESTRE_ANEL := Color("ffd28b")
## O ambiente de recurso da arena do Mestre (fundo e luz ambiente).
const COR_MESTRE_FUNDO_AMBIENTE := Color(0.52, 0.66, 0.8)
const COR_MESTRE_LUZ_AMBIENTE := Color(0.85, 0.88, 0.92)

# ================================================================ marcador de figura (o do site, cena.js r3)

## Anel de identificação, pela ordem de entrada (`units.size % 5`).
const PALETA_ANEIS := [Color("87b4b0"), Color("e5bb74"), Color("b98b9d"), Color("b5c3ce"), Color("b7b77c")]
const COR_PEDRA := Color("817c73")
const COR_PEDRA_LOBO := Color("777b79")
## Sombra de contacto / mancha da base: 080c12, opacidade 0,35.
const COR_CONTACTO := Color(0.031, 0.047, 0.071, 0.35)
const RAIO_ANEL := 0.56
const RAIO_CONTACTO := 0.5

# ================================================================ alturas das figuras (m)
# A altura-alvo de cada TIPO de figura. A ficha manda quando traz `visual.alturaM` (as figuras do site já vêm
# ×1,25: a Ong 2,625 m); sem ela, vale a do tipo. Hoje o cliente só desenha marcadores (não há passo de
# importação de GLB a escalar modelos) e os dois tipos usam a mesma altura por omissão.

## A escala das figuras: regra do Mestre, figuras ×1,25.
const ESCALA_FIGURA := 1.25
## Humano de 1,80 m × 1,25 (Plano B §B1).
const ALTURA_PADRAO := 2.25
const ALTURAS_POR_TIPO := {
	"marcador": ALTURA_PADRAO,
	"marcador-lobo": ALTURA_PADRAO,
}

# ================================================================ tamanhos da mesa (m)

## A ESCALA DO MUNDO (Ordem ESCALA; palavra do Mestre, 20/11/2026, como no protótipo `hudt1-escala`): o lado de uma
## casa NÃO é fixo — o Mestre escolhe-o (1 · 1,5 · 2 m por casa) no selector dele (mestre.gd, «Mudar a escala»), e o
## servidor guarda a escala viva no mundo (`mapa.casaM`, ROOM_SNAPSHOT / MASTER_VIEW). Esta tabela é a fonte única,
## no cliente, das escalas que valem e da PRÉ-DEFINIDA (1,5 m: a escala com que a sala nasce e a que vale enquanto o
## servidor não disse outra). No servidor, a mesma lista é `ESCALAS_CASA_M`/`CASA_M` de servidor/nucleo/sala.js; o
## teste do cliente (rodar_testes, _teste_escala_do_mundo) confere que as duas dizem o mesmo.
## Toda a conta em metros é casas × escala viva (nunca × esta constante quando o servidor mandou a escala).
## O MAPA (grelha_floresta.CASA_M, relevo_floresta.CASA_M) guarda o seu próprio 1,5 m — é a malha do relevo, não a
## escala do mundo: esses ficheiros são fontes do terreno do servidor, conferidas por SHA (ver PENDENCIAS).
const ESCALAS_CASA_M := [1.0, 1.5, 2.0]
## A escala pré-definida (m por casa): a da sala que nasce.
const CASA_M := 1.5
## A grelha por omissão da arena da jogadora (o ROOM_SNAPSHOT.mapa manda).
const GRELHA_LARGURA_PADRAO := 20
const GRELHA_ALTURA_PADRAO := 20
## A altura do rótulo da recusa acima da casa.
const ALTURA_ROTULO_RECUSA := 1.6

# ================================================================ ecrã e letra

## A resolução de referência da interface (a escala é min(janela / base)).
const LARGURA_BASE := 1920.0
const ALTURA_BASE := 1080.0
const FONTE_BASE := 22
const FONTE_MIN_PX_REAIS := 13.0  # acima dos 12 px pedidos
const MARGEM_BASE := 24.0

# ================================================================ câmara da mesa

const ZOOM_PADRAO := 1.5  # palavra do Mestre

# ================================================================ pendências (valores por fechar ou a conferir)
# Registadas com o número; nenhuma se corrige nesta tabela.
const PENDENCIAS := [
	"Paleta: os papéis bronze, ouro, sangue, lendário, raro e mágico não têm valor — a Ordem 65 fechou só a paleta do AMBIENTE (color_script) e nenhum desses papéis existe hoje no cliente. Sem hexadecimal inventado.",
	"Casa: FECHADA pela Ordem ESCALA (palavra do Mestre, 20/11/2026) — a casa é a escala do mundo, 1 · 1,5 · 2 m, escolhida pelo Mestre; pré-definida 1,5 m (ESCALAS_CASA_M / CASA_M acima). A malha do mapa (grelha_floresta, relevo_floresta) continua a 1,5 m: ver a linha seguinte.",
	"Casa no mapa: grelha_floresta.CASA_M e relevo_floresta.CASA_M (1,5 m) ficam no mapa, sem ler da tabela — os dois ficheiros são fontes do terreno do servidor (servidor/dados/terreno-floresta.json, conferido por SHA no rodar_testes); religá-los obriga a refazer o terreno com exportar_terreno.gd. Fica para quando o terreno se refizer por outra razão.",
	"Degrau: não há tamanho de apresentação de degrau no cliente; o degrau de uma casa é medido do relevo (grelha_floresta.degrau) e o limite de passagem é regra do servidor.",
	"Alturas: não há passo de importação de GLB que escale modelos; só a altura por omissão dos marcadores (2,25 m). Alturas-alvo por tipo de modelo ficam por definir quando a importação existir.",
	"CORES_DANO: marcadas PROVISÓRIO no HUD desde a V1.2 (Plano B).",
]
