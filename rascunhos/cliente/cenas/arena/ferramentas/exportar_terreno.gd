extends SceneTree
## exportar_terreno.gd — Ordens 44 e 48. Escreve o TERRENO DO MAPA que o servidor lê
## (servidor/dados/terreno-floresta.json), a partir da arena DO JOGO, sem janela.
##
## Ordem 48: UMA SÓ FONTE PARA QUALQUER TAMANHO DE GRELHA. Até aqui o pacote levava 6 grelhas feitas (20 × 20 e
## 30 × 30 nas três escalas) e qualquer outro tamanho caía, no servidor, em «todas as casas se pisam». Agora o
## pacote leva o MAPA INTEIRO, e o servidor recorta dele a grelha viva (tamanho e escala). São três partes:
##
##   origens   para cada escala (1 / 1,5 / 2 m, REF_36), a origem no mapa (canto NO) de uma grelha de 1, 2, 3, …
##             casas de lado, até à maior que cabe no mapa de 50 × 50 casas de 1,5 m (75 m). É a regra da arena
##             (Assentamento.origem_no_mapa) tabelada: o servidor não a reescreve, lê-a. Uma grelha maior do que a
##             tabela não cabe no mapa: o servidor recusa-a com erro nomeado (TERRENO_GRELHA_FORA_DO_MAPA).
##   redes     as alturas, casa a casa, das MAIORES grelhas que cabem no mapa — uma por escala e por «fase» da
##             origem (com casas de 1 m, as grelhas de lado par têm os centros nos meios-metros e as de lado ímpar
##             nos metros; com 1,5 m a origem encosta-se sempre às linhas do mapa). Toda a grelha que cabe no mapa
##             é um recorte exacto de uma delas: os mesmos centros, logo as mesmas contas, os mesmos bits.
##             Por casa:
##               alturaM   altura do relevo no centro da casa (arena.centro_casa);
##               peM       altura da base de uma figura nessa casa (arena.pe_figura: a base inclinada da Ordem 44);
##             e, por coluna e por linha, a casa do mapa que contém o centro (Assentamento.casa_do_mapa).
##             As alturas vão em base64 dos doubles (IEEE-754, little-endian, linha a linha): o servidor lê
##             exactamente o double que o cliente calcula, sem passar por texto decimal.
##   mapa      o que BLOQUEIA (e porquê) e a COBERTURA das 50 × 50 casas do mapa, lidos do mapa construído para a
##             zona de REFERÊNCIA (abaixo).
##
## PORQUE É QUE O BLOQUEIO SE RECORTA DE UM SÓ MAPA. O mapa da arena é construído para a zona jogável (Ordem
## 42): dentro dela não planta árvores, rochas nem estrato, e corta o tronco tombado antes dela; o que fica fora é
## posto como sempre. Logo o mapa muda com a zona. Mas o que BLOQUEIA uma casa DENTRO da zona não muda: os marcos
## (menires, santuário, lanternas), a água funda e a escarpa são do relevo e do gerador dos marcos (semente própria),
## não da zona; e o que a zona tira só bloqueia longe dela (uma árvore, uma rocha ou o tronco só sobrevivem a mais
## do que o raio deles da borda — medido em 42 zonas pela sonda da Ordem 48: 0 casas com bloqueio ou motivo
## diferente). A zona de REFERÊNCIA é maior do que o mapa (4,5 m de folga a toda a volta): nada removível chega a
## uma casa do mapa, e o que fica é exactamente o que bloqueia dentro de QUALQUER zona.
## ORDEM LAGO-MAIOR (Parte 2): a zona viva deixou de decidir a decoração — o mapa só a tira do CAMPO DA ORDEM 42 (o
## quadrado fixo de 30 × 30 m do meio, campo_floresta.CAMPO_ORDEM_42), com qualquer zona. O mapa de referência passa
## a ter a floresta de fora desse campo: as casas de tronco e de rocha vão no pacote como BLOQUEADAS («tronco»,
## «rocha»), como os marcos; o estrato não bloqueia. E a «água funda» é a do lago novo (onde não se faz pé), não a do
## charco da Ordem 38.
##
## A COBERTURA NA BORDA. A cobertura de uma casa dentro da zona também vem de coisas FORA dela (uma árvore logo
## fora dá meia cobertura à casa vizinha), e o que fica fora depende da zona (o gerador gasta a semente de outra
## maneira quando a zona tira coisas). Por isso a cobertura só é servida nas casas cujo centro está a mais de
## BORDA_COBERTURA_M da borda da zona: o maior alcance de uma cobertura vinda de fora (rocha: 0,85 × tam + 1,6 m de
## alcance contra 0,9 × tam + 0,25 m de folga → até 1,35 m para dentro; árvore: 1,30 m; tronco tombado: 1,15 m).
## Nas casas da faixa da borda o servidor diz que não sabe (null), com nome — nunca um número errado.
##
## A FRONTEIRA DO MAPA (Ordem 59). Um lado da zona que está na fronteira do mapa (a folga entre ele e a fronteira é
## de no máximo FOLGA_FONTE_COBERTURA_M) não traz cobertura de fora: tudo o que dá cobertura e muda com a zona só
## conta se estiver numa casa DO MAPA (árvore: `Grelha.casa_em != FORA`; rocha: idem; estrato: `dar_cobertura` só
## dentro; a cobertura do tronco tombado não passa de x = −19,5 m nem de z = 32,4 m) e só sobrevive a mais de
## FOLGA_FONTE_COBERTURA_M fora da zona (o menor raio de sobrevivência entre as fontes: rocha de 0,5 m,
## 0,9 × 0,5 + 0,25 = 0,70 m; estrato 0,925 m; árvore raio + 0,75 m). Logo, do lado da fronteira, não há fonte:
## a cobertura das casas cuja faixa só toca lados na fronteira é a do mapa de referência, como no interior.
## O servidor só cala (null) a faixa dos lados ABERTOS (os que têm mapa para lá de FOLGA_FONTE_COBERTURA_M).
##
## Nada se escreve à mão: os números saem das mesmas funções com que a arena desenha (cenas/arena/assentamento.gd,
## o Relevo e a grelha do mapa).
##
##   godot --headless --path cliente -s res://cenas/arena/ferramentas/exportar_terreno.gd [-- --conferir]
## Sem argumentos escreve o ficheiro; com --conferir não escreve: refaz tudo e compara com o ficheiro do
## repositório — sai com 0 e «EM DIA», ou com 1 e o porquê, nomeado (TERRENO_DESACTUALIZADO: que fontes mudaram
## e que partes do pacote diferem). O script local servidor/ferramentas/conferir-terreno.mjs corre isto.

