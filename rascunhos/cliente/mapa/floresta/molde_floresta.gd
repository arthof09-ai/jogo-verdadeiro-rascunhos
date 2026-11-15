extends RefCounted
## molde_floresta.gd — Ordem 54. O mapa da floresta construído UMA vez por chave, reutilizado depois.
##
## Desde a Ordem 45 cada arena (a do jogador e a do ecrã do Mestre) monta o mapa inteiro pelo módulo partilhado
## (campo_da_mesa.montar_mapa), e cada abertura do ecrã do Mestre construía-o outra vez de raiz: ~1,5 s no
## primeiro e ~3 s nos seguintes. A construção é determinística (a semente, a zona jogável e as constantes do
## mapa decidem tudo), por isso o mesmo mapa não precisa de ser feito duas vezes.
##
## Como: no fim da PRIMEIRA construção de uma chave, ainda dentro do _ready (antes de alguém lhe mexer: perfil,
## clima, recorte, ocupação da grelha), guarda-se um MOLDE intacto do mapa acabado: os nós (num PackedScene) e o
## estado dos scripts (valores copiados). Os mapas seguintes com a mesma chave VESTEM-SE de uma cópia do molde
## em vez de se construírem.
##   - partilha-se só o que ninguém muda depois de construído: as malhas, as texturas, as formas de colisão, os
##     shaders;
##   - copia-se para cada mapa o que muda: os materiais (recorte, densidade, neve e água), as MultiMesh (o LOD da
##     relva), a grelha (ocupação), os lotes, o gerador de acaso e todos os contentores do estado.
## Cada mapa nasce, assim, como se tivesse sido construído agora; o molde nunca é entregue a ninguém e nunca muda.
## A prova está em testes/pecas_mestre.gd (o retrato inteiro do mapa vestido é igual ao do construído).
##
## Só o usa quem o pede (CampoFloresta.reutilizar_molde, ligado por campo_da_mesa.montar_mapa). O mapa sozinho
## (campo_floresta.tscn: filmes, medições) constrói sempre.

## Quantos moldes (chaves) ficam guardados; o mais antigo sai primeiro. Cada grelha (tamanho × casa) é uma zona.
const MAX_MOLDES := 3

## Desligar faz todos os mapas construírem-se de raiz (para comparar e para medir o «antes»).
static var ligado := true
## Contas da sessão (para as provas): mapas construídos com molde guardado, e mapas vestidos de um molde.
static var contas := {"guardados": 0, "vestidos": 0}

static var _moldes: Dictionary = {}  # chave -> _Molde
static var _ordem: Array[String] = []


## A referência a um nó do mapa, pelo caminho a partir do mapa (o molde não guarda nós vivos).
class _RefNo:
	extends RefCounted
	var caminho: NodePath

	func _init(c: NodePath) -> void:
		caminho = c


## Um valor de fora do mapa (o Ambiente, o Sol, a Câmara da arena): o mapa vestido fica com o seu.
class _Fora:
	extends RefCounted


class _Molde:
	extends RefCounted
	var cenas: Array[PackedScene] = []
	## caminho do nó com script (a partir do mapa; "." = o próprio mapa) -> {nome da variável: valor guardado}
	var estado: Dictionary = {}
	## MultiMesh do molde -> {"n", "visiveis", "buffer"}: o buffer vem vazio sem GPU (o servidor sem janela não
	## guarda as instâncias)
	var dados_mm: Dictionary = {}
	## por cena: as posições (na ordem de _descendentes) dos nós com nome automático (@Classe@N). O PackedScene
	## troca-lhes o «@» por «_»; ao vestir nascem outra vez sem nome, como na construção.
	var sem_nome: Array = []


