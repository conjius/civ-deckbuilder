class_name YieldPickerUI
extends Control

signal resource_chosen(res_type: CardData.ResourceType)

var _buttons: Array[Control] = []
var _labels: Array[Label] = []
var _glow_ctrls: Array[Control] = []
var _dim: ColorRect
var _title: Label
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _btn_targets: Array[Vector2] = []
var _label_targets: Array[Vector2] = []
var _title_target: Vector2 = Vector2.ZERO
var _in_gallery: bool = false
var _btn_size: Vector2 = Vector2.ZERO
var _base_scale: float = 1.0


func show_choices(
	types: Array[CardData.ResourceType],
) -> void:
	_clear()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(PRESET_FULL_RECT)
	size = get_viewport().get_visible_rect().size

	_dim = ColorRect.new()
	_dim.set_anchors_preset(PRESET_FULL_RECT)
	_dim.color = Color(0, 0, 0, 0)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)

	var tw_dim := _dim.create_tween()
	tw_dim.tween_property(_dim, "color:a", 0.4, 0.2)

	var vp := get_viewport().get_visible_rect().size
	var circle_r := float(UIHelpers.CARD_WIDTH) * 0.6
	_btn_size = Vector2(circle_r * 2, circle_r * 2 + 50)
	var spacing := 60.0
	var total_w := float(types.size()) * _btn_size.x
	if types.size() > 1:
		total_w += spacing
	var start_x := (vp.x - total_w) * 0.5
	var center_y := vp.y * 0.52

	_title = Label.new()
	_title.text = "Choose Resource to Gather:"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.size = Vector2(vp.x, 60)
	_title_target = Vector2(
		0, center_y - _btn_size.y * 0.5 - 130
	)
	_title.position = _title_target
	_title.add_theme_font_override("font", _font_bold)
	_title.add_theme_font_size_override(
		"font_size", int(22 * UIHelpers.UI_SCALE)
	)
	_title.add_theme_color_override(
		"font_color", Color(0.95, 0.88, 0.7)
	)
	_title.add_theme_constant_override("outline_size", 4)
	_title.add_theme_color_override(
		"font_outline_color", Color(0.15, 0.1, 0.05)
	)
	_title.modulate.a = 0.0
	add_child(_title)
	_title.create_tween().tween_property(
		_title, "modulate:a", 1.0, 0.3
	)

	for i in range(types.size()):
		var res_type: CardData.ResourceType = types[i]
		var btn := _create_choice_button(res_type, _btn_size, i)
		add_child(btn)
		var target := Vector2(
			start_x + float(i) * (_btn_size.x + spacing),
			center_y - _btn_size.y * 0.5,
		)
		_btn_targets.append(target)
		btn.position = Vector2(target.x, vp.y)
		btn.modulate.a = 0.0
		var tw := btn.create_tween()
		tw.set_parallel(true)
		tw.tween_property(
			btn, "position", target, 0.35,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_OUT
		).set_delay(float(i) * 0.1)
		tw.tween_property(
			btn, "modulate:a", 1.0, 0.2,
		).set_delay(float(i) * 0.1)
		_buttons.append(btn)


func hide_choices() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _dim:
		_dim.create_tween().tween_property(
			_dim, "color:a", 0.0, 0.2
		)
	if _title:
		_title.create_tween().tween_property(
			_title, "modulate:a", 0.0, 0.2
		)
	for i in range(_buttons.size()):
		var btn: Control = _buttons[i]
		var tw := btn.create_tween()
		tw.set_parallel(true)
		tw.tween_property(btn, "modulate:a", 0.0, 0.2)
		tw.tween_property(
			btn, "position:y", btn.position.y + 100.0, 0.25,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.3).timeout
	_clear()


