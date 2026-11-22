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
## Ordem CAIXA-RELATO-B7-CORRECOES-2 (sentença da conferência da CAIXA-RELATO-B7-CORRECOES):
##  - B1: "propria" entra em `PROIBIDAS` — nenhuma linha legítima do relato a traz (as palavras fixas de `linha()`, os
##    rótulos, os tipos de evento e os campos da caixa não a têm; o «própria» acentuado das provas vivas não é linha
##    de `linha()` nem casa com "propria"). «Não traz `propria`» passa a ser verdade por teste.
##  - B2: nenhuma linha é ecoada ANTES da varredura. As linhas (do §B6 e do caso do `limpar()`) só se imprimem depois
##    de varridas, e uma linha com palavras proibidas NÃO se imprime — sai só o rótulo e as palavras achadas (`_ecoar`).
##  - B4: a verificação de cobertura do caso do `limpar()` prende as 4 linhas pelo rótulo («B7-1:» … «B7-4:») e pela
##    origem (seq 1, seq 0, seq 0, seq 5); a B7-2 e a B7-3 têm o mesmo corpo (o evento à espera não muda nada) e
##    distinguem-se pelo rótulo — o teste confere as duas coisas. Continua 30/30.
## Ordem CAIXA-RELATO-B7-CORRECOES-3 (sentença da CAIXA-RELATO-B7-CORRECOES-2):
##  - B1 (ordem futura R1): a retenção deixa de ser só por palavras PROIBIDAS. Uma linha só se ecoa se, além de não ter
##    nenhuma proibida, tiver SÓ chaves JSON de `CHAVES_PERMITIDAS` e SÓ palavras de `PALAVRAS_PERMITIDAS` (mais números
##    e ids hexadecimais de 17). Um valor novo sem chave proibida ao lado («"alcunha": "Canario-R1"») já não passa nem se
##    ecoa. O que se acha fora da lista conta-se, mas NUNCA se imprime (o achado seria o próprio valor).
##  - B2: a comparação normaliza acentos (e maiúsculas) dos dois lados — «"própria"» casa com "propria".
##  - B3: o comentário de "propria" aponta `estado.gd:57` (a linha do `var propria`).
##  - B4 (registo): a B7-2 e a B7-3 continuam presas só pelo rótulo; uma troca/duplicação dos dois passos do meio
##    passa — inerente aos dados (ver o comentário no caso do `limpar()`).
##  - B5: o total de verificações é afirmado (`TOTAL_ESPERADO`): uma verificação removida já não passa calada com
##    «30 de 30» — o teste sai com código 1. São 31, não 30: na `fable/integracao-50` as 30 da B7-CORRECOES-2 juntaram-se
##    à verificação do fuso injectado da CORRECOES-3 (B6). Continua 31/31.
## Ordem CAIXA-RELATO-B7-CORRECOES-4 (sentença da CAIXA-RELATO-B7-CORRECOES-3):
##  - B1 (D1): as listas viam as chaves e as palavras, não o TIPO nem a FORMA do valor — «"ultimo": "turno"» (só
##    palavras permitidas) e «"ultimo": 42» (um número) passavam e ecoavam. Agora a forma de cada valor confere-se
##    (`_forma_fora`, ao lado de `CHAVES_PERMITIDAS`): `ordem` só lista de ids de 17 hex, `ultimo` só id de 17 hex,
##    `ligada`/`fechada` só booleanos, `ordemPor` só "dinamico", `ordemDinamica` só objecto, e cada chave no seu nível.
##  - B2 (D2): registado ao lado de `RE_ID` — qualquer 17-hex passa por id.
##  - B5 (D5): `_SEM_ACENTO` com o latim alargado A (e o s longo U+017F), e as marcas combinantes em todos os blocos
##    (U+0300–036F, 1AB0–1AFF, 1DC0–1DFF, 20D0–20FF, FE20–FE2F). O mapa NÃO é uma normalização Unicode completa: a rede
##    de segurança é a lista permitida, e um carácter não-ASCII que sobre depois de `_normal` (fora o «—» e o «·» das
##    palavras fixas) já não serve de separador — conta como palavra fora da lista e retém a linha.
##    Continua 31/31: nenhuma verificação nova, a forma e o resíduo não-ASCII entram em `_achados_em`.
##
## Correr (na raiz do repo):
##   godot --headless --path rascunhos/cliente -s "$PWD/provas/ordem-caixa-relato/ferramentas/teste_relato_caixa.gd"

