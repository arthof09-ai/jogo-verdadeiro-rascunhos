// relva.gdshader — Ordem 37/38. Relva ALTA que se mexe: tufos de lâminas em MultiMesh.
// Geometria (sem alfa, sem discard: zero sobre-desenho de recorte).
//
// ORDEM 38
//  · defeito 7 (vento em gelatina): a fase do vento vem SÓ da posição no mundo — uma onda que
//    VIAJA pelo campo (mais uma segunda, mais curta, noutro rumo, e as rajadas largas do ruído).
//    Já não há fase ao acaso por tufo. A amplitude é contida: a ponta desvia no máximo
//    ~vento_forca metros (0,17 m; eram ~0,6 m).
//  · defeito 10 (LOD): cada tufo tem um número de ordem r (0–1). A fracção de tufos que fica a
//    cada distância é manter(d) — a MESMA conta que a CPU usa para cortar o número de
//    instâncias de cada bloco (relva_floresta.gd). Aqui, o tufo que está a chegar ao corte
//    ENCOLHE até zero antes de sair (sem salto), e os que ficam ALARGAM para a cobertura
//    não abrir carecas ao longe.
//  · defeito 5 (pontas queimadas): sem somas de luz; o brilho da onda e da contraluz são
//    multiplicações contidas e a cor final tem tecto.
//  · defeito 8: a luz usa a normal do TERRENO debaixo do tufo (cor da instância): a relva da
//    vertente ao sol acende e a da vertente de costas escurece, como o chão.
//
// ORDEM GRAMA (39/46)
//  · TRÊS ALTURAS: as manchas (mancha_rect / mancha_altura, até 4) põem a erva de um rectângulo do chão a
//    uma altura certa em METROS (baixa 0,30 · média 0,95 · alta 1,40 são as da casa: rastro_relva.gd). Fora
//    das manchas a erva é a de sempre (a do mapa; pisada na zona jogável).
//  · O RASTRO: quem passa abre a erva (rastro_relva.gdshaderinc); o jeito sai da altura do tufo em metros. A
//    dobra do rastro soma-se à do vento — longe do caminho a conta dá zero e fica só o vento.
//
// UV.y = altura na lâmina (0 base, 1 ponta).
// INSTANCE_CUSTOM = (r de ordem, seca, tom, altura da malha do tufo em unidades dela).
// COLOR (instância) = (normal do terreno x e z em 0–1, sombra de floresta, —).
shader_type spatial;
render_mode unshaded, cull_disabled, world_vertex_coords;

#include "luz_floresta.gdshaderinc"
#include "res://arte/clima/clima_terreno.gdshaderinc"
#include "vento_floresta.gdshaderinc"
#include "rastro_relva.gdshaderinc"

uniform vec3 cor_base : source_color = vec3(0.34, 0.40, 0.21);
uniform vec3 cor_ponta : source_color = vec3(0.70, 0.68, 0.42);
uniform vec3 cor_seca : source_color = vec3(0.80, 0.73, 0.49);
uniform vec3 cor_floresta : source_color = vec3(0.29, 0.42, 0.29);
// Ordem 43: o vento é o do MUNDO (vento_floresta.gdshaderinc). Aqui só fica quanto a ponta
// desvia no limite (m): com a tarde forte anda pelos 0,13 m de média e 0,30 m na rajada.
uniform float vento_amplitude : hint_range(0.0, 0.8) = 0.36;
uniform float lod_perto = 16.0;
uniform float lod_longe = 90.0;
uniform float lod_min = 0.10;
uniform float lod_ligado = 1.0;
uniform float densidade = 1.0;

// ORDEM 42 — a zona jogável do jogo (cenas/arena): a relva lá dentro está PISADA (baixa), para as
// casas, os destaques e o pé das figuras se lerem — e continua a mexer com o mesmo vento.
uniform vec4 campo_rect = vec4(0.0);   // (x0, z0, x1, z1) no mundo; vazia = nenhuma (o mapa sozinho)
uniform float campo_alto = 1.0;        // fracção da altura que a erva tem lá dentro
// ORDEM 42 + clima (arte/clima): a erva responde ao clima da arena. Os valores são os do módulo do clima
// (neve pousada, aglomerado da nevasca, água e lama do alagamento) e as bacias e os abrigos chegam pelo
// clima_terreno.gdshaderinc. A erva afoga-se nas bolsas (a água lê-se no chão) e enterra-se e branqueia
// debaixo da neve (o manto e os montes lêem-se). Tudo a zero: a erva de sempre.
uniform float clima_neve = 0.0;
uniform float clima_aglomerado = 0.0;
uniform float clima_agua = 0.0;
uniform float clima_lama = 0.0;
float no_campo(vec2 xz) {
	if (campo_rect.z <= campo_rect.x) {
		return 0.0;
	}
	vec2 fora = max(campo_rect.xy - xz, xz - campo_rect.zw);
	return 1.0 - smoothstep(-0.9, 0.6, max(fora.x, fora.y));
}

// ORDEM GRAMA — as manchas de altura: (x0, z0, x1, z1) no mundo e a altura da erva lá dentro (m; 0 = sem mancha).
uniform vec4 mancha_rect[4];
uniform float mancha_altura[4];
// x = a altura (m) que a mancha pede aqui · y = quanto se está dentro de uma mancha (0–1)
vec2 na_mancha(vec2 xz) {
	float alvo = 0.0;
	float peso = 0.0;
	for (int i = 0; i < 4; i++) {
		if (mancha_altura[i] <= 0.0) {
			continue;
		}
		vec2 fora = max(mancha_rect[i].xy - xz, xz - mancha_rect[i].zw);
		float dentro = 1.0 - smoothstep(-0.25, 0.15, max(fora.x, fora.y));
		alvo = mix(alvo, mancha_altura[i], dentro);
		peso = max(peso, dentro);
	}
	return vec2(alvo, peso);
}

varying float v_alt;
varying float v_rastro;
varying float v_neve;
varying float v_dobra;
varying vec3 v_tom;
varying vec3 v_pos;
varying vec4 v_mapa;
varying vec3 v_nt;

// A fracção de tufos que fica à distância d (igual à de relva_floresta.gd: manter()).
float manter(float d) {
	float t = clamp((d - lod_perto) / (lod_longe - lod_perto), 0.0, 1.0);
	return mix(1.0, lod_min, pow(t, 0.55));
}

void vertex() {
	v_alt = UV.y;
	vec3 raiz = MODEL_MATRIX[3].xyz;
	vec3 p = VERTEX;
	// ---- LOD: encolher o que sai, alargar o que fica
	float d_cam = distance(raiz.xz, CAMERA_POSITION_WORLD.xz);
	float k = mix(1.0, manter(d_cam), lod_ligado) * densidade;
	float fica = 1.0 - smoothstep(k * 0.80, k, INSTANCE_CUSTOM.r);
	float alarga = min(inversesqrt(k), 2.6);
	p.xz = raiz.xz + (p.xz - raiz.xz) * alarga * fica;
	p.y = raiz.y + (p.y - raiz.y) * fica * mix(1.0, 1.12, clamp(alarga - 1.0, 0.0, 1.0));
	float baixa = mix(1.0, campo_alto, no_campo(raiz.xz));
	// ---- ORDEM GRAMA: a mancha de altura manda na altura do tufo, em metros (± 14 % de tufo para tufo)
	float alto_tufo = length(MODEL_MATRIX[1].xyz) * max(INSTANCE_CUSTOM.a, 0.2);   // m, antes de tudo
	vec2 mancha = na_mancha(raiz.xz);
	if (mancha.y > 0.0) {
		float pede = mancha.x * mix(0.86, 1.14, INSTANCE_CUSTOM.b) / alto_tufo;
		baixa = mix(baixa, pede, mancha.y);
		// a erva alta é também mais larga (o tufo esticado não fica um fio)
		p.xz = raiz.xz + (p.xz - raiz.xz) * (1.0 + 0.22 * clamp(baixa - 1.0, 0.0, 1.5));
	}
	// clima: a água e a lama afogam a erva; a neve enterra-a
	float y_rel = raiz.y - chao_ref_y;
	float afoga = 0.0;
	if (clima_agua > 0.0) {
		afoga = smoothstep(-0.015, 0.05, clima_fundura(raiz.xz, y_rel, clima_agua * CLIMA_ENCHE, 0.0));
	}
	if (clima_lama > 0.0) {
		afoga = max(afoga, 0.65 * smoothstep(-0.01, 0.03, clima_fundura(raiz.xz, y_rel, clima_lama * CLIMA_ENCHE, CLIMA_MARGEM_LAMA)));
	}
	float neve_aqui = clima_neve;
	if (clima_aglomerado > 0.0) {
		float ab = clima_abrigo(raiz.xz);
		float exposto = 1.0 - clamp(ab * 1.4, 0.0, 1.0);
		neve_aqui = clima_neve * (1.0 - clima_aglomerado * exposto * 0.67) + clima_aglomerado * ab * 1.05;
	}
	v_neve = clamp(neve_aqui, 0.0, 1.0);
	baixa *= (1.0 - afoga) * (1.0 - 0.80 * clamp(neve_aqui, 0.0, 1.0));
	p.y = raiz.y + (p.y - raiz.y) * baixa;
	// ---- ORDEM GRAMA: o rastro de quem passa — o tufo dobra pela raiz para o rumo guardado, mais na ponta
	vec4 rastro = rastro_dobra(raiz.xz, alto_tufo * baixa * fica);
	v_rastro = rastro.w;
	if (rastro.z != 0.0) {
		float h = p.y - raiz.y;
		float dobra_r = rastro.z * mix(0.45, 1.0, v_alt);
		p.xz += rastro.xy * sin(dobra_r) * h;
		p.y = raiz.y + h * cos(dobra_r);
	}
	// ---- vento: onda que viaja (fase só da posição)
	// (Ordem 43) o vento do mundo: a velocidade local (rajada que passa incluída) dá a pressão,
	// a pressão dá a dobra; as ondas viajam na direcção do vento ao ritmo dele.
	vec2 dv = vento_dir;
	float vl = vento_local(raiz.xz);
	float dobra = vento_dobra(vl);
	float fase = dot(raiz.xz, dv) * 0.24 - vento_fase * 1.35;
	vec2 dv2 = vec2(dv.y, -dv.x) * 0.5 + dv * 0.866;
	float fase2 = dot(raiz.xz, dv2) * 0.61 - vento_fase * 2.3;
	float onda = 0.5 + 0.5 * sin(fase);
	float onda2 = 0.5 + 0.5 * sin(fase2);
	float peso = v_alt * v_alt;
	float forma = 0.46 + 0.40 * onda + 0.14 * onda2;
	float d = vento_amplitude * dobra * forma * peso;
	float trem = sin(vento_tremor * 5.3 + raiz.x * 3.1 + raiz.z * 2.3) * 0.012 * min(vl, 1.6) * peso;
	d *= mix(1.0, min(baixa, 2.0), 0.6);
	// a erva deitada pelo rastro ainda mexe, mas menos (o rastro soma-se ao vento, não o cala)
	d *= 1.0 - 0.55 * rastro.w;
	p.xz += dv * (d + trem);
	p.y -= d * d * 1.2;
	VERTEX = p;
	v_pos = p;
	v_mapa = ler_mapa_lod(raiz.xz);
	v_dobra = forma * dobra * 2.0 * mix(1.0, min(baixa, 2.0), 0.6);
	v_tom = vec3(INSTANCE_CUSTOM.g, INSTANCE_CUSTOM.b, COLOR.b);
	vec2 nxz = COLOR.rg * 2.0 - 1.0;
	v_nt = vec3(nxz.x, sqrt(max(1.0 - dot(nxz, nxz), 0.05)), nxz.y);
}

