extends Node

signal hand_changed(hand: Array[CardData])
signal card_played(card: CardData)
signal draw_pile_changed(count: int)
signal discard_pile_changed(count: int)

@export var starting_deck: Array[CardData] = []
@export var hand_size: int = 5

var deck_manager: DeckManager = DeckManager.new()


func initialize_deck() -> void:
	deck_manager.hand_size = hand_size
	deck_manager.initialize(starting_deck)
	draw_pile_changed.emit(deck_manager.draw_pile.size())
	discard_pile_changed.emit(deck_manager.discard_pile.size())


func draw_hand() -> void:
	deck_manager.draw_hand()
	hand_changed.emit(deck_manager.hand)
	draw_pile_changed.emit(deck_manager.draw_pile.size())
	discard_pile_changed.emit(deck_manager.discard_pile.size())


func play_card(card: CardData) -> void:
	if not deck_manager.play_card(card):
		return
	card_played.emit(card)
	draw_pile_changed.emit(deck_manager.draw_pile.size())
	discard_pile_changed.emit(deck_manager.discard_pile.size())


func discard_hand() -> void:
	deck_manager.discard_hand()
	hand_changed.emit(deck_manager.hand)
	discard_pile_changed.emit(deck_manager.discard_pile.size())


func is_hand_empty() -> bool:
	return deck_manager.hand.is_empty()
