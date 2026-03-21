extends PanelContainer

var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _font_regular: Font = preload(
	"res://assets/fonts/Cinzel-Regular.ttf"
)

@onready var avatar_rect: ColorRect = %AvatarRect
@onready var unit_name_label: Label = %UnitNameLabel
@onready var health_label: Label = %HealthLabel
@onready var attack_label: Label = %AttackLabel
@onready var defense_label: Label = %DefenseLabel


func _ready() -> void:
	unit_name_label.add_theme_font_override("font", _font_bold)
	unit_name_label.add_theme_font_size_override(
		"font_size", UIHelpers.FONT_UNIT_NAME
	)
	for lbl: Label in [health_label, attack_label, defense_label]:
		lbl.add_theme_font_override("font", _font_regular)
		lbl.add_theme_font_size_override(
			"font_size", UIHelpers.FONT_UNIT_STAT
		)


func update_unit(unit: Node3D) -> void:
	if unit == null:
		visible = false
		return
	visible = true
	avatar_rect.color = unit.avatar_color
	unit_name_label.text = unit.state.unit_name
	health_label.text = "HP: %d/%d" % [
		unit.state.health, unit.state.max_health,
	]
	attack_label.text = "ATK: %d" % unit.state.attack
	var eff_def: int = (
		unit.state.defense + unit.state.defense_modifier
	)
	defense_label.text = "DEF: %d" % eff_def


func update_settlement(
	settlement_name: String, player_color: Color,
	coord: Vector2i, terrain: TerrainType,
) -> void:
	visible = true
	avatar_rect.color = player_color
	unit_name_label.text = settlement_name
	health_label.text = "(%d, %d)" % [coord.x, coord.y]
	if terrain:
		attack_label.text = terrain.terrain_name
	else:
		attack_label.text = ""
	defense_label.text = ""
