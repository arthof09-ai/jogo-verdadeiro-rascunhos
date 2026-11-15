extends SceneTree
## provar_estacoes.gd — Ordem 56. A PROVA EM NÚMEROS do ano e das estações (sem render: --headless).
##
##   godot --headless --path cliente -s res://mapa/floresta/ferramentas/provar_estacoes.gd
##   (opções depois de «--»:
##      --referencia=CAMINHO    o ciclo_dia.gd da Ordem 43 (`git show d7b9e6c:…/ciclo_dia.gd`, fora do
##                              repositório): as 40 saídas dele têm de sair IGUAIS, bit a bit, no dia de
##                              referência com lua cheia, nos 1440 minutos
##      --referencia55=CAMINHO  o ciclo_dia.gd da Ordem 55 (`git show 0435aa7:…`): as 45 saídas dele,
##                              nas 4 fases da lua, iguais bit a bit no dia de referência
##      --gravar                grava capturas/ciclo56/estacoes.json)
##
## Sai com 0 se todas as verificações passarem, 1 se alguma falhar. Verifica:
##   1. ÂNCORA: calcular(h) = calcular(h, cheia) = calcular(h, cheia, dia 21) = o relógio novo; e,
##      com as referências, = a Ordem 43 e = a Ordem 55, bit a bit;
##   2. AS ESTAÇÕES: os nomes; a duração do dia no meio das 4 (verão a maior do ano, inverno a menor);
##   3. SÓ O SOL MUDA: de um dia do ano para outro mudam só as saídas que saem do sol; a lua (sítio,
##      fase, disco) e a névoa ficam iguais;
##   4. AS FASES DA LUA INTACTAS em todas as estações (nova 0; quartos ½ da cheia em todos os minutos);
##   5. O RELÓGIO UM ANO INTEIRO, minuto a minuto: a estação vira 4 vezes, por ordem, e o relógio volta
##      ao ponto de partida (dia 21, lua cheia); na viragem do nome nenhum passo é maior do que no
##      mesmo minuto do dia antes e do dia depois; o ano a andar não junta passo nenhum ao do dia;
##   6. CONTINUIDADE: o maior passo por minuto de cada saída, em cada um dos 112 dias, contra o do dia
##      de referência (o critério da ordem, à letra — e onde não se cumpre, diz-se quanto e porquê).

const Ciclo := preload("res://mapa/floresta/ciclo_dia.gd")
const SAIDA := "res://mapa/floresta/capturas/ciclo56/estacoes.json"
## Os meios das estações (o ponto do ano que lhes dá o nome) e o dia 21 de cada uma (o das capturas).
const MEIOS := [["primavera", 14.0], ["verão", 42.0], ["outono", 70.0], ["inverno", 98.0]]
const DIAS_21 := [["primavera", 21.0], ["verão", 49.0], ["outono", 77.0], ["inverno", 105.0]]
## As saídas que NÃO podem mudar com o dia do ano (a lua, a névoa, o relógio).
const FIXAS := ["hora", "manha", "lua_azimute", "lua_elevacao", "dir_lua", "lua_idade", "lua_fase",
	"lua_iluminada", "lua_terminador", "lua_lado", "nevoa_inicio", "nevoa_fim", "nevoa_tecto"]

## As saídas que SÃO o ano (o relógio do ano, como a «hora» é o do dia): não se medem como passos
## de luz — o ano_dia dá a volta aos 112, e a declinação e a duração do dia andam com o relógio.
const DO_ANO := ["ano_dia", "sol_declinacao", "dia_duracao"]
## A folga da AMOSTRAGEM nas comparações com a referência (relativa, 0,01 %): o passo é medido de
## minuto a minuto, e o mesmo ritmo máximo dá passos um nada diferentes conforme cai a amostra. A
## elevação do sol, por exemplo, tem o MESMO ritmo máximo em todos os dias do ano (15° · cos 38° por
## hora — a geometria, para qualquer |δ| < 52°) e as amostras diferem até ~3e-5.
const RUIDO := 1e-4
## As saídas da IDADE da lua: mudam de propósito às 12:30 (Ordem 55, a troca que não se vê).
const DA_IDADE_LUA := ["lua_idade", "lua_iluminada", "lua_terminador", "lua_lado"]

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
	print("== O ano e as estações (Ordem 56) ==")
	_ancora()
	_estacoes()
	_so_o_sol_muda()
	_fases_intactas()
	await _ano_inteiro()
	_continuidade()
	_cor_do_sol()
	if OS.get_cmdline_user_args().has("--gravar"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAIDA).get_base_dir())
		var f := FileAccess.open(SAIDA, FileAccess.WRITE)
		f.store_string(JSON.stringify(_saida, "\t"))
		f.close()
		print("[estacoes] gravado %s" % SAIDA)
	print("")
	print("%d de %d verificações passaram." % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)


