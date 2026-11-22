extends SceneTree
## Prova da Ordem CAIXA-MANEQUIM (21/11/2026) — os MESMOS 5 momentos da prova viva da CAIXA-HUD-JOGADORA
## (provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd, de que esta é cópia), com UMA mudança: as
## figuras em cena — e por isso os retratos da caixa, que são cópias delas (hud/retratos.gd) — são o MANEQUIM DE
## REFERÊNCIA DA CASA (Mannequin_F do UAL2 com o ANDAR v3, testes/manequim/andar-v3.glb, SHA-256 conferido; o mesmo
## das capturas do LAGO-MAIOR), nunca as cápsulas de bancada. Não é código do jogo: o jogo continua a pôr a cápsula;
## esta ferramenta esconde-a (o nó «Corpo» fica no sítio, invisível — a arena continua a pintá-lo e a assentá-lo) e
## põe o manequim no pé da figura, virado como ela. Os retratos já desenhados são esquecidos e refeitos do manequim.
## Nenhuma cor nova: o manequim traz os seus materiais; a caixa e o fundo dos retratos são os da tabela (paleta C).
##
##   node provas/ordem-caixa-hud-jogadora/ferramentas/servidor-bancada-prova.mjs --porta=8794 --semente=7 --info=<f> --motor=<vlab>
##   godot --resolution 1280x720 --path rascunhos/cliente -s <esta ferramenta> -- --servidor=127.0.0.1:8794 --saida=<pasta>
##
## Passos (iguais aos da CAIXA-HUD-JOGADORA):
##   0. a batalha de bancada a meio (Arqueira, Lobo, Espadachim jogam pela IA de bancada).
##   1. dinâmica: a Espadachim entra pelo ecrã a sério; a caixa dinâmica, ela na vez.
##   2. iniciativa: o Mestre escolhe «Modo iniciativa»; outra figura na vez (Bruto).
##   3. desligada: o Mestre desliga a caixa; sai do HUD dela.
##   4. religada e avançada: volta a ligar no dinâmico; a bancada joga Bruto e Arqueira; a caixa adianta-se.
##   5. reentrada: ela sai e volta a entrar; a caixa reconstrói-se do snapshot.
## Em cada captura confere-se ainda: todas as figuras em cena vestem o manequim, nenhuma cápsula se vê, e cada
## retrato da caixa foi desenhado de uma cópia com o manequim (e sem a cápsula).
## Deixa em <pasta>: 1-entrou-dinamica.png, 2-iniciativa.png, 3-desligada.png, 4-religada-avancou.png,
## 5-reentrou.png e relato.txt. Código de saída 0 se todas as verificações passam.

const CENA := "res://cenas/arena/arena.tscn"
const IA := preload("res://autojogo/ia_bancada.gd")
const Lugar := preload("res://autojogo/lugar_bancada.gd")
const VEZES_A_JOGAR := 3
const GLB := "res://testes/manequim/andar-v3.glb"
const GLB_SHA256 := "8413b0395d6b9f161aefe05004999ee5f605d4eb68e81a4767a81f9b56ea3491"
const ANIM := "andar_v3"
const NOME_MANEQUIM := "ManequimDeReferencia"

var _args := {}
var _saida := ""
var _url := ""
var _pin := "81052918516180889851"
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
## Ordem CAIXA-RELATO (B7b): de que snapshot é a caixa que o relato imprime — {seq, revisao, hora, eventos depois}.
var _snap := {}
var RelatoCaixa  # provas/ordem-caixa-relato/ferramentas/relato_caixa.gd
var _caixa_relatada := {}  # a última linha da caixa: {desactualizado, snapshot, actual}
## CAIXA-RELATO-CORRECOES-2 (B1): os nomes verdadeiros (os que diferem do nome público) que o canário procura também
## no RELATO — juntados a cada passagem do canário, para a varredura final do relato inteiro em _fim().
var _canarios_nomes: Array = []
var _gltf_doc: GLTFDocument
var _gltf_estado: GLTFState


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _linha(t: String) -> void:
	print(t)
	_relato.append(t)
	_gravar_relato()


## CAIXA-RELATO-CORRECOES-4 (B1): troca a linha `i` (a partir de 0) do relato e regrava o ficheiro — o número de linhas
## não muda. Na consola sai a linha nova, marcada como reescrita.
func _reescrever(i: int, t: String) -> void:
	print("  (reescrita da linha %d do relato) " % (i + 1) + t)
	_relato[i] = t
	_gravar_relato()


