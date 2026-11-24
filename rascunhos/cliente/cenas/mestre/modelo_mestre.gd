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
	# Ordem 13: a chuva (do clima), os raios, o raio pedido e o fogo com o combustível — só neste ecrã.
	var chuva := nivel_chuva(_texto(a.get("clima")))
	saida.append(Textos.CHUVA % Textos.CHUVA_NIVEL[chuva])
	var raios := Textos.RAIOS_DESLIGADOS
	if a.get("raios") == true:
		raios = Textos.RAIOS_LIGADOS if chuva > 0 else Textos.RAIOS_SEM_CHUVA
	saida.append(Textos.RAIOS % raios)
	if a.get("raioPendente") == true:
		saida.append(Textos.RAIO_PENDENTE)
	var fogo: Dictionary = m.get("fogo") if m is Dictionary and m.get("fogo") is Dictionary else {}
	var casas: Array[String] = []
	for k in (fogo.get("casas") if fogo.get("casas") is Array else []):
		if k is Dictionary:
			casas.append(Textos.CASA_COMBUSTIVEL % [_inteiro(k.get("x")), _inteiro(k.get("y")), _inteiro(k.get("combustivel"))])
	saida.append(Textos.CASAS_A_ARDER % (", ".join(PackedStringArray(casas)) if not casas.is_empty() else Textos.NINGUEM))
	var ardem: Array[String] = []
	for id in (fogo.get("aArder") if fogo.get("aArder") is Array else []):
		ardem.append(_nome_curto(vista, str(id)))
	saida.append(Textos.A_ARDER % (", ".join(PackedStringArray(ardem)) if not ardem.is_empty() else Textos.NINGUEM))
	saida.append(Textos.FUTURO % _ou_traco(a.get("futuro")))
	saida.append(Textos.PARTY_VE % (", ".join(PackedStringArray(publico)) if not publico.is_empty() else Textos.SEM_VALOR))
	return saida


# ---------------------------------------------------------------- ambiente: raio e fogo (ordem 13, dívida E1)
#
# As regras são do servidor (nucleo/ambiente.js). Aqui: o nível da chuva para mostrar, os comandos do painel e a
# narração ao Mestre (a frase do site com o nome verdadeiro + a linha do registo com os números do soMestre).

## 0 sem chuva, 1 pouca, 2 forte — a mesma leitura do servidor (clima «chuva» / «tempestade»).
static func nivel_chuva(clima: String) -> int:
	return 2 if clima == "tempestade" else (1 if clima == "chuva" else 0)


## O painel do ambiente que está na vista (bloco do Mestre).
static func painel_ambiente(vista: Dictionary) -> Dictionary:
	var m = vista.get("mestre")
	return m.get("ambiente") if m is Dictionary and m.get("ambiente") is Dictionary else {}


## Campos do MASTER_AMBIENTE para mudar a hora `passo` horas (a hora do painel é «HH:MM»; sem hora, parte das 12:00).
static func hora_mais(vista: Dictionary, passo: int) -> Dictionary:
	var h := 12
	var mi := 0
	var t := _texto(painel_ambiente(vista).get("hora"))
	var partes := t.split(":")
	if partes.size() == 2 and partes[0].is_valid_int() and partes[1].is_valid_int():
		h = int(partes[0])
		mi = int(partes[1])
	h = posmod(h + passo, 24)
	return {"hora": "%02d:%02d" % [h, mi]}


## Campos do MASTER_AMBIENTE para ligar/desligar os raios.
static func alternar_raios(vista: Dictionary) -> Dictionary:
	return {"raios": painel_ambiente(vista).get("raios") != true}


## O «⚡ Raio agora» pode ir? (o servidor confere tudo; isto só acende/apaga o botão.)
static func raio_agora_possivel(vista: Dictionary) -> bool:
	var a := painel_ambiente(vista)
	return _texto(vista.get("fase")) == "combate" and a.get("raios") == true \
		and nivel_chuva(_texto(a.get("clima"))) > 0 and a.get("raioPendente") != true \
		and int(a.get("raioPedidoRodada", 0)) != int(vista.get("rodada", 0))


