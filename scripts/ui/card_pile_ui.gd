class_name CardPileUI
extends Control

var _count_label: Label
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _is_face_down: bool = false
var _pile_width: int
var _pile_height: int
var _original_pos: Vector2 = Vector2.ZERO


func setup(face_down: bool) -> void:
	_is_face_down = face_down
	_pile_width = int(float(UIHelpers.CARD_WIDTH) * 0.5)
	_pile_height = int(float(UIHelpers.CARD_HEIGHT) * 0.5)
	custom_minimum_size = Vector2(_pile_width, _pile_height)
	size = Vector2(_pile_width, _pile_height)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	if face_down:
		var card_back := UIHelpers.create_card_back()
		card_back.scale = Vector2(0.5, 0.5)
		card_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(card_back)
	else:
		var face := UIHelpers.create_card_back_light()
		face.scale = Vector2(0.5, 0.5)
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(face)

	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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


func update_count(count: int) -> void:
	_count_label.text = str(count)
	visible = count > 0


func store_original_pos() -> void:
	_original_pos = position


func animate_to(target: Vector2, dur: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(
		self, "position", target, dur,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	return tw


func animate_back(dur: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(
		self, "position", _original_pos, dur,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	return tw
