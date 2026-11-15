extends Node
## ciclo_dia.gd — Ordem 43. O RELÓGIO DO MUNDO e tudo o que sai da hora: o sol, a lua, o céu,
## a luz, a névoa. É APRESENTAÇÃO: a hora do mundo não entra em regra, custo ou turno nenhum.
##
## COMO SE LÊ (para as outras peças):
##   var relogio := get_tree().get_first_node_in_group("relogio_mundo")
##   relogio.hora_do_mundo()   -> float, 0–24 contínua (16.25 = 16:15)
##   relogio.hora_texto()      -> "16:15"
##   relogio.fase()            -> "madrugada" | "manhã" | "dia" | "tarde" | "entardecer" | "noite"
##   relogio.estado()          -> Dictionary com TUDO o que sai da hora (astros, cores, luz, névoa)
##   sinal fase_mudou(fase)    -> quando a fase muda de nome
##
## A DURAÇÃO DO DIA configura-se num só sítio: DURACAO_DIA_S (segundos reais por dia do mundo;
## ou o export duracao_dia_s do nó). O MODO DE PROVA acelera-o: modo_prova = true (tecla T na
## cena) faz o dia inteiro em DURACAO_PROVA_S.
##
## O MODELO (um só, contínuo — nada é tabelado por hora de relógio):
##   · o SOL e a LUA são astros a sério: ângulo horário + declinação + latitude → elevação e
##     azimute. Sol: nasce às 06:00 a és-nordeste, culmina às 12:30 a sul (61,5°), põe-se às
##     19:00 a oés-noroeste. Lua (cheia, oposta): nasce às 18:30 a leste, culmina às 00:30 a sul
##     (52°), põe-se às 06:30 a oeste. Às 16:15 o sol está onde a Ordem 38 o pintou (az −110°,
##     elev 32°): a tarde da Ordem 38 é uma hora deste dia.
##   · as CORES saem da ELEVAÇÃO do sol (chaves em graus, interpoladas com suavidade), com uma
##     tabela para a manhã e outra para a tarde (madrugada rosa/dourada ≠ entardecer laranja/
##     vermelho); as duas coincidem de dia e de noite, por isso a troca nunca se vê.
##   · a luz-chave (a «luz pintada» dos shaders e a DirectionalLight do mundo) é o sol enquanto
##     ele está acima do horizonte e a lua de noite; entre os dois há um instante de crepúsculo
##     em que NENHUM dá luz directa (só céu): é aí que a direcção da luz troca, sem se ver.

signal fase_mudou(fase: String)

const Paleta := preload("res://mapa/floresta/paleta_floresta.gd")

## Segundos reais por dia do mundo (24 min: 1 minuto real = 1 hora do mundo).
const DURACAO_DIA_S := 1440.0
## No modo de prova o dia inteiro passa neste tempo.
const DURACAO_PROVA_S := 96.0
## A hora a que o mundo abre: a tarde da Ordem 38.
const HORA_INICIAL := 16.25

const LATITUDE := 38.0
const SOL_DECLINACAO := 9.5
const SOL_CULMINA := 12.5      # hora do meio-dia solar
const LUA_DECLINACAO := 0.0
const LUA_CULMINA := 0.5

## As chaves de elevação do sol (graus) a que as tabelas de cor estão escritas.
const ELEV: Array[float] = [-18.0, -9.0, -4.0, 0.0, 6.0, 14.0, 30.0]

