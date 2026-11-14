extends RefCounted
## bacias_do_relevo.gd — Ordem 42. Os PONTOS BAIXOS REAIS do relevo do mapa, para o alagamento do clima
## (arte/clima/clima.gd definir_bacias). Nada sorteado, nada desenhado à mão: a água vai para onde o chão a
## leva.
##
## O método é a INUNDAÇÃO POR PRIORIDADE (priority-flood). Amostra-se o relevo (Relevo.altura, a altura única
## do mapa) numa grelha que cobre a zona e uma folga à volta. A borda da grelha é a saída: a água que lá chega
## escorre para fora. Enche-se de fora para dentro, sempre pela célula mais baixa ainda por visitar; cada
## célula fica com o nível a que a água tem de subir para sair dali (o seu ou o da vizinha por onde saiu, o
## maior). Onde esse nível fica acima do chão há uma COVA. As células com cova, ligadas entre si (4
## vizinhas), são uma bacia, e de cada uma sai:
##   x, z      o centro (pesado pela fundura);
##   raio      até onde a bacia vai (o raio do círculo com a mesma área, × 1,1 + meio passo); dentro dele só
##             conta o chão que não está abaixo do fundo da cova (o de fora do transbordo fica seco);
##   fundura   a cova mais funda (m);
##   nivel     o nível de transbordo (m, no mundo): até aí a água pode subir.
## Ficam as maiores (por volume), até `maximo`. A subida da água conta-se do fundo REAL da cova e fica limitada
## a `subida_max` (m): a cova do charco (2,6 m) não vira um lago até à borda — o charco cresce, não transborda
## o vale (o fundo fica onde é; só o nível de cima baixa).

const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")


## `zona` em metros do mundo (x, z); `folga` (m) à volta (a saída fica longe da zona); `passo` (m).
static func achar(zona: Rect2, folga: float = 14.0, passo: float = 0.5, maximo: int = 8, fundura_min: float = 0.02, area_min: float = 0.3, subida_max: float = 1.0) -> Array:
	var r := zona.grow(folga)
	var nx := int(ceil(r.size.x / passo)) + 1
	var nz := int(ceil(r.size.y / passo)) + 1
	var h := PackedFloat32Array()
	h.resize(nx * nz)
	for j in nz:
		for i in nx:
			h[j * nx + i] = Relevo.altura(r.position.x + i * passo, r.position.y + j * passo)
	var cheio := PackedFloat32Array()
	cheio.resize(nx * nz)
	var visto := PackedByteArray()
	visto.resize(nx * nz)
	# monte binário de [nível, índice]
	var monte: Array = []
	for j in nz:
		for i in nx:
			if i == 0 or j == 0 or i == nx - 1 or j == nz - 1:
				var k := j * nx + i
				visto[k] = 1
				cheio[k] = h[k]
				_por(monte, [h[k], k])
	while not monte.is_empty():
		var topo: Array = _tirar(monte)
		var nivel: float = topo[0]
		var k: int = topo[1]
		var i := k % nx
		var j := k / nx
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var ii := i + d.x
			var jj := j + d.y
			if ii < 0 or jj < 0 or ii >= nx or jj >= nz:
				continue
			var kk := jj * nx + ii
			if visto[kk] == 1:
				continue
			visto[kk] = 1
			cheio[kk] = maxf(h[kk], nivel)
			_por(monte, [cheio[kk], kk])
	# as covas ligadas → bacias
	var marca := PackedInt32Array()
	marca.resize(nx * nz)
	marca.fill(-1)
	var bacias: Array = []
	for k0 in nx * nz:
		if marca[k0] != -1 or cheio[k0] - h[k0] < 0.005:
			continue
		var fila: Array[int] = [k0]
		marca[k0] = bacias.size()
		var cabeca := 0
		var soma_p := Vector2.ZERO
		var soma_w := 0.0
		var vol := 0.0
		var fundo := 0.0
		var transbordo := -INF
		while cabeca < fila.size():
			var k: int = fila[cabeca]
			cabeca += 1
			var dd := cheio[k] - h[k]
			var p := Vector2(r.position.x + (k % nx) * passo, r.position.y + (k / nx) * passo)
			soma_p += p * dd
			soma_w += dd
			vol += dd * passo * passo
			fundo = maxf(fundo, dd)
			transbordo = maxf(transbordo, cheio[k])
			var i := k % nx
			var j := k / nx
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var ii := i + d.x
				var jj := j + d.y
				if ii < 0 or jj < 0 or ii >= nx or jj >= nz:
					continue
				var kk := jj * nx + ii
				if marca[kk] == -1 and cheio[kk] - h[kk] >= 0.005:
					marca[kk] = bacias.size()
					fila.append(kk)
		var area := fila.size() * passo * passo
		var c := soma_p / maxf(soma_w, 0.0001)
		var sobe := minf(fundo, subida_max)
		bacias.append({"x": c.x, "z": c.y, "raio": sqrt(area / PI) * 1.1 + passo * 0.5, "fundura": sobe,
			"nivel": transbordo - fundo + sobe, "fundura_real": fundo, "nivel_transbordo": transbordo,
			"area_m2": area, "volume_m3": vol})
	var boas: Array = []
	for b: Dictionary in bacias:
		if float(b["fundura"]) >= fundura_min and float(b["area_m2"]) >= area_min:
			boas.append(b)
	boas.sort_custom(func(a, b): return float(a["volume_m3"]) > float(b["volume_m3"]))
	return boas.slice(0, maximo)


static func _por(monte: Array, e: Array) -> void:
	monte.append(e)
	var i := monte.size() - 1
	while i > 0:
		var pai := (i - 1) / 2
		if float(monte[pai][0]) <= float(e[0]):
			break
		monte[i] = monte[pai]
		i = pai
	monte[i] = e


static func _tirar(monte: Array) -> Array:
	var topo: Array = monte[0]
	var ultimo: Array = monte.pop_back()
	if monte.is_empty():
		return topo
	var n := monte.size()
	var i := 0
	while true:
		var f := 2 * i + 1
		if f >= n:
			break
		if f + 1 < n and float(monte[f + 1][0]) < float(monte[f][0]):
			f += 1
		if float(monte[f][0]) >= float(ultimo[0]):
			break
		monte[i] = monte[f]
		i = f
	monte[i] = ultimo
	return topo
