// luz_floresta.gdshaderinc — Ordem 37. A LUZ PINTADA comum a tudo o que vive na arena.
//
// A luz do mapa é ESTÁTICA (o sol vive na pintura do céu), por isso é pintada, não simulada:
//   - materiais «unshaded» com a luz calculada aqui (1 passagem, sem passes de luz/sombra);
//   - as sombras das árvores e das pedras vêm COZIDAS no mapa do chão (canal R), gerado na carga;
//   - sombra colorida, nunca preta (regra da casa).
// Canais do mapa do chão: R = sol que chega (árvores + pedras), G = terra à mostra,
// B = sol que chega contando só as copas (para troncos e pedras não se sombrearem a si próprios).

uniform vec3 dir_luz = vec3(-0.46, 0.56, -0.69);
uniform vec3 cor_sol : source_color = vec3(1.0, 0.89, 0.66);
uniform vec3 cor_sombra : source_color = vec3(0.35, 0.44, 0.55);
uniform vec3 cor_ceu : source_color = vec3(0.66, 0.73, 0.56);
uniform sampler2D mapa_chao : filter_linear, repeat_disable, hint_default_white;
uniform float mapa_meio = 66.0;
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable, hint_default_white;

vec2 uv_mapa(vec2 xz) {
	return xz / (2.0 * mapa_meio) + 0.5;
}

// A luz que a relva ao sol devolve para cima: aquece o que olha para baixo (copas por baixo,
// barrigas das pedras, troncos) — sem isto a sombra da floresta fica um buraco negro.
vec3 ressalto_chao(vec3 n) {
	return vec3(0.46, 0.48, 0.17) * 0.30 * clamp(0.5 - 0.5 * n.y, 0.0, 1.0);
}

vec3 luz_pintada(vec3 albedo, vec3 n, float vis) {
	float ndl = dot(n, dir_luz);
	float k = smoothstep(-0.15, 0.55, ndl) * vis;
	vec3 amb = cor_ceu * (0.30 + 0.20 * n.y) + ressalto_chao(n);
	vec3 direta = mix(cor_sombra * 0.42, cor_sol, k);
	return albedo * (amb + direta);
}
