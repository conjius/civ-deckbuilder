class_name MapData
extends RefCounted

var _terrain: Dictionary = {}
var _settlements: Dictionary = {}
var _enemies: Dictionary = {}


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


func place_settlement(coord: Vector2i, sname: String) -> void:
	_settlements[coord] = sname


func set_enemy_position(coord: Vector2i, present: bool) -> void:
	if present:
		_enemies[coord] = true
	else:
		_enemies.erase(coord)


func has_enemy(coord: Vector2i) -> bool:
	return _enemies.has(coord)


func get_settlement_name(coord: Vector2i) -> String:
	return _settlements.get(coord, "") as String


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
