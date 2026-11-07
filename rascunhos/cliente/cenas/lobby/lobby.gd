extends Control
## Lobby e entrada (JV3.1). Cena principal do projeto.
##
## Fluxo do Mestre (04/11 20:46):
##   - a jogadora entra com o NOME DA PERSONAGEM e uma SENHA SIMPLES, e espera;
##   - o Mestre entra com o PIN (cenas/mestre) e escolhe mapa, criaturas e NPCs;
##   - ao confirmar (MASTER_START), todos entram; as criaturas não entram sozinhas:
##     o Mestre coloca cada uma (MASTER_PLACE).
##
## - Na web, o servidor é a origem da página (Rede.url_servidor via JavaScriptBridge).
##   No Windows e no Android há um campo editável "IP:porta" (guardado em user://rede.cfg).
## - Os erros da entrada mostram a frase `texto` do servidor (ERRO / ROOM_REJECT), nunca texto técnico.
## - O seatToken fica em user:// (pela Rede): ao reabrir, entra sozinha, sem pedir a senha.
## - Lobby → arena quando a fase passa a "combate" (ROOM_SNAPSHOT com fase "combate",
##   ou o primeiro `turno` depois do MASTER_START: ver estado.gd).

const CENA_ARENA := "res://cenas/arena/arena.tscn"
const CENA_MESTRE := "res://cenas/mestre/mestre.tscn"
const LARGURA_BASE := 1920.0
const ALTURA_BASE := 1080.0
const FONTE_BASE := 22
const FONTE_MIN_PX_REAIS := 13.0  # acima dos 12 px pedidos
const OPACIDADE_PAINEL := 0.55
## Frases do próprio cliente (quando o servidor não manda `texto`).
const FRASES := {
	"senha": "O nome ou a senha não conferem.",
	"token": "Entre de novo, por favor.",
	"outro_aparelho": "Esta personagem entrou em outro aparelho.",
	"nome": "Escreva o nome da personagem.",
	"pin": "Escreva o PIN do Mestre.",
	"bloqueado": "Muitas tentativas. Espere um pouco.",
}

var _tema := Theme.new()
var _fonte := FONTE_BASE
var _painel: PanelContainer
var _titulo: Label
var _estado: Label
var _aviso: Label
var _caixa_jogadora: VBoxContainer
var _caixa_mestre: VBoxContainer
var _caixa_espera: VBoxContainer
var _caixa_servidor: HBoxContainer = null
var _campo_nome: LineEdit
var _campo_senha: LineEdit
var _campo_pin: LineEdit
var _campo_host: LineEdit = null
var _modo_mestre := false
var _saindo := false


func _ready() -> void:
	_montar()
	get_viewport().size_changed.connect(_ao_redimensionar)
	_ao_redimensionar()
	Rede.ligacao_mudou.connect(_ao_ligacao)
	Rede.precisa_entrar.connect(_ao_precisa_entrar)
	Rede.entrada_recusada.connect(_ao_entrada_recusada)
	Rede.boas_vindas_recebidas.connect(_ao_boas_vindas)
	Rede.erro_recebido.connect(_ao_erro)
	Estado.snapshot_aplicado.connect(_verificar_fase)
	Estado.fase_mudou.connect(_ao_fase)
	Estado.pausa_mudou.connect(_ao_pausa)
	if Rede.motivo_entrada != "":
		_ao_precisa_entrar(Rede.motivo_entrada)  # veio da arena ou do Mestre com um motivo
	Rede.iniciar()  # com token guardado, entra sozinha; sem token, pede a entrada
	_atualizar()
	_verificar_fase()
	print("pronto")  # o CI (JV0.2) espera esta linha no console


# ---------------------------------------------------------------- montagem

