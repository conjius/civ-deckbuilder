class_name UIHelpers
extends RefCounted

const UI_SCALE: float = 3.69

const CARD_WIDTH: int = int(115 * UI_SCALE)
const CARD_HEIGHT: int = int(165 * UI_SCALE)
const CARD_BORDER: int = int(2 * UI_SCALE)
const CARD_PADDING: int = int(2 * UI_SCALE)
const SECTION_TOP: int = CARD_BORDER + CARD_PADDING
const SECTION_GAP: int = int(2 * UI_SCALE)
const CARD_CORNER_RADIUS: int = int(22 * UI_SCALE)
const SECTION_CORNER_RADIUS: int = int(4 * UI_SCALE)
const SECTION_MARGIN_H: int = int(6 * UI_SCALE)
const SECTION_MARGIN_V: int = int(4 * UI_SCALE)
const CONTENT_WIDTH: int = CARD_WIDTH - SECTION_MARGIN_H * 2

const FONT_TITLE: int = int(13 * UI_SCALE)
const FONT_BODY: int = int(11 * UI_SCALE)
const FONT_SMALL: int = int(10 * UI_SCALE)
const FONT_LABEL: int = int(11 * UI_SCALE)
const FONT_TURN: int = int(14 * UI_SCALE)
const FONT_INFO: int = int(11 * UI_SCALE)
const FONT_STAT_NUM: int = int(FONT_LABEL * 1.2)
const FONT_UNIT_NAME: int = int(10 * UI_SCALE)
const FONT_UNIT_STAT: int = int(8 * UI_SCALE)

const MARGIN: int = int(10 * UI_SCALE)
const SPACING: int = int(8 * UI_SCALE)
const SPACING_LARGE: int = int(12 * UI_SCALE)
const SPACING_SMALL: int = int(6 * UI_SCALE)

const PANEL_MARGIN_H: int = int(10 * UI_SCALE)
const PANEL_MARGIN_V: int = int(8 * UI_SCALE)
const AVATAR_SIZE: int = int(48 * UI_SCALE)
const BUTTON_SIZE: int = int(40 * UI_SCALE)
const PILE_WIDTH: int = int(120 * UI_SCALE)
const BOTTOM_BAR_HEIGHT: int = int(190 * UI_SCALE)
const LEFT_PANEL_WIDTH: int = int(180 * UI_SCALE)
const LEFT_PANEL_HEIGHT: int = int(200 * UI_SCALE)
const RESOURCE_WIDTH: int = int(150 * UI_SCALE)
const RESOURCE_HEIGHT: int = int(60 * UI_SCALE)
const STACK_OFFSET: int = int(2 * UI_SCALE)

const SETTLEMENT_FONT_SIZE: int = int(14.5 * UI_SCALE)
const SETTLEMENT_OUTLINE: int = int(4 * UI_SCALE)

const CARD_OVERLAP: int = int(15 * UI_SCALE)
const HAND_HIDDEN_Y: float = 50.0
const HAND_DEFAULT_SCALE: Vector2 = Vector2(1.0, 1.0)
const HAND_FOCUS_SCALE: Vector2 = Vector2(1.4, 1.4)
const HAND_TWEEN_DURATION: float = 0.18
const HAND_FAN_ANGLE: float = 8.0

const CONTAINER_SCALE: float = 0.91
const ICON_SCALE: float = 1.274
const _CARD_INNER_W: int = CARD_WIDTH - CARD_BORDER * 2
const _CARD_INNER_H: int = (
	CARD_HEIGHT - CARD_BORDER * 2 - CARD_PADDING * 2
)
const CONTAINER_W: int = int(_CARD_INNER_W * CONTAINER_SCALE)
const CONTAINER_H: int = int(_CARD_INNER_H * CONTAINER_SCALE) + 8
@warning_ignore("integer_division")
const CONTAINER_X: int = CARD_BORDER + (_CARD_INNER_W - CONTAINER_W) / 2
@warning_ignore("integer_division")
const CONTAINER_Y: int = (
	CARD_BORDER + CARD_PADDING
	+ (_CARD_INNER_H - CONTAINER_H) / 2
)
const HEADER_HEIGHT: int = int(CONTAINER_H * 0.17)
const AVATAR_HEIGHT: int = int(CONTAINER_H * 0.34)
const FOOTER_HEIGHT: int = int(CONTAINER_H * 0.19)
const DESC_HEIGHT: int = (
	CONTAINER_H
	- HEADER_HEIGHT
	- AVATAR_HEIGHT
	- FOOTER_HEIGHT
	- SECTION_GAP * 3
)


