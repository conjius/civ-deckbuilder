extends Control

signal drag_started(card: CardData)
signal drag_ended(card: CardData, target: Vector2i, success: bool, drop_pos: Vector2)

const MIN_DRAG_MS: int = 100

var card_data: CardData
var hex_map: Node3D
var camera: Camera3D
var card_effects: Node
var active_unit: Node3D
var arrow_indicator: Control
var is_face_up: bool = true

var _dragging: bool = false
var _returning: bool = false
var _drag_start_time: int = 0
var _original_position: Vector2 = Vector2.ZERO
var _bg_panel: Panel
var _sections: Array[PanelContainer] = []
var _desc_section: PanelContainer
var _desc_label: Label
var _footer_section: PanelContainer
var _footer_label: Control
var _is_blocked: bool = false
var _valid_targets: Array[Vector2i] = []
var _drag_cursor_tex: ImageTexture
var _needs_cursor_update: bool = false
var _card_back: Control
var _face_container: Control


func setup(card: CardData) -> void:
	card_data = card
	custom_minimum_size = Vector2(
		UIHelpers.CARD_WIDTH, UIHelpers.CARD_HEIGHT
	)
	_face_container = Control.new()
	_face_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_face_container)
	var result: Dictionary = CardFaceBuilder.build_face(
		_face_container, card, _sections
	)
	_bg_panel = result["bg"] as Panel
	_desc_section = result["desc_section"] as PanelContainer
	_desc_label = result["desc_label"] as Label
	_footer_section = result["footer_section"] as PanelContainer
	_footer_label = result["footer_label"] as Control
	_card_back = UIHelpers.create_card_back()
	_card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card_back)
	set_face_up(true)


func set_face_up(value: bool) -> void:
	is_face_up = value
	if _face_container:
		_face_container.visible = value
	if _card_back:
		_card_back.visible = not value


func _gui_input(event: InputEvent) -> void:
	if _returning:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not _dragging:
				_start_drag()
				accept_event()
			elif not event.pressed and _dragging:
				var elapsed: int = (
					Time.get_ticks_msec() - _drag_start_time
				)
				if elapsed >= MIN_DRAG_MS:
					_end_drag(event.global_position)
					accept_event()


func _process(_delta: float) -> void:
	if _needs_cursor_update and _drag_cursor_tex != null:
		_needs_cursor_update = false
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
		Input.set_custom_mouse_cursor(
			_drag_cursor_tex, Input.CURSOR_ARROW, Vector2(1, 1)
		)


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		_needs_cursor_update = true
		_update_hover(event.global_position)
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_drag()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var elapsed: int = Time.get_ticks_msec() - _drag_start_time
			if elapsed >= MIN_DRAG_MS:
				_end_drag(event.global_position)


func _start_drag() -> void:
	if _returning:
		return
	_dragging = true
	_drag_start_time = Time.get_ticks_msec()
	_original_position = global_position
	z_index = 100
	var icon_tex := CardFaceBuilder.get_card_icon(card_data)
	_drag_cursor_tex = UIHelpers.make_drag_cursor_tex(
		icon_tex, card_data.card_color
	)
	_needs_cursor_update = true
	_valid_targets.clear()
	if hex_map and card_effects and active_unit:
		_valid_targets = card_effects.get_valid_targets(
			card_data, active_unit.current_coord
		)
		if card_data.card_type == CardData.CardType.SETTLE:
			if _valid_targets.is_empty():
				_apply_blocked_settle()
			else:
				var settle_color := Color(0.2, 1.0, 0.4, 1.0)
				for coord in _valid_targets:
					var tile: Node3D = hex_map.get_tile(coord)
					if tile:
						tile.pulse_highlight(settle_color)
		else:
			hex_map.highlight_tiles(
				_valid_targets, Color(0.3, 0.8, 1.0, 0.8)
			)
	if card_data.card_type == CardData.CardType.MOVE:
		if active_unit and active_unit.has_method("set_targeting_move"):
			active_unit.set_targeting_move(true)
	drag_started.emit(card_data)


func _cancel_drag() -> void:
	_dragging = false
	_stop_all_pulses()
	hex_map.clear_highlights()
	if arrow_indicator:
		arrow_indicator.hide_arrow()
	_valid_targets.clear()
	_restore_card_visuals()
	if active_unit and active_unit.has_method("set_targeting_move"):
		active_unit.set_targeting_move(false)


