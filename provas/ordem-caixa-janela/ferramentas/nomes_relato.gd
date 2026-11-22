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
