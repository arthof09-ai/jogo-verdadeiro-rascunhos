// forno_camadas.gdshader — Ordem 43. O PINCEL que coze as CAMADAS do céu do ciclo do dia
// (corre UMA vez, no forno: ferramentas/cozer_camadas.gd). Não entra no jogo: o jogo só lê o
// PNG cozido (ceu/ceu_camadas_v1.png) em shaders/ceu_ciclo.gdshader.
//
// Canal R = a densidade das nuvens (0–1) — a MESMA função nuvem() do forno_ceu.gdshader da
// Ordem 38 (os mesmos cúmulos de bom tempo, no mesmo sítio). A luz das nuvens já não vem
// cozida: o céu vivo ilumina-as conforme a hora, lendo esta densidade 3 vezes.
// Mapa: u = azimute (0,5 = norte, -Z), v = elevação de +90° (v=0) a ELEV_MIN (v=1).
shader_type canvas_item;

uniform float elev_min_graus = -6.0;

const float TAU_ = 6.28318530718;

float h13(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.zyx + 31.32);
	return fract((p.x + p.y) * p.z);
}

float ruido3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(h13(i), h13(i + vec3(1, 0, 0)), u.x), mix(h13(i + vec3(0, 1, 0)), h13(i + vec3(1, 1, 0)), u.x), u.y),
		mix(mix(h13(i + vec3(0, 0, 1)), h13(i + vec3(1, 0, 1)), u.x), mix(h13(i + vec3(0, 1, 1)), h13(i + vec3(1, 1, 1)), u.x), u.y),
		u.z);
}

float fbm(vec3 p) {
	float a = 0.5;
	float s = 0.0;
	for (int k = 0; k < 6; k++) {
		s += a * ruido3(p);
		p = p * 2.03 + vec3(17.1, 3.7, 9.2);
		a *= 0.5;
	}
	return s;
}

float nuvem(float az, float el) {
	vec3 p = vec3(cos(az) * 2.9, el * 8.5, sin(az) * 2.9);
	float base = fbm(p * 1.20 + vec3(4.0, 0.0, 1.5));
	float fino = fbm(p * 3.6 + vec3(1.0, 7.0, 2.0));
	float dens = base * 0.78 + fino * 0.22;
	float faixa = smoothstep(0.07, 0.17, el) * (1.0 - smoothstep(0.45, 0.95, el));
	float limiar = 0.545;
	return smoothstep(limiar, limiar + 0.13, dens) * faixa;
}

void fragment() {
	float az = (UV.x - 0.5) * TAU_;
	float el = radians(mix(90.0, elev_min_graus, UV.y));
	float n = nuvem(az, max(el, 0.0));
	COLOR = vec4(n, n, n, 1.0);
}
