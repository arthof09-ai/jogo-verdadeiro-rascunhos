// chuva_salpicos.gdshader — Ordem 40 (clima). O salpico que salta do chão onde a chuva bate: um cartão
// pequeno de pé, virado para a câmara, que nasce num sítio sorteado, abre, sobe e some. Tudo no shader
// (a CPU só manda o tempo e a caixa): cada instância tem a sua semente e o seu ritmo.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, skip_vertex_transform;

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
	float alt = max(mix(0.10, 0.24, forca) * (0.7 + 0.6 * h1(semente + ciclo)), px_minimo * 2.0 * m_por_px);
	float larg = alt * 1.5;
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
	ALBEDO = cor.rgb;
	ALPHA = a * cor.a * v_alpha * opacidade;
}
