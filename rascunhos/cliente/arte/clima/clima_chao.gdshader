// clima_chao.gdshader — Ordem 40 (clima) + Ordem 41 (expansão). A RESPOSTA DO CHÃO, como material_overlay:
// desenha-se POR CIMA do chão que lá estiver (cor lisa, textura, terreno), sem trocar o material dele.
//
// A BASE (Ordem 40):
//   molhado (0..1): escurece, ganha reflexo do céu (mais forte nas poças e de raspão), brilho do sol e os
//                   anéis dos pingos onde a chuva bate (`pingos` = quantos, `forca_pingo` = a força do bater);
//   neve (0..1):    o chão branqueia aos poucos — primeiro um pó, depois manchas que crescem até cobrir tudo.
//                   Ao longo das linhas da grelha a neve fica rala, para a grelha continuar a ler-se.
// O CLIMA FORTE (Ordem 41) — tudo a zero nos climas fracos, e aí a camada é a da base, igual:
//   agua (0..1):        as BOLSAS — a água junta-se nos pontos baixos (clima_terreno.gdshaderinc), nasce
//                       pequena e cresce; cor, reflexo e ruga da água da casa (mapa/floresta/shaders/agua);
//   lama (0..1):        a LAMA à volta e debaixo das bolsas (uma faixa, não um corte), com `lama_humida`
//                       (1 = a brilhar de molhada, 0 = baça, a secar);
//   aglomerado (0..1):  a neve da NEVASCA junta-se nos cantos, nas bordas e contra os obstáculos (com a
//                       cauda a sotavento) e o centro fica varrido; os montes têm sombra própria;
//   gelo (0..1):        o chão varrido ganha placas de gelo (brilho frio, cintilar);
//   rasteira (0..1):    as fitas de neve que o vento arrasta rente ao chão (andam com `d_varre`);
//   veu (0..1):         ao longe o chão some-se no branco (de `veu_perto_m` a `veu_longe_m` da câmara).
//
// Sem luz do motor (unshaded): a luz é a que o Clima manda (sol e reflexo), barato no telemóvel. A saída é
// «aditiva + escurecer» feita com blend_mix: ALPHA = quanto tapa, ALBEDO = cor / ALPHA.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

#include "res://arte/clima/clima_terreno.gdshaderinc"

uniform float molhado : hint_range(0.0, 1.0) = 0.0;
uniform float neve : hint_range(0.0, 1.0) = 0.0;
uniform float pingos : hint_range(0.0, 1.0) = 0.0;
uniform float forca_pingo : hint_range(0.0, 1.0) = 0.5;
uniform float tempo = 0.0;
// Para onde está o sol (mundo) e a cor dele.
uniform vec3 luz_dir = vec3(0.4, 0.8, 0.45);
uniform vec3 luz_cor : source_color = vec3(1.0, 0.95, 0.85);
uniform vec3 cor_reflexo : source_color = vec3(0.72, 0.80, 0.88);
uniform vec3 cor_neve : source_color = vec3(0.93, 0.96, 0.99);
uniform vec3 cor_neve_sombra : source_color = vec3(0.72, 0.80, 0.91);
// A grelha táctica (0 = sem grelha): a neve abre um fio ao longo das linhas.
uniform vec3 grelha_origem = vec3(0.0);
uniform float grelha_casa_m = 0.0;
// 0 = Baixo (uma camada de pingos, ruído simples, sem fitas), 1 = Médio, 2 = Alto.
uniform int qualidade = 1;

