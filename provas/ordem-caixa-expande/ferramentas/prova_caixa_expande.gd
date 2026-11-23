extends SceneTree
## Ordem F27 da sentença da CAIXA-EXPANDE-INTERACAO (23/11/2026): a mesma prova, com um passo novo, o 13, depois do 11/12
## (com as 16 figuras que o 11 deixou):
##   13     o D1 com MOVIMENTO. A IA de ensaio joga as vezes das outras figuras até ser a vez da jogadora (a do ecrã a sério);
##          ela abre o Mover pelo botão da barra (toque pelo Input do motor). Em 844×390 e 780×360: a expandida aberta
##          por toque; um toque fora, num sítio que cai numa casa de destino do Mover, fecha-a e a figura FICA NO SÍTIO
##          (o nó dela e a casa do Estado iguais, a casa no servidor igual, o Mover ainda aberto, nenhuma intenção na fila
##          nem enviada); de controlo, com a caixa fechada, o MESMO toque escolhe a casa, sai a intenção e a figura ANDA
##          até ela (a casa do Estado e a do servidor passam a ser a de destino; o nó chega lá). Capturas
##          13-mover-aberta-*, 13-mover-toque-fora-* e 13-mover-controlo-*.
##   bash provas/ordem-f27-mover-aberto/ferramentas/correr-prova-mover-aberto.sh <godot.exe> <vlab-completo.js> <pasta-tmp>
##
## Ordem CAIXA-EXPANDE-VISTAS (22/11/2026, F15 da sentença da CAIXA-EXPANDE, D2): a mesma prova, com um passo novo, o 12,
## corrido dentro do ciclo do 11 (as mesmas 12 e 16 figuras, em 844×390 e 780×360, depois dos 3 gestos):
##   12     a barra de rolagem da expandida COMO É HOJE (não se muda): a lista no topo sem rolar (linhas inteiras à vista,
##          a cortada pela borda), a meio (um passo da roda) e no fim; a barra do tema medida (à vista, largura, altura,
##          pega; unidades do HUD e px reais). Capturas 12-barra-{topo,meio,fim}-N-figuras-WxH.png e o recorte ampliado
##          3× de todas (-recorte.png): a matéria da pergunta ao olho do Mestre (barra discreta ou mais visível).
##   bash provas/ordem-caixa-expande-vistas/ferramentas/correr-prova-vistas.sh <godot.exe> <vlab-completo.js> <pasta-tmp>
##
## Ordem CAIXA-EXPANDE-INTERACAO (22/11/2026, F14 da sentença da CAIXA-EXPANDE): a mesma prova, com dois acertos —
##   8      a lista rola até ao fim com a RODA DO RATO a sério (push_input), e não com `scroll_vertical` posto pelo código.
##   11     os 3 gestos a sério, com 12 e 16 figuras (o Mestre põe mais criaturas), em 844×390 e 780×360:
##       D2  a roda rola a lista (posição medida antes e depois); o arrastar com o rato mede-se e regista-se;
##       D3  a roda no fim e no topo da lista não muda o zoom do tabuleiro (a câmara da arena; medido antes e depois);
##       D1  com a expandida aberta por toque (pelo Input do motor, que imita o rato a partir dele), um toque fora fecha-a e
##           o tabuleiro fica quieto: o «toque» da câmara não dispara, as figuras não se mexem, a arena não muda de modo
##           nem de cursor e não sai intenção nenhuma.
##   bash provas/ordem-caixa-expande-interacao/ferramentas/correr-prova-interacao.sh <godot.exe> <vlab-completo.js> <pasta-tmp>
##
## Prova da Ordem CAIXA-EXPANDE (22/11/2026) — cópia da prova da CAIXA-PADRAO-CORRECOES
## (provas/ordem-caixa-padrao-correcoes/ferramentas/prova_caixa_padrao_correcoes.gd): os mesmos 5 momentos e os casos do
## retrato, com a regra do Mestre (21/11/2026 23:10) e os momentos novos:
##   compacta  nos momentos com a caixa à vista: o cartão grande é SÓ a figura na vez e o nome a ouro é SÓ o dela; as
##       caixinhas pequenas são os PRÓXIMOS a jogar (até 4), a contar de quem vem a seguir à vez, sem a figura na vez,
##       todas a pergaminho (hud/caixa_ordem.gd proximos).
##   6 (a)  o rato por cima da caixa (eventos do motor, como o rato a sério) → a vista expandida: a ordem inteira, a vez
##       primeiro e realçada, os nomes completos; tirar o rato volta à compacta.
##   7 (b)  8+ figuras: o Mestre de ensaio põe 5 criaturas a mais (MASTER_PLACE em combate) e escolhe a iniciativa; a
##       expandida mostra-as todas; e o toque (aparelhos sem rato) abre e fecha a mesma vista.
##   8 (c)  a expandida com essas figuras em 844×390 e 780×360 (a janela muda de tamanho a sério): cabe acima da barra;
##       o que não cabe rola por dentro (MEDIDA EXPANDIDA ...).
##   9 (d)  a recentragem da faixa (F4) com a caixa nova, em 844×390, 780×360 e 1920×1080, contra os tectos novos
##       (testes/caixa_jogadora.gd TECTO_DESVIO_8).
##   10     os casos do retrato (os mesmos da CAIXA-PADRAO-CORRECOES).
##   bash provas/ordem-caixa-expande/ferramentas/correr-prova-caixa-expande.sh <godot.exe> <vlab-completo.js> <pasta-tmp>
##
## Prova da Ordem CAIXA-PADRAO-CORRECOES (22/11/2026) — cópia da prova da CAIXA-PADRAO-BUSTO
## (provas/ordem-caixa-padrao-busto/ferramentas/prova_caixa_padrao_busto.gd), os mesmos 5 momentos, com as correcções
## da sentença da CAIXA-PADRAO-BUSTO:
##   B1/B2/B4/B5  um 6.º passo, «os casos do retrato», com o render a sério e os manequins da cena: o ciclo inteiro do
##       ANDAR (o «de pé» em todos os quadros, a margem ao limiar), a passada longa, a arma rígida levantada, o braço
##       levantado (limite), a figura deitada, o quadrúpede esfolado, a caixa zero, a validação em repouso e a caixa em pose
##       contra a malha esfolada PELO MOTOR (bake_mesh_from_current_skeleton_pose; aqui há render). Os retratos destes
##       casos ficam em retratos/casos/. Nos momentos com a caixa à vista, os retratos da cena são também confrontados
##       com a malha esfolada pelo motor. Os casos vêm de rascunhos/cliente/testes/casos_retrato.gd (os mesmos da suite).
##   B3  a lista dos quadradinhos imprime os caracteres VISÍVEIS dos nomes (hud/caixa_ordem.gd texto_visivel: o que a
##       linha mostra depois do corte com «…»), e não o `nome.text` de antes do corte.
##   B7  `_privacidade` também no momento 2 (iniciativa).
##   B8  o PIN do Mestre não tem literal: vem por --pin= (o lançador gera um novo por corrida); o info e o log do
##       servidor não se copiam para a pasta de saída. E o relato só leva nomes PÚBLICOS (nomePublico): a vista do Mestre
##       não entra no relato.
## Tudo o resto (ordens, vezes, manequim, cores, quadradinhos, busto) igual à prova do padrão-busto.
##
## Prova da Ordem CAIXA-PADRAO-BUSTO (21/11/2026) — cópia da prova da CAIXA-TESTE-ESTETICA
## (provas/ordem-caixa-teste-estetica/ferramentas/prova_caixa_teste_estetica.gd), igual passo a passo, com duas
## verificações novas em cada momento com a caixa à vista (palavra do Mestre, 21/11/2026 19:52):
##   (a) os quadradinhos das figuras seguintes têm TODOS o mesmo tamanho, medido ao píxel (a célula e o retrato),
##       igual à célula fixa da caixa (hud/caixa_ordem.gd tamanho_celula), seja qual for o nome; o cartão grande da
##       figura na vez continua maior;
##   (b) cada retrato (o da fila e o do cartão grande são a mesma textura) é um BUSTO — rosto e peitoral: na câmara do
##       retrato, o alto da cabeça, o rosto e o peito da figura EM POSE caem dentro do quadro, a cintura, os joelhos e
##       os pés ficam fora, e a câmara está à frente da figura (do lado do rosto).
## Guarda também, em retratos/, o retrato de cada figura no momento 1 (160×160), para o olho.
## As verificações antigas (ordens, vezes, manequim, privacidade, cores) mantêm-se tal e qual.
##
## A prova da CAIXA-MANEQUIM: os MESMOS 5 momentos da prova viva da CAIXA-HUD-JOGADORA
## (provas/ordem-caixa-hud-jogadora/ferramentas/prova_caixa_jogadora.gd, de que esta é cópia), com UMA mudança: as
## figuras em cena — e por isso os retratos da caixa, que são cópias delas (hud/retratos.gd) — são o MANEQUIM DE
## REFERÊNCIA DA CASA (Mannequin_F do UAL2 com o ANDAR v3, testes/manequim/andar-v3.glb, SHA-256 conferido; o mesmo
## das capturas do LAGO-MAIOR), nunca as cápsulas de bancada. Não é código do jogo: o jogo continua a pôr a cápsula;
## esta ferramenta esconde-a (o nó «Corpo» fica no sítio, invisível — a arena continua a pintá-lo e a assentá-lo) e
## põe o manequim no pé da figura, virado como ela. Os retratos já desenhados são esquecidos e refeitos do manequim.
## Nenhuma cor nova: o manequim traz os seus materiais; a caixa e o fundo dos retratos são os da tabela.
##
##   bash provas/ordem-caixa-padrao-correcoes/ferramentas/correr-prova-caixa-padrao-correcoes.sh <godot.exe> <vlab-completo.js> <pasta-tmp>
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
var _pin := ""  # B8: sem literal — o PIN da corrida vem por --pin= (o lançador gera-o)
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
var _gltf_doc: GLTFDocument
var _gltf_estado: GLTFState
var _medidas: Array = []  # a lista medida dos quadradinhos, por momento
var _letras_vistas: Array = []  # B3: as letras à vista dos nomes, em todos os momentos


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


func _caixa_b(ligada: bool, modo: String) -> bool:
	return await _comando_b("MASTER_SUPERVISOR", {"op": "caixa", "caixa": {"ligada": ligada, "modo": modo}})


