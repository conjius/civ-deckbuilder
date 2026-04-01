extends DarkCardUI

signal pressed

var _tex: Texture2D = preload(
	"res://assets/icons/hourglass_64.svg"
)
var _icon: TextureRect
var _title_label: Label
var _hovering: bool = false
var _animating: bool = false
var _disabled: bool = false
var _glow_mat: ShaderMaterial
var _flip_dur := 0.15


func _ready() -> void:
	_is_dark = false
	setup_card()
	pivot_offset = Vector2(size.x * 0.5, size.y * 0.5)
	mouse_filter = Control.MOUSE_FILTER_PASS

	_glow_mat = CardPileUI._create_glow_shader()
	_glow_mat.set_shader_parameter("glow_strength", 0.0)
	var svc := get_child(0) as SubViewportContainer
	svc.material = _glow_mat

	var label_cx := pivot_x()
	var label_cy := pivot_y() - float(card_h) * 0.5
	_glow_mat.set_shader_parameter(
		"hole_center", Vector2(
			label_cx / float(size.x),
			label_cy / float(size.y),
		)
	)
	_glow_mat.set_shader_parameter(
		"hole_radius", 30.0 * UIHelpers.UI_SCALE / float(size.x)
	)
	_glow_mat.set_shader_parameter(
		"aspect", float(size.x) / float(size.y)
	)

	var icon_sz := float(card_w) * 0.5 * 1.3
	var icon_w := icon_sz * 1.1
	var icon_h := icon_sz * 0.9
	_icon = TextureRect.new()
	_icon.texture = _tex
	_icon.stretch_mode = TextureRect.STRETCH_SCALE
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.size = Vector2(icon_w, icon_h)
	_icon.position = Vector2(
		label_cx - icon_w * 0.5,
		label_cy - icon_h * 0.5,
	)
	_icon.pivot_offset = Vector2(icon_w * 0.5, icon_h * 0.5)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.modulate = Color(0.95, 0.88, 0.7)
	_icon.material = UIHelpers.create_icon_shadow_shader()
	add_child(_icon)

	_title_label = Label.new()
	_title_label.text = "End Turn"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", _font_bold)
	_title_label.add_theme_font_size_override(
		"font_size", UIHelpers.s(10)
	)
	_title_label.add_theme_color_override(
		"font_color", Color(0.85, 0.78, 0.65)
	)
	_title_label.position = Vector2(
		0, size.y - float(glow_pad) + 3.0
	)
	_title_label.size = Vector2(
		float(size.x), UIHelpers.sf(14.0)
	)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title_label)

	mouse_entered.connect(func() -> void:
		_hovering = true
		_update_hover()
	)
	mouse_exited.connect(func() -> void:
		_hovering = false
		_update_hover()
	)


func _has_point(point: Vector2) -> bool:
	var card_rect := Rect2(
		Vector2(visual_card_left_in_ctrl(), visual_card_top_in_ctrl()),
		Vector2(float(card_w), float(card_h)),
	)
	return card_rect.has_point(point)


func set_disabled(value: bool) -> void:
	_disabled = value
	modulate.a = 0.4 if _disabled else 1.0


func flip_to_dark() -> void:
	_do_flip(true)


func flip_to_light() -> void:
	_do_flip(false)


func _do_flip(to_dark: bool) -> void:
	if _is_dark == to_dark:
		return
	_animating = true
	var orig_sx: float = scale.x
	var tw := create_tween()
	tw.tween_property(
		self, "scale:x", 0.0, _flip_dur,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		_is_dark = to_dark
		_draw_ctrl.queue_redraw()
	)
	tw.tween_property(
		self, "scale:x", orig_sx, _flip_dur,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		_animating = false
		_update_hover()
	)


func _update_hover() -> void:
	if _animating:
		return
	var target := 1.0 if (_hovering and not _disabled) else 0.0
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
	if _disabled or _animating:
		return
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_LEFT
			and event.pressed
		):
			_on_clicked()
			accept_event()


func _on_clicked() -> void:
	flip_to_dark()
	var tw := create_tween()
	tw.tween_interval(_flip_dur * 2.0)
	tw.tween_callback(func() -> void:
		pressed.emit()
	)
