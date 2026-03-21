extends VBoxContainer

var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _parchment_tex: Texture2D = preload(
	"res://assets/textures/ui/parchment_256_grayscale.png"
)
var _cards: Array[CardData] = []

@onready var _stack: Control = $Stack
@onready var _count_label: Label = $CountLabel


func _ready() -> void:
	_count_label.add_theme_font_override("font", _font_bold)
	_count_label.add_theme_font_size_override("font_size", 11)
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
	_count_label.text = "Discard: %d" % _cards.size()
	for child in _stack.get_children():
		child.queue_free()
	var cards_to_show := mini(_cards.size(), 5)
	var start_idx := _cards.size() - cards_to_show
	for i in range(cards_to_show):
		var card: CardData = _cards[start_idx + i]
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(115, 165)
		panel.position = Vector2(i * 2, -i * 2)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxTexture.new()
		style.texture = _parchment_tex
		style.modulate_color = card.card_color
		style.content_margin_left = 4.0
		style.content_margin_right = 4.0
		style.content_margin_top = 4.0
		style.content_margin_bottom = 4.0
		panel.add_theme_stylebox_override("panel", style)
		var lbl := Label.new()
		lbl.text = card.card_name
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(lbl)
		_stack.add_child(panel)
