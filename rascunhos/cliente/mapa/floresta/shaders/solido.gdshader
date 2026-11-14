// solido.gdshader — Ordem 37/38. Troncos e pedras: tinta do vértice + pincelada + musgo por cima.
// Ordem 38: para lá do mapa do chão é floresta fechada (ler_mapa), não a última linha da textura;
// e o pé escurece com a oclusão de contacto (canal A do mapa) — nada pousa sem sombra.
// A sombra das copas vem do canal B do mapa do chão (só copas: não se sombreiam a si próprios).
shader_type spatial;
render_mode unshaded, cull_back, world_vertex_coords;

#include "luz_floresta.gdshaderinc"
#include "recorte_vista.gdshaderinc"

uniform vec3 cor_musgo : source_color = vec3(0.40, 0.50, 0.23);
uniform float forca_musgo : hint_range(0.0, 1.0) = 0.8;
// 1 = o musgo segue a forma LISA (UV.x, pedras); 0 = segue a normal (troncos)
uniform float musgo_de : hint_range(0.0, 1.0) = 0.40;
uniform float musgo_liso : hint_range(0.0, 1.0) = 0.0;

varying vec3 v_pos;
varying vec3 v_n;

void vertex() {
	v_pos = VERTEX;
	v_n = NORMAL;
}

void fragment() {
	if (recorte_vista(VERTEX, INV_VIEW_MATRIX, CAMERA_POSITION_WORLD, FRAGCOORD.xy)) {
		discard;
	}
	vec3 n = normalize(v_n);
	float r = texture(ruido, (v_pos.xz + v_pos.y * vec2(0.7, 0.3)) * 0.42).r;
	float r2 = texture(ruido, (v_pos.xy + v_pos.z * vec2(0.4, 0.8)) * 1.3).r;
	vec3 alb = COLOR.rgb * (0.78 + 0.30 * r + 0.14 * r2);
	float cima = mix(n.y, UV.x * 0.75 + n.y * 0.25, musgo_liso);
	float musgo = smoothstep(musgo_de, musgo_de + 0.32, cima + (r - 0.5) * 0.7) * forca_musgo;
	alb = mix(alb, cor_musgo * (0.78 + 0.44 * r2), musgo);
	vec4 m = ler_mapa(v_pos.xz);
	float vis = smoothstep(0.30, 0.70, m.b + (r2 - 0.5) * 0.4);
	vec3 cor = luz_pintada(alb, n, vis);
	vec3 vw = normalize(CAMERA_POSITION_WORLD - v_pos);
	float orla = 1.0 - max(dot(n, vw), 0.0);
	cor += cor_sol * alb * orla * orla * orla * 0.35 * vis * smoothstep(-0.2, 0.4, dot(n, dir_luz));
	ALBEDO = cor * COLOR.a;
}
