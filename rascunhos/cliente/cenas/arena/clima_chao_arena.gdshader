// clima_chao_arena.gdshader — Ordem Neve (Fatia 2 e Fatia 3).
// Camada do chão da arena integrada (material_overlay sobre Arena/Terreno e Fundo/TerrenoLargo):
// - Resolve a correcção de 14/11: em nevasca consolidada (F = 1), TODO o chão se lê coberto, centro incluído,
//   SEM véu branco liso:
//   · covas, bacias do relevo, cantos, bordas e sombras de vento (barlavento/sotavento dos obstáculos) com
//     manto espesso e dunas esculpidas;
//   · cristas e zonas varridas do centro com manto mais fino e crosta fria/esbranquiçada esculpida pelo vento
//     (sastrugi), nunca relva verde crua no meio da nevasca;
//   · luz integrada com o ciclo do dia (Ordem 43): o branco não estoura o relevo ao meio-dia nem perde volume
//     à noite;
// - Congelamento gradual (Fatia 3): geada/gelo progressivo nas bordas do terreno, zonas varridas e humidade/covas
//   da Ordem 42 (`congelamento`).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

#include "res://arte/clima/clima_terreno.gdshaderinc"

uniform float molhado : hint_range(0.0, 1.0) = 0.0;
uniform float neve : hint_range(0.0, 1.0) = 0.0;
uniform float pingos : hint_range(0.0, 1.0) = 0.0;
uniform float forca_pingo : hint_range(0.0, 1.0) = 0.5;
uniform float tempo = 0.0;
uniform vec3 luz_dir = vec3(-0.79, 0.52, 0.32);
uniform vec3 luz_cor : source_color = vec3(1.0, 0.90, 0.71);
uniform vec3 cor_reflexo : source_color = vec3(0.72, 0.80, 0.88);
uniform vec3 cor_neve : source_color = vec3(0.92, 0.95, 0.99);
uniform vec3 cor_neve_sombra : source_color = vec3(0.56, 0.66, 0.82);
uniform vec3 cor_neve_varrida : source_color = vec3(0.68, 0.77, 0.89);
uniform vec3 grelha_origem = vec3(0.0);
uniform float grelha_casa_m = 0.0;
uniform int qualidade = 1;

// Clima forte e congelamento
uniform float agua : hint_range(0.0, 1.0) = 0.0;
uniform float lama : hint_range(0.0, 1.0) = 0.0;
uniform float lama_humida : hint_range(0.0, 1.0) = 1.0;
uniform float aglomerado : hint_range(0.0, 1.0) = 0.0;
uniform float gelo : hint_range(0.0, 1.0) = 0.0;
uniform float congelamento : hint_range(0.0, 1.0) = 0.0;
uniform float rasteira : hint_range(0.0, 1.0) = 0.0;
uniform float d_varre = 0.0;
uniform float veu : hint_range(0.0, 1.0) = 0.0;
uniform float veu_perto_m = 30.0;
uniform float veu_longe_m = 60.0;
uniform vec4 pes[8];
uniform int n_pes = 0;
uniform vec3 cor_agua_funda : source_color = vec3(0.24, 0.40, 0.44);
uniform vec3 cor_agua_rasa : source_color = vec3(0.49, 0.60, 0.53);
uniform vec3 cor_lama : source_color = vec3(0.20, 0.135, 0.085);
uniform vec3 cor_lama_seca : source_color = vec3(0.40, 0.33, 0.24);
uniform vec3 cor_gelo : source_color = vec3(0.70, 0.86, 0.98);

// Ciclo do dia da floresta (Ordem 43) para o branco não estourar ao meio-dia nem perder volume à noite
uniform vec3 cor_sombra_ciclo : source_color = vec3(0.32, 0.40, 0.54);
uniform vec3 cor_ceu_ciclo : source_color = vec3(0.64, 0.71, 0.74);
uniform float noite_ciclo : hint_range(0.0, 1.0) = 0.0;
uniform float sombra_forca_ciclo : hint_range(0.0, 1.0) = 1.0;
uniform sampler2D mapa_sombra_arena : filter_linear, repeat_disable, hint_default_white;
uniform float mapa_meio_arena = 72.0;
uniform float tem_mapa_sombra = 0.0;

