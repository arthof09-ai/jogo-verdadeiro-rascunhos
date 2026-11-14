// clima_chao.gdshader — Ordem 40 (clima). A RESPOSTA DO CHÃO, como material_overlay: desenha-se POR CIMA do
// chão que lá estiver (cor lisa, textura, terreno), sem trocar o material dele. Serve qualquer chão.
//
//   molhado (0..1): escurece, ganha reflexo do céu (mais forte nas poças e de raspão), brilho do sol e os
//                   anéis dos pingos onde a chuva bate (`pingos` = quantos, `forca_pingo` = a força do bater);
//   neve (0..1):    o chão branqueia aos poucos — primeiro um pó, depois manchas que crescem até cobrir tudo.
//                   Ao longo das linhas da grelha a neve fica rala, para a grelha continuar a ler-se.
//
// Sem luz do motor (unshaded): a luz é a que o Clima manda (sol e reflexo), barato no telemóvel. A saída é
// «aditiva + escurecer» feita com blend_mix: ALPHA = quanto tapa, ALBEDO = cor / ALPHA.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back, shadows_disabled;

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
// 0 = Baixo (uma camada de pingos, ruído simples), 1 = Médio/Alto.
uniform int qualidade = 1;

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
// Devolve (inclinação.xz da ondinha, brilho da crista).
vec3 camada_pingos(vec2 p, float celula, float semente) {
	vec2 id = floor(p / celula);
	vec2 r0 = h22(id + semente);
	float periodo = mix(0.55, 1.05, r0.x);
	float fase = tempo / periodo + r0.y;
	float ciclo = floor(fase);
	float f = fract(fase);
	float ativo = step(h21(id * 1.7 + ciclo * 0.61 + semente), pingos);
	vec2 r1 = h22(id + semente + ciclo * 1.37);
	vec2 centro = (id + 0.32 + 0.36 * r1) * celula;
	vec2 d = p - centro;
	float dist = length(d);
	float raio = f * celula * mix(0.20, 0.30, forca_pingo);
	float larg = celula * 0.035;
	float x = (dist - raio) / larg;
	float onda = exp(-x * x);
	float amp = (1.0 - f) * (1.0 - f) * ativo;
	float clarao = smoothstep(0.15, 0.0, f) * smoothstep(celula * 0.07, 0.0, dist) * ativo;
	vec2 dir = d / max(dist, 1e-4);
	return vec3(dir * (-2.0 * x * onda) * amp, onda * amp + clarao);
}

void vertex() {
	v_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n_base = normalize(v_normal);
	float cima = smoothstep(0.25, 0.7, n_base.y);
	vec3 V = normalize(CAMERA_POSITION_WORLD - v_mundo);

	// ---------------------------------------------------------------- molhado
	vec3 brilho = vec3(0.0);
	float a_molhado = 0.0;
	if (molhado > 0.001) {
		float m = molhado;
		float n1 = fbm(v_mundo.xz * 0.42);
		// As poças aparecem e crescem com o molhado.
		float nivel = n1 + (m - 1.0) * 0.30;
		float poca = smoothstep(0.52, 0.57, nivel) * cima;
		// À volta da poça a terra fica mais encharcada (mais escura).
		float margem = smoothstep(0.43, 0.52, nivel) * (1.0 - poca) * cima;
		vec3 rip = vec3(0.0);
		if (pingos > 0.001) {
			rip = camada_pingos(v_mundo.xz, 0.85, 3.1);
			if (qualidade > 0) {
				rip += camada_pingos(v_mundo.xz + 11.3, 0.55, 8.7);
			}
		}
		vec3 N = normalize(n_base + vec3(rip.x, 0.0, rip.y) * mix(0.10, 0.28, forca_pingo));
		float nv = clamp(dot(N, V), 0.0, 1.0);
		float raspao = pow(1.0 - nv, 4.0);
		// Quanto do céu o chão devolve: pouco no molhado, muito na poça e de raspão.
		float reflecte = m * (mix(0.06, 0.30, poca) + 0.55 * raspao);
		vec3 L = normalize(luz_dir);
		vec3 R = reflect(-V, N);
		// O céu no reflexo: claro para o horizonte, mais fundo a pique.
		vec3 ceu = cor_reflexo * mix(1.15, 0.60, clamp(R.y, 0.0, 1.0));
		// O lustro do molhado: um brilho largo para o lado do sol, com o grão do chão (não é um espelho liso).
		vec2 grao = vec2(ruido(v_mundo.xz * 3.1 + 2.0), ruido(v_mundo.xz * 3.1 + 9.0)) - 0.5;
		vec3 Rg = reflect(-V, normalize(N + vec3(grao.x, 0.0, grao.y) * 0.30));
		float lustro = pow(max(dot(Rg, L), 0.0), 5.0) * m * mix(0.32, 0.50, poca);
		float sol = pow(max(dot(R, L), 0.0), mix(40.0, 180.0, poca)) * m;
		float crista = rip.z * m * mix(0.25, 0.55, forca_pingo);
		brilho = ceu * reflecte + luz_cor * (sol * 0.9 + lustro) + vec3(0.92, 0.96, 1.0) * crista;
		a_molhado = clamp(max(m * (mix(0.34, 0.52, poca) + 0.14 * margem), max(brilho.r, max(brilho.g, brilho.b))), 0.0, 1.0);
		brilho = min(brilho, vec3(a_molhado));
	}

	// ---------------------------------------------------------------- neve
	float a_neve = 0.0;
	vec3 c_neve = cor_neve;
	if (neve > 0.001) {
		float n2 = fbm(v_mundo.xz * 0.55 + 31.7);
		float n3 = ruido(v_mundo.xz * 2.3 + 5.0);
		float campo = 0.8 * n2 + 0.2 * n3;
		// Manchas de borda macia: onde o ruído é baixo cobre primeiro; a neve = 1 cobre tudo.
		float manto = smoothstep(campo * 0.80, campo * 0.80 + 0.30, neve * 1.12);
		// Pó: um véu fino e liso desde o primeiro minuto (sem pontilhado).
		float po = clamp(neve * 3.0, 0.0, 1.0) * (0.22 + 0.20 * n3);
		a_neve = clamp(max(manto, po), 0.0, 1.0) * 0.93 * cima;
		if (grelha_casa_m > 0.0) {
			vec2 q = (v_mundo.xz - grelha_origem.xz) / grelha_casa_m;
			vec2 dq = abs(fract(q + 0.5) - 0.5) * grelha_casa_m;
			float dl = min(dq.x, dq.y);
			float fio = max(0.06, fwidth(dl) * 1.6);
			a_neve *= mix(0.22, 1.0, smoothstep(fio * 0.4, fio, dl));
		}
		float luz = 0.80 + 0.20 * clamp(dot(n_base, normalize(luz_dir)), 0.0, 1.0);
		c_neve = mix(cor_neve_sombra, cor_neve, smoothstep(0.15, 0.75, 0.5 * n2 + 0.5 * manto)) * luz;
		c_neve *= 0.96 + 0.06 * n3;
	}

	// ---------------------------------------------------------------- juntar (neve por cima do molhado)
	vec3 pre = brilho * (1.0 - a_neve) + c_neve * a_neve;
	float a = a_neve + a_molhado * (1.0 - a_neve);
	ALBEDO = pre / max(a, 1e-4);
	ALPHA = a;
}
