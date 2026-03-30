class_name CardPileUI
extends Control

signal clicked

const GLOW_PAD := 50
const FAN_CARDS := 4
const FAN_SPREAD := 60.0
const CARD_SCALE := 0.5
const ICON_CARD_SCALE := 0.6

var _count_label: Label
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _is_face_down: bool = false
var _pile_width: int
var _pile_height: int
var _original_pos: Vector2 = Vector2.ZERO
var _toggled_on: bool = false
var _hovered: bool = false
var _in_gallery: bool = false
var _glow_mat: ShaderMaterial
var _sv: SubViewport
var _draw_ctrl: Control
var _card_angles: Array[float] = [0.0]
var _target_angles: Array[float] = [0.0]
var _anim_tween: Tween
var _anim_progress: float = 1.0
var _start_angles: Array[float] = [0.0]
var _brightness: float = 1.0
var _gray_strength: float = 0.0
var _start_brightness: float = 1.0
var _start_gray: float = 0.0
var _target_brightness: float = 1.0
var _target_gray: float = 0.0


func setup(face_down: bool) -> void:
	_is_face_down = face_down
	_pile_width = int(
		float(UIHelpers.CARD_WIDTH) * ICON_CARD_SCALE
	)
	_pile_height = int(
		float(UIHelpers.CARD_HEIGHT) * ICON_CARD_SCALE
	)
	var total_w: int = _pile_width + GLOW_PAD * 2 + 100
	var total_h: int = _pile_height + GLOW_PAD * 2
	custom_minimum_size = Vector2(total_w, total_h)
	size = Vector2(total_w, total_h)
	mouse_filter = Control.MOUSE_FILTER_PASS
	position -= Vector2(GLOW_PAD, GLOW_PAD)

	var svc := SubViewportContainer.new()
	svc.size = Vector2(total_w, total_h)
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow_mat = _create_glow_shader()
	_glow_mat.set_shader_parameter("glow_strength", 0.0)
	svc.material = _glow_mat
	add_child(svc)
	_sv = SubViewport.new()
	_sv.size = Vector2i(total_w, total_h)
	_sv.transparent_bg = true
	svc.add_child(_sv)

	_draw_ctrl = Control.new()
	_draw_ctrl.size = Vector2(total_w, total_h)
	_draw_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sv.add_child(_draw_ctrl)

	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var pivot_y: int = GLOW_PAD + int(float(_pile_height) * 0.9)
	var card_top: int = pivot_y - _pile_height
	@warning_ignore("integer_division")
	var label_x: int = (total_w - _pile_width) / 2
	_count_label.position = Vector2(label_x, card_top)
	_count_label.size = Vector2(_pile_width, _pile_height)
	_count_label.add_theme_font_override("font", _font_bold)
	_count_label.add_theme_font_size_override(
		"font_size", int(36 * UIHelpers.UI_SCALE)
	)
	_count_label.add_theme_color_override(
		"font_color", Color(0.95, 0.88, 0.7)
	)
	_count_label.add_theme_constant_override("outline_size", 0)
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count_label)

	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)

	_brightness = 1.0
	_gray_strength = 0.0
	if _toggled_on:
		_card_angles.clear()
		var start_a := -FAN_SPREAD * 0.5
		var step: float = FAN_SPREAD / float(FAN_CARDS - 1)
		for i in FAN_CARDS:
			_card_angles.append(
				deg_to_rad(start_a + float(i) * step)
			)
	else:
		_card_angles = [0.0] as Array[float]
	_draw_ctrl.draw.connect(_draw_cards)
	_update_label_color()
	# Hole punch for number — in UV space
	var label_cx: float = (
		_count_label.position.x + _count_label.size.x * 0.5
	)
	var label_cy: float = (
		_count_label.position.y + _count_label.size.y * 0.5
	)
	_glow_mat.set_shader_parameter(
		"hole_center", Vector2(
			label_cx / float(total_w),
			label_cy / float(total_h),
		)
	)
	_glow_mat.set_shader_parameter(
		"hole_radius", 22.0 / float(total_w)
	)
	_draw_ctrl.queue_redraw()


