extends RefCounted
## integrador_vento.gd — Ordem 40 (clima). O deslocamento das gotas e dos flocos, INTEGRADO FRAME A FRAME.
##
## A lição medida da REF_85 (protótipo web, 2026-11-13): a fórmula «vento actual × tempo total decorrido» punha
## 47,7% dos flocos a andar CONTRA o vento (basta o vento mudar para a nuvem inteira saltar). A fórmula certa
## soma, em cada frame, só o que esse frame andou:
##
##     posição += (vento do frame + queda) × dt
##
## Aqui NÃO se guarda uma posição por floco na CPU (seria caro no telemóvel). Guardam-se 7 acumuladores, somados
## frame a frame com o vento DESSE frame, e cada floco lê-os com os seus pesos (constantes, sorteados uma vez):
##
##     d_queda     += queda × dt                               (1 número)
##     d_vento[c]  += vento × g_c(t) × dt        c = 0, 1, 2   (3 vectores; g_c > 0: rajadas ao longo do vento)
##     d_lado[c]   += perp(vento) × a_c(t) × dt  c = 0, 1, 2   (3 vectores; balanço PERPENDICULAR ao vento)
##
##     floco.xz = base.xz + Σ d_vento[c] × w_c/16 + Σ d_lado[c] × l_c/8        (w_c ≥ 0 inteiros, l_c inteiros)
##     floco.y  = base.y  − d_queda × k/16                                     (k > 0 inteiro)
##
## Como os pesos são constantes, o que o floco anda num frame é exactamente
##     dt × ( vento × Σ g_c·w_c/16  +  perp × Σ a_c·l_c/8  +  queda × k/16 )
## isto é: «(vento do frame + queda) × dt», com o ganho do vento sempre positivo. O balanço é perpendicular ao
## vento do frame, por isso NENHUM floco anda contra o vento — por construção, e medido em `medir()`.
## Nunca aparece «vento × tempo total» em lado nenhum: mudar o vento só muda o que se soma DAQUI para a frente.
##
## O shader (clima_comum.gdshaderinc) faz a mesma conta com os mesmos números; `posicao()` é o espelho dela na
## CPU, para os testes e para a medição. Os acumuladores dão a volta em 16 × caixa (os pesos são múltiplos de
## 1/16 e de 1/8, por isso a volta não mexe em floco nenhum) — a precisão não se gasta com as horas.

const CANAIS := 3
const PASSOS := 16.0
const AMPLITUDE_RAJADA := 0.4
const OMEGA_RAJADA: Array[float] = [0.9, 1.7, 2.9]
const FASE_RAJADA: Array[float] = [0.0, 2.1, 4.4]
const OMEGA_LADO: Array[float] = [1.3, 2.1, 3.3]
const FASE_LADO: Array[float] = [0.7, 3.9, 5.2]
## dt preso: um engasgo do aparelho não vira um salto dos flocos.
const DT_MAXIMO := 0.1

var tempo := 0.0
var caixa := Vector3(38.0, 12.0, 38.0)
var d_queda := 0.0
var d_vento := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var d_lado := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
## O que se somou no último frame, em m/s (a chuva usa-o para se inclinar com a velocidade do frame).
var v_vento := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var v_lado := PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
var v_queda := 0.0


func definir_caixa(tamanho: Vector3) -> void:
	caixa = Vector3(maxf(tamanho.x, 1.0), maxf(tamanho.y, 1.0), maxf(tamanho.z, 1.0))


## Um frame: soma o que ESTE frame andou. `vento` em m/s no plano do chão (x, z); `queda` em m/s (para baixo);
## `balanco` em m/s (amplitude do balanço lateral dos flocos).
func avancar(dt: float, vento: Vector2, queda: float, balanco: float) -> void:
	dt = clampf(dt, 0.0, DT_MAXIMO)
	var perp := Vector2(1.0, 0.0)
	if vento.length_squared() > 1e-8:
		perp = Vector2(-vento.y, vento.x).normalized()
	var volta := Vector2(PASSOS * caixa.x, PASSOS * caixa.z)
	for c in CANAIS:
		var ganho := 1.0 + AMPLITUDE_RAJADA * sin(OMEGA_RAJADA[c] * tempo + FASE_RAJADA[c])
		var vv: Vector2 = vento * ganho
		var vl: Vector2 = perp * (balanco * sin(OMEGA_LADO[c] * tempo + FASE_LADO[c]))
		v_vento[c] = vv
		v_lado[c] = vl
		var dv: Vector2 = d_vento[c] + vv * dt
		var dl: Vector2 = d_lado[c] + vl * dt
		d_vento[c] = Vector2(fposmod(dv.x, volta.x), fposmod(dv.y, volta.y))
		d_lado[c] = Vector2(fposmod(dl.x, volta.x), fposmod(dl.y, volta.y))
	v_queda = queda
	d_queda = fposmod(d_queda + queda * dt, PASSOS * caixa.y)
	tempo += dt


