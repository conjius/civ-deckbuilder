class_name DeckManager
extends RefCounted

var cards: Array[CardData] = []
var used_this_turn: Array[CardData] = []


func initialize(deck: Array[CardData]) -> void:
	cards = deck.duplicate()
	used_this_turn.clear()


func play_card(card: CardData) -> bool:
	var idx := cards.find(card)
	if idx == -1:
		return false
	cards.remove_at(idx)
	used_this_turn.append(card)
	return true


func end_turn() -> void:
	cards.append_array(used_this_turn)
	used_this_turn.clear()


func add_card(card: CardData) -> void:
	cards.append(card)


func count_resources() -> Dictionary:
	var totals := {"food": 0, "materials": 0}
	for pile: Array[CardData] in [cards, used_this_turn]:
		for card: CardData in pile:
			if card.card_type != CardData.CardType.RESOURCE:
				continue
			match card.resource_type:
				CardData.ResourceType.FOOD:
					totals["food"] += card.resource_value
				CardData.ResourceType.MATERIALS:
					totals["materials"] += card.resource_value
	return totals
