class_name CardFaceBuilder
extends RefCounted

static var _font_bold: Font = preload(
	"res://assets/fonts/Cinzel-Bold.ttf"
)
static var _card_icon_textures: Dictionary = {
	CardData.CardType.MOVE: preload(
		"res://assets/icons/explorer_unit.svg"
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


static func get_card_icon(card: CardData) -> Texture2D:
	var tex: Texture2D = null
	if card.icon_path != "":
		tex = load(card.icon_path) as Texture2D
	if tex == null:
		tex = _card_icon_textures.get(
			card.card_type, null
		) as Texture2D
	return tex


static func build_face(
	parent: Control, card: CardData,
	sections_out: Array[PanelContainer] = [],
) -> Dictionary:
	var cw := UIHelpers.CARD_WIDTH
	var ch := UIHelpers.CARD_HEIGHT
	var base: Color = card.card_color
	var dark: Color = base.darkened(0.35)
	var light: Color = base.lightened(0.2)

	var bg := Panel.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(cw, ch)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_theme_stylebox_override(
		"panel", UIHelpers.create_panel_style()
	)
	parent.add_child(bg)
	UIHelpers.apply_parchment_bg(bg, false)

	var container := Control.new()
	container.position = Vector2(
		UIHelpers.CONTAINER_X, UIHelpers.CONTAINER_Y
	)
	container.size = Vector2(
		UIHelpers.CONTAINER_W, UIHelpers.CONTAINER_H
	)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.clip_contents = true
	parent.add_child(container)

	var iw := UIHelpers.CONTAINER_W
	var gap := UIHelpers.SECTION_GAP
	var mh := UIHelpers.SECTION_MARGIN_H
	var mv := UIHelpers.SECTION_MARGIN_V
	var cont_r := maxf(
		float(UIHelpers.CARD_CORNER_RADIUS)
		- float(UIHelpers.CONTAINER_X), 0.0
	)
	var y := 0

	var hh := UIHelpers.HEADER_HEIGHT
	var header := _add_section(
		container, dark, 0, y, iw, hh,
		sections_out, cont_r
	)
	var name_lbl := _add_label_in(
		header, card.card_name, _font_bold, Color.BLACK,
		UIHelpers.fit_font_size(
			card.card_name, iw - mh * 2, hh - mv * 2,
			UIHelpers.FONT_TITLE, UIHelpers.s(9),
		),
	)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	y += hh + gap

	var ah := UIHelpers.AVATAR_HEIGHT
	var avatar_sec := _add_section(
		container, light, 0, y, iw, ah, sections_out
	)
	_add_avatar(avatar_sec, card)
	y += ah + gap

	var dh := UIHelpers.DESC_HEIGHT
	var desc_sec := _add_section(
		container, base, 0, y, iw, dh, sections_out
	)
	var desc_lbl := _add_label_in(
		desc_sec, card.description, _font_bold,
		Color.BLACK,
		UIHelpers.fit_font_size(
			card.description, iw - mh * 2, dh - mv * 2,
			UIHelpers.FONT_BODY, UIHelpers.s(7),
		),
	)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	y += dh + gap

	var fh := UIHelpers.FOOTER_HEIGHT
	var footer_sec := _add_section(
		container, dark, 0, y, iw, fh,
		sections_out, -1.0, cont_r
	)
	var range_rtl := _build_range_label(card)
	footer_sec.add_child(range_rtl)

	return {
		"bg": bg,
		"desc_section": desc_sec,
		"desc_label": desc_lbl,
		"footer_section": footer_sec,
		"footer_label": range_rtl,
	}


static func _build_range_label(card: CardData) -> Control:
	if card.card_type == CardData.CardType.RESOURCE:
		return _build_resource_footer(card)
	if card.card_type == CardData.CardType.ATTACK:
		return _build_attack_footer(card)
	if card.card_type == CardData.CardType.DEFENSE:
		return _build_defense_footer(card)
	if card.range_value == 0:
		var lbl := Label.new()
		lbl.text = "Current tile"
		lbl.layout_mode = 1
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", _font_bold)
		lbl.add_theme_font_size_override(
			"font_size", UIHelpers.FONT_UNIT_STAT
		)
		lbl.add_theme_color_override("font_color", Color.BLACK)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return lbl
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.layout_mode = 1
	rtl.set_anchors_preset(Control.PRESET_FULL_RECT)
	rtl.add_theme_font_override("normal_font", _font_bold)
	rtl.add_theme_color_override("default_color", Color.BLACK)
	rtl.add_theme_font_size_override(
		"normal_font_size", UIHelpers.FONT_UNIT_STAT
	)
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := "[center]" + UIHelpers.icon_value(
		"Range", str(card.range_value)
	) + "[/center]"
	UIHelpers.set_bbcode(rtl, text)
	return rtl


static func _build_attack_footer(
	card: CardData,
) -> Control:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.layout_mode = 1
	rtl.set_anchors_preset(Control.PRESET_FULL_RECT)
	rtl.add_theme_font_override("normal_font", _font_bold)
	rtl.add_theme_color_override("default_color", Color.BLACK)
	rtl.add_theme_font_size_override(
		"normal_font_size", UIHelpers.FONT_UNIT_STAT
	)
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := "[center]" + UIHelpers.icon_value(
		"Attack", str(card.attack_damage)
	) + "    " + UIHelpers.icon_value(
		"Range", str(card.range_value)
	) + "[/center]"
	UIHelpers.set_bbcode(rtl, text)
	return rtl


static func _build_defense_footer(
	card: CardData,
) -> Control:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.layout_mode = 1
	rtl.set_anchors_preset(Control.PRESET_FULL_RECT)
	rtl.add_theme_font_override("normal_font", _font_bold)
	rtl.add_theme_color_override("default_color", Color.BLACK)
	rtl.add_theme_font_size_override(
		"normal_font_size", UIHelpers.FONT_UNIT_STAT
	)
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := "[center]" + UIHelpers.icon_value(
		"Defense", "+" + str(card.defense_bonus)
	) + "[/center]"
	UIHelpers.set_bbcode(rtl, text)
	return rtl


static func _build_resource_footer(
	card: CardData,
) -> Control:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.layout_mode = 1
	rtl.set_anchors_preset(Control.PRESET_FULL_RECT)
	rtl.add_theme_font_override("normal_font", _font_bold)
	rtl.add_theme_color_override("default_color", Color.BLACK)
	rtl.add_theme_font_size_override(
		"normal_font_size", UIHelpers.FONT_UNIT_STAT
	)
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_name: String
	if card.resource_type == CardData.ResourceType.FOOD:
		icon_name = "Food"
	else:
		icon_name = "Materials"
	var text := "[center]" + UIHelpers.icon_value(
		icon_name, str(card.resource_value)
	) + "[/center]"
	UIHelpers.set_bbcode(rtl, text)
	return rtl


static func _add_section(
	parent: Control, color: Color,
	x: int, y: int, w: int, h: int,
	sections_out: Array[PanelContainer],
	top_r: float = -1.0, bottom_r: float = -1.0,
) -> PanelContainer:
	var sec := PanelContainer.new()
	sec.position = Vector2(x, y)
	sec.size = Vector2(w, h)
	sec.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sec.clip_contents = true
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.content_margin_left = UIHelpers.SECTION_MARGIN_H
	style.content_margin_right = UIHelpers.SECTION_MARGIN_H
	style.content_margin_top = UIHelpers.SECTION_MARGIN_V
	style.content_margin_bottom = UIHelpers.SECTION_MARGIN_V
	sec.add_theme_stylebox_override("panel", style)
	parent.add_child(sec)
	UIHelpers.apply_section_parchment(
		sec, color, top_r, bottom_r
	)
	sections_out.append(sec)
	return sec


static func _add_label_in(
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


static func _add_avatar(
	section: PanelContainer, card: CardData,
) -> void:
	var icon_tex := get_card_icon(card)
	if icon_tex:
		var tex_rect := TextureRect.new()
		tex_rect.texture = icon_tex
		tex_rect.stretch_mode = (
			TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sc := card.icon_scale * UIHelpers.ICON_SCALE
		var sz := section.size
		var inset := sz * (1.0 - sc) * 0.5
		tex_rect.position = inset
		tex_rect.size = sz * sc
		tex_rect.material = UIHelpers.create_icon_shadow_shader()
		section.add_child(tex_rect)
