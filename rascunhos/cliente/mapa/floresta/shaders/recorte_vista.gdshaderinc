// recorte_vista.gdshaderinc — Ordem 42. A câmara da mesa (Fixa / 360° / Panorama) olha para o campo de
// cima e de fora: o que fica ENTRE ela e o foco (a copa de uma árvore da orla, o santuário, um menir)
// não pode tapar o jogo. Esse pedaço some num ponteado (dither, sem alfa nem ordenação): um cilindro
// de raio `vista_raio` da câmara até ao foco, e tudo o que esteja a menos de 4–7 m da lente.
// Desligado (vista_raio = 0) no mapa sozinho: nada muda.
uniform vec3 vista_foco = vec3(0.0);
uniform float vista_raio = 0.0;

bool recorte_vista(vec3 vertice_vista, mat4 inv_vista, vec3 camara, vec2 pixel) {
	if (vista_raio <= 0.0) {
		return false;
	}
	vec3 p = (inv_vista * vec4(vertice_vista, 1.0)).xyz;
	vec3 ab = vista_foco - camara;
	float t = clamp(dot(p - camara, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
	float d = distance(p, camara + ab * t);
	float corta = (1.0 - smoothstep(vista_raio * 0.55, vista_raio, d)) * (1.0 - smoothstep(0.78, 0.92, t));
	corta = max(corta, 1.0 - smoothstep(4.0, 7.0, distance(p, camara)));
	float ruido_px = fract(52.9829189 * fract(dot(pixel, vec2(0.06711056, 0.00583715))));
	return corta > ruido_px;
}