func _end_drag(mouse_pos: Vector2) -> void:
	_dragging = false
	modulate = Color.WHITE
	_stop_all_pulses()
	hex_map.clear_highlights()
	if arrow_indicator:
		arrow_indicator.hide_arrow()
	var target := _raycast_hex(mouse_pos)
	if active_unit and active_unit.has_method("set_targeting_move"):
		active_unit.set_targeting_move(false)
	var is_valid := (
		target != Vector2i(-999, -999)
		and _is_valid_target(target)
	)
	var elapsed: int = Time.get_ticks_msec() - _drag_start_time
	_valid_targets.clear()
	if is_valid and elapsed >= MIN_DRAG_MS:
		_animate_to_discard(target, mouse_pos)
	else:
		_restore_card_visuals()
		drag_ended.emit(
			card_data, Vector2i.ZERO, false, mouse_pos
		)


func _animate_to_discard(
	target: Vector2i, mouse_pos: Vector2,
) -> void:
	z_index = 0
	UIHelpers.restore_default_cursor()
	drag_ended.emit(card_data, target, true, mouse_pos)


func _update_hover(mouse_pos: Vector2) -> void:
	if not hex_map or not camera:
		return
	hex_map.clear_highlights()
	hex_map.highlight_tiles(
		_valid_targets, Color(0.3, 0.8, 1.0, 0.8)
	)
	var from_pos := Vector3.ZERO
	if active_unit:
		from_pos = active_unit.global_position
	var hovered := _raycast_hex(mouse_pos)
	if hovered != Vector2i(-999, -999) and _is_valid_target(hovered):
		hex_map.highlight_tiles(
			[hovered] as Array[Vector2i],
			Color(1.0, 1.0, 0.3, 1.0),
		)
	if arrow_indicator and camera:
		var to_pos := _screen_to_ground(mouse_pos)
		if hovered != Vector2i(-999, -999) and _is_valid_target(hovered):
			to_pos = HexUtil.axial_to_world(
				hovered.x, hovered.y
			)
		var col := Color(
			card_data.card_color.r,
			card_data.card_color.g,
			card_data.card_color.b,
			0.85,
		)
		arrow_indicator.show_arrow(from_pos, to_pos, col)


func _raycast_hex(screen_pos: Vector2) -> Vector2i:
	if not hex_map or not camera:
		return Vector2i(-999, -999)
	return hex_map.raycast_to_hex(camera, screen_pos)


func _is_valid_target(coord: Vector2i) -> bool:
	return coord in _valid_targets


func _apply_blocked_settle() -> void:
	_is_blocked = true
	modulate = Color(1.0, 0.3, 0.3, 0.6)
	if active_unit:
		var coord: Vector2i = active_unit.current_coord
		var tile: Node3D = hex_map.get_tile(coord)
		if tile:
			tile.pulse_highlight(Color(1.0, 0.2, 0.2, 1.0))


func _restore_card_visuals() -> void:
	_returning = false
	_is_blocked = false
	z_index = 0
	modulate = Color.WHITE
	UIHelpers.restore_default_cursor()
	if _bg_panel:
		_bg_panel.visible = true
	for sec in _sections:
		sec.self_modulate = Color.WHITE
	if _desc_section:
		_desc_section.visible = true
	if _desc_label:
		_desc_label.visible = true
	if _footer_section:
		_footer_section.visible = true
	if _footer_label:
		_footer_label.visible = true


func _stop_all_pulses() -> void:
	for coord in _valid_targets:
		var tile: Node3D = hex_map.get_tile(coord)
		if tile and tile.has_method("stop_pulse"):
			tile.stop_pulse()
	if _is_blocked and active_unit:
		var tile: Node3D = hex_map.get_tile(
			active_unit.current_coord
		)
		if tile and tile.has_method("stop_pulse"):
			tile.stop_pulse()


func _is_in_hand_area(screen_pos: Vector2) -> bool:
	var vp_h: float = get_viewport().get_visible_rect().size.y
	var hand_top: float = vp_h - float(UIHelpers.CARD_HEIGHT)
	return screen_pos.y >= hand_top


func _screen_to_ground(screen_pos: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return Vector3.ZERO
	var t := -origin.y / dir.y
	return origin + dir * t
