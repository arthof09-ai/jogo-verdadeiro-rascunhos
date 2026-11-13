// forno_ceu.gdshader — Ordem 37. O PINCEL que coze a pintura do céu (corre UMA vez, no forno:
// ferramentas/cozer_ceu.gd). Não entra no jogo: o jogo só lê o PNG cozido.
//
// A pintura segue a receita aprovada da casa (céu v2): gradiente por paradas, sol e lua
// DESENHADOS (disco + coroa + halo; lua com mares, crateras e fase), nuvens com FORMA
// (sopros com luz por cima e sombra por baixo) e estrelas em 3 classes de tamanho.
// Sol Ø 5,75° · lua Ø 7,17° · brilho da lua 0,410 (mediana da luma do disco, medida no forno).
//
// Mapa da textura: u = azimute (0,5 = norte, -Z), v = elevação de +90° (v=0) a ELEV_MIN (v=1).
// Só o hemisfério de cima: abaixo do horizonte o céu do jogo é a cor do horizonte.
// As cores aqui são sRGB «de tinta» (sem hint source_color): o que se pinta é o que sai no PNG.

shader_type canvas_item;

uniform vec3 cor_horizonte = vec3(0.84, 0.82, 0.60);
uniform vec3 dir_sol = vec3(-0.5, 0.2, -0.8);
uniform vec3 dir_lua = vec3(0.5, 0.5, 0.6);
uniform float sol_raio_graus = 2.875;
uniform float lua_raio_graus = 3.585;
uniform float lua_ganho = 0.62;       // afinado no forno até a mediana do disco dar 0,410
uniform float elev_min_graus = -6.0;
uniform float nuvens_opacidade = 0.86;

const float TAU_ = 6.28318530718;

float h13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

