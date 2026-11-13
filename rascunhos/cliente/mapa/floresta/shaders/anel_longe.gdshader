// anel_longe.gdshader — Ordem 37. O ANEL LONGE e a árvore-âncora: silhuetas com TODO o ar já
// na tinta (cor do vértice). Fora da névoa do motor (fog_disabled): a névoa satura antes
// deste anel, e o que aqui se vê é a pintura — a base de cada silhueta é a cor do horizonte.
// O motor já lineariza a cor do vértice (provado por render: com outra conversão por cima a
// tinta escurecia e abria costura com a faixa baixa do céu).
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

void fragment() {
	ALBEDO = COLOR.rgb;
}
