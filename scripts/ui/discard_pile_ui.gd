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
		"res://assets/icons/move_64.svg"
	),
	CardData.CardType.SCOUT: preload(
		"res://assets/icons/scout_64.svg"
	),
	CardData.CardType.GATHER: preload(
		"res://assets/icons/gather_64.svg"
	),
	CardData.CardType.SETTLE: preload(
		"res://assets/icons/settle_64.svg"
	),
}
var _cards: Array[CardData] = []

@onready var _stack: Control = $Stack
@onready var _count_label: Label = $CountLabel


func _ready() -> void:
	_count_label.add_theme_font_override("font", _font_bold)
	_count_label.add_theme_font_size_override(
		"font_size", UIHelpers.FONT_LABEL
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
	_count_label.text = "Discard: %d" % _cards.size()
	for child in _stack.get_children():
		child.queue_free()
	var cards_to_show := mini(_cards.size(), 3)
	var start_idx := _cards.size() - cards_to_show
	for i in range(cards_to_show):
		var card: CardData = _cards[start_idx + i]
		var panel := _build_card_face(card)
		var off := UIHelpers.STACK_OFFSET
		panel.position = Vector2(i * off, -i * off)
		_stack.add_child(panel)


func _build_card_face(card: CardData) -> PanelContainer:
	var base: Color = card.card_color
	var dark: Color = base.darkened(0.35)
	var light: Color = base.lightened(0.2)
	var cw := UIHelpers.CARD_WIDTH
	var ch := UIHelpers.CARD_HEIGHT
	var b := UIHelpers.CARD_BORDER
	var iw := cw - b * 2
	var gap := UIHelpers.SECTION_GAP

	var outer := Control.new()
	outer.custom_minimum_size = Vector2(cw, ch)
	outer.size = Vector2(cw, ch)
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := Panel.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(cw, ch)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.08, 0.05)
	bg_style.border_color = Color(0.55, 0.4, 0.15)
	bg_style.set_border_width_all(b)
	bg_style.set_corner_radius_all(UIHelpers.CARD_CORNER_RADIUS)
	bg.add_theme_stylebox_override("panel", bg_style)
	outer.add_child(bg)

	var mh := UIHelpers.SECTION_MARGIN_H
	var mv := UIHelpers.SECTION_MARGIN_V
	var y := UIHelpers.SECTION_TOP

	var hh := UIHelpers.HEADER_HEIGHT
	var header := _add_section(outer, dark, b, y, iw, hh)
	var nl := _add_label_in(
		header, card.card_name, _font_bold, Color.WHITE,
		UIHelpers.fit_font_size(
			card.card_name, iw - mh * 2, hh - mv * 2,
			UIHelpers.FONT_TITLE, UIHelpers.s(9),
		),
	)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	y += hh + gap

	var ah := UIHelpers.AVATAR_HEIGHT
	var avatar_sec := _add_section(
		outer, light, b, y, iw, ah
	)
	var icon_tex: Texture2D = null
	if card.icon_path != "":
		icon_tex = load(card.icon_path) as Texture2D
	if icon_tex == null:
		icon_tex = _card_icon_textures.get(
			card.card_type, null
		) as Texture2D
	if icon_tex:
		var tex_rect := TextureRect.new()
		tex_rect.texture = icon_tex
		tex_rect.layout_mode = 1
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_sec.add_child(tex_rect)
	y += ah + gap

	var dh := UIHelpers.DESC_HEIGHT
	var desc_sec := _add_section(outer, base, b, y, iw, dh)
	var dl := _add_label_in(
		desc_sec, card.description, _font_regular,
		Color.WHITE,
		UIHelpers.fit_font_size(
			card.description, iw - mh * 2, dh - mv * 2,
			UIHelpers.FONT_BODY, UIHelpers.s(7),
		),
	)
	dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD
	y += dh + gap

	var fh := UIHelpers.FOOTER_HEIGHT
	var footer := _add_section(outer, dark, b, y, iw, fh)
	var ftxt := "Range %d" % card.range_value
	var fl := _add_label_in(
		footer, ftxt, _font_regular,
		Color(1, 1, 1, 0.8),
		UIHelpers.fit_font_size(
			ftxt, iw - mh * 2, fh - mv * 2,
			UIHelpers.FONT_BODY, UIHelpers.s(8),
		),
	)
	fl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	return outer


func _add_section(
	parent: Control, color: Color,
	x: int, y: int, w: int, h: int,
) -> PanelContainer:
	var sec := PanelContainer.new()
	sec.position = Vector2(x, y)
	sec.size = Vector2(w, h)
	sec.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sec.clip_contents = true
	var style := StyleBoxTexture.new()
	style.texture = _parchment_tex
	style.modulate_color = color
	sec.add_theme_stylebox_override("panel", style)
	parent.add_child(sec)
	return sec


func _add_label_in(
	section: PanelContainer, text: String, font: Font,
	color: Color, font_size: int,
) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.layout_mode = 1
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section.add_child(lbl)
	return lbl
