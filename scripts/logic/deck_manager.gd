## Manages the three card piles: draw, hand, and discard.
## Handles drawing, playing, discarding, reshuffling, and emits
## piles_changed on every state change for UI counter sync.
class_name DeckManager
extends RefCounted

## Emitted after every pile modification with current counts
signal piles_changed(draw_count: int, hand_count: int, discard_count: int)

const HAND_SIZE := 7

var draw_pile: Array[CardData] = []
var hand: Array[CardData] = []
var discard_pile: Array[CardData] = []


func _emit_counts() -> void:
	piles_changed.emit(
		draw_pile.size(), hand.size(), discard_pile.size()
	)


## Shuffle the deck and reset all piles
func initialize(deck: Array[CardData]) -> void:
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()
	_emit_counts()


## Draw HAND_SIZE cards from draw pile, reshuffling discard if needed
func draw_hand() -> void:
	for _i in range(HAND_SIZE):
		if draw_pile.is_empty() and discard_pile.is_empty():
			break
		if draw_pile.is_empty():
			_reshuffle_discard()
		hand.append(draw_pile.pop_back())
	_emit_counts()


## Move a card from hand to discard pile. Returns false if card not in hand.
func play_card(card: CardData) -> bool:
	var idx := hand.find(card)
	if idx == -1:
		return false
	hand.remove_at(idx)
	discard_pile.append(card)
	_emit_counts()
	return true


## Discard entire hand at end of turn
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


## Add a new card to the discard pile (e.g. from gather)
func add_card(card: CardData) -> void:
	discard_pile.append(card)
	_emit_counts()


## Add a card directly to hand (e.g. from Plan Ahead draw)
func add_to_hand(card: CardData) -> void:
	hand.append(card)
	_emit_counts()


func draw_pile_count() -> int:
	return draw_pile.size()


func discard_pile_count() -> int:
	return discard_pile.size()


## Count total food and materials across all three piles
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
