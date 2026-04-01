extends CanvasLayer

signal end_turn_pressed
signal card_dropped(card: CardData, target: Vector2i)
signal action_pressed(action_name: String)
signal gallery_closed

var hex_map: Node3D
var camera: Camera3D
var card_effects: Node
var active_unit: Node3D
var arrow_indicator: Control
var card_gallery: CardGalleryUI

var _fps_label: Label
var _current_cards: Array[CardData] = []
var _hand_original_pos: Vector2 = Vector2.ZERO
var _btn_original_x: float = -1.0
var _unit_original_x: float = -1.0
var _unit_panel_hidden: bool = false
var _dim_overlay: ColorRect
var _tile_info_card: Control
var _unit_card: UnitCardUI
var _pending_drag_card: CardData = null
var _pending_drag_pos: Vector2 = Vector2.ZERO
var _draw_pile_ui: CardPileUI
var _discard_pile_ui: CardPileUI
var _active_picker: YieldPickerUI = null
var _deck_manager_ref: DeckManager = null
var _font_bold: Font = preload(
	"res://assets/fonts/Cinzel-Bold.ttf"
)
var _font_regular: Font = _font_bold

@onready var full_screen: MarginContainer = $FullScreen
@onready var bottom_bar: PanelContainer = $FullScreen/VBox/BottomBar
@onready var card_hand: Control = %CardHand
@onready var turn_label: RichTextLabel = %TurnLabel
@onready var end_turn_button: Control = %EndTurnButton
@onready var info_label: RichTextLabel = %InfoLabel  # Legacy, hidden
@onready var unit_info: PanelContainer = %UnitInfo


func _ready() -> void:
	if info_label:
		info_label.visible = false
	unit_info.visible = false
	# Reparent end turn button out of layout container
	var et_parent := end_turn_button.get_parent()
	if et_parent:
		et_parent.remove_child(end_turn_button)
	add_child(end_turn_button)
	_dim_overlay = ColorRect.new()
	_dim_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim_overlay.visible = false
	add_child(_dim_overlay)
	card_gallery = CardGalleryUI.new()
	card_gallery.visible = false
	card_gallery.closing.connect(_on_gallery_closing)
	card_gallery.closed.connect(_on_gallery_closed)
	card_gallery.filter_changed.connect(_sync_pile_toggles)
	card_gallery.card_drag_requested.connect(
		_on_gallery_card_drag
	)
	add_child(card_gallery)
	end_turn_button.pressed.connect(
		func() -> void: end_turn_pressed.emit()
	)
	card_hand.card_dropped.connect(
		func(card: CardData, target: Vector2i) -> void:
			card_dropped.emit(card, target)
	)
	unit_info.action_pressed.connect(
		func(name: String) -> void:
			action_pressed.emit(name)
	)
	card_hand.gallery_requested.connect(_toggle_gallery)
	_setup_fps_label()
	_apply_styles()
	_apply_sizes()
	_setup_piles()
	_capture_positions.call_deferred()


func _setup_piles() -> void:
	_draw_pile_ui = CardPileUI.new()
	_draw_pile_ui.setup(true)
	_draw_pile_ui.set_title("Draw")
	add_child(_draw_pile_ui)
	_discard_pile_ui = CardPileUI.new()
	_discard_pile_ui.setup(true)
	_discard_pile_ui.set_title("Discard")
	add_child(_discard_pile_ui)
	var tile_info_cls: GDScript = load(
		"res://scripts/ui/tile_info_card_ui.gd"
	) as GDScript
	_tile_info_card = tile_info_cls.new()
	_tile_info_card.z_index = -1
	add_child(_tile_info_card)
	_unit_card = UnitCardUI.new()
	_unit_card.z_index = -1
	add_child(_unit_card)
	end_turn_button.z_index = -1
	_layout_piles()
	get_viewport().size_changed.connect(_layout_piles)
	_draw_pile_ui.clicked.connect(_on_draw_pile_clicked)
	_discard_pile_ui.clicked.connect(_on_discard_pile_clicked)