const CENA := "res://cenas/arena/arena.tscn"
const Assentamento := preload("res://cenas/arena/assentamento.gd")
const GrelhaMapa := preload("res://mapa/floresta/grelha_floresta.gd")

const FORMATO := "terreno/2"
## As escalas que valem (REF_36, servidor ESCALAS_CASA_M).
const ESCALAS := [1.0, 1.5, 2.0]
## A grelha cuja zona é a de referência para o bloqueio e a cobertura: 56 × 56 casas de 1,5 m = 84 m, centrada,
## 4,5 m além do mapa de 75 m a toda a volta.
const REFERENCIA := [56, 56, 1.5]
## A folga mínima da zona de referência para lá do mapa (m). O maior alcance para fora do que a zona tira é o de
## uma rocha de 2,4 m (0,9 × 2,4 + 0,25 = 2,41 m) e a cobertura dela chega 1,35 m mais longe.
const FOLGA_REFERENCIA_M := 4.0
## A faixa da borda onde a cobertura não se serve (m, distância do centro da casa do mapa à borda da zona).
const BORDA_COBERTURA_M := 1.35
## Ordem 59: a folga (m) entre um lado da zona e a fronteira do mapa até à qual esse lado não traz cobertura de fora
## (a menor distância a que uma fonte de cobertura sobrevive fora da zona: rocha de 0,5 m, 0,9 × 0,5 + 0,25).
const FOLGA_FONTE_COBERTURA_M := 0.70
## Os ficheiros de que o terreno depende (o relevo, a grelha do mapa, o que o mapa põe e bloqueia, a regra do
## assentamento e este exportador, que decide a forma do pacote, a zona de referência e a faixa da borda). O SHA de
## cada um (texto com fins de linha LF) vai no pacote: se um mudar sem se refazer o terreno, o teste do cliente
## (rodar_testes) fica vermelho e o conferir-terreno diz que fonte foi.
const FONTES := ["res://mapa/floresta/relevo_floresta.gd", "res://mapa/floresta/grelha_floresta.gd",
	"res://mapa/floresta/campo_floresta.gd", "res://mapa/floresta/formas_floresta.gd",
	"res://cenas/arena/assentamento.gd", "res://cenas/arena/ferramentas/exportar_terreno.gd"]


