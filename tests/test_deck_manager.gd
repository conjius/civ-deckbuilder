extends RefCounted

var _card_a: CardData
var _card_b: CardData
var _card_c: CardData
var _food_card: CardData
var _mat_card: CardData


func before() -> void:
	_card_a = CardData.new()
	_card_a.card_name = "A"
	_card_b = CardData.new()
	_card_b.card_name = "B"
	_card_c = CardData.new()
	_card_c.card_name = "C"
	_food_card = CardData.new()
	_food_card.card_name = "Chicken"
	_food_card.card_type = CardData.CardType.RESOURCE
	_food_card.resource_type = CardData.ResourceType.FOOD
	_food_card.resource_value = 1
	_mat_card = CardData.new()
	_mat_card.card_name = "Wood"
	_mat_card.card_type = CardData.CardType.RESOURCE
	_mat_card.resource_type = CardData.ResourceType.MATERIALS
	_mat_card.resource_value = 1


func _make_deck(count: int) -> Array[CardData]:
	var deck: Array[CardData] = []
	for i in range(count):
		var c := CardData.new()
		c.card_name = "Card_%d" % i
		deck.append(c)
	return deck


func test_initialize_all_in_draw_pile() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a, _card_b, _card_c] as Array[CardData])
	TestAssert.assert_size(dm.draw_pile, 3)
	TestAssert.assert_size(dm.hand, 0)
	TestAssert.assert_size(dm.discard_pile, 0)


func test_draw_hand_draws_seven() -> void:
	var deck := _make_deck(12)
	var dm := DeckManager.new()
	dm.initialize(deck)
	dm.draw_hand()
	TestAssert.assert_size(dm.hand, 7)
	TestAssert.assert_size(dm.draw_pile, 5)


func test_draw_hand_draws_all_if_fewer_than_seven() -> void:
	var dm := DeckManager.new()
	dm.initialize(
		[_card_a, _card_b, _card_c] as Array[CardData]
	)
	dm.draw_hand()
	TestAssert.assert_size(dm.hand, 3)
	TestAssert.assert_size(dm.draw_pile, 0)


func test_play_card_moves_to_discard() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a, _card_b] as Array[CardData])
	dm.draw_hand()
	var played := dm.play_card(_card_a)
	TestAssert.assert_true(played)
	TestAssert.assert_size(dm.hand, 1)
	TestAssert.assert_contains(dm.discard_pile, _card_a)


func test_play_card_not_in_hand_fails() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a] as Array[CardData])
	dm.draw_hand()
	var played := dm.play_card(_card_b)
	TestAssert.assert_false(played)


func test_end_turn_discards_hand() -> void:
	var deck := _make_deck(12)
	var dm := DeckManager.new()
	dm.initialize(deck)
	dm.draw_hand()
	dm.play_card(dm.hand[0])
	dm.end_turn()
	TestAssert.assert_size(dm.hand, 0)
	TestAssert.assert_size(dm.discard_pile, 7)
	TestAssert.assert_size(dm.draw_pile, 5)


func test_draw_reshuffles_when_draw_empty() -> void:
	var deck := _make_deck(10)
	var dm := DeckManager.new()
	dm.initialize(deck)
	dm.draw_hand()
	TestAssert.assert_size(dm.hand, 7)
	TestAssert.assert_size(dm.draw_pile, 3)
	dm.end_turn()
	TestAssert.assert_size(dm.discard_pile, 7)
	TestAssert.assert_size(dm.draw_pile, 3)
	dm.draw_hand()
	TestAssert.assert_size(dm.hand, 7)
	TestAssert.assert_size(dm.discard_pile, 0)
	TestAssert.assert_size(dm.draw_pile, 3)


func test_draw_reshuffles_mid_draw() -> void:
	var deck := _make_deck(9)
	var dm := DeckManager.new()
	dm.initialize(deck)
	dm.draw_hand()
	dm.end_turn()
	# draw_pile has 2, discard has 7
	TestAssert.assert_size(dm.draw_pile, 2)
	TestAssert.assert_size(dm.discard_pile, 7)
	dm.draw_hand()
	# Should draw 2 from draw, reshuffle 7 from discard, draw 5 more
	TestAssert.assert_size(dm.hand, 7)
	TestAssert.assert_size(dm.discard_pile, 0)
	TestAssert.assert_size(dm.draw_pile, 2)


func test_add_card_goes_to_discard() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a] as Array[CardData])
	dm.add_card(_food_card)
	TestAssert.assert_contains(dm.discard_pile, _food_card)


func test_count_resources_all_piles() -> void:
	var dm := DeckManager.new()
	dm.initialize(
		[_food_card, _mat_card, _card_a] as Array[CardData]
	)
	dm.draw_hand()
	dm.play_card(_food_card)
	var totals: Dictionary = dm.count_resources()
	TestAssert.assert_eq(totals["food"], 1)
	TestAssert.assert_eq(totals["materials"], 1)


func test_count_resources_sums_values() -> void:
	var high_food := CardData.new()
	high_food.card_type = CardData.CardType.RESOURCE
	high_food.resource_type = CardData.ResourceType.FOOD
	high_food.resource_value = 3
	var dm := DeckManager.new()
	dm.initialize(
		[_food_card, high_food, _card_a] as Array[CardData]
	)
	dm.draw_hand()
	var totals: Dictionary = dm.count_resources()
	TestAssert.assert_eq(totals["food"], 4)


