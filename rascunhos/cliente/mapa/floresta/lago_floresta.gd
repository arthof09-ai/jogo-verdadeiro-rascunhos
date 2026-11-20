extends Node3D
## lago_floresta.gd — Ordem 66. O LAGO do mapa da floresta: a superfície da água e a sua REACÇÃO a quem lá anda.
##
## O lago assenta na cova do NE (a do charco da Ordem 38): o relevo (relevo_floresta.gd) dá o nível, a RASA e a
## FUNDA; aqui vive o que se vê e mexe — a malha da superfície, a fundura cozida numa textura (o shader pinta a
## rasa clara e a funda escura) e a reacção: anéis, o anel de espuma na linha de água de cada corpo e a ESTEIRA.
## O desenho é do shader mapa/floresta/shaders/agua.gdshader; este nó escreve-lhe o relógio e as listas.
##
## SÓ APRESENTAÇÃO. Nada aqui é regra: não há custos, casas nem decisões — o que a água custa a quem a
## atravessa é do servidor. Este nó não lê Estado, Rede nem nada do Mestre.
##
##   seguir(nó, raio, pontos)   põe um nó (uma figura) a mexer a água: enquanto estiver dentro dela, deixa anéis
##                              à volta do corpo e por onde passa e, mais fundo, a esteira atrás de si;
##   deixar(nó)                 tira-o;
##   pulso(x, z, força)         um anel solto (uma pedra que cai, um passo);
##   ponto_de_rasto(...)        um ponto da esteira, à mão;
##   imersao(y_base)            quantos metros de um corpo com a base em y_base estão debaixo de água;
##   pe_na_agua(x, z)           a altura da base de uma figura em (x, z): o leito enquanto se faz pé; onde a
##                              água passa de FLUTUA_M, a figura bóia com a água pelo peito (não se enterra);
##   a_nadar(x, z)              (Ordem NADO) se a figura em (x, z) já não faz pé e passa ao clipe de nado.
##
## ORDEM ÁGUA-REAÇÃO (v2 da reacção): a água responde ao ESTADO de cada figura seguida, lido das mesmas funções
## de cima (imersao para «dentro de água», a_nadar para «a nadar») — não há outra detecção de água:
##   · ao ENTRAR na água, e outra vez ao passar a NADAR, um SALPICO: SALPICO_ANEIS anéis que nascem no ponto de
##     contacto, uns atrás dos outros, e se abrem;
##   · a MEXER-SE (vadear ou nadar) a ondulação colada ao corpo, os anéis do caminho e a esteira crescem com a
##     velocidade; PARADA, o AGITO da figura cai a direito até 0 em CALMA_S segundos — a ondulação, a espuma
##     da linha de água e os anéis fracos de quem está parado acalmam até sumir (fica só o vento).

const Relevo := preload("res://mapa/floresta/relevo_floresta.gd")

## Os tamanhos das listas do shader (agua.gdshader: MAX_PULSOS, MAX_RASTO, MAX_CORPOS). MAX_CORPOS fica em 4: o
## agito dos corpos vai num vec4 (corpos_agito).
const MAX_PULSOS := 24
const MAX_RASTO := 48
const MAX_CORPOS := 4
## A malha da superfície: quadrados deste lado (m). A textura da fundura: TEX_N × TEX_N sobre o mesmo quadrado.
const PASSO_MALHA := 0.375
const TEX_N := 128
const FUNDURA_ESCALA := 3.5
## A água pelo peito: a partir desta fundura uma figura de pé deixa de fazer pé e bóia (m).
const FLUTUA_M := 1.25
## Um pulso a cada tantos metros andados dentro de água, e um ponto de esteira a cada tantos.
const PASSO_PULSO_M := 0.42
const PASSO_RASTO_M := 0.30
## Parado dentro de água, um corpo ainda mexe um pouco: um anel fraco de tantos em tantos segundos.
const PULSO_PARADO_S := 1.6
## ORDEM ÁGUA-REAÇÃO — o salpico ao entrar na água (e ao passar a nadar): tantos anéis, com este intervalo (s);
## e o tempo que o agito de uma figura parada leva a cair de 1 a 0 (s).
const SALPICO_ANEIS := 3
const SALPICO_INTERVALO_S := 0.24
const CALMA_S := 3.5
## A velocidade (m/s) a partir da qual o agito de quem anda na água é o máximo (abaixo, cresce com ela).
const AGITO_VELOC_M_S := 0.45
## Quanto tempo vivem (s): o shader já os apagou antes disto.
const VIDA_PULSO_S := 7.0
const VIDA_RASTO_S := 14.5

