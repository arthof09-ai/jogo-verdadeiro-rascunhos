// neve_flocos.gdshader — Ordem 40 (clima). Um floco por instância da MultiMesh, virado para a câmara.
// Compatibility (WebGL 2 / telemóvel): sem luz, sem escrever profundidade; a conta toda no vértice.
//
// Ordem 41 (nevasca): com `exposicao_s` > 0 o floco estica-se ao longo da velocidade DO FRAME (queda + vento
// desse frame), como a gota da chuva — nas rajadas os flocos inclinam-se e alongam-se todos juntos; na calma
// voltam a ser pontos. O mesmo shader desenha o VÉU (cartões grandes e ténues que só aparecem ao longe,
// de `veu_perto_m` a `veu_longe_m` da câmara): a nevasca fecha o fundo sem tapar a zona da câmara.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;

#include "res://arte/clima/clima_comum.gdshaderinc"

uniform vec4 cor : source_color = vec4(0.96, 0.98, 1.0, 0.92);
uniform float tamanho_m = 0.075;
// Nunca mais pequeno do que isto no ecrã (em píxeis do render): o floco não some no Panorama.
uniform float px_minimo = 1.7;
uniform float opacidade = 1.0;
// Ordem 41: o rasto do floco é o caminho dele durante este tempo (s). 0 = ponto redondo (a base).
uniform float exposicao_s = 0.0;
// Ordem 41: o véu só se vê ao longe. veu_longe_m = 0 desliga (flocos normais).
uniform float veu_perto_m = 0.0;
uniform float veu_longe_m = 0.0;
// 0 = floco de orla nítida; 1 = mancha macia (o véu).
uniform float macio = 0.0;

varying float v_alpha;

void vertex() {
	PesosClima p = clima_pesos(INSTANCE_CUSTOM);
	vec3 mundo = clima_posicao(MODEL_MATRIX[3].xyz, p);
	vec4 vista = VIEW_MATRIX * vec4(mundo, 1.0);
	float dist = max(-vista.z, 0.001);
	float t = tamanho_m * (0.65 + 0.7 * p.r / 63.0);
	float m_por_px = 2.0 * dist / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	t = max(t, px_minimo * m_por_px);
	// O rasto: estica ao longo da velocidade do frame, vista do ecrã (sem rasto, eixo = (0, 1): fica igual).
	vec2 eixo = vec2(0.0, 1.0);
	float comp = t;
	if (exposicao_s > 0.0) {
		vec3 vel = (VIEW_MATRIX * vec4(clima_velocidade(p), 0.0)).xyz;
		float rapidez = length(vel.xy);
		if (rapidez > 0.001) {
			eixo = vel.xy / rapidez;
			comp = max(t, 0.5 * rapidez * exposicao_s + 0.5 * t);
		}
	}
	vec2 lado = vec2(eixo.y, -eixo.x);
	VERTEX = vista.xyz + vec3(lado * (VERTEX.x * t) + eixo * (VERTEX.y * comp), 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
	// Perto demais da câmara o floco tapava a mesa: esbate.
	v_alpha = smoothstep(0.8, 2.5, dist) * clima_borda(mundo);
	if (veu_longe_m > 0.0) {
		v_alpha *= smoothstep(veu_perto_m, veu_longe_m, dist);
	}
	// O floco esticado espalha a mesma neve por mais área: fica mais ténue (não é um risco de giz).
	v_alpha *= mix(1.0, 0.72, clamp(comp / t - 1.0, 0.0, 1.0));
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float d = dot(q, q);
	float a = mix(smoothstep(1.0, 0.25, d), smoothstep(1.0, 0.0, d) * smoothstep(1.0, 0.0, d), macio);
	// A orla do floco é azulada: lê-se mesmo por cima do chão já branco.
	ALBEDO = mix(cor.rgb * vec3(0.66, 0.74, 0.90), cor.rgb, smoothstep(0.85, 0.15, d));
	ALPHA = a * cor.a * v_alpha * opacidade;
}
