extends SceneTree
## Ordem CAIXA-RELATO (B7b) — o teste do REGISTO da linha da caixa (relato_caixa.gd), sem servidor e sem ecrã, com o
## MODELO REAL do HUD (res://hud/ordem_turnos.gd). Reproduz o §4 da prova da caixa: a caixa chega num snapshot
## (3 figuras, fechada false), os eventos que a jogadora recebe adiantam-na (Bruto, Arqueira: a volta fecha) e a linha
## tem de dizer que o JSON é o velho e qual é o actual. E o contrário (§1/§5): snapshot acabado de chegar = actual.
## Ordem CAIXA-RELATO-CORRECOES: o contador do ajudante (novo_snap/anotar_evento — o mesmo que as provas usam) com
## contagens EXACTAS e os tipos; o caso vivo de um `encerrar` (só um `turno`) que não muda a caixa (B2); a hora com
## milissegundos (B3); a privacidade varre todas as linhas, incluindo as «JSON actual» (B6).
##
## Correr (na raiz do repo):
##   godot --headless --path rascunhos/cliente -s "$PWD/provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd"

const OrdemTurnos := preload("res://hud/ordem_turnos.gd")

var _total := 0
var _falhas := 0


func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		print("  FALHA ", nome)
		printerr("  FALHA ", nome)


