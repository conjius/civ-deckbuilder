extends Control

signal drag_started(card: CardData)
signal drag_ended(card: CardData, target: Vector2i, success: bool)

var card_data: CardData
var hex_map: Node3D
var camera: Camera3D
var card_effects: Node
var active_unit: Node3D
var arrow_indicator: Control
var discard_pile: Control

var _card_icon_textures: Dictionary = {
	CardData.CardType.MOVE: preload("res://assets/icons/explorer_unit.svg"),
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
var _returning: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2 = Vector2.ZERO
var _bg_panel: Panel
var _sections: Array[PanelContainer] = []
var _desc_section: PanelContainer
var _desc_label: Label
var _footer_section: PanelContainer
var _footer_label: Label
var _is_blocked: bool = false
var _valid_targets: Array[Vector2i] = []


func setup(card: CardData) -> void:
	card_data = card
	custom_minimum_size = Vector2(
		UIHelpers.CARD_WIDTH, UIHelpers.CARD_HEIGHT
	)

	var base: Color = card.card_color
	var dark: Color = base.darkened(0.35)
	var light: Color = base.lightened(0.2)

	_bg_panel = Panel.new()
	var bg := _bg_panel
	bg.position = Vector2.ZERO
	bg.size = Vector2(
		UIHelpers.CARD_WIDTH, UIHelpers.CARD_HEIGHT
	)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_style := UIHelpers.create_panel_style()
	bg_style.set_corner_radius_all(UIHelpers.CARD_CORNER_RADIUS)
	bg.add_theme_stylebox_override("panel", bg_style)
	add_child(bg)

	var b := UIHelpers.CARD_BORDER
	var cw := UIHelpers.CARD_WIDTH - b * 2
	var gap := UIHelpers.SECTION_GAP
	var mh := UIHelpers.SECTION_MARGIN_H
	var mv := UIHelpers.SECTION_MARGIN_V
	var y := UIHelpers.SECTION_TOP

	var hh := UIHelpers.HEADER_HEIGHT
	var header := _add_section(self, dark, b, y, cw, hh)
	var name_lbl := _add_label_in(
		header, card.card_name, _font_bold, Color.WHITE,
		UIHelpers.fit_font_size(
			card.card_name, cw - mh * 2,
			hh - mv * 2, UIHelpers.FONT_TITLE,
			UIHelpers.s(9),
		),
	)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	y += hh + gap

	var ah := UIHelpers.AVATAR_HEIGHT
	var avatar_sec := _add_section(self, light, b, y, cw, ah)
	_add_avatar(avatar_sec, card)
	y += ah + gap

	var dh := UIHelpers.DESC_HEIGHT
	_desc_section = _add_section(self, base, b, y, cw, dh)
	_desc_label = _add_label_in(
		_desc_section, card.description, _font_bold,
		Color.WHITE,
		UIHelpers.fit_font_size(
			card.description, cw - mh * 2,
			dh - mv * 2, UIHelpers.FONT_BODY,
			UIHelpers.s(7),
		),
	)
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	y += dh + gap

	var fh := UIHelpers.FOOTER_HEIGHT
	_footer_section = _add_section(self, dark, b, y, cw, fh)
	var ftxt := "Range %d" % card.range_value
	_footer_label = _add_label_in(
		_footer_section, ftxt, _font_bold,
		Color(1, 1, 1, 0.8),
		UIHelpers.fit_font_size(
			ftxt, cw - mh * 2, fh - mv * 2,
			UIHelpers.FONT_BODY, UIHelpers.s(8),
		),
	)
	_footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_footer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


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
	style.content_margin_left = UIHelpers.SECTION_MARGIN_H
	style.content_margin_right = UIHelpers.SECTION_MARGIN_H
	style.content_margin_top = UIHelpers.SECTION_MARGIN_V
	style.content_margin_bottom = UIHelpers.SECTION_MARGIN_V
	var do_rotate: bool = randi() % 2 == 0
	var do_mirror: bool = randi() % 2 == 0
	if do_rotate or do_mirror:
		var img := _parchment_tex.get_image().duplicate()
		if do_rotate:
			img.rotate_180()
		if do_mirror:
			img.flip_x()
		style.texture = ImageTexture.create_from_image(img)
	sec.add_theme_stylebox_override("panel", style)
	parent.add_child(sec)
	_sections.append(sec)
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


func _add_avatar(
	section: PanelContainer, card: CardData,
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
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sc := card.icon_scale
		if sc < 1.0:
			var sz := section.size
			var inset := sz * (1.0 - sc) * 0.5
			tex_rect.position = inset
			tex_rect.size = sz * sc
		else:
			tex_rect.layout_mode = 1
			tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		section.add_child(tex_rect)


func _gui_input(event: InputEvent) -> void:
	if _returning:
		return
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
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_cancel_drag()
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_end_drag(event.global_position)


func _start_drag(mouse_pos: Vector2) -> void:
	if _returning:
		return
	_dragging = true
	_original_position = global_position
	_drag_offset = mouse_pos - global_position
	z_index = 100
	modulate = Color(1.0, 1.0, 1.0, 0.6)
	if _bg_panel:
		_bg_panel.visible = false
	for sec in _sections:
		sec.self_modulate = Color(1, 1, 1, 0)
	if _desc_section:
		_desc_section.visible = false
	if _desc_label:
		_desc_label.visible = false
	if _footer_section:
		_footer_section.visible = false
	if _footer_label:
		_footer_label.visible = false
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
	drag_started.emit(card_data)


func _cancel_drag() -> void:
	_dragging = false
	_returning = true
	_stop_all_pulses()
	hex_map.clear_highlights()
	if arrow_indicator:
		arrow_indicator.hide_arrow()
	_valid_targets.clear()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		self, "global_position", _original_position, 0.25
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		self, "modulate", Color.WHITE, 0.2
	)
	tween.chain().tween_callback(_restore_card_visuals)


func _end_drag(mouse_pos: Vector2) -> void:
	_dragging = false
	_stop_all_pulses()
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
		_animate_to_discard(target)
	else:
		_returning = true
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(
			self, "global_position", _original_position, 0.2
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(
			self, "modulate", Color.WHITE, 0.15
		)
		tween.chain().tween_callback(func() -> void:
			_restore_card_visuals()
			drag_ended.emit(card_data, Vector2i.ZERO, false)
		)


func _animate_to_discard(target: Vector2i) -> void:
	var dest := _original_position
	if discard_pile:
		dest = discard_pile.global_position
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		self, "global_position", dest, 0.25
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(
		self, "modulate", Color.WHITE, 0.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		self, "scale", Vector2.ONE, 0.2
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func() -> void:
		z_index = 0
		drag_ended.emit(card_data, target, true)
	)


func _update_hover(mouse_pos: Vector2) -> void:
	if not hex_map or not camera:
		return
	hex_map.clear_highlights()
	hex_map.highlight_tiles(
		_valid_targets, Color(0.3, 0.8, 1.0, 0.8)
	)
	var from_pos := _screen_to_ground(
		_original_position + size * 0.5
	)
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
		arrow_indicator.show_arrow(from_pos, to_pos)


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


func _screen_to_ground(screen_pos: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return Vector3.ZERO
	var t := -origin.y / dir.y
	return origin + dir * t