## Copia valores: os recursos que mudam são copiados uma vez por objecto (a identidade mantém-se: o material que
## 50 blocos de relva partilham continua partilhado pelos 50 da cópia); o resto partilha-se.
class _Copia:
	extends RefCounted
	var mapa: Node                    # o mapa de onde (guardar) ou para onde (vestir) se copia
	var a_guardar := true
	var molde: _Molde
	var feitos: Dictionary = {}        # objecto de origem -> cópia

	func valor(v: Variant) -> Variant:
		match typeof(v):
			TYPE_OBJECT:
				return _objecto(v)
			TYPE_ARRAY:
				var a: Array = v
				if a.is_typed() and a.get_typed_builtin() != TYPE_OBJECT:
					return a.duplicate(true)
				var r: Array = a.duplicate(false)
				for i in a.size():
					r[i] = valor(a[i])
				return r
			TYPE_DICTIONARY:
				var d: Dictionary = v
				var r: Dictionary = d.duplicate(false)
				for k in d:
					r[k] = valor(d[k])
				return r
			TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, \
			TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, \
			TYPE_PACKED_COLOR_ARRAY, TYPE_PACKED_VECTOR4_ARRAY:
				return v.duplicate()  # os Packed passam por referência: cada mapa tem os seus
		return v

	func _objecto(o: Object) -> Variant:
		if o == null:
			return null
		if feitos.has(o):
			return feitos[o]
		var c: Variant = _copiar(o)
		feitos[o] = c
		return c

	func _copiar(o: Object) -> Variant:
		if o is Node:
			if a_guardar:
				var n := o as Node
				if n == mapa or mapa.is_ancestor_of(n):
					return _RefNo.new(mapa.get_path_to(n))
				return _Fora.new()
			return o  # (ao vestir, os nós já vêm resolvidos)
		if o is _RefNo:
			return mapa.get_node((o as _RefNo).caminho)
		if o is _Fora:
			return o
		if o is Material:
			var m: Material = (o as Material).duplicate(false)
			if m.next_pass != null:
				m.next_pass = _objecto(m.next_pass)
			return m
		if o is MultiMesh:
			return _multimesh(o as MultiMesh)
		if o is RandomNumberGenerator:
			var r := RandomNumberGenerator.new()
			r.seed = (o as RandomNumberGenerator).seed
			r.state = (o as RandomNumberGenerator).state
			return r
		if o is RefCounted and not (o is Resource) and o.get_script() != null:
			# os objectos do mapa com script (a grelha, os lotes): um novo, com o estado copiado
			var novo: Object = (o.get_script() as Script).new()
			for nome in variaveis(o):
				novo.set(nome, valor(o.get(nome)))
			return novo
		return o  # malhas, texturas, formas, shaders: não mudam depois de construídos — partilham-se

	## A MultiMesh: o mesmo formato, a mesma malha, o mesmo número de instâncias, os mesmos dados (pelo buffer).
	## A do molde fica VAZIA (sem instâncias: não ocupa a placa); os números e os dados ficam em molde.dados_mm.
	func _multimesh(o: MultiMesh) -> MultiMesh:
		var n := MultiMesh.new()
		n.transform_format = o.transform_format
		n.use_colors = o.use_colors
		n.use_custom_data = o.use_custom_data
		n.mesh = o.mesh
		n.custom_aabb = o.custom_aabb
		n.physics_interpolation_quality = o.physics_interpolation_quality
		if a_guardar:
			molde.dados_mm[n] = {"n": o.instance_count, "visiveis": o.visible_instance_count, "buffer": o.buffer}
			return n
		var dados: Dictionary = molde.dados_mm[o]
		n.instance_count = dados["n"]
		var buf: PackedFloat32Array = dados["buffer"]
		if buf.size() > 0 and n.instance_count > 0:
			n.buffer = buf  # sem GPU vem vazio (o servidor sem janela não guarda as instâncias): nada a copiar
		n.visible_instance_count = dados["visiveis"]
		return n

	## As variáveis de estado de um objecto com script (as que não são @export: essas dá-as quem cria o mapa).
	static func variaveis(o: Object) -> Array[String]:
		var r: Array[String] = []
		for p in o.get_property_list():
			var u: int = p["usage"]
			if u & PROPERTY_USAGE_SCRIPT_VARIABLE and not (u & PROPERTY_USAGE_STORAGE):
				r.append(p["name"])
		return r


## A chave de um mapa: tudo o que a construção lê de fora. Os caminhos do Ambiente/Sol/Câmara não entram (o
## mapa vestido monta o céu nos seus); `vistas_por_tecla` e `mostrar_medicao` também não (correm igual nos dois).
static func chave(mapa: Node) -> String:
	return var_to_str([mapa.semente, mapa.zona_jogo, mapa.relva_no_campo, mapa.densidade_relva])


static func tem(c: String) -> bool:
	return ligado and _moldes.has(c)


