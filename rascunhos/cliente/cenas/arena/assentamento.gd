extends RefCounted
## assentamento.gd — Ordem 44. A REGRA ÚNICA de como a grelha do jogo assenta no relevo do mapa da floresta.
##
## Um só sítio para as contas que o cliente usa para desenhar e que o servidor tem de conhecer:
##   - onde fica a grelha no mapa (`origem_no_mapa`);
##   - a altura do centro de cada casa (`centro_casa`);
##   - onde pousa a BASE de uma figura e com que inclinação (`pegada`);
##   - que casa do mapa corresponde a uma casa do jogo (`casa_do_mapa`).
## A arena (cenas/arena/arena.gd) desenha com estas funções; o exportador
## (cenas/arena/ferramentas/exportar_terreno.gd) chama as MESMAS para escrever o terreno que o servidor lê
## (servidor/dados/terreno-floresta.json). Nenhum número é copiado à mão: a fonte é esta e o Relevo.
##
## A REGRA DO PÉ (Ordem 44, parte B). Até à Ordem 42 a base era horizontal, à altura mais baixa da pegada:
## nada ficava no ar, mas numa encosta o lado de cima entrava no chão (0,60 m na casa (0, 0), com 1,49 m de
## degrau). Medimos as três saídas possíveis nas 6 casas do outeiro:
##   - base horizontal à MÉDIA da pegada: enterra até 0,30 m e flutua até 0,30 m (não serve);
##   - base horizontal ao ponto MAIS ALTO: flutua até 0,60 m (não serve);
##   - base INCLINADA com a encosta: o plano que melhor se encosta ao relevo debaixo da pegada (mínimos
##     quadrados no centro e em dois anéis de 16 pontos), descido ou subido para que o pior enterramento e
##     a pior flutuação fiquem iguais (minimax). Dá ≤ 0,02 m nas 6 casas e ≤ 0,03 m nas 400.
## Escolheu-se a terceira: é a única em que a figura não flutua nem se enterra numa encosta de 35°. Para a
## leitura em jogo ficar limpa, só a BASE (a mancha de contacto) se inclina; o corpo de pé fica a prumo
## (uma figura não se deita com a encosta) e sobe o justo para a cápsula tocar o plano da base sem o
## atravessar (`subida_do_corpo`). A figura caída deita-se no plano da base. Num chão plano tudo isto dá o
## mesmo que antes: inclinação 0, base no chão.

const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")
const GrelhaMapa := preload("res://mapa/floresta/grelha_floresta.gd")

## Raio da pegada (e da cápsula do marcador) em fracção da casa: 0,28 × 1,5 = 0,42 m.
const RAIO_PEGADA_FRAC := 0.28
## Pontos por anel na amostra da pegada (o ajuste do plano usa o centro e anéis a 1/2 e 1 raio).
const PONTOS_ANEL := 16


## Ordem 42: a grelha fica centrada no centro da arena do mapa (0, 0) e, se as casas forem de 1,5 m,
## encostada às linhas da grelha do mapa (−37,5 + k × 1,5): cada casa do jogo é uma casa do mapa.
static func origem_no_mapa(tam: Vector2, casa_m: float) -> Vector2:
	var o := -tam * 0.5
	if is_equal_approx(casa_m, GrelhaMapa.CASA_M):
		o.x = -GrelhaMapa.MEIO + roundf((o.x + GrelhaMapa.MEIO) / GrelhaMapa.CASA_M) * GrelhaMapa.CASA_M
		o.y = -GrelhaMapa.MEIO + roundf((o.y + GrelhaMapa.MEIO) / GrelhaMapa.CASA_M) * GrelhaMapa.CASA_M
	return o


## Centro da casa do jogo `c`, em cima do chão do mapa (a altura do relevo nesse ponto).
static func centro_casa(origem: Vector2, casa_m: float, c: Vector2i) -> Vector3:
	var x := origem.x + (c.x + 0.5) * casa_m
	var z := origem.y + (c.y + 0.5) * casa_m
	return Vector3(x, Relevo.altura(x, z), z)


## A casa do mapa (50 × 50 de 1,5 m) que contém o centro da casa do jogo. Com casas de 1,5 m é a mesma casa.
static func casa_do_mapa(origem: Vector2, casa_m: float, c: Vector2i) -> Vector2i:
	var p := centro_casa(origem, casa_m, c)
	return GrelhaMapa.casa_em(p.x, p.z)


static func raio_pegada(casa_m: float) -> float:
	return casa_m * RAIO_PEGADA_FRAC


## A base de uma figura pousada em (x, z), com pegada de raio `raio`. Devolve:
##   y          a altura da base no centro (o «pé»; é o que o servidor recebe como peM);
##   gradiente  a inclinação do plano da base (dy/dx, dy/dz);
##   normal     a normal do plano da base (para cima);
##   enterra    o que o relevo sobe acima do plano, no pior ponto da amostra (m);
##   flutua     o que o plano fica acima do relevo, no pior ponto da amostra (m).
static func pegada(x: float, z: float, raio: float) -> Dictionary:
	var pts: Array[Vector2] = [Vector2.ZERO]
	for anel in [0.5, 1.0]:
		for k in PONTOS_ANEL:
			var a := TAU * k / float(PONTOS_ANEL)
			pts.append(Vector2(cos(a), sin(a)) * raio * anel)
	var hs := PackedFloat64Array()
	hs.resize(pts.size())
	var sxx := 0.0
	var szz := 0.0
	var sxz := 0.0
	var sxh := 0.0
	var szh := 0.0
	var sh := 0.0
	for i in pts.size():
		var q := pts[i]
		var h := Relevo.altura(x + q.x, z + q.y)
		hs[i] = h
		sxx += q.x * q.x
		szz += q.y * q.y
		sxz += q.x * q.y
		sxh += q.x * h
		szh += q.y * h
		sh += h
	# A amostra é simétrica à volta do centro (soma de x e de z = 0): o plano dos mínimos quadrados sai fechado.
	var a0 := sh / float(pts.size())
	var det := sxx * szz - sxz * sxz
	var gx := (sxh * szz - szh * sxz) / det
	var gz := (szh * sxx - sxh * sxz) / det
	var rmin := INF
	var rmax := -INF
	for i in pts.size():
		var r := hs[i] - (a0 + gx * pts[i].x + gz * pts[i].y)
		rmin = minf(rmin, r)
		rmax = maxf(rmax, r)
	var meio := (rmin + rmax) * 0.5
	return {"y": a0 + meio, "gradiente": Vector2(gx, gz), "normal": Vector3(-gx, 1.0, -gz).normalized(),
		"enterra": rmax - meio, "flutua": meio - rmin}


## Quanto sobe o corpo de pé (cápsula a prumo, de raio `raio_corpo`) para tocar o plano da base sem o
## atravessar: a esfera de baixo fica tangente ao plano. 0 num chão plano.
static func subida_do_corpo(gradiente: Vector2, raio_corpo: float) -> float:
	return raio_corpo * (sqrt(1.0 + gradiente.length_squared()) - 1.0)
