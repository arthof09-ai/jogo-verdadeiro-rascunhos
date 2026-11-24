extends Node
## Autoload "Medicao" — Ordem PLANO-2-F2 (V1.0 do Plano A): o link de medição de 1 minuto.
##
## O Mestre (ou a jogadora) abre http://<servidor>/?medir=1 no aparelho e espera 1 minuto. Fora da web: «-- --medir».
## A arena abre como sempre, mas a Rede não liga (Rede.modo_medicao): mede-se o mapa da arena na vista de arranque.
##  - 5 s de aquecimento (shaders, carga) e 55 s de amostra, quadro a quadro: o aparelho não deve ser tocado;
##  - FPS: mediana e p5 do FPS instantâneo (1 / duração do quadro, pelo relógio de parede);
##  - chamadas de desenho por quadro (mediana e máximo), a GPU, o viewport e o DPR;
##  - no fim, o JSON aparece no ecrã, sai no console («medicao-v1.0 {…}») e vai sozinho para o servidor
##    (POST /medicao, na mesma origem). O servidor guarda-o na pasta das medições (servidor-ws.js).
## Sem o parâmetro, este nó não faz nada (nem processa).

const FORMATO := "medicao-v1.0/1"
const AQUECIMENTO_S := 5.0
const JANELA_S := 55.0
const ROTA := "/medicao"

var ativo := false
var resultado: Dictionary = {}
var _inicio_us := 0  # relógio de parede (Time.get_ticks_usec): o delta do motor não acompanha o tempo real na web
var _anterior_us := 0
var _fps: PackedFloat32Array = PackedFloat32Array()
var _chamadas: PackedFloat32Array = PackedFloat32Array()
var _camada: CanvasLayer
var _rotulo: Label
var _js_resposta = null  # o callback do fetch (tem de viver até a resposta chegar)


func _ready() -> void:
	set_process(false)
	ativo = pedido()
	if not ativo:
		return
	var rede := get_node_or_null("/root/Rede")  # pelo caminho: os testes -s compilam isto sem os autoloads
	if rede != null:
		rede.modo_medicao = true
	_montar_ecra()
	_inicio_us = Time.get_ticks_usec()
	_anterior_us = _inicio_us
	set_process(true)


## O link pede a medição? Web: «?medir» na query. Fora dela: o argumento «--medir».
static func pedido() -> bool:
	if OS.has_feature("web"):
		# Em texto: o bool do JS não chega ao GDScript de forma fiável (a comparação com true dava verdade sem o «?medir»).
		var r = JavaScriptBridge.eval("String(new URLSearchParams(window.location.search).has('medir'))", true)
		return str(r) == "true"
	return OS.get_cmdline_user_args().has("--medir")


func _process(_delta: float) -> void:
	# Tudo pelo relógio de parede: a janela de 1 minuto e a duração de cada quadro (de um _process ao seguinte).
	var agora_us := Time.get_ticks_usec()
	var quadro_s := float(agora_us - _anterior_us) / 1e6
	_anterior_us = agora_us
	var t := float(agora_us - _inicio_us) / 1e6
	if t < AQUECIMENTO_S:
		_rotulo.text = "A preparar a medição… não toque no ecrã."
		return
	if t < AQUECIMENTO_S + JANELA_S:
		if quadro_s > 0.0:
			_fps.append(1.0 / quadro_s)
		_chamadas.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		_rotulo.text = "A medir… faltam %d s. Não toque no ecrã." % ceili(AQUECIMENTO_S + JANELA_S - t)
		return
	set_process(false)
	resultado = montar_resultado(_fps, _chamadas, _ambiente())
	var texto := JSON.stringify(resultado)
	print("medicao-v1.0 " + texto)
	_rotulo.text = "Medição feita. A enviar…\n\n" + JSON.stringify(resultado, "  ")
	_enviar(texto)


# ---------------------------------------------------------------- contas (estáticas, testáveis sem ecrã)

## Percentil p (0..100) por interpolação linear entre as amostras ordenadas. Lista vazia → 0.
static func percentil(valores: PackedFloat32Array, p: float) -> float:
	if valores.is_empty():
		return 0.0
	var v := valores.duplicate()
	v.sort()
	var pos := clampf(p, 0.0, 100.0) / 100.0 * float(v.size() - 1)
	var i := int(floor(pos))
	var j := mini(i + 1, v.size() - 1)
	return lerpf(v[i], v[j], pos - float(i))


static func montar_resultado(fps: PackedFloat32Array, chamadas: PackedFloat32Array, amb: Dictionary) -> Dictionary:
	var r := {
		"formato": FORMATO,
		"quadros": fps.size(),
		"aquecimento_s": AQUECIMENTO_S,
		"janela_s": JANELA_S,
		"fps_mediana": snappedf(percentil(fps, 50.0), 0.1),
		"fps_p5": snappedf(percentil(fps, 5.0), 0.1),
		"chamadas_mediana": int(round(percentil(chamadas, 50.0))),
		"chamadas_max": int(round(percentil(chamadas, 100.0))),
	}
	r.merge(amb)
	return r