// ---- Ordem 41: o clima forte
uniform float agua : hint_range(0.0, 1.0) = 0.0;
uniform float lama : hint_range(0.0, 1.0) = 0.0;
uniform float lama_humida : hint_range(0.0, 1.0) = 1.0;
uniform float aglomerado : hint_range(0.0, 1.0) = 0.0;
uniform float gelo : hint_range(0.0, 1.0) = 0.0;
uniform float rasteira : hint_range(0.0, 1.0) = 0.0;
uniform float d_varre = 0.0;
uniform float veu : hint_range(0.0, 1.0) = 0.0;
uniform float veu_perto_m = 30.0;
uniform float veu_longe_m = 60.0;
// As figuras com os pés na água: x, z, raio dos pés (m), agitação (0 = parada … 1 = acabou de se mexer).
uniform vec4 pes[8];
uniform int n_pes = 0;
// As cores da água da casa (mapa/floresta/shaders/agua.gdshader: cor_funda, cor_rasa).
uniform vec3 cor_agua_funda : source_color = vec3(0.24, 0.40, 0.44);
uniform vec3 cor_agua_rasa : source_color = vec3(0.49, 0.60, 0.53);
uniform vec3 cor_lama : source_color = vec3(0.20, 0.135, 0.085);
uniform vec3 cor_lama_seca : source_color = vec3(0.40, 0.33, 0.24);
uniform vec3 cor_gelo : source_color = vec3(0.72, 0.89, 1.0);

varying vec3 v_mundo;
varying vec3 v_normal;

float h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 h22(vec2 p) {
	float n = h21(p);
	return vec2(n, h21(p + n + 17.1));
}

float ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1.0, 0.0)), f.x), mix(h21(i + vec2(0.0, 1.0)), h21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.55 * ruido(p) + 0.30 * ruido(p * 2.03 + 7.1);
	if (qualidade > 0) {
		v += 0.15 * ruido(p * 4.01 + 3.3);
	} else {
		v += 0.075;
	}
	return v;
}

// Uma camada de pingos: em cada célula, um anel que nasce num ponto sorteado, abre e some.
// Devolve (inclinação.xz da ondinha, brilho da crista). `na_agua` = 1: o pingo cai em água junta — a coroa
// abre mais, dura mais e leva um segundo anel por dentro (no chão molhado é um anel curto, que morre logo).
vec3 camada_pingos(vec2 p, float celula, float semente, float na_agua) {
	vec2 id = floor(p / celula);
	vec2 r0 = h22(id + semente);
	float periodo = mix(0.55, 1.05, r0.x) * mix(1.0, 1.55, na_agua);
	float fase = tempo / periodo + r0.y;
	float ciclo = floor(fase);
	float f = fract(fase);
	float ativo = step(h21(id * 1.7 + ciclo * 0.61 + semente), pingos);
	vec2 r1 = h22(id + semente + ciclo * 1.37);
	vec2 centro = (id + 0.32 + 0.36 * r1) * celula;
	vec2 d = p - centro;
	float dist = length(d);
	float raio = f * celula * mix(mix(0.20, 0.30, forca_pingo), 0.46, na_agua);
	float larg = celula * mix(0.035, 0.028, na_agua);
	float x = (dist - raio) / larg;
	float onda = exp(-x * x);
	float x2 = (dist - raio * 0.55) / larg;
	float onda2 = exp(-x2 * x2) * 0.6 * na_agua;
	float amp = (1.0 - f) * (1.0 - f) * ativo;
	float clarao = smoothstep(0.15, 0.0, f) * smoothstep(celula * 0.07, 0.0, dist) * ativo;
	vec2 dir = d / max(dist, 1e-4);
	return vec3(dir * (-2.0 * (x * onda + x2 * onda2)) * amp, (onda + onda2) * amp + clarao);
}

// Os anéis à volta dos pés das figuras que estão dentro da bolsa: um anel de contacto (sempre) e as ondas
// que abrem quando a figura se mexe. Só apresentação: quem diz onde a figura está é a cena.
vec3 aneis_dos_pes(vec2 xz) {
	vec3 r = vec3(0.0);
	for (int i = 0; i < 8; i++) {
		if (i >= n_pes) {
			break;
		}
		vec4 pe = pes[i];
		vec2 d = xz - pe.xy;
		float dist = length(d);
		vec2 dir = d / max(dist, 1e-4);
		float x0 = (dist - pe.z - 0.04) / 0.035;
		float brilho = exp(-x0 * x0) * 0.30;
		vec2 inc = vec2(0.0);
		for (int k = 0; k < 3; k++) {
			float fase = fract(tempo * 0.80 + float(k) / 3.0 + float(i) * 0.37);
			float raio = pe.z + 0.06 + fase * 1.45;
			float x = (dist - raio) / 0.055;
			float onda = exp(-x * x) * pe.w * (1.0 - fase) * (1.0 - fase);
			inc += dir * (-2.0 * x * onda);
			brilho += onda * 0.75;
		}
		r += vec3(inc * 0.45, brilho);
	}
	return r;
}

