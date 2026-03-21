extends RefCounted

var _plains: TerrainType
var _mountain: TerrainType
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
	TestAssert.assert_eq(gs.turn.current_phase, TurnStateMachine.Phase.PLAY)
	TestAssert.assert_eq(gs.deck.hand.size(), 5)


func test_play_card_move() -> void:
	var gs := _make_game()
	var card: CardData = gs.deck.hand[0]
	if card.card_type != CardData.CardType.MOVE:
		return
	var result := gs.play_card(card, Vector2i(1, 0))
	TestAssert.assert_true(result.success)
	TestAssert.assert_eq(gs.player.current_coord, Vector2i(1, 0))
	TestAssert.assert_eq(gs.deck.hand.size(), 4)


func test_play_card_invalid_target() -> void:
	var gs := _make_game()
	var move_in_hand: CardData = null
	for c in gs.deck.hand:
		if c.card_type == CardData.CardType.MOVE:
			move_in_hand = c
			break
	if move_in_hand == null:
		return
	var result := gs.play_card(move_in_hand, Vector2i(0, -1))
	TestAssert.assert_false(result.success)
	TestAssert.assert_eq(gs.player.current_coord, Vector2i(0, 0))


func test_play_card_not_in_play_phase() -> void:
	var gs := _make_game()
	gs.turn.current_phase = TurnStateMachine.Phase.DRAW
	var card: CardData = gs.deck.hand[0]
	var result := gs.play_card(card, Vector2i(1, 0))
	TestAssert.assert_false(result.success)


func test_end_turn_flow() -> void:
	var gs := _make_game()
	var old_turn := gs.turn.current_turn
	gs.end_turn()
	TestAssert.assert_eq(gs.turn.current_turn, old_turn + 1)
	TestAssert.assert_gt(gs.deck.hand.size(), 0)


func test_gather_accumulates_resources() -> void:
	var gs := _make_game()
	var gather_in_hand: CardData = null
	for c in gs.deck.hand:
		if c.card_type == CardData.CardType.GATHER:
			gather_in_hand = c
			break
	if gather_in_hand == null:
		return
	var result := gs.play_card(gather_in_hand, Vector2i(1, 0))
	TestAssert.assert_true(result.success)
	TestAssert.assert_eq(gs.player.materials, 1)
	TestAssert.assert_eq(gs.player.food, 0)


func test_get_valid_targets() -> void:
	var gs := _make_game()
	var targets := gs.get_valid_targets(_move_card)
	TestAssert.assert_contains(targets, Vector2i(1, 0))
	TestAssert.assert_not_contains(targets, Vector2i(0, -1))
