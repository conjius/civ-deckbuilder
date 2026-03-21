extends VBoxContainer

var _font: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _count: int = 0

@onready var _stack: Control = $Stack
@onready var _count_label: RichTextLabel = $CountLabel


func _ready() -> void:
	_count_label.add_theme_font_override(
		"normal_font", _font
	)
	_count_label.add_theme_font_size_override(
		"normal_font_size", UIHelpers.FONT_UNIT_STAT
	)
	_count_label.add_theme_color_override(
		"font_color", Color(0.9, 0.85, 0.7)
	)
	update_count(0)


func update_count(count: int) -> void:
	_count = count
	_update_display()


func _update_display() -> void:
	if not is_inside_tree():
		return
	var icon_sz: int = int(UIHelpers.FONT_UNIT_STAT * 1.2)
	var path: String = UIHelpers.ENTITY_ICONS.get(
		"Draw", ""
	) as String
	var num_sz: int = UIHelpers.FONT_STAT_NUM
	var bbcode := "[center]Draw [img=%d]%s[/img] [font_size=%d]%d[/font_size][/center]" % [
		icon_sz, path, num_sz, _count,
	]
	UIHelpers.set_bbcode(_count_label, bbcode)
	for child in _stack.get_children():
		child.queue_free()
	var cards_to_show := mini(_count, 5)
	for i in range(cards_to_show):
		var card_back := UIHelpers.create_card_back()
		var off := UIHelpers.STACK_OFFSET
		card_back.position = Vector2(i * off, -i * off)
		_stack.add_child(card_back)