var material: ShaderMaterial
var tempo := 0.0
## O quadrado do mundo que a malha e a textura cobrem.
var rect := Rect2()
var medidas: Dictionary = {}

var _pulsos: Array[Vector4] = []
var _rasto: Array[Vector4] = []
var _seguidos: Array = []   # [{no, raio, pontos, antes, andado_p, andado_r, parado, dentro, lado, vigor, agito, nada}]
## ORDEM ÁGUA-REAÇÃO: quantos salpicos houve (entradas na água e passagens a nado) e o custo do avancar() (µs).
var salpicos := 0
var _custo_us := 0
var _custo_n := 0
var _sujo := true


## Constrói a superfície e a textura da fundura, com o material `mat` (do shader agua.gdshader).
func montar(mat: ShaderMaterial) -> void:
	material = mat
	var c := Relevo.COVA
	var meio := Relevo.LAGO_RAIO + 0.25
	rect = Rect2(c.x - meio, c.y - meio, 2.0 * meio, 2.0 * meio)
	var nivel := Relevo.nivel_lago()
	# ---- a fundura cozida (metros de água; negativa em seco, para a orla se desfazer sem degrau)
	var img := Image.create(TEX_N, TEX_N, false, Image.FORMAT_RF)
	var maxima := 0.0
	var area := 0.0
	var area_rasa := 0.0
	var area_funda := 0.0
	var texel := rect.size.x / TEX_N
	for j in TEX_N:
		for i in TEX_N:
			var x := rect.position.x + (i + 0.5) * texel
			var z := rect.position.y + (j + 0.5) * texel
			var f := -0.5
			if Vector2(x - c.x, z - c.y).length() < Relevo.LAGO_RAIO - 0.05:
				f = clampf(nivel - Relevo.altura(x, z), -0.5, FUNDURA_ESCALA - 0.5)
			if f > 0.0:
				area += texel * texel
				if f <= 0.6:
					area_rasa += texel * texel
				elif f >= 1.25:
					area_funda += texel * texel
			maxima = maxf(maxima, f)
			img.set_pixel(i, j, Color((f + 0.5) / FUNDURA_ESCALA, 0.0, 0.0))
	img.convert(Image.FORMAT_RH)
	var tex := ImageTexture.create_from_image(img)
	# ---- a malha: os quadrados que tocam a água (mais uma orla, para a linha de água respirar)
	var n := int(round(rect.size.x / PASSO_MALHA))
	var molhado := PackedByteArray()
	molhado.resize((n + 1) * (n + 1))
	for j in n + 1:
		for i in n + 1:
			var x := rect.position.x + i * PASSO_MALHA
			var z := rect.position.y + j * PASSO_MALHA
			var dentro := Vector2(x - c.x, z - c.y).length() < Relevo.LAGO_RAIO - 0.05
			molhado[j * (n + 1) + i] = 1 if dentro and nivel - Relevo.altura(x, z) > -0.07 else 0
	var indice := PackedInt32Array()
	indice.resize((n + 1) * (n + 1))
	indice.fill(-1)
	var v := PackedVector3Array()
	var idx := PackedInt32Array()
	for j in n:
		for i in n:
			var k := j * (n + 1) + i
			if molhado[k] + molhado[k + 1] + molhado[k + n + 1] + molhado[k + n + 2] == 0:
				continue
			var cantos: Array[int] = [k, k + 1, k + n + 1, k + n + 2]
			for q in cantos:
				if indice[q] < 0:
					indice[q] = v.size()
					v.append(Vector3(rect.position.x + (q % (n + 1)) * PASSO_MALHA, nivel, rect.position.y + (q / (n + 1)) * PASSO_MALHA))
			idx.append_array([indice[k], indice[k + 1], indice[k + n + 1], indice[k + 1], indice[k + n + 2], indice[k + n + 1]])
	var nor := PackedVector3Array()
	nor.resize(v.size())
	nor.fill(Vector3.UP)
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nor
	arr[Mesh.ARRAY_INDEX] = idx
	var malha := ArrayMesh.new()
	malha.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.name = "Superficie"
	mi.mesh = malha
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 0.5
	add_child(mi)
	mat.set_shader_parameter("fundura_tex", tex)
	mat.set_shader_parameter("fundura_escala", FUNDURA_ESCALA)
	mat.set_shader_parameter("lago_rect", Vector4(rect.position.x, rect.position.y, 1.0 / rect.size.x, 1.0 / rect.size.y))
	medidas = {"lago_tri": idx.size() / 3, "lago_nivel_m": snappedf(nivel, 0.001), "lago_area_m2": snappedf(area, 0.1),
		"lago_rasa_m2": snappedf(area_rasa, 0.1), "lago_funda_m2": snappedf(area_funda, 0.1),
		"lago_fundura_max_m": snappedf(maxima, 0.01)}
	_escrever()


