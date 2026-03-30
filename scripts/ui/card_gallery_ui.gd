class_name CardGalleryUI
extends Control

signal closing
signal closed
signal card_drag_requested(card: CardData, mouse_pos: Vector2)
signal filter_changed

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
var _card_nodes: Array = []
var _cards_built: bool = false
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
	_hand_btn.set_title("Hand")
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
	visible = true
	var vp_size := get_viewport().get_visible_rect().size
	_position_hand_btn(vp_size)
	_build_all_cards.call_deferred()
	_layout_visible_cards.call_deferred()
	_hand_btn.visible = true
	_hand_btn.set_gallery_mode(true)
	_update_hand_visual()
	# Fly hand button in from below
	var final_y: float = _hand_btn.position.y
	_hand_btn.position.y = vp_size.y + _hand_btn.size.y
	var hand_tw := _hand_btn.create_tween()
	hand_tw.tween_property(
		_hand_btn, "position:y", final_y, ANIM_DURATION,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_animating = true
	var vp_h: float = vp_size.y
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
	_hand_btn.set_gallery_mode(false)
	# Fly hand button out below
	var fly_out_y: float = (
		get_viewport().get_visible_rect().size.y
		+ _hand_btn.size.y
	)
	var hand_tw := _hand_btn.create_tween()
	hand_tw.tween_property(
		_hand_btn, "position:y", fly_out_y, ANIM_DURATION,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	hand_tw.tween_callback(func() -> void:
		_hand_btn.visible = false
	)
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
		_card_nodes.clear()
		_cards_built = false
		closed.emit()
	)


func toggle_filter(pile: String) -> void:
	var was_on: bool = false
	match pile:
		"draw": was_on = _show_draw
		"hand": was_on = _show_hand
		"discard": was_on = _show_discard
	_show_draw = false
	_show_hand = false
	_show_discard = false
	if not was_on:
		match pile:
			"draw": _show_draw = true
			"hand": _show_hand = true
			"discard": _show_discard = true
	_scroll_offset = 0.0
	_layout_visible_cards()
	_apply_scroll()
	_update_hand_visual()
	filter_changed.emit()


func update_hand_toggle() -> void:
	if _hand_btn:
		_hand_btn.set_toggled(_show_hand)


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


func _build_all_cards() -> void:
	# Clear old cards
	for child in _container.get_children():
		child.queue_free()
	_card_nodes.clear()

	var all_cards: Array[Array] = []
	for card in _draw_cards:
		all_cards.append([card, "draw"])
	for card in _hand_cards:
		all_cards.append([card, "hand"])
	for card in _discard_cards:
		all_cards.append([card, "discard"])

	for entry in all_cards:
		var card: CardData = entry[0] as CardData
		var pile: String = entry[1] as String
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
		_card_nodes.append({
			"node": outer, "card": card, "pile": pile,
		})
	_cards_built = true


func _layout_visible_cards() -> void:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var side_margin: float = 40.0
	var area_w: float = vp_size.x - side_margin * 2.0
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
	for entry in _card_nodes:
		var node: Control = entry["node"] as Control
		var pile: String = entry["pile"] as String
		var show := false
		match pile:
			"draw": show = _show_draw
			"hand": show = _show_hand
			"discard": show = _show_discard
		node.visible = show
		if show:
			var x: float = (
				side_margin + PADDING + col * (cw + COL_GAP)
			)
			var y: float = PADDING + row * (ch + ROW_GAP)
			node.scale = Vector2(card_scale, card_scale)
			node.position = Vector2(x, y)
			col += 1
			if col >= COLS:
				col = 0
				row += 1

	@warning_ignore("integer_division")
	var visible_count := 0
	for entry in _card_nodes:
		var pile: String = entry["pile"] as String
		match pile:
			"draw":
				if _show_draw: visible_count += 1
			"hand":
				if _show_hand: visible_count += 1
			"discard":
				if _show_discard: visible_count += 1
	@warning_ignore("integer_division")
	var total_rows: int = (visible_count + COLS - 1) / COLS
	var total_h: float = (
		PADDING * 2 + total_rows * (ch + ROW_GAP)
		- ROW_GAP
	)
	var usable_h: float = vp_size.y - _bottom_reserve
	_max_scroll = maxf(0.0, total_h - usable_h)


func _position_hand_btn(vp_size: Vector2) -> void:
	var btn_h := _hand_btn.size.y
	var target_y := vp_size.y - btn_h - 20.0
	_bottom_reserve = vp_size.y - target_y
	_hand_btn.position = Vector2(
		(vp_size.x - _hand_btn.size.x) * 0.5,
		target_y,
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
