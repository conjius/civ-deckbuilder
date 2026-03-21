extends Node

signal turn_started(turn_number: int)
signal phase_changed(phase: TurnStateMachine.Phase)

var state: TurnStateMachine = TurnStateMachine.new()
var card_manager: Node


func start_game() -> void:
	state.start_game()
	_on_new_turn()


func check_hand_empty() -> void:
	if card_manager.is_hand_empty():
		var result := state.on_hand_empty()
		if result.turn_ended:
			_on_new_turn()


func end_turn() -> void:
	var result := state.end_turn()
	if result.turn_ended:
		card_manager.discard_hand()
		_on_new_turn()


func can_play_cards() -> bool:
	return state.can_play_cards()


func _on_new_turn() -> void:
	turn_started.emit(state.current_turn)
	phase_changed.emit(TurnStateMachine.Phase.DRAW)
	card_manager.draw_hand()
	phase_changed.emit(TurnStateMachine.Phase.PLAY)