# ------------------------------------------------------------------ a medida da água

## O nível da água (m).
func nivel() -> float:
	return Relevo.nivel_lago()


## Os metros de água por cima do leito em (x, z) (0 = em seco).
func fundura(x: float, z: float) -> float:
	return Relevo.lago_fundura(x, z)


## Quantos metros de um corpo com a base em `y_base` estão debaixo de água em (x, z) (0 = fora dela).
func imersao(x: float, z: float, y_base: float) -> float:
	if Relevo.lago_fundura(x, z) <= 0.0:
		return 0.0
	return maxf(Relevo.nivel_lago() - y_base, 0.0)


## A altura da base de uma figura de pé em (x, z): o leito enquanto faz pé; mais fundo do que `flutua`, bóia com
## a água a `flutua` metros da base (não se enterra no fundo nem sobe para cima da água). Em seco é o relevo.
static func pe_na_agua(x: float, z: float, flutua: float = FLUTUA_M) -> float:
	var chao := Relevo.altura(x, z)
	if Relevo.lago_fundura(x, z) <= flutua:
		return chao
	return Relevo.nivel_lago() - flutua


## Ordem NADO: em (x, z) uma figura já NADA? É quando não faz pé — a mesma fronteira de pe_na_agua (mais de
## `flutua` metros de água). Na rasa anda (com a água pelo joelho); em seco anda. Só apresentação: escolhe o clipe.
static func a_nadar(x: float, z: float, flutua: float = FLUTUA_M) -> bool:
	return Relevo.lago_fundura(x, z) > flutua


# ------------------------------------------------------------------ a reacção

## Um anel solto em (x, z), de força 0–1. `atraso` (s): o anel nasce daqui a tanto (o salpico põe vários).
func pulso(x: float, z: float, forca: float, atraso: float = 0.0) -> void:
	if Relevo.lago_fundura(x, z) <= 0.0 or forca <= 0.0:
		return
	_pulsos.append(Vector4(x, z, tempo + maxf(atraso, 0.0), clampf(forca, 0.0, 1.0)))
	while _pulsos.size() > MAX_PULSOS:
		_pulsos.pop_front()
	_sujo = true


## ORDEM ÁGUA-REAÇÃO — um SALPICO no ponto de contacto (x, z): SALPICO_ANEIS anéis, o primeiro já, os outros
## a SALPICO_INTERVALO_S uns dos outros e cada um mais fraco; abrem-se como os outros anéis (o shader).
func salpico(x: float, z: float, forca: float) -> void:
	if Relevo.lago_fundura(x, z) <= 0.0 or forca <= 0.0:
		return
	for i in SALPICO_ANEIS:
		pulso(x, z, forca * pow(0.72, i), SALPICO_INTERVALO_S * i)
	salpicos += 1


## Um ponto da esteira em (x, z), de força 0–1 (0 = o rasto leve de quem anda na rasa; 1 = a esteira de quem
## nada). `novo_fio`: este ponto não liga ao anterior (outro corpo, ou o mesmo depois de sair da água).
func ponto_de_rasto(x: float, z: float, forca: float, novo_fio: bool = false) -> void:
	var f := clampf(forca, 0.02, 1.0)
	_rasto.append(Vector4(x, z, tempo, -f if novo_fio else f))
	while _rasto.size() > MAX_RASTO:
		_rasto.pop_front()
	_sujo = true


## Põe `no` a mexer a água. `raio`: o do corpo na linha de água (m). `pontos` (opcional): Callable () ->
## Array[Vector3] com os sítios onde o corpo fura a superfície agora — (x, z, raio) de cada perna ou do tronco;
## sem ele, é um anel só, à volta do nó.
func seguir(no: Node3D, raio: float = 0.28, pontos: Callable = Callable()) -> void:
	deixar(no)
	_seguidos.append({"no": no, "raio": raio, "pontos": pontos, "antes": null, "andado_p": 0.0, "andado_r": 0.0,
		"parado": 0.0, "dentro": false, "lado": 1.0, "vigor": 0.0, "agito": 0.0, "nada": false})


func deixar(no: Node3D) -> void:
	for i in range(_seguidos.size() - 1, -1, -1):
		if _seguidos[i]["no"] == no:
			_seguidos.remove_at(i)
	_sujo = true


## Este nó já está a mexer a água?
func segue(no: Node3D) -> bool:
	for s: Dictionary in _seguidos:
		if s["no"] == no:
			return true
	return false


func a_seguir() -> int:
	return _seguidos.size()


func pulsos_vivos() -> int:
	return _pulsos.size()


func pontos_de_rasto() -> int:
	return _rasto.size()


## ORDEM ÁGUA-REAÇÃO: o agito de `no` agora (0 = a água à volta dele está calma … 1 = a mexê-la de todo); -1 se
## não é seguido. Fora de água é 0.
func agito_de(no: Node3D) -> float:
	for s: Dictionary in _seguidos:
		if s["no"] == no:
			return float(s["agito"])
	return -1.0


## O custo médio do avancar() desde o último pedido (µs por quadro; zera a conta).
func custo_medio_us() -> float:
	var m := float(_custo_us) / float(maxi(_custo_n, 1))
	_custo_us = 0
	_custo_n = 0
	return m


func _process(delta: float) -> void:
	avancar(delta)