func update_count(count: int, hide_on_zero: bool = true) -> void:
	_count_label.text = str(count)
	if hide_on_zero:
		visible = count > 0


func set_toggled(value: bool) -> void:
	if _toggled_on == value:
		return
	_toggled_on = value
	_rebuild_visual()
	_update_glow()


func set_gallery_mode(active: bool) -> void:
	if _in_gallery == active:
		return
	_in_gallery = active
	if active:
		_rebuild_visual()
	else:
		# Leaving gallery: animate to full brightness, no gray
		_toggled_on = false
		_start_angles = _card_angles.duplicate()
		_target_angles.clear()
		for i in _start_angles.size():
			_target_angles.append(0.0)
		var anim_count: int = _start_angles.size()
		_card_angles.resize(anim_count)
		if _anim_tween and _anim_tween.is_running():
			_anim_tween.kill()
		_anim_progress = 0.0
		var exit_b: float = _brightness
		var exit_g: float = _gray_strength
		_anim_tween = create_tween()
		_anim_tween.tween_method(
			func(t: float) -> void:
				for i in _card_angles.size():
					var from: float = (
						_start_angles[i]
						if i < _start_angles.size() else 0.0
					)
					_card_angles[i] = lerpf(from, 0.0, t)
				_brightness = lerpf(exit_b, 1.0, t)
				_gray_strength = lerpf(exit_g, 0.0, t)
				_update_label_color()
				_draw_ctrl.queue_redraw(),
			0.0, 1.0, 0.25,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_IN_OUT
		)
		_anim_tween.tween_callback(func() -> void:
			_card_angles = [0.0] as Array[float]
			_brightness = 1.0
			_gray_strength = 0.0
			_draw_ctrl.queue_redraw()
		)


func _on_hover_enter() -> void:
	_hovered = true
	_update_glow()


func _on_hover_exit() -> void:
	_hovered = false
	_update_glow()


func _update_glow() -> void:
	var target := 1.0 if _hovered else 0.0
	var current: float = (
		_glow_mat.get_shader_parameter("glow_strength")
	) as float
	create_tween().tween_method(
		func(v: float) -> void:
			_glow_mat.set_shader_parameter(
				"glow_strength", v
			),
		current, target, 0.15,
	)