static func caminho_saida() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../servidor/dados/terreno-floresta.json").simplify_path()


static func sha_fontes() -> Dictionary:
	var r := {}
	for f in FONTES:
		r[String(f).trim_prefix("res://")] = FileAccess.get_file_as_string(f).replace("\r\n", "\n").sha256_text()
	return r


## O retângulo do mapa (50 × 50 casas de 1,5 m) no mundo.
static func rect_mapa() -> Rect2:
	return Rect2(-GrelhaMapa.MEIO, -GrelhaMapa.MEIO, GrelhaMapa.LADO * GrelhaMapa.CASA_M, GrelhaMapa.LADO * GrelhaMapa.CASA_M)


## A origem (x) de uma grelha de `n` casas de lado na escala `s`: a regra da arena (a mesma para x e z).
static func origem_lado(n: int, s: float) -> float:
	return Assentamento.origem_no_mapa(Vector2(n * s, n * s), s).x


## As origens das grelhas de 1, 2, … casas de lado que cabem no mapa, nesta escala. Pára na primeira que não cabe
## (e confere que nenhuma maior volta a caber: o servidor serve exactamente os lados 1..tamanho da tabela).
static func origens(s: float) -> Array:
	var m := rect_mapa()
	var r: Array = []
	var n := 1
	while true:
		var o := origem_lado(n, s)
		if o < m.position.x or o + n * s > m.end.x:
			break
		r.append(o)
		n += 1
	for k in range(n, n + 40):
		var o := origem_lado(k, s)
		assert(o < m.position.x or o + k * s > m.end.x, "a grelha de %d casas de %s m volta a caber no mapa" % [k, s])
	return r


## As redes de um eixo, para uma escala: [[lado, origem], ...]. A maior grelha abre uma rede; cada grelha menor é
## um recorte de uma rede já aberta (a origem dela cai num centro de casa da rede, a um número inteiro de casas) ou
## abre outra. Com 1,5 m há uma; com 1 m e 2 m há duas (lado par e lado ímpar).
static func redes_eixo(s: float) -> Array:
	var tab := origens(s)
	var redes: Array = []
	for i in range(tab.size() - 1, -1, -1):
		var n := i + 1
		var o: float = tab[i]
		var cabe := false
		for r in redes:
			var k := (o - float(r[1])) / s
			if k == floorf(k) and k >= 0.0 and int(k) + n <= int(r[0]):
				cabe = true
				break
		if not cabe:
			redes.append([n, o])
	return redes


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


var _arena: Node = null
var _seq := 0


## Abre (ou refaz) a arena do jogo com uma grelha deste tamanho e escala, como um snapshot do servidor faria.
func _abrir(w: int, h: int, s: float) -> Node:
	_seq += 1
	root.get_node("/root/Estado").aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "terreno-48", "seq": _seq,
		"revision": _seq, "fase": "combate", "mapa": {"largura": w, "altura": h, "casaM": s}, "figuras": [],
		"vezId": null, "ambiente": {}})
	if _arena == null:
		_arena = (load(CENA) as PackedScene).instantiate()
		root.add_child(_arena)
	for i in 3:
		await process_frame
	if _arena.largura != w or _arena.altura != h or not is_equal_approx(_arena.casa_m, s):
		push_error("a arena não abriu a grelha %d×%d de %s m" % [w, h, s])
		return null
	return _arena