## Guarda o molde de `mapa`, acabado de construir (no fim do _ready). `raizes` são os nós que a construção
## pendurou no mapa (a Arena e o Fundo).
static func guardar(mapa: Node, raizes: Array[Node], c: String) -> void:
	if not ligado:
		return
	var m := _Molde.new()
	var cp := _Copia.new()
	cp.mapa = mapa
	cp.molde = m
	for raiz in raizes:
		var d := raiz.duplicate(Node.DUPLICATE_GROUPS | Node.DUPLICATE_SCRIPTS)
		var auto: Array[int] = []
		var o_nos := _descendentes(raiz)
		for i in o_nos.size():
			if String(o_nos[i].name).begins_with("@"):
				auto.append(i)
		m.sem_nome.append(auto)
		_trocar_recursos(raiz, d, cp)
		_guardar_estado(mapa, raiz, cp, m)
		for x in _descendentes(d):
			x.owner = d
		var cena := PackedScene.new()
		var e := cena.pack(d)
		d.free()
		if e != OK:
			push_warning("[floresta] molde não guardado (pack: %d)" % e)
			return
		m.cenas.append(cena)
	var proprio: Dictionary = {}
	for nome in _Copia.variaveis(mapa):
		proprio[nome] = cp.valor(mapa.get(nome))
	m.estado[NodePath(".")] = proprio
	_moldes[c] = m
	_ordem.erase(c)
	_ordem.append(c)
	while _ordem.size() > MAX_MOLDES:
		_moldes.erase(_ordem.pop_front())
	contas["guardados"] += 1


## Veste `mapa` (ainda sem filhos da construção) com uma cópia do molde da chave `c`. Devolve false se não há.
static func vestir(mapa: Node, c: String) -> bool:
	if not tem(c):
		return false
	var m: _Molde = _moldes[c]
	_ordem.erase(c)
	_ordem.append(c)
	var cp := _Copia.new()
	cp.mapa = mapa
	cp.a_guardar = false
	cp.molde = m
	for k in m.cenas.size():
		var raiz := m.cenas[k].instantiate()
		var nos := _descendentes(raiz)
		for x in nos:
			x.owner = null
		for i in m.sem_nome[k]:
			_sem_nome(nos[i])
		_trocar_recursos(raiz, raiz, cp)
		mapa.add_child(raiz)
	for caminho: NodePath in m.estado:
		var alvo := mapa.get_node(caminho)
		var guardado: Dictionary = m.estado[caminho]
		for nome in guardado:
			var v: Variant = cp.valor(guardado[nome])
			if v is _Fora:
				continue
			alvo.set(nome, v)
	contas["vestidos"] += 1
	return true


## Troca `n` por um nó novo da mesma classe, com as mesmas propriedades e os mesmos filhos, mas SEM nome: o pai
## dá-lhe o nome automático, como na construção.
static func _sem_nome(n: Node) -> void:
	var pai := n.get_parent()
	var i := n.get_index()
	var novo: Node = ClassDB.instantiate(n.get_class())
	if n.get_script() != null:
		novo.set_script(n.get_script())
	for p in n.get_property_list():
		var nome: String = p["name"]
		if int(p["usage"]) & PROPERTY_USAGE_STORAGE and nome != "name" and nome != "script":
			novo.set(nome, n.get(nome))
	for g in n.get_groups():
		novo.add_to_group(g, true)
	for f in n.get_children():
		n.remove_child(f)
		novo.add_child(f)
	pai.remove_child(n)
	pai.add_child(novo)
	pai.move_child(novo, i)
	n.free()


## Os recursos que mudam, em cada nó de `origem`, passam a cópias no nó correspondente de `destino` (a mesma árvore).
static func _trocar_recursos(origem: Node, destino: Node, cp: _Copia) -> void:
	var o_nos := _descendentes(origem)
	var d_nos := _descendentes(destino)
	o_nos.push_front(origem)
	d_nos.push_front(destino)
	for i in o_nos.size():
		var o := o_nos[i]
		var d := d_nos[i]
		if o is GeometryInstance3D:
			(d as GeometryInstance3D).material_override = cp.valor((o as GeometryInstance3D).material_override)
			(d as GeometryInstance3D).material_overlay = cp.valor((o as GeometryInstance3D).material_overlay)
		if o is MeshInstance3D:
			for s in (o as MeshInstance3D).get_surface_override_material_count():
				(d as MeshInstance3D).set_surface_override_material(s, cp.valor((o as MeshInstance3D).get_surface_override_material(s)))
		if o is MultiMeshInstance3D:
			(d as MultiMeshInstance3D).multimesh = cp.valor((o as MultiMeshInstance3D).multimesh)