func _gravar_relato() -> void:
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


func _caixa_b(ligada: bool, modo: String) -> bool:
	return await _comando_b("MASTER_SUPERVISOR", {"op": "caixa", "caixa": {"ligada": ligada, "modo": modo}})


## CAIXA-RELATO-CORRECOES-2 (B1): o nome que vai para o RELATO é o `nomePublico` (o que a Party vê), nunca o `nome`
## verdadeiro da vista do Mestre — o relato é cometido e não pode trazer o valor-canário. Sem nome público: o id.
func _nome(v: Dictionary, id: String) -> String:
	for f in v.get("mestre", {}).get("figuras", []):
		if str(f.get("id", "")) == id:
			return _nome_publico(f, id)
	return id


func _nome_publico(f: Dictionary, id: String) -> String:
	var np = f.get("nomePublico")
	return str(np) if np is String and np != "" else id


## Joga UMA vez da figura que está na vez (mover pela IA de bancada e encerrar). Devolve o id de quem jogou ("" = não deu).
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
		_linha("  bancada: %s → %s (%s)" % [_nome_publico(quem, vez_id), JSON.stringify(passo), str(lugar.respostas.get(id, {}).get("estado", lugar.respostas.get(id, {}).get("motivo", "?")))])
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
	for c in _cenario["criaturas"]:
		if not await _comando_b("MASTER_PLACE", {"fichaId": c["fichaId"], "casa": c["casa"]}):
			_ok(false, "MASTER_PLACE %s aceite" % c["fichaId"])
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
	var jogaram: Array = []
	while jogaram.size() < VEZES_A_JOGAR:
		var quem := await _jogar_vez()
		if quem == "" or jogaram.has(quem):
			break
		jogaram.append(quem)
	var fim := await _vista_b()
	# CAIXA-RELATO-CORRECOES-3 (B3): o nome que o relato dá à jogadora é o PÚBLICO (`_nome` → `_nome_publico`), não o
	# `nome` do cenário — que é o do lugar (o login) e pode diferir do `nomePublico` da ficha.
	_jogadora["nomePublico"] = _nome(fim, str(_jogadora["figuraId"]))
	var od = fim.get("ordemDinamica", {})
	_linha("  a batalha a meio: fase %s, rodada %s, vez de %s, ordem dinâmica (Mestre) %s" % [fim.get("fase"), fim.get("rodada"),
		_nome(fim, str(fim.get("vezId"))), JSON.stringify((od.get("ordem", []) as Array).map(func(x): return _nome(fim, x)))])
	_ok(str(fim.get("fase", "")) == "combate" and (od.get("ordem", []) as Array).size() >= 2,
		"batalha de bancada a meio: em combate e com a ordem dinâmica formada no servidor (≥ 2 figuras)")
	# O lugar de bancada da jogadora sai: quem entra a seguir é ela, pelo ecrã a sério.
	var l = _herois[_jogadora["figuraId"]]
	l.fechar()
	_herois.erase(_jogadora["figuraId"])
	await _quadros(20)
	return true


# ------------------------------------------------------------------ o manequim de referência

func _abrir_manequim() -> bool:
	if FileAccess.get_sha256(GLB) != GLB_SHA256:
		_ok(false, "o manequim é o ANDAR v3 aprovado (SHA-256 %s)" % GLB_SHA256)
		return false
	_gltf_doc = GLTFDocument.new()
	_gltf_estado = GLTFState.new()
	var erro := _gltf_doc.append_from_file(GLB, _gltf_estado)
	_ok(erro == OK, "o manequim de referência abriu (Mannequin_F · UAL2 · ANDAR v3 · sha256 %s…)" % GLB_SHA256.substr(0, 16))
	return erro == OK


## Um manequim novo, parado no quadro 0 do ANDAR v3 (a pose das capturas do LAGO-MAIOR).
func _novo_manequim() -> Node3D:
	var m := _gltf_doc.generate_scene(_gltf_estado) as Node3D
	m.name = NOME_MANEQUIM
	var anim: AnimationPlayer = m.find_child("AnimationPlayer", true, false)
	if anim != null and anim.has_animation(ANIM):
		anim.play(ANIM)
		anim.seek(0.0, true)
		anim.speed_scale = 0.0
	return m