// Correcções de 17/11 (sentença da bancada):
// 1c — DECISÃO DO COORDENADOR: a lagoa NÃO branqueia com a neve nesta ordem (o gelo da água é trabalho futuro,
//      reservado). O leito do lago é este mesmo chão e a água é translúcida: sem esta máscara, o leito branqueado
//      lia-se através da água como uma placa pálida. Debaixo do nível da água (e na faixa encharcada da margem)
//      o clima não pinta neve nem gelo — a água fica com o comportamento dela. Lê só a geometria do relevo
//      (centro/raio da cova e nível da água), nenhum ficheiro do lago.
uniform vec3 lago_centro_raio = vec3(0.0, 0.0, -1.0);
uniform float lago_nivel = -1000.0;
// 1a — modulação do campo exposto (véu liso ao meio-dia): força 0..1 (0 = como a primeira execução).
uniform float modulacao_campo : hint_range(0.0, 1.0) = 1.0;

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

// Deriva de neve (1a): campo de espessura alongado ao longo do vento (≈ 6 m × 2 m) — zonas varridas finas e
// línguas de neve acumulada no campo aberto, onde o abrigo dos obstáculos não chega.
float deriva(vec2 uv) {
	return 0.62 * ruido(uv) + 0.38 * ruido(uv * 2.3 + vec2(5.1, 1.7));
}

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

float cintilar(vec2 p, vec3 V) {
	vec2 g = p * 26.0;
	float r = h21(floor(g));
	vec2 f = fract(g) - 0.5;
	float fase = dot(V.xz, vec2(37.0, 53.0)) + r * 40.0 + tempo * 0.7;
	float fino = smoothstep(0.7, 0.2, fwidth(g.x) + fwidth(g.y));
	return step(0.955, r) * smoothstep(0.38, 0.0, length(f)) * max(sin(fase), 0.0) * fino;
}

void por_cima(inout vec3 pre, inout float a, vec3 cor, float quanto) {
	pre = cor * quanto + pre * (1.0 - quanto);
	a = quanto + a * (1.0 - quanto);
}

