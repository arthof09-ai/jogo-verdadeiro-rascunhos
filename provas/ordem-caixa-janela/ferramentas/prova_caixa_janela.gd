extends SceneTree
## Prova da Ordem CAIXA-JANELA — o CLIENTE DA JOGADORA a sério (cenas/arena/arena.tscn com o HUD, pela Rede do jogo) contra
## o servidor de mesa de BANCADA, com 10 FIGURAS na batalha (as 2 heroínas e 8 criaturas de bancada).
## Base: provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd (os mesmos ajudantes; aquela fica intacta).
##
##   node provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs --porta=8793 --semente=7 --info=<f> --motor=<vlab>
##   godot --resolution 1280x720 --path rascunhos/cliente -s <esta ferramenta> -- --servidor=127.0.0.1:8793 --saida=<pasta>
##
## Passos:
##   0. o Mestre da bancada põe 8 criaturas e começa; a IA de bancada joga uma volta inteira (as 10 figuras entram na
##      ordem dinâmica do servidor); o lugar de bancada da Espadachim sai.
##   1. B1 — A JANELA: a Espadachim entra pela Rede a sério e recebe o snapshot, mas a ARENA AINDA NÃO ABRIU; nesse
##      intervalo a bancada joga mais vezes (os ROOM_EVENT chegam ao Estado dela sem HUD nenhum). Só então a arena abre:
##      a caixa tem de ser já a ordem do servidor (com os eventos da janela), sem esperar pelo snapshot seguinte.
##   2. B3 — ECRÃS BAIXOS: a janela passa a 1280×720 (referência), 844×390 e 780×360: a caixa com as 10 figuras cabe,
##      não tapa a ⚙/ficha/barra, e a faixa tem a largura da frase mais comprida, sem passar por baixo da caixa.
##      Uma captura em cada tamanho.
## Em todos: nada do Mestre chega ao aparelho dela; nenhum texto da caixa mostra nome verdadeiro, vida ou PA.
## CAIXA-JANELA-NOMES: o relato escreve só o nome PÚBLICO das figuras (ferramentas/nomes_relato.gd), e o canário varre
## também o relato — em cada passagem (1, 2) e no fim, o relato inteiro: um nome verdadeiro de bancada nele é FALHA.
## CAIXA-JANELA-NOMES-CORRECOES: os canários do relato vêm primeiro do ELENCO (as fichas de bancada, antes de haver
## batalha; B6), e a varredura final em _fim() é INCONDICIONAL (corre em todos os caminhos, também quando a prova pára
## no passo 0 ou 1, antes de qualquer passagem do canário; B3). Os diagnósticos dizem a contagem e as linhas, nunca os
## nomes achados (B4) — o diagnóstico vai para o relato, que é cometido.
## CAIXA-JANELA-COBERTURA (C1): o relato também é varrido por CHAVES proibidas de vida/PA/alma
## (`NomesRelato.CHAVES_PROIBIDAS`) — em cada passagem (1, 2) e no fim, incondicional como a dos nomes. Cobre a linha
## «bancada:», que escreve o passo inteiro: um valor de PA posto no passo é FALHA.
## CAIXA-JANELA-COBERTURA-CORRECOES (B1): as chaves são 12 (vida, PA — incluindo `paGasto` e `custoPA` —, alma, dano,
## estado de morte, arma caída/quebrada, corpo partido); os rótulos dizem «chaves privadas do Mestre».
## Deixa em <pasta>: 1-janela-1280x720.png, 2-baixo-844x390.png, 3-baixo-780x360.png e relato.txt. Código 0 se tudo passa.

const CENA := "res://cenas/arena/arena.tscn"
const IA := preload("res://autojogo/ia_bancada.gd")
const Lugar := preload("res://autojogo/lugar_bancada.gd")
## Mais criaturas de bancada (as fichas do cenário, repetidas em casas da floresta): 2 heroínas + 8 criaturas = 10 figuras.
const CASAS_EXTRA := [
	{"fichaId": "bruto-bancada", "casa": {"x": 5, "y": 15}}, {"fichaId": "lobo-bancada", "casa": {"x": 15, "y": 12}},
	{"fichaId": "bruto-bancada", "casa": {"x": 14, "y": 16}}, {"fichaId": "lobo-bancada", "casa": {"x": 7, "y": 17}},
	{"fichaId": "bruto-bancada", "casa": {"x": 3, "y": 12}}, {"fichaId": "lobo-bancada", "casa": {"x": 10, "y": 18}},
]
const MIN_FIGURAS := 8
const TAMANHOS := [
	[Vector2i(1280, 720), "1-janela-1280x720.png"],
	[Vector2i(844, 390), "2-baixo-844x390.png"],
	[Vector2i(780, 360), "3-baixo-780x360.png"],
]