func _montar() -> void:
	var painel_sb := StyleBoxFlat.new()
	painel_sb.bg_color = Color(0.06, 0.07, 0.10, OPACIDADE_PAINEL)
	painel_sb.set_corner_radius_all(14)
	painel_sb.set_content_margin_all(24)
	_tema.set_stylebox("panel", "PanelContainer", painel_sb)
	_tema.set_color("font_color", "Label", Color.WHITE)
	_tema.set_color("font_color", "Button", Color.WHITE)
	theme = _tema

	var fundo := ColorRect.new()
	fundo.color = Color(0.10, 0.13, 0.18)
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var centro := CenterContainer.new()
	add_child(centro)
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_painel = PanelContainer.new()
	centro.add_child(_painel)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 14)
	_painel.add_child(caixa)

	_titulo = Label.new()
	_titulo.text = "Assimilação"
	_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(_titulo)

	_estado = _rotulo_quebrado()
	caixa.add_child(_estado)
	_aviso = _rotulo_quebrado()
	_aviso.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	caixa.add_child(_aviso)

	# Jogadora: nome da personagem + senha simples.
	_caixa_jogadora = VBoxContainer.new()
	_caixa_jogadora.add_theme_constant_override("separation", 12)
	caixa.add_child(_caixa_jogadora)
	_campo_nome = LineEdit.new()
	_campo_nome.placeholder_text = "Nome da personagem"
	_caixa_jogadora.add_child(_campo_nome)
	_campo_senha = LineEdit.new()
	_campo_senha.placeholder_text = "Senha"
	_campo_senha.secret = true
	_campo_senha.text_submitted.connect(_ao_enviar_senha)
	_caixa_jogadora.add_child(_campo_senha)
	var b_entrar := Button.new()
	b_entrar.text = "Entrar"
	b_entrar.pressed.connect(_ao_entrar)
	_caixa_jogadora.add_child(b_entrar)
	var b_sou_mestre := Button.new()
	b_sou_mestre.text = "Sou o Mestre"
	b_sou_mestre.flat = true
	b_sou_mestre.pressed.connect(_alternar_mestre.bind(true))
	_caixa_jogadora.add_child(b_sou_mestre)

	# Mestre: PIN (o servidor exige 6 dígitos ou mais e trava as tentativas, E-P9).
	_caixa_mestre = VBoxContainer.new()
	_caixa_mestre.add_theme_constant_override("separation", 12)
	caixa.add_child(_caixa_mestre)
	_campo_pin = LineEdit.new()
	_campo_pin.placeholder_text = "PIN do Mestre"
	_campo_pin.secret = true
	_campo_pin.text_submitted.connect(_ao_enviar_pin)
	_caixa_mestre.add_child(_campo_pin)
	var b_mestre := Button.new()
	b_mestre.text = "Entrar como Mestre"
	b_mestre.pressed.connect(_ao_entrar_mestre)
	_caixa_mestre.add_child(b_mestre)
	var b_voltar := Button.new()
	b_voltar.text = "Voltar"
	b_voltar.flat = true
	b_voltar.pressed.connect(_alternar_mestre.bind(false))
	_caixa_mestre.add_child(b_voltar)

	# Já na mesa, à espera do Mestre.
	_caixa_espera = VBoxContainer.new()
	caixa.add_child(_caixa_espera)
	var b_sair := Button.new()
	b_sair.text = "Sair desta mesa"
	b_sair.flat = true
	b_sair.pressed.connect(_ao_sair)
	_caixa_espera.add_child(b_sair)

	# Fora da web: o endereço do servidor é editável.
	if not OS.has_feature("web"):
		_caixa_servidor = HBoxContainer.new()
		_caixa_servidor.add_theme_constant_override("separation", 10)
		caixa.add_child(_caixa_servidor)
		var l := Label.new()
		l.text = "Servidor"
		_caixa_servidor.add_child(l)
		_campo_host = LineEdit.new()
		_campo_host.text = Rede.host_configurado()
		_campo_host.placeholder_text = "IP:porta"
		_campo_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_caixa_servidor.add_child(_campo_host)
		var b_usar := Button.new()
		b_usar.text = "Usar"
		b_usar.pressed.connect(_ao_usar_servidor)
		_caixa_servidor.add_child(b_usar)


