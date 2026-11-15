// vento_floresta.gdshaderinc — Ordem 43. O VENTO DO MUNDO nos shaders: um vento só.
// Tudo chega de vento_mundo.gd (o MESMO estado que a API vento_actual()/vento_em() devolve):
// direcção e força reais, rajada incluída. Inclui-se DEPOIS de luz_floresta.gdshaderinc
// (usa o `ruido` do mundo como campo de rajadas).
//
// A FÍSICA que aqui vive:
//  · o campo de rajadas é LEVADO pelo vento (vento_desloc é a advecção integrada no tempo);
//  · a dobra segue a pressão dinâmica (∝ v²) e SATURA: dobra = v² / (v² + 0,9);
//  · as ondas e o tremor andam com fases integradas (vento_fase, vento_tremor), que correm
//    mais depressa com mais vento — com calma a relva quase pára.

uniform vec2 vento_dir = vec2(0.86, 0.51);    // PARA ONDE sopra (xz, unitário)
uniform float vento_v = 1.0;                   // velocidade normalizada (1 = a tarde forte), rajada global incluída
uniform vec2 vento_desloc = vec2(0.0);         // advecção integrada do campo de rajadas (m)
uniform float vento_fase = 0.0;                // fase integrada das ondas (rad)
uniform float vento_tremor = 0.0;              // fase integrada do tremor (rad)

// A rajada (0–1) que está a passar em xz.
float vento_rajada(vec2 xz) {
	return smoothstep(0.30, 0.78, textureLod(ruido, (xz - vento_desloc) * 0.011, 0.0).r);
}

// A velocidade normalizada do vento em xz (a mesma conta de vento_mundo.gd: vento_em()).
float vento_local(vec2 xz) {
	return vento_v * (0.55 + 0.80 * vento_rajada(xz));
}

// A lei da dobra: pressão ∝ v², com saturação.
float vento_dobra(float v) {
	float q = v * v;
	return q / (q + 0.9);
}