# ---- o céu (tinta sRGB, como a paleta): zénite, meia altura, baixo, horizonte
const ZENITE_M: Array[String] = ["0b1535", "121f47", "20376d", "2f5294", "3a66a8", "3f70b2", "3f73b4"]
const ZENITE_T: Array[String] = ["0b1535", "121f47", "1f3268", "2c4a8c", "3a63a6", "3f70b2", "3f73b4"]
const MEIO_M: Array[String] = ["111e44", "1d2b58", "4c5a92", "8a9dc6", "8eaace", "84a8ce", "7fa6cf"]
const MEIO_T: Array[String] = ["111e44", "1f2a56", "4f4f84", "8f8db2", "90a4c6", "84a8ce", "7fa6cf"]
const BAIXO_M: Array[String] = ["182a55", "36406f", "b88a9c", "f0c2a6", "ecd4b6", "d4d0be", "bccbc4"]
const BAIXO_T: Array[String] = ["182a55", "453a60", "b86d5e", "f0985a", "ecb684", "dcc9aa", "bccbc4"]
const HORIZONTE_M: Array[String] = ["1d2f58", "4a4668", "b08488", "ecc09a", "ead0a2", "dcd1aa", "d6d0ab"]
const HORIZONTE_T: Array[String] = ["1d2f58", "553c52", "ae6650", "e68a4e", "e6ae76", "dec59a", "d6d0ab"]
## O arrebol: a faixa quente do lado do sol (cor e força).
const ARREBOL_M: Array[String] = ["40304f", "c0607a", "f08a7a", "ffbe7a", "ffd9a0", "ffe8c0", "ffe8c0"]
const ARREBOL_T: Array[String] = ["40304f", "a03a3a", "e8553a", "ff8a3a", "ffb86a", "ffe0b0", "ffe8c0"]
const ARREBOL_F: Array[float] = [0.0, 0.40, 0.92, 1.0, 0.60, 0.15, 0.0]
## As nuvens: o lado da luz e o lado da sombra.
const NUVEM_LUZ_M: Array[String] = ["2b3552", "4a4a72", "c08a96", "ffd0b4", "fff0d8", "fff8e8", "fff9e8"]
const NUVEM_LUZ_T: Array[String] = ["2b3552", "5a4064", "c8685a", "ffa06a", "ffd6a0", "fff4dc", "fff9e8"]
const NUVEM_SOMBRA_M: Array[String] = ["0f1830", "1e2748", "4a4a78", "8088b0", "98a4c0", "99abc2", "99abc2"]
const NUVEM_SOMBRA_T: Array[String] = ["0f1830", "22223f", "4a3a62", "7a6a90", "949ab8", "99abc2", "99abc2"]
## O disco do sol e o clarão à volta dele.
const DISCO_M: Array[String] = ["ff7a50", "ff7a50", "ff7a50", "ff8a58", "ffd088", "fff0c4", "fffff5"]
const DISCO_T: Array[String] = ["ff4a22", "ff4a22", "ff4a22", "ff5c2a", "ffb060", "ffeab8", "fffff5"]
const CLARAO_M: Array[String] = ["ffb090", "ffb090", "ffb090", "ffc49a", "ffe2b8", "fff2d4", "fff6de"]
const CLARAO_T: Array[String] = ["ff8a50", "ff8a50", "ff8a50", "ffa060", "ffd09a", "ffeccc", "fff6de"]

# ---- a luz
## A cor da luz do sol (a COR_SOL da paleta é a chave dos 30°).
const SOL_M: Array[String] = ["ff8a50", "ff8a50", "ff8a50", "ffa468", "ffc888", "ffdca6", "ffe6b4"]
const SOL_T: Array[String] = ["ff6a30", "ff6a30", "ff6a30", "ff8038", "ffb066", "ffd596", "ffe6b4"]
## A sombra colorida (nunca preta) e a luz do céu (ambiente): tinta e força.
const SOMBRA_M: Array[String] = ["2c4484", "344a88", "56609a", "62689a", "5a6692", "54658c", "52658a"]
const SOMBRA_T: Array[String] = ["2c4484", "3a4484", "5c5890", "6a6294", "5e6490", "54658c", "52658a"]
const AMBIENTE_M: Array[String] = ["4e6cc0", "5870c0", "7c88c0", "a8a8c4", "b0b0be", "a8b4be", "a3b4bd"]
const AMBIENTE_T: Array[String] = ["4e6cc0", "5c6ab8", "8880b4", "b49ea8", "b6a8ac", "a8b2ba", "a3b4bd"]
## Quanta luz o céu dá (1 = dia). De noite nunca chega a zero: noite jogável, nunca breu.
const CEU_LUZ: Array[float] = [0.20, 0.30, 0.44, 0.62, 0.82, 0.95, 1.0]

const COR_LUA := Color("#a9c0f2")
const LUA_ENERGIA := 0.36

# ---- a névoa por HORA (a madrugada tem bruma; o entardecer também, menos): hora, início (m),
# fim (m), tecto (opacidade máxima)
const NEVOA: Array = [
	[0.0, 38.0, 140.0, 0.86], [4.5, 34.0, 132.0, 0.88], [6.2, 26.0, 118.0, 0.93], [8.5, 40.0, 140.0, 0.86],
	[11.0, 48.0, 150.0, 0.80], [17.5, 48.0, 150.0, 0.80], [19.5, 40.0, 140.0, 0.85], [22.0, 38.0, 140.0, 0.86],
	[24.0, 38.0, 140.0, 0.86],
]

