extends Control

@export var arrow_width: float = 0.7
@export var dash_length: float = 1.2
@export var gap_length: float = 0.6
@export var arrowhead_length: float = 3.2
@export var arrowhead_width: float = 2.8
@export var arrow_color: Color = Color(0.7, 0.15, 0.1, 0.85)
@export var screen_scale: float = 40.0

var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _visible: bool = false
var _camera: Camera3D


func setup_camera(cam: Camera3D) -> void:
	_camera = cam


func show_arrow(
	from_pos: Vector3, to_pos: Vector3,
	color: Color = Color(-1, -1, -1),
) -> void:
	if color.r >= 0:
		arrow_color = color
	if not _camera:
		return
	_from = _camera.unproject_position(
		Vector3(from_pos.x, 0.3, from_pos.z)
	)
	_to = _camera.unproject_position(
		Vector3(to_pos.x, 0.3, to_pos.z)
	)
	_visible = true
	queue_redraw()


func hide_arrow() -> void:
	_visible = false
	queue_redraw()


func _draw() -> void:
	if not _visible:
		return

	var dir := (_to - _from)
	var total_length := dir.length()
	if total_length < 5.0:
		return

	dir = dir.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var sc := screen_scale
	var half_w := arrow_width * sc * 0.5
	var head_len := arrowhead_length * sc
	var head_w := arrowhead_width * sc * 0.5
	var d_len := dash_length * sc
	var g_len := gap_length * sc

	var shaft_length := maxf(0.0, total_length - head_len)

	var pos := 0.0
	while pos < shaft_length:
		var seg_end := minf(pos + d_len, shaft_length)

		var p0 := _from + dir * pos
		var p1 := _from + dir * seg_end
		var t0 := pos / total_length
		var t1 := seg_end / total_length
		var c0 := _color_at(t0)
		var c1 := _color_at(t1)

		var pts := PackedVector2Array([
			p0 + perp * half_w,
			p0 - perp * half_w,
			p1 - perp * half_w,
			p1 + perp * half_w,
		])
		var cols := PackedColorArray([c0, c0, c1, c1])
		draw_polygon(pts, cols)

		pos = seg_end + g_len

	var hb := _from + dir * shaft_length
	var t_base := shaft_length / total_length
	var c_base := _color_at(t_base)
	var c_tip := _color_at(1.0)

	var head_pts := PackedVector2Array([
		hb + perp * head_w,
		hb - perp * head_w,
		_to,
	])
	var head_cols := PackedColorArray([c_base, c_base, c_tip])
	draw_polygon(head_pts, head_cols)


func _color_at(t: float) -> Color:
	var alpha := lerpf(0.05, arrow_color.a, t)
	return Color(
		arrow_color.r, arrow_color.g, arrow_color.b, alpha
	)
