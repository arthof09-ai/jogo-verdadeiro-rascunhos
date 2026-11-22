extends RefCounted
## Ordem CAIXA-JANELA-NOMES — os nomes que o RELATO da prova da caixa-janela escreve, e o canário que os confere.
## O relato é cometido: não pode trazer o `nome` verdadeiro das figuras (o valor-canário da bancada), só o `nomePublico`
## (o que a Party vê). O mesmo remédio da B1 da CAIXA-RELATO-CORRECOES-2, aqui partilhado pela prova
## (`prova_caixa_janela.gd`) e pelo seu teste (`teste_nomes_relato.gd`), para que o teste exercite o código da prova.


## O nome que vai para o relato: o `nomePublico` da figura; sem nome público, o id. Nunca o `nome` verdadeiro.
static func nome_publico(f: Dictionary, id: String) -> String:
	var np = f.get("nomePublico")
	return str(np) if np is String and np != "" else id


## O nome público da figura `id` na vista do Mestre `v` (o id se não está lá).
static func nome(v: Dictionary, id: String) -> String:
	for f in v.get("mestre", {}).get("figuras", []):
		if str(f.get("id", "")) == id:
			return nome_publico(f, id)
	return id


## A linha «bancada: …» do relato (uma acção jogada pela IA de bancada).
static func linha_bancada(quem: Dictionary, vez_id: String, passo: Dictionary, estado: String) -> String:
	return "  bancada: %s → %s (%s)" % [nome_publico(quem, vez_id), JSON.stringify(passo), estado]


## Os canários: os nomes verdadeiros das figuras da vista do Mestre que diferem do nome público (sem repetidos).
static func nomes_verdadeiros(v: Dictionary) -> Array:
	var nomes: Array = []
	for f in v.get("mestre", {}).get("figuras", []):
		var n := str(f.get("nome", "")) if f.get("nome") is String else ""
		if n != "" and n != str(f.get("nomePublico", "")) and not nomes.has(n):
			nomes.append(n)
	return nomes


## CAIXA-JANELA-NOMES-CORRECOES (B6): uma vista do Mestre feita do ELENCO (as fichas, p. ex. `fichas-bancada.json`):
## uma figura por ficha (id = o id da ficha), só com `id`, `nome` e `nomePublico` — nada de vida, PA ou outro campo.
## Serve para tirar os canários antes de haver vista nenhuma (`nomes_verdadeiros(vista_do_elenco(...))`).
static func vista_do_elenco(fichas_json) -> Dictionary:
	var figuras: Array = []
	if fichas_json is Dictionary:
		var lista = fichas_json.get("fichas", fichas_json.get("lista", []))
		if lista is Dictionary:
			lista = lista.values()
		if lista is Array:
			for f in lista:
				if f is Dictionary and f.has("nome"):
					figuras.append({"id": str(f.get("id", "")), "nome": f["nome"], "nomePublico": f.get("nomePublico")})
	return {"mestre": {"figuras": figuras}}


## As linhas do relato que trazem algum dos nomes dados («<nome> na linha <n>»). Vazio = o relato está limpo.
## Só para o teste conferir o caso: o diagnóstico que vai para um relato ou registo é o de `diagnostico()`, sem nomes.
static func no_relato(relato: PackedStringArray, nomes: Array) -> Array:
	var achados: Array = []
	for i in relato.size():
		for k in nomes:
			if relato[i].contains(str(k)):
				achados.append("%s na linha %d" % [k, i + 1])
	return achados


## CAIXA-JANELA-NOMES-CORRECOES (B4): os números das linhas com achados (sem repetidos, por ordem).
static func linhas(relato: PackedStringArray, nomes: Array) -> Array:
	var ls: Array = []
	for i in relato.size():
		for k in nomes:
			if relato[i].contains(str(k)) and not ls.has(i + 1):
				ls.append(i + 1)
	return ls


