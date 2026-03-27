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
	if _state == 0 and _elapsed >= 5.0:
		_capture("screenshot-main.png")
		_open_gallery()
		_state = 1
		_elapsed = 0.0
	elif _state == 1 and _elapsed >= 4.0:
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
	var game_ui := _find_node_by_script("game_ui.gd")
	if game_ui and game_ui.has_method("_toggle_gallery"):
		game_ui._toggle_gallery()
		print("Gallery opened via _toggle_gallery")
	else:
		print("ERROR: could not find game_ui to open gallery")


func _find_node_by_script(script_name: String) -> Node:
	return _search_tree(get_tree().root, script_name)


func _search_tree(node: Node, script_name: String) -> Node:
	if node.get_script():
		var path: String = node.get_script().resource_path
		if path.ends_with(script_name):
			return node
	for child in node.get_children():
		var found := _search_tree(child, script_name)
		if found:
			return found
	return null
