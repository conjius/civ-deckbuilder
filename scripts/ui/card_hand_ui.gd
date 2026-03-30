extends Control

signal card_dropped(card: CardData, target: Vector2i)
signal gallery_requested

var hex_map: Node3D
var camera: Camera3D
var card_effects: Node
var active_unit: Node3D
var arrow_indicator: Control
var deck_manager: DeckManager
var draw_pile_pos: Vector2 = Vector2.ZERO
var discard_pile_pos: Vector2 = Vector2.ZERO

var _card_display_scene: PackedScene = preload(
	"res://scenes/ui/card_display.tscn"
)
var _focused_card: Control = null
var _any_dragging: bool = false
var _dealing: bool = false
var _removing: bool = false
var _discarding_all: bool = false


func _ready() -> void:
	resized.connect(_layout_cards)


func show_cards(cards: Array[CardData], animate_draw: bool = true) -> void:
	_focused_card = null
	var old := get_children().duplicate()
	for child in old:
		remove_child(child)
		child.queue_free()
	for card in cards:
		_add_card_display(card, animate_draw)
	if animate_draw:
		_do_draw_anim.call_deferred()
	else:
		_layout_cards.call_deferred()


func discard_all(on_done: Callable = Callable()) -> void:
	_focused_card = null
	var cards := _get_card_children()
	if cards.is_empty():
		if on_done.is_valid():
			on_done.call()
		return
	_discarding_all = true
	var last_delay := float(cards.size() - 1) * 0.05
	for i in range(cards.size()):
		var card: Control = cards[i]
		var gpos: Vector2 = card.global_position
		remove_child(card)
		var parent: Node = self
		while parent and not parent is CanvasLayer:
			parent = parent.get_parent()
		if parent:
			parent.add_child(card)
		else:
			get_tree().root.add_child(card)
		card.global_position = gpos
		var delay := float(i) * 0.05
		var tw := card.create_tween()
		tw.tween_interval(delay)
		tw.set_parallel(true)
		var half_pile := Vector2(
			float(UIHelpers.CARD_WIDTH) * 0.25,
			float(UIHelpers.CARD_HEIGHT) * 0.25,
		)
		var disc_target := discard_pile_pos - half_pile
		tw.tween_property(
			card, "global_position", disc_target, 0.2,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_IN
		).set_delay(delay)
		tw.tween_property(
			card, "scale", Vector2(0.5, 0.5), 0.2,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_IN
		).set_delay(delay)
		tw.finished.connect(func() -> void:
			card.queue_free()
		)
	var total_time := last_delay + 0.25
	get_tree().create_timer(total_time).timeout.connect(
		func() -> void:
			_discarding_all = false
			if on_done.is_valid():
				on_done.call()
	)


