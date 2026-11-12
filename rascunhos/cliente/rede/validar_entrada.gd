extends RefCounted
## Validação do ROOM_JOIN no aparelho, antes de enviar (ordem 34, N26-2; sentença da bancada de 2026-11-12).
## Os limites são os do schema (protocolo/v2/ROOM_JOIN.schema.json): nome 1-64, senha 1-128, PIN ^[0-9]{6,32}$.
## Contam-se caracteres, não bytes (String.length() do Godot conta caracteres: nome com acento não vale «mais»).
## Cada função devolve "" quando o campo está dentro, ou a dica curta que aparece debaixo do campo.
## Campo fora = nada se envia: não vai ao servidor, não conta como credencial errada, não alimenta travão nenhum.
## Uso: const ValidarEntrada := preload("res://rede/validar_entrada.gd")

const NOME_MAX := 64
const SENHA_MAX := 128
const PIN_MIN := 6
const PIN_MAX := 32
const DICA_NOME := "Nome: até 64 letras"
const DICA_SENHA_FALTA := "Falta a senha"
const DICA_SENHA := "Senha: até 128 letras"
const DICA_PIN := "PIN: só números, 6 a 32"


## O nome vai aparado (a Rede manda-o sem os espaços das pontas).
static func dica_nome(nome: String) -> String:
	var n := nome.strip_edges().length()
	return "" if n >= 1 and n <= NOME_MAX else DICA_NOME


## A senha vai como foi escrita (os espaços contam).
static func dica_senha(senha: String) -> String:
	if senha.length() == 0:
		return DICA_SENHA_FALTA
	return "" if senha.length() <= SENHA_MAX else DICA_SENHA


## O PIN tem de casar exactamente ^[0-9]{6,32}$: só os algarismos 0-9 (nem espaços, nem algarismos de outra escrita).
static func dica_pin(pin: String) -> String:
	var n := pin.length()
	if n < PIN_MIN or n > PIN_MAX:
		return DICA_PIN
	for i in n:
		var c := pin.unicode_at(i)
		if c < 0x30 or c > 0x39:
			return DICA_PIN
	return ""


static func jogadora_valida(nome: String, senha: String) -> bool:
	return dica_nome(nome) == "" and dica_senha(senha) == ""


static func mestre_valido(pin: String) -> bool:
	return dica_pin(pin) == ""
