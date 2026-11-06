@tool
class_name ColorScript
extends Resource
## color_script.gd — Assimilação, missão V1.1 (Plano B v1.1, B2.1 item 1; base da V4.3)
##
## Color script das 4 horas: chave (luz do sol), sombra, contorno, neblina e céu (3 cores), em hex.
## amostrar(hora) interpola 0-24 h; aplicar(...) escreve o resultado na cena.
##
## >>> PROVISÓRIO até ao guia V0.1 (Muse). Os hex são um andaime a partir da repintura Arcane
## >>> aprovada; a V0.1 fixa os definitivos. Regra fixa: "sombra" é azul ou roxo, nunca preto
## >>> (B3: croma >= 6, matiz entre 230° e 320°).
##
## Interpolação: igual ao ceu_pintado.gdshader (por_hora). Entre chaves, smoothstep; a mistura
## das cores é feita em espaço linear.

const PROVISORIO := true
const ORDEM := ["manha", "tarde", "crepusculo", "noite"]
const CAMPOS_COR := ["chave", "sombra", "contorno", "neblina", "ceu_topo", "ceu_horizonte", "ceu_baixo"]

@export var horas_chave: Dictionary = {
	"manha": 8.0,
	"tarde": 15.0,
	"crepusculo": 18.5,
	"noite": 22.0,
}

@export var paleta: Dictionary = {
	"manha": {
		"chave": "#FFE2B8", "sombra": "#4A5A9E", "contorno": "#3B2E5A", "neblina": "#C9D3E6",
		"ceu_topo": "#6F9BD8", "ceu_horizonte": "#F2D9B8", "ceu_baixo": "#8A93A8",
		"energia_chave": 1.0,
	},
	"tarde": {
		"chave": "#FFF1DA", "sombra": "#4E5FA8", "contorno": "#352C55", "neblina": "#D2DCE6",
		"ceu_topo": "#4A86D9", "ceu_horizonte": "#D8E4E8", "ceu_baixo": "#7F9099",
		"energia_chave": 1.1,
	},
	"crepusculo": {
		"chave": "#FF9E6B", "sombra": "#5B3F8C", "contorno": "#3A2348", "neblina": "#B98A9A",
		"ceu_topo": "#3E3A7A", "ceu_horizonte": "#F89664", "ceu_baixo": "#5A4668",
		"energia_chave": 0.75,
	},
	"noite": {
		"chave": "#9FB4FF", "sombra": "#2E3470", "contorno": "#1E1F40", "neblina": "#2A3050",
		"ceu_topo": "#10122E", "ceu_horizonte": "#2E315A", "ceu_baixo": "#17182D",
		"energia_chave": 0.25,
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
