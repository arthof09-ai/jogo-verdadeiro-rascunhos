extends RefCounted
## erros_floresta.gd — Ordem 38: os erros do mapa da floresta têm NOME.
##
## Nada falha calado: quem encontra um problema chama Erros.erro(CODIGO, detalhe). O erro vai
## para a consola (push_error, com o código à frente), fica no registo, e as ferramentas de
## prova saem com código ≠ 0 se o registo não estiver vazio (Erros.contagem()).

const CEU_EM_FALTA := "FLORESTA-E01-CEU-EM-FALTA"            # a pintura do céu não abriu
const NO_EM_FALTA := "FLORESTA-E02-NO-EM-FALTA"              # a cena não tem o nó esperado
const FICHEIRO_NAO_GRAVOU := "FLORESTA-E03-FICHEIRO-NAO-GRAVOU"
const FICHEIRO_NAO_ABRIU := "FLORESTA-E04-FICHEIRO-NAO-ABRIU"
const VISTA_INVALIDA := "FLORESTA-E05-VISTA-INVALIDA"
const CASA_FORA := "FLORESTA-E06-CASA-FORA-DA-GRELHA"
const CASA_OCUPADA := "FLORESTA-E07-CASA-OCUPADA"
const CASA_BLOQUEADA := "FLORESTA-E08-CASA-BLOQUEADA"
const OCUPANTE_DESCONHECIDO := "FLORESTA-E09-OCUPANTE-DESCONHECIDO"
const ALTURA_DIVERGE := "FLORESTA-E10-ALTURA-DIVERGE"        # malha, colisão e consulta não batem
const MALHA_VAZIA := "FLORESTA-E11-MALHA-VAZIA"
const SEM_GPU := "FLORESTA-E12-SEM-JANELA-GPU"               # a ferramenta precisa de render
const COZEDURA_FORA_DE_ORDEM := "FLORESTA-E13-COZEDURA-FORA-DE-ORDEM"  # carimbo depois de cozer
const ARGUMENTO_INVALIDO := "FLORESTA-E14-ARGUMENTO-INVALIDO"
const SEM_APOIO := "FLORESTA-E15-SEM-APOIO"                  # alguma coisa ficou a flutuar

static var _registo: Array[String] = []


static func erro(codigo: String, detalhe: String = "") -> void:
	var linha := codigo if detalhe == "" else "%s: %s" % [codigo, detalhe]
	_registo.append(linha)
	push_error("[floresta] " + linha)


static func contagem() -> int:
	return _registo.size()


static func registo() -> Array[String]:
	return _registo.duplicate()


static func limpar() -> void:
	_registo.clear()
