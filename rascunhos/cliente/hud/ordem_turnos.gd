extends RefCounted
## Ordem HUD — o MODELO da CAIXA DA ORDEM DE TURNOS (desenho = palavra do Mestre, 16/11/2026 11:18).
##
## Não é previsão: a caixa mostra a ordem QUE EXISTE. Dois modos, que o Mestre escolhe:
##
## - DINÂMICO (por defeito, sem iniciativa): a batalha não tem turnos fixos — o Mestre dita quem vai. A ordem
##   EMERGE da sequência de quem agiu e REPETE-SE. Exemplo do Mestre: as jogadoras surpreendem um monstro; ataca a
##   jogadora 1, depois a 2, depois a 3, depois o monstro → a ordem ficou 1-2-3-monstro e repete.
##   Conta como «agiu» o que o servidor narra como acção de alguém: `movimento` (figuraId), `ataque` que NÃO é de
##   oportunidade (atacanteId), `cura` (curadorId) e `consumivel` (figuraId). Várias acções seguidas da mesma
##   figura são uma só vez. Quando uma figura que já está na ordem volta a agir, a volta FECHA: a ordem passa a
##   repetir-se. Depois de fechada, se alguém age fora da sequência (o Mestre ditou outra coisa), a figura passa
##   a ficar logo a seguir a quem agiu antes dela — a caixa segue sempre a última sequência que aconteceu.
## - INICIATIVA (o botão «Modo iniciativa» do Mestre): a ordem é a do servidor (`iniciativa` do snapshot — só a
##   ORDEM, nunca os valores) e quem está na vez é `vezId`. O cliente não rola nem inventa a fórmula.
##
## Só guarda e ordena ids. Nunca calcula regra. Sem nós: os testes usam-no sem árvore.

const DINAMICO := "dinamico"
const INICIATIVA := "iniciativa"

var modo := DINAMICO
## A ordem formada pelas acções (ids), pela ordem em que agiram pela primeira vez nesta volta.
var ordem_dinamica: Array[String] = []
## A volta fechou: a ordem já se repetiu pelo menos uma vez.
var fechada := false
## Quem agiu por último (a figura «na vez» no modo dinâmico).
var ultimo := ""
## Quantas vezes distintas se registaram (para os testes e o registo).
var vezes := 0


## O id de quem agiu neste evento, ou "" se o evento não é uma acção de alguém.
static func actor_do_evento(evento: Dictionary) -> String:
	var tipo := str(evento.get("tipo", ""))
	var d = evento.get("dados")
	if not (d is Dictionary):
		return ""
	match tipo:
		"movimento", "consumivel":
			return _id(d.get("figuraId"))
		"ataque":
			if d.get("ataqueDeOportunidade") == true:
				return ""  # a reacção de oportunidade não é «ir»
			return _id(d.get("atacanteId"))
		"cura":
			return _id(d.get("curadorId"))
	return ""


## Lê um ROOM_EVENT. Devolve true se a ordem dinâmica mudou (ou a vez passou).
func registar_evento(evento: Dictionary) -> bool:
	var tipo := str(evento.get("tipo", ""))
	if tipo == "recomeco" or tipo == "revertido":
		# «Recomeçar» e «Voltar até aqui»: a sequência de antes deixa de ser a que aconteceu.
		var tinha := not ordem_dinamica.is_empty()
		limpar_dinamica()
		return tinha
	var id := actor_do_evento(evento)
	if id == "":
		return false
	return registar_acao(id)


## Uma figura agiu. Devolve true se a vez passou (ou a ordem mudou).
func registar_acao(id: String) -> bool:
	if id == "" or id == ultimo:
		return false  # mais uma acção da mesma vez
	var anterior := ultimo
	ultimo = id
	vezes += 1
	var i := ordem_dinamica.find(id)
	if not fechada:
		if i < 0:
			ordem_dinamica.append(id)
		else:
			fechada = true  # voltou a agir quem já estava: a ordem repete-se
			_colocar_depois(id, anterior)
		return true
	# Fechada: quem age a seguir ao esperado não muda nada; fora da sequência, passa para depois de quem agiu antes.
	if i >= 0 and anterior != "" and _seguinte_de(anterior) == id:
		return true
	_colocar_depois(id, anterior)
	return true


## Põe `id` logo a seguir a `anterior` na ordem (se `anterior` lá estiver); senão, no fim.
func _colocar_depois(id: String, anterior: String) -> void:
	var a := ordem_dinamica.find(anterior)
	if a < 0:
		if not ordem_dinamica.has(id):
			ordem_dinamica.append(id)
		return
	if _seguinte_de(anterior) == id:
		return
	ordem_dinamica.erase(id)
	a = ordem_dinamica.find(anterior)
	ordem_dinamica.insert(a + 1, id)


func _seguinte_de(id: String) -> String:
	var i := ordem_dinamica.find(id)
	if i < 0 or ordem_dinamica.is_empty():
		return ""
	return ordem_dinamica[(i + 1) % ordem_dinamica.size()]


func limpar_dinamica() -> void:
	ordem_dinamica.clear()
	fechada = false
	ultimo = ""
	vezes = 0


## O Mestre carregou em «Modo iniciativa» (ligar) ou desligou-o. A ordem dinâmica guarda-se: desligar volta a ela.
func definir_modo(novo: String) -> void:
	modo = INICIATIVA if novo == INICIATIVA else DINAMICO


## A ordem a mostrar, só com figuras que existem no espelho (`figuras`: id -> {...}).
## Dinâmico: a ordem formada. Iniciativa: a ordem do servidor (Estado.iniciativa).
func ordem_visivel(iniciativa: Array, figuras: Dictionary) -> Array[String]:
	var fonte: Array = iniciativa if modo == INICIATIVA else ordem_dinamica
	var out: Array[String] = []
	for v in fonte:
		var id := _id(v)
		if id != "" and figuras.has(id) and not out.has(id):
			out.append(id)
	return out


## Quem está na vez: dinâmico = quem agiu por último; iniciativa = o `vezId` do servidor.
func na_vez(vez_id: String) -> String:
	return vez_id if modo == INICIATIVA else ultimo


static func _id(v) -> String:
	return v if v is String else ""
