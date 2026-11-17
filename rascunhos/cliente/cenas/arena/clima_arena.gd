extends "res://arte/clima/clima.gd"
## clima_arena.gd — Ordem Neve. O controlador de clima da arena integrada (estende arte/clima/clima.gd sem tocar
## em arte/).
##
## Fatia 1 — Precipitação + vento do mundo + troca viva dos 4 estados:
##   - Liga `neve_fraca` e `nevasca` ao vento do mundo (Ordem 43/64, `vento_mundo.gd`), com acoplamento calibrado
##     para a velocidade terminal dos flocos: na neve fraca deriva suavemente com o rumo do mundo; na nevasca
##     alterna entre calma e rajada mudando visivelmente o ângulo e a força da queda.
##   - Sem filtro de ecrã nem véu colado à câmara (`veu_forca = 0`): a precipitação pertence ao espaço 3D da
##     arena e a cor dos flocos lê a luz do ciclo do dia (`ciclo_dia.gd`).
##   - Garante a troca viva dos 4 estados (`limpo` ↔ `neve_fraca` ↔ `nevasca` ↔ `chuva`) sem erro nem reinício.
##
## Fatia 2 — Cobertura do chão (correcção de 14/11) + acumulação direccional:
##   - Usa `clima_chao_arena.gdshader` e `clima_figura_arena.gdshader`: em nevasca consolidada, TODO o chão se lê
##     coberto, centro incluído, sem véu branco liso (covas/obstáculos/cantos com manto espesso; cristas e zonas
##     varridas com manto mais fino e crosta fria esculpida pelo vento).
##   - Passa a luz e a sombra viva do `ciclo_dia.gd` e `sombras_floresta.gd` ao chão e aos obstáculos/figuras para
##     o branco nunca estourar o relevo ao meio-dia nem perder volume à noite.

const SH_CHAO_ARENA: Shader = preload("res://cenas/arena/clima_chao_arena.gdshader")
const SH_FIGURA_ARENA: Shader = preload("res://cenas/arena/clima_figura_arena.gdshader")

## Escala do vento do mundo (7–10 m/s à tarde) para a queda da neve (1,2–1,8 m/s): evita que a neve fraca se
## deite a 85° na horizontal e garante que na nevasca a rajada mude visivelmente o ângulo (~32° → ~74°) e a força.
@export var escala_vento_neve_fraca: float = 0.24
@export var escala_vento_nevasca_calma: float = 0.16
@export var escala_vento_nevasca_pico: float = 0.84

var _mapa_arena: WeakRef = null
var _zona_arena: Rect2 = Rect2()


func _init() -> void:
	# Nada de filtro de ecrã nem camada colada à câmara: desliga o véu de distância na arena integrada.
	veu_forca = 0.0
	nevasca_guinada_graus = 28.0
	nevasca_rasto_s = 0.042


## Liga a referência do mapa da floresta da arena integrada (para ler a luz do ciclo do dia e o relevo).
func ligar_mapa_arena(mapa: Node3D, zona: Rect2) -> void:
	_mapa_arena = weakref(mapa) if mapa != null else null
	_zona_arena = zona
	veu_forca = 0.0


func mapa_da_arena() -> Node3D:
	if _mapa_arena == null:
		return null
	var m = _mapa_arena.get_ref()
	return m if m != null and is_instance_valid(m) else null


## Sem véu colado à câmara na arena integrada.
func contagem_alvo(qual: String) -> int:
	if qual == "veu":
		return 0
	return super.contagem_alvo(qual)


## Estado canónico actual: "limpo" | "neve_fraca" | "nevasca" | "chuva".
func estado_clima() -> String:
	match tipo:
		"neve":
			return "nevasca" if intensidade == "forte" else "neve_fraca"
		"chuva":
			return "chuva"
		_:
			return "limpo"


## Aceita tanto os pares ("nenhum"|"chuva"|"neve", "fraco"|"forte") como os 4 estados canónicos
## ("limpo", "neve_fraca", "nevasca", "chuva") sem reiniciar a cena.
func definir(novo_tipo: String, nova_intensidade: String = "") -> bool:
	var t := novo_tipo.strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	var i := nova_intensidade.strip_edges().to_lower()
	if i == "fraca":
		i = "fraco"
	match t:
		"limpo", "nenhum", "sem_clima", "desligado":
			return super.definir("nenhum", i if i != "" else intensidade)
		"neve_fraca":
			return super.definir("neve", "fraco")
		"nevasca", "neve_forte":
			return super.definir("neve", "forte")
		"chuva_fraca":
			return super.definir("chuva", "fraco")
		"chuva_forte", "tempestade":
			return super.definir("chuva", "forte")
		"chuva":
			return super.definir("chuva", i if i != "" else "fraco")
		"neve":
			return super.definir("neve", i if i != "" else intensidade)
		_:
			return super.definir(novo_tipo, i)


