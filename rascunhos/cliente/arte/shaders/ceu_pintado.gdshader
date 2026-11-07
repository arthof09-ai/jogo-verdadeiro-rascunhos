// ceu_pintado.gdshader — Assimilação, missão V1.1 (Plano B v1.1, V1.1 passo 7)
// Renderizador: Compatibility. Usa só built-ins da doc de sky shaders do Godot 4:
// EYEDIR, SKY_COORDS, COLOR, AT_CUBEMAP_PASS, LIGHT0_ENABLED/DIRECTION/COLOR/ENERGY/SIZE.
// Não usa as passagens de meia/quarto de resolução nem TIME (céu estático = radiance estável).
//
// Gradiente de 3 cores (topo, horizonte, baixo), sol suave (disco + halo) e as 4 horas do
// color script em uniforms. A uniform "hora" (0-24) interpola entre as 4 chaves.
// O color_script.gd escreve "hora" e pode reescrever as 12 cores.
//
// Custo: mudar uma uniform obriga a refazer o cubemap de radiance. Atualize "hora" em degraus
// (ver README), não a cada quadro.
//
// PROVISÓRIO: todas as cores e horas-chave até ao guia V0.1.

shader_type sky;

uniform float hora : hint_range(0.0, 24.0) = 15.0;
uniform float hora_manha : hint_range(0.0, 24.0) = 8.0;
uniform float hora_tarde : hint_range(0.0, 24.0) = 15.0;
uniform float hora_crepusculo : hint_range(0.0, 24.0) = 18.5;
uniform float hora_noite : hint_range(0.0, 24.0) = 22.0;

uniform vec3 topo_manha : source_color = vec3(0.435, 0.608, 0.847);
uniform vec3 horizonte_manha : source_color = vec3(0.949, 0.851, 0.722);
uniform vec3 baixo_manha : source_color = vec3(0.541, 0.576, 0.659);

uniform vec3 topo_tarde : source_color = vec3(0.290, 0.525, 0.851);
uniform vec3 horizonte_tarde : source_color = vec3(0.847, 0.894, 0.910);
uniform vec3 baixo_tarde : source_color = vec3(0.498, 0.565, 0.600);

uniform vec3 topo_crepusculo : source_color = vec3(0.243, 0.227, 0.478);
uniform vec3 horizonte_crepusculo : source_color = vec3(0.973, 0.588, 0.392);
uniform vec3 baixo_crepusculo : source_color = vec3(0.353, 0.275, 0.408);

uniform vec3 topo_noite : source_color = vec3(0.063, 0.071, 0.180);
uniform vec3 horizonte_noite : source_color = vec3(0.180, 0.192, 0.353);
uniform vec3 baixo_noite : source_color = vec3(0.090, 0.094, 0.176);

// Forma do gradiente
uniform float altura_horizonte : hint_range(-0.3, 0.3) = 0.0;
uniform float curva_topo : hint_range(0.1, 4.0) = 0.6;
uniform float curva_baixo : hint_range(0.1, 4.0) = 0.5;
uniform float faixa_baixo : hint_range(0.5, 8.0) = 3.0;

// Pinceladas opcionais (textura em cinzento, panorâmica). Sem textura: forca_pinceladas = 0.
uniform sampler2D pinceladas : filter_linear_mipmap, repeat_enable, hint_default_black;
uniform vec2 escala_pinceladas = vec2(3.0, 1.0);
uniform float forca_pinceladas : hint_range(0.0, 1.0) = 0.0;

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

void sky() {
	vec3 topo = por_hora(topo_manha, topo_tarde, topo_crepusculo, topo_noite);
	vec3 hor = por_hora(horizonte_manha, horizonte_tarde, horizonte_crepusculo, horizonte_noite);
	vec3 baixo = por_hora(baixo_manha, baixo_tarde, baixo_crepusculo, baixo_noite);

	// Sem pinceladas, não lê a textura (ramo por uniform: coerente, sem custo de divergência).
	float pin = 0.0;
	if (forca_pinceladas > 0.0) {
		pin = texture(pinceladas, SKY_COORDS * escala_pinceladas).r - 0.5;
	}
	float y = EYEDIR.y - altura_horizonte + pin * forca_pinceladas * 0.15;

	vec3 cor;
	if (y >= 0.0) {
		cor = mix(hor, topo, pow(clamp(y, 0.0, 1.0), curva_topo));
	} else {
		cor = mix(hor, baixo, pow(clamp(-y * faixa_baixo, 0.0, 1.0), curva_baixo));
	}
	cor *= 1.0 + pin * forca_pinceladas * 0.2;

	if (LIGHT0_ENABLED) {
		float c = clamp(dot(EYEDIR, LIGHT0_DIRECTION), -1.0, 1.0);
		vec3 cor_sol = LIGHT0_COLOR * min(LIGHT0_ENERGY, 1.5);
		float halo = pow(max(c, 0.0), dureza_halo) * forca_halo;
		float calor = pow(max(c, 0.0), 2.0) * (1.0 - clamp(abs(y) * 2.0, 0.0, 1.0)) * aquecimento_horizonte;
		cor += cor_sol * (halo + calor);
		// Disco só no fundo visível; fora do cubemap para não criar um brilho duro nos reflexos.
		if (!AT_CUBEMAP_PASS) {
			// Corda em vez de acos (revisão V1.1): 2·sen(θ/2) ≈ θ para ângulos pequenos, sem
			// o custo nem a perda de precisão do acos perto de c = 1 em GPUs de celular.
			float ang = length(EYEDIR - LIGHT0_DIRECTION);
			float raio = max(LIGHT0_SIZE * 0.5 * tamanho_sol, raio_sol_minimo);
			float disco = 1.0 - smoothstep(raio * (1.0 - borda_sol), raio * (1.0 + borda_sol), ang);
			cor = mix(cor, cor_sol, clamp(disco * forca_sol, 0.0, 1.0));
		}
	}
	// Compatibility trabalha em RGBA8 (LDR): manter <= 1.
	COLOR = min(cor, vec3(1.0));
}
