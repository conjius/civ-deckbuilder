class_name AIController
extends Node

signal turn_completed

const PLAY_DELAY: float = 0.4

var ai_unit: Node3D
var deck_manager: DeckManager = DeckManager.new()
var card_effects: Node
var card_resolver: CardResolver
var hex_map: Node3D


func initialize(deck: Array[CardData]) -> void:
	deck_manager.hand_size = 5
	deck_manager.initialize(deck)


func take_turn() -> void:
	deck_manager.draw_hand()
	var cards_to_play: Array[CardData] = deck_manager.hand.duplicate()
	for card in cards_to_play:
		var targets := card_resolver.get_valid_targets(
			card, ai_unit.current_coord
		)
		if targets.is_empty():
			deck_manager.play_card(card)
			continue
		var target: Vector2i = targets[randi() % targets.size()]
		var result: CardResolver.CardResult = (
			card_effects.execute_card(card, target, ai_unit)
		)
		if result.success:
			deck_manager.play_card(card)
			_handle_result(card, result)
			if card.card_type == CardData.CardType.MOVE:
				if ai_unit.is_moving():
					await ai_unit.movement_finished
			await get_tree().create_timer(PLAY_DELAY).timeout
		else:
			deck_manager.play_card(card)
	deck_manager.discard_hand()
	turn_completed.emit()


func _handle_result(
	card: CardData, result: CardResolver.CardResult,
) -> void:
	match card.card_type:
		CardData.CardType.GATHER:
			ai_unit.state.add_resources(
				result.materials_gained, result.food_gained
			)
		CardData.CardType.SETTLE:
			var tile: Node3D = hex_map.get_tile(
				result.settled_coord
			)
			if tile:
				tile.place_settlement(
					result.settlement_name,
					ai_unit.avatar_color,
					hex_map.map_data,
				)
