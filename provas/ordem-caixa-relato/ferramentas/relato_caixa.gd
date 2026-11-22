extends RefCounted
## Ordem CAIXA-RELATO (B7b da conferência da CAIXA-HUD-JOGADORA, 21/11/2026) — a linha do relato das provas da caixa
## que imprime a caixa que chegou ao aparelho da jogadora.
##
## Antes: a linha imprimia `Estado.caixa` — o JSON do ÚLTIMO ROOM_SNAPSHOT — sem dizer de quando era. No §4 da prova,
## depois do snapshot a caixa da jogadora adianta-se pelos EVENTOS que ela recebe (a volta fecha), e o JSON do snapshot
## (`"fechada":false`, 3 figuras) saía logo abaixo de «fechada: true», a passar por actual.
##
## Agora: a linha diz SEMPRE de que snapshot é o JSON (seq, revisão, hora da chegada, quantos eventos chegaram depois) e
## compara-o com a caixa ACTUAL dela (o modelo do HUD, `hud.ordem_turnos`, que é o que os eventos adiantam). Se forem
## diferentes, a linha marca «DESACTUALIZADO» antes do JSON velho e imprime também o actual. Só ids (opacos) e os campos
## da caixa da Party (ligada, ordemPor, ordemDinamica) — nenhum nome verdadeiro, vida, alma ou PA entra no registo.
##
## Sem estado: é carregado pelas ferramentas das provas (prova_caixa_jogadora.gd, prova_caixa_manequim.gd) e pelo
## teste teste_relato_caixa.gd.


## A caixa ACTUAL da jogadora, na mesma forma da do snapshot: ligada/ordemPor só mudam por snapshot (escolha do
## Mestre), a ordemDinamica é a do modelo do HUD (adianta-se pelos eventos). `ordem_turnos` = hud.ordem_turnos.
static func caixa_actual(caixa_snapshot: Dictionary, ordem_turnos) -> Dictionary:
	if caixa_snapshot.is_empty():
		return {}
	var ordem: Array = []
	for id in ordem_turnos.ordem_dinamica:
		ordem.append(str(id))
	return {
		"ligada": caixa_snapshot.get("ligada"),
		"ordemPor": caixa_snapshot.get("ordemPor"),
		"ordemDinamica": {"ordem": ordem, "fechada": ordem_turnos.fechada == true, "ultimo": str(ordem_turnos.ultimo)},
	}


## A ordemDinamica normalizada (ids em texto, fechada booleana, ultimo em texto) — para comparar sem tropeçar em
## tipos (o JSON traz Array genérico, o modelo Array[String]).
static func _od_normal(c: Dictionary) -> Dictionary:
	var od = c.get("ordemDinamica")
	if not (od is Dictionary):
		return {}
	var ordem: Array = []
	if od.get("ordem") is Array:
		for id in od["ordem"]:
			ordem.append(str(id))
	var ultimo = od.get("ultimo")
	return {"ordem": ordem, "fechada": od.get("fechada") == true, "ultimo": "" if ultimo == null else str(ultimo)}


## true = o JSON do snapshot já não é a caixa dela (os eventos depois dele adiantaram-na).
static func desactualizado(caixa_snapshot: Dictionary, actual: Dictionary) -> bool:
	if caixa_snapshot.is_empty() and actual.is_empty():
		return false
	return JSON.stringify(_od_normal(caixa_snapshot)) != JSON.stringify(_od_normal(actual)) \
		or caixa_snapshot.get("ligada") != actual.get("ligada") or caixa_snapshot.get("ordemPor") != actual.get("ordemPor")


## Um número do JSON (que chega como float) escrito como inteiro; o resto como texto.
static func _num(v) -> String:
	if v is float and v == floorf(v):
		return str(int(v))
	return "?" if v == null else str(v)


## A origem do JSON: {seq, revisao, hora, eventos} (o que a ferramenta guardou ao receber o snapshot e os eventos).
static func _origem(snap: Dictionary) -> String:
	return "ROOM_SNAPSHOT seq %s, revisão %s, chegou às %s; %d evento(s) depois dele" % [
		_num(snap.get("seq")), _num(snap.get("revisao")), str(snap.get("hora", "?")), int(snap.get("eventos", 0))]


## O texto da verificação (sem o «ok»/«FALHA», que é do _ok da ferramenta). Lê-se numa linha: de que snapshot é o
## JSON, se é o actual, e — se não for — qual é o actual.
static func linha(rotulo: String, caixa_snapshot: Dictionary, snap: Dictionary, actual: Dictionary) -> String:
	var base := rotulo + ": a caixa que lhe chegou só tem ligada, ordemPor e ordemDinamica"
	if desactualizado(caixa_snapshot, actual):
		return "%s — JSON DESACTUALIZADO (é o do %s, que a adiantaram): %s · a caixa ACTUAL dela (revisão %s): %s" % [
			base, _origem(snap), JSON.stringify(caixa_snapshot), _num(snap.get("revisao_actual")), JSON.stringify(actual)]
	return "%s — JSON actual (do %s; a caixa dela é esta): %s" % [base, _origem(snap), JSON.stringify(caixa_snapshot)]
