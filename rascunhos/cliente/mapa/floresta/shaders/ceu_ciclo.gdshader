// ceu_ciclo.gdshader — Ordem 43. O céu do CICLO DO DIA: UM céu só, que muda com a hora.
// É a mesma pintura da Ordem 38 (o mesmo gradiente, as mesmas nuvens, os mesmos discos — a
// receita do forno_ceu.gdshader), mas pintada AO VIVO: o sol e a lua andam (dir_sol, dir_lua),
// e as tintas (zénite, meia altura, baixo, horizonte, arrebol, nuvens) chegam da hora
// (ciclo_dia.gd). Nunca se troca de céu: só mudam os uniforms.
//
// CUSTO: o gradiente e os discos são contas; as NUVENS vêm cozidas numa textura de camadas
// (ceu/ceu_camadas_v1.png, canal R = densidade; 3 leituras: aqui, por cima e para o lado da
// luz); as ESTRELAS são 1 sorteio por píxel (sem textura). Sem TIME: o céu só se repinta
// quando um uniform muda.
//
// A faixa baixa funde-se na COR DO HORIZONTE — a mesma variável da névoa e da tinta dos anéis
// (regra anti-costura), em TODOS os azimutes e a TODAS as horas. O arrebol (a faixa quente do
// lado do sol) vive POR CIMA dessa faixa.
// As tintas são sRGB «de pintor» (sem source_color): mistura-se em sRGB, como o forno, e
// converte-se para luz no fim.
shader_type sky;

uniform sampler2D camadas : filter_linear, repeat_enable;
uniform vec3 cor_horizonte = vec3(0.84, 0.82, 0.67);
uniform vec3 cor_baixo = vec3(0.74, 0.80, 0.77);
uniform vec3 cor_meio = vec3(0.50, 0.65, 0.81);
uniform vec3 cor_zenite = vec3(0.25, 0.45, 0.71);
uniform vec3 cor_arrebol = vec3(1.0, 0.6, 0.3);
uniform float arrebol = 0.0;
uniform vec3 dir_sol = vec3(-0.8, 0.5, 0.3);
uniform vec3 dir_lua = vec3(0.7, 0.6, -0.4);
uniform vec3 dir_luz = vec3(-0.8, 0.5, 0.3);      // de que lado as nuvens apanham luz
uniform vec3 cor_disco = vec3(1.0, 1.0, 0.96);
uniform vec3 cor_clarao = vec3(1.0, 0.965, 0.87);
uniform float sol_visivel = 1.0;
uniform vec3 nuvem_luz = vec3(1.0, 0.975, 0.91);
uniform vec3 nuvem_sombra = vec3(0.60, 0.67, 0.76);
uniform float nuvens_opacidade = 0.90;
uniform float nuvens_desloc = 0.0;                // as nuvens andam com o vento (em voltas)
uniform float estrelas = 0.0;
uniform float lua_noite = 0.0;                    // 0 = lua de dia (véu pálido) · 1 = lua da noite
uniform float sol_raio_graus = 2.875;
uniform float lua_raio_graus = 1.95;
uniform float faixa : hint_range(0.01, 0.5) = 0.15;
uniform float elev_min_graus = -6.0;

float h13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