var _args := {}
var _saida := ""
var _url := ""
var _pin := "20261116"
var _total := 0
var _falhas := 0
var _relato: PackedStringArray = []
var _rede: Node
var _estado: Node
var _arena = null
var _mestre_b  # Lugar do Mestre da bancada
var _herois := {}  # figuraId → Lugar
var _a_entrar = null
var _cenario: Dictionary = {}
var _jogadora: Dictionary = {}  # a heroína que entra pelo ecrã a sério (a 1.ª do cenário)
var _recebido: Array = []  # tudo o que chegou ao aparelho da jogadora (JSON)
## CAIXA-JANELA-NOMES: os nomes do relato e o canário do relato (ferramentas/nomes_relato.gd, partilhado com o teste).
var NomesRelato
## Os nomes verdadeiros (os que diferem do público): os do elenco no arranque (B6) e os de cada vista do Mestre que o
## canário vê, para a varredura final em _fim().
var _canarios_nomes: Array = []


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _linha(t: String) -> void:
	print(t)
	_relato.append(t)
	if _saida != "":
		var f := FileAccess.open(_saida.path_join("relato.txt"), FileAccess.WRITE)
		if f != null:
			f.store_string("\n".join(_relato) + "\n")
			f.close()


func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		_linha("  ok    " + nome)
	else:
		_falhas += 1
		_linha("  FALHA " + nome)
		printerr("  FALHA ", nome)


func _poll() -> void:
	if _mestre_b != null:
		_mestre_b.poll()
	for l in _herois.values():
		l.poll()
	if _a_entrar != null:
		_a_entrar.poll()


func _esperar(cond: Callable, segundos: float = 30.0) -> bool:
	var t := Time.get_ticks_msec()
	while not cond.call():
		if Time.get_ticks_msec() - t > int(segundos * 1000.0):
			return false
		await process_frame
		_poll()
	return true


func _quadros(n: int) -> void:
	for i in n:
		await process_frame
		_poll()


