extends Control
## Tabuleiro do Mestre, visto de cima (JV3.1, primeira versão, I0004 08/11/2026).
##
## Desenha a grelha da arena e TODAS as figuras colocadas; a figura da vez leva um anel cheio. As não
## colocadas (as únicas que a Party não vê) não têm casa e ficam só na aba Figuras. O anel tracejado
## fica para quando o servidor tiver figuras colocadas e escondidas (hoje não tem). A arena 3D com a câmara da mesa (camera_mesa) entra num passo seguinte; esta grelha
## chega para o Mestre saber onde está cada figura e serve de prova no CI.

const Modelo := preload("res://cenas/mestre/modelo_mestre.gd")

const COR_FUNDO := Color(0.09, 0.1, 0.12)
const COR_GRELHA := Color(1, 1, 1, 0.08)
const COR_LADO := {"jogadora": Color(0.35, 0.7, 1.0), "criatura": Color(0.95, 0.4, 0.35), "npc": Color(0.95, 0.8, 0.35)}
const COR_VEZ := Color(1, 1, 1)

var vista: Dictionary = {}:
	set(v):
		vista = v
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COR_FUNDO)
	var mapa = vista.get("mapa")
	if not (mapa is Dictionary):
		return
	var larg := maxi(1, int(mapa.get("largura", 1)))
	var alt := maxi(1, int(mapa.get("altura", 1)))
	var lado := minf(size.x / larg, size.y / alt)
	var origem := (size - Vector2(lado * larg, lado * alt)) * 0.5
	for i in larg + 1:
		draw_line(origem + Vector2(i * lado, 0), origem + Vector2(i * lado, alt * lado), COR_GRELHA)
	for j in alt + 1:
		draw_line(origem + Vector2(0, j * lado), origem + Vector2(larg * lado, j * lado), COR_GRELHA)
	var vez := str(vista.get("vezId", "")) if vista.get("vezId") is String else ""
	var fonte := get_theme_default_font()
	for f in Modelo.figuras(vista):
		if not (f is Dictionary) or f.get("colocada") != true:
			continue
		var c := origem + (Vector2(float(f.get("x", 0)), float(f.get("y", 0))) + Vector2(0.5, 0.5)) * lado
		var raio := lado * 0.38
		draw_circle(c, raio, COR_LADO.get(str(f.get("lado", "")), Color.GRAY))
		var id := str(f.get("id", ""))
		if not Modelo.visivel_para_party(vista, id):
			_anel_tracejado(c, raio * 1.25, Color(1, 1, 1, 0.8), maxf(1.0, lado * 0.05))
		if id == vez:
			draw_arc(c, raio * 1.45, 0.0, TAU, 32, COR_VEZ, maxf(1.0, lado * 0.07))
		if fonte != null and lado >= 18.0:
			var inicial := Modelo.nome_mestre(f).left(1)
			draw_string(fonte, c + Vector2(-raio * 0.45, raio * 0.4), inicial, HORIZONTAL_ALIGNMENT_LEFT, -1, int(lado * 0.4))


func _anel_tracejado(c: Vector2, r: float, cor: Color, largura: float) -> void:
	var partes := 12
	for i in partes:
		var a0 := TAU * i / partes
		draw_arc(c, r, a0, a0 + TAU / partes * 0.55, 6, cor, largura)
