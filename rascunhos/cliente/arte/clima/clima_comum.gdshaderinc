// clima_comum.gdshaderinc — Ordem 40 (clima). A conta da posição de cada gota/floco, igual à de
// integrador_vento.gd (`posicao()`): os acumuladores vêm da CPU, somados FRAME A FRAME com o vento de cada
// frame; aqui só se lêem com os pesos do floco. Nunca «vento × tempo total» (lição da REF_85).

uniform vec3 caixa_min = vec3(-4.0, 0.0, -4.0);
uniform vec3 caixa_tam = vec3(38.0, 12.0, 38.0);
uniform float d_queda = 0.0;
uniform vec2 d_vento[3];
uniform vec2 d_lado[3];
// O que o último frame somou, em m/s (a chuva inclina-se com isto).
uniform float v_queda = 0.0;
uniform vec2 v_vento[3];

// Os pesos do floco, desempacotados do INSTANCE_CUSTOM (inteiros pequenos; ver Integrador.empacotar).
struct PesosClima {
	float k;   // queda: 10..16 (em 1/16)
	float r;   // 0..63: tamanho e fase
	vec3 w;    // vento: três pesos ≥ 0 (em 1/16)
	vec3 l;    // balanço: três pesos −8..8 (em 1/8)
};

PesosClima clima_pesos(vec4 c) {
	PesosClima p;
	p.k = mod(c.x, 32.0);
	p.r = floor(c.x / 32.0);
	p.w.x = mod(c.y, 32.0);
	p.w.y = floor(c.y / 32.0);
	p.w.z = mod(c.z, 32.0);
	p.l.x = floor(c.z / 32.0) - 8.0;
	p.l.y = mod(c.w, 32.0) - 8.0;
	p.l.z = floor(c.w / 32.0) - 8.0;
	return p;
}

// Posição no mundo. `base` = fracções 0..1 da caixa (a origem da instância).
vec3 clima_posicao(vec3 base, PesosClima p) {
	vec2 h = base.xz * caixa_tam.xz;
	h += (d_vento[0] * p.w.x + d_vento[1] * p.w.y + d_vento[2] * p.w.z) / 16.0;
	h += (d_lado[0] * p.l.x + d_lado[1] * p.l.y + d_lado[2] * p.l.z) / 8.0;
	float y = base.y * caixa_tam.y - d_queda * p.k / 16.0;
	return caixa_min + vec3(mod(h.x, caixa_tam.x), mod(y, caixa_tam.y), mod(h.y, caixa_tam.z));
}

// Velocidade do floco no último frame (m/s, mundo).
vec3 clima_velocidade(PesosClima p) {
	vec2 h = (v_vento[0] * p.w.x + v_vento[1] * p.w.y + v_vento[2] * p.w.z) / 16.0;
	return vec3(h.x, -v_queda * p.k / 16.0, h.y);
}

// Esbate o que está colado às paredes da caixa (o floco não «nasce» de repente à vista).
float clima_borda(vec3 mundo) {
	vec3 f = (mundo - caixa_min) / caixa_tam;
	float topo = smoothstep(1.0, 0.92, f.y);
	vec2 lados = smoothstep(vec2(0.0), vec2(0.03), f.xz) * smoothstep(vec2(1.0), vec2(0.97), f.xz);
	return topo * lados.x * lados.y;
}