func _gravar(nome: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		_ok(false, nome + ": sem imagem (o render não correu)")
		return
	var erro := img.save_png(_saida.path_join(nome))
	_ok(erro == OK, "captura %s (%d×%d)" % [nome, img.get_width(), img.get_height()])


func _ler_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var i := a.find("=")
			if i < 0:
				_args[a.substr(2)] = true
			else:
				_args[a.substr(2, i - 2)] = a.substr(i + 1)


# ------------------------------------------------------------------ a bancada (Mestre e heroínas por lugares próprios)

func _vista_b() -> Dictionary:
	var alvo: int = _mestre_b.pedir_vista()
	if not await _esperar(func(): return _mestre_b.vistas_recebidas >= alvo, 10.0):
		return {}
	return _mestre_b.vista


func _comando_b(tipo: String, campos: Dictionary) -> bool:
	await _vista_b()
	var id: String = _mestre_b.comando(tipo, campos)
	if not await _esperar(func(): return _mestre_b.respostas.has(id), 10.0):
		return false
	return str(_mestre_b.respostas[id].get("estado", "")) == "APLICADA"


## CAIXA-JANELA-NOMES: o nome que vai para o RELATO é o `nomePublico` (o que a Party vê), nunca o nome verdadeiro da
## vista do Mestre — o relato é cometido e não pode trazer o valor-canário. Sem nome público: o id.
func _nome(v: Dictionary, id: String) -> String:
	return NomesRelato.nome(v, id)


## Joga UMA vez da figura que está na vez (a IA de bancada e encerrar). Devolve o id de quem jogou ("" = não deu).
func _jogar_vez() -> String:
	var v := await _vista_b()
	var mv: Dictionary = v.get("mestre", {})
	if mv.get("cartoes") is Array and not (mv["cartoes"] as Array).is_empty():
		return ""
	var vez_id := str(v.get("vezId", "")) if v.get("vezId") is String else ""
	if vez_id == "" or str(v.get("fase", "")) != "combate":
		return ""
	var figuras: Array = mv.get("figuras", [])
	var quem: Dictionary = {}
	for f in figuras:
		if str(f.get("id", "")) == vez_id:
			quem = f
	var lugar = _herois.get(vez_id, _mestre_b)
	var pronto := func(): return str(lugar.opcoes.get("vezId", "")) == vez_id and int(lugar.opcoes.get("revision", -1)) == lugar.revision
	await _esperar(pronto, 5.0)
	var d := IA.decidir(quem, figuras, lugar.opcoes, {"andou": false, "atacou": false, "accoes": 0})
	for passo in [d["acao"], {"tipo": "encerrar"}]:
		var id := ""
		if lugar.papel == "mestre":
			id = lugar.comando("MASTER_ACT", {"figuraId": vez_id, "acao": passo})
		else:
			id = lugar.intencao(passo)
		await _esperar(func(): return lugar.respostas.has(id), 10.0)
		_linha(NomesRelato.linha_bancada(quem, vez_id, passo, str(lugar.respostas.get(id, {}).get("estado", lugar.respostas.get(id, {}).get("motivo", "?")))))
		if passo.get("tipo") == "encerrar":
			break
		await _vista_b()
		await _esperar(func(): return int(lugar.opcoes.get("revision", -1)) == lugar.revision, 5.0)
	return vez_id


func _montar_batalha() -> bool:
	_mestre_b = Lugar.new("mestre-bancada", 7)
	_mestre_b.ligar(_url, {"v": 2, "type": "ROOM_JOIN", "papel": "mestre", "pin": _pin, "cliente": Lugar.VERSAO})
	if not await _esperar(func(): return _mestre_b.na_mesa and _mestre_b.vistas_recebidas > 0, 20.0):
		_ok(false, "o Mestre da bancada entrou")
		return false
	var fichas: Array = []
	for c in _cenario["criaturas"]:
		if not fichas.has(c["fichaId"]):
			fichas.append(c["fichaId"])
	if not await _comando_b("MASTER_LOBBY_SET", {"mapaId": str(_cenario.get("mapaId", "floresta")), "criaturasDisponiveis": fichas, "npcsDisponiveis": []}):
		_ok(false, "MASTER_LOBBY_SET aceite")
		return false
	for c in (_cenario["criaturas"] as Array) + CASAS_EXTRA:
		if not await _comando_b("MASTER_PLACE", {"fichaId": c["fichaId"], "casa": c["casa"]}):
			_ok(false, "MASTER_PLACE %s %s aceite" % [c["fichaId"], c["casa"]])
			return false
	var i := 0
	for h in _cenario["heroinas"]:
		i += 1
		var l = Lugar.new("heroina-%d" % i, 7)
		l.ligar(_url, {"v": 2, "type": "ROOM_JOIN", "papel": "jogadora", "nome": str(h["nome"]), "senha": str(h["senha"]), "cliente": Lugar.VERSAO})
		_a_entrar = l
		var entrou := await _esperar(func(): return l.na_mesa and l.figura_id != "", 20.0)
		_a_entrar = null
		if not entrou:
			_ok(false, "a heroína %d entrou" % i)
			return false
		_herois[l.figura_id] = l
		if i == 1:
			_jogadora = {"nome": str(h["nome"]), "senha": str(h["senha"]), "figuraId": l.figura_id}
	if not await _comando_b("MASTER_START", {}):
		_ok(false, "MASTER_START aceite")
		return false
	var n_figuras: int = ((await _vista_b()).get("mestre", {}).get("figuras", []) as Array).size()
	_ok(n_figuras >= MIN_FIGURAS + 2, "a batalha tem %d figuras (≥ %d)" % [n_figuras, MIN_FIGURAS + 2])
	var jogaram: Array = []
	while jogaram.size() < n_figuras:
		var quem := await _jogar_vez()
		if quem == "" or jogaram.has(quem):
			break
		jogaram.append(quem)
	var fim := await _vista_b()
	var od = fim.get("ordemDinamica", {})
	_linha("  a batalha a meio: fase %s, rodada %s, vez de %s, ordem dinâmica (Mestre) %s" % [fim.get("fase"), fim.get("rodada"),
		_nome(fim, str(fim.get("vezId"))), JSON.stringify((od.get("ordem", []) as Array).map(func(x): return _nome(fim, x)))])
	_ok(str(fim.get("fase", "")) == "combate" and (od.get("ordem", []) as Array).size() >= MIN_FIGURAS,
		"batalha de bancada a meio: em combate e com a ordem dinâmica do servidor com %d figuras (≥ %d)" % [(od.get("ordem", []) as Array).size(), MIN_FIGURAS])
	# O lugar de bancada da jogadora sai: quem entra a seguir é ela, pelo ecrã a sério.
	var l = _herois[_jogadora["figuraId"]]
	l.fechar()
	_herois.erase(_jogadora["figuraId"])
	await _quadros(20)
	return true


# ------------------------------------------------------------------ a jogadora a sério

func _registar(msg: Dictionary) -> void:
	_recebido.append(JSON.stringify(msg))


## Só a Rede: ela entra e recebe o snapshot, mas a arena (e o HUD) ainda não existe — a janela lobby→arena.
func _entrar_rede(rotulo: String) -> bool:
	_rede.entrar(_jogadora["nome"], _jogadora["senha"])
	var dentro := func(): return _rede.na_mesa() and _estado.tem_snapshot and _estado.minha_figura_id == _jogadora["figuraId"]
	if not await _esperar(dentro, 30.0):
		_ok(false, rotulo + ": a jogadora entrou e recebeu o snapshot")
		return false
	return true


func _abrir_arena(rotulo: String) -> bool:
	_arena = (load(CENA) as PackedScene).instantiate()
	root.add_child(_arena)
	await _quadros(60)  # a arena e os retratos (SubViewport) desenham-se
	_ok(_estado.fase == "combate", rotulo + ": a arena abriu a meio da batalha (fase %s, rodada %s)" % [_estado.fase, _estado.rodada])
	return true


func _caixa() -> Dictionary:
	return _arena.hud.caixa_mostrada()


func _nomes_ids(ids: Array) -> String:
	return JSON.stringify(ids.map(func(x): return _estado.nome_de(str(x))))


func _descrever(c: Dictionary) -> String:
	return "visível=%s modo=%s ordem=%s vez=%s" % [c["visivel"], c["modo"], _nomes_ids(c["ids"]), _estado.nome_de(c["vez"])]


## A ordem dinâmica do servidor (a do Mestre; a bancada só anda, ataca e encerra, por isso é a mesma que a da Party).
func _ordem_servidor() -> Dictionary:
	var v := await _vista_b()
	return v.get("ordemDinamica", {})


func _textos(no: Node, saida: Array) -> void:
	if no is Label or no is Button or no is RichTextLabel:
		saida.append(no.text)
	for f in no.get_children():
		_textos(f, saida)


## Nada do Mestre: nas mensagens que chegaram ao aparelho dela e nos textos da caixa.
func _privacidade(rotulo: String) -> void:
	var tudo := "\n".join(_recebido)
	_ok(not tudo.contains("caixaMestre") and not tudo.contains("\"mestre\"") and not tudo.contains("MASTER_VIEW"),
		rotulo + ": nenhuma mensagem do Mestre chegou ao aparelho dela (%d mensagens; sem caixaMestre, bloco mestre, MASTER_VIEW)" % _recebido.size())
	_ok(_estado.mestre.is_empty(), rotulo + ": o estado dela não guarda nada do Mestre")
	var c: Dictionary = _estado.caixa
	var chaves_ok: bool = c.is_empty() or (c.keys().size() == 3 and c.has("ligada") and c.has("ordemPor") and c.has("ordemDinamica"))
	_ok(chaves_ok, rotulo + ": a caixa que lhe chegou só tem ligada, ordemPor e ordemDinamica")
	var v := await _vista_b()
	var nomes: Array = NomesRelato.nomes_verdadeiros(v)
	var canarios: Array = nomes.duplicate()
	for f in v.get("mestre", {}).get("figuras", []):
		for k in ["vidaActual", "vidaTotal", "paTotal", "paLivre"]:
			if f.get(k) is float or f.get(k) is int:
				canarios.append(str(int(f[k])))
	var textos: Array = []
	_textos(_arena.hud.get_node("Raiz/Seguro/Camadas/CaixaOrdem"), textos)
	var achados: Array = []
	var em_textos: Array = []  # B4: o diagnóstico diz quantos achados e em que textos (índice), nunca o valor nem o texto
	for i in textos.size():
		# Os números de vida/PA não podem aparecer como palavra nos textos da caixa (nem um dígito: a caixa não tem números).
		for k in canarios:
			if str(textos[i]).contains(k):
				achados.append(i)
				if not em_textos.has(i):
					em_textos.append(i)
	_ok(achados.is_empty(), rotulo + ": nenhum dado do Mestre (nome verdadeiro, vida, PA) nos textos da caixa (%d achado(s), textos %s)" % [achados.size(), JSON.stringify(em_textos)])
	var com_digito: Array = []
	for i in textos.size():
		if RegEx.create_from_string("[0-9]").search(str(textos[i])) != null:
			com_digito.append(i)
	_ok(com_digito.is_empty(), rotulo + ": nenhum número nos textos da caixa (%d textos; com dígito: %s)" % [textos.size(), JSON.stringify(com_digito)])
	# CAIXA-JANELA-NOMES: o canário estende-se ao RELATO (o que fica cometido): nenhum nome verdadeiro em nenhuma linha
	# até aqui. Só os nomes — vida e PA são números pequenos que o relato tem por outras razões (coordenadas, seq,
	# medidas); esses ficam para a varredura dos textos da caixa, acima.
	for n in nomes:
		if not _canarios_nomes.has(n):
			_canarios_nomes.append(n)
	var no_relato: Array = NomesRelato.no_relato(_relato, nomes)
	_ok(not nomes.is_empty() and no_relato.is_empty(),
		rotulo + ": nenhum nome verdadeiro no relato (%d linhas; canários: %d nome(s) que diferem do público; %s)" % [_relato.size(), nomes.size(), NomesRelato.diagnostico(_relato, nomes)])
	# CAIXA-JANELA-COBERTURA (C1; B1 das CORRECOES: 12 chaves): e nenhuma chave privada do Mestre em nenhuma linha do
	# relato até aqui.
	_ok(NomesRelato.chaves_no_relato(_relato).is_empty(),
		rotulo + ": nenhuma chave privada do Mestre no relato (%d linhas; %d chaves proibidas; %s)" % [_relato.size(), NomesRelato.CHAVES_PROIBIDAS.size(), NomesRelato.diagnostico_chaves(_relato)])


func _correr() -> void:
	_ler_args()
	_saida = str(_args.get("saida", ""))
	var srv := str(_args.get("servidor", ""))
	if _saida == "" or srv.find(":") < 0:
		printerr("uso: -- --servidor=127.0.0.1:PORTA --saida=<pasta>")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_saida)
	_url = "ws://%s/ws" % srv
	_pin = str(_args.get("pin", _pin))
	NomesRelato = load(str(get_script().resource_path).get_base_dir().path_join("nomes_relato.gd"))
	if NomesRelato == null:
		printerr("não abriu provas/ordem-caixa-janela/ferramentas/nomes_relato.gd")
		quit(2)
		return
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	_rede.persistir = false
	_rede.definir_servidor(srv)
	_rede.snapshot_recebido.connect(_registar)
	_rede.evento_recebido.connect(_registar)
	_rede.opcoes_recebidas.connect(_registar)
	_rede.mestre_recebido.connect(_registar)
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	_cenario = JSON.parse_string(FileAccess.get_file_as_string(raiz.path_join("servidor/autojogo/cenario-bancada.json")))
	# B6: os canários do relato a partir do elenco (as fichas de bancada), antes de qualquer linha do relato.
	var elenco = JSON.parse_string(FileAccess.get_file_as_string(raiz.path_join("servidor/autojogo/fichas-bancada.json")))
	_canarios_nomes = NomesRelato.nomes_verdadeiros(NomesRelato.vista_do_elenco(elenco))
	_linha("== Ordem CAIXA-JANELA — a janela lobby→arena e a caixa com 10 figuras em ecrãs baixos (cliente a sério) ==")
	_linha("servidor %s · render %s · Godot %s" % [_url, RenderingServer.get_video_adapter_name(), str(Engine.get_version_info().get("string", "?"))])

	_linha("== 0. batalha de bancada com 10 figuras (IA de bancada, lugares próprios) ==")
	if not await _montar_batalha():
		_fim()
		return

	_linha("== 1. B1 — a janela: o snapshot chega, a batalha anda, e SÓ DEPOIS a arena (e o HUD) abre ==")
	if not await _entrar_rede("1"):
		_fim()
		return
	var seq_snapshot: int = _estado.ultimo_seq
	_ok(_estado.eventos_desde_snapshot.is_empty(), "1: snapshot recebido (seq %d), ainda sem HUD e sem eventos depois dele" % seq_snapshot)
	var na_janela: Array = []
	for k in 3:
		var v := await _vista_b()
		if str(v.get("vezId", "")) == _jogadora["figuraId"]:
			break  # a vez é dela: quem joga é ela, não a bancada
		var quem := await _jogar_vez()
		if quem == "":
			break
		na_janela.append(_estado.nome_de(quem))
	await _quadros(30)
	var od := await _ordem_servidor()
	var n_janela: int = _estado.eventos_desde_snapshot.size()
	_linha("  na janela (sem HUD) a bancada jogou %s: %d eventos chegaram ao Estado dela (seq %d → %d)" % [JSON.stringify(na_janela), n_janela, seq_snapshot, _estado.ultimo_seq])
	_ok(not na_janela.is_empty() and n_janela > 0, "1: a batalha andou entre o snapshot e o HUD (%d vezes, %d eventos)" % [na_janela.size(), n_janela])
	if not await _abrir_arena("1"):
		_fim()
		return
	var c := _caixa()
	_linha("  caixa da jogadora ao abrir: " + _descrever(c))
	_linha("  ordem do servidor:          %s, vez %s" % [_nomes_ids(od.get("ordem", [])), _estado.nome_de(str(od.get("ultimo", "")))])
	_ok(c["visivel"] and c["ids"] == od.get("ordem", []) and c["vez"] == str(od.get("ultimo", "")),
		"1: ao abrir, a caixa já é a ordem do servidor com os eventos da janela (%d figuras, vez %s), sem esperar pelo snapshot seguinte" % [(c["ids"] as Array).size(), _estado.nome_de(c["vez"])])
	_ok(_estado.ultimo_seq > seq_snapshot and not _estado.eventos_desde_snapshot.is_empty(),
		"1: nenhum snapshot novo chegou entretanto (os %d eventos de depois do de seq %d continuam por cima dele)" % [_estado.eventos_desde_snapshot.size(), seq_snapshot])
	await _privacidade("1")

	_linha("== 2. B3 — a caixa com %d figuras em ecrãs baixos ==" % (c["ids"] as Array).size())
	for t in TAMANHOS:
		await _medir_vivo(t[0], t[1])
	await _privacidade("2")
	_fim()


