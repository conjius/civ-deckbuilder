extends Node

var _elapsed: float = 0.0
var _state: int = 0
var _output_dir: String = ""
var _frame_count: int = 0


func _ready() -> void:
	_output_dir = OS.get_user_data_dir() + "/screenshots"
	DirAccess.make_dir_recursive_absolute(_output_dir)
	print("[SS] Screenshot dir: " + _output_dir)
	print("[SS] Renderer: " + str(OS.get_video_adapter_driver_info()))
	print("[SS] Viewport size: " + str(get_viewport().size))


func _process(delta: float) -> void:
	_elapsed += delta
	_frame_count += 1
	if _frame_count == 1:
		print("[SS] First frame rendered")
	if _frame_count == 10:
		print("[SS] 10 frames in, elapsed=" + str(_elapsed))
	if _state == 0 and _elapsed >= 5.0:
		print("[SS] State 0: capturing main at frame " + str(_frame_count))
		_capture("screenshot-main.png")
		_open_gallery()
		_state = 1
		_elapsed = 0.0
	elif _state == 1 and _elapsed >= 4.0:
		print("[SS] State 1: capturing gallery at frame " + str(_frame_count))
		_capture("screenshot-gallery.png")
		get_tree().quit()


func _capture(filename: String) -> void:
	var path: String = _output_dir + "/" + filename
	print("[SS] Capture: " + path)
	var img := get_viewport().get_texture().get_image()
	if img == null:
		print("[SS] ERROR: image is null")
		return
	print("[SS] Image size: " + str(img.get_size()))
	var err := img.save_png(path)
	print("[SS] Save result: " + str(err))


func _open_gallery() -> void:
	var game_ui := _find_node_by_script("game_ui.gd")
	if game_ui == null:
		print("[SS] ERROR: game_ui not found")
		return
	print("[SS] Found game_ui: " + str(game_ui))
	if game_ui.has_method("_toggle_gallery"):
		print("[SS] Calling _toggle_gallery, _current_cards size: " + str(game_ui._current_cards.size()))
		game_ui._toggle_gallery()
		print("[SS] Gallery toggled")
	else:
		print("[SS] ERROR: _toggle_gallery not found")


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