## A narração ao Mestre de um ROOM_EVENT do ambiente (como o Mestre o recebe, com soMestre): lista de
## {frase, linha}. Vazia se o evento não é do ambiente. A frase é a do site com o nome verdadeiro; a linha leva
## os números (origem, dano, combustível, faces) que só o Mestre vê.
static func narrar_ambiente(msg: Dictionary, v: Dictionary) -> Array:
	var r: Array = []
	var d = msg.get("dados")
	if not (d is Dictionary):
		return r
	var so = d.get("soMestre") if d.get("soMestre") is Dictionary else {}
	match _texto(msg.get("tipo")):
		"raio":
			var alvo := _texto(d.get("alvoId"))
			var cruz: Array = so.get("cruz") if so.get("cruz") is Array else []
			var linha: String = Textos.REGISTO_RAIO % [str(Textos.ORIGEM_RAIO.get(_texto(so.get("origem")), _texto(so.get("origem")))),
				_inteiro(d.get("x")), _inteiro(d.get("y")), _inteiro(so.get("combustivel")), cruz.size()]
			var frase := Frases.raio_na_arena()
			if alvo != "":
				var f := figura(v, alvo)
				frase = Frases.raio_atinge(_nome_curto(v, alvo), _texto(f.get("lado")) == "jogadora", _texto(d.get("desfecho")))
				linha += Textos.REGISTO_RAIO_DANO % [_nome_curto(v, alvo), _inteiro(so.get("dano"))]
			r.append({"frase": frase, "linha": linha})
		"dano_ambiente":
			if _texto(d.get("origem")) != "fogo":
				return r  # o do raio já foi narrado com o `raio`
			var quem := _texto(d.get("alvoId"))
			var f := figura(v, quem)
			var faces: Array = so.get("faces") if so.get("faces") is Array else []
			r.append({
				"frase": Frases.fogo_morde(_nome_curto(v, quem), _texto(f.get("lado")) == "jogadora", _texto(d.get("desfecho"))),
				"linha": Textos.REGISTO_FOGO % [_nome_curto(v, quem), _inteiro(so.get("dano")),
					_inteiro(faces[0]) if not faces.is_empty() else 0, Textos.REGISTO_FOGO_PEGOU if so.get("pegouFogo") == true else ""],
			})
		"fogo":
			for a in (d.get("apagados") if d.get("apagados") is Array else []):
				if a is Dictionary:
					var fid := _texto(a.get("figuraId"))
					var f := figura(v, fid)
					var porque := _texto(a.get("porque"))
					r.append({
						"frase": Frases.fogo_apagado(_nome_curto(v, fid), _texto(f.get("lado")) == "jogadora", porque),
						"linha": Textos.REGISTO_APAGADO % [_nome_curto(v, fid), str(Textos.PORQUE_APAGADO.get(porque, porque))],
					})
			_extintas(so, r)
		"ambiente_mestre", "ambiente":
			if so.get("raioCancelado") == true:
				r.append({"frase": "", "linha": Textos.RAIO_CANCELADO})
			_extintas(so, r)
	return r


static func _extintas(so: Dictionary, r: Array) -> void:
	for e in (so.get("extintas") if so.get("extintas") is Array else []):
		if e is Dictionary:
			var porque := _texto(e.get("porque"))
			r.append({"frase": "", "linha": Textos.REGISTO_EXTINTA % [_inteiro(e.get("x")), _inteiro(e.get("y")),
				str(Textos.PORQUE_EXTINTA.get(porque, porque))]})


# ---------------------------------------------------------------- «Exportar registo» (ordem 13, parte D)

