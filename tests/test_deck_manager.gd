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


func test_initialize() -> void:
	var dm := DeckManager.new()
	var deck: Array[CardData] = [_card_a, _card_b, _card_c]
	dm.initialize(deck)
	TestAssert.assert_size(dm.cards, 3)
	TestAssert.assert_size(dm.used_this_turn, 0)


func test_play_card() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a, _card_b] as Array[CardData])
	var played := dm.play_card(_card_a)
	TestAssert.assert_true(played)
	TestAssert.assert_size(dm.cards, 1)
	TestAssert.assert_contains(dm.used_this_turn, _card_a)


func test_play_card_not_in_cards() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a] as Array[CardData])
	var played := dm.play_card(_card_b)
	TestAssert.assert_false(played)
	TestAssert.assert_size(dm.cards, 1)


func test_end_turn_returns_used_cards() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a, _card_b] as Array[CardData])
	dm.play_card(_card_a)
	TestAssert.assert_size(dm.cards, 1)
	dm.end_turn()
	TestAssert.assert_size(dm.cards, 2)
	TestAssert.assert_size(dm.used_this_turn, 0)


func test_end_turn_with_nothing_used() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a] as Array[CardData])
	dm.end_turn()
	TestAssert.assert_size(dm.cards, 1)
	TestAssert.assert_size(dm.used_this_turn, 0)


func test_add_card() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a] as Array[CardData])
	dm.add_card(_food_card)
	TestAssert.assert_size(dm.cards, 2)
	TestAssert.assert_contains(dm.cards, _food_card)


func test_count_resources_empty() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a] as Array[CardData])
	var totals: Dictionary = dm.count_resources()
	TestAssert.assert_eq(totals["food"], 0)
	TestAssert.assert_eq(totals["materials"], 0)


func test_count_resources_in_cards() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a] as Array[CardData])
	dm.add_card(_food_card)
	dm.add_card(_mat_card)
	var totals: Dictionary = dm.count_resources()
	TestAssert.assert_eq(totals["food"], 1)
	TestAssert.assert_eq(totals["materials"], 1)


func test_count_resources_includes_used() -> void:
	var dm := DeckManager.new()
	dm.initialize(
		[_food_card, _mat_card, _card_a] as Array[CardData]
	)
	dm.play_card(_card_a)
	var totals: Dictionary = dm.count_resources()
	TestAssert.assert_eq(totals["food"], 1)
	TestAssert.assert_eq(totals["materials"], 1)


func test_count_resources_sums_values() -> void:
	var high_food := CardData.new()
	high_food.card_type = CardData.CardType.RESOURCE
	high_food.resource_type = CardData.ResourceType.FOOD
	high_food.resource_value = 3
	var dm := DeckManager.new()
	dm.initialize([_card_a] as Array[CardData])
	dm.add_card(_food_card)
	dm.add_card(high_food)
	var totals: Dictionary = dm.count_resources()
	TestAssert.assert_eq(totals["food"], 4)


func test_play_same_card_twice_fails() -> void:
	var dm := DeckManager.new()
	dm.initialize([_card_a, _card_b] as Array[CardData])
	dm.play_card(_card_a)
	var played := dm.play_card(_card_a)
	TestAssert.assert_false(played)


func test_cards_order_preserved_after_end_turn() -> void:
	var dm := DeckManager.new()
	dm.initialize(
		[_card_a, _card_b, _card_c] as Array[CardData]
	)
	dm.play_card(_card_b)
	dm.end_turn()
	TestAssert.assert_size(dm.cards, 3)
	TestAssert.assert_contains(dm.cards, _card_b)
