extends RefCounted
## O que o ecrã do Mestre mostra e que comando cada botão monta (JV3.1, I0004, 08/11/2026).
##
## Só funções puras: recebem a MASTER_VIEW e o MASTER_CARD tal como o servidor os mandou e devolvem
## texto e comandos. Não calculam regra nenhuma (os motores não se traduzem): a frase que a Party
## vai ler sai das mesmas frases do site (hud/frases_batalha.gd), a partir da proposta do motor.
##
## Este ficheiro só é usado dentro de cenas/mestre/: o lugar da jogadora nunca o carrega.

const Textos := preload("res://cenas/mestre/textos_mestre.gd")
const Frases := preload("res://hud/frases_batalha.gd")


# ---------------------------------------------------------------- figuras

static func figuras(vista: Dictionary) -> Array:
	var m = vista.get("mestre")
	if not (m is Dictionary) or not (m.get("figuras") is Array):
		return []
	return m["figuras"]


static func figura(vista: Dictionary, id: String) -> Dictionary:
	for f in figuras(vista):
		if f is Dictionary and str(f.get("id", "")) == id:
			return f
	return {}


## Nome para o Mestre: o verdadeiro, com o público entre parênteses quando é diferente.
static func nome_mestre(f: Dictionary) -> String:
	var nome := _texto(f.get("nome"))
	var publico := _texto(f.get("nomePublico"))
	if nome == "":
		return publico
	if publico != "" and publico != nome:
		return "%s (%s)" % [nome, publico]
	return nome


## A Party vê a figura? Só se está na lista pública da vista (a figura só existe para a Party depois do
## MASTER_PLACE). O campo público `visivel` é o estado visual (de_pe, caida, transformada, morta), não
## esconder: o servidor não tem figuras escondidas além das não colocadas.
static func visivel_para_party(vista: Dictionary, id: String) -> bool:
	var lista = vista.get("figuras")
	if lista is Array:
		for p in lista:
			if p is Dictionary and str(p.get("id", "")) == id:
				return true
	return false


## Uma linha por figura: nome · lado · vida a/b · PA livre/total · modo · estados.
static func linha_figura(vista: Dictionary, f: Dictionary) -> String:
	var partes: Array[String] = [nome_mestre(f), str(Textos.LADO.get(_texto(f.get("lado")), _texto(f.get("lado"))))]
	partes.append(Textos.VIDA % [_num_txt(f.get("vidaActual")), _num_txt(f.get("vidaTotal"))])
	var pa_total = f.get("paTotal")
	if pa_total is float or pa_total is int:
		partes.append(Textos.PA % [_num_txt(float(pa_total) - float(f.get("paGasto", 0))), _num_txt(pa_total)])
	var modo := _texto(f.get("modo"))
	if modo != "":
		partes.append(str(Textos.MODO.get(modo, modo)))
	if f.get("colocada") != true:
		partes.append(Textos.NAO_COLOCADA)
	elif not visivel_para_party(vista, _texto(f.get("id"))):
		partes.append(Textos.OCULTA)
	if f.get("vivo") == false:
		partes.append(Textos.MORTA)
	elif f.get("caido") == true:
		partes.append(Textos.CAIDA)
	if f.get("armaCaida") == true:
		partes.append(Textos.ARMA_CAIDA)
	if f.get("armaQuebrada") == true:
		partes.append(Textos.ARMA_QUEBRADA)
	if f.get("corpoPartido") == true:
		partes.append(Textos.CORPO)
	return " · ".join(PackedStringArray(partes))


## Figuras pela ordem da iniciativa; as que não estão na ordem (não colocadas) vão no fim.
static func figuras_por_ordem(vista: Dictionary) -> Array:
	var ordem = vista.get("iniciativa")
	var saida: Array = []
	var vistas := {}
	if ordem is Array:
		for id in ordem:
			var f := figura(vista, str(id))
			if not f.is_empty():
				saida.append(f)
				vistas[str(id)] = true
	for f in figuras(vista):
		if f is Dictionary and not vistas.has(_texto(f.get("id"))):
			saida.append(f)
	return saida


# ---------------------------------------------------------------- sala, vez e ambiente

