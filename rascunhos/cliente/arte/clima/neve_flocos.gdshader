// neve_flocos.gdshader — Ordem 40 (clima). Um floco por instância da MultiMesh, virado para a câmara.
// Compatibility (WebGL 2 / telemóvel): sem luz, sem escrever profundidade; a conta toda no vértice.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;

#include "res://arte/clima/clima_comum.gdshaderinc"

uniform vec4 cor : source_color = vec4(0.96, 0.98, 1.0, 0.92);
uniform float tamanho_m = 0.075;
// Nunca mais pequeno do que isto no ecrã (em píxeis do render): o floco não some no Panorama.
uniform float px_minimo = 1.7;
uniform float opacidade = 1.0;

varying float v_alpha;

void vertex() {
	PesosClima p = clima_pesos(INSTANCE_CUSTOM);
	vec3 mundo = clima_posicao(MODEL_MATRIX[3].xyz, p);
	vec4 vista = VIEW_MATRIX * vec4(mundo, 1.0);
	float dist = max(-vista.z, 0.001);
	float t = tamanho_m * (0.65 + 0.7 * p.r / 63.0);
	float m_por_px = 2.0 * dist / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	t = max(t, px_minimo * m_por_px);
	VERTEX = vista.xyz + vec3(VERTEX.xy * t, 0.0);
	NORMAL = vec3(0.0, 0.0, 1.0);
	// Perto demais da câmara o floco tapava a mesa: esbate.
	v_alpha = smoothstep(0.8, 2.5, dist) * clima_borda(mundo);
}

void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float d = dot(q, q);
	float a = smoothstep(1.0, 0.25, d);
	// A orla do floco é azulada: lê-se mesmo por cima do chão já branco.
	ALBEDO = mix(cor.rgb * vec3(0.66, 0.74, 0.90), cor.rgb, smoothstep(0.85, 0.15, d));
	ALPHA = a * cor.a * v_alpha * opacidade;
}
