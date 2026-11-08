extends CanvasLayer
## HUD da jogadora (JV2.3, pelo que o Mestre aprovou; o visual fino é da V1.2).
##
## - Barra SÓ com Ataque · Mover · Consumível, e Encerrar quando a vez é dela (palavra do Mestre).
## - ⚙ no canto SUPERIOR ESQUERDO com TODAS as configurações (gráficos, câmera, zoom,
##   tela vermelha com 2 interruptores, sair da mesa).
## - Painéis a 55% de opacidade, texto sólido.
## - Números de dano flutuantes por tipo, também nos golpes recebidos (só os que o servidor deixa ela ver).
## - Tela vermelha gradual desde 25% da vida DELA, com pulso.
## - Safe-area; textos com 12 px reais ou mais; nada técnico na tela.
## - Mostra ROOM_OPTIONS como o servidor as manda: nunca calcula alcance, caminho nem CA.
## A entrada (nome e senha) é do lobby (cenas/lobby).

signal modo_pedido(modo: int, extra: Dictionary)
signal acao_pedida(acao: Dictionary)
signal preferencia_mudou(chave: String, valor: Variant)

const Arena := preload("res://cenas/arena/arena.gd")

const ARQ_PREF := "user://preferencias.cfg"
const LARGURA_BASE := 1920.0
const ALTURA_BASE := 1080.0
const FONTE_BASE := 22
const FONTE_MIN_PX_REAIS := 13.0  # acima dos 12 px pedidos
const MARGEM_BASE := 24.0
const OPACIDADE_PAINEL := 0.55
const LIMIAR_TELA_VERMELHA := 0.25
const PERFIS := ["baixo", "medio", "alto"]
const NOMES_PERFIS := ["Baixo", "Médio", "Alto"]
const CAMERAS := ["fixa", "360", "panorama"]
const NOMES_CAMERAS := ["Fixa", "360°", "Panorama"]
## PROVISÓRIO: a paleta final é da V1.2 (Plano B). As chaves "cortante" e "perfurante"
## são as das fichas de exemplo do servidor (campo `tipo`/`tipos` das técnicas).
const CORES_DANO := {
	"fisico": Color(1.0, 0.96, 0.88),
	"corte": Color(1.0, 0.85, 0.80),
	"cortante": Color(1.0, 0.85, 0.80),
	"perfuracao": Color(1.0, 0.90, 0.75),
	"perfurante": Color(1.0, 0.90, 0.75),
	"impacto": Color(0.95, 0.90, 0.80),
	"contundente": Color(0.95, 0.90, 0.80),
	"agua": Color(0.40, 0.75, 1.0),
	"fogo": Color(1.0, 0.55, 0.15),
	"eletrico": Color(1.0, 0.95, 0.30),
	"gelo": Color(0.75, 0.95, 1.0),
	"veneno": Color(0.55, 0.95, 0.35),
	"cura": Color(0.45, 1.0, 0.60),
}
## `resultado` do evento `ataque` (sala.js RESULTADOS) → frase simples.
const FRASES_ATAQUE := {
	"acerto": "Acertou!",
	"erro": "Errou.",
	"critico": "Crítico!",
	"falha_critica": "Falha crítica!",
}
## TODO(FRASES-DESGRACA, I0004 08/11): aqui entram as frases das desgraças e do teste de morte, iguais
## às do site vivo (o Muse manda a lista). Ver estado.gd, ramo `_` de aplicar o evento.
const SHADER_TELA_VERMELHA := """
shader_type canvas_item;
uniform float intensidade : hint_range(0.0, 1.0) = 0.0;
uniform vec4 cor : source_color = vec4(0.75, 0.0, 0.0, 1.0);
void fragment() {
	vec2 c = (UV - vec2(0.5)) * vec2(2.0, 2.0);
	float d = length(c * vec2(1.0, 0.8));
	float borda = smoothstep(0.30, 1.15, d);
	COLOR = vec4(cor.rgb, intensidade * mix(0.18, 0.85, borda));
}
"""

var arena = null  # a cena da arena (definida por ela)
var pref := {"perfil": "medio", "camera": "fixa", "tela_vermelha": true, "pulso": true}

