extends CanvasLayer

signal end_turn_pressed
signal card_dropped(card: CardData, target: Vector2i)

var hex_map: Node3D
var camera: Camera3D
var card_effects: Node
var active_unit: Node3D
var arrow_indicator: MeshInstance3D

var _wood_tex: Texture2D = preload(
	"res://assets/textures/ui/wood_panel_256_grayscale.png"
)
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _font_regular: Font = preload("res://assets/fonts/Cinzel-Regular.ttf")

@onready var bottom_bar: PanelContainer = $FullScreen/VBox/BottomBar
@onready var card_hand: HBoxContainer = %CardHand
@onready var draw_pile: VBoxContainer = %DrawPile
@onready var discard_pile: VBoxContainer = %DiscardPile
@onready var turn_label: Label = %TurnLabel
@onready var end_turn_button: Button = %EndTurnButton
@onready var info_label: Label = %InfoLabel
@onready var unit_info: PanelContainer = %UnitInfo
@onready var resource_tracker: PanelContainer = %ResourceTracker


func _ready() -> void:
	end_turn_button.pressed.connect(
		func() -> void: end_turn_pressed.emit()
	)
	card_hand.card_dropped.connect(
		func(card: CardData, target: Vector2i) -> void:
			card_dropped.emit(card, target)
	)
	_apply_styles()


func setup_refs(
	p_hex_map: Node3D, p_camera: Camera3D,
	p_card_effects: Node, p_unit: Node3D,
	p_arrow: MeshInstance3D,
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
	turn_label.text = "Turn: %d" % turn_number


func update_draw_count(count: int) -> void:
	draw_pile.update_count(count)


func update_discard_count(count: int) -> void:
	discard_pile.update_count(count)


func on_card_played(card: CardData) -> void:
	discard_pile.add_card(card)


func update_info(text: String) -> void:
	info_label.text = text
	info_label.visible = text != ""


func set_end_turn_enabled(enabled: bool) -> void:
	end_turn_button.disabled = not enabled


func refresh_unit_info() -> void:
	unit_info.update_unit(active_unit)


func update_resources(materials: int, food: int) -> void:
	resource_tracker.update_resources(materials, food)


func _apply_styles() -> void:
	var wood_style := StyleBoxTexture.new()
	wood_style.texture = _wood_tex
	wood_style.modulate_color = Color(0.45, 0.3, 0.18)
	wood_style.content_margin_left = 8.0
	wood_style.content_margin_right = 8.0
	wood_style.content_margin_top = 8.0
	wood_style.content_margin_bottom = 8.0
	bottom_bar.add_theme_stylebox_override("panel", wood_style)

	turn_label.add_theme_font_override("font", _font_bold)
	turn_label.add_theme_font_size_override("font_size", 14)

	end_turn_button.add_theme_font_override("font", _font_bold)
	end_turn_button.add_theme_font_size_override("font_size", 12)