## O que o ficheiro do «Exportar registo» leva: o registo do servidor (MASTER_EXPORT.conteudo, INTACTO — é texto
## assinado, e o «restaurar» precisa dos mesmos bytes) e a narração deste ecrã, da mais antiga para a mais nova.
static func conteudo_export(conteudo, narracao: Array) -> Dictionary:
	var n: Array[String] = []
	for t in narracao:
		n.append(str(t))
	return {"formato": "registo-mestre/1", "marca": "MESTRE-ONLY", "registo": conteudo, "narracao": n}


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
## ORDEM-D-AUD-07-REGISTO: a rodada e a vez do rótulo são as de QUEM FEZ A JOGADA (`rodadaAutor`/`autorId`, a vez de
## antes da transacção), não as de depois (`rodada`/`vezId`, para onde o «voltar» vai). Sala de antes desta ordem (sem os
## campos novos): fica a linha de antes.
static func linha_ponto(vista: Dictionary, p: Dictionary) -> String:
	var tipos = p.get("tipos")
	if tipos is Array and tipos.size() == 1 and str(tipos[0]) == "inicio":
		return Textos.PONTO_INICIO
	var nomes := PackedStringArray()
	if tipos is Array:
		for t in tipos:
			nomes.append(str(Textos.NOME_EVENTO.get(str(t), str(t))))
	var tem_autor := p.has("autorId") and p.has("rodadaAutor")
	var vez := _texto(p.get("autorId")) if tem_autor else _texto(p.get("vezId"))
	var rodada := int(p.get("rodadaAutor", 0)) if tem_autor else int(p.get("rodada", 0))
	var quem := nome_mestre(figura(vista, vez)) if vez != "" else Textos.SEM_VALOR
	if quem == "":
		quem = Textos.SEM_VALOR
	return Textos.PONTO % [rodada, quem, ", ".join(nomes)]


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
			# Ordem 14: no cartão de um monstro, a primeira linha é a da falha, como no site; o nome continua lá.
			var falha := frase_cartao_falha(cartao, vista)
			linhas.append(falha if falha != "" else quem)
			linhas.append(Textos.PROPOSTA % str(Textos.NOME_DESGRACA.get(efeito, efeito)))
			var frase := frase_prevista(cartao, vista)
			if frase != "":
				linhas.append(Textos.A_PARTY_VAI_LER % frase)
			# Regra-mãe (vale o site): a rolagem da falha crítica não se deita fora — sem «Sem desgraça» no cartão.
			# Ordem 8 (item 5; REF_34): ao recusar a proposta, o «Não acontece nada» vem no fim da lista do «Escolher outra».
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
	return {"titulo": titulo_cartao(cartao, vista), "linhas": linhas, "botoes": botoes}


## O título do cartão. Ordem 15: o cartão de desgraça de um ataque de oportunidade diz «Ataque de oportunidade» (o
## marcador vem do cartão interno da vista do Mestre; o MASTER_CARD não muda).
static func titulo_cartao(cartao: Dictionary, vista: Dictionary) -> String:
	var tipo := _texto(cartao.get("tipo"))
	if tipo == "desgraca" and cartao_interno(vista, _texto(cartao.get("cartaoId"))).get("ataqueDeOportunidade") == true:
		return Textos.TITULO_OPORTUNIDADE
	return str(Textos.TITULO.get(tipo, tipo))


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
		"nada":
			# Ordem 8 (item 5; site REF_34): «Não acontece nada» — só num cartão de desgraça, só pela mão do Mestre.
			if _texto(cartao.get("tipo")) != "desgraca":
				return {}
			return {"tipo": "MASTER_APPROVE", "campos": {"cartaoId": id, "decisao": "recusar", "edicao": {"semDesgraca": true}}}
		"amigo":
			# Q12: «acerta-amigo» com o amigo declarado — só um dos `amigos` do cartão, e só se o «acerta-amigo»
			# está na lista (o servidor recusa o resto; o VLAB também: ALIADO_ATINGIDO_NAO_ELEGIVEL).
			var lista_d = cartao.get("desgracas")
			var amigos = cartao.get("amigos")
			if not (lista_d is Array) or not lista_d.has("acerta-amigo") or not (amigos is Array) or not amigos.has(escolha):
				return {}
			return {"tipo": "MASTER_APPROVE", "campos": {"cartaoId": id, "decisao": "editar",
				"edicao": {"desgraca": "acerta-amigo", "aliadoAtingidoId": escolha}}}
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


## Q12: os amigos que o Mestre pode escolher no «acerta-amigo» — só quando há MAIS DE UM (com um só, ou
## nenhum, não há o que escolher: vale o primeiro, o mais perto). Ordem do servidor (do mais perto).
static func amigos_para_escolher(cartao: Dictionary) -> Array:
	var amigos = cartao.get("amigos")
	var lista_d = cartao.get("desgracas")
	if not (amigos is Array) or amigos.size() < 2 or not (lista_d is Array) or not lista_d.has("acerta-amigo"):
		return []
	return amigos.duplicate()


