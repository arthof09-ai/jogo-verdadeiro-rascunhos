// marco.gdshader — Ordem 38 (defeito 4). Os marcos construídos da arena (santuário, lanternas):
// tinta do vértice com a luz pintada do mapa. COLOR.a = 0 marca LUZ PRÓPRIA (janelas e lume
// acesos: não levam sombra — são o ouro que ecoa o palácio da Árvore Ancestral).
shader_type spatial;
render_mode unshaded, cull_back, world_vertex_coords;

#include "luz_floresta.gdshaderinc"

varying vec3 v_pos;
varying vec3 v_n;

void vertex() {
	v_pos = VERTEX;
	v_n = NORMAL;
}

void fragment() {
	vec3 n = normalize(v_n);
	float r = texture(ruido, (v_pos.xz + v_pos.y * vec2(0.7, 0.3)) * 0.9).r;
	vec3 alb = COLOR.rgb * (0.86 + 0.28 * r);
	float vis = smoothstep(0.30, 0.70, ler_mapa(v_pos.xz).b);
	vec3 cor = luz_pintada(alb, n, vis);
	ALBEDO = mix(COLOR.rgb * (0.95 + 0.25 * r), cor, step(0.5, COLOR.a));
}
