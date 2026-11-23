extends SceneTree
## Ordem CAIXA-JANELA-NOMES — o teste dos NOMES do relato da prova da caixa-janela, sem servidor e sem ecrã.
## Usa o ajudante que a prova usa (`nomes_relato.gd`) e as FICHAS DE BANCADA reais
## (`rascunhos/servidor/autojogo/fichas-bancada.json`: «Bruto de Bancada»/«Bruto», «Lobo de Bancada»/«Lobo» — os
## valores-canário). Reproduz o defeito medido: o relato cometido da CAIXA-JANELA (`provas/ordem-caixa-janela/cliente/
## relato.txt`, a corrida de antes da CAIXA-JANELA-NOMES) traz os nomes verdadeiros, e o canário do relato tem de os
## apanhar. Um nome verdadeiro de bancada numa linha do relato = o canário dá achados = a prova FALHA.
## CAIXA-JANELA-NOMES-CORRECOES: esse relato está CONGELADO aqui dentro (RELATO_VELHO, B2), para o §4 não depender do
## ficheiro (que é registo histórico e pode ser limpo por outra ordem); a vista vem do elenco pelo ajudante da prova
## (`vista_do_elenco`, B6); os diagnósticos dizem a contagem e as linhas, não os nomes (`diagnostico`, B4).
## CAIXA-JANELA-COBERTURA (C1): §5 — a varredura do relato por CHAVES proibidas de vida/PA/alma
## (`chaves_no_relato`, a mesma que a prova corre), com o caso de um passo «bancada:» que traz um custo de PA.
## CAIXA-JANELA-COBERTURA-CORRECOES: 12 chaves (B1), o caso testa o CUSTO (`custoPA`/`paGasto`), 49 formas (12×4+1),
## as formas de chave de «alma»/«dano» e a prosa (B2), as maiúsculas (B4) e os limites registados (B2/B6).
## CAIXA-JANELA-COBERTURA-CORRECOES-2: 17 chaves (B1: + `custoM`, `reservaM`, `perdeQuarto`, `reacaoDisponivel`,
## `defendendo`), o caso do custo também com `custoM`, 69 formas (17×4+1); os limites novos fixados (B2: `modo`, kebab,
## `m` minúsculo); o falso alarme da prosa «a alma 3 vezes» fixado (B5).
## CAIXA-JANELA-COBERTURA-CORRECOES-4: o rótulo das chaves passa a «chave privada» (B2: «do Mestre» deixava de fora a
## dona, que recebe 12 das 17 — a tabela está em `nomes_relato.gd`), com a prosa do §5 a acompanhar; e o TOTAL de
## verificações é afirmado no `_fim()` (B3: `VERIFICACOES` = 25; uma verificação apagada, ou saltada, é FALHA).
## No CI: job `cliente`, passo «Nomes do relato da caixa-janela» (B1).
##
## Correr (na raiz do repo):
##   godot --headless --path rascunhos/cliente -s "$PWD/provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd"

