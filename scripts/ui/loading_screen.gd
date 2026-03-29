extends Control

var _logo_tex: Texture2D = preload("res://assets/boot_logo.png")
var _font: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _progress: float = 0.0
var _loading: bool = true
var _scene_path: String = "res://scenes/main.tscn"


func _ready() -> void:
	ResourceLoader.load_threaded_request(_scene_path)


func _process(_delta: float) -> void:
	if not _loading:
		return
	var status: int = ResourceLoader.load_threaded_get_status(
		_scene_path, []
	)
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var progress: Array = []
		ResourceLoader.load_threaded_get_status(
			_scene_path, progress
		)
		if progress.size() > 0:
			_progress = progress[0]
		queue_redraw()
	elif status == ResourceLoader.THREAD_LOAD_LOADED:
		_progress = 1.0
		_loading = false
		queue_redraw()
		_transition()
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		_loading = false
		get_tree().change_scene_to_file(_scene_path)


func _transition() -> void:
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		var scene: PackedScene = (
			ResourceLoader.load_threaded_get(_scene_path)
		)
		if scene:
			get_tree().change_scene_to_packed(scene)
		else:
			get_tree().change_scene_to_file(_scene_path)
	)


func _draw() -> void:
	var vp := get_viewport_rect().size

	# Logo centered
	if _logo_tex:
		var tex_size := _logo_tex.get_size()
		var pos := Vector2(
			(vp.x - tex_size.x) * 0.5,
			(vp.y - tex_size.y) * 0.5 - 40,
		)
		draw_texture(_logo_tex, pos)

	# Progress bar
	var bar_w := 300.0
	var bar_h := 6.0
	var bar_x := (vp.x - bar_w) * 0.5
	var bar_y := vp.y * 0.5 + 80
	# Background
	draw_rect(
		Rect2(bar_x, bar_y, bar_w, bar_h),
		Color(0.2, 0.2, 0.2),
	)
	# Fill
	draw_rect(
		Rect2(bar_x, bar_y, bar_w * _progress, bar_h),
		Color(0.85, 0.65, 0.2),
	)
