extends Node3D

const BASE_HEX_HEIGHT := 0.1

@export var map_width: int = 20
@export var map_height: int = 20
@export var noise_seed: int = 0

var tiles: Dictionary = {}       # Vector2i -> HexTile node
var map_data: MapData = MapData.new()
var fog_cloud_manager: FogCloudManager

var _hex_tile_scene: PackedScene = preload("res://scenes/map/hex_tile.tscn")
var _terrain_plains: TerrainType = preload("res://resources/terrain/plains.tres")
var _terrain_forest: TerrainType = preload("res://resources/terrain/forest.tres")
var _terrain_mountain: TerrainType = preload("res://resources/terrain/mountain.tres")
var _terrain_water: TerrainType = preload("res://resources/terrain/water.tres")
var _terrain_desert: TerrainType = preload("res://resources/terrain/desert.tres")

var _mesh_cache: Dictionary = {}
var _shape_cache: Dictionary = {}
var _terrain_mat_cache: Dictionary = {}
var _outline_mesh: ArrayMesh
var _mountain_mesh: Mesh
var _mountain_mat: StandardMaterial3D
var _water_mat: StandardMaterial3D
var _forest_decorator: ForestDecorator
var _terrain_batches: Dictionary = {}
var _terrain_mmi: Dictionary = {}
var _highlighted_coords: Array[Vector2i] = []
var _batch_dirty: bool = false


func generate_map() -> void:
	_outline_mesh = HexMeshGenerator.create_hex_outline_mesh(0.08)
	_setup_mountain_assets()
	_setup_water_assets()
	_forest_decorator = ForestDecorator.new()
	add_child(_forest_decorator)
	_forest_decorator.load_trees()
	fog_cloud_manager = FogCloudManager.new()
	add_child(fog_cloud_manager)

	var base_seed: int = noise_seed if noise_seed != 0 else randi()
	var noise := FastNoiseLite.new()
	noise.seed = base_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.04
	var detail := FastNoiseLite.new()
	detail.seed = base_seed + 1
	detail.noise_type = FastNoiseLite.TYPE_CELLULAR
	detail.frequency = 0.15

	# Pass 1: assign terrain via noise + create tile nodes
	for q in range(map_width):
		for r in range(map_height):
			@warning_ignore("integer_division")
			var coord := Vector2i(q, r - q / 2)
			var world_pos := HexUtil.axial_to_world(coord.x, coord.y)
			var base_val := noise.get_noise_2d(
				world_pos.x * 3.0, world_pos.z * 3.0
			)
			var cell_val := detail.get_noise_2d(
				world_pos.x * 3.0, world_pos.z * 3.0
			)
			var noise_val := base_val * 0.75 + cell_val * 0.25
			map_data.set_terrain(coord, _pick_terrain(noise_val))
			var tile: Node3D = _hex_tile_scene.instantiate()
			add_child(tile)
			tile.coord = coord
			tile.position = HexUtil.axial_to_world(
				coord.x, coord.y
			)
			tile.position.y = 0.0
			tiles[coord] = tile

	# Place water clumps over existing terrain
	_place_water_clumps()

	# Pass 2: set up visuals from final terrain
	for coord: Vector2i in tiles:
		var tile: Node3D = tiles[coord] as Node3D
		var terrain: TerrainType = map_data.get_terrain(coord)
		var mesh: Mesh
		var mat: StandardMaterial3D
		if terrain == _terrain_mountain and _mountain_mesh:
			mesh = _mountain_mesh
			mat = _mountain_mat
		elif terrain == _terrain_water and _water_mat:
			mesh = _get_cached_mesh(BASE_HEX_HEIGHT)
			mat = _water_mat
		else:
			mesh = _get_cached_mesh(BASE_HEX_HEIGHT)
			mat = _get_cached_terrain_mat(terrain)
		var shape := _get_cached_shape(BASE_HEX_HEIGHT)
		tile.setup(coord, terrain, mesh, shape, mat)
		tile.get_node("MeshInstance3D").visible = false
		var highlight_mesh: MeshInstance3D = (
			tile.get_node("HighlightMesh")
		)
		highlight_mesh.mesh = _outline_mesh
		highlight_mesh.visibility_range_end = 40.0
		var fog_mesh: MeshInstance3D = (
			tile.get_node("FogOverlay")
		)
		fog_mesh.mesh = _get_cached_mesh(0.02)
		fog_mesh.visibility_range_end = 50.0
		fog_cloud_manager.add_fog(
			coord, tile.position, terrain.height,
		)
	fog_cloud_manager.rebuild()