# ---------------------------------------------------------------- caída atingida (ordem 12)
#
# Paridade com o site (REF_35; jogo.js vlabAplicarAlvoDepois → 'falhaDeMorte'): quando um golpe acerta na heroína
# que JÁ estava a morrer e o motor lhe sobe as falhas, o site narra «ela, caída, piora visivelmente» e regista a falha
# por golpe. A regra é do motor e do servidor; aqui só se COMPARA o estadoMorte de antes com o que o servidor mandou.
#
# O servidor não emite `estado` neste caso (a Vida fica a 0 e o visível fica «caida»): a falha nova só chega ao Mestre
# no próprio `ataque`, em soMestre.soDoMestre.alvoDepois.estadoMorte. O «antes» é o espelho que o ecrã guarda: a vista
# (bloco mestre) e, entre vistas, o que os eventos trazem (mortes_do_evento).

## id → estadoMorte (ou null) de cada figura da vista do Mestre.
static func mortes_da_vista(v: Dictionary) -> Dictionary:
	var r := {}
	for f in figuras(v):
		if f is Dictionary and _texto(f.get("id")) != "":
			r[f["id"]] = f.get("estadoMorte")
	return r


## O estadoMorte novo que um ROOM_EVENT (como o Mestre o recebe) traz, por figura.
static func mortes_do_evento(msg: Dictionary) -> Dictionary:
	var r := {}
	var d = msg.get("dados")
	if not (d is Dictionary):
		return r
	var so = d.get("soMestre")
	match _texto(msg.get("tipo")):
		"estado":
			var fid := _texto(d.get("figuraId"))
			if fid == "":
				return r
			if d.has("estadoMorte"):
				r[fid] = d["estadoMorte"]  # jogadora: vem nos dados
			elif so is Dictionary and so.has("estadoMorte"):
				r[fid] = so["estadoMorte"]  # monstro: vem no soMestre
		"ataque":
			var sdm = so.get("soDoMestre") if so is Dictionary else null
			if sdm is Dictionary:
				for par in [["alvoId", "alvoDepois"], ["atacanteId", "atacanteDepois"]]:
					var fid := _texto(d.get(par[0]))
					var dep = sdm.get(par[1])
					if fid != "" and dep is Dictionary and dep.has("estadoMorte"):
						r[fid] = dep["estadoMorte"]
	return r


## A falha de morte por golpe deste `ataque`, ou {} se não houve:
## {alvoId, atacanteId, oportunidade, sucessos, falhas}.
## Como no site: só a jogadora; só se ANTES já estava a morrer (a queda nova não é isto — narra-se como queda); só se as
## falhas subiram; e não quando o golpe a matou (a morte narra-se pelo fim da batalha).
static func falha_por_golpe(msg: Dictionary, mortes: Dictionary, v: Dictionary) -> Dictionary:
	if _texto(msg.get("tipo")) != "ataque":
		return {}
	var d = msg.get("dados")
	if not (d is Dictionary):
		return {}
	var alvo := _texto(d.get("alvoId"))
	var f := figura(v, alvo)
	if alvo == "" or (not f.is_empty() and _texto(f.get("lado")) != "jogadora"):
		return {}
	var so = d.get("soMestre")
	var sdm = so.get("soDoMestre") if so is Dictionary else null
	var dep = sdm.get("alvoDepois") if sdm is Dictionary else null
	if not (dep is Dictionary):
		return {}
	var depois = dep.get("estadoMorte")
	var antes = mortes.get(alvo)
	if not (depois is Dictionary and antes is Dictionary):
		return {}
	if _texto(antes.get("fase")) != "aMorrer" or _texto(depois.get("fase")) != "aMorrer":
		return {}
	if _inteiro(depois.get("falhas")) <= _inteiro(antes.get("falhas")):
		return {}
	if dep.get("morteAdjudicada") == true or dep.get("vivo") == false:
		return {}
	var vida = dep.get("vidaActual")
	if (vida is int or vida is float) and float(vida) > 0.0:
		return {}
	return {
		"alvoId": alvo, "atacanteId": _texto(d.get("atacanteId")), "oportunidade": d.get("ataqueDeOportunidade") == true,
		"sucessos": _inteiro(depois.get("sucessos")), "falhas": _inteiro(depois.get("falhas")),
	}


