extends PanelContainer

var _font: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")

@onready var materials_label: RichTextLabel = %MaterialsLabel
@onready var food_label: RichTextLabel = %FoodLabel


func _ready() -> void:
	add_theme_stylebox_override(
		"panel", UIHelpers.create_panel_style()
	)
	UIHelpers.apply_parchment_bg(self)
	custom_minimum_size = Vector2(UIHelpers.CARD_WIDTH, 0)
	size.x = UIHelpers.CARD_WIDTH
	size_flags_horizontal = Control.SIZE_SHRINK_END
	clip_contents = true
	for lbl: RichTextLabel in [materials_label, food_label]:
		lbl.add_theme_font_override("normal_font", _font)
		lbl.add_theme_font_size_override(
			"normal_font_size", UIHelpers.FONT_UNIT_STAT
		)
		lbl.add_theme_color_override(
			"default_color", Color.BLACK
		)
	update_resources(0, 0)


func update_resources(materials: int, food: int) -> void:
	UIHelpers.set_bbcode(materials_label, UIHelpers.icon_text(
		"Materials", str(materials)
	))
	UIHelpers.set_bbcode(
		food_label, UIHelpers.icon_text("Food", str(food))
	)
