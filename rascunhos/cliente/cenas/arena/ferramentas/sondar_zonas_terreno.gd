extends SceneTree
## sondar_zonas_terreno.gd — Ordem 48. A SONDA que sustenta o recorte do terreno no servidor.
##
## O mapa da arena é construído para a zona jogável (Ordem 42: dentro dela não se plantam árvores, rochas nem
## estrato, e o tronco tombado é cortado antes dela), por isso muda com o tamanho e a escala da grelha. O servidor
## recorta o bloqueio, os motivos e a cobertura de UM só mapa — o construído para a zona de referência do
## exportador (56 × 56 casas de 1,5 m, maior do que o mapa). Esta sonda constrói o mapa de verdade para muitas
## zonas e confere, em cada casa do jogo, a casa do mapa debaixo do centro:
##   bloqueio e motivo   iguais aos do mapa de referência (em todas as casas);
##   cobertura           igual à do mapa de referência longe da borda (centro da casa do mapa a mais de
##                       BORDA_COBERTURA_M da borda) e onde a referência dá 2 (é o que o servidor afirma); na faixa
##                       da borda conta-se quantas casas o cliente tem diferente (o porquê do null do servidor).
##
##   godot --headless --path cliente -s res://cenas/arena/ferramentas/sondar_zonas_terreno.gd [-- --json=caminho]
## Sai com 0 se nenhuma zona contradiz o recorte, 1 se alguma contradiz. ~3 s por zona.

const CENA := "res://cenas/arena/arena.tscn"
const Assentamento := preload("res://cenas/arena/assentamento.gd")
const GrelhaMapa := preload("res://mapa/floresta/grelha_floresta.gd")
const Exportar := preload("res://cenas/arena/ferramentas/exportar_terreno.gd")

## As zonas da sonda da Ordem 48 (largura, altura, casaM): as 6 do pacote antigo, a 25 × 25 nas três escalas,
## pequenas, grandes, até ao mapa todo e além dele, quadradas e não, lados pares e ímpares.
const ZONAS := [[50, 50, 1.5], [20, 20, 1.5], [25, 25, 1.5], [30, 30, 1.5], [10, 10, 1.5], [12, 12, 1.5], [16, 16, 1.5],
	[40, 40, 1.5], [49, 49, 1.5], [25, 25, 1.0], [25, 25, 2.0], [20, 20, 1.0], [30, 30, 2.0], [21, 17, 1.0], [33, 27, 2.0],
	[37, 37, 1.5], [15, 15, 1.5], [60, 60, 1.0], [37, 37, 2.0], [11, 11, 1.0], [8, 8, 2.0], [13, 29, 1.0], [45, 45, 1.5],
	[51, 51, 1.5], [70, 70, 1.0], [44, 44, 2.0], [23, 23, 1.0], [27, 19, 1.5], [35, 35, 2.0], [18, 18, 2.0], [5, 5, 1.5],
	[1, 1, 1.0], [46, 46, 1.5], [41, 41, 1.5], [44, 20, 1.5], [26, 26, 1.5], [24, 24, 1.5], [22, 22, 1.5], [28, 28, 1.0],
	[34, 34, 1.0], [31, 31, 2.0], [19, 19, 2.0]]

var _seq := 0
var _arena: Node = null


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _abrir(w: int, h: int, s: float) -> Node:
	_seq += 1
	root.get_node("/root/Estado").aplicar_snapshot({"v": 2, "type": "ROOM_SNAPSHOT", "roomId": "sonda-48", "seq": _seq,
		"revision": _seq, "fase": "combate", "mapa": {"largura": w, "altura": h, "casaM": s}, "figuras": [], "vezId": null, "ambiente": {}})
	if _arena == null:
		_arena = (load(CENA) as PackedScene).instantiate()
		root.add_child(_arena)
	for i in 3:
		await process_frame
	return _arena


## O mapa (50 × 50) que a arena tem construído: [bloqueio, motivo, cobertura] por índice.
static func _ler_mapa(a) -> Array:
	var g = a.mapa.grelha
	var r: Array = []
	for i in GrelhaMapa.LADO * GrelhaMapa.LADO:
		var c := GrelhaMapa.casa_do_indice(i)
		r.append([g.bloqueada(c), g.motivo_bloqueio(c), g.cobertura(c)])
	return r