// Acumulação direccional da arena: junta neve nos cantos/bordas (modulada por ruído orgânico para não desenhar
// uma caixa rígida), na base de barlavento (onde o vento empurra contra o obstáculo) e na cauda comprida de
// sotavento, além das covas/bacias do relevo e das vertentes abrigadas do vento.
float abrigo_direccional_arena(vec2 xz, float y_rel, vec3 n_base, float dunas) {
	vec2 w = normalize(vento_abrigo + vec2(1e-5, 0.0));
	// Bordas e cantos da arena modulados pelo relevo e por dunas (sem linha recta artificial)
	vec2 e = max(campo.zw - abs(xz - campo.xy), vec2(0.0)) + (dunas - 0.5) * 1.8;
	vec2 lado = sign(xz - campo.xy);
	vec2 peso = vec2(1.0) - 0.48 * lado * w;
	vec2 b = exp(-max(e, vec2(0.0)) / 2.2) * peso;
	float canto = exp(-max(e.x + e.y, 0.0) / 4.2) * 0.55 * (peso.x + peso.y);
	float soma = bordas * (0.50 * max(b.x, b.y) + 0.95 * canto) * (0.65 + 0.70 * dunas);

	// Obstáculos reais do mapa: banco de barlavento (contra o obstáculo) + cauda de sotavento (atrás dele)
	for (int i = 0; i < CLIMA_MAX_ABRIGOS; i++) {
		if (i >= n_abrigos) {
			break;
		}
		vec4 c = abrigos[i];
		float alcance = clamp(abrigos_alt[i] * 2.8, 1.1, 6.0);
		vec2 d = xz - c.xy;
		float proj = dot(d, w);
		float s = clamp(proj, 0.0, alcance);
		float f = s / alcance;
		float meia = min(c.z, c.w);
		float d0 = clima_sd_caixa(xz, c);
		float d1 = clima_sd_caixa(xz - w * s, c) + f * (0.22 + 0.55 * meia);
		// Barlavento (proj < 0): a neve empurrada pelo vento acumula-se contra o pé frontal do obstáculo
		float barla = smoothstep(0.1, -0.75, proj / (0.5 + meia)) * exp(-max(d0, 0.0) / 0.55);
		// Sotavento (proj > 0): abrigo comprido atrás do obstáculo
		float sota = smoothstep(-0.2, 0.85, proj / (0.5 + meia)) * exp(-max(d0, 0.0) / 0.65);
		float cauda = smoothstep(0.42, -0.22, d1) * (1.0 - f) * (1.0 - 0.65 * f);
		soma += max(max(barla * 0.92, sota * 1.10), cauda * 1.05);
	}

	// Covas e bacias do relevo (Ordem 42): as depressões recolhem um manto mais espesso
	float d_bacia = clima_fundura(xz, y_rel, 1.0, 0.45);
	float cova = smoothstep(-0.06, 0.04, d_bacia) * 0.55 + clamp((-y_rel - 0.15) * 0.35, 0.0, 0.45);
	// Encostas a sotavento do vento acumulam mais do que cristas varridas a barlavento
	float encosta_sota = clamp(dot(n_base.xz, w) * 1.8, -0.35, 0.55);
	soma += cova + max(encosta_sota, 0.0) * 0.65;
	return clamp(soma, 0.0, 1.85);
}

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n_base = normalize(v_normal);
	float cima = smoothstep(0.20, 0.68, n_base.y);
	vec3 para_camara = CAMERA_POSITION_WORLD - v_mundo;
	float dist_camara = length(para_camara);
	vec3 V = para_camara / max(dist_camara, 1e-4);
	vec3 L = normalize(luz_dir);
	vec2 xz = v_mundo.xz;
	float y_rel = v_mundo.y - chao_ref_y;
	vec3 pre = vec3(0.0);
	float a = 0.0;
	float cong = max(gelo, congelamento);
	// 1c: fora da lagoa = 1; debaixo de água (e na margem encharcada) = 0.
	float fora_lago = 1.0;
	if (lago_centro_raio.z > 0.0) {
		float dentro = smoothstep(lago_centro_raio.z, lago_centro_raio.z - 0.6, length(xz - lago_centro_raio.xy));
		fora_lago = 1.0 - dentro * smoothstep(lago_nivel + 0.14, lago_nivel + 0.04, v_mundo.y);
	}

	// Sombra viva da floresta (Ordem 43) para a neve ler as sombras das árvores e do relevo
	float vis_sombra = 1.0;
	if (tem_mapa_sombra > 0.5) {
		vec2 uv_s = xz / (2.0 * mapa_meio_arena) + 0.5;
		float s_raw = texture(mapa_sombra_arena, uv_s).r;
		vis_sombra = mix(1.0, smoothstep(0.25, 0.75, s_raw), sombra_forca_ciclo * 0.85);
	}

	// ---------------------------------------------------------------- bolsas e lama (Ordem 41/42)
	float m_agua = 0.0;
	float m_lama = 0.0;
	float fundo = 0.0;
	if ((lama > 0.001 || cong > 0.05) && n_bacias > 0) {
		float orla = ruido(xz * 2.3 + 4.0) - 0.5;
		if (lama > 0.001) {
			float dl = clima_fundura(xz, y_rel, lama * CLIMA_ENCHE, CLIMA_MARGEM_LAMA);
			m_lama = smoothstep(0.0, 0.011, dl + orla * 0.007) * cima * clamp(lama * 8.0, 0.0, 1.0);
		}
		if (agua > 0.001) {
			float d = clima_fundura(xz, y_rel, agua * CLIMA_ENCHE, 0.0) + orla * 0.0022;
			m_agua = smoothstep(0.0, 0.0035, d) * cima;
			fundo = clamp(d / 0.065, 0.0, 1.0);
		}
		if (m_lama > 0.001) {
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
		float nivel = n1 + (m - 1.0) * 0.30;
		float poca = smoothstep(0.52, 0.57, nivel) * cima;
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
		float reflecte = m * (mix(0.06, 0.30, poca) + 0.55 * raspao);
		vec3 R = reflect(-V, N);
		vec3 ceu = cor_reflexo * mix(1.15, 0.60, clamp(R.y, 0.0, 1.0));
		vec2 grao = vec2(ruido(xz * 3.1 + 2.0), ruido(xz * 3.1 + 9.0)) - 0.5;
		vec3 Rg = reflect(-V, normalize(N + vec3(grao.x, 0.0, grao.y) * 0.30));
		float lustro = pow(max(dot(Rg, L), 0.0), 5.0) * m * mix(0.32, 0.50, poca);
		float sol = pow(max(dot(R, L), 0.0), mix(40.0, 180.0, poca)) * m;
		float crista = rip.z * m * mix(0.25, 0.55, forca_pingo);
		vec3 brilho = ceu * reflecte + luz_cor * (sol * 0.9 + lustro) + vec3(0.92, 0.96, 1.0) * crista;
		float a_molhado = clamp(max(m * (mix(0.34, 0.52, poca) + 0.14 * margem), max(brilho.r, max(brilho.g, brilho.b))), 0.0, 1.0);
		brilho = min(brilho, vec3(a_molhado));
		float resto = 1.0 - max(m_agua, 0.75 * m_lama);
		pre = brilho * resto + pre * (1.0 - a_molhado * resto);
		a = a_molhado * resto + a * (1.0 - a_molhado * resto);
	}

	// ---------------------------------------------------------------- a água das bolsas (Ordem 41)
	if (m_agua > 0.001) {
		float ruga = ruido(xz * 1.7 + vec2(tempo * 0.11, tempo * 0.07));
		float ruga2 = ruido(xz * 3.3 - vec2(tempo * 0.09, -tempo * 0.13));
		float liquida = 1.0 - 0.85 * cong;
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
		c_agua = mix(c_agua, cor_reflexo * (0.80 + 0.30 * ruga2), clamp(0.10 + 0.75 * rasante, 0.0, 0.85) * smoothstep(0.02, 0.30, fundo + 0.1));
		vec3 Ra = reflect(-V, Na);
		c_agua += luz_cor * (pow(max(dot(Ra, L), 0.0), 60.0) * 0.35);
		c_agua += vec3(0.92, 0.96, 1.0) * ((rip.z * mix(0.30, 0.60, forca_pingo) + pe.z) * liquida);
		c_agua = mix(c_agua, cor_gelo * (0.62 + 0.30 * ruga), 0.82 * cong);
		float fio_agua = smoothstep(0.0, 0.5, m_agua) * smoothstep(1.0, 0.5, m_agua) * 0.18;
		por_cima(pre, a, c_agua + cor_reflexo * fio_agua, m_agua * mix(0.50, 0.94, smoothstep(0.0, 0.45, fundo)));
	}

	// ---------------------------------------------------------------- neve, acumulação direccional e cobertura do centro (Ordem Neve)
	if ((neve > 0.001 || aglomerado > 0.001 || cong > 0.001) && fora_lago > 0.001) {
		vec2 w = normalize(vento_abrigo + vec2(1e-5, 0.0));
		vec2 uv_vento = vec2(dot(xz, w), dot(xz, vec2(-w.y, w.x)));
		// Sastrugi (ondas de neve esculpidas na direcção do vento): evitam que o chão seja um véu branco liso
		float sastrugi = fbm(uv_vento * vec2(0.34, 1.15) + vec2(4.2, 9.1));
		float dunas = fbm(xz * 0.68 + 12.0);
		float n2 = fbm(xz * 0.52 + 31.7);
		float n3 = ruido(xz * 2.4 + 5.0);
		float manchas = 0.65 * n2 + 0.35 * sastrugi;

		float ab = abrigo_direccional_arena(xz, y_rel, n_base, dunas);
		float exposto = 1.0 - clamp(ab * 1.15, 0.0, 1.0);
		// Cristas altas ou viradas contra o vento são mais varridas; covas e abrigos são mais espessos
		float crista_varrida = clamp((y_rel - 0.10) * 0.32 - dot(n_base.xz, w) * 0.45, 0.0, 0.65) * exposto;

		// Correcção de 14/11: na nevasca consolidada (neve=1, aglomerado=1), o centro NUNCA perde a cobertura
		// para voltar ao verde (antes descia a 0,33). O centro fica coberto a sério (q ~ 0,88..1,10), mais fino
		// e esculpido pelo vento nas cristas/zonas varridas, enquanto covas/obstáculos/cantos acumulam montes
		// espessos (q ~ 1,30..1,95).
		float q_base = neve * (1.0 - aglomerado * exposto * 0.16);
		float q_monte = aglomerado * (ab * 0.95 + (1.0 - crista_varrida) * (0.14 + 0.24 * sastrugi));
		float q = q_base + q_monte;

		float monte = smoothstep(0.78, 1.45, q) * clamp(aglomerado * 2.8, 0.0, 1.0);
		float espesso = smoothstep(0.55, 1.25, q);
		float relevo = smoothstep(0.28, 1.55, q) * clamp((neve * 0.35 + aglomerado * 0.85) * 2.5, 0.0, 1.0)
			+ 0.22 * sastrugi * clamp(neve + aglomerado, 0.0, 1.0);

		// Cobertura progressiva:
		// Em F = 0,5 (q ~ 0,55 no centro, > 0,95 nos abrigos), o centro mostra manto em formação + geada e os
		// cantos/obstáculos já mostram acumulação clara.
		// Em F = 1,0 (q >= 0,88 no centro), manto cobre todo o centro sem buracos verdes.
		float manto = smoothstep(manchas * 0.58, manchas * 0.58 + 0.24, q * 1.06);
		float geada_varrida = clamp((q * 0.85 + cong * 0.55) * (0.55 + 0.45 * sastrugi), 0.0, 1.0);
		float cobertura_centro = smoothstep(0.62, 0.92, max(neve, aglomerado));
		float a_neve_bruta = max(manto, geada_varrida * mix(0.42, 0.88, cobertura_centro));
		// Zonas varridas têm cobertura ligeiramente mais fina (deixando ler a crosta gelada fria), enquanto covas
		// e abrigos têm manto denso (0,97..0,99)
		float opacidade_alvo = mix(mix(0.84, 0.91, sastrugi), 0.985, max(monte, espesso * 0.85));
		float a_neve = clamp(a_neve_bruta, 0.0, 1.0) * opacidade_alvo * cima;

		// Fio da grelha táctica dentro do campo para a grelha continuar legível sobre a neve
		vec2 fora_campo = abs(xz - campo.xy) - campo.zw;
		if (grelha_casa_m > 0.0 && max(fora_campo.x, fora_campo.y) < 0.02) {
			vec2 qg = (xz - grelha_origem.xz) / grelha_casa_m;
			vec2 dq = abs(fract(qg + 0.5) - 0.5) * grelha_casa_m;
			float dl = min(dq.x, dq.y);
			float fio = max(0.06, fwidth(dl) * 1.6);
			a_neve *= mix(mix(0.32, 0.58, monte), 1.0, smoothstep(fio * 0.4, fio, dl));
		}

		// Normal 3D composta: normal do relevo do terreno + inclinação dos montes e das dunas de vento
		vec3 N_neve = n_base;
		if (relevo > 0.001) {
			vec2 ax = dFdx(xz);
			vec2 ay = dFdy(xz);
			float gx = dFdx(relevo);
			float gy = dFdy(relevo);
			float det = ax.x * ay.y - ax.y * ay.x;
			vec2 grad = abs(det) > 1e-10 ? vec2(gx * ay.y - gy * ax.y, gy * ax.x - gx * ay.x) / det : vec2(0.0);
			grad = clamp(grad * 0.72, vec2(-1.6), vec2(1.6));
			N_neve = normalize(n_base + vec3(-grad.x, 0.0, -grad.y) * 0.65);
		}

		// Diferença cromática de espessura (sem véu branco liso):
		// - zonas varridas/finas: branco-azulado frio de crosta batida pelo vento (`cor_neve_varrida`)
		// - covas e montes densos: branco encorpado no topo e azul-índigo nas concavidades (`cor_neve` / `cor_neve_sombra`)
		float fator_espessura = clamp((q - 0.55) / 0.85, 0.0, 1.0);
		vec3 tinta_base = mix(cor_neve_varrida, cor_neve, smoothstep(0.10, 0.85, fator_espessura * 0.70 + sastrugi * 0.30));
		tinta_base = mix(cor_neve_sombra, tinta_base, smoothstep(0.12, 0.82, 0.45 * sastrugi + 0.55 * manto));
		tinta_base *= 0.94 + 0.08 * n3;

		// Iluminação do ciclo do dia (Ordem 43):
		// - lê a normal 3D (vertentes + montes de neve) e a sombra viva das árvores/relevo;
		// - ao meio-dia tem tecto contido (nunca estoura o relevo num branco liso);
		// - à noite mantém contraste direccional da lua e volume azul-prateado.
		float ndl = dot(N_neve, L);
		float k_luz = smoothstep(-0.22, 0.88, ndl) * vis_sombra;
		vec3 amb_ciclo = cor_ceu_ciclo * (0.34 + 0.22 * N_neve.y);
		vec3 dir_ciclo = mix(cor_sombra_ciclo * 0.52, luz_cor * 1.12, k_luz);
		vec3 luz_total = amb_ciclo + dir_ciclo;
		// Tecto de luminância ao meio-dia para preservar sempre o volume das encostas e das dunas
		luz_total = clamp(luz_total, vec3(0.24, 0.30, 0.44), vec3(0.94, 0.95, 0.98));
		vec3 c_neve = tinta_base * luz_total;

		// Contraste extra de crista/sombra nos montes e dunas
		float lado_sol = clamp((dot(N_neve, L) - n_base.y * L.y * 0.65) * 2.2, -1.0, 1.0);
		c_neve = mix(c_neve, c_neve * vec3(0.74, 0.82, 0.95), clamp(-lado_sol, 0.0, 1.0) * 0.55);
		c_neve += luz_cor * vec3(0.06, 0.055, 0.045) * clamp(lado_sol, 0.0, 1.0) * vis_sombra;

		// Olho da noite (Ordem 43): puxa ao azul nocturno sem perder o relevo das dunas
		if (noite_ciclo > 0.001) {
			float lum_n = dot(c_neve, vec3(0.30, 0.52, 0.18));
			c_neve = mix(c_neve, lum_n * vec3(0.72, 0.92, 1.36), noite_ciclo * 0.46);
		}
		c_neve = min(c_neve, vec3(0.91, 0.93, 0.96));

		// 1a (17/11): a modulação do campo exposto aplica-se DEPOIS do tecto de luz — antes, o tecto
		// (luz_total ≤ 0,94–0,98 e c_neve ≤ 0,91) apagava ao meio-dia toda a variação de tinta e o centro lia-se
		// como um véu uniforme. Três coisas, todas no campo aberto (os abrigos já são espessos):
		//  · espessura: línguas de deriva (mais brancas e opacas) × zonas varridas (crosta fina, mais fria e
		//    mais escura, onde o chão se adivinha);
		//  · relevo da deriva iluminado pelo sol do ciclo (o lado virado à luz clareia, o outro escurece);
		//  · sulcos finos de sastrugi ao longo do vento.
		float m_amp = modulacao_campo * clamp(max(aglomerado, neve * 0.6) * 1.25, 0.0, 1.0) * mix(0.45, 1.0, exposto);
		if (m_amp > 0.001) {
			vec2 ud = uv_vento * vec2(0.16, 0.52);
			float hd = deriva(ud);
			vec2 Lxz = L.xz / max(length(L.xz), 1e-4);
			vec2 l_uv = vec2(dot(Lxz, w), dot(Lxz, vec2(-w.y, w.x)));
			float hd_l = deriva((uv_vento + l_uv * 0.5) * vec2(0.16, 0.52));
			float sombra_deriva = clamp(0.5 + (hd_l - hd) * 5.0, 0.0, 1.0);
			float grosso = smoothstep(0.30, 0.72, hd);
			float sulco = ruido(uv_vento * vec2(0.85, 4.6) + vec2(2.0, 7.0));
			vec3 tom = mix(vec3(0.80, 0.82, 0.86), vec3(1.04, 1.03, 1.02), grosso);
			tom *= mix(0.82, 1.08, sombra_deriva * mix(1.0, vis_sombra, 0.5));
			tom *= 0.93 + 0.10 * sulco;
			c_neve *= mix(vec3(1.0), tom, m_amp);
			c_neve = min(c_neve, vec3(0.96, 0.97, 0.985));
			a_neve *= mix(1.0, mix(0.82, 1.0, grosso), m_amp * (1.0 - monte));
		}

		// ---- Congelamento gradual (Fatia 3): geada/gelo nas bordas do terreno, covas da Ordem 42 e zonas varridas
		if (cong > 0.001) {
			float d_cova = clima_fundura(xz, y_rel, 1.0, 0.35);
			float na_cova_ou_borda = clamp(smoothstep(-0.04, 0.03, d_cova) + crista_varrida * 0.85 + (1.0 - n_base.y) * 2.2, 0.0, 1.0);
			float placa = smoothstep(0.32, 0.58, fbm(xz * 0.42 + 50.0) + cong * 0.62 - 0.15 + na_cova_ou_borda * 0.28);
			float raspao_g = pow(1.0 - clamp(dot(N_neve, V), 0.0, 1.0), 2.8);
			vec2 gr = vec2(ruido(xz * 4.0 + 21.0), ruido(xz * 4.0 + 27.0)) - 0.5;
			vec3 Rg2 = reflect(-V, normalize(N_neve + vec3(gr.x, 0.0, gr.y) * 0.10));
			float espicula = pow(max(dot(Rg2, L), 0.0), 96.0) * vis_sombra;
			float brilha = cintilar(xz, V);
			vec3 c_gelo = cor_gelo * (0.52 + 0.42 * raspao_g) * clamp(luz_total * 1.08, vec3(0.30), vec3(0.95))
				+ luz_cor * espicula * 0.95 + vec3(brilha * 0.75);
			// O gelo veste tanto o chão varrido/bordas como dá crosta vidrada às covas e cristas
			float a_gelo = fora_lago * cong * cima * clamp(placa * (0.35 + 0.45 * raspao_g + 0.35 * na_cova_ou_borda) + espicula * 0.8 + brilha * 0.6, 0.0, 0.88);
			por_cima(pre, a, c_gelo, a_gelo * (1.0 - 0.65 * a_neve));
			c_neve = mix(c_neve, mix(c_neve, cor_gelo * luz_total, 0.32), cong * (0.35 + 0.45 * crista_varrida));
			c_neve += vec3(0.85, 0.94, 1.0) * brilha * cong * 0.45;
		}
		por_cima(pre, a, c_neve, a_neve * fora_lago);
	}

	// ---------------------------------------------------------------- neve rasteira (fitas arrastadas pelo vento no chão)
	if (rasteira > 0.001 && qualidade > 0) {
		vec2 w = normalize(vento_abrigo + vec2(1e-5, 0.0));
		vec2 pc = xz - campo.xy;
		vec2 uv = vec2(dot(pc, w) - d_varre, dot(pc, vec2(-w.y, w.x)));
		float s1 = ruido(uv * vec2(0.20, 1.35));
		float s2 = ruido(uv * vec2(0.43, 2.70) + vec2(-0.55 * d_varre, 3.0));
		float fita = smoothstep(0.58, 0.91, 0.62 * s1 + 0.38 * s2 + 0.14 * rasteira);
		vec3 cor_fita = clamp(cor_ceu_ciclo * 0.45 + luz_cor * 0.55, vec3(0.35, 0.42, 0.56), vec3(0.92, 0.95, 0.99));
		por_cima(pre, a, cor_fita, fita * rasteira * 0.42 * cima * fora_lago);
	}

	ALBEDO = pre / max(a, 1e-4);
	ALPHA = a;
}
