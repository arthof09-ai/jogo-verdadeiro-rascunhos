// ceu_pintado.gdshader — Assimilação, kit de arte (missão V1.1, passo 7; fechado na Ordem 65)
// Renderizador: Compatibility. Usa só built-ins da doc de sky shaders do Godot 4:
// EYEDIR, SKY_COORDS, COLOR, AT_CUBEMAP_PASS, LIGHT0_ENABLED/DIRECTION/COLOR/ENERGY/SIZE.
// Não usa as passagens de meia/quarto de resolução nem TIME (céu estático = radiance estável).
//
// Gradiente de 3 cores (topo, horizonte, baixo), sol suave (disco + halo) e as 4 horas do
// color script em uniforms. A uniform "hora" (0-24) interpola entre as 4 chaves.
// O color_script.gd escreve "hora" e pode reescrever as 12 cores.
//
// O PINCEL (Ordem 65): com as duas texturas de arte/pincel/ o céu deixa de ser um gradiente liso.
//  - "pinceladas" (ceu_pinceladas.png, panorâmica) empurra o gradiente para cima e para baixo ao
//    longo de pinceladas largas e deitadas;
//  - o gradiente parte-se em "tons" (poucas tintas, como numa paleta), e a borda entre dois tons
//    segue a pincelada em vez da altura;
//  - "mascara_pincel" (pincel_mascara.png, repetida) põe as cerdas na borda dos tons, do halo e
//    do disco do sol.
// Sem texturas: forca_pinceladas = 0 e o céu volta ao gradiente liso (2 leituras de textura a menos).
//
// Custo: mudar uma uniform obriga a refazer o cubemap de radiance. Atualize "hora" em degraus
// (ver README), não a cada quadro.
//
// As cores e as horas-chave por omissão são as do color_script.gd (a paleta da casa, Ordem 65).

shader_type sky;

uniform float hora : hint_range(0.0, 24.0) = 15.0;
uniform float hora_manha : hint_range(0.0, 24.0) = 6.5;
uniform float hora_tarde : hint_range(0.0, 24.0) = 15.0;
uniform float hora_crepusculo : hint_range(0.0, 24.0) = 18.5;
uniform float hora_noite : hint_range(0.0, 24.0) = 22.0;

uniform vec3 topo_manha : source_color = vec3(0.227, 0.400, 0.659);
uniform vec3 horizonte_manha : source_color = vec3(0.918, 0.816, 0.635);
uniform vec3 baixo_manha : source_color = vec3(0.651, 0.600, 0.569);

uniform vec3 topo_tarde : source_color = vec3(0.247, 0.451, 0.706);
uniform vec3 horizonte_tarde : source_color = vec3(0.839, 0.816, 0.671);
uniform vec3 baixo_tarde : source_color = vec3(0.600, 0.612, 0.596);

uniform vec3 topo_crepusculo : source_color = vec3(0.227, 0.388, 0.651);
uniform vec3 horizonte_crepusculo : source_color = vec3(0.902, 0.682, 0.463);
uniform vec3 baixo_crepusculo : source_color = vec3(0.643, 0.518, 0.494);

uniform vec3 topo_noite : source_color = vec3(0.043, 0.082, 0.208);
uniform vec3 horizonte_noite : source_color = vec3(0.114, 0.184, 0.345);
uniform vec3 baixo_noite : source_color = vec3(0.086, 0.145, 0.286);

// Forma do gradiente
uniform float altura_horizonte : hint_range(-0.3, 0.3) = 0.0;
uniform float curva_topo : hint_range(0.1, 4.0) = 0.6;
uniform float curva_baixo : hint_range(0.1, 4.0) = 0.5;
uniform float faixa_baixo : hint_range(0.5, 8.0) = 3.0;

