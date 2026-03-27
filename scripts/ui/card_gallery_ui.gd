class_name CardGalleryUI
extends Control

signal closed

const COLS := 5
const ROW_GAP := 20
const COL_GAP := 16
const PADDING := 30
const ANIM_DURATION := 0.35

var _cards: Array[CardData] = []
var _scroll_offset: float = 0.0
var _max_scroll: float = 0.0
var _container: Control
var _bg: ColorRect
var _animating: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_bg = ColorRect.new()
	_bg.color = Color(0.0, 0.0, 0.0, 0.0)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_container = Control.new()
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)


func show_gallery(cards: Array[CardData]) -> void:
	_cards = cards
	_scroll_offset = 0.0
	_rebuild()
	visible = true
	_animating = true
	var vp_h: float = get_viewport().get_visible_rect().size.y
	_container.position.y = vp_h
	_bg.color = Color(0.0, 0.0, 0.0, 0.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		_container, "position:y", -_scroll_offset,
		ANIM_DURATION,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		_bg, "color:a", 0.7, ANIM_DURATION,
	).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(
		func() -> void: _animating = false
	)


func hide_gallery() -> void:
	_animating = true
	var vp_h: float = get_viewport().get_visible_rect().size.y
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		_container, "position:y", vp_h,
		ANIM_DURATION,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(
		_bg, "color:a", 0.0, ANIM_DURATION,
	).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_callback(func() -> void:
		visible = false
		_animating = false
		for child in _container.get_children():
			child.queue_free()
		closed.emit()
	)


func _rebuild() -> void:
	for child in _container.get_children():
		child.queue_free()

	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var cw: float = (
		(vp_size.x - PADDING * 2 - COL_GAP * (COLS - 1))
		/ float(COLS)
	)
	var ch: float = cw * (
		float(UIHelpers.CARD_HEIGHT)
		/ float(UIHelpers.CARD_WIDTH)
	)
	var card_scale: float = cw / float(UIHelpers.CARD_WIDTH)

	var row := 0
	var col := 0
	for card in _cards:
		var x: float = PADDING + col * (cw + COL_GAP)
		var y: float = PADDING + row * (ch + ROW_GAP)
		var sections: Array[PanelContainer] = []
		var outer := Control.new()
		outer.custom_minimum_size = Vector2(
			UIHelpers.CARD_WIDTH, UIHelpers.CARD_HEIGHT
		)
		outer.size = Vector2(
			UIHelpers.CARD_WIDTH, UIHelpers.CARD_HEIGHT
		)
		outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		CardFaceBuilder.build_face(outer, card, sections)
		outer.scale = Vector2(card_scale, card_scale)
		outer.position = Vector2(x, y)
		_container.add_child(outer)

		col += 1
		if col >= COLS:
			col = 0
			row += 1

	@warning_ignore("integer_division")
	var total_rows: int = (_cards.size() + COLS - 1) / COLS
	var total_h: float = (
		PADDING * 2 + total_rows * (ch + ROW_GAP) - ROW_GAP
	)
	_max_scroll = maxf(0.0, total_h - vp_size.y)


func _apply_scroll() -> void:
	_container.position.y = -_scroll_offset


func _gui_input(event: InputEvent) -> void:
	if _animating:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			hide_gallery()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_offset = maxf(0.0, _scroll_offset - 40.0)
			_apply_scroll()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll_offset = minf(
				_max_scroll, _scroll_offset + 40.0
			)
			_apply_scroll()
			get_viewport().set_input_as_handled()
	if event is InputEventPanGesture:
		_scroll_offset = clampf(
			_scroll_offset + event.delta.y * 20.0,
			0.0, _max_scroll,
		)
		_apply_scroll()
		get_viewport().set_input_as_handled()