func reveal_tile(coord: Vector2i) -> void:
	var tile: Node3D = tiles.get(coord, null) as Node3D
	if tile == null:
		return
	var prev: MapData.Visibility = map_data.get_visibility(coord)
	map_data.set_visibility(coord, MapData.Visibility.VISIBLE)
	tile.apply_visibility(MapData.Visibility.VISIBLE)
	fog_cloud_manager.remove_fog(coord)
	if prev == MapData.Visibility.UNEXPLORED:
		_add_tile_to_batch(tile)
		if tile.terrain == _terrain_forest:
			_forest_decorator.collect_tile(tile)
			_forest_decorator.build_multimeshes()
		if not _batch_dirty:
			_batch_dirty = true
			_rebuild_terrain_deferred.call_deferred()


func _add_tile_to_batch(tile: Node3D) -> void:
	var terrain: TerrainType = tile.terrain
	var batch_key: String = terrain.resource_path
	if not _terrain_batches.has(batch_key):
		var mesh: Mesh
		var mat: StandardMaterial3D
		if terrain == _terrain_mountain and _mountain_mesh:
			mesh = _mountain_mesh
			mat = _mountain_mat
		elif terrain == _terrain_water and _water_mat:
			mesh = _get_cached_mesh(BASE_HEX_HEIGHT)
			mat = _water_mat
		else:
			mesh = _get_cached_mesh(BASE_HEX_HEIGHT)
			mat = _get_cached_terrain_mat(terrain)
		_terrain_batches[batch_key] = {
			"mesh": mesh, "mat": mat, "xforms": [],
		}
	_terrain_batches[batch_key]["xforms"].append(
		Transform3D(Basis.IDENTITY, tile.position)
	)


func _rebuild_terrain_deferred() -> void:
	_batch_dirty = false
	for child in get_children():
		if child is MultiMeshInstance3D and child.name.begins_with("TerrainBatch"):
			child.queue_free()
	_build_terrain_multimeshes()


func fog_tile(coord: Vector2i) -> void:
	var tile: Node3D = tiles.get(coord, null) as Node3D
	if tile == null:
		return
	var prev: MapData.Visibility = map_data.get_visibility(coord)
	if prev == MapData.Visibility.UNEXPLORED:
		return
	map_data.set_visibility(coord, MapData.Visibility.FOGGED)
	tile.apply_visibility(MapData.Visibility.FOGGED)
	fog_cloud_manager.add_fog(
		coord, tile.position, tile.terrain.height,
	)
	fog_cloud_manager.rebuild()


func get_tile(coord: Vector2i) -> Node3D:
	return tiles.get(coord, null) as Node3D


func get_terrain(coord: Vector2i) -> TerrainType:
	return map_data.get_terrain(coord)


func get_walkable_neighbors(coord: Vector2i) -> Array[Vector2i]:
	return map_data.get_walkable_neighbors(coord)


func highlight_tiles(
	coords: Array[Vector2i],
	color: Color = Color(0.3, 0.8, 0.3, 0.5),
) -> void:
	for coord in coords:
		var tile: Node3D = get_tile(coord)
		if tile:
			tile.set_highlighted(true, color)
			if coord not in _highlighted_coords:
				_highlighted_coords.append(coord)


func clear_highlights() -> void:
	for coord in _highlighted_coords:
		var tile: Node3D = get_tile(coord)
		if tile:
			tile.set_highlighted(false)
	_highlighted_coords.clear()


func raycast_to_hex(camera: Camera3D, mouse_pos: Vector2) -> Vector2i:
	var from := camera.project_ray_origin(mouse_pos)
	var to := from + camera.project_ray_normal(mouse_pos) * 100.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var space := get_world_3d().direct_space_state
	var result: Dictionary = space.intersect_ray(query)
	if result.is_empty():
		return Vector2i(-999, -999)
	var collider: Object = result["collider"]
	var tile: Node3D = collider.get_parent() as Node3D
	if tile and tile.has_method("setup"):
		return tile.coord
	return Vector2i(-999, -999)


func _pick_terrain(noise_val: float) -> TerrainType:
	if noise_val < -0.15:
		return _terrain_desert
	if noise_val < 0.15:
		return _terrain_plains
	if noise_val < 0.32:
		return _terrain_forest
	return _terrain_mountain