vec3 para_luz(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

vec3 gradiente(float e) {
	vec3 c = mix(cor_horizonte, cor_baixo, smoothstep(0.0, 0.10, e));
	c = mix(c, cor_meio, smoothstep(0.06, 0.34, e));
	c = mix(c, cor_zenite, smoothstep(0.26, 0.86, e));
	return c;
}

float nuvem(float u, float el) {
	float v = clamp((90.0 - degrees(el)) / (90.0 - elev_min_graus), 0.002, 0.998);
	return texture(camadas, vec2(u + nuvens_desloc, v)).r;
}

// Uma estrela por casa de uma grelha 3D sobre a esfera: 1 sorteio, sem vizinhos.
float estrela(vec3 d) {
	vec3 p = d * 150.0;
	vec3 i = floor(p);
	float h = h13(i);
	if (h < 0.962) {
		return 0.0;
	}
	vec3 o = (vec3(h13(i + 7.1), h13(i + 13.7), h13(i + 29.3)) - 0.5) * 0.5;
	float r = length(fract(p) - 0.5 - o);
	float mag = fract(h * 977.0);
	mag = mag * mag;
	return (1.0 - smoothstep(0.0, 0.10 + 0.13 * mag, r)) * (0.30 + 0.70 * mag);
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float az = atan(d.x, -d.z);
	float u = az / TAU + 0.5;
	float el = asin(clamp(d.y, -1.0, 1.0));
	float e = clamp(d.y, 0.0, 1.0);
	vec3 s = normalize(dir_sol);
	float cs = max(dot(d, s), 0.0);
	float az_sol = atan(s.x, -s.z);

	// ---------- gradiente (igual em toda a volta)
	vec3 cor = gradiente(e);

	// ---------- arrebol: a faixa quente do lado do sol (madrugada e entardecer)
	float lado = 0.5 + 0.5 * cos(az - az_sol);
	float baixo = 1.0 - smoothstep(0.03, 0.46, e);
	cor = mix(cor, cor_arrebol, arrebol * lado * lado * baixo * 0.80);
	// e do lado de lá, o rosa frio do anti-crepúsculo, muito leve
	cor = mix(cor, mix(cor_arrebol, cor_meio, 0.55), arrebol * (1.0 - lado) * (1.0 - lado) * baixo * 0.22);
	vec3 ceu_limpo = cor;

	// ---------- estrelas (só de noite; somem na bruma do horizonte)
	if (estrelas > 0.001) {
		float est = estrela(d) * estrelas * smoothstep(0.05, 0.30, d.y);
		cor = mix(cor, vec3(0.93, 0.95, 1.0), clamp(est, 0.0, 1.0));
	}

	// ---------- lua (de dia um véu pálido; de noite o disco claro, com os mares e um halo)
	{
		vec3 l = normalize(dir_lua);
		vec3 lx = normalize(cross(vec3(0.0, 1.0, 0.0), l));
		vec3 ly = cross(l, lx);
		float raio = radians(lua_raio_graus);
		vec2 q = vec2(dot(d, lx), dot(d, ly)) / raio;
		float rr = length(q);
		float frente = step(0.0, dot(d, l));
		float halo = (1.0 - smoothstep(1.0, 6.5, rr)) * frente;
		cor = mix(cor, vec3(0.62, 0.72, 0.92), halo * halo * 0.30 * lua_noite);
		if (frente > 0.5 && rr < 1.0) {
			float mares = 0.0;
			mares += 0.34 * (1.0 - smoothstep(0.0, 0.37, length(q - vec2(0.31, 0.46))));
			mares += 0.34 * (1.0 - smoothstep(0.0, 0.27, length(q - vec2(0.68, 0.13))));
			mares += 0.34 * (1.0 - smoothstep(0.0, 0.31, length(q - vec2(0.08, -0.08))));
			mares += 0.30 * (1.0 - smoothstep(0.0, 0.21, length(q - vec2(0.44, -0.44))));
			mares += 0.28 * (1.0 - smoothstep(0.0, 0.18, length(q - vec2(-0.27, -0.31))));
			mares = clamp(mares, 0.0, 0.5);
			float borda = 1.0 - smoothstep(0.93, 1.0, rr);
			// de dia: um véu claro por cima do azul (nos mares vê-se o céu através dela)
			vec3 dia = mix(cor, vec3(0.985, 0.975, 0.945), clamp(0.80 - mares * 0.55, 0.0, 1.0));
			// de noite: disco de marfim, mares em cinza-azulado
			vec3 noite = mix(vec3(0.99, 0.975, 0.93), vec3(0.60, 0.66, 0.78), mares * 1.1);
			cor = mix(cor, mix(dia, noite, lua_noite), borda);
		}
	}

	// ---------- o clarão do sol (só à volta do sol)
	float ang = acos(clamp(dot(d, s), -1.0, 1.0));
	float rs = ang / radians(sol_raio_graus);
	cor = mix(cor, cor_clarao, clamp(pow(cs, 7.0) * 0.22 + pow(cs, 48.0) * 0.40, 0.0, 1.0) * sol_visivel);
	float sob_sol = pow(0.5 + 0.5 * cos(az - az_sol), 3.0) * (1.0 - smoothstep(0.0, 0.22, e));
	cor = mix(cor, cor * vec3(1.05, 1.01, 0.92), sob_sol * 0.6 * sol_visivel);

	// ---------- nuvens (cozidas; claras para o lado da luz, base na sombra)
	{
		vec3 lz = normalize(dir_luz);
		float az_luz = atan(lz.x, -lz.z);
		float elp = max(el, 0.0);
		float n = nuvem(u, elp);
		float n_cima = nuvem(u, elp + 0.05);
		float passo_az = 0.07 * sign(sin(az_luz - az));
		float n_sol = nuvem(u + passo_az / TAU, elp + 0.03);
		float topo = clamp(1.0 - n_cima * 1.15, 0.0, 1.0);
		float para_sol = clamp(1.0 - n_sol, 0.0, 1.0);
		float luz = clamp(0.42 + 0.34 * topo + 0.30 * para_sol, 0.0, 1.0);
		vec3 n_sombra = mix(nuvem_sombra, ceu_limpo, 0.25);
		vec3 cor_n = mix(n_sombra, nuvem_luz, smoothstep(0.42, 0.98, luz));
		// orla incandescente só mesmo ao pé do sol
		cor_n += cor_clarao * pow(cs, 14.0) * 0.30 * (1.0 - n) * sol_visivel;
		// as bases afundam-se na bruma do horizonte
		cor_n = mix(cor_horizonte, cor_n, smoothstep(0.03, 0.24, d.y));
		cor = mix(cor, cor_n, n * nuvens_opacidade);
	}

	// ---------- a base funde-se na cor do horizonte (a fórmula do forno e a do jogo)
	cor = mix(cor_horizonte, cor, smoothstep(0.0, 0.10, d.y));
	cor = mix(cor_horizonte, cor, smoothstep(0.0, faixa, d.y));

	// ---------- sol por cima de tudo (halo + coroa + disco): lê-se mesmo a tocar o horizonte
	{
		float halo = (1.0 - smoothstep(1.0, 3.2, rs)) * 0.26;
		float coroa = (1.0 - smoothstep(1.0, 1.45, rs)) * 0.16;
		float por_cima = smoothstep(-0.07, 0.0, d.y);
		cor = mix(cor, cor_clarao, clamp((halo + coroa) * 1.7, 0.0, 1.0) * step(1.0, rs) * sol_visivel * por_cima);
		float limbo = 1.0 - 0.03 * smoothstep(0.5, 1.0, rs);
		cor = mix(cor, cor_disco * limbo, (1.0 - smoothstep(0.93, 1.0, rs)) * sol_visivel * por_cima);
	}
	COLOR = para_luz(clamp(cor, 0.0, 1.0));
}
