extends VBoxContainer

var _card_back_tex: Texture2D = preload(
	"res://assets/icons/card_back.svg"
)
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _count: int = 0

@onready var _stack: Control = $Stack
@onready var _count_label: RichTextLabel = $CountLabel


func _ready() -> void:
	_count_label.add_theme_font_override(
		"normal_font", _font_bold
	)
	_count_label.add_theme_font_size_override(
		"normal_font_size", UIHelpers.FONT_LABEL
	)
	_count_label.add_theme_color_override(
		"font_color", Color(0.9, 0.85, 0.7)
	)
	_update_display()


func update_count(count: int) -> void:
	_count = count
	_update_display()


func _update_display() -> void:
	if not is_inside_tree():
		return
	var icon_sz: int = int(UIHelpers.FONT_LABEL * 1.2)
	var card_path: String = UIHelpers.ENTITY_ICONS.get(
		"Draw", ""
	) as String
	var bbcode := "Draw  [img=%d]%s[/img] %d" % [
		icon_sz, card_path, _count,
	]
	UIHelpers.set_bbcode(_count_label, bbcode)
	for child in _stack.get_children():
		child.queue_free()
	var cards_to_show := mini(_count, 5)
	for i in range(cards_to_show):
		var tex_rect := TextureRect.new()
		tex_rect.texture = _card_back_tex
		tex_rect.custom_minimum_size = Vector2(
			UIHelpers.CARD_WIDTH, UIHelpers.CARD_HEIGHT
		)
		tex_rect.stretch_mode = TextureRect.STRETCH_SCALE
		var off := UIHelpers.STACK_OFFSET
		tex_rect.position = Vector2(i * off, -i * off)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_stack.add_child(tex_rect)
