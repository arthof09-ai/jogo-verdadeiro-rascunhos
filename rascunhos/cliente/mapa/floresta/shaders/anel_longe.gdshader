// anel_longe.gdshader — Ordem 37. O ANEL LONGE e a árvore-âncora: silhuetas com TODO o ar já
// na tinta (cor do vértice). Fora da névoa do motor (fog_disabled): a névoa satura antes
// deste anel, e o que aqui se vê é a pintura — a base de cada silhueta é a cor do horizonte.
// O motor já lineariza a cor do vértice (provado por render: com outra conversão por cima a
// tinta escurecia e abria costura com a faixa baixa do céu).
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;

// Ordem 43 (ciclo do dia): a tinta foi cozida para o ar da tarde (COR_HORIZONTE da paleta).
// `grau` = horizonte de agora ÷ horizonte da paleta (em luz): a base de cada silhueta continua
// a ser EXACTAMENTE a cor do horizonte (a da névoa e da faixa baixa do céu) a todas as horas.
uniform vec3 grau = vec3(1.0);

void fragment() {
	ALBEDO = COLOR.rgb * grau;
}
