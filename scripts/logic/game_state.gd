class_name GameState
extends RefCounted

var map: MapData
var deck: DeckManager
var turn: TurnStateMachine
var player: PlayerState
var resolver: CardResolver


func setup(p_map: MapData, starting_deck: Array[CardData], start_coord: Vector2i) -> void:
	map = p_map
	player = PlayerState.new()
	player.place_at(start_coord)

	deck = DeckManager.new()
	deck.initialize(starting_deck)

	turn = TurnStateMachine.new()
	turn.start_game()

	resolver = CardResolver.new(map)


func play_card(card: CardData, target: Vector2i) -> CardResolver.CardResult:
	var empty := CardResolver.CardResult.new()
	if not turn.can_play_cards():
		return empty

	var result := resolver.resolve_card(card, target, player.current_coord)
	if not result.success:
		return result

	match card.card_type:
		CardData.CardType.MOVE:
			player.move_to(result.new_coord)
		CardData.CardType.GATHER:
			for gained_card: CardData in result.gained_cards:
				deck.add_card(gained_card)
		CardData.CardType.DEFENSE:
			player.defense_modifier += result.defense_gained

	deck.play_card(card)
	return result


func end_turn() -> void:
	var result := turn.end_turn()
	if result.turn_ended:
		deck.end_turn()


func get_valid_targets(card: CardData) -> Array[Vector2i]:
	return resolver.get_valid_targets(card, player.current_coord)
