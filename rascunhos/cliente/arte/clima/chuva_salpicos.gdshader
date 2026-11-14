// chuva_salpicos.gdshader — Ordem 40 (clima). O salpico que salta do chão onde a chuva bate: um cartão
// pequeno de pé, virado para a câmara, que nasce num sítio sorteado, abre, sobe e some. Tudo no shader
// (a CPU só manda o tempo e a caixa): cada instância tem a sua semente e o seu ritmo.
//
// Ordem 41: o salpico sabe onde cai. Em chão seco/molhado são duas gotículas que saltam; dentro de uma BOLSA
// (clima_terreno.gdshaderinc) é um salpico de ÁGUA — a coroa que abre larga e baixa, com o jacto ao centro.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;

#include "res://arte/clima/clima_terreno.gdshaderinc"

uniform float agua = 0.0;
uniform vec3 caixa_min = vec3(0.0);
uniform vec3 caixa_tam = vec3(30.0, 12.0, 30.0);
uniform float chao_y = 0.0;
uniform float tempo = 0.0;
// 0..1: a força do bater (altura e abertura do salpico).
uniform float forca = 0.6;
uniform float opacidade = 1.0;
uniform vec4 cor : source_color = vec4(0.90, 0.94, 1.0, 0.75);
uniform float px_minimo = 2.5;

varying float v_fase;
varying float v_alpha;
varying float v_na_agua;

float h1(float n) { return fract(sin(n * 127.1) * 43758.5453); }

void vertex() {
	float semente = INSTANCE_CUSTOM.x;
	float periodo = mix(0.32, 0.55, h1(semente + 0.5));
	float fase = tempo / periodo + h1(semente + 3.7);
	float ciclo = floor(fase);
	v_fase = fract(fase);
	vec2 onde = vec2(h1(semente * 1.3 + ciclo * 0.731), h1(semente * 2.1 + ciclo * 1.193 + 9.0));
	vec3 mundo = vec3(caixa_min.x + onde.x * caixa_tam.x, chao_y, caixa_min.z + onde.y * caixa_tam.z);
	vec4 vista = VIEW_MATRIX * vec4(mundo, 1.0);
	float dist = max(-vista.z, 0.001);
	float m_por_px = 2.0 * dist / (PROJECTION_MATRIX[1][1] * VIEWPORT_SIZE.y);
	// Cai numa bolsa? (a mesma conta do chão)
	v_na_agua = 0.0;
	if (agua > 0.001 && n_bacias > 0) {
		v_na_agua = step(0.004, clima_fundura(mundo.xz, 0.0, agua * CLIMA_ENCHE, 0.0));
	}
	float alt = max(mix(0.10, 0.24, forca) * (0.7 + 0.6 * h1(semente + ciclo)), px_minimo * 2.0 * m_por_px);
	// Na água a coroa é mais larga do que alta.
	alt *= mix(1.0, 1.25, v_na_agua);
	float larg = alt * mix(1.5, 2.3, v_na_agua);
	// De pé no mundo (eixo Y), de frente para a câmara.
	vec3 cima = (VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz;
	vec3 lado = normalize(cross(cima, vec3(0.0, 0.0, 1.0)) + vec3(1e-5, 0.0, 0.0));
	VERTEX = vista.xyz + lado * (VERTEX.x * larg) + cima * ((VERTEX.y + 0.5) * alt);
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_alpha = smoothstep(0.8, 2.5, dist);
}

void fragment() {
	// q.x em −1..1; q.y de 0 (chão) a 1 (topo).
	vec2 q = vec2(UV.x * 2.0 - 1.0, 1.0 - UV.y);
	float f = v_fase;
	// Duas gotículas que abrem para os lados em parábola, mais um jacto curto ao centro no início.
	float h = 4.0 * f * (1.0 - f) * 0.8;
	float abre = 0.15 + 0.7 * f;
	float gota = exp(-(pow(abs(q.x) - abre, 2.0) / 0.012 + pow(q.y - h, 2.0) / 0.012));
	float jacto = exp(-(q.x * q.x / 0.01)) * smoothstep(0.9 * (1.0 - f), 0.0, q.y) * smoothstep(0.45, 0.0, f);
	float a = clamp(gota + jacto, 0.0, 1.0) * (1.0 - f * f);
	if (v_na_agua > 0.5) {
		// A coroa: uma parede fina de água que abre para fora e desce, com gotas na crista; depois o jacto
		// do centro (a água que volta a subir). Lê-se como água a bater em água, não como pó a saltar.
		float raio = 0.18 + 0.62 * f;
		float topo = 0.55 * (1.0 - f) * (1.0 - f) + 0.10;
		float parede = exp(-pow(abs(q.x) - raio, 2.0) / 0.004) * smoothstep(topo, topo * 0.2, q.y);
		float crista = exp(-(pow(abs(q.x) - raio, 2.0) / 0.006 + pow(q.y - topo, 2.0) / 0.006));
		float arco = exp(-pow(q.y - topo * (1.0 - q.x * q.x / max(raio * raio, 0.01)), 2.0) / 0.003) * step(abs(q.x), raio);
		float volta = exp(-(q.x * q.x / 0.006)) * smoothstep(0.75 * sin(3.14159 * clamp((f - 0.35) / 0.65, 0.0, 1.0)), 0.0, q.y) * step(0.35, f);
		a = clamp(0.7 * parede + crista + 0.35 * arco + 0.8 * volta, 0.0, 1.0) * (1.0 - f * f * f);
	}
	ALBEDO = cor.rgb;
	ALPHA = a * cor.a * v_alpha * opacidade;
}
