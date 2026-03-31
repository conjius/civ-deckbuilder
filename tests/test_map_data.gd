extends RefCounted

var _plains: TerrainType
var _forest: TerrainType
var _mountain: TerrainType
var _water: TerrainType


func before() -> void:
	_plains = TerrainType.new()
	_plains.terrain_name = "Plains"
	_plains.is_passable = true
	_plains.height = 0.1
	_plains.materials_yield = 1
	_plains.food_yield = 0

	_forest = TerrainType.new()
	_forest.terrain_name = "Forest"
	_forest.is_passable = true
	_forest.height = 0.15
	_forest.materials_yield = 2
	_forest.food_yield = 1

	_mountain = TerrainType.new()
	_mountain.terrain_name = "Mountain"
	_mountain.is_passable = false
	_mountain.height = 0.5
	_mountain.materials_yield = 0
	_mountain.food_yield = 0

	_water = TerrainType.new()
	_water.terrain_name = "Water"
	_water.is_passable = false
	_water.height = 0.05
	_water.materials_yield = 0
	_water.food_yield = 2


func test_set_and_get_terrain() -> void:
	var map := MapData.new()
	var coord := Vector2i(3, 2)
	map.set_terrain(coord, _plains)
	TestAssert.assert_eq(map.get_terrain(coord), _plains)


func test_get_terrain_missing_returns_null() -> void:
	var map := MapData.new()
	TestAssert.assert_null(map.get_terrain(Vector2i(99, 99)))


func test_has_tile() -> void:
	var map := MapData.new()
	var coord := Vector2i(1, 1)
	TestAssert.assert_false(map.has_tile(coord))
	map.set_terrain(coord, _plains)
	TestAssert.assert_true(map.has_tile(coord))


func test_get_walkable_neighbors_filters_impassable() -> void:
	var map := MapData.new()
	var center := Vector2i(2, 2)
	map.set_terrain(center, _plains)

	var east := Vector2i(3, 2)
	var west := Vector2i(1, 2)
	var ne := Vector2i(3, 1)
	map.set_terrain(east, _plains)
	map.set_terrain(west, _mountain)
	map.set_terrain(ne, _forest)

	var walkable := map.get_walkable_neighbors(center)
	TestAssert.assert_contains(walkable, east)
	TestAssert.assert_contains(walkable, ne)
	TestAssert.assert_not_contains(walkable, west)


func test_get_walkable_neighbors_edge_of_map() -> void:
	var map := MapData.new()
	var corner := Vector2i(0, 0)
	map.set_terrain(corner, _plains)
	var neighbor := Vector2i(1, 0)
	map.set_terrain(neighbor, _plains)

	var walkable := map.get_walkable_neighbors(corner)
	TestAssert.assert_size(walkable, 1)
	TestAssert.assert_contains(walkable, neighbor)


func test_find_path_adjacent() -> void:
	var map := MapData.new()
	map.set_terrain(Vector2i(0, 0), _plains)
	map.set_terrain(Vector2i(1, 0), _plains)
	var path := map.find_path(Vector2i(0, 0), Vector2i(1, 0))
	TestAssert.assert_size(path, 2)
	TestAssert.assert_eq(path[0], Vector2i(0, 0))
	TestAssert.assert_eq(path[1], Vector2i(1, 0))


func test_find_path_two_steps() -> void:
	var map := MapData.new()
	map.set_terrain(Vector2i(0, 0), _plains)
	map.set_terrain(Vector2i(1, 0), _plains)
	map.set_terrain(Vector2i(2, 0), _plains)
	var path := map.find_path(Vector2i(0, 0), Vector2i(2, 0))
	TestAssert.assert_size(path, 3)
	TestAssert.assert_eq(path[0], Vector2i(0, 0))
	TestAssert.assert_eq(path[2], Vector2i(2, 0))


func test_find_path_around_obstacle() -> void:
	var map := MapData.new()
	map.set_terrain(Vector2i(0, 0), _plains)
	map.set_terrain(Vector2i(1, 0), _mountain)
	map.set_terrain(Vector2i(2, 0), _plains)
	map.set_terrain(Vector2i(0, 1), _plains)
	map.set_terrain(Vector2i(1, 1), _plains)
	var path := map.find_path(Vector2i(0, 0), Vector2i(2, 0))
	TestAssert.assert_gt(path.size(), 0)
	TestAssert.assert_eq(path[0], Vector2i(0, 0))
	TestAssert.assert_eq(path[path.size() - 1], Vector2i(2, 0))
	TestAssert.assert_not_contains(path, Vector2i(1, 0))


func test_find_path_no_route_returns_empty() -> void:
	var map := MapData.new()
	map.set_terrain(Vector2i(0, 0), _plains)
	map.set_terrain(Vector2i(2, 0), _plains)
	var path := map.find_path(Vector2i(0, 0), Vector2i(2, 0))
	TestAssert.assert_size(path, 0)


func test_find_path_same_tile() -> void:
	var map := MapData.new()
	map.set_terrain(Vector2i(0, 0), _plains)
	var path := map.find_path(Vector2i(0, 0), Vector2i(0, 0))
	TestAssert.assert_size(path, 1)
	TestAssert.assert_eq(path[0], Vector2i(0, 0))


func test_settlement_default_stats() -> void:
	var map := MapData.new()
	map.place_settlement(Vector2i(0, 0), "Camp")
	TestAssert.assert_eq(map.get_settlement_hp(Vector2i(0, 0)), 5)
	TestAssert.assert_eq(map.get_settlement_max_hp(Vector2i(0, 0)), 5)
	TestAssert.assert_eq(map.get_settlement_attack(Vector2i(0, 0)), 0)
	TestAssert.assert_eq(map.get_settlement_defense(Vector2i(0, 0)), 0)


func test_settlement_damage() -> void:
	var map := MapData.new()
	map.place_settlement(Vector2i(0, 0), "Camp")
	map.damage_settlement(Vector2i(0, 0), 3)
	TestAssert.assert_eq(map.get_settlement_hp(Vector2i(0, 0)), 2)


func test_settlement_damage_cannot_go_below_zero() -> void:
	var map := MapData.new()
	map.place_settlement(Vector2i(0, 0), "Camp")
	map.damage_settlement(Vector2i(0, 0), 100)
	TestAssert.assert_eq(map.get_settlement_hp(Vector2i(0, 0)), 0)


func test_settlement_removal() -> void:
	var map := MapData.new()
	map.place_settlement(Vector2i(0, 0), "Camp")
	TestAssert.assert_true(map.has_settlement(Vector2i(0, 0)))
	map.remove_settlement(Vector2i(0, 0))
	TestAssert.assert_false(map.has_settlement(Vector2i(0, 0)))
