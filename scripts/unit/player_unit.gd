extends Node3D

signal movement_finished

@export var move_speed: float = 2.7

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
var _is_selected: bool = false
var _is_targeting_move: bool = false
var _camera: Camera3D

var _boots_mesh_path: String = (
	"res://assets/models/boots/boots.obj"
)


func _ready() -> void:
	var old_mesh: Node = get_node_or_null("MeshInstance3D")
	if old_mesh:
		old_mesh.queue_free()
	var mesh_res: Mesh = load(_boots_mesh_path) as Mesh
	if mesh_res:
		_model = Node3D.new()
		var mi := MeshInstance3D.new()
		mi.mesh = mesh_res
		mi.scale = Vector3(0.0176, 0.012, 0.0224)
		mi.rotation.y = PI + PI / 2.0
		_model.add_child(mi)
		add_child(_model)
	else:
		_model = _build_boot_model()
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
	position.y = terrain_height + 0.15


func offset_for_packing(
	has_building: bool, has_yields: bool = false,
) -> void:
	if not _model:
		return
	if has_building:
		_model.position = Vector3(0.4, 0, 0.3)
	elif has_yields:
		_model.position = Vector3(0.15, 0, 0.55)
	else:
		_model.position = Vector3.ZERO


func move_to(coord: Vector2i, terrain_height: float = 0.0) -> void:
	state.move_to(coord)
	var target := HexUtil.axial_to_world(coord.x, coord.y)
	target.y = terrain_height + 0.15
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
		target.y = terrain_heights[i] + 0.15
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


func _process(_delta: float) -> void:
	if _is_targeting_move and not _is_moving and _camera and _model:
		var mouse_pos := get_viewport().get_mouse_position()
		var ground := _screen_to_ground(mouse_pos)
		if ground != Vector3.ZERO:
			_face_toward_instant(ground)


func _on_move_finished() -> void:
	_is_moving = false
	movement_finished.emit()


func _face_toward(target: Vector3) -> void:
	var dir := target - position
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		_last_facing = dir.normalized()
		_face_direction(_last_facing)


func _face_toward_instant(target: Vector3) -> void:
	if not _model:
		return
	var dir := target - global_position
	dir.y = 0.0
	if dir.length_squared() > 0.001:
		_model.look_at(global_position - dir, Vector3.UP)


func _face_direction(dir: Vector3) -> void:
	if not _model:
		return
	if dir.length_squared() > 0.001:
		_model.look_at(
			_model.global_position - dir, Vector3.UP
		)


func _screen_to_ground(screen_pos: Vector2) -> Vector3:
	if not _camera:
		return Vector3.ZERO
	var origin := _camera.project_ray_origin(screen_pos)
	var ray_dir := _camera.project_ray_normal(screen_pos)
	if absf(ray_dir.y) < 0.001:
		return Vector3.ZERO
	var t := -origin.y / ray_dir.y
	return origin + ray_dir * t


func _build_boot_model() -> Node3D:
	var root := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var brown := Color(0.45, 0.28, 0.15)
	var sole := Color(0.2, 0.12, 0.08)
	# Boot sole (flat box)
	var sw := 0.15
	var sl := 0.35
	var sh := 0.05
	_add_box(st, Vector3(-sw, 0, -sl * 0.4),
		Vector3(sw, sh, sl * 0.6), sole)
	# Boot shaft (back upright part)
	var bw := 0.13
	var bh := 0.4
	var bd := 0.15
	_add_box(st, Vector3(-bw, sh, -bd * 0.3),
		Vector3(bw, bh, bd * 0.7), brown)
	# Toe cap (front low part)
	var tw := 0.14
	var th := 0.15
	_add_box(st, Vector3(-tw, sh, -sl * 0.4),
		Vector3(tw, th, -bd * 0.3), brown.darkened(0.1))
	var mi := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	mi.material_override = mat
	mi.mesh = st.commit()
	mi.scale = Vector3(0.85, 0.85, 0.85)
	mi.position.y = -0.15
	root.add_child(mi)
	return root


static func _add_box(
	st: SurfaceTool, min_pt: Vector3,
	max_pt: Vector3, color: Color,
) -> void:
	var corners: Array[Vector3] = [
		Vector3(min_pt.x, min_pt.y, min_pt.z),
		Vector3(max_pt.x, min_pt.y, min_pt.z),
		Vector3(max_pt.x, max_pt.y, min_pt.z),
		Vector3(min_pt.x, max_pt.y, min_pt.z),
		Vector3(min_pt.x, min_pt.y, max_pt.z),
		Vector3(max_pt.x, min_pt.y, max_pt.z),
		Vector3(max_pt.x, max_pt.y, max_pt.z),
		Vector3(min_pt.x, max_pt.y, max_pt.z),
	]
	var faces: Array[Array] = [
		[0, 1, 2, 3, Vector3(0, 0, -1)],
		[5, 4, 7, 6, Vector3(0, 0, 1)],
		[4, 0, 3, 7, Vector3(-1, 0, 0)],
		[1, 5, 6, 2, Vector3(1, 0, 0)],
		[3, 2, 6, 7, Vector3(0, 1, 0)],
		[4, 5, 1, 0, Vector3(0, -1, 0)],
	]
	for face: Array in faces:
		var i0: int = face[0]
		var i1: int = face[1]
		var i2: int = face[2]
		var i3: int = face[3]
		var n: Vector3 = face[4]
		st.set_normal(n)
		st.set_color(color)
		st.add_vertex(corners[i0])
		st.add_vertex(corners[i1])
		st.add_vertex(corners[i2])
		st.add_vertex(corners[i0])
		st.add_vertex(corners[i2])
		st.add_vertex(corners[i3])


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
