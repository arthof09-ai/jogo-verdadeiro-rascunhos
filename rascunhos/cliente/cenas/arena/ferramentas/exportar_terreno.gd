extends SceneTree
## exportar_terreno.gd — Ordem 44 (parte A). Escreve o TERRENO DO MAPA que o servidor lê
## (servidor/dados/terreno-floresta.json), a partir da arena DO JOGO, sem janela.
##
## Uma só fonte de verdade: para cada grelha (largura × altura × casaM), a ferramenta abre a arena com um
## snapshot desse tamanho (o mapa refaz-se para a zona, como em jogo) e lê, casa a casa, o que a arena
## desenha — com as mesmas funções (cenas/arena/assentamento.gd e grelha_floresta.gd):
##   alturaM     altura do relevo no centro da casa (arena.centro_casa);
##   peM         altura da base de uma figura nessa casa (arena.pe_figura: a base inclinada, parte B);
##   bloqueadas  1 se a casa do mapa debaixo do centro está bloqueada (menir, santuário, rocha, tronco,
##               água funda, escarpa…), com o motivo em `motivos`;
##   cobertura   0 nenhuma, 1 meia, 2 total (a do mapa).
## Os números saem em precisão inteira (JSON com 17 algarismos): o servidor lê exactamente o double que o
## cliente calcula. Nada se escreve à mão.
##
##   godot --headless --path cliente -s res://cenas/arena/ferramentas/exportar_terreno.gd [-- --conferir]
## Sem argumentos escreve o ficheiro; com --conferir não escreve: refaz tudo e compara com o ficheiro do
## repositório (sai com 1 se o ficheiro estiver desactualizado).

const CENA := "res://cenas/arena/arena.tscn"
const Assentamento := preload("res://cenas/arena/assentamento.gd")
const GrelhaMapa := preload("res://mapa/floresta/grelha_floresta.gd")

## As grelhas exportadas: a de sempre (20 × 20) e a maior (30 × 30), nas três escalas que valem (REF_36).
const GRELHAS := [[20, 20, 1.5], [30, 30, 1.5], [20, 20, 1.0], [20, 20, 2.0], [30, 30, 1.0], [30, 30, 2.0]]
## Os ficheiros de que o terreno depende (o relevo, a grelha do mapa, o que o mapa põe e bloqueia, a regra do
## assentamento). O SHA de cada um (texto com fins de linha LF) vai no pacote: se um mudar sem se refazer o
## terreno, o teste do cliente (rodar_testes) fica vermelho.
const FONTES := ["res://mapa/floresta/relevo_floresta.gd", "res://mapa/floresta/grelha_floresta.gd",
	"res://mapa/floresta/campo_floresta.gd", "res://mapa/floresta/formas_floresta.gd",
	"res://cenas/arena/assentamento.gd"]


static func caminho_saida() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../servidor/dados/terreno-floresta.json").simplify_path()


static func sha_fontes() -> Dictionary:
	var r := {}
	for f in FONTES:
		r[String(f).trim_prefix("res://")] = FileAccess.get_file_as_string(f).replace("\r\n", "\n").sha256_text()
	return r


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _correr() -> void:
	var conferir := OS.get_cmdline_user_args().has("--conferir")
	root.get_node("/root/Rede")._ativo = true
	var est = root.get_node("/root/Estado")
	var arena: Node = null
	var linhas: Array[String] = []
	var seq := 0
	for g in GRELHAS:
		seq += 1
		est.aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "terreno-44", "seq": seq, "revision": seq,
			"fase": "combate", "mapa": {"largura": g[0], "altura": g[1], "casaM": g[2]}, "figuras": [],
			"vezId": null, "ambiente": {}})
		if arena == null:
			arena = (load(CENA) as PackedScene).instantiate()
			root.add_child(arena)
		for i in 3:
			await process_frame
		if arena.largura != g[0] or arena.altura != g[1] or not is_equal_approx(arena.casa_m, g[2]):
			push_error("a arena não abriu a grelha %s" % [g])
			quit(1)
			return
		linhas.append(JSON.stringify(grelha_da_arena(arena), "", false, true))
		print("grelha %d×%d de %s m: origem (%s, %s); %d casas bloqueadas" % [g[0], g[1], g[2], arena.origem.x, arena.origem.y,
			(grelha_da_arena(arena)["bloqueadas"] as Array).count(1)])
	var cab := {"formato": "terreno/1", "mapa": "floresta",
		"geradoPor": "cliente/cenas/arena/ferramentas/exportar_terreno.gd (Ordem 44)",
		"nota": "Gerado: não editar à mão. Refazer com a ferramenta sempre que o relevo, o mapa ou a regra do assentamento mudarem.",
		"fontes": sha_fontes()}
	var texto := "{\n\"cabecalho\": %s,\n\"grelhas\": [\n%s\n]\n}\n" % [JSON.stringify(cab, "", false), ",\n".join(linhas)]
	var caminho := caminho_saida()
	if conferir:
		var antigo := FileAccess.get_file_as_string(caminho).replace("\r\n", "\n")
		var igual := antigo == texto
		print("terreno do servidor %s: %s" % ["EM DIA" if igual else "DESACTUALIZADO", caminho])
		quit(0 if igual else 1)
		return
	DirAccess.make_dir_recursive_absolute(caminho.get_base_dir())
	var f := FileAccess.open(caminho, FileAccess.WRITE)
	f.store_string(texto)
	f.close()
	print("escrito: %s (%d bytes, %d grelhas)" % [caminho, texto.length(), linhas.size()])
	quit(0)


## O terreno da grelha que a arena tem aberta, casa a casa (linha a linha, de cima para baixo).
static func grelha_da_arena(arena) -> Dictionary:
	var g = arena.mapa.grelha
	var alturas: Array = []
	var pes: Array = []
	var bloq: Array = []
	var cob: Array = []
	var motivos := {}
	for y in arena.altura:
		for x in arena.largura:
			var c := Vector2i(x, y)
			alturas.append(arena.centro_casa(c).y)
			pes.append(arena.pe_figura(c).y)
			var cm := Assentamento.casa_do_mapa(arena.origem, arena.casa_m, c)
			var b: int = 1 if g.bloqueada(cm) else 0
			bloq.append(b)
			cob.append(g.cobertura(cm))
			if b == 1:
				motivos["%d,%d" % [x, y]] = g.motivo_bloqueio(cm)
	return {"largura": arena.largura, "altura": arena.altura, "casaM": arena.casa_m,
		"origemM": [arena.origem.x, arena.origem.y],
		"alturaM": alturas, "peM": pes, "bloqueadas": bloq, "cobertura": cob, "motivos": motivos}