## O estado dos nós com script debaixo de `raiz` (a relva), com os caminhos a partir do mapa.
static func _guardar_estado(mapa: Node, raiz: Node, cp: _Copia, m: _Molde) -> void:
	var nos := _descendentes(raiz)
	nos.push_front(raiz)
	for n in nos:
		if n.get_script() == null:
			continue
		var e: Dictionary = {}
		for nome in _Copia.variaveis(n):
			e[nome] = cp.valor(n.get(nome))
		m.estado[mapa.get_path_to(n)] = e


static func _descendentes(n: Node) -> Array[Node]:
	var r: Array[Node] = []
	for f in n.get_children():
		r.append(f)
		r.append_array(_descendentes(f))
	return r


# ------------------------------------------------------------------ a prova (testes/pecas_mestre.gd)

## O RETRATO de um mapa: tudo o que decide o que se vê e o que o jogo lê dele, em linhas de texto comparáveis.
## Cada nó (caminho, classe, script, transformação, visibilidade, grupos, sombra, margens, malha, materiais,
## MultiMesh, forma), cada recurso pelas suas propriedades guardadas (os materiais com todos os parâmetros, as
## malhas e as MultiMesh pelos dados), o estado dos scripts (o mapa, a relva, a grelha, os lotes) e o que o mapa
## montou no Ambiente, no Sol e na Câmara do dono. A partilha também entra: cada recurso tem um número pela ordem
## em que aparece, por isso «50 blocos com o mesmo material» e «50 materiais iguais» dão retratos diferentes.
## Os números grandes (vértices, instâncias, imagens) entram pelo tamanho e por um resumo (hash).
## Fica de fora só o que é tempo: medidas.carga_ms.
static func retrato(mapa: Node) -> PackedStringArray:
	var r := _Retrato.new()
	r.mapa = mapa
	var nos := _descendentes(mapa)
	nos.push_front(mapa)
	for n in nos:
		r.no(n)
	var dono := mapa.get_parent()
	for caminho in [mapa.no_ambiente, mapa.no_sol, mapa.no_camera]:
		var fora := mapa.get_node_or_null(caminho)
		if fora != null:
			r.linhas.append("fora %s %s" % [fora.name, r.props(fora, ["environment", "transform", "light_color",
				"light_energy", "shadow_enabled", "near", "far"])])
	return r.linhas


## Os objectos que mudam (materiais, MultiMesh, grelha, lotes, gerador): dois mapas vivos não podem partilhar nenhum.
static func mutaveis(mapa: Node) -> Array:
	var r := _Retrato.new()
	r.mapa = mapa
	var nos := _descendentes(mapa)
	nos.push_front(mapa)
	for n in nos:
		r.no(n)
	var muda: Array = []
	for o in r.vistos:
		if o is Material or o is MultiMesh or o is RandomNumberGenerator \
				or (o is RefCounted and not (o is Resource) and o.get_script() != null):
			muda.append(o)
	return muda