static func linha_sala(vista: Dictionary) -> String:
	var m = vista.get("mestre")
	var fase := _texto(vista.get("fase"))
	if m is Dictionary and m.get("pausa") is Dictionary:
		fase = "pausa"
	var linha := str(Textos.FASE.get(fase, fase))
	if vista.get("selo") is String and vista.get("selo") != "":
		linha = Textos.SELO % vista["selo"] + linha  # L9: o selo TESTE, só no ecrã do Mestre
	var vez := _texto(vista.get("vezId"))
	if vez != "":
		linha += "\n" + Textos.RODADA_VEZ % [int(vista.get("rodada", 0)), nome_mestre(figura(vista, vez))]
	return linha


static func linhas_ambiente(vista: Dictionary) -> Array[String]:
	var m = vista.get("mestre")
	var a: Dictionary = m.get("ambiente") if m is Dictionary and m.get("ambiente") is Dictionary else {}
	var efeito: Dictionary = vista.get("ambiente") if vista.get("ambiente") is Dictionary else {}
	var publico: Array[String] = []
	for k in ["luz", "clima"]:
		var v := _texto(efeito.get(k))
		if v != "":
			publico.append(v)
	var saida: Array[String] = []
	saida.append(Textos.HORA % _ou_traco(a.get("hora")))
	saida.append(Textos.CLIMA % _ou_traco(a.get("clima")))
	saida.append(Textos.FUTURO % _ou_traco(a.get("futuro")))
	saida.append(Textos.PARTY_VE % (", ".join(PackedStringArray(publico)) if not publico.is_empty() else Textos.SEM_VALOR))
	return saida


## Cartões abertos que a vista conhece (para o contador da fila).
static func cartoes_abertos(vista: Dictionary) -> Array:
	var m = vista.get("mestre")
	if m is Dictionary and m.get("cartoes") is Array:
		return m["cartoes"]
	return []


static func cartao_interno(vista: Dictionary, cartao_id: String) -> Dictionary:
	for c in cartoes_abertos(vista):
		if c is Dictionary and _texto(c.get("cartaoId")) == cartao_id:
			return c
	return {}


## Um ponto de «voltar» (MASTER_VIEW.pontos, L8) em texto: «Rodada 2 · vez de Orc · movimento, vez nova».
static func linha_ponto(vista: Dictionary, p: Dictionary) -> String:
	var tipos = p.get("tipos")
	if tipos is Array and tipos.size() == 1 and str(tipos[0]) == "inicio":
		return Textos.PONTO_INICIO
	var nomes := PackedStringArray()
	if tipos is Array:
		for t in tipos:
			nomes.append(str(Textos.NOME_EVENTO.get(str(t), str(t))))
	var vez := _texto(p.get("vezId"))
	var quem := nome_mestre(figura(vista, vez)) if vez != "" else Textos.SEM_VALOR
	if quem == "":
		quem = Textos.SEM_VALOR
	return Textos.PONTO % [int(p.get("rodada", 0)), quem, ", ".join(nomes)]


# ---------------------------------------------------------------- cartões

## A desgraça proposta: {id} do VLAB, {tipo} do motor falso, ou texto.
static func efeito_proposto(proposta) -> String:
	if proposta is String:
		return proposta
	if proposta is Dictionary:
		for k in ["id", "tipo"]:
			var v := _texto(proposta.get(k))
			if v != "":
				return v
	return ""


## A frase que a Party vai ler se o Mestre confirmar (as frases do site). Vazia para «nenhuma».
static func frase_prevista(cartao: Dictionary, vista: Dictionary, efeito: String = "") -> String:
	if efeito == "":
		efeito = efeito_proposto(cartao.get("proposta"))
	if efeito == "" or efeito == "nenhuma":
		return ""
	var f := figura(vista, _texto(cartao.get("figuraId")))
	var interno := cartao_interno(vista, _texto(cartao.get("cartaoId")))
	var arma := _texto(interno.get("tecnicaId")).replace("-", " ").replace("_", " ").strip_edges()
	# A Party lê o nome PÚBLICO. A perda do quebra-corpo só a diz se o servidor a aplicar (perdeQuarto).
	var frase := Frases.desgraca(efeito, _texto(f.get("nomePublico")), _texto(f.get("lado")) == "jogadora", arma, false)
	return Frases.com_cabecalho(frase)


