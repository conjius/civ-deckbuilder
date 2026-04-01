extends RefCounted


func test_initial_stats() -> void:
	var ps := PlayerState.new()
	TestAssert.assert_eq(ps.unit_name, "Explorer")
	TestAssert.assert_eq(ps.health, 1)
	TestAssert.assert_eq(ps.max_health, 1)
	TestAssert.assert_eq(ps.attack, 0)
	TestAssert.assert_eq(ps.defense, 0)
	TestAssert.assert_eq(ps.sight_range, 2)


func test_place_at() -> void:
	var ps := PlayerState.new()
	ps.place_at(Vector2i(3, 4))
	TestAssert.assert_eq(ps.current_coord, Vector2i(3, 4))


func test_move_to() -> void:
	var ps := PlayerState.new()
	ps.place_at(Vector2i(0, 0))
	ps.move_to(Vector2i(1, 0))
	TestAssert.assert_eq(ps.current_coord, Vector2i(1, 0))


func test_take_damage() -> void:
	var ps := PlayerState.new()
	ps.health = 10
	ps.max_health = 10
	ps.take_damage(3)
	TestAssert.assert_eq(ps.health, 7)


func test_take_damage_cannot_go_below_zero() -> void:
	var ps := PlayerState.new()
	ps.take_damage(100)
	TestAssert.assert_eq(ps.health, 0)


func test_heal() -> void:
	var ps := PlayerState.new()
	ps.health = 10
	ps.max_health = 10
	ps.take_damage(5)
	ps.heal(3)
	TestAssert.assert_eq(ps.health, 8)


func test_heal_cannot_exceed_max() -> void:
	var ps := PlayerState.new()
	ps.health = 10
	ps.max_health = 10
	ps.take_damage(2)
	ps.heal(100)
	TestAssert.assert_eq(ps.health, ps.max_health)


func test_health_modifier_absorbs_damage() -> void:
	var ps := PlayerState.new()
	ps.health = 5
	ps.max_health = 5
	ps.health_modifier = 3
	ps.take_damage(2)
	TestAssert.assert_eq(ps.health_modifier, 1)
	TestAssert.assert_eq(ps.health, 5)


func test_health_modifier_overflow_to_health() -> void:
	var ps := PlayerState.new()
	ps.health = 5
	ps.max_health = 5
	ps.health_modifier = 2
	ps.take_damage(5)
	TestAssert.assert_eq(ps.health_modifier, 0)
	TestAssert.assert_eq(ps.health, 2)


func test_effective_health() -> void:
	var ps := PlayerState.new()
	ps.health = 5
	ps.health_modifier = 3
	TestAssert.assert_eq(ps.effective_health(), 8)
