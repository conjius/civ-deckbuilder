class_name FogCloudManager
extends Node3D

var _clouds: Dictionary = {}
var _cloud_mat: StandardMaterial3D
var _anim_data: Dictionary = {}


func _ready() -> void:
	_cloud_mat = StandardMaterial3D.new()
	_cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cloud_mat.albedo_color = Color(0.6, 0.6, 0.65, 0.5)
	_cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cloud_mat.cull_mode = BaseMaterial3D.CULL_DISABLED


func add_fog(
	coord: Vector2i, world_pos: Vector3,
	_tile_height: float,
) -> void:
	if _clouds.has(coord):
		return
	var mesh := _build_cloud_mesh(coord)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _cloud_mat
	mi.position = world_pos
	mi.position.y = 0.55
	mi.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
	add_child(mi)
	_clouds[coord] = mi
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)
	_anim_data[coord] = {
		"phase": rng.randf() * TAU,
		"breathe_spd": rng.randf_range(0.3, 0.8),
		"breathe_amp": rng.randf_range(0.05, 0.15),
		"drift_spd": rng.randf_range(0.02, 0.05),
		"base_y": 0.55,
	}


func remove_fog(coord: Vector2i) -> void:
	if _clouds.has(coord):
		var mi: MeshInstance3D = _clouds[coord] as MeshInstance3D
		mi.queue_free()
		_clouds.erase(coord)
		_anim_data.erase(coord)


func has_fog(coord: Vector2i) -> bool:
	return _clouds.has(coord)


func rebuild() -> void:
	pass


func _process(_delta: float) -> void:
	if _clouds.is_empty():
		return
	var t: float = Time.get_ticks_msec() * 0.0005
	for coord: Vector2i in _clouds:
		var mi: MeshInstance3D = _clouds[coord] as MeshInstance3D
		var d: Dictionary = _anim_data[coord]
		var phase: float = d["phase"] as float
		var bs: float = d["breathe_spd"] as float
		var ba: float = d["breathe_amp"] as float
		var ds: float = d["drift_spd"] as float
		var base_y: float = d["base_y"] as float
		var breathe: float = 1.0 + ba * sin(t * bs + phase)
		mi.scale = Vector3(1.0, breathe, 1.0)
		mi.position.y = (
			base_y + sin(t * ds + phase) * 0.05
		)


func _build_cloud_mesh(coord: Vector2i) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array[Vector3] = []
	for i in 6:
		var angle: float = TAU * float(i) / 6.0 + PI / 6.0
		corners.append(Vector3(
			cos(angle) * HexUtil.HEX_SIZE * 1.05,
			0.0,
			sin(angle) * HexUtil.HEX_SIZE * 1.05,
		))
	var all_edge_pts: Array[Array] = []
	for i in 6:
		var c0: Vector3 = corners[i]
		var c1: Vector3 = corners[(i + 1) % 6]
		var pts: Array[Vector3] = (
			HexMeshGenerator.get_wavy_edge_points(
				c0, c1, coord, i, 12, 0.4
			)
		)
		all_edge_pts.append(pts)
	var center := Vector3.ZERO
	var dome_h := 0.3
	# Top dome: center raised, edges at y=0
	st.set_color(Color.WHITE)
	for i in 6:
		var pts: Array = all_edge_pts[i]
		for j in range(pts.size() - 1):
			var p0: Vector3 = pts[j]
			var p1: Vector3 = pts[j + 1]
			var n := Vector3.UP
			st.set_normal(n)
			st.add_vertex(Vector3(center.x, dome_h, center.z))
			st.add_vertex(Vector3(p0.x, 0.0, p0.z))
			st.add_vertex(Vector3(p1.x, 0.0, p1.z))
	# Bottom flat cap
	for i in 6:
		var pts: Array = all_edge_pts[i]
		for j in range(pts.size() - 1):
			var p0: Vector3 = pts[j]
			var p1: Vector3 = pts[j + 1]
			st.set_normal(Vector3.DOWN)
			st.add_vertex(center)
			st.add_vertex(Vector3(p1.x, 0.0, p1.z))
			st.add_vertex(Vector3(p0.x, 0.0, p0.z))
	return st.commit()
