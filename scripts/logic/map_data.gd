class_name MapData
extends RefCounted

enum Visibility { UNEXPLORED, FOGGED, VISIBLE }

var _terrain: Dictionary = {}
var _settlements: Dictionary = {}
var _enemies: Dictionary = {}
var _visibility: Dictionary = {}


func get_visibility(coord: Vector2i) -> Visibility:
	return _visibility.get(coord, Visibility.UNEXPLORED) as Visibility


func set_visibility(coord: Vector2i, state: Visibility) -> void:
	_visibility[coord] = state


func reveal_tiles(coords: Array[Vector2i]) -> void:
	for coord in coords:
		_visibility[coord] = Visibility.VISIBLE


func degrade_fog(still_visible: Array[Vector2i]) -> void:
	var visible_set: Dictionary = {}
	for coord in still_visible:
		visible_set[coord] = true
	for coord: Vector2i in _visibility:
		var state: Visibility = _visibility[coord] as Visibility
		if state == Visibility.VISIBLE and not visible_set.has(coord):
			_visibility[coord] = Visibility.FOGGED


func set_terrain(coord: Vector2i, terrain: TerrainType) -> void:
	_terrain[coord] = terrain


func get_terrain(coord: Vector2i) -> TerrainType:
	return _terrain.get(coord, null) as TerrainType


func has_tile(coord: Vector2i) -> bool:
	return _terrain.has(coord)


func get_walkable_neighbors(coord: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for neighbor in HexUtil.get_neighbors(coord):
		if _terrain.has(neighbor):
			var terrain: TerrainType = _terrain[neighbor] as TerrainType
			if terrain.is_passable:
				result.append(neighbor)
	return result


func has_settlement(coord: Vector2i) -> bool:
	return _settlements.has(coord)


func has_enemy_settlement(
	coord: Vector2i, own_color: Color,
) -> bool:
	if not _settlements.has(coord):
		return false
	var color: Color = get_settlement_color(coord)
	return color != own_color


func place_settlement(
	coord: Vector2i, sname: String,
	owner_color: Color = Color.WHITE,
	hp: int = 5, atk: int = 0, def: int = 0,
) -> void:
	_settlements[coord] = {
		"name": sname, "color": owner_color,
		"hp": hp, "max_hp": hp, "attack": atk, "defense": def,
	}


func set_enemy_position(coord: Vector2i, present: bool) -> void:
	if present:
		_enemies[coord] = true
	else:
		_enemies.erase(coord)


func has_enemy(coord: Vector2i) -> bool:
	return _enemies.has(coord)


func get_settlement_name(coord: Vector2i) -> String:
	var data: Dictionary = (
		_settlements.get(coord, {}) as Dictionary
	)
	return data.get("name", "") as String


func get_settlement_color(coord: Vector2i) -> Color:
	var data: Dictionary = (
		_settlements.get(coord, {}) as Dictionary
	)
	return data.get("color", Color.WHITE) as Color


func get_settlement_hp(coord: Vector2i) -> int:
	var data: Dictionary = (
		_settlements.get(coord, {}) as Dictionary
	)
	return data.get("hp", 0) as int


func get_settlement_max_hp(coord: Vector2i) -> int:
	var data: Dictionary = (
		_settlements.get(coord, {}) as Dictionary
	)
	return data.get("max_hp", 0) as int


func get_settlement_attack(coord: Vector2i) -> int:
	var data: Dictionary = (
		_settlements.get(coord, {}) as Dictionary
	)
	return data.get("attack", 0) as int


func get_settlement_defense(coord: Vector2i) -> int:
	var data: Dictionary = (
		_settlements.get(coord, {}) as Dictionary
	)
	return data.get("defense", 0) as int


func damage_settlement(coord: Vector2i, amount: int) -> void:
	if not _settlements.has(coord):
		return
	var data: Dictionary = _settlements[coord] as Dictionary
	var hp: int = data.get("hp", 0) as int
	data["hp"] = maxi(0, hp - amount)


func remove_settlement(coord: Vector2i) -> void:
	_settlements.erase(coord)


func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if from == to:
		return [from] as Array[Vector2i]
	if not has_tile(from) or not has_tile(to):
		return [] as Array[Vector2i]
	var frontier: Array[Vector2i] = [from]
	var came_from: Dictionary = {}
	came_from[from] = from
	while frontier.size() > 0:
		var current: Vector2i = frontier.pop_front()
		if current == to:
			break
		for neighbor in get_walkable_neighbors(current):
			if not came_from.has(neighbor):
				came_from[neighbor] = current
				frontier.append(neighbor)
	if not came_from.has(to):
		return [] as Array[Vector2i]
	var path: Array[Vector2i] = []
	var current: Vector2i = to
	while current != from:
		path.push_front(current)
		current = came_from[current] as Vector2i
	path.push_front(from)
	return path
