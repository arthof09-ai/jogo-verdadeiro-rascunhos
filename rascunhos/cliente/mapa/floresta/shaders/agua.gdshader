// agua.gdshader — a ÁGUA DO LAGO (Ordem 66; até aqui era o charco parado da Ordem 38, opaco).
//
// A superfície tem vida própria e REAGE a quem lá anda. Tudo num passe, sem luz do motor («unshaded», a luz
// pintada do mapa), sem ler o ecrã nem a profundidade — corre igual no Compatibility do telemóvel.
//
//   VIDA PRÓPRIA  · ondinhas que andam com o VENTO DO MUNDO (o da relva: vento_floresta) e duas camadas de
//                   ruga fina que se cruzam — a superfície nunca pára;
//                 · o céu espelhado (mais forte a olhar rasante), o brilho do sol na ruga e as pinceladas de
//                   brilho que cintilam ao sol; a sombra das copas apaga-os;
//                 · a espuma fina a lamber a margem.
//   FUNDURA       · `fundura_tex` (cozida do relevo por lago_floresta.gd) dá os metros de água em cada ponto:
//                   a RASA é clara e deixa ver o fundo (e as pernas de quem lá anda), a FUNDA é escura e fecha
//                   — a passagem de uma à outra lê-se na cor; na rasa a luz desenha cáusticas no fundo.
//   REACÇÃO       · `pulsos`  anéis que nascem onde um corpo mexe a água e se abrem e morrem;
//                 · `corpos`  o anel de espuma e as ondinhas coladas a cada perna/tronco na linha de água;
//                 · `rasto`   a ESTEIRA: a faixa remexida e espumada por onde o corpo passou; alarga e
//                             desfaz-se DEVAGAR (a espuma parte-se em manchas que vão fechando).
//                   Quem os escreve é lago_floresta.gd (seguir / pulso / ponto_de_rasto), com o relógio `tempo`.
//                 · (Ordem ÁGUA-REAÇÃO) `corpos_agito` quanto cada corpo ainda mexe a água: 1 a andar/nadar, cai
//                   a 0 quando pára — a ondulação colada e a espuma da linha de água acalmam até sumir.
shader_type spatial;
render_mode unshaded, cull_back, world_vertex_coords, blend_mix, depth_draw_never;

#include "luz_floresta.gdshaderinc"
#include "vento_floresta.gdshaderinc"

const int MAX_PULSOS = 24;
const int MAX_RASTO = 48;
const int MAX_CORPOS = 4;

uniform vec3 cor_funda : source_color = vec3(0.24, 0.40, 0.44);
uniform vec3 cor_rasa : source_color = vec3(0.49, 0.60, 0.53);
uniform vec3 cor_reflexo : source_color = vec3(0.50, 0.65, 0.81);
uniform vec3 cor_horizonte : source_color = vec3(0.84, 0.82, 0.67);
uniform vec3 cor_espuma : source_color = vec3(0.90, 0.94, 0.92);
// A fundura cozida: R = (metros de água + 0,5) / fundura_escala. lago_rect = (x0, z0, 1/largura, 1/altura).
uniform sampler2D fundura_tex : filter_linear, repeat_disable, hint_default_black;
uniform vec4 lago_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform float fundura_escala = 3.5;
uniform float tempo = 0.0;
// Quanto a superfície mexe e brilha por si (o perfil gráfico pode baixar; 0 nunca: água parada é defeito).
uniform float vida = 1.0;
// pulsos[i] = (x, z, instante em que nasceu, força 0–1)
uniform vec4 pulsos[MAX_PULSOS];
uniform int n_pulsos = 0;
// rasto[i] = (x, z, instante, força 0–1); força negativa = este ponto começa outro fio (não liga ao anterior)
uniform vec4 rasto[MAX_RASTO];
uniform int n_rasto = 0;
// corpos[i] = (x, z, raio na linha de água, vigor 0–1)
uniform vec4 corpos[MAX_CORPOS];
uniform int n_corpos = 0;
// (Ordem ÁGUA-REAÇÃO) o agito de cada corpo, 0–1 (lago_floresta.gd: sobe com a velocidade, parado cai a 0)
uniform float corpos_agito[MAX_CORPOS];

