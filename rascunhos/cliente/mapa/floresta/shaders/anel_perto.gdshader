// anel_perto.gdshader — Ordem 37. O ANEL PRÓXIMO: geometria pobre de propósito, uma só malha.
// Sem luz: a tinta (cor do vértice) já traz a luz E o clarear da distância cozinhados.
// A névoa de profundidade do motor ainda cai por cima (faz a emenda com a orla real).
// O motor já lineariza a cor do vértice (provado por render).
shader_type spatial;
render_mode unshaded, cull_disabled;

void fragment() {
	ALBEDO = COLOR.rgb;
}
