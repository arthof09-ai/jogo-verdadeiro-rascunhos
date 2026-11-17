extends RefCounted
## ORDEM AUTOJOGO — IA DE BANCADA. FERRAMENTA DE MEDIÇÃO, NÃO É A IA DO JOGO.
##
## Vive só no modo de autojogo (res://autojogo/autojogo.gd, arrancado com -s). Nenhuma cena do jogo a carrega e ela
## nunca entra no caminho normal: a IA das criaturas do jogo continua a ser a do servidor (proporIA), que no autojogo
## fica desligada (criaturas em modo manual). Esta é a mais simples que joga uma partida até ao fim:
##   1. há ataque ao alcance (nas ROOM_OPTIONS que o servidor mandou) → ataca: a primeira técnica da lista do servidor
##      (a ordem da ficha) contra o inimigo mais perto (empate: o id menor);
##   2. ainda não atacou nem andou nesta vez e há casa na reserva de movimento que encurta a distância ao inimigo vivo
##      mais perto → anda para a casa que mais encurta (empate: a mais barata, depois y, depois x);
##   3. senão → encerra a vez.
## Não escolhe nada que o servidor não tenha oferecido: as regras continuam todas do servidor.
## Determinista: só decide pelo estado (vista do Mestre + opções); nenhum acaso, nenhuma hora.


## Distância em casas para a escolha (euclidiana ao quadrado: só serve para ordenar).
static func dist2(a: Vector2i, b: Vector2i) -> int:
	var d := a - b
	return d.x * d.x + d.y * d.y


static func casa(f: Dictionary) -> Vector2i:
	return Vector2i(int(f.get("x", 0)), int(f.get("y", 0)))


static func sao_inimigos(a: Dictionary, b: Dictionary) -> bool:
	return (str(a.get("lado", "")) == "jogadora") != (str(b.get("lado", "")) == "jogadora")


## Inimigos vivos e colocados de `quem`, da lista de figuras da MASTER_VIEW (mestre.figuras).
static func inimigos_vivos(quem: Dictionary, figuras: Array) -> Array:
	var r: Array = []
	for f in figuras:
		if not (f is Dictionary):
			continue
		if str(f.get("id", "")) == str(quem.get("id", "")):
			continue
		if not bool(f.get("vivo", false)) or not bool(f.get("colocada", false)):
			continue
		if sao_inimigos(quem, f):
			r.append(f)
	return r


## Distância ao inimigo vivo mais perto a partir da casa `c` (-1 = não há inimigos).
static func dist_ao_mais_perto(c: Vector2i, inimigos: Array) -> int:
	var melhor := -1
	for f in inimigos:
		var d := dist2(c, casa(f))
		if melhor < 0 or d < melhor:
			melhor = d
	return melhor


## Decide a acção desta vez.
##   quem: a figura da vez (da MASTER_VIEW, mestre.figuras)
##   figuras: todas as figuras da MASTER_VIEW (mestre.figuras)
##   opcoes: as ROOM_OPTIONS que o servidor mandou ao lugar que joga esta figura
##   vez: o que já se fez nesta vez {andou: bool, atacou: bool, accoes: int}
## Devolve {acao: Dictionary, razao: String}.
static func decidir(quem: Dictionary, figuras: Array, opcoes: Dictionary, vez: Dictionary) -> Dictionary:
	var accoes: Array = opcoes.get("acoes", []) if opcoes.get("acoes") is Array else []
	var ataques: Array = opcoes.get("ataques", []) if opcoes.get("ataques") is Array else []
	var mover: Array = opcoes.get("mover", []) if opcoes.get("mover") is Array else []
	var por_id := {}
	for f in figuras:
		if f is Dictionary:
			por_id[str(f.get("id", ""))] = f
	var aqui := casa(quem)
	# 1. atacar
	if not ataques.is_empty() and not bool(vez.get("atacou", false)):
		var arma := str((ataques[0] as Dictionary).get("arma", ""))
		var melhor: Dictionary = {}
		var melhor_d := -1
		for a in ataques:
			if not (a is Dictionary) or str(a.get("arma", "")) != arma:
				continue
			var alvo: Dictionary = por_id.get(str(a.get("alvoId", "")), {})
			var d := dist2(aqui, casa(alvo)) if not alvo.is_empty() else 1 << 30
			var aid := str(a.get("alvoId", ""))
			if melhor.is_empty() or d < melhor_d or (d == melhor_d and aid < str(melhor.get("alvoId", ""))):
				melhor = a
				melhor_d = d
		return {"acao": {"tipo": "atacar", "alvoId": str(melhor["alvoId"]), "arma": arma}, "razao": "ao alcance"}
	# 2. aproximar
	var inimigos := inimigos_vivos(quem, figuras)
	if not bool(vez.get("andou", false)) and not bool(vez.get("atacou", false)) and not mover.is_empty() and not inimigos.is_empty():
		var agora_d := dist_ao_mais_perto(aqui, inimigos)
		var escolha: Dictionary = {}
		var escolha_d := agora_d
		for o in mover:
			if not (o is Dictionary):
				continue
			var c := Vector2i(int(o.get("x", 0)), int(o.get("y", 0)))
			var d := dist_ao_mais_perto(c, inimigos)
			if d < escolha_d or (not escolha.is_empty() and d == escolha_d and _antes(o, escolha)):
				escolha = o
				escolha_d = d
		if not escolha.is_empty() and escolha_d < agora_d:
			return {"acao": {"tipo": "mover", "destino": {"x": int(escolha["x"]), "y": int(escolha["y"])}}, "razao": "aproxima"}
	# 3. encerrar (está sempre nas opções enquanto há vez)
	if accoes.has("encerrar") or accoes.is_empty():
		return {"acao": {"tipo": "encerrar"}, "razao": "nada ao alcance" if not bool(vez.get("atacou", false)) else "já atacou"}
	return {"acao": {"tipo": "encerrar"}, "razao": "sem opção"}


## Desempate das casas: a mais barata, depois y, depois x (a mesma ordem em que o servidor as manda).
static func _antes(a: Dictionary, b: Dictionary) -> bool:
	var ca := float(a.get("custoM", 0.0))
	var cb := float(b.get("custoM", 0.0))
	if ca != cb:
		return ca < cb
	if int(a.get("y", 0)) != int(b.get("y", 0)):
		return int(a.get("y", 0)) < int(b.get("y", 0))
	return int(a.get("x", 0)) < int(b.get("x", 0))