func _rotulo_quebrado() -> Label:
	var l := Label.new()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func _ao_redimensionar() -> void:
	var janela := Vector2(get_window().size)
	var escala := minf(janela.x / LARGURA_BASE, janela.y / ALTURA_BASE)
	if escala <= 0.0:
		escala = 1.0
	# canvas_items + expand: 1 unidade = `escala` px reais. Garante ≥ 13 px reais.
	_fonte = maxi(FONTE_BASE, ceili(FONTE_MIN_PX_REAIS / escala))
	_tema.default_font_size = _fonte
	_titulo.add_theme_font_size_override("font_size", _fonte * 2)
	_painel.custom_minimum_size = Vector2(float(_fonte) * 18.0, 0.0)


# ---------------------------------------------------------------- estado da tela

func _atualizar() -> void:
	var na_mesa: bool = Rede.na_mesa()
	var ligando: bool = Rede.a_ligar()
	var formulario := not na_mesa and not ligando
	_caixa_espera.visible = na_mesa and Rede.papel == "jogadora"
	_caixa_jogadora.visible = formulario and not _modo_mestre
	_caixa_mestre.visible = formulario and _modo_mestre
	if _caixa_servidor != null:
		_caixa_servidor.visible = formulario
	if ligando:
		_estado.text = "A conexão caiu. Voltando à mesa..." if Rede.ja_esteve_na_mesa() else "Conectando à mesa..."
	elif na_mesa:
		_estado.text = "A mesa está em pausa. O Mestre já volta." if Estado.pausada else "Esperando o Mestre começar..."
	elif _modo_mestre:
		_estado.text = "Entre com o PIN do Mestre."
	else:
		_estado.text = "Entre com o nome da sua personagem e a senha."


func _verificar_fase() -> void:
	if _saindo or not Rede.na_mesa():
		return
	if Rede.papel == "mestre":
		_ir(CENA_MESTRE)
		return
	if Estado.tem_snapshot and (Estado.fase == "combate" or Estado.fase == "fim"):
		_ir(CENA_ARENA)


func _ir(cena: String) -> void:
	if _saindo:
		return
	_saindo = true
	get_tree().change_scene_to_file.call_deferred(cena)


# ---------------------------------------------------------------- sinais

func _ao_ligacao(_e: int) -> void:
	_atualizar()


func _ao_fase(_f: String) -> void:
	_verificar_fase()


func _ao_pausa(_p: bool) -> void:
	_atualizar()


func _ao_boas_vindas(_msg: Dictionary) -> void:
	_aviso.text = ""
	_atualizar()
	_verificar_fase()


func _ao_precisa_entrar(motivo: String) -> void:
	if motivo == "token" or motivo == "outro_aparelho" or motivo == "nome" or motivo == "pin":
		_aviso.text = FRASES[motivo]
	elif motivo != "" and _aviso.text == "":
		_aviso.text = str(FRASES.get(motivo, ""))
	if Rede.papel == "mestre" and motivo != "outro_aparelho":
		_modo_mestre = true
	_atualizar()


## ERRO do servidor na entrada: mostra a frase dele (ex.: "Não foi possível entrar.").
func _ao_entrada_recusada(codigo: String, texto: String) -> void:
	_aviso.text = texto if texto != "" else str(FRASES.get(codigo, FRASES["senha"]))
	_atualizar()


func _ao_erro(codigo: String, _texto: String) -> void:
	if codigo == "versao":
		_aviso.text = "Há uma versão nova do jogo. Recarregue a página."
	# Os outros erros não aparecem: nada técnico na tela.


func _alternar_mestre(ligado: bool) -> void:
	_modo_mestre = ligado
	_aviso.text = ""
	_atualizar()


func _ao_enviar_senha(_t: String) -> void:
	_ao_entrar()


func _ao_enviar_pin(_t: String) -> void:
	_ao_entrar_mestre()


func _ao_entrar() -> void:
	_aviso.text = ""
	Rede.entrar(_campo_nome.text, _campo_senha.text)
	_campo_senha.text = ""
	_atualizar()


func _ao_entrar_mestre() -> void:
	_aviso.text = ""
	Rede.entrar_mestre(_campo_pin.text)
	_campo_pin.text = ""  # o PIN nunca fica na tela nem no disco
	_atualizar()


func _ao_usar_servidor() -> void:
	if _campo_host == null:
		return
	Rede.definir_servidor(_campo_host.text)
	_aviso.text = "Endereço guardado."


func _ao_sair() -> void:
	Rede.sair()
	_atualizar()