func _place_water_clumps() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(noise_seed) + 42
	var all_coords: Array[Vector2i] = []
	for coord: Vector2i in tiles:
		all_coords.append(coord)
	var water_budget: int = int(all_coords.size() * 0.15)
	var placed := 0
	var water_set: Dictionary = {}
	while placed < water_budget:
		var seed_coord: Vector2i = all_coords[
			rng.randi_range(0, all_coords.size() - 1)
		]
		if water_set.has(seed_coord):
			continue
		var clump_size: int
		if rng.randf() < 0.3:
			clump_size = rng.randi_range(1, 3)
		else:
			clump_size = rng.randi_range(25, 40)
		var clump: Array[Vector2i] = _grow_clump(
			seed_coord, clump_size, water_set, rng
		)
		for c in clump:
			water_set[c] = true
			map_data.set_terrain(c, _terrain_water)
		placed += clump.size()


func _grow_clump(
	seed_coord: Vector2i, target_size: int,
	existing: Dictionary,
	rng: RandomNumberGenerator,
) -> Array[Vector2i]:
	var result: Array[Vector2i] = [seed_coord]
	var frontier: Array[Vector2i] = [seed_coord]
	while result.size() < target_size and not frontier.is_empty():
		var idx: int = rng.randi_range(0, frontier.size() - 1)
		var current: Vector2i = frontier[idx]
		frontier.remove_at(idx)
		var neighbors := HexUtil.get_neighbors(current)
		neighbors.shuffle()
		for n in neighbors:
			if result.size() >= target_size:
				break
			if existing.has(n) or n in result:
				continue
			if not tiles.has(n):
				continue
			result.append(n)
			frontier.append(n)
	return result


func _build_terrain_multimeshes() -> void:
	for key: String in _terrain_batches:
		var batch: Dictionary = _terrain_batches[key]
		var xforms: Array = batch["xforms"]
		if xforms.is_empty():
			continue
		var mesh: Mesh = batch["mesh"] as Mesh
		var mat: StandardMaterial3D = (
			batch["mat"] as StandardMaterial3D
		)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = xforms.size()
		for i in xforms.size():
			mm.set_instance_transform(
				i, xforms[i] as Transform3D
			)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "TerrainBatch_" + key.get_file()
		mmi.multimesh = mm
		mmi.material_override = mat
		add_child(mmi)


func _setup_mountain_assets() -> void:
	var mesh_res: Mesh = load(
		"res://assets/models/mountain/mountain_hex.res"
	) as Mesh
	if mesh_res == null:
		return
	_mountain_mesh = mesh_res
	_mountain_mat = StandardMaterial3D.new()
	var diffuse: Texture2D = load(
		"res://assets/models/mountain/SnowyMountainTexture.png"
	) as Texture2D
	var normal: Texture2D = load(
		"res://assets/models/mountain/mountain_normal.png"
	) as Texture2D
	if diffuse:
		_mountain_mat.albedo_texture = diffuse
	_mountain_mat.albedo_color = Color(0.85, 0.85, 0.9)
	_mountain_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if normal:
		_mountain_mat.normal_enabled = true
		_mountain_mat.normal_texture = normal
	_mountain_mat.roughness = 0.8


func _setup_water_assets() -> void:
	_water_mat = StandardMaterial3D.new()
	_water_mat.albedo_color = Color(0.2, 0.45, 0.72)
	if _terrain_water.texture:
		_water_mat.albedo_texture = _terrain_water.texture
	var water_normal: Texture2D = load(
		"res://assets/models/water/water_normal.jpg"
	) as Texture2D
	if water_normal:
		_water_mat.normal_enabled = true
		_water_mat.normal_texture = water_normal
		_water_mat.normal_scale = 0.5
	_water_mat.roughness = 0.1
	_water_mat.metallic = 0.2
	_water_mat.metallic_specular = 0.8


func _get_cached_terrain_mat(
	terrain: TerrainType,
) -> StandardMaterial3D:
	var key: String = terrain.resource_path
	if not _terrain_mat_cache.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = terrain.color
		if terrain.texture:
			mat.albedo_texture = terrain.texture
		_terrain_mat_cache[key] = mat
	return _terrain_mat_cache[key] as StandardMaterial3D


func _get_cached_mesh(height: float) -> ArrayMesh:
	if not _mesh_cache.has(height):
		_mesh_cache[height] = HexMeshGenerator.create_hex_mesh(height)
	return _mesh_cache[height] as ArrayMesh


func _get_cached_shape(height: float) -> ConvexPolygonShape3D:
	if not _shape_cache.has(height):
		_shape_cache[height] = HexMeshGenerator.create_hex_collision_shape(height)
	return _shape_cache[height] as ConvexPolygonShape3D