@onready var _raiz: Control = $Raiz
@onready var _tela_vermelha: ColorRect = $Raiz/TelaVermelha
@onready var _numeros: Control = $Raiz/Numeros
@onready var _seguro: MarginContainer = $Raiz/Seguro
@onready var _faixa: Label = $Raiz/Seguro/Camadas/Faixa
@onready var _aviso: Label = $Raiz/Seguro/Camadas/Aviso
@onready var _coluna: VBoxContainer = $Raiz/Seguro/Camadas/ColunaEsquerda
@onready var _botao_config: Button = $Raiz/Seguro/Camadas/ColunaEsquerda/BotaoConfig
@onready var _painel_config: PanelContainer = $Raiz/Seguro/Camadas/ColunaEsquerda/PainelConfig
@onready var _barra: HBoxContainer = $Raiz/Seguro/Camadas/Barra
@onready var _b_ataque: Button = $Raiz/Seguro/Camadas/Barra/BotaoAtaque
@onready var _b_mover: Button = $Raiz/Seguro/Camadas/Barra/BotaoMover
@onready var _b_consumivel: Button = $Raiz/Seguro/Camadas/Barra/BotaoConsumivel
@onready var _b_encerrar: Button = $Raiz/Seguro/Camadas/Barra/BotaoEncerrar
@onready var _painel_escolha: PanelContainer = $Raiz/Seguro/Camadas/PainelEscolha

var _tema := Theme.new()
var _escala := 1.0
var _fonte := FONTE_BASE
var _modo_atual: int = Arena.Modo.NENHUM
var _tempo := 0.0
var _aviso_restante := 0.0
var _mat_vermelha: ShaderMaterial
var _reacao_mostrada := ""

var _op_perfil: OptionButton
var _op_camera: OptionButton
var _chk_vermelha: CheckButton
var _chk_pulso: CheckButton
var _caixa_escolha: VBoxContainer
var _titulo_escolha: Label


func _ready() -> void:
	_carregar_preferencias()
	_montar_tema()
	_montar_layout()
	_montar_config()
	_montar_escolha()
	_montar_tela_vermelha()
	get_viewport().size_changed.connect(_ao_redimensionar)
	_ao_redimensionar()

	_botao_config.pressed.connect(_alternar_config)
	_botao_config.draw.connect(_desenhar_engrenagem)
	_b_ataque.pressed.connect(_ao_botao.bind(Arena.Modo.ATAQUE))
	_b_mover.pressed.connect(_ao_botao.bind(Arena.Modo.MOVER))
	_b_consumivel.pressed.connect(_ao_botao_consumivel)
	_b_encerrar.pressed.connect(_pedir_encerrar)

	Rede.ligacao_mudou.connect(_ao_ligacao)
	Rede.recibo_recebido.connect(_ao_recibo)
	Rede.recusa_recebida.connect(_ao_recusa)
	Rede.erro_recebido.connect(_ao_erro)
	Estado.opcoes_mudaram.connect(_atualizar)
	Estado.snapshot_aplicado.connect(_atualizar)
	Estado.evento_aplicado.connect(_ao_evento)
	Estado.pausa_mudou.connect(_ao_pausa)
	Estado.dano_visto.connect(_ao_dano)
	Estado.ataque_visto.connect(_ao_ataque)
	Estado.fase_mudou.connect(_ao_fase)
	_atualizar()


func _process(delta: float) -> void:
	_tempo += delta
	_atualizar_tela_vermelha()
	if _aviso_restante > 0.0:
		_aviso_restante -= delta
		if _aviso_restante <= 0.0:
			_aviso.visible = false


# ---------------------------------------------------------------- API usada pela arena

func aplicar_preferencias_iniciais() -> void:
	for k in pref:
		preferencia_mudou.emit(k, pref[k])


func ao_modo_mudou(m: int) -> void:
	_modo_atual = m
	_b_ataque.set_pressed_no_signal(m == Arena.Modo.ATAQUE)
	_b_mover.set_pressed_no_signal(m == Arena.Modo.MOVER)
	_b_consumivel.set_pressed_no_signal(m == Arena.Modo.CONSUMIVEL)
	_faixa.text = _texto_faixa()