// O cintilar do gelo: grãos que acendem e apagam com o ângulo da câmara (e devagar com o tempo).
float cintilar(vec2 p, vec3 V) {
	vec2 g = p * 26.0;
	float r = h21(floor(g));
	vec2 f = fract(g) - 0.5;
	float fase = dot(V.xz, vec2(37.0, 53.0)) + r * 40.0 + tempo * 0.7;
	float fino = smoothstep(0.7, 0.2, fwidth(g.x) + fwidth(g.y));
	return step(0.955, r) * smoothstep(0.38, 0.0, length(f)) * max(sin(fase), 0.0) * fino;
}

// «Por cima»: junta uma camada (cor, quanto tapa) ao que já lá está (cor pré-multiplicada, alfa).
void por_cima(inout vec3 pre, inout float a, vec3 cor, float quanto) {
	pre = cor * quanto + pre * (1.0 - quanto);
	a = quanto + a * (1.0 - quanto);
}

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n_base = normalize(v_normal);
	float cima = smoothstep(0.25, 0.7, n_base.y);
	vec3 para_camara = CAMERA_POSITION_WORLD - v_mundo;
	float dist_camara = length(para_camara);
	vec3 V = para_camara / max(dist_camara, 1e-4);
	vec3 L = normalize(luz_dir);
	vec2 xz = v_mundo.xz;
	vec3 pre = vec3(0.0);
	float a = 0.0;

	// ---------------------------------------------------------------- bolsas e lama (Ordem 41)
	float m_agua = 0.0;
	float m_lama = 0.0;
	float fundo = 0.0;
	if (lama > 0.001 && n_bacias > 0) {
		float y_rel = v_mundo.y - chao_ref_y;
		float orla = ruido(xz * 2.3 + 4.0) - 0.5;
		float dl = clima_fundura(xz, y_rel, lama * CLIMA_ENCHE, CLIMA_MARGEM_LAMA);
		m_lama = smoothstep(0.0, 0.011, dl + orla * 0.007) * cima * clamp(lama * 8.0, 0.0, 1.0);
		if (agua > 0.001) {
			float d = clima_fundura(xz, y_rel, agua * CLIMA_ENCHE, 0.0) + orla * 0.0022;
			m_agua = smoothstep(0.0, 0.0035, d) * cima;
			fundo = clamp(d / 0.065, 0.0, 1.0);
		}
		if (m_lama > 0.001) {
			// A lama: escura e saturada; molhada, brilha aos altos e baixos (não é um espelho liso).
			vec2 g = vec2(ruido(xz * 5.3 + 1.7), ruido(xz * 5.3 + 8.3)) - 0.5;
			vec3 Nl = normalize(n_base + vec3(g.x, 0.0, g.y) * 0.60);
			vec3 Rl = reflect(-V, Nl);
			float raspao_l = pow(1.0 - clamp(dot(Nl, V), 0.0, 1.0), 4.0);
			vec3 ceu_l = cor_reflexo * mix(1.10, 0.60, clamp(Rl.y, 0.0, 1.0));
			vec3 c_lama = mix(cor_lama_seca, cor_lama, lama_humida) * (0.80 + 0.40 * ruido(xz * 1.9 + 3.0));
			c_lama += lama_humida * (ceu_l * (0.07 + 0.50 * raspao_l) + luz_cor * (pow(max(dot(Rl, L), 0.0), 24.0) * 0.50));
			por_cima(pre, a, c_lama, m_lama * mix(0.55, 0.90, lama_humida));
		}
	}

	// ---------------------------------------------------------------- molhado (a base)
	if (molhado > 0.001) {
		float m = molhado;
		float n1 = fbm(xz * 0.42);
		// As poças aparecem e crescem com o molhado.
		float nivel = n1 + (m - 1.0) * 0.30;
		float poca = smoothstep(0.52, 0.57, nivel) * cima;
		// À volta da poça a terra fica mais encharcada (mais escura).
		float margem = smoothstep(0.43, 0.52, nivel) * (1.0 - poca) * cima;
		vec3 rip = vec3(0.0);
		if (pingos > 0.001) {
			rip = camada_pingos(xz, 0.85, 3.1, 0.0);
			if (qualidade > 0) {
				rip += camada_pingos(xz + 11.3, 0.55, 8.7, 0.0);
			}
		}
		vec3 N = normalize(n_base + vec3(rip.x, 0.0, rip.y) * mix(0.10, 0.28, forca_pingo));
		float nv = clamp(dot(N, V), 0.0, 1.0);
		float raspao = pow(1.0 - nv, 4.0);
		// Quanto do céu o chão devolve: pouco no molhado, muito na poça e de raspão.
		float reflecte = m * (mix(0.06, 0.30, poca) + 0.55 * raspao);
		vec3 R = reflect(-V, N);
		// O céu no reflexo: claro para o horizonte, mais fundo a pique.
		vec3 ceu = cor_reflexo * mix(1.15, 0.60, clamp(R.y, 0.0, 1.0));
		// O lustro do molhado: um brilho largo para o lado do sol, com o grão do chão (não é um espelho liso).
		vec2 grao = vec2(ruido(xz * 3.1 + 2.0), ruido(xz * 3.1 + 9.0)) - 0.5;
		vec3 Rg = reflect(-V, normalize(N + vec3(grao.x, 0.0, grao.y) * 0.30));
		float lustro = pow(max(dot(Rg, L), 0.0), 5.0) * m * mix(0.32, 0.50, poca);
		float sol = pow(max(dot(R, L), 0.0), mix(40.0, 180.0, poca)) * m;
		float crista = rip.z * m * mix(0.25, 0.55, forca_pingo);
		vec3 brilho = ceu * reflecte + luz_cor * (sol * 0.9 + lustro) + vec3(0.92, 0.96, 1.0) * crista;
		float a_molhado = clamp(max(m * (mix(0.34, 0.52, poca) + 0.14 * margem), max(brilho.r, max(brilho.g, brilho.b))), 0.0, 1.0);
		brilho = min(brilho, vec3(a_molhado));
		// Onde há bolsa ou lama, quem manda é a camada delas (a base só lhes dá um resto de lustro).
		float resto = 1.0 - max(m_agua, 0.75 * m_lama);
		pre = brilho * resto + pre * (1.0 - a_molhado * resto);
		a = a_molhado * resto + a * (1.0 - a_molhado * resto);
	}

	// ---------------------------------------------------------------- a água das bolsas (Ordem 41)
	if (m_agua > 0.001) {
		// A ruga lenta da água parada, os pingos (coroa e anel, de água) e os anéis à volta dos pés.
		float ruga = ruido(xz * 1.7 + vec2(tempo * 0.11, tempo * 0.07));
		float ruga2 = ruido(xz * 3.3 - vec2(tempo * 0.09, -tempo * 0.13));
		float liquida = 1.0 - 0.85 * gelo;
		vec3 rip = vec3(0.0);
		if (pingos > 0.001) {
			rip = camada_pingos(xz + 3.7, 1.10, 5.3, 1.0);
			if (qualidade > 0) {
				rip += camada_pingos(xz + 17.9, 0.78, 12.1, 1.0);
			}
		}
		vec3 pe = aneis_dos_pes(xz);
		vec2 inclina = (vec2(ruga, ruga2) - 0.5) * 0.22 + (rip.xy * mix(0.30, 0.55, forca_pingo) + pe.xy) * liquida;
		vec3 Na = normalize(vec3(inclina.x, 1.0, inclina.y));
		vec3 c_agua = mix(cor_agua_rasa, cor_agua_funda, smoothstep(0.0, 0.75, fundo));
		float rasante = pow(1.0 - max(dot(Na, V), 0.0), 3.0);
		// A conta do reflexo é a da água da casa: 10% a pique, até 85% a olhar rasante.
		c_agua = mix(c_agua, cor_reflexo * (0.80 + 0.30 * ruga2), clamp(0.10 + 0.75 * rasante, 0.0, 0.85) * smoothstep(0.02, 0.30, fundo + 0.1));
		vec3 Ra = reflect(-V, Na);
		c_agua += luz_cor * (pow(max(dot(Ra, L), 0.0), 60.0) * 0.35);
		c_agua += vec3(0.92, 0.96, 1.0) * ((rip.z * mix(0.30, 0.60, forca_pingo) + pe.z) * liquida);
		// Com a nevasca a bolsa gela: baça, fria, sem ondas.
		c_agua = mix(c_agua, cor_gelo * (0.62 + 0.30 * ruga), 0.75 * gelo);
		// A linha de água: um fio claro onde a bolsa toca a lama.
		float fio_agua = smoothstep(0.0, 0.5, m_agua) * smoothstep(1.0, 0.5, m_agua) * 0.18;
		por_cima(pre, a, c_agua + cor_reflexo * fio_agua, m_agua * mix(0.50, 0.94, smoothstep(0.0, 0.45, fundo)));
	}

	// ---------------------------------------------------------------- neve (a base) e a nevasca (Ordem 41)
	float a_neve = 0.0;
	if (neve > 0.001 || aglomerado > 0.001) {
		float n2 = fbm(xz * 0.55 + 31.7);
		float n3 = ruido(xz * 2.3 + 5.0);
		float manchas = 0.8 * n2 + 0.2 * n3;
		// Quanta neve há AQUI. Na base é igual em todo o lado; com a nevasca, o vento tira-a do centro
		// exposto e junta-a nos cantos, nas bordas e contra os obstáculos (clima_abrigo).
		float q = neve;
		float monte = 0.0;
		float relevo = 0.0;
		if (aglomerado > 0.001) {
			float dunas = fbm(xz * 0.85 + 12.0);
			float ab = clima_abrigo(xz) * (0.70 + 0.60 * dunas);
			float exposto = 1.0 - clamp(ab * 1.4, 0.0, 1.0);
			q = neve * (1.0 - aglomerado * exposto * (0.52 + 0.30 * dunas)) + aglomerado * ab * 1.05;
			monte = smoothstep(0.70, 1.35, q) * clamp(aglomerado * 4.0, 0.0, 1.0);
			relevo = smoothstep(0.35, 1.50, q) * clamp(aglomerado * 4.0, 0.0, 1.0);
		}
		// Manchas de borda macia: onde o ruído é baixo cobre primeiro; a neve = 1 cobre tudo.
		float manto = smoothstep(manchas * 0.80, manchas * 0.80 + 0.30, q * 1.12);
		// Pó: um véu fino e liso desde o primeiro minuto (sem pontilhado).
		float po = clamp(q * 3.0, 0.0, 1.0) * (0.22 + 0.20 * n3);
		a_neve = mix(clamp(max(manto, po), 0.0, 1.0) * 0.93, 0.985, monte) * cima;
		if (grelha_casa_m > 0.0) {
			vec2 qg = (xz - grelha_origem.xz) / grelha_casa_m;
			vec2 dq = abs(fract(qg + 0.5) - 0.5) * grelha_casa_m;
			float dl = min(dq.x, dq.y);
			float fio = max(0.06, fwidth(dl) * 1.6);
			// Nos montes a neve tapa mais, mas o fio da grelha continua lá.
			a_neve *= mix(mix(0.22, 0.50, monte), 1.0, smoothstep(fio * 0.4, fio, dl));
		}
		float luz = 0.80 + 0.20 * clamp(dot(n_base, L), 0.0, 1.0);
		vec3 c_neve = mix(cor_neve_sombra, cor_neve, smoothstep(0.15, 0.75, 0.5 * n2 + 0.5 * manto)) * luz;
		c_neve *= 0.96 + 0.06 * n3;
		if (relevo > 0.001) {
			// Os montes têm corpo: a inclinação tira-se do próprio monte (derivadas no ecrã → no chão) e o
			// lado virado ao sol fica claro, o outro azulado.
			vec2 ax = dFdx(xz);
			vec2 ay = dFdy(xz);
			float gx = dFdx(relevo);
			float gy = dFdy(relevo);
			float det = ax.x * ay.y - ax.y * ay.x;
			vec2 grad = abs(det) > 1e-10 ? vec2(gx * ay.y - gy * ax.y, gy * ax.x - gx * ay.x) / det : vec2(0.0);
			grad = clamp(grad * 0.55, vec2(-1.5), vec2(1.5));
			vec3 Nm = normalize(vec3(-grad.x, 1.0, -grad.y));
			float lado_sol = clamp((dot(Nm, L) - L.y) * 2.4, -1.0, 1.0);
			c_neve = mix(c_neve, cor_neve_sombra * 0.86, clamp(-lado_sol, 0.0, 1.0) * 0.75);
			c_neve += vec3(0.07, 0.06, 0.04) * clamp(lado_sol, 0.0, 1.0) + vec3(0.03) * monte;
		}
		// ---- o gelo: o chão que o vento varreu fica vidrado (placas que crescem com a exposição)
		if (gelo > 0.001) {
			float placa = smoothstep(0.42, 0.62, fbm(xz * 0.38 + 50.0) + gelo * 0.55 - 0.22);
			float raspao_g = pow(1.0 - clamp(dot(n_base, V), 0.0, 1.0), 3.0);
			vec2 gr = vec2(ruido(xz * 4.0 + 21.0), ruido(xz * 4.0 + 27.0)) - 0.5;
			vec3 Rg2 = reflect(-V, normalize(n_base + vec3(gr.x, 0.0, gr.y) * 0.10));
			float espicula = pow(max(dot(Rg2, L), 0.0), 110.0);
			float brilha = cintilar(xz, V);
			vec3 c_gelo = cor_gelo * (0.55 + 0.45 * raspao_g) + luz_cor * espicula * 1.2 + vec3(brilha);
			float a_gelo = gelo * cima * (1.0 - a_neve) * clamp(placa * (0.20 + 0.50 * raspao_g) + espicula * 0.9 + brilha * 0.8, 0.0, 0.9);
			por_cima(pre, a, c_gelo, a_gelo);
			// A geada na crista dos montes: a neve antiga cintila.
			c_neve += vec3(0.9, 0.97, 1.0) * brilha * gelo * 0.6;
		}
		por_cima(pre, a, c_neve, a_neve);
	}

	// ---------------------------------------------------------------- a neve rasteira e o véu (Ordem 41)
	if (rasteira > 0.001 && qualidade > 0) {
		// Fitas de neve arrastadas rente ao chão: andam com o vento (d_varre soma-se frame a frame).
		vec2 w = vento_abrigo;
		vec2 pc = xz - campo.xy;
		vec2 uv = vec2(dot(pc, w) - d_varre, dot(pc, vec2(-w.y, w.x)));
		float s1 = ruido(uv * vec2(0.20, 1.35));
		float s2 = ruido(uv * vec2(0.43, 2.70) + vec2(-0.55 * d_varre, 3.0));
		float fita = smoothstep(0.56, 0.90, 0.62 * s1 + 0.38 * s2 + 0.16 * rasteira);
		por_cima(pre, a, vec3(0.95, 0.97, 1.0), fita * rasteira * 0.58 * cima);
	}
	if (veu > 0.001) {
		float longe = smoothstep(veu_perto_m, veu_longe_m, dist_camara);
		por_cima(pre, a, vec3(0.84, 0.88, 0.94), veu * longe * 0.66);
	}

	ALBEDO = pre / max(a, 1e-4);
	ALPHA = a;
}