vec3 h33(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
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

vec3 paradas4(vec3 c0, vec3 c1, vec3 c2, vec3 c3, vec3 c4, float e) {
	// e = elevação normalizada 0 (horizonte) .. 1 (zénite); paradas em 0, .09, .24, .52, 1
	vec3 c = mix(c0, c1, smoothstep(0.0, 0.09, e));
	c = mix(c, c2, smoothstep(0.09, 0.24, e));
	c = mix(c, c3, smoothstep(0.24, 0.52, e));
	c = mix(c, c4, smoothstep(0.52, 1.0, e));
	return c;
}

// Densidade de nuvem numa direcção. Domínio (azimute em círculo, elevação esticada):
// massas largas e baixas com torres, como os cúmulos da referência 07.
float nuvem(vec3 d, float az, float el) {
	vec3 p = vec3(cos(az) * 2.6, el * 7.5, sin(az) * 2.6);
	float base = fbm(p * 1.15 + vec3(4.0, 0.0, 1.5));
	float fino = fbm(p * 3.4 + vec3(1.0, 7.0, 2.0));
	float dens = base * 0.78 + fino * 0.22;
	// Faixa de elevação: nascem da bruma (3°), enchem até ~40° e rareiam para o zénite.
	float faixa = smoothstep(0.03, 0.14, el) * (1.0 - smoothstep(0.50, 1.05, el));
	// Mais massa do lado do sol (o céu de ouro da referência); céu mais limpo do lado da lua.
	float lado = 0.5 + 0.5 * dot(normalize(d.xz + vec2(0.0001)), normalize(dir_sol.xz));
	float limiar = mix(0.56, 0.47, lado);
	return smoothstep(limiar, limiar + 0.16, dens) * faixa;
}

void fragment() {
	float az = (UV.x - 0.5) * TAU_;
	float el = radians(mix(90.0, elev_min_graus, UV.y));
	vec3 d = vec3(sin(az) * cos(el), sin(el), -cos(az) * cos(el));
	float e = clamp(d.y, 0.0, 1.0);

	// ---------- gradiente (lado do sol / lado da lua)
	float lado = 0.5 + 0.5 * dot(normalize(d.xz + vec2(0.0001)), normalize(dir_sol.xz));
	lado = smoothstep(0.0, 1.0, lado);
	lado = mix(0.5, lado, smoothstep(1.0, 0.55, d.y));
	vec3 sol_lado = paradas4(cor_horizonte, vec3(0.953, 0.875, 0.651), vec3(0.906, 0.843, 0.588),
			vec3(0.686, 0.776, 0.604), vec3(0.478, 0.647, 0.588), e);
	vec3 lua_lado = paradas4(cor_horizonte, vec3(0.812, 0.812, 0.624), vec3(0.624, 0.702, 0.604),
			vec3(0.310, 0.455, 0.502), vec3(0.176, 0.298, 0.396), e);
	vec3 cor = mix(lua_lado, sol_lado, lado);

	// ---------- estrelas (3 classes, do lado escuro; a v2 dá-lhes alfa 0,55 x peso da lua)
	float escuro = (1.0 - lado) * smoothstep(0.16, 0.55, d.y);
	{
		vec3 p = d * 46.0;
		vec3 cel = floor(p);
		vec3 r = h33(cel);
		vec3 pos = cel + 0.2 + 0.6 * r;
		float classe = h13(cel + 7.7);
		float tam = classe < 0.45 ? 0.055 : (classe < 0.85 ? 0.08 : 0.12);
		float existe = step(0.62, h13(cel + 3.1));
		float dist = length(p - pos);
		float nucleo = smoothstep(tam, tam * 0.1, dist);
		float brilho = 0.45 + 0.55 * h13(cel + 11.3);
		vec3 cor_e = mix(vec3(0.84, 0.89, 1.0), vec3(1.0, 0.95, 0.87), h13(cel + 5.5));
		cor = mix(cor, cor_e, nucleo * existe * brilho * 0.55 * escuro);
	}

	// ---------- lua (disco desenhado: fase, mares, crateras, orla)
	{
		vec3 l = normalize(dir_lua);
		vec3 lx = normalize(cross(vec3(0.0, 1.0, 0.0), l));
		vec3 ly = cross(l, lx);
		float raio = radians(lua_raio_graus);
		vec2 q = vec2(dot(d, lx), dot(d, ly)) / raio;  // -1..1 no disco
		float rr = length(q);
		if (dot(d, l) > 0.0 && rr < 2.2) {
			// halo ténue (v2: até ~1,8 raios, alfa 0,10)
			cor += vec3(0.10) * (1.0 - smoothstep(1.0, 1.85, rr)) * step(1.0, rr);
			if (rr < 1.0) {
				// luz de cima-esquerda, sombra para baixo-direita
				float luz = 1.0 - 0.30 * smoothstep(0.0, 1.45, length(q - vec2(-0.42, 0.50)));
				float mares = 0.0;
				mares += 0.34 * (1.0 - smoothstep(0.0, 0.37, length(q - vec2(0.31, 0.46))));
				mares += 0.34 * (1.0 - smoothstep(0.0, 0.27, length(q - vec2(0.68, 0.13))));
				mares += 0.34 * (1.0 - smoothstep(0.0, 0.31, length(q - vec2(0.08, -0.08))));
				mares += 0.34 * (1.0 - smoothstep(0.0, 0.21, length(q - vec2(0.44, -0.44))));
				mares += 0.30 * (1.0 - smoothstep(0.0, 0.18, length(q - vec2(-0.27, -0.31))));
				mares += 0.28 * (1.0 - smoothstep(0.0, 0.15, length(q - vec2(-0.13, 0.42))));
				float manchas = (fbm(vec3(q * 3.2, 4.0)) - 0.5) * 0.30;
				float crat = smoothstep(0.62, 0.70, ruido3(vec3(q * 9.0, 9.0))) * 0.10;
				float fase = 0.38 * (1.0 - smoothstep(0.25, 1.7, length(q - vec2(-0.75, -0.87))));
				float tom = luz * (1.0 - clamp(mares, 0.0, 0.5)) - manchas * 0.5 - crat - fase;
				// orla clara do lado da luz
				tom += 0.10 * smoothstep(0.93, 0.99, rr) * smoothstep(-0.2, 0.6, dot(normalize(q), normalize(vec2(-0.45, 0.6))));
				vec3 tinta_lua = vec3(1.0, 0.985, 0.95) * lua_ganho;
				float borda = 1.0 - smoothstep(0.945, 1.0, rr);
				cor = mix(cor, tinta_lua * clamp(tom, 0.0, 1.0), borda);
			}
		}
	}

	// ---------- sol (clarão largo + halo + coroa + disco)
	vec3 s = normalize(dir_sol);
	float cs = max(dot(d, s), 0.0);
	float ang = acos(clamp(dot(d, s), -1.0, 1.0));
	float rs = ang / radians(sol_raio_graus);  // 1 = orla do disco
	vec3 ouro = vec3(1.0, 0.90, 0.62);
	// clarão de atmosfera (a «luz dourada do mundo»), largo e baixo
	float clarao = pow(cs, 5.0) * 0.26 + pow(cs, 24.0) * 0.16;
	cor += ouro * clarao * (1.0 - 0.35 * smoothstep(0.0, 0.6, d.y));

	// ---------- nuvens com forma (luz por cima, sombra por baixo)
	{
		float n = nuvem(d, az, max(el, 0.0));
		float n_cima = nuvem(d, az, max(el, 0.0) + 0.045);
		float n_sol = nuvem(normalize(mix(d, s, 0.06)), az + 0.06 * sign(sin(atan(s.x, -s.z) - az)), max(el, 0.0) + 0.02);
		// luz por cima: menos nuvem por cima de mim = estou no topo iluminado
		float topo = clamp(1.0 - n_cima * 1.15, 0.0, 1.0);
		float para_sol = clamp(1.0 - n_sol, 0.0, 1.0);
		float luz = clamp(0.50 + 0.36 * topo + 0.22 * para_sol, 0.0, 1.0);  // v2: sombra ~128, luz 255
		float wsol = mix(0.30, 1.0, lado);
		// luz: creme-ouro do lado do sol, cinza-azul do lado da lua; sombra: ocre quente / azul-ardósia
		vec3 n_luz = mix(vec3(0.62, 0.70, 0.74), vec3(1.0, 0.945, 0.78), wsol);
		vec3 n_sombra = mix(vec3(0.30, 0.40, 0.48), vec3(0.80, 0.66, 0.44), wsol);
		vec3 cor_n = mix(n_sombra, n_luz, smoothstep(0.50, 1.0, luz));
		// orla incandescente perto do sol (prata/ouro nas bordas das massas)
		cor_n += ouro * pow(cs, 10.0) * 0.38 * (1.0 - n) ;
		// as bases afundam-se na bruma do horizonte
		cor_n = mix(cor_horizonte, cor_n, smoothstep(0.02, 0.22, d.y));
		cor = mix(cor, cor_n, n * nuvens_opacidade);
	}

	// ---------- sol desenhado por cima (o disco vê-se através da bruma, não das nuvens densas)
	{
		float halo = (1.0 - smoothstep(1.0, 3.07, rs)) * 0.22;
		float coroa = (1.0 - smoothstep(1.0, 1.42, rs)) * (0.10 + 0.10 * ruido3(vec3(atan(dot(d, cross(s, vec3(0, 1, 0))), d.y - s.y) * 7.0, 1.0, 2.0)));
		cor += vec3(1.0, 0.95, 0.80) * (halo + coroa) * step(1.0, rs);
		float limbo = 1.0 - 0.07 * smoothstep(0.2, 1.0, rs);
		vec3 disco = vec3(1.0, 0.985, 0.90) * limbo + vec3(0.05) * smoothstep(0.93, 0.985, rs);
		cor = mix(cor, min(disco, vec3(1.0)), 1.0 - smoothstep(0.955, 1.0, rs));
	}

	// ---------- a base funde-se na cor do horizonte (a mesma fórmula do jogo, já na tinta)
	cor = mix(cor_horizonte, cor, smoothstep(0.0, 0.10, d.y));
	// grão de pincel, muito leve
	cor *= 1.0 + (ruido3(vec3(UV * vec2(900.0, 420.0), 3.0)) - 0.5) * 0.025;
	COLOR = vec4(clamp(cor, 0.0, 1.0), 1.0);
}