func _correr() -> void:
	var conferir := OS.get_cmdline_user_args().has("--conferir")
	root.get_node("/root/Rede")._ativo = true
	var partes := {}
	# 1. o mapa de referência: o que bloqueia e a cobertura, das 50 × 50 casas
	var a = await _abrir(REFERENCIA[0], REFERENCIA[1], REFERENCIA[2])
	if a == null:
		quit(1)
		return
	if not a.mapa.zona_jogo.grow(-FOLGA_REFERENCIA_M).encloses(rect_mapa()):
		push_error("a zona de referência %s não deixa %s m de folga à volta do mapa" % [a.mapa.zona_jogo, FOLGA_REFERENCIA_M])
		quit(1)
		return
	var zona_ref: Rect2 = a.mapa.zona_jogo
	partes["mapa"] = mapa_da_arena(a)
	print("mapa de referência (zona %s): %d casas bloqueadas, %d com cobertura" % [a.mapa.zona_jogo,
		(partes["mapa"]["bloqueadas"] as Array).count(1), (partes["mapa"]["cobertura"] as Array).size() - (partes["mapa"]["cobertura"] as Array).count(0)])
	# 2. as origens e as redes de cada escala
	var escalas: Array = []
	var redes: Array = []
	for s in ESCALAS:
		var tab := origens(s)
		escalas.append({"casaM": s, "origensM": tab})
		var eixo := redes_eixo(s)
		for rx in eixo:
			for rz in eixo:
				a = await _abrir(int(rx[0]), int(rz[0]), s)
				if a == null or not is_equal_approx(a.origem.x, float(rx[1])) or not is_equal_approx(a.origem.y, float(rz[1])):
					push_error("a arena não pôs a rede %d×%d de %s m onde a regra diz" % [rx[0], rz[0], s])
					quit(1)
					return
				var rede = rede_da_arena(a)
				if rede == null:
					quit(1)
					return
				redes.append(rede)
				print("rede %d×%d de %s m: origem (%s, %s)" % [a.largura, a.altura, s, a.origem.x, a.origem.y])
		print("escala %s m: grelhas de 1 a %d casas de lado; %d rede(s) por eixo" % [s, tab.size(), eixo.size()])
	partes["escalas"] = escalas
	partes["redes"] = redes
	var cab := {"formato": FORMATO, "mapa": "floresta",
		"geradoPor": "cliente/cenas/arena/ferramentas/exportar_terreno.gd (Ordens 44, 48 e 59)",
		"nota": "Gerado: não editar à mão. Refazer com a ferramenta sempre que o relevo, o mapa ou a regra do assentamento mudarem; conferir com servidor/ferramentas/conferir-terreno.mjs.",
		"casasDoMapa": {"lado": GrelhaMapa.LADO, "casaM": GrelhaMapa.CASA_M, "origemM": [-GrelhaMapa.MEIO, -GrelhaMapa.MEIO]},
		"zonaReferenciaM": [zona_ref.position.x, zona_ref.position.y, zona_ref.size.x, zona_ref.size.y],
		"bordaCoberturaM": BORDA_COBERTURA_M, "folgaFonteCoberturaM": FOLGA_FONTE_COBERTURA_M,
		"codificacao": "redes[].alturaM e peM: base64 dos doubles IEEE-754 little-endian, linha a linha (de norte para sul, x a crescer para leste)",
		"fontes": sha_fontes()}
	var texto := montar_texto(cab, partes)
	var caminho := caminho_saida()
	if conferir:
		quit(_conferir(caminho, texto))
		return
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_string(texto)
	f.close()
	print("escrito: %s (%d bytes, %d redes)" % [caminho, texto.length(), redes.size()])
	quit(0)


## O texto do pacote: uma linha por parte (e por rede), para o diff dizer o que mudou.
static func montar_texto(cab: Dictionary, partes: Dictionary) -> String:
	var linhas_redes: Array[String] = []
	for r in partes["redes"]:
		linhas_redes.append(JSON.stringify(r, "", false, true))
	var linhas_escalas: Array[String] = []
	for e in partes["escalas"]:
		linhas_escalas.append(JSON.stringify(e, "", false, true))
	return "{\n\"cabecalho\": %s,\n\"escalas\": [\n%s\n],\n\"mapa\": %s,\n\"redes\": [\n%s\n]\n}\n" % [
		JSON.stringify(cab, "", false, true), ",\n".join(linhas_escalas), JSON.stringify(partes["mapa"], "", false, true),
		",\n".join(linhas_redes)]


