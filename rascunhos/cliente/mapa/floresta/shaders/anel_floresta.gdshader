// anel_floresta.gdshader — Ordem 38 (defeito 1). A FLORESTA DO ANEL: as árvores para lá da orla
// rica. Deixaram de ser troncos-impostores: são árvores inteiras (pé no chão, tronco, copa), das
// MESMAS famílias da orla, só com menos malha — e pintadas com a MESMA conta de luz das árvores
// reais (copa.gdshader e solido.gdshader), por isso não há costura entre a orla e o anel.
// Tronco e copa vão na MESMA malha (1 chamada de desenho por quadrante):
//   UV.x ≥ 1,5 marca TRONCO (sem vento); senão é copa e UV = (fase do vento, peso do vento).
// COLOR.rgb = tinta; COLOR.a = oclusão cozida. O ar da distância é a névoa do motor.
shader_type spatial;
render_mode unshaded, cull_back, world_vertex_coords;

#include "luz_floresta.gdshaderinc"
#include "vento_floresta.gdshaderinc"

uniform vec3 cor_ouro : source_color = vec3(0.66, 0.61, 0.34);
uniform vec3 cor_musgo : source_color = vec3(0.37, 0.45, 0.27);
// Ordem 43: o vento é o do MUNDO (vento_floresta.gdshaderinc).
uniform float vento_amplitude : hint_range(0.0, 1.5) = 0.20;

varying vec3 v_pos;
varying vec3 v_n;
varying float v_tronco;

void vertex() {
	v_tronco = step(1.5, UV.x);
	float peso = UV.y * (1.0 - v_tronco);
	vec2 dv = vento_dir;
	float empurra = vento_dobra(vento_local(VERTEX.xz)) * 2.0 * vento_amplitude;
	float fase = UV.x * 6.2832 + dot(VERTEX.xz, dv) * 0.12;
	float balanco = sin(vento_fase * 0.9 + fase) * 0.6 + sin(vento_fase * 0.37 + fase * 1.7) * 0.4;
	VERTEX.xz += dv * (0.40 + 0.80 * balanco) * empurra * peso;
	v_pos = VERTEX;
	v_n = NORMAL;
}

void fragment() {
	vec3 n = normalize(v_n);
	float r = texture(ruido, v_pos.xz * 0.33 + v_pos.y * 0.21).r;
	float r2 = texture(ruido, v_pos.xy * 0.85 + v_pos.z * 0.6).r;
	vec3 cor;
	if (v_tronco > 0.5) {
		// tronco: debaixo das copas (o mapa do chão diz quanto sol lá chega), musgo do lado de cima
		vec3 alb = COLOR.rgb * (0.78 + 0.30 * r + 0.14 * r2);
		alb = mix(alb, cor_musgo * (0.78 + 0.44 * r2), smoothstep(0.45, 0.80, n.y + (r - 0.5) * 0.7) * 0.45);
		float vis = smoothstep(0.30, 0.70, ler_mapa(v_pos.xz).b + (r2 - 0.5) * 0.4);
		cor = luz_pintada(alb, n, vis);
	} else {
		float pinc = r * 0.55 + r2 * 0.45;
		float ndl = dot(n, dir_luz) + (pinc - 0.5) * 0.75;
		float k = smoothstep(-0.20, 0.10, ndl) * 0.5 + smoothstep(0.28, 0.58, ndl) * 0.5;
		float ao = COLOR.a;
		vec3 alb = COLOR.rgb * (0.82 + 0.36 * r);
		vec3 amb = cor_ceu * (0.26 + 0.20 * n.y) + ressalto_chao(n) * 1.25;
		cor = alb * (amb + mix(cor_sombra * 0.45, cor_sol, k * ao));
		cor = mix(cor, cor_ouro * cor_sol * 1.15, smoothstep(0.62, 0.85, ndl) * 0.26 * ao);
		cor = olho_noite(cor * mix(0.72, 1.0, ao));
	}
	ALBEDO = cor;
}
