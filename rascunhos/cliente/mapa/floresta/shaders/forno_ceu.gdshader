// forno_ceu.gdshader — Ordem 37, refeito na 38. O PINCEL que coze a pintura do céu (corre UMA
// vez, no forno: ferramentas/cozer_ceu.gd). Não entra no jogo: o jogo só lê o PNG cozido.
//
// ORDEM 38 (defeito 5): UM SÓ CÉU E UMA SÓ HORA nos 360° — meio da tarde. O gradiente
// (zénite azul, meia altura, bruma dourada no horizonte) é o MESMO em todos os azimutes; à
// volta do sol só há o clarão que um sol de tarde tem. SEM estrelas (é dia). A lua é de dia:
// pálida, mais clara que o céu, e MENOR que o sol (Ø 3,9° contra 5,75°). As nuvens são cúmulos
// de bom tempo com a mesma luz em toda a volta (claras para o lado do sol, base azulada).
//
// Mapa da textura: u = azimute (0,5 = norte, -Z), v = elevação de +90° (v=0) a ELEV_MIN (v=1).
// Só o hemisfério de cima: abaixo do horizonte o céu do jogo é a cor do horizonte.
// As cores aqui são sRGB «de tinta» (sem hint source_color): o que se pinta é o que sai no PNG.

shader_type canvas_item;

uniform vec3 cor_horizonte = vec3(0.84, 0.82, 0.67);
uniform vec3 cor_zenite = vec3(0.25, 0.45, 0.71);
uniform vec3 cor_meio = vec3(0.50, 0.65, 0.81);
uniform vec3 cor_baixo = vec3(0.74, 0.80, 0.77);
uniform vec3 dir_sol = vec3(-0.8, 0.5, 0.3);
uniform vec3 dir_lua = vec3(0.7, 0.6, -0.4);
uniform float sol_raio_graus = 2.875;
uniform float lua_raio_graus = 1.95;
uniform float elev_min_graus = -6.0;
uniform float nuvens_opacidade = 0.90;

const float TAU_ = 6.28318530718;

float h13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float ruido3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(h13(i), h13(i + vec3(1, 0, 0)), u.x), mix(h13(i + vec3(0, 1, 0)), h13(i + vec3(1, 1, 0)), u.x), u.y),
		mix(mix(h13(i + vec3(0, 0, 1)), h13(i + vec3(1, 0, 1)), u.x), mix(h13(i + vec3(0, 1, 1)), h13(i + vec3(1, 1, 1)), u.x), u.y),
		u.z);
}

float fbm(vec3 p) {
	float a = 0.5;
	float s = 0.0;
	for (int k = 0; k < 6; k++) {
		s += a * ruido3(p);
		p = p * 2.03 + vec3(17.1, 3.7, 9.2);
		a *= 0.5;
	}
	return s;
}

// O gradiente do céu: o MESMO em todos os azimutes (uma só hora).
vec3 gradiente(float e) {
	vec3 c = mix(cor_horizonte, cor_baixo, smoothstep(0.0, 0.10, e));
	c = mix(c, cor_meio, smoothstep(0.06, 0.34, e));
	c = mix(c, cor_zenite, smoothstep(0.26, 0.86, e));
	return c;
}

// Densidade de nuvem numa direcção. Domínio (azimute em círculo, elevação esticada):
// cúmulos de bom tempo, espalhados por igual em toda a volta.
float nuvem(float az, float el) {
	vec3 p = vec3(cos(az) * 2.9, el * 8.5, sin(az) * 2.9);
	float base = fbm(p * 1.20 + vec3(4.0, 0.0, 1.5));
	float fino = fbm(p * 3.6 + vec3(1.0, 7.0, 2.0));
	float dens = base * 0.78 + fino * 0.22;
	// Faixa de elevação: nascem acima da bruma (5°), enchem até ~35° e rareiam para o zénite.
	float faixa = smoothstep(0.07, 0.17, el) * (1.0 - smoothstep(0.45, 0.95, el));
	float limiar = 0.545;
	return smoothstep(limiar, limiar + 0.13, dens) * faixa;
}