## A frase que o Mestre lê (a do site, com o nome dela).
static func frase_caida_piora(v: Dictionary, r: Dictionary) -> String:
	var atac := _texto(r.get("atacanteId"))
	if r.get("oportunidade") == true:
		return Textos.CAIDA_PIORA_OPORTUNIDADE % [_nome_curto(v, atac), _nome_curto(v, _texto(r.get("alvoId")))]
	return Textos.CAIDA_PIORA % [_nome_curto(v, atac), verbo_acerto(v, atac), _nome_curto(v, _texto(r.get("alvoId")))]


## Ordem 13 (parte C; site jogo.js FRASES_IA → verbos.acerto): o verbo do golpe que vem na ficha do monstro (a vista
## do Mestre traz `verbos`); sem ele, «acerta». Só texto: a mecânica não muda.
static func verbo_acerto(v: Dictionary, id: String) -> String:
	var verbos = figura(v, id).get("verbos")
	if verbos is Dictionary and _texto(verbos.get("acerto")) != "":
		return _texto(verbos["acerto"])
	return Textos.VERBO_ACERTO_PADRAO


# ---------------------------------------------------------------- falha do monstro (ordem 14)
#
# Paridade com o site (jogo.js atacarIA, ramos 'erra' e 'falhaCritica'; série de oportunidade; cartão de desgraça em
# modo «monstro»): quando o monstro falha o golpe, a narração diz a falha com o verbo próprio dele (verbos.falha da
# ficha). Só texto, a partir do que o servidor já manda ao Mestre: a mecânica não muda.
#
# Na falha crítica o site junta numa frase só a falha e a desgraça («… e falhou. A arma (machado) caiu-lhe da mão.»;
# sem desgraça aplicada, «O golpe correu mal.»). O servidor emite o `ataque` e, logo a seguir (journalSeq + 1), a
# `desgraca` quando há uma aplicada; por isso a falha crítica espera pelo evento seguinte para se fechar.

## O verbo da falha da ficha do monstro; sem ele, o do site para quem não tem verbos («tentou atacar»).
static func verbo_falha(v: Dictionary, id: String) -> String:
	var verbos = figura(v, id).get("verbos")
	if verbos is Dictionary and _texto(verbos.get("falha")) != "":
		return _texto(verbos["falha"])
	return Textos.VERBO_FALHA_PADRAO


## A falha de um monstro neste `ataque`, ou {} se não é isso:
## {atacanteId, alvoId, oportunidade, critica, arma, journalSeq}. Só criaturas (o golpe falhado da heroína tem as frases
## dela no HUD) e só figuras que a vista conhece.
static func falha_do_monstro(msg: Dictionary, v: Dictionary) -> Dictionary:
	if _texto(msg.get("tipo")) != "ataque":
		return {}
	var d = msg.get("dados")
	if not (d is Dictionary):
		return {}
	var res := _texto(d.get("resultado"))
	if res != "erro" and res != "falha_critica":
		return {}
	var atac := _texto(d.get("atacanteId"))
	var f := figura(v, atac)
	if atac == "" or f.is_empty() or _texto(f.get("lado")) == "jogadora":
		return {}
	var js = d.get("journalSeq")
	return {
		"atacanteId": atac, "alvoId": _texto(d.get("alvoId")), "oportunidade": d.get("ataqueDeOportunidade") == true,
		"critica": res == "falha_critica", "arma": _texto(d.get("arma")),
		"journalSeq": int(js) if js is int or js is float else -1,
	}


## A desgraça aplicada que fecha esta falha crítica ({efeito, perdeQuarto}), ou {} se `msg` não é ela: tem de ser a
## `desgraca` do mesmo atacante e, quando o fio traz o journalSeq, o evento logo a seguir ao `ataque`.
static func desgraca_da_falha(msg: Dictionary, r: Dictionary) -> Dictionary:
	if _texto(msg.get("tipo")) != "desgraca" or r.is_empty():
		return {}
	var d = msg.get("dados")
	if not (d is Dictionary) or _texto(d.get("figuraId")) != _texto(r.get("atacanteId")):
		return {}
	var js = d.get("journalSeq")
	if (js is int or js is float) and int(r.get("journalSeq", -1)) >= 0 and int(js) != int(r["journalSeq"]) + 1:
		return {}
	return {"efeito": _texto(d.get("efeito")), "perdeQuarto": d.get("perdeQuarto") == true}


