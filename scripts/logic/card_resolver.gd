class_name CardResolver
extends RefCounted

var _map: MapData


class CardResult extends RefCounted:
	var success: bool = false
	var new_coord: Vector2i = Vector2i.ZERO
	var revealed_tiles: Array[Vector2i] = []
	var materials_gained: int = 0
	var food_gained: int = 0
	var settled_coord: Vector2i = Vector2i(-999, -999)
	var settlement_name: String = ""


func _init(map: MapData) -> void:
	_map = map


func get_map_data() -> MapData:
	return _map


func get_valid_targets(card: CardData, origin: Vector2i) -> Array[Vector2i]:
	match card.card_type:
		CardData.CardType.MOVE:
			return _get_move_targets(origin, card.range_value)
		CardData.CardType.SCOUT:
			return _get_scout_targets(origin, card.range_value)
		CardData.CardType.GATHER:
			return _map.get_walkable_neighbors(origin)
		CardData.CardType.SETTLE:
			return _get_settle_targets(origin)
	return []


func resolve_card(card: CardData, target: Vector2i, origin: Vector2i) -> CardResult:
	match card.card_type:
		CardData.CardType.MOVE:
			return _resolve_move(card, target, origin)
		CardData.CardType.SCOUT:
			return _resolve_scout(card, target)
		CardData.CardType.GATHER:
			return _resolve_gather(target)
		CardData.CardType.SETTLE:
			return _resolve_settle(target)
	return CardResult.new()


func _get_move_targets(origin: Vector2i, max_range: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var hexes := HexUtil.get_hexes_in_range(origin, max_range)
	for coord in hexes:
		if coord == origin:
			continue
		var terrain: TerrainType = _map.get_terrain(coord)
		if terrain != null and terrain.is_passable:
			result.append(coord)
	return result


func _get_scout_targets(origin: Vector2i, range_value: int) -> Array[Vector2i]:
	var valid: Array[Vector2i] = []
	var hexes := HexUtil.get_hexes_in_range(origin, range_value)
	for c in hexes:
		if _map.has_tile(c):
			valid.append(c)
	return valid


func _resolve_move(card: CardData, target: Vector2i, origin: Vector2i) -> CardResult:
	var result := CardResult.new()
	var distance := HexUtil.axial_distance(origin, target)
	if distance > card.range_value or distance == 0:
		return result
	var terrain: TerrainType = _map.get_terrain(target)
	if terrain == null or not terrain.is_passable:
		return result
	result.success = true
	result.new_coord = target
	return result


func _resolve_scout(card: CardData, target: Vector2i) -> CardResult:
	var result := CardResult.new()
	result.success = true
	var hexes := HexUtil.get_hexes_in_range(target, card.range_value)
	for coord in hexes:
		if _map.has_tile(coord):
			result.revealed_tiles.append(coord)
	return result


func _get_settle_targets(origin: Vector2i) -> Array[Vector2i]:
	if _map.has_settlement(origin):
		return [] as Array[Vector2i]
	var terrain: TerrainType = _map.get_terrain(origin)
	if terrain == null or not terrain.is_passable:
		return [] as Array[Vector2i]
	return [origin] as Array[Vector2i]


func _resolve_settle(target: Vector2i) -> CardResult:
	var result := CardResult.new()
	if _map.has_settlement(target):
		return result
	var terrain: TerrainType = _map.get_terrain(target)
	if terrain == null or not terrain.is_passable:
		return result
	var sname := SettlementNames.get_random_name()
	_map.place_settlement(target, sname)
	result.success = true
	result.settled_coord = target
	result.settlement_name = sname
	return result


func _resolve_gather(target: Vector2i) -> CardResult:
	var result := CardResult.new()
	var terrain: TerrainType = _map.get_terrain(target)
	if terrain == null:
		return result
	result.success = true
	result.materials_gained = terrain.materials_yield
	result.food_gained = terrain.food_yield
	return result
