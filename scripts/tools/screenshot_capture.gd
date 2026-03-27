extends Node

var _elapsed: float = 0.0
var _state: int = 0
var _output_dir: String = ""


func _ready() -> void:
	_output_dir = OS.get_user_data_dir() + "/screenshots"
	DirAccess.make_dir_recursive_absolute(_output_dir)
	print("Screenshot dir: " + _output_dir)


func _process(delta: float) -> void:
	_elapsed += delta
	if _state == 0 and _elapsed >= 3.0:
		_capture("screenshot-main.png")
		_open_gallery()
		_state = 1
		_elapsed = 0.0
	elif _state == 1 and _elapsed >= 2.0:
		_capture("screenshot-gallery.png")
		get_tree().quit()


func _capture(filename: String) -> void:
	var path: String = _output_dir + "/" + filename
	print("Capture at t=" + str(_elapsed) + ": " + path)
	var img := get_viewport().get_texture().get_image()
	if img == null:
		print("ERROR: image is null")
		return
	print("Image: " + str(img.get_size()))
	var err := img.save_png(path)
	print("Save result: " + str(err))


func _open_gallery() -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	press.position = Vector2(960, 900)
	press.global_position = press.position
	Input.parse_input_event(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_RIGHT
	release.pressed = false
	release.position = Vector2(960, 900)
	release.global_position = release.position
	Input.parse_input_event(release)
