extends VBoxContainer

var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _font_regular: Font = preload(
	"res://assets/fonts/Cinzel-Regular.ttf"
)
var _parchment_tex: Texture2D = preload(
	"res://assets/textures/ui/parchment_256_grayscale.png"
)
var _card_icon_textures: Dictionary = {
	CardData.CardType.MOVE: preload(
		"res://assets/icons/boot_64.png"
	),
	CardData.CardType.SCOUT: preload(
		"res://assets/icons/binoculars_64.svg"
	),
	CardData.CardType.GATHER: preload(
		"res://assets/icons/mining_64.png"
	),
}
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
	var cards_to_show := mini(_cards.size(), 3)
	var start_idx := _cards.size() - cards_to_show
	for i in range(cards_to_show):
		var card: CardData = _cards[start_idx + i]
		var panel := _build_card_face(card)
		panel.position = Vector2(i * 2, -i * 2)
		_stack.add_child(panel)


func _build_card_face(card: CardData) -> PanelContainer:
	var base: Color = card.card_color
	var dark: Color = base.darkened(0.35)
	var light: Color = base.lightened(0.2)

	var cw := UIHelpers.CARD_WIDTH
	var ch := UIHelpers.CARD_HEIGHT
	var cw_inner := UIHelpers.CONTENT_WIDTH

	var outer := PanelContainer.new()
	outer.custom_minimum_size = Vector2(cw, ch)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.clip_contents = true
	var outer_style := StyleBoxFlat.new()
	outer_style.bg_color = Color(0.12, 0.08, 0.05)
	outer_style.border_color = Color(0.55, 0.4, 0.15)
	outer_style.border_width_left = 2
	outer_style.border_width_right = 2
	outer_style.border_width_top = 2
	outer_style.border_width_bottom = 2
	outer_style.corner_radius_top_left = 6
	outer_style.corner_radius_top_right = 6
	outer_style.corner_radius_bottom_left = 6
	outer_style.corner_radius_bottom_right = 6
	outer.add_theme_stylebox_override("panel", outer_style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override(
		"separation", UIHelpers.SECTION_GAP
	)
	outer.add_child(vbox)

	# Header
	var hh := UIHelpers.HEADER_HEIGHT
	var header := _make_section(dark, Vector2(0, hh))
	var name_lbl := Label.new()
	name_lbl.text = card.card_name
	name_lbl.clip_text = true
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_override("font", _font_bold)
	var ts := UIHelpers.fit_font_size(
		card.card_name, cw_inner, hh - 8, 13, 9,
	)
	name_lbl.add_theme_font_size_override("font_size", ts)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(name_lbl)
	vbox.add_child(header)

	# Avatar
	var ah := UIHelpers.AVATAR_HEIGHT
	var avatar := _make_section(light, Vector2(0, ah))
	var icon_tex: Texture2D = _card_icon_textures.get(
		card.card_type, null
	) as Texture2D
	if icon_tex:
		var tex_rect := TextureRect.new()
		tex_rect.texture = icon_tex
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar.add_child(tex_rect)
	vbox.add_child(avatar)

	# Description
	var dh := UIHelpers.DESC_HEIGHT
	var desc := _make_section(base, Vector2(0, dh))
	var desc_lbl := Label.new()
	desc_lbl.text = card.description
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.add_theme_font_override("font", _font_regular)
	var ds := UIHelpers.fit_font_size(
		card.description, cw_inner, dh - 8, 11, 7,
	)
	desc_lbl.add_theme_font_size_override("font_size", ds)
	desc_lbl.add_theme_color_override("font_color", Color.WHITE)
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.add_child(desc_lbl)
	vbox.add_child(desc)

	# Footer
	var fh := UIHelpers.FOOTER_HEIGHT
	var footer := _make_section(dark, Vector2(0, fh))
	var footer_lbl := Label.new()
	var footer_text := "Range %d" % card.range_value
	footer_lbl.text = footer_text
	footer_lbl.clip_text = true
	footer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer_lbl.add_theme_font_override("font", _font_regular)
	var fs := UIHelpers.fit_font_size(
		footer_text, cw_inner, fh - 8, 11, 8,
	)
	footer_lbl.add_theme_font_size_override("font_size", fs)
	footer_lbl.add_theme_color_override(
		"font_color", Color(1, 1, 1, 0.8)
	)
	footer_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(footer_lbl)
	vbox.add_child(footer)

	return outer


func _make_section(
	color: Color, min_size: Vector2,
) -> PanelContainer:
	var section := PanelContainer.new()
	section.custom_minimum_size = min_size
	section.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxTexture.new()
	style.texture = _parchment_tex
	style.modulate_color = color
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	section.add_theme_stylebox_override("panel", style)
	return section
