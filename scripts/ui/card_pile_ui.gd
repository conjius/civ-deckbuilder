class_name CardPileUI
extends Control

signal clicked

const GLOW_PAD := 40
const FAN_CARDS := 4
const FAN_SPREAD := 60.0
const CARD_SCALE := 0.5

var _count_label: Label
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _is_face_down: bool = false
var _pile_width: int
var _pile_height: int
var _original_pos: Vector2 = Vector2.ZERO
var _toggled_on: bool = false
var _hovered: bool = false
var _glow_mat: ShaderMaterial
var _sv: SubViewport
var _draw_ctrl: Control
var _grayscale_mat: ShaderMaterial


func setup(face_down: bool) -> void:
	_is_face_down = face_down
	_pile_width = int(float(UIHelpers.CARD_WIDTH) * CARD_SCALE)
	_pile_height = int(float(UIHelpers.CARD_HEIGHT) * CARD_SCALE)
	var total_w: int = _pile_width + GLOW_PAD * 2
	var total_h: int = _pile_height + GLOW_PAD * 2
	custom_minimum_size = Vector2(total_w, total_h)
	size = Vector2(total_w, total_h)
	mouse_filter = Control.MOUSE_FILTER_STOP
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

	_grayscale_mat = _create_grayscale_shader()

	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.position = Vector2.ZERO
	_count_label.size = Vector2(total_w, total_h)
	_count_label.add_theme_font_override("font", _font_bold)
	_count_label.add_theme_font_size_override(
		"font_size", int(18 * UIHelpers.UI_SCALE)
	)
	if face_down:
		_count_label.add_theme_color_override(
			"font_color", Color(0.95, 0.88, 0.7)
		)
	else:
		_count_label.add_theme_color_override(
			"font_color", Color(0.3, 0.2, 0.1)
		)
	_count_label.add_theme_constant_override("outline_size", 3)
	_count_label.add_theme_color_override(
		"font_outline_color",
		Color(0.2, 0.15, 0.05) if face_down
		else Color(0.85, 0.78, 0.65),
	)
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_count_label)

	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)

	_rebuild_visual()


func update_count(count: int) -> void:
	_count_label.text = str(count)
	visible = count > 0


func set_toggled(value: bool) -> void:
	if _toggled_on == value:
		return
	_toggled_on = value
	_rebuild_visual()
	_update_glow()


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
	# Remove old draw connections
	if _draw_ctrl.draw.is_connected(_draw_cards_fan):
		_draw_ctrl.draw.disconnect(_draw_cards_fan)
	if _draw_ctrl.draw.is_connected(_draw_single_card):
		_draw_ctrl.draw.disconnect(_draw_single_card)
	# Apply grayscale when off
	if _toggled_on:
		_draw_ctrl.material = null
	else:
		_draw_ctrl.material = _grayscale_mat
	# Connect the right draw function
	if _toggled_on:
		_draw_ctrl.draw.connect(_draw_cards_fan)
	else:
		_draw_ctrl.draw.connect(_draw_single_card)
	_draw_ctrl.queue_redraw()


func _draw_cards_fan() -> void:
	var ptex: Texture2D = load(
		UIHelpers.PARCHMENT_PATH
	) as Texture2D
	var fan_scale := 0.6
	var hw := float(_pile_width) * 0.5 * fan_scale
	var hh := float(_pile_height) * fan_scale
	var card_r := float(
		UIHelpers.CARD_CORNER_RADIUS
	) * CARD_SCALE * fan_scale
	var cx := size.x * 0.5
	var cy := float(GLOW_PAD) + float(_pile_height) * 0.85
	var start_angle := -FAN_SPREAD * 0.5
	var step: float = FAN_SPREAD / float(FAN_CARDS - 1)
	for i in range(FAN_CARDS):
		var angle := deg_to_rad(start_angle + float(i) * step)
		_draw_rotated_card(
			_draw_ctrl, ptex, hw, hh, card_r,
			cx, cy, angle, 1.0,
		)


