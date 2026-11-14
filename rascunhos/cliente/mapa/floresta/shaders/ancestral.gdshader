// ancestral.gdshader — Ordem 38 (defeito 2). A ÁRVORE ANCESTRAL: o marco do mapa.
// Deixou de ser um fantasma: é opaca, tem cor própria (casca clara com musgo, folha verde-ouro,
// telha de ardósia, janelas de ouro acesas) e a MESMA luz do resto do mapa (dir_luz).
// O ar entra pouco e só para dar a distância: mais na base (a bruma do vale), quase nada na copa.
// Fora da névoa do motor (fog_disabled): o ar dela é pintado aqui, com a cor do horizonte.
// COLOR.rgb = tinta · COLOR.a = sol que chega (sombra da copa e oclusão, cozidas no vértice)
// UV.x = matéria: 0 madeira · 1 folha · 2 construção · 3 luz própria (janelas)
shader_type spatial;
render_mode unshaded, cull_back, fog_disabled;

uniform vec3 dir_luz = vec3(-0.79, 0.52, 0.32);
uniform vec3 cor_sol : source_color = vec3(1.0, 0.90, 0.71);
uniform vec3 cor_sombra : source_color = vec3(0.32, 0.40, 0.54);
uniform vec3 cor_ceu : source_color = vec3(0.64, 0.71, 0.74);
uniform vec3 cor_horizonte : source_color = vec3(0.84, 0.82, 0.67);
uniform vec3 cor_musgo : source_color = vec3(0.37, 0.48, 0.21);
uniform vec3 cor_folha_luz : source_color = vec3(0.53, 0.64, 0.24);
uniform sampler2D ruido : filter_linear_mipmap, repeat_enable, hint_default_white;
uniform float altura = 260.0;
uniform float ar_topo : hint_range(0.0, 1.0) = 0.10;
uniform float ar_base : hint_range(0.0, 1.0) = 0.34;

varying vec3 v_loc;
varying vec3 v_n;

void vertex() {
	v_loc = VERTEX;
	v_n = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	vec3 n = normalize(v_n);
	float h = v_loc.y / altura;
	// as pinceladas medem-se em fracções da árvore (q = metros de uma árvore de 130 m)
	vec3 q = v_loc * (130.0 / altura);
	float r1 = texture(ruido, q.xz * 0.011 + q.y * 0.007).r;
	float r2 = texture(ruido, q.xy * 0.045 + q.z * 0.031).r;
	float sol = COLOR.a;
	vec3 alb = COLOR.rgb;
	float ndl = dot(n, dir_luz);
	vec3 cor;
	if (UV.x > 2.5) {
		// janelas acesas: luz própria, quente
		cor = alb * (0.92 + 0.22 * r2);
	} else {
		if (UV.x < 0.5) {
			// casca: veios ao alto, e musgo onde a casca olha para cima e nas manchas
			float veio = texture(ruido, vec2((q.x + q.z) * 0.060, q.y * 0.006)).r;
			alb *= 0.74 + 0.34 * veio + 0.16 * r2;
			float musgo = smoothstep(0.50, 0.78, r1 * 0.75 + max(n.y, 0.0) * 0.55 + (1.0 - smoothstep(0.0, 0.35, h)) * 0.10);
			alb = mix(alb, cor_musgo * (0.75 + 0.5 * r2), musgo * 0.72);
			ndl += (veio - 0.5) * 0.35;
		} else if (UV.x < 1.5) {
			// folha: pincelada que parte a luz em toques; o tom alto é verde-ouro; a barriga
			// das almofadas é funda (é ela que dá o volume à cúpula)
			float pinc = r1 * 0.5 + r2 * 0.5;
			float r3 = texture(ruido, q.xz * 0.16 + q.y * 0.11).r;
			ndl += (pinc - 0.5) * 0.9 + (r3 - 0.5) * 0.5;
			alb *= 0.74 + 0.36 * r2 + 0.16 * r3;
			alb = mix(alb, cor_folha_luz, smoothstep(0.30, 0.85, ndl) * 0.60 * sol);
			// o cimo de cada almofada apanha o céu: tom alto mesmo do lado de lá do sol
			alb = mix(alb, cor_folha_luz, smoothstep(0.45, 0.95, n.y) * 0.30 * sol);
			alb *= mix(0.50, 0.92, smoothstep(-0.35, 0.35, n.y));
		} else {
			alb *= 0.88 + 0.24 * r2;
		}
		float k = (smoothstep(-0.25, 0.10, ndl) * 0.45 + smoothstep(0.10, 0.80, ndl) * 0.55) * sol;
		vec3 amb = cor_ceu * (0.34 + 0.18 * n.y) + vec3(0.40, 0.44, 0.22) * 0.20 * clamp(0.5 - 0.5 * n.y, 0.0, 1.0);
		amb *= mix(0.62, 1.0, sol);   // onde o sol não chega, o céu também chega menos
		cor = alb * (amb + mix(cor_sombra * 0.42, cor_sol * 1.30, k));
	}
	float ar = mix(ar_base, ar_topo, smoothstep(0.0, 0.42, h));
	ALBEDO = mix(cor, cor_horizonte, ar);
}