## Descreve o cartão para a doca: {titulo, linhas, botoes:[{rotulo, acao, duas_vezes, ligado}]}.
static func descrever_cartao(cartao: Dictionary, vista: Dictionary) -> Dictionary:
	if cartao.is_empty():
		return {"titulo": Textos.SEM_CARTAO, "linhas": [], "botoes": []}
	var tipo := _texto(cartao.get("tipo"))
	var f := figura(vista, _texto(cartao.get("figuraId")))
	var quem := nome_mestre(f) if not f.is_empty() else ""
	var linhas: Array[String] = []
	var botoes: Array = []
	match tipo:
		"desgraca":
			var efeito := efeito_proposto(cartao.get("proposta"))
			linhas.append(quem)
			linhas.append(Textos.PROPOSTA % str(Textos.NOME_DESGRACA.get(efeito, efeito)))
			var frase := frase_prevista(cartao, vista)
			if frase != "":
				linhas.append(Textos.A_PARTY_VAI_LER % frase)
			# Regra-mãe (vale o site): a rolagem da falha crítica não se deita fora — sem «Sem desgraça».
			botoes = [
				_botao(Textos.CONFIRMAR, "confirmar", false),
				_botao(Textos.ESCOLHER_OUTRA, "escolher", false, cartao.get("desgracas") is Array),
			]
		"ia":
			linhas.append(quem)
			linhas.append(Textos.PROPOSTA % descrever_acao(cartao.get("proposta"), vista))
			var razao := _texto(cartao.get("razao"))
			if razao != "":
				linhas.append(Textos.RAZAO % razao)
			# L10: com o cartão de IA aberto o servidor manda ao Mestre as opções da criatura, por isso
			# «Escolher outra» abre a aba Agir para escolher a acção (MASTER_APPROVE editar {acao}).
			# L6: numa marcha pura o primeiro botão é «Continuar a rodada» (D4: um Continuar por rodada).
			var primeiro: Dictionary = _botao(Textos.CONTINUAR_RODADA, "continuar_rodada", false) if marcha_pura(cartao.get("proposta")) \
				else _botao(Textos.CONFIRMAR, "confirmar", false)
			botoes = [
				primeiro,
				_botao(Textos.ESCOLHER_OUTRA, "escolher", false),
				_botao(Textos.JOGO_EU, "jogo_eu", true),
			]
		"progresso":
			linhas.append(Textos.ENCERRAR_PERGUNTA % quem)
			botoes = [_botao(Textos.ENCERRAR_A_VEZ, "encerrar", false), _botao(Textos.CONTINUAR, "continuar", false)]
		"dados":
			linhas.append(quem)
			var faces = cartao.get("faces")
			var lista_faces := PackedStringArray()
			if faces is Array:
				for x in faces:
					lista_faces.append(_num_txt(x))
			linhas.append(Textos.FACES % (", ".join(lista_faces) if not lista_faces.is_empty() else Textos.SEM_VALOR))
			botoes = [_botao(Textos.CONFIRMAR, "aceitar_dados", false), _botao(Textos.NAO_ACEITAR, "nao_aceitar", true)]
		_:
			linhas.append(tipo)
	return {"titulo": str(Textos.TITULO.get(tipo, tipo)), "linhas": linhas, "botoes": botoes}


static func descrever_acao(acao, vista: Dictionary) -> String:
	if not (acao is Dictionary):
		return Textos.SEM_VALOR
	var t := _texto(acao.get("tipo"))
	match t:
		"mover":
			var d = acao.get("destino")
			return "mover para %s,%s" % [_num_txt(d.get("x")), _num_txt(d.get("y"))] if d is Dictionary else "mover"
		"atacar":
			return "atacar %s (%s)" % [nome_mestre(figura(vista, _texto(acao.get("alvoId")))), _texto(acao.get("arma")).replace("-", " ")]
		"encerrar":
			return "encerrar a vez"
		_:
			return t


