// terreno.gdshader — Ordem 37/38. O chão da floresta: relva rente, folhada debaixo das copas,
// terra, musgo e rocha em estratos nas escarpas.
// A cor da relva rente casa com a base dos tufos (relva.gdshader) para a relva parecer cheia;
// e leva FIOS pintados (ruído esticado) para nunca se ler como chão liso entre tufos (defeito 7).
// Relevo legível (defeito 8): luz franca por vertente, sombra do relevo cozida (mapa R),
// oclusão no pé das vertentes (mapa A) e um toque de altitude (alto = claro e quente;
// cova = fresca e escura).
// Para lá da floresta rica o chão leva AR PINTADO: chega à orla da malha na cor do horizonte.
shader_type spatial;
render_mode unshaded, cull_back, world_vertex_coords;

#include "luz_floresta.gdshaderinc"

uniform vec3 cor_relva : source_color = vec3(0.40, 0.45, 0.24);
uniform vec3 cor_relva_seca : source_color = vec3(0.60, 0.56, 0.36);
uniform vec3 cor_floresta : source_color = vec3(0.30, 0.35, 0.23);
uniform vec3 cor_terra : source_color = vec3(0.48, 0.40, 0.29);
uniform vec3 cor_musgo : source_color = vec3(0.36, 0.44, 0.27);
uniform vec3 cor_pedra : source_color = vec3(0.56, 0.55, 0.51);
uniform vec3 cor_pedra_quente : source_color = vec3(0.64, 0.60, 0.53);
uniform vec3 cor_horizonte : source_color = vec3(0.84, 0.82, 0.67);
uniform float meio_arena = 37.5;
uniform float ar_de = 58.0;
uniform float ar_ate = 88.0;

varying vec3 v_pos;
varying vec3 v_n;

void vertex() {
	v_pos = VERTEX;
	v_n = NORMAL;
}

void fragment() {
	vec4 m = ler_mapa(v_pos.xz);
	float r1 = texture(ruido, v_pos.xz * 0.021).r;
	float r2 = texture(ruido, v_pos.xz * 0.11 + 0.37).r;
	float r3 = texture(ruido, v_pos.xz * 0.53).r;
	// fios de relva: ruído esticado em duas direcções cruzadas
	float fio = texture(ruido, vec2(v_pos.x * 1.9 + v_pos.z * 0.5, v_pos.z * 0.22 - v_pos.x * 0.06)).r;
	fio = fio * 0.6 + 0.4 * texture(ruido, vec2(v_pos.z * 2.3 - v_pos.x * 0.7, v_pos.x * 0.27 + 0.5)).r;
	vec3 relva = mix(cor_relva, cor_relva_seca, smoothstep(0.50, 0.85, r1) * 0.35);
	relva *= 0.78 + 0.22 * r2 + 0.24 * fio;
	// debaixo das copas a relva dá lugar à folhada
	float fora = max(abs(v_pos.x), abs(v_pos.z)) - meio_arena;
	float coberto = (1.0 - m.b) * smoothstep(-6.0, 6.0, fora);
	relva = mix(relva, cor_floresta * (0.82 + 0.36 * r3), clamp(coberto * 0.85 + smoothstep(20.0, 30.0, fora) * 0.6, 0.0, 0.92));
	float terra = smoothstep(0.35, 0.65, m.g + (r3 - 0.5) * 0.5);
	vec3 chao = mix(cor_terra * (0.80 + 0.40 * r3), cor_musgo, smoothstep(0.55, 0.82, r2) * 0.45);
	vec3 alb = mix(relva, chao, terra);
	vec3 n = normalize(v_n);
	float incl = 1.0 - n.y;
	// a rocha das escarpas: estratos deitados com 2 tons, musgo a entrar pelas manchas
	float estrato = texture(ruido, vec2((v_pos.x + v_pos.z) * 0.035, v_pos.y * 0.55 + r2 * 0.22)).r;
	float degrau = smoothstep(0.42, 0.58, fract(v_pos.y * 1.9 + r2 * 0.8));
	vec3 pedra = mix(cor_pedra, cor_pedra_quente, estrato) * (0.76 + 0.22 * degrau + 0.10 * r3);
	pedra = mix(pedra, cor_musgo, smoothstep(0.55, 0.85, r2) * 0.45 * smoothstep(0.75, 0.35, incl));
	alb = mix(alb, pedra, smoothstep(0.20, 0.34, incl + (r2 - 0.5) * 0.10));
	// altitude: o alto aclara e aquece, a cova arrefece (só dentro e à beira da arena)
	float alt = clamp(v_pos.y / 3.4, -1.0, 1.0) * smoothstep(14.0, 2.0, fora);
	alb *= mix(vec3(1.0), vec3(1.13, 1.10, 0.96), max(alt, 0.0));
	alb *= mix(vec3(1.0), vec3(0.80, 0.90, 0.97), max(-alt, 0.0));
	// a orla da sombra quebra-se em pinceladas (a luz coada pelas copas)
	float vis = smoothstep(0.30, 0.70, m.r + (texture(ruido, v_pos.xz * 0.9).r - 0.5) * 0.40);
	vec3 cor = luz_pintada(alb, n, vis) * mix(0.62, 1.0, m.a);
	ALBEDO = mix(cor, cor_horizonte, smoothstep(ar_de, ar_ate, fora));
}
