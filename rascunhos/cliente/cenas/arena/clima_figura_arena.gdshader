// clima_figura_arena.gdshader — Ordem Neve (Fatia 2 e Fatia 3).
// Camada das figuras e dos obstáculos reais do mapa (pedras, menires, santuário, troncos) na arena integrada:
// - Acumulação direccional respeitando barlavento/sotavento e o topo virado para cima;
// - Congelamento gradual (`congelamento` / `gelo`) nas bordas, contornos e faces varridas pelo vento;
// - Leitura integrada com a luz do ciclo do dia (Ordem 43) para não estourar ao meio-dia nem brilhar no escuro à noite.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

#include "res://arte/clima/clima_terreno.gdshaderinc"

uniform float molhado : hint_range(0.0, 1.0) = 0.0;
uniform float neve : hint_range(0.0, 1.0) = 0.0;
uniform vec3 luz_dir = vec3(-0.79, 0.52, 0.32);
uniform vec3 luz_cor : source_color = vec3(1.0, 0.90, 0.71);
uniform vec3 cor_reflexo : source_color = vec3(0.72, 0.80, 0.88);
uniform vec3 cor_neve : source_color = vec3(0.92, 0.95, 0.99);
uniform vec3 cor_neve_sombra : source_color = vec3(0.58, 0.68, 0.84);
uniform float espessura_m = 0.055;
uniform float aglomerado : hint_range(0.0, 1.0) = 0.0;
uniform float gelo : hint_range(0.0, 1.0) = 0.0;
uniform float congelamento : hint_range(0.0, 1.0) = 0.0;
uniform float agua : hint_range(0.0, 1.0) = 0.0;
uniform float tempo = 0.0;
uniform vec3 cor_gelo : source_color = vec3(0.70, 0.87, 0.99);

uniform vec3 cor_sombra_ciclo : source_color = vec3(0.32, 0.40, 0.54);
uniform vec3 cor_ceu_ciclo : source_color = vec3(0.64, 0.71, 0.74);
uniform float noite_ciclo : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_mundo;
varying vec3 v_normal;

