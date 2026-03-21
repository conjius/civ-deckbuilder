extends RefCounted


func test_start_game() -> void:
	var tsm := TurnStateMachine.new()
	tsm.start_game()
	TestAssert.assert_eq(tsm.current_turn, 1)
	TestAssert.assert_eq(tsm.current_phase, TurnStateMachine.Phase.PLAY)


func test_can_play_cards() -> void:
	var tsm := TurnStateMachine.new()
	tsm.start_game()
	TestAssert.assert_true(tsm.can_play_cards())


func test_end_turn() -> void:
	var tsm := TurnStateMachine.new()
	tsm.start_game()
	var result := tsm.end_turn()
	TestAssert.assert_true(result.turn_ended)
	TestAssert.assert_eq(tsm.current_turn, 2)
	TestAssert.assert_eq(tsm.current_phase, TurnStateMachine.Phase.PLAY)


func test_end_turn_not_in_play_phase() -> void:
	var tsm := TurnStateMachine.new()
	var result := tsm.end_turn()
	TestAssert.assert_false(result.turn_ended)


func test_on_hand_empty_triggers_end() -> void:
	var tsm := TurnStateMachine.new()
	tsm.start_game()
	var result := tsm.on_hand_empty()
	TestAssert.assert_true(result.turn_ended)
	TestAssert.assert_eq(tsm.current_turn, 2)
	TestAssert.assert_true(tsm.can_play_cards())


func test_on_hand_empty_not_in_play_phase() -> void:
	var tsm := TurnStateMachine.new()
	var result := tsm.on_hand_empty()
	TestAssert.assert_false(result.turn_ended)