## L6: a proposta é uma marcha pura (andar ou encerrar a vez)? Igual à lista do servidor (sala.js MARCHA_PURA).
static func marcha_pura(proposta) -> bool:
	return proposta is Dictionary and ["mover", "encerrar"].has(_texto(proposta.get("tipo")))


## L9: as linhas das estatísticas (só o Mestre). Vazio se a vista não as traz.
static func linhas_estatisticas(vista: Dictionary) -> Array[String]:
	var saida: Array[String] = []
	var e = vista.get("estatisticas")
	if not (e is Dictionary):
		return saida
	var ids := {}
	for k in ["ataques", "danoCausado", "danoSofrido"]:
		if e.get(k) is Dictionary:
			for id in e[k]:
				ids[str(id)] = true
	for id in ids:
		var f := figura(vista, id)
		var nome: String = nome_mestre(f) if not f.is_empty() else str(id)
		saida.append(Textos.ESTAT_FIGURA % [nome, int(e.get("ataques", {}).get(id, 0)),
			_num_txt(e.get("danoCausado", {}).get(id, 0)), _num_txt(e.get("danoSofrido", {}).get(id, 0))])
	var c = e.get("cartoes")
	if c is Dictionary and not c.is_empty():
		var partes := PackedStringArray()
		for d in c:
			partes.append("%s %d" % [str(Textos.NOME_DECISAO.get(str(d), str(d))), int(c[d])])
		saida.append(Textos.ESTAT_CARTOES % ", ".join(partes))
	if saida.is_empty():
		saida.append(Textos.ESTAT_SEM)
	return saida


## O comando que um botão do cartão monta: {tipo, campos}, ou {} se o botão não manda nada.
static func comando(cartao: Dictionary, acao: String, escolha: String = "") -> Dictionary:
	var id := _texto(cartao.get("cartaoId"))
	match acao:
		"confirmar", "encerrar":
			return {"tipo": "MASTER_APPROVE", "campos": {"cartaoId": id, "decisao": "aprovar"}}
		"continuar_rodada":
			return {"tipo": "MASTER_APPROVE", "campos": {"cartaoId": id, "decisao": "aprovar", "rodada": true}}
		"jogo_eu", "continuar":
			return {"tipo": "MASTER_APPROVE", "campos": {"cartaoId": id, "decisao": "recusar"}}
		"escolha":
			var lista = cartao.get("desgracas")
			if not (lista is Array) or not lista.has(escolha):
				return {}  # L2: só da lista que o servidor mandou
			return {"tipo": "MASTER_APPROVE", "campos": {"cartaoId": id, "decisao": "editar", "edicao": {"desgraca": escolha}}}
		"aceitar_dados", "nao_aceitar":
			return {"tipo": "MASTER_CONFIRM_DICE",
				"campos": {"intentId": _texto(cartao.get("intentIdOrigem")), "aceitar": acao == "aceitar_dados"}}
		_:
			return {}


# ---------------------------------------------------------------- alertas

static func texto_alerta(msg: Dictionary) -> String:
	var motivo := _texto(msg.get("motivo"))
	match motivo:
		"bloqueio_join":
			return Textos.ALERTA["bloqueio_join"] % _texto(msg.get("alvo"))
		"segunda_ligacao":
			return Textos.ALERTA["segunda_ligacao"] % (_texto(msg.get("nome")) if _texto(msg.get("nome")) != "" else _texto(msg.get("papel")))
		_:
			return motivo


# ---------------------------------------------------------------- utilidades

static func _botao(rotulo: String, acao: String, duas_vezes: bool, ligado: bool = true) -> Dictionary:
	return {"rotulo": rotulo, "acao": acao, "duas_vezes": duas_vezes, "ligado": ligado}


static func _texto(v) -> String:
	return v if v is String else ""


static func _ou_traco(v) -> String:
	return v if v is String and v != "" else Textos.SEM_VALOR


static func _num_txt(v) -> String:
	if v is float and is_equal_approx(v, roundf(v)):
		return str(int(v))
	if v is int or v is float:
		return str(v)
	return Textos.SEM_VALOR
