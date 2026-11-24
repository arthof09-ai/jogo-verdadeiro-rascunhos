extends SceneTree
## ORDEM-D-AUD-16-SEGUIMENTO (medição, não é suite): o ecrã do Mestre aberto com a Rede a ligar a um servidor FORA DO
## AR, como no arranque directo. Regista cada mudança da ligação (ms desde o início), a frase do rótulo da ligação e
## o número de alertas. Uso: godot --headless --path . -s testes/medir_ligacao_arranque.gd -- --servidor=127.0.0.1:<porta livre>
const CENA := "res://cenas/mestre/mestre.tscn"
const DURACAO_MS := 75000
const NOMES := ["DESLIGADA", "A_LIGAR", "A_ENTRAR", "NA_MESA", "A_ESPERAR", "PARADA"]
var _rede: Node
var _c
var _t0 := 0
var _mudancas := 0


func _init() -> void:
	process_frame.connect(_correr, CONNECT_ONE_SHOT)


func _linha(o_que: String) -> void:
	var rot := ""
	if _c != null and _c._ligacao != null:
		rot = _c._ligacao.text if _c._ligacao.visible else "(rótulo escondido)"
	print("t=%6d ms  %-10s  alertas=%d  rótulo: %s  [%s]" % [Time.get_ticks_msec() - _t0, NOMES[_rede.estado_ligacao],
		_c.alertas.size() if _c != null else 0, rot, o_que])


func _correr() -> void:
	_rede = root.get_node("Rede")
	_rede.persistir = false  # nada em disco: o lugar fictício só vive em memória
	_rede.papel = "mestre"
	_rede._seat_token = "token-ficticio-da-medicao"
	_rede._room_id = "sala-medida"
	print("servidor: %s (fora do ar)" % _rede.url_servidor())
	_t0 = Time.get_ticks_msec()
	_rede.iniciar()  # como o arranque directo: a Rede começa a ligar ANTES de o ecrã do Mestre existir
	_c = (load(CENA) as PackedScene).instantiate()
	_c.pedir_vista_fn = func(): return false
	root.add_child(_c)
	_linha("o ecrã do Mestre abriu")
	_rede.ligacao_mudou.connect(func(_e): _mudancas += 1; _linha("ligacao_mudou"))
	while Time.get_ticks_msec() - _t0 < DURACAO_MS:
		await process_frame
	_linha("fim da medição")
	print("mudanças da ligação em %d s: %d; alertas no fim: %d; na mesa alguma vez: %s" % [DURACAO_MS / 1000, _mudancas,
		_c.alertas.size(), _rede.ja_esteve_na_mesa()])
	quit(0)
