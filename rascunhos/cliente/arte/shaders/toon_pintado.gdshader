// toon_pintado.gdshader — Assimilação, missão V1.1 (Plano B v1.1, B2.1 e B2.2)
// Renderizador: Compatibility (WebGL 2 / GLES3). Não usa nada exclusivo do Forward+.
//
// Ideia: luz "pintada à mão" no estilo Arcane.
//  - A rampa por família (PNG 256x1, gerada por rampas/gerar_rampas.gd) dá a forma do terminador.
//  - A máscara de pincelada desloca a coordenada da rampa e a borda da sombra projetada,
//    para o terminador sair quebrado, como pincel, e não em degraus duros.
//  - Onde não há luz direta (lado de trás OU sombra projetada), a luz vira cor_sombra
//    (azul/roxo) multiplicada pela energia do sol. Nunca preto.
//  - Luz de contorno (rim) só da luz direcional, nos bordos virados para a luz.
//  - Especular mínimo (Blinn-Phong pequeno, quebrado pelo pincel).
//
// Requisitos do projeto:
//  - rendering/shading/overrides/force_vertex_shading = false
//    (com vertex shading a função light() não é executada — doc oficial, spatial shader).
//  - Só a DirectionalLight3D tem sombra (B2.2). Tochas (Omni/Spot) sem sombra.
//
// PROVISÓRIO: valores padrão das uniforms até ao guia V0.1. O color_script.gd escreve cor_sombra por hora.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// ---------- albedo ----------
uniform vec4 cor_albedo : source_color = vec4(1.0);
uniform sampler2D textura_albedo : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform vec2 escala_uv = vec2(1.0);

// ---------- rampa e pincel ----------
// A rampa é DADO (fator de mistura por canal), não cor: por isso sem source_color.
// Coordenada x = N·L remapeado para 0..1 (0,5 = terminador). 0 = sombra total, 1 = luz total.
uniform sampler2D rampa : filter_linear, repeat_disable, hint_default_white;
// Máscara de pincelada em tons de cinzento; 0,5 = neutro. Sem textura atribuída, use forca_pincel = 0.
uniform sampler2D pincel : filter_linear_mipmap, repeat_enable, hint_default_white;
uniform float escala_pincel = 4.0;
uniform float forca_pincel : hint_range(0.0, 1.0) = 0.25;

// ---------- sombra colorida ----------
// Fração colorida da luz do sol que sobra na sombra (azul ou roxo, nunca preto).
uniform vec3 cor_sombra : source_color = vec3(0.29, 0.35, 0.62);
// Largura da borda da sombra projetada (ATTENUATION), antes do pincel.
uniform float suavidade_sombra : hint_range(0.01, 0.5) = 0.12;
// Piso emissivo mínimo na cor da sombra: garante que nenhum píxel cai a preto (B3: L* >= 5).
uniform float piso_sombra : hint_range(0.0, 0.2) = 0.03;

// ---------- luz de contorno (rim) ----------
uniform vec3 cor_contorno_luz : source_color = vec3(1.0, 0.86, 0.66);
uniform float largura_rim : hint_range(0.0, 1.0) = 0.28;
uniform float suavidade_rim : hint_range(0.01, 0.5) = 0.08;
uniform float forca_rim : hint_range(0.0, 4.0) = 0.9;

// ---------- especular mínimo e PBR residual ----------
uniform float especular : hint_range(0.0, 1.0) = 0.06;
uniform float brilho : hint_range(4.0, 256.0) = 48.0;
uniform float rugosidade : hint_range(0.0, 1.0) = 0.85;
// Atenção: o motor reduz a difusa por (1 - METALLIC). Para "metal pintado", use a rampa da
// família metal e mantenha metalico <= 0,3, senão a sombra colorida some.
uniform float metalico : hint_range(0.0, 1.0) = 0.0;
// Reflexo do céu (radiance). 0 desliga reflexos.
uniform float reflexo_ambiente : hint_range(0.0, 1.0) = 0.15;

// fragment -> light (permitido pela doc: "send data from fragment to light processors using varying")
varying float v_pincel;

float luminancia(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec4 tex = texture(textura_albedo, UV * escala_uv);
	vec3 alb = tex.rgb * cor_albedo.rgb;
	ALBEDO = alb;
	ROUGHNESS = rugosidade;
	METALLIC = metalico;
	SPECULAR = reflexo_ambiente * 0.5;
	v_pincel = texture(pincel, UV * escala_pincel).r - 0.5;
	EMISSION = alb * cor_sombra * piso_sombra;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float quebra = v_pincel * forca_pincel;
	float x = clamp(ndl * 0.5 + 0.5 + quebra, 0.0, 1.0);
	vec3 k = texture(rampa, vec2(x, 0.5)).rgb;
	// LIGHT_COLOR = cor * energia * PI (doc). Dividir por PI mantém a energia do Lambert do motor.
	vec3 luz = LIGHT_COLOR / PI;

	if (LIGHT_IS_DIRECTIONAL) {
		// Na direcional, ATTENUATION é só a sombra projetada (1 = iluminado).
		float s = smoothstep(0.5 - suavidade_sombra, 0.5 + suavidade_sombra, ATTENUATION + quebra);
		vec3 k_total = k * s;
		float energia = luminancia(luz);
		vec3 preenchimento = cor_sombra * energia;
		DIFFUSE_LIGHT += mix(preenchimento, luz, k_total);

		// Luz de contorno: fresnel, só nos bordos virados para a luz, mais forte em contraluz.
		float fres = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float ini = 1.0 - largura_rim;
		float rim = smoothstep(ini, ini + suavidade_rim, fres + quebra * 0.5);
		float virado = smoothstep(-0.25, 0.35, ndl);
		float contraluz = mix(0.6, 1.0, clamp(-dot(VIEW, LIGHT) * 0.5 + 0.5, 0.0, 1.0));
		SPECULAR_LIGHT += cor_contorno_luz * (rim * virado * contraluz * s * forca_rim * energia);

		// Especular mínimo, recortado e quebrado pelo pincel.
		vec3 h = normalize(LIGHT + VIEW);
		float sp = pow(max(dot(NORMAL, h), 0.0), brilho);
		sp = smoothstep(0.35, 0.65, sp + quebra);
		SPECULAR_LIGHT += luz * (sp * especular * s);
	} else {
		// Omni/Spot (tochas, sem sombra): ATTENUATION = queda por distância. Sem tinta de sombra,
		// para não pintar de azul onde a tocha não chega.
		DIFFUSE_LIGHT += luz * k * ATTENUATION;
		vec3 h = normalize(LIGHT + VIEW);
		float sp = pow(max(dot(NORMAL, h), 0.0), brilho);
		sp = smoothstep(0.35, 0.65, sp + quebra);
		SPECULAR_LIGHT += luz * (sp * especular * ATTENUATION);
	}
}