class _Retrato:
	extends RefCounted
	var mapa: Node
	var linhas := PackedStringArray()
	var vistos: Dictionary = {}  # objecto -> número

	func no(n: Node) -> void:
		var caminho := _caminho(n)
		var s := "%s [%s] script=%s" % [caminho, n.get_class(), n.get_script().resource_path if n.get_script() else "-"]
		var grupos: Array = n.get_groups().filter(func(g): return not String(g).begins_with("_"))
		grupos.sort()
		s += " grupos=%s dono=%s" % [grupos, n.owner != null]
		if n is Node3D:
			s += " t=%s vis=%s" % [var_to_str((n as Node3D).transform), (n as Node3D).visible]
		if n is GeometryInstance3D:
			s += " " + props(n, ["cast_shadow", "extra_cull_margin", "lod_bias", "layers", "gi_mode",
				"visibility_range_begin", "visibility_range_end", "material_override", "material_overlay", "sorting_offset"])
		if n is MeshInstance3D:
			s += " " + props(n, ["mesh", "skeleton"])
			for i in (n as MeshInstance3D).get_surface_override_material_count():
				s += " sup%d=%s" % [i, valor((n as MeshInstance3D).get_surface_override_material(i))]
		if n is MultiMeshInstance3D:
			s += " " + props(n, ["multimesh"])
		if n is CollisionShape3D:
			s += " " + props(n, ["shape", "disabled"])
		if n is CollisionObject3D:
			s += " " + props(n, ["collision_layer", "collision_mask"])
		linhas.append(s)
		if n.get_script() != null:
			for nome in _Copia.variaveis(n):
				var v: Variant = n.get(nome)
				if n == mapa and nome == "medidas":
					v = (v as Dictionary).duplicate()
					(v as Dictionary).erase("carga_ms")
				linhas.append("  %s.%s = %s" % [caminho, nome, valor(v)])

	func props(o: Object, nomes: Array) -> String:
		var p := PackedStringArray()
		for nome in nomes:
			if nome in o:
				p.append("%s=%s" % [nome, valor(o.get(nome))])
		return " ".join(p)

	func _caminho(n: Node) -> String:
		if n == mapa or mapa.is_ancestor_of(n):
			# os nomes automáticos (@Classe@123) mudam com o contador do motor: só a classe conta
			var partes := String(mapa.get_path_to(n)).split("/")
			for i in partes.size():
				if partes[i].begins_with("@"):
					partes[i] = "@" + partes[i].get_slice("@", 1) + "@"
			return "/".join(partes)
		return "fora:" + String(n.name)

	func valor(v: Variant) -> String:
		match typeof(v):
			TYPE_OBJECT:
				return _objecto(v)
			TYPE_ARRAY:
				var p := PackedStringArray()
				for x in v:
					p.append(valor(x))
				return "[" + ", ".join(p) + "]"
			TYPE_DICTIONARY:
				var p := PackedStringArray()
				var chaves: Array = (v as Dictionary).keys()
				for k in chaves:
					p.append("%s: %s" % [var_to_str(k), valor(v[k])])
				return "{" + ", ".join(p) + "}"
			TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, \
			TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, \
			TYPE_PACKED_COLOR_ARRAY, TYPE_PACKED_VECTOR4_ARRAY:
				return "%s(%d #%d)" % [type_string(typeof(v)), v.size(), hash(v)]
		return var_to_str(v)

	func _objecto(o: Object) -> String:
		if o == null:
			return "null"
		if o is Node:
			return "nó:" + _caminho(o as Node)
		if vistos.has(o):
			return "#%d" % vistos[o]
		vistos[o] = vistos.size()
		var id := "#%d" % vistos[o]
		if o is Resource and (o as Resource).resource_path.begins_with("res://") and not (o as Resource).resource_path.contains("::"):
			return "%s=%s(%s)" % [id, o.get_class(), (o as Resource).resource_path]
		if o is RandomNumberGenerator:
			return "%s=RNG(%d,%d)" % [id, (o as RandomNumberGenerator).seed, (o as RandomNumberGenerator).state]
		if o is RefCounted and not (o is Resource) and o.get_script() != null:
			var p := PackedStringArray()
			for nome in _Copia.variaveis(o):
				p.append("%s=%s" % [nome, valor(o.get(nome))])
			return "%s=%s{%s}" % [id, (o.get_script() as Script).resource_path.get_file(), ", ".join(p)]
		var p := PackedStringArray()
		for prop in o.get_property_list():
			var u: int = prop["usage"]
			var nome: String = prop["name"]
			if not (u & PROPERTY_USAGE_STORAGE) or nome.begins_with("resource_") or nome == "script":
				continue
			p.append("%s=%s" % [nome, valor(o.get(nome))])
		if o is Mesh:
			p.append("aabb=%s" % var_to_str((o as Mesh).get_aabb()))
			for s in (o as Mesh).get_surface_count():
				p.append("sup%d=%s" % [s, valor((o as Mesh).surface_get_arrays(s))])
		if o is Texture2D:
			var img := (o as Texture2D).get_image()
			p.append("img=%s" % (valor(img.get_data()) if img != null else "null"))
		return "%s=%s{%s}" % [id, o.get_class(), ", ".join(p)]
