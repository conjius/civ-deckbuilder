extends PanelContainer

var _font: Font = preload("res://assets/fonts/Cinzel-Regular.ttf")

@onready var materials_label: Label = %MaterialsLabel
@onready var food_label: Label = %FoodLabel


func _ready() -> void:
	for lbl: Label in [materials_label, food_label]:
		lbl.add_theme_font_override("font", _font)
		lbl.add_theme_font_size_override(
			"font_size", UIHelpers.FONT_LABEL
		)


func update_resources(materials: int, food: int) -> void:
	materials_label.text = "Materials: %d" % materials
	food_label.text = "Food: %d" % food
