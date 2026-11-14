// clima_figura.gdshader — Ordem 40 (clima) + Ordem 41 (expansão). A RESPOSTA DAS FIGURAS E DOS OBSTÁCULOS,
// como material_overlay: desenha-se por cima da figura (marcador, cápsula ou GLB), sem tocar no material dela.
//
// A BASE (Ordem 40):
//   molhado (0..1): a figura escurece um pouco e ganha brilho — reflexo do céu no contorno e do sol nas faces;
//   neve (0..1):    neve em cima — começa no topo (cabeça) e desce pelas faces viradas para cima; a camada
//                   sobe uns centímetros, para a neve ter corpo. Só visual: não muda altura nenhuma do jogo.
// O CLIMA FORTE (Ordem 41) — a zero nos climas fracos:
//   aglomerado (0..1): a neve da nevasca cola-se ao lado ABRIGADO do vento (costas, ombros, nuca) e engrossa
//                      em cima;
//   gelo (0..1):       brilho frio no contorno, espícula do sol e geada no lado de onde o vento vem —
//                      cresce com o tempo de exposição;
//   agua:              dentro de uma bolsa, a figura lê-se com os pés na água (uma barra molhada em baixo).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

#include "res://arte/clima/clima_terreno.gdshaderinc"

uniform float molhado : hint_range(0.0, 1.0) = 0.0;
uniform float neve : hint_range(0.0, 1.0) = 0.0;
uniform vec3 luz_dir = vec3(0.4, 0.8, 0.45);
uniform vec3 luz_cor : source_color = vec3(1.0, 0.95, 0.85);
uniform vec3 cor_reflexo : source_color = vec3(0.72, 0.80, 0.88);
uniform vec3 cor_neve : source_color = vec3(0.93, 0.96, 0.99);
uniform vec3 cor_neve_sombra : source_color = vec3(0.72, 0.80, 0.91);
// Quanto a camada de neve sobe com a neve = 1 (m).
uniform float espessura_m = 0.05;
// ---- Ordem 41
uniform float aglomerado : hint_range(0.0, 1.0) = 0.0;
uniform float gelo : hint_range(0.0, 1.0) = 0.0;
uniform float agua : hint_range(0.0, 1.0) = 0.0;
uniform float tempo = 0.0;
uniform vec3 cor_gelo : source_color = vec3(0.72, 0.89, 1.0);

varying vec3 v_mundo;
varying vec3 v_normal;

float h31(vec3 p) {
	p = fract(p * vec3(123.34, 456.21, 289.77));
	p += dot(p, p.yzx + 45.32);
	return fract((p.x + p.y) * p.z);
}

void vertex() {
	v_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	// A neve sobe uns centímetros para CIMA no mundo. A conta faz-se no espaço do modelo e soma zero quando
	// não há neve: o vértice fica igual, bit a bit, ao do material da figura (sem isto a camada do molhado
	// «lutava» pela profundidade com a figura e ficava aos salpicos).
	vec3 cima_local = vec3(0.0, 1.0, 0.0) * mat3(MODEL_MATRIX);
	cima_local /= max(dot(cima_local, cima_local), 1e-8);
	VERTEX += cima_local * (espessura_m * (neve + 0.8 * aglomerado) * smoothstep(0.0, 0.6, v_normal.y));
	// A neve colada ao lado abrigado tem corpo: sai uns centímetros para fora, ao longo da normal.
	float sota = smoothstep(0.10, 0.80, dot(v_normal.xz, vento_abrigo));
	VERTEX += NORMAL * (0.030 * aglomerado * sota);
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 N = normalize(v_normal);
	vec3 V = normalize(CAMERA_POSITION_WORLD - v_mundo);
	vec3 L = normalize(luz_dir);
	float nv = clamp(dot(N, V), 0.0, 1.0);
	vec3 R = reflect(-V, N);
	vec3 pre = vec3(0.0);
	float a = 0.0;

	if (molhado > 0.001) {
		float raspao = pow(1.0 - nv, 4.0);
		vec3 ceu = cor_reflexo * mix(1.1, 0.8, clamp(R.y, 0.0, 1.0));
		float sol = pow(max(dot(R, L), 0.0), 36.0);
		// Um reflexo do céu nas faces viradas para cima; a cor da figura continua a mandar (lê-se quem é quem).
		float topo = smoothstep(0.1, 0.9, N.y) * 0.10;
		float lustro = pow(max(dot(R, L), 0.0), 6.0) * 0.20;
		vec3 brilho = (ceu * (0.03 + 0.50 * raspao + topo) + luz_cor * (sol * 0.85 + lustro)) * molhado;
		float a_molhado = clamp(max(molhado * 0.26, max(brilho.r, max(brilho.g, brilho.b))), 0.0, 1.0);
		pre = min(brilho, vec3(a_molhado));
		a = a_molhado;
	}

	// Os pés na água: dentro de uma bolsa, a parte de baixo da figura fica escura e a brilhar (Ordem 41).
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

	// O gelo (Ordem 41): contorno frio, espícula e geada do lado do vento — por baixo da neve.
	if (gelo > 0.001) {
		float contorno = pow(1.0 - nv, 2.4);
		float espicula = pow(max(dot(R, L), 0.0), 90.0);
		float barlavento = smoothstep(0.15, 0.85, -dot(N.xz, vento_abrigo)) * smoothstep(-0.5, 0.2, N.y);
		float grao = h31(floor(v_mundo * 55.0));
		float cintila = step(0.94, grao) * max(sin(grao * 60.0 + dot(V, vec3(41.0, 23.0, 57.0)) + tempo * 0.7), 0.0);
		vec3 c_gelo = cor_gelo * (0.70 + 0.30 * contorno) + luz_cor * espicula * 1.3 + vec3(cintila * 0.8);
		float a_gelo = clamp(gelo * (0.10 + 0.62 * contorno + 0.30 * barlavento * (0.6 + 0.4 * grao) + espicula + cintila * 0.7), 0.0, 0.92);
		pre = c_gelo * a_gelo + pre * (1.0 - a_gelo);
		a = a_gelo + a * (1.0 - a_gelo);
	}

	if (neve > 0.001 || aglomerado > 0.001) {
		// A linha da neve desce: primeiro só o topo, depois tudo o que olha para cima.
		float limiar = mix(0.97, 0.22, clamp(neve + 0.35 * aglomerado, 0.0, 1.0));
		float a_neve = smoothstep(limiar, limiar + 0.10, N.y) * min((neve + aglomerado) * 10.0, 1.0) * 0.97;
		// A nevasca cola a neve ao lado abrigado (as costas): mais em cima (ombros, nuca), menos junto ao chão.
		float sota = smoothstep(0.10, 0.80, dot(N.xz, vento_abrigo));
		float corpo = smoothstep(-0.55, 0.15, N.y) * (0.72 + 0.28 * h31(floor(v_mundo * 9.0)));
		a_neve = max(a_neve, aglomerado * sota * corpo * 0.95);
		float luz = 0.78 + 0.22 * clamp(dot(N, L), 0.0, 1.0);
		vec3 c_neve = mix(cor_neve_sombra, cor_neve, smoothstep(0.3, 0.95, max(N.y, sota * 0.8))) * luz;
		pre = c_neve * a_neve + pre * (1.0 - a_neve);
		a = a_neve + a * (1.0 - a_neve);
	}

	ALBEDO = pre / max(a, 1e-4);
	ALPHA = a;
}
