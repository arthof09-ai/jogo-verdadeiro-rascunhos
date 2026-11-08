extends RefCounted
## Frases de batalha IGUAIS às do site vivo (jogo-t1/jogo.js, REF_25, SHA d022aae4…):
## `vlabFraseDesgraca` (linha 1020), o relógio de morte (linhas 1083, 1090) e o fim (2162–2165).
## Enviadas pelo Muse (CM-000009) e conferidas pelo I0004 contra o jogo.js servido (08/11/2026).
##
## O cliente nunca calcula regra: só escolhe a frase a partir do que o servidor projetou
## (`desgraca` {figuraId, efeito, perdeQuarto?}, `teste_morte` {figuraId}, `estado` com o
## `estadoMorte` DELA, `fim` {desfecho}). Sem números de ninguém.
##
## Tratamento: o site usa «tu» («Aperta»). A pergunta tu/você está com o Mestre; até lá as frases
## ficam como no site.

## Cabeçalho que o site põe antes da frase da desgraça.
const CABECALHO_DESGRACA := "Falha crítica · "

## O site acaba as frases de fim com «Aperta Recomeçar para jogar outra vez.». Com a resposta N4 do Mestre
## (08/11: «Claro que quero») o jogo tem o «Recomeçar» (no ecrã do Mestre) e, pela regra-mãe (vale o site),
## a frase completa do site volta a valer.
const CLAUSULA_RECOMECAR := " Aperta Recomeçar para jogar outra vez."
const HA_BOTAO_RECOMECAR := true


## Nome como o site o escreve dentro da frase: a jogadora com artigo («a Ong»), a criatura só com
## o nome da cena («Lobo»).
static func nome_em_frase(nome: String, e_jogadora: bool) -> String:
	return ("a " + nome) if e_jogadora else nome


## Frase da desgraça (sem cabeçalho). `arma` é o nome legível da arma de quem falhou.
static func desgraca(efeito: String, nome: String, e_jogadora: bool, arma: String, perde_quarto: bool) -> String:
	var n := nome_em_frase(nome, e_jogadora)
	match efeito:
		"cai":
			return "%s foi ao chão com o golpe falhado." % n
		"arma-cai":
			return "A arma (%s) caiu-lhe da mão." % arma
		"arma-quebra":
			return "A arma (%s) quebrou — fica inutilizável até ser consertada." % arma
		"acerta-se":
			return "%s atingiu-se a si %s com o próprio golpe." % [n, "própria" if e_jogadora else "próprio"]
		"quebra-corpo":
			var frase := "%s quebrou algo no corpo — os golpes %s ficam prejudicados e anda metade até ao fim do combate." % [
				n, "dela" if e_jogadora else "dele"]
			if perde_quarto:
				frase += " Perde um quarto da vida que tem agora."
			return frase
		"acerta-amigo":
			return "O golpe atingiu um aliado sem querer."
		_:
			return "O golpe correu mal."


## Apanhar a arma caída (jogo.js linha 2360, botão de ataque com a arma no chão): gasta o movimento desta vez.
static func apanhou_arma(nome: String, arma: String) -> String:
	return "A %s apanha o %s do chão — isso gasta o movimento desta vez." % [nome, arma]


static func com_cabecalho(frase: String) -> String:
	return CABECALHO_DESGRACA + frase


# ---------------------------------------------------------------- relógio de morte (só DELA)

static func caiu(nome: String) -> String:
	return "A %s caiu — a batalha continua à volta dela." % nome


static func aguenta(nome: String) -> String:
	return "A %s, caída, aguenta-se — continua a respirar." % nome


static func piora(nome: String) -> String:
	return "A %s, caída, piora visivelmente." % nome


## Fim por vitória (jogo.js linha 2162). Sem nome (espectador), fica «vitória nesta batalha».
static func fim_vitoria(nome: String) -> String:
	var de := (" da " + nome) if nome != "" else ""
	return "Os inimigos caíram todos — vitória%s nesta batalha.%s" % [de, CLAUSULA_RECOMECAR if HA_BOTAO_RECOMECAR else ""]


static func fim_estabilizada(nome: String) -> String:
	return "A %s caiu, mas estabilizou — fim desta batalha.%s" % [nome, CLAUSULA_RECOMECAR if HA_BOTAO_RECOMECAR else ""]


## Fim declarado pelo Mestre («Terminar batalha», N4), com a frase do site (jogo.js terminarBatalha, M-014).
static func fim_terminada() -> String:
	return "A batalha terminou — a mesa fechou este encontro.%s" % [CLAUSULA_RECOMECAR if HA_BOTAO_RECOMECAR else ""]


static func fim_morte(nome: String) -> String:
	return "A %s caiu — fim desta batalha.%s" % [nome, CLAUSULA_RECOMECAR if HA_BOTAO_RECOMECAR else ""]
