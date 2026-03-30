class_name FogCloudManager
extends Node3D

const BLOBS_PER_TILE := 4
const BLOB_SCALE_MIN := 0.3
const BLOB_SCALE_MAX := 0.5
const CLOUD_Y := 0.6
const BAND_WIDTH := 0.15

var _tile_blobs: Dictionary = {}
var _blob_anim: Array = []
var _blob_nodes: Array = []
var _cloud_mat: StandardMaterial3D


func _ready() -> void:
	_cloud_mat = StandardMaterial3D.new()
	_cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cloud_mat.albedo_color = Color(0.65, 0.65, 0.7, 0.45)
	_cloud_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cloud_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cloud_mat.vertex_color_use_as_albedo = true
	_cloud_mat.render_priority = 10
	_cloud_mat.no_depth_test = true


func add_fog(
	coord: Vector2i, world_pos: Vector3,
	_tile_height: float,
) -> void:
	if _tile_blobs.has(coord):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)
	var indices: Array[int] = []
	for _b in BLOBS_PER_TILE:
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(0.0, 0.45)
		var scale: float = rng.randf_range(
			BLOB_SCALE_MIN, BLOB_SCALE_MAX
		)
		var offset := Vector3(
			cos(angle) * dist, 0.0, sin(angle) * dist
		)
		var blob_coord := Vector2i(
			coord.x * 100 + _b, coord.y * 100 + _b
		)
		var mesh := _build_blob_mesh(blob_coord, scale)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _cloud_mat
		mi.position = world_pos + offset
		mi.position.y = CLOUD_Y + rng.randf_range(-0.05, 0.1)
		mi.cast_shadow = (
			GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		)
		add_child(mi)
		var idx: int = _blob_nodes.size()
		indices.append(idx)
		_blob_nodes.append(mi)
		_blob_anim.append({
			"phase": rng.randf() * TAU,
			"breathe_spd": rng.randf_range(0.3, 0.8),
			"breathe_amp": rng.randf_range(0.05, 0.15),
			"drift_spd": rng.randf_range(0.02, 0.05),
			"base_y": mi.position.y,
			"base_pos": mi.position,
		})
	_tile_blobs[coord] = indices


func remove_fog(coord: Vector2i) -> void:
	if not _tile_blobs.has(coord):
		return
	var indices: Array = _tile_blobs[coord]
	for idx: int in indices:
		if idx < _blob_nodes.size() and _blob_nodes[idx] != null:
			var mi: MeshInstance3D = (
				_blob_nodes[idx] as MeshInstance3D
			)
			mi.queue_free()
			_blob_nodes[idx] = null
			_blob_anim[idx] = null
	_tile_blobs.erase(coord)


func has_fog(coord: Vector2i) -> bool:
	return _tile_blobs.has(coord)


func rebuild() -> void:
	pass


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() * 0.0005
	for i in _blob_nodes.size():
		if _blob_nodes[i] == null:
			continue
		var mi: MeshInstance3D = _blob_nodes[i] as MeshInstance3D
		var d: Dictionary = _blob_anim[i]
		var phase: float = d["phase"] as float
		var bs: float = d["breathe_spd"] as float
		var ba: float = d["breathe_amp"] as float
		var ds: float = d["drift_spd"] as float
		var base_pos: Vector3 = d["base_pos"] as Vector3
		var breathe: float = 1.0 + ba * sin(t * bs + phase)
		mi.scale = Vector3(breathe, breathe, breathe)
		mi.position.x = base_pos.x + sin(t * ds + phase) * 0.15
		mi.position.z = base_pos.z + cos(
			t * ds * 0.7 + phase * 1.3
		) * 0.15
		mi.position.y = (
			base_pos.y + sin(t * ds * 0.5 + phase) * 0.03
		)


func _build_blob_mesh(
	coord: Vector2i, scale: float,
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners: Array[Vector3] = []
	for i in 6:
		var angle: float = TAU * float(i) / 6.0 + PI / 6.0
		corners.append(Vector3(
			cos(angle) * HexUtil.HEX_SIZE * scale,
			0.0,
			sin(angle) * HexUtil.HEX_SIZE * scale,
		))
	var all_edge_pts: Array[Array] = []
	for i in 6:
		var c0: Vector3 = corners[i]
		var c1: Vector3 = corners[(i + 1) % 6]
		var pts: Array[Vector3] = (
			HexMeshGenerator.get_wavy_edge_points(
				c0, c1, coord, i, 8, 0.3 * scale
			)
		)
		all_edge_pts.append(pts)
	var center := Vector3.ZERO
	var dome_h: float = 0.2 * scale
	var band: float = BAND_WIDTH * scale
	# Inner triangles (center to inner ring) — full alpha
	# Outer band (inner ring to edge) — alpha gradient 1→0
	for i in 6:
		var pts: Array = all_edge_pts[i]
		for j in range(pts.size() - 1):
			var p0: Vector3 = pts[j]
			var p1: Vector3 = pts[j + 1]
			var edge_mid := (p0 + p1) * 0.5
			var dir_to_center := (center - edge_mid).normalized()
			var inner0 := p0 + dir_to_center * band
			var inner1 := p1 + dir_to_center * band
			var inner_y: float = dome_h * 0.8
			# Inner tri: center → inner0 → inner1
			st.set_normal(Vector3.UP)
			st.set_color(Color(1, 1, 1, 1))
			st.add_vertex(Vector3(center.x, dome_h, center.z))
			st.add_vertex(Vector3(
				inner0.x, inner_y, inner0.z
			))
			st.add_vertex(Vector3(
				inner1.x, inner_y, inner1.z
			))
			# Outer band: inner → edge (alpha 1 → 0)
			st.set_normal(Vector3.UP)
			st.set_color(Color(1, 1, 1, 1))
			st.add_vertex(Vector3(
				inner0.x, inner_y, inner0.z
			))
			st.set_color(Color(1, 1, 1, 0))
			st.add_vertex(Vector3(p0.x, 0.0, p0.z))
			st.set_color(Color(1, 1, 1, 0))
			st.add_vertex(Vector3(p1.x, 0.0, p1.z))
			st.set_color(Color(1, 1, 1, 0))
			st.add_vertex(Vector3(p1.x, 0.0, p1.z))
			st.set_color(Color(1, 1, 1, 1))
			st.add_vertex(Vector3(
				inner1.x, inner_y, inner1.z
			))
			st.set_color(Color(1, 1, 1, 1))
			st.add_vertex(Vector3(
				inner0.x, inner_y, inner0.z
			))
	return st.commit()
