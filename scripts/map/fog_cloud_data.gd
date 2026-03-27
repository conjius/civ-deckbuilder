class_name FogCloudData
extends RefCounted

const CLUSTERS_PER_TILE := 2
const MIN_BLOBS_PER_CLUSTER := 2
const MAX_BLOBS_PER_CLUSTER := 3
const CLOUD_Y_OFFSET := 0.55

var _tile_blobs: Dictionary = {}  # Vector2i -> Array[int] (indices into _instances)
var _instances: Array = []  # {transform: Transform3D, custom: Color}


func has_tile(coord: Vector2i) -> bool:
	return _tile_blobs.has(coord)


func get_blob_count() -> int:
	return _instances.size()


func add_tile(coord: Vector2i, world_pos: Vector3, _tile_height: float) -> void:
	if _tile_blobs.has(coord):
		return
	var indices: Array[int] = []
	var base_y: float = world_pos.y + CLOUD_Y_OFFSET
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(coord)
	for _c in CLUSTERS_PER_TILE:
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(0.0, 0.5)
		var cluster_pos := Vector3(
			world_pos.x + cos(angle) * dist,
			base_y + rng.randf_range(-0.05, 0.15),
			world_pos.z + sin(angle) * dist,
		)
		var blob_count: int = rng.randi_range(
			MIN_BLOBS_PER_CLUSTER, MAX_BLOBS_PER_CLUSTER
		)
		for _b in blob_count:
			var radius: float = rng.randf_range(0.25, 0.5)
			var height: float = rng.randf_range(0.4, 0.7)
			var blob_pos := Vector3(
				cluster_pos.x + rng.randf_range(-0.2, 0.2),
				cluster_pos.y + rng.randf_range(-0.06, 0.1),
				cluster_pos.z + rng.randf_range(-0.2, 0.2),
			)
			var sx: float = rng.randf_range(0.7, 1.8) * radius
			var sy: float = rng.randf_range(0.4, 1.0) * height
			var sz: float = rng.randf_range(0.7, 1.8) * radius
			var rot_y: float = rng.randf() * TAU
			var basis := Basis(
				Vector3.UP, rot_y
			).scaled(Vector3(sx, sy, sz))
			var xform := Transform3D(basis, blob_pos)
			var phase: float = rng.randf() * TAU
			var drift_speed: float = rng.randf_range(0.03, 0.08)
			var breathe_speed: float = rng.randf_range(0.3, 0.8)
			var breathe_amp: float = rng.randf_range(0.1, 0.3)
			var custom := Color(phase, drift_speed, breathe_speed, breathe_amp)
			var idx: int = _instances.size()
			_instances.append({
				"transform": xform,
				"custom": custom,
			})
			indices.append(idx)
	_tile_blobs[coord] = indices


func remove_tile(coord: Vector2i) -> void:
	if not _tile_blobs.has(coord):
		return
	var to_remove: Dictionary = {}
	for idx: int in _tile_blobs[coord]:
		to_remove[idx] = true
	_tile_blobs.erase(coord)
	var new_instances: Array = []
	var old_to_new: Dictionary = {}
	for i in _instances.size():
		if not to_remove.has(i):
			old_to_new[i] = new_instances.size()
			new_instances.append(_instances[i])
	_instances = new_instances
	for tile_coord: Vector2i in _tile_blobs:
		var tile_indices: Array = _tile_blobs[tile_coord]
		for j in tile_indices.size():
			tile_indices[j] = old_to_new[tile_indices[j]]


func get_instance_transforms() -> Array:
	var result: Array = []
	for inst: Dictionary in _instances:
		result.append(inst["transform"])
	return result


func get_instance_custom_data() -> Array:
	var result: Array = []
	for inst: Dictionary in _instances:
		result.append(inst["custom"])
	return result
