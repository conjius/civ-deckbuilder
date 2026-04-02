class_name ForestDecorator
extends Node3D

const TREE_NAMES := [
	"PineTree_V1", "Pinetree_V2", "PineTree_V3",
	"Tree", "Tree1", "Tree2", "Tree4",
]
const MIN_TREES := 5
const MAX_TREES := 10
const MIN_SPACING := 0.15
const CHUNK_SIZE := 8
const TARGET_HEIGHT := 0.6
const TREE_HEIGHT_JITTER := 0.2

var _tree_meshes: Array[Mesh] = []
var _tree_scales: Array[float] = []
var _tree_radii: Array[float] = []
var _pending: Array[Array] = []


func load_trees() -> void:
	for tree_name in TREE_NAMES:
		var node := AssetPack.get_model(tree_name, 1.0)
		var mi: MeshInstance3D = null
		for child in node.get_children():
			if child is MeshInstance3D:
				mi = child as MeshInstance3D
				break
		if mi == null or mi.mesh == null:
			continue
		var aabb: AABB = mi.mesh.get_aabb()
		var center: Vector3 = aabb.get_center()
		var recentered: ArrayMesh = _recenter_mesh(
			mi.mesh, center
		)
		for s in recentered.get_surface_count():
			var orig: Material = mi.mesh.surface_get_material(s)
			if orig is StandardMaterial3D:
				var mat: StandardMaterial3D = (
					orig.duplicate() as StandardMaterial3D
				)
				var c := mat.albedo_color
				if c.g > c.r and c.g > c.b:
					mat.albedo_color = Color(
						c.r * 0.7, c.g * 1.2, c.b * 0.6
					).lightened(0.3)
				else:
					mat.albedo_color = c.lightened(0.4)
				recentered.surface_set_material(s, mat)
			elif orig:
				recentered.surface_set_material(s, orig)
		_tree_meshes.append(recentered)
		var mesh_height: float = recentered.get_aabb().size.y
		var scale_val: float
		if mesh_height > 0.0:
			scale_val = TARGET_HEIGHT / mesh_height
		else:
			scale_val = 0.003
		_tree_scales.append(scale_val)
		var new_aabb: AABB = recentered.get_aabb()
		var half_x: float = maxf(
			absf(new_aabb.position.x),
			absf(new_aabb.position.x + new_aabb.size.x),
		) * scale_val
		var half_z: float = maxf(
			absf(new_aabb.position.z),
			absf(new_aabb.position.z + new_aabb.size.z),
		) * scale_val
		_tree_radii.append(maxf(half_x, half_z))
	for _i in _tree_meshes.size():
		_pending.append([])


func collect_tile(tile: Node3D) -> void:
	if _tree_meshes.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(tile.coord)
	var count: int = rng.randi_range(MIN_TREES, MAX_TREES)
	var placements: Array[Array] = _distribute_trees(rng, count)
	var tile_pos: Vector3 = tile.position
	for placement in placements:
		var pos: Vector2 = placement[0] as Vector2
		var tree_idx: int = placement[1] as int
		var base_scale: float = _tree_scales[tree_idx]
		var scale_factor: float = base_scale * rng.randf_range(
			1.0 - TREE_HEIGHT_JITTER,
			1.0 + TREE_HEIGHT_JITTER,
		)
		var rot_y: float = rng.randf() * TAU
		var world_pos := Vector3(
			tile_pos.x + pos.x,
			tile_pos.y + 0.05,
			tile_pos.z + pos.y,
		)
		var basis := Basis(Vector3.UP, rot_y).scaled(
			Vector3(scale_factor, scale_factor, scale_factor)
		)
		var xform := Transform3D(basis, world_pos)
		_pending[tree_idx].append(xform)


func build_multimeshes() -> void:
	for i in _tree_meshes.size():
		var transforms: Array = _pending[i]
		if transforms.is_empty():
			continue
		var chunks: Dictionary = {}
		for xform: Transform3D in transforms:
			@warning_ignore("integer_division")
			var cx: int = int(floor(
				xform.origin.x / (CHUNK_SIZE * 1.5)
			))
			@warning_ignore("integer_division")
			var cz: int = int(floor(
				xform.origin.z / (CHUNK_SIZE * 1.7)
			))
			var key := Vector2i(cx, cz)
			if not chunks.has(key):
				chunks[key] = []
			chunks[key].append(xform)
		for key: Vector2i in chunks:
			var chunk_xforms: Array = chunks[key]
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = _tree_meshes[i]
			mm.instance_count = chunk_xforms.size()
			for j in chunk_xforms.size():
				mm.set_instance_transform(
					j, chunk_xforms[j] as Transform3D
				)
			var mmi := MultiMeshInstance3D.new()
			mmi.multimesh = mm
			mmi.cast_shadow = (
				GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			)
			mmi.visibility_range_end = 35.0
			mmi.visibility_range_fade_mode = (
				GeometryInstance3D
				.VISIBILITY_RANGE_FADE_SELF
			)
			add_child(mmi)
	_pending.clear()
	for _i in _tree_meshes.size():
		_pending.append([])


func _recenter_mesh(
	src: Mesh, center: Vector3,
) -> ArrayMesh:
	var result := ArrayMesh.new()
	# Z is up in pack, swap to Y-up; ground at bottom of AABB
	var aabb := src.get_aabb()
	var ground_z: float = aabb.position.z
	var offset := Vector3(center.x, center.y, ground_z)
	for s in src.get_surface_count():
		var arrays: Array = src.surface_get_arrays(s)
		if arrays.size() == 0:
			continue
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var new_verts := PackedVector3Array()
		new_verts.resize(verts.size())
		for i in verts.size():
			var v := verts[i] - offset
			new_verts[i] = Vector3(v.x, v.z, v.y)
		arrays[Mesh.ARRAY_VERTEX] = new_verts
		if arrays[Mesh.ARRAY_NORMAL]:
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var new_normals := PackedVector3Array()
			new_normals.resize(normals.size())
			for i in normals.size():
				new_normals[i] = Vector3(
					normals[i].x, normals[i].z, normals[i].y
				)
			arrays[Mesh.ARRAY_NORMAL] = new_normals
		var fmt: int = src.surface_get_format(s)
		result.add_surface_from_arrays(
			Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, fmt
		)
	return result


func _distribute_trees(
	rng: RandomNumberGenerator, count: int,
) -> Array[Array]:
	var result: Array[Array] = []
	var placed_pos: Array[Vector2] = []
	var max_attempts := 50
	for _i in count:
		var tree_idx: int = rng.randi_range(
			0, _tree_meshes.size() - 1
		)
		var r: float = _tree_radii[tree_idx]
		var hex_limit: float = maxf(0.1, 0.85 - r)
		for _attempt in max_attempts:
			var angle: float = rng.randf() * TAU
			var dist: float = rng.randf_range(0.0, hex_limit)
			var x: float = cos(angle) * dist
			var y: float = sin(angle) * dist
			if not _in_hex(x, y, hex_limit):
				continue
			var too_close := false
			for existing in placed_pos:
				if Vector2(x, y).distance_to(existing) < MIN_SPACING:
					too_close = true
					break
			if not too_close:
				placed_pos.append(Vector2(x, y))
				result.append([Vector2(x, y), tree_idx])
				break
	return result


static func _in_hex(x: float, y: float, radius: float) -> bool:
	var ax: float = absf(x)
	var ay: float = absf(y)
	return (
		ay <= radius * sqrt(3.0) / 2.0
		and ax * sqrt(3.0) + ay <= radius * sqrt(3.0)
	)
