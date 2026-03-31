extends RefCounted


func test_discard_pile_is_face_down() -> void:
	var pile := CardPileUI.new()
	pile.setup(true)
	TestAssert.assert_true(
		pile._is_face_down,
		"discard pile should be face-down (dark)"
	)


func test_draw_pile_is_face_down() -> void:
	var pile := CardPileUI.new()
	pile.setup(true)
	TestAssert.assert_true(
		pile._is_face_down,
		"draw pile should be face-down (dark)"
	)


func test_discard_anim_duration_matches_draw() -> void:
	var hand := load(
		"res://scripts/ui/card_hand_ui.gd"
	) as GDScript
	TestAssert.assert_true(
		hand != null, "card_hand_ui.gd should load"
	)
	var src := hand.source_code
	TestAssert.assert_true(
		src.contains("DISCARD_DUR := 0.7"),
		"discard duration constant should be 0.7 to match draw"
	)


func test_discard_anim_has_flip() -> void:
	var src := (
		load("res://scripts/ui/card_hand_ui.gd") as GDScript
	).source_code
	var fn_start := src.find("func _animate_to_discard_pile")
	var fn_body := src.substr(fn_start, 1600)
	TestAssert.assert_true(
		fn_body.contains("set_face_up(false)"),
		"discard animation should flip card to face-down"
	)