func test_reorder_card_in_hand() -> void:
	var dm := DeckManager.new()
	dm.initialize(
		[_card_a, _card_b, _card_c] as Array[CardData]
	)
	dm.draw_hand()
	dm.reorder_card(_card_c, 0)
	TestAssert.assert_eq(dm.hand[0], _card_c)


func test_play_same_card_twice_fails() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a, _card_b] as Array[CardData])
	dm.draw_hand()
	dm.play_card(_card_a)
	var played := dm.play_card(_card_a)
	TestAssert.assert_false(played)


func test_total_cards_constant() -> void:
	var deck := _make_deck(15)
	var dm := DeckManager.new()
	dm.initialize(deck)
	dm.draw_hand()
	dm.play_card(dm.hand[0])
	dm.play_card(dm.hand[0])
	var total: int = (
		dm.draw_pile.size() + dm.hand.size()
		+ dm.discard_pile.size()
	)
	TestAssert.assert_eq(total, 15)


func test_draw_pile_count() -> void:
	var deck := _make_deck(15)
	var dm := DeckManager.new()
	dm.initialize(deck)
	TestAssert.assert_eq(dm.draw_pile_count(), 15)
	dm.draw_hand()
	TestAssert.assert_eq(dm.draw_pile_count(), 8)


func test_end_turn_full_cycle() -> void:
	var deck := _make_deck(15)
	var dm := DeckManager.new()
	dm.initialize(deck)
	dm.draw_hand()
	TestAssert.assert_size(dm.hand, 7)
	TestAssert.assert_size(dm.draw_pile, 8)
	dm.play_card(dm.hand[0])
	dm.play_card(dm.hand[0])
	TestAssert.assert_size(dm.hand, 5)
	TestAssert.assert_size(dm.discard_pile, 2)
	dm.end_turn()
	TestAssert.assert_size(dm.hand, 0)
	TestAssert.assert_size(dm.discard_pile, 7)
	TestAssert.assert_size(dm.draw_pile, 8)
	dm.draw_hand()
	TestAssert.assert_size(dm.hand, 7)
	TestAssert.assert_size(dm.draw_pile, 1)
	dm.end_turn()
	dm.draw_hand()
	TestAssert.assert_size(dm.hand, 7)
	var total: int = (
		dm.draw_pile.size() + dm.hand.size()
		+ dm.discard_pile.size()
	)
	TestAssert.assert_eq(total, 15)


func test_discard_pile_count() -> void:
	var deck := _make_deck(10)
	var dm := DeckManager.new()
	dm.initialize(deck)
	dm.draw_hand()
	dm.play_card(dm.hand[0])
	TestAssert.assert_eq(dm.discard_pile_count(), 1)


func test_signal_fires_on_initialize() -> void:
	var dm := DeckManager.new()
	var fired := [false]
	dm.piles_changed.connect(func(_d: int, _h: int, _di: int) -> void:
		fired[0] = true
	)
	dm.initialize([_card_a, _card_b] as Array[CardData])
	TestAssert.assert_true(fired[0], "signal should fire on initialize")


func test_signal_fires_on_draw_hand() -> void:
	var dm := DeckManager.new()
	dm.initialize(_make_deck(10))
	var counts: Array[int] = []
	dm.piles_changed.connect(func(d: int, h: int, di: int) -> void:
		counts.assign([d, h, di])
	)
	dm.draw_hand()
	TestAssert.assert_eq(counts[0], 3)
	TestAssert.assert_eq(counts[1], 7)
	TestAssert.assert_eq(counts[2], 0)


func test_signal_fires_on_play_card() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a, _card_b, _card_c] as Array[CardData])
	dm.draw_hand()
	var counts: Array[int] = []
	dm.piles_changed.connect(func(d: int, h: int, di: int) -> void:
		counts.assign([d, h, di])
	)
	dm.play_card(_card_a)
	TestAssert.assert_eq(counts[0], 0)
	TestAssert.assert_eq(counts[1], 2)
	TestAssert.assert_eq(counts[2], 1)


func test_signal_fires_on_end_turn() -> void:
	var deck := _make_deck(10)
	var dm := DeckManager.new()
	dm.initialize(deck)
	dm.draw_hand()
	var counts: Array[int] = []
	dm.piles_changed.connect(func(d: int, h: int, di: int) -> void:
		counts.assign([d, h, di])
	)
	dm.end_turn()
	TestAssert.assert_eq(counts[0], 3)
	TestAssert.assert_eq(counts[1], 0)
	TestAssert.assert_eq(counts[2], 7)


func test_signal_fires_on_add_card() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a] as Array[CardData])
	dm.draw_hand()
	var counts: Array[int] = []
	dm.piles_changed.connect(func(d: int, h: int, di: int) -> void:
		counts.assign([d, h, di])
	)
	dm.add_card(_card_b)
	TestAssert.assert_eq(counts[0], 0)
	TestAssert.assert_eq(counts[1], 1)
	TestAssert.assert_eq(counts[2], 1)


func test_signal_counts_correct_after_reshuffle() -> void:
	var deck := _make_deck(9)
	var dm := DeckManager.new()
	dm.initialize(deck)
	dm.draw_hand()
	dm.end_turn()
	var counts: Array[int] = []
	dm.piles_changed.connect(func(d: int, h: int, di: int) -> void:
		counts.assign([d, h, di])
	)
	dm.draw_hand()
	TestAssert.assert_eq(counts[0], 2)
	TestAssert.assert_eq(counts[1], 7)
	TestAssert.assert_eq(counts[2], 0)