## Mostra uma lista de escolhas. `itens` = [[texto, Callable], ...]
func escolher(titulo: String, itens: Array) -> void:
	_titulo_escolha.text = titulo
	for n in _caixa_escolha.get_children():
		if n != _titulo_escolha:
			n.queue_free()
	for par in itens:
		var b := Button.new()
		b.text = str(par[0])
		var cb: Callable = par[1]
		b.pressed.connect(_ao_escolha.bind(cb))
		_caixa_escolha.add_child(b)
	var cancelar := Button.new()
	cancelar.text = "Cancelar"
	cancelar.pressed.connect(_ao_escolha.bind(Callable()))
	_caixa_escolha.add_child(cancelar)
	_painel_escolha.visible = true
	_ancorar.call_deferred(_painel_escolha, Control.PRESET_CENTER)


## Nome para mostrar. Nunca mostra um id opaco: usa `nome`, um id legível, ou `padrao`.
## (A `arma` do ROOM_OPTIONS é o id da técnica, ex.: "chicote-teste" → "Chicote teste".)
func nome_legivel(v, nome, padrao: String) -> String:
	if nome is String and nome != "":
		return nome
	if v is Dictionary and v.get("nome") is String:
		return v["nome"]
	if v is String:
		var re := RegEx.create_from_string("^[a-z]+(-[a-z]+)*$")
		if re.search(v) != null:
			var t: String = v.replace("-", " ")
			return t.substr(0, 1).to_upper() + t.substr(1)
	return padrao


# ---------------------------------------------------------------- montagem

func _montar_tema() -> void:
	var painel := StyleBoxFlat.new()
	painel.bg_color = Color(0.06, 0.07, 0.10, OPACIDADE_PAINEL)
	painel.set_corner_radius_all(14)
	painel.set_content_margin_all(18)
	_tema.set_stylebox("panel", "PanelContainer", painel)
	var estilos := {
		"normal": Color(0.10, 0.12, 0.16, OPACIDADE_PAINEL),
		"hover": Color(0.16, 0.19, 0.25, OPACIDADE_PAINEL + 0.1),
		"pressed": Color(0.20, 0.40, 0.65, 0.85),
		"disabled": Color(0.10, 0.12, 0.16, 0.35),
	}
	for nome in estilos:
		var sb := StyleBoxFlat.new()
		sb.bg_color = estilos[nome]
		sb.set_corner_radius_all(12)
		sb.set_content_margin_all(12)
		_tema.set_stylebox(nome, "Button", sb)
	var foco := StyleBoxFlat.new()
	foco.draw_center = false
	foco.set_border_width_all(3)
	foco.border_color = Color(1.0, 0.9, 0.4)
	foco.set_corner_radius_all(12)
	_tema.set_stylebox("focus", "Button", foco)
	_tema.set_color("font_color", "Label", Color.WHITE)
	_tema.set_color("font_color", "Button", Color.WHITE)
	_tema.set_color("font_pressed_color", "Button", Color.WHITE)
	_tema.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.45))
	_raiz.theme = _tema


func _montar_layout() -> void:
	for c in [_raiz, _tela_vermelha, _numeros, _seguro]:
		(c as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tela_vermelha.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_numeros.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seguro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Raiz/Seguro/Camadas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_coluna.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_barra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_faixa.add_theme_constant_override("outline_size", 8)
	_faixa.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_aviso.add_theme_constant_override("outline_size", 8)
	_aviso.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_botao_config.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_coluna.add_theme_constant_override("separation", 10)
	_barra.add_theme_constant_override("separation", 14)


func _montar_config() -> void:
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 12)
	_painel_config.add_child(caixa)
	var titulo := Label.new()
	titulo.text = "Configurações"
	caixa.add_child(titulo)

	_op_perfil = OptionButton.new()
	for i in NOMES_PERFIS.size():
		_op_perfil.add_item(NOMES_PERFIS[i], i)
	_op_perfil.select(maxi(0, PERFIS.find(pref["perfil"])))
	_op_perfil.item_selected.connect(_ao_perfil)
	caixa.add_child(_linha("Gráficos", _op_perfil))

	_op_camera = OptionButton.new()
	for i in NOMES_CAMERAS.size():
		_op_camera.add_item(NOMES_CAMERAS[i], i)
	_op_camera.select(maxi(0, CAMERAS.find(pref["camera"])))
	_op_camera.item_selected.connect(_ao_camera)
	caixa.add_child(_linha("Câmera", _op_camera))

	var repor := Button.new()
	repor.text = "Repor o zoom"
	repor.pressed.connect(_ao_repor_zoom)
	caixa.add_child(repor)

	_chk_vermelha = CheckButton.new()
	_chk_vermelha.text = "Tela vermelha"
	_chk_vermelha.set_pressed_no_signal(bool(pref["tela_vermelha"]))
	_chk_vermelha.toggled.connect(_ao_chk_vermelha)
	caixa.add_child(_chk_vermelha)

	_chk_pulso = CheckButton.new()
	_chk_pulso.text = "Pulso da tela vermelha"
	_chk_pulso.set_pressed_no_signal(bool(pref["pulso"]))
	_chk_pulso.toggled.connect(_ao_chk_pulso)
	caixa.add_child(_chk_pulso)

	var sair := Button.new()
	sair.text = "Sair da mesa"
	sair.pressed.connect(_pedir_sair)
	caixa.add_child(sair)

	var fechar := Button.new()
	fechar.text = "Fechar"
	fechar.pressed.connect(_fechar_config)
	caixa.add_child(fechar)


