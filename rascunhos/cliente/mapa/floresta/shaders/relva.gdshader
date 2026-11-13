// relva.gdshader — Ordem 37. Relva ALTA que se mexe: tufos de lâminas em MultiMesh.
// Geometria (sem alfa, sem discard: zero sobre-desenho de recorte). O vento é do vértice:
// rajadas largas que atravessam o campo (ruído a deslizar) + onda + tremor da ponta.
// UV.y = altura na lâmina (0 base, 1 ponta). INSTANCE_CUSTOM = (tom, seca, fase, —).
shader_type spatial;
render_mode unshaded, cull_disabled, world_vertex_coords;

#include "luz_floresta.gdshaderinc"

uniform vec3 cor_base : source_color = vec3(0.25, 0.35, 0.15);
uniform vec3 cor_ponta : source_color = vec3(0.66, 0.72, 0.35);
uniform vec3 cor_seca : source_color = vec3(0.79, 0.72, 0.40);
uniform vec2 vento_dir = vec2(0.85, 0.5);
uniform float vento_forca : hint_range(0.0, 1.5) = 0.42;
uniform float vento_vel : hint_range(0.0, 4.0) = 1.0;

varying float v_alt;
varying float v_vis;
varying float v_dobra;
varying vec2 v_tom;
varying vec3 v_pos;

void vertex() {
	v_alt = UV.y;
	vec3 p = VERTEX;
	vec2 dv = normalize(vento_dir);
	float t = TIME * vento_vel;
	// rajada: mancha larga de vento que atravessa o campo
	float raj = textureLod(ruido, p.xz * 0.011 - dv * t * 0.035, 0.0).r;
	raj = smoothstep(0.30, 0.78, raj);
	float fase = dot(p.xz, dv) * 0.35 - t * 1.7 + INSTANCE_CUSTOM.b * 6.2832;
	float onda = sin(fase) * 0.6 + sin(fase * 2.7 + 1.3) * 0.25;
	float peso = v_alt * v_alt;
	float d = (onda * 0.45 + 0.75 * raj + 0.10) * vento_forca * (0.35 + 0.9 * raj) * peso;
	float trem = sin(t * 5.3 + p.x * 3.1 + p.z * 2.3) * 0.025 * peso;
	p.xz += dv * (d + trem) + vec2(-dv.y, dv.x) * sin(fase * 1.7 + p.x) * 0.035 * peso;
	p.y -= d * d * 0.55;
	VERTEX = p;
	v_pos = p;
	v_vis = textureLod(mapa_chao, uv_mapa(p.xz), 0.0).r;
	v_dobra = d;
	v_tom = INSTANCE_CUSTOM.rg;
}

void fragment() {
	vec3 ponta = mix(cor_ponta, cor_seca, v_tom.y);
	vec3 alb = mix(cor_base, ponta, pow(v_alt, 1.35));
	alb *= 0.84 + 0.32 * v_tom.x;
	// a lâmina dobrada pelo vento apanha a luz: é isto que desenha as ondas no campo
	alb += ponta * clamp(v_dobra, 0.0, 0.5) * 0.9 * v_alt;
	float vis = smoothstep(0.30, 0.70, v_vis);
	vec3 cor = luz_pintada(alb, vec3(0.0, 1.0, 0.0), vis);
	// translucidez: contra o sol as pontas acendem em ouro
	vec3 vw = normalize(CAMERA_POSITION_WORLD - v_pos);
	float contra = max(dot(-vw, dir_luz), 0.0);
	cor += cor_sol * ponta * contra * contra * 0.55 * v_alt * vis;
	ALBEDO = cor;
}
