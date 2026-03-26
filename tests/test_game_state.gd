extends RefCounted

var _plains: TerrainType
var _mountain: TerrainType
var _forest: TerrainType
var _move_card: CardData
var _scout_card: CardData
var _gather_card: CardData


func before() -> void:
	_plains = TerrainType.new()
	_plains.terrain_name = "Plains"
	_plains.is_passable = true
	_plains.height = 0.1
	_plains.materials_yield = 1
	_plains.food_yield = 0

	_mountain = TerrainType.new()
	_mountain.terrain_name = "Mountain"
	_mountain.is_passable = false
	_mountain.height = 0.5
	_mountain.materials_yield = 0
	_mountain.food_yield = 0

	_forest = TerrainType.new()
	_forest.terrain_name = "Forest"
	_forest.is_passable = true
	_forest.stops_movement = true
	_forest.materials_yield = 1
	_forest.food_yield = 1

	_move_card = CardData.new()
	_move_card.card_name = "March"
	_move_card.card_type = CardData.CardType.MOVE
	_move_card.range_value = 1

	_scout_card = CardData.new()
	_scout_card.card_name = "Scout"
	_scout_card.card_type = CardData.CardType.SCOUT
	_scout_card.range_value = 2

	_gather_card = CardData.new()
	_gather_card.card_name = "Gather"
	_gather_card.card_type = CardData.CardType.GATHER
	_gather_card.range_value = 1


func _make_game() -> GameState:
	var map := MapData.new()
	map.set_terrain(Vector2i(0, 0), _plains)
	map.set_terrain(Vector2i(1, 0), _plains)
	map.set_terrain(Vector2i(2, 0), _plains)
	map.set_terrain(Vector2i(0, 1), _plains)
	map.set_terrain(Vector2i(0, -1), _mountain)

	var deck: Array[CardData] = [
		_move_card, _move_card, _move_card,
		_scout_card,
		_gather_card,
	]

	var gs := GameState.new()
	gs.setup(map, deck, Vector2i(0, 0))
	return gs


func test_setup_initializes_state() -> void:
	var gs := _make_game()
	TestAssert.assert_eq(gs.player.current_coord, Vector2i(0, 0))
	TestAssert.assert_eq(gs.turn.current_turn, 1)
	TestAssert.assert_eq(
		gs.turn.current_phase, TurnStateMachine.Phase.PLAY
	)
	TestAssert.assert_eq(gs.deck.cards.size(), 5)


func test_play_card_move() -> void:
	var gs := _make_game()
	var result := gs.play_card(_move_card, Vector2i(1, 0))
	TestAssert.assert_true(result.success)
	TestAssert.assert_eq(gs.player.current_coord, Vector2i(1, 0))
	TestAssert.assert_eq(gs.deck.cards.size(), 4)
	TestAssert.assert_contains(gs.deck.used_this_turn, _move_card)


func test_play_card_invalid_target() -> void:
	var gs := _make_game()
	var result := gs.play_card(_move_card, Vector2i(0, -1))
	TestAssert.assert_false(result.success)
	TestAssert.assert_eq(gs.player.current_coord, Vector2i(0, 0))
	TestAssert.assert_eq(gs.deck.cards.size(), 5)


func test_play_card_not_in_play_phase() -> void:
	var gs := _make_game()
	gs.turn.current_phase = TurnStateMachine.Phase.DRAW
	var result := gs.play_card(_move_card, Vector2i(1, 0))
	TestAssert.assert_false(result.success)


func test_end_turn_returns_used_cards() -> void:
	var gs := _make_game()
	gs.play_card(_move_card, Vector2i(1, 0))
	TestAssert.assert_eq(gs.deck.cards.size(), 4)
	gs.end_turn()
	TestAssert.assert_eq(gs.deck.cards.size(), 5)
	TestAssert.assert_eq(gs.turn.current_turn, 2)


func test_gather_adds_resource_cards_to_deck() -> void:
	var gs := _make_game()
	var result := gs.play_card(_gather_card, Vector2i(1, 0))
	TestAssert.assert_true(result.success)
	var totals: Dictionary = gs.deck.count_resources()
	TestAssert.assert_eq(totals["materials"], 1)
	TestAssert.assert_eq(totals["food"], 0)


func test_gather_mixed_terrain_produces_both_types() -> void:
	var map := MapData.new()
	map.set_terrain(Vector2i(0, 0), _plains)
	map.set_terrain(Vector2i(1, 0), _forest)
	var deck: Array[CardData] = [
		_gather_card, _move_card, _move_card,
		_move_card, _move_card,
	]
	var gs := GameState.new()
	gs.setup(map, deck, Vector2i(0, 0))
	gs.play_card(_gather_card, Vector2i(1, 0))
	var totals: Dictionary = gs.deck.count_resources()
	TestAssert.assert_eq(totals["materials"], 1)
	TestAssert.assert_eq(totals["food"], 1)


func test_gather_cards_survive_end_turn() -> void:
	var gs := _make_game()
	gs.play_card(_gather_card, Vector2i(1, 0))
	var totals_before: Dictionary = gs.deck.count_resources()
	gs.end_turn()
	var totals_after: Dictionary = gs.deck.count_resources()
	TestAssert.assert_eq(
		totals_after["materials"],
		totals_before["materials"],
	)


func test_get_valid_targets() -> void:
	var gs := _make_game()
	var targets := gs.get_valid_targets(_move_card)
	TestAssert.assert_contains(targets, Vector2i(1, 0))
	TestAssert.assert_not_contains(targets, Vector2i(0, -1))


func test_resource_cards_not_playable() -> void:
	var food := CardData.new()
	food.card_type = CardData.CardType.RESOURCE
	food.resource_type = CardData.ResourceType.FOOD
	food.resource_value = 1
	var map := MapData.new()
	map.set_terrain(Vector2i(0, 0), _plains)
	var deck: Array[CardData] = [food, _move_card]
	var gs := GameState.new()
	gs.setup(map, deck, Vector2i(0, 0))
	var targets := gs.get_valid_targets(food)
	TestAssert.assert_size(targets, 0)
