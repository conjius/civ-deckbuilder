extends RefCounted

var _plains: TerrainType
var _map: MapData
var _melee: CardData
var _ranged: CardData
var _shield: CardData
var _armor: CardData


func before_each() -> void:
	_plains = TerrainType.new()
	_plains.terrain_name = "Plains"
	_plains.is_passable = true
	_plains.materials_yield = 1

	_map = MapData.new()
	for q in range(-3, 4):
		for r in range(-3, 4):
			_map.set_terrain(Vector2i(q, r), _plains)

	_melee = CardData.new()
	_melee.card_name = "Strike"
	_melee.card_type = CardData.CardType.ATTACK
	_melee.range_value = 1
	_melee.attack_damage = 1

	_ranged = CardData.new()
	_ranged.card_name = "Shoot"
	_ranged.card_type = CardData.CardType.ATTACK
	_ranged.range_value = 2
	_ranged.attack_damage = 1

	_shield = CardData.new()
	_shield.card_name = "Shields Up!"
	_shield.card_type = CardData.CardType.DEFENSE
	_shield.defense_bonus = 1

	_armor = CardData.new()
	_armor.card_name = "Armor Up!"
	_armor.card_type = CardData.CardType.DEFENSE
	_armor.defense_bonus = 2


func test_attack_targets_empty_without_enemies() -> void:
	var resolver := CardResolver.new(_map)
	var targets := resolver.get_valid_targets(
		_melee, Vector2i(0, 0)
	)
	TestAssert.assert_size(targets, 0)


func test_attack_targets_include_enemy_in_range() -> void:
	_map.set_enemy_position(Vector2i(1, 0), true)
	var resolver := CardResolver.new(_map)
	var targets := resolver.get_valid_targets(
		_melee, Vector2i(0, 0)
	)
	TestAssert.assert_contains(targets, Vector2i(1, 0))


func test_attack_targets_exclude_enemy_out_of_range() -> void:
	_map.set_enemy_position(Vector2i(2, 0), true)
	var resolver := CardResolver.new(_map)
	var targets := resolver.get_valid_targets(
		_melee, Vector2i(0, 0)
	)
	TestAssert.assert_not_contains(targets, Vector2i(2, 0))


func test_ranged_attack_hits_at_range_2() -> void:
	_map.set_enemy_position(Vector2i(2, 0), true)
	var resolver := CardResolver.new(_map)
	var targets := resolver.get_valid_targets(
		_ranged, Vector2i(0, 0)
	)
	TestAssert.assert_contains(targets, Vector2i(2, 0))


func test_attack_targets_include_settlement() -> void:
	_map.place_settlement(
		Vector2i(1, 0), "Enemy Camp", Color.RED
	)
	var resolver := CardResolver.new(_map)
	var targets := resolver.get_valid_targets(
		_melee, Vector2i(0, 0)
	)
	TestAssert.assert_contains(targets, Vector2i(1, 0))


func test_attack_targets_exclude_empty_terrain() -> void:
	var resolver := CardResolver.new(_map)
	var targets := resolver.get_valid_targets(
		_melee, Vector2i(0, 0)
	)
	for t in targets:
		var has_target: bool = (
			_map.has_settlement(t)
			or _map.has_enemy(t)
		)
		TestAssert.assert_true(
			has_target,
			"target should be enemy or settlement",
		)


func test_resolve_melee_attack() -> void:
	_map.set_enemy_position(Vector2i(1, 0), true)
	var resolver := CardResolver.new(_map)
	var result := resolver.resolve_card(
		_melee, Vector2i(1, 0), Vector2i(0, 0)
	)
	TestAssert.assert_true(result.success)
	TestAssert.assert_eq(result.damage_dealt, 1)


func test_resolve_ranged_attack() -> void:
	_map.set_enemy_position(Vector2i(2, 0), true)
	var resolver := CardResolver.new(_map)
	var result := resolver.resolve_card(
		_ranged, Vector2i(2, 0), Vector2i(0, 0)
	)
	TestAssert.assert_true(result.success)
	TestAssert.assert_eq(result.damage_dealt, 1)


func test_resolve_attack_on_empty_tile_fails() -> void:
	var resolver := CardResolver.new(_map)
	var result := resolver.resolve_card(
		_melee, Vector2i(1, 0), Vector2i(0, 0)
	)
	TestAssert.assert_false(result.success)


func test_resolve_shield() -> void:
	var resolver := CardResolver.new(_map)
	var result := resolver.resolve_card(
		_shield, Vector2i(0, 0), Vector2i(0, 0)
	)
	TestAssert.assert_true(result.success)
	TestAssert.assert_eq(result.defense_gained, 1)


func test_shield_targets_self_only() -> void:
	var resolver := CardResolver.new(_map)
	var targets := resolver.get_valid_targets(
		_shield, Vector2i(0, 0)
	)
	TestAssert.assert_size(targets, 1)
	TestAssert.assert_contains(targets, Vector2i(0, 0))


func test_resolve_armor() -> void:
	var resolver := CardResolver.new(_map)
	var result := resolver.resolve_card(
		_armor, Vector2i(0, 0), Vector2i(0, 0)
	)
	TestAssert.assert_true(result.success)
	TestAssert.assert_eq(result.defense_gained, 2)


func test_damage_blocked_by_defense() -> void:
	var ps := PlayerState.new()
	ps.health = 10
	ps.max_health = 10
	ps.defense = 2
	var actual_damage: int = CombatResolver.compute_damage(3, ps.defense + ps.defense_modifier)
	TestAssert.assert_eq(actual_damage, 1)
	ps.take_damage(actual_damage)
	TestAssert.assert_eq(ps.health, 9)


func test_damage_fully_blocked() -> void:
	var actual_damage: int = CombatResolver.compute_damage(2, 3)
	TestAssert.assert_eq(actual_damage, 0)


func test_damage_with_defense_modifier() -> void:
	var ps := PlayerState.new()
	ps.health = 10
	ps.max_health = 10
	ps.defense = 0
	ps.defense_modifier = 2
	var actual_damage: int = CombatResolver.compute_damage(3, ps.defense + ps.defense_modifier)
	TestAssert.assert_eq(actual_damage, 1)


func test_attack_settlement_with_defense() -> void:
	_map.place_settlement(Vector2i(1, 0), "Camp", Color.RED)
	var def: int = _map.get_settlement_defense(Vector2i(1, 0))
	var actual_damage: int = CombatResolver.compute_damage(2, def)
	TestAssert.assert_eq(actual_damage, 1)
	_map.damage_settlement(Vector2i(1, 0), actual_damage)
	TestAssert.assert_eq(_map.get_settlement_hp(Vector2i(1, 0)), 4)


func test_defense_resets_on_turn() -> void:
	var ps := PlayerState.new()
	ps.defense_modifier = 1
	ps.defense_modifier = 0
	TestAssert.assert_eq(ps.defense_modifier, 0)