## Veste o manequim em todas as figuras em cena que ainda não o têm (a cápsula «Corpo» fica escondida). Se vestiu
## alguma, os retratos da caixa esquecem as chaves e redesenham-se das cópias novas. Devolve quantas vestiu.
func _vestir_manequins() -> int:
	var vestidas := 0
	for id in _arena._nos:
		var no: Node3D = _arena._nos[id]
		if no == null or not is_instance_valid(no):
			continue
		(no.get_node("Corpo") as Node3D).visible = false
		if no.get_node_or_null(NOME_MANEQUIM) == null:
			no.add_child(_novo_manequim())
			vestidas += 1
	if vestidas > 0:
		await _quadros(2)  # o esqueleto do manequim assenta na pose antes de o retrato o copiar
		var r = _arena.hud._retratos
		r._chaves.clear()
		_arena.hud._pedir_desenho_caixa()
		await _quadros(6)
	return vestidas


## Confere a cena e os retratos antes de cada captura: só manequins à vista, nenhuma cápsula.
func _conferir_manequins(rotulo: String) -> void:
	await _vestir_manequins()
	var total := 0
	var com := 0
	var capsulas := 0
	for id in _arena._nos:
		var no: Node3D = _arena._nos[id]
		total += 1
		var m := no.get_node_or_null(NOME_MANEQUIM) as Node3D
		if m != null and m.visible:
			com += 1
		if (no.get_node("Corpo") as Node3D).visible:
			capsulas += 1
	_ok(total > 0 and com == total and capsulas == 0,
		rotulo + ": as %d figuras em cena vestem o manequim de referência, nenhuma cápsula à vista (%d com manequim, %d cápsulas)" % [total, com, capsulas])
	var c := _caixa()
	if not c["visivel"]:
		return
	var r = _arena.hud._retratos
	var maus: Array = []
	for id in c["ids"]:
		var sv: SubViewport = r._palcos.get(id)
		if sv == null:
			maus.append(_estado.nome_de(str(id)) + " sem retrato")
			continue
		var palco := sv.get_node("Palco")
		var copia: Node = palco.get_child(0) if palco.get_child_count() > 0 else null
		var tem_m := copia != null and copia.get_node_or_null(NOME_MANEQUIM) != null and (copia.get_node(NOME_MANEQUIM) as Node3D).visible
		var tem_cap := copia != null and (copia.get_node("Corpo") as Node3D).visible
		if not tem_m or tem_cap:
			maus.append(_estado.nome_de(str(id)))
	_ok(maus.is_empty(), rotulo + ": os %d retratos da caixa são do manequim, nenhum da cápsula %s" % [(c["ids"] as Array).size(), maus])


# ------------------------------------------------------------------ a jogadora a sério

func _registar(msg: Dictionary) -> void:
	_recebido.append(JSON.stringify(msg))


## Ordem CAIXA-RELATO (B7b): a origem da caixa do Estado (o último ROOM_SNAPSHOT) e os eventos depois dele.
## Ordem CAIXA-RELATO-CORRECOES (B1/B3): ouve a APLICAÇÃO no Estado (snapshot_aplicado / evento_aplicado), não a
## recepção na Rede; a hora leva milissegundos; cada evento guarda o tipo e conta à parte se tiver actor.
func _registar_snapshot() -> void:
	_snap = RelatoCaixa.novo_snap(_estado.ultimo_seq, _estado.revisao)


func _registar_evento(msg: Dictionary) -> void:
	RelatoCaixa.anotar_evento(_snap, msg)


func _entrar_jogadora(rotulo: String) -> bool:
	_rede.entrar(_jogadora["nome"], _jogadora["senha"])
	var dentro := func(): return _rede.na_mesa() and _estado.tem_snapshot and _estado.minha_figura_id == _jogadora["figuraId"]
	if not await _esperar(dentro, 30.0):
		_ok(false, rotulo + ": a jogadora entrou e recebeu o snapshot")
		return false
	_arena = (load(CENA) as PackedScene).instantiate()
	root.add_child(_arena)
	await _quadros(60)  # a arena e os retratos (SubViewport) desenham-se
	_ok(_estado.fase == "combate", rotulo + ": a jogadora entrou a meio da batalha (fase %s, rodada %s)" % [_estado.fase, _estado.rodada])
	return true