## Posição de um floco DENTRO da caixa (0..caixa), a mesma conta do shader. `base` em fracções 0..1.
func posicao(base: Vector3, k: int, w: Vector3i, l: Vector3i) -> Vector3:
	var h := Vector2(base.x * caixa.x, base.z * caixa.z)
	h += d_vento[0] * (w.x / PASSOS) + d_vento[1] * (w.y / PASSOS) + d_vento[2] * (w.z / PASSOS)
	h += d_lado[0] * (l.x / 8.0) + d_lado[1] * (l.y / 8.0) + d_lado[2] * (l.z / 8.0)
	var y := base.y * caixa.y - d_queda * (k / PASSOS)
	return Vector3(fposmod(h.x, caixa.x), fposmod(y, caixa.y), fposmod(h.y, caixa.z))


## Sorteia os pesos de `n` partículas (sempre os mesmos para a mesma semente). Devolve as colunas:
## bases (fracções 0..1 da caixa), k (queda, 10..16), w (vento, três inteiros ≥ 0 com soma 12..16),
## l (balanço, três inteiros −8..8; tudo 0 se `com_balanco` for falso) e r (0..63, tamanho e fase).
static func sortear(n: int, semente: int, com_balanco: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var bases := PackedVector3Array()
	var k := PackedInt32Array()
	var w: Array[Vector3i] = []
	var l: Array[Vector3i] = []
	var r := PackedInt32Array()
	bases.resize(n)
	k.resize(n)
	r.resize(n)
	w.resize(n)
	l.resize(n)
	for i in n:
		bases[i] = Vector3(rng.randf(), rng.randf(), rng.randf())
		k[i] = rng.randi_range(10, 16)
		var a := rng.randi_range(1, 6)
		var b := rng.randi_range(1, 6)
		var soma := rng.randi_range(12, 16)
		w[i] = Vector3i(a, b, soma - a - b)
		if com_balanco:
			l[i] = Vector3i(rng.randi_range(-8, 8), rng.randi_range(-8, 8), rng.randi_range(-8, 8))
		else:
			l[i] = Vector3i.ZERO
		r[i] = rng.randi_range(0, 63)
	return {"bases": bases, "k": k, "w": w, "l": l, "r": r}


## Os 4 números que vão para o INSTANCE_CUSTOM do shader (inteiros pequenos: exactos mesmo em meia precisão).
static func empacotar(k: int, w: Vector3i, l: Vector3i, r: int) -> Color:
	return Color(
			float(k + 32 * r),
			float(w.x + 32 * w.y),
			float(w.z + 32 * (l.x + 8)),
			float((l.y + 8) + 32 * (l.z + 8)))


## A medição da REF_85, feita com a conta do jogo: corre `quadros` frames de `dt` com o vento que `vento_fn(t)`
## devolver (Vector2, m/s) e conta, floco a floco e frame a frame, quantos deslocamentos foram CONTRA o vento
## desse frame (produto interno negativo) e o maior salto. As voltas da caixa (o floco que sai por um lado e
## entra pelo outro) contam-se à parte: são o reaparecimento, não movimento.
func medir(n: int, quadros: int, dt: float, vento_fn: Callable, queda: float, balanco: float, semente: int = 85) -> Dictionary:
	var s := sortear(n, semente, balanco > 0.0)
	var bases: PackedVector3Array = s["bases"]
	var ks: PackedInt32Array = s["k"]
	var ws: Array[Vector3i] = s["w"]
	var ls: Array[Vector3i] = s["l"]
	var antes := PackedVector3Array()
	antes.resize(n)
	for i in n:
		antes[i] = posicao(bases[i], ks[i], ws[i], ls[i])
	var contra := 0
	var total := 0
	var voltas := 0
	var subiram := 0
	var salto_max := 0.0
	var meia := caixa * 0.5
	for q in quadros:
		var vento: Vector2 = vento_fn.call(tempo)
		avancar(dt, vento, queda, balanco)
		for i in n:
			var p := posicao(bases[i], ks[i], ws[i], ls[i])
			var d := p - antes[i]
			antes[i] = p
			if absf(d.x) > meia.x or absf(d.y) > meia.y or absf(d.z) > meia.z:
				voltas += 1
				continue
			total += 1
			if d.x * vento.x + d.z * vento.y < -1e-7:
				contra += 1
			if d.y > 1e-7:
				subiram += 1
			salto_max = maxf(salto_max, d.length())
	return {
		"flocos": n, "quadros": quadros, "dt": dt, "deslocamentos": total, "contra_o_vento": contra,
		"percent_contra": (100.0 * contra / float(maxi(total, 1))), "subiram": subiram,
		"salto_max_m": salto_max, "voltas_da_caixa": voltas,
	}