func _init() -> void:
	var R = load(str(get_script().resource_path).get_base_dir().path_join("relato_caixa.gd"))
	if R == null:
		printerr("não abriu relato_caixa.gd")
		quit(2)
		return
	print("== Ordem CAIXA-RELATO — o registo da caixa da jogadora no relato da prova ==")
	# Ids opacos como os da prova (a Party só vê ids e nomes públicos; aqui nem nomes).
	var arq := "ff2acf60bd672e76e"
	var lobo := "f08e6e9dc41e7a378"
	var esp := "f20af3254ba898103"
	var bruto := "f1c67641aa5cdfe28"
	var snap_caixa := {"ligada": true, "ordemPor": "dinamico",
		"ordemDinamica": {"fechada": false, "ordem": [arq, lobo, esp], "ultimo": esp}}
	var linhas: Array = []  # todas as linhas geradas — a privacidade varre-as todas (B6)

	# --- §1/§5: o snapshot acabou de ser aplicado; o modelo carregou-o; nenhum evento depois.
	var snap: Dictionary = R.novo_snap(9.0, 31.0, "21:30:00.125")
	snap["revisao_actual"] = 31
	var m := OrdemTurnos.new()
	m.definir_modo("dinamico")
	m.carregar_do_servidor(snap_caixa["ordemDinamica"])
	var act: Dictionary = R.caixa_actual(snap_caixa, m)
	var l: String = R.linha("1", snap_caixa, snap, act)
	linhas.append(l)
	print("  linha: ", l)
	_ok(not R.desactualizado(snap_caixa, act), "acabado de chegar: o JSON do snapshot é a caixa actual")
	_ok(l.contains("JSON actual") and not l.contains("DESACTUALIZADO"), "acabado de chegar: a linha diz «JSON actual», sem «DESACTUALIZADO»")
	_ok(l.contains("seq 9") and l.contains("revisão 31") and l.contains("21:30:00.125") and l.contains("0 evento(s) aplicado(s) depois dele [], 0 de actor"),
		"acabado de chegar: a linha diz de que snapshot é (seq, revisão, hora com ms, 0 eventos, nenhum tipo, 0 de actor)")
	_ok(l.contains(JSON.stringify(snap_caixa)), "acabado de chegar: a linha traz o JSON do snapshot tal como chegou")

	# --- B3: a hora leva milissegundos — dois snapshots aplicados no mesmo segundo distinguem-se.
	var s1: Dictionary = R.novo_snap(13, 10)
	OS.delay_msec(5)
	var s2: Dictionary = R.novo_snap(13, 10)
	var re := RegEx.create_from_string("^\\d\\d:\\d\\d:\\d\\d\\.\\d\\d\\d$")
	_ok(re.search(str(s1["hora"])) != null and re.search(str(s2["hora"])) != null, "a hora é HH:MM:SS.mmm (%s)" % s1["hora"])
	_ok(str(s1["hora"]) != str(s2["hora"]) and R.linha("x", snap_caixa, s1, act) != R.linha("x", snap_caixa, s2, act),
		"dois snapshots com o mesmo seq e revisão, a 5 ms um do outro, dão linhas diferentes (%s ≠ %s)" % [s1["hora"], s2["hora"]])

	# --- B2: o caso vivo exacto — depois do snapshot, a figura na vez ENCERRA. O servidor (sala.js `encerrar` →
	# avancarVez) só emite um `turno`; sem actor, o modelo não se mexe: a caixa continua a do snapshot.
	var me := OrdemTurnos.new()
	me.definir_modo("dinamico")
	me.carregar_do_servidor(snap_caixa["ordemDinamica"])
	var se: Dictionary = R.novo_snap(9, 31, "21:30:01.000")
	var turno := {"tipo": "turno", "dados": {"figuraId": arq, "rodada": 2}}
	me.registar_evento(turno)
	R.anotar_evento(se, turno)
	se["revisao_actual"] = 32
	var le: String = R.linha("e", snap_caixa, se, R.caixa_actual(snap_caixa, me))
	linhas.append(le)
	print("  linha: ", le)
	_ok(se["eventos"] == 1 and se["de_actor"] == 0 and se["tipos"] == ["turno"],
		"um `encerrar` (o `turno` que produz): exactamente 1 evento, de tipo turno, 0 de actor")
	_ok(le.contains("JSON actual") and le.contains("1 evento(s) aplicado(s) depois dele [turno], 0 de actor") and not le.contains("adiantaram"),
		"um `encerrar` não muda a caixa: o JSON continua o actual e a linha diz «1 evento … [turno], 0 de actor» (sem «que a adiantaram»)")

	# --- Um evento de actor que não muda a caixa (a mesma figura volta a agir): conta 1 de actor, continua actual.
	var m2 := OrdemTurnos.new()
	m2.carregar_do_servidor(snap_caixa["ordemDinamica"])
	var s3: Dictionary = R.novo_snap(9, 31, "21:30:02.000")
	var mov_esp := {"tipo": "movimento", "dados": {"figuraId": esp}}  # a mesma vez
	m2.registar_evento(mov_esp)
	R.anotar_evento(s3, mov_esp)
	var l2: String = R.linha("x", snap_caixa, s3, R.caixa_actual(snap_caixa, m2))
	linhas.append(l2)
	_ok(l2.contains("JSON actual") and l2.contains("1 evento(s) aplicado(s) depois dele [movimento], 1 de actor"),
		"um evento de actor que não muda a caixa: o JSON continua o actual (e diz que houve 1 evento, de actor)")

	# --- §4: depois do snapshot a bancada joga Bruto e depois Arqueira (cada vez: a acção e o `encerrar` → `turno`);
	# os eventos de actor adiantam o modelo (a volta fecha). Contagem exacta: 6 eventos, 3 de actor.
	var eventos := [
		{"tipo": "movimento", "dados": {"figuraId": bruto}},
		{"tipo": "turno", "dados": {"figuraId": arq, "rodada": 2}},
		{"tipo": "movimento", "dados": {"figuraId": arq}},
		{"tipo": "ataque", "dados": {"atacanteId": arq, "alvoId": lobo}},
		{"tipo": "dano", "dados": {"alvoId": lobo}},
		{"tipo": "turno", "dados": {"figuraId": lobo, "rodada": 2}},
	]
	for e in eventos:
		m.registar_evento(e)
		R.anotar_evento(snap, e)
	snap["revisao_actual"] = 35
	act = R.caixa_actual(snap_caixa, m)
	l = R.linha("4", snap_caixa, snap, act)
	linhas.append(l)
	print("  linha: ", l)
	_ok(m.fechada and act["ordemDinamica"]["fechada"] == true and act["ordemDinamica"]["ordem"] == [arq, lobo, esp, bruto] and act["ordemDinamica"]["ultimo"] == arq,
		"o modelo do HUD adiantou-se pelos eventos de actor: 4 figuras, fechada true, Arqueira na vez (a caixa actual)")
	_ok(snap["eventos"] == 6 and snap["de_actor"] == 3 and snap["tipos"] == ["movimento", "turno", "movimento", "ataque", "dano", "turno"],
		"contagem exacta: 6 eventos aplicados, 3 de actor, os tipos pela ordem")
	_ok(R.desactualizado(snap_caixa, act), "depois dos eventos: o JSON do snapshot já NÃO é a caixa actual")
	var i_marca := l.find("DESACTUALIZADO")
	var i_velho := l.find(JSON.stringify(snap_caixa))
	var i_actual := l.find(JSON.stringify(act))
	_ok(i_marca >= 0 and i_velho > i_marca, "a linha marca «DESACTUALIZADO» ANTES do JSON velho (lê-se a marca primeiro)")
	_ok(i_actual > i_velho and l.contains("ACTUAL"), "a mesma linha imprime a caixa ACTUAL depois do JSON velho")
	_ok(l.contains("\"fechada\":false") and l.contains("\"fechada\":true"), "lêem-se as duas: a velha (fechada false) e a actual (fechada true)")
	_ok(l.contains("seq 9") and l.contains("revisão 31") and l.contains("6 evento(s) aplicado(s) depois dele [movimento, turno, movimento, ataque, dano, turno], 3 de actor")
		and l.contains("(revisão 35)"),
		"a linha diz de que snapshot é o velho (seq 9, revisão 31, 6 eventos com os tipos, 3 de actor) e a revisão da actual (35)")
	_ok(not l.contains("JSON actual") and not l.contains("adiantaram"), "o JSON velho nunca passa por actual; a linha não diz «que a adiantaram»")
	_ok(not l.contains("9.0") and not l.contains("31.0"), "seq e revisão (floats do JSON) escritos como inteiros")

	# --- Sem caixa (sala de espera / servidor antigo): nada a marcar.
	var m3 := OrdemTurnos.new()
	_ok(not R.desactualizado({}, R.caixa_actual({}, m3)), "sem caixa no snapshot: nada desactualizado")

	# --- Privacidade (B6): TODAS as linhas — as «JSON actual» (§1/§5, o `encerrar`, a mesma vez) e a do §4 — só têm
	# ids opacos, os campos da caixa e a origem do snapshot: nenhum nome, vida, alma ou PA.
	var proibidas := ["nome", "vida", "alma", "pa\"", "paTotal", "vidaActual", "mestre"]
	var achadas: Array = []
	var actuais := 0
	for linha_r in linhas:
		if str(linha_r).contains("JSON actual"):
			actuais += 1
		for p in proibidas:
			if str(linha_r).to_lower().contains(p.to_lower()):
				achadas.append(p)
	_ok(linhas.size() == 4 and actuais == 3, "a privacidade varre as 4 linhas, 3 delas «JSON actual» (não só a do §4)")
	_ok(achadas.is_empty(), "nenhuma linha ganha nomes, vida, alma nem PA %s" % [achadas])

	print("")
	print("teste do relato da caixa: %d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 or _total == 0 else 0)
