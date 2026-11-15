extends Node
## vento_mundo.gd — Ordem 43. O VENTO DO MUNDO: um só. Em cada instante tem direcção e força;
## a relva, as hastes, as copas e a Árvore Ancestral mexem SEGUNDO ele, e qualquer peça o lê.
## É APRESENTAÇÃO: o vento não entra em regra, custo ou turno nenhum.
##
## COMO SE LÊ (para as outras peças — o clima incluído):
##   var vento := get_tree().get_first_node_in_group("vento_mundo")
##   vento.vento_actual()      -> { "direcao": Vector3 (unitário, no chão: PARA ONDE sopra),
##                                  "forca": float (0–~1,7; 1 = a tarde forte),
##                                  "velocidade_ms": float, "azimute_para": graus, "azimute_de": graus,
##                                  "rajada": float 0–1 }
##   vento.vento_em(posicao)   -> o mesmo, NAQUELE sítio (a rajada que lá está a passar agora:
##                                  é o mesmo campo que a relva mostra)
##   vento.vetor()             -> Vector3 = direcção × velocidade (m/s)   — o atalho do clima
##   vento.vetor_em(posicao)   -> idem, local
##
## O MODELO
##  1. A CURVA DO DIA (função pura da hora — curva_do_dia(h)): a força segue o dia (calma ao
##     amanhecer, levanta de manhã, forte a meio da tarde, cai ao entardecer, fraca de noite) e
##     a direcção RODA devagar, sempre no mesmo sentido (o dos ponteiros, como o sol: a volta
##     da brisa), ~15°/h com um vaguear lento por cima. Às 16:15 sopra para és-sueste — o
##     vento que a Ordem 38 tinha fixo.
##  2. AS RAJADAS (tempo real, não periódicas): ruído contínuo em duas escalas faz a força
##     subir e descer; cada rajada traz um desvio breve da direcção. De noite o vento é fraco
##     mas mais irregular (a variação relativa cresce quando a força-base é pequena).
##  3. A FÍSICA
##     · INÉRCIA: a força e a direcção não saltam — seguem o alvo com atraso (a rajada entra
##       depressa, 0,5 s, e morre devagar, 1,6 s);
##     · ADVECÇÃO: o campo de rajadas (o ruído do mundo) é LEVADO pelo vento: desloca-se na
##       direcção do vento à velocidade dele (integrada no tempo — rodar a direcção não faz o
##       campo saltar). É por isso que se vê a rajada a atravessar a clareira;
##     · PRESSÃO: a dobra da vegetação segue a pressão dinâmica (∝ v²) e SATURA (a lâmina
##       deita-se, não estica) — shaders/vento_floresta.gdshaderinc;
##     · as ondas e o tremor da relva andam ao ritmo da velocidade (fases integradas): com
##       calma quase param, com vento correm.

const VEL_REF_MS := 7.5         # m/s quando a força é 1 (27 km/h)
const ADVECCAO := 0.42          # o campo de rajadas viaja a esta fracção da velocidade do vento
const ESCALA_RAJADA := 0.011    # 1/m: a escala do campo de rajadas (a mesma dos shaders)
const TAU_SOBE := 0.5           # s
const TAU_DESCE := 1.6          # s
const TAU_RODA := 1.3           # s

## A força-base por hora (0–1).
const FORCA_DIA: Array = [
	[0.0, 0.20], [3.0, 0.16], [5.5, 0.08], [7.0, 0.14], [9.0, 0.36], [11.0, 0.60], [13.0, 0.82],
	[15.5, 1.00], [17.0, 0.86], [18.5, 0.52], [20.0, 0.27], [22.0, 0.20], [24.0, 0.20],
]

const Ciclo := preload("res://mapa/floresta/ciclo_dia.gd")

## Parado: o vento só anda por avancar() (as ferramentas de filme usam isto).
@export var parado: bool = false

## O relógio do mundo (se faltar, o vento fica na hora do `hora_fixa`).
var relogio: Node
var hora_fixa := 16.25