const OrdemTurnos := preload("res://hud/ordem_turnos.gd")

## As palavras que nenhuma linha do relato pode ter (B6; CORRECOES-2 B3). Partilhada pela varredura do §B6 e pela do
## caso do `limpar()` (B7-CORRECOES B2).
## B7-CORRECOES-2 (B1): "propria" (o campo do snapshot só da jogadora: vida, PA e ficha dela — estado.gd:57).
## B7-CORRECOES-3 (B2): comparadas sem acentos nem maiúsculas (`_normal`), dos dois lados.
const PROIBIDAS := ["nome", "vida", "alma", "pa", "pa\"", "paTotal", "vidaActual", "mestre", "master", "caixaMestre",
	"propria"]

## B7-CORRECOES-3 (B1, R1): o que uma linha PODE ter. Tudo o resto retém a linha. Nenhum campo novo entra na caixa sem
## passar pela conferência: acrescentá-lo aqui é a mudança que a conferência vê.
## As chaves JSON da caixa da Party (projecao.js `caixa`) — as 3 de cima e as 3 da `ordemDinamica`.
## B7-CORRECOES-4 (B1, D1) — O LIMITE: a chave estar nesta lista não diz nada do VALOR. Até à B7-CORRECOES-3 um valor
## feito só de palavras permitidas, ou um número, debaixo de uma chave permitida passava e ecoava («"ultimo": "turno"»,
## «"ultimo": 42» → 31/31, ecoados). Fecha-se com a FORMA de cada valor (`_forma_fora`): o que não
## tem a forma conta-se e retém a linha, sem se imprimir. A forma é a das linhas DESTE teste (ids de 17 hex, modo
## dinâmico): uma linha real com `"ultimo": null` (o servidor manda null antes da primeira vez) ou `"ordemPor":
## "iniciativa"` ficaria retida — alargá-la é, outra vez, uma mudança que a conferência vê.
const CHAVES_PERMITIDAS := ["ligada", "ordemPor", "ordemDinamica", "ordem", "fechada", "ultimo"]
## B7-CORRECOES-4 (B1): em que nível vive cada chave — as 3 da caixa em cima, as 3 da `ordemDinamica` dentro dela.
const CHAVES_CAIXA := ["ligada", "ordemPor", "ordemDinamica"]
const CHAVES_ORDEM_DINAMICA := ["ordem", "fechada", "ultimo"]
## As palavras (já normalizadas por `_normal`: minúsculas, sem acentos) que `relato_caixa.linha()` e `_origem()` escrevem,
## os valores JSON da caixa, os tipos de evento e os rótulos deste teste. Números e ids hexadecimais de 17 à parte.
const PALAVRAS_PERMITIDAS := [
	# linha(): a base, «JSON DESACTUALIZADO (é o do …)», «a caixa ACTUAL dela (revisão N)», «JSON actual (do …; a caixa dela é esta)»
	"a", "caixa", "que", "lhe", "chegou", "so", "tem", "ligada", "ordempor", "e", "ordemdinamica",
	"json", "desactualizado", "o", "do", "actual", "dela", "revisao", "esta",
	# _origem(): «ROOM_SNAPSHOT seq N, revisão N, aplicado às H; N evento(s) aplicado(s) depois dele […], N de actor (só esses podem adiantá-la)»
	"room_snapshot", "seq", "aplicado", "as", "evento", "s", "depois", "dele", "de", "actor", "esses", "podem", "adianta", "la",
	# os valores JSON da caixa (as chaves já estão acima, normalizadas)
	"true", "false", "null", "dinamico", "ordem", "fechada", "ultimo",
	# os tipos de evento que o teste aplica
	"movimento", "turno", "ataque", "dano", "estado",
	# os rótulos do teste: «1», «x», «e», «4», «B7-1»…«B7-4»
	"x", "b7",
]
## Os ids opacos (hexadecimais de 17, como os da prova). Os números (seq, revisão, hora) são só dígitos.
## B7-CORRECOES-4 (B2, D2) — O LIMITE: a regra é a FORMA de um id, não a lista dos ids deste teste. Qualquer 17-hex
## passa por id, como palavra solta e como valor de `ordem`/`ultimo` («"ultimo": "0123456789abcdef0"» → 31/31, ecoado).
## Um valor que fosse, por acaso ou de propósito, 17 caracteres hexadecimais em minúsculas não se distingue de um id.
## Nos valores em causa (nomes, vida, PA) não há nenhum assim; fica registado, não fechado.
const RE_ID := "^[0-9a-f]{17}$"
const RE_NUM := "^[0-9]+$"
## B7-CORRECOES-3 (B5): quantas verificações o teste tem. Uma a menos (ou a mais) sem mudar este número = o teste falha.
const TOTAL_ESPERADO := 31
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
	var achadas: Array = _achados_em(linhas)  # B7-CORRECOES-3 (B1): proibidas E fora das listas permitidas
	var actuais := 0
	for linha_r in linhas:
		if str(linha_r).contains("JSON actual"):
			actuais += 1
	_ok(linhas.size() == 6 and actuais == 5,
		"a privacidade varre as 6 linhas, 5 delas «JSON actual» (não só a do §4; %d linhas, %d actuais)" % [linhas.size(), actuais])
	_ok(achadas.is_empty(), "nenhuma linha ganha nomes, vida, alma nem PA, nem nada fora das chaves e palavras permitidas %s" % [achadas])
	_ecoar(linhas)  # B7-CORRECOES-2 (B2): o eco só depois da varredura, e só das linhas limpas

	_caso_limpar(R)

	print("")
	print("teste do relato da caixa: %d de %d verificações passaram." % [_total - _falhas, _total])
	# B7-CORRECOES-3 (B5): o total afirmado — uma verificação removida não passa calada com «30 de 30».
	var total_ok := _total == TOTAL_ESPERADO
	if not total_ok:
		print("  FALHA o total: %d verificações, esperadas %d (TOTAL_ESPERADO)" % [_total, TOTAL_ESPERADO])
		printerr("  FALHA o total: %d verificações, esperadas %d (TOTAL_ESPERADO)" % [_total, TOTAL_ESPERADO])
	quit(1 if _falhas > 0 or _total == 0 or not total_ok else 0)