static func _h(m: int) -> float:
	return float(m) / 60.0


static func _igual(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	return a == b


## O passo entre dois valores de uma saída (a régua da Ordem 43, provar_ciclo_vento.gd): cores, o
## maior canal; direcções, a distância dos vectores; números, a diferença. -1 = não se mede.
static func _passo(k: String, a: Variant, b: Variant) -> float:
	if a is Color:
		var ca: Color = a
		var cb: Color = b
		return maxf(maxf(absf(ca.r - cb.r), absf(ca.g - cb.g)), absf(ca.b - cb.b))
	if a is Vector3:
		return (a as Vector3).distance_to(b as Vector3)
	if a is float and k != "hora" and not k.ends_with("azimute") and not DO_ANO.has(k):
		return absf(float(a) - float(b))
	return -1.0


## O maior passo por minuto de cada saída, num dia do ano CONGELADO (a lua cheia).
static func _maiores(d: float) -> Dictionary:
	var maior := {}
	var antes: Dictionary = Ciclo.calcular(0.0, Ciclo.LUA_CHEIA, d)
	for m in range(1, 1441):
		var e: Dictionary = Ciclo.calcular(_h(m), Ciclo.LUA_CHEIA, d)
		for k: String in e:
			var p := _passo(k, antes[k], e[k])
			if p >= 0.0:
				maior[k] = maxf(float(maior.get(k, 0.0)), p)
		antes = e
	return maior


func _abrir(caminho: String) -> GDScript:
	var src := FileAccess.get_file_as_string(caminho)
	var g := GDScript.new()
	g.source_code = src
	var erro := g.reload()
	_ok(erro == OK and src.length() > 0, "âncora: abre %s" % caminho)
	return g if erro == OK else null


# ------------------------------------------------------------------ 1. a âncora

func _ancora() -> void:
	_ok(Ciclo.declinacao_de(Ciclo.DIA_ANO_REFERENCIA) == Ciclo.SOL_DECLINACAO,
		"âncora: no dia de referência (%d, %s) a declinação é EXACTAMENTE %.1f° (%.17f)" % [int(Ciclo.DIA_ANO_REFERENCIA),
		Ciclo.estacao_de(Ciclo.DIA_ANO_REFERENCIA), Ciclo.SOL_DECLINACAO, Ciclo.declinacao_de(Ciclo.DIA_ANO_REFERENCIA)])
	var dif := 0
	var dif_relogio := 0
	var relogio: Node = Ciclo.new()
	relogio.set("parado", true)
	root.add_child(relogio)
	_ok(float(relogio.call("dia_do_ano")) == Ciclo.DIA_ANO_REFERENCIA and String(relogio.call("estacao")) == "primavera",
		"o mundo abre no dia de referência: dia %.1f, %s" % [float(relogio.call("dia_do_ano")), String(relogio.call("estacao"))])
	for m in 1440:
		var a: Dictionary = Ciclo.calcular(_h(m))
		var b: Dictionary = Ciclo.calcular(_h(m), Ciclo.LUA_CHEIA, Ciclo.DIA_ANO_REFERENCIA)
		relogio.call("definir_hora", _h(m))
		var c: Dictionary = relogio.call("estado")
		for k: String in a:
			if not _igual(a[k], b[k]):
				dif += 1
			if not _igual(a[k], c[k]):
				dif_relogio += 1
	_ok(dif == 0, "âncora: calcular(h) = calcular(h, cheia, dia 21) em 1440 minutos (%d diferenças)" % dif)
	_ok(dif_relogio == 0 and float(relogio.call("dia_do_ano")) == Ciclo.DIA_ANO_REFERENCIA,
		"âncora: o relógio novo dá o mesmo estado() e definir_hora não mexe no ano (%d diferenças; dia %.1f)" % [dif_relogio, float(relogio.call("dia_do_ano"))])
	relogio.free()
	_saida["ancora"] = {"dia_de_referencia": Ciclo.DIA_ANO_REFERENCIA, "estacao": Ciclo.estacao_de(Ciclo.DIA_ANO_REFERENCIA),
		"declinacao": Ciclo.declinacao_de(Ciclo.DIA_ANO_REFERENCIA), "amplitude": Ciclo.SOL_DECL_AMPLITUDE}
	# ---- contra a Ordem 43 (as 40 saídas, na cheia)
	var ref := _arg("--referencia")
	if ref == "":
		print("  (sem --referencia: a comparação com o ciclo_dia.gd da Ordem 43 não correu)")
		_saida["ancora_ordem43"] = "não corrida (sem --referencia)"
	else:
		var velho := _abrir(ref)
		if velho != null:
			var r := _comparar(velho, [Ciclo.LUA_CHEIA], false)
			_ok(r["difs"] == 0, "âncora: no dia de referência com lua cheia, as %d saídas da Ordem 43 são iguais bit a bit nos 1440 minutos (%d diferenças%s)" % [r["chaves"], r["difs"], r["exemplo"]])
			_saida["ancora_ordem43"] = {"referencia": ref, "saidas": r["chaves"], "minutos": 1440, "diferencas": r["difs"]}
	# ---- contra a Ordem 55 (as 45 saídas, nas 4 fases)
	var ref55 := _arg("--referencia55")
	if ref55 == "":
		print("  (sem --referencia55: a comparação com o ciclo_dia.gd da Ordem 55 não correu)")
		_saida["ancora_ordem55"] = "não corrida (sem --referencia55)"
	else:
		var v55 := _abrir(ref55)
		if v55 != null:
			var r := _comparar(v55, [Ciclo.LUA_CHEIA], true)
			_ok(r["difs"] == 0, "âncora: no dia de referência com lua cheia, as %d saídas da Ordem 55 são iguais bit a bit nos 1440 minutos (%d diferenças%s)" % [r["chaves"], r["difs"], r["exemplo"]])
			var r4 := _comparar(v55, [Ciclo.LUA_NOVA, Ciclo.LUA_CRESCENTE, Ciclo.LUA_MINGUANTE, 3.5, 10.0, 25.0], true)
			_ok(r4["difs"] == 0, "âncora: e nas outras idades da lua (0, 7, 21, 3,5, 10, 25) também — as fases da Ordem 55 intactas (%d diferenças%s)" % [r4["difs"], r4["exemplo"]])
			_saida["ancora_ordem55"] = {"referencia": ref55, "saidas": r["chaves"], "minutos": 1440, "diferencas_na_cheia": r["difs"], "diferencas_outras_idades": r4["difs"]}


func _comparar(velho: GDScript, idades: Array, com_idade: bool) -> Dictionary:
	var chaves := 0
	var difs := 0
	var exemplo := ""
	for idade: float in idades:
		for m in 1440:
			var v: Dictionary = velho.call("calcular", _h(m), idade) if com_idade else velho.call("calcular", _h(m))
			var n: Dictionary = Ciclo.calcular(_h(m), idade) if com_idade else Ciclo.calcular(_h(m))
			chaves = v.size()
			for k: String in v:
				if not n.has(k) or not _igual(v[k], n[k]):
					difs += 1
					if exemplo == "":
						exemplo = "; 1.ª: %s às %s (idade %.1f): %s → %s" % [k, Ciclo.texto_de(_h(m)), idade, str(v[k]), str(n.get(k))]
	return {"chaves": chaves, "difs": difs, "exemplo": exemplo}


# ------------------------------------------------------------------ 2. as estações e a duração do dia

static func _minutos_de_sol(d: float) -> int:
	var n := 0
	for m in 1440:
		if Ciclo.sol(_h(m) + 0.5 / 60.0, d).y > 0.0:
			n += 1
	return n


func _estacoes() -> void:
	var nomes_ok := true
	for i in 112:
		var esperado: String = Ciclo.ESTACOES[i / 28]
		if Ciclo.estacao_de(float(i)) != esperado or Ciclo.estacao_de(float(i) + 0.999) != esperado:
			nomes_ok = false
	_ok(nomes_ok and Ciclo.estacao_de(112.0) == "primavera" and Ciclo.estacao_de(-0.5) == "inverno",
		"os nomes: primavera 0–28 · verão 28–56 · outono 56–84 · inverno 84–112 (e dá a volta)")
	var tab := {}
	for x: Array in MEIOS + DIAS_21:
		var d: float = x[1]
		var np := Ciclo.nascer_e_por_de(d)
		var e_meio := Ciclo.sol(Ciclo.SOL_CULMINA, d).y
		tab["%s (dia %d)" % [x[0], int(d)]] = {"estacao": Ciclo.estacao_de(d), "declinacao": snappedf(Ciclo.declinacao_de(d), 0.001),
			"duracao_do_dia_h": snappedf(Ciclo.duracao_do_dia_de(d), 0.001), "minutos_de_sol_contados": _minutos_de_sol(d),
			"nasce": Ciclo.texto_de(np.x), "poe_se": Ciclo.texto_de(np.y), "sol_ao_meio_dia_elev": snappedf(e_meio, 0.1),
			"sol_as_18h_elev": snappedf(Ciclo.sol(18.0, d).y, 0.1),
			"nasce_azimute": snappedf(fposmod(Ciclo.sol(np.x, d).x, 360.0), 0.1), "poe_se_azimute": snappedf(fposmod(Ciclo.sol(np.y, d).x, 360.0), 0.1)}
	_saida["estacoes"] = tab
	print("[estacoes] %s" % JSON.stringify(tab))
	var dur := {}
	for x: Array in MEIOS:
		dur[x[0]] = Ciclo.duracao_do_dia_de(x[1])
		_ok(Ciclo.estacao_de(x[1]) == x[0], "o meio do/da %s (dia %d) é %s" % [x[0], int(x[1]), Ciclo.estacao_de(x[1])])
	var mn := 1e9
	var mx := -1e9
	var d_mn := -1
	var d_mx := -1
	var maior_variacao := 0.0
	for i in 1121:
		var dd := float(i) / 10.0
		var v := Ciclo.duracao_do_dia_de(dd)
		if v < mn:
			mn = v
			d_mn = i
		if v > mx:
			mx = v
			d_mx = i
		maior_variacao = maxf(maior_variacao, absf(Ciclo.duracao_do_dia_de(dd + 1.0) - v))
	_ok(dur["verão"] > dur["primavera"] and dur["verão"] > dur["outono"] and dur["primavera"] > dur["inverno"] and dur["outono"] > dur["inverno"],
		"duração do dia no meio das estações: verão %.3f h > primavera %.3f h = outono %.3f h > inverno %.3f h" % [dur["verão"], dur["primavera"], dur["outono"], dur["inverno"]])
	_ok(absf(float(d_mx) / 10.0 - 42.0) < 0.05 and absf(float(d_mn) / 10.0 - 98.0) < 0.05,
		"o dia mais longo do ano é o meio do verão (dia %.1f, %.3f h) e o mais curto o meio do inverno (dia %.1f, %.3f h)" % [float(d_mx) / 10.0, mx, float(d_mn) / 10.0, mn])
	_ok(absf(Ciclo.duracao_do_dia_de(Ciclo.DIA_ANO_REFERENCIA) - 13.0) < 0.01,
		"no dia de referência o dia é o da Ordem 43: nasce %s, põe-se %s (%.3f h)" % [Ciclo.texto_de(Ciclo.nascer_e_por_de(21.0).x), Ciclo.texto_de(Ciclo.nascer_e_por_de(21.0).y), Ciclo.duracao_do_dia_de(21.0)])
	_saida["duracao_do_dia"] = {"meios": dur, "mais_longo": [float(d_mx) / 10.0, mx], "mais_curto": [float(d_mn) / 10.0, mn],
		"maior_variacao_de_um_dia_para_o_seguinte_h": snappedf(maior_variacao, 0.0001)}
	print("[estacoes] a duração do dia muda no máximo %.1f min de um dia do mundo para o seguinte" % (maior_variacao * 60.0))


# ------------------------------------------------------------------ 3. só o sol muda

func _so_o_sol_muda() -> void:
	var mudam := {}
	for m in range(0, 1440, 5):
		var ref: Dictionary = Ciclo.calcular(_h(m))
		for i in range(0, 112, 7):
			var e: Dictionary = Ciclo.calcular(_h(m), Ciclo.LUA_CHEIA, float(i))
			for k: String in ref:
				if not _igual(ref[k], e[k]):
					mudam[k] = true
	var fora := []
	for k: String in FIXAS:
		if mudam.has(k):
			fora.append(k)
	_ok(fora.is_empty(), "a lua (sítio, fase, disco), a névoa e o relógio não mudam com o dia do ano (mudaram: %s)" % str(fora))
	_saida["o_que_muda_com_o_ano"] = mudam.keys()
	print("[estacoes] mudam com o ano: %s" % str(mudam.keys()))


# ------------------------------------------------------------------ 4. as fases da lua em todas as estações

func _fases_intactas() -> void:
	var nova_max := 0.0
	var quarto_err := 0.0
	for x: Array in MEIOS + DIAS_21:
		for m in 1440:
			var cheia: float = Ciclo.calcular(_h(m), Ciclo.LUA_CHEIA, x[1])["lua_energia"]
			nova_max = maxf(nova_max, float(Ciclo.calcular(_h(m), Ciclo.LUA_NOVA, x[1])["lua_energia"]))
			var c: float = Ciclo.calcular(_h(m), Ciclo.LUA_CRESCENTE, x[1])["lua_energia"]
			var g: float = Ciclo.calcular(_h(m), Ciclo.LUA_MINGUANTE, x[1])["lua_energia"]
			quarto_err = maxf(quarto_err, maxf(absf(c - 0.5 * cheia), absf(g - 0.5 * cheia)))
	_ok(nova_max == 0.0 and quarto_err < 1e-6,
		"as fases da lua em todas as estações: nova sem luz (máx %.6f), quartos = ½ da cheia (maior erro %.9f)" % [nova_max, quarto_err])


# ------------------------------------------------------------------ 5. o relógio um ano inteiro

func _ano_inteiro() -> void:
	var r: Node = Ciclo.new()
	r.set("parado", true)
	root.add_child(r)
	await process_frame
	var sinais: Array = []
	var viradas: Array = []
	r.connect("estacao_mudou", func(e: String) -> void:
		sinais.append(e)
		viradas.append([int(r.get("dias")), String(r.call("hora_texto")), snappedf(float(r.call("dia_do_ano")), 0.0001), e]))
	var hora0: float = r.call("hora_do_mundo")
	var passos := 112 * 1440
	var antes: Dictionary = (r.call("estado") as Dictionary).duplicate()
	var anel: Array = []           # os passos dos últimos 1440 minutos (para o «dia antes»)
	anel.resize(1440)
	var pendentes: Array = []      # [minuto_do_dia_depois, passos_na_virada, passos_dia_antes]
	var n_sinais := 0
	var pior_virada := 0.0
	var detalhe_virada := []
	for i in passos:
		r.call("avancar_horas", 1.0 / 60.0)
		var e: Dictionary = r.call("estado")
		var p := {}
		for k: String in e:
			var v := _passo(k, antes[k], e[k])
			if v >= 0.0:
				p[k] = v
		antes = e.duplicate()
		if sinais.size() != n_sinais:
			n_sinais = sinais.size()
			pendentes.append([i + 1440, p, anel[i % 1440]])
		for q: Array in pendentes:
			if q[0] == i:
				# o passo no minuto da virada contra o mesmo minuto do dia antes e do dia depois
				var na: Dictionary = q[1]
				var ant: Dictionary = q[2] if q[2] != null else na
				var pior_k := 0.0
				for k: String in na:
					var teto := maxf(float(ant.get(k, 0.0)), float(p.get(k, 0.0)))
					var excesso := float(na[k]) - teto
					pior_k = maxf(pior_k, excesso)
				pior_virada = maxf(pior_virada, pior_k)
				detalhe_virada.append(snappedf(pior_k, 0.0000001))
		anel[i % 1440] = p
	var dia_fim: float = r.call("dia_do_ano")
	_ok(sinais == ["verão", "outono", "inverno", "primavera"], "um ano a andar minuto a minuto: estacao_mudou sai 4 vezes, por ordem (%s)" % str(sinais))
	_ok(viradas.size() == 4 and absf(float(viradas[0][2]) - 28.0) < 0.001 and absf(float(viradas[1][2]) - 56.0) < 0.001 and absf(float(viradas[2][2]) - 84.0) < 0.001 and float(viradas[3][2]) < 0.001,
		"as viradas são nos dias 28, 56, 84 e 112 (= 0): %s" % str(viradas))
	_ok(int(r.get("dias")) == 112 and absf(float(r.call("hora_do_mundo")) - hora0) < 0.01 and absf(dia_fim - Ciclo.DIA_ANO_REFERENCIA) < 1e-6
		and String(r.call("estacao")) == "primavera" and float(r.call("idade_da_lua")) == Ciclo.LUA_CHEIA,
		"ao fim do ano volta ao ponto de partida: dias %d, %s, dia do ano %.9f (resto %.12f), %s, lua %s (idade %.1f)" % [int(r.get("dias")),
		String(r.call("hora_texto")), dia_fim, dia_fim - Ciclo.DIA_ANO_REFERENCIA, String(r.call("estacao")), String(r.call("fase_da_lua")), float(r.call("idade_da_lua"))])
	_ok(detalhe_virada.size() == 4 and pior_virada <= 1e-6,
		"na viragem do nome nenhum passo é maior do que no mesmo minuto do dia antes ou do dia depois (excesso máx %.12f; por virada: %s)" % [pior_virada, str(detalhe_virada)])
	# a API: definir_hora não mexe no ano; definir_dia_do_ano dá a volta e não mexe na hora nem na lua
	r.call("definir_hora", 3.0)
	var ok_hora: bool = absf(float(r.call("dia_do_ano")) - dia_fim) == 0.0
	r.call("definir_dia_do_ano", 130.0)
	_ok(ok_hora and float(r.call("dia_do_ano")) == 18.0 and String(r.call("estacao")) == "primavera" and float(r.call("hora_do_mundo")) == 3.0
		and float(r.call("idade_da_lua")) == Ciclo.LUA_CHEIA and sinais.size() == 4,
		"definir_hora não mexe no ano; definir_dia_do_ano(130) → dia 18, primavera, sem sinal, a hora e a lua iguais")
	r.call("definir_dia_do_ano", 30.0)
	_ok(sinais.size() == 5 and sinais[4] == "verão" and is_equal_approx(float(r.call("duracao_do_dia")), Ciclo.duracao_do_dia_de(30.0)),
		"definir_dia_do_ano(30) → «verão», com sinal; duracao_do_dia() = %.3f h" % float(r.call("duracao_do_dia")))
	r.queue_free()
	_saida["relogio_um_ano"] = {"viradas": viradas.slice(0, 4), "sinais": sinais.slice(0, 4), "dia_do_ano_no_fim": dia_fim,
		"excesso_na_virada_por_virada": detalhe_virada}


# ------------------------------------------------------------------ 6. continuidade

func _continuidade() -> void:
	var ref := _maiores(Ciclo.DIA_ANO_REFERENCIA)
	var maior_ano := {}
	var acima := {}             # dia -> {saída: razão}
	var pior := {}              # saída -> [razão, dia]
	var por_estacao := {}
	for i in 112:
		var d := float(i)
		var m := _maiores(d)
		var est := Ciclo.estacao_de(d)
		for k: String in m:
			maior_ano[k] = maxf(float(maior_ano.get(k, 0.0)), float(m[k]))
			var r := float(m[k]) / maxf(float(ref.get(k, 0.0)), 1e-12)
			if float(m[k]) > float(ref.get(k, 0.0)) * (1.0 + RUIDO) + 1e-12:
				if not acima.has(i):
					acima[i] = {}
				acima[i][k] = snappedf(r, 0.0001)
				if r > float(pior.get(k, [0.0])[0]):
					pior[k] = [snappedf(r, 0.0001), i]
				var pe: Dictionary = por_estacao.get(est, {})
				pe[k] = maxf(float(pe.get(k, 1.0)), r)
				por_estacao[est] = pe
	var dias_acima: Array = acima.keys()
	dias_acima.sort()
	var pior_razao := 1.0
	var pior_quem := ""
	for k: String in pior:
		if float(pior[k][0]) > pior_razao:
			pior_razao = float(pior[k][0])
			pior_quem = "%s no dia %d (%s)" % [k, int(pior[k][1]), Ciclo.estacao_de(float(pior[k][1]))]
	# O ANO A ANDAR: um ano inteiro, minuto a minuto, com o dia do ano a correr (h = m/60, dia =
	# 21 + m/1440: a grelha exacta). Em cada minuto, o passo divide-se em dois: o do DIA (a hora anda,
	# o dia do ano parado) e o do ANO (o mesmo minuto, o dia do ano de antes → o de agora). O do ano
	# é a única coisa que o ano a correr junta: mede-se contra o maior passo do dia de referência.
	# (Mede-se na grelha exacta e não com o relógio de 5., cuja hora acumula a soma dos minutos: a
	# meia-noite tem um degrau que é da Ordem 43 — o peso «manha» salta de 0 a 0,156 às 00:00, nas
	# tintas do sol, que de noite não se vêem — e uma amostra desfasada lê-o de outro tamanho.)
	var corrido := {}
	var do_ano := {}
	var antes: Dictionary = Ciclo.calcular(0.0, Ciclo.LUA_CHEIA, Ciclo.DIA_ANO_REFERENCIA)
	for m in range(1, 112 * 1440 + 1):
		var d_agora := Ciclo.DIA_ANO_REFERENCIA + float(m) / 1440.0
		var e: Dictionary = Ciclo.calcular(fposmod(_h(m), 24.0), Ciclo.LUA_CHEIA, d_agora)
		var so_ano: Dictionary = Ciclo.calcular(fposmod(_h(m - 1), 24.0), Ciclo.LUA_CHEIA, d_agora)
		for k: String in e:
			var p := _passo(k, antes[k], e[k])
			if p >= 0.0:
				corrido[k] = maxf(float(corrido.get(k, 0.0)), p)
				do_ano[k] = maxf(float(do_ano.get(k, 0.0)), _passo(k, antes[k], so_ano[k]))
		antes = e
	var junta := 0.0
	var junta_quem := ""
	for k: String in do_ano:
		var r := float(do_ano[k]) / maxf(float(ref.get(k, 0.0)), 1e-12)
		if float(ref.get(k, 0.0)) > 0.0 and r > junta:
			junta = r
			junta_quem = k
	_ok(junta < 0.01, "o ano a andar não junta passo que se veja: num minuto, a parte do passo que é do ANO fica a %.2f %% do maior passo do dia de referência, no máximo (%s)" % [junta * 100.0, junta_quem])
	var pior_corrido := 1.0
	var pior_corrido_quem := ""
	for k: String in corrido:
		var r := float(corrido[k]) / maxf(float(ref.get(k, 0.0)), 1e-12)
		if float(ref.get(k, 0.0)) > 0.0 and r > pior_corrido:
			pior_corrido = r
			pior_corrido_quem = k
	print("    [o ano a andar] o maior passo do ano inteiro a correr fica a %.4f× o do dia de referência (%s) — o mesmo que nos dias congelados, mais a amostragem entre dias inteiros" % [pior_corrido, pior_corrido_quem])
	_ok(not por_estacao.has("verão"), "no verão (dias 28–56) nenhum passo por minuto passa o do dia de referência")
	for est: String in ["primavera", "outono", "inverno"]:
		if por_estacao.has(est):
			var pe: Dictionary = por_estacao[est]
			var chaves := pe.keys()
			chaves.sort_custom(func(a: String, b: String) -> bool: return float(pe[a]) > float(pe[b]))
			var top := []
			for k: String in chaves.slice(0, 4):
				top.append("%s +%.1f %%" % [k, (float(pe[k]) - 1.0) * 100.0])
			print("    [%s] passa a referência em %d saídas; as maiores: %s" % [est, chaves.size(), ", ".join(top)])
	# o critério da ordem, à letra. A geometria não o deixa cumprir: com a latitude fixa, o sol corta
	# o horizonte mais depressa perto dos equinócios (15° · cos 38° · cos δ · sen H₀ por hora, que é
	# máximo em δ = 0) do que no dia de referência (δ = 9,5°); e o crepúsculo fundo (−18°) é mais
	# rápido com δ ≈ −11° (inverno). Não se esconde: a verificação fica, e falha enquanto for assim.
	_ok(dias_acima.is_empty() and pior_corrido <= 1.0 + RUIDO,
		"(o critério da ordem, à letra) em nenhum dia do ano o maior passo por minuto passa o do dia de referência (passa em %d dos 112 dias: %s; o pior num dia inteiro: +%.1f %%, %s; com o ano a correr, entre dias: +%.1f %%, %s)" % [dias_acima.size(),
		_intervalos(dias_acima), (pior_razao - 1.0) * 100.0, pior_quem, (pior_corrido - 1.0) * 100.0, pior_corrido_quem])
	for k: String in ref:
		ref[k] = snappedf(float(ref[k]), 0.00001)
	for k: String in maior_ano:
		maior_ano[k] = snappedf(float(maior_ano[k]), 0.00001)
	for e: String in por_estacao:
		for k: String in por_estacao[e]:
			por_estacao[e][k] = snappedf(float(por_estacao[e][k]), 0.0001)
	_saida["continuidade"] = {"nota": "maior passo por minuto do mundo de cada saída (a régua da Ordem 43: cores 0–1 pelo maior canal; direcções, distância de vectores unitários; números, a diferença), com o dia do ano congelado e a lua cheia.",
		"dia_de_referencia": ref, "o_maior_do_ano": maior_ano, "dias_acima_da_referencia": _intervalos(dias_acima),
		"pior_razao_por_saida": pior, "pior_razao_por_estacao": por_estacao,
		"o_ano_a_andar": {"a_parte_do_ano_no_maior_minuto_em_fraccao_da_referencia": snappedf(junta, 0.00001), "em": junta_quem,
			"maior_passo_do_ano_a_correr_em_fraccao_da_referencia": snappedf(pior_corrido, 0.0001), "em_quem": pior_corrido_quem}}


static func _intervalos(dias: Array) -> String:
	if dias.is_empty():
		return "nenhum"
	var partes := []
	var a: int = dias[0]
	var b: int = dias[0]
	for i in range(1, dias.size()):
		if int(dias[i]) == b + 1:
			b = dias[i]
		else:
			partes.append(str(a) if a == b else "%d–%d" % [a, b])
			a = dias[i]
			b = dias[i]
	partes.append(str(a) if a == b else "%d–%d" % [a, b])
	return ", ".join(partes)


# ------------------------------------------------------------------ a cor do sol (para as notas)

func _cor_do_sol() -> void:
	var t := {}
	for x: Array in MEIOS + DIAS_21:
		var linha := {}
		for hh: float in [Ciclo.SOL_CULMINA, 16.25, 18.0]:
			var e: Dictionary = Ciclo.calcular(hh, Ciclo.LUA_CHEIA, x[1])
			linha[Ciclo.texto_de(hh)] = {"sol_elev": snappedf(float(e["sol_elevacao"]), 0.1), "cor_luz_sol": (e["cor_luz_sol"] as Color).to_html(false),
				"cor_luz": (e["cor_luz"] as Color).to_html(false), "sol_energia": snappedf(float(e["sol_energia"]), 0.001),
				"fase": Ciclo.fase_de(hh, x[1]), "lume": snappedf(float(e["lume"]), 0.001)}
		t["%s (dia %d)" % [x[0], int(x[1])]] = linha
	_saida["o_sol_por_estacao"] = t
	print("[estacoes] o sol por estação: %s" % JSON.stringify(t))