func enter_gallery_mode() -> void:
	if _in_gallery:
		return
	_in_gallery = true
	_base_scale = 0.5
	var vp := get_viewport().get_visible_rect().size
	var small_scale := 0.5
	var dur := 0.35
	if _dim:
		_dim.visible = false
	if _title:
		_title.create_tween().tween_property(
			_title, "modulate:a", 0.0, dur
		)
	for i in range(_buttons.size()):
		var btn: Control = _buttons[i]
		var spacing := 50.0
		var small_w := _btn_size.x * small_scale
		var total := float(_buttons.size()) * small_w
		if _buttons.size() > 1:
			total += spacing
		# Pivot offset shifts visual position when scaled
		var pivot := btn.pivot_offset
		var pivot_shift_x := pivot.x * (1.0 - small_scale)
		var pivot_shift_y := pivot.y * (1.0 - small_scale)
		var sx := (vp.x - total) * 0.5
		var gallery_pos := Vector2(
			sx + float(i) * (small_w + spacing) - pivot_shift_x,
			vp.y - _btn_size.y * small_scale - 120
			- pivot_shift_y,
		)
		btn.z_index = 200
		var tw := btn.create_tween()
		tw.set_parallel(true)
		tw.tween_property(
			btn, "position", gallery_pos, dur,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(
			btn, "scale",
			Vector2(small_scale, small_scale), dur,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for label: Label in _labels:
		label.create_tween().tween_property(
			label, "modulate:a", 0.0, dur
		)


func exit_gallery_mode() -> void:
	if not _in_gallery:
		return
	_in_gallery = false
	_base_scale = 1.0
	var dur := 0.35
	if _dim:
		_dim.visible = true
	if _title:
		_title.create_tween().tween_property(
			_title, "modulate:a", 1.0, dur
		)
	for i in range(_buttons.size()):
		var btn: Control = _buttons[i]
		btn.z_index = 0
		var tw := btn.create_tween()
		tw.set_parallel(true)
		tw.tween_property(
			btn, "position", _btn_targets[i], dur,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(
			btn, "scale", Vector2(1.0, 1.0), dur,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for j in range(_labels.size()):
		var label: Label = _labels[j]
		label.create_tween().tween_property(
			label, "modulate:a", 1.0, dur
		)


func _create_choice_button(
	res_type: CardData.ResourceType,
	btn_size: Vector2, _btn_idx: int,
) -> Control:
	var container := Control.new()
	container.custom_minimum_size = btn_size
	container.size = btn_size
	container.mouse_filter = Control.MOUSE_FILTER_STOP

	var circle_d := btn_size.x
	var circle_r := circle_d * 0.5
	var glow_spread := circle_r * 0.4
	var glow_total := circle_d + glow_spread * 2
	var glow_ctrl := Control.new()
	glow_ctrl.size = Vector2(glow_total, glow_total)
	glow_ctrl.position = Vector2(-glow_spread, -glow_spread)
	glow_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow_ctrl.modulate.a = 0.0
	var gc := Vector2(glow_total * 0.5, glow_total * 0.5)
	glow_ctrl.draw.connect(func() -> void:
		var passes := 12
		for p in range(passes):
			var t := float(p) / float(passes)
			var r_val := circle_r + glow_spread * t
			var alpha := (1.0 - t) * (1.0 - t) * 0.08
			glow_ctrl.draw_circle(
				gc, r_val, Color(0.9, 0.8, 0.6, alpha)
			)
	)
	glow_ctrl.queue_redraw()
	container.add_child(glow_ctrl)
	_glow_ctrls.append(glow_ctrl)

	var circle_ctrl := Control.new()
	circle_ctrl.size = Vector2(circle_d, circle_d)
	circle_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tint := Color(0.35, 0.22, 0.12)
	var border_color := Color(0.65, 0.5, 0.2)
	var border_w := 6.0
	var ptex: Texture2D = load(
		UIHelpers.PARCHMENT_PATH
	) as Texture2D
	circle_ctrl.draw.connect(func() -> void:
		var center := Vector2(circle_r, circle_r)
		var segments := 64
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		var zoom := 1.5
		for s in range(segments):
			var a := float(s) / float(segments) * TAU
			var px := center.x + cos(a) * circle_r
			var py := center.y + sin(a) * circle_r
			pts.append(Vector2(px, py))
			uvs.append(Vector2(
				(0.5 - 0.5 / zoom) + (px / circle_d) / zoom,
				(0.5 - 0.5 / zoom) + (py / circle_d) / zoom,
			))
		if ptex:
			var colors := PackedColorArray()
			colors.append(tint)
			circle_ctrl.draw_polygon(
				pts, colors, uvs, ptex
			)
		else:
			circle_ctrl.draw_colored_polygon(pts, tint)
		circle_ctrl.draw_arc(
			center, circle_r - border_w * 0.5,
			0.0, TAU, 64, border_color, border_w,
		)
	)
	circle_ctrl.queue_redraw()
	container.add_child(circle_ctrl)

	var icon_name: String
	var label_text: String
	if res_type == CardData.ResourceType.FOOD:
		icon_name = "Food"
		label_text = "Food"
	else:
		icon_name = "Materials"
		label_text = "Materials"

	var icon_path: String = UIHelpers.ENTITY_ICONS.get(
		icon_name, ""
	) as String
	if icon_path != "":
		var tex: Texture2D = load(icon_path) as Texture2D
		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.stretch_mode = (
				TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			var icon_sz := circle_d * 0.5
			icon.custom_minimum_size = Vector2(icon_sz, icon_sz)
			icon.size = Vector2(icon_sz, icon_sz)
			icon.position = Vector2(
				(circle_d - icon_sz) * 0.5,
				(circle_d - icon_sz) * 0.5,
			)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			container.add_child(icon)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(btn_size.x, 40)
	label.position = Vector2(0, circle_d + 10)
	label.add_theme_font_override("font", _font_bold)
	label.add_theme_font_size_override(
		"font_size", int(16 * UIHelpers.UI_SCALE)
	)
	label.add_theme_color_override(
		"font_color", Color(0.95, 0.88, 0.7)
	)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_color_override(
		"font_outline_color", Color(0.15, 0.1, 0.05)
	)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)
	_labels.append(label)
	_label_targets.append(label.position)

	container.mouse_entered.connect(func() -> void:
		var s := _base_scale
		glow_ctrl.create_tween().tween_property(
			glow_ctrl, "modulate:a", 1.0, 0.2,
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		container.create_tween().tween_property(
			container, "scale",
			Vector2(s * 1.08, s * 1.08), 0.15,
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	)
	container.mouse_exited.connect(func() -> void:
		var s := _base_scale
		glow_ctrl.create_tween().tween_property(
			glow_ctrl, "modulate:a", 0.0, 0.25,
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		container.create_tween().tween_property(
			container, "scale", Vector2(s, s), 0.2,
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	)
	container.gui_input.connect(func(event: InputEvent) -> void:
		var mb := event as InputEventMouseButton
		if mb and mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				resource_chosen.emit(res_type)
				get_viewport().set_input_as_handled()
	)
	container.pivot_offset = Vector2(
		btn_size.x * 0.5, btn_size.y * 0.4
	)
	return container


func _clear() -> void:
	for child in get_children():
		child.queue_free()
	_buttons.clear()
	_labels.clear()
	_glow_ctrls.clear()
	_btn_targets.clear()
	_label_targets.clear()
	_dim = null
	_title = null