## B7-CORRECOES-3 (B2): o texto em minúsculas e sem acentos — as letras acentuadas passam à letra de base, e as marcas
## combinantes (U+0300–U+036F, o acento escrito à parte) caem. «"própria"», «PRÓPRIA» e «própria» dão «propria».
## B7-CORRECOES-4 (B5, D5): o mapa cobre o latim-1 e o latim alargado A (U+0100–U+017F, com o s longo «ſ» → «s»), e as
## marcas combinantes caem em todos os blocos delas (`_COMBINANTES`). NÃO é uma normalização Unicode completa (não há
## NFKD em GDScript): letras de outros blocos (o «о» cirílico, as de largura dupla «ｐ», o «ȷ» U+0237…) não se
## traduzem. Para essas a rede de segurança é a lista permitida: o que sobra fora do ASCII depois de `_normal` conta
## como palavra fora da lista (`_fora_da_lista`) e retém a linha — não fica nomeado pela `PROIBIDAS`, mas não se ecoa.
const _SEM_ACENTO := {"á": "a", "à": "a", "â": "a", "ã": "a", "ä": "a", "å": "a", "é": "e", "è": "e", "ê": "e", "ë": "e",
	"í": "i", "ì": "i", "î": "i", "ï": "i", "ó": "o", "ò": "o", "ô": "o", "õ": "o", "ö": "o", "ú": "u", "ù": "u",
	"û": "u", "ü": "u", "ç": "c", "ñ": "n", "ý": "y", "ÿ": "y",
	# B5: o resto do latim-1 (minúsculas; `to_lower` já passou as maiúsculas)
	"ø": "o", "æ": "ae", "œ": "oe", "ß": "ss", "ð": "d", "þ": "th",
	# B5: o latim alargado A (U+0100–U+017F), as minúsculas
	"ā": "a", "ă": "a", "ą": "a", "ć": "c", "ĉ": "c", "ċ": "c", "č": "c", "ď": "d", "đ": "d", "ē": "e", "ĕ": "e",
	"ė": "e", "ę": "e", "ě": "e", "ĝ": "g", "ğ": "g", "ġ": "g", "ģ": "g", "ĥ": "h", "ħ": "h", "ĩ": "i", "ī": "i",
	"ĭ": "i", "į": "i", "ı": "i", "ĳ": "ij", "ĵ": "j", "ķ": "k", "ĸ": "k", "ĺ": "l", "ļ": "l", "ľ": "l", "ŀ": "l",
	"ł": "l", "ń": "n", "ņ": "n", "ň": "n", "ŉ": "n", "ŋ": "n", "ō": "o", "ŏ": "o", "ő": "o", "ŕ": "r", "ŗ": "r",
	"ř": "r", "ś": "s", "ŝ": "s", "ş": "s", "š": "s", "ţ": "t", "ť": "t", "ŧ": "t", "ũ": "u", "ū": "u", "ŭ": "u",
	"ů": "u", "ű": "u", "ų": "u", "ŵ": "w", "ŷ": "y", "ź": "z", "ż": "z", "ž": "z", "ſ": "s"}
