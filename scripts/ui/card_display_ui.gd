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
var _cursor_node: TextureRect
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


func _show_cursor_node() -> void:
	if _cursor_node != null:
		return
	var icon_tex := CardFaceBuilder.get_card_icon(card_data)
	if icon_tex == null:
		return
	var sz := UIHelpers.DRAG_CURSOR_SIZE
	_cursor_node = TextureRect.new()
	_cursor_node.texture = icon_tex
	_cursor_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cursor_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cursor_node.custom_minimum_size = Vector2(sz, sz)
	_cursor_node.size = Vector2(sz, sz)
	_cursor_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_node.z_index = 200
	var mat := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = (
		"shader_type canvas_item;\n"
		+ "uniform vec4 tint_color : source_color;\n"
		+ "uniform float glow_size : hint_range(0.0, 0.15)"
		+ " = 0.12;\n"
		+ "void fragment() {\n"
		+ "  vec4 tex = texture(TEXTURE, UV);\n"
		+ "  float acc = 0.0;\n"
		+ "  float total = 0.0;\n"
		+ "  for (int r = 1; r <= 6; r++) {\n"
		+ "    float rd = glow_size * float(r) / 6.0;\n"
		+ "    float w = 1.0 - float(r) / 9.0;\n"
		+ "    for (int i = 0; i < 16; i++) {\n"
		+ "      float a = float(i) / 16.0 * 6.2832;\n"
		+ "      vec2 off = vec2(cos(a), sin(a)) * rd;\n"
		+ "      acc += texture(TEXTURE, UV + off).a * w;\n"
		+ "      total += w;\n"
		+ "    }\n"
		+ "  }\n"
		+ "  float glow = (acc / total) * (1.0 - tex.a);\n"
		+ "  float lum = dot(tex.rgb,"
		+ " vec3(0.299, 0.587, 0.114));\n"
		+ "  vec3 col = tint_color.rgb"
		+ " * max(lum, 0.15) * tex.a;\n"
		+ "  float fa = max(tex.a * tint_color.a,"
		+ " glow * 0.9);\n"
		+ "  COLOR = vec4(col, fa);\n"
		+ "}\n"
	)
	mat.shader = shader
	mat.set_shader_parameter(
		"tint_color", card_data.card_color
	)
	_cursor_node.material = mat
	get_tree().root.add_child(_cursor_node)
	_update_cursor_pos()


func _update_cursor_pos() -> void:
	if _cursor_node == null:
		return
	var mouse := get_viewport().get_mouse_position()
	@warning_ignore("integer_division")
	var half := UIHelpers.DRAG_CURSOR_SIZE / 2
	_cursor_node.global_position = mouse - Vector2(half, half)


func _hide_cursor_node() -> void:
	if _cursor_node != null:
		_cursor_node.queue_free()
		_cursor_node = null


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		_update_cursor_pos()
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
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_show_cursor_node()
	_valid_targets.clear()
	if hex_map and card_effects and active_unit:
		var unit_color: Color = Color(-1, -1, -1)
		if "avatar_color" in active_unit:
			unit_color = active_unit.avatar_color
		_valid_targets = card_effects.get_valid_targets(
			card_data, active_unit.current_coord, unit_color
		)
		if _valid_targets.is_empty():
			_apply_blocked()
		elif card_data.card_type == CardData.CardType.SETTLE:
			var settle_color := Color(0.2, 1.0, 0.4, 1.0)
			for coord in _valid_targets:
				var tile: Node3D = hex_map.get_tile(coord)
				if tile:
					tile.pulse_highlight(settle_color)
		else:
			var card_color := Color(
				card_data.card_color.r,
				card_data.card_color.g,
				card_data.card_color.b,
				0.4,
			)
			hex_map.highlight_tiles(_valid_targets, card_color)
	if card_data.card_type == CardData.CardType.MOVE:
		if active_unit and active_unit.has_method("set_targeting_move"):
			active_unit.set_targeting_move(true)
	drag_started.emit(card_data)


func _cancel_drag() -> void:
	_dragging = false
	_hide_cursor_node()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_stop_all_pulses()
	hex_map.clear_highlights()
	hex_map.clear_hover_highlight()
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
	hex_map.clear_hover_highlight()
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
	_hide_cursor_node()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	UIHelpers.restore_default_cursor()
	drag_ended.emit(card_data, target, true, mouse_pos)


func _update_hover(mouse_pos: Vector2) -> void:
	if not hex_map or not camera:
		return
	hex_map.clear_hover_highlight()
	hex_map.clear_highlights()
	var red := Color(1.0, 0.2, 0.2, 0.4)
	if _is_blocked:
		# Re-apply red on unit hex while blocked
		if active_unit:
			var unit_coord: Vector2i = active_unit.current_coord
			var tile: Node3D = hex_map.get_tile(unit_coord)
			if tile:
				tile.set_highlighted(true, red)
	else:
		var card_color := Color(
			card_data.card_color.r,
			card_data.card_color.g,
			card_data.card_color.b,
			0.4,
		)
		hex_map.highlight_tiles(_valid_targets, card_color)
	var from_pos := Vector3.ZERO
	if active_unit:
		from_pos = active_unit.global_position
	var hovered := _raycast_hex(mouse_pos)
	if hovered != Vector2i(-999, -999):
		if _is_blocked:
			hex_map.set_hover_highlight(hovered)
			var tile: Node3D = hex_map.get_tile(hovered)
			if tile:
				tile.set_highlighted(true, red)
		elif _is_valid_target(hovered):
			hex_map.highlight_tiles(
				[hovered] as Array[Vector2i],
				hex_map.BLUE_HIGHLIGHT,
			)
		else:
			hex_map.set_hover_highlight(hovered)
	if arrow_indicator and camera:
		var to_pos := _screen_to_ground(mouse_pos)
		var snapped := (
			hovered != Vector2i(-999, -999)
			and _is_valid_target(hovered)
		)
		if snapped:
			to_pos = HexUtil.axial_to_world(
				hovered.x, hovered.y
			)
		else:
			var to_screen := camera.unproject_position(to_pos)
			var from_screen := camera.unproject_position(from_pos)
			var screen_dir := to_screen - from_screen
			var screen_dist := screen_dir.length()
			var pull_back_px := float(UIHelpers.DRAG_CURSOR_SIZE) * 0.85
			if screen_dist > pull_back_px:
				var shortened := to_screen - screen_dir.normalized() * pull_back_px
				to_pos = _screen_to_ground(shortened)
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


func _apply_blocked() -> void:
	_is_blocked = true
	modulate = Color(1.0, 0.3, 0.3, 0.6)
	var red := Color(1.0, 0.2, 0.2, 0.4)
	if active_unit:
		var coord: Vector2i = active_unit.current_coord
		hex_map.set_blue_highlight(coord)
		var tile: Node3D = hex_map.get_tile(coord)
		if tile:
			tile.set_highlighted(true, red)


func _restore_card_visuals() -> void:
	_returning = false
	_is_blocked = false
	z_index = 0
	modulate = Color.WHITE
	_hide_cursor_node()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
