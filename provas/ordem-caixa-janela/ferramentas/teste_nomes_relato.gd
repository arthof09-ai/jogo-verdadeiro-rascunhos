extends SceneTree
## Ordem CAIXA-JANELA-NOMES — o teste dos NOMES do relato da prova da caixa-janela, sem servidor e sem ecrã.
## Usa o ajudante que a prova usa (`nomes_relato.gd`) e as FICHAS DE BANCADA reais
## (`rascunhos/servidor/autojogo/fichas-bancada.json`: «Bruto de Bancada»/«Bruto», «Lobo de Bancada»/«Lobo» — os
## valores-canário). Reproduz o defeito medido: o relato cometido da CAIXA-JANELA (`provas/ordem-caixa-janela/cliente/
## relato.txt`, a corrida de antes desta ordem) traz os nomes verdadeiros, e o canário do relato tem de os apanhar.
## Um nome verdadeiro de bancada numa linha do relato = o canário dá achados = a prova FALHA.
##
## Correr (na raiz do repo):
##   godot --headless --path rascunhos/cliente -s "$PWD/provas/ordem-caixa-janela/ferramentas/teste_nomes_relato.gd"

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

	# Uma vista do Mestre como a da bancada: uma figura por ficha (id = o fichaId), com nome e nomePublico das fichas.
	var figuras: Array = []
	var por_id := {}
	var lista = fichas_json.get("fichas", fichas_json.get("lista", []))
	if lista is Dictionary:
		lista = lista.values()
	for f in lista:
		if f is Dictionary and f.has("nome"):
			var fig := {"id": str(f["id"]), "nome": f["nome"], "nomePublico": f.get("nomePublico"), "vidaActual": 9}
			figuras.append(fig)
			por_id[str(f["id"])] = fig
	var vista := {"mestre": {"figuras": figuras}}
	_ok(por_id.has("bruto-bancada") and por_id.has("lobo-bancada"), "as fichas de bancada têm o Bruto e o Lobo (%d fichas)" % figuras.size())
	if not (por_id.has("bruto-bancada") and por_id.has("lobo-bancada")):
		_fim()
		return
	var bruto: Dictionary = por_id["bruto-bancada"]
	var lobo: Dictionary = por_id["lobo-bancada"]

	print("== 1. os canários: os nomes verdadeiros que diferem do público ==")
	var canarios: Array = N.nomes_verdadeiros(vista)
	_ok(canarios.has("Bruto de Bancada") and canarios.has("Lobo de Bancada"), "1: «Bruto de Bancada» e «Lobo de Bancada» são canários %s" % [canarios])
	_ok(not canarios.has("Espadachim de Bancada") and not canarios.has("Arqueira de Bancada"),
		"1: as heroínas (nome = nome público) não são canários")
	var dup := {"mestre": {"figuras": figuras + [bruto.duplicate()]}}
	_ok(N.nomes_verdadeiros(dup).size() == canarios.size(), "1: figuras repetidas (as 8 criaturas da prova) não repetem o canário")

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
	_ok(achados_limpo.is_empty(), "3: o relato escrito pela fonte (nome público) passa o canário %s" % [achados_limpo])
	# O caso: um nome verdadeiro de bancada no relato tem de falhar.
	var sujo := limpo.duplicate()
	sujo.append("  bancada: Bruto de Bancada → {\"tipo\":\"encerrar\"} (APLICADA)")
	var achados_sujo: Array = N.no_relato(sujo, canarios)
	_ok(achados_sujo == ["Bruto de Bancada na linha 5"], "3: «Bruto de Bancada» na linha 5 → o canário FALHA %s" % [achados_sujo])
	var sujo2 := PackedStringArray(['  ordem ["Lobo","Lobo de Bancada"]'])
	_ok(N.no_relato(sujo2, canarios) == ["Lobo de Bancada na linha 1"], "3: dentro de JSON também se apanha («Lobo de Bancada»)")
	_ok(N.no_relato(sujo, []).is_empty(), "3: sem canários não há achados (por isso a prova exige ≥ 1 canário)")

	print("== 4. o caso medido: o relato cometido da CAIXA-JANELA de antes desta ordem ==")
	var velho_p := ProjectSettings.globalize_path("res://").path_join("../../provas/ordem-caixa-janela/cliente/relato.txt").simplify_path()
	var velho := FileAccess.get_file_as_string(velho_p)
	if velho == "":
		_ok(false, "4: abriu %s" % velho_p)
	else:
		var achados_velho: Array = N.no_relato(PackedStringArray(velho.split("\n")), canarios)
		_ok(not achados_velho.is_empty(), "4: o canário apanha os nomes verdadeiros no relato antigo (%d achados; o 1.º: %s)" % [
			achados_velho.size(), achados_velho[0] if not achados_velho.is_empty() else "-"])
	_fim()


func _fim() -> void:
	print("")
	print("teste dos nomes do relato da caixa-janela: %d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 or _total == 0 else 0)