## CORRECOES-4 (B3): as verificações que o teste corre — 22 `_ok` locais + 1 em ciclo de 3 (§5, os custos) = 25.
## Afirmado no `_fim()` antes da linha do total: menos (uma verificação apagada, um ramo saltado) ou mais é FALHA.
## A verificação do total é ela própria um `_ok`, por isso a linha final diz 26 (as 25 + a do total).
const VERIFICACOES := 25

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
	var aqui := str(get_script().resource_path).get_base_dir()
	var N = load(aqui.path_join("nomes_relato.gd"))
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()  # rascunhos/
	var fichas_txt := FileAccess.get_file_as_string(raiz.path_join("servidor/autojogo/fichas-bancada.json"))
	var fichas_json = JSON.parse_string(fichas_txt)
	if N == null or not fichas_json is Dictionary:
		printerr("não abriu nomes_relato.gd ou as fichas de bancada (%s)" % raiz)
		quit(2)
		return
	print("== Ordem CAIXA-JANELA-NOMES — os nomes do relato da prova da caixa-janela ==")

	# Uma vista do Mestre como a da bancada: uma figura por ficha (id = o id da ficha), só com nome e nomePublico — a
	# mesma que a prova faz do elenco para os seus canários (nomes_relato.gd, vista_do_elenco; B6).
	var vista: Dictionary = N.vista_do_elenco(fichas_json)
	var figuras: Array = vista["mestre"]["figuras"]
	var por_id := {}
	for fig in figuras:
		por_id[str(fig["id"])] = fig
	_ok(por_id.has("bruto-bancada") and por_id.has("lobo-bancada"), "as fichas de bancada têm o Bruto e o Lobo (%d fichas)" % figuras.size())
	if not (por_id.has("bruto-bancada") and por_id.has("lobo-bancada")):
		_fim()
		return
	var bruto: Dictionary = por_id["bruto-bancada"]
	var lobo: Dictionary = por_id["lobo-bancada"]

	print("== 1. os canários: os nomes verdadeiros que diferem do público ==")
	var canarios: Array = N.nomes_verdadeiros(vista)
	_ok(canarios.has("Bruto de Bancada") and canarios.has("Lobo de Bancada"), "1: «nome n.º 1» e «nome n.º 2» são canários (%d)" % canarios.size())
	_ok(not canarios.has("Espadachim de Bancada") and not canarios.has("Arqueira de Bancada"),
		"1: as heroínas (nome = nome público) não são canários")
	var dup := {"mestre": {"figuras": figuras + [bruto.duplicate()]}}
	_ok(N.nomes_verdadeiros(dup).size() == canarios.size(), "1: uma ficha repetida não repete o canário (aqui as %d fichas + 1 Bruto repetido; na prova viva, 10 figuras de 4 fichas)" % figuras.size())

	print("== 2. a fonte: o relato escreve o nome PÚBLICO ==")
	_ok(N.nome(vista, "bruto-bancada") == "Bruto" and N.nome(vista, "lobo-bancada") == "Lobo",
		"2: _nome() da prova dá «%s» e «%s» (o público)" % [N.nome(vista, "bruto-bancada"), N.nome(vista, "lobo-bancada")])
	_ok(N.nome(vista, "nao-existe") == "nao-existe", "2: figura que não está na vista → o id")
	_ok(N.nome_publico({"id": "x", "nome": "Segredo de Bancada"}, "x") == "x", "2: sem nomePublico → o id, nunca o nome verdadeiro")
	_ok(N.nome_publico({"id": "x", "nome": "Segredo de Bancada", "nomePublico": ""}, "x") == "x", "2: nomePublico vazio → o id")
	var lb: String = N.linha_bancada(lobo, "lobo-bancada", {"tipo": "encerrar"}, "APLICADA")
	_ok(lb == "  bancada: Lobo → {\"tipo\":\"encerrar\"} (APLICADA)", "2: a linha «bancada:» traz o público: «%s»" % lb)
	var ordem: Array = ["bruto-bancada", "lobo-bancada", "espadachim-bancada"].map(func(x): return N.nome(vista, x))
	var la := "  a batalha a meio: fase combate, rodada 2, vez de %s, ordem dinâmica (Mestre) %s" % [N.nome(vista, "lobo-bancada"), JSON.stringify(ordem)]

	print("== 3. o canário do relato ==")
	var limpo := PackedStringArray(["== prova ==", lb, N.linha_bancada(bruto, "bruto-bancada", {"tipo": "mover"}, "APLICADA"), la])
	var achados_limpo: Array = N.no_relato(limpo, canarios)
	_ok(achados_limpo.is_empty(), "3: o relato escrito pela fonte (nome público) passa o canário (%s)" % N.diagnostico(limpo, canarios))
	# O caso: um nome verdadeiro de bancada no relato tem de falhar.
	var sujo := limpo.duplicate()
	sujo.append("  bancada: Bruto de Bancada → {\"tipo\":\"encerrar\"} (APLICADA)")
	var achados_sujo: Array = N.no_relato(sujo, canarios)
	_ok(achados_sujo == ["Bruto de Bancada na linha 5"], "3: «nome n.º 1» na linha 5 → o canário FALHA (%s)" % N.diagnostico(sujo, canarios))
	var sujo2 := PackedStringArray(['  ordem ["Lobo","Lobo de Bancada"]'])
	_ok(N.no_relato(sujo2, canarios) == ["Lobo de Bancada na linha 1"], "3: dentro de JSON também se apanha («nome n.º 2»)")
	_ok(N.no_relato(sujo, []).is_empty(), "3: sem canários não há achados (por isso a prova exige ≥ 1 canário)")

	print("== 4. o caso medido: o relato da CAIXA-JANELA de antes da CAIXA-JANELA-NOMES (congelado: RELATO_VELHO) ==")
	# B2: preso ao caso medido — 22 achados (linha × nome; 28 ocorrências brutas, porque a linha da ordem dinâmica traz
	# 4 «Lobo de Bancada» e 4 «Bruto de Bancada»), o 1.º «Lobo de Bancada na linha 7».
	var velho := PackedStringArray(RELATO_VELHO.split("\n"))
	var achados_velho: Array = N.no_relato(velho, canarios)
	var brutas := 0
	for k in canarios:
		brutas += RELATO_VELHO.count(str(k))
	_ok(achados_velho.size() == 22 and achados_velho[0] == "Lobo de Bancada na linha 7" and brutas == 28,
		"4: o canário apanha no relato antigo 22 achados (28 ocorrências brutas), o 1.º «nome n.º 2 na linha 7» (%s; %d brutas)" % [
		N.diagnostico(velho, canarios), brutas])

	print("== 5. C1 (+ B1–B4 das CORRECOES, B1/B2/B5 das CORRECOES-2) — as 17 chaves privadas no relato ==")
	var chaves: Array = N.CHAVES_PROIBIDAS
	_ok(chaves == ["vidaActual", "vidaTotal", "paTotal", "paLivre", "alma",
		"paGasto", "estadoMorte", "armaCaida", "armaQuebrada", "corpoPartido", "custoPA", "dano",
		"custoM", "reservaM", "perdeQuarto", "reacaoDisponivel", "defendendo"],
		"5: as chaves proibidas são as 17 privadas (vida, PA, alma, dano, morte, arma, corpo, movimento, desgraça, reacção, defesa) — %d" % chaves.size())
	# O relato escrito pela fonte e o relato antigo inteiro (com os seus rótulos «vida, PA» em palavra) passam.
	_ok(N.chaves_no_relato(limpo).is_empty() and N.chaves_no_relato(velho).is_empty(),
		"5: o relato da fonte e o relato antigo (%d linhas) não têm chaves (%s; %s)" % [velho.size(), N.diagnostico_chaves(limpo), N.diagnostico_chaves(velho)])
	# O caso (B1): a IA ou o protocolo põem no passo o CUSTO — o `custoPA` da técnica, o `paGasto` da figura (a chave de
	# PA que a vista do Mestre traz) ou o `custoM` da casa de destino (`opcoes.mover`, B1 da CORRECOES-2); a linha
	# «bancada:» escreve o passo inteiro.
	var custos := ["custoPA", "paGasto", "custoM"]
	for k in custos:
		var passo_pa := {"tipo": "atacar", "alvoId": "f00d", "arma": "golpe-forte-bancada", k: 2}
		var com_pa := limpo.duplicate()
		com_pa.append(N.linha_bancada(lobo, "lobo-bancada", passo_pa, "APLICADA"))
		_ok(N.chaves_no_relato(com_pa) == ["%s na linha 5" % k] and N.diagnostico_chaves(com_pa) == "1 achado(s), linhas [5]"
			and not N.diagnostico_chaves(com_pa).contains(k),
			"5: um passo «bancada:» com um custo (a %d.ª chave de custo) → a varredura FALHA (%s)" % [
				custos.find(k) + 1, N.diagnostico_chaves(com_pa)])
	# Cada chave, nas formas em que pode chegar a uma linha: JSON, `str()` de um Dictionary do Godot, `k=`/`k:` à mão.
	var formas := PackedStringArray()
	for k in chaves:
		formas.append("  x %s" % JSON.stringify({k: 9}))
		formas.append("  x %s" % str({k: 9}))
		formas.append("  x %s=9" % k)
		formas.append("  x %s: 9" % k)
	formas.append("  x almaLivre 3")
	var por_forma: Array = []
	for i in formas.size():
		por_forma.append(N.chaves_no_relato(PackedStringArray([formas[i]])).size())
	_ok(formas.size() == 69 and not por_forma.has(0) and N.diagnostico_chaves(formas) == "%d achado(s), linhas %s" % [formas.size(), JSON.stringify(range(1, formas.size() + 1))],
		"5: cada uma das 17 chaves é apanhada em JSON, em str() de Dictionary, em k= e em k: (e «almaLivre») — %d linhas (esperadas 69 = 17×4+1), %d achado(s)" % [formas.size(), N.chaves_no_relato(formas).size()])
	# As palavras não tropeçam (os rótulos usam-nas), e o diagnóstico não escreve a chave achada.
	var prosa := PackedStringArray([
		"  ok    1: nenhum dado do Mestre (nome verdadeiro, vida, PA) nos textos da caixa (0 achado(s), textos [])",
		"  ok    1: nenhuma chave privada no relato (40 linhas; 17 chaves proibidas; 0 achado(s), linhas [])",
		"  ok    fim: o relato inteiro (78 linhas) não traz nenhuma das 17 chaves privadas (0 achado(s), linhas [])",
		"  ok    1: nenhuma chave privada do Mestre no relato (40 linhas; 17 chaves proibidas; 0 achado(s), linhas [])",
		"  ok    1: nenhuma chave privada do Mestre no relato (40 linhas; 12 chaves proibidas; 0 achado(s), linhas [])",
		"  ok    1: nenhuma chave de vida/PA/alma no relato (40 linhas; 5 chaves proibidas; 0 achado(s), linhas [])",
		"  a alma do Lobo, com calma, na palma da mão; Alma; almas; vida total; PA livre; PA gasto; custo de PA",
		"  os números de dano do Lobo; o dano, 3 vezes; danos; abandono; Dano; dano (2d8+3); estado de morte; arma caída",
		"  a alma, 3 vezes; capaLivre; escapaTotal; mapaGasto; recustoPA",
		"  as figuras reservam 3 m; custom; o custo em m; a reserva em metros; perde um quarto; reacção disponível",
		"  a Arqueira está defendendo; Defendendo, o Bruto; defendendo o Lobo; incustoM; areservaM"])
	_ok(N.chaves_no_relato(prosa).is_empty(),
		"5: «vida», «PA», «alma», «dano», «morte», «arma», «reservam», «defendendo» como palavras, e as chaves a meio de outra palavra, não são chaves (%s)" % N.diagnostico_chaves(prosa))
	# B2: as formas seguras de chave de «alma»/«dano»/«defendendo» (snake_case, nua seguida de número, camelCase) — apanhadas.
	var formas_palavra := PackedStringArray(["  x alma_livre 3", "  x alma 3", "  x alma -1", "  x almaTotal",
		"  x dano_total 4", "  x dano 7", "  x dano=-2", "  x danoTotal", "  x 'dano'", "  x {\"dano\":5}",
		"  x {\"defendendo\":true}", "  x defendendo=false", "  x { \"defendendo\": true }", "  x 'defendendo'"])
	var por_palavra: Array = []
	for f in formas_palavra:
		por_palavra.append(N.chaves_no_relato(PackedStringArray([f])).size())
	_ok(not por_palavra.has(0), "5: «alma»/«dano»/«defendendo» em forma de chave (k_snake, k nua com número, kCamel, 'k', JSON) são apanhadas — %d de %d" % [
		por_palavra.count(1), formas_palavra.size()])
	# B4: as chaves camelCase não escapam por mudar maiúsculas/minúsculas (o `M` de unidade só maiúsculo, B1 da CORRECOES-2).
	var caixa := PackedStringArray(["  x VidaActual 3", "  x vidaactual 3", "  x PALIVRE 3", "  x CustoPa 2", "  x PaGasto 1", "  x EstadoMorte",
		"  x CUSTOM 3", "  x ReservaM 6", "  x PERDEQUARTO", "  x reacaodisponivel"])
	var por_caixa: Array = []
	for f in caixa:
		por_caixa.append(N.chaves_no_relato(PackedStringArray([f])).size())
	_ok(not por_caixa.has(0), "5: as chaves camelCase com outras maiúsculas (VidaActual, vidaactual, PALIVRE, CUSTOM, …) são apanhadas — %d de %d" % [
		por_caixa.count(1), caixa.size()])
	# B2/B6 (e B2 da CORRECOES-2): os limites que ficam, fixados para que mudem só de propósito (ver nomes_relato.gd e os
	# ESTADO-FINAL): um valor sob uma chave genérica, «Alma»/«Dano» com maiúscula, a palavra seguida de pontuação, a
	# chave com prefixo; `modo` (não listável: a linha legítima «modo=dinamico» é o rótulo do cliente para o
	# `ordemPor`, visível à Party — não o H10 da figura, B2 da CORRECOES-3), «alma»/«dano» em kebab, `custoM`/`reservaM`
	# com `m` minúsculo, «defendendo» nua com booleano.
	# B2 da CORRECOES-3: o LATENTE — o `modo` H10 de uma figura (`modo=auto`, `"modo":"manual"`) também escaparia.
	var limites := PackedStringArray(["  x {\"valor\":16}", "  x {\"Alma\":3}", "  x Dano: 4", "  x alma, 3", "  x figuraPaLivre 2", "  x max_paGasto 1",
		"  caixa da jogadora ao abrir: visível=true modo=dinamico vez=Lobo", "  x {\"modo\":\"dinamico\"}",
		"  x alma-total 3", "  x dano-total 4", "  x reservam=3", "  x custom: 1", "  x defendendo true",
		"  x modo=auto", "  x {\"modo\":\"manual\"}"])
	_ok(N.chaves_no_relato(limites).is_empty(),
		"5: limites registados — %d formas escapam por desenho (valor genérico, Alma/Dano maiúsculos, palavra + pontuação, chave com prefixo, modo (rótulo e H10 latente), kebab, m minúsculo, defendendo + booleano)" % limites.size())
	# B5 da CORRECOES-2: o falso alarme aceite, para o lado seguro — «alma»/«dano» nua seguida de número é forma de chave
	# (B2), por isso a prosa SEM vírgula («a alma 3 vezes») tropeça. Fixado: se isto mudar, muda de propósito.
	var alarme := PackedStringArray(["  a alma 3 vezes", "  o dano 3 vezes"])
	_ok(N.chaves_no_relato(alarme) == ["alma na linha 1", "dano na linha 2"] and N.diagnostico_chaves(alarme) == "2 achado(s), linhas [1,2]",
		"5: a prosa «a alma 3 vezes» (sem vírgula) É apanhada — falso alarme aceite, para o lado seguro (%s)" % N.diagnostico_chaves(alarme))
	_fim()

