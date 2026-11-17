@tool
class_name ColorScript
extends Resource
## color_script.gd — Assimilação, kit de arte (missão V1.1, B2.1 item 1; base da V4.3; fechado na Ordem 65)
##
## Color script das 4 horas: chave (luz do sol), sombra, contorno, neblina e céu (3 cores), em hex.
## amostrar(hora) interpola 0-24 h; aplicar(...) escreve o resultado na cena.
##
## A PALETA É A DA CASA (Ordem 65). Cada hora-chave é uma amostra do ciclo do dia que já corre no
## mapa da floresta (mapa/floresta/ciclo_dia.gd + paleta_floresta.gd), lida nessa mesma hora:
##   manhã 6,5 h (sol a 5,8° a nascente) · tarde 15 h (sol a 45,9°) · crepúsculo 18,5 h (sol a 5,8°
##   a poente) · noite 22 h (noite cerrada, lua cheia).
## De onde vem cada campo:
##   chave          a cor da luz do sol nessa hora (tabelas SOL_M/SOL_T); de noite, a cor da lua
##   energia_chave  a energia do sol nessa hora (a curva do ciclo); de noite, a energia da lua
##   sombra         a tinta da sombra nessa hora (tabelas SOMBRA_M/SOMBRA_T). Regra fixa: azul ou
##                  roxo, nunca preto (B3: croma >= 6, matiz entre 230° e 320° — as 4 medem
##                  croma 23 a 41 e matiz 277° a 290°)
##   contorno       a sombra da hora escurecida a 35% (em luz linear) — o fator_escuro por omissão
##                  do contorno_casca; o shader só lhe usa o matiz
##   neblina        igual ao ceu_horizonte (regra anti-costura da paleta: o ar e o horizonte são
##                  uma só cor)
##   ceu_topo       o zénite do céu da casa (tabelas ZENITE_M/ZENITE_T)
##   ceu_horizonte  o horizonte do céu da casa (tabelas HORIZONTE_M/HORIZONTE_T)
##   ceu_baixo      o que fica abaixo do horizonte: 40% horizonte + 60% sombra da casa nessa hora
##                  (a sombra já escalada pela luz do céu), misturados em luz linear
##
## Interpolação: igual ao ceu_pintado.gdshader (por_hora). Entre chaves, smoothstep; a mistura
## das cores é feita em espaço linear.

const ORDEM := ["manha", "tarde", "crepusculo", "noite"]
const CAMPOS_COR := ["chave", "sombra", "contorno", "neblina", "ceu_topo", "ceu_horizonte", "ceu_baixo"]

@export var horas_chave: Dictionary = {
	"manha": 6.5,
	"tarde": 15.0,
	"crepusculo": 18.5,
	"noite": 22.0,
}

@export var paleta: Dictionary = {
	"manha": {
		"chave": "#FFC888", "sombra": "#5A6692", "contorno": "#353D59", "neblina": "#EAD0A2",
		"ceu_topo": "#3A66A8", "ceu_horizonte": "#EAD0A2", "ceu_baixo": "#A69991",
		"energia_chave": 0.66,
	},
	"tarde": {
		"chave": "#FFEECB", "sombra": "#52658A", "contorno": "#303C54", "neblina": "#D6D0AB",
		"ceu_topo": "#3F73B4", "ceu_horizonte": "#D6D0AB", "ceu_baixo": "#999C98",
		"energia_chave": 0.93,
	},
	"crepusculo": {
		"chave": "#FFB066", "sombra": "#5E6490", "contorno": "#383C58", "neblina": "#E6AE76",
		"ceu_topo": "#3A63A6", "ceu_horizonte": "#E6AE76", "ceu_baixo": "#A4847E",
		"energia_chave": 0.66,
	},
	"noite": {
		"chave": "#A9C0F2", "sombra": "#2C4484", "contorno": "#172750", "neblina": "#1D2F58",
		"ceu_topo": "#0B1535", "ceu_horizonte": "#1D2F58", "ceu_baixo": "#162549",
		"energia_chave": 0.36,
	},
}


## Devolve { "chave": Color, "sombra": Color, ..., "energia_chave": float } para a hora (0-24).
func amostrar(hora: float) -> Dictionary:
	var seg := _segmento(fposmod(hora, 24.0))
	var a: Dictionary = paleta[seg[0]]
	var b: Dictionary = paleta[seg[1]]
	var t: float = seg[2]
	var saida := {}
	for campo in CAMPOS_COR:
		saida[campo] = _mistura_hex(a[campo], b[campo], t)
	saida["energia_chave"] = lerpf(float(a["energia_chave"]), float(b["energia_chave"]), t)
	return saida


## Escreve a hora na cena. Qualquer argumento pode ser null.
## materiais_luz: ShaderMaterial com toon_pintado / folhagem_vento (recebem cor_sombra).
## materiais_contorno: ShaderMaterial com contorno_casca (recebem tinta_contorno).
## material_ceu: ShaderMaterial com ceu_pintado (recebe "hora"; as 12 cores via preencher_ceu).
func aplicar(hora: float, sol: DirectionalLight3D, ambiente: Environment,
		materiais_luz: Array = [], materiais_contorno: Array = [],
		material_ceu: ShaderMaterial = null) -> void:
	var c := amostrar(hora)
	if sol:
		sol.light_color = c["chave"]
		sol.light_energy = c["energia_chave"]
	if ambiente:
		ambiente.ambient_light_color = c["sombra"]
		ambiente.fog_light_color = c["neblina"]
	for m in materiais_luz:
		if m is ShaderMaterial:
			m.set_shader_parameter("cor_sombra", c["sombra"])
	for m in materiais_contorno:
		if m is ShaderMaterial:
			m.set_shader_parameter("tinta_contorno", c["contorno"])
	if material_ceu:
		material_ceu.set_shader_parameter("hora", fposmod(hora, 24.0))


## Copia as horas-chave e as 12 cores de céu deste recurso para o ceu_pintado.gdshader.
func preencher_ceu(material_ceu: ShaderMaterial) -> void:
	for nome in ORDEM:
		var p: Dictionary = paleta[nome]
		material_ceu.set_shader_parameter("hora_%s" % nome, float(horas_chave[nome]))
		material_ceu.set_shader_parameter("topo_%s" % nome, Color.html(p["ceu_topo"]))
		material_ceu.set_shader_parameter("horizonte_%s" % nome, Color.html(p["ceu_horizonte"]))
		material_ceu.set_shader_parameter("baixo_%s" % nome, Color.html(p["ceu_baixo"]))


## [nome_a, nome_b, t] — chaves cíclicas; da noite passa-se à manhã do dia seguinte.
func _segmento(h: float) -> Array:
	for i in range(ORDEM.size() - 1):
		var ha := float(horas_chave[ORDEM[i]])
		var hb := float(horas_chave[ORDEM[i + 1]])
		if h >= ha and h < hb:
			return [ORDEM[i], ORDEM[i + 1], smoothstep(ha, hb, h)]
	var hn := float(horas_chave["noite"])
	var hm := float(horas_chave["manha"]) + 24.0
	var hh := h + 24.0 if h < float(horas_chave["manha"]) else h
	return ["noite", "manha", smoothstep(hn, hm, hh)]


func _mistura_hex(a: String, b: String, t: float) -> Color:
	var ca := Color.html(a).srgb_to_linear()
	var cb := Color.html(b).srgb_to_linear()
	return ca.lerp(cb, t).linear_to_srgb()