func _linha(texto: String, controle: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	var l := Label.new()
	l.text = texto
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	h.add_child(controle)
	return h


func _montar_escolha() -> void:
	_caixa_escolha = VBoxContainer.new()
	_caixa_escolha.add_theme_constant_override("separation", 12)
	_painel_escolha.add_child(_caixa_escolha)
	_titulo_escolha = Label.new()
	_titulo_escolha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caixa_escolha.add_child(_titulo_escolha)


func _montar_tela_vermelha() -> void:
	var sh := Shader.new()
	sh.code = SHADER_TELA_VERMELHA
	_mat_vermelha = ShaderMaterial.new()
	_mat_vermelha.shader = sh
	_tela_vermelha.material = _mat_vermelha
	_tela_vermelha.color = Color.WHITE
	_tela_vermelha.visible = false


# ---------------------------------------------------------------- tamanho, letra e safe-area

func _ao_redimensionar() -> void:
	var janela := Vector2(get_window().size)
	_escala = minf(janela.x / LARGURA_BASE, janela.y / ALTURA_BASE)
	if _escala <= 0.0:
		_escala = 1.0
	# canvas_items + expand: 1 unidade = _escala px reais. Garante ≥ 13 px reais.
	_fonte = maxi(FONTE_BASE, ceili(FONTE_MIN_PX_REAIS / _escala))
	_tema.default_font_size = _fonte
	var lado := float(_fonte) * 2.4
	_botao_config.custom_minimum_size = Vector2(lado, lado)
	for b in [_b_ataque, _b_mover, _b_consumivel, _b_encerrar]:
		(b as Button).custom_minimum_size = Vector2(_fonte * 7.5, _fonte * 2.8)
	_painel_config.custom_minimum_size = Vector2(_fonte * 17.0, 0.0)
	_painel_escolha.custom_minimum_size = Vector2(_fonte * 12.0, 0.0)
	_aplicar_safe_area()
	_reposicionar.call_deferred()


func _aplicar_safe_area() -> void:
	var esq := 0.0
	var topo := 0.0
	var dir := 0.0
	var baixo := 0.0
	if OS.has_feature("mobile"):
		# Só Android/iOS implementam; noutras plataformas devolve a área útil do ecrã.
		var seguro := DisplayServer.get_display_safe_area()
		var tela := DisplayServer.screen_get_size()
		esq = maxf(0.0, seguro.position.x)
		topo = maxf(0.0, seguro.position.y)
		dir = maxf(0.0, tela.x - seguro.end.x)
		baixo = maxf(0.0, tela.y - seguro.end.y)
	_seguro.add_theme_constant_override("margin_left", int(MARGEM_BASE + esq / _escala))
	_seguro.add_theme_constant_override("margin_top", int(MARGEM_BASE + topo / _escala))
	_seguro.add_theme_constant_override("margin_right", int(MARGEM_BASE + dir / _escala))
	_seguro.add_theme_constant_override("margin_bottom", int(MARGEM_BASE + baixo / _escala))


func _reposicionar() -> void:
	_faixa.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_faixa.offset_left = float(_fonte) * 3.5  # não passa por cima da ⚙
	_faixa.offset_right = -float(_fonte) * 3.5
	_aviso.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_aviso.offset_top = float(_fonte) * 2.4
	_aviso.offset_left = float(_fonte) * 3.5
	_aviso.offset_right = -float(_fonte) * 3.5
	_ancorar(_coluna, Control.PRESET_TOP_LEFT)
	_ancorar(_barra, Control.PRESET_CENTER_BOTTOM)
	_barra.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_ancorar(_painel_escolha, Control.PRESET_CENTER)


func _ancorar(c: Control, preset: int) -> void:
	c.reset_size()
	c.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE)
	c.grow_horizontal = Control.GROW_DIRECTION_BOTH if preset != Control.PRESET_TOP_LEFT else Control.GROW_DIRECTION_END


