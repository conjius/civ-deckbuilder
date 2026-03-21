class_name TerrainType
extends Resource

@export var terrain_name: String = ""
@export var movement_cost: int = 1
@export var is_passable: bool = true
@export var height: float = 0.1
@export var color: Color = Color.GREEN
@export var texture: Texture2D
@export var materials_yield: int = 0
@export var food_yield: int = 0
@export var stops_movement: bool = false
