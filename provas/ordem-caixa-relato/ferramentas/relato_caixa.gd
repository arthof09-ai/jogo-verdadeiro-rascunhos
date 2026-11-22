extends RefCounted
## Ordem CAIXA-RELATO (B7b da conferência da CAIXA-HUD-JOGADORA, 21/11/2026) — a linha do relato das provas da caixa
## que imprime a caixa que chegou ao aparelho da jogadora.
##
## Antes: a linha imprimia `Estado.caixa` — o JSON do ÚLTIMO ROOM_SNAPSHOT — sem dizer de quando era. No §4 da prova,
## depois do snapshot a caixa da jogadora adianta-se pelos EVENTOS que ela recebe (a volta fecha), e o JSON do snapshot
## (`"fechada":false`, 3 figuras) saía logo abaixo de «fechada: true», a passar por actual.
##
## Agora: a linha diz SEMPRE de que snapshot é o JSON (seq, revisão, hora da aplicação com milissegundos, quantos eventos
## foram aplicados depois dele, de que tipos, e quantos desses têm actor) e compara-o com a caixa ACTUAL dela. Se forem
## diferentes, a linha marca «DESACTUALIZADO» antes do JSON velho e imprime também o actual. Só ids (opacos) e os campos
## da caixa da Party (ligada, ordemPor, ordemDinamica) — nenhum nome verdadeiro, vida, alma ou PA entra no registo.
##
## Ordem CAIXA-RELATO-CORRECOES (conferência da CAIXA-RELATO, 21/11/2026):
##  - B1: o contador ouve a APLICAÇÃO (`Estado.snapshot_aplicado` / `Estado.evento_aplicado`), não a recepção da Rede (um
##    snapshot velho que o Estado recusa, ou um evento repetido, já não mexem nele). Conta todos os eventos aplicados e,
##    à parte, os de actor (`OrdemTurnos.actor_do_evento` ≠ "") — os únicos que podem adiantar a caixa; o `turno` que um
##    `encerrar` produz não adianta. A linha deixou de dizer «que a adiantaram» (não é verdade para todos).
##  - B2: os tipos dos eventos ficam na linha («[movimento, turno, …]»).
##  - B3: a hora leva milissegundos — dois snapshots no mesmo segundo deixam de ser indistinguíveis.
##  - B4: `caixa_actual` só vale em modo DINÂMICO (ver o comentário dela).
##
## Sem estado (a origem do snapshot vive num Dictionary que a ferramenta guarda): é carregado pelas ferramentas das
## provas (prova_caixa_jogadora.gd, prova_caixa_manequim.gd) e pelo teste teste_relato_caixa.gd.


const OrdemTurnos := preload("res://hud/ordem_turnos.gd")


## A caixa ACTUAL da jogadora, na mesma forma da do snapshot. SÓ VALE EM MODO DINÂMICO: a `ordemDinamica` vem do modelo
## da ordem do HUD (`hud.ordem_turnos`, que os eventos de actor adiantam) — em modo iniciativa o HUD mostra a ordem de
## `Estado.iniciativa` e a vez de `Estado.vezId`, que este ajudante NÃO lê (as provas só chamam a linha com a caixa em
## dinâmico ou desligada; no §2, em iniciativa, a verificação é outra). E não é «o modelo do HUD» por inteiro: `ligada`
## e `ordemPor` vêm do SNAPSHOT (só mudam por snapshot, na escolha do Mestre); só a `ordemDinamica` vem do modelo.
## `ordem_turnos` = hud.ordem_turnos.
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


## A hora local com milissegundos («HH:MM:SS.mmm») — B3.
static func hora_ms() -> String:
	# Um só instante para os segundos e os milissegundos (duas leituras do relógio podiam cair em segundos diferentes).
	var t := Time.get_unix_time_from_system()
	var local := int(floor(t)) + int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	return "%s.%03d" % [Time.get_time_string_from_unix_time(local), int(fmod(t, 1.0) * 1000.0)]


## A origem de um snapshot acabado de APLICAR (Estado.snapshot_aplicado): {seq, revisao, hora, eventos, de_actor, tipos}.
static func novo_snap(seq, revisao, hora: String = "") -> Dictionary:
	return {"seq": seq, "revisao": revisao, "hora": hora if hora != "" else hora_ms(), "eventos": 0, "de_actor": 0, "tipos": []}


## Um evento APLICADO depois do snapshot (Estado.evento_aplicado): conta-o, guarda o tipo e, se tiver actor (o único que
## pode adiantar a ordem dinâmica — as mesmas regras do modelo do HUD), conta-o também à parte.
static func anotar_evento(snap: Dictionary, evento: Dictionary) -> void:
	snap["eventos"] = int(snap.get("eventos", 0)) + 1
	if not (snap.get("tipos") is Array):
		snap["tipos"] = []
	snap["tipos"].append(str(evento.get("tipo", "?")))
	if OrdemTurnos.actor_do_evento(evento) != "":
		snap["de_actor"] = int(snap.get("de_actor", 0)) + 1


## A origem do JSON: de que snapshot é, a que horas foi aplicado e o que foi aplicado depois dele.
static func _origem(snap: Dictionary) -> String:
	var tipos: Array = snap.get("tipos", []) if snap.get("tipos") is Array else []
	return "ROOM_SNAPSHOT seq %s, revisão %s, aplicado às %s; %d evento(s) aplicado(s) depois dele %s, %d de actor (só esses podem adiantá-la)" % [
		_num(snap.get("seq")), _num(snap.get("revisao")), str(snap.get("hora", "?")), int(snap.get("eventos", 0)),
		"[" + ", ".join(PackedStringArray(tipos)) + "]", int(snap.get("de_actor", 0))]


## O texto da verificação (sem o «ok»/«FALHA», que é do _ok da ferramenta). Lê-se numa linha: de que snapshot é o
## JSON, se é o actual, e — se não for — qual é o actual.
static func linha(rotulo: String, caixa_snapshot: Dictionary, snap: Dictionary, actual: Dictionary) -> String:
	var base := rotulo + ": a caixa que lhe chegou só tem ligada, ordemPor e ordemDinamica"
	if desactualizado(caixa_snapshot, actual):
		return "%s — JSON DESACTUALIZADO (é o do %s): %s · a caixa ACTUAL dela (revisão %s): %s" % [
			base, _origem(snap), JSON.stringify(caixa_snapshot), _num(snap.get("revisao_actual")), JSON.stringify(actual)]
	return "%s — JSON actual (do %s; a caixa dela é esta): %s" % [base, _origem(snap), JSON.stringify(caixa_snapshot)]
