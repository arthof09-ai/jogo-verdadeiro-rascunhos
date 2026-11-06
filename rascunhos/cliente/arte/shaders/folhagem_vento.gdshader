// folhagem_vento.gdshader — Assimilação, missão V1.1 (Plano B v1.1, B2.1 item 4 e B2.2 "Folhagem")
// Renderizador: Compatibility.
//
// - Alpha scissor (pipeline opaco, projeta sombra). usar_alpha_hash = true troca por dither
//   estocástico (Alpha Hash) para copas altas que tapam figuras; opacidade_dither (por instância)
//   faz o desvanecimento.
//   NOTA: a doc oficial diz que o Compatibility tem MSAA 3D "but no alpha to coverage";
//   por isso este shader NÃO usa alpha_to_coverage (ver README, divergência com a B2.2).
// - Vento no vértice: balanço (soma de senos) + rajada (ruído de valor) + tremor da folha.
//   Peso: cor do vértice R (base 0, ponta 1) ou UV.y. Malha sem cor de vértice lê branco = tudo mexe.
// - Normais "de volume": a normal é puxada para a esfera em volta de centro_copa (espaço do modelo),
//   para a luz cair na copa como numa massa pintada, e não folha a folha.
// - Sombra colorida igual à do toon_pintado (mesma rampa, pincel e cor_sombra) + translucidez.
//
// PROVISÓRIO: valores de vento, cor e translucidez até ao guia V0.1.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// ---------- albedo e alpha ----------
uniform vec4 cor_albedo : source_color = vec4(1.0);
uniform sampler2D textura_albedo : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform float limiar_alpha : hint_range(0.0, 1.0) = 0.5;
uniform bool usar_alpha_hash = false;
// Por instância (GeometryInstance3D.set_instance_shader_parameter). 1 = opaco. Só tem efeito com hash.
instance uniform float opacidade_dither : hint_range(0.0, 1.0) = 1.0;
// Variação de cor por árvore (hash da posição da instância).
uniform vec3 cor_variacao : source_color = vec3(0.85, 0.95, 0.7);
uniform float variacao : hint_range(0.0, 1.0) = 0.35;

// ---------- vento ----------
uniform vec2 direcao_vento = vec2(1.0, 0.35);
uniform float forca_vento : hint_range(0.0, 2.0) = 0.25;     // metros na ponta (peso 1)
uniform float velocidade_vento : hint_range(0.0, 5.0) = 1.1;
uniform float frequencia_espacial : hint_range(0.0, 1.0) = 0.12; // defasagem entre árvores
uniform float forca_rajada : hint_range(0.0, 2.0) = 0.6;
uniform float tremor_folha : hint_range(0.0, 0.2) = 0.03;
// 0 = COLOR.r ; 1 = UV.y ; 2 = 1 - UV.y
uniform int fonte_peso : hint_range(0, 2) = 0;

// ---------- normais de volume ----------
uniform vec3 centro_copa = vec3(0.0, 8.0, 0.0);
uniform float forca_volume : hint_range(0.0, 1.0) = 0.85;

// ---------- luz (igual ao toon_pintado) ----------
uniform sampler2D rampa : filter_linear, repeat_disable, hint_default_white;
uniform sampler2D pincel : filter_linear_mipmap, repeat_enable, hint_default_white;
uniform float escala_pincel = 3.0;
uniform float forca_pincel : hint_range(0.0, 1.0) = 0.3;
uniform vec3 cor_sombra : source_color = vec3(0.29, 0.35, 0.62);
uniform float suavidade_sombra : hint_range(0.01, 0.5) = 0.15;
uniform float piso_sombra : hint_range(0.0, 0.2) = 0.03;
uniform vec3 cor_translucidez : source_color = vec3(0.75, 0.9, 0.35);
uniform float translucidez : hint_range(0.0, 1.0) = 0.35;

varying vec3 v_normal_vista;
varying float v_var;
varying float v_pincel;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

// ruído de valor 1D, saída -1..1
float ruido1(float x) {
	float i = floor(x);
	float f = fract(x);
	float u = f * f * (3.0 - 2.0 * f);
	return mix(hash11(i), hash11(i + 1.0), u) * 2.0 - 1.0;
}