func _desenhar_engrenagem() -> void:
	var b := _botao_config
	var c := b.size * 0.5
	var r := minf(b.size.x, b.size.y) * 0.26
	var cor := Color.WHITE
	for i in 8:
		b.draw_set_transform(c, TAU * float(i) / 8.0, Vector2.ONE)
		b.draw_rect(Rect2(Vector2(-r * 0.22, -r * 1.4), Vector2(r * 0.44, r * 0.6)), cor)
	b.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	b.draw_circle(c, r, cor)
	b.draw_circle(c, r * 0.42, Color(0.10, 0.12, 0.16, 1.0))


# ---------------------------------------------------------------- estado da tela

func _atualizar() -> void:
	var na_mesa: bool = Rede.na_mesa()
	var livre: bool = na_mesa and not Estado.pausada and not Rede.ha_intencao_em_voo() and not Rede.aguardando_mestre()
	_b_ataque.disabled = not livre or Estado.lista_opcao("ataques").is_empty()
	_b_mover.disabled = not livre or Estado.lista_opcao("mover").is_empty()
	_b_consumivel.disabled = not livre or Estado.lista_opcao("consumiveis").is_empty()
	# Encerrar só aparece quando a vez é dela e o servidor o pôs em `acoes`.
	_b_encerrar.visible = Estado.e_minha_vez() and Estado.tem_acao("encerrar")
	_b_encerrar.disabled = not livre
	_barra.visible = na_mesa and Estado.fase == "combate"
	_faixa.text = _texto_faixa()
	_ver_reacao(livre)


func _texto_faixa() -> String:
	if Rede.a_ligar():
		return "A conexão caiu. Voltando à mesa..." if Rede.ja_esteve_na_mesa() else "Conectando à mesa..."
	if not Rede.na_mesa():
		return ""
	if Estado.pausada:
		return "A mesa está em pausa. O Mestre já volta."
	if Rede.aguardando_mestre():
		return "O Mestre está decidindo..."
	if Estado.fase == "lobby":
		return "Esperando o Mestre começar..."
	if Estado.fase == "fim":
		if Estado.desfecho == "vitoria":
			return "Vitória!"
		return "Fim da batalha"
	if Estado.e_minha_vez():
		var orc: float = Estado.orcamento_m()
		if _modo_atual == Arena.Modo.MOVER and orc >= 0.0:
			return "Sua vez · pode andar até %s m" % _metros(orc)
		return "Sua vez"
	if Estado.vez_id != "":
		var f = Estado.figuras.get(Estado.vez_id)
		if Estado.e_jogadora(f) and Estado.nome_de(Estado.vez_id) != "":
			return "Vez de %s" % Estado.nome_de(Estado.vez_id)
		return "O Mestre narra"  # E-P11: igual para qualquer modo da criatura
	return ""


func _metros(m: float) -> String:
	return ("%.1f" % m).replace(".", ",")


func _ver_reacao(livre: bool) -> void:
	# TODO(JV1.x A-4): o servidor ainda manda `reacoes: []` sempre; a forma final vem com a janela de reação.
	var reacoes := Estado.lista_opcao("reacoes")
	if reacoes.is_empty() or not livre:
		return
	var r = reacoes[0]
	if not (r is Dictionary) or not (r.get("reacaoId") is String):
		return
	var rid: String = r["reacaoId"]
	if rid == _reacao_mostrada:
		return
	_reacao_mostrada = rid
	escolher("Reagir agora?", [
		["Sim", _emitir_acao.bind({"tipo": "reacao", "reacaoId": rid, "aceitar": true})],
		["Não", _emitir_acao.bind({"tipo": "reacao", "reacaoId": rid, "aceitar": false})],
	])


