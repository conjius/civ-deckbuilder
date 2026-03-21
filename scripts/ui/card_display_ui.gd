extends PanelContainer

signal drag_started(card: CardData)
signal drag_ended(card: CardData, target: Vector2i, success: bool)

var card_data: CardData
var hex_map: Node3D
var camera: Camera3D
var card_effects: Node
var active_unit: Node3D
var arrow_indicator: MeshInstance3D

var _card_icon_textures: Dictionary = {
	CardData.CardType.MOVE: preload("res://assets/icons/move_64.svg"),
	CardData.CardType.SCOUT: preload("res://assets/icons/scout_64.svg"),
	CardData.CardType.GATHER: preload(
		"res://assets/icons/gather_64.svg"
	),
	CardData.CardType.SETTLE: preload(
		"res://assets/icons/settle_64.svg"
	),
}
var _parchment_tex: Texture2D = preload(
	"res://assets/textures/ui/parchment_256_grayscale.png"
)
var _font_regular: Font = preload(
	"res://assets/fonts/Cinzel-Regular.ttf"
)
var _font_bold: Font = preload(
	"res://assets/fonts/Cinzel-Bold.ttf"
)
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2 = Vector2.ZERO
var _valid_targets: Array[Vector2i] = []


func setup(card: CardData) -> void:
	card_data = card
	custom_minimum_size = Vector2(
		UIHelpers.CARD_WIDTH, UIHelpers.CARD_HEIGHT
	)

	var base: Color = card.card_color
	var dark: Color = base.darkened(0.35)
	var light: Color = base.lightened(0.2)

	var outer := StyleBoxFlat.new()
	outer.bg_color = Color(0.12, 0.08, 0.05)
	outer.border_color = Color(0.55, 0.4, 0.15)
	outer.set_border_width_all(UIHelpers.CARD_BORDER)
	outer.set_corner_radius_all(6)
	outer.content_margin_left = 0
	outer.content_margin_right = 0
	outer.content_margin_top = 0
	outer.content_margin_bottom = 0
	add_theme_stylebox_override("panel", outer)

	var inner := Control.new()
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inner)

	var b := UIHelpers.CARD_BORDER
	var cw := UIHelpers.CARD_WIDTH - b * 2
	var gap := UIHelpers.SECTION_GAP
	var y := 0

	var hh := UIHelpers.HEADER_HEIGHT
	_add_section(inner, dark, b, y, cw, hh)
	var name_lbl := _add_label(
		inner, card.card_name, _font_bold,
		b, y, cw, hh, Color.WHITE,
		UIHelpers.fit_font_size(
			card.card_name, cw - 12, hh - 8, 13, 9
		),
	)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	y += hh + gap

	var ah := UIHelpers.AVATAR_HEIGHT
	_add_section(inner, light, b, y, cw, ah)
	_add_avatar(inner, card, b, y, cw, ah)
	y += ah + gap

	var dh := UIHelpers.DESC_HEIGHT
	_add_section(inner, base, b, y, cw, dh)
	var desc_lbl := _add_label(
		inner, card.description, _font_regular,
		b, y, cw, dh, Color.WHITE,
		UIHelpers.fit_font_size(
			card.description, cw - 12, dh - 8, 11, 7
		),
	)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	y += dh + gap

	var fh := UIHelpers.FOOTER_HEIGHT
	_add_section(inner, dark, b, y, cw, fh)
	var ftxt := "Range %d" % card.range_value
	var f_lbl := _add_label(
		inner, ftxt, _font_regular,
		b, y, cw, fh, Color(1, 1, 1, 0.8),
		UIHelpers.fit_font_size(ftxt, cw - 12, fh - 8, 11, 8),
	)
	f_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	f_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


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
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	sec.add_theme_stylebox_override("panel", style)
	parent.add_child(sec)
	return sec


func _add_label(
	parent: Control, text: String, font: Font,
	x: int, y: int, w: int, h: int,
	color: Color, font_size: int,
) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(x + 6, y + 4)
	lbl.size = Vector2(w - 12, h - 8)
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(lbl)
	return lbl


func _add_avatar(
	parent: Control, card: CardData,
	x: int, y: int, w: int, h: int,
) -> void:
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
		tex_rect.position = Vector2(x, y)
		tex_rect.size = Vector2(w, h)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(tex_rect)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not _dragging:
				_start_drag(event.global_position)
				accept_event()
			elif not event.pressed and _dragging:
				_end_drag(event.global_position)
				accept_event()


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		global_position = event.global_position - _drag_offset
		_update_hover(event.global_position)
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_end_drag(event.global_position)


func _start_drag(mouse_pos: Vector2) -> void:
	_dragging = true
	_original_position = global_position
	_drag_offset = mouse_pos - global_position
	z_index = 100
	modulate = Color(1.0, 1.0, 1.0, 0.5)
	scale = Vector2(1.05, 1.05)
	_valid_targets.clear()
	if hex_map and card_effects and active_unit:
		_valid_targets = card_effects.get_valid_targets(
			card_data, active_unit.current_coord
		)
		hex_map.highlight_tiles(
			_valid_targets, Color(0.3, 0.8, 1.0, 0.8)
		)
	drag_started.emit(card_data)


func _end_drag(mouse_pos: Vector2) -> void:
	_dragging = false
	z_index = 0
	modulate = Color.WHITE
	scale = Vector2.ONE
	hex_map.clear_highlights()
	if arrow_indicator:
		arrow_indicator.hide_arrow()
	var target := _raycast_hex(mouse_pos)
	var is_valid := (
		target != Vector2i(-999, -999)
		and _is_valid_target(target)
	)
	_valid_targets.clear()
	if is_valid:
		drag_ended.emit(card_data, target, true)
	else:
		global_position = _original_position
		drag_ended.emit(card_data, Vector2i.ZERO, false)


func _update_hover(mouse_pos: Vector2) -> void:
	if not hex_map or not camera:
		return
	hex_map.clear_highlights()
	hex_map.highlight_tiles(
		_valid_targets, Color(0.3, 0.8, 1.0, 0.8)
	)
	var hovered := _raycast_hex(mouse_pos)
	if hovered != Vector2i(-999, -999) and _is_valid_target(hovered):
		hex_map.highlight_tiles(
			[hovered] as Array[Vector2i],
			Color(1.0, 1.0, 0.3, 1.0),
		)
		if arrow_indicator and camera:
			var from_pos := _screen_to_ground(
				_original_position + size * 0.5
			)
			var to_pos := HexUtil.axial_to_world(
				hovered.x, hovered.y
			)
			arrow_indicator.show_arrow(from_pos, to_pos)
	else:
		if arrow_indicator:
			arrow_indicator.hide_arrow()


func _raycast_hex(screen_pos: Vector2) -> Vector2i:
	if not hex_map or not camera:
		return Vector2i(-999, -999)
	return hex_map.raycast_to_hex(camera, screen_pos)


func _is_valid_target(coord: Vector2i) -> bool:
	return coord in _valid_targets


func _screen_to_ground(screen_pos: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return Vector3.ZERO
	var t := -origin.y / dir.y
	return origin + dir * t
