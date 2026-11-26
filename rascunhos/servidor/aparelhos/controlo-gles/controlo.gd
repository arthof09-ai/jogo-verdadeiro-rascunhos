extends Node3D
## ORDEM-PLANO-2-F2-ANDROID-SHADER: o controlo. Desenha o mínimo que liga os dois shaders do Godot que falharam no
## emulador — um cubo com o material padrão (SceneShaderGLES3) e um texto (CanvasShaderGLES3) — e diz «pronto».
## Nenhum shader nem recurso do jogo.

var _quadros := 0


func _ready() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1, 3)
	add_child(cam)
	cam.look_at(Vector3.ZERO)
	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-45, 30, 0)
	add_child(luz)
	var cubo := MeshInstance3D.new()
	cubo.mesh = BoxMesh.new()
	cubo.material_override = StandardMaterial3D.new()
	add_child(cubo)
	var texto := Label.new()
	texto.text = "controlo GLES"
	add_child(texto)


func _process(_d: float) -> void:
	_quadros += 1
	if _quadros == 60:
		print("controlo-gles: %s | %s | %s" % [RenderingServer.get_video_adapter_api_version(),
			RenderingServer.get_video_adapter_name(), RenderingServer.get_video_adapter_vendor()])
		print("controlo-gles pronto")