func add_cards_to_hand(new_cards: Array[CardData]) -> void:
	for card in new_cards:
		_add_card_display(card, false)
		var cards := _get_card_children()
		var ctrl: Control = cards[cards.size() - 1]
		ctrl.scale = Vector2(0.0, 0.0)
		ctrl.modulate.a = 0.0
		var tw := ctrl.create_tween()
		tw.set_parallel(true)
		tw.tween_property(
			ctrl, "scale", UIHelpers.HAND_DEFAULT_SCALE, 0.3,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(
			ctrl, "modulate:a", 1.0, 0.2,
		)
	_layout_cards()


func _do_draw_anim() -> void:
	_dealing = true
	_layout_cards(false)
	var cards := _get_card_children()
	var local_draw := draw_pile_pos - global_position
	for i in range(cards.size()):
		var card: Control = cards[i]
		var target_pos := card.position
		var target_scale := card.scale
		var target_rot := card.rotation
		card.position = local_draw - card.size * 0.25
		card.scale = Vector2(0.5, 0.5)
		card.rotation = 0.0
		card.set_face_up(false)
		card.modulate.a = 0.0
		card.z_index = 100 + i
		var delay := float(i) * 0.18
		var dur := 0.7
		var flip_time := delay + dur * 0.35
		var flip_dur := 0.15
		# Position + rotation + Y scale
		var tw := card.create_tween()
		tw.set_parallel(true)
		tw.tween_property(
			card, "modulate:a", 1.0, 0.05,
		).set_delay(delay)
		tw.tween_property(
			card, "position", target_pos, dur,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_OUT
		).set_delay(delay)
		tw.tween_property(
			card, "scale:y", target_scale.y, dur,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_OUT
		).set_delay(delay)
		tw.tween_property(
			card, "rotation", target_rot, dur,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_OUT
		).set_delay(delay)
		var is_last: bool = i == cards.size() - 1
		tw.tween_callback(func() -> void:
			card.z_index = 0
			if is_last:
				_dealing = false
		).set_delay(delay + dur)
		# X scale: grow from 0.5 to mid, squeeze to 0, flip, stretch back
		var mid_sx: float = lerpf(0.5, target_scale.x, 0.35)
		var flip_tw := card.create_tween()
		flip_tw.tween_property(
			card, "scale:x", mid_sx, flip_time - delay,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_OUT
		).set_delay(delay)
		flip_tw.tween_property(
			card, "scale:x", 0.0, flip_dur,
		).set_trans(Tween.TRANS_SINE).set_ease(
			Tween.EASE_IN
		)
		flip_tw.tween_callback(func() -> void:
			card.set_face_up(true)
		)
		flip_tw.tween_property(
			card, "scale:x", target_scale.x, flip_dur,
		).set_trans(Tween.TRANS_SINE).set_ease(
			Tween.EASE_OUT
		)
		# Settle remaining x scale
		var remaining := dur - (flip_time - delay) - flip_dur * 2
		if remaining > 0.0:
			flip_tw.tween_property(
				card, "scale:x", target_scale.x, remaining,
			).set_trans(Tween.TRANS_CUBIC).set_ease(
				Tween.EASE_OUT
			)


func show_cards_with_drag(
	cards: Array[CardData], drag_card: CardData,
	mouse_pos: Vector2,
) -> void:
	_focused_card = null
	for child in get_children():
		child.queue_free()
	for card in cards:
		if card == drag_card:
			continue
		_add_card_display(card)
	var drag_display: Control = (
		_card_display_scene.instantiate()
	)
	add_child(drag_display)
	drag_display.setup(drag_card)
	drag_display.set_face_up(true)
	drag_display.hex_map = hex_map
	drag_display.camera = camera
	drag_display.card_effects = card_effects
	drag_display.active_unit = active_unit
	drag_display.arrow_indicator = arrow_indicator
	drag_display.drag_started.connect(_on_drag_started)
	drag_display.drag_ended.connect(_on_drag_ended)
	drag_display.pivot_offset = Vector2(
		UIHelpers.CARD_WIDTH * 0.5,
		float(UIHelpers.CARD_HEIGHT),
	)
	drag_display.scale = UIHelpers.HAND_FOCUS_SCALE
	drag_display.z_index = 100
	drag_display.global_position = (
		mouse_pos
		- drag_display.size * UIHelpers.HAND_FOCUS_SCALE * 0.5
	)
	_any_dragging = true
	drag_display._start_drag()
	_layout_cards.call_deferred()


func remove_card(card: CardData) -> void:
	for child in get_children():
		var ctrl := child as Control
		if ctrl == null:
			continue
		if ctrl.card_data == card:
			if ctrl == _focused_card:
				_focused_card = null
			var gpos: Vector2 = ctrl.global_position
			remove_child(ctrl)
			# Add to parent CanvasLayer so it stays visible
			var parent: Node = self
			while parent and not parent is CanvasLayer:
				parent = parent.get_parent()
			if parent:
				parent.add_child(ctrl)
			else:
				get_tree().root.add_child(ctrl)
			ctrl.global_position = gpos
			_animate_to_discard_pile(ctrl)
			break
	_layout_cards.call_deferred()



func _animate_to_discard_pile(card: Control) -> void:
	var half_pile := Vector2(
		float(UIHelpers.CARD_WIDTH) * 0.25,
		float(UIHelpers.CARD_HEIGHT) * 0.25,
	)
	var target := discard_pile_pos - half_pile
	card.z_index = 50
	var tw := card.create_tween()
	tw.set_parallel(true)
	tw.tween_property(
		card, "global_position", target, 0.25,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(
		card, "scale", Vector2(0.5, 0.5), 0.25,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.finished.connect(func() -> void:
		card.queue_free()
	)


func _add_card_display(
	card: CardData, face_down: bool = false,
) -> void:
	var display: Control = _card_display_scene.instantiate()
	add_child(display)
	display.setup(card)
	display.set_face_up(not face_down)
	display.hex_map = hex_map
	display.camera = camera
	display.card_effects = card_effects
	display.active_unit = active_unit
	display.arrow_indicator = arrow_indicator
	display.drag_started.connect(_on_drag_started)
	display.drag_ended.connect(_on_drag_ended)
	display.pivot_offset = Vector2(
		UIHelpers.CARD_WIDTH * 0.5,
		float(UIHelpers.CARD_HEIGHT),
	)
	display.scale = UIHelpers.HAND_DEFAULT_SCALE
	display.position.y = size.y


func _base_y() -> float:
	return size.y - float(UIHelpers.CARD_HEIGHT)


func _hidden_y(t_abs: float = 0.0) -> float:
	return _base_y() + UIHelpers.HAND_HIDDEN_Y + t_abs * 40.0


func _layout_cards(animate: bool = true) -> void:
	if _removing:
		return
	var cards := _get_card_children()
	var n := cards.size()
	if n == 0:
		return
	var cw := float(UIHelpers.CARD_WIDTH)
	var overlap := float(UIHelpers.CARD_OVERLAP)
	var available_w := size.x
	var min_visible := cw * 0.15
	var max_overlap := cw - min_visible
	var actual_overlap := overlap
	var total_w := n * cw - (n - 1) * overlap
	if total_w > available_w and n > 1:
		actual_overlap = minf(
			(n * cw - available_w) / float(n - 1),
			max_overlap,
		)
	var final_w := n * cw - (n - 1) * actual_overlap
	var start_x := (available_w - final_w) * 0.5
	var center_idx := (n - 1) * 0.5
	for i in n:
		var card: Control = cards[i]
		var rest_x := start_x + i * (cw - actual_overlap)
		var t := (float(i) - center_idx) / maxf(center_idx, 1.0)
		var angle := deg_to_rad(
			UIHelpers.HAND_FAN_ANGLE * t
		)
		if card != _focused_card:
			var target_y := _hidden_y(absf(t))
			if animate:
				var tw := card.create_tween()
				tw.set_parallel(true)
				tw.tween_property(
					card, "position:x", rest_x, 0.2,
				).set_trans(Tween.TRANS_SINE).set_ease(
					Tween.EASE_OUT
				)
				tw.tween_property(
					card, "rotation", angle, 0.2,
				).set_trans(Tween.TRANS_SINE).set_ease(
					Tween.EASE_OUT
				)
				if not _any_dragging:
					tw.tween_property(
						card, "position:y", target_y, 0.2,
					).set_trans(Tween.TRANS_SINE).set_ease(
						Tween.EASE_OUT
					)
			else:
				card.position.x = rest_x
				card.rotation = angle
				if not _any_dragging:
					card.position.y = target_y


func _get_rest_position(card: Control) -> Vector2:
	var cards := _get_card_children()
	var idx := cards.find(card)
	if idx < 0:
		return card.position
	var n := cards.size()
	var cw := float(UIHelpers.CARD_WIDTH)
	var overlap := float(UIHelpers.CARD_OVERLAP)
	var available_w := size.x
	var min_visible := cw * 0.15
	var max_overlap := cw - min_visible
	var actual_overlap := overlap
	var total_w := n * cw - (n - 1) * overlap
	if total_w > available_w and n > 1:
		actual_overlap = minf(
			(n * cw - available_w) / float(n - 1),
			max_overlap,
		)
	var final_w := n * cw - (n - 1) * actual_overlap
	var start_x := (available_w - final_w) * 0.5
	var center_idx := (n - 1) * 0.5
	var t_abs := absf(
		(float(idx) - center_idx) / maxf(center_idx, 1.0)
	)
	return Vector2(
		start_x + idx * (cw - actual_overlap),
		_hidden_y(t_abs),
	)


func _get_card_children() -> Array[Control]:
	var result: Array[Control] = []
	for child in get_children():
		var ctrl := child as Control
		if ctrl and not ctrl.is_queued_for_deletion():
			result.append(ctrl)
	return result


func _input(event: InputEvent) -> void:
	if _any_dragging or _dealing:
		return
	if event is InputEventMouseButton:
		if (event.button_index == MOUSE_BUTTON_RIGHT
			and event.pressed
		):
			gallery_requested.emit()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion:
		_update_focus(event.global_position)


func _update_focus(mouse_pos: Vector2) -> void:
	var local := mouse_pos - global_position
	var cards := _get_card_children()
	var hovered: Control = null
	for i in range(cards.size() - 1, -1, -1):
		var card: Control = cards[i]
		var rest := _get_rest_position(card)
		var rect := Rect2(rest, card.size)
		if rect.has_point(local):
			hovered = card
			break
	if hovered == _focused_card:
		return
	if _focused_card != null:
		_unfocus_card(_focused_card)
	if hovered != null:
		_focus_card(hovered)


func _get_fan_angle(card: Control) -> float:
	var cards := _get_card_children()
	var idx := cards.find(card)
	if idx < 0:
		return 0.0
	var n := cards.size()
	var center_idx := (n - 1) * 0.5
	var t := (float(idx) - center_idx) / maxf(center_idx, 1.0)
	return deg_to_rad(UIHelpers.HAND_FAN_ANGLE * t)


func _focus_card(card: Control) -> void:
	_focused_card = card
	card.z_index = 10
	var tween := card.create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		card, "position:y", _base_y(),
		UIHelpers.HAND_TWEEN_DURATION,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		card, "scale", UIHelpers.HAND_FOCUS_SCALE,
		UIHelpers.HAND_TWEEN_DURATION,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		card, "rotation", 0.0,
		UIHelpers.HAND_TWEEN_DURATION,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _unfocus_card(card: Control) -> void:
	if card == _focused_card:
		_focused_card = null
	card.z_index = 0
	var rest := _get_rest_position(card)
	var angle := _get_fan_angle(card)
	var tween := card.create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		card, "position:y", rest.y,
		UIHelpers.HAND_TWEEN_DURATION,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		card, "scale", UIHelpers.HAND_DEFAULT_SCALE,
		UIHelpers.HAND_TWEEN_DURATION,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		card, "rotation", angle,
		UIHelpers.HAND_TWEEN_DURATION,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_drag_started(_card: CardData) -> void:
	_any_dragging = true
	_focused_card = null
	if active_unit and active_unit.has_method("set_dragging_card"):
		active_unit.set_dragging_card(true)


func _on_drag_ended(
	card: CardData, target: Vector2i, success: bool,
	drop_pos: Vector2,
) -> void:
	_any_dragging = false
	if active_unit and active_unit.has_method("set_dragging_card"):
		active_unit.set_dragging_card(false)
	if success:
		card_dropped.emit(card, target)
		return
	var in_hand := _is_in_hand_area(drop_pos)
	if in_hand and deck_manager:
		var new_idx := _get_insert_index(drop_pos)
		deck_manager.reorder_card(card, new_idx)
		_reorder_children_to_match()
	var is_resource: bool = (
		card.card_type == CardData.CardType.RESOURCE
	)
	for child in get_children():
		if child.card_data == card:
			var tw := child.create_tween()
			tw.tween_property(
				child, "scale",
				UIHelpers.HAND_DEFAULT_SCALE, 0.2,
			).set_trans(Tween.TRANS_SINE).set_ease(
				Tween.EASE_OUT
			)
			child.z_index = 0
			if is_resource and not in_hand:
				var flash := child.create_tween()
				flash.tween_property(
					child, "modulate",
					Color(1.0, 0.3, 0.3, 0.5), 0.1,
				).set_trans(Tween.TRANS_SINE)
				flash.tween_interval(0.1)
				flash.tween_property(
					child, "modulate",
					Color.WHITE, 0.1,
				).set_trans(Tween.TRANS_SINE)
			break
	_layout_cards()
	if in_hand:
		_update_focus(drop_pos)


func _is_in_hand_area(screen_pos: Vector2) -> bool:
	var vp_h: float = get_viewport().get_visible_rect().size.y
	var hand_top: float = vp_h - float(UIHelpers.CARD_HEIGHT)
	return screen_pos.y >= hand_top


func _get_insert_index(screen_pos: Vector2) -> int:
	var local_x: float = screen_pos.x - global_position.x
	var cards := _get_card_children()
	var n := cards.size()
	if n == 0:
		return 0
	for i in n:
		var rest := _get_rest_position(cards[i])
		var mid_x: float = rest.x + float(UIHelpers.CARD_WIDTH) * 0.5
		if local_x < mid_x:
			return i
	return n


func _reorder_children_to_match() -> void:
	if not deck_manager:
		return
	var card_map: Dictionary = {}
	for child in get_children():
		if child.has_method("setup"):
			card_map[child.card_data] = child
	var idx := 0
	for card: CardData in deck_manager.hand:
		var ctrl: Control = card_map.get(card) as Control
		if ctrl:
			move_child(ctrl, idx)
			idx += 1
