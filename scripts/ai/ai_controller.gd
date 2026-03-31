class_name AIController
extends Node

signal turn_completed

const PLAY_DELAY: float = 0.4

var ai_unit: Node3D
var player_unit: Node3D
var deck_manager: DeckManager = DeckManager.new()
var card_effects: Node
var card_resolver: CardResolver
var hex_map: Node3D


func initialize(deck: Array[CardData]) -> void:
	deck_manager.initialize(deck)
	deck_manager.draw_hand()


func take_turn() -> void:
	_update_enemy_positions()
	ai_unit.state.attack_modifier = 0
	ai_unit.state.defense_modifier = 0
	var cards_to_play: Array[CardData] = deck_manager.hand.duplicate()
	for card in cards_to_play:
		if card.card_type == CardData.CardType.RESOURCE:
			continue
		var targets := card_resolver.get_valid_targets(
			card, ai_unit.current_coord,
			ai_unit.avatar_color,
		)
		if targets.is_empty():
			continue
		var target: Vector2i = targets[randi() % targets.size()]
		var result: CardResolver.CardResult = (
			card_effects.execute_card(card, target, ai_unit)
		)
		if result.success:
			deck_manager.play_card(card)
			_handle_result(card, result, target)
			if card.card_type == CardData.CardType.MOVE:
				if ai_unit.is_moving():
					await ai_unit.movement_finished
			await get_tree().create_timer(PLAY_DELAY).timeout
	deck_manager.end_turn()
	deck_manager.draw_hand()
	_restore_enemy_positions()
	turn_completed.emit()


func _update_enemy_positions() -> void:
	hex_map.map_data._enemies.clear()
	if player_unit:
		hex_map.map_data.set_enemy_position(
			player_unit.current_coord, true
		)


func _restore_enemy_positions() -> void:
	hex_map.map_data._enemies.clear()
	if ai_unit:
		hex_map.map_data.set_enemy_position(
			ai_unit.current_coord, true
		)


func _handle_result(
	card: CardData, result: CardResolver.CardResult,
	target: Vector2i = Vector2i.ZERO,
) -> void:
	match card.card_type:
		CardData.CardType.GATHER:
			var terrain: TerrainType = (
				hex_map.get_terrain(target)
			)
			if terrain:
				var types: Array[CardData.ResourceType] = []
				if terrain.materials_yield > 0:
					types.append(
						CardData.ResourceType.MATERIALS
					)
				if terrain.food_yield > 0:
					types.append(CardData.ResourceType.FOOD)
				if not types.is_empty():
					var picked: CardData.ResourceType = (
						types[randi() % types.size()]
					)
					var new_card := (
						card_resolver.pick_resource_card(picked)
					)
					deck_manager.hand.append(new_card)
		CardData.CardType.SETTLE:
			hex_map.map_data.place_settlement(
				result.settled_coord,
				result.settlement_name,
				ai_unit.avatar_color,
			)
			var tile: Node3D = hex_map.get_tile(
				result.settled_coord
			)
			if tile:
				tile.place_settlement(
					result.settlement_name,
					ai_unit.avatar_color,
					hex_map.map_data,
				)
