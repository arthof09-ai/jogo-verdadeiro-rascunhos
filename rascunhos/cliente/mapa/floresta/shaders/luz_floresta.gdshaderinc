// luz_floresta.gdshaderinc — Ordem 37/38. A LUZ PINTADA comum a tudo o que vive na arena.
//
// A luz do mapa é ESTÁTICA (o sol vive na pintura do céu), por isso é pintada, não simulada:
//   - materiais «unshaded» com a luz calculada aqui (1 passagem, sem passes de luz/sombra);
//   - as sombras das árvores, das pedras, dos marcos E DO RELEVO vêm COZIDAS no mapa do chão;
//   - sombra colorida, nunca preta (regra da casa).
// Canais do mapa do chão: R = sol que chega (tudo), G = terra à mostra, B = sol que chega
// contando só as copas (para troncos e pedras não se sombrearem a si próprios), A = oclusão
// de contacto (pé das vertentes, dos troncos e das pedras; 1 = aberto).
//
// Ordem 38 (defeito 8, relevo ilegível): a luz directa cresce até a face olhar o sol de frente
// (antes saturava cedo e o chão plano ficava tão claro como a vertente ao sol). Com o sol a
// 31°, o plano fica a meio tom, a vertente virada ao sol acende e a de costas cai em sombra —
// a altura lê-se sem medidor.

uniform vec3 dir_luz = vec3(-0.79, 0.52, 0.32);
uniform vec3 cor_sol : source_color = vec3(1.0, 0.90, 0.71);
uniform vec3 cor_sombra : source_color = vec3(0.32, 0.40, 0.54);
uniform vec3 cor_ceu : source_color = vec3(0.64, 0.71, 0.74);
uniform sampler2D mapa_chao : filter_linear, repeat_disable, hint_default_white;
uniform float mapa_meio = 72.0;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable, hint_default_white;

vec2 uv_mapa(vec2 xz) {
	return xz / (2.0 * mapa_meio) + 0.5;
}

// O mapa do chão; para lá da sua orla é «debaixo da floresta» (sombra coada, sem terra).
vec4 ler_mapa(vec2 xz) {
	vec2 uv = uv_mapa(xz);
	vec4 m = texture(mapa_chao, uv);
	float longe = smoothstep(0.455, 0.495, max(abs(uv.x - 0.5), abs(uv.y - 0.5)));
	return mix(m, vec4(0.30, 0.0, 0.34, 0.85), longe);
}

vec4 ler_mapa_lod(vec2 xz) {
	vec2 uv = uv_mapa(xz);
	vec4 m = textureLod(mapa_chao, uv, 0.0);
	float longe = smoothstep(0.455, 0.495, max(abs(uv.x - 0.5), abs(uv.y - 0.5)));
	return mix(m, vec4(0.30, 0.0, 0.34, 0.85), longe);
}

// A luz que a relva ao sol devolve para cima: aquece o que olha para baixo (copas por baixo,
// barrigas das pedras, troncos) — sem isto a sombra da floresta fica um buraco negro.
vec3 ressalto_chao(vec3 n) {
	return vec3(0.44, 0.45, 0.22) * 0.30 * clamp(0.5 - 0.5 * n.y, 0.0, 1.0);
}

vec3 luz_pintada(vec3 albedo, vec3 n, float vis) {
	float ndl = dot(n, dir_luz);
	float k = smoothstep(-0.10, 0.92, ndl) * vis;
	vec3 amb = cor_ceu * (0.30 + 0.20 * n.y) + ressalto_chao(n);
	vec3 direta = mix(cor_sombra * 0.40, cor_sol * 1.42, k);
	return albedo * (amb + direta);
}