func _sair_jogadora(rotulo: String) -> void:
	_arena.queue_free()
	_arena = null
	await _quadros(2)
	_rede.sair()
	await _quadros(20)
	_ok(not _rede.na_mesa(), rotulo + ": a jogadora saiu")


func _caixa() -> Dictionary:
	return _arena.hud.caixa_mostrada()


func _nomes_ids(ids: Array) -> String:
	return JSON.stringify(ids.map(func(x): return _estado.nome_de(str(x))))


func _descrever(c: Dictionary) -> String:
	return "visível=%s modo=%s ordem=%s vez=%s" % [c["visivel"], c["modo"], _nomes_ids(c["ids"]), _estado.nome_de(c["vez"])]


## A ordem dinâmica do servidor PARA A PARTY: a do Mestre, menos quem só entrou por um `acao` (aqui a bancada só anda
## e encerra, por isso é a mesma — e confere-se as duas coisas).
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
	# Ordem CAIXA-RELATO (B7b): o JSON é o do último snapshot; a linha diz de qual e, se os eventos o adiantaram,
	# marca-o DESACTUALIZADO e imprime a caixa actual dela (o modelo do HUD).
	var snap := _snap.duplicate(true)  # fundo: os `tipos` continuam a crescer depois desta linha
	snap["revisao_actual"] = _estado.revisao
	# CAIXA-RELATO-CORRECOES (B2): o Estado guarda, à parte, os eventos aplicados desde o snapshot — a contagem e os
	# tipos do relato têm de bater com eles exactamente (a verificação do §4 confere).
	snap["tipos_estado"] = _estado.eventos_desde_snapshot.map(func(e): return str(e.get("tipo", "?")))
	var actual: Dictionary = RelatoCaixa.caixa_actual(c, _arena.hud.ordem_turnos)
	_caixa_relatada = {"desactualizado": RelatoCaixa.desactualizado(c, actual), "snapshot": c, "actual": actual, "snap": snap}
	_ok(chaves_ok, RelatoCaixa.linha(rotulo, c, snap, actual))
	var v := await _vista_b()
	var canarios: Array = []
	for f in v.get("mestre", {}).get("figuras", []):
		if str(f.get("nome", "")) != str(f.get("nomePublico", "")):
			canarios.append(str(f.get("nome")))
		for k in ["vidaActual", "vidaTotal", "paTotal"]:
			if f.get(k) is float or f.get(k) is int:
				if int(f[k]) >= 10:
					canarios.append(str(int(f[k])))
	var textos: Array = []
	_textos(_arena.hud.get_node("Raiz/Seguro/Camadas/CaixaOrdem"), textos)
	var achados: Array = []
	for j in textos.size():
		for i in canarios.size():
			var k = canarios[i]
			# CAIXA-RELATO-CORRECOES-3 (B2): sem distinguir maiúsculas («bruto de bancada» também é o canário).
			# CAIXA-RELATO-CORRECOES-4 (B2): o achado diz qual canário (n.º e espécie) e em que texto — nunca o valor nem
			# o texto, que o trazem: a linha FALHA vai para o relato e para a consola, e os dois ficam cometidos.
			if str(textos[j]).to_lower().contains(str(k).to_lower()):
				achados.append("canário n.º %d (%s) no texto n.º %d da caixa" % [i + 1, "número" if str(k).is_valid_int() else "nome", j + 1])
	_ok(achados.is_empty(), rotulo + ": nenhum dado do Mestre (nome verdadeiro, vida, PA) nos textos da caixa %s" % [achados])
	# CAIXA-RELATO-CORRECOES-2 (B1): o canário estende-se ao RELATO (o que fica cometido): nenhum nome verdadeiro em
	# nenhuma linha até aqui. Só os nomes — vida e PA são números pequenos que o relato tem por outras razões
	# (coordenadas, seq, revisões); esses ficam para a varredura dos textos da caixa, acima.
	var nomes: Array = []
	for f in v.get("mestre", {}).get("figuras", []):
		if str(f.get("nome", "")) != str(f.get("nomePublico", "")) and str(f.get("nome", "")) != "":
			nomes.append(str(f.get("nome")))
			if not _canarios_nomes.has(str(f.get("nome"))):
				_canarios_nomes.append(str(f.get("nome")))
	var no_relato := _nomes_no_relato(nomes)
	_ok(not nomes.is_empty() and no_relato.is_empty(),
		rotulo + ": nenhum nome verdadeiro no relato (%d linhas; canários: %d nome(s) que diferem do público) %s" % [_relato.size(), nomes.size(), no_relato])