func _fim() -> void:
	# CORRECOES-4 (B3): o total afirmado — antes de contar a própria verificação.
	var corridas := _total
	_ok(corridas == VERIFICACOES, "fim: correram as %d verificações do teste (esperadas %d)" % [corridas, VERIFICACOES])
	print("")
	print("teste dos nomes do relato da caixa-janela: %d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 or _total == 0 else 0)


## B2 — o relato cometido da Ordem CAIXA-JANELA (`provas/ordem-caixa-janela/cliente/relato.txt`, blob `2b919f6b45f0`), congelado
## byte a byte. Traz os nomes verdadeiros de bancada (valores-canário, fichas fictícias) — é o caso que o §4 mede. Só
## nomes de bancada, coordenadas, seq e medidas: nenhuma vida, PA ou outro dado do Mestre.
const RELATO_VELHO := """== Ordem CAIXA-JANELA — a janela lobby→arena e a caixa com 10 figuras em ecrãs baixos (cliente a sério) ==
servidor ws://127.0.0.1:8793/ws · render NVIDIA GeForce RTX 4060 · Godot 4.7.2-stable (official)
== 0. batalha de bancada com 10 figuras (IA de bancada, lugares próprios) ==
  ok    a batalha tem 10 figuras (≥ 10)
  bancada: Arqueira de Bancada → {"destino":{"x":11,"y":10},"tipo":"mover"} (APLICADA)
  bancada: Arqueira de Bancada → {"tipo":"encerrar"} (APLICADA)
  bancada: Lobo de Bancada → {"destino":{"x":12,"y":10},"tipo":"mover"} (APLICADA)
  bancada: Lobo de Bancada → {"tipo":"encerrar"} (APLICADA)
  bancada: Lobo de Bancada → {"destino":{"x":11,"y":11},"tipo":"mover"} (APLICADA)
  bancada: Lobo de Bancada → {"tipo":"encerrar"} (APLICADA)
  bancada: Lobo de Bancada → {"destino":{"x":9,"y":11},"tipo":"mover"} (APLICADA)
  bancada: Lobo de Bancada → {"tipo":"encerrar"} (APLICADA)
  bancada: Lobo de Bancada → {"destino":{"x":10,"y":10},"tipo":"mover"} (APLICADA)
  bancada: Lobo de Bancada → {"tipo":"encerrar"} (APLICADA)
  bancada: Espadachim de Bancada → {"destino":{"x":10,"y":9},"tipo":"mover"} (APLICADA)
  bancada: Espadachim de Bancada → {"tipo":"encerrar"} (APLICADA)
  bancada: Bruto de Bancada → {"destino":{"x":10,"y":11},"tipo":"mover"} (APLICADA)
  bancada: Bruto de Bancada → {"tipo":"encerrar"} (APLICADA)
  bancada: Bruto de Bancada → {"destino":{"x":6,"y":12},"tipo":"mover"} (APLICADA)
  bancada: Bruto de Bancada → {"tipo":"encerrar"} (APLICADA)
  bancada: Bruto de Bancada → {"destino":{"x":14,"y":12},"tipo":"mover"} (APLICADA)
  bancada: Bruto de Bancada → {"tipo":"encerrar"} (APLICADA)
  bancada: Bruto de Bancada → {"destino":{"x":6,"y":11},"tipo":"mover"} (APLICADA)
  bancada: Bruto de Bancada → {"tipo":"encerrar"} (APLICADA)
  a batalha a meio: fase combate, rodada 2.0, vez de Arqueira de Bancada, ordem dinâmica (Mestre) ["Arqueira de Bancada","Lobo de Bancada","Lobo de Bancada","Lobo de Bancada","Lobo de Bancada","Espadachim de Bancada","Bruto de Bancada","Bruto de Bancada","Bruto de Bancada","Bruto de Bancada"]
  ok    batalha de bancada a meio: em combate e com a ordem dinâmica do servidor com 10 figuras (≥ 8)
== 1. B1 — a janela: o snapshot chega, a batalha anda, e SÓ DEPOIS a arena (e o HUD) abre ==
  ok    1: snapshot recebido (seq 33), ainda sem HUD e sem eventos depois dele
  bancada: Arqueira de Bancada → {"alvoId":"f00d6f54afaa36569","arma":"tiro-certeiro-bancada","tipo":"atacar"} (APLICADA)
  bancada: Arqueira de Bancada → {"tipo":"encerrar"} (APLICADA)
  bancada: Lobo de Bancada → {"alvoId":"ff2acf60bd672e76e","arma":"mordida-bancada","tipo":"atacar"} (APLICADA)
  bancada: Lobo de Bancada → {"tipo":"encerrar"} (APLICADA)
  bancada: Lobo de Bancada → {"alvoId":"ff2acf60bd672e76e","arma":"mordida-bancada","tipo":"atacar"} (APLICADA)
  bancada: Lobo de Bancada → {"tipo":"encerrar"} (APLICADA)
  na janela (sem HUD) a bancada jogou ["Arqueira de Bancada","Lobo","Lobo"]: 10 eventos chegaram ao Estado dela (seq 33 → 43)
  ok    1: a batalha andou entre o snapshot e o HUD (3 vezes, 10 eventos)
  ok    1: a arena abriu a meio da batalha (fase combate, rodada 2)
  caixa da jogadora ao abrir: visível=true modo=dinamico ordem=["Arqueira de Bancada","Lobo","Lobo","Lobo","Lobo","Espadachim de Bancada","Bruto","Bruto","Bruto","Bruto"] vez=Lobo
  ordem do servidor:          ["Arqueira de Bancada","Lobo","Lobo","Lobo","Lobo","Espadachim de Bancada","Bruto","Bruto","Bruto","Bruto"], vez Lobo
  ok    1: ao abrir, a caixa já é a ordem do servidor com os eventos da janela (10 figuras, vez Lobo), sem esperar pelo snapshot seguinte
  ok    1: nenhum snapshot novo chegou entretanto (os 10 eventos de depois do de seq 33 continuam por cima dele)
  ok    1: nenhuma mensagem do Mestre chegou ao aparelho dela (11 mensagens; sem caixaMestre, bloco mestre, MASTER_VIEW)
  ok    1: o estado dela não guarda nada do Mestre
  ok    1: a caixa que lhe chegou só tem ligada, ordemPor e ordemDinamica
  ok    1: nenhum dado do Mestre (nome verdadeiro, vida, PA) nos textos da caixa []
  ok    1: nenhum número nos textos da caixa (15 textos) []
== 2. B3 — a caixa com 10 figuras em ecrãs baixos ==
  MEDIDA viva 10 figuras · janela 1280x720 (unidades 1920x1080, escala 0.667): caixa 841x212 u = 560x141 px reais (44% x 20% do ecrã), 10 por linha, retrato 62 u = 41 px, nome 17 u = 11.3 px · faixa «O Mestre narra» livre 943 u (precisa 453 u) = 628 px reais, letra 14.7 px
  ok    1280x720: a caixa com as 10 figuras cabe no ecrã
  ok    1280x720: a caixa não tapa a ⚙/ficha nem a barra []
  ok    1280x720: a faixa tem 943 u para a frase mais comprida (453 u), numa linha, fora da caixa
  ok    1280x720: a fila segue a letra de agora (retrato 62 u = 2,8 × 22)
  ok    1280x720: a letra da faixa tem 14.7 px reais (≥ 13)
  ok    captura 1-janela-1280x720.png (1280×720)
  MEDIDA viva 10 figuras · janela 844x390 (unidades 2337x1080, escala 0.361): caixa 1326x323 u = 478x116 px reais (57% x 30% do ecrã), 10 por linha, retrato 101 u = 36 px, nome 27 u = 9.8 px · faixa «O Mestre narra» livre 819 u (precisa 729 u) = 295 px reais, letra 13.0 px
  ok    844x390: a caixa com as 10 figuras cabe no ecrã
  ok    844x390: a caixa não tapa a ⚙/ficha nem a barra []
  ok    844x390: a faixa tem 819 u para a frase mais comprida (729 u), numa linha, fora da caixa
  ok    844x390: a fila segue a letra de agora (retrato 101 u = 2,8 × 36)
  ok    844x390: a letra da faixa tem 13.0 px reais (≥ 13)
  ok    captura 2-baixo-844x390.png (844×390)
  MEDIDA viva 10 figuras · janela 780x360 (unidades 2340x1080, escala 0.333): caixa 1320x386 u = 440x128 px reais (56% x 36% do ecrã), 9 por linha, retrato 110 u = 37 px, nome 29 u = 9.7 px · faixa «O Mestre narra» livre 816 u (precisa 788 u) = 272 px reais, letra 13.0 px
  ok    780x360: a caixa com as 10 figuras cabe no ecrã
  ok    780x360: a caixa não tapa a ⚙/ficha nem a barra []
  ok    780x360: a faixa tem 816 u para a frase mais comprida (788 u), numa linha, fora da caixa
  ok    780x360: a fila segue a letra de agora (retrato 110 u = 2,8 × 39)
  ok    780x360: a letra da faixa tem 13.0 px reais (≥ 13)
  ok    captura 3-baixo-780x360.png (780×360)
  ok    2: nenhuma mensagem do Mestre chegou ao aparelho dela (11 mensagens; sem caixaMestre, bloco mestre, MASTER_VIEW)
  ok    2: o estado dela não guarda nada do Mestre
  ok    2: a caixa que lhe chegou só tem ligada, ordemPor e ordemDinamica
  ok    2: nenhum dado do Mestre (nome verdadeiro, vida, PA) nos textos da caixa []
  ok    2: nenhum número nos textos da caixa (15 textos) []

prova da janela e da caixa com 10 figuras: 35 de 35 verificações passaram.
"""
