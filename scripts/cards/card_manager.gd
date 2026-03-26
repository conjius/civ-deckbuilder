extends Node

signal cards_changed(cards: Array[CardData])
signal card_played(card: CardData)

@export var starting_deck: Array[CardData] = []

var deck_manager: DeckManager = DeckManager.new()


func initialize_deck() -> void:
	deck_manager.initialize(starting_deck)
	cards_changed.emit(deck_manager.cards)


func play_card(card: CardData) -> void:
	if not deck_manager.play_card(card):
		return
	card_played.emit(card)
	cards_changed.emit(deck_manager.cards)


func end_turn() -> void:
	deck_manager.end_turn()
	cards_changed.emit(deck_manager.cards)
