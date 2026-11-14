// chuva_gotas.gdshader — Ordem 40 (clima). Uma gota por instância: um risco esticado AO LONGO DA VELOCIDADE
// do frame (queda + vento desse frame), por isso a chuva inclina-se com o vento e roda quando ele roda.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;

#include "res://arte/clima/clima_comum.gdshaderinc"

uniform vec4 cor : source_color = vec4(0.80, 0.87, 0.96, 0.55);
// O risco é o caminho da gota durante este tempo (s).
uniform float exposicao_s = 0.035;
uniform float largura_m = 0.016;
uniform float px_minimo = 1.3;
uniform float opacidade = 1.0;

varying float v_alpha;

void vertex() {
	PesosClima p = clima_pesos(INSTANCE_CUSTOM);
	vec3 mundo = clima_posicao(MODEL_MATRIX[3].xyz, p);
	vec3 vel = clima_velocidade(p);
	float rapidez = max(length(vel), 0.001);
	vec3 eixo_mundo = vel / rapidez;
	vec4 vista = VIEW_MATRIX * vec4(mundo, 1.0);
	vec3 eixo = (VIEW_MATRIX * vec4(eixo_mundo, 0.0)).xyz;
	float dist = max(-vista.z, 0.001);
	vec3 lado = cross(eixo, normalize(vista.xyz));
	float ll = length(lado);
	lado = ll > 0.001 ? lado / ll : vec3(1.0, 0.0, 0.0);
	float m_por_px = 2.0 * dist / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	float larg = max(largura_m * (0.7 + 0.6 * p.r / 63.0), px_minimo * m_por_px);
	float comp = max(rapidez * exposicao_s, larg);
	// VERTEX.y = -0.5 é a ponta de baixo (a cabeça da gota, para onde ela vai).
	VERTEX = vista.xyz - eixo * (VERTEX.y * comp) + lado * (VERTEX.x * larg);
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_alpha = smoothstep(0.8, 2.5, dist) * clima_borda(mundo) * (0.75 + 0.25 * p.r / 63.0);
}

void fragment() {
	// UV.y: 0 em cima (a cauda), 1 em baixo (a cabeça). A cauda esbate.
	float ao_longo = smoothstep(0.0, 0.55, UV.y) * smoothstep(1.0, 0.9, UV.y);
	float atraves = 1.0 - abs(UV.x * 2.0 - 1.0);
	ALBEDO = cor.rgb;
	ALPHA = ao_longo * atraves * cor.a * v_alpha * opacidade;
}