var forca := 0.0                 # a força agora (rajada incluída), 0–~1,7
var forca_base := 0.0
var rajada := 0.0                # 0–1
var azimute_para := 120.0        # graus a partir do norte, positivo para leste: PARA ONDE sopra
var desloc := Vector2.ZERO       # advecção integrada do campo de rajadas (m, com volta)
var fase := 0.0                  # fase integrada das ondas (rad, com volta)
var tremor := 0.0                # fase integrada do tremor (rad, com volta)

var _t := 0.0
var _r1 := FastNoiseLite.new()
var _r2 := FastNoiseLite.new()
var _ruido_img: Image
var _materiais: Array[ShaderMaterial] = []
var _pronto := false


func _ready() -> void:
	add_to_group("vento_mundo")
	_r1.seed = 4301
	_r1.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_r1.frequency = 1.0
	_r2.seed = 4302
	_r2.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_r2.frequency = 1.0


func _process(delta: float) -> void:
	if not parado:
		avancar(delta)


## Os materiais que o vento comanda e a imagem do ruído do mundo (o campo de rajadas).
func ligar(materiais: Array[ShaderMaterial], ruido: Image) -> void:
	_materiais = materiais
	_ruido_img = ruido
	_escrever()


# ------------------------------------------------------------------ a curva do dia

## Função PURA da hora: { "forca": 0–1, "azimute_para": graus, "azimute_de": graus }.
static func curva_do_dia(h: float) -> Dictionary:
	h = fposmod(h, 24.0)
	var f := Ciclo.curva(FORCA_DIA, h)
	# a volta da brisa: 15°/h no sentido dos ponteiros, mais depressa de tarde e mais devagar de
	# madrugada (o seno), com um vaguear lento por cima (período de 24 h: fecha sem salto)
	var a := TAU * h / 24.0
	var az := 120.0 + 15.0 * (h - 16.25) + 16.0 * (sin(a - 2.1) - sin(TAU * 16.25 / 24.0 - 2.1)) \
		+ 9.0 * (sin(3.0 * a + 0.7) - sin(3.0 * TAU * 16.25 / 24.0 + 0.7))
	az = wrapf(az, -180.0, 180.0)
	return {"forca": f, "azimute_para": az, "azimute_de": wrapf(az + 180.0, -180.0, 180.0)}


static func rumo(az: float) -> String:
	var nomes: Array[String] = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSO", "SO", "OSO", "O", "ONO", "NO", "NNO"]
	return nomes[int(round(fposmod(az, 360.0) / 22.5)) % 16]


# ------------------------------------------------------------------ o tempo

func _hora() -> float:
	if relogio != null and relogio.has_method("hora_do_mundo"):
		return relogio.call("hora_do_mundo")
	return hora_fixa


## Avança o vento `delta` segundos reais.
func avancar(delta: float) -> void:
	delta = clampf(delta, 0.0, 0.25)
	_t += delta
	var dia := curva_do_dia(_hora())
	forca_base = dia["forca"]
	# ---- rajadas: duas escalas de ruído contínuo (não periódico)
	var lento := _r1.get_noise_1d(_t * 0.105)
	var rapido := _r1.get_noise_1d(_t * 0.43 + 100.0)
	var x := 0.5 + 0.5 * clampf((lento * 0.72 + rapido * 0.28) * 1.9, -1.0, 1.0)
	var alvo_raj := x * x * (3.0 - 2.0 * x)
	# quanto menor a força-base, maior a variação relativa (o vento fraco é irregular)
	var irregular := 0.95 + 0.75 * (1.0 - forca_base)
	var alvo := forca_base * (0.66 + irregular * alvo_raj) + 0.035 * (0.5 + 0.5 * rapido)
	var tau := TAU_SOBE if alvo > forca else TAU_DESCE
	if not _pronto:
		forca = alvo
		rajada = alvo_raj
	else:
		forca += (alvo - forca) * (1.0 - exp(-delta / tau))
		rajada += (alvo_raj - rajada) * (1.0 - exp(-delta / tau))
	# ---- direcção: a do dia + o desvio da rajada + um vaguear lento
	var vaguear := 12.0 * _r2.get_noise_1d(_t * 0.045) + 16.0 * alvo_raj * _r2.get_noise_1d(_t * 0.17 + 50.0)
	vaguear *= 1.0 + 0.8 * (1.0 - forca_base)
	var alvo_az: float = float(dia["azimute_para"]) + vaguear
	if not _pronto:
		azimute_para = alvo_az
	else:
		var k := 1.0 - exp(-delta / TAU_RODA)
		azimute_para = rad_to_deg(lerp_angle(deg_to_rad(azimute_para), deg_to_rad(alvo_az), k))
	azimute_para = wrapf(azimute_para, -180.0, 180.0)
	_pronto = true
	# ---- integração: advecção do campo de rajadas e fases das ondas
	var d := direcao2()
	var volta := 1.0 / ESCALA_RAJADA
	desloc += d * (forca * VEL_REF_MS * ADVECCAO * delta)
	desloc = Vector2(fposmod(desloc.x, volta), fposmod(desloc.y, volta))
	fase = fposmod(fase + (0.30 + 0.75 * forca) * delta, TAU * 100.0)
	tremor = fposmod(tremor + (0.45 + 1.0 * forca) * delta, TAU * 10.0)
	_escrever()


