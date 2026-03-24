extends Node3D

const BASE_HEX_HEIGHT := 0.1

@export var map_width: int = 40
@export var map_height: int = 40
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


func generate_map() -> void:
	_outline_mesh = HexMeshGenerator.create_hex_outline_mesh(0.08)
	_setup_mountain_assets()
	_setup_water_assets()
	_forest_decorator = ForestDecorator.new()
	_forest_decorator.load_trees()
	fog_cloud_manager = FogCloudManager.new()
	add_child(fog_cloud_manager)

	var noise := FastNoiseLite.new()
	noise.seed = noise_seed if noise_seed != 0 else randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.08

	for q in range(map_width):
		for r in range(map_height):
			@warning_ignore("integer_division")
			var coord := Vector2i(q, r - q / 2)
			var world_pos := HexUtil.axial_to_world(coord.x, coord.y)
			var noise_val := noise.get_noise_2d(world_pos.x * 3.0, world_pos.z * 3.0)

			var terrain := _pick_terrain(noise_val)
			map_data.set_terrain(coord, terrain)

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

			var tile: Node3D = _hex_tile_scene.instantiate()
			add_child(tile)
			tile.setup(coord, terrain, mesh, shape, mat)

			var highlight_mesh: MeshInstance3D = tile.get_node("HighlightMesh")
			highlight_mesh.mesh = _outline_mesh
			var fog_mesh: MeshInstance3D = tile.get_node("FogOverlay")
			fog_mesh.mesh = _get_cached_mesh(0.02)

			tiles[coord] = tile
			if terrain == _terrain_forest:
				_forest_decorator.decorate_tile(tile)
			fog_cloud_manager.add_fog(
				coord, tile.position, terrain.height,
			)
	fog_cloud_manager.rebuild()


func reveal_tile(coord: Vector2i) -> void:
	var tile: Node3D = tiles.get(coord, null) as Node3D
	if tile:
		tile.set_fog(false)
		fog_cloud_manager.remove_fog(coord)


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


func clear_highlights() -> void:
	for tile: Node3D in tiles.values():
		tile.set_highlighted(false)


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
	if noise_val < -0.3:
		return _terrain_water
	if noise_val < -0.05:
		return _terrain_desert
	if noise_val < 0.15:
		return _terrain_plains
	if noise_val < 0.4:
		return _terrain_forest
	return _terrain_mountain


func _setup_mountain_assets() -> void:
	var mesh_res: Mesh = load(
		"res://assets/models/mountain/mountain_hex.obj"
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