const PARCHMENT_OPACITY: float = 0.9
const PARCHMENT_PATH: String = (
	"res://assets/textures/ui/parchment_256_grayscale.png"
)

const ENTITY_ICONS: Dictionary = {
	"Materials": "res://assets/icons/entities/materials.svg",
	"Food": "res://assets/icons/entities/food.svg",
	"Range": "res://assets/icons/entities/range.svg",
	"HP": "res://assets/icons/entities/hp.svg",
	"Attack": "res://assets/icons/entities/attack.svg",
	"Defense": "res://assets/icons/entities/defense.svg",
	"Turn": "res://assets/icons/entities/turn.svg",
	"Draw": "res://assets/icons/entities/card.svg",
	"Discard": "res://assets/icons/entities/card.svg",
	"Tile": "res://assets/icons/entities/hex.svg",
}

const CURSOR_SIZE: int = 32
const DRAG_CURSOR_SIZE: int = 96


static func set_default_cursor() -> void:
	var img := _create_cursor_image()
	var tex := ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(
		tex, Input.CURSOR_ARROW, Vector2(1, 1)
	)


static func _create_cursor_image() -> Image:
	var sz := CURSOR_SIZE
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var fill := Color(0.83, 0.72, 0.47)
	var outline := Color(0.23, 0.14, 0.06)
	var shadow := Color(0, 0, 0, 0.35)
	# Arrow shape: tip at (3,1), left edge, notch, right edge
	var pts: Array[Vector2] = [
		Vector2(3, 1), Vector2(3, 22), Vector2(8, 17),
		Vector2(13, 27), Vector2(16, 25.5), Vector2(11, 16),
		Vector2(18, 16),
	]
	# Draw shadow offset
	_fill_polygon(img, pts, shadow, Vector2(1.5, 1.5))
	# Draw outline (slightly expanded)
	for off_x in [-1.0, 0.0, 1.0]:
		for off_y in [-1.0, 0.0, 1.0]:
			if off_x != 0.0 or off_y != 0.0:
				_fill_polygon(
					img, pts, outline,
					Vector2(off_x, off_y)
				)
	# Draw fill
	_fill_polygon(img, pts, fill)
	return img


static func _fill_polygon(
	img: Image, pts: Array[Vector2],
	color: Color, offset: Vector2 = Vector2.ZERO,
) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var p := Vector2(float(x), float(y)) - offset
			if _point_in_polygon(p, pts):
				var existing := img.get_pixel(x, y)
				if color.a >= 1.0 or existing.a == 0.0:
					img.set_pixel(x, y, color)
				else:
					var blended := existing.blend(color)
					img.set_pixel(x, y, blended)


static func _point_in_polygon(
	point: Vector2, polygon: Array[Vector2],
) -> bool:
	var inside := false
	var n := polygon.size()
	var j := n - 1
	for i in n:
		var pi := polygon[i]
		var pj := polygon[j]
		if (
			(pi.y > point.y) != (pj.y > point.y)
			and point.x < (
				(pj.x - pi.x) * (point.y - pi.y)
				/ (pj.y - pi.y) + pi.x
			)
		):
			inside = not inside
		j = i
	return inside


static func make_drag_cursor_tex(
	icon_tex: Texture2D, card_color: Color,
) -> ImageTexture:
	if icon_tex == null:
		return null
	var src_img := icon_tex.get_image()
	if src_img == null:
		src_img = Image.create(
			DRAG_CURSOR_SIZE, DRAG_CURSOR_SIZE,
			false, Image.FORMAT_RGBA8,
		)
		src_img.fill(card_color)
	else:
		src_img = src_img.duplicate()
	src_img.resize(
		DRAG_CURSOR_SIZE, DRAG_CURSOR_SIZE,
		Image.INTERPOLATE_LANCZOS,
	)
	var tint := Color(0.85, 0.75, 0.6)
	tint = tint.lerp(card_color, 0.4)
	for y in src_img.get_height():
		for x in src_img.get_width():
			var px := src_img.get_pixel(x, y)
			if px.a > 0.0:
				src_img.set_pixel(x, y, Color(
					tint.r, tint.g, tint.b, px.a
				))
	return ImageTexture.create_from_image(src_img)


