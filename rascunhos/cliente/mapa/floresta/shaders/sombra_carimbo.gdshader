// sombra_carimbo.gdshader — Ordem 43. O FORNO VIVO das sombras: os mesmos carimbos elípticos
// que a Ordem 38 cozia UMA vez no mapa do chão (campo_floresta.gd: _carimbo_min), agora
// desenhados pela GPU a cada mudança da luz — para as sombras RODAREM e ALONGAREM com o sol
// (e com a lua). Desenha-se num SubViewport visto de cima (sombras_floresta.gd).
//
// Cada lançador de sombra é um quadrado de 4 vértices iguais:
//   VERTEX  = (x, altura acima do chão, z) do ponto que faz sombra
//   UV2     = (raio de través, força)
//   CUSTOM0 = (a, b, c, só-copas): raio ao longo da luz = a + b·cotg(elev) + c/sen(elev)
//             (a: fixo · b: o alto que se deita · c: a esfera que se estica)
// O canto do quadrado sai do número do vértice. Mistura por MULTIPLICAÇÃO sobre branco:
// canal R = sol que chega (tudo) · canal B = sol que chega contando só as copas.
shader_type spatial;
render_mode unshaded, blend_mul, cull_disabled, depth_test_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 dir_luz = vec3(-0.79, 0.52, 0.32);
uniform float sen_min = 0.12;      // a sombra não estica para lá do que daria um astro a 7°

varying vec2 v_q;
varying float v_forca;
varying float v_copa;

void vertex() {
	vec2 canto = vec2(float(VERTEX_ID & 1) * 2.0 - 1.0, float((VERTEX_ID >> 1) & 1) * 2.0 - 1.0);
	vec3 l = normalize(dir_luz);
	float sen = max(l.y, sen_min);
	float cotg = sqrt(max(1.0 - sen * sen, 0.0)) / sen;
	vec2 d2 = normalize(l.xz + vec2(1e-5, 0.0));
	float ra = CUSTOM0.x + CUSTOM0.y * cotg + CUSTOM0.z / sen;
	float rb = UV2.x;
	vec2 g = VERTEX.xz - d2 * (VERTEX.y * cotg);
	vec2 p = g + d2 * (canto.x * ra) + vec2(-d2.y, d2.x) * (canto.y * rb);
	v_q = canto;
	v_forca = UV2.y;
	v_copa = CUSTOM0.w;
	VERTEX = vec3(p.x, 0.0, p.y);
}

vec3 para_luz(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void fragment() {
	float q = dot(v_q, v_q);
	float s = 1.0 - v_forca * (1.0 - smoothstep(0.45, 1.0, q));
	// (a saída do 3D passa a sRGB antes da mistura: escreve-se «em luz» para multiplicar por s)
	ALBEDO = para_luz(vec3(s, 1.0, mix(1.0, s, v_copa)));
}
