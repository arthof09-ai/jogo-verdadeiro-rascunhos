// ceu_panorama.gdshader — Ordem 37. O céu é PINTURA: uma textura (ceu/ceu_floresta_v2.png),
// zero geometria. Sol, lua, nuvens e estrelas vivem na textura.
// A faixa baixa funde-se na COR DO HORIZONTE — a mesma variável da névoa e da tinta dos anéis
// (paleta_floresta.gd). Fórmula da v2: mix(horizonte, pintura, smoothstep(0; 0,15; y)).
// Mapa da textura: u = azimute (0,5 = norte), v = elevação de +90° (0) a elev_min (1).
shader_type sky;

uniform sampler2D pintura : source_color, filter_linear, repeat_enable;
uniform vec3 cor_horizonte : source_color = vec3(0.84, 0.82, 0.60);
uniform float faixa : hint_range(0.01, 0.5) = 0.15;
uniform float elev_min_graus = -6.0;

void sky() {
	vec3 d = normalize(EYEDIR);
	float u = atan(d.x, -d.z) / TAU + 0.5;
	float el = degrees(asin(clamp(d.y, -1.0, 1.0)));
	float v = clamp((90.0 - el) / (90.0 - elev_min_graus), 0.002, 0.998);
	vec3 c = texture(pintura, vec2(u, v)).rgb;
	COLOR = mix(cor_horizonte, c, smoothstep(0.0, faixa, d.y));
}
