extends RefCounted
## grelha_floresta.gd — Ordem 38 (defeito 9): a FUNDAÇÃO DA GRELHA do mapa da floresta.
##
## O CONTRATO mundo ↔ casa (50 × 50 casas de 1,5 m — palavra do Mestre):
##   - a casa (0, 0) é o canto NOROESTE; a coluna cresce para LESTE (+X), a linha para SUL (+Z)
##     — a mesma leitura da arena do jogo (cenas/arena/arena.gd: «a casa y cresce para +Z»);
##   - o centro da casa (c, l) está em  x = −37,5 + (c + 0,5) × 1,5   z = −37,5 + (l + 0,5) × 1,5
##     e a sua altura é Relevo.altura(x, z) — a ALTURA FINAL ÚNICA (malha = colisão = consulta);
##   - um ponto do mundo pertence à casa (floor((x + 37,5) / 1,5), floor((z + 37,5) / 1,5)).
##
## TERRENO (estático, escrito pelo mapa ao construir-se): cada casa sabe se está BLOQUEADA
## (tronco, rocha, menir, água funda, escarpa…) e que COBERTURA dá (0 nenhuma, 1 meia, 2 total).
##
## OCUPAÇÃO (dinâmica): quem está em cada casa. O cliente nunca decide regra — quem manda é o
## servidor; esta tabela é o espelho local onde o cliente pousa o que o servidor projectou e
## pergunta «esta casa está livre?». As recusas devolvem um erro NOMEADO (erros_floresta.gd),
## nunca calam.

const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const Erros := preload("res://mapa/floresta/erros_floresta.gd")

## ORDEM DADOS DE APRESENTAÇÃO: o lado da casa vem da tabela única.
const Apresentacao := preload("res://dados/apresentacao.gd")
const LADO := 50
const CASA_M := Apresentacao.CASA_M
const MEIO := 37.5
const FORA := Vector2i(-1, -1)

const COBERTURA_NENHUMA := 0
const COBERTURA_MEIA := 1
const COBERTURA_TOTAL := 2

## Emitido sempre que a ocupação de uma casa muda (casa, quem saiu, quem entrou; "" = ninguém).
signal ocupacao_mudou(casa: Vector2i, antes: String, depois: String)

var _bloqueio := PackedByteArray()        # 0 = passa; 1 = bloqueada
var _motivo: Dictionary = {}              # índice -> nome do que bloqueia
var _cobertura := PackedByteArray()
var _ocupante: Dictionary = {}            # índice -> id
var _casa_de: Dictionary = {}             # id -> índice


func _init() -> void:
	_bloqueio.resize(LADO * LADO)
	_cobertura.resize(LADO * LADO)


# ------------------------------------------------------------------ contrato mundo ↔ casa

static func dentro(casa: Vector2i) -> bool:
	return casa.x >= 0 and casa.y >= 0 and casa.x < LADO and casa.y < LADO


static func indice(casa: Vector2i) -> int:
	return casa.y * LADO + casa.x


static func casa_do_indice(i: int) -> Vector2i:
	return Vector2i(i % LADO, i / LADO)


## A casa que contém o ponto (x, z) do mundo, ou FORA.
static func casa_em(x: float, z: float) -> Vector2i:
	var c := Vector2i(floori((x + MEIO) / CASA_M), floori((z + MEIO) / CASA_M))
	return c if dentro(c) else FORA


## Centro da casa em cima do chão (a altura final única). Casa fora da grelha: erro nomeado.
static func centro(casa: Vector2i) -> Vector3:
	if not dentro(casa):
		Erros.erro(Erros.CASA_FORA, "centro(%s)" % casa)
		return Vector3.ZERO
	var x := -MEIO + (casa.x + 0.5) * CASA_M
	var z := -MEIO + (casa.y + 0.5) * CASA_M
	return Vector3(x, Relevo.altura(x, z), z)


## Canto noroeste da casa (x, z no mundo).
static func canto(casa: Vector2i) -> Vector2:
	return Vector2(-MEIO + casa.x * CASA_M, -MEIO + casa.y * CASA_M)


static func altura_casa(casa: Vector2i) -> float:
	return centro(casa).y


## Desnível (m) de `de` para `para`: positivo = sobe.
static func desnivel(de: Vector2i, para: Vector2i) -> float:
	return altura_casa(para) - altura_casa(de)


## Maior diferença de altura dentro da casa (entre os 4 cantos e o centro): mede a inclinação.
static func degrau(casa: Vector2i) -> float:
	var c := canto(casa)
	var lo := INF
	var hi := -INF
	for p in [Vector2(0, 0), Vector2(CASA_M, 0), Vector2(0, CASA_M), Vector2(CASA_M, CASA_M), Vector2(CASA_M * 0.5, CASA_M * 0.5)]:
		var h := Relevo.altura(c.x + p.x, c.y + p.y)
		lo = minf(lo, h)
		hi = maxf(hi, h)
	return hi - lo