## As linhas do relato que trazem algum dos nomes dados (o texto da própria verificação ainda não está lá).
func _nomes_no_relato(nomes: Array) -> Array:
	return _nomes_em(_relato, nomes)


## CAIXA-RELATO-CORRECOES-3 (B1/B2): as linhas de `linhas` que trazem algum dos nomes — sem distinguir maiúsculas dos
## dois lados (um canário escrito «lobo de bancada» é o mesmo nome verdadeiro). Linhas numeradas a partir de 1.
func _nomes_em(linhas: PackedStringArray, nomes: Array) -> Array:
	var achados: Array = []
	for i in linhas.size():
		var l := linhas[i].to_lower()
		for k in nomes:
			if l.contains(str(k).to_lower()):
				# CAIXA-RELATO-CORRECOES-4 (B2): o n.º do nome em _canarios_nomes (ou, se lá não estiver, em `nomes`), nunca
				# o nome (ver acima).
				var num := _canarios_nomes.find(str(k)) + 1
				achados.append("nome verdadeiro n.º %d na linha %d" % [num if num > 0 else nomes.find(k) + 1, i + 1])
	return achados


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
	_rede = root.get_node("Rede")
	_estado = root.get_node("Estado")
	_rede.persistir = false
	_rede.definir_servidor(srv)
	_rede.snapshot_recebido.connect(_registar)
	_rede.evento_recebido.connect(_registar)
	RelatoCaixa = load(str(get_script().resource_path).get_base_dir().path_join("../../ordem-caixa-relato/ferramentas/relato_caixa.gd").simplify_path())
	if RelatoCaixa == null:
		printerr("não abriu provas/ordem-caixa-relato/ferramentas/relato_caixa.gd")
		quit(2)
		return
	_estado.snapshot_aplicado.connect(_registar_snapshot)  # CAIXA-RELATO-CORRECOES (B1): a aplicação, não a recepção
	_estado.evento_aplicado.connect(_registar_evento)
	_rede.opcoes_recebidas.connect(_registar)
	_rede.mestre_recebido.connect(_registar)
	var raiz := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	_cenario = JSON.parse_string(FileAccess.get_file_as_string(raiz.path_join("servidor/autojogo/cenario-bancada.json")))
	_linha("== Ordem CAIXA-MANEQUIM — os 5 momentos da caixa no HUD da jogadora, com o manequim de referência no lugar das cápsulas ==")
	_linha("servidor %s · render %s" % [_url, RenderingServer.get_video_adapter_name()])

	if not _abrir_manequim():
		_fim()
		return
	_linha("== 0. batalha de bancada (IA de bancada, lugares próprios) ==")
	if not await _montar_batalha():
		_fim()
		return

	_linha("== 1. a jogadora (%s) entra pelo ecrã a sério ==" % _jogadora.get("nomePublico", _jogadora["figuraId"]))
	if not await _entrar_jogadora("1"):
		_fim()
		return
	var c := _caixa()
	var od := await _ordem_servidor()
	_linha("  caixa da jogadora: " + _descrever(c))
	_ok(c["visivel"] and c["modo"] == "dinamico", "1: a caixa aparece no HUD dela como o Mestre a tem (ligada, dinâmico)")
	_ok(c["ids"] == od.get("ordem", []) and not (c["ids"] as Array).is_empty(), "1: a ordem é a do servidor %s" % _nomes_ids(od.get("ordem", [])))
	_ok(c["vez"] == str(od.get("ultimo", "")), "1: a figura na vez (dinâmico: quem agiu por último) é a do servidor (%s)" % _estado.nome_de(str(od.get("ultimo", ""))))
	_ok(c["ids"].has(_jogadora["figuraId"]), "1: a própria jogadora está na ordem (agiu antes de entrar, pelo lugar de bancada)")
	await _privacidade("1")
	await _conferir_manequins("1")
	await _gravar("1-entrou-dinamica.png")

	_linha("== 2. o Mestre carrega em «Modo iniciativa» ==")
	_ok(await _caixa_b(true, "iniciativa"), "2: o servidor aceitou a escolha do Mestre (ligada, iniciativa)")
	_ok(await _esperar(func(): return _caixa()["modo"] == "iniciativa", 10.0), "2: a caixa da jogadora passou ao modo iniciativa")
	await _quadros(10)
	c = _caixa()
	_linha("  caixa da jogadora: " + _descrever(c))
	_ok(c["visivel"] and c["ids"] == _estado.iniciativa and c["vez"] == _estado.vez_id,
		"2: a ordem é a de iniciativa do servidor %s e a vez é a do servidor (%s)" % [_nomes_ids(_estado.iniciativa), _estado.nome_de(_estado.vez_id)])
	await _conferir_manequins("2")
	await _gravar("2-iniciativa.png")

	_linha("== 3. o Mestre desliga a caixa ==")
	_ok(await _caixa_b(false, "iniciativa"), "3: o servidor aceitou (desligada)")
	_ok(await _esperar(func(): return not _caixa()["visivel"], 10.0), "3: a caixa desapareceu do HUD da jogadora")
	await _quadros(10)
	await _conferir_manequins("3")
	await _gravar("3-desligada.png")

	_linha("== 4. o Mestre volta a ligar no modo dinâmico; a bancada joga mais duas vezes ==")
	_ok(await _caixa_b(true, "dinamico"), "4: o servidor aceitou (ligada, dinâmico)")
	_ok(await _esperar(func(): return _caixa()["visivel"] and _caixa()["modo"] == "dinamico", 10.0), "4: a caixa voltou ao HUD dela no modo dinâmico")
	for k in 2:
		var quem := await _jogar_vez()
		_ok(quem != "", "4: a bancada jogou a vez de %s" % _estado.nome_de(quem))
	await _quadros(20)
	c = _caixa()
	od = await _ordem_servidor()
	_linha("  caixa da jogadora: " + _descrever(c))
	_ok(c["ids"] == od.get("ordem", []) and c["vez"] == str(od.get("ultimo", "")),
		"4: pelos eventos que recebeu, a caixa dela adiantou-se e é igual à ordem do servidor %s (vez: %s, fechada: %s)" % [_nomes_ids(od.get("ordem", [])), _estado.nome_de(str(od.get("ultimo", ""))), od.get("fechada")])
	await _privacidade("4")
	# Ordem CAIXA-RELATO (B7b): aqui o JSON do snapshot (o da religação) é velho — a volta fechou pelos eventos. O
	# relato tem de o dizer na linha e imprimir a caixa actual dela, que é a do servidor (fechada: true).
	var cr := _caixa_relatada
	var od_snap: Dictionary = cr.get("snapshot", {}).get("ordemDinamica", {})
	var od_act: Dictionary = cr.get("actual", {}).get("ordemDinamica", {})
	_ok(cr.get("desactualizado") == true and int(cr.get("snap", {}).get("eventos", 0)) > 0 and od_snap.get("fechada") != od_act.get("fechada")
		and od_act.get("ordem", []) == od.get("ordem", []) and od_act.get("fechada") == od.get("fechada") and od_act.get("ultimo", "") == str(od.get("ultimo", "")),
		"4: o relato marca o JSON do snapshot como DESACTUALIZADO (%d eventos depois dele; fechada %s → %s) e a caixa actual que imprime é a do servidor" % [
			int(cr.get("snap", {}).get("eventos", 0)), od_snap.get("fechada"), od_act.get("fechada")])
	# CAIXA-RELATO-CORRECOES (B2): a contagem do relato é EXACTA — o mesmo número e os mesmos tipos, pela mesma ordem,
	# que o Estado aplicou desde o snapshot; as duas vezes jogadas dão 2 eventos de actor (a acção de cada uma) e 2
	# `turno` (o `encerrar` de cada uma, que não adianta a caixa).
	var sn: Dictionary = cr.get("snap", {})
	var tipos_rel: Array = sn.get("tipos", [])
	var tipos_est: Array = sn.get("tipos_estado", [])
	_ok(int(sn.get("eventos", -1)) == tipos_est.size() and tipos_rel == tipos_est and int(sn.get("de_actor", -1)) == 2
		and tipos_rel.count("turno") == 2,
		"4: a contagem do relato é exacta: %d evento(s) %s = os %d que o Estado aplicou desde o snapshot %s; %d de actor (esperados 2), %d turno (esperados 2)" % [
			int(sn.get("eventos", -1)), JSON.stringify(tipos_rel), tipos_est.size(), JSON.stringify(tipos_est), int(sn.get("de_actor", -1)), tipos_rel.count("turno")])
	await _conferir_manequins("4")
	await _gravar("4-religada-avancou.png")

	_linha("== 5. a jogadora sai e volta a entrar ==")
	var antes := _caixa()
	await _sair_jogadora("5")
	_recebido.clear()
	if not await _entrar_jogadora("5"):
		_fim()
		return
	c = _caixa()
	_linha("  caixa da jogadora: " + _descrever(c))
	_ok(c["visivel"] and c["modo"] == "dinamico" and c["ids"] == antes["ids"] and c["vez"] == antes["vez"],
		"5: a caixa reconstruiu-se do snapshot, igual à de antes de sair")
	await _privacidade("5")
	_ok(_caixa_relatada.get("desactualizado") == false, "5: o relato dá o JSON do snapshot da reentrada como o actual (não marcado)")
	await _conferir_manequins("5")
	await _gravar("5-reentrou.png")
	_fim()


