extends SceneTree
## Lê um .ogv (o ficheiro entregue) e tira quadros: folha de quadros (grelha) + quadros inteiros escolhidos.
## uso: godot --fixed-fps 30 -s folha.gd -- --video=<ogv> --saida=<prefixo> --tempos=0.5,2,4 [--cheios=4,8] [--cols=3] [--larg=480]

var _player: VideoStreamPlayer
var _tempos: Array = []
var _cheios: Array = []
var _saida := ""
var _cols := 3
var _larg := 480
var _t := 0.0
var _quadros: Array = []
var _i := 0
var _j := 0


func _init() -> void:
	var video := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--video="):
			video = a.trim_prefix("--video=")
		elif a.begins_with("--saida="):
			_saida = a.trim_prefix("--saida=")
		elif a.begins_with("--tempos="):
			for x in a.trim_prefix("--tempos=").split(","):
				_tempos.append(float(x))
		elif a.begins_with("--cheios="):
			for x in a.trim_prefix("--cheios=").split(","):
				_cheios.append(float(x))
		elif a.begins_with("--cols="):
			_cols = int(a.trim_prefix("--cols="))
		elif a.begins_with("--larg="):
			_larg = int(a.trim_prefix("--larg="))
	var s := VideoStreamTheora.new()
	s.file = video
	_player = VideoStreamPlayer.new()
	_player.stream = s
	_player.expand = true
	_player.size = Vector2(960, 540)
	root.add_child(_player)
	process_frame.connect(func(): _player.play(); process_frame.connect(_quadro), CONNECT_ONE_SHOT)


func _quadro() -> void:
	_t += 1.0 / 30.0
	var tex := _player.get_video_texture()
	if tex == null:
		return
	if _i < _tempos.size() and _t >= float(_tempos[_i]):
		var img := tex.get_image()
		if img != null:
			_quadros.append([_tempos[_i], img])
		_i += 1
	if _j < _cheios.size() and _t >= float(_cheios[_j]):
		var img2 := tex.get_image()
		if img2 != null:
			img2.save_png("%s_quadro_t%s.png" % [_saida, str(_cheios[_j]).replace(".", ",")])
		_j += 1
	if (_i >= _tempos.size() and _j >= _cheios.size()) or (_t > 0.5 and not _player.is_playing()):
		_fazer_folha()
		quit(0)


func _fazer_folha() -> void:
	if _quadros.is_empty():
		print("sem quadros")
		return
	var w0: int = (_quadros[0][1] as Image).get_width()
	var h0: int = (_quadros[0][1] as Image).get_height()
	var alt := int(round(_larg * float(h0) / float(w0)))
	var linhas := int(ceil(_quadros.size() / float(_cols)))
	var folha := Image.create(_cols * _larg, linhas * alt, false, Image.FORMAT_RGB8)
	for k in _quadros.size():
		var im: Image = (_quadros[k][1] as Image).duplicate()
		im.convert(Image.FORMAT_RGB8)
		im.resize(_larg, alt, Image.INTERPOLATE_LANCZOS)
		folha.blit_rect(im, Rect2i(0, 0, _larg, alt), Vector2i((k % _cols) * _larg, (k / _cols) * alt))
	folha.save_jpg("%s_folha.jpg" % _saida, 0.88)
	print("folha: %d quadros, %dx%d, video %dx%d" % [_quadros.size(), folha.get_width(), folha.get_height(), w0, h0])
