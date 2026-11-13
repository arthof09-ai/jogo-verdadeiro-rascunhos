// copa.gdshader — Ordem 37. Copas e arbustos: massas pintadas (sem alfa), 3 tons de pincelada,
// normais de volume, contraluz dourada na orla e vento no vértice.
// COLOR.rgb = tinta da bolha; COLOR.a = oclusão cozinhada. UV = (fase do vento, peso do vento).
shader_type spatial;
render_mode unshaded, cull_back, world_vertex_coords;

#include "luz_floresta.gdshaderinc"

uniform vec3 cor_ouro : source_color = vec3(0.70, 0.65, 0.27);
uniform vec2 vento_dir = vec2(0.85, 0.5);
uniform float vento_forca : hint_range(0.0, 1.5) = 0.22;
uniform float vento_vel : hint_range(0.0, 4.0) = 1.0;

varying vec3 v_pos;
varying vec3 v_n;

void vertex() {
	vec2 dv = normalize(vento_dir);
	float t = TIME * vento_vel;
	float fase = UV.x * 6.2832 + dot(VERTEX.xz, dv) * 0.12;
	float balanco = sin(t * 0.9 + fase) * 0.6 + sin(t * 0.37 + fase * 1.7) * 0.4;
	float trem = sin(t * 4.3 + VERTEX.x * 1.9 + VERTEX.y * 2.3 + VERTEX.z * 1.3);
	VERTEX.xz += dv * (balanco * vento_forca + trem * 0.035) * UV.y;
	VERTEX.y += trem * 0.03 * UV.y;
	v_pos = VERTEX;
	v_n = NORMAL;
}

void fragment() {
	vec3 n = normalize(v_n);
	// pinceladas de folha: ruído em dois planos do mundo
	float r = texture(ruido, v_pos.xz * 0.33 + v_pos.y * 0.21).r;
	float r2 = texture(ruido, v_pos.xy * 0.85 + v_pos.z * 0.6).r;
	float pinc = r * 0.55 + r2 * 0.45;
	float ndl = dot(n, dir_luz) + (pinc - 0.5) * 0.75;
	float k = smoothstep(-0.20, 0.10, ndl) * 0.5 + smoothstep(0.28, 0.58, ndl) * 0.5;
	float ao = COLOR.a;
	vec3 alb = COLOR.rgb * (0.82 + 0.36 * r);
	vec3 amb = cor_ceu * (0.26 + 0.20 * n.y) + ressalto_chao(n) * 1.25;
	vec3 cor = alb * (amb + mix(cor_sombra * 0.45, cor_sol, k * ao));
	// o tom mais alto leva ouro (a luz rasante da referência)
	cor += cor_ouro * cor_sol * smoothstep(0.62, 0.80, ndl) * 0.30 * ao;
	// contraluz na orla
	vec3 vw = normalize(CAMERA_POSITION_WORLD - v_pos);
	float orla = 1.0 - max(dot(n, vw), 0.0);
	float contra = max(dot(-vw, dir_luz), 0.0);
	cor += cor_ouro * cor_sol * orla * orla * (0.10 + 0.9 * contra * contra) * 0.55;
	ALBEDO = cor * mix(0.72, 1.0, ao);
}
