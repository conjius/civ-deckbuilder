extends Node

signal effect_completed
signal gather_choice_needed(
	coord: Vector2i,
	types: Array[CardData.ResourceType],
)
signal settled(coord: Vector2i, settlement_name: String)
signal attacked(target: Vector2i, damage: int, attacker: Node3D)
signal defended(bonus: int)
signal turn_should_end

var hex_map: Node3D
var player_unit: Node3D
var card_resolver: CardResolver


func execute_card(
	card: CardData, target_coord: Vector2i,
	unit: Node3D = null,
) -> CardResolver.CardResult:
	if unit == null:
		unit = player_unit
	var origin: Vector2i = unit.current_coord
	var unit_color: Color = Color(-1, -1, -1)
	if "avatar_color" in unit:
		unit_color = unit.avatar_color
	var result := card_resolver.resolve_card(
		card, target_coord, origin, unit_color
	)
	if not result.success:
		return result

	match card.card_type:
		CardData.CardType.MOVE:
			var map_data := card_resolver.get_map_data()
			var path := map_data.find_path(
				origin, result.new_coord
			)
			if path.size() <= 1:
				var terrain: TerrainType = (
					hex_map.get_terrain(target_coord)
				)
				unit.move_to(
					result.new_coord, 0.0
				)
			else:
				var heights: Array[float] = []
				for coord in path:
					heights.append(0.0)
				unit.move_along_path(path, heights)
		CardData.CardType.SCOUT:
			for coord in result.revealed_tiles:
				hex_map.reveal_tile(coord)
		CardData.CardType.GATHER:
			if unit == player_unit:
				var types: Array[CardData.ResourceType] = []
				var terrain: TerrainType = (
					hex_map.get_terrain(target_coord)
				)
				if terrain:
					if terrain.materials_yield > 0:
						types.append(
							CardData.ResourceType.MATERIALS
						)
					if terrain.food_yield > 0:
						types.append(
							CardData.ResourceType.FOOD
						)
				gather_choice_needed.emit(target_coord, types)
		CardData.CardType.SETTLE:
			settled.emit(
				result.settled_coord,
				result.settlement_name,
			)
		CardData.CardType.ATTACK:
			unit.state.attack_modifier += result.damage_dealt
			var total_atk: int = (
				unit.state.attack
				+ unit.state.attack_modifier
			)
			attacked.emit(target_coord, total_atk, unit)
		CardData.CardType.DEFENSE:
			unit.state.defense_modifier += result.defense_gained
			defended.emit(result.defense_gained)

	effect_completed.emit()
	return result


func get_valid_targets(
	card: CardData, unit_coord: Vector2i,
	unit_color: Color = Color(-1, -1, -1),
) -> Array[Vector2i]:
	return card_resolver.get_valid_targets(
		card, unit_coord, unit_color
	)