## Segundos reais por dia do mundo (o sítio único é DURACAO_DIA_S; aqui muda-se por cena).
@export var duracao_dia_s: float = DURACAO_DIA_S
@export var modo_prova: bool = false
## Parado: o relógio só anda por definir_hora()/avancar() (as ferramentas de filme usam isto).
@export var parado: bool = false

var hora: float = HORA_INICIAL
var dias: int = 0

var _estado: Dictionary = {}
var _hora_do_estado := -1.0
var _fase := ""


func _ready() -> void:
	add_to_group("relogio_mundo")
	_fase = fase()


func _process(delta: float) -> void:
	if not parado:
		avancar(delta)


# ------------------------------------------------------------------ API

func hora_do_mundo() -> float:
	return hora


func hora_texto() -> String:
	return texto_de(hora)


static func texto_de(h: float) -> String:
	var m := int(round(fposmod(h, 24.0) * 60.0)) % 1440
	return "%02d:%02d" % [m / 60, m % 60]


## Horas do mundo por segundo real, agora.
func ritmo() -> float:
	return 24.0 / maxf(DURACAO_PROVA_S if modo_prova else duracao_dia_s, 1.0)


func definir_hora(h: float) -> void:
	hora = fposmod(h, 24.0)
	_ver_fase()


## Avança o relógio `delta` segundos REAIS (ao ritmo do dia configurado).
func avancar(delta: float) -> void:
	avancar_horas(delta * ritmo())


func avancar_horas(dh: float) -> void:
	hora += dh
	while hora >= 24.0:
		hora -= 24.0
		dias += 1
	_ver_fase()


func fase() -> String:
	return fase_de(hora)


static func fase_de(h: float) -> String:
	var e := sol(h).y
	var manha := h < SOL_CULMINA and h > LUA_CULMINA
	if e < -6.0:
		return "noite"
	if e < 6.0:
		return "madrugada" if manha else "entardecer"
	if e < 30.0:
		return "manhã" if manha else "tarde"
	return "dia"


func estado() -> Dictionary:
	if not is_equal_approx(hora, _hora_do_estado):
		_estado = calcular(hora)
		_hora_do_estado = hora
	return _estado


func _ver_fase() -> void:
	var f := fase()
	if f != _fase:
		_fase = f
		fase_mudou.emit(f)


# ------------------------------------------------------------------ os astros

## (azimute, elevação) em graus de um astro com ângulo horário `h_graus` e declinação `decl`.
## Azimute a partir do norte, positivo para leste (a convenção da paleta).
static func astro(h_graus: float, decl: float) -> Vector2:
	var h := deg_to_rad(h_graus)
	var d := deg_to_rad(decl)
	var f := deg_to_rad(LATITUDE)
	var sen_el := sin(f) * sin(d) + cos(f) * cos(d) * cos(h)
	var leste := -cos(d) * sin(h)
	var norte := cos(f) * sin(d) - sin(f) * cos(d) * cos(h)
	return Vector2(rad_to_deg(atan2(leste, norte)), rad_to_deg(asin(clampf(sen_el, -1.0, 1.0))))


static func sol(h: float) -> Vector2:
	return astro((h - SOL_CULMINA) * 15.0, SOL_DECLINACAO)


static func lua(h: float) -> Vector2:
	return astro((h - LUA_CULMINA) * 15.0, LUA_DECLINACAO)


# ------------------------------------------------------------------ as tabelas