void fragment() {
	float az = (UV.x - 0.5) * TAU_;
	float el = radians(mix(90.0, elev_min_graus, UV.y));
	vec3 d = vec3(sin(az) * cos(el), sin(el), -cos(az) * cos(el));
	float e = clamp(d.y, 0.0, 1.0);
	vec3 s = normalize(dir_sol);
	float cs = max(dot(d, s), 0.0);
	float az_sol = atan(s.x, -s.z);

	// ---------- gradiente (igual em toda a volta)
	vec3 cor = gradiente(e);
	vec3 ceu_limpo = cor;

	// ---------- lua de dia (um véu claro por cima do azul; o lado da sombra é céu)
	{
		vec3 l = normalize(dir_lua);
		vec3 lx = normalize(cross(vec3(0.0, 1.0, 0.0), l));
		vec3 ly = cross(l, lx);
		float raio = radians(lua_raio_graus);
		vec2 q = vec2(dot(d, lx), dot(d, ly)) / raio;  // -1..1 no disco
		float rr = length(q);
		if (dot(d, l) > 0.0 && rr < 1.0) {
			// a fase: iluminada do lado do sol (terminador em elipse: lua gibosa)
			vec2 para_sol = normalize(vec2(dot(s, lx), dot(s, ly)));
			float u = dot(q, para_sol);
			float w = dot(q, vec2(-para_sol.y, para_sol.x));
			float terminador = -0.55 * sqrt(max(1.0 - w * w, 0.0));
			float luz = smoothstep(terminador - 0.10, terminador + 0.10, u);
			float mares = 0.0;
			mares += 0.34 * (1.0 - smoothstep(0.0, 0.37, length(q - vec2(0.31, 0.46))));
			mares += 0.34 * (1.0 - smoothstep(0.0, 0.27, length(q - vec2(0.68, 0.13))));
			mares += 0.34 * (1.0 - smoothstep(0.0, 0.31, length(q - vec2(0.08, -0.08))));
			mares += 0.30 * (1.0 - smoothstep(0.0, 0.21, length(q - vec2(0.44, -0.44))));
			mares += 0.28 * (1.0 - smoothstep(0.0, 0.18, length(q - vec2(-0.27, -0.31))));
			float manchas = (fbm(vec3(q * 3.2, 4.0)) - 0.5) * 0.25;
			// nos mares vê-se o céu através dela
			float veu = clamp(0.80 - clamp(mares, 0.0, 0.5) * 0.55 - manchas, 0.0, 1.0) * luz;
			vec3 tinta_lua = vec3(0.985, 0.975, 0.945);
			float borda = 1.0 - smoothstep(0.93, 1.0, rr);
			cor = mix(cor, tinta_lua, veu * borda);
		}
	}

	// ---------- o clarão do sol de tarde (só à volta do sol; o resto do céu não muda de hora)
	vec3 ouro = vec3(1.0, 0.93, 0.74);
	float ang = acos(clamp(dot(d, s), -1.0, 1.0));
	float rs = ang / radians(sol_raio_graus);  // 1 = orla do disco
	// (mistura para creme, não soma: ouro somado ao azul dava um anel esverdeado)
	cor = mix(cor, vec3(1.0, 0.965, 0.87), clamp(pow(cs, 7.0) * 0.22 + pow(cs, 48.0) * 0.40, 0.0, 1.0));
	// a bruma do horizonte aquece um pouco por baixo do sol
	float sob_sol = pow(0.5 + 0.5 * cos(az - az_sol), 3.0) * (1.0 - smoothstep(0.0, 0.22, e));
	cor = mix(cor, cor * vec3(1.05, 1.01, 0.92), sob_sol * 0.6);

	// ---------- nuvens com forma (a MESMA luz em toda a volta: claras para o sol, base azulada)
	{
		float elp = max(el, 0.0);
		float n = nuvem(az, elp);
		float n_cima = nuvem(az, elp + 0.05);
		// para o lado do sol (em azimute e para cima): menos nuvem = face iluminada
		float passo_az = 0.07 * sign(sin(az_sol - az));
		float n_sol = nuvem(az + passo_az, elp + 0.03);
		float topo = clamp(1.0 - n_cima * 1.15, 0.0, 1.0);
		float para_sol = clamp(1.0 - n_sol, 0.0, 1.0);
		float luz = clamp(0.42 + 0.34 * topo + 0.30 * para_sol, 0.0, 1.0);
		vec3 n_luz = vec3(1.0, 0.975, 0.91);
		vec3 n_sombra = mix(vec3(0.60, 0.67, 0.76), ceu_limpo, 0.25);
		vec3 cor_n = mix(n_sombra, n_luz, smoothstep(0.42, 0.98, luz));
		// orla incandescente só mesmo ao pé do sol
		cor_n += ouro * pow(cs, 14.0) * 0.30 * (1.0 - n);
		// as bases afundam-se na bruma do horizonte
		cor_n = mix(cor_horizonte, cor_n, smoothstep(0.03, 0.24, d.y));
		cor = mix(cor, cor_n, n * nuvens_opacidade);
	}

	// ---------- sol desenhado por cima (halo + coroa + disco)
	{
		float halo = (1.0 - smoothstep(1.0, 3.2, rs)) * 0.26;
		float coroa = (1.0 - smoothstep(1.0, 1.45, rs)) * 0.16;
		cor = mix(cor, vec3(1.0, 0.975, 0.90), clamp((halo + coroa) * 1.7, 0.0, 1.0) * step(1.0, rs));
		// o clarão em volta não estoura em branco: fica creme, para o disco se ler POR CIMA dele
		cor = mix(min(cor, vec3(1.0, 0.965, 0.84)), cor, smoothstep(3.0, 9.0, rs));
		float limbo = 1.0 - 0.03 * smoothstep(0.5, 1.0, rs);
		vec3 disco = vec3(1.0, 1.0, 0.96) * limbo;
		cor = mix(cor, disco, 1.0 - smoothstep(0.93, 1.0, rs));
	}

	// ---------- a base funde-se na cor do horizonte (a mesma fórmula do jogo, já na tinta)
	cor = mix(cor_horizonte, cor, smoothstep(0.0, 0.10, d.y));
	// grão de pincel, muito leve
	cor *= 1.0 + (ruido3(vec3(UV * vec2(900.0, 420.0), 3.0)) - 0.5) * 0.02;
	COLOR = vec4(clamp(cor, 0.0, 1.0), 1.0);
}
