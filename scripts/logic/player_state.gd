class_name PlayerState
extends RefCounted

var unit_name: String = "Explorer"
var max_health: int = 1
var health: int = 1
var attack: int = 0
var defense: int = 0
var defense_modifier: int = 0
var sight_range: int = 2
var current_coord: Vector2i = Vector2i.ZERO


func place_at(coord: Vector2i) -> void:
	current_coord = coord


func move_to(coord: Vector2i) -> void:
	current_coord = coord


func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)


func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