## O nome PÚBLICO da figura (o que a jogadora vê). A vista do Mestre traz também o nome verdadeiro: não entra no relato.
func _nome(v: Dictionary, id: String) -> String:
	for f in v.get("mestre", {}).get("figuras", []):
		if str(f.get("id", "")) == id:
			return str(f.get("nomePublico", id))
	return id


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
		_linha("  IA: %s → %s (%s)" % [str(quem.get("nomePublico", vez_id)), JSON.stringify(passo), str(lugar.respostas.get(id, {}).get("estado", lugar.respostas.get(id, {}).get("motivo", "?")))])
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


# ------------------------------------------------------------------ as cores da caixa (teste estético)

const Apresentacao := preload("res://dados/apresentacao.gd")
const PAINEL := Color(16 / 255.0, 12 / 255.0, 8 / 255.0, 0.55)
const OURO := Color(0xc9 / 255.0, 0xa2 / 255.0, 0x27 / 255.0, 0.85)
const PERGAMINHO := Color(0xf3 / 255.0, 0xe9 / 255.0, 0xd2 / 255.0, 1.0)
const FUNDO_RETRATO := Color(10 / 255.0, 8 / 255.0, 5 / 255.0, 0.82)


func _cor_igual(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.002 and absf(a.g - b.g) < 0.002 and absf(a.b - b.b) < 0.002 and absf(a.a - b.a) < 0.002


func _juntar_cores(no: Node, achados: Dictionary) -> void:
	if no is Label and (no as Label).is_visible_in_tree():
		var l := no as Label
		var cor := l.get_theme_color("font_color")
		var pai := l.get_parent()
		# Ordem CAIXA-EXPANDE: a ouro, SÓ o nome do cartão grande (compacta) e a linha da vez (expandida).
		var avo: Node = pai.get_parent() if pai != null else null
		var na_vez: bool = l.name == "NomeActiva" or (pai != null and pai.name == "Textos" and avo != null and str(avo.name) == "Linha_" + str(_caixa()["vez"]))
		var certa := OURO if na_vez else PERGAMINHO
		if not _cor_igual(cor, certa):
			achados["maus"].append("letra «%s» %s" % [l.text, cor.to_html()])
		achados["letras"] += 1
	if no is PanelContainer and no.name == "Moldura" and (no as Control).is_visible_in_tree():
		var s := (no as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat
		if s == null or not _cor_igual(s.border_color, OURO) or not _cor_igual(s.bg_color, FUNDO_RETRATO):
			achados["maus"].append("moldura %s" % (s.border_color.to_html() if s != null else "?"))
		elif s.border_width_top == 3:
			achados["realce"] += 1
		achados["molduras"] += 1
	for f in no.get_children():
		_juntar_cores(f, achados)


## A caixa só usa as quatro cores da linguagem do protótipo; a figura na vez destaca-se pela moldura grossa e o nome a ouro.
func _conferir_cores(rotulo: String) -> void:
	var cx := _arena.hud.get_node("Raiz/Seguro/Camadas/CaixaOrdem") as PanelContainer
	var fundo := cx.get_theme_stylebox("panel") as StyleBoxFlat
	_ok(_cor_igual(Apresentacao.COR_CAIXA_PAINEL, PAINEL) and _cor_igual(Apresentacao.COR_CAIXA_MOLDURA, OURO)
		and _cor_igual(Apresentacao.COR_CAIXA_TEXTO, PERGAMINHO) and _cor_igual(Apresentacao.COR_RETRATO_FUNDO, FUNDO_RETRATO),
		rotulo + ": a tabela tem as cores do protótipo (painel %s, moldura %s, letras %s, retrato %s)" % [
			Apresentacao.COR_CAIXA_PAINEL.to_html(), Apresentacao.COR_CAIXA_MOLDURA.to_html(),
			Apresentacao.COR_CAIXA_TEXTO.to_html(), Apresentacao.COR_RETRATO_FUNDO.to_html()])
	_ok(fundo != null and _cor_igual(fundo.bg_color, PAINEL), rotulo + ": o painel da caixa é rgba(16,12,8,.55)")
	var achados := {"maus": [], "letras": 0, "molduras": 0, "realce": 0}
	_juntar_cores(cx, achados)
	_ok((achados["maus"] as Array).is_empty() and achados["letras"] > 0 and achados["molduras"] > 0,
		rotulo + ": %d letras a pergaminho (só o cartão grande / a linha da vez a ouro) e %d molduras a ouro .85 com o fundo do retrato, nenhuma outra cor %s" % [achados["letras"], achados["molduras"], achados["maus"]])
	_ok(achados["realce"] >= 1, rotulo + ": a figura na vez destaca-se com a moldura de ouro grossa (%d)" % achados["realce"])


# ------------------------------------------------------------------ Ordem CAIXA-PADRAO-BUSTO: (a) quadradinhos e (b) busto

const Retratos := preload("res://hud/retratos.gd")
const CaixaOrdem := preload("res://hud/caixa_ordem.gd")
const CasosRetrato := preload("res://testes/casos_retrato.gd")


## (a) Todos os quadradinhos da fila com o mesmo tamanho, medido em píxeis reais da janela (o tamanho de cada um com a
## escala da janela, ver _janela) e em unidades do HUD.
func _conferir_quadradinhos(rotulo: String) -> void:
	_linha("  escala HUD→janela %.4f (janela %dx%d, área do HUD %dx%d u)" % [_janela().x, root.size.x, root.size.y,
		int(root.get_visible_rect().size.x), int(root.get_visible_rect().size.y)])
	var cx = _arena.hud.get_node("Raiz/Seguro/Camadas/CaixaOrdem")
	var fila: Node = cx.find_child("Fila", true, false)
	var tamanhos: Array = []
	var distintos := {}
	var molduras := {}
	var largura := 0
	for slot in fila.get_children():
		var sc := slot as Control
		var esc: Vector2 = sc.get_global_transform_with_canvas().get_scale() * _janela()
		var px := Vector2i(roundi(sc.size.x * esc.x), roundi(sc.size.y * esc.y))
		var m := slot.get_node("Moldura") as Control
		var mpx := Vector2i(roundi(m.size.x * esc.x), roundi(m.size.y * esc.y))
		var nome := slot.get_node("Nome") as Label
		# B3: o que a linha MOSTRA (cortado com «…» na largura da célula), e quantas letras ficam à vista.
		var vis := CaixaOrdem.texto_visivel(nome)
		var letras := vis.trim_suffix(nome.ellipsis_char).length()
		tamanhos.append("«%s» (%d letras à vista) %dx%d px (%dx%d u)" % [vis, letras, px.x, px.y, int(sc.size.x), int(sc.size.y)])
		_letras_vistas.append(letras)
		distintos["%dx%d" % [px.x, px.y]] = true
		molduras["%dx%d" % [mpx.x, mpx.y]] = true
		largura = px.x
	var cel: Vector2 = cx.tamanho_celula()
	var activa := cx.find_child("Activa", true, false) as Control
	var am := activa.get_child(0) as Control
	var aesc: Vector2 = am.get_global_transform_with_canvas().get_scale() * _janela()
	var apx := Vector2i(roundi(am.size.x * aesc.x), roundi(am.size.y * aesc.y))
	_linha("  quadradinhos (px reais da janela): %s · retrato %s · célula fixa %dx%d u · cartão na vez %dx%d px" % [
		", ".join(tamanhos), molduras.keys(), int(cel.x), int(cel.y), apx.x, apx.y])
	_medidas.append("%s: %s · retrato %s · cartão na vez %dx%d" % [rotulo, ", ".join(tamanhos), molduras.keys(), apx.x, apx.y])
	_ok(tamanhos.size() >= 2 and distintos.size() == 1 and molduras.size() == 1,
		rotulo + ": os %d quadradinhos têm TODOS o mesmo tamanho, ao píxel (%s; retrato %s)" % [tamanhos.size(), distintos.keys(), molduras.keys()])
	var um := fila.get_child(0) as Control
	_ok(is_equal_approx(um.size.x, cel.x) and is_equal_approx(um.size.y, cel.y),
		rotulo + ": e esse tamanho é a célula fixa da caixa (%dx%d u)" % [int(cel.x), int(cel.y)])
	if activa.visible:
		_ok(apx.x > largura, rotulo + ": o cartão grande da figura na vez continua maior (%dx%d px contra %d)" % [apx.x, apx.y, largura])


## Quantos píxeis reais da janela vale uma unidade do HUD (o projecto estica o HUD de 1920×1080: canvas_items).
func _janela() -> Vector2:
	var v := root.get_visible_rect().size
	return Vector2(float(root.size.x) / v.x, float(root.size.y) / v.y)


## (b) Cada retrato da caixa é um busto: rosto e peitoral dentro do quadro, corpo inteiro não.
func _conferir_busto(rotulo: String, guardar: bool) -> void:
	var c := _caixa()
	var r = _arena.hud._retratos
	var maus: Array = []
	var medidas: Array = []
	for id in c["ids"]:
		var sv: SubViewport = r._palcos.get(id)
		if sv == null:
			maus.append(_estado.nome_de(str(id)) + " sem retrato")
			continue
		var cam := sv.get_node("Camera") as Camera3D
		var copia := sv.get_node("Palco").get_child(0) as Node3D
		var p: AABB = Retratos.caixa_do_corpo(copia)
		var cxs := Retratos.caixas_do_corpo(copia)
		var h := p.size.y
		var cx := p.get_center().x
		var cz := p.get_center().z
		var topo := Vector3(cx, p.end.y - h * 0.02, cz)
		var rosto := Vector3(cx, p.end.y - h * 0.07, cz)
		var peito := Vector3(cx, p.end.y - h * 0.22, cz)
		var cintura := Vector3(cx, p.end.y - h * 0.45, cz)
		var joelho := Vector3(cx, p.position.y + h * 0.28, cz)
		var pe := Vector3(cx, p.position.y + h * 0.02, cz)
		var dentro := cam.is_position_in_frustum(topo) and cam.is_position_in_frustum(rosto) and cam.is_position_in_frustum(peito)
		var fora := not cam.is_position_in_frustum(cintura) and not cam.is_position_in_frustum(joelho) and not cam.is_position_in_frustum(pe)
		var frente := cam.transform.origin.z < p.get_center().z
		var malha_t := ""
		for mi in copia.find_children("*", "MeshInstance3D", true, false):
			if (mi as MeshInstance3D).skin != null and (mi as MeshInstance3D).is_visible_in_tree():
				var a := (mi as MeshInstance3D).mesh.get_aabb()
				malha_t = " (a malha em T: %.2f×%.2f)" % [a.size.x, a.size.y]
		medidas.append("%s: em pose %.2f×%.2f m%s, de pé %s, rosto+peito no quadro %s, cintura/joelhos/pés fora %s, de frente %s" % [
			_estado.nome_de(str(id)), maxf(p.size.x, p.size.z), h, malha_t, Retratos.de_pe(p, cxs), dentro, fora, frente])
		if not (Retratos.de_pe(p, cxs) and dentro and fora and frente):
			maus.append(_estado.nome_de(str(id)))
		if guardar:
			DirAccess.make_dir_recursive_absolute(_saida.path_join("retratos"))
			var img := sv.get_texture().get_image()
			if img != null and not img.is_empty():
				img.save_png(_saida.path_join("retratos").path_join("%s.png" % _estado.nome_de(str(id)).to_lower().replace(" ", "-")))
	for m in medidas:
		_linha("    retrato " + m)
	_ok(maus.is_empty() and not medidas.is_empty(),
		rotulo + ": os %d retratos são busto — rosto e peitoral no quadro; cintura, joelhos e pés fora; de frente %s" % [medidas.size(), maus])
	_conferir_esfola(rotulo, c["ids"])


## B5: a caixa dos retratos (a cópia em pose no palco) contém a malha da figura em cena esfolada PELO MOTOR
## (bake_mesh_from_current_skeleton_pose; a cópia assenta na origem, por isso o espaço da figura, sem a posição e o rumo
## dela na arena, é o do palco), e a esfola
## por CPU (a conta da suite, sem ecrã) dá o mesmo que a do motor.
func _conferir_esfola(rotulo: String, ids: Array) -> void:
	var r = _arena.hud._retratos
	var maus: Array = []
	var linhas: Array = []
	for id in ids:
		var sv: SubViewport = r._palcos.get(id)
		var no: Node3D = _arena._nos.get(id)
		if sv == null or no == null:
			maus.append(str(id) + " sem retrato")
			continue
		var copia := sv.get_node("Palco").get_child(0) as Node3D
		var m := no.get_node(NOME_MANEQUIM) as Node3D
		var mi := m.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		# no espaço da figura (a cópia do palco assenta na origem: tira-se a posição e o rumo da figura na arena)
		var local := no.transform.affine_inverse()
		var mot := local * CasosRetrato.esfolar_motor(no, mi)
		var cpu := local * CasosRetrato.esfolar_cpu(no, mi)
		var p := Retratos.caixa_do_corpo(copia)
		var igual := mot.size != Vector3.ZERO and mot.position.distance_to(cpu.position) < 0.002 and mot.size.distance_to(cpu.size) < 0.002
		var folga := p.size - mot.size
		linhas.append("figura %s: retrato %.3f×%.3f×%.3f, motor %.3f×%.3f×%.3f, folga máx %.3f m, CPU = motor %s" % [str(id),
			p.size.x, p.size.y, p.size.z, mot.size.x, mot.size.y, mot.size.z, maxf(folga.x, maxf(folga.y, folga.z)), igual])
		if not (igual and p.grow(0.001).encloses(mot)):
			maus.append(str(id))
	for l in linhas:
		_linha("    esfola " + l)
	_ok(maus.is_empty() and not linhas.is_empty(),
		rotulo + ": a caixa dos %d retratos contém, um a um, a malha esfolada pelo motor, e a esfola por CPU é igual à do motor %s" % [linhas.size(), maus])


# ------------------------------------------------------------------ a jogadora a sério

func _registar(msg: Dictionary) -> void:
	_recebido.append(JSON.stringify(msg))


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
	_ok(chaves_ok, rotulo + ": a caixa que lhe chegou só tem ligada, ordemPor e ordemDinamica %s" % JSON.stringify(c))
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
	for t in textos:
		for k in canarios:
			if str(t).contains(k):
				achados.append("%s em «%s»" % [k, t])
	_ok(achados.is_empty(), rotulo + ": nenhum dado do Mestre (nome verdadeiro, vida, PA) nos textos da caixa (%d achados; o texto achado não se repete aqui)" % achados.size())


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
	if _pin.length() < 6 or not _pin.lstrip("0123456789").is_empty():
		printerr("falta --pin=<6 dígitos ou mais> (o PIN da corrida; o lançador gera-o)")
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
	_linha("== Ordem CAIXA-EXPANDE — os 5 momentos da caixa no HUD da jogadora (manequim de referência), a vista expandida, a recentragem da faixa e os casos do retrato ==")
	_linha("servidor %s · render %s" % [_url, RenderingServer.get_video_adapter_name()])

	if not _abrir_manequim():
		_fim()
		return
	_linha("== 0. batalha de bancada (IA de bancada, lugares próprios) ==")
	if not await _montar_batalha():
		_fim()
		return

	_linha("== 1. a jogadora (a heroína 1 do cenário) entra pelo ecrã a sério ==")
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
	_conferir_cores("1")
	_conferir_compacta("1")
	_conferir_quadradinhos("1")
	_conferir_busto("1", true)
	await _gravar("1-entrou-dinamica.png")

	_linha("== 2. o Mestre carrega em «Modo iniciativa» ==")
	_ok(await _caixa_b(true, "iniciativa"), "2: o servidor aceitou a escolha do Mestre (ligada, iniciativa)")
	_ok(await _esperar(func(): return _caixa()["modo"] == "iniciativa", 10.0), "2: a caixa da jogadora passou ao modo iniciativa")
	await _quadros(10)
	c = _caixa()
	_linha("  caixa da jogadora: " + _descrever(c))
	_ok(c["visivel"] and c["ids"] == _estado.iniciativa and c["vez"] == _estado.vez_id,
		"2: a ordem é a de iniciativa do servidor %s e a vez é a do servidor (%s)" % [_nomes_ids(_estado.iniciativa), _estado.nome_de(_estado.vez_id)])
	await _privacidade("2")
	await _conferir_manequins("2")
	_conferir_cores("2")
	_conferir_compacta("2")
	_conferir_quadradinhos("2")
	_conferir_busto("2", false)
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
	await _conferir_manequins("4")
	_conferir_cores("4")
	_conferir_compacta("4")
	_conferir_quadradinhos("4")
	_conferir_busto("4", false)
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
	await _conferir_manequins("5")
	_conferir_cores("5")
	_conferir_compacta("5")
	_conferir_quadradinhos("5")
	_conferir_busto("5", false)
	await _gravar("5-reentrou.png")
	await _expande()
	await _casos()
	await _interacao()
	await _mover_aberto()
	_fim()


# ------------------------------------------------------------------ 6. os casos do retrato (B1, B2, B4, B5)

## Pede o retrato do `modelo` a um palco de retratos próprio (o mesmo hud/retratos.gd do HUD), espera que se desenhe e
## guarda-o em retratos/casos/<nome>.png. Devolve a câmara desse palco (para conferir o quadro).
func _retrato_caso(r: Node, nome: String, modelo: Node3D) -> Camera3D:
	r.pedir(nome, "1", modelo)
	await _quadros(4)
	await RenderingServer.frame_post_draw
	var dir := _saida.path_join("retratos").path_join("casos")
	DirAccess.make_dir_recursive_absolute(dir)
	var img: Image = r.textura(nome).get_image()
	var ok: bool = img != null and not img.is_empty() and img.save_png(dir.path_join(nome + ".png")) == OK
	_linha("    retrato do caso guardado em retratos/casos/%s.png: %s" % [nome, ok])
	return r._palcos[nome].get_node("Camera") as Camera3D


func _copia_do_palco(r: Node, nome: String) -> Node3D:
	return r._palcos[nome].get_node("Palco").get_child(0) as Node3D


func _casos() -> void:
	_linha("== 10. os casos do retrato, com o render a sério (B1, B2, B4, B5) ==")
	var r := Retratos.new()
	r.name = "RetratosDosCasos"
	root.add_child(r)
	# B1 (a): o ciclo inteiro do ANDAR, numa figura da cena (o manequim dela), quadro a quadro.
	var id0: String = _caixa()["ids"][0] if not (_caixa()["ids"] as Array).is_empty() else str(_arena._nos.keys()[0])
	var no: Node3D = _arena._nos[id0]
	var anim := no.get_node(NOME_MANEQUIM).find_child("AnimationPlayer", true, false) as AnimationPlayer
	var a := anim.get_animation(ANIM)
	var n := int(round(a.length * 30.0))
	var fundo_max := 0.0
	var q_max := -1
	var limiar_q := 0.0
	var tronco_max := 0.0
	var todos := true
	for i in n + 1:
		anim.seek(minf(a.length, float(i) / 30.0), true)
		var cp := Retratos.copiar_modelo(no)
		var cxs := Retratos.caixas_do_corpo(cp)
		var c := Retratos.caixa_do_corpo(cp)
		if maxf(c.size.x, c.size.z) > fundo_max:
			fundo_max = maxf(c.size.x, c.size.z)
			q_max = i
			limiar_q = c.size.y / Retratos.DE_PE
		tronco_max = maxf(tronco_max, Retratos.largura_tronco(cxs, c))
		todos = todos and Retratos.de_pe(c, cxs) and Retratos.de_pe(c)
		cp.free()
	anim.seek(0.0, true)
	_ok(todos and n + 1 >= 40, "10 (B1): o manequim da figura %s, nos %d quadros do ANDAR, está sempre de pé (pela caixa toda e pelo tronco)" % [id0, n + 1])
	_ok(limiar_q - fundo_max > 0.4, "10 (B1): a profundidade máxima do ANDAR é %.3f m (quadro %d), a %.3f m do limiar %.3f m; o tronco não passa de %.3f m" % [
		fundo_max, q_max, limiar_q - fundo_max, limiar_q, tronco_max])
	# B1 (b): a passada longa.
	var d := CasosRetrato.manequim(0.3)
	root.add_child(d["fig"])
	CasosRetrato.parar(d)
	CasosRetrato.passada_longa(d, 60.0)
	await _quadros(2)
	var cam := await _retrato_caso(r, "passada-longa", d["fig"])
	var cp := _copia_do_palco(r, "passada-longa")
	var cxs := Retratos.caixas_do_corpo(cp)
	var c := Retratos.caixa_do_corpo(cp)
	var b := CasosRetrato.conferir_busto(cam, c)
	_ok(not Retratos.de_pe(c) and Retratos.de_pe(c, cxs) and b["dentro"] and b["fora"],
		"10 (B1): a passada longa (%.2f m de fundo, %.2f de alto): pela caixa toda não diria «de pé», pelo tronco (%.2f m) diz, e no render o retrato é o busto %s" % [
			maxf(c.size.x, c.size.z), c.size.y, Retratos.largura_tronco(cxs, c), b["falta"]])
	(d["fig"] as Node).free()
	# B2: a arma rígida levantada; o braço levantado (limite).
	d = CasosRetrato.manequim(0.3)
	root.add_child(d["fig"])
	CasosRetrato.parar(d)
	await _quadros(2)
	var c0 := Retratos.caixa_do_corpo(Retratos.copiar_modelo(d["fig"]))
	CasosRetrato.arma_levantada(d, 0.6)
	cam = await _retrato_caso(r, "arma-levantada", d["fig"])
	cp = _copia_do_palco(r, "arma-levantada")
	c = Retratos.caixa_do_corpo(cp)
	var tudo := Retratos.caixa_visivel(cp)
	b = CasosRetrato.conferir_busto(cam, c)
	_ok(tudo.end.y > c.end.y + 0.5 and c.is_equal_approx(c0) and b["dentro"] and b["fora"],
		"10 (B2): com a arma levantada (ponta a %.2f m, cabeça a %.2f m) o corpo não muda e no render o retrato continua o busto %s" % [tudo.end.y, c.end.y, b["falta"]])
	(d["fig"] as Node).free()
	d = CasosRetrato.manequim(0.3)
	root.add_child(d["fig"])
	CasosRetrato.parar(d)
	await _quadros(2)
	var esq := d["esqueleto"] as Skeleton3D
	var cabeca := Retratos._no_espaco_de(d["fig"], esq) * esq.get_bone_global_pose(esq.find_bone(CasosRetrato.CABECA)).origin
	CasosRetrato.braco_levantado(d)
	cam = await _retrato_caso(r, "braco-levantado", d["fig"])
	c = Retratos.caixa_do_corpo(_copia_do_palco(r, "braco-levantado"))
	_ok(CasosRetrato.ve(cam, cabeca + Vector3(0, 0.1, 0)) and CasosRetrato.ve(cam, cabeca + Vector3(0, 0.2, 0)),
		"10 (B2, limite): com o braço levantado a figura sobe a %.2f m; o rosto fica no quadro, o peito %s (limite documentado)" % [
			c.end.y, "também" if CasosRetrato.ve(cam, cabeca + Vector3(0, -0.25, 0)) else "sai"])
	(d["fig"] as Node).free()
	# B4: deitada, quadrúpede, caixa zero.
	d = CasosRetrato.manequim(0.0)
	root.add_child(d["fig"])
	CasosRetrato.parar(d)
	CasosRetrato.deitar(d)
	await _quadros(2)
	cam = await _retrato_caso(r, "deitada", d["fig"])
	cp = _copia_do_palco(r, "deitada")
	c = Retratos.caixa_do_corpo(cp)
	_ok(not Retratos.de_pe(c, Retratos.caixas_do_corpo(cp)) and CasosRetrato.caixa_no_quadro(cam, c),
		"10 (B4): o manequim deitado (%.2f × %.2f × %.2f m) dá o corpo inteiro, todo no quadro" % [c.size.x, c.size.y, c.size.z])
	(d["fig"] as Node).free()
	var q := CasosRetrato.quadrupede()
	root.add_child(q)
	await _quadros(2)
	cam = await _retrato_caso(r, "quadrupede", q)
	cp = _copia_do_palco(r, "quadrupede")
	c = Retratos.caixa_do_corpo(cp)
	var mq := q.find_child("Corpo", true, false) as MeshInstance3D
	var mot := CasosRetrato.esfolar_motor(q, mq)
	_ok(not Retratos.de_pe(c, Retratos.caixas_do_corpo(cp)) and CasosRetrato.caixa_no_quadro(cam, c) and mot.size != Vector3.ZERO and c.grow(0.001).encloses(mot),
		"10 (B4): o quadrúpede esfolado (%.2f × %.2f × %.2f m) dá o corpo inteiro, todo no quadro; o motor esfola-o (%.2f × %.2f × %.2f m, dentro da caixa)" % [
			c.size.x, c.size.y, c.size.z, mot.size.x, mot.size.y, mot.size.z])
	q.free()
	var nada := Node3D.new()
	root.add_child(nada)
	cam = await _retrato_caso(r, "caixa-zero", nada)
	_ok(cam.transform.origin.is_finite() and cam.transform.origin.z < 0.0 and cam.far > cam.near,
		"10 (B4): a caixa zero (nada visível) desenha a figura de recurso sem erro (câmara à frente, planos %.2f–%.2f m)" % [cam.near, cam.far])
	nada.free()
	# B5: em repouso, a conta por ossos dá a caixa da malha; a esfola do motor também.
	d = CasosRetrato.manequim(0.0)
	root.add_child(d["fig"])
	CasosRetrato.parar(d)
	(d["esqueleto"] as Skeleton3D).reset_bone_poses()
	await _quadros(2)
	cp = Retratos.copiar_modelo(d["fig"])
	c = Retratos.caixa_do_corpo(cp)
	var malha := (d["malha"] as MeshInstance3D).mesh.get_aabb()
	mot = CasosRetrato.esfolar_motor(d["fig"], d["malha"])
	_ok(c.size.distance_to(malha.size) < 0.001 and c.position.distance_to(malha.position) < 0.001 and mot.size.distance_to(malha.size) < 0.002,
		"10 (B5): em repouso, a conta por ossos dá a caixa da malha (%.3f × %.3f × %.3f m contra %.3f × %.3f × %.3f), e a esfola do motor também (%.3f × %.3f × %.3f)" % [
			c.size.x, c.size.y, c.size.z, malha.size.x, malha.size.y, malha.size.z, mot.size.x, mot.size.y, mot.size.z])
	cp.free()
	(d["fig"] as Node).free()
	r.queue_free()
	await _quadros(2)


# ------------------------------------------------------------------ Ordem CAIXA-EXPANDE: a compacta, a expandida e a faixa

const TectosCaixa := preload("res://testes/caixa_jogadora.gd")


func _cx() -> Control:
	return _arena.hud.get_node("Raiz/Seguro/Camadas/CaixaOrdem") as Control


## A vista compacta: o cartão grande é só a figura na vez; as caixinhas são os próximos (até 4), sem ela.
func _conferir_compacta(rotulo: String) -> void:
	var c := _caixa()
	var ids: Array[String] = []
	for x in c["ids"]:
		ids.append(str(x))
	var esperada := CaixaOrdem.proximos(ids, str(c["vez"]), CaixaOrdem.MAX_FILA)
	var fila: Array = c["fila"]
	_linha("  compacta: cartão grande %s · caixinhas %s" % [_estado.nome_de(str(c["vez"])), _nomes_ids(fila)])
	_ok(fila == Array(esperada) and not fila.has(c["vez"]) and fila.size() == mini(CaixaOrdem.MAX_FILA, maxi(0, ids.size() - (1 if c["vez"] != "" else 0))),
		rotulo + ": as caixinhas são os %d próximos a jogar, a contar de quem vem depois da vez, sem a figura na vez %s" % [fila.size(), _nomes_ids(fila)])


## Um movimento do rato a sério, nas coordenadas do ecrã do HUD.
func _rato(p: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = p
	e.global_position = p
	root.push_input(e, true)


## Um toque (carrega e levanta no mesmo sítio), nas coordenadas do ecrã do HUD.
func _tocar(p: Vector2) -> void:
	for k in 2:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.pressed = k == 0
		t.position = p
		root.push_input(t, true)


## Um sítio do ecrã fora da caixa (expandida ou não) e fora da ⚙: o meio do ecrã, um pouco abaixo da faixa.
func _fora() -> Vector2:
	var v := root.get_visible_rect().size
	return Vector2(v.x * 0.4, v.y * 0.55)


## A vista expandida aberta: a ordem inteira a partir da vez, todas as linhas com o retrato e o nome COMPLETO, a vez realçada.
## Devolve o rectângulo da caixa expandida.
func _conferir_expandida(rotulo: String) -> Rect2:
	var c := _caixa()
	var cx := _cx()
	var ids: Array[String] = []
	for x in c["ids"]:
		ids.append(str(x))
	var seq := CaixaOrdem.sequencia(ids, str(c["vez"]))
	var lista: Node = cx.find_child("Lista", true, false)
	var linhas: Array = []
	var maus: Array = []
	var retratos := 0
	for l in lista.get_children():
		var id := str(l.name).trim_prefix("Linha_")
		var nome := l.get_node("Textos/Nome") as Label
		var vis := CaixaOrdem.texto_visivel(nome)
		linhas.append("«%s»%s" % [vis, " (na vez)" if l.has_node("Textos/NaVez") else ""])
		if vis != _estado.nome_de(id):
			maus.append(vis)
		var tr := l.get_node("Moldura/Retrato") as TextureRect
		if tr.texture != null:
			retratos += 1
	var r := cx.get_global_rect()
	var esc := _janela()
	_linha("  expandida (%dx%d u = %dx%d px reais; compacta %dx%d u): %s · rola %s" % [int(r.size.x), int(r.size.y), roundi(r.size.x * esc.x), roundi(r.size.y * esc.y),
		int(cx.tamanho_compacto().x), int(cx.tamanho_compacto().y), ", ".join(linhas), "SIM" if cx.expandida_rola() else "NÃO"])
	_ok(c["expandida"] and c["ordem_expandida"] == Array(seq) and lista.get_child_count() == ids.size() and ids.size() >= 2,
		rotulo + ": a caixa cresceu e mostra a ordem completa (%d figuras), a figura na vez primeiro e as outras pela ordem em que vão jogar" % ids.size())
	_ok(maus.is_empty() and cx.linhas_cortadas().is_empty(), rotulo + ": todos os nomes completos, sem corte %s" % [maus])
	var vez_l := lista.get_child(0)
	_ok(vez_l.has_node("Textos/NaVez") and lista.get_children().filter(func(x): return x.has_node("Textos/NaVez")).size() == 1
		and ((vez_l.get_node("Moldura") as PanelContainer).get_theme_stylebox("panel") as StyleBoxFlat).border_width_top == 3,
		rotulo + ": a figura na vez vem realçada como no cartão grande (moldura grossa, nome a ouro, «na vez»), e só ela")
	_ok(retratos == ids.size(), rotulo + ": todas as linhas têm o retrato da figura (%d de %d)" % [retratos, ids.size()])
	var tela := root.get_visible_rect()
	var barra := _arena.hud.get_node("Raiz/Seguro/Camadas/Barra") as Control
	var faixa := _arena.hud.get_node("Raiz/Seguro/Camadas/Faixa") as Control
	_ok(tela.encloses(r) and (not barra.visible or r.end.y <= barra.get_global_rect().position.y + 0.5) and not faixa.get_global_rect().intersects(r),
		rotulo + ": cabe no ecrã, acima da barra, sem tapar a faixa (%s)" % r)
	return r


## Abre a expandida com o rato por cima (eventos a sério); confere; grava; tira o rato e confere que volta à compacta.
func _rato_expandida(rotulo: String, captura: String) -> void:
	var cx := _cx()
	var r0 := cx.get_global_rect()
	var margens := Vector2((_arena.hud.get_node("Raiz/Seguro/Camadas/Faixa") as Control).offset_left, (_arena.hud.get_node("Raiz/Seguro/Camadas/Faixa") as Control).offset_right)
	_rato(r0.get_center())
	await _quadros(6)
	var r := _conferir_expandida(rotulo)
	var f := _arena.hud.get_node("Raiz/Seguro/Camadas/Faixa") as Control
	_ok(absf(r.end.x - r0.end.x) <= 0.5 and absf(r.position.y - r0.position.y) <= 0.5 and Vector2(f.offset_left, f.offset_right) == margens,
		rotulo + ": cresce para a esquerda e para baixo, encostada ao mesmo canto; a faixa não se mexe")
	_conferir_cores(rotulo)
	await _privacidade(rotulo)
	await _gravar(captura)
	_rato(_fora())
	await _quadros(4)
	_ok(not _caixa()["expandida"] and cx.get_global_rect().is_equal_approx(r0), rotulo + ": tirar o rato volta ao tamanho compacto (%s)" % cx.get_global_rect())


## Muda a janela para `tam` (px reais) e espera o HUD arrumar-se. Devolve false se a janela não ficou com esse tamanho.
func _janela_em(tam: Vector2i) -> bool:
	root.size = tam
	await _quadros(12)
	if root.size != tam:
		_ok(false, "%dx%d pedida, mas a janela ficou %dx%d: sem medida" % [tam.x, tam.y, root.size.x, root.size.y])
		return false
	_arena.hud._ao_redimensionar()
	await _quadros(8)
	return true


func _expande() -> void:
	_linha("== 6. (a) o rato por cima da caixa: a vista expandida (na janela da prova) ==")
	_conferir_compacta("6")
	await _rato_expandida("6", "6-rato-expandida.png")

	_linha("== 7. (b) 8+ figuras na vista expandida: o Mestre põe mais criaturas na luta e escolhe a iniciativa ==")
	var fichas: Array = []  # as fichas de criatura do cenário (as que o lobby deixa pôr)
	for cr in _cenario["criaturas"]:
		if not fichas.has(cr["fichaId"]):
			fichas.append(cr["fichaId"])
	var postas := 0
	var tentativas := 0
	for y in [16, 11, 17, 10, 15, 12]:
		for x in [6, 15, 8, 13, 4, 17]:
			if postas >= 5:
				break
			tentativas += 1
			if await _comando_b("MASTER_PLACE", {"fichaId": fichas[postas % fichas.size()], "casa": {"x": x, "y": y}}):
				postas += 1
	_ok(postas == 5, "7: o Mestre pôs 5 criaturas a mais na luta (%d tentativas de casa)" % tentativas)
	# Depois de as pôr: a escolha da caixa manda um snapshot novo à Party, que traz a ordem de iniciativa com elas (a
	# colocação a meio da luta, sozinha, não muda a `iniciativa` que a jogadora tem até ao snapshot seguinte).
	_ok(await _caixa_b(true, "iniciativa"), "7: o servidor aceitou (ligada, iniciativa)")
	_ok(await _esperar(func(): return (_caixa()["ids"] as Array).size() >= 8 and _caixa()["modo"] == "iniciativa", 15.0),
		"7: a caixa dela tem %d figuras na ordem de iniciativa do servidor" % (_caixa()["ids"] as Array).size())
	await _quadros(20)
	await _conferir_manequins("7")
	var c := _caixa()
	_linha("  caixa da jogadora: " + _descrever(c))
	_ok(c["ids"] == _estado.iniciativa and c["vez"] == _estado.vez_id, "7: a ordem e a vez são as do servidor (%d figuras)" % (c["ids"] as Array).size())
	_conferir_compacta("7")
	_conferir_cores("7")
	_conferir_quadradinhos("7")
	await _rato_expandida("7", "7-expandida-9-figuras.png")
	# O toque (aparelhos de toque, sem rato): um toque abre a mesma vista, outro fecha; um toque fora também fecha.
	var r0 := _cx().get_global_rect()
	_tocar(r0.get_center())
	await _quadros(4)
	var aberta: bool = _caixa()["expandida"] and (_caixa()["ordem_expandida"] as Array).size() == (c["ids"] as Array).size()
	_tocar(_cx().get_global_rect().get_center())
	await _quadros(4)
	var fechou: bool = not _caixa()["expandida"]
	_tocar(r0.get_center())
	await _quadros(4)
	_tocar(_fora())
	await _quadros(4)
	_ok(aberta and fechou and not _caixa()["expandida"],
		"7: no toque, um toque na caixa abre a mesma vista expandida, outro fecha, e um toque fora também fecha (%s/%s)" % [aberta, fechou])

	_linha("== 8. (c) a vista expandida num ecrã baixo, com %d figuras ==" % (_caixa()["ids"] as Array).size())
	for tam in [Vector2i(844, 390), Vector2i(780, 360)]:
		if not await _janela_em(tam):
			continue
		_linha("  escala HUD→janela %.4f (janela %dx%d, área do HUD %dx%d u)" % [_janela().x, root.size.x, root.size.y,
			int(root.get_visible_rect().size.x), int(root.get_visible_rect().size.y)])
		var rot := "8 %dx%d" % [tam.x, tam.y]
		_conferir_compacta(rot)
		var cx := _cx()
		_rato(cx.get_global_rect().get_center())
		await _quadros(6)
		_conferir_expandida(rot)
		var lista: Node = cx.find_child("Lista", true, false)
		var rol := cx.find_child("Expandida", true, false) as ScrollContainer
		var l0 := lista.get_child(0) as Control
		var sep := float(lista.get_theme_constant("separation"))
		var n := lista.get_child_count()
		var a_vista := n if not cx.expandida_rola() else int(floor((rol.size.y + sep + 0.5) / (l0.size.y + sep)))
		_linha("  MEDIDA EXPANDIDA %d figuras %dx%d: %d linhas de %d u (%d px reais), %d à vista sem rolar, rola %s" % [n, tam.x, tam.y, n, int(l0.size.y),
			roundi(l0.size.y * _janela().y), a_vista, "SIM" if cx.expandida_rola() else "NÃO"])
		await _gravar("8-expandida-%dx%d.png" % [tam.x, tam.y])
		if cx.expandida_rola():
			# Ordem CAIXA-EXPANDE-INTERACAO (D2): rola-se com a roda do rato a sério, em cima da lista (era
			# `scroll_vertical = max_value` posto pelo código). Mede-se a posição antes e no fim.
			var antes8 := rol.scroll_vertical
			var passos8 := await _rodar_ate_parar(rol.get_global_rect().get_center(), true)
			var max8 := int(rol.get_v_scroll_bar().max_value - rol.get_v_scroll_bar().page)
			var ul := lista.get_child(n - 1) as Control
			_linha("  MEDIDA RODA %s: lista %d → %d u (máximo %d u) em %d passos da roda" % [rot, antes8, rol.scroll_vertical, max8, passos8])
			_ok(antes8 == 0 and rol.scroll_vertical > 0 and rol.scroll_vertical == max8 and rol.get_global_rect().grow(0.5).encloses(ul.get_global_rect()),
				rot + ": a roda do rato rola a lista até ao fim (%d → %d u; a última figura à vista)" % [antes8, rol.scroll_vertical])
			await _gravar("8-expandida-%dx%d-fim.png" % [tam.x, tam.y])
			await _rodar_ate_parar(rol.get_global_rect().get_center(), false)
		_rato(_fora())
		await _quadros(4)
		_ok(not _caixa()["expandida"], rot + ": tirar o rato volta à compacta")

	_linha("== 9. (d) a recentragem da faixa (F4) com a caixa nova, nas 3 resoluções ==")
	for tam in [Vector2i(844, 390), Vector2i(780, 360), Vector2i(1920, 1080)]:
		if not await _janela_em(tam):
			continue
		var faixa := _arena.hud.get_node("Raiz/Seguro/Camadas/Faixa") as Label
		var tela := root.get_visible_rect()
		var rf := faixa.get_global_rect()
		var r := _cx().get_global_rect()
		var desvio := absf(rf.get_center().x - tela.get_center().x)
		var tecto: float = TectosCaixa.TECTO_DESVIO_8[tam]
		var precisa: float = _arena.hud.largura_faixa_precisa()
		_linha("  MEDIDA F4 %dx%d (%d figuras): caixa compacta %dx%d u · faixa %d u (precisa %d u), margens esq %d / dir %d u · desvio do centro %.1f u (tecto %.1f u) · faixa e caixa %s" % [
			tam.x, tam.y, (_caixa()["ids"] as Array).size(), int(r.size.x), int(r.size.y), int(rf.size.x), int(precisa), int(faixa.offset_left), int(-faixa.offset_right),
			desvio, tecto, "sobrepõem-se" if rf.intersects(r) else "não se tocam"])
		_ok(desvio <= tecto and not rf.intersects(r) and rf.size.x >= precisa,
			"9 %dx%d: a faixa fica o mais perto do centro que o espaço deixa — desvio %.1f u ≤ tecto %.1f u, numa linha, sem tocar na caixa" % [tam.x, tam.y, desvio, tecto])
		await _gravar("9-faixa-%dx%d.png" % [tam.x, tam.y])
	await _janela_em(Vector2i(1280, 720))


# ------------------------------------------------------------------ 11. Ordem CAIXA-EXPANDE-INTERACAO: os 3 gestos a sério

## Um passo da roda do rato a sério (carregar e largar), nas coordenadas do ecrã do HUD.
func _roda(p: Vector2, para_baixo: bool) -> void:
	for carregado in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_WHEEL_DOWN if para_baixo else MOUSE_BUTTON_WHEEL_UP
		e.pressed = carregado
		e.factor = 1.0
		e.position = p
		e.global_position = p
		root.push_input(e, true)


## Passos da roda (para baixo ou para cima) em `p` até a lista parar. Devolve quantos passos deu.
func _rodar_ate_parar(p: Vector2, para_baixo: bool) -> int:
	var rol := _cx().find_child("Expandida", true, false) as ScrollContainer
	var ultimo := -1
	var passos := 0
	while rol.scroll_vertical != ultimo and passos < 200:
		ultimo = rol.scroll_vertical
		_roda(p, para_baixo)
		passos += 1
		await _quadros(2)
	return passos


## Um toque pelo Input do motor (carrega e levanta no mesmo sítio): dado nas unidades do HUD, enviado em píxeis da
## janela. O motor imita o rato a partir dele e despacha esse rato antes do toque, como num aparelho de toque.
func _tocar_motor(p: Vector2) -> void:
	var px: Vector2 = root.get_final_transform() * p
	for k in 2:
		var t := InputEventScreenTouch.new()
		t.index = 0
		t.pressed = k == 0
		t.position = px
		Input.parse_input_event(t)
		Input.flush_buffered_events()
		await _quadros(1)


## O estado do tabuleiro que um toque pode mudar: onde estão as figuras (o nó em cena e a casa do Estado), o modo da
## arena (mover/atacar/…), a casa sob o cursor, os alvos e a última intenção enviada.
func _tabuleiro() -> Dictionary:
	var pos := {}
	for id in _arena._nos:
		var no: Node3D = _arena._nos[id]
		pos[id] = "%.2f,%.2f,%.2f" % [no.global_position.x, no.global_position.y, no.global_position.z]
	var casas := {}
	for id in _estado.figuras:
		var f: Dictionary = _estado.figuras[id]
		casas[str(id)] = "%s,%s" % [f.get("x"), f.get("y")]
	return {"nos": pos, "casas": casas, "modo": _arena.modo, "cursor": _arena._cursor, "alvos": _arena._alvos.size(),
		"item": _arena._item.size(), "ultima_intencao": _arena._ultimo_id}


## O Mestre põe criaturas na luta até a ordem ter `alvo` figuras (MASTER_PLACE em combate), e volta a escolher a
## iniciativa (o snapshot que leva a ordem nova à jogadora). Devolve quantas pôs.
func _por_ate(alvo: int) -> int:
	var fichas: Array = []
	for cr in _cenario["criaturas"]:
		if not fichas.has(cr["fichaId"]):
			fichas.append(cr["fichaId"])
	var falta := alvo - (_caixa()["ids"] as Array).size()
	var postas := 0
	for y in [5, 7, 9, 13, 14, 18, 4, 6, 8, 3, 19]:
		for x in [3, 5, 7, 9, 11, 14, 16, 18, 10, 12]:
			if postas >= falta:
				break
			if await _comando_b("MASTER_PLACE", {"fichaId": fichas[postas % fichas.size()], "casa": {"x": x, "y": y}}):
				postas += 1
	await _caixa_b(true, "iniciativa")
	await _esperar(func(): return (_caixa()["ids"] as Array).size() >= alvo, 15.0)
	await _quadros(20)
	return postas


func _interacao() -> void:
	_linha("== 11. Ordem CAIXA-EXPANDE-INTERACAO: a roda rola a lista; a roda nos fins não dá zoom; o toque fora deixa o tabuleiro quieto ==")
	var cam = _arena.camera
	var toques: Array = []
	cam.toque.connect(func(p: Vector2): toques.append(p))
	_linha("  ecrã de toque nesta máquina (DisplayServer.is_touchscreen_available): %s" % ("SIM" if DisplayServer.is_touchscreen_available() else "NÃO"))
	for alvo in [12, 16]:
		var postas := await _por_ate(alvo)
		var n := (_caixa()["ids"] as Array).size()
		_ok(n == alvo, "11: o Mestre pôs %d criaturas a mais; a caixa dela tem %d figuras (pedidas %d)" % [postas, n, alvo])
		await _conferir_manequins("11 %d" % n)
		for tam in [Vector2i(844, 390), Vector2i(780, 360)]:
			if not await _janela_em(tam):
				continue
			var rot := "11 %d figuras %dx%d" % [n, tam.x, tam.y]
			var cx := _cx()
			var rol := cx.find_child("Expandida", true, false) as ScrollContainer
			var lista: Node = cx.find_child("Lista", true, false)
			# D2 — a roda rola a lista (o rato por cima abre a expandida; a lista leva-se ao topo com a roda).
			_rato(cx.get_global_rect().get_center())
			await _quadros(6)
			var p := rol.get_global_rect().get_center()
			await _rodar_ate_parar(p, false)
			cam.definir_zoom(cam.ZOOM_PADRAO)
			await _quadros(2)
			var z0: float = cam.zoom
			var s0 := rol.scroll_vertical
			_roda(p, true)
			await _quadros(2)
			var s1 := rol.scroll_vertical
			var passos := await _rodar_ate_parar(p, true)
			var s_fim := rol.scroll_vertical
			var max_l := int(rol.get_v_scroll_bar().max_value - rol.get_v_scroll_bar().page)
			var ul := lista.get_child(lista.get_child_count() - 1) as Control
			var z_meio: float = cam.zoom
			_linha("  MEDIDA RODA %s: rola %s · lista %d u → 1 passo %d u → fim %d u (máximo %d u, %d passos) · zoom do tabuleiro %.3f → %.3f" % [
				rot, "SIM" if cx.expandida_rola() else "NÃO", s0, s1, s_fim, max_l, passos + 1, z0, z_meio])
			_ok(cx.expandida_rola() and s0 == 0 and s1 > 0 and s_fim == max_l and rol.get_global_rect().grow(0.5).encloses(ul.get_global_rect()),
				rot + ": [D2] a roda do rato rola a lista (%d → %d → %d u; a última figura à vista)" % [s0, s1, s_fim])
			await _gravar("11-roda-fim-%d-figuras-%dx%d.png" % [n, tam.x, tam.y])
			# D3 — no fim e no topo, a roda fica na caixa.
			_roda(p, true)
			await _quadros(3)
			var z_fim: float = cam.zoom
			var s_fim2 := rol.scroll_vertical
			await _rodar_ate_parar(p, false)
			var s_topo := rol.scroll_vertical
			_roda(p, false)
			await _quadros(3)
			var z_topo: float = cam.zoom
			var s_topo2 := rol.scroll_vertical
			_linha("  MEDIDA D3 %s: roda para baixo no fim: lista %d → %d u, zoom %.3f · roda para cima no topo: lista %d → %d u, zoom %.3f (antes %.3f)" % [
				rot, s_fim, s_fim2, z_fim, s_topo, s_topo2, z_topo, z0])
			_ok(s_fim2 == s_fim and s_topo == 0 and s_topo2 == 0 and z_meio == z0 and z_fim == z0 and z_topo == z0,
				rot + ": [D3] a roda no fim e no topo da lista não dá zoom ao tabuleiro (%.3f → %.3f no fim, %.3f no topo)" % [z0, z_fim, z_topo])
			# O arrastar com o botão do rato na lista: medido e registado (no PC sem ecrã de toque o motor não rola assim).
			var b := InputEventMouseButton.new()
			b.button_index = MOUSE_BUTTON_LEFT
			b.pressed = true
			b.position = p
			b.global_position = p
			root.push_input(b, true)
			var d := Vector2(0.0, -0.75 * rol.size.y)
			for k in 6:
				var m := InputEventMouseMotion.new()
				m.button_mask = MOUSE_BUTTON_MASK_LEFT
				m.position = p + d * float(k + 1) / 6.0
				m.global_position = m.position
				m.relative = d / 6.0
				root.push_input(m, true)
				await _quadros(1)
			var b2 := b.duplicate() as InputEventMouseButton
			b2.pressed = false
			b2.position = p + d
			b2.global_position = b2.position
			root.push_input(b2, true)
			await _quadros(3)
			_linha("  REGISTO ARRASTAR %s: ecrã de toque %s · arrastar com o rato na lista %d → %d u (não conta: é o que a plataforma faz)" % [
				rot, "SIM" if DisplayServer.is_touchscreen_available() else "NÃO", s_topo2, rol.scroll_vertical])
			await _rodar_ate_parar(p, false)
			# De controlo: a roda fora da caixa dá zoom ao tabuleiro (a câmara está a ouvir). O zoom volta ao padrão a seguir.
			_rato(_fora())
			await _quadros(4)
			_roda(_fora(), false)
			await _quadros(3)
			var z_ctl: float = cam.zoom
			cam.definir_zoom(cam.ZOOM_PADRAO)
			_ok(not is_equal_approx(z_ctl, z0), rot + ": [D3] de controlo, a roda fora da caixa dá zoom ao tabuleiro (%.3f → %.3f)" % [z0, z_ctl])
			await _quadros(6)
			# D1 — o toque fora que fecha a expandida deixa o tabuleiro quieto.
			await _tocar_motor(cx.get_global_rect().get_center())
			await _quadros(6)
			var abriu: bool = _caixa()["expandida"]
			await _gravar("11-toque-aberta-%d-figuras-%dx%d.png" % [n, tam.x, tam.y])
			var t0 := _tabuleiro()
			var n0 := toques.size()
			await _tocar_motor(_fora())
			await _quadros(10)
			var t1 := _tabuleiro()
			var disparou := toques.size() - n0
			var fechou: bool = not _caixa()["expandida"]
			_linha("  MEDIDA D1 %s: abriu por toque %s · toque fora em %s u: fechou %s · «toque» do tabuleiro %d vez(es) · toque armado na câmara %s · modo da arena %d → %d · figuras no mesmo sítio %s · casas do Estado iguais %s · cursor %s → %s · última intenção igual %s" % [
				rot, abriu, _fora(), fechou, disparou, cam._esq, t0["modo"], t1["modo"], t0["nos"] == t1["nos"], t0["casas"] == t1["casas"],
				t0["cursor"], t1["cursor"], t0["ultima_intencao"] == t1["ultima_intencao"]])
			_ok(abriu and fechou and disparou == 0 and not cam._esq and t0 == t1,
				rot + ": [D1] com a expandida aberta por toque, um toque fora fecha-a e o tabuleiro fica quieto (o «toque» não dispara; nenhuma figura movida nem seleccionada; nenhuma intenção enviada)")
			await _gravar("11-toque-fora-%d-figuras-%dx%d.png" % [n, tam.x, tam.y])
			# De controlo: com a caixa fechada, o mesmo toque chega ao tabuleiro. Só se a arena não estiver num modo que
			# o transforme num comando (modo NENHUM: o toque não escolhe casa nenhuma).
			if _arena.modo == 0:
				await _tocar_motor(_fora())
				await _quadros(6)
				_ok(toques.size() - n0 == 1 and _tabuleiro() == t1,
					rot + ": [D1] de controlo, com a caixa fechada o toque seguinte chega ao tabuleiro («toque» %d vez; a arena sem modo, nada muda)" % (toques.size() - n0))
			else:
				_linha("  (controlo do D1 saltado: a arena está no modo %d e o toque seria um comando)" % _arena.modo)
			# Ordem CAIXA-EXPANDE-VISTAS (D2): a barra de rolagem como é hoje, medida e fotografada (não se muda).
			await _barra(n, tam)
	await _janela_em(Vector2i(1280, 720))


# ------------------------------------------------------------------ 12. Ordem CAIXA-EXPANDE-VISTAS (D2): a barra como é hoje

## As linhas da lista agora: quantas estão inteiras dentro da vista dela e a primeira cortada pela borda (superior ou
## inferior: índice a contar de 1 e a fracção à vista).
func _linhas_vista(rol: ScrollContainer, lista: Node) -> Dictionary:
	var vr := rol.get_global_rect()
	var inteiras := 0
	var cortada := 0
	var fraccao := 0.0
	var k := 0
	for l in lista.get_children():
		k += 1
		var lr := (l as Control).get_global_rect()
		if vr.grow(0.5).encloses(lr):
			inteiras += 1
		elif vr.intersects(lr) and cortada == 0:
			cortada = k
			fraccao = vr.intersection(lr).size.y / lr.size.y
	return {"inteiras": inteiras, "cortada": cortada, "fraccao": fraccao}


## A captura de agora recortada na caixa (o rectângulo `r`, em unidades do HUD) e ampliada 3× ao píxel (sem filtro),
## para o olho ver a barra: é a mesma imagem da captura inteira, só recortada.
func _gravar_recorte(nome: String, r: Rect2) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if img == null or img.is_empty():
		_ok(false, nome + ": sem imagem (o render não correu)")
		return
	var px: Rect2 = root.get_final_transform() * r
	var ri := Rect2i(Vector2i(px.position.floor()), Vector2i(px.size.ceil())).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var rec := img.get_region(ri)
	rec.resize(ri.size.x * 3, ri.size.y * 3, Image.INTERPOLATE_NEAREST)
	var erro := rec.save_png(_saida.path_join(nome))
	_ok(erro == OK, "captura %s (recorte %d×%d px da janela, ampliado 3×)" % [nome, ri.size.x, ri.size.y])


## D2: com `n` figuras no ecrã `tam`, a expandida aberta pelo rato: a lista no topo (sem rolar: quantas linhas inteiras
## à vista, qual a cortada pela borda inferior), a meio (um passo da roda) e no fim; e a barra de rolagem DO TEMA, tal
## como é hoje: à vista ou não, a largura e a altura dela e o comprimento da pega, em unidades do HUD e em px reais.
## Captura inteira e recorte ampliado nos três sítios. Nada se muda na barra.
func _barra(n: int, tam: Vector2i) -> void:
	var rot := "12 %d figuras %dx%d" % [n, tam.x, tam.y]
	var cx := _cx()
	var rol := cx.find_child("Expandida", true, false) as ScrollContainer
	var lista: Node = cx.find_child("Lista", true, false)
	_rato(cx.get_global_rect().get_center())
	await _quadros(6)
	var p := rol.get_global_rect().get_center()
	await _rodar_ate_parar(p, false)
	await _quadros(2)
	var esc := _janela().x  # px reais por unidade do HUD
	var sb := rol.get_v_scroll_bar()
	var sr := sb.get_global_rect()
	var pega := 0.0
	if sb.max_value > 0.0:
		pega = sr.size.y * clampf(sb.page / sb.max_value, 0.0, 1.0)
	var topo := _linhas_vista(rol, lista)
	_linha("  MEDIDA BARRA %s: expandida %s · rola %s · lista no topo: %d de %d linhas inteiras à vista sem rolar · cortada pela borda inferior: linha %d (%.0f por cento à vista) · barra à vista %s · barra %.1f × %.1f u (%.1f × %.1f px reais) · pega %.1f u (%.1f px reais) · caixa %.0f × %.0f u" % [
		rot, _caixa()["expandida"], "SIM" if cx.expandida_rola() else "NÃO", topo["inteiras"], lista.get_child_count(), topo["cortada"],
		topo["fraccao"] * 100.0, "SIM" if sb.is_visible_in_tree() else "NÃO", sr.size.x, sr.size.y, sr.size.x * esc, sr.size.y * esc, pega, pega * esc,
		cx.size.x, cx.size.y])
	_ok(cx.expandida_rola() and topo["inteiras"] < lista.get_child_count() and rol.scroll_vertical == 0,
		rot + ": a lista no topo não mostra todas as figuras (%d de %d inteiras à vista sem rolar)" % [topo["inteiras"], lista.get_child_count()])
	await _gravar("12-barra-topo-%d-figuras-%dx%d.png" % [n, tam.x, tam.y])
	await _gravar_recorte("12-barra-topo-%d-figuras-%dx%d-recorte.png" % [n, tam.x, tam.y], cx.get_global_rect())
	_roda(p, true)
	await _quadros(3)
	var meio := _linhas_vista(rol, lista)
	_linha("  MEDIDA BARRA %s: um passo da roda: lista em %d u de %d u · %d linhas inteiras à vista · pega a %.1f u do topo da barra" % [
		rot, rol.scroll_vertical, int(sb.max_value - sb.page), meio["inteiras"],
		(sr.size.y - pega) * (float(rol.scroll_vertical) / maxf(1.0, sb.max_value - sb.page))])
	await _gravar("12-barra-meio-%d-figuras-%dx%d.png" % [n, tam.x, tam.y])
	await _gravar_recorte("12-barra-meio-%d-figuras-%dx%d-recorte.png" % [n, tam.x, tam.y], cx.get_global_rect())
	await _rodar_ate_parar(p, true)
	var fim := _linhas_vista(rol, lista)
	var ul := lista.get_child(lista.get_child_count() - 1) as Control
	var ultima := rol.get_global_rect().grow(0.5).encloses(ul.get_global_rect())
	_linha("  MEDIDA BARRA %s: no fim: lista em %d u · %d linhas inteiras à vista · a última figura inteira à vista %s · cortada pela borda superior: linha %d (%.0f por cento à vista)" % [
		rot, rol.scroll_vertical, fim["inteiras"], "SIM" if ultima else "NÃO", fim["cortada"], fim["fraccao"] * 100.0])
	_ok(ultima and rol.scroll_vertical == int(sb.max_value - sb.page), rot + ": no fim da lista a última figura está inteira à vista")
	await _gravar("12-barra-fim-%d-figuras-%dx%d.png" % [n, tam.x, tam.y])
	await _gravar_recorte("12-barra-fim-%d-figuras-%dx%d-recorte.png" % [n, tam.x, tam.y], cx.get_global_rect())
	await _rodar_ate_parar(p, false)
	_rato(_fora())
	await _quadros(6)


# ------------------------------------------------------------------ 13. Ordem F27: o D1 com o Mover aberto

## A casa da figura `id` na vista do Mestre (a do servidor), "x,y".
func _casa_servidor(id: String) -> String:
	var v := await _vista_b()
	for f in v.get("mestre", {}).get("figuras", []):
		if str(f.get("id", "")) == id:
			return "%d,%d" % [int(f.get("x", -1)), int(f.get("y", -1))]
	return "?"


## A condução: a IA de ensaio joga as vezes das outras figuras (a IA de ensaio: mover e encerrar) até ser a vez da
## jogadora do ecrã a sério; depois espera que as opções dela (o ROOM_OPTIONS com casas do Mover) cheguem ao aparelho.
## Se já é a vez dela mas o Mover se gastou, ela encerra (a mesma intenção do botão «Encerrar») e a volta segue.
func _ate_a_vez_dela(rotulo: String) -> bool:
	var dela: String = _jogadora["figuraId"]
	if _estado.e_minha_vez() and _estado.lista_opcao("mover").is_empty():
		_ok(_arena.enviar_acao({"tipo": "encerrar"}), rotulo + ": a vez dela sem casas do Mover: ela encerra")
		await _esperar(func(): return not _estado.e_minha_vez(), 10.0)
	var jogaram: Array = []
	for k in 40:
		var v := await _vista_b()
		if str(v.get("vezId", "")) == dela:
			break
		var quem := await _jogar_vez()
		if quem == "":
			break
		jogaram.append(_estado.nome_de(quem))
	var pronta := func(): return _estado.e_minha_vez() and not _estado.lista_opcao("mover").is_empty()
	var chegou := await _esperar(pronta, 15.0)
	await _quadros(10)
	_linha("  condução %s: o ensaio jogou %d vez(es) %s · vez de %s (rodada %s) · casa dela %s · casas do Mover no ROOM_OPTIONS %d · orçamento %.1f m" % [
		rotulo, jogaram.size(), JSON.stringify(jogaram), _estado.nome_de(_estado.vez_id), _estado.rodada,
		_estado.casa_de(_estado.figuras.get(dela)), _estado.lista_opcao("mover").size(), _estado.orcamento_m()])
	_ok(chegou, rotulo + ": a batalha chegou à vez da jogadora, com casas para onde mover (%d)" % _estado.lista_opcao("mover").size())
	return chegou


## O sítio do ecrã (unidades do HUD) de uma casa de destino do Mover que fica fora da caixa (`r`, a expandida aberta),
## da ⚙/ficha, da barra, da faixa e da gaveta: o centro da casa projectado pela câmara da arena, e só se a arena,
## com um toque aí, der essa mesma casa. Prefere a mais próxima de `_fora()`. Devolve [casa, sítio] ou [].
func _destino_fora(r: Rect2) -> Array:
	var hud = _arena.hud
	var evitar: Array = [r.grow(8.0)]
	for p in ["Raiz/Seguro/Camadas/ColunaEsquerda", "Raiz/Seguro/Camadas/Barra", "Raiz/Seguro/Camadas/Faixa"]:
		var no := hud.get_node(p) as Control
		if no.visible:
			evitar.append(no.get_global_rect().grow(8.0))
	if hud._gaveta.is_visible_in_tree():
		evitar.append((hud._gaveta as Control).get_global_rect().grow(8.0))
	var tela := root.get_visible_rect().grow(-12.0)
	var melhor: Array = []
	var dist := INF
	var casas: Array = _arena._casas.keys()
	casas.sort()
	for c in casas:
		var mundo: Vector3 = _arena.centro_casa(c)
		if _arena.camera.is_position_behind(mundo):
			continue
		var p: Vector2 = _arena.camera.unproject_position(mundo)
		if not tela.has_point(p) or evitar.any(func(e: Rect2): return e.has_point(p)) or _arena.casa_em_tela(p) != c:
			continue
		if p.distance_to(_fora()) < dist:
			dist = p.distance_to(_fora())
			melhor = [c, p]
	return melhor


## Espera que nenhum nó de figura se mexa durante 30 quadros seguidos (até 10 s). Devolve se assentou.
func _assentar() -> bool:
	var ultimo: Dictionary = _tabuleiro()["nos"]
	var quietos := 0
	var t := Time.get_ticks_msec()
	while quietos < 30 and Time.get_ticks_msec() - t < 10000:
		await _quadros(1)
		var agora: Dictionary = _tabuleiro()["nos"]
		quietos = quietos + 1 if agora == ultimo else 0
		ultimo = agora
	return quietos >= 30


## Os ROOM_EVENT «movimento» da figura da jogadora que chegaram ao aparelho dela desde a mensagem n.º `desde` de
## `_recebido`: a lista dos `para` ({x, y}).
func _movimentos_dela(desde: int) -> Array:
	var saida: Array = []
	for i in range(desde, _recebido.size()):
		var m = JSON.parse_string(_recebido[i])
		if not (m is Dictionary) or m.get("type") != "ROOM_EVENT" or m.get("tipo") != "movimento":
			continue
		var d = m.get("dados", {})
		if d is Dictionary and str(d.get("figuraId", "")) == _jogadora["figuraId"] and d.get("para") is Dictionary:
			saida.append(d["para"])
	return saida


func _mover_aberto() -> void:
	_linha("== 13. Ordem F27: o D1 com o Mover aberto — a vez da jogadora, o toque fora numa casa de destino ==")
	var dela: String = _jogadora["figuraId"]
	var cam = _arena.camera
	var toques: Array = []
	cam.toque.connect(func(p: Vector2): toques.append(p))
	var MOVER: int = _arena.Modo.MOVER
	var n := (_caixa()["ids"] as Array).size()
	for tam in [Vector2i(844, 390), Vector2i(780, 360)]:
		var rot := "13 %d figuras %dx%d" % [n, tam.x, tam.y]
		if not await _ate_a_vez_dela(rot):
			continue
		if not await _janela_em(tam):
			continue
		_rede.fila._itens.clear()  # as intenções de antes, já respondidas (a fila guarda-as): só contam as deste passo
		# O Mover aberto pelo botão da barra, por toque (a caixa fechada).
		var bm: Control = _arena.hud._b_mover
		await _tocar_motor(bm.get_global_rect().get_center())
		await _quadros(6)
		var mover_aberto: bool = _arena.modo == MOVER and not _arena._casas.is_empty()
		# A expandida aberta por toque.
		await _tocar_motor(_cx().get_global_rect().get_center())
		await _quadros(6)
		var c := _caixa()
		var aberta: bool = c["expandida"] and (c["ordem_expandida"] as Array).size() == n
		var destino := _destino_fora(_cx().get_global_rect())
		_linha("  Mover aberto pelo botão %s: modo %d · %d casas de destino · a dela em %s · expandida aberta por toque %s · sítio fora da caixa sobre uma casa de destino %s" % [
			mover_aberto, _arena.modo, _arena._casas.size(), _estado.casa_de(_estado.figuras.get(dela)), aberta, destino])
		_ok(_estado.e_minha_vez() and mover_aberto and aberta and not destino.is_empty(),
			rot + ": a vez da jogadora, o Mover aberto pelo botão, a expandida aberta por toque e um sítio fora dela que cai numa casa de destino %s" % [destino])
		if destino.is_empty():
			continue
		var casa: Vector2i = destino[0]
		var sitio: Vector2 = destino[1]
		await _gravar("13-mover-aberta-%d-figuras-%dx%d.png" % [n, tam.x, tam.y])
		# D1 — o toque fora, em cima da casa de destino. Antes de medir, o tabuleiro assenta: as figuras que o ensaio
		# acabou de mover acabam de andar (nenhum nó mexe durante 30 quadros seguidos; até 10 s).
		var assentou := await _assentar()
		var t0 := _tabuleiro()
		var r0 := _recebido.size()
		var f0: Array = (_rede.fila._itens as Dictionary).keys()
		var srv0: String = await _casa_servidor(dela)
		var n0 := toques.size()
		await _tocar_motor(sitio)
		var t := Time.get_ticks_msec()
		while Time.get_ticks_msec() - t < 2000:  # tempo para uma intenção ir e voltar, se tivesse saído
			await _quadros(1)
		var t1 := _tabuleiro()
		var f1: Array = (_rede.fila._itens as Dictionary).keys()
		var mov_d1 := _movimentos_dela(r0)
		var difs: Array = []
		for k in t0:
			if t0[k] != t1[k]:
				if k == "nos":
					for id in t0["nos"]:
						if t0["nos"][id] != t1["nos"].get(id):
							difs.append("nó de %s %s → %s" % [_estado.nome_de(str(id)), t0["nos"][id], t1["nos"].get(id)])
				else:
					difs.append("%s %s → %s" % [k, t0[k], t1[k]])
		var srv1: String = await _casa_servidor(dela)
		var fechou: bool = not _caixa()["expandida"]
		var disparou := toques.size() - n0
		_linha("  MEDIDA D1-MOVER %s: toque fora em %s u, sobre a casa de destino %s · ANTES: nó %s, casa (Estado) %s, casa (servidor) %s, modo %d, fila %d · DEPOIS: fechou %s, «toque» %d, nó %s, casa (Estado) %s, casa (servidor) %s, modo %d, fila %d, última intenção igual %s, cursor %s → %s, movimentos da jogadora recebidos %d · tabuleiro assentado antes %s · diferenças no tabuleiro inteiro %s" % [
			rot, sitio, casa, t0["nos"][dela], t0["casas"][dela], srv0, t0["modo"], f0.size(),
			fechou, disparou, t1["nos"][dela], t1["casas"][dela], srv1, t1["modo"], f1.size(), t0["ultima_intencao"] == t1["ultima_intencao"],
			t0["cursor"], t1["cursor"], mov_d1.size(), assentou, difs])
		_ok(fechou and disparou == 0 and t0 == t1 and t1["modo"] == MOVER and f1 == f0 and srv1 == srv0 and mov_d1.is_empty(),
			rot + ": [D1 com o Mover aberto] o toque fora sobre a casa %s fecha a expandida e a figura fica no sítio (nó, casa do Estado e casa do servidor iguais; o Mover ainda aberto; nenhuma intenção)" % [casa])
		await _gravar("13-mover-toque-fora-%d-figuras-%dx%d.png" % [n, tam.x, tam.y])
		# De controlo: com a caixa fechada, o mesmo toque escolhe a casa e a figura anda até ela.
		var r1 := _recebido.size()
		await _tocar_motor(sitio)
		var no_dela: Node3D = _arena._nos[dela]
		var alvo3: Vector3 = _arena.pe_figura(casa)
		var andou := await _esperar(func(): return _estado.casa_de(_estado.figuras.get(dela)) == casa, 10.0)
		var chegou := await _esperar(func(): return Vector2(no_dela.global_position.x - alvo3.x, no_dela.global_position.z - alvo3.z).length() < 0.05, 10.0)
		await _quadros(10)
		var t2 := _tabuleiro()
		var f2: Array = (_rede.fila._itens as Dictionary).keys()
		var novas: Array = f2.filter(func(id): return not f1.has(id))
		# A fila apaga o texto da intenção quando ela termina: o destino lê-se do que a jogadora recebeu do servidor,
		# o ROOM_EVENT «movimento» dela (o `para`).
		var mov_ctl := _movimentos_dela(r1)
		var para := Vector2i(-1, -1)
		if mov_ctl.size() >= 1:
			para = Vector2i(int(mov_ctl[0].get("x", -1)), int(mov_ctl[0].get("y", -1)))
		var srv2: String = await _casa_servidor(dela)
		_linha("  MEDIDA CONTROLO-MOVER %s: caixa fechada · o mesmo toque em %s u: «toque» %d · intenções novas %d · «movimento» da jogadora recebido do servidor %d, para %s · nó %s → %s · casa (Estado) %s → %s · casa (servidor) %s → %s · modo %d → %d" % [
			rot, sitio, toques.size() - n0, novas.size(), mov_ctl.size(), para, t1["nos"][dela], t2["nos"][dela],
			t1["casas"][dela], t2["casas"][dela], srv1, srv2, t1["modo"], t2["modo"]])
		_ok(toques.size() - n0 == 1 and novas.size() == 1 and mov_ctl.size() == 1 and para == casa and andou and chegou
			and srv2 == "%d,%d" % [casa.x, casa.y] and t2["nos"][dela] != t1["nos"][dela],
			rot + ": [D1 controlo] com a caixa fechada o mesmo toque chega ao tabuleiro, escolhe a casa %s e a figura anda até ela (Estado, servidor e nó)" % [casa])
		await _gravar("13-mover-controlo-%d-figuras-%dx%d.png" % [n, tam.x, tam.y])
	await _janela_em(Vector2i(1280, 720))


func _fim() -> void:
	_linha("")
	_linha("tamanhos medidos dos quadradinhos (px reais da janela) e os nomes À VISTA (B3), por momento:")
	for m in _medidas:
		_linha("  " + m)
	var cortadas := {}
	for k in _letras_vistas:
		cortadas[k] = true
	_linha("letras à vista por nome, em todos os momentos: %s (LADO_RETRATO_EM_LETRAS = %.1f; a escolha 7 ou 10 letras é do Mestre)" % [
		_letras_vistas, CaixaOrdem.LADO_RETRATO_EM_LETRAS])
	_linha("prova da caixa (expande, com os manequins): %d de %d verificações passaram." % [_total - _falhas, _total])
	for l in _herois.values():
		l.fechar()
	if _mestre_b != null:
		_mestre_b.fechar()
	await _quadros(5)
	quit(1 if _falhas > 0 or _total == 0 else 0)