static func set_drag_cursor(
	icon_tex: Texture2D, card_color: Color,
) -> void:
	var tex := make_drag_cursor_tex(icon_tex, card_color)
	if tex == null:
		return
	@warning_ignore("integer_division")
	var hotspot := Vector2(
		DRAG_CURSOR_SIZE / 2, DRAG_CURSOR_SIZE / 2
	)
	Input.set_custom_mouse_cursor(
		tex, Input.CURSOR_ARROW, hotspot
	)


static func restore_default_cursor() -> void:
	Input.set_custom_mouse_cursor(
		null, Input.CURSOR_CROSS
	)
	set_default_cursor()


static func fit_font_size(
	text: String, max_width: int, max_height: int,
	max_size: int = 12, min_size: int = 7,
) -> int:
	var avg_char_w := 0.7
	var line_h_factor := 1.5
	for s in range(max_size, min_size - 1, -1):
		var char_w := s * avg_char_w
		var chars_per_line := int(max_width / char_w)
		if chars_per_line < 1:
			continue
		@warning_ignore("integer_division")
		var lines := (text.length() + chars_per_line - 1) / chars_per_line
		var total_h := lines * s * line_h_factor
		if total_h <= max_height:
			return s
	return min_size


static func _make_parchment_tex() -> Texture2D:
	var tex: Texture2D = load(PARCHMENT_PATH) as Texture2D
	if tex == null:
		return null
	var do_rotate: bool = randi() % 2 == 0
	var do_mirror: bool = randi() % 2 == 0
	if do_rotate or do_mirror:
		var img := tex.get_image().duplicate()
		if do_rotate:
			img.rotate_180()
		if do_mirror:
			img.flip_x()
		return ImageTexture.create_from_image(img)
	return tex


static func create_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.88, 0.82, 0.72, 0.5)
	style.border_color = Color(0.55, 0.4, 0.15)
	style.set_border_width_all(CARD_BORDER)
	style.set_corner_radius_all(CARD_CORNER_RADIUS)
	style.content_margin_left = PANEL_MARGIN_H
	style.content_margin_right = PANEL_MARGIN_H
	style.content_margin_top = PANEL_MARGIN_V
	style.content_margin_bottom = PANEL_MARGIN_V
	return style


static func apply_parchment_bg(
	panel: Control, is_container: bool = true,
	circle: bool = false,
) -> void:
	var ptex: Texture2D = _make_parchment_tex()
	if ptex == null:
		return
	var tint := Color(0.85, 0.75, 0.6, 1.0)
	if is_container or not circle:
		var zoom := 1.3
		var b := float(CARD_BORDER)
		var cr := float(CARD_CORNER_RADIUS)
		var border_style := StyleBoxFlat.new()
		border_style.bg_color = Color.TRANSPARENT
		border_style.border_color = Color(0.55, 0.4, 0.15)
		border_style.set_border_width_all(CARD_BORDER)
		border_style.set_corner_radius_all(CARD_CORNER_RADIUS)
		panel.draw.connect(func() -> void:
			var iw := panel.size.x - b * 2.0
			var ih := panel.size.y - b * 2.0
			var clip_r := maxf(cr - b, 0.0)
			var pts: PackedVector2Array = _rounded_rect_points(
				b, b, iw, ih, clip_r
			)
			var uvs := PackedVector2Array()
			for pt: Vector2 in pts:
				uvs.append(Vector2(
					(0.5 - 0.5 / zoom)
						+ (pt.x / panel.size.x) / zoom,
					(0.5 - 0.5 / zoom)
						+ (pt.y / panel.size.y) / zoom,
				))
			var colors := PackedColorArray()
			colors.append(tint)
			panel.draw_polygon(pts, colors, uvs, ptex)
			border_style.draw(
				panel.get_canvas_item(),
				Rect2(Vector2.ZERO, panel.size)
			)
		)
		panel.queue_redraw()
	else:
		# Circular panel: draw zoomed parchment clipped to a circle
		var zoom := 1.5
		var segments := 64
		panel.draw.connect(func() -> void:
			var center := panel.size * 0.5
			var r := minf(center.x, center.y) - float(CARD_BORDER)
			var pts := PackedVector2Array()
			var uvs := PackedVector2Array()
			var uv_r := 0.5 / zoom
			for i in segments:
				var angle := TAU * float(i) / float(segments)
				var dir := Vector2(cos(angle), sin(angle))
				pts.append(center + dir * r)
				uvs.append(Vector2(0.5, 0.5) + dir * uv_r)
			var colors := PackedColorArray()
			colors.append(tint)
			panel.draw_polygon(pts, colors, uvs, ptex)
		)
		panel.queue_redraw()


