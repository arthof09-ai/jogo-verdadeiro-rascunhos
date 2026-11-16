// rastro_relva.gdshaderinc — Ordem GRAMA (39/46). O RASTRO na relva, do lado de quem a desenha.
// Tudo chega de rastro_relva.gd (o mapa do rastro e os números das três alturas — uma tabela só):
//   rastro_tex   por ponto do chão: (hora da última passagem, rumo x, rumo z para onde a erva foge, força 0–1)
//   rastro_rect  (x0, z0, 1/largura, 1/comprimento) da zona que o mapa cobre
//   rastro_agora o relógio do rastro (s) — a idade de uma passagem é agora − hora
// A conta é a MESMA de rastro_relva.gd (`pesos`, `resposta`): o jeito sai da ALTURA do tufo em metros.
//   baixa: só debaixo dos pés, dobra pouco, volta num instante com um ressalto de mola;
//   média: abre já à frente de quem vem e fecha logo atrás;
//   alta:  deita-se para os lados, segura e fecha devagar (o corredor).
// Com rastro_ligado = 0 (ninguém passou há mais tempo do que a erva mais lenta leva a fechar) nem se lê a
// textura: a relva de sempre, ao vento.

uniform sampler2D rastro_tex : filter_nearest, repeat_disable;
uniform vec4 rastro_rect = vec4(0.0);
uniform float rastro_agora = 0.0;
uniform float rastro_ligado = 0.0;
// por altura: (força em que começa a abrir, força em que está toda aberta, segura (s), fecha (s))
uniform vec4 rastro_baixa = vec4(0.50, 0.92, 0.0, 0.9);
uniform vec4 rastro_media = vec4(0.04, 0.50, 0.25, 1.3);
uniform vec4 rastro_alta = vec4(0.22, 0.72, 3.0, 9.0);
// a dobra máxima (rad) de cada altura
uniform vec3 rastro_angulos = vec3(0.85, 1.10, 1.20);
// a mola da erva baixa: (amortecimento 1/s, frequência rad/s)
uniform vec2 rastro_mola = vec2(4.5, 9.0);
// as fronteiras entre os jeitos, pela altura do tufo (m)
uniform vec4 rastro_fronteiras = vec4(0.45, 0.62, 1.10, 1.20);

float rastro_resposta(vec4 c, float forca, float idade) {
	return smoothstep(c.x, c.y, forca) * (1.0 - smoothstep(c.z, c.z + c.w, idade));
}

// O que o rastro faz ao tufo de `altura_m` metros com a raiz em xz:
//   xy = o rumo (no chão) para onde dobra · z = o ângulo da dobra (rad; negativo = o ressalto da mola)
//   w  = a abertura (0–1), para a cor e para conter o vento na erva deitada
vec4 rastro_dobra(vec2 xz, float altura_m) {
	if (rastro_ligado < 0.5) {
		return vec4(0.0);
	}
	vec2 uv = (xz - rastro_rect.xy) * rastro_rect.zw;
	if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) {
		return vec4(0.0);
	}
	vec4 t = textureLod(rastro_tex, uv, 0.0);
	if (t.a <= 0.0) {
		return vec4(0.0);
	}
	float idade = rastro_agora - t.r;
	if (idade < 0.0) {
		return vec4(0.0);
	}
	float p_baixa = 1.0 - smoothstep(rastro_fronteiras.x, rastro_fronteiras.y, altura_m);
	float p_alta = smoothstep(rastro_fronteiras.z, rastro_fronteiras.w, altura_m);
	float p_media = max(1.0 - p_baixa - p_alta, 0.0);
	// a baixa: a mola (apaga-se a oscilar e cala-se ao fim do tempo de fecho)
	float cala = 1.0 - smoothstep(rastro_baixa.w * 0.6, rastro_baixa.w, idade);
	float a_baixa = smoothstep(rastro_baixa.x, rastro_baixa.y, t.a) * exp(-idade * rastro_mola.x) * cos(idade * rastro_mola.y) * cala;
	float a_media = rastro_resposta(rastro_media, t.a, idade);
	float a_alta = rastro_resposta(rastro_alta, t.a, idade);
	float angulo = p_baixa * a_baixa * rastro_angulos.x + p_media * a_media * rastro_angulos.y + p_alta * a_alta * rastro_angulos.z;
	float abertura = p_baixa * abs(a_baixa) + p_media * a_media + p_alta * a_alta;
	return vec4(t.gb, angulo, abertura);
}