func _layout_piles() -> void:
	var vp := get_viewport().get_visible_rect().size
	var focused_y: float = vp.y - float(UIHelpers.CARD_HEIGHT)
	var pile_y: float = focused_y - 100.0
	var gap_w: float = float(UIHelpers.CARD_WIDTH) * 0.5 + 200.0
	_draw_pile_ui.position = Vector2(
		(gap_w - _draw_pile_ui.size.x) * 0.5,
		pile_y - _draw_pile_ui.size.y,
	)
	_discard_pile_ui.position = Vector2(
		vp.x - gap_w + (gap_w - _discard_pile_ui.size.x) * 0.5,
		pile_y - _discard_pile_ui.size.y,
	)
	_draw_pile_ui.store_original_pos()
	_discard_pile_ui.store_original_pos()
	var pile_gp := float(CardPileUI.glow_pad)
	# The draw/discard piles position.x includes a -GLOW_PAD offset
	# Their visual card left edge is at position.x + GLOW_PAD
	# Their visual card center X is position.x + GLOW_PAD + pile_width/2
	var draw_visual_cx: float = (
		_draw_pile_ui.position.x + pile_gp
		+ float(_draw_pile_ui._pile_width) * 0.5
	)
	var discard_visual_cx: float = (
		_discard_pile_ui.position.x + pile_gp
		+ float(_discard_pile_ui._pile_width) * 0.5
	)
	# Pile screen visual card left edge
	@warning_ignore("integer_division")
	var draw_screen_left: float = (
		_draw_pile_ui.position.x
		+ (_draw_pile_ui.size.x - float(_draw_pile_ui._pile_width)) * 0.5
	)
	@warning_ignore("integer_division")
	var discard_screen_left: float = (
		_discard_pile_ui.position.x
		+ (_discard_pile_ui.size.x - float(_discard_pile_ui._pile_width)) * 0.5
	)
	# Top cards: match visual card left edge to pile visual card left edge
	var vcl: float = float(DarkCardUI.glow_pad) + float(DarkCardUI.extra_w) * 0.5
	var card_y: float = 20.0
	end_turn_button.position = Vector2(
		discard_screen_left - vcl, card_y
	)
	_btn_original_x = end_turn_button.position.x
	if _tile_info_card:
		_tile_info_card.position = Vector2(
			draw_screen_left - vcl, card_y
		)
		_tile_info_card.store_original_pos()
	if _unit_card:
		_unit_card.position = Vector2(
			(vp.x - _unit_card.size.x) * 0.5, card_y
		)
		_unit_card.store_original_pos()
	_btn_original_x = end_turn_button.position.x
	card_hand.draw_pile_pos = get_draw_pile_center()
	card_hand.discard_pile_pos = get_discard_pile_center()


func update_piles(
	draw_count: int, discard_count: int,
	hand_count: int = -1,
) -> void:
	_draw_pile_ui.update_count(draw_count)
	_discard_pile_ui.update_count(discard_count)
	if hand_count >= 0:
		card_gallery.update_hand_count(hand_count)


func get_draw_pile_center() -> Vector2:
	return _draw_pile_ui.position + _draw_pile_ui.size * 0.5


func get_discard_pile_center() -> Vector2:
	return _discard_pile_ui.position + _discard_pile_ui.size * 0.5


