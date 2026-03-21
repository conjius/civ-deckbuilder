class_name PlayerState
extends RefCounted

var unit_name: String = "Scout"
var max_health: int = 10
var health: int = 10
var attack: int = 2
var defense: int = 1
var defense_modifier: int = 0
var sight_range: int = 2
var current_coord: Vector2i = Vector2i.ZERO
var materials: int = 0
var food: int = 0


func place_at(coord: Vector2i) -> void:
	current_coord = coord


func move_to(coord: Vector2i) -> void:
	current_coord = coord


func add_resources(mat: int, fd: int) -> void:
	materials += mat
	food += fd


func take_damage(amount: int) -> void:
	health = maxi(0, health - amount)


func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
