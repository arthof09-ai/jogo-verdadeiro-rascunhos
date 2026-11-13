// anel_longe.gdshader — Ordem 37. O ANEL LONGE e a árvore-âncora: silhuetas com TODO o ar já
// na tinta (cor do vértice, sRGB). Fora da névoa do motor (fog_disabled): a névoa satura antes
// deste anel, e o que aqui se vê é a pintura — a base de cada silhueta é a cor do horizonte.
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

vec3 de_srgb(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void fragment() {
	ALBEDO = COLOR.rgb;
}
