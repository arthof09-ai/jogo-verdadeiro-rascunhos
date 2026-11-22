extends SceneTree
## Ordem CAIXA-RELATO (B7b) — o teste do REGISTO da linha da caixa (relato_caixa.gd), sem servidor e sem ecrã, com o
## MODELO REAL do HUD (res://hud/ordem_turnos.gd). Reproduz o §4 da prova da caixa: a caixa chega num snapshot
## (3 figuras, fechada false), os eventos que a jogadora recebe adiantam-na (Bruto, Arqueira: a volta fecha) e a linha
## tem de dizer que o JSON é o velho e qual é o actual. E o contrário (§1/§5): snapshot acabado de chegar = actual.
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
	var snap := {"seq": 9.0, "revisao": 31.0, "hora": "21:30:00", "eventos": 0, "revisao_actual": 31}

	# --- §1/§5: o snapshot acabou de chegar; o modelo carregou-o; nenhum evento depois.
	var m := OrdemTurnos.new()
	m.definir_modo("dinamico")
	m.carregar_do_servidor(snap_caixa["ordemDinamica"])
	var act: Dictionary = R.caixa_actual(snap_caixa, m)
	var l: String = R.linha("1", snap_caixa, snap, act)
	print("  linha: ", l)
	_ok(not R.desactualizado(snap_caixa, act), "acabado de chegar: o JSON do snapshot é a caixa actual")
	_ok(l.contains("JSON actual") and not l.contains("DESACTUALIZADO"), "acabado de chegar: a linha diz «JSON actual», sem «DESACTUALIZADO»")
	_ok(l.contains("seq 9") and l.contains("revisão 31") and l.contains("21:30:00") and l.contains("0 evento(s) depois"),
		"acabado de chegar: a linha diz de que snapshot é (seq, revisão, hora, 0 eventos depois)")
	_ok(l.contains(JSON.stringify(snap_caixa)), "acabado de chegar: a linha traz o JSON do snapshot tal como chegou")

	# --- §4: depois do snapshot, a bancada joga Bruto e depois Arqueira; os eventos adiantam o modelo (volta fecha).
	var eventos := [
		{"tipo": "movimento", "dados": {"figuraId": bruto}},
		{"tipo": "movimento", "dados": {"figuraId": arq}},
		{"tipo": "ataque", "dados": {"atacanteId": arq, "alvoId": lobo}},
	]
	for e in eventos:
		m.registar_evento(e)
		snap["eventos"] += 1
	snap["revisao_actual"] = 35
	act = R.caixa_actual(snap_caixa, m)
	l = R.linha("4", snap_caixa, snap, act)
	print("  linha: ", l)
	_ok(m.fechada and act["ordemDinamica"]["fechada"] == true and act["ordemDinamica"]["ordem"] == [arq, lobo, esp, bruto] and act["ordemDinamica"]["ultimo"] == arq,
		"o modelo do HUD adiantou-se pelos eventos: 4 figuras, fechada true, Arqueira na vez (a caixa actual)")
	_ok(R.desactualizado(snap_caixa, act), "depois dos eventos: o JSON do snapshot já NÃO é a caixa actual")
	var i_marca := l.find("DESACTUALIZADO")
	var i_velho := l.find(JSON.stringify(snap_caixa))
	var i_actual := l.find(JSON.stringify(act))
	_ok(i_marca >= 0 and i_velho > i_marca, "a linha marca «DESACTUALIZADO» ANTES do JSON velho (lê-se a marca primeiro)")
	_ok(i_actual > i_velho and l.contains("ACTUAL"), "a mesma linha imprime a caixa ACTUAL depois do JSON velho")
	_ok(l.contains("\"fechada\":false") and l.contains("\"fechada\":true"), "lêem-se as duas: a velha (fechada false) e a actual (fechada true)")
	_ok(l.contains("seq 9") and l.contains("revisão 31") and l.contains("3 evento(s) depois") and l.contains("(revisão 35)"),
		"a linha diz de que snapshot é o velho (seq 9, revisão 31, 3 eventos depois) e a revisão da actual (35)")
	_ok(not l.contains("JSON actual"), "o JSON velho nunca passa por actual")
	_ok(not l.contains("9.0") and not l.contains("31.0"), "seq e revisão (floats do JSON) escritos como inteiros")

	# --- Mesmos eventos mas que não mexem na caixa (a mesma figura volta a agir): continua actual.
	var m2 := OrdemTurnos.new()
	m2.carregar_do_servidor(snap_caixa["ordemDinamica"])
	m2.registar_evento({"tipo": "movimento", "dados": {"figuraId": esp}})  # a mesma vez
	var snap2 := {"seq": 9, "revisao": 31, "hora": "21:30:00", "eventos": 1, "revisao_actual": 32}
	var l2: String = R.linha("x", snap_caixa, snap2, R.caixa_actual(snap_caixa, m2))
	_ok(l2.contains("JSON actual") and l2.contains("1 evento(s) depois"), "um evento que não muda a caixa: o JSON continua o actual (e diz que houve 1 evento)")

	# --- Sem caixa (sala de espera / servidor antigo): nada a marcar.
	var m3 := OrdemTurnos.new()
	_ok(not R.desactualizado({}, R.caixa_actual({}, m3)), "sem caixa no snapshot: nada desactualizado")

	# --- Privacidade: a linha só tem ids opacos e os campos da caixa — nenhum nome, vida, alma ou PA.
	var proibidas := ["nome", "vida", "alma", "pa\"", "paTotal", "vidaActual", "mestre"]
	var achadas: Array = []
	for p in proibidas:
		if l.to_lower().contains(p.to_lower()):
			achadas.append(p)
	_ok(achadas.is_empty(), "a linha não ganha nomes, vida, alma nem PA %s" % [achadas])

	print("")
	print("teste do relato da caixa: %d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 or _total == 0 else 0)
