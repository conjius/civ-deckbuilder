extends Node

signal cards_changed(cards: Array[CardData])
signal card_played(card: CardData)

@export var starting_deck: Array[CardData] = []

var deck_manager: DeckManager = DeckManager.new()


func initialize_deck() -> void:
	deck_manager.initialize(starting_deck)
	deck_manager.draw_hand()
	cards_changed.emit(deck_manager.hand)


func play_card(card: CardData) -> void:
	if not deck_manager.play_card(card):
		return
	card_played.emit(card)
	cards_changed.emit(deck_manager.hand)


func discard_hand() -> void:
	deck_manager.end_turn()
	cards_changed.emit(deck_manager.hand)


func draw_new_hand() -> void:
	deck_manager.draw_hand()
	cards_changed.emit(deck_manager.hand)