// Interleaved gradient noise (ecrã) para o alpha hash.
float ruido_ecra(vec2 p) {
	return fract(52.9829189 * fract(dot(p, vec2(0.06711056, 0.00583715))));
}

float luminancia(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void vertex() {
	float peso;
	if (fonte_peso == 0) {
		peso = COLOR.r;
	} else if (fonte_peso == 1) {
		peso = UV.y;
	} else {
		peso = 1.0 - UV.y;
	}
	peso = clamp(peso, 0.0, 1.0);
	peso *= peso; // base presa, ponta solta

	// Normal de volume (antes do deslocamento).
	vec3 n_esfera = normalize(VERTEX - centro_copa + vec3(0.0, 0.0001, 0.0));
	vec3 n = normalize(mix(NORMAL, n_esfera, forca_volume));
	NORMAL = n;
	v_normal_vista = normalize(MODELVIEW_NORMAL_MATRIX * n);

	// MODEL_MATRIX é por instância também em MultiMesh.
	vec3 origem = MODEL_MATRIX[3].xyz;
	vec3 pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_var = hash11(dot(origem, vec3(1.0, 7.0, 13.0)));

	vec2 dir = normalize(direcao_vento + vec2(0.0001));
	float fase = dot(origem.xz, dir) * frequencia_espacial + v_var * 6.2831;
	float t = TIME * velocidade_vento;
	float balanco = sin(t + fase) * 0.6 + sin(t * 0.37 + fase * 1.7) * 0.4;
	float rajada = ruido1(t * 0.25 + fase * 0.5) * 0.5 + 0.5; // 0..1
	float onda = balanco * (1.0 + forca_rajada * rajada) + forca_rajada * rajada * 0.5; // inclina a favor do vento
	float tremor = sin(t * 6.0 + dot(pos_mundo, vec3(1.7, 2.3, 1.3)) * 3.0) * tremor_folha;

	vec3 desloc_mundo = vec3(dir.x, 0.0, dir.y) * (onda * forca_vento + tremor) * peso;
	desloc_mundo.y += tremor * peso;

	// Mundo -> modelo (rotação + escala uniforme): M^-1 d = (M^T d) / s^2.
	float s = max(length(MODEL_MATRIX[0].xyz), 0.0001);
	VERTEX += (vec4(desloc_mundo, 0.0) * MODEL_MATRIX).xyz / (s * s);
}

void fragment() {
	vec4 tex = texture(textura_albedo, UV);
	vec3 alb = tex.rgb * cor_albedo.rgb;
	alb *= mix(vec3(1.0), cor_variacao, v_var * variacao);
	ALBEDO = alb;

	float a = tex.a * cor_albedo.a;
	if (usar_alpha_hash && !IN_SHADOW_PASS) {
		a = step(ruido_ecra(FRAGCOORD.xy), a * opacidade_dither);
	}
	ALPHA = a;
	ALPHA_SCISSOR_THRESHOLD = usar_alpha_hash ? 0.5 : limiar_alpha;

	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
	// Normal de volume, ignorando a viragem automática da face de trás (cull_disabled).
	NORMAL = normalize(v_normal_vista);
	v_pincel = texture(pincel, UV * escala_pincel).r - 0.5;
	EMISSION = alb * cor_sombra * piso_sombra;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float quebra = v_pincel * forca_pincel;
	float x = clamp(ndl * 0.5 + 0.5 + quebra, 0.0, 1.0);
	vec3 k = texture(rampa, vec2(x, 0.5)).rgb;
	vec3 luz = LIGHT_COLOR / PI;

	if (LIGHT_IS_DIRECTIONAL) {
		float s = smoothstep(0.5 - suavidade_sombra, 0.5 + suavidade_sombra, ATTENUATION + quebra);
		float energia = luminancia(luz);
		DIFFUSE_LIGHT += mix(cor_sombra * energia, luz, k * s);
		// Translucidez: sol atrás da folha, em relação à câmara.
		float tr = pow(clamp(dot(-VIEW, LIGHT), 0.0, 1.0), 4.0) * translucidez * s;
		DIFFUSE_LIGHT += luz * cor_translucidez * tr;
	} else {
		DIFFUSE_LIGHT += luz * k * ATTENUATION;
	}
}
