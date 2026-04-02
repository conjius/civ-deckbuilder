extends Node3D

signal movement_finished

@export var move_speed: float = 5.4

var state: PlayerState = PlayerState.new()
var avatar_color: Color = Color(0.9, 0.2, 0.2, 1)

var current_coord: Vector2i:
	get: return state.current_coord
	set(value): state.current_coord = value

var unit_name: String:
	get: return state.unit_name

var health: int:
	get: return state.health

var max_health: int:
	get: return state.max_health

var attack: int:
	get: return state.attack

var defense: int:
	get: return state.defense

var _is_moving: bool = false
var _move_tween: Tween = null
var _model: Node3D
var _last_facing: Vector3 = Vector3(0, 0, -1)
var _current_angle: float = 0.0
var _target_angle: float = 0.0
var _is_selected: bool = false
var _is_targeting_move: bool = false
var _is_dragging_card: bool = false
var _camera: Camera3D
var _ground_y := 0.6

func _ready() -> void:
	var old_mesh: Node = get_node_or_null("MeshInstance3D")
	if old_mesh:
		old_mesh.queue_free()
	_model = _build_character_model()
	add_child(_model)
	_apply_color_wash()


func setup_camera(cam: Camera3D) -> void:
	_camera = cam


func set_selected(value: bool) -> void:
	_is_selected = value
	if not value and _model:
		_is_targeting_move = false
		_face_direction(_last_facing)


func set_targeting_move(value: bool) -> void:
	_is_targeting_move = value
	if not value and _model:
		_face_direction(_last_facing)


func is_moving() -> bool:
	return _is_moving


func place_at(coord: Vector2i, terrain_height: float = 0.0) -> void:
	state.place_at(coord)
	position = HexUtil.axial_to_world(coord.x, coord.y)
	position.y = terrain_height + 0.2


func offset_for_packing(
	has_building: bool, has_yields: bool = false,
) -> void:
	if not _model:
		return
	if has_building:
		_model.position = Vector3(0.4, _ground_y, 0.3)
	elif has_yields:
		_model.position = Vector3(0.15, _ground_y, 0.55)
	else:
		_model.position = Vector3(0, _ground_y, 0)