float h31(vec3 p) {
	p = fract(p * vec3(123.34, 456.21, 289.77));
	p += dot(p, p.yzx + 45.32);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	v_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	vec2 w = normalize(vento_abrigo + vec2(1e-5, 0.0));
	vec3 cima_local = vec3(0.0, 1.0, 0.0) * mat3(MODEL_MATRIX);
	cima_local /= max(dot(cima_local, cima_local), 1e-8);
	VERTEX += cima_local * (espessura_m * (neve + 0.85 * aglomerado) * smoothstep(0.0, 0.58, v_normal.y));
	// Acumulação direccional em sotavento e barlavento nos obstáculos/figuras
	float sota = smoothstep(0.08, 0.78, dot(v_normal.xz, w));
	float barla = smoothstep(0.15, 0.82, -dot(v_normal.xz, w));
	VERTEX += NORMAL * (0.032 * aglomerado * max(sota, barla * 0.65));
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 N = normalize(v_normal);
	vec3 V = normalize(CAMERA_POSITION_WORLD - v_mundo);
	vec3 L = normalize(luz_dir);
	vec2 w = normalize(vento_abrigo + vec2(1e-5, 0.0));
	float nv = clamp(dot(N, V), 0.0, 1.0);
	vec3 R = reflect(-V, N);
	vec3 pre = vec3(0.0);
	float a = 0.0;
	float cong = max(gelo, congelamento);

	float ndl = dot(N, L);
	float k_luz = smoothstep(-0.20, 0.85, ndl);
	vec3 luz_ciclo = clamp(cor_ceu_ciclo * (0.34 + 0.20 * N.y) + mix(cor_sombra_ciclo * 0.50, luz_cor * 1.10, k_luz),
		vec3(0.24, 0.30, 0.44), vec3(0.93, 0.95, 0.98));

	if (molhado > 0.001) {
		float raspao = pow(1.0 - nv, 4.0);
		vec3 ceu = cor_reflexo * mix(1.1, 0.8, clamp(R.y, 0.0, 1.0));
		float sol = pow(max(dot(R, L), 0.0), 36.0);
		float topo = smoothstep(0.1, 0.9, N.y) * 0.10;
		float lustro = pow(max(dot(R, L), 0.0), 6.0) * 0.20;
		vec3 brilho = (ceu * (0.03 + 0.50 * raspao + topo) + luz_cor * (sol * 0.85 + lustro)) * molhado;
		float a_molhado = clamp(max(molhado * 0.26, max(brilho.r, max(brilho.g, brilho.b))), 0.0, 1.0);
		pre = min(brilho, vec3(a_molhado));
		a = a_molhado;
	}

	if (agua > 0.001 && n_bacias > 0) {
		float y_rel = v_mundo.y - chao_ref_y;
		float d = clima_fundura(v_mundo.xz, 0.0, agua * CLIMA_ENCHE, 0.0);
		float dentro = smoothstep(0.0, 0.006, d);
		float barra = dentro * smoothstep(0.16, 0.04, y_rel);
		float linha = dentro * smoothstep(0.035, 0.0, abs(y_rel - 0.02));
		vec3 c_pes = vec3(0.07, 0.09, 0.10) + cor_reflexo * (0.10 + 0.45 * pow(1.0 - nv, 3.0) + 0.5 * linha);
		float a_pes = clamp(barra * 0.55 + linha * 0.5, 0.0, 0.85);
		pre = c_pes * a_pes + pre * (1.0 - a_pes);
		a = a_pes + a * (1.0 - a_pes);
	}

	// Congelamento gradual (Fatia 3): geada e gelo nas faces de barlavento e no contorno
	if (cong > 0.001) {
		float contorno = pow(1.0 - nv, 2.3);
		float espicula = pow(max(dot(R, L), 0.0), 90.0);
		float barlavento = smoothstep(0.10, 0.82, -dot(N.xz, w)) * smoothstep(-0.45, 0.25, N.y);
		float grao = h31(floor(v_mundo * 55.0));
		float cintila = step(0.94, grao) * max(sin(grao * 60.0 + dot(V, vec3(41.0, 23.0, 57.0)) + tempo * 0.7), 0.0);
		vec3 c_gelo = cor_gelo * (0.68 + 0.32 * contorno) * luz_ciclo + luz_cor * espicula * 1.1 + vec3(cintila * 0.75);
		float a_gelo = clamp(cong * (0.14 + 0.62 * contorno + 0.36 * barlavento * (0.6 + 0.4 * grao) + espicula + cintila * 0.7), 0.0, 0.92);
		pre = c_gelo * a_gelo + pre * (1.0 - a_gelo);
		a = a_gelo + a * (1.0 - a_gelo);
	}

	if (neve > 0.001 || aglomerado > 0.001) {
		float limiar = mix(0.95, 0.14, clamp(neve + 0.45 * aglomerado, 0.0, 1.0));
		float a_neve = smoothstep(limiar, limiar + 0.12, N.y) * min((neve + aglomerado) * 10.0, 1.0) * 0.97;
		// Acumulação direccional a sotavento e junto à base de barlavento
		float sota = smoothstep(0.08, 0.78, dot(N.xz, w));
		float barla_base = smoothstep(0.18, 0.85, -dot(N.xz, w)) * smoothstep(0.65, 0.0, v_mundo.y - chao_ref_y);
		float corpo = smoothstep(-0.50, 0.18, N.y) * (0.72 + 0.28 * h31(floor(v_mundo * 9.0)));
		a_neve = max(a_neve, aglomerado * max(sota, barla_base * 0.80) * corpo * 0.95);
		vec3 c_neve = mix(cor_neve_sombra, cor_neve, smoothstep(0.25, 0.92, max(N.y, sota * 0.8))) * luz_ciclo;
		if (noite_ciclo > 0.001) {
			float lum_n = dot(c_neve, vec3(0.30, 0.52, 0.18));
			c_neve = mix(c_neve, lum_n * vec3(0.72, 0.92, 1.36), noite_ciclo * 0.45);
		}
		c_neve = min(c_neve, vec3(0.92, 0.94, 0.97));
		pre = c_neve * a_neve + pre * (1.0 - a_neve);
		a = a_neve + a * (1.0 - a_neve);
	}

	ALBEDO = pre / max(a, 1e-4);
	ALPHA = a;
}