## B7-CORRECOES-4 (B5): os blocos de marcas combinantes — as diacríticas (U+0300–036F), as alargadas (U+1AB0–1AFF), o
## suplemento (U+1DC0–1DFF), as dos símbolos (U+20D0–20FF, a da sonda U+20D0) e as meias marcas (U+FE20–FE2F).
const _COMBINANTES := [[0x300, 0x36F], [0x1AB0, 0x1AFF], [0x1DC0, 0x1DFF], [0x20D0, 0x20FF], [0xFE20, 0xFE2F]]


func _combinante(cp: int) -> bool:
	for r in _COMBINANTES:
		if cp >= int(r[0]) and cp <= int(r[1]):
			return true
	return false


func _normal(s: String) -> String:
	var low := s.to_lower()
	var out := ""
	for i in range(low.length()):
		var cp := low.unicode_at(i)
		if _combinante(cp):
			continue
		var c := low.substr(i, 1)
		out += str(_SEM_ACENTO.get(c, c))
	return out


## As palavras de PROIBIDAS que aparecem nas linhas (sem distinguir maiúsculas nem acentos — B7-CORRECOES-3, B2), uma
## entrada por achado. Só palavras DA LISTA — é seguro imprimi-las.
func _proibidas_em(linhas_v: Array) -> Array:
	var achadas: Array = []
	for linha_r in linhas_v:
		var ln := _normal(str(linha_r))
		for p in PROIBIDAS:
			if ln.contains(_normal(str(p))):
				achadas.append(p)
	return achadas


## B7-CORRECOES-3 (B1, R1): quantas chaves JSON fora de `CHAVES_PERMITIDAS` e quantas palavras fora de
## `PALAVRAS_PERMITIDAS` (nem número, nem id) a linha tem. Devolve SÓ as contagens — o que está fora da lista é, num
## vazamento, o próprio valor, e não se imprime. A chave compara-se tal como vem (não normalizada): «ordempor» ou
## «ligáda» não são chaves da caixa.
func _fora_da_lista(lx: String) -> Dictionary:
	var chaves := 0
	var re_chave := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"\\s*:")
	for m in re_chave.search_all(lx):
		if not CHAVES_PERMITIDAS.has(m.get_string(1)):
			chaves += 1
	var palavras := 0
	var re_id := RegEx.create_from_string(RE_ID)
	var re_num := RegEx.create_from_string(RE_NUM)
	# B7-CORRECOES-4 (B5): separam só o ASCII que não é letra/dígito/«_» e o «—»/«·» das palavras fixas de `linha()`.
	# Qualquer outro carácter não-ASCII que `_normal` não traduziu fica DENTRO da palavra — e uma palavra com ele não
	# está na lista: retém a linha. Antes servia de separador («a» + «ȷ» + «e» dava «a» e «e», as duas permitidas).
	var re_sep := RegEx.create_from_string("(?:[^a-z0-9_\\x{80}-\\x{10FFFF}]|[\\x{2014}\\x{00B7}])+")
	for p in re_sep.sub(_normal(lx), " ", true).split(" ", false):
		if not (PALAVRAS_PERMITIDAS.has(p) or re_num.search(p) != null or re_id.search(p) != null):
			palavras += 1
	return {"chaves": chaves, "palavras": palavras, "forma": _forma_fora(lx)}


## B7-CORRECOES-4 (B1, D1): quantos valores da caixa NÃO têm a forma da caixa deste teste. Cada objecto JSON da linha
## (o `JSON.stringify` da caixa do snapshot e da actual) lê-se com `JSON.parse_string` e percorre-se:
##  - em cima só `ligada` (booleano), `ordemPor` (só "dinamico") e `ordemDinamica` (objecto);
##  - dentro da `ordemDinamica` só `ordem` (lista de ids de 17 hex), `fechada` (booleano) e `ultimo` (id de 17 hex);
##  - uma chave permitida no nível errado, um objecto que não se lê, e uma chave «"k":» da linha que não esteja dentro
##    de nenhum objecto lido (escrita à mão no texto, fora do JSON) contam também.
## Devolve SÓ a contagem — o valor fora da forma, num vazamento, é o próprio valor, e não se imprime. As chaves fora de
## `CHAVES_PERMITIDAS` contam-se em `_fora_da_lista`; aqui só a forma do que é permitido.
func _forma_fora(lx: String) -> int:
	var fora := 0
	var vistas := [0]  # as chaves percorridas nos objectos lidos
	for obj in _objectos_json(lx):
		var v = JSON.parse_string(obj)
		if v == null:
			fora += 1  # um objecto que não se lê não se confere
			continue
		fora += _andar_forma(v, "caixa", vistas)
	var re_chave := RegEx.create_from_string("\"((?:[^\"\\\\]|\\\\.)*)\"\\s*:")
	fora += maxi(0, re_chave.search_all(lx).size() - int(vistas[0]))
	return fora