func _rebuild_visual() -> void:
	if _draw_ctrl == null:
		return
	_start_angles = _card_angles.duplicate()
	if _toggled_on:
		_target_angles.clear()
		var start_a := -FAN_SPREAD * 0.5
		var step: float = FAN_SPREAD / float(FAN_CARDS - 1)
		for i in FAN_CARDS:
			_target_angles.append(
				deg_to_rad(start_a + float(i) * step)
			)
	else:
		# All cards collapse to angle 0
		_target_angles.clear()
		for i in _start_angles.size():
			_target_angles.append(0.0)
	# Pad start to match target count
	while _start_angles.size() < _target_angles.size():
		_start_angles.append(0.0)
	# Use max card count during animation
	var anim_count: int = maxi(
		_start_angles.size(), _target_angles.size()
	)
	_card_angles.resize(anim_count)
	if not _draw_ctrl.draw.is_connected(_draw_cards):
		_draw_ctrl.draw.connect(_draw_cards)
	var should_dim := _in_gallery and not _toggled_on
	_start_brightness = _brightness
	_start_gray = _gray_strength
	_target_brightness = 0.7 if should_dim else 1.0
	_target_gray = 1.0 if should_dim else 0.0
	if _anim_tween and _anim_tween.is_running():
		_anim_tween.kill()
	_anim_progress = 0.0
	_anim_tween = create_tween()
	_anim_tween.tween_method(
		_set_anim_progress, 0.0, 1.0, 0.3,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_anim_tween.tween_callback(_on_anim_finished)


func _set_anim_progress(t: float) -> void:
	_anim_progress = t
	for i in _card_angles.size():
		var from: float = (
			_start_angles[i] if i < _start_angles.size()
			else 0.0
		)
		var to: float = (
			_target_angles[i] if i < _target_angles.size()
			else 0.0
		)
		_card_angles[i] = lerpf(from, to, t)
	_brightness = lerpf(_start_brightness, _target_brightness, t)
	_gray_strength = lerpf(_start_gray, _target_gray, t)
	_update_label_color()
	_draw_ctrl.queue_redraw()


func _update_label_color() -> void:
	if _count_label == null:
		return
	var base_col := Color(0.95, 0.88, 0.7)
	var gray_val: float = (
		base_col.r * 0.3 + base_col.g * 0.59 + base_col.b * 0.11
	) * 0.6
	var r: float = lerpf(base_col.r, gray_val, _gray_strength) * _brightness
	var g: float = lerpf(base_col.g, gray_val, _gray_strength) * _brightness
	var b: float = lerpf(base_col.b, gray_val, _gray_strength) * _brightness
	_count_label.add_theme_color_override(
		"font_color", Color(r, g, b)
	)


func _on_anim_finished() -> void:
	if not _toggled_on:
		_card_angles = [0.0] as Array[float]
		_draw_ctrl.queue_redraw()


func _draw_cards() -> void:
	var ptex: Texture2D = load(
		UIHelpers.PARCHMENT_PATH
	) as Texture2D
	var cw := float(UIHelpers.CARD_WIDTH) * ICON_CARD_SCALE
	var ch := float(UIHelpers.CARD_HEIGHT) * ICON_CARD_SCALE
	var card_r := float(
		UIHelpers.CARD_CORNER_RADIUS
	) * ICON_CARD_SCALE
	# Pivot = bottom center of icon area
	var pivot_x := size.x * 0.5
	var pivot_y := float(GLOW_PAD) + float(_pile_height) * 0.9
	var brightness := _brightness
	for i in _card_angles.size():
		var angle: float = _card_angles[i]
		_draw_rotated_card(
			_draw_ctrl, ptex, cw, ch, card_r,
			pivot_x, pivot_y, angle, brightness,
		)


func _draw_rotated_card(
	ctrl: Control, ptex: Texture2D,
	cw: float, ch: float, card_r: float,
	pivot_x: float, pivot_y: float,
	angle: float, brightness: float,
) -> void:
	# Card rect: bottom-center at origin, extends up
	var raw := UIHelpers._rounded_rect_points(
		-cw * 0.5, -ch, cw, ch, card_r, 6,
	)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var zoom := 1.5
	for p_idx in range(raw.size()):
		var c: Vector2 = raw[p_idx]
		# Rotate around bottom-center (origin = 0,0)
		var rx := c.x * cos(angle) - c.y * sin(angle)
		var ry := c.x * sin(angle) + c.y * cos(angle)
		pts.append(Vector2(pivot_x + rx, pivot_y + ry))
		uvs.append(Vector2(
			(0.5 - 0.5 / zoom)
				+ ((c.x + cw * 0.5) / cw) / zoom,
			(0.5 - 0.5 / zoom)
				+ ((c.y + ch) / ch) / zoom,
		))
	var base: Color
	if _is_face_down:
		base = Color(0.35, 0.25, 0.15, 1.0)
	else:
		base = Color(0.85, 0.75, 0.6, 1.0)
	var gray: float = (
		base.r * 0.3 + base.g * 0.59 + base.b * 0.11
	) * 0.6
	var r: float = lerpf(base.r, gray, _gray_strength) * brightness
	var g: float = lerpf(base.g, gray, _gray_strength) * brightness
	var b: float = lerpf(base.b, gray, _gray_strength) * brightness
	var tint := Color(r, g, b, 1.0)
	if ptex:
		var colors := PackedColorArray()
		colors.append(tint)
		ctrl.draw_polygon(pts, colors, uvs, ptex)
	else:
		ctrl.draw_colored_polygon(pts, tint)
	var border_pts := PackedVector2Array()
	for b_idx in range(raw.size()):
		var c: Vector2 = raw[b_idx]
		var rx := c.x * cos(angle) - c.y * sin(angle)
		var ry := c.x * sin(angle) + c.y * cos(angle)
		border_pts.append(Vector2(pivot_x + rx, pivot_y + ry))
	var bb := Color(0.65, 0.5, 0.2)
	var bg_val: float = (
		bb.r * 0.3 + bb.g * 0.59 + bb.b * 0.11
	) * 0.6
	var br: float = lerpf(bb.r, bg_val, _gray_strength) * brightness
	var bgg: float = lerpf(bb.g, bg_val, _gray_strength) * brightness
	var bbl: float = lerpf(bb.b, bg_val, _gray_strength) * brightness
	for j in range(border_pts.size()):
		var k: int = (j + 1) % border_pts.size()
		ctrl.draw_line(
			border_pts[j], border_pts[k],
			Color(br, bgg, bbl), 6.0,
		)


func _has_point(point: Vector2) -> bool:
	var card_rect := Rect2(
		Vector2(
			float(GLOW_PAD) + (float(size.x) - float(GLOW_PAD) * 2 - float(_pile_width)) * 0.5,
			float(GLOW_PAD),
		),
		Vector2(float(_pile_width) + 50, float(_pile_height)),
	)
	return card_rect.has_point(point)


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
		clicked.emit()
		get_viewport().set_input_as_handled()


func store_original_pos() -> void:
	_original_pos = position


func animate_to(target: Vector2, dur: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(
		self, "position", target - Vector2(GLOW_PAD, GLOW_PAD),
		dur,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	return tw


func animate_back(dur: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(
		self, "position", _original_pos, dur,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	return tw


static func _create_glow_shader() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = (
		"shader_type canvas_item;\n"
		+ "uniform float glow_size = 0.08;\n"
		+ "uniform float glow_strength = 0.0;\n"
		+ "uniform vec3 glow_color = vec3(0.9, 0.8, 0.6);\n"
		+ "uniform vec2 hole_center = vec2(0.5, 0.5);\n"
		+ "uniform float hole_radius = 0.0;\n"
		+ "void fragment() {\n"
		+ "  vec4 tex = texture(TEXTURE, UV);\n"
		+ "  float acc = 0.0;\n"
		+ "  float total = 0.0;\n"
		+ "  for (int r = 1; r <= 12; r++) {\n"
		+ "    float rd = glow_size * float(r) / 12.0;\n"
		+ "    float w = exp(-3.0 * float(r) / 12.0);\n"
		+ "    for (int i = 0; i < 16; i++) {\n"
		+ "      float a = float(i) / 16.0 * 6.2832;\n"
		+ "      vec2 off = vec2(cos(a), sin(a)) * rd;\n"
		+ "      acc += texture(TEXTURE, UV + off).a * w;\n"
		+ "      total += w;\n"
		+ "    }\n"
		+ "  }\n"
		+ "  float d = distance(UV, hole_center);\n"
		+ "  float hole = smoothstep("
		+ "hole_radius - 0.02, hole_radius, d);\n"
		+ "  float card_a = tex.a * hole;\n"
		+ "  float glow = (acc / total)"
		+ " * (1.0 - card_a) * glow_strength * 0.35;\n"
		+ "  vec3 col = mix(glow_color, tex.rgb, card_a);\n"
		+ "  float fa = max(card_a, glow);\n"
		+ "  COLOR = vec4(col, fa);\n"
		+ "}\n"
	)
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat


static func _create_grayscale_shader() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = (
		"shader_type canvas_item;\n"
		+ "uniform float strength : hint_range(0.0, 1.0) = 0.0;\n"
		+ "void fragment() {\n"
		+ "  vec4 tex = texture(TEXTURE, UV);\n"
		+ "  float gray = dot(tex.rgb, vec3(0.3, 0.59, 0.11));\n"
		+ "  vec3 dimmed = vec3(gray) * 0.6;\n"
		+ "  COLOR = vec4(mix(tex.rgb, dimmed, strength), tex.a);\n"
		+ "}\n"
	)
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat
