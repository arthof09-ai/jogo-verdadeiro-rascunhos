extends Node
## rastro_relva.gd — Ordem GRAMA (39/46). O RASTRO na relva: quem atravessa a erva abre-a por onde passa, e ela
## recupera sozinha — cada altura à sua maneira. Só apresentação: nenhuma regra lê isto, nada aqui muda casas,
## custos nem alcances (o que o servidor manda continua a mandar).
##
## A TÉCNICA
##  · COMO SE REGISTA O CAMINHO: um mapa do chão (N × N pontos sobre a zona da relva que interessa) guarda, em
##    cada ponto, QUANDO foi a última passagem (relógio do rastro, em segundos), PARA ONDE a erva foi empurrada
##    (um rumo no chão) e COM QUE FORÇA (0–1: 1 debaixo de quem passa, a cair para os lados e — mais longe — para
##    a frente). Não se guarda «quanto falta recuperar»: guarda-se a HORA. Por isso a CPU só escreve à volta de
##    quem anda (uma pegada em forma de ovo, comprida para a frente) e nunca tem de varrer o mapa para o fazer
##    esquecer: o esquecimento é uma conta sobre a idade (agora − hora), feita onde é precisa.
##  · COMO A ERVA O LÊ: o shader da relva (shaders/rastro_relva.gdshaderinc) lê o ponto debaixo da RAIZ de cada
##    tufo, faz a idade e dobra o tufo para o rumo guardado, conforme a ALTURA do próprio tufo (em metros):
##      baixa  (< ~0,55 m)  só mesmo debaixo dos pés, dobra pouco e volta num instante, com um ressalto de mola;
##      média  (~0,55–1,15) abre já À FRENTE de quem vem (a força baixa chega para a abrir) e fecha logo atrás;
##      alta   (> ~1,15 m)  deita-se para os lados e fica: um corredor que se segura e se fecha devagar.
##    A dobra do rastro SOMA-SE à do vento (o vento continua a correr por cima, mais contido na erva deitada);
##    onde a força é zero ou a idade passou do tempo de recuperação a conta dá zero — a relva de sempre.
##  · NADA É PERMANENTE: passado o tempo de recuperação da erva mais lenta, o mapa inteiro vale zero e o shader
##    nem o lê (`rastro_ligado` = 0): com ninguém a andar, o custo é nenhum.
## As MESMAS contas vivem aqui (`resposta`, `abertura_em`) e no shader — os números saem daqui, de CLASSES, e
## vão para o shader como uniformes: uma tabela só.

## As três alturas: a altura de referência de cada uma (m) e o seu jeito de rastro.
##   lim0, lim1  a força a partir da qual começa a abrir e a força em que está toda aberta;
##   segura      quanto tempo fica toda aberta depois de quem passa se afastar (s);
##   fecha       quanto tempo leva a fechar depois disso (s);
##   angulo      a dobra máxima do tufo (rad);
##   mola        (só a baixa) o ressalto: a dobra apaga-se como uma mola (amortecimento 1/s, frequência rad/s).
const CLASSES := {
	"baixa": {"altura_m": 0.30, "lim0": 0.50, "lim1": 0.92, "segura": 0.0, "fecha": 0.9, "angulo": 0.85, "mola": Vector2(4.5, 9.0)},
	"media": {"altura_m": 0.95, "lim0": 0.04, "lim1": 0.50, "segura": 0.25, "fecha": 1.3, "angulo": 1.10, "mola": Vector2.ZERO},
	"alta": {"altura_m": 1.40, "lim0": 0.22, "lim1": 0.72, "segura": 3.0, "fecha": 9.0, "angulo": 1.20, "mola": Vector2.ZERO},
}
const ORDEM: Array[String] = ["baixa", "media", "alta"]
## As fronteiras entre os jeitos, pela altura do tufo (m): abaixo de A0 é baixa pura, de A1 a A2 média pura,
## acima de A3 alta pura; entre elas mistura-se.
const FRONTEIRAS := Vector4(0.45, 0.62, 1.10, 1.20)

## Pontos por lado do mapa do rastro.
const N := 256
## Margem (m) à volta da zona jogável que o mapa do rastro também cobre.
const MARGEM_M := 4.0
## A pegada (em raios de quem passa): para a frente, para trás e para os lados.
const OVO_FRENTE := 2.4
const OVO_TRAS := 0.8
## Quem está parado refresca a pegada de tantos em tantos segundos (a erva não fecha debaixo dele).
const REFRESCO_S := 0.12
## Quem anda carimba a cada tantos metros.
const PASSO_M := 0.05
const NUNCA := -1.0e6

## O relógio do rastro (s). Só anda para a frente; `avancar` é o passo (o _process chama-o com o delta).
var agora := 0.0
## Pára o relógio e as pegadas (as provas avançam à mão com `avancar`).
var parado := false
## A zona que o mapa do rastro cobre (x, z no mundo).
var zona := Rect2(-37.5, -37.5, 75.0, 75.0)
## A altura da erva (m), para o rastro saber que jeito tem a erva de cada sítio (a mesma que o shader mede em
## cada tufo, aqui por zonas): as manchas de altura ([[Rect2, altura em m], …] — as do mapa:
## campo_floresta.definir_manchas_relva), a zona jogável (erva pisada) e o resto do mapa (a erva de sempre).
var manchas: Array = []
var campo := Rect2()
var altura_no_campo := 0.26
var altura_fora := 0.68

var _dados := PackedFloat32Array()      # N·N·4: hora, rumo x, rumo z, força
var _img: Image
var _tex: ImageTexture
var _sujo := false
var _materiais: Array[ShaderMaterial] = []
var _ultima_pegada := NUNCA
var _ligado := false
var _seguidos: Array = []                # [{no, raio, ultimo: Vector3, tem: bool, t: float, rumo: Vector2}]


func _init() -> void:
	_dados.resize(N * N * 4)
	_limpar()
	_img = Image.create_from_data(N, N, false, Image.FORMAT_RGBAF, _dados.to_byte_array())
	_tex = ImageTexture.create_from_image(_img)


func _limpar() -> void:
	for i in N * N:
		_dados[i * 4] = NUNCA
		_dados[i * 4 + 1] = 0.0
		_dados[i * 4 + 2] = 0.0
		_dados[i * 4 + 3] = 0.0


# ------------------------------------------------------------------ ligar

## Os materiais que lêem o rastro (a relva e as hastes), a zona que o mapa do rastro cobre e a zona jogável
## (onde a erva está pisada).
func ligar(materiais: Array[ShaderMaterial], zona_coberta: Rect2, zona_jogo: Rect2 = Rect2()) -> void:
	_materiais = materiais
	zona = zona_coberta
	campo = zona_jogo
	for m in _materiais:
		m.set_shader_parameter("rastro_tex", _tex)
		m.set_shader_parameter("rastro_rect", Vector4(zona.position.x, zona.position.y, 1.0 / zona.size.x, 1.0 / zona.size.y))
		m.set_shader_parameter("rastro_fronteiras", FRONTEIRAS)
		for nome in ORDEM:
			var c: Dictionary = CLASSES[nome]
			m.set_shader_parameter("rastro_" + nome, Vector4(c["lim0"], c["lim1"], c["segura"], c["fecha"]))
		m.set_shader_parameter("rastro_angulos", Vector3(CLASSES["baixa"]["angulo"], CLASSES["media"]["angulo"], CLASSES["alta"]["angulo"]))
		m.set_shader_parameter("rastro_mola", CLASSES["baixa"]["mola"])
	_escrever_relogio()


## A zona que o rastro cobre para uma zona jogável (a zona e a margem, num quadrado); sem zona, a arena do mapa.
static func zona_para(zona_jogo: Rect2) -> Rect2:
	if not zona_jogo.has_area():
		return Rect2(-37.5, -37.5, 75.0, 75.0)
	var lado := maxf(zona_jogo.size.x, zona_jogo.size.y) + 2.0 * MARGEM_M
	var meio := zona_jogo.get_center()
	return Rect2(meio.x - lado * 0.5, meio.y - lado * 0.5, lado, lado)


## A textura do mapa do rastro (hora, rumo x, rumo z, força).
func textura() -> ImageTexture:
	return _tex


# ------------------------------------------------------------------ quem passa

## Passa a seguir um nó: por onde ele andar, a erva abre. `raio` = meia largura de quem passa (m).
func seguir(no: Node3D, raio: float = 0.5) -> void:
	deixar(no)
	_seguidos.append({"no": no, "raio": raio, "ultimo": Vector3.ZERO, "tem": false, "t": NUNCA, "rumo": Vector2.ZERO})


func deixar(no: Node3D) -> void:
	for i in range(_seguidos.size() - 1, -1, -1):
		if _seguidos[i]["no"] == no:
			_seguidos.remove_at(i)


func seguidos() -> int:
	return _seguidos.size()


func _process(delta: float) -> void:
	if parado:
		return
	avancar(delta)


## Um passo do relógio do rastro: carimba as pegadas de quem se segue e escreve a hora nos materiais.
func avancar(delta: float) -> void:
	agora += maxf(delta, 0.0)
	for i in range(_seguidos.size() - 1, -1, -1):
		var s: Dictionary = _seguidos[i]
		var no: Node3D = s["no"]
		if not is_instance_valid(no):
			_seguidos.remove_at(i)
			continue
		if not no.is_inside_tree() or not no.is_visible_in_tree():
			s["tem"] = false
			continue
		var p := no.global_position
		if not s["tem"]:
			s["tem"] = true
			s["ultimo"] = p
			s["t"] = agora
			pisar(p, Vector2.ZERO, s["raio"])
			continue
		var antes: Vector3 = s["ultimo"]
		var d := Vector2(p.x - antes.x, p.z - antes.z)
		var comp := d.length()
		if comp >= PASSO_M:
			s["rumo"] = d / comp
			s["ultimo"] = p
			s["t"] = agora
			# um passo largo (a figura que salta de casa em casa) carimba-se ao longo do caminho, não só à chegada
			var meio_raio := maxf(float(s["raio"]) * 0.5, PASSO_M)
			var n := clampi(int(ceil(comp / meio_raio)), 1, 48)
			for k in range(1, n + 1):
				pisar(antes.lerp(p, float(k) / float(n)), s["rumo"], s["raio"])
		elif agora - float(s["t"]) >= REFRESCO_S:
			# parado (ou quase): a pegada redonda, refrescada — a erva não fecha debaixo de quem lá está
			s["t"] = agora
			pisar(p, Vector2.ZERO, s["raio"])
	if _ligado and agora - _ultima_pegada > recuperacao_maxima() + 0.5:
		# já ninguém passa e a erva mais lenta já fechou: o mapa volta a zero e o shader deixa de o ler
		_limpar()
		_sujo = true
		_ligado = false
	if _sujo:
		_sujo = false
		_img.set_data(N, N, false, Image.FORMAT_RGBAF, _dados.to_byte_array())
		_tex.update(_img)
	_escrever_relogio()


func _escrever_relogio() -> void:
	for m in _materiais:
		m.set_shader_parameter("rastro_agora", agora)
		m.set_shader_parameter("rastro_ligado", 1.0 if _ligado else 0.0)


## Uma pegada: quem está em `p` (mundo), a andar para `rumo` (xz, unitário; ZERO = parado), com meia largura
## `raio` (m). Cada ponto do mapa debaixo da pegada fica com a força da pegada se ela for maior do que a que lá
## resta — e com a hora de agora e o rumo para onde a erva foge (para o lado de fora do caminho e um pouco para
## a frente).
func pisar(p: Vector3, rumo: Vector2, raio: float = 0.5, forca: float = 1.0) -> void:
	var r_frente := raio * (OVO_FRENTE if rumo != Vector2.ZERO else 1.0)
	var r_tras := raio * (OVO_TRAS if rumo != Vector2.ZERO else 1.0)
	var alcance := maxf(r_frente, raio)
	var px := (p.x - zona.position.x) / zona.size.x * N
	var pz := (p.z - zona.position.y) / zona.size.y * N
	var ax := alcance / zona.size.x * N
	var az := alcance / zona.size.y * N
	var i0 := maxi(int(floor(px - ax)), 0)
	var i1 := mini(int(ceil(px + ax)), N - 1)
	var j0 := maxi(int(floor(pz - az)), 0)
	var j1 := mini(int(ceil(pz + az)), N - 1)
	if i0 > i1 or j0 > j1:
		return
	var lado := Vector2(-rumo.y, rumo.x)
	var passo_x := zona.size.x / N
	var passo_z := zona.size.y / N
	var tocou := false
	for j in range(j0, j1 + 1):
		var z := zona.position.y + (j + 0.5) * passo_z
		for i in range(i0, i1 + 1):
			var x := zona.position.x + (i + 0.5) * passo_x
			var rel := Vector2(x - p.x, z - p.z)
			var f: float
			var foge: Vector2
			if rumo == Vector2.ZERO:
				var d := rel.length()
				f = forca * (1.0 - smoothstep(0.30, 1.0, d / raio))
				foge = rel / d if d > 0.001 else Vector2(1.0, 0.0)
			else:
				var ao_longo := rel.dot(rumo)
				var de_lado := rel.dot(lado)
				var u := ao_longo / (r_frente if ao_longo > 0.0 else r_tras)
				var v := de_lado / raio
				f = forca * (1.0 - smoothstep(0.30, 1.0, sqrt(u * u + v * v)))
				foge = (lado * (1.0 if de_lado >= 0.0 else -1.0) + rumo * 0.35).normalized()
			if f <= 0.0:
				continue
			var k := (j * N + i) * 4
			if _dados[k + 3] > 0.0:
				# só escreve se a pegada nova abrir a erva deste sítio pelo menos tanto como a que lá resta: a
				# abertura nunca dá um salto para trás (a cauda da pegada não fecha o que o corpo abriu)
				var pes := pesos(altura_da_erva(x, z))
				if _abertura(pes, f, 0.0) < _abertura(pes, _dados[k + 3], agora - _dados[k]):
					continue
			_dados[k] = agora
			_dados[k + 1] = foge.x
			_dados[k + 2] = foge.y
			_dados[k + 3] = f
			tocou = true
	if tocou:
		_sujo = true
		_ligado = true
		_ultima_pegada = agora


## A altura da erva (m) em (x, z), por zonas: a mancha que lá houver, a erva pisada da zona jogável, ou a do mapa.
func altura_da_erva(x: float, z: float) -> float:
	var q := Vector2(x, z)
	for m: Array in manchas:
		if (m[0] as Rect2).has_point(q):
			return float(m[1])
	if campo.has_area() and campo.has_point(q):
		return altura_no_campo
	return altura_fora


## A abertura (0–1, em valor absoluto) da erva com os pesos `pes` (baixa, média, alta), com a força e a idade dadas.
static func _abertura(pes: Vector3, forca: float, idade: float) -> float:
	var total := 0.0
	for c in 3:
		if pes[c] > 0.0:
			total += pes[c] * absf(resposta(ORDEM[c], forca, idade))
	return total


# ------------------------------------------------------------------ as contas (as mesmas do shader)

## O peso de cada jeito (baixa, média, alta) para um tufo com `h` metros. Soma 1.
static func pesos(h: float) -> Vector3:
	var baixa := 1.0 - smoothstep(FRONTEIRAS.x, FRONTEIRAS.y, h)
	var alta := smoothstep(FRONTEIRAS.z, FRONTEIRAS.w, h)
	return Vector3(baixa, maxf(1.0 - baixa - alta, 0.0), alta)


## A abertura (−1 a 1; 1 = toda aberta; negativo = o ressalto da mola da erva baixa) de um tufo do jeito
## `classe`, num ponto com a força `forca`, `idade` segundos depois da passagem.
static func resposta(classe: String, forca: float, idade: float) -> float:
	var c: Dictionary = CLASSES[classe]
	if idade < 0.0 or forca <= 0.0:
		return 0.0
	var abre := smoothstep(float(c["lim0"]), float(c["lim1"]), forca)
	var mola: Vector2 = c["mola"]
	if mola != Vector2.ZERO:
		# a mola: apaga-se a oscilar, e cala-se de todo ao fim do tempo de fecho
		var cala := 1.0 - smoothstep(float(c["fecha"]) * 0.6, float(c["fecha"]), idade)
		return abre * exp(-idade * mola.x) * cos(idade * mola.y) * cala
	return abre * (1.0 - smoothstep(float(c["segura"]), float(c["segura"]) + float(c["fecha"]), idade))


## O tempo (s) ao fim do qual a erva do jeito `classe` está outra vez como estava (abertura 0).
static func recuperacao(classe: String) -> float:
	var c: Dictionary = CLASSES[classe]
	return float(c["segura"]) + float(c["fecha"])


static func recuperacao_maxima() -> float:
	var t := 0.0
	for nome in ORDEM:
		t = maxf(t, recuperacao(nome))
	return t


## O que o mapa do rastro guarda em (x, z): {"forca", "idade", "rumo": Vector2}. Fora da zona: força 0.
func ponto(x: float, z: float) -> Dictionary:
	var i := int(floor((x - zona.position.x) / zona.size.x * N))
	var j := int(floor((z - zona.position.y) / zona.size.y * N))
	if i < 0 or j < 0 or i >= N or j >= N:
		return {"forca": 0.0, "idade": INF, "rumo": Vector2.ZERO}
	var k := (j * N + i) * 4
	return {"forca": _dados[k + 3], "idade": agora - _dados[k], "rumo": Vector2(_dados[k + 1], _dados[k + 2])}


## A abertura (−1 a 1) do tufo de `h` metros com a raiz em (x, z), agora — a mesma conta do shader.
## h < 0: a altura da erva que há nesse sítio (altura_da_erva).
func abertura_em(x: float, z: float, h: float = -1.0) -> float:
	if h < 0.0:
		h = altura_da_erva(x, z)
	var q := ponto(x, z)
	if float(q["forca"]) <= 0.0:
		return 0.0
	var p := pesos(h)
	var a := 0.0
	for c in 3:
		if p[c] > 0.0:
			a += p[c] * resposta(ORDEM[c], q["forca"], q["idade"])
	return a


## Há algum rastro por fechar? (falso = o mapa vale zero e o shader nem o lê)
func ativo() -> bool:
	return _ligado


## Quantos pontos do mapa ainda têm a erva aberta (abertura > 1 %) — para as provas.
func pontos_abertos() -> int:
	if not _ligado:
		return 0
	var n := 0
	var passo_x := zona.size.x / N
	var passo_z := zona.size.y / N
	for j in N:
		for i in N:
			var k := (j * N + i) * 4
			if _dados[k + 3] <= 0.0:
				continue
			var x := zona.position.x + (i + 0.5) * passo_x
			var z := zona.position.y + (j + 0.5) * passo_z
			if absf(abertura_em(x, z)) > 0.01:
				n += 1
	return n