func _correr() -> void:
	root.get_node("/root/Rede")._ativo = true
	var ref_g: Array = Exportar.REFERENCIA
	var ref := _ler_mapa(await _abrir(ref_g[0], ref_g[1], ref_g[2]))
	print("== Ordem 48: a sonda das zonas (referência %d×%d de %s m) ==" % [ref_g[0], ref_g[1], ref_g[2]])
	var contradiz := 0
	var relatorio: Array = []
	var tot := {"casas": 0, "borda": 0, "bordaDiferente": 0}
	for z in ZONAS:
		var a = await _abrir(z[0], z[1], z[2])
		var cli := _ler_mapa(a)
		var zona := Rect2(a.origem, Vector2(a.largura * a.casa_m, a.altura * a.casa_m))
		var d_bloq := 0
		var d_mot := 0
		var d_cob := 0
		var borda := 0
		var borda_dif := 0
		var casas := 0
		for y in a.altura:
			for x in a.largura:
				var cm := Assentamento.casa_do_mapa(a.origem, a.casa_m, Vector2i(x, y))
				if cm == GrelhaMapa.FORA:
					continue
				casas += 1
				var i := GrelhaMapa.indice(cm)
				if cli[i][0] != ref[i][0]:
					d_bloq += 1
				elif cli[i][1] != ref[i][1]:
					d_mot += 1
				var mc := GrelhaMapa.canto(cm) + Vector2(GrelhaMapa.CASA_M, GrelhaMapa.CASA_M) * 0.5
				var fundo := minf(minf(mc.x - zona.position.x, zona.end.x - mc.x), minf(mc.y - zona.position.y, zona.end.y - mc.y))
				if fundo > Exportar.BORDA_COBERTURA_M or int(ref[i][2]) == 2:
					if cli[i][2] != ref[i][2]:
						d_cob += 1
				else:
					borda += 1
					if cli[i][2] != ref[i][2]:
						borda_dif += 1
		var ok := d_bloq == 0 and d_mot == 0 and d_cob == 0
		if not ok:
			contradiz += 1
		tot["casas"] += casas
		tot["borda"] += borda
		tot["bordaDiferente"] += borda_dif
		print("  %s %d×%d de %s m: %d casas; bloqueio diferente %d, motivo %d, cobertura afirmada %d; faixa da borda %d casas (%d com outra cobertura no cliente)" % [
			"ok   " if ok else "FALHA", z[0], z[1], z[2], casas, d_bloq, d_mot, d_cob, borda, borda_dif])
		relatorio.append({"largura": z[0], "altura": z[1], "casaM": z[2], "origemM": [a.origem.x, a.origem.y], "casas": casas,
			"bloqueioDiferente": d_bloq, "motivoDiferente": d_mot, "coberturaAfirmadaDiferente": d_cob,
			"casasNaFaixaDaBorda": borda, "faixaDaBordaClienteDiferente": borda_dif})
	print("%d zonas, %d casas: %s; na faixa da borda %d casas, %d com outra cobertura no cliente" % [ZONAS.size(), tot["casas"],
		"NENHUMA contradiz o recorte" if contradiz == 0 else "%d ZONAS CONTRADIZEM o recorte" % contradiz, tot["borda"], tot["bordaDiferente"]])
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--json="):
			var f := FileAccess.open(arg.trim_prefix("--json="), FileAccess.WRITE)
			f.store_string(JSON.stringify({"ordem": 48, "sonda": "cliente/cenas/arena/ferramentas/sondar_zonas_terreno.gd",
				"referencia": {"largura": ref_g[0], "altura": ref_g[1], "casaM": ref_g[2]}, "bordaCoberturaM": Exportar.BORDA_COBERTURA_M,
				"zonasQueContradizem": contradiz, "totais": tot, "zonas": relatorio}, " "))
			f.close()
	quit(0 if contradiz == 0 else 1)
