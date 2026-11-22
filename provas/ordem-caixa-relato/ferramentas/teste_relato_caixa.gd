extends SceneTree
## Ordem CAIXA-RELATO (B7b) — o teste do REGISTO da linha da caixa (relato_caixa.gd), sem servidor e sem ecrã, com o
## MODELO REAL do HUD (res://hud/ordem_turnos.gd). Reproduz o §4 da prova da caixa: a caixa chega num snapshot
## (3 figuras, fechada false), os eventos que a jogadora recebe adiantam-na (Bruto, Arqueira: a volta fecha) e a linha
## tem de dizer que o JSON é o velho e qual é o actual. E o contrário (§1/§5): snapshot acabado de chegar = actual.
## Ordem CAIXA-RELATO-CORRECOES: o contador do ajudante (novo_snap/anotar_evento — o mesmo que as provas usam) com
## contagens EXACTAS e os tipos; o caso vivo de um `encerrar` (só um `turno`) que não muda a caixa (B2); a hora com
## milissegundos (B3); a privacidade varre todas as linhas, incluindo as «JSON actual» (B6).
## Ordem CAIXA-RELATO-CORRECOES-2 (conferência da CAIXA-RELATO-CORRECOES):
##  - B2: as 2 linhas do caso da hora também entram na varredura de privacidade — 6 linhas, 5 «JSON actual».
##  - B3: a lista das proibidas ganha "master", "caixaMestre" e "pa".
##  - B5: os dois snapshots do caso da hora ficam a 20 ms (não 5) e a hora confere-se contra a hora LOCAL do sistema
##    (um `hora_ms()` que esquecesse o fuso — `bias` a zero — dava a hora UTC e passava; agora não passa fora de UTC).
##  - B6: o §4 leva um evento `estado` (como o do caso vivo: o ataque produz-o). Traz `figuraId` mas não é de actor —
##    contá-lo como de actor muda a contagem e adianta o modelo.
## Ordem CAIXA-RELATO-B7: com o Estado REAL, a verificação B2 continua a passar depois de um `limpar()` sem snapshot
## novo (D4 da conferência da CAIXA-RELATO-CORRECOES: o `limpar()` deixava `eventos_desde_snapshot` do snapshot velho).
## Ordem CAIXA-RELATO-B7-CORRECOES (sentença da conferência da CAIXA-RELATO-B7):
##  - B2: o caso do `limpar()` corre DEPOIS da varredura de privacidade do §B6 e não era varrido. Agora gera, a cada passo,
##    a linha do relato tal como as provas a escreveriam (a caixa do Estado, a origem do snapshot e a caixa actual do
##    modelo do HUD) e varre-as com a MESMA lista de proibidas (`PROIBIDAS`) — 2 verificações novas (28 → 30).
##  - B3: «o snapshot DESTE CASO não traz `propria` nem nomes» — é o que o teste monta, não uma regra do protocolo.
## Ordem CAIXA-RELATO-CORRECOES-3 (sentença da CAIXA-RELATO-CORRECOES-2):
##  - B4 (só comentário): a eficácia de "master", "caixaMestre" e "pa" na lista das proibidas assenta nas MUTAÇÕES do
##    executor (fugas «(master)», «(caixaMestre)», «(PA 3)» postas de propósito na origem da linha, cada uma 22/23 —
##    `provas/ordem-caixa-relato/correcoes-3/mutacoes.log`), não em nada que este teste gere por si: nenhuma linha
##    honesta as contém. E o "pa" SOZINHO vale só aqui, nas linhas sintéticas deste teste (palavras fixas e ids
##    hexadecimais): NUNCA migra para o canário vivo das provas — no relato vivo «pa» ocorre 23× como substring, sem
##    distinguir maiúsculas, de texto honesto (`correcoes-2/cliente-hud/relato.txt`: 13× «Espadachim», 3× «aparelho»,
##    3× o «PA» do próprio texto das verificações de privacidade, «aparece», «desapareceu», «passaram», «passou») e
##    daria falsos positivos. O canário vivo procura os nomes verdadeiros (e, nos textos da caixa, os números de
##    vida/PA), não a palavra «pa».
##  - B6: a conta do fuso confere-se com um instante e um fuso INJECTADOS (`hora_ms(unix, bias_min)`, bias −180 e
##    +330): não depende do fuso da máquina, e um `hora_ms()` que esquecesse o fuso falha também no CI (UTC).
##
## Correr (na raiz do repo):
##   godot --headless --path rascunhos/cliente -s "$PWD/provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd"