func _atualizar_tela_vermelha() -> void:
	var intensidade := 0.0
	if bool(pref["tela_vermelha"]):
		var f: float = Estado.vida_fracao_propria()
		if f >= 0.0 and f <= LIMIAR_TELA_VERMELHA:
			# Gradual: começa fraca nos 25% e chega ao máximo na vida zero.
			intensidade = lerpf(0.15, 1.0, (LIMIAR_TELA_VERMELHA - f) / LIMIAR_TELA_VERMELHA)
			if bool(pref["pulso"]):
				var ritmo := lerpf(0.6, 1.6, intensidade)  # pulsa mais depressa quanto pior
				intensidade *= 0.78 + 0.22 * sin(_tempo * TAU * ritmo)
	_mat_vermelha.set_shader_parameter("intensidade", intensidade)
	_tela_vermelha.visible = intensidade > 0.001


# ---------------------------------------------------------------- reações

func _ao_ligacao(_e: int) -> void:
	_atualizar()


func _ao_evento(_e: Dictionary) -> void:
	_atualizar()


func _ao_pausa(_p: bool) -> void:
	_atualizar()


func _ao_fase(_f: String) -> void:
	_atualizar()


func _ao_botao(m: int) -> void:
	_painel_config.visible = false
	if _modo_atual == m:
		modo_pedido.emit(Arena.Modo.NENHUM, {})
	else:
		modo_pedido.emit(m, {})


func _ao_botao_consumivel() -> void:
	_painel_config.visible = false
	if _modo_atual == Arena.Modo.CONSUMIVEL:
		modo_pedido.emit(Arena.Modo.NENHUM, {})
		return
	ao_modo_mudou(_modo_atual)  # o botão só fica marcado quando o modo entra mesmo
	var itens: Array = []
	var lista := Estado.lista_opcao("consumiveis")
	for i in lista.size():
		var o = lista[i]
		if o is Dictionary:
			var item: Dictionary = o
			itens.append([nome_legivel(item.get("itemId"), item.get("nome"), "Item %d" % (i + 1)),
				_emitir_modo.bind(Arena.Modo.CONSUMIVEL, item)])
	if itens.size() == 1:
		var unico: Callable = itens[0][1]
		unico.call()
	elif not itens.is_empty():
		escolher("Usar o quê?", itens)


func _emitir_modo(m: int, extra: Dictionary) -> void:
	modo_pedido.emit(m, extra)


func _ao_escolha(cb: Callable) -> void:
	_painel_escolha.visible = false
	if cb.is_valid():
		cb.call()


func _pedir_encerrar() -> void:
	_painel_config.visible = false
	escolher("Encerrar a sua vez?", [["Sim, encerrar", _emitir_acao.bind({"tipo": "encerrar"})]])


func _pedir_sair() -> void:
	_painel_config.visible = false
	escolher("Sair da mesa neste aparelho?", [["Sim, sair", Rede.sair]])


func _emitir_acao(acao: Dictionary) -> void:
	acao_pedida.emit(acao)


func _alternar_config() -> void:
	_painel_config.visible = not _painel_config.visible
	_ancorar.call_deferred(_coluna, Control.PRESET_TOP_LEFT)


func _fechar_config() -> void:
	_painel_config.visible = false


func _ao_perfil(i: int) -> void:
	_mudar_pref("perfil", PERFIS[i])


func _ao_camera(i: int) -> void:
	_mudar_pref("camera", CAMERAS[i])


func _ao_repor_zoom() -> void:
	preferencia_mudou.emit("zoom_padrao", true)


func _ao_chk_vermelha(v: bool) -> void:
	_mudar_pref("tela_vermelha", v)


func _ao_chk_pulso(v: bool) -> void:
	_mudar_pref("pulso", v)


func _mudar_pref(chave: String, valor) -> void:
	pref[chave] = valor
	_guardar_preferencias()
	preferencia_mudou.emit(chave, valor)


