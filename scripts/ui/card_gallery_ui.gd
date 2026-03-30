class_name CardGalleryUI
extends Control

signal closing
signal closed
signal card_drag_requested(card: CardData, mouse_pos: Vector2)

const COLS := 5
const ROW_GAP := 20
const COL_GAP := 16
const PADDING := 30
const ANIM_DURATION := 0.35
const HAND_BTN_GAP := 20

var _draw_cards: Array[CardData] = []
var _hand_cards: Array[CardData] = []
var _discard_cards: Array[CardData] = []
var _show_draw: bool = false
var _show_hand: bool = true
var _show_discard: bool = false
var _scroll_offset: float = 0.0
var _max_scroll: float = 0.0
var _clip_wrapper: Control
var _container: Control
var _animating: bool = false
var _hand_btn: CardPileUI
var _hand_btn_height: float = 0.0
var _bottom_reserve: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)

	_clip_wrapper = Control.new()
	_clip_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip_wrapper.clip_contents = true
	add_child(_clip_wrapper)

	_container = Control.new()
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip_wrapper.add_child(_container)

	_hand_btn = CardPileUI.new()
	_hand_btn.setup(false)
	_hand_btn.set_toggled(true)
	_hand_btn.visible = false
	_hand_btn.z_index = 100
	_hand_btn.clicked.connect(func() -> void:
		if not _animating:
			toggle_filter("hand")
	)
	add_child(_hand_btn)


func show_gallery(
	draw: Array[CardData],
	hand: Array[CardData],
	discard: Array[CardData],
	initial_draw: bool = false,
	initial_hand: bool = true,
	initial_discard: bool = false,
) -> void:
	_draw_cards = draw
	_hand_cards = hand
	_discard_cards = discard
	_hand_btn.update_count(hand.size(), false)
	_hand_btn.set_gallery_mode(true)
	_show_draw = initial_draw
	_show_hand = initial_hand
	_show_discard = initial_discard
	_scroll_offset = 0.0
	_rebuild()
	visible = true
	_hand_btn.visible = true
	_update_hand_visual()
	_animating = true
	var vp_h: float = get_viewport().get_visible_rect().size.y
	_container.position.y = vp_h
	var tween := create_tween()
	tween.tween_property(
		_container, "position:y", -_scroll_offset,
		ANIM_DURATION,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(
		func() -> void: _animating = false
	)


func hide_gallery() -> void:
	_animating = true
	closing.emit()
	_hand_btn.visible = false
	_hand_btn.set_gallery_mode(false)
	var vp_h: float = get_viewport().get_visible_rect().size.y
	var past_middle: bool = _scroll_offset > _max_scroll * 0.5
	var target_y: float
	if past_middle:
		target_y = -vp_h - _scroll_offset
	else:
		target_y = vp_h
	var tween := create_tween()
	tween.tween_property(
		_container, "position:y", target_y,
		ANIM_DURATION,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		visible = false
		_animating = false
		for child in _container.get_children():
			child.queue_free()
		closed.emit()
	)


func toggle_filter(pile: String) -> void:
	match pile:
		"draw":
			_show_draw = not _show_draw
		"hand":
			_show_hand = not _show_hand
		"discard":
			_show_discard = not _show_discard
	_scroll_offset = 0.0
	_rebuild()
	_apply_scroll()
	_update_hand_visual()


func update_hand_count(count: int) -> void:
	if _hand_btn:
		_hand_btn.update_count(count, false)


func _update_hand_visual() -> void:
	if _hand_btn:
		_hand_btn.set_toggled(_show_hand)


func _get_filtered_cards() -> Array[CardData]:
	var result: Array[CardData] = []
	if _show_draw:
		result.append_array(_draw_cards)
	if _show_hand:
		result.append_array(_hand_cards)
	if _show_discard:
		result.append_array(_discard_cards)
	return result


func _rebuild() -> void:
	for child in _container.get_children():
		child.queue_free()

	var cards := _get_filtered_cards()
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var pile_inset: float = (
		float(UIHelpers.CARD_WIDTH) * 0.5 + 200.0
	)
	var area_w: float = vp_size.x - pile_inset * 2.0
	_position_hand_btn(vp_size)
	var cw: float = (
		(area_w - PADDING * 2 - COL_GAP * (COLS - 1))
		/ float(COLS)
	)
	var ch: float = cw * (
		float(UIHelpers.CARD_HEIGHT)
		/ float(UIHelpers.CARD_WIDTH)
	)
	var card_scale: float = cw / float(UIHelpers.CARD_WIDTH)

	var row := 0
	var col := 0
	for card in cards:
		var x: float = (
			pile_inset + PADDING + col * (cw + COL_GAP)
		)
		var y: float = PADDING + row * (ch + ROW_GAP)
		var sections: Array[PanelContainer] = []
		var outer := Control.new()
		outer.custom_minimum_size = Vector2(
			UIHelpers.CARD_WIDTH, UIHelpers.CARD_HEIGHT
		)
		outer.size = Vector2(
			UIHelpers.CARD_WIDTH, UIHelpers.CARD_HEIGHT
		)
		outer.mouse_filter = Control.MOUSE_FILTER_STOP
		CardFaceBuilder.build_face(outer, card, sections)
		outer.scale = Vector2(card_scale, card_scale)
		outer.position = Vector2(x, y)
		var card_ref: CardData = card
		outer.gui_input.connect(
			func(event: InputEvent) -> void:
				if _animating:
					return
				if event is InputEventMouseButton:
					if (event.button_index == MOUSE_BUTTON_LEFT
						and event.pressed
					):
						card_drag_requested.emit(
							card_ref, event.global_position
						)
						get_viewport().set_input_as_handled()
		)
		_container.add_child(outer)

		col += 1
		if col >= COLS:
			col = 0
			row += 1

	@warning_ignore("integer_division")
	var total_rows: int = (cards.size() + COLS - 1) / COLS
	var total_h: float = (
		PADDING * 2 + total_rows * (ch + ROW_GAP)
		- ROW_GAP
	)
	var usable_h: float = vp_size.y - _bottom_reserve
	_max_scroll = maxf(0.0, total_h - usable_h)


func _position_hand_btn(vp_size: Vector2) -> void:
	var pile_h: float = float(UIHelpers.CARD_HEIGHT) * 0.5
	_hand_btn_height = pile_h + HAND_BTN_GAP * 2 + 130
	_bottom_reserve = _hand_btn_height
	_hand_btn.position = Vector2(
		(vp_size.x - _hand_btn.size.x) * 0.5,
		vp_size.y - _hand_btn_height,
	)
	_clip_wrapper.position = Vector2.ZERO
	_clip_wrapper.size = Vector2(
		vp_size.x, vp_size.y - _bottom_reserve,
	)




func _apply_scroll() -> void:
	_container.position.y = -_scroll_offset


func _input(event: InputEvent) -> void:
	if not visible or _animating:
		return
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_RIGHT
			and event.pressed
		):
			hide_gallery()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll_offset = maxf(
				0.0, _scroll_offset - 40.0
			)
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
	elif event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()
