class_name FogCloudManager
extends Node3D

const BLOBS_PER_TILE := 10
const CLOUD_Y := 1.1
const BAND_RATIO := 0.35

var _tile_blobs: Dictionary = {}
var _blob_anim: Array = []
var _blob_nodes: Array = []
var _cloud_mat: StandardMaterial3D


func _ready() -> void:
	_cloud_mat = StandardMaterial3D.new()
	_cloud_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_cloud_mat.albedo_color = Color(1, 1, 1, 1)
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
	for b in BLOBS_PER_TILE:
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(0.2, 0.6)
		var sx: float = rng.randf_range(1.0, 2.0)
		var sz: float = rng.randf_range(0.7, 1.5)
		var rot: float = rng.randf() * TAU
		var offset := Vector3(
			cos(angle) * dist, 0.0, sin(angle) * dist
		)
		var blob_seed := Vector2i(
			coord.x * 100 + b, coord.y * 100 + b
		)
		var mesh := _build_blob_mesh(blob_seed, sx, sz, rot)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _cloud_mat
		mi.position = world_pos + offset
		mi.position.y = CLOUD_Y + rng.randf_range(-0.03, 0.08)
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
			"breathe_amp": rng.randf_range(0.03, 0.1),
			"drift_spd": rng.randf_range(0.02, 0.05),
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
	var t: float = Time.get_ticks_msec() * 0.001
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
		mi.scale = Vector3(breathe, 1.0, breathe)
		mi.position.x = (
			base_pos.x + sin(t * ds + phase) * 0.12
		)
		mi.position.z = (
			base_pos.z
			+ cos(t * ds * 0.7 + phase * 1.3) * 0.12
		)
		mi.position.y = (
			base_pos.y + sin(t * ds * 0.5 + phase) * 0.02
		)


func _build_blob_mesh(
	seed_coord: Vector2i, scale_x: float,
	scale_z: float, rotation: float,
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 36
	var cloud_col := Color(0.62, 0.62, 0.67, 0.22)
	var edge_col := Color(0.65, 0.65, 0.7, 0.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_coord)
	# Generate wobbly perimeter points
	var outer_pts: Array[Vector2] = []
	var inner_pts: Array[Vector2] = []
	for i in segs:
		var a: float = TAU * float(i) / float(segs)
		# Elliptical base radius
		var rx: float = HexUtil.HEX_SIZE * scale_x
		var rz: float = HexUtil.HEX_SIZE * scale_z
		var base_r: float = (rx * rz) / sqrt(
			(rz * cos(a)) * (rz * cos(a))
			+ (rx * sin(a)) * (rx * sin(a))
		)
		# Noisy irregular edge
		var wobble: float = (
			sin(a * 2.0 + rng.randf() * TAU) * 0.2
			+ sin(a * 5.0 + rng.randf() * TAU) * 0.15
			+ sin(a * 9.0 + rng.randf() * TAU) * 0.1
			+ sin(a * 13.0 + rng.randf() * TAU) * 0.08
			+ sin(a * 1.5 + rng.randf() * TAU) * 0.18
			+ rng.randf_range(-0.12, 0.12)
		) * base_r
		var r: float = base_r + wobble
		# Apply rotation
		var px: float = cos(a + rotation) * r
		var pz: float = sin(a + rotation) * r
		outer_pts.append(Vector2(px, pz))
		var inner_r: float = r * (1.0 - BAND_RATIO)
		inner_pts.append(Vector2(
			cos(a + rotation) * inner_r,
			sin(a + rotation) * inner_r,
		))
	# Smooth the points
	for _pass in 2:
		var smoothed_o: Array[Vector2] = []
		var smoothed_i: Array[Vector2] = []
		for i in segs:
			var prev: int = (i - 1 + segs) % segs
			var next: int = (i + 1) % segs
			smoothed_o.append(
				outer_pts[prev] * 0.25
				+ outer_pts[i] * 0.5
				+ outer_pts[next] * 0.25
			)
			smoothed_i.append(
				inner_pts[prev] * 0.25
				+ inner_pts[i] * 0.5
				+ inner_pts[next] * 0.25
			)
		outer_pts = smoothed_o
		inner_pts = smoothed_i
	var y: float = 0.01
	# Inner fill — full alpha
	for i in segs:
		var i2: int = (i + 1) % segs
		st.set_normal(Vector3.UP)
		st.set_color(cloud_col)
		st.add_vertex(Vector3(0, y, 0))
		st.add_vertex(Vector3(inner_pts[i].x, y, inner_pts[i].y))
		st.add_vertex(Vector3(
			inner_pts[i2].x, y, inner_pts[i2].y
		))
	# Outer band — alpha gradient
	for i in segs:
		var i2: int = (i + 1) % segs
		st.set_normal(Vector3.UP)
		# Tri 1: inner_i, outer_i, outer_i2
		st.set_color(cloud_col)
		st.add_vertex(Vector3(
			inner_pts[i].x, y, inner_pts[i].y
		))
		st.set_color(edge_col)
		st.add_vertex(Vector3(
			outer_pts[i].x, y, outer_pts[i].y
		))
		st.set_color(edge_col)
		st.add_vertex(Vector3(
			outer_pts[i2].x, y, outer_pts[i2].y
		))
		# Tri 2: outer_i2, inner_i2, inner_i
		st.set_color(edge_col)
		st.add_vertex(Vector3(
			outer_pts[i2].x, y, outer_pts[i2].y
		))
		st.set_color(cloud_col)
		st.add_vertex(Vector3(
			inner_pts[i2].x, y, inner_pts[i2].y
		))
		st.set_color(cloud_col)
		st.add_vertex(Vector3(
			inner_pts[i].x, y, inner_pts[i].y
		))
	return st.commit()
