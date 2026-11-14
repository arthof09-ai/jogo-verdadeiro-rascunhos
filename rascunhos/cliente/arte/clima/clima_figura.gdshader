// clima_figura.gdshader — Ordem 40 (clima). A RESPOSTA DAS FIGURAS, como material_overlay: desenha-se por
// cima da figura (marcador, cápsula ou GLB), sem tocar no material dela.
//
//   molhado (0..1): a figura escurece um pouco e ganha brilho — reflexo do céu no contorno e do sol nas faces;
//   neve (0..1):    neve em cima — começa no topo (cabeça) e desce pelas faces viradas para cima; a camada
//                   sobe uns centímetros, para a neve ter corpo. Só visual: não muda altura nenhuma do jogo.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled, world_vertex_coords;

uniform float molhado : hint_range(0.0, 1.0) = 0.0;
uniform float neve : hint_range(0.0, 1.0) = 0.0;
uniform vec3 luz_dir = vec3(0.4, 0.8, 0.45);
uniform vec3 luz_cor : source_color = vec3(1.0, 0.95, 0.85);
uniform vec3 cor_reflexo : source_color = vec3(0.72, 0.80, 0.88);
uniform vec3 cor_neve : source_color = vec3(0.93, 0.96, 0.99);
uniform vec3 cor_neve_sombra : source_color = vec3(0.72, 0.80, 0.91);
// Quanto a camada de neve sobe com a neve = 1 (m).
uniform float espessura_m = 0.05;

varying vec3 v_mundo;
varying vec3 v_normal;

void vertex() {
	// world_vertex_coords: VERTEX e NORMAL já estão no mundo.
	v_normal = NORMAL;
	VERTEX.y += espessura_m * neve * smoothstep(0.0, 0.6, NORMAL.y);
	v_mundo = VERTEX;
}

void fragment() {
	vec3 N = normalize(v_normal);
	vec3 V = normalize(CAMERA_POSITION_WORLD - v_mundo);
	float nv = clamp(dot(N, V), 0.0, 1.0);

	vec3 brilho = vec3(0.0);
	float a_molhado = 0.0;
	if (molhado > 0.001) {
		float raspao = pow(1.0 - nv, 3.0);
		vec3 R = reflect(-V, N);
		vec3 ceu = cor_reflexo * mix(1.1, 0.8, clamp(R.y, 0.0, 1.0));
		float sol = pow(max(dot(R, normalize(luz_dir)), 0.0), 28.0);
		// Um reflexo largo do céu nas faces viradas para cima (pedra molhada).
		float topo = smoothstep(0.1, 0.9, N.y) * 0.22;
		float lustro = pow(max(dot(R, normalize(luz_dir)), 0.0), 5.0) * 0.35;
		brilho = (ceu * (0.12 + 0.70 * raspao + topo) + luz_cor * (sol * 0.8 + lustro)) * molhado;
		a_molhado = clamp(max(molhado * 0.32, max(brilho.r, max(brilho.g, brilho.b))), 0.0, 1.0);
		brilho = min(brilho, vec3(a_molhado));
	}

	float a_neve = 0.0;
	vec3 c_neve = cor_neve;
	if (neve > 0.001) {
		// A linha da neve desce: primeiro só o topo, depois tudo o que olha para cima.
		float limiar = mix(0.97, 0.22, neve);
		a_neve = smoothstep(limiar, limiar + 0.10, N.y) * min(neve * 10.0, 1.0) * 0.97;
		float luz = 0.78 + 0.22 * clamp(dot(N, normalize(luz_dir)), 0.0, 1.0);
		c_neve = mix(cor_neve_sombra, cor_neve, smoothstep(0.3, 0.95, N.y)) * luz;
	}

	vec3 pre = brilho * (1.0 - a_neve) + c_neve * a_neve;
	float a = a_neve + a_molhado * (1.0 - a_neve);
	ALBEDO = pre / max(a, 1e-4);
	ALPHA = a;
}