static func apply_section_parchment(
	sec: PanelContainer, color: Color,
	top_r: float = -1.0, bottom_r: float = -1.0,
) -> void:
	var ptex: Texture2D = _make_parchment_tex()
	if ptex == null:
		return
	sec.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var cr := float(SECTION_CORNER_RADIUS)
	var tr := cr if top_r < 0.0 else top_r
	var br := cr if bottom_r < 0.0 else bottom_r
	sec.draw.connect(func() -> void:
		var pts: PackedVector2Array = _rounded_rect_points_4r(
			0.0, 0.0, sec.size.x, sec.size.y,
			tr, br, br, tr
		)
		var uvs := PackedVector2Array()
		for pt: Vector2 in pts:
			uvs.append(Vector2(
				pt.x / sec.size.x, pt.y / sec.size.y
			))
		var colors := PackedColorArray()
		colors.append(color)
		sec.draw_polygon(pts, colors, uvs, ptex)
	)
	sec.queue_redraw()


static func create_circle_panel_style(
	radius: int,
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.25, 0.18, 0.12, PARCHMENT_OPACITY)
	style.border_color = Color(0.55, 0.4, 0.15)
	style.set_border_width_all(CARD_BORDER)
	style.set_corner_radius_all(radius)
	style.content_margin_left = PANEL_MARGIN_H
	style.content_margin_right = PANEL_MARGIN_H
	style.content_margin_top = PANEL_MARGIN_V
	style.content_margin_bottom = PANEL_MARGIN_V
	return style


static func icon_text(
	entity: String, value: String,
	align_right: bool = false,
) -> String:
	var path: String = ENTITY_ICONS.get(entity, "") as String
	var text: String
	if path == "":
		text = "%s: %s" % [entity, value]
	else:
		var icon_sz: int = int(FONT_LABEL * 1.2)
		var num_sz: int = FONT_STAT_NUM
		text = "[img=%d]%s[/img] [font_size=%d]%s[/font_size] %s" % [
			icon_sz, path, num_sz, value, entity,
		]
	if align_right:
		return "[right]%s[/right]" % text
	return text


static func set_bbcode(
	label: RichTextLabel, bbcode: String,
) -> void:
	label.clear()
	label.append_text("[left]" + bbcode + "[/left]")