## Um passo do relógio da água (o _process chama-o; as provas sem janela também).
func avancar(delta: float) -> void:
	var t0 := Time.get_ticks_usec()
	tempo += delta
	var corpos := PackedVector4Array()
	var agitos := PackedFloat32Array()
	for i in range(_seguidos.size() - 1, -1, -1):
		var s: Dictionary = _seguidos[i]
		var no: Node3D = s["no"]
		if not is_instance_valid(no) or not no.is_inside_tree():
			_seguidos.remove_at(i)
			continue
		var p := no.global_position
		var imerso := imersao(p.x, p.z, p.y)
		var antes = s["antes"]
		s["antes"] = p
		if imerso <= 0.02:
			s["dentro"] = false
			s["vigor"] = 0.0
			s["agito"] = 0.0
			s["nada"] = false
			continue
		var passo := 0.0
		var rumo := Vector2.ZERO
		if antes != null:
			var d := Vector2(p.x - antes.x, p.z - antes.z)
			passo = d.length()
			if passo > 0.0001:
				rumo = d / passo
		var veloc := passo / maxf(delta, 0.0001)
		var vigor := clampf(veloc / 1.2, 0.0, 1.0)
		s["vigor"] = lerpf(float(s["vigor"]), vigor, clampf(delta * 6.0, 0.0, 1.0))
		# ÁGUA-REAÇÃO: o agito sobe logo com a velocidade e, parado, cai a direito até 0 em CALMA_S
		var alvo := clampf(veloc / AGITO_VELOC_M_S, 0.0, 1.0)
		s["agito"] = maxf(alvo, float(s["agito"]) - delta / CALMA_S)
		var nada := a_nadar(p.x, p.z)
		# quanto do corpo vai na água: 0 = pelo tornozelo … 1 = pelo peito (a esteira cresce com isto)
		var fundo := clampf((imerso - 0.15) / (FLUTUA_M - 0.15), 0.0, 1.0)
		# os sítios onde o corpo fura a superfície
		var furos: Array = []
		var pontos: Callable = s["pontos"]
		if pontos.is_valid():
			furos = pontos.call()
		if furos.is_empty():
			furos = [Vector3(p.x, p.z, float(s["raio"]))]
		for f: Vector3 in furos:
			if corpos.size() < MAX_CORPOS:
				corpos.append(Vector4(f.x, f.y, f.z, float(s["vigor"])))
				agitos.append(float(s["agito"]))
		# os anéis: um por cada PASSO_PULSO_M andado (alternando os furos: um pé, o outro), ou um fraco, parado
		s["andado_p"] = float(s["andado_p"]) + passo
		s["andado_r"] = float(s["andado_r"]) + passo
		s["parado"] = float(s["parado"]) + delta
		var novo: bool = not s["dentro"]
		# ÁGUA-REAÇÃO: o salpico — ao entrar na água (no primeiro furo: o pé que entra) e ao passar a nadar (o tronco
		# deita-se na água); a força cresce com a velocidade e com quanto do corpo vai dentro. Quem já começa dentro
		# de água (o primeiro quadro em que é seguido) não entrou: não salpica.
		var entrou: bool = novo and antes != null
		if entrou or (nada and not bool(s["nada"]) and not novo):
			var fs: Vector3 = furos[0]
			salpico(fs.x, fs.y, (0.85 if nada else 0.55 + 0.35 * fundo) * (0.55 + 0.45 * clampf(veloc / 1.2, 0.0, 1.0)))
			s["agito"] = 1.0
			s["andado_p"] = 0.0
			s["parado"] = 0.0
		s["nada"] = nada
		if float(s["andado_p"]) >= PASSO_PULSO_M:
			s["andado_p"] = 0.0
			s["parado"] = 0.0
			s["lado"] = -float(s["lado"])
			var f: Vector3 = furos[(0 if float(s["lado"]) > 0.0 else furos.size() - 1)]
			pulso(f.x, f.y, (0.50 + 0.40 * fundo) * (0.45 + 0.55 * vigor))
		elif float(s["parado"]) >= PULSO_PARADO_S:
			s["parado"] = 0.0
			# ÁGUA-REAÇÃO: parado, o anel fraco enfraquece com o agito e deixa de nascer quando a água acalma
			if float(s["agito"]) > 0.05:
				pulso(p.x, p.z, 0.22 * float(s["agito"]))
		# a esteira: um ponto por cada PASSO_RASTO_M (o fio recomeça quando o corpo entra na água)
		if float(s["andado_r"]) >= PASSO_RASTO_M or novo:
			s["andado_r"] = 0.0
			ponto_de_rasto(p.x - rumo.x * 0.10, p.z - rumo.y * 0.10, 0.10 + 0.90 * fundo * fundo, novo)
		s["dentro"] = true
	# o que já morreu sai das listas
	while not _pulsos.is_empty() and tempo - _pulsos[0].z > VIDA_PULSO_S:
		_pulsos.pop_front()
	while _rasto.size() > 1 and tempo - _rasto[1].z > VIDA_RASTO_S:
		_rasto.pop_front()
	if _rasto.size() == 1 and tempo - _rasto[0].z > VIDA_RASTO_S:
		_rasto.clear()
	_escrever(corpos, agitos)
	_custo_us += Time.get_ticks_usec() - t0
	_custo_n += 1


func _escrever(corpos: PackedVector4Array = PackedVector4Array(), agitos: PackedFloat32Array = PackedFloat32Array()) -> void:
	if material == null:
		return
	material.set_shader_parameter("tempo", tempo)
	var n_corpos := corpos.size()
	corpos.resize(MAX_CORPOS)
	agitos.resize(MAX_CORPOS)
	material.set_shader_parameter("corpos", corpos)
	material.set_shader_parameter("corpos_agito", Vector4(agitos[0], agitos[1], agitos[2], agitos[3]))
	material.set_shader_parameter("n_corpos", n_corpos)
	if not _sujo:
		return
	_sujo = false
	var p := PackedVector4Array(_pulsos)
	p.resize(MAX_PULSOS)
	material.set_shader_parameter("pulsos", p)
	material.set_shader_parameter("n_pulsos", _pulsos.size())
	var r := PackedVector4Array(_rasto)
	r.resize(MAX_RASTO)
	material.set_shader_parameter("rasto", r)
	material.set_shader_parameter("n_rasto", _rasto.size())
