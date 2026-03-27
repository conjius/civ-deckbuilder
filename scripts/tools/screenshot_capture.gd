extends Node

var _elapsed: float = 0.0
var _state: int = 0
var _output_dir: String = ""
var _frame_count: int = 0


func _ready() -> void:
	_output_dir = OS.get_user_data_dir() + "/screenshots"
	DirAccess.make_dir_recursive_absolute(_output_dir)
	print("[SS] Screenshot dir: " + _output_dir)
	print("[SS] Viewport size: " + str(get_viewport().size))


func _process(delta: float) -> void:
	_elapsed += delta
	_frame_count += 1
	if _frame_count % 10 == 0:
		print("[SS] frame=" + str(_frame_count) + " elapsed=" + str(snapped(_elapsed, 0.1)))
	if _state == 0 and _elapsed >= 2.0:
		print("[SS] Capturing main")
		_capture("screenshot-main.png")
		_open_gallery()
		_state = 1
		_elapsed = 0.0
	elif _state == 1 and _elapsed >= 2.0:
		print("[SS] Capturing gallery")
		_capture("screenshot-gallery.png")
		get_tree().quit()


func _capture(filename: String) -> void:
	var path: String = _output_dir + "/" + filename
	var img := get_viewport().get_texture().get_image()
	if img == null:
		print("[SS] ERROR: image is null for " + filename)
		return
	var err := img.save_png(path)
	print("[SS] Saved " + filename + ": " + str(img.get_size()) + " err=" + str(err))


func _open_gallery() -> void:
	var game_ui := _find_node("game_ui.gd")
	if game_ui == null:
		print("[SS] ERROR: game_ui not found")
		return
	if not game_ui.has_method("_toggle_gallery"):
		print("[SS] ERROR: no _toggle_gallery method")
		return
	print("[SS] Cards: " + str(game_ui._current_cards.size()))
	game_ui._toggle_gallery()
	print("[SS] Gallery toggled")


func _find_node(script_name: String) -> Node:
	return _search(get_tree().root, script_name)


func _search(node: Node, script_name: String) -> Node:
	if node.get_script():
		if node.get_script().resource_path.ends_with(script_name):
			return node
	for child in node.get_children():
		var found := _search(child, script_name)
		if found:
			return found
	return null