func _medir_vivo(tam: Vector2i, nome: String) -> void:
	var w := root as Window
	w.size = tam
	await _quadros(30)
	if w.size != tam:
		_ok(false, "%s pedida, mas a janela ficou %s: sem medida" % [tam, w.size])
		return
	var hud = _arena.hud
	var c := _caixa()
	var r: Rect2 = c["rect"]
	var tela := root.get_visible_rect()
	var escala: float = hud._escala
	var tapa: Array = []
	for p in ["Raiz/Seguro/Camadas/ColunaEsquerda", "Raiz/Seguro/Camadas/Barra"]:
		var no := hud.get_node(p) as Control
		if no.visible and no.get_global_rect().intersects(r):
			tapa.append(p.get_file())
	var faixa := hud.get_node("Raiz/Seguro/Camadas/Faixa") as Label
	var pai := faixa.get_parent() as Control
	var livre: float = pai.size.x - faixa.offset_left + faixa.offset_right
	var precisa: float = hud.largura_faixa_precisa()
	var rf := faixa.get_global_rect()
	var px_letra: float = float(faixa.get_theme_font_size("font_size")) * escala
	var slot0: Node = hud._caixa.find_child("Fila", true, false).get_child(0)
	var lado_retrato: float = (slot0.get_node("Moldura") as Control).size.y
	var letra_nome: int = (slot0.get_node("Nome") as Label).get_theme_font_size("font_size")
	_linha("  MEDIDA viva %d figuras · janela %dx%d (unidades %dx%d, escala %.3f): caixa %dx%d u = %dx%d px reais (%.0f%% x %.0f%% do ecrã), %d por linha, retrato %d u = %.0f px, nome %d u = %.1f px · faixa «%s» livre %d u (precisa %d u) = %d px reais, letra %.1f px" % [
		(c["ids"] as Array).size(), tam.x, tam.y, int(tela.size.x), int(tela.size.y), escala, int(r.size.x), int(r.size.y),
		int(r.size.x * escala), int(r.size.y * escala), 100.0 * r.size.x / tela.size.x, 100.0 * r.size.y / tela.size.y,
		hud._caixa.colunas_fila(), int(lado_retrato), lado_retrato * escala, letra_nome, float(letra_nome) * escala, faixa.text, int(livre), int(precisa), int(livre * escala), px_letra])
	_ok(c["visivel"] and (c["ids"] as Array).size() >= MIN_FIGURAS and tela.encloses(r), "%dx%d: a caixa com as %d figuras cabe no ecrã" % [tam.x, tam.y, (c["ids"] as Array).size()])
	_ok(tapa.is_empty(), "%dx%d: a caixa não tapa a ⚙/ficha nem a barra %s" % [tam.x, tam.y, tapa])
	_ok(livre >= precisa and not rf.intersects(r), "%dx%d: a faixa tem %d u para a frase mais comprida (%d u), numa linha, fora da caixa" % [tam.x, tam.y, int(livre), int(precisa)])
	_ok(absf(lado_retrato - float(hud._fonte) * 2.8) <= 1.0, "%dx%d: a fila segue a letra de agora (retrato %d u = 2,8 × %d)" % [tam.x, tam.y, int(lado_retrato), hud._fonte])
	_ok(px_letra >= 12.99, "%dx%d: a letra da faixa tem %.1f px reais (≥ 13)" % [tam.x, tam.y, px_letra])
	await _gravar(nome)


