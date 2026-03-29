class_name CardPileUI
extends Control

signal clicked

const GLOW_PAD := 30

var _count_label: Label
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _is_face_down: bool = false
var _pile_width: int
var _pile_height: int
var _original_pos: Vector2 = Vector2.ZERO
var _toggled_on: bool = false
var _hovered: bool = false
var _glow_mat: ShaderMaterial


func setup(face_down: bool) -> void:
	_is_face_down = face_down
	_pile_width = int(float(UIHelpers.CARD_WIDTH) * 0.5)
	_pile_height = int(float(UIHelpers.CARD_HEIGHT) * 0.5)
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
	var sv := SubViewport.new()
	sv.size = Vector2i(total_w, total_h)
	sv.transparent_bg = true
	svc.add_child(sv)

	if face_down:
		var card_back := UIHelpers.create_card_back()
		card_back.scale = Vector2(0.5, 0.5)
		card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_back.position = Vector2(GLOW_PAD, GLOW_PAD)
		sv.add_child(card_back)
	else:
		var face := UIHelpers.create_card_back_light()
		face.scale = Vector2(0.5, 0.5)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		face.position = Vector2(GLOW_PAD, GLOW_PAD)
		sv.add_child(face)

	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_count_label.position = Vector2(GLOW_PAD, GLOW_PAD)
	_count_label.size = Vector2(_pile_width, _pile_height)
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


func update_count(count: int) -> void:
	_count_label.text = str(count)
	visible = count > 0


func set_toggled(value: bool) -> void:
	_toggled_on = value
	_update_glow()


func _on_hover_enter() -> void:
	_hovered = true
	_update_glow()


func _on_hover_exit() -> void:
	_hovered = false
	_update_glow()


func _update_glow() -> void:
	var target := 1.0 if (_toggled_on or _hovered) else 0.0
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
		+ "uniform float glow_size = 0.1;\n"
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
		+ " * (1.0 - tex.a) * glow_strength;\n"
		+ "  vec3 col = mix(glow_color, tex.rgb, tex.a);\n"
		+ "  float fa = max(tex.a, glow);\n"
		+ "  COLOR = vec4(col, fa);\n"
		+ "}\n"
	)
	var mat := ShaderMaterial.new()
	mat.shader = shader
	return mat