static func create_card_back() -> Control:
	var w := float(CARD_WIDTH)
	var h := float(CARD_HEIGHT)
	var r := float(CARD_CORNER_RADIUS)
	var ptex: Texture2D = _make_parchment_tex()
	var ctrl := Control.new()
	ctrl.custom_minimum_size = Vector2(w, h)
	ctrl.size = Vector2(w, h)
	ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctrl.draw.connect(func() -> void:
		var b := float(CARD_BORDER)
		var cr := maxf(r - b, 0.0)
		var iw := w - b * 2.0
		var ih := h - b * 2.0
		var tint := Color(0.35, 0.25, 0.15, 1.0)
		var zoom := 1.3
		# Parchment fill clipped to rounded corners
		var pts: PackedVector2Array = _rounded_rect_points(
			b, b, iw, ih, cr
		)
		if ptex:
			var uvs := PackedVector2Array()
			for pt: Vector2 in pts:
				uvs.append(Vector2(
					(0.5 - 0.5 / zoom)
						+ (pt.x / w) / zoom,
					(0.5 - 0.5 / zoom)
						+ (pt.y / h) / zoom,
				))
			var colors := PackedColorArray()
			colors.append(tint)
			ctrl.draw_polygon(pts, colors, uvs, ptex)
		else:
			ctrl.draw_colored_polygon(pts, tint)
		# Gold border on top
		var border_style := StyleBoxFlat.new()
		border_style.bg_color = Color.TRANSPARENT
		border_style.border_color = Color(0.55, 0.4, 0.15)
		border_style.set_border_width_all(CARD_BORDER)
		border_style.set_corner_radius_all(CARD_CORNER_RADIUS)
		border_style.draw(
			ctrl.get_canvas_item(),
			Rect2(Vector2.ZERO, Vector2(w, h))
		)
		# Decorative elements
		var m := sf(10.0)
		var mr := maxf(r - m, sf(2.0))
		_draw_rounded_border(
			ctrl, m, m, w - m * 2.0, h - m * 2.0, mr,
			Color(0.42, 0.298, 0.118), sf(0.7)
		)
		var n := sf(18.0)
		var ir := maxf(r - n, sf(2.0))
		_draw_rounded_border(
			ctrl, n, n, w - n * 2.0, h - n * 2.0, ir,
			Color(0.29, 0.208, 0.071), sf(0.45)
		)
		var cx := w * 0.5
		var cy := h * 0.5
		_draw_circle_outline(
			ctrl, cx, cy, sf(25.0),
			Color(0.545, 0.412, 0.078), sf(0.9)
		)
		_draw_circle_outline(
			ctrl, cx, cy, sf(15.0),
			Color(0.42, 0.298, 0.118), sf(0.7)
		)
		ctrl.draw_circle(
			Vector2(cx, cy), sf(5.0),
			Color(0.545, 0.412, 0.078)
		)
		var lr := sf(25.0)
		var col1 := Color(0.42, 0.298, 0.118)
		var col2 := Color(0.29, 0.208, 0.071)
		ctrl.draw_line(
			Vector2(cx, cy - lr), Vector2(cx, m),
			col1, sf(0.7)
		)
		ctrl.draw_line(
			Vector2(cx, cy + lr), Vector2(cx, h - m),
			col1, sf(0.7)
		)
		ctrl.draw_line(
			Vector2(cx - lr, cy), Vector2(m, cy),
			col1, sf(0.7)
		)
		ctrl.draw_line(
			Vector2(cx + lr, cy), Vector2(w - m, cy),
			col1, sf(0.7)
		)
		var diag_r := sf(18.0)
		var dot_r := sf(3.5)
		var dot_positions: Array[Vector2] = [
			Vector2(sf(25.0), sf(30.0)),
			Vector2(sf(90.0), sf(30.0)),
			Vector2(sf(25.0), sf(135.0)),
			Vector2(sf(90.0), sf(135.0)),
		]
		for dot_pos: Vector2 in dot_positions:
			var dir: Vector2 = (
				dot_pos - Vector2(cx, cy)
			).normalized()
			var start: Vector2 = (
				Vector2(cx, cy) + dir * diag_r
			)
			ctrl.draw_line(
				start, dot_pos, col2, sf(0.45)
			)
			ctrl.draw_circle(dot_pos, dot_r, col2)
	)
	ctrl.queue_redraw()
	return ctrl


static func _rounded_rect_points(
	x: float, y: float, w: float, h: float,
	r: float, segments: int = 16,
) -> PackedVector2Array:
	return _rounded_rect_points_4r(
		x, y, w, h, r, r, r, r, segments
	)


static func _rounded_rect_points_4r(
	x: float, y: float, w: float, h: float,
	r_tr: float, r_br: float,
	r_bl: float, r_tl: float,
	segments: int = 16,
) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var radii: Array[float] = [r_tr, r_br, r_bl, r_tl]
	var start_angles: Array[float] = [
		-PI * 0.5, 0.0, PI * 0.5, PI,
	]
	for i in 4:
		var ri: float = radii[i]
		var center: Vector2
		if i == 0:
			center = Vector2(x + w - ri, y + ri)
		elif i == 1:
			center = Vector2(x + w - ri, y + h - ri)
		elif i == 2:
			center = Vector2(x + ri, y + h - ri)
		else:
			center = Vector2(x + ri, y + ri)
		var start_angle: float = start_angles[i]
		for j in range(segments + 1):
			var angle := (
				start_angle
				+ float(j) / float(segments) * PI * 0.5
			)
			pts.append(
				center + Vector2(cos(angle), sin(angle)) * ri
			)
	return pts


static func _draw_rounded_border(
	ctrl: Control, x: float, y: float,
	w: float, h: float, r: float,
	color: Color, width: float,
) -> void:
	var pts := _rounded_rect_points(x, y, w, h, r)
	pts.append(pts[0])
	ctrl.draw_polyline(pts, color, width, true)


static func _draw_circle_outline(
	ctrl: Control, cx: float, cy: float,
	r: float, color: Color, width: float,
	segments: int = 48,
) -> void:
	var pts := PackedVector2Array()
	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		pts.append(Vector2(cx + cos(angle) * r, cy + sin(angle) * r))
	ctrl.draw_polyline(pts, color, width, true)


static func s(value: int) -> int:
	return int(value * UI_SCALE)


static func sf(value: float) -> float:
	return value * UI_SCALE