# ---------------------------------------------------------------- o aparelho

func _ambiente() -> Dictionary:
	var vp := get_viewport().get_visible_rect().size
	var janela := DisplayServer.window_get_size()
	var a := {
		"gpu": RenderingServer.get_video_adapter_name(),
		"gpu_fabricante": RenderingServer.get_video_adapter_vendor(),
		"gpu_api": RenderingServer.get_video_adapter_api_version(),
		"renderizador": str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "")),
		"viewport": [int(vp.x), int(vp.y)],
		"janela_px": [janela.x, janela.y],
		"dpr": DisplayServer.screen_get_scale(),
		"plataforma": OS.get_name(),
		"motor": Engine.get_version_info().get("string", ""),
		"carimbo": Time.get_datetime_string_from_system(true) + "Z",
	}
	if OS.has_feature("web"):
		var dpr = JavaScriptBridge.eval("window.devicePixelRatio", true)
		if dpr is float or dpr is int:
			a["dpr"] = float(dpr)
		var css = JavaScriptBridge.eval("[window.innerWidth, window.innerHeight].join('x')", true)
		a["viewport_css"] = str(css)
		a["navegador"] = str(JavaScriptBridge.eval("navigator.userAgent", true))
		# A GPU de verdade (o Godot só vê «WebGL2»): a extensão WEBGL_debug_renderer_info, quando o navegador a dá.
		var g = JavaScriptBridge.eval("(function(){try{var c=document.createElement('canvas');"
			+ "var g=c.getContext('webgl2')||c.getContext('webgl');var e=g&&g.getExtension('WEBGL_debug_renderer_info');"
			+ "return e?(g.getParameter(e.UNMASKED_VENDOR_WEBGL)+' | '+g.getParameter(e.UNMASKED_RENDERER_WEBGL)):'';}"
			+ "catch(x){return '';}})()", true)
		if g is String and g != "":
			a["gpu_webgl"] = g
	return a


func _enviar(texto: String) -> void:
	if OS.has_feature("web"):
		_js_resposta = JavaScriptBridge.create_callback(_ao_resposta_js)
		var janela = JavaScriptBridge.get_interface("window")
		janela.__medicaoResposta = _js_resposta
		# JSON.stringify(texto) dá um literal de texto JS (o JSON vai como corpo, tal e qual).
		var js := "fetch(window.location.origin + '" + ROTA + "', {method: 'POST', "
		js += "headers: {'Content-Type': 'application/json'}, body: " + JSON.stringify(texto) + "})"
		js += ".then(function(r){window.__medicaoResposta(r.status);})"
		js += ".catch(function(){window.__medicaoResposta(0);});"
		JavaScriptBridge.eval(js, true)
		return
	var pedido_http := HTTPRequest.new()
	add_child(pedido_http)
	pedido_http.request_completed.connect(func(_r: int, codigo: int, _h, _b) -> void: _mostrar_envio(codigo))
	var rede := get_node_or_null("/root/Rede")
	var host: String = rede.host_configurado() if rede != null else "127.0.0.1:8080"
	var err := pedido_http.request("http://%s%s" % [host, ROTA],
		PackedStringArray(["Content-Type: application/json"]), HTTPClient.METHOD_POST, texto)
	if err != OK:
		_mostrar_envio(0)


func _ao_resposta_js(args: Array) -> void:
	_mostrar_envio(int(args[0]) if args.size() > 0 else 0)


func _mostrar_envio(codigo: int) -> void:
	var cabeca := "Medição feita e enviada ao servidor. Pode fechar." if codigo >= 200 and codigo < 300 \
		else "Medição feita, mas não chegou ao servidor (%d). Tire uma foto deste ecrã." % codigo
	print("medicao-v1.0 envio %d" % codigo)
	_rotulo.text = cabeca + "\n\n" + JSON.stringify(resultado, "  ")


func _montar_ecra() -> void:
	_camada = CanvasLayer.new()
	_camada.layer = 100
	add_child(_camada)
	var fundo := PanelContainer.new()
	fundo.set_anchors_preset(Control.PRESET_TOP_LEFT)
	fundo.position = Vector2(16, 16)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.72)
	sb.set_content_margin_all(14)
	fundo.add_theme_stylebox_override("panel", sb)
	_camada.add_child(fundo)
	_rotulo = Label.new()
	_rotulo.add_theme_font_size_override("font_size", 26)
	_rotulo.add_theme_color_override("font_color", Color(1, 1, 1))
	fundo.add_child(_rotulo)
