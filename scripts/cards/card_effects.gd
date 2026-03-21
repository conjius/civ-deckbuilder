extends Node

signal effect_completed
signal gathered(materials: int, food: int)
signal settled(coord: Vector2i, settlement_name: String)
signal turn_should_end

var hex_map: Node3D
var player_unit: Node3D
var card_resolver: CardResolver


func execute_card(card: CardData, target_coord: Vector2i) -> bool:
	var origin: Vector2i = player_unit.current_coord
	var result := card_resolver.resolve_card(card, target_coord, origin)
	if not result.success:
		return false

	match card.card_type:
		CardData.CardType.MOVE:
			var path := card_resolver.get_map_data().find_path(origin, result.new_coord)
			if path.size() <= 1:
				var terrain: TerrainType = hex_map.get_terrain(target_coord)
				player_unit.move_to(result.new_coord, terrain.height - 0.1)
			else:
				var heights: Array[float] = []
				for coord in path:
					var terrain: TerrainType = hex_map.get_terrain(coord)
					heights.append(terrain.height - 0.1)
				player_unit.move_along_path(path, heights)
		CardData.CardType.SCOUT:
			for coord in result.revealed_tiles:
				var tile: Node3D = hex_map.get_tile(coord)
				if tile:
					tile.set_fog(false)
		CardData.CardType.GATHER:
			gathered.emit(result.materials_gained, result.food_gained)
		CardData.CardType.SETTLE:
			settled.emit(
				result.settled_coord, result.settlement_name
			)

	effect_completed.emit()
	if result.ends_turn:
		turn_should_end.emit()
	return true


func get_valid_targets(card: CardData, unit_coord: Vector2i) -> Array[Vector2i]:
	return card_resolver.get_valid_targets(card, unit_coord)