varying vec3 v_pos;

float fundura_em(vec2 xz) {
	vec2 uv = (xz - lago_rect.xy) * lago_rect.zw;
	return texture(fundura_tex, uv).r * fundura_escala - 0.5;
}

// As ondinhas do vento: devolve o declive (xz) e, em `alt`, a altura (m).
vec2 ondinhas(vec2 p, float t, out float alt) {
	vec2 w = normalize(vento_dir + vec2(0.0001, 0.0));
	vec2 l = vec2(-w.y, w.x);
	float forca = (0.55 + 0.45 * clamp(vento_local(p), 0.0, 1.8)) * vida;
	vec2 g = vec2(0.0);
	alt = 0.0;
	// (direcção, número de onda rad/m, velocidade m/s, altura m)
	vec2 d1 = normalize(w + 0.25 * l);
	vec2 d2 = normalize(w - 0.55 * l);
	vec2 d3 = normalize(w + 0.95 * l);
	vec2 d4 = normalize(w - 0.15 * l);
	float f1 = dot(d1, p) * 2.6 - t * 1.25;
	float f2 = dot(d2, p) * 4.7 - t * 2.05 + 1.3;
	float f3 = dot(d3, p) * 7.9 - t * 2.9 + 4.1;
	float f4 = dot(d4, p) * 13.0 - t * 4.4 + 2.2;
	alt = forca * (0.014 * sin(f1) + 0.008 * sin(f2) + 0.0045 * sin(f3) + 0.0022 * sin(f4));
	g += d1 * (0.014 * 2.6 * cos(f1));
	g += d2 * (0.008 * 4.7 * cos(f2));
	g += d3 * (0.0045 * 7.9 * cos(f3));
	g += d4 * (0.0022 * 13.0 * cos(f4));
	return g * forca;
}

void vertex() {
	v_pos = VERTEX;
	float alt;
	ondinhas(VERTEX.xz, tempo, alt);
	VERTEX.y += alt;
}

