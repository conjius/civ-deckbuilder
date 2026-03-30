extends Control

signal pressed

const GLOW_PAD := 50

var _tex: Texture2D = preload(
	"res://assets/icons/hourglass_64.svg"
)
var _font_bold: Font = preload(
	"res://assets/fonts/Cinzel-Bold.ttf"
)
var _icon: TextureRect
var _title_label: Label
var _hovering: bool = false
var _animating: bool = false
var _disabled: bool = false
var _glow_mat: ShaderMaterial
var _draw_ctrl: Control
var _card_w: int
var _card_h: int


func _ready() -> void:
	_card_w = int(
		float(UIHelpers.CARD_WIDTH) * CardPileUI.ICON_CARD_SCALE
	)
	_card_h = int(
		float(UIHelpers.CARD_HEIGHT) * CardPileUI.ICON_CARD_SCALE
	)
	var total_w: int = _card_w + GLOW_PAD * 2 + 100
	var total_h: int = _card_h + GLOW_PAD * 2
	custom_minimum_size = Vector2(total_w, total_h)
	size = Vector2(total_w, total_h)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var svc := SubViewportContainer.new()
	svc.size = Vector2(total_w, total_h)
	svc.stretch = true
	svc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow_mat = CardPileUI._create_glow_shader()
	_glow_mat.set_shader_parameter("glow_strength", 0.0)
	svc.material = _glow_mat
	add_child(svc)
	var sv := SubViewport.new()
	sv.size = Vector2i(total_w, total_h)
	sv.transparent_bg = true
	svc.add_child(sv)

	_draw_ctrl = Control.new()
	_draw_ctrl.size = Vector2(total_w, total_h)
	_draw_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sv.add_child(_draw_ctrl)
	_draw_ctrl.draw.connect(_draw_card)
	_draw_ctrl.queue_redraw()

	# Hole punch uniforms
	var pivot_y: int = GLOW_PAD + int(float(_card_h) * 0.9)
	var label_cx: float = float(total_w) * 0.5
	var label_cy: float = float(pivot_y) - float(_card_h) * 0.5
	_glow_mat.set_shader_parameter(
		"hole_center", Vector2(
			label_cx / float(total_w),
			label_cy / float(total_h),
		)
	)
	_glow_mat.set_shader_parameter(
		"hole_radius", 22.0 / float(total_w)
	)
	_glow_mat.set_shader_parameter(
		"aspect", float(total_w) / float(total_h)
	)

	# Hourglass icon — inside the hole
	var icon_sz: float = float(_card_w) * 0.25
	_icon = TextureRect.new()
	_icon.texture = _tex
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.size = Vector2(icon_sz, icon_sz)
	_icon.position = Vector2(
		label_cx - icon_sz * 0.5,
		label_cy - icon_sz * 0.5,
	)
	_icon.pivot_offset = Vector2(icon_sz * 0.5, icon_sz * 0.5)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_icon.modulate = Color(0.95, 0.88, 0.7)
	_icon.material = UIHelpers.create_icon_shadow_shader()
	add_child(_icon)

	# Title below card
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
		0, size.y - float(GLOW_PAD) + 17.0
	)
	_title_label.size = Vector2(
		float(total_w), UIHelpers.sf(14.0)
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
		Vector2(
			float(GLOW_PAD)
			+ (float(size.x) - float(GLOW_PAD) * 2
			- float(_card_w)) * 0.5,
			float(GLOW_PAD),
		),
		Vector2(float(_card_w) + 50, float(_card_h)),
	)
	return card_rect.has_point(point)


func set_disabled(value: bool) -> void:
	_disabled = value
	modulate.a = 0.4 if _disabled else 1.0


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
	_animating = true
	_icon.modulate = Color(0.7, 0.65, 0.5)
	var tween := create_tween()
	tween.tween_property(
		_icon, "rotation", _icon.rotation + PI, 0.2
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		_animating = false
		_icon.modulate = Color(0.95, 0.88, 0.7)
		_update_hover()
		pressed.emit()
	)


func _draw_card() -> void:
	var ptex: Texture2D = load(
		UIHelpers.PARCHMENT_PATH
	) as Texture2D
	var cw := float(_card_w)
	var ch := float(_card_h)
	var card_r := float(
		UIHelpers.CARD_CORNER_RADIUS
	) * CardPileUI.ICON_CARD_SCALE
	var pivot_x := size.x * 0.5
	var pivot_y := float(GLOW_PAD) + float(_card_h) * 0.9
	var raw := UIHelpers._rounded_rect_points(
		-cw * 0.5, -ch, cw, ch, card_r, 6,
	)
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var zoom := 1.5
	for p_idx in range(raw.size()):
		var c: Vector2 = raw[p_idx]
		pts.append(Vector2(pivot_x + c.x, pivot_y + c.y))
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
	# Border
	var border_pts := PackedVector2Array()
	for b_idx in range(raw.size()):
		var c: Vector2 = raw[b_idx]
		border_pts.append(Vector2(pivot_x + c.x, pivot_y + c.y))
	for j in range(border_pts.size()):
		var k: int = (j + 1) % border_pts.size()
		_draw_ctrl.draw_line(
			border_pts[j], border_pts[k],
			Color(0.65, 0.5, 0.2), 6.0,
		)