func _fim() -> void:
	# CAIXA-JANELA-NOMES: a varredura final do relato INTEIRO (incluindo o que se escreveu depois do último canário).
	# B3: INCONDICIONAL — corre em todos os caminhos que chegam aqui (também quando a prova pára no passo 0 ou 1, antes
	# de qualquer passagem do canário); sem canários (elenco ilegível e nenhuma vista) é FALHA, nunca um salto calado.
	var no_relato: Array = NomesRelato.no_relato(_relato, _canarios_nomes)
	_ok(not _canarios_nomes.is_empty() and no_relato.is_empty(), "fim: o relato inteiro (%d linhas) não traz nenhum dos %d nome(s) verdadeiro(s) (%s)" % [
		_relato.size(), _canarios_nomes.size(), NomesRelato.diagnostico(_relato, _canarios_nomes)])
	# CAIXA-JANELA-COBERTURA (C1; B1 das CORRECOES: 12 chaves): a varredura final das chaves privadas, também incondicional (não precisa de
	# canários: as chaves são fixas). Corre antes da linha de baixo, sobre o relato inteiro.
	_ok(NomesRelato.chaves_no_relato(_relato).is_empty(), "fim: o relato inteiro (%d linhas) não traz nenhuma das %d chaves privadas do Mestre (%s)" % [
		_relato.size(), NomesRelato.CHAVES_PROIBIDAS.size(), NomesRelato.diagnostico_chaves(_relato)])
	_linha("")
	_linha("prova da janela e da caixa com 10 figuras: %d de %d verificações passaram." % [_total - _falhas, _total])
	for l in _herois.values():
		l.fechar()
	if _mestre_b != null:
		_mestre_b.fechar()
	await _quadros(5)
	quit(1 if _falhas > 0 or _total == 0 else 0)
