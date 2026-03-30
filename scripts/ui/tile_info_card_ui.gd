extends DarkCardUI

var _title_label: Label
var _yield_container: VBoxContainer
var _original_x: float = 0.0
var _current_terrain_name: String = ""


func _ready() -> void:
	setup_card()

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_override("font", _font_bold)
	_title_label.add_theme_font_size_override(
		"font_size", UIHelpers.s(11)
	)
	_title_label.add_theme_color_override(
		"font_color", Color(0.95, 0.88, 0.7)
	)
	_title_label.position = Vector2(0, 8)
	_title_label.size = Vector2(
		float(card_w), UIHelpers.sf(16.0)
	)
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_clip.add_child(_title_label)

	_yield_container = VBoxContainer.new()
	_yield_container.position = Vector2(0, UIHelpers.sf(22.0))
	_yield_container.size = Vector2(
		float(card_w),
		float(card_h) - UIHelpers.sf(22.0),
	)
	_yield_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_yield_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_clip.add_child(_yield_container)

	var card_title := Label.new()
	card_title.text = "Terrain"
	card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_title.add_theme_font_override("font", _font_bold)
	card_title.add_theme_font_size_override(
		"font_size", UIHelpers.s(10)
	)
	card_title.add_theme_color_override(
		"font_color", Color(0.85, 0.78, 0.65)
	)
	card_title.position = Vector2(
		0, size.y - float(GLOW_PAD) + 3.0
	)
	card_title.size = Vector2(
		float(size.x), UIHelpers.sf(14.0)
	)
	card_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card_title)


func update_info(
	terrain_name: String, yields: Array[String],
) -> void:
	if terrain_name == _current_terrain_name:
		return
	_current_terrain_name = terrain_name
	if terrain_name == "":
		_title_label.text = ""
		for child in _yield_container.get_children():
			child.queue_free()
		return
	_title_label.text = terrain_name
	if yields.is_empty():
		_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_title_label.position.y = 0.0
		_title_label.size.y = float(card_h)
	else:
		_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_title_label.position.y = 8.0
		_title_label.size.y = UIHelpers.sf(16.0)
	for child in _yield_container.get_children():
		child.queue_free()
	for y_text in yields:
		var lbl := RichTextLabel.new()
		lbl.bbcode_enabled = true
		lbl.fit_content = true
		lbl.add_theme_font_override("normal_font", _font_bold)
		lbl.add_theme_font_size_override(
			"normal_font_size", UIHelpers.s(9)
		)
		lbl.add_theme_color_override(
			"default_color", Color(0.95, 0.88, 0.7)
		)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UIHelpers.set_bbcode(
			lbl, "[center]" + y_text + "[/center]"
		)
		_yield_container.add_child(lbl)


func slide_out_left() -> void:
	var tw := create_tween()
	tw.tween_property(
		self, "position:x", -size.x - 50.0, 0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func slide_in_from_left() -> void:
	var tw := create_tween()
	tw.tween_property(
		self, "position:x", _original_x, 0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func store_original_pos() -> void:
	_original_x = position.x
