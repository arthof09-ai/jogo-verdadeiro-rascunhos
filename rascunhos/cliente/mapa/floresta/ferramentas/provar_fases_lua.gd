extends SceneTree
## provar_fases_lua.gd — Ordem 55. A PROVA EM NÚMEROS das fases da lua (sem render: --headless).
##
##   godot --headless --path cliente -s res://mapa/floresta/ferramentas/provar_fases_lua.gd
##   (opções depois de «--»:
##      --referencia=CAMINHO   o ciclo_dia.gd da Ordem 43 (p. ex. `git show d7b9e6c:…/ciclo_dia.gd`
##                             gravado fora do repositório): compara-o minuto a minuto com o de agora
##                             na lua cheia — TODAS as saídas da Ordem 43 têm de ser IGUAIS, bit a bit
##      --gravar               grava capturas/ciclo55/fases_lua.json)
##
## Sai com 0 se todas as verificações passarem, 1 se alguma falhar. Verifica:
##   1. ÂNCORA: calcular(h) sem idade = calcular(h, cheia) = o relógio novo (estado()) — e, com
##      --referencia, = o ciclo_dia.gd da Ordem 43, em todas as chaves, nos 1440 minutos do dia;
##   2. LUA NOVA: nenhuma luz da lua em minuto nenhum (lua_energia = 0);
##   3. QUARTOS: a luz da lua é exactamente metade da da cheia, em todos os minutos (o meio-termo
##      sai da fracção iluminada; o lua_baixa fica igual — a razão não depende da altura da lua);
##   4. SÓ A LUA MUDA: entre fases, as saídas do sol, do céu e da névoa são iguais;
##   5. O RELÓGIO: 28 dias do mundo a andar de minuto a minuto — a idade vira 1 vez por dia, às
##      12:30, volta à cheia ao fim de 28 dias, e o sinal fase_da_lua_mudou sai 4 vezes, por ordem;
##   6. A TROCA NÃO SE VÊ: às 12:30 a lua está debaixo do chão e a luz dela é 0 em todas as
##      idades — o passo de idade não mexe em nada do que se vê;
##   7. CONTINUIDADE: em cada fase, o maior passo por minuto do mundo não passa o da cheia.

const Ciclo := preload("res://mapa/floresta/ciclo_dia.gd")
const SAIDA := "res://mapa/floresta/capturas/ciclo55/fases_lua.json"
## As saídas que dependem da luz da lua (as únicas que podem mudar com a fase).
const DA_LUA := ["lua_energia", "cor_luz", "sombra_forca", "ressalto",
	"lua_idade", "lua_fase", "lua_iluminada", "lua_terminador", "lua_lado"]
const FASES := [["nova", 0.0], ["crescente", 7.0], ["cheia", 14.0], ["minguante", 21.0]]

var _total := 0
var _falhas := 0
var _saida := {}


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		printerr("  FALHA ", nome)


func _arg(nome: String) -> String:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(nome + "="):
			return a.trim_prefix(nome + "=")
	return ""


func _correr() -> void:
	print("== Fases da lua (Ordem 55) ==")
	_ancora()
	_nova_e_quartos()
	_so_a_lua_muda()
	await _relogio()
	_troca()
	_continuidade()
	_noite()
	if OS.get_cmdline_user_args().has("--gravar"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA).get_base_dir())
		var f := FileAccess.open(SAIDA, FileAccess.WRITE)
		f.store_string(JSON.stringify(_saida, "\t"))
		f.close()
		print("[fases] gravado %s" % SAIDA)
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)


static func _h(m: int) -> float:
	return float(m) / 60.0


