extends RefCounted

var _map: MapData
var _plains: TerrainType


func before_each() -> void:
	_map = MapData.new()
	_plains = TerrainType.new()
	_plains.terrain_name = "Plains"
	_plains.is_passable = true
	_map.set_terrain(Vector2i(0, 0), _plains)
	_map.set_terrain(Vector2i(1, 0), _plains)
	_map.set_terrain(Vector2i(2, 0), _plains)


func test_tiles_start_unexplored() -> void:
	TestAssert.assert_eq(
		_map.get_visibility(Vector2i(0, 0)),
		MapData.Visibility.UNEXPLORED,
	)


func test_reveal_sets_visible() -> void:
	_map.set_visibility(
		Vector2i(0, 0), MapData.Visibility.VISIBLE,
	)
	TestAssert.assert_eq(
		_map.get_visibility(Vector2i(0, 0)),
		MapData.Visibility.VISIBLE,
	)


func test_fogged_state() -> void:
	_map.set_visibility(
		Vector2i(0, 0), MapData.Visibility.FOGGED,
	)
	TestAssert.assert_eq(
		_map.get_visibility(Vector2i(0, 0)),
		MapData.Visibility.FOGGED,
	)


func test_unknown_tile_returns_unexplored() -> void:
	TestAssert.assert_eq(
		_map.get_visibility(Vector2i(99, 99)),
		MapData.Visibility.UNEXPLORED,
	)


func test_reveal_tiles_sets_visible() -> void:
	var coords: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0),
	]
	_map.reveal_tiles(coords)
	TestAssert.assert_eq(
		_map.get_visibility(Vector2i(0, 0)),
		MapData.Visibility.VISIBLE,
	)
	TestAssert.assert_eq(
		_map.get_visibility(Vector2i(1, 0)),
		MapData.Visibility.VISIBLE,
	)


func test_degrade_visible_to_fogged() -> void:
	_map.set_visibility(
		Vector2i(0, 0), MapData.Visibility.VISIBLE,
	)
	_map.set_visibility(
		Vector2i(1, 0), MapData.Visibility.VISIBLE,
	)
	var still_visible: Array[Vector2i] = [Vector2i(0, 0)]
	_map.degrade_fog(still_visible)
	TestAssert.assert_eq(
		_map.get_visibility(Vector2i(0, 0)),
		MapData.Visibility.VISIBLE,
	)
	TestAssert.assert_eq(
		_map.get_visibility(Vector2i(1, 0)),
		MapData.Visibility.FOGGED,
	)


func test_degrade_does_not_affect_unexplored() -> void:
	_map.set_visibility(
		Vector2i(0, 0), MapData.Visibility.VISIBLE,
	)
	var still_visible: Array[Vector2i] = [Vector2i(0, 0)]
	_map.degrade_fog(still_visible)
	TestAssert.assert_eq(
		_map.get_visibility(Vector2i(1, 0)),
		MapData.Visibility.UNEXPLORED,
	)


func test_fogged_stays_fogged_on_degrade() -> void:
	_map.set_visibility(
		Vector2i(0, 0), MapData.Visibility.FOGGED,
	)
	var still_visible: Array[Vector2i] = []
	_map.degrade_fog(still_visible)
	TestAssert.assert_eq(
		_map.get_visibility(Vector2i(0, 0)),
		MapData.Visibility.FOGGED,
	)
