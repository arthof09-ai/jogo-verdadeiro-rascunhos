// anel_perto.gdshader — Ordem 37. O ANEL PRÓXIMO: geometria pobre de propósito, uma só malha.
// Sem luz: a tinta (cor do vértice, sRGB) já traz a luz E o clarear da distância cozinhados.
// A névoa de profundidade do motor ainda cai por cima (faz a emenda com a orla real).
shader_type spatial;
render_mode unshaded, cull_disabled;

vec3 de_srgb(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void fragment() {
	ALBEDO = de_srgb(COLOR.rgb);
}