func _draw_single_card() -> void:
	var ptex: Texture2D = load(
		UIHelpers.PARCHMENT_PATH
	) as Texture2D
	var hw := float(_pile_width) * 0.5
	var hh := float(_pile_height)
	var card_r := float(UIHelpers.CARD_CORNER_RADIUS) * CARD_SCALE
	var cx := size.x * 0.5
	var cy := float(GLOW_PAD) + float(_pile_height) * 0.85
	_draw_rotated_card(
		_draw_ctrl, ptex, hw, hh, card_r,
		cx, cy, 0.0, 0.7,
	)


func _draw_rotated_card(
	ctrl: Control, ptex: Texture2D,
	hw: float, hh: float, card_r: float,
	cx: float, cy: float, angle: float,
	brightness: float,
) -> void:
	var raw := UIHelpers._rounded_rect_points(
		-hw * 0.5, -hh, hw, hh, card_r, 6,
	)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var zoom := 1.5
	for p_idx in range(raw.size()):
		var c: Vector2 = raw[p_idx]
		var rx := c.x * cos(angle) - c.y * sin(angle)
		var ry := c.x * sin(angle) + c.y * cos(angle)
		pts.append(Vector2(cx + rx, cy + ry))
		uvs.append(Vector2(
			(0.5 - 0.5 / zoom)
				+ ((c.x + hw * 0.5) / hw) / zoom,
			(0.5 - 0.5 / zoom)
				+ ((c.y + hh) / hh) / zoom,
		))
	var tint: Color
	if _is_face_down:
		tint = Color(
			0.35 * brightness, 0.25 * brightness,
			0.15 * brightness, 1.0,
		)
	else:
		tint = Color(
			0.85 * brightness, 0.75 * brightness,
			0.6 * brightness, 1.0,
		)
	if ptex:
		var colors := PackedColorArray()
		colors.append(tint)
		ctrl.draw_polygon(pts, colors, uvs, ptex)
	else:
		ctrl.draw_colored_polygon(pts, tint)
	# Border
	var border_pts := PackedVector2Array()
	for b_idx in range(raw.size()):
		var c: Vector2 = raw[b_idx]
		var rx := c.x * cos(angle) - c.y * sin(angle)
		var ry := c.x * sin(angle) + c.y * cos(angle)
		border_pts.append(Vector2(cx + rx, cy + ry))
	for j in range(border_pts.size()):
		var k: int = (j + 1) % border_pts.size()
		ctrl.draw_line(
			border_pts[j], border_pts[k],
			Color(
				0.65 * brightness, 0.5 * brightness,
				0.2 * brightness,
			), 4.0,
		)


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
		+ "uniform float glow_size = 0.2;\n"
		+ "uniform float glow_strength = 0.0;\n"
		+ "uniform vec3 glow_color = vec3(0.9, 0.8, 0.6);\n"
		+ "void fragment() {\n"
		+ "  vec4 tex = texture(TEXTURE, UV);\n"
		+ "  float acc = 0.0;\n"
		+ "  float total = 0.0;\n"
		+ "  for (int r = 1; r <= 8; r++) {\n"
		+ "    float rd = glow_size * float(r) / 8.0;\n"
		+ "    float w = 1.0 - float(r) / 9.0;\n"
		+ "    for (int i = 0; i < 16; i++) {\n"
		+ "      float a = float(i) / 16.0 * 6.2832;\n"
		+ "      vec2 off = vec2(cos(a), sin(a)) * rd;\n"
		+ "      acc += texture(TEXTURE, UV + off).a * w;\n"
		+ "      total += w;\n"
		+ "    }\n"
		+ "  }\n"
		+ "  float glow = (acc / total)"
		+ " * (1.0 - tex.a) * glow_strength * 0.5;\n"
		+ "  vec3 col = mix(glow_color, tex.rgb, tex.a);\n"
		+ "  float fa = max(tex.a, glow);\n"
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
		+ "void fragment() {\n"
		+ "  vec4 tex = texture(TEXTURE, UV);\n"
		+ "  float gray = dot(tex.rgb, vec3(0.3, 0.59, 0.11));\n"
		+ "  COLOR = vec4(vec3(gray) * 0.6, tex.a);\n"
		+ "}\n"
	)
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat
