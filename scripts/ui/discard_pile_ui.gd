extends VBoxContainer

var _font: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _cards: Array[CardData] = []

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
	_update_display()


func add_card(card: CardData) -> void:
	_cards.append(card)
	_update_display()


func clear_pile() -> void:
	_cards.clear()
	_update_display()


func update_count(count: int) -> void:
	if count == 0:
		_cards.clear()
	_update_display()


func _update_display() -> void:
	if not is_inside_tree():
		return
	var icon_sz: int = int(UIHelpers.FONT_UNIT_STAT * 1.2)
	var path: String = UIHelpers.ENTITY_ICONS.get(
		"Discard", ""
	) as String
	var num_sz: int = UIHelpers.FONT_STAT_NUM
	var bbcode := (
		"[center]Discard [img=%d]%s[/img]"
		+ " [font_size=%d]%d[/font_size][/center]"
	) % [icon_sz, path, num_sz, _cards.size()]
	UIHelpers.set_bbcode(_count_label, bbcode)
	for child in _stack.get_children():
		child.queue_free()
	var cards_to_show := mini(_cards.size(), 3)
	var start_idx := _cards.size() - cards_to_show
	for i in range(cards_to_show):
		var card: CardData = _cards[start_idx + i]
		var panel := _build_card_face(card)
		panel.modulate = Color(0.45, 0.45, 0.45, 1.0)
		var off := UIHelpers.STACK_OFFSET
		panel.position = Vector2(i * off, -i * off)
		_stack.add_child(panel)


func _build_card_face(card: CardData) -> Control:
	var cw := UIHelpers.CARD_WIDTH
	var ch := UIHelpers.CARD_HEIGHT
	var outer := Control.new()
	outer.custom_minimum_size = Vector2(cw, ch)
	outer.size = Vector2(cw, ch)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sections: Array[PanelContainer] = []
	CardFaceBuilder.build_face(outer, card, sections)
	return outer
