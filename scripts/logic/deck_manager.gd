class_name DeckManager
extends RefCounted

signal piles_changed(draw_count: int, hand_count: int, discard_count: int)

const HAND_SIZE := 7

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []


func _emit_counts() -> void:
	piles_changed.emit(
		draw_pile.size(), hand.size(), discard_pile.size()
	)


func initialize(deck: Array[CardData]) -> void:
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()
	_emit_counts()


func draw_hand() -> void:
	for _i in range(HAND_SIZE):
		if draw_pile.is_empty() and discard_pile.is_empty():
			break
		if draw_pile.is_empty():
			_reshuffle_discard()
		hand.append(draw_pile.pop_back())
	_emit_counts()


func play_card(card: CardData) -> bool:
	var idx := hand.find(card)
	if idx == -1:
		return false
	hand.remove_at(idx)
	discard_pile.append(card)
	_emit_counts()
	return true


func end_turn() -> void:
	discard_pile.append_array(hand)
	hand.clear()
	_emit_counts()


func reorder_card(card: CardData, new_index: int) -> void:
	var old_idx := hand.find(card)
	if old_idx == -1:
		return
	hand.remove_at(old_idx)
	new_index = clampi(new_index, 0, hand.size())
	hand.insert(new_index, card)


func add_card(card: CardData) -> void:
	discard_pile.append(card)
	_emit_counts()


func add_to_hand(card: CardData) -> void:
	hand.append(card)
	_emit_counts()


func draw_pile_count() -> int:
	return draw_pile.size()


func discard_pile_count() -> int:
	return discard_pile.size()


func count_resources() -> Dictionary:
	var totals := {"food": 0, "materials": 0}
	for pile: Array[CardData] in [draw_pile, hand, discard_pile]:
		for card: CardData in pile:
			if card.card_type != CardData.CardType.RESOURCE:
				continue
			match card.resource_type:
				CardData.ResourceType.FOOD:
					totals["food"] += card.resource_value
				CardData.ResourceType.MATERIALS:
					totals["materials"] += card.resource_value
	return totals


func _reshuffle_discard() -> void:
	draw_pile.append_array(discard_pile)
	discard_pile.clear()
	draw_pile.shuffle()
