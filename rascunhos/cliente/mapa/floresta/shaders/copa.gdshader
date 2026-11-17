// copa.gdshader — Ordem 37/38. Copas e arbustos: massas pintadas (sem alfa), 3 tons de pincelada,
// (Ordem 38, defeito 3: o ouro já não se SOMA à copa — mistura-se, contido; a copa fica no verde
// frio da cobertura e só o tom alto e a contraluz puxam ao verde-ouro.)
// normais de volume, contraluz dourada na orla e vento no vértice.
// COLOR.rgb = tinta da bolha; COLOR.a = oclusão cozinhada. UV = (fase do vento, peso do vento).
shader_type spatial;
render_mode unshaded, cull_back, world_vertex_coords;

#include "luz_floresta.gdshaderinc"
#include "recorte_vista.gdshaderinc"
#include "vento_floresta.gdshaderinc"

uniform vec3 cor_ouro : source_color = vec3(0.70, 0.65, 0.27);
// Ordem 43: o vento é o do MUNDO (vento_floresta.gdshaderinc). Aqui só fica o balanço (m)
// desta família de copa com a tarde forte.
uniform float vento_amplitude : hint_range(0.0, 1.5) = 0.22;
uniform float clima_neve = 0.0;
uniform float clima_aglomerado = 0.0;
uniform float clima_gelo = 0.0;
uniform vec2 vento_abrigo = vec2(1.0, 0.0);

varying vec3 v_pos;
varying vec3 v_n;

void vertex() {
	// (Ordem 43) a copa verga para onde o vento sopra (a pressão) e balança à volta disso
	vec2 dv = vento_dir;
	float vl = vento_local(VERTEX.xz);
	float empurra = vento_dobra(vl) * 2.0 * vento_amplitude;
	float fase = UV.x * 6.2832 + dot(VERTEX.xz, dv) * 0.12;
	float balanco = sin(vento_fase * 0.9 + fase) * 0.6 + sin(vento_fase * 0.37 + fase * 1.7) * 0.4;
	float trem = sin(vento_tremor * 4.3 + VERTEX.x * 1.9 + VERTEX.y * 2.3 + VERTEX.z * 1.3) * min(vl, 1.6);
	VERTEX.xz += dv * ((0.40 + 0.80 * balanco) * empurra + trem * 0.035) * UV.y;
	VERTEX.y += trem * 0.03 * UV.y;
	v_pos = VERTEX;
	v_n = NORMAL;
}

void fragment() {
	if (recorte_vista(VERTEX, INV_VIEW_MATRIX, CAMERA_POSITION_WORLD, FRAGCOORD.xy)) {
		discard;
	}
	vec3 n = normalize(v_n);
	// pinceladas de folha: ruído em dois planos do mundo
	float r = texture(ruido, v_pos.xz * 0.33 + v_pos.y * 0.21).r;
	float r2 = texture(ruido, v_pos.xy * 0.85 + v_pos.z * 0.6).r;
	float pinc = r * 0.55 + r2 * 0.45;
	float ndl = dot(n, dir_luz) + (pinc - 0.5) * 0.75;
	float k = smoothstep(-0.20, 0.10, ndl) * 0.5 + smoothstep(0.28, 0.58, ndl) * 0.5;
	float ao = COLOR.a;
	vec3 alb = COLOR.rgb * (0.82 + 0.36 * r);
	vec3 amb = cor_ceu * (0.26 + 0.20 * n.y) + ressalto_chao(n) * 1.25;
	vec3 cor = alb * (amb + mix(cor_sombra * 0.45, cor_sol, k * ao));
	// o tom mais alto leva ouro (a luz rasante da referência)
	cor = mix(cor, cor_ouro * cor_sol * 1.15, smoothstep(0.62, 0.85, ndl) * 0.26 * ao);
	// contraluz na orla
	vec3 vw = normalize(CAMERA_POSITION_WORLD - v_pos);
	float orla = 1.0 - max(dot(n, vw), 0.0);
	float contra = max(dot(-vw, dir_luz), 0.0);
	cor = mix(cor, cor_ouro * cor_sol * 1.2, orla * orla * (0.06 + 0.9 * contra * contra) * 0.42);
	vec3 saida = olho_noite(cor * mix(0.72, 1.0, ao));
	if (clima_neve > 0.001 || clima_aglomerado > 0.001 || clima_gelo > 0.001) {
		vec2 w = normalize(vento_abrigo + vec2(1e-5, 0.0));
		float sota = clamp(dot(n.xz, w) * 0.45, -0.25, 0.45);
		float lim = mix(0.85, 0.08, clamp(clima_neve * 0.70 + clima_aglomerado * 0.55, 0.0, 1.0));
		float m_copa = smoothstep(lim, lim + 0.24, n.y + sota + (pinc - 0.5) * 0.38)
			* clamp((clima_neve + clima_aglomerado + clima_gelo * 0.5) * 1.35, 0.0, 0.92);
		vec3 luz_copa = olho_noite(clamp(amb + mix(cor_sombra * 0.52, cor_sol * 1.02, k * ao), vec3(0.24, 0.30, 0.44), vec3(0.92, 0.94, 0.97)));
		vec3 tinta_copa = mix(vec3(0.68, 0.77, 0.89), vec3(0.91, 0.94, 0.98), smoothstep(0.2, 0.8, n.y + 0.2 * pinc)) * luz_copa;
		saida = mix(saida, tinta_copa, m_copa);
	}
	ALBEDO = saida;
}
