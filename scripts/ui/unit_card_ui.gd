class_name UnitCardUI
extends Control

const GLOW_PAD := 50

var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _card_w: int
var _card_h: int
var _draw_ctrl: Control
var _content_clip: Control
var _lines_container: VBoxContainer
var _sv: SubViewport
var _original_y: float = 0.0
var _showing: bool = false
var _current_unit: Node3D


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
	visible = false

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

	_content_clip = Control.new()
	_content_clip.clip_contents = true
	var clip_x: float = (
		float(total_w) - float(_card_w)
	) * 0.5
	var clip_y: float = (
		float(GLOW_PAD) + float(_card_h) * 0.9
		- float(_card_h)
	)
	_content_clip.position = Vector2(clip_x, clip_y)
	_content_clip.size = Vector2(
		float(_card_w), float(_card_h)
	)
	_content_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content_clip)

	_lines_container = VBoxContainer.new()
	_lines_container.position = Vector2(4, 8)
	_lines_container.size = Vector2(
		float(_card_w) - 8, float(_card_h) - 16
	)
	_lines_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_clip.add_child(_lines_container)


func show_unit(unit: Node3D) -> void:
	if unit == _current_unit and _showing:
		return
	if _showing:
		_slide_out_then_in(unit)
	else:
		_current_unit = unit
		_populate(unit)
		_slide_in()


func hide_unit() -> void:
	if not _showing:
		return
	_current_unit = null
	_slide_out()


func slide_out_for_gallery() -> void:
	if not _showing:
		return
	var tw := create_tween()
	tw.tween_property(
		self, "position:y",
		-size.y - 20.0, 0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func slide_in_from_gallery() -> void:
	if not _showing:
		return
	var tw := create_tween()
	tw.tween_property(
		self, "position:y",
		_original_y, 0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func store_original_pos() -> void:
	_original_y = position.y


func _populate(unit: Node3D) -> void:
	for child in _lines_container.get_children():
		child.queue_free()
	if unit == null:
		return
	_add_line(
		UIHelpers.icon_value("HP", "%d/%d" % [
			unit.health, unit.max_health,
		])
	)
	_add_line(
		UIHelpers.icon_value("Attack", str(unit.attack))
	)
	var eff_def: int = unit.defense
	if unit.state:
		eff_def += unit.state.defense_modifier
	_add_line(
		UIHelpers.icon_value("Defense", str(eff_def))
	)


func _add_line(bbcode: String) -> void:
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.add_theme_font_override("normal_font", _font_bold)
	lbl.add_theme_font_size_override(
		"normal_font_size", UIHelpers.s(10)
	)
	lbl.add_theme_color_override(
		"default_color", Color(0.95, 0.88, 0.7)
	)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIHelpers.set_bbcode(lbl, "[center]" + bbcode + "[/center]")
	_lines_container.add_child(lbl)


func _slide_in() -> void:
	visible = true
	_showing = true
	position.y = -size.y - 20.0
	var tw := create_tween()
	tw.tween_property(
		self, "position:y", _original_y, 0.3,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _slide_out() -> void:
	_showing = false
	var tw := create_tween()
	tw.tween_property(
		self, "position:y",
		-size.y - 20.0, 0.25,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		visible = false
	)


func _slide_out_then_in(new_unit: Node3D) -> void:
	var tw := create_tween()
	tw.tween_property(
		self, "position:y",
		-size.y - 20.0, 0.2,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		_current_unit = new_unit
		_populate(new_unit)
	)
	tw.tween_property(
		self, "position:y", _original_y, 0.25,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


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
		border_pts.append(Vector2(
			pivot_x + c.x, pivot_y + c.y
		))
	for j in range(border_pts.size()):
		var k: int = (j + 1) % border_pts.size()
		_draw_ctrl.draw_line(
			border_pts[j], border_pts[k],
			Color(0.65, 0.5, 0.2), 6.0,
		)