## Igualdade EXACTA de dois valores (cores e vectores componente a componente).
static func _igual(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	return a == b


# ------------------------------------------------------------------ 1. a âncora

func _ancora() -> void:
	var dif_omissao := 0
	var dif_relogio := 0
	var relogio: Node = Ciclo.new()
	relogio.set("parado", true)
	root.add_child(relogio)
	for m in 1440:
		var a: Dictionary = Ciclo.calcular(_h(m))
		var b: Dictionary = Ciclo.calcular(_h(m), Ciclo.LUA_CHEIA)
		relogio.call("definir_hora", _h(m))
		var c: Dictionary = relogio.call("estado")
		for k: String in a:
			if not _igual(a[k], b[k]):
				dif_omissao += 1
			if not _igual(a[k], c[k]):
				dif_relogio += 1
	relogio.free()
	_ok(dif_omissao == 0, "âncora: calcular(h) = calcular(h, cheia) em 1440 minutos (%d diferenças)" % dif_omissao)
	_ok(dif_relogio == 0, "âncora: o relógio novo abre na cheia e dá o mesmo estado() (%d diferenças)" % dif_relogio)
	var ref := _arg("--referencia")
	if ref == "":
		print("  (sem --referencia: a comparação com o ciclo_dia.gd da Ordem 43 não correu)")
		_saida["ancora_ordem43"] = "não corrida (sem --referencia)"
		return
	var src := FileAccess.get_file_as_string(ref)
	var velho := GDScript.new()
	velho.source_code = src
	var erro := velho.reload()
	_ok(erro == OK and src.length() > 0, "âncora: o ciclo_dia.gd da Ordem 43 abre (%s)" % ref)
	if erro != OK:
		return
	var chaves := 0
	var difs := 0
	var exemplo := ""
	for m in 1440:
		var v: Dictionary = velho.call("calcular", _h(m))
		var n: Dictionary = Ciclo.calcular(_h(m))
		chaves = v.size()
		for k: String in v:
			if not n.has(k) or not _igual(v[k], n[k]):
				difs += 1
				if exemplo == "":
					exemplo = "%s às %s: %s → %s" % [k, Ciclo.texto_de(_h(m)), str(v[k]), str(n.get(k))]
	_ok(difs == 0, "âncora: na cheia, as %d saídas da Ordem 43 são iguais bit a bit nos 1440 minutos (%d diferenças%s)" % [chaves, difs, "" if exemplo == "" else "; 1.ª: " + exemplo])
	_saida["ancora_ordem43"] = {"referencia": ref, "saidas": chaves, "minutos": 1440, "diferencas": difs}


# ------------------------------------------------------------------ 2–3. nova e quartos

func _nova_e_quartos() -> void:
	var nova_max := 0.0
	var quarto_err := 0.0
	var minutos_com_lua := 0
	var razoes := {}
	for m in 1440:
		var cheia: float = Ciclo.calcular(_h(m), Ciclo.LUA_CHEIA)["lua_energia"]
		var nova: float = Ciclo.calcular(_h(m), Ciclo.LUA_NOVA)["lua_energia"]
		var cresc: float = Ciclo.calcular(_h(m), Ciclo.LUA_CRESCENTE)["lua_energia"]
		var ming: float = Ciclo.calcular(_h(m), Ciclo.LUA_MINGUANTE)["lua_energia"]
		nova_max = maxf(nova_max, nova)
		quarto_err = maxf(quarto_err, maxf(absf(cresc - 0.5 * cheia), absf(ming - 0.5 * cheia)))
		if cheia > 0.001:
			minutos_com_lua += 1
			var r := snappedf(cresc / cheia, 0.000001)
			razoes[r] = true
	_ok(nova_max == 0.0, "lua nova: luz da lua = 0 em todos os minutos (máx %.6f)" % nova_max)
	_ok(quarto_err < 1e-6, "quartos: luz da lua = ½ da cheia em todos os minutos (maior erro %.9f)" % quarto_err)
	_ok(razoes.size() == 1, "quartos: a razão quarto/cheia é a mesma a qualquer altura da lua (%d minutos com lua; razões: %s) — o lua_baixa compõe-se, não muda" % [minutos_com_lua, str(razoes.keys())])
	var ilum := {}
	for fz: Array in FASES:
		ilum[fz[0]] = snappedf(Ciclo.iluminada_de(fz[1]), 0.000001)
		_ok(Ciclo.fase_da_lua_de(fz[1]) == fz[0], "o nome da fase na idade %d é «%s»" % [int(fz[1]), Ciclo.fase_da_lua_de(fz[1])])
	_ok(ilum["cheia"] == 1.0 and ilum["nova"] == 0.0 and ilum["crescente"] == 0.5 and ilum["minguante"] == 0.5,
		"fracção iluminada: nova 0 · crescente ½ · cheia 1 · minguante ½ (%s)" % str(ilum))
	var por_dia: Array = []
	for i in 28:
		por_dia.append([i, Ciclo.fase_da_lua_de(float(i)), snappedf(Ciclo.iluminada_de(float(i)), 0.001)])
	_saida["fraccao_iluminada"] = ilum
	_saida["os_28_dias"] = {"colunas": ["idade", "fase", "iluminada"], "dias": por_dia}


# ------------------------------------------------------------------ 4. só a lua muda

func _so_a_lua_muda() -> void:
	var mudam := {}
	for m in range(0, 1440, 5):
		var cheia: Dictionary = Ciclo.calcular(_h(m), Ciclo.LUA_CHEIA)
		for fz: Array in FASES:
			var e: Dictionary = Ciclo.calcular(_h(m), fz[1])
			for k: String in cheia:
				if not _igual(cheia[k], e[k]):
					mudam[k] = true
	var fora := []
	for k: String in mudam:
		if not DA_LUA.has(k):
			fora.append(k)
	_ok(fora.is_empty(), "só a lua muda com a fase: mudam %s; nada mais (fora da lista: %s)" % [str(mudam.keys()), str(fora)])
	_saida["o_que_muda_com_a_fase"] = mudam.keys()


# ------------------------------------------------------------------ 5. o relógio

func _relogio() -> void:
	var r: Node = Ciclo.new()
	r.set("parado", true)
	root.add_child(r)
	await process_frame
	var sinais: Array = []
	r.connect("fase_da_lua_mudou", func(f: String) -> void: sinais.append(f))
	var idade0: float = r.call("idade_da_lua")
	var hora0: float = r.call("hora_do_mundo")
	var viradas: Array = []
	var antes: float = idade0
	var passos := 28 * 24 * 60
	for i in passos:
		r.call("avancar_horas", 1.0 / 60.0)
		var agora: float = r.call("idade_da_lua")
		if agora != antes:
			viradas.append([int(r.get("dias")), String(r.call("hora_texto")), agora])
			antes = agora
	var horas_ok := true
	for v: Array in viradas:
		if v[1] != "12:30" and v[1] != "12:31":
			horas_ok = false
	_ok(idade0 == Ciclo.LUA_CHEIA, "o mundo abre na lua cheia (idade %.1f)" % idade0)
	_ok(viradas.size() == 28, "em 28 dias do mundo a idade vira 28 vezes (%d)" % viradas.size())
	_ok(horas_ok, "a idade vira sempre à hora da troca, 12:30 (%s)" % str(viradas.slice(0, 3)))
	_ok(float(r.call("idade_da_lua")) == Ciclo.LUA_CHEIA, "ao fim de 28 dias volta a cheia (idade %.4f)" % float(r.call("idade_da_lua")))
	_ok(int(r.get("dias")) == 28 and absf(float(r.call("hora_do_mundo")) - hora0) < 0.01, "o relógio andou 28 dias (dias = %d, hora %s)" % [int(r.get("dias")), String(r.call("hora_texto"))])
	_ok(sinais == ["minguante", "nova", "crescente", "cheia"], "fase_da_lua_mudou sai 4 vezes por ordem: %s" % str(sinais))
	# definir_hora não mexe na lua (como não mexe nos dias); definir_idade_da_lua dá a volta aos 28
	r.call("definir_hora", 3.0)
	_ok(float(r.call("idade_da_lua")) == Ciclo.LUA_CHEIA, "definir_hora não mexe na idade da lua")
	r.call("definir_idade_da_lua", 30.0)
	_ok(float(r.call("idade_da_lua")) == 2.0 and String(r.call("fase_da_lua")) == "nova", "definir_idade_da_lua(30) → idade 2, «nova»")
	r.queue_free()
	_saida["relogio_28_dias"] = {"viradas": viradas, "sinais": sinais}


# ------------------------------------------------------------------ 6. a troca

func _troca() -> void:
	var h := Ciclo.LUA_TROCA_HORA
	var l: Vector2 = Ciclo.lua(h)
	var visiveis := ["lua_energia", "cor_luz", "sombra_forca", "ressalto"]
	var pior := 0.0
	for i in 28:
		var a: Dictionary = Ciclo.calcular(h - 0.5 / 60.0, float(i))
		var b: Dictionary = Ciclo.calcular(h - 0.5 / 60.0, float((i + 1) % 28))
		var c: Dictionary = Ciclo.calcular(h + 0.5 / 60.0, float((i + 1) % 28))
		var d: Dictionary = Ciclo.calcular(h + 0.5 / 60.0, float(i))
		for k: String in visiveis:
			if not _igual(a[k], b[k]) or not _igual(c[k], d[k]):
				pior = 1.0
		pior = maxf(pior, float(a["lua_energia"]) + float(c["lua_energia"]))
	_ok(l.y < -40.0, "na troca (12:30) a lua está debaixo do chão (elevação %.1f°)" % l.y)
	_ok(pior == 0.0, "na troca a luz da lua é 0 em todas as idades e mudar de idade não mexe em nada do que se vê")
	_saida["troca"] = {"hora": Ciclo.texto_de(h), "lua_elevacao": snappedf(l.y, 0.1), "sol_elevacao": snappedf(Ciclo.sol(h).y, 0.1)}


# ------------------------------------------------------------------ 7. continuidade por fase

func _continuidade() -> void:
	var tab := {}
	for fz: Array in FASES:
		var antes: Dictionary = Ciclo.calcular(0.0, fz[1])
		var maior := {}
		for m in range(1, 1441):
			var e: Dictionary = Ciclo.calcular(_h(m), fz[1])
			for k: String in ["lua_energia", "cor_luz", "sombra_forca", "ressalto"]:
				var d := 0.0
				if e[k] is Color:
					var ca: Color = antes[k]
					var cb: Color = e[k]
					d = maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), absf(ca.b - cb.b))
				else:
					d = absf(float(e[k]) - float(antes[k]))
				maior[k] = maxf(float(maior.get(k, 0.0)), d)
			antes = e
		tab[fz[0]] = maior
	var ok := true
	for f: String in tab:
		for k: String in tab[f]:
			if float(tab[f][k]) > float(tab["cheia"][k]) + 1e-9:
				print("    [%s] %s: %.9f > cheia %.9f" % [f, k, float(tab[f][k]), float(tab["cheia"][k])])
				ok = false
	# (arredonda-se só DEPOIS de comparar tudo: a coluna da cheia é a régua das outras)
	for f: String in tab:
		for k: String in tab[f]:
			tab[f][k] = snappedf(float(tab[f][k]), 0.0001)
	_ok(ok, "continuidade: em nenhuma fase o maior passo por minuto do mundo passa o da cheia (%s)" % JSON.stringify(tab))
	_saida["continuidade_maior_passo_por_minuto"] = tab


# ------------------------------------------------------------------ a noite em números (para as notas)

func _noite() -> void:
	var linhas := {}
	for hh: float in [19.75, 22.0, 1.0, 4.0]:
		var por_fase := {}
		for fz: Array in FASES:
			var e: Dictionary = Ciclo.calcular(hh, fz[1])
			var cl: Color = e["cor_luz"]
			var lin := cl.srgb_to_linear()
			por_fase[fz[0]] = {"lua_energia": snappedf(float(e["lua_energia"]), 0.0001),
				"cor_luz": cl.to_html(false), "luz_chave_luminancia_linear": snappedf(0.2126 * lin.r + 0.7152 * lin.g + 0.0722 * lin.b, 0.0001),
				"sombra_forca": snappedf(float(e["sombra_forca"]), 0.0001), "ressalto": snappedf(float(e["ressalto"]), 0.0001)}
		linhas[Ciclo.texto_de(hh)] = por_fase
	_saida["a_noite_por_fase"] = linhas
	print("[fases] a noite por fase: %s" % JSON.stringify(linhas))