func move_to(coord: Vector2i, terrain_height: float = 0.0) -> void:
	state.move_to(coord)
	var target := HexUtil.axial_to_world(coord.x, coord.y)
	target.y = terrain_height + 0.2
	_is_moving = true
	_face_toward(target)
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()
	_move_tween = create_tween()
	var distance := position.distance_to(target)
	var duration := distance / move_speed
	_move_tween.tween_property(
		self, "position", target, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move_tween.finished.connect(_on_move_finished)


func move_along_path(
	path_coords: Array[Vector2i],
	terrain_heights: Array[float],
) -> void:
	if path_coords.size() <= 1:
		movement_finished.emit()
		return
	state.move_to(path_coords[path_coords.size() - 1])
	_is_moving = true
	var first_target := HexUtil.axial_to_world(
		path_coords[1].x, path_coords[1].y
	)
	_face_toward(first_target)
	if _move_tween and _move_tween.is_running():
		_move_tween.kill()
	_move_tween = create_tween()
	for i in range(1, path_coords.size()):
		var target := HexUtil.axial_to_world(
			path_coords[i].x, path_coords[i].y
		)
		target.y = terrain_heights[i] + 0.2
		var face_dir := target - HexUtil.axial_to_world(
			path_coords[i - 1].x, path_coords[i - 1].y
		)
		face_dir.y = 0.0
		if face_dir.length_squared() > 0.001 and _model:
			var angle := atan2(-face_dir.x, -face_dir.z)
			_move_tween.tween_property(
				_model, "rotation:y", angle, 0.15
			).set_trans(Tween.TRANS_SINE)
		var prev := path_coords[i - 1]
		var prev_world := HexUtil.axial_to_world(prev.x, prev.y)
		var step_distance := prev_world.distance_to(
			HexUtil.axial_to_world(
				path_coords[i].x, path_coords[i].y
			)
		)
		var duration := step_distance / move_speed
		_move_tween.tween_property(
			self, "position", target, duration
		).set_trans(Tween.TRANS_LINEAR)
	_move_tween.finished.connect(_on_move_finished)


func set_dragging_card(value: bool) -> void:
	_is_dragging_card = value
	if not value and not _is_targeting_move:
		_face_direction(_last_facing)


func _process(delta: float) -> void:
	if (_is_targeting_move or _is_dragging_card) and not _is_moving and _camera and _model:
		var mouse_pos := get_viewport().get_mouse_position()
		var ground := _screen_to_ground(mouse_pos)
		if ground != Vector3.ZERO:
			_face_toward_instant(ground)
	if _model and not _is_moving:
		_current_angle = lerp_angle(
			_current_angle, _target_angle, 4.0 * delta
		)
		_model.rotation.y = _current_angle


func _on_move_finished() -> void:
	_is_moving = false
	if _model:
		_current_angle = _model.rotation.y
		_target_angle = _current_angle
	movement_finished.emit()


func _face_toward(target: Vector3) -> void:
	var dir := target - position
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		_last_facing = dir.normalized()
		var angle := atan2(-dir.x, -dir.z)
		_target_angle = angle
		_current_angle = angle
		if _model:
			_model.rotation.y = angle


func _face_toward_instant(target: Vector3) -> void:
	if not _model:
		return
	var dir := target - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		_target_angle = atan2(-dir.x, -dir.z)


func _face_direction(dir: Vector3) -> void:
	if not _model:
		return
	if dir.length_squared() > 0.001:
		_target_angle = atan2(-dir.x, -dir.z)


func _screen_to_ground(screen_pos: Vector2) -> Vector3:
	if not _camera:
		return Vector3.ZERO
	var origin := _camera.project_ray_origin(screen_pos)
	var ray_dir := _camera.project_ray_normal(screen_pos)
	if absf(ray_dir.y) < 0.001:
		return Vector3.ZERO
	var t := -origin.y / ray_dir.y
	return origin + ray_dir * t


func _build_character_model() -> Node3D:
	var node := AssetPack.get_model("Guy", 0.003)
	node.position = Vector3(0, _ground_y, 0)
	return node


func _build_boot_model() -> Node3D:
	var root := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var brown := Color(0.45, 0.28, 0.15)
	var segs: int = 8
	var spacing: float = 0.10
	# Build two boots side by side
	for side: float in [-1.0, 1.0]:
		var x_off: float = side * spacing
		_build_single_boot(
			st, brown, segs, x_off,
		)
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	mi.material_override = mat
	mi.mesh = st.commit()
	mi.scale = Vector3(1.26, 1.26, 1.26)
	mi.position.y = 0.0
	root.add_child(mi)
	return root


static func _build_single_boot(
	st: SurfaceTool, brown: Color,
	segs: int, x_off: float,
) -> void:
	var sole_lift: float = 0.07
	var shaft_r_bot: float = 0.07
	var shaft_r_top: float = 0.09
	var shaft_h: float = 0.35
	var shaft_lean: float = -0.08
	_add_leaning_cylinder(
		st, shaft_r_bot, shaft_r_top, shaft_h,
		Vector3(x_off, sole_lift, 0),
		Vector3(0, 0, shaft_lean),
		segs, brown,
	)
	var bot_hw: float = 0.09
	var bot_hl: float = 0.176
	var bot_r: float = 0.065
	var top_hw: float = 0.07
	var top_hl: float = 0.152
	var top_r: float = 0.05
	var toe_h: float = 0.12
	var toe_front_lift: float = 0.10
	_add_rounded_rect_prism_curved(
		st, bot_hw, bot_hl, top_hw, top_hl,
		bot_r, top_r, toe_h,
		Vector3(x_off, -0.02, -bot_hl * 0.5),
		toe_front_lift, segs, brown.darkened(0.1),
	)
	var rim_pos := Vector3(
		x_off, sole_lift + shaft_h, shaft_lean,
	)
	_add_ring(
		st, shaft_r_top + 0.015, 0.025,
		rim_pos, segs, brown.lightened(0.15),
	)


static func _add_rounded_box(
	st: SurfaceTool, hw: float, hl: float,
	h: float, y: float, segs: int, color: Color,
) -> void:
	var pts: Array[Vector2] = []
	for i in segs:
		var angle := TAU * float(i) / float(segs)
		pts.append(Vector2(
			cos(angle) * hw, sin(angle) * hl,
		))
	var center_top := Vector3(0, y + h, 0)
	var center_bot := Vector3(0, y, 0)
	for i in segs:
		var i2 := (i + 1) % segs
		var p0 := Vector3(pts[i].x, y, pts[i].y)
		var p1 := Vector3(pts[i2].x, y, pts[i2].y)
		var p2 := Vector3(pts[i2].x, y + h, pts[i2].y)
		var p3 := Vector3(pts[i].x, y + h, pts[i].y)
		var n := (p1 - p0).cross(p3 - p0).normalized()
		st.set_normal(n)
		st.set_color(color)
		st.add_vertex(p0)
		st.add_vertex(p1)
		st.add_vertex(p2)
		st.add_vertex(p0)
		st.add_vertex(p2)
		st.add_vertex(p3)
	for i in segs:
		var i2 := (i + 1) % segs
		st.set_normal(Vector3.UP)
		st.set_color(color)
		st.add_vertex(center_top)
		st.add_vertex(Vector3(pts[i].x, y + h, pts[i].y))
		st.add_vertex(Vector3(pts[i2].x, y + h, pts[i2].y))


static func _add_tapered_cylinder(
	st: SurfaceTool, r_bot: float, r_top: float,
	h: float, origin: Vector3, segs: int,
	color: Color,
) -> void:
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var b0 := Vector3(
			cos(a0) * r_bot + origin.x, origin.y,
			sin(a0) * r_bot + origin.z,
		)
		var b1 := Vector3(
			cos(a1) * r_bot + origin.x, origin.y,
			sin(a1) * r_bot + origin.z,
		)
		var t0 := Vector3(
			cos(a0) * r_top + origin.x, origin.y + h,
			sin(a0) * r_top + origin.z,
		)
		var t1 := Vector3(
			cos(a1) * r_top + origin.x, origin.y + h,
			sin(a1) * r_top + origin.z,
		)
		var n := (b1 - b0).cross(t0 - b0).normalized()
		st.set_normal(n)
		st.set_color(color)
		st.add_vertex(b0)
		st.add_vertex(b1)
		st.add_vertex(t1)
		st.add_vertex(b0)
		st.add_vertex(t1)
		st.add_vertex(t0)
	var top_center := Vector3(origin.x, origin.y + h, origin.z)
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		st.set_normal(Vector3.UP)
		st.set_color(color)
		st.add_vertex(top_center)
		st.add_vertex(Vector3(
			cos(a0) * r_top + origin.x, origin.y + h,
			sin(a0) * r_top + origin.z,
		))
		st.add_vertex(Vector3(
			cos(a1) * r_top + origin.x, origin.y + h,
			sin(a1) * r_top + origin.z,
		))


static func _add_leaning_cylinder(
	st: SurfaceTool, r_bot: float, r_top: float,
	h: float, origin: Vector3, top_offset: Vector3,
	segs: int, color: Color,
) -> void:
	var top_origin := Vector3(
		origin.x + top_offset.x,
		origin.y + h,
		origin.z + top_offset.z,
	)
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var b0 := Vector3(
			cos(a0) * r_bot + origin.x, origin.y,
			sin(a0) * r_bot + origin.z,
		)
		var b1 := Vector3(
			cos(a1) * r_bot + origin.x, origin.y,
			sin(a1) * r_bot + origin.z,
		)
		var t0 := Vector3(
			cos(a0) * r_top + top_origin.x, top_origin.y,
			sin(a0) * r_top + top_origin.z,
		)
		var t1 := Vector3(
			cos(a1) * r_top + top_origin.x, top_origin.y,
			sin(a1) * r_top + top_origin.z,
		)
		var n := (b1 - b0).cross(t0 - b0).normalized()
		st.set_normal(n)
		st.set_color(color)
		st.add_vertex(b0)
		st.add_vertex(b1)
		st.add_vertex(t1)
		st.add_vertex(b0)
		st.add_vertex(t1)
		st.add_vertex(t0)
	var top_center := top_origin
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		st.set_normal(Vector3.UP)
		st.set_color(color)
		st.add_vertex(top_center)
		st.add_vertex(Vector3(
			cos(a0) * r_top + top_origin.x, top_origin.y,
			sin(a0) * r_top + top_origin.z,
		))
		st.add_vertex(Vector3(
			cos(a1) * r_top + top_origin.x, top_origin.y,
			sin(a1) * r_top + top_origin.z,
		))


static func _add_rounded_rect_prism_curved(
	st: SurfaceTool, bot_hw: float, bot_hl: float,
	top_hw: float, top_hl: float,
	bot_r: float, top_r: float, h: float,
	origin: Vector3, front_lift: float,
	segs: int, color: Color,
) -> void:
	var bot_pts := _rounded_rect_pts(bot_hw, bot_hl, bot_r, segs)
	var top_pts := _rounded_rect_pts(top_hw, top_hl, top_r, segs)
	var n_pts := bot_pts.size()
	var max_z := bot_hl
	for i in n_pts:
		var bz: float = bot_pts[i].y
		var tz: float = top_pts[i].y
		var min_neg_z := -bot_hl
		var range_z := max_z - min_neg_z
		var bt: float = 0.0
		var tt: float = 0.0
		if range_z > 0.0:
			bt = clampf((bz - min_neg_z) / range_z, 0.0, 1.0)
			tt = clampf((tz - min_neg_z) / range_z, 0.0, 1.0)
		bot_pts[i] = Vector2(bot_pts[i].x, bot_pts[i].y)
		top_pts[i] = Vector2(top_pts[i].x, top_pts[i].y)
		var i2 := (i + 1) % n_pts
		var bz2: float = bot_pts[i2].y
		var tz2: float = top_pts[i2].y
		var bt2: float = 0.0
		var tt2: float = 0.0
		if range_z > 0.0:
			bt2 = clampf((bz2 - min_neg_z) / range_z, 0.0, 1.0)
			tt2 = clampf((tz2 - min_neg_z) / range_z, 0.0, 1.0)
		var b0 := Vector3(
			bot_pts[i].x + origin.x,
			origin.y + front_lift * bt,
			bz + origin.z,
		)
		var b1 := Vector3(
			bot_pts[i2].x + origin.x,
			origin.y + front_lift * bt2,
			bz2 + origin.z,
		)
		var t0 := Vector3(
			top_pts[i].x + origin.x,
			origin.y + h + front_lift * tt,
			tz + origin.z,
		)
		var t1 := Vector3(
			top_pts[i2].x + origin.x,
			origin.y + h + front_lift * tt2,
			tz2 + origin.z,
		)
		var n := (b1 - b0).cross(t0 - b0).normalized()
		st.set_normal(n)
		st.set_color(color)
		st.add_vertex(b0)
		st.add_vertex(b1)
		st.add_vertex(t1)
		st.add_vertex(b0)
		st.add_vertex(t1)
		st.add_vertex(t0)
	# Top cap
	var top_center := Vector3(
		origin.x, origin.y + h + front_lift * 0.5, origin.z,
	)
	for i in n_pts:
		var i2 := (i + 1) % n_pts
		var tz: float = top_pts[i].y
		var tz2: float = top_pts[i2].y
		var min_neg_z := -top_hl
		var range_z := max_z - min_neg_z
		var tt: float = 0.0
		var tt2: float = 0.0
		if range_z > 0.0:
			tt = clampf((tz - min_neg_z) / range_z, 0.0, 1.0)
			tt2 = clampf((tz2 - min_neg_z) / range_z, 0.0, 1.0)
		st.set_normal(Vector3.UP)
		st.set_color(color)
		st.add_vertex(top_center)
		st.add_vertex(Vector3(
			top_pts[i].x + origin.x,
			origin.y + h + front_lift * tt,
			tz + origin.z,
		))
		st.add_vertex(Vector3(
			top_pts[i2].x + origin.x,
			origin.y + h + front_lift * tt2,
			tz2 + origin.z,
		))


static func _add_ring(
	st: SurfaceTool, r: float, h: float,
	origin: Vector3, segs: int, color: Color,
) -> void:
	_add_tapered_cylinder(st, r, r, h, origin, segs, color)


static func _rounded_rect_pts(
	hw: float, hl: float, r: float, segs: int,
) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	var corner_segs := maxi(segs / 4, 2)
	var corners: Array[Vector2] = [
		Vector2(hw - r, -(hl - r)),
		Vector2(hw - r, hl - r),
		Vector2(-(hw - r), hl - r),
		Vector2(-(hw - r), -(hl - r)),
	]
	for c_idx in 4:
		var start_angle := -PI * 0.5 + float(c_idx) * PI * 0.5
		var cx: float = corners[c_idx].x
		var cy: float = corners[c_idx].y
		for j in corner_segs:
			var a := start_angle + float(j) / float(corner_segs) * PI * 0.5
			pts.append(Vector2(cx + cos(a) * r, cy + sin(a) * r))
	return pts


static func _add_rounded_rect_prism(
	st: SurfaceTool, bot_hw: float, bot_hl: float,
	top_hw: float, top_hl: float,
	bot_r: float, top_r: float, h: float,
	origin: Vector3, segs: int, color: Color,
) -> void:
	var bot_pts := _rounded_rect_pts(bot_hw, bot_hl, bot_r, segs)
	var top_pts := _rounded_rect_pts(top_hw, top_hl, top_r, segs)
	var n_pts := bot_pts.size()
	# Sides
	for i in n_pts:
		var i2 := (i + 1) % n_pts
		var b0 := Vector3(
			bot_pts[i].x + origin.x, origin.y,
			bot_pts[i].y + origin.z,
		)
		var b1 := Vector3(
			bot_pts[i2].x + origin.x, origin.y,
			bot_pts[i2].y + origin.z,
		)
		var t0 := Vector3(
			top_pts[i].x + origin.x, origin.y + h,
			top_pts[i].y + origin.z,
		)
		var t1 := Vector3(
			top_pts[i2].x + origin.x, origin.y + h,
			top_pts[i2].y + origin.z,
		)
		var n := (b1 - b0).cross(t0 - b0).normalized()
		st.set_normal(n)
		st.set_color(color)
		st.add_vertex(b0)
		st.add_vertex(b1)
		st.add_vertex(t1)
		st.add_vertex(b0)
		st.add_vertex(t1)
		st.add_vertex(t0)
	# Top cap
	var top_center := Vector3(origin.x, origin.y + h, origin.z)
	for i in n_pts:
		var i2 := (i + 1) % n_pts
		st.set_normal(Vector3.UP)
		st.set_color(color)
		st.add_vertex(top_center)
		st.add_vertex(Vector3(
			top_pts[i].x + origin.x, origin.y + h,
			top_pts[i].y + origin.z,
		))
		st.add_vertex(Vector3(
			top_pts[i2].x + origin.x, origin.y + h,
			top_pts[i2].y + origin.z,
		))


func _apply_color_wash() -> void:
	if not _model:
		return
	_color_wash_recursive(_model)


func _color_wash_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var overlay := StandardMaterial3D.new()
		overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		overlay.albedo_color = Color(
			avatar_color.r, avatar_color.g,
			avatar_color.b, 0.45,
		)
		overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_overlay = overlay
	for child in node.get_children():
		_color_wash_recursive(child)