## B7-CORRECOES-4 (B1): percorre um valor lido do JSON; `nivel` = "caixa" (o objecto de topo), "od" (dentro de uma
## `ordemDinamica` com a forma certa) ou "" (qualquer outro sítio). Conta em `vistas[0]` as chaves que percorre.
func _andar_forma(v, nivel: String, vistas: Array) -> int:
	var n := 0
	if v is Array:
		for x in v:
			n += _andar_forma(x, "", vistas)
	elif v is Dictionary:
		for k in v:
			vistas[0] += 1
			var x = v[k]
			var ks := str(k)
			if not CHAVES_PERMITIDAS.has(ks):
				n += _andar_forma(x, "", vistas)  # fora da lista: já conta em `_fora_da_lista`; aqui só o de dentro
				continue
			var no_nivel := (nivel == "caixa" and CHAVES_CAIXA.has(ks)) or (nivel == "od" and CHAVES_ORDEM_DINAMICA.has(ks))
			var forma_ok := false
			match ks:
				"ligada", "fechada":
					forma_ok = typeof(x) == TYPE_BOOL
				"ordemPor":
					forma_ok = x is String and x == "dinamico"
				"ultimo":
					forma_ok = _e_id(x)
				"ordem":
					forma_ok = x is Array
					if forma_ok:
						for y in x:
							forma_ok = forma_ok and _e_id(y)
				"ordemDinamica":
					forma_ok = x is Dictionary
			if not (no_nivel and forma_ok):
				n += 1
			n += _andar_forma(x, "od" if ks == "ordemDinamica" and forma_ok else "", vistas)
	return n


## B7-CORRECOES-4 (B1): um id = texto de 17 hexadecimais (o limite B2 está em `RE_ID`).
func _e_id(v) -> bool:
	return v is String and RegEx.create_from_string(RE_ID).search(v) != null


## B7-CORRECOES-4 (B1): os objectos JSON de topo da linha («{…}», com as chavetas e as aspas emparelhadas). Uma
## chaveta que não fecha dá o resto da linha (que depois não se lê, e conta).
func _objectos_json(lx: String) -> Array:
	var objs: Array = []
	var fundo := 0
	var em_texto := false
	var escapado := false
	var ini := -1
	for i in range(lx.length()):
		var c := lx[i]
		if em_texto:
			if escapado:
				escapado = false
			elif c == "\\":
				escapado = true
			elif c == "\"":
				em_texto = false
			continue
		if c == "\"" and fundo > 0:
			em_texto = true
		elif c == "{":
			if fundo == 0:
				ini = i
			fundo += 1
		elif c == "}" and fundo > 0:
			fundo -= 1
			if fundo == 0:
				objs.append(lx.substr(ini, i - ini + 1))
	if fundo > 0:
		objs.append(lx.substr(ini))
	return objs


## Tudo o que retém as linhas: as proibidas achadas (pelo nome, da lista) e, à parte, as CONTAGENS do que está fora das
## listas permitidas (B1). Vazio = as linhas só têm o permitido.
func _achados_em(linhas_v: Array) -> Array:
	var achados: Array = _proibidas_em(linhas_v)
	var chaves := 0
	var palavras := 0
	var forma := 0
	for linha_r in linhas_v:
		var f := _fora_da_lista(str(linha_r))
		chaves += int(f["chaves"])
		palavras += int(f["palavras"])
		forma += int(f["forma"])
	if chaves > 0:
		achados.append("chave(s) fora da lista: %d" % chaves)
	if palavras > 0:
		achados.append("palavra(s) fora da lista: %d" % palavras)
	if forma > 0:
		achados.append("valor(es) fora da forma: %d" % forma)  # B7-CORRECOES-4 (B1): só a contagem
	return achados


