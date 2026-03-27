extends CanvasLayer

signal end_turn_pressed
signal card_dropped(card: CardData, target: Vector2i)
signal action_pressed(action_name: String)

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
var _dim_overlay: ColorRect
var _pending_drag_card: CardData = null
var _pending_drag_pos: Vector2 = Vector2.ZERO
var _font_bold: Font = preload(
	"res://assets/fonts/Cinzel-Bold.ttf"
)
var _font_regular: Font = _font_bold

@onready var full_screen: MarginContainer = $FullScreen
@onready var bottom_bar: PanelContainer = $FullScreen/VBox/BottomBar
@onready var card_hand: Control = %CardHand
@onready var turn_label: RichTextLabel = %TurnLabel
@onready var end_turn_button: Control = %EndTurnButton
@onready var info_label: RichTextLabel = %InfoLabel
@onready var unit_info: PanelContainer = %UnitInfo


func _ready() -> void:
	_dim_overlay = ColorRect.new()
	_dim_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_dim_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim_overlay.visible = false
	add_child(_dim_overlay)
	card_gallery = CardGalleryUI.new()
	card_gallery.visible = false
	card_gallery.closing.connect(_on_gallery_closing)
	card_gallery.closed.connect(_on_gallery_closed)
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


func update_info(text: String) -> void:
	if text == "":
		info_label.visible = false
		return
	info_label.visible = true
	UIHelpers.set_bbcode(info_label, "[center]" + text + "[/center]")


func set_end_turn_enabled(enabled: bool) -> void:
	end_turn_button.set_disabled(not enabled)


func refresh_unit_info() -> void:
	unit_info.update_unit(active_unit)


func show_settlement_info(
	sname: String, color: Color,
	coord: Vector2i, terrain: TerrainType,
) -> void:
	unit_info.update_settlement(sname, color, coord, terrain)




func _toggle_gallery() -> void:
	if card_gallery.visible:
		card_gallery.hide_gallery()
	else:
		_animate_overlay(true)
		_slide_hand_out()
		_slide_ui_out()
		card_gallery.show_gallery(_current_cards)


func _on_gallery_closing() -> void:
	_animate_overlay(false)
	_slide_ui_in()


func _slide_ui_out() -> void:
	if _btn_original_x < 0:
		_btn_original_x = end_turn_button.position.x
	if _unit_original_x < 0:
		_unit_original_x = unit_info.position.x
	var tw_btn := end_turn_button.create_tween()
	tw_btn.tween_property(
		end_turn_button, "position:x",
		_btn_original_x + end_turn_button.size.x + 50,
		0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	var tw_unit := unit_info.create_tween()
	tw_unit.tween_property(
		unit_info, "position:x",
		_unit_original_x - unit_info.size.x - 50,
		0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func _slide_ui_in() -> void:
	var tw_btn := end_turn_button.create_tween()
	tw_btn.tween_property(
		end_turn_button, "position:x",
		_btn_original_x,
		0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var tw_unit := unit_info.create_tween()
	tw_unit.tween_property(
		unit_info, "position:x",
		_unit_original_x,
		0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_gallery_card_drag(
	card: CardData, mouse_pos: Vector2,
) -> void:
	_animate_overlay(false)
	_slide_hand_in()
	_slide_ui_in()
	card_hand.show_cards_with_drag(
		_current_cards, card, mouse_pos
	)
	card_gallery.hide_gallery()


func _on_gallery_closed() -> void:
	if not _pending_drag_card:
		_slide_hand_in()


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

	info_label.add_theme_font_override(
		"normal_font", _font_bold
	)
	info_label.add_theme_font_size_override(
		"normal_font_size", UIHelpers.FONT_UNIT_STAT
	)

	bottom_bar.custom_minimum_size = Vector2(
		0, UIHelpers.BOTTOM_BAR_HEIGHT
	)
