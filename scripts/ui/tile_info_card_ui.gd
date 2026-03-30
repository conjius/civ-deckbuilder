extends Control

const GLOW_PAD := 50
const ANIM_DUR := 0.2

var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _card_w: int
var _card_h: int
var _draw_ctrl: Control
var _content_clip: Control
var _title_label: Label
var _yield_container: VBoxContainer
var _original_x: float = 0.0
var _sv: SubViewport
var _current_terrain_name: String = ""


func _ready() -> void:
	_card_w = int(
		float(UIHelpers.CARD_WIDTH) * CardPileUI.ICON_CARD_SCALE
	)
	_card_h = int(
		float(UIHelpers.CARD_HEIGHT) * CardPileUI.ICON_CARD_SCALE
	)
	var total_w: int = _card_w + GLOW_PAD * 2 + 100
	var total_h: int = _card_h + GLOW_PAD * 2
	custom_minimum_size = Vector2(total_w, total_h)
	size = Vector2(total_w, total_h)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var svc := SubViewportContainer.new()
	svc.size = Vector2(total_w, total_h)
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(svc)
	_sv = SubViewport.new()
	_sv.size = Vector2i(total_w, total_h)
	_sv.transparent_bg = true
	svc.add_child(_sv)

	_draw_ctrl = Control.new()
	_draw_ctrl.size = Vector2(total_w, total_h)
	_draw_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sv.add_child(_draw_ctrl)
	_draw_ctrl.draw.connect(_draw_card)
	_draw_ctrl.queue_redraw()

	# Content area clipped to card bounds
	_content_clip = Control.new()
	_content_clip.clip_contents = true
	var clip_x: float = (float(total_w) - float(_card_w)) * 0.5
	var clip_y: float = float(GLOW_PAD) + float(_card_h) * 0.9 - float(_card_h)
	_content_clip.position = Vector2(clip_x, clip_y)
	_content_clip.size = Vector2(float(_card_w), float(_card_h))
	_content_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content_clip)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", _font_bold)
	_title_label.add_theme_font_size_override(
		"font_size", UIHelpers.s(11)
	)
	_title_label.add_theme_color_override(
		"font_color", Color(0.95, 0.88, 0.7)
	)
	_title_label.position = Vector2(0, 8)
	_title_label.size = Vector2(float(_card_w), UIHelpers.sf(16.0))
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_clip.add_child(_title_label)

	_yield_container = VBoxContainer.new()
	_yield_container.position = Vector2(0, UIHelpers.sf(22.0))
	_yield_container.size = Vector2(
		float(_card_w), float(_card_h) - UIHelpers.sf(22.0)
	)
	_yield_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_yield_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_clip.add_child(_yield_container)

	# Card title below
	var card_title := Label.new()
	card_title.text = "Terrain"
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.add_theme_font_override("font", _font_bold)
	card_title.add_theme_font_size_override(
		"font_size", UIHelpers.s(10)
	)
	card_title.add_theme_color_override(
		"font_color", Color(0.85, 0.78, 0.65)
	)
	card_title.position = Vector2(0, size.y - float(GLOW_PAD) + 3.0)
	card_title.size = Vector2(float(total_w), UIHelpers.sf(14.0))
	card_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_title)


func update_info(terrain_name: String, yields: Array[String]) -> void:
	if terrain_name == _current_terrain_name:
		return
	_current_terrain_name = terrain_name

	if terrain_name == "":
		_title_label.text = ""
		for child in _yield_container.get_children():
			child.queue_free()
		return

	_title_label.text = terrain_name
	if yields.is_empty():
		_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_title_label.position.y = 0.0
		_title_label.size.y = float(_card_h)
	else:
		_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_title_label.position.y = 8.0
		_title_label.size.y = UIHelpers.sf(16.0)

	for child in _yield_container.get_children():
		child.queue_free()

	for y_text in yields:
		var lbl := RichTextLabel.new()
		lbl.bbcode_enabled = true
		lbl.fit_content = true
		lbl.add_theme_font_override("normal_font", _font_bold)
		lbl.add_theme_font_size_override(
			"normal_font_size", UIHelpers.s(9)
		)
		lbl.add_theme_color_override(
			"default_color", Color(0.95, 0.88, 0.7)
		)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIHelpers.set_bbcode(lbl, "[center]" + y_text + "[/center]")
		_yield_container.add_child(lbl)


func slide_out_left() -> void:
	var tw := create_tween()
	tw.tween_property(
		self, "position:x",
		-size.x - 50.0, 0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func slide_in_from_left() -> void:
	var tw := create_tween()
	tw.tween_property(
		self, "position:x",
		_original_x, 0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func store_original_pos() -> void:
	_original_x = position.x


func _draw_card() -> void:
	var ptex: Texture2D = load(
		UIHelpers.PARCHMENT_PATH
	) as Texture2D
	var cw := float(_card_w)
	var ch := float(_card_h)
	var card_r := float(
		UIHelpers.CARD_CORNER_RADIUS
	) * CardPileUI.ICON_CARD_SCALE
	var pivot_x := size.x * 0.5
	var pivot_y := float(GLOW_PAD) + float(_card_h) * 0.9
	var raw := UIHelpers._rounded_rect_points(
		-cw * 0.5, -ch, cw, ch, card_r, 6,
	)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var zoom := 1.5
	for p_idx in range(raw.size()):
		var c: Vector2 = raw[p_idx]
		pts.append(Vector2(pivot_x + c.x, pivot_y + c.y))
		uvs.append(Vector2(
			(0.5 - 0.5 / zoom)
				+ ((c.x + cw * 0.5) / cw) / zoom,
			(0.5 - 0.5 / zoom)
				+ ((c.y + ch) / ch) / zoom,
		))
	var tint := Color(0.35, 0.25, 0.15, 1.0)
	if ptex:
		var colors := PackedColorArray()
		colors.append(tint)
		_draw_ctrl.draw_polygon(pts, colors, uvs, ptex)
	else:
		_draw_ctrl.draw_colored_polygon(pts, tint)
	var border_pts := PackedVector2Array()
	for b_idx in range(raw.size()):
		var c: Vector2 = raw[b_idx]
		border_pts.append(Vector2(pivot_x + c.x, pivot_y + c.y))
	for j in range(border_pts.size()):
		var k: int = (j + 1) % border_pts.size()
		_draw_ctrl.draw_line(
			border_pts[j], border_pts[k],
			Color(0.65, 0.5, 0.2), 6.0,
		)