func _fim() -> void:
	# CAIXA-RELATO-CORRECOES-2 (B1): a varredura final do relato INTEIRO (incluindo o que se escreveu depois do §5).
	# CAIXA-RELATO-CORRECOES-3 (B1): «inteiro» é o ficheiro TODO: as 3 linhas finais (esta verificação, a linha em
	# branco e o resumo) compõem-se primeiro, a varredura corre sobre o relato + elas e a contagem diz esse tamanho.
	# Depois de TODAS as _linha(), o relato volta a ser varrido (abaixo).
	# CAIXA-RELATO-CORRECOES-4 (B1): se a re-varredura achar um nome, a verificação do fim passa a FALHA e o resumo é
	# refeito, os dois NO SÍTIO (`_reescrever`), sem linhas a mais: a contagem continua a ser a do ficheiro e há um só
	# resumo. Antes, juntava-se uma FALHA e um 2.º resumo, e o ficheiro ficava com 2 linhas a mais do que dizia.
	# CAIXA-RELATO-CORRECOES-4 (B3): sem nomes verdadeiros juntados (`_canarios_nomes` vazio), a varredura não tem o
	# que procurar — falha em voz alta em vez de não verificar nada (como as passagens do `_privacidade`).
	var resumo := "prova da caixa com os manequins: %d de %d verificações passaram."
	var texto := "fim: o relato inteiro (%d linhas — todas as do ficheiro, contando esta e as 2 finais) não traz nenhum dos %d nome(s) verdadeiro(s) %s"
	var pre_ok := false
	var i_fim := -1
	if _canarios_nomes.is_empty():
		_ok(false, "fim: a varredura do relato inteiro não tem nenhum nome verdadeiro para procurar (o canário não juntou nenhum) — não pode passar sem verificar")
	else:
		var n := _relato.size() + 3
		var finais := PackedStringArray(["  ok    " + texto % [n, _canarios_nomes.size(), []], "", resumo % [_total + 1 - _falhas, _total + 1]])
		var achados := _nomes_em(_relato + finais, _canarios_nomes)
		pre_ok = achados.is_empty()
		i_fim = _relato.size()
		_ok(pre_ok, texto % [n, _canarios_nomes.size(), achados])
	_linha("")
	_linha(resumo % [_total - _falhas, _total])
	# B1: re-varrer DEPOIS de todas as _linha() — o relato em memória é agora o ficheiro inteiro. (Se a varredura de
	# cima já falhou, a prova já falha; não se repete.)
	if pre_ok:
		var depois := _nomes_no_relato(_canarios_nomes)
		if not depois.is_empty():
			_falhas += 1
			var falha := "fim: o relato inteiro (%d linhas — todas as do ficheiro, contando esta e as 2 finais) traz nome(s) verdadeiro(s), achados só pela re-varredura do que se escreveu %s" % [_relato.size(), depois]
			_reescrever(i_fim, "  FALHA " + falha)
			printerr("  FALHA ", falha)
			_reescrever(_relato.size() - 1, resumo % [_total - _falhas, _total])
	for l in _herois.values():
		l.fechar()
	if _mestre_b != null:
		_mestre_b.fechar()
	await _quadros(5)
	quit(1 if _falhas > 0 or _total == 0 else 0)
