extends HBoxContainer

signal card_dropped(card: CardData, target: Vector2i)

var hex_map: Node3D
var camera: Camera3D
var card_effects: Node
var active_unit: Node3D
var arrow_indicator: MeshInstance3D

var _card_display_scene: PackedScene = preload(
	"res://scenes/ui/card_display.tscn"
)


func update_hand(hand: Array[CardData]) -> void:
	for child in get_children():
		child.queue_free()

	for card in hand:
		_add_card_display(card)


func remove_card(card: CardData) -> void:
	for child in get_children():
		if child.card_data == card:
			child.queue_free()
			break


func _add_card_display(card: CardData) -> void:
	var display: PanelContainer = _card_display_scene.instantiate()
	add_child(display)
	display.setup(card)
	display.hex_map = hex_map
	display.camera = camera
	display.card_effects = card_effects
	display.active_unit = active_unit
	display.arrow_indicator = arrow_indicator
	display.drag_started.connect(_on_drag_started)
	display.drag_ended.connect(_on_drag_ended)


func _on_drag_started(_card: CardData) -> void:
	pass


func _on_drag_ended(
	card: CardData, target: Vector2i, success: bool,
) -> void:
	if success:
		card_dropped.emit(card, target)
