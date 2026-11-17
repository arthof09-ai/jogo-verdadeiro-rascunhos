// haste.gdshader — Ordem 38 (defeito 6). As outras famílias de erva: espigas, flores e juncos
// (uma haste fina + uma cabeça). Geometria, sem alfa. O mesmo vento da relva (onda que viaja,
// fase só da posição) e somem com a distância (encolhem até zero, sem salto).
// UV.y = altura (0–1). UV.x: < 0,5 haste, ≥ 0,5 cabeça. COLOR (instância) = cor da cabeça.
// INSTANCE_CUSTOM = (r de ordem, —, tom, —).
shader_type spatial;
render_mode unshaded, cull_disabled, world_vertex_coords;

#include "luz_floresta.gdshaderinc"
#include "vento_floresta.gdshaderinc"
#include "rastro_relva.gdshaderinc"

uniform vec3 cor_haste : source_color = vec3(0.37, 0.44, 0.28);
// Ordem 43: o vento é o do MUNDO (vento_floresta.gdshaderinc).
uniform float vento_amplitude : hint_range(0.0, 0.8) = 0.42;
uniform float some_de = 34.0;
uniform float some_ate = 60.0;

// ORDEM 42 — a zona jogável do jogo (cenas/arena): a relva lá dentro está PISADA (baixa), para as
// casas, os destaques e o pé das figuras se lerem — e continua a mexer com o mesmo vento.
uniform vec4 campo_rect = vec4(0.0);   // (x0, z0, x1, z1) no mundo; vazia = nenhuma (o mapa sozinho)
uniform float campo_alto = 1.0;        // fracção da altura que a erva tem lá dentro
uniform float clima_neve = 0.0;
uniform float clima_aglomerado = 0.0;
uniform float clima_gelo = 0.0;
float no_campo(vec2 xz) {
	if (campo_rect.z <= campo_rect.x) {
		return 0.0;
	}
	vec2 fora = max(campo_rect.xy - xz, xz - campo_rect.zw);
	return 1.0 - smoothstep(-0.9, 0.6, max(fora.x, fora.y));
}

varying float v_alt;
varying float v_cabeca;
varying vec3 v_cor;
varying vec4 v_mapa;

void vertex() {
	v_alt = UV.y;
	v_cabeca = step(0.5, UV.x);
	vec3 raiz = MODEL_MATRIX[3].xyz;
	vec3 p = VERTEX;
	float d_cam = distance(raiz.xz, CAMERA_POSITION_WORLD.xz);
	float fica = 1.0 - smoothstep(some_de, some_ate, d_cam + INSTANCE_CUSTOM.r * 14.0);
	float cobertura_neve = clamp(clima_neve + 0.55 * clima_aglomerado, 0.0, 1.0);
	float encolhe = fica * mix(1.0, campo_alto, no_campo(raiz.xz)) * (1.0 - 0.84 * cobertura_neve);
	p = raiz + (p - raiz) * encolhe;
	// Ordem GRAMA: a haste também se deita com o rastro de quem passa (o jeito sai da altura dela, em metros)
	vec4 rastro = rastro_dobra(raiz.xz, length(MODEL_MATRIX[1].xyz) * 0.9 * encolhe);
	if (rastro.z != 0.0) {
		float h = p.y - raiz.y;
		float dobra_r = rastro.z * mix(0.45, 1.0, v_alt);
		p.xz += rastro.xy * sin(dobra_r) * h;
		p.y = raiz.y + h * cos(dobra_r);
	}
	vec2 dv = vento_dir;
	float dobra = vento_dobra(vento_local(raiz.xz));
	float fase = dot(raiz.xz, dv) * 0.24 - vento_fase * 1.35;
	float onda = 0.5 + 0.5 * sin(fase);
	float d = vento_amplitude * dobra * (0.46 + 0.54 * onda) * v_alt * v_alt;
	p.xz += dv * d;
	p.y -= d * d * 0.8;
	VERTEX = p;
	v_mapa = ler_mapa_lod(raiz.xz);
	v_cor = COLOR.rgb * (0.88 + 0.24 * INSTANCE_CUSTOM.b);
}

void fragment() {
	vec3 alb = mix(cor_haste * (0.7 + 0.5 * v_alt), v_cor, v_cabeca);
	float vis = smoothstep(0.30, 0.70, v_mapa.r);
	// a cabeça é palha ou pétala, não um espelho: luz contida e tecto de cor (defeito 5)
	vec3 cor = luz_pintada(alb, vec3(0.0, 1.0, 0.0), vis) * mix(1.0, 0.74, v_cabeca);
	cor = min(cor, vec3(0.90, 0.86, 0.74));
	float f_neve = clamp(clima_neve + 0.45 * clima_aglomerado + 0.35 * clima_gelo, 0.0, 1.0);
	if (f_neve > 0.001) {
		vec3 c_neve = luz_pintada(vec3(0.84, 0.89, 0.95), vec3(0.0, 1.0, 0.0), vis);
		cor = mix(cor, min(c_neve, vec3(0.90, 0.92, 0.95)), f_neve * mix(0.70, 0.96, v_alt));
	}
	ALBEDO = cor;
}
