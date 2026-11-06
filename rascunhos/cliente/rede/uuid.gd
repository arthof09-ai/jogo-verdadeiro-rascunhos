extends RefCounted
## UUID v4 (RFC 4122) feito com bytes de Crypto.generate_random_bytes (CSPRNG).
## Uso: const Uuid := preload("res://rede/uuid.gd"); Uuid.v4()


static func v4() -> String:
	var crypto := Crypto.new()
	var b: PackedByteArray = crypto.generate_random_bytes(16)
	b[6] = (b[6] & 0x0f) | 0x40  # versão 4
	b[8] = (b[8] & 0x3f) | 0x80  # variante RFC 4122
	var h: String = b.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		h.substr(0, 8), h.substr(8, 4), h.substr(12, 4), h.substr(16, 4), h.substr(20, 12)
	]