func _ao_dano(alvo_id: String, valor, tipo_dano: String, em_mim: bool) -> void:
	var p = null
	if arena != null:
		p = arena.posicao_tela(alvo_id)
	if p == null:
		p = _numeros.size * Vector2(0.5, 0.4)
	var rotulo := Label.new()
	rotulo.text = _texto_numero(valor)
	rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ls := LabelSettings.new()
	ls.font_size = int(_fonte * 1.9)
	ls.font_color = _cor_dano(tipo_dano)
	ls.outline_size = maxi(4, int(_fonte * 0.35))
	ls.outline_color = Color(0.55, 0.0, 0.0) if em_mim else Color(0.0, 0.0, 0.0)
	rotulo.label_settings = ls
	_numeros.add_child(rotulo)
	rotulo.reset_size()
	var desvio := Vector2(randf_range(-0.8, 0.8) * _fonte, float(_numeros.get_child_count() % 3) * -_fonte)
	rotulo.position = Vector2(p) - rotulo.size * 0.5 + desvio
	var tw := rotulo.create_tween()
	tw.set_parallel(true)
	tw.tween_property(rotulo, "position:y", rotulo.position.y - _fonte * 4.0, 1.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(rotulo, "modulate:a", 0.0, 0.6).set_delay(0.8)
	tw.chain().tween_callback(rotulo.queue_free)


## O ataque DELA: o servidor manda o resultado e (v0.2.1) o total; ela vê como no jogo do site.
func _ao_ataque(dados: Dictionary) -> void:
	if Estado.minha_figura_id == "" or dados.get("atacanteId") != Estado.minha_figura_id:
		return
	var frase: String = FRASES_ATAQUE.get(str(dados.get("resultado")), "")
	if frase == "":
		return
	var total = dados.get("total")
	if total is int or total is float:
		frase += " Total %s." % _texto_numero(total)
	_mostrar_aviso(frase)


func _texto_numero(v) -> String:
	if v is float and v == floorf(v):
		return str(int(v))
	if v is int or v is float or v is String:
		return str(v)
	return ""


func _cor_dano(tipo: String) -> Color:
	var t := tipo.to_lower()
	for de_para in [["á", "a"], ["â", "a"], ["ã", "a"], ["é", "e"], ["ê", "e"], ["í", "i"],
			["ó", "o"], ["ô", "o"], ["õ", "o"], ["ú", "u"], ["ç", "c"]]:
		t = t.replace(de_para[0], de_para[1])
	return CORES_DANO.get(t, Color.WHITE)


func _ao_recibo(_intent_id: String, estado: String, msg: Dictionary) -> void:
	# RECUSADA por RECEIPT_QUERY ou por "voltar" do Mestre vem sem `texto` (sala.js tratarConsulta).
	if msg.get("revertidaEm") != null:
		_mostrar_aviso("A jogada foi desfeita pelo Mestre.")
	elif estado == "RECUSADA":
		_mostrar_aviso("A ação não foi feita. Escolha outra vez.")
	_atualizar()


func _ao_recusa(_intent_id: String, _motivo: String, texto: String) -> void:
	# O servidor manda uma frase simples, sem números do Mestre (sala.js TEXTOS_RECUSA).
	_mostrar_aviso(texto if texto != "" else "Não deu certo. Escolha outra vez.")
	_atualizar()


func _ao_erro(codigo: String, _texto: String) -> void:
	if codigo == "versao":
		_mostrar_aviso("Há uma versão nova do jogo. Atualiza a página.", 3600.0)
	# Outros erros não aparecem: nada técnico na tela da jogadora.


func _mostrar_aviso(texto: String, segundos: float = 3.5) -> void:
	_aviso.text = texto
	_aviso.visible = true
	_aviso_restante = segundos


# ---------------------------------------------------------------- preferências

func _carregar_preferencias() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(ARQ_PREF) != OK:
		if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
			pref["perfil"] = "baixo"
		return
	for k in pref.keys():
		pref[k] = cfg.get_value("pref", k, pref[k])


func _guardar_preferencias() -> void:
	var cfg := ConfigFile.new()
	for k in pref:
		cfg.set_value("pref", k, pref[k])
	cfg.save(ARQ_PREF)
