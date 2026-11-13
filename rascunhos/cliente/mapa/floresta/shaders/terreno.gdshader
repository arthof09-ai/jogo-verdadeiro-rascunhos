// terreno.gdshader — Ordem 37. O chão da floresta: relva rente, terra, musgo e rocha nas rampas.
// A cor da relva rente casa com a base dos tufos (relva.gdshader) para a relva parecer cheia.
shader_type spatial;
render_mode unshaded, cull_back, world_vertex_coords;

#include "luz_floresta.gdshaderinc"

uniform vec3 cor_relva : source_color = vec3(0.30, 0.39, 0.16);
uniform vec3 cor_relva_seca : source_color = vec3(0.60, 0.56, 0.30);
uniform vec3 cor_terra : source_color = vec3(0.43, 0.35, 0.24);
uniform vec3 cor_musgo : source_color = vec3(0.36, 0.48, 0.20);
uniform vec3 cor_pedra : source_color = vec3(0.54, 0.53, 0.47);

varying vec3 v_pos;
varying vec3 v_n;

void vertex() {
	v_pos = VERTEX;
	v_n = NORMAL;
}

void fragment() {
	vec3 m = texture(mapa_chao, uv_mapa(v_pos.xz)).rgb;
	float r1 = texture(ruido, v_pos.xz * 0.021).r;
	float r2 = texture(ruido, v_pos.xz * 0.11 + 0.37).r;
	float r3 = texture(ruido, v_pos.xz * 0.53).r;
	vec3 relva = mix(cor_relva, cor_relva_seca, smoothstep(0.50, 0.85, r1) * 0.30);
	relva *= 0.84 + 0.32 * r2;
	float terra = smoothstep(0.35, 0.65, m.g + (r3 - 0.5) * 0.5);
	vec3 chao = mix(cor_terra * (0.78 + 0.44 * r3), cor_musgo, smoothstep(0.52, 0.80, r2) * 0.55);
	vec3 alb = mix(relva, chao, terra);
	vec3 n = normalize(v_n);
	float incl = 1.0 - n.y;
	// a rocha das rampas: camadas deitadas (estratos) em vez de grão miúdo — o grão lia-se
	// como chuvisco cinzento na escarpa do terraço — e musgo a entrar pelas manchas
	float estrato = texture(ruido, vec2((v_pos.x + v_pos.z) * 0.035, v_pos.y * 0.42 + r2 * 0.25)).r;
	vec3 pedra = cor_pedra * (0.74 + 0.40 * estrato + 0.08 * r3);
	pedra = mix(pedra, cor_musgo, smoothstep(0.48, 0.78, r2) * 0.50);
	alb = mix(alb, pedra, smoothstep(0.17, 0.30, incl + (r2 - 0.5) * 0.10));
	// a orla da sombra quebra-se em pinceladas (a luz coada pelas copas)
	float vis = smoothstep(0.30, 0.70, m.r + (texture(ruido, v_pos.xz * 0.9).r - 0.5) * 0.45);
	ALBEDO = luz_pintada(alb, n, vis);
}