## CAIXA-JANELA-NOMES-CORRECOES (B4): o diagnóstico de uma varredura — a contagem de achados e as linhas, NUNCA os
## nomes (o diagnóstico vai para o relato e para os registos, que são cometidos: escrever lá o nome achado era a fuga).
static func diagnostico(relato: PackedStringArray, nomes: Array) -> String:
	return "%d achado(s), linhas %s" % [no_relato(relato, nomes).size(), JSON.stringify(linhas(relato, nomes))]


## CAIXA-JANELA-COBERTURA (C1; as faltas 1 e 2 da B7 da CAIXA-JANELA-NOMES-CORRECOES): as CHAVES privadas
## que nenhuma linha do relato pode trazer. A varredura é por chaves e não por valores: os valores de bancada
## (vida 16/22/30/34, PA 0/6) confundem-se com coordenadas, seq e medidas. Apanha também um valor que a IA ou o protocolo
## ponham no passo da linha «bancada:» (que é `JSON.stringify(passo)`), p. ex. um custo de PA como `"custoPA":2`.
## CAIXA-JANELA-COBERTURA-CORRECOES (B1): de 5 para 12 chaves — `paGasto` (a chave de PA que a vista do Mestre traz
## de facto), `estadoMorte`, `armaCaida`, `armaQuebrada`, `corpoPartido`; o `custoPA` das técnicas; e o `dano`.
## (CORRECOES-4, B1:) NÃO são todas «só do Mestre»: 9 das 12 chegam à DONA (a jogadora da própria figura). Quem recebe
## cada uma (CORRECOES-5, B2: o Mestre recebe 10 das 12 do servidor — 8 nas figuras da vista do Mestre, `paLivre` no
## evento `estado` e `dano` no `soMestre`; a chave `custoPA` tem-na nas fichas que escreve e o servidor carrega, não
## na vista; `alma` não existe. A conferência das fontes está em
## `provas/ordem-caixa-janela/cobertura-correcoes-4/conferencia-fontes.log` e em
## `provas/ordem-caixa-janela/cobertura-correcoes-5/conferencia-fontes.log`):
##   chave          | onde chega à dona                                                    | quem a recebe
##   vidaActual     | `propria` do evento `estado` (`projecao.js:37`); `base.propria` do    | o Mestre e a dona
##                  | snapshot (`projecao.js:218`)                                         |
##   paLivre        | idem (`projecao.js:37`; `projecao.js:220`)                           | o Mestre e a dona
##   estadoMorte    | idem (`projecao.js:37`; `projecao.js:222`)                           | o Mestre e a dona
##   armaCaida      | idem (`projecao.js:37`; `projecao.js:223`)                           | o Mestre e a dona
##   armaQuebrada   | idem (`projecao.js:37`; `projecao.js:224`)                           | o Mestre e a dona
##   corpoPartido   | idem (`projecao.js:37`; `projecao.js:225`)                           | o Mestre e a dona
##   vidaTotal      | só no `base.propria` do snapshot (`projecao.js:219`)                 | o Mestre e a dona
##   paTotal        | só no `base.propria` do snapshot (`projecao.js:221`)                 | o Mestre e a dona
##   custoPA        | dentro da própria ficha (`ficha: clonarJson(ficha)`, `projecao.js:226`; | a dona (na ficha); o Mestre
##                  | um campo de cada técnica); não vai nas opções de ataque/cura          | tem-na nas fichas que
##                  |                                                                      | carrega, não na vista
##   paGasto        | não chega: à dona vai só o `paLivre` (= paTotal − paGasto)           | só o Mestre
##   alma           | não chega: nenhum campo de alma nas fontes (a chave fica de guarda)  | ninguém (guarda)
##   dano           | não chega como chave: o evento `dano` leva `valor`/`tipos`; a ficha  | só o Mestre (o `dano:`
##                  | só tem `expressaoDano`                                               | do `soMestre`, sala.js)
## O filtro não muda: o relato é cometido e lido por quem não é a dona, por isso exclui as 12 na mesma.
## Duas famílias de regex (`_re_chave`):
## - as 10 camelCase: em qualquer sítio da linha, sem distinguir maiúsculas (`(?i)`, B4: `VidaActual`/`vidaactual`),
##   mas não a meio de um identificador (`(?<![A-Za-z0-9_])`, B2: `capaLivre` não é `paLivre`);
## - «alma» e «dano», que também são palavras portuguesas (os rótulos dizem «vida, PA, alma»; a prosa diz «números de
##   dano»): só em FORMA DE CHAVE (B2) — `"k"`, `'k'`, `k:` / `k=`, `kCamel` (`almaLivre`, `danoTotal`), `k_snake`
##   (`alma_livre`) e `k` nua seguida de um número (`alma 3`, `dano -2`). Sempre com maiúscula/minúscula como estão
##   (`Alma` e `Dano` em início de frase são prosa).
## Limites que ficam (B2/B6; o teste §5 fixa-os):
## - «alma»/«dano» com maiúscula inicial em posição de chave (`"Alma":3`, `Dano: 4`) escapam — a casa escreve as
##   chaves em camelCase com minúscula, e a maiúscula é o início de frase da prosa;
## - «alma»/«dano» seguidos de pontuação e número (`alma, 3`; `dano (2d8)`) escapam — é a forma da prosa;
## - as 10 camelCase coladas a um prefixo (`figuraPaLivre`, `max_paGasto`) escapam — é o preço da lookbehind;
## - um VALOR sob uma chave que não está na lista (`"valor":16`, `"pv":22`) ou um número solto escapa: a varredura é
##   por nomes de chave, não por valores (R1 da RELATO-B7-CORRECOES; ver o ESTADO-FINAL, B6).
## CAIXA-JANELA-COBERTURA-CORRECOES-2 (B1): de 12 para 17 chaves — as 5 privadas que ainda passavam (latentes, não
## vivas): `custoM` e `reservaM` (a `propria` do evento `movimento`, `projecao.js:25`; o `custoM` também vem em cada casa
## de `opcoes.mover`, `sala.js:889`), `perdeQuarto` (a `propria` da `desgraca`, `projecao.js:38`), `reacaoDisponivel` e
## `defendendo` (por figura, `sala.js:551`).
## CAIXA-JANELA-COBERTURA-CORRECOES-3 (B1): quem recebe cada uma — NÃO são todas «só do Mestre». `custoM`/`reservaM`
## são `propria` do `movimento` (`projecao.js:25`): a própria jogadora recebe-as no evento; o `custoM` vai-lhe também
## em cada casa de `opcoes.mover` (`sala.js:889`) e a `reservaM` chega-lhe como `orcamentoM` (`sala.js:947`).
## `perdeQuarto` é `propria` da `desgraca` (`projecao.js:38`). Só `reacaoDisponivel`/`defendendo` (`sala.js:551`)
## não constam de `projecao.js` e são mesmo só do Mestre. O filtro não muda: o relato é cometido e lido por quem não
## é a dona dos valores, por isso exclui as 5 na mesma.
## - `custoM`/`reservaM` acabam no sufixo de unidade `M` (metros): o radical conta sem distinguir maiúsculas, o `M`
##   final só maiúsculo (`(?i:custo)M`) — para que «reservam» (verbo) e «custom» não tropecem;
## - `defendendo` também é palavra (gerúndio de «defender»): vai para a família de «alma»/«dano», só em forma de chave
##   (os valores são booleanos: `"defendendo":true`, `defendendo=false`, `{ "defendendo": true }` são apanhados).
## Limites que ficam, além dos de cima (B2 da CORRECOES-2; o teste §5 fixa-os):
## - `modo` NÃO é listável: a linha legítima da prova «caixa da jogadora ao abrir: visível=true modo=dinamico …»
##   tropeçaria em todas as corridas (`modo=` é forma de chave na própria linha). (CORRECOES-3, B2:) esse `modo=` NÃO é
##   o H10 da figura (nunca projectado, `sala.js:552`): é o rótulo do cliente (`ordem_turnos.modo`) para o `ordemPor`
##   da caixa (`ordem-dinamica.js:166`), que a Party vê por desenho. LATENTE: uma futura linha com o `modo` H10 de uma
##   figura (`modo=auto`, `"modo":"manual"`; valores em `sala.js:62`) escaparia à varredura;
## - «alma»/«dano»/«defendendo» em kebab (`alma-total`, `dano-total`) escapam — a casa não escreve chaves em kebab, e o
##   hífen é o da prosa composta;
## - `custoM`/`reservaM` com o `m` final minúsculo (`reservam=3`, `custom: 1`) escapam — o preço de não tropeçar no
##   verbo; «defendendo» nua seguida de booleano (`defendendo true`) escapa — é a forma da prosa;
## - falso alarme ACEITE (para o lado seguro): «alma»/«dano» nua seguida de número, em prosa («a alma 3 vezes»), É
##   apanhada, porque `alma 3` é forma de chave (B2); a prosa da casa escreve «a alma, 3 vezes», que passa.
const CHAVES_PROIBIDAS := ["vidaActual", "vidaTotal", "paTotal", "paLivre", "alma",
	"paGasto", "estadoMorte", "armaCaida", "armaQuebrada", "corpoPartido", "custoPA", "dano",
	"custoM", "reservaM", "perdeQuarto", "reacaoDisponivel", "defendendo"]