## Aceita "limpo", "neve_fraca", "nevasca", "chuva", além de "nenhum", "neve-fraca", "neve-forte", "chuva-fraca", "chuva-forte".
func definir_por_nome(nome: String) -> bool:
	var n := nome.strip_edges().to_lower().replace("_", "-").replace(" ", "-").replace(":", "-")
	match n:
		"", "limpo", "nenhum", "sem-clima", "desligado":
			return super.definir("nenhum")
		"neve-fraca", "neve-fraco":
			return super.definir("neve", "fraco")
		"nevasca", "neve-forte":
			return super.definir("neve", "forte")
		"chuva", "chuva-fraca", "chuva-fraco":
			return super.definir("chuva", "fraco")
		"chuva-forte", "tempestade":
			return super.definir("chuva", "forte")
		_:
			return super.definir_por_nome(nome)


## O vento deste frame (m/s no chão: x, z).
## - Para a chuva: exactamente o vetor() do vento do mundo (Ordem 64).
## - Para a neve quando segue o vento do mundo: usa a direcção e a força do vento do mundo calibradas para a
##   velocidade de queda dos flocos, somando na nevasca a modulação de calma/rajada e guinada para que a rajada
##   mude visivelmente o ângulo e a força da queda dentro do mesmo plano.
func vento_do_frame(para_tipo: String = "") -> Vector2:
	var t := para_tipo if para_tipo != "" else tipo
	if t != "neve" or not segue_fonte("neve"):
		return super.vento_do_frame(para_tipo)
	var fn := fonte_do_vento()
	var v: Vector3 = fn.vetor()
	var v2 := Vector2(v.x, v.z)
	var forca_mundo := v2.length()
	var rumo := atan2(v.z, v.x) if forca_mundo > 1e-5 else deg_to_rad(vento_direcao_graus)
	var escala := escala_vento_neve_fraca
	if _nevasca_vento > 0.0:
		var g := rajada_da_nevasca(_tempo)
		var esc_nevasca := lerpf(escala_vento_nevasca_calma, escala_vento_nevasca_pico, g)
		escala = lerpf(escala, esc_nevasca, _nevasca_vento)
		var osc := 0.55 * sin(0.23 * _tempo + 1.1) + 0.45 * g * sin(0.61 * _tempo)
		rumo += deg_to_rad(nevasca_guinada_graus) * _nevasca_vento * osc
	var forca := maxf(forca_mundo * escala, 0.0)
	return Vector2(cos(rumo), sin(rumo)) * forca


## Fatia 2: acumulação direccional (cantos/bordas, barlavento e sotavento dos obstáculos e covas do relevo).
func abrigo_em(xz: Vector2, rumo: Vector2 = Vector2.ZERO) -> float:
	var w := rumo.normalized() if rumo != Vector2.ZERO else (_vento_lento if _vento_lento != Vector2.ZERO else Vector2.RIGHT)
	var c := Vector2(_centro.x, _centro.z)
	var meio := _tamanho * 0.5
	var e := Vector2(maxf(meio.x - absf(xz.x - c.x), 0.0), maxf(meio.y - absf(xz.y - c.y), 0.0))
	var lado := Vector2(signf(xz.x - c.x), signf(xz.y - c.y))
	var peso := Vector2(1.0 - 0.48 * lado.x * w.x, 1.0 - 0.48 * lado.y * w.y)
	var b := Vector2(exp(-e.x / 2.2) * peso.x, exp(-e.y / 2.2) * peso.y)
	var canto := exp(-(e.x + e.y) / 4.2) * 0.55 * (peso.x + peso.y)
	var soma := bordas_abrigo * (0.50 * maxf(b.x, b.y) + 0.95 * canto)
	for i in _abrigos.size():
		var cx := _abrigos[i]
		var alcance := clampf(_abrigos_alt[i] * 2.8, 1.1, 6.0)
		var d := xz - Vector2(cx.x, cx.y)
		var proj := d.dot(w)
		var s := clampf(proj, 0.0, alcance)
		var f := s / alcance
		var meia := minf(cx.z, cx.w)
		var d0 := _sd_caixa(xz, cx)
		var d1 := _sd_caixa(xz - w * s, cx) + f * (0.22 + 0.55 * meia)
		var barla := smoothstep(0.1, -0.75, proj / (0.5 + meia)) * exp(-maxf(d0, 0.0) / 0.55)
		var sota := smoothstep(-0.2, 0.85, proj / (0.5 + meia)) * exp(-maxf(d0, 0.0) / 0.65)
		var cauda := smoothstep(0.42, -0.22, d1) * (1.0 - f) * (1.0 - 0.65 * f)
		soma += maxf(maxf(barla * 0.92, sota * 1.10), cauda * 1.05)
	var y_rel := (float(altura_do_chao.call(xz.x, xz.y)) - _centro.y) if altura_do_chao.is_valid() else 0.0
	var d_bacia := fundura_em(xz, 1.0, 0.45, y_rel)
	var cova := smoothstep(-0.06, 0.04, d_bacia) * 0.55 + clampf((-y_rel - 0.15) * 0.35, 0.0, 0.45)
	return clampf(soma + cova, 0.0, 1.85)


