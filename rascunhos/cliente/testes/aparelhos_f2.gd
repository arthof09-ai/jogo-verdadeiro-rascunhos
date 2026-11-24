extends SceneTree
## Ordem PLANO-2-F2 — testes sem tela do que a F2 pôs no cliente (os três aparelhos).
##
##   godot --headless --path rascunhos/cliente -s res://testes/aparelhos_f2.gd
##
## - JV2.1b: a guarda do Android (ws:// só para a rede local; wss:// sempre);
## - JV2.1b: a entrada pela linha de comando (as provas do ROOM_SNAPSHOT no Windows e no Android);
## - JV3.4b: o tecto da espera da reconexão (≤ 30 s depois de a rede voltar, com a variação de ±20 %);
## - V1.0: o percentil e os campos do JSON da medição.
## Sai com 0 se tudo passa e 1 se algo falha.

const RedeScript := preload("res://rede/rede.gd")
const MedicaoScript := preload("res://medicao/medicao.gd")

var _total := 0
var _falhas := 0


func _initialize() -> void:
	print("== Testes dos aparelhos (Ordem PLANO-2-F2) ==")
	_teste_rede_local()
	_teste_entrada_por_argumentos()
	_teste_espera_da_reconexao()
	_teste_medicao()
	print("== %d de %d ==" % [_total - _falhas, _total])
	quit(1 if _falhas > 0 else 0)


func _ok(cond: bool, nome: String) -> void:
	_total += 1
	if cond:
		print("  ok    ", nome)
	else:
		_falhas += 1
		printerr("  FALHA ", nome)


func _teste_rede_local() -> void:
	var sim := ["ws://192.168.1.20:8080/ws", "ws://10.0.2.2:8080/ws", "ws://172.16.0.5/ws", "ws://172.31.255.1:80/ws",
		"ws://127.0.0.1:8080/ws", "ws://localhost:8080/ws", "ws://mesa.local:8080/ws", "ws://169.254.3.4/ws",
		"ws://[::1]:8080/ws", "ws://[fd12:3456::1]:8080/ws", "ws://[fe80::1]/ws", "wss://exemplo.org/ws",
		"wss://8.8.8.8/ws"]
	var nao := ["ws://8.8.8.8:8080/ws", "ws://172.32.0.1/ws", "ws://172.15.9.9/ws", "ws://192.169.0.1/ws",
		"ws://exemplo.org/ws", "ws://11.0.0.1/ws", "ws://[2001:db8::1]/ws", "ws://192.168.1/ws",
		"ws://192.168.1.300/ws", "http://192.168.1.2/ws", "ws://", "ws://local/ws", "ws://localhost.exemplo.org/ws"]
	for u in sim:
		_ok(RedeScript.url_permitida_no_android(u), "JV2.1b: Android liga a %s" % u)
	for u in nao:
		_ok(not RedeScript.url_permitida_no_android(u), "JV2.1b: Android NÃO liga em claro a %s" % u)


func _teste_entrada_por_argumentos() -> void:
	var r = RedeScript.new()
	var a: Dictionary = r.entrada_da_linha_de_comando(PackedStringArray(["--servidor=10.0.2.2:8080",
		"--entrar-nome=Ana Fictícia", "--entrar-senha=s3nha"]))
	_ok(a.get("nome") == "Ana Fictícia" and a.get("senha") == "s3nha", "JV2.1b: nome e senha vêm dos argumentos")
	_ok(r.entrada_da_linha_de_comando(PackedStringArray(["--entrar-nome=Ana"])).is_empty(),
		"JV2.1b: sem senha não há entrada automática")
	_ok(r.entrada_da_linha_de_comando(PackedStringArray()).is_empty(), "JV2.1b: sem argumentos não há entrada automática")
	r.free()


func _teste_espera_da_reconexao() -> void:
	# A tentativa que falha mesmo antes de a rede voltar marca a seguinte para ≤ tecto × 1,2 depois.
	_ok(RedeScript.ESPERA_MAX_S * 1.2 < 30.0, "JV3.4b: tecto da espera × 1,2 = %.1f s < 30 s" % (RedeScript.ESPERA_MAX_S * 1.2))
	_ok(RedeScript.ESPERA_MIN_S == 1.0, "JV3.4b: a primeira tentativa continua a 1 s")


func _teste_medicao() -> void:
	var v := PackedFloat32Array([10, 20, 30, 40, 50, 60, 70, 80, 90, 100])
	_ok(is_equal_approx(MedicaoScript.percentil(v, 50.0), 55.0), "V1.0: mediana de 10..100 = 55")
	_ok(is_equal_approx(MedicaoScript.percentil(v, 5.0), 14.5), "V1.0: p5 de 10..100 = 14,5 (interpolado)")
	_ok(MedicaoScript.percentil(PackedFloat32Array(), 50.0) == 0.0, "V1.0: sem amostras → 0")
	var r: Dictionary = MedicaoScript.montar_resultado(v, PackedFloat32Array([5, 7, 9]), {"gpu": "x", "dpr": 2.0,
		"viewport": [390, 844]})
	for campo in ["formato", "quadros", "fps_mediana", "fps_p5", "chamadas_mediana", "chamadas_max", "gpu", "dpr",
			"viewport", "janela_s"]:
		_ok(r.has(campo), "V1.0: o JSON traz «%s»" % campo)
	_ok(r["formato"] == "medicao-v1.0/1" and r["chamadas_mediana"] == 7 and r["chamadas_max"] == 9,
		"V1.0: formato e chamadas (mediana 7, máx 9)")
	_ok(is_equal_approx(MedicaoScript.AQUECIMENTO_S + MedicaoScript.JANELA_S, 60.0), "V1.0: 5 s + 55 s = 1 minuto")