## As chaves que também são palavras portuguesas: só contam em forma de chave.
const CHAVES_PALAVRA := ["alma", "dano", "defendendo"]
## As chaves com sufixo de unidade maiúsculo (`M` = metros): o sufixo só conta maiúsculo.
const CHAVES_SUFIXO := ["custoM", "reservaM"]


static func _re_chave(k: String) -> RegEx:
	if CHAVES_PALAVRA.has(k):
		return RegEx.create_from_string(
			"(?<![A-Za-z0-9_])(?:%s[A-Z_][A-Za-z0-9_]*|\"%s\"|'%s'|%s[ \t]*[:=]|%s[ \t]*-?[0-9])" % [k, k, k, k, k])
	if CHAVES_SUFIXO.has(k):
		return RegEx.create_from_string("(?<![A-Za-z0-9_])(?i:%s)%s" % [k.left(-1), k.right(1)])
	return RegEx.create_from_string("(?i)(?<![A-Za-z0-9_])" + k)


## As chaves proibidas nas linhas do relato («<chave> na linha <n>», uma entrada por linha × chave). Vazio = limpo.
## Só para o teste conferir o caso; o diagnóstico que vai para o relato é o de `diagnostico_chaves()`.
static func chaves_no_relato(relato: PackedStringArray) -> Array:
	var achados: Array = []
	var res := {}
	for k in CHAVES_PROIBIDAS:
		res[k] = _re_chave(k)
	for i in relato.size():
		for k in CHAVES_PROIBIDAS:
			if (res[k] as RegEx).search(relato[i]) != null:
				achados.append("%s na linha %d" % [k, i + 1])
	return achados


## O diagnóstico da varredura das chaves: a contagem e as linhas, sem as chaves — o diagnóstico vai para o relato, e
## escrever lá a chave achada faria a varredura seguinte (a do `fim`) tropeçar no próprio rótulo.
static func diagnostico_chaves(relato: PackedStringArray) -> String:
	var ls: Array = []
	for a in chaves_no_relato(relato):
		var n := int(str(a).get_slice(" na linha ", 1))
		if not ls.has(n):
			ls.append(n)
	return "%d achado(s), linhas %s" % [chaves_no_relato(relato).size(), JSON.stringify(ls)]