func animate_deal(
	cards: Array[CardData],
	draw_count: int, discard_count: int,
) -> void:
	if card_gallery.visible:
		card_gallery.hide_gallery()
		await card_gallery.closed
	update_piles(draw_count + cards.size(), discard_count)
	# Move draw pile to center at same height as static piles
	var vp_w: float = get_viewport().get_visible_rect().size.x
	var deal_pos := Vector2(
		vp_w * 0.5 - _draw_pile_ui.size.x * 0.5,
		_draw_pile_ui._original_pos.y,
	)
	var tw_out := _draw_pile_ui.animate_to(deal_pos, 0.2)
	await tw_out.finished
	# Cards spawn from the pile's current center
	card_hand.draw_pile_pos = (
		_draw_pile_ui.global_position
		+ _draw_pile_ui.size * 0.5
	)
	set_current_cards(cards)
	card_hand.show_cards(cards, true)
	# Draw pulls cards out → decrement at START of each card anim
	# Hand receives cards → increment at END of each card anim
	var remaining_draw := draw_count + cards.size()
	var hand_count := 0
	var dur := 0.7
	for i in cards.size():
		await get_tree().create_timer(0.18).timeout
		remaining_draw -= 1
		_draw_pile_ui.update_count(remaining_draw)
	for i in cards.size():
		if i == 0:
			await get_tree().create_timer(dur).timeout
		else:
			await get_tree().create_timer(0.18).timeout
		hand_count += 1
		card_gallery.update_hand_count(hand_count)
	update_piles(draw_count, discard_count, cards.size())
	var tw_back := _draw_pile_ui.animate_back(0.2)
	await tw_back.finished
	card_hand.draw_pile_pos = get_draw_pile_center()


func _capture_positions() -> void:
	if _unit_original_x < 0:
		_unit_original_x = unit_info.position.x
	if _btn_original_x < 0:
		_btn_original_x = end_turn_button.position.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if (event.keycode == KEY_TAB
			or event.keycode == KEY_SPACE
		):
			_toggle_gallery(false, true, false)
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	_fps_label.text = "%d FPS" % Engine.get_frames_per_second()


func _setup_fps_label() -> void:
	_fps_label = Label.new()
	_fps_label.position = Vector2(8, 4)
	_fps_label.add_theme_font_override("font", _font_bold)
	_fps_label.add_theme_font_size_override("font_size", 14)
	_fps_label.add_theme_color_override(
		"font_color", Color(1.0, 1.0, 1.0, 0.6)
	)
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fps_label)


func setup_refs(
	p_hex_map: Node3D, p_camera: Camera3D,
	p_card_effects: Node, p_unit: Node3D,
	p_arrow: Control,
) -> void:
	hex_map = p_hex_map
	camera = p_camera
	card_effects = p_card_effects
	active_unit = p_unit
	arrow_indicator = p_arrow
	card_hand.hex_map = p_hex_map
	card_hand.camera = p_camera
	card_hand.card_effects = p_card_effects
	card_hand.active_unit = p_unit
	card_hand.arrow_indicator = p_arrow
	unit_info.update_unit(p_unit)


func update_turn(turn_number: int) -> void:
	UIHelpers.set_bbcode(turn_label, UIHelpers.icon_text(
		"Turn", str(turn_number)
	))


func update_tile_info(
	terrain_name: String, yields: Array[String],
) -> void:
	if _tile_info_card:
		_tile_info_card.update_info(terrain_name, yields)


func set_end_turn_enabled(enabled: bool) -> void:
	end_turn_button.set_disabled(not enabled)


func refresh_unit_info() -> void:
	if _unit_card and active_unit and _unit_card._showing:
		_unit_card.show_unit(active_unit)


func show_unit_info(unit: Node3D) -> void:
	if _unit_card:
		_unit_card.show_unit(unit)


func show_settlement_info(
	sname: String, color: Color,
	_coord: Vector2i, _terrain: TerrainType,
	hp: int = 5, atk: int = 1, def: int = 1,
) -> void:
	if _unit_card:
		_unit_card.show_settlement(sname, color, hp, atk, def)