void fragment() {
	vec2 p = v_pos.xz;
	float t = tempo;
	float prof = fundura_em(p);
	vec2 w = normalize(vento_dir + vec2(0.0001, 0.0));
	// ---- a superfície viva: ondinhas do vento + duas rugas finas que se cruzam e derivam com ele
	float alt;
	vec2 g = ondinhas(p, t, alt);
	vec2 deriva = w * t * 0.055;
	float ra = texture(ruido, p * 0.19 - deriva + vec2(t * 0.012, 0.0)).r;
	float rb = texture(ruido, p * 0.19 - deriva + vec2(0.37, 0.61 + t * 0.012)).r;
	float rc = texture(ruido, p * 0.53 + deriva * 0.6 + vec2(0.0, -t * 0.021)).r;
	float rd = texture(ruido, p * 0.53 + deriva * 0.6 + vec2(0.71 - t * 0.021, 0.23)).r;
	vec2 ruga = (vec2(ra, rb) - 0.5) * 0.30 + (vec2(rc, rd) - 0.5) * 0.22;

	// ---- a reacção: os anéis dos pulsos
	vec2 g_reac = vec2(0.0);
	float crista = 0.0;
	for (int i = 0; i < n_pulsos; i++) {
		vec4 q = pulsos[i];
		float idade = t - q.z;
		if (idade < 0.0 || idade > 7.0) {
			continue;
		}
		vec2 dv = p - q.xy;
		float dist = length(dv) + 0.0001;
		float raio = 0.08 + 0.55 * idade;
		float x = dist - raio;
		float larg = 0.15 + 0.065 * idade;
		float env = exp(-(x * x) / (larg * larg));
		float amp = q.w * exp(-idade * 0.50) / (1.0 + 0.55 * raio);
		float fase = x * 12.0;
		g_reac += (dv / dist) * (-sin(fase) * env * amp);
		crista += max(cos(fase), 0.0) * env * amp;
	}
	// ---- os corpos na linha de água: o anel de espuma e as ondinhas coladas a cada um
	float anel = 0.0;
	for (int i = 0; i < n_corpos; i++) {
		vec4 c = corpos[i];
		float ag = corpos_agito[i];
		if (ag <= 0.0) {
			continue;
		}
		vec2 dv = p - c.xy;
		float dist = length(dv) + 0.0001;
		float x = dist - c.z;
		float perto = exp(-max(x, 0.0) * 2.4) * step(-0.05, x);
		float fase = x * 16.0 - t * 5.5;
		g_reac += (dv / dist) * (-sin(fase) * perto * (0.22 + 0.55 * c.w) * ag);
		crista += max(cos(fase), 0.0) * perto * (0.10 + 0.35 * c.w) * smoothstep(0.9, 0.2, x) * ag;
		float borda = smoothstep(-0.03, 0.015, x) * (1.0 - smoothstep(0.03, 0.10 + 0.10 * c.w, x));
		anel = max(anel, borda * (0.55 + 0.45 * c.w) * ag);
	}
	// ---- a esteira: a faixa por onde o corpo passou (a distância ao fio e a idade no ponto mais perto)
	float esteira = 0.0;
	float esteira_k = 1.0;
	float esteira_d = 9.0;   // a distância ao fio, em larguras da faixa
	float esteira_f = 0.0;   // a força que resta (morre com a idade)
	for (int i = 0; i < n_rasto - 1; i++) {
		vec4 a = rasto[i];
		vec4 b = rasto[i + 1];
		if (b.w < 0.0) {
			continue;
		}
		vec2 ab = b.xy - a.xy;
		float h = clamp(dot(p - a.xy, ab) / max(dot(ab, ab), 0.00001), 0.0, 1.0);
		float dist = length(p - a.xy - ab * h);
		float idade = t - mix(a.z, b.z, h);
		float forca = mix(abs(a.w), abs(b.w), h);
		float dura = mix(3.5, 14.0, forca);
		float larg = mix(0.20, 0.30, forca) + (0.035 + 0.07 * forca) * idade;
		float k = clamp(idade / dura, 0.0, 1.0);
		float e = exp(-(dist * dist) / (larg * larg)) * (1.0 - k * k) * (0.40 + 0.60 * forca);
		if (e > esteira) {
			esteira = e;
			esteira_k = k;
			esteira_d = dist / larg;
			esteira_f = forca * (1.0 - k);
		}
	}
	// os dois BRAÇOS da esteira: as cristas que se afastam do fio, uma de cada lado, e morrem com a idade
	float bracos = exp(-pow((esteira_d - 0.92) / 0.20, 2.0)) * esteira_f;
	crista += bracos * (0.30 + 0.45 * texture(ruido, p * 1.9 + deriva).r);
	// a água remexida da esteira: a ruga fina fica mais viva lá dentro
	ruga *= 1.0 + 2.6 * esteira;
	vec2 declive = g + ruga * (0.55 + 0.45 * vida) + g_reac * 0.75;
	vec3 n = normalize(vec3(-declive.x, 1.0, -declive.y));

	// ---- a cor da água pela fundura (a rasa clara, a funda escura) e a luz pintada
	float funda = smoothstep(0.30, 1.80, prof);
	vec3 agua = mix(cor_rasa, cor_funda, funda);
	float vis = smoothstep(0.30, 0.70, ler_mapa(p).r);
	vec3 cor = luz_pintada(agua, vec3(0.0, 1.0, 0.0), vis);
	// cáusticas no fundo da rasa (duas rugas que se cruzam: onde coincidem a luz junta-se)
	float ca = texture(ruido, p * 0.83 + vec2(t * 0.031, t * 0.017)).r;
	float cb = texture(ruido, p * 0.83 + vec2(0.5 - t * 0.023, 0.3 + t * 0.027)).r;
	float caustica = smoothstep(0.075, 0.0, abs(ca - cb)) * (1.0 - smoothstep(0.15, 1.0, prof)) * smoothstep(0.02, 0.15, prof);
	cor += cor_sol * caustica * 0.13 * vis * sombra_forca;

	// ---- o céu espelhado e o brilho
	vec3 vw = normalize(CAMERA_POSITION_WORLD - v_pos);
	float ndv = max(dot(n, vw), 0.0);
	float rasante = pow(1.0 - ndv, 3.0);
	vec3 refl = reflect(-vw, n);
	vec3 ceu = mix(cor_horizonte, cor_reflexo, smoothstep(0.02, 0.55, refl.y));
	ceu = olho_noite(ceu * mix(0.35, 1.0, 1.0 - noite));
	float espelho = clamp(0.10 + 0.82 * rasante, 0.0, 0.92) * smoothstep(0.0, 0.12, prof);
	// a ruga inclina o espelho: as cristas apanham mais céu (a superfície lê-se mesmo de cima)
	espelho = clamp(espelho + 0.9 * (declive.x * w.x + declive.y * w.y) + 0.22 * (rc - 0.5), 0.02, 0.95);
	cor = mix(cor, ceu, espelho);
	// o brilho do sol na ruga
	float sol = pow(max(dot(refl, dir_luz), 0.0), 140.0);
	cor += cor_sol * sol * 1.6 * vis * sombra_forca;
	// as pinceladas de brilho: cintilam onde as rugas se alinham com o sol (só ao sol)
	float alinhado = dot(normalize(declive + vec2(0.0001)), normalize(dir_luz.xz + vec2(0.0001)));
	float cintila = smoothstep(0.62, 0.86, rc + 0.35 * ra) * smoothstep(0.035, 0.11, length(declive)) * smoothstep(0.2, 0.9, alinhado);
	cor += cor_sol * cintila * 0.55 * vis * sombra_forca * vida * (1.0 - 0.8 * noite);

	// ---- a espuma: a margem a lamber, as cristas dos anéis, o anel dos corpos e a esteira
	float er = texture(ruido, p * 1.7 - deriva * 2.0).r * 0.62 + texture(ruido, p * 4.3 + vec2(t * 0.02, 0.4)).r * 0.38;
	float lambe = prof - 0.035 - 0.03 * sin(t * 1.1 + ra * 9.0 + rb * 5.0);
	float margem = smoothstep(0.09, 0.0, lambe) * smoothstep(-0.06, -0.01, lambe) * smoothstep(0.35, 0.60, er + 0.25 * sin(t * 0.8 + rb * 12.0));
	// a espuma da esteira desfaz-se DEVAGAR: o limiar sobe a direito com a idade (aos 2/3 da vida ainda há flocos)
	float limiar = mix(0.22, 0.84, esteira_k);
	float esp_esteira = smoothstep(limiar, limiar + 0.13, er) * smoothstep(0.04, 0.30, esteira);
	float esp_crista = smoothstep(0.10, 0.34, crista) * 0.75;
	float esp_anel = anel * smoothstep(0.25, 0.55, er + 0.3);
	float espuma = clamp(max(max(margem * 0.85, esp_esteira), max(esp_crista, esp_anel)), 0.0, 1.0);
	// as cristas dos anéis e a esteira lêem-se mesmo sem espuma: a água levantada apanha a luz
	cor += (cor_sol * 0.5 + ceu * 0.5) * clamp(crista * 0.55 + esteira * 0.10, 0.0, 0.35) * mix(0.5, 1.0, vis);
	vec3 branca = luz_pintada(cor_espuma, vec3(0.0, 1.0, 0.0), vis);
	// a faixa remexida da esteira: a água fica mais clara (as bolhas) e volta à cor dela devagar
	cor = mix(cor, branca, clamp(esteira * 0.34, 0.0, 0.34));
	cor = mix(cor, branca, espuma * 0.92);

	// ---- quanto se vê o fundo: a rasa deixa ver (o leito e as pernas), a funda fecha
	float alfa = mix(mix(0.46, 0.60, smoothstep(0.03, 0.50, prof)), 0.97, smoothstep(0.50, 1.15, prof));
	alfa = max(alfa, espelho * 0.9);
	alfa = max(alfa, espuma);
	alfa = clamp(alfa + sol + cintila * 0.4, 0.0, 1.0);
	// a orla: a água acaba onde o leito sai dela (com a ondinha a subir e a descer a linha)
	alfa *= smoothstep(-0.012, 0.03, prof + alt * 1.5);
	ALBEDO = cor;
	ALPHA = alfa;
}
