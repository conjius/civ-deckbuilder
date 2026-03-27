extends Node

signal effect_completed
signal gathered(cards: Array[CardData])
signal settled(coord: Vector2i, settlement_name: String)
signal attacked(target: Vector2i, damage: int)
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
	var result := card_resolver.resolve_card(
		card, target_coord, origin
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
			gathered.emit(result.gained_cards)
		CardData.CardType.SETTLE:
			settled.emit(
				result.settled_coord,
				result.settlement_name,
			)
		CardData.CardType.ATTACK:
			attacked.emit(target_coord, result.damage_dealt)
		CardData.CardType.DEFENSE:
			unit.state.defense_modifier += result.defense_gained
			defended.emit(result.defense_gained)

	effect_completed.emit()
	return result


func get_valid_targets(card: CardData, unit_coord: Vector2i) -> Array[Vector2i]:
	return card_resolver.get_valid_targets(card, unit_coord)
