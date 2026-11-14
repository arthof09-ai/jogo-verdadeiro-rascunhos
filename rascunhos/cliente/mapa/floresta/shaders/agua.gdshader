// agua.gdshader — Ordem 38 (defeito 4). O charco da cova: água parada, opaca (sem alfa).
// A cor vai da margem rasa ao fundo escuro (COLOR.a = fundura 0–1, cozida no vértice); por cima
// o céu espelhado (mais forte a olhar rasante), a sombra das copas e uma ruga lenta.
shader_type spatial;
render_mode unshaded, cull_back, world_vertex_coords;

#include "luz_floresta.gdshaderinc"

uniform vec3 cor_funda : source_color = vec3(0.24, 0.40, 0.44);
uniform vec3 cor_rasa : source_color = vec3(0.49, 0.60, 0.53);
uniform vec3 cor_reflexo : source_color = vec3(0.50, 0.65, 0.81);

varying vec3 v_pos;

void vertex() {
	v_pos = VERTEX;
}

void fragment() {
	float fundo = COLOR.a;
	float ruga = texture(ruido, v_pos.xz * 0.21 + vec2(TIME * 0.011, TIME * 0.007)).r;
	float ruga2 = texture(ruido, v_pos.xz * 0.47 - vec2(TIME * 0.009, -TIME * 0.013)).r;
	vec3 n = normalize(vec3((ruga - 0.5) * 0.22, 1.0, (ruga2 - 0.5) * 0.22));
	vec3 agua = mix(cor_rasa, cor_funda, smoothstep(0.0, 0.75, fundo));
	float vis = smoothstep(0.30, 0.70, ler_mapa(v_pos.xz).r);
	vec3 cor = luz_pintada(agua, vec3(0.0, 1.0, 0.0), vis);
	vec3 vw = normalize(CAMERA_POSITION_WORLD - v_pos);
	float rasante = pow(1.0 - max(dot(n, vw), 0.0), 3.0);
	cor = mix(cor, cor_reflexo * (0.80 + 0.30 * ruga2), clamp(0.10 + 0.75 * rasante, 0.0, 0.85) * smoothstep(0.02, 0.30, fundo + 0.1));
	// o brilho do sol na ruga (contido)
	vec3 refl = reflect(-vw, n);
	cor += cor_sol * pow(max(dot(refl, dir_luz), 0.0), 60.0) * 0.35 * vis;
	ALBEDO = cor;
}