// O pincel (Ordem 65). As duas texturas vivem em arte/pincel/ (cinzento, 0,5 = neutro).
// Sem mipmaps de propósito: na costura da panorâmica (SKY_COORDS.x salta de 1 para 0) a derivada
// dispara e o mipmap mais pequeno desenhava uma linha vertical no céu.
// Sem texturas: forca_pinceladas = 0 (o céu fica em gradiente liso e não lê textura nenhuma).
uniform sampler2D pinceladas : filter_linear, repeat_enable, hint_default_black;
uniform sampler2D mascara_pincel : filter_linear, repeat_enable, hint_default_black;
// Quantas vezes cada textura se repete: (à volta do horizonte, do zénite ao nadir).
uniform vec2 escala_pinceladas = vec2(2.0, 1.0);
uniform vec2 escala_mascara = vec2(16.0, 8.0);
uniform float forca_pinceladas : hint_range(0.0, 1.0) = 0.0;
// Quanto a pincelada empurra o gradiente (em fração da altura do gradiente, para cada lado).
uniform float alcance_pinceladas : hint_range(0.0, 0.4) = 0.16;
// Em quantas tintas o gradiente se parte entre o horizonte e o topo (menos de 2 = não parte).
uniform float tons : hint_range(0.0, 24.0) = 9.0;
// Largura da borda entre duas tintas, em fração de um tom (0,5 = sem patamar nenhum).
uniform float borda_tons : hint_range(0.01, 0.5) = 0.14;
// Variação de valor da tinta ao longo da pincelada (a tinta mais carregada e mais aguada).
uniform float aguada : hint_range(0.0, 0.3) = 0.07;

// Sol
uniform float tamanho_sol : hint_range(0.5, 8.0) = 2.0;   // multiplica LIGHT0_SIZE
// Raio mínimo do disco, em radianos (revisão V1.1, 06/11). LIGHT0_SIZE é o diâmetro angular
// (doc do sky shader) e vem do light_angular_distance da luz, que por padrão é 0: sem este
// mínimo, o disco ficava com 0,002 rad (~0,1°) e não se via. 0,03 rad ≈ 1,7°.
uniform float raio_sol_minimo : hint_range(0.0, 0.2) = 0.03;
uniform float borda_sol : hint_range(0.05, 1.0) = 0.35;   // suavidade do disco (fração do raio)
uniform float forca_sol : hint_range(0.0, 2.0) = 0.9;
uniform float dureza_halo : hint_range(1.0, 256.0) = 24.0;
uniform float forca_halo : hint_range(0.0, 1.0) = 0.25;
uniform float aquecimento_horizonte : hint_range(0.0, 1.0) = 0.25;

// Interpola 4 chaves cíclicas (manhã -> tarde -> crepúsculo -> noite -> manhã seguinte).
// Mesma regra de color_script.gd (_segmento).
vec3 por_hora(vec3 a, vec3 b, vec3 c, vec3 d) {
	float h = mod(hora, 24.0);
	if (h >= hora_manha && h < hora_tarde) {
		return mix(a, b, smoothstep(hora_manha, hora_tarde, h));
	}
	if (h >= hora_tarde && h < hora_crepusculo) {
		return mix(b, c, smoothstep(hora_tarde, hora_crepusculo, h));
	}
	if (h >= hora_crepusculo && h < hora_noite) {
		return mix(c, d, smoothstep(hora_crepusculo, hora_noite, h));
	}
	float hh = h < hora_manha ? h + 24.0 : h;
	return mix(d, a, smoothstep(hora_noite, hora_manha + 24.0, hh));
}

// Parte x (0..1) em n patamares com bordas curtas (largura "borda", em fração de um patamar).
float em_tons(float x, float n, float borda) {
	if (n < 2.0) {
		return x;
	}
	float q = x * n;
	float f = fract(q);
	return (floor(q) + smoothstep(0.5 - borda, 0.5 + borda, f)) / n;
}

void sky() {
	vec3 topo = por_hora(topo_manha, topo_tarde, topo_crepusculo, topo_noite);
	vec3 hor = por_hora(horizonte_manha, horizonte_tarde, horizonte_crepusculo, horizonte_noite);
	vec3 baixo = por_hora(baixo_manha, baixo_tarde, baixo_crepusculo, baixo_noite);

	// Sem pinceladas, não lê as texturas (ramo por uniform: coerente, sem custo de divergência).
	float pin = 0.0;    // a pincelada larga (-0,5..0,5)
	float cerda = 0.0;  // as cerdas (-0,5..0,5)
	if (forca_pinceladas > 0.0) {
		// Perto do zénite e do nadir a panorâmica aperta-se num ponto: o pincel sai de cena.
		float polo = 1.0 - smoothstep(0.82, 0.98, abs(EYEDIR.y));
		pin = (texture(pinceladas, SKY_COORDS * escala_pinceladas).r - 0.5) * forca_pinceladas * polo;
		cerda = (texture(mascara_pincel, SKY_COORDS * escala_mascara).r - 0.5) * forca_pinceladas * polo;
	}
	float traco = pin * 2.0 + cerda * 0.5;  // -1,25..1,25: o que desloca as bordas
	float y = EYEDIR.y - altura_horizonte;

	// O gradiente pintado: a altura vira um valor 0..1, a pincelada empurra-o e os tons partem-no.
	vec3 cor;
	if (y >= 0.0) {
		float g = pow(clamp(y, 0.0, 1.0), curva_topo);
		// junto ao horizonte a pincelada perde alcance: a linha do horizonte não ondula
		g = clamp(g + traco * alcance_pinceladas * smoothstep(0.0, 0.12, g), 0.0, 1.0);
		cor = mix(hor, topo, em_tons(g, tons, borda_tons));
	} else {
		float g = pow(clamp(-y * faixa_baixo, 0.0, 1.0), curva_baixo);
		g = clamp(g + traco * alcance_pinceladas * smoothstep(0.0, 0.12, g), 0.0, 1.0);
		cor = mix(hor, baixo, em_tons(g, floor(tons * 0.5), borda_tons));
	}
	cor *= 1.0 + (pin * 1.4 + cerda * 0.6) * aguada;

	if (LIGHT0_ENABLED) {
		float c = clamp(dot(EYEDIR, LIGHT0_DIRECTION), -1.0, 1.0);
		vec3 cor_sol = LIGHT0_COLOR * min(LIGHT0_ENERGY, 1.5);
		// O halo e o calor do horizonte também são tinta: poucos patamares, borda de pincel.
		float quebra = traco * 0.10;
		float halo = pow(max(c, 0.0), dureza_halo);
		float calor = pow(max(c, 0.0), 2.0) * (1.0 - clamp(abs(y) * 2.0, 0.0, 1.0));
		if (forca_pinceladas > 0.0) {
			halo = em_tons(clamp(halo + quebra * sqrt(halo), 0.0, 1.0), 5.0, borda_tons);
			calor = em_tons(clamp(calor + quebra * sqrt(calor), 0.0, 1.0), 5.0, borda_tons);
		}
		cor += cor_sol * (halo * forca_halo + calor * aquecimento_horizonte);
		// Disco só no fundo visível; fora do cubemap para não criar um brilho duro nos reflexos.
		if (!AT_CUBEMAP_PASS) {
			// Corda em vez de acos (revisão V1.1): 2·sen(θ/2) ≈ θ para ângulos pequenos, sem
			// o custo nem a perda de precisão do acos perto de c = 1 em GPUs de celular.
			float raio = max(LIGHT0_SIZE * 0.5 * tamanho_sol, raio_sol_minimo);
			// as cerdas mordem a borda do disco (até um quarto do raio)
			float ang = length(EYEDIR - LIGHT0_DIRECTION) + cerda * raio * 0.5;
			float disco = 1.0 - smoothstep(raio * (1.0 - borda_sol), raio * (1.0 + borda_sol), ang);
			// o disco é sempre mais claro do que o céu por trás: com o sol rasante (energia baixa) a
			// tinta do sol sozinha ficava mais escura do que o halo e o disco lia-se como mancha escura
			vec3 tinta_disco = max(cor_sol, cor + cor_sol * 0.35);
			cor = mix(cor, tinta_disco, clamp(disco * forca_sol, 0.0, 1.0));
		}
	}
	// Compatibility trabalha em RGBA8 (LDR): manter <= 1.
	COLOR = min(cor, vec3(1.0));
}
