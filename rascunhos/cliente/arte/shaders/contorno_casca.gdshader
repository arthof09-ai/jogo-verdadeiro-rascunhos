// contorno_casca.gdshader — Assimilação, missão V1.1 (Plano B v1.1, B2.1 item 3)
// Contorno por casca invertida (inverted hull). Renderizador: Compatibility.
//
// Regras do Mestre: contorno na cor ESCURA do próprio albedo, NUNCA preto, SÓ nas figuras,
// 1 a 1,5 px a 1080p, desligado no perfil Baixo.
//
// Como usar: no material toon_pintado da FIGURA, em "Next Pass", pôr um ShaderMaterial com
// este shader e a MESMA textura_albedo / cor_albedo / escala_uv. Não aplicar em cenário.
// Desligar no Baixo = tirar o next_pass (ver README).
//
// Espessura em espaço de ecrã: a normal é projetada para o clip space e o vértice é empurrado
// em píxeis (VIEWPORT_SIZE), multiplicando por clip.w para a espessura não depender da distância.
//
// Malhas com arestas duras (normais partidas) abrem buracos no contorno: guarde normais
// suavizadas na cor do vértice (RGB = n*0,5+0,5) e ligue normal_suave_em_cor.
//
// PROVISÓRIO: fator_escuro, saturacao e tinta até ao guia V0.1.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_front, unshaded;

uniform vec4 cor_albedo : source_color = vec4(1.0);
uniform sampler2D textura_albedo : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform vec2 escala_uv = vec2(1.0);

// Cor = albedo x fator escuro, com mais saturação (escurecer tira cor; o pintor compensa).
uniform float fator_escuro : hint_range(0.05, 0.8) = 0.35;
uniform float saturacao : hint_range(0.0, 2.0) = 1.3;
// Tinta da hora (color script, campo "contorno"), misturada mantendo a luminância.
uniform vec3 tinta_contorno : source_color = vec3(0.23, 0.18, 0.35);
uniform float mistura_tinta : hint_range(0.0, 1.0) = 0.25;
// Piso de cor: nunca abaixo disto (linear). Garante que o contorno não vira preto.
uniform float piso_contorno : hint_range(0.0, 0.1) = 0.02;

// Espessura
uniform float largura_px : hint_range(0.5, 3.0) = 1.25;
// true: largura_px vale "a 1080p" e escala com a altura do viewport 3D.
uniform bool escalar_com_resolucao = true;
// Mínimo absoluto em píxeis do RENDER 3D INTERNO (revisão V1.1, 06/11).
// No Compatibility 4.7, VIEWPORT_SIZE é o tamanho interno já escalado: o render_scene passa
// "Size2i screen_size = rb->internal_size;" ao _setup_environment. Logo, com escala 3D 0,6 a
// 1080p, o viewport interno tem 648 px de altura e 1,25 px "a 1080p" viram 0,75 px internos:
// uma casca abaixo de 1 px parte-se e cintila (era a causa do "contorno que some").
// Com mínimo 1,0: escala 0,67 -> 1,5 px finais; escala 0,6 -> 1,67 px finais.
uniform float largura_minima_px : hint_range(0.0, 2.0) = 1.0;
uniform bool normal_suave_em_cor = false;

float luminancia(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void vertex() {
	vec3 n = NORMAL;
	if (normal_suave_em_cor) {
		n = normalize(COLOR.rgb * 2.0 - 1.0);
	}
	vec4 pos_vista = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 n_vista = normalize(MODELVIEW_NORMAL_MATRIX * n);
	vec4 clip = PROJECTION_MATRIX * pos_vista;

	// Direção da normal no ecrã, em píxeis.
	vec2 n_clip = (PROJECTION_MATRIX * vec4(n_vista, 0.0)).xy;
	vec2 dir_px = n_clip * VIEWPORT_SIZE;
	float comp = length(dir_px);

	float px = largura_px;
	if (escalar_com_resolucao) {
		px = largura_px * VIEWPORT_SIZE.y / 1080.0;
	}
	// O mínimo vale nos dois modos (antes só valia com escalar_com_resolucao = true).
	px = max(px, largura_minima_px);
	if (comp > 0.00001) {
		// 1 px em NDC = 2 / VIEWPORT_SIZE; x clip.w para valer em clip space.
		clip.xy += (dir_px / comp) * px * (2.0 / VIEWPORT_SIZE) * clip.w;
	}

	// A casca não deve entrar no mapa de sombra: atira-a para fora do volume de recorte.
	// (Os 3 vértices caem no mesmo ponto: triângulo degenerado, sem píxeis. A chamada de
	// desenho do passe de sombra pode continuar a existir; contar no orçamento e medir.)
	if (IN_SHADOW_PASS) {
		clip = vec4(2.0, 2.0, 2.0, 1.0);
	}
	POSITION = clip;
}

void fragment() {
	vec3 base = texture(textura_albedo, UV * escala_uv).rgb * cor_albedo.rgb;
	vec3 escuro = base * fator_escuro;
	float l = luminancia(escuro);
	escuro = max(mix(vec3(l), escuro, saturacao), vec3(0.0));
	// tinta da hora com a mesma luminância do escuro
	vec3 tinta = tinta_contorno * (l / max(luminancia(tinta_contorno), 0.001));
	escuro = mix(escuro, tinta, mistura_tinta);
	escuro = max(escuro, tinta_contorno * piso_contorno / max(luminancia(tinta_contorno), 0.001));
	ALBEDO = escuro;
}