## Fatia 2 (correcção de 14/11): na nevasca consolidada (neve=1, aglomerado=1), o centro exposto mantém cobertura
## real (q >= 0,88; nunca desce aos 0,33 que deixavam a relva verde), enquanto covas, cantos e obstáculos acumulam
## manto espesso (q > 1,30).
func neve_em(xz: Vector2) -> float:
	if aglomerado <= 0.0:
		return neve
	var ab := abrigo_em(xz)
	var exposto := 1.0 - clampf(ab * 1.15, 0.0, 1.0)
	var y_rel := (float(altura_do_chao.call(xz.x, xz.y)) - _centro.y) if altura_do_chao.is_valid() else 0.0
	var crista := clampf((y_rel - 0.10) * 0.32, 0.0, 0.55) * exposto
	return neve * (1.0 - aglomerado * exposto * 0.16) + aglomerado * (ab * 0.95 + (1.0 - crista) * 0.22)


func _vestir_alvos() -> void:
	var precisa := molhado > 0.0 or neve > 0.0 or tipo != "nenhum" or aglomerado > 0.0 or gelo > 0.0 or agua > 0.0 or lama > 0.0
	if precisa and _mat_chao == null:
		_mat_chao = _material(SH_CHAO_ARENA, -20)
		_mat_figura = _material(SH_FIGURA_ARENA, 0)
	super._vestir_alvos()


func empurrar_terreno_para(m: ShaderMaterial) -> void:
	super.empurrar_terreno_para(m)
	m.set_shader_parameter(&"clima_gelo", gelo)


func _empurrar_uniformes() -> void:
	super._empurrar_uniformes()
	var m := mapa_da_arena()
	if m != null and m.get("ciclo") != null:
		var e: Dictionary = m.ciclo.estado()
		var dir_luz_ciclo: Vector3 = e.get("dir_luz", Vector3(-0.79, 0.52, 0.32))
		var cor_luz: Color = e.get("cor_luz", Color(1.0, 0.90, 0.71))
		var cor_sombra: Color = e.get("cor_sombra", Color(0.32, 0.40, 0.54))
		var cor_ceu: Color = e.get("cor_ceu", Color(0.64, 0.71, 0.74))
		var noite_f: float = float(e.get("noite", 0.0))
		var sombra_f: float = float(e.get("sombra_forca", 1.0))
		if _mat_flocos != null and _n_flocos > 0.0:
			var luz_floco := (cor_luz * 0.62 + cor_ceu * 0.52).clamp(Color(0.28, 0.34, 0.48), Color(0.96, 0.98, 1.0))
			if noite_f > 0.001:
				var lum := 0.30 * luz_floco.r + 0.52 * luz_floco.g + 0.18 * luz_floco.b
				luz_floco = luz_floco.lerp(Color(lum * 0.74, lum * 0.94, minf(lum * 1.42, 0.95)), noite_f * 0.45)
			var raj := rajada_da_nevasca(_tempo) if _nevasca_vento > 0.0 else 0.0
			_mat_flocos.set_shader_parameter(&"cor", Color(luz_floco.r, luz_floco.g, luz_floco.b, lerpf(0.88, 0.96, raj)))
			_mat_flocos.set_shader_parameter(&"exposicao_s", nevasca_rasto_s * _nevasca_vento * (0.35 + 0.95 * raj))
		for mat in [_mat_chao, _mat_figura]:
			if mat != null:
				mat.set_shader_parameter(&"luz_dir", dir_luz_ciclo)
				mat.set_shader_parameter(&"luz_cor", cor_luz)
				mat.set_shader_parameter(&"cor_sombra_ciclo", cor_sombra)
				mat.set_shader_parameter(&"cor_ceu_ciclo", cor_ceu)
				mat.set_shader_parameter(&"noite_ciclo", noite_f)
				mat.set_shader_parameter(&"congelamento", gelo)
		if _mat_chao != null:
			_mat_chao.set_shader_parameter(&"sombra_forca_ciclo", sombra_f)
			var sombras_no = m.get("sombras")
			if sombras_no != null and sombras_no.has_method(&"textura"):
				_mat_chao.set_shader_parameter(&"mapa_sombra_arena", sombras_no.textura())
				_mat_chao.set_shader_parameter(&"tem_mapa_sombra", 1.0)
