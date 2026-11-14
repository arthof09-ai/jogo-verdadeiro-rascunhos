// sobre_relevo.gdshader — Ordem 42. O que a arena desenha COLADO ao chão do mapa da floresta:
// as linhas da grelha, os destaques (mover / alvos), as casas a arder, o cursor e o pé das figuras.
//
// A malha já vem assente no relevo (cada vértice à altura Relevo.altura(x, z) + uns cm, a mesma
// altura única que a malha do chão desenha). Aqui só se resolve o que fica POR CIMA do chão: a
// relva (pisada, 0,2–0,35 m na zona jogável). Cada vértice é PUXADO para a câmara ao longo do
// próprio raio de vista (`puxar` metros): no ecrã fica exactamente no mesmo píxel, mas na
// profundidade passa à frente da erva — e uma subida a sério (mais do que `puxar`) continua a
// tapá-lo, como deve.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 cor : source_color = vec4(1.0);
uniform float puxar = 0.45;
uniform bool cor_da_instancia = false;

void vertex() {
	vec4 v = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	float d = length(v.xyz);
	v.xyz *= max(d - puxar, 0.05) / max(d, 0.0001);
	POSITION = PROJECTION_MATRIX * v;
}

void fragment() {
	vec4 c = cor;
	if (cor_da_instancia) {
		c *= COLOR;
	}
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
