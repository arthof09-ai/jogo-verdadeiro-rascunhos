// clima_terreno.gdshaderinc — Ordem 41 (expansão do clima). O que o clima forte precisa de saber do TERRENO:
//
//   BACIAS   — os pontos baixos onde a água da chuva forte se junta (as bolsas). Cada bacia é uma taça
//              (centro, raio, fundura); a bolsa nasce no fundo e cresce com o enchimento `a` (0..1).
//              O relevo de verdade entra por `y_rel` (altura do chão acima do plano de referência): numa
//              malha com alturas, as covas reais enchem pela mesma conta.
//   ABRIGOS  — as caixas dos obstáculos (centro, meia-largura, altura): a neve da nevasca junta-se na base
//              deles e a sotavento (a cauda), e nas bordas e nos cantos do campo.
//
// As mesmas contas vivem em clima.gd (`fundura_em`, `abrigo_em`), para os testes e para a medição.

const int CLIMA_MAX_BACIAS = 8;
const int CLIMA_MAX_ABRIGOS = 8;
// A bolsa cheia (água = 1) enche a taça até 86% da fundura: nunca transborda para o plano.
const float CLIMA_ENCHE = 0.86;
// A lama passa da linha de água por esta margem (em fracção da fundura da taça).
const float CLIMA_MARGEM_LAMA = 0.12;

uniform vec4 bacias[8];        // x, z, raio (m), fundura (m)
uniform int n_bacias = 0;
// Ordem 42: a bacia do RELEVO (tipo 1) — um ponto baixo de verdade do mapa, achado pela inundação do terreno.
// A água tem a superfície PLANA: sobe do fundo (nível − fundura) até ao nível de transbordo (m, no mundo), e o
// próprio relevo dá a forma à bolsa. Tipo 0 = a taça da Ordem 41 (como era).
uniform int bacias_tipo[8];
uniform float bacias_nivel[8];
uniform float chao_ref_y = 0.0;
uniform vec4 abrigos[8];       // x, z, meia-largura x, meia-largura z (m)
uniform float abrigos_alt[8];  // altura (m)
uniform int n_abrigos = 0;
// O campo: centro (x, z) e meias-larguras — para as bordas e os cantos.
uniform vec4 campo = vec4(15.0, 15.0, 15.0, 15.0);
// Para onde o vento sopra (unitário, x/z), alisado no tempo: os montes não rodam com cada rajada.
uniform vec2 vento_abrigo = vec2(1.0, 0.0);
// Quanto as bordas e os cantos do campo juntam neve (0 = campo aberto, sem bordas).
uniform float bordas = 1.0;

// A margem da bolsa não é um círculo de compasso: o plano torce-se um pouco (só senos — a CPU faz igual).
vec2 clima_torcer(vec2 p) {
	return p + 0.55 * vec2(sin(p.y * 0.83 + 1.3) + 0.5 * sin(p.x * 1.71 + 4.1), sin(p.x * 0.77 + 2.9) + 0.5 * sin(p.y * 1.93 + 0.4));
}

// A água (m) por cima deste ponto com o enchimento `a` (0..1). Negativo: o que falta para a água cá chegar.
// `margem` (0..1, em fracção da fundura) alarga a conta para fora da linha de água (a faixa da lama).
float clima_fundura(vec2 xz, float y_rel, float a, float margem) {
	vec2 q = clima_torcer(xz);
	// Ordem 42: «nenhuma bacia aqui» tem de dar seco também num chão com relevo (era −1 − y_rel: o chão mais
	// de 1 m abaixo da referência saía molhado). Num chão liso (y_rel = 0) é o mesmo −1 de antes.
	float d = -1.0 + y_rel;
	for (int i = 0; i < CLIMA_MAX_BACIAS; i++) {
		if (i >= n_bacias) {
			break;
		}
		vec4 b = bacias[i];
		if (bacias_tipo[i] == 1) {
			vec2 v0 = (xz - b.xy) / max(b.z, 0.01);
			float y_abs = y_rel + chao_ref_y;
			// só o chão da cova: o que está abaixo do fundo dela é de fora (do outro lado do transbordo)
			if (dot(v0, v0) < 1.0 && y_abs > bacias_nivel[i] - b.w - 0.03) {
				float nivel = bacias_nivel[i] - b.w + (a + margem) * b.w;
				d = max(d, nivel - y_abs + y_rel);
			}
			continue;
		}
		vec2 v = (q - b.xy) / max(b.z, 0.01);
		float u2 = min(dot(v, v), 1.0);
		float taca = (1.0 - u2) * (1.0 - u2);
		d = max(d, b.w * (taca - (1.0 - a) + margem));
	}
	return d - y_rel;
}

float clima_sd_caixa(vec2 p, vec4 c) {
	vec2 d = abs(p - c.xy) - c.zw;
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}

// Quanto a neve se junta aqui (0 = campo varrido … 1,6 = canto com obstáculo): as bordas e os cantos do
// campo, a base dos obstáculos e a cauda a sotavento de cada um.
float clima_abrigo(vec2 xz) {
	vec2 w = vento_abrigo;
	// Bordas e cantos: a borda de onde o vento vem abriga mais do que a borda para onde ele vai.
	vec2 e = max(campo.zw - abs(xz - campo.xy), vec2(0.0));
	vec2 lado = sign(xz - campo.xy);
	vec2 peso = vec2(1.0) - 0.45 * lado * w;
	vec2 b = exp(-e / 1.15) * peso;
	float canto = exp(-(e.x + e.y) / 2.4) * 0.5 * (peso.x + peso.y);
	float soma = bordas * (0.55 * max(b.x, b.y) + 0.95 * canto);
	// Obstáculos: o monte à volta da base e a cauda a sotavento.
	for (int i = 0; i < CLIMA_MAX_ABRIGOS; i++) {
		if (i >= n_abrigos) {
			break;
		}
		vec4 c = abrigos[i];
		float alcance = clamp(abrigos_alt[i] * 2.6, 0.9, 5.5);
		vec2 d = xz - c.xy;
		float s = clamp(dot(d, w), 0.0, alcance);
		float f = s / alcance;
		float meia = min(c.z, c.w);
		float d0 = clima_sd_caixa(xz, c);
		float d1 = clima_sd_caixa(xz - w * s, c) + f * (0.25 + 0.6 * meia);
		float lado_abrigado = 0.5 + 0.5 * clamp(dot(d, w) / (0.6 + meia), -1.0, 1.0);
		float base = exp(-max(d0, 0.0) / 0.38) * mix(0.45, 0.95, lado_abrigado);
		float cauda = smoothstep(0.30, -0.20, d1) * (1.0 - f) * (1.0 - f);
		soma += max(base, cauda);
	}
	return min(soma, 1.6);
}