static func _suave(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Posição (índice, fracção suave) da elevação `e` nas chaves ELEV.
static func _onde(e: float) -> Vector2:
	if e <= ELEV[0]:
		return Vector2(0, 0)
	for i in ELEV.size() - 1:
		if e < ELEV[i + 1]:
			return Vector2(i, _suave(ELEV[i], ELEV[i + 1], e))
	return Vector2(ELEV.size() - 2, 1.0)


static func _tinta(tab: Array[String], onde: Vector2) -> Color:
	var i := int(onde.x)
	return Color(tab[i]).lerp(Color(tab[i + 1]), onde.y)


static func _cor(tab_m: Array[String], tab_t: Array[String], onde: Vector2, manha: float) -> Color:
	return _tinta(tab_t, onde).lerp(_tinta(tab_m, onde), manha)


static func _num(tab: Array[float], onde: Vector2) -> float:
	var i := int(onde.x)
	return lerpf(tab[i], tab[i + 1], onde.y)


## Curva por pontos (x crescente): interpolação suave entre chaves [x, y].
static func curva(chaves: Array, x: float, coluna: int = 1) -> float:
	if x <= float(chaves[0][0]):
		return float(chaves[0][coluna])
	for i in chaves.size() - 1:
		if x < float(chaves[i + 1][0]):
			return lerpf(float(chaves[i][coluna]), float(chaves[i + 1][coluna]), _suave(float(chaves[i][0]), float(chaves[i + 1][0]), x))
	return float(chaves[chaves.size() - 1][coluna])


## Escala uma tinta sRGB em LUZ (linear) e devolve-a em sRGB — para os uniforms source_color.
static func _escalar(c: Color, k: float) -> Color:
	var l := c.srgb_to_linear()
	return Color(l.r * k, l.g * k, l.b * k).linear_to_srgb()


static func _max_luz(a: Color, b: Color) -> Color:
	var la := a.srgb_to_linear()
	var lb := b.srgb_to_linear()
	return Color(maxf(la.r, lb.r), maxf(la.g, lb.g), maxf(la.b, lb.b)).linear_to_srgb()


# ------------------------------------------------------------------ tudo o que sai da hora

## Função PURA: a mesma hora dá sempre o mesmo mundo.
static func calcular(h: float) -> Dictionary:
	h = fposmod(h, 24.0)
	var s := sol(h)
	var l := lua(h)
	var e := s.y
	var onde := _onde(e)
	# manhã (1) ou tarde (0): troca suave à volta das culminações (onde as tabelas coincidem)
	var manha := _suave(LUA_CULMINA - 1.0, LUA_CULMINA + 1.0, h) * (1.0 - _suave(SOL_CULMINA - 1.0, SOL_CULMINA + 1.0, h))
	var d := {}
	d["hora"] = h
	d["sol_azimute"] = s.x
	d["sol_elevacao"] = e
	d["lua_azimute"] = l.x
	d["lua_elevacao"] = l.y
	d["dir_sol"] = Paleta.dir_de(s.x, e)
	d["dir_lua"] = Paleta.dir_de(l.x, l.y)
	d["manha"] = manha
	# ---- céu
	d["cor_zenite"] = _cor(ZENITE_M, ZENITE_T, onde, manha)
	d["cor_meio"] = _cor(MEIO_M, MEIO_T, onde, manha)
	d["cor_baixo"] = _cor(BAIXO_M, BAIXO_T, onde, manha)
	d["cor_horizonte"] = _cor(HORIZONTE_M, HORIZONTE_T, onde, manha)
	d["cor_arrebol"] = _cor(ARREBOL_M, ARREBOL_T, onde, manha)
	d["arrebol"] = _num(ARREBOL_F, onde)
	d["nuvem_luz"] = _cor(NUVEM_LUZ_M, NUVEM_LUZ_T, onde, manha)
	d["nuvem_sombra"] = _cor(NUVEM_SOMBRA_M, NUVEM_SOMBRA_T, onde, manha)
	d["cor_disco"] = _cor(DISCO_M, DISCO_T, onde, manha)
	d["cor_clarao"] = _cor(CLARAO_M, CLARAO_T, onde, manha)
	d["sol_visivel"] = _suave(-4.0, -0.8, e)
	d["estrelas"] = 1.0 - _suave(-13.0, -4.0, e)
	d["noite"] = 1.0 - _suave(-11.0, -2.0, e)
	d["lua_noite"] = 1.0 - _suave(-8.0, 3.0, e)
	# ---- luz
	# o sol dá luz directa de −1,5° para cima; ao meio-dia baixa um pouco (o chão plano recebe-o
	# de frente: sem isto estourava)
	var sol_energia := curva([[-1.5, 0.0], [2.0, 0.40], [6.0, 0.66], [14.0, 0.86], [30.0, 1.0], [45.0, 0.93], [62.0, 0.86]], e)
	# a lua só conta com o sol bem posto, e sobe com a elevação dela
	# (sessão 3) com a lua baixa a luz rasante quase não toca o chão plano: o crepúsculo (19:45)
	# ficava MAIS escuro que a noite cerrada. A lua baixa ganha força até 1,35× (a 8°) e volta a
	# 1× aos 35° — a noite lê-se igual de ponta a ponta, sem quebra
	var lua_baixa := lerpf(1.35, 1.0, _suave(8.0, 35.0, l.y))
	var lua_energia := LUA_ENERGIA * lua_baixa * (1.0 - _suave(-7.0, -2.2, e)) * _suave(0.0, 12.0, l.y)
	var ceu_luz := _num(CEU_LUZ, onde)
	# (sessão 3) QUEM é a luz-chave: um PESO contínuo (0 = lua, 1 = sol), não um interruptor. A
	# passagem faz-se com o sol entre −5° e −1° (~20 min do mundo) — à volta da janela em que nenhum astro dá luz directa
	# que se veja. Antes era um interruptor: a direcção da luz saltava ~180° (da lua a oeste
	# para o sol a leste) de um minuto do mundo para o seguinte, às 05:49 e às 19:12.
	var peso_sol := _suave(-5.0, -1.0, e)
	var de_sol := peso_sol >= 0.5
	d["luz_e_sol"] = de_sol
	d["peso_sol"] = peso_sol
	d["sol_energia"] = sol_energia
	d["lua_energia"] = lua_energia
	d["ceu_luz"] = ceu_luz
	var cor_sol := _cor(SOL_M, SOL_T, onde, manha)
	if e > 30.0:
		cor_sol = cor_sol.lerp(Color("#fff4de"), _suave(30.0, 60.0, e))
	d["cor_luz_sol"] = cor_sol
	var sombra := _escalar(_cor(SOMBRA_M, SOMBRA_T, onde, manha), ceu_luz)
	var ambiente := _escalar(_cor(AMBIENTE_M, AMBIENTE_T, onde, manha), ceu_luz)
	d["cor_sombra"] = sombra
	d["cor_ceu"] = ambiente
	# a luz-chave dos shaders pintados: nunca abaixo do enchimento de sombra (senão a sombra
	# ficava MAIS clara que a luz no crepúsculo)
	# (as duas energias nunca se sobrepõem: o sol acende aos −1,5°, a lua apaga aos −2,2°)
	var chave := _max_luz(_escalar(cor_sol, sol_energia), _escalar(COR_LUA, lua_energia))
	d["cor_luz"] = _max_luz(chave, _escalar(sombra, 0.46))
	# a direcção da luz-chave; com o astro rasante a geometria da luz fica presa nos 3° (a luz
	# já vem quase a zero nessa altura). Na passagem lua↔sol a direcção RODA por cima (a soma
	# dos dois vectores quase opostos passa pelo alto): sem salto, e com a luz no mínimo
	var d_sol := Paleta.dir_de(s.x, maxf(e, 3.0))
	var d_lua := Paleta.dir_de(l.x, maxf(l.y, 3.0))
	# (rotação a passo certo: da lua sobe ao zénite, do zénite desce ao sol — slerp em duas
	# metades; a soma linear de dois vectores quase opostos rodava quase tudo no meio)
	var dl := d_lua.slerp(Vector3.UP, peso_sol * 2.0) if peso_sol < 0.5 else Vector3.UP.slerp(d_sol, peso_sol * 2.0 - 1.0)
	d["dir_luz"] = dl
	d["luz_azimute"] = rad_to_deg(atan2(dl.x, -dl.z)) if Vector2(dl.x, dl.z).length() > 0.001 else 0.0
	d["luz_elevacao"] = rad_to_deg(asin(clampf(dl.y, -1.0, 1.0)))
	# as sombras: francas de dia, suaves ao luar, nenhumas no crepúsculo sem luz directa
	d["sombra_forca"] = maxf(_suave(0.0, 0.5, sol_energia), 0.62 * _suave(0.0, 0.5 * LUA_ENERGIA, lua_energia))
	d["ressalto"] = clampf(maxf(sol_energia, lua_energia * 0.5) * 0.8 + ceu_luz * 0.2, 0.0, 1.0)
	# as luzes artificiais (lanternas, janelas): acendem quando o sol toca o horizonte
	d["lume"] = 1.0 - _suave(-4.0, 1.5, e)
	# ---- névoa
	d["nevoa_inicio"] = curva(NEVOA, h, 1)
	d["nevoa_fim"] = curva(NEVOA, h, 2)
	d["nevoa_tecto"] = curva(NEVOA, h, 3)
	return d
