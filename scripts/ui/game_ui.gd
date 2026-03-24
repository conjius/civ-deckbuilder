extends CanvasLayer

signal end_turn_pressed
signal card_dropped(card: CardData, target: Vector2i)
signal action_pressed(action_name: String)

var hex_map: Node3D
var camera: Camera3D
var card_effects: Node
var active_unit: Node3D
var arrow_indicator: Control

var _fps_label: Label

var _font_bold: Font = preload(
	"res://assets/fonts/Cinzel-Bold.ttf"
)
var _font_regular: Font = _font_bold
@onready var full_screen: MarginContainer = $FullScreen
@onready var bottom_bar: PanelContainer = $FullScreen/VBox/BottomBar
@onready var card_hand: Control = %CardHand
@onready var draw_pile: VBoxContainer = %DrawPile
@onready var discard_pile: VBoxContainer = %DiscardPile
@onready var turn_label: RichTextLabel = %TurnLabel
@onready var end_turn_button: Control = %EndTurnButton
@onready var info_label: RichTextLabel = %InfoLabel
@onready var unit_info: PanelContainer = %UnitInfo
@onready var resource_tracker: PanelContainer = %ResourceTracker
@onready var discard_column: VBoxContainer = (
	$FullScreen/VBox/BottomBar/HBox/DiscardColumn
)


func _ready() -> void:
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
	card_hand.discard_pile = discard_pile
	unit_info.update_unit(p_unit)


func update_turn(turn_number: int) -> void:
	UIHelpers.set_bbcode(turn_label, UIHelpers.icon_text(
		"Turn", str(turn_number)
	))


func update_draw_count(count: int) -> void:
	draw_pile.update_count(count)


func update_discard_count(count: int) -> void:
	discard_pile.update_count(count)


func on_card_played(card: CardData) -> void:
	discard_pile.add_card(card)


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


func update_resources(materials: int, food: int) -> void:
	resource_tracker.update_resources(materials, food)


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

	var hbox: HBoxContainer = bottom_bar.get_node("HBox")
	hbox.add_theme_constant_override(
		"separation", UIHelpers.SPACING_LARGE
	)

	draw_pile.custom_minimum_size = Vector2(
		UIHelpers.PILE_WIDTH, 0
	)
	var draw_stack: Control = draw_pile.get_node("Stack")
	draw_stack.custom_minimum_size = Vector2(
		UIHelpers.CARD_WIDTH, UIHelpers.CARD_HEIGHT
	)

	discard_column.custom_minimum_size = Vector2(
		UIHelpers.PILE_WIDTH, 0
	)
	discard_column.add_theme_constant_override(
		"separation", UIHelpers.SPACING_SMALL
	)

	var disc_stack: Control = discard_pile.get_node("Stack")
	disc_stack.custom_minimum_size = Vector2(
		UIHelpers.CARD_WIDTH, UIHelpers.CARD_HEIGHT
	)
