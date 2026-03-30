class_name CombatResolver
extends RefCounted


static func compute_damage(attack_value: int, defense_value: int) -> int:
	var diff: int = attack_value - defense_value
	if diff < 0:
		return 0
	return diff
