class_name DarkCardUI
extends Control

static var glow_pad: int = int(27.0 * UIHelpers.UI_SCALE)
static var extra_w: int = int(54.0 * UIHelpers.UI_SCALE)
static var border_w: float = 3.0 * UIHelpers.UI_SCALE

var card_w: int
var card_h: int
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _draw_ctrl: Control
var _sv: SubViewport
var _content_clip: Control


func setup_card() -> void:
	card_w = int(
		float(UIHelpers.CARD_WIDTH) * CardPileUI.ICON_CARD_SCALE
	)
	card_h = int(
		float(UIHelpers.CARD_HEIGHT) * CardPileUI.ICON_CARD_SCALE
	)
	var total_w: int = card_w + glow_pad * 2 + extra_w
	var total_h: int = card_h + glow_pad * 2
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

	_content_clip = Control.new()
	_content_clip.clip_contents = true
	_content_clip.position = Vector2(
		visual_card_left_in_ctrl(),
		visual_card_top_in_ctrl(),
	)
	_content_clip.size = Vector2(float(card_w), float(card_h))
	_content_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content_clip)


func visual_card_left_in_ctrl() -> float:
	return (float(size.x) - float(card_w)) * 0.5


func visual_card_top_in_ctrl() -> float:
	return float(glow_pad) + float(card_h) * 0.9 - float(card_h)


func pivot_x() -> float:
	return size.x * 0.5


func pivot_y() -> float:
	return float(glow_pad) + float(card_h) * 0.9


func _draw_card() -> void:
	var ptex: Texture2D = load(
		UIHelpers.PARCHMENT_PATH
	) as Texture2D
	var cw := float(card_w)
	var ch := float(card_h)
	var card_r := float(
		UIHelpers.CARD_CORNER_RADIUS
	) * CardPileUI.ICON_CARD_SCALE
	var px := pivot_x()
	var py := pivot_y()
	var raw := UIHelpers._rounded_rect_points(
		-cw * 0.5, -ch, cw, ch, card_r, 6,
	)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var zoom := 1.5
	for p_idx in range(raw.size()):
		var c: Vector2 = raw[p_idx]
		pts.append(Vector2(px + c.x, py + c.y))
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
		border_pts.append(Vector2(px + c.x, py + c.y))
	for j in range(border_pts.size()):
		var k: int = (j + 1) % border_pts.size()
		_draw_ctrl.draw_line(
			border_pts[j], border_pts[k],
			Color(0.65, 0.5, 0.2), border_w, true,
		)
