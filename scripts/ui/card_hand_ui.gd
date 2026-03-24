extends Control

signal card_dropped(card: CardData, target: Vector2i)
signal card_discarded(card: CardData)
signal animations_finished

const FLIP_SQUISH: float = 0.12
const FLIP_STRETCH: float = 0.23
const SLIDE_DURATION: float = 0.3
const DISCARD_STAGGER: float = 0.08

var hex_map: Node3D
var camera: Camera3D
var card_effects: Node
var active_unit: Node3D
var arrow_indicator: Control
var discard_pile: Control
var draw_pile: Control

var _card_display_scene: PackedScene = preload(
	"res://scenes/ui/card_display.tscn"
)
var _focused_card: Control = null
var _any_dragging: bool = false
var _animating: bool = false
var _discarding: bool = false


func _ready() -> void:
	resized.connect(_layout_cards)


func update_hand(hand: Array[CardData]) -> void:
	_focused_card = null
	for child in get_children():
		child.queue_free()
	for card in hand:
		_add_card_display(card)
	_layout_cards.call_deferred()


func animate_draw_hand(hand: Array[CardData]) -> void:
	_focused_card = null
	_animating = true
	for child in get_children():
		child.queue_free()
	for card in hand:
		_add_card_display(card, false)
	await get_tree().process_frame
	var cards := _get_card_children()
	var draw_pos := _get_draw_pile_local()
	for card_ctrl: Control in cards:
		card_ctrl.position = draw_pos
		card_ctrl.scale = UIHelpers.HAND_DEFAULT_SCALE
		card_ctrl.modulate.a = 0.0
	var n := cards.size()
	for i in n:
		var card_ctrl: Control = cards[i]
		var rest := _get_rest_position(card_ctrl)
		var angle := _get_fan_angle(card_ctrl)
		var delay := float(i) * DISCARD_STAGGER
		card_ctrl.modulate.a = 1.0
		var tween := card_ctrl.create_tween()
		tween.tween_interval(delay)
		# Slide from draw pile
		tween.tween_property(
			card_ctrl, "position", rest,
			SLIDE_DURATION,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_OUT
		)
		# Flip: squish then stretch
		var flip_tween := card_ctrl.create_tween()
		flip_tween.tween_interval(delay)
		flip_tween.tween_property(
			card_ctrl, "scale:x", 0.01, FLIP_SQUISH,
		).set_trans(Tween.TRANS_QUAD).set_ease(
			Tween.EASE_OUT
		)
		flip_tween.tween_callback(
			func() -> void: card_ctrl.set_face_up(true)
		)
		flip_tween.tween_property(
			card_ctrl, "scale:x",
			UIHelpers.HAND_DEFAULT_SCALE.x,
			FLIP_STRETCH,
		).set_trans(Tween.TRANS_QUAD).set_ease(
			Tween.EASE_IN
		)
		# Rotation
		var rot_tween := card_ctrl.create_tween()
		rot_tween.tween_interval(delay)
		rot_tween.tween_property(
			card_ctrl, "rotation", angle,
			SLIDE_DURATION,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_OUT
		)
	var total := float(n - 1) * DISCARD_STAGGER + SLIDE_DURATION
	await get_tree().create_timer(total).timeout
	_animating = false
	animations_finished.emit()


func animate_discard_hand() -> void:
	_focused_card = null
	_animating = true
	var cards := _get_card_children()
	var discard_pos := _get_discard_pile_local()
	var n := cards.size()
	z_index = 100
	for i in n:
		var card_ctrl: Control = cards[n - 1 - i]
		var delay := float(i) * DISCARD_STAGGER
		var tween := card_ctrl.create_tween()
		tween.tween_interval(delay)
		tween.set_parallel(true)
		tween.tween_property(
			card_ctrl, "position", discard_pos,
			SLIDE_DURATION,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_IN
		)
		tween.tween_property(
			card_ctrl, "rotation", 0.0, SLIDE_DURATION,
		).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_IN
		)
	var total := float(n - 1) * DISCARD_STAGGER + SLIDE_DURATION
	await get_tree().create_timer(maxf(total, 0.01)).timeout
	for child in get_children():
		child.queue_free()
	z_index = 0
	_animating = false
	animations_finished.emit()


func remove_card(card: CardData) -> void:
	for child in get_children():
		if child.card_data == card:
			if child == _focused_card:
				_focused_card = null
			_discarding = true
			var discard_pos := _get_discard_pile_local()
			var card_ctrl: Control = child
			card_ctrl.z_index = 100
			var tween := card_ctrl.create_tween()
			tween.set_parallel(true)
			tween.tween_property(
				card_ctrl, "position", discard_pos,
				SLIDE_DURATION,
			).set_trans(Tween.TRANS_CUBIC).set_ease(
				Tween.EASE_IN
			)
			tween.tween_property(
				card_ctrl, "rotation", 0.0,
				SLIDE_DURATION * 0.5,
			).set_trans(Tween.TRANS_SINE)
			tween.tween_property(
				card_ctrl, "modulate",
				Color(0.45, 0.45, 0.45, 1.0),
				SLIDE_DURATION,
			).set_trans(Tween.TRANS_SINE).set_ease(
				Tween.EASE_IN
			)
			var card_ref: CardData = card
			tween.chain().tween_callback(
				func() -> void:
					_discarding = false
					child.queue_free()
					_layout_cards.call_deferred()
					card_discarded.emit(card_ref)
			)
			break


func _add_card_display(
	card: CardData, face_up: bool = true,
) -> void:
	var display: Control = _card_display_scene.instantiate()
	add_child(display)
	display.setup(card)
	display.set_face_up(face_up)
	display.hex_map = hex_map
	display.camera = camera
	display.card_effects = card_effects
	display.active_unit = active_unit
	display.arrow_indicator = arrow_indicator
	display.discard_pile = discard_pile
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


func _get_draw_pile_local() -> Vector2:
	if draw_pile:
		var gp := draw_pile.global_position
		return gp - global_position
	return Vector2(-200, size.y * 0.5)


func _get_discard_pile_local() -> Vector2:
	if discard_pile:
		var gp := discard_pile.global_position
		return gp - global_position
	return Vector2(size.x + 200, size.y * 0.5)


func _layout_cards(animate: bool = true) -> void:
	if _discarding:
		return
	var cards := _get_card_children()
	var n := cards.size()
	if n == 0:
		return
	var cw := float(UIHelpers.CARD_WIDTH)
	var overlap := float(UIHelpers.CARD_OVERLAP)
	var total_w := n * cw - (n - 1) * overlap
	var available_w := size.x
	var actual_overlap := overlap
	if total_w > available_w and n > 1:
		actual_overlap = (n * cw - available_w) / float(n - 1)
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
	var total_w := n * cw - (n - 1) * overlap
	var available_w := size.x
	var actual_overlap := overlap
	if total_w > available_w and n > 1:
		actual_overlap = (n * cw - available_w) / float(n - 1)
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
	if _any_dragging or _animating or _discarding:
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
	if _discarding:
		return
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
	if _focused_card != null:
		_unfocus_card(_focused_card)


func _on_drag_ended(
	card: CardData, target: Vector2i, success: bool,
) -> void:
	_any_dragging = false
	if success:
		_discarding = true
		card_dropped.emit(card, target)
