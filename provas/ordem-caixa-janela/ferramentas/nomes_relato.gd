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


## As linhas do relato que trazem algum dos nomes dados («<nome> na linha <n>»). Vazio = o relato está limpo.
static func no_relato(relato: PackedStringArray, nomes: Array) -> Array:
	var achados: Array = []
	for i in relato.size():
		for k in nomes:
			if relato[i].contains(str(k)):
				achados.append("%s na linha %d" % [k, i + 1])
	return achados