## A frase do site para a falha do monstro. `desg` é a desgraça que a fechou ({} = nenhuma aplicada).
static func frase_falha_monstro(v: Dictionary, r: Dictionary, desg: Dictionary = {}) -> String:
	var atac := _texto(r.get("atacanteId"))
	var nome := _nome_curto(v, atac)
	var frase: String
	if r.get("oportunidade") == true:
		frase = Textos.FALHA_OPORTUNIDADE % nome
	else:
		frase = Textos.FALHA_MONSTRO % [nome, verbo_falha(v, atac), _nome_curto(v, _texto(r.get("alvoId")))]
	if r.get("critica") == true:
		# Sem desgraça aplicada (o Mestre escolheu «Não acontece nada»), o site diz «O golpe correu mal.».
		frase += " " + Frases.desgraca(_texto(desg.get("efeito")), nome, false, _arma_legivel(_texto(r.get("arma"))),
			desg.get("perdeQuarto") == true)
	return frase


## A linha que fica no registo da narração (o supRegistar do site: quem, contra quem, oportunidade, falha crítica).
static func linha_registo_falha(v: Dictionary, r: Dictionary, desg: Dictionary = {}) -> String:
	var critica := ""
	if r.get("critica") == true:
		var ef := _texto(desg.get("efeito"))
		critica = Textos.REGISTO_FALHA_CRITICA % (str(Textos.NOME_DESGRACA.get(ef, ef)) if ef != "" else Textos.REGISTO_FALHA_SEM_DESGRACA)
	return Textos.REGISTO_FALHA % [
		_nome_curto(v, _texto(r.get("atacanteId"))), _nome_curto(v, _texto(r.get("alvoId"))),
		Textos.REGISTO_CAIDA_OPORTUNIDADE if r.get("oportunidade") == true else "", critica,
	]


## A linha de abertura do cartão de desgraça de um MONSTRO (site: modo «monstro» do cartão): «Orc tentou desferir o
## machado a Ong e falhou.» ou, no golpe de oportunidade, «Orc tentou golpeá-la de oportunidade ao sair e falhou.».
## "" quando o cartão não é de desgraça ou a desgraça é da heroína (o site não enquadra esse).
static func frase_cartao_falha(cartao: Dictionary, vista: Dictionary) -> String:
	if _texto(cartao.get("tipo")) != "desgraca":
		return ""
	var atac := _texto(cartao.get("figuraId"))
	var f := figura(vista, atac)
	if f.is_empty() or _texto(f.get("lado")) == "jogadora":
		return ""
	var interno := cartao_interno(vista, _texto(cartao.get("cartaoId")))
	var nome := _nome_curto(vista, atac)
	if interno.get("ataqueDeOportunidade") == true:
		return Textos.CARTAO_FALHA_OPORTUNIDADE % nome
	var alvo := _texto(interno.get("alvoId"))
	if alvo == "":
		return ""
	return Textos.FALHA_MONSTRO % [nome, verbo_falha(vista, atac), _nome_curto(vista, alvo)]


## O nome legível da arma (o id da técnica, como na frase prevista do cartão).
static func _arma_legivel(id: String) -> String:
	return id.replace("-", " ").replace("_", " ").strip_edges()


## A linha que fica no registo da narração, com os contadores (como o supRegistar do site).
static func linha_registo_caida(v: Dictionary, r: Dictionary) -> String:
	return Textos.REGISTO_CAIDA % [
		_nome_curto(v, _texto(r.get("alvoId"))), _nome_curto(v, _texto(r.get("atacanteId"))),
		Textos.REGISTO_CAIDA_OPORTUNIDADE if r.get("oportunidade") == true else "",
		int(r.get("sucessos", 0)), int(r.get("falhas", 0)),
	]


## Nome dentro de uma frase: o verdadeiro (o Mestre vê-o), senão o público.
static func _nome_curto(v: Dictionary, id: String) -> String:
	var f := figura(v, id)
	var nome := _texto(f.get("nome"))
	if nome == "":
		nome = _texto(f.get("nomePublico"))
	return nome if nome != "" else Textos.ALGUEM


static func _inteiro(x) -> int:
	return int(x) if x is int or x is float else 0


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
