## Mutable state for a player unit (explorer).
## Modifiers (attack/defense/health) are temporary buffs that reset each turn.
class_name PlayerState
extends RefCounted

var unit_name: String = "Explorer"
var max_health: int = 1
var health: int = 1
var attack: int = 0
var defense: int = 0
## Temporary attack buff, resets on turn start
var attack_modifier: int = 0
## Temporary defense buff, resets on turn start
var defense_modifier: int = 0
## Temporary HP buffer that absorbs damage first, resets on turn start
var health_modifier: int = 0
var sight_range: int = 2
var current_coord: Vector2i = Vector2i.ZERO


func place_at(coord: Vector2i) -> void:
	current_coord = coord


func move_to(coord: Vector2i) -> void:
	current_coord = coord


## Total HP including temporary health buffer
func effective_health() -> int:
	return health + health_modifier


## Apply damage, absorbing into health_modifier first
func take_damage(amount: int) -> void:
	if health_modifier > 0:
		var absorbed: int = mini(amount, health_modifier)
		health_modifier -= absorbed
		amount -= absorbed
	health = maxi(0, health - amount)


func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
