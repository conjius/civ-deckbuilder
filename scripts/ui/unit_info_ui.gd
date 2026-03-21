extends PanelContainer

signal action_pressed(action_name: String)

var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _font_regular: Font = preload(
	"res://assets/fonts/Cinzel-Regular.ttf"
)
var _explorer_icon_path: String = (
	"res://assets/icons/move_64.svg"
)
var _settle_icon_path: String = (
	"res://assets/icons/settle_64.svg"
)
var _explorer_icon: Texture2D
var _settle_icon: Texture2D

@onready var avatar_rect: TextureRect = %AvatarRect
@onready var unit_name_label: Label = %UnitNameLabel
@onready var health_label: RichTextLabel = %HealthLabel
@onready var attack_label: RichTextLabel = %AttackLabel
@onready var defense_label: RichTextLabel = %DefenseLabel
@onready var action_container: VBoxContainer = %ActionContainer


func _ready() -> void:
	_explorer_icon = load(_explorer_icon_path) as Texture2D
	_settle_icon = load(_settle_icon_path) as Texture2D
	add_theme_stylebox_override(
		"panel", UIHelpers.create_panel_style()
	)
	custom_minimum_size = Vector2(
		UIHelpers.CARD_WIDTH, 0
	)
	size.x = UIHelpers.CARD_WIDTH
	clip_contents = true
	unit_name_label.add_theme_font_override("font", _font_bold)
	unit_name_label.add_theme_font_size_override(
		"font_size", UIHelpers.FONT_UNIT_NAME
	)
	unit_name_label.clip_text = true
	for lbl: RichTextLabel in [
		health_label, attack_label, defense_label,
	]:
		lbl.add_theme_font_override(
			"normal_font", _font_regular
		)
		lbl.add_theme_font_size_override(
			"normal_font_size", UIHelpers.FONT_UNIT_STAT
		)
		lbl.autowrap_mode = TextServer.AUTOWRAP_OFF


func update_unit(unit: Node3D) -> void:
	if unit == null:
		visible = false
		return
	visible = true
	avatar_rect.texture = _explorer_icon
	avatar_rect.modulate = unit.avatar_color
	unit_name_label.text = unit.state.unit_name
	UIHelpers.set_bbcode(health_label, UIHelpers.icon_text(
		"HP", "%d/%d" % [unit.state.health, unit.state.max_health]
	))
	health_label.visible = true
	UIHelpers.set_bbcode(attack_label, UIHelpers.icon_text(
		"Attack", str(unit.state.attack)))
	attack_label.visible = true
	var eff_def: int = (
		unit.state.defense + unit.state.defense_modifier
	)
	UIHelpers.set_bbcode(defense_label, UIHelpers.icon_text(
		"Defense", str(eff_def)))
	defense_label.visible = true
	_clear_actions()


func update_settlement(
	settlement_name: String, player_color: Color,
	_coord: Vector2i, terrain: TerrainType,
) -> void:
	visible = true
	avatar_rect.texture = _settle_icon
	avatar_rect.modulate = player_color
	unit_name_label.text = settlement_name
	UIHelpers.set_bbcode(
		health_label, UIHelpers.icon_text("HP", "50/50")
	)
	health_label.visible = true
	if terrain:
		UIHelpers.set_bbcode(attack_label, terrain.terrain_name)
	else:
		UIHelpers.set_bbcode(attack_label, "")
	attack_label.visible = true
	UIHelpers.set_bbcode(
		defense_label, UIHelpers.icon_text("Defense", "0")
	)
	defense_label.visible = true
	_clear_actions()
	_add_action("Build")


func _clear_actions() -> void:
	if not action_container:
		return
	for child in action_container.get_children():
		child.queue_free()


func _add_action(label: String) -> void:
	if not action_container:
		return
	var btn := Button.new()
	btn.text = label
	btn.add_theme_font_override("font", _font_regular)
	btn.add_theme_font_size_override(
		"font_size", UIHelpers.FONT_UNIT_STAT
	)
	btn.pressed.connect(
		func() -> void: action_pressed.emit(label.to_lower())
	)
	action_container.add_child(btn)