void fragment() {
	vec3 ponta = mix(cor_ponta, cor_seca, v_tom.x);
	vec3 alb = mix(cor_base, ponta, pow(v_alt, 1.3));
	alb *= 0.86 + 0.28 * v_tom.y;
	// debaixo da floresta a relva é mais fria e escura
	alb = mix(alb, cor_floresta * (0.55 + 0.6 * v_alt), v_tom.z * 0.75);
	// a lâmina dobrada pelo vento apanha a luz: desenha as ondas no campo (contido)
	alb *= 1.0 + 0.16 * clamp(v_dobra - 0.45, -0.45, 0.55) * v_alt;
	// ORDEM GRAMA: a erva aberta pelo rastro mostra o pé (mais escuro e mais frio): o caminho lê-se
	alb *= 1.0 - 0.20 * v_rastro * mix(1.0, 0.55, v_alt);
	float vis = smoothstep(0.30, 0.70, v_mapa.r);
	// a normal: a do terreno, levantada para o céu na ponta (a lâmina é fina e translúcida)
	vec3 n = normalize(mix(v_nt, vec3(0.0, 1.0, 0.0), 0.35 * v_alt));
	vec3 cor = luz_pintada(alb, n, vis) * mix(0.62, 1.0, mix(v_mapa.a, 1.0, v_alt));
	// translucidez contida: contra o sol as pontas aquecem
	vec3 vw = normalize(CAMERA_POSITION_WORLD - v_pos);
	float contra = max(dot(-vw, dir_luz), 0.0);
	cor *= 1.0 + 0.22 * contra * contra * v_alt * vis;
	cor = min(cor, vec3(0.86, 0.84, 0.70));
	// clima: a erva debaixo da neve fica branca (as pontas primeiro)
	cor = mix(cor, vec3(0.86, 0.89, 0.93) * mix(0.72, 1.0, vis), v_neve * mix(0.55, 0.95, v_alt));
	ALBEDO = cor;
}