func _escrever() -> void:
	var d := direcao2()
	for m in _materiais:
		m.set_shader_parameter("vento_dir", d)
		m.set_shader_parameter("vento_v", forca)
		m.set_shader_parameter("vento_desloc", desloc)
		m.set_shader_parameter("vento_fase", fase)
		m.set_shader_parameter("vento_tremor", tremor)


# ------------------------------------------------------------------ API

## Para onde sopra, no plano do chão (x = leste, y = z do mundo: +z é sul).
func direcao2() -> Vector2:
	var a := deg_to_rad(azimute_para)
	return Vector2(sin(a), -cos(a))


## A rajada (0–1) que está a passar em (x, z): o MESMO campo que os shaders desenham.
func rajada_em(x: float, z: float) -> float:
	if _ruido_img == null:
		return rajada
	var n := _ruido_img.get_width()
	var u := fposmod((x - desloc.x) * ESCALA_RAJADA, 1.0) * n - 0.5
	var v := fposmod((z - desloc.y) * ESCALA_RAJADA, 1.0) * n - 0.5
	var x0 := int(floor(u))
	var y0 := int(floor(v))
	var fx := u - x0
	var fy := v - y0
	var a := _ruido_img.get_pixel(posmod(x0, n), posmod(y0, n)).r
	var b := _ruido_img.get_pixel(posmod(x0 + 1, n), posmod(y0, n)).r
	var c := _ruido_img.get_pixel(posmod(x0, n), posmod(y0 + 1, n)).r
	var e := _ruido_img.get_pixel(posmod(x0 + 1, n), posmod(y0 + 1, n)).r
	var r := lerpf(lerpf(a, b, fx), lerpf(c, e, fx), fy)
	var t := clampf((r - 0.30) / 0.48, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _leitura(f: float, raj: float) -> Dictionary:
	var d := direcao2()
	return {
		"direcao": Vector3(d.x, 0.0, d.y),
		"forca": f,
		"velocidade_ms": f * VEL_REF_MS,
		"azimute_para": azimute_para,
		"azimute_de": wrapf(azimute_para + 180.0, -180.0, 180.0),
		"rajada": raj,
	}


func vento_actual() -> Dictionary:
	return _leitura(forca, rajada)


## O vento num sítio: a força do mundo modulada pela rajada local (a mesma conta dos shaders:
## v_local = v · (0,55 + 0,80 · rajada_local)).
func vento_em(posicao: Vector3) -> Dictionary:
	var r := rajada_em(posicao.x, posicao.z)
	return _leitura(forca * (0.55 + 0.80 * r), r)


func vetor() -> Vector3:
	var d := direcao2()
	return Vector3(d.x, 0.0, d.y) * (forca * VEL_REF_MS)


func vetor_em(posicao: Vector3) -> Vector3:
	var d := direcao2()
	return Vector3(d.x, 0.0, d.y) * (forca * (0.55 + 0.80 * rajada_em(posicao.x, posicao.z)) * VEL_REF_MS)