const OrdemTurnos := preload("res://hud/ordem_turnos.gd")

## As palavras que nenhuma linha do relato pode ter (B6; CORRECOES-2 B3). Partilhada pela varredura do §B6 e pela do
## caso do `limpar()` (B7-CORRECOES B2).
const PROIBIDAS := ["nome", "vida", "alma", "pa", "pa\"", "paTotal", "vidaActual", "mestre", "master", "caixaMestre"]

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
	# B5: a hora local do sistema (só HH:MM:SS) antes e depois de cada leitura — a do ajudante tem de cair entre elas.
	var antes1 := Time.get_time_string_from_system()
	var s1: Dictionary = R.novo_snap(13, 10)
	var depois1 := Time.get_time_string_from_system()
	OS.delay_msec(20)
	var antes2 := Time.get_time_string_from_system()
	var s2: Dictionary = R.novo_snap(13, 10)
	var depois2 := Time.get_time_string_from_system()
	var re := RegEx.create_from_string("^\\d\\d:\\d\\d:\\d\\d\\.\\d\\d\\d$")
	_ok(re.search(str(s1["hora"])) != null and re.search(str(s2["hora"])) != null, "a hora é HH:MM:SS.mmm (%s)" % s1["hora"])
	var h1 := str(s1["hora"]).substr(0, 8)
	var h2 := str(s2["hora"]).substr(0, 8)
	var fuso := Time.get_time_zone_from_system()
	_ok(h1 >= antes1 and h1 <= depois1 and h2 >= antes2 and h2 <= depois2,
		"a hora é a LOCAL do sistema (fuso %s, bias %s min): %s ∈ [%s, %s] e %s ∈ [%s, %s]" % [
			fuso.get("name", "?"), fuso.get("bias", "?"), h1, antes1, depois1, h2, antes2, depois2])
	# B6 (CORRECOES-3): o fuso injectado — a mesma conta com bias ≠ 0 em qualquer máquina (no CI, UTC, o caso de cima
	# não distingue «somar o bias» de «esquecê-lo»). 1795000000.25 s = 2026-11-18 11:06:40.250 UTC.
	var inj_sp: String = R.hora_ms(1795000000.25, -180)
	var inj_in: String = R.hora_ms(1795000000.25, 330)
	_ok(inj_sp == "08:06:40.250" and inj_in == "16:36:40.250",
		"a hora soma o fuso INJECTADO (não depende do fuso desta máquina): bias −180 → %s (08:06:40.250), bias +330 → %s (16:36:40.250)" % [inj_sp, inj_in])
	var lh1: String = R.linha("x", snap_caixa, s1, act)
	var lh2: String = R.linha("x", snap_caixa, s2, act)
	linhas.append(lh1)  # B2: as duas linhas do caso da hora também passam pela varredura de privacidade
	linhas.append(lh2)
	_ok(str(s1["hora"]) != str(s2["hora"]) and lh1 != lh2,
		"dois snapshots com o mesmo seq e revisão, a 20 ms um do outro, dão linhas diferentes (%s ≠ %s)" % [s1["hora"], s2["hora"]])

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
	# os eventos de actor adiantam o modelo (a volta fecha). B6: o ataque produz também um `estado` (como no caso vivo),
	# que traz o `figuraId` do alvo mas NÃO é de actor. Contagem exacta: 7 eventos, 3 de actor.
	var eventos := [
		{"tipo": "movimento", "dados": {"figuraId": bruto}},
		{"tipo": "turno", "dados": {"figuraId": arq, "rodada": 2}},
		{"tipo": "movimento", "dados": {"figuraId": arq}},
		{"tipo": "ataque", "dados": {"atacanteId": arq, "alvoId": lobo}},
		{"tipo": "dano", "dados": {"alvoId": lobo}},
		{"tipo": "estado", "dados": {"figuraId": lobo}},
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
	_ok(OrdemTurnos.actor_do_evento(eventos[5]) == "", "o evento `estado` (com figuraId) não é de actor")
	_ok(snap["eventos"] == 7 and snap["de_actor"] == 3 and snap["tipos"] == ["movimento", "turno", "movimento", "ataque", "dano", "estado", "turno"],
		"contagem exacta: 7 eventos aplicados, 3 de actor, os tipos pela ordem (com o `estado`)")
	_ok(R.desactualizado(snap_caixa, act), "depois dos eventos: o JSON do snapshot já NÃO é a caixa actual")
	var i_marca := l.find("DESACTUALIZADO")
	var i_velho := l.find(JSON.stringify(snap_caixa))
	var i_actual := l.find(JSON.stringify(act))
	_ok(i_marca >= 0 and i_velho > i_marca, "a linha marca «DESACTUALIZADO» ANTES do JSON velho (lê-se a marca primeiro)")
	_ok(i_actual > i_velho and l.contains("ACTUAL"), "a mesma linha imprime a caixa ACTUAL depois do JSON velho")
	_ok(l.contains("\"fechada\":false") and l.contains("\"fechada\":true"), "lêem-se as duas: a velha (fechada false) e a actual (fechada true)")
	_ok(l.contains("seq 9") and l.contains("revisão 31") and l.contains("7 evento(s) aplicado(s) depois dele [movimento, turno, movimento, ataque, dano, estado, turno], 3 de actor")
		and l.contains("(revisão 35)"),
		"a linha diz de que snapshot é o velho (seq 9, revisão 31, 7 eventos com os tipos, 3 de actor) e a revisão da actual (35)")
	_ok(not l.contains("JSON actual") and not l.contains("adiantaram"), "o JSON velho nunca passa por actual; a linha não diz «que a adiantaram»")
	_ok(not l.contains("9.0") and not l.contains("31.0"), "seq e revisão (floats do JSON) escritos como inteiros")

	# --- Sem caixa (sala de espera / servidor antigo): nada a marcar.
	var m3 := OrdemTurnos.new()
	_ok(not R.desactualizado({}, R.caixa_actual({}, m3)), "sem caixa no snapshot: nada desactualizado")

	# --- Privacidade (B6; CORRECOES-2 B2/B3): TODAS as linhas — as «JSON actual» (§1/§5, as duas do caso da hora, o
	# `encerrar`, a mesma vez) e a do §4 — só têm ids opacos, os campos da caixa e a origem do snapshot: nenhum nome,
	# vida, alma, PA nem nada do Mestre. "pa" sozinho: nenhuma palavra fixa da linha o tem (e os ids são hexadecimais).
	var achadas: Array = _proibidas_em(linhas)
	var actuais := 0
	for linha_r in linhas:
		if str(linha_r).contains("JSON actual"):
			actuais += 1
	_ok(linhas.size() == 6 and actuais == 5,
		"a privacidade varre as 6 linhas, 5 delas «JSON actual» (não só a do §4; %d linhas, %d actuais)" % [linhas.size(), actuais])
	_ok(achadas.is_empty(), "nenhuma linha ganha nomes, vida, alma nem PA %s" % [achadas])

	_caso_limpar(R)

	print("")
	print("teste do relato da caixa: %d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 or _total == 0 else 0)


## As palavras de PROIBIDAS que aparecem nas linhas (sem distinguir maiúsculas), uma entrada por achado.
func _proibidas_em(linhas_v: Array) -> Array:
	var achadas: Array = []
	for linha_r in linhas_v:
		for p in PROIBIDAS:
			if str(linha_r).to_lower().contains(str(p).to_lower()):
				achadas.append(p)
	return achadas


## Ordem CAIXA-RELATO-B7 (Mecânica D4 da conferência da CAIXA-RELATO-CORRECOES): `Estado.limpar()` emite
## `snapshot_aplicado` — as provas recomeçam aí o contador (`_registar_snapshot` → novo_snap) — mas deixava
## `eventos_desde_snapshot` com os eventos do snapshot de ANTES. A verificação B2 das provas (a contagem e os tipos do
## relato = os que o Estado aplicou desde o snapshot) falhava depois de um `limpar()` sem snapshot novo. Aqui com o
## ESTADO REAL (res://estado/estado.gd, fora da árvore: sem Rede, sem Mestre) e a mesma ligação das provas.
## Só ids opacos: o snapshot DESTE CASO (o que o teste monta) não traz `propria` nem nomes; nada de vida, alma ou PA.
## B7-CORRECOES (B2): as linhas do relato deste caso também passam pela varredura de privacidade (no fim do caso).
func _caso_limpar(R) -> void:
	var est = load("res://estado/estado.gd").new()
	var ctx := {"snap": {}}
	est.snapshot_aplicado.connect(func(): ctx["snap"] = R.novo_snap(est.ultimo_seq, est.revisao))
	est.evento_aplicado.connect(func(e: Dictionary): R.anotar_evento(ctx["snap"], e))
	var a := "f1c67641aa5cdfe28"
	var b := "ff2acf60bd672e76e"
	var snapshot := func(seq: int) -> void:
		est.aplicar_snapshot({"type": "ROOM_SNAPSHOT", "seq": seq, "revision": seq, "fase": "combate", "rodada": 1,
			"figuras": [{"id": a, "lado": "jogadora", "x": 1, "y": 1}, {"id": b, "lado": "criatura", "x": 3, "y": 3}],
			"iniciativa": [a, b], "vezId": a,
			"caixa": {"ligada": true, "ordemPor": "dinamico", "ordemDinamica": {"ordem": [a], "fechada": false, "ultimo": a}}})
	var evento := func(seq: int, tipo: String, fid: String) -> void:
		est.receber_evento({"type": "ROOM_EVENT", "seq": seq, "revision": seq, "tipo": tipo, "dados": {"figuraId": fid, "rodada": 1}})
	# A verificação B2 das provas (prova_caixa_jogadora.gd / prova_caixa_manequim.gd, §4), sem o «2 de actor» do caso vivo.
	var linhas_b7: Array = []
	var b2 := func(rotulo: String, esperados: Array) -> void:
		var sn: Dictionary = ctx["snap"]
		# B7-CORRECOES (B2): a linha do relato deste passo, como as provas a escrevem — a caixa do Estado, a origem do
		# snapshot e a caixa actual (o modelo do HUD carregado da caixa do Estado e adiantado pelos eventos desde o
		# snapshot). Sem caixa (depois do `limpar()`) a linha sai com `{}`.
		var mod := OrdemTurnos.new()
		mod.definir_modo("dinamico")
		if est.caixa.get("ordemDinamica") is Dictionary:
			mod.carregar_do_servidor(est.caixa["ordemDinamica"])
		for e in est.eventos_desde_snapshot:
			mod.registar_evento(e)
		var sl: Dictionary = sn.duplicate(true)
		sl["revisao_actual"] = est.revisao
		linhas_b7.append(R.linha("B7-%d" % (linhas_b7.size() + 1), est.caixa, sl, R.caixa_actual(est.caixa, mod)))
		var tipos_rel: Array = sn.get("tipos", [])
		var tipos_est: Array = est.eventos_desde_snapshot.map(func(e): return str(e.get("tipo", "?")))
		_ok(int(sn.get("eventos", -1)) == tipos_est.size() and tipos_rel == tipos_est and tipos_rel == esperados,
			"B7 %s: a verificação B2 passa — %d evento(s) %s no relato = os %d %s que o Estado guarda desde o snapshot (esperados %s)" % [
				rotulo, int(sn.get("eventos", -1)), JSON.stringify(tipos_rel), tipos_est.size(), JSON.stringify(tipos_est), JSON.stringify(esperados)])

	snapshot.call(1)
	evento.call(2, "movimento", b)
	evento.call(3, "turno", b)
	b2.call("antes do limpar()", ["movimento", "turno"])
	est.limpar()
	_ok(not est.tem_snapshot and est.eventos_desde_snapshot.is_empty(),
		"B7: depois do limpar() o Estado fica sem snapshot e sem eventos de depois dele (ficaram %d; antes da B7 ficavam os 2 do snapshot velho)" % est.eventos_desde_snapshot.size())
	b2.call("limpar() sem snapshot novo", [])
	evento.call(4, "movimento", a)  # sem snapshot o evento fica à espera (não é aplicado): nada muda
	b2.call("um evento depois do limpar(), ainda sem snapshot", [])
	snapshot.call(5)
	evento.call(6, "turno", a)
	b2.call("o snapshot novo e um evento", ["turno"])
	# B7-CORRECOES (B2): a varredura de privacidade do §B6, estendida a este caso — as 4 linhas, a mesma lista.
	for lb in linhas_b7:
		print("  linha: ", lb)
	_ok(linhas_b7.size() == 4 and str(linhas_b7[1]).contains("seq 0") and str(linhas_b7[3]).contains("seq 5"),
		"B7-CORRECOES: a varredura do caso do limpar() cobre as 4 linhas do relato (antes, o limpar() sem snapshot, o evento à espera, o snapshot novo; %d linhas)" % linhas_b7.size())
	var achadas_b7: Array = _proibidas_em(linhas_b7)
	_ok(achadas_b7.is_empty(), "B7-CORRECOES: nenhuma linha do caso do limpar() ganha nomes, vida, alma nem PA %s" % [achadas_b7])
	est.free()