## --conferir: 0 se o pacote do repositório é o que o cliente gera hoje; senão 1, com o porquê nomeado.
func _conferir(caminho: String, texto: String) -> int:
	var antigo := FileAccess.get_file_as_string(caminho).replace("\r\n", "\n")
	if antigo == texto:
		print("terreno do servidor EM DIA: %s" % caminho)
		return 0
	var porque: Array[String] = []
	var velho = JSON.parse_string(antigo)
	if not velho is Dictionary:
		porque.append("o pacote do repositório não se lê (%s)" % ("ficheiro em falta" if antigo == "" else "JSON inválido"))
	else:
		var cab_velho: Dictionary = velho.get("cabecalho", {})
		if String(cab_velho.get("formato", "")) != FORMATO:
			porque.append("formato %s, esperado %s" % [cab_velho.get("formato", "?"), FORMATO])
		var fontes_velhas: Dictionary = cab_velho.get("fontes", {})
		var hoje := sha_fontes()
		for fo in hoje:
			if String(fontes_velhas.get(fo, "")) != String(hoje[fo]):
				porque.append("a fonte %s mudou desde a exportação" % fo)
		for fo in fontes_velhas:
			if not hoje.has(fo):
				porque.append("a fonte %s já não conta" % fo)
		var novo = JSON.parse_string(texto)
		for parte in ["escalas", "mapa", "redes"]:
			if JSON.stringify(velho.get(parte)) != JSON.stringify(novo.get(parte)):
				porque.append("a parte «%s» do pacote difere do que o cliente gera hoje" % parte)
		if porque.is_empty():
			porque.append("o texto do pacote difere (cabeçalho ou arrumação)")
	print("TERRENO_DESACTUALIZADO: %s" % caminho)
	for p in porque:
		print("  - %s" % p)
	print("  refazer: godot --headless --path cliente -s res://cenas/arena/ferramentas/exportar_terreno.gd")
	return 1


## O mapa (50 × 50 casas de 1,5 m) que a arena tem construído: bloqueio, motivo e cobertura, linha a linha.
static func mapa_da_arena(a) -> Dictionary:
	var g = a.mapa.grelha
	var bloq: Array = []
	var cob: Array = []
	var motivos := {}
	for l in GrelhaMapa.LADO:
		for c in GrelhaMapa.LADO:
			var casa := Vector2i(c, l)
			var b: int = 1 if g.bloqueada(casa) else 0
			bloq.append(b)
			cob.append(g.cobertura(casa))
			if b == 1:
				motivos["%d,%d" % [c, l]] = g.motivo_bloqueio(casa)
	return {"lado": GrelhaMapa.LADO, "bloqueadas": bloq, "cobertura": cob, "motivos": motivos}


## Uma rede: a grelha que a arena tem aberta, casa a casa (linha a linha, de cima para baixo), com a casa do mapa
## de cada coluna e de cada linha. null (e erro) se a casa do mapa não for separável por coluna e linha ou cair
## fora do mapa — o servidor recorta por coluna e linha.
static func rede_da_arena(a) -> Variant:
	var alturas := PackedFloat64Array()
	var pes := PackedFloat64Array()
	var colunas: Array = []
	var linhas: Array = []
	for x in a.largura:
		colunas.append(Assentamento.casa_do_mapa(a.origem, a.casa_m, Vector2i(x, 0)).x)
	for y in a.altura:
		linhas.append(Assentamento.casa_do_mapa(a.origem, a.casa_m, Vector2i(0, y)).y)
	for y in a.altura:
		for x in a.largura:
			var c := Vector2i(x, y)
			alturas.append(a.centro_casa(c).y)
			pes.append(a.pe_figura(c).y)
			var cm := Assentamento.casa_do_mapa(a.origem, a.casa_m, c)
			if cm != Vector2i(int(colunas[x]), int(linhas[y])) or not GrelhaMapa.dentro(cm):
				push_error("rede %d×%d de %s m: a casa (%d,%d) cai na casa do mapa %s" % [a.largura, a.altura, a.casa_m, x, y, cm])
				return null
	return {"casaM": a.casa_m, "largura": a.largura, "altura": a.altura, "origemM": [a.origem.x, a.origem.y],
		"colunaMapa": colunas, "linhaMapa": linhas,
		"alturaM": Marshalls.raw_to_base64(alturas.to_byte_array()), "peM": Marshalls.raw_to_base64(pes.to_byte_array())}