static func vizinhas(casa: Vector2i, com_diagonais: bool = true) -> Array[Vector2i]:
	var r: Array[Vector2i] = []
	for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		if not com_diagonais and d.x != 0 and d.y != 0:
			continue
		if dentro(casa + d):
			r.append(casa + d)
	return r


# ------------------------------------------------------------------ terreno (estático)

func bloquear(casa: Vector2i, motivo: String) -> void:
	if not dentro(casa):
		return
	_bloqueio[indice(casa)] = 1
	_motivo[indice(casa)] = motivo
	_cobertura[indice(casa)] = COBERTURA_TOTAL


func bloqueada(casa: Vector2i) -> bool:
	return dentro(casa) and _bloqueio[indice(casa)] == 1


## O que bloqueia a casa ("" se nada).
func motivo_bloqueio(casa: Vector2i) -> String:
	return String(_motivo.get(indice(casa), "")) if dentro(casa) else ""


func dar_cobertura(casa: Vector2i, nivel: int) -> void:
	if dentro(casa) and nivel > _cobertura[indice(casa)]:
		_cobertura[indice(casa)] = nivel


func cobertura(casa: Vector2i) -> int:
	return _cobertura[indice(casa)] if dentro(casa) else COBERTURA_NENHUMA


func casas_bloqueadas() -> int:
	return _bloqueio.count(1)


# ------------------------------------------------------------------ ocupação (dinâmica)

func ocupante(casa: Vector2i) -> String:
	return String(_ocupante.get(indice(casa), "")) if dentro(casa) else ""


## Livre = dentro da grelha, não bloqueada pelo terreno e sem ocupante.
func livre(casa: Vector2i) -> bool:
	return dentro(casa) and _bloqueio[indice(casa)] == 0 and not _ocupante.has(indice(casa))


func casa_de(id: String) -> Vector2i:
	return casa_do_indice(_casa_de[id]) if _casa_de.has(id) else FORA


## Pousa `id` na casa. Devolve "" se pousou, ou o NOME do erro (e a casa fica como estava).
## Se `id` já estava noutra casa, muda-se (a antiga fica livre).
func ocupar(casa: Vector2i, id: String) -> String:
	if not dentro(casa):
		return Erros.CASA_FORA
	var k := indice(casa)
	if _bloqueio[k] == 1:
		return Erros.CASA_BLOQUEADA
	if _ocupante.has(k):
		return "" if _ocupante[k] == id else Erros.CASA_OCUPADA
	if _casa_de.has(id):
		var antiga: int = _casa_de[id]
		_ocupante.erase(antiga)
		ocupacao_mudou.emit(casa_do_indice(antiga), id, "")
	_ocupante[k] = id
	_casa_de[id] = k
	ocupacao_mudou.emit(casa, "", id)
	return ""


## Tira `id` da grelha. Devolve "" ou o NOME do erro.
func libertar(id: String) -> String:
	if not _casa_de.has(id):
		return Erros.OCUPANTE_DESCONHECIDO
	var k: int = _casa_de[id]
	_casa_de.erase(id)
	_ocupante.erase(k)
	ocupacao_mudou.emit(casa_do_indice(k), id, "")
	return ""


func limpar_ocupacao() -> void:
	for id in _casa_de.keys():
		libertar(id)


func ocupantes() -> Dictionary:
	var r := {}
	for id in _casa_de:
		r[id] = casa_do_indice(_casa_de[id])
	return r


## A casa livre mais próxima de `casa` (ela própria se estiver livre): busca em largura, as
## vizinhas em ordem de leitura — a mesma regra do servidor (ordem 34, D-1). FORA se não há.
func livre_mais_proxima(casa: Vector2i) -> Vector2i:
	if not dentro(casa):
		return FORA
	var visto := PackedByteArray()
	visto.resize(LADO * LADO)
	var fila: Array[Vector2i] = [casa]
	visto[indice(casa)] = 1
	var cabeca := 0
	while cabeca < fila.size():
		var c := fila[cabeca]
		cabeca += 1
		if livre(c):
			return c
		for v in vizinhas(c):
			if visto[indice(v)] == 0:
				visto[indice(v)] = 1
				fila.append(v)
	return FORA


# ------------------------------------------------------------------ para o servidor

## O terreno que o servidor lê NÃO sai daqui: sai de cenas/arena/ferramentas/exportar_terreno.gd, que mede as casas
## DO JOGO com as funções com que a arena desenha (alturas em precisão inteira, o pé da Ordem 44) e escreve o mapa
## inteiro (Ordem 48). A antiga exportar_terreno() desta grelha (Ordem 38: alturas ao centímetro, casas do mapa) foi
## apagada na Ordem 48 — ninguém a chamava e dava números que não eram os do jogo.
