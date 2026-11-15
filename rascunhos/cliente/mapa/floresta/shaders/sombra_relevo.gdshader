// sombra_relevo.gdshader — Ordem 43. A sombra que o RELEVO deita, ao vivo: a mesma conta que
// a Ordem 38 fazia UMA vez em campo_floresta.gd (_iniciar_mapa), agora na GPU e com a luz de
// cada hora. É o fundo do forno vivo das sombras (sombras_floresta.gd): pinta o mapa inteiro;
// os carimbos multiplicam-se por cima.
// `alturas` = o relevo (metros, canal R), cobrindo [-meio, meio] nos dois eixos.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform sampler2D alturas : filter_linear, repeat_disable;
uniform vec3 dir_luz = vec3(-0.79, 0.52, 0.32);
uniform float meio = 72.0;
uniform float sen_min = 0.12;

vec3 para_luz(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void fragment() {
	vec3 l = normalize(dir_luz);
	float sen = max(l.y, sen_min);
	float sobe = sen / sqrt(max(1.0 - sen * sen, 1e-4));
	vec2 d2 = normalize(l.xz + vec2(1e-5, 0.0));
	// com o astro baixo a sombra vai mais longe: o passo cresce (até 4×)
	float passo = 1.2 * clamp(0.60 / sobe, 1.0, 4.0);
	float h = texture(alturas, UV).r;
	float tapa = 0.0;
	for (int s = 1; s <= 12; s++) {
		float t = float(s) * passo;
		float a = texture(alturas, UV + d2 * t / (2.0 * meio)).r - (h + 0.12 + sobe * t);
		tapa = max(tapa, a / (0.20 + 0.10 * t));
	}
	float r = 1.0 - 0.88 * clamp(tapa, 0.0, 1.0);
	ALBEDO = para_luz(vec3(r, 1.0, 1.0));
}