## B7-CORRECOES-2 (B2): o eco das linhas, chamado SÓ DEPOIS da varredura. Uma linha limpa imprime-se inteira; uma linha
## com palavras proibidas não — sai o rótulo (o texto antes do primeiro «:», que é do teste) e as palavras achadas. Num
## vazamento real o valor não chega ao log cometido.
## B7-CORRECOES-3 (B1): «limpa» = sem proibidas E só com chaves e palavras permitidas (`_achados_em`). O rótulo de uma
## linha retida só se imprime se ele próprio for só do permitido; senão sai o número da linha.
func _ecoar(linhas_v: Array) -> void:
	for i in range(linhas_v.size()):
		var lx := str(linhas_v[i])
		var achadas: Array = _achados_em([lx])
		if achadas.is_empty():
			print("  linha: ", lx)
		else:
			var rot := lx.get_slice(":", 0)
			if not _achados_em([rot]).is_empty():
				rot = "n.º %d" % (i + 1)
			print("  linha %s: RETIDA (não se imprime; tem %s)" % [rot, achadas])


## Ordem CAIXA-RELATO-B7 (Mecânica D4 da conferência da CAIXA-RELATO-CORRECOES): `Estado.limpar()` emite
## `snapshot_aplicado` — as provas recomeçam aí o contador (`_registar_snapshot` → novo_snap) — mas deixava
## `eventos_desde_snapshot` com os eventos do snapshot de ANTES. A verificação B2 das provas (a contagem e os tipos do
## relato = os que o Estado aplicou desde o snapshot) falhava depois de um `limpar()` sem snapshot novo. Aqui com o
## ESTADO REAL (res://estado/estado.gd, fora da árvore: sem Rede, sem Mestre) e a mesma ligação das provas.
## Só ids opacos: o snapshot DESTE CASO (o que o teste monta) não traz `propria` nem nomes; nada de vida, alma ou PA.
## B7-CORRECOES (B2): as linhas do relato deste caso também passam pela varredura de privacidade (no fim do caso).
## B7-CORRECOES-2 (B1): e "propria" está em `PROIBIDAS` — «não traz `propria`» confere-se nas linhas, não só na montagem.
## B7-CORRECOES-3 (B1/B2): e também sem acentos («própria»), e nenhuma chave ou palavra fora das listas permitidas.
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
	# B7-CORRECOES-2 (B4): cada linha presa pelo rótulo e pela origem; B7-1 pela âncora «seq 1,». A B7-2 e a B7-3 têm o
	# mesmo corpo (o evento à espera não muda nada): o rótulo distingue-as, e o teste confere que o corpo é igual.
	# B7-CORRECOES-3 (B4, registo): a B7-2/B7-3 distinguem-se SÓ pelo rótulo, e não se inventa âncora. Limite inerente
	# aos dados: uma troca ou duplicação dos dois passos do meio (p. ex. o passo 3 sem o evento à espera, igual ao 2)
	# dá as mesmas 4 linhas e passa esta verificação — não há nada no corpo que os distinga.
	var seqs := ["seq 1,", "seq 0,", "seq 0,", "seq 5,"]
	var presas := linhas_b7.size() == 4
	for i in range(mini(linhas_b7.size(), 4)):
		presas = presas and str(linhas_b7[i]).begins_with("B7-%d:" % (i + 1)) and str(linhas_b7[i]).contains(seqs[i])
	presas = presas and str(linhas_b7[1]).get_slice(":", 0) != str(linhas_b7[2]).get_slice(":", 0) 		and str(linhas_b7[1]).trim_prefix("B7-2") == str(linhas_b7[2]).trim_prefix("B7-3")
	_ok(presas,
		"B7-CORRECOES: a varredura do caso do limpar() cobre as 4 linhas do relato, cada uma presa pelo rótulo e pela origem (B7-1 seq 1, B7-2 seq 0, B7-3 seq 0 com o mesmo corpo da B7-2, B7-4 seq 5; %d linhas)" % linhas_b7.size())
	var achadas_b7: Array = _achados_em(linhas_b7)  # B7-CORRECOES-3 (B1): proibidas E fora das listas permitidas
	_ok(achadas_b7.is_empty(), "B7-CORRECOES: nenhuma linha do caso do limpar() ganha nomes, vida, alma, PA nem `propria`, nem nada fora das chaves e palavras permitidas %s" % [achadas_b7])
	_ecoar(linhas_b7)  # B7-CORRECOES-2 (B2): o eco só depois da varredura, e só das linhas limpas
	est.free()