func _toggle_gallery(
	show_draw: bool = false,
	show_hand: bool = true,
	show_discard: bool = false,
) -> void:
	if card_gallery.visible:
		card_gallery.hide_gallery()
	else:
		if not _active_picker:
			_animate_overlay(true)
		_slide_hand_out()
		_slide_ui_out()
		var dm := _deck_manager_ref
		if dm:
			card_gallery.show_gallery(
				dm.draw_pile, dm.hand, dm.discard_pile,
				show_draw, show_hand, show_discard,
			)
		else:
			card_gallery.show_gallery(
				[] as Array[CardData],
				_current_cards,
				[] as Array[CardData],
				false, true, false,
			)
		var rig := camera.get_parent().get_parent()
		if "input_enabled" in rig:
			rig.input_enabled = false
		if hex_map:
			hex_map.clear_highlights()
		_draw_pile_ui.set_gallery_mode(true)
		_discard_pile_ui.set_gallery_mode(true)
		_draw_pile_ui.set_toggled(show_draw)
		_discard_pile_ui.set_toggled(show_discard)
		_animate_piles_to_gallery()
		if _active_picker:
			_active_picker.enter_gallery_mode()


func _sync_pile_toggles() -> void:
	_draw_pile_ui.set_toggled(card_gallery._show_draw)
	_discard_pile_ui.set_toggled(card_gallery._show_discard)
	card_gallery.update_hand_toggle()


func _on_draw_pile_clicked() -> void:
	if card_gallery.visible:
		card_gallery.toggle_filter("draw")
		_sync_pile_toggles()
	else:
		_toggle_gallery(true, false, false)


func _on_discard_pile_clicked() -> void:
	if card_gallery.visible:
		card_gallery.toggle_filter("discard")
		_sync_pile_toggles()
	else:
		_toggle_gallery(false, false, true)


func _on_gallery_closing() -> void:
	if not _active_picker:
		_animate_overlay(false)
	_slide_ui_in()
	var rig := camera.get_parent().get_parent()
	if "input_enabled" in rig:
		rig.input_enabled = true
	_draw_pile_ui.set_gallery_mode(false)
	_discard_pile_ui.set_gallery_mode(false)
	_animate_piles_back()


