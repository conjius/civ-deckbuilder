class_name CardResolver
extends RefCounted

var _map: MapData

var _food_cards: Array[CardData] = []
var _material_cards: Array[CardData] = []


class CardResult extends RefCounted:
	var success: bool = false
	var new_coord: Vector2i = Vector2i.ZERO
	var revealed_tiles: Array[Vector2i] = []
	var gained_cards: Array[CardData] = []
	var settled_coord: Vector2i = Vector2i(-999, -999)
	var settlement_name: String = ""
	var ends_turn: bool = false
	var damage_dealt: int = 0
	var defense_gained: int = 0


func _init(map: MapData) -> void:
	_map = map
	_load_resource_pools()


func _load_resource_pools() -> void:
	var food_paths := [
		"res://resources/cards/chicken.tres",
		"res://resources/cards/beef.tres",
		"res://resources/cards/pork.tres",
	]
	var mat_paths := [
		"res://resources/cards/ore.tres",
		"res://resources/cards/iron.tres",
		"res://resources/cards/copper.tres",
		"res://resources/cards/wood.tres",
		"res://resources/cards/glass.tres",
	]
	for p: String in food_paths:
		var card: CardData = load(p) as CardData
		if card:
			_food_cards.append(card)
	for p: String in mat_paths:
		var card: CardData = load(p) as CardData
		if card:
			_material_cards.append(card)


func pick_resource_card(
	res_type: CardData.ResourceType,
) -> CardData:
	var pool: Array[CardData]
	if res_type == CardData.ResourceType.FOOD:
		pool = _food_cards
	else:
		pool = _material_cards
	if pool.is_empty():
		var fallback := CardData.new()
		fallback.card_type = CardData.CardType.RESOURCE
		fallback.resource_type = res_type
		fallback.resource_value = 1
		if res_type == CardData.ResourceType.FOOD:
			fallback.card_name = "Food"
		else:
			fallback.card_name = "Materials"
		return fallback
	return pool[randi() % pool.size()].duplicate()


func get_map_data() -> MapData:
	return _map


func get_valid_targets(
	card: CardData, origin: Vector2i,
	attacker_color: Color = Color(-1, -1, -1),
) -> Array[Vector2i]:
	match card.card_type:
		CardData.CardType.MOVE:
			return _get_move_targets(origin, card.range_value)
		CardData.CardType.SCOUT:
			return _get_scout_targets(origin, card.range_value)
		CardData.CardType.GATHER:
			return _get_gather_targets(origin)
		CardData.CardType.SETTLE:
			return _get_settle_targets(origin)
		CardData.CardType.ATTACK:
			return _get_attack_targets(
				origin, card.range_value, attacker_color
			)
		CardData.CardType.DEFENSE:
			return [origin] as Array[Vector2i]
	return []


func resolve_card(
	card: CardData, target: Vector2i, origin: Vector2i,
	attacker_color: Color = Color(-1, -1, -1),
) -> CardResult:
	match card.card_type:
		CardData.CardType.MOVE:
			return _resolve_move(card, target, origin)
		CardData.CardType.SCOUT:
			return _resolve_scout(card, target)
		CardData.CardType.GATHER:
			return _resolve_gather(target)
		CardData.CardType.SETTLE:
			return _resolve_settle(target)
		CardData.CardType.ATTACK:
			return _resolve_attack(
				card, target, origin, attacker_color
			)
		CardData.CardType.DEFENSE:
			return _resolve_defense(card)
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
		if c == origin:
			continue
		if HexUtil.axial_distance(origin, c) == range_value:
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
	if terrain.stops_movement:
		result.ends_turn = true
	return result


func _resolve_scout(_card: CardData, target: Vector2i) -> CardResult:
	var result := CardResult.new()
	result.success = true
	if _map.has_tile(target):
		result.revealed_tiles.append(target)
	return result


func _get_gather_targets(origin: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for neighbor in HexUtil.get_neighbors(origin):
		var terrain: TerrainType = _map.get_terrain(neighbor)
		if terrain == null:
			continue
		if terrain.materials_yield > 0 or terrain.food_yield > 0:
			result.append(neighbor)
	return result


func _get_settle_targets(origin: Vector2i) -> Array[Vector2i]:
	if _map.has_settlement(origin):
		return [] as Array[Vector2i]
	var terrain: TerrainType = _map.get_terrain(origin)
	if terrain == null or not terrain.is_passable:
		return [] as Array[Vector2i]
	if not terrain.is_settleable:
		return [] as Array[Vector2i]
	return [origin] as Array[Vector2i]


func _resolve_settle(target: Vector2i) -> CardResult:
	var result := CardResult.new()
	if _map.has_settlement(target):
		return result
	var terrain: TerrainType = _map.get_terrain(target)
	if terrain == null or not terrain.is_passable:
		return result
	if not terrain.is_settleable:
		return result
	var sname := SettlementNames.get_random_name()
	_map.place_settlement(target, sname, Color.WHITE)
	result.success = true
	result.settled_coord = target
	result.settlement_name = sname
	return result


func _get_attack_targets(
	origin: Vector2i, max_range: int,
	attacker_color: Color = Color(-1, -1, -1),
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var hexes := HexUtil.get_hexes_in_range(origin, max_range)
	for coord in hexes:
		if coord == origin:
			continue
		var is_enemy: bool = _map.has_enemy(coord)
		var is_enemy_settlement: bool = false
		if attacker_color.r >= 0.0:
			is_enemy_settlement = (
				_map.has_enemy_settlement(coord, attacker_color)
			)
		else:
			is_enemy_settlement = _map.has_settlement(coord)
		if is_enemy or is_enemy_settlement:
			result.append(coord)
	return result


func _resolve_attack(
	card: CardData, target: Vector2i, origin: Vector2i,
	attacker_color: Color = Color(-1, -1, -1),
) -> CardResult:
	var result := CardResult.new()
	var distance := HexUtil.axial_distance(origin, target)
	if distance > card.range_value or distance == 0:
		return result
	var has_target: bool = _map.has_enemy(target)
	if not has_target:
		if attacker_color.r >= 0.0:
			has_target = _map.has_enemy_settlement(
				target, attacker_color
			)
		else:
			has_target = _map.has_settlement(target)
	if not has_target:
		return result
	result.success = true
	result.damage_dealt = card.attack_damage
	return result


func _resolve_defense(card: CardData) -> CardResult:
	var result := CardResult.new()
	result.success = true
	result.defense_gained = card.defense_bonus
	return result


func _resolve_gather(target: Vector2i) -> CardResult:
	var result := CardResult.new()
	var terrain: TerrainType = _map.get_terrain(target)
	if terrain == null:
		return result
	result.success = true
	for _i in terrain.materials_yield:
		result.gained_cards.append(
			pick_resource_card(CardData.ResourceType.MATERIALS)
		)
	for _i in terrain.food_yield:
		result.gained_cards.append(
			pick_resource_card(CardData.ResourceType.FOOD)
		)
	return result