func _animate_piles_to_gallery() -> void:
	var vp := get_viewport().get_visible_rect().size
	var gallery_scale := 0.8
	var spacing := 60.0
	var pw := _draw_pile_ui.size.x * gallery_scale
	var ph := _draw_pile_ui.size.y * gallery_scale
	var total_w := pw * 3.0 + spacing * 2.0
	var start_x := (vp.x - total_w) * 0.5
	var target_y := card_gallery._gallery_bottom_y + 20.0
	var gp := float(CardPileUI.glow_pad) * gallery_scale
	_draw_pile_ui.animate_to(
		Vector2(start_x + gp, target_y + gp), 0.3,
	)
	_discard_pile_ui.animate_to(
		Vector2(
			start_x + pw * 2.0 + spacing * 2.0 + gp,
			target_y + gp,
		), 0.3,
	)
	var scale_v := Vector2(gallery_scale, gallery_scale)
	_draw_pile_ui.pivot_offset = _draw_pile_ui.size * 0.5
	_discard_pile_ui.pivot_offset = _discard_pile_ui.size * 0.5
	_draw_pile_ui.create_tween().tween_property(
		_draw_pile_ui, "scale", scale_v, 0.3,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_discard_pile_ui.create_tween().tween_property(
		_discard_pile_ui, "scale", scale_v, 0.3,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _animate_piles_back() -> void:
	_draw_pile_ui.animate_back(0.3)
	_discard_pile_ui.animate_back(0.3)
	var full_scale := Vector2(1.0, 1.0)
	_draw_pile_ui.create_tween().tween_property(
		_draw_pile_ui, "scale", full_scale, 0.3,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_discard_pile_ui.create_tween().tween_property(
		_discard_pile_ui, "scale", full_scale, 0.3,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


	if _active_picker:
		_active_picker.exit_gallery_mode()


func _slide_ui_out() -> void:
	if _btn_original_x < 0:
		_btn_original_x = end_turn_button.position.x
	var tw_btn := end_turn_button.create_tween()
	tw_btn.tween_property(
		end_turn_button, "position:x",
		_btn_original_x + end_turn_button.size.x + 50,
		0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	if _tile_info_card:
		_tile_info_card.slide_out_left()
	if _unit_card:
		_unit_card.slide_out_for_gallery()


func _slide_ui_in() -> void:
	var tw_btn := end_turn_button.create_tween()
	tw_btn.tween_property(
		end_turn_button, "position:x",
		_btn_original_x,
		0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _tile_info_card:
		_tile_info_card.slide_in_from_left()
	if _unit_card:
		_unit_card.slide_in_from_gallery()


func slide_unit_panel_out() -> void:
	if _unit_card:
		_unit_card.hide_unit()


func slide_unit_panel_in(
	_swap: bool = false, update_fn: Callable = Callable(),
) -> void:
	if update_fn.is_valid():
		update_fn.call()
	if _unit_card and active_unit and _unit_card._showing:
		_unit_card.show_unit(active_unit)


func _on_gallery_card_drag(
	card: CardData, mouse_pos: Vector2, pile: String,
) -> void:
	if pile != "hand":
		_flash_reject_card(mouse_pos)
		return
	_animate_overlay(false)
	_slide_hand_in()
	_slide_ui_in()
	card_hand.show_cards_with_drag(
		_current_cards, card, mouse_pos
	)
	card_gallery.hide_gallery()


func _flash_reject_card(pos: Vector2) -> void:
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.2, 0.2, 0.4)
	flash.size = Vector2(60, 80)
	flash.position = pos - flash.size * 0.5
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tw := flash.create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.3)
	tw.tween_callback(flash.queue_free)


func _on_gallery_closed() -> void:
	if not _pending_drag_card:
		_slide_hand_in()
	gallery_closed.emit()


func _animate_overlay(show: bool) -> void:
	if show:
		var vp := get_viewport().get_visible_rect().size
		_dim_overlay.position = Vector2.ZERO
		_dim_overlay.size = vp
		_dim_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
		_dim_overlay.visible = true
		var tween := _dim_overlay.create_tween()
		tween.tween_property(
			_dim_overlay, "color:a", 0.6, 0.25,
		).set_trans(Tween.TRANS_SINE)
	else:
		var tween := _dim_overlay.create_tween()
		tween.tween_property(
			_dim_overlay, "color:a", 0.0, 0.35,
		).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(
			func() -> void: _dim_overlay.visible = false
		)


func _slide_hand_out() -> void:
	if _hand_original_pos == Vector2.ZERO:
		_hand_original_pos = bottom_bar.position
	var target_y: float = (
		_hand_original_pos.y
		+ float(UIHelpers.BOTTOM_BAR_HEIGHT) + 50.0
	)
	var tween := bottom_bar.create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		bottom_bar, "position:y", target_y, 0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(
		bottom_bar, "modulate:a", 0.0, 0.25,
	).set_trans(Tween.TRANS_SINE)


func _slide_hand_in() -> void:
	var tween := bottom_bar.create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		bottom_bar, "position:y", _hand_original_pos.y, 0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		bottom_bar, "modulate:a", 1.0, 0.25,
	).set_trans(Tween.TRANS_SINE)


func set_current_cards(cards: Array[CardData]) -> void:
	_current_cards = cards


func _apply_styles() -> void:
	var empty_style := StyleBoxEmpty.new()
	bottom_bar.add_theme_stylebox_override("panel", empty_style)


func _apply_sizes() -> void:
	var m := UIHelpers.MARGIN
	full_screen.add_theme_constant_override("margin_left", m)
	full_screen.add_theme_constant_override("margin_top", m)
	full_screen.add_theme_constant_override("margin_right", m)
	full_screen.add_theme_constant_override("margin_bottom", 0)

	turn_label.add_theme_font_override(
		"normal_font", _font_bold
	)
	turn_label.add_theme_font_size_override(
		"normal_font_size", UIHelpers.FONT_TURN
	)


	bottom_bar.custom_minimum_size = Vector2(
		0, UIHelpers.BOTTOM_BAR_HEIGHT
	)
