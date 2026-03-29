extends PanelContainer

signal action_pressed(action_name: String)

var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _font_regular: Font = _font_bold
var _explorer_icon_path: String = (
	"res://assets/icons/move_64.svg"
)
var _settle_icon_path: String = (
	"res://assets/icons/settle_64.svg"
)
var _explorer_icon: Texture2D
var _settle_icon: Texture2D
var _color_shader: ShaderMaterial

@onready var avatar_rect: TextureRect = %AvatarRect
@onready var unit_name_label: Label = %UnitNameLabel
@onready var health_label: RichTextLabel = %HealthLabel
@onready var attack_label: RichTextLabel = %AttackLabel
@onready var defense_label: RichTextLabel = %DefenseLabel
@onready var action_container: VBoxContainer = %ActionContainer


func _ready() -> void:
	_explorer_icon = load(_explorer_icon_path) as Texture2D
	_settle_icon = load(_settle_icon_path) as Texture2D
	var shader := Shader.new()
	shader.code = (
		"shader_type canvas_item;\n"
		+ "uniform vec4 tint_color : source_color = vec4(1.0);\n"
		+ "void fragment() {\n"
		+ "    vec4 tex = texture(TEXTURE, UV);\n"
		+ "    float lum = dot(tex.rgb, vec3(0.3, 0.6, 0.1));\n"
		+ "    vec3 tinted = tint_color.rgb * (0.7 + lum * 0.3);\n"
		+ "    float acc = 0.0;\n"
		+ "    float total = 0.0;\n"
		+ "    for (int r = 1; r <= 6; r++) {\n"
		+ "      float rd = 0.1 * float(r) / 6.0;\n"
		+ "      float w = 1.0 - float(r) / 7.0;\n"
		+ "      for (int i = 0; i < 12; i++) {\n"
		+ "        float a = float(i) / 12.0 * 6.2832;\n"
		+ "        vec2 off = vec2(cos(a), sin(a)) * rd;\n"
		+ "        acc += texture(TEXTURE, UV + off).a * w;\n"
		+ "        total += w;\n"
		+ "      }\n"
		+ "    }\n"
		+ "    float shadow = (acc / total) * (1.0 - tex.a);\n"
		+ "    vec3 col = mix(vec3(0.0), tinted, tex.a);\n"
		+ "    float fa = max(tex.a, shadow * 0.8);\n"
		+ "    COLOR = vec4(col, fa);\n"
		+ "}\n"
	)
	_color_shader = ShaderMaterial.new()
	_color_shader.shader = shader
	avatar_rect.material = _color_shader
	add_theme_stylebox_override(
		"panel", UIHelpers.create_panel_style()
	)
	UIHelpers.apply_parchment_bg(self)
	custom_minimum_size = Vector2(
		UIHelpers.LEFT_PANEL_WIDTH, 0
	)
	size.x = UIHelpers.LEFT_PANEL_WIDTH
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	clip_contents = true
	var vbox: VBoxContainer = $VBox
	vbox.add_theme_constant_override(
		"separation", UIHelpers.SPACING_SMALL
	)
	var body_hbox: HBoxContainer = $VBox/BodyHBox
	body_hbox.add_theme_constant_override(
		"separation", UIHelpers.SPACING_SMALL
	)
	if action_container:
		action_container.add_theme_constant_override(
			"separation", UIHelpers.SPACING_SMALL
		)
	unit_name_label.add_theme_font_override("font", _font_bold)
	unit_name_label.add_theme_font_size_override(
		"font_size", UIHelpers.FONT_UNIT_NAME
	)
	unit_name_label.add_theme_color_override(
		"font_color", Color.BLACK
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
		lbl.add_theme_color_override(
			"default_color", Color.BLACK
		)


func update_unit(unit: Node3D) -> void:
	if unit == null:
		return
	avatar_rect.texture = _explorer_icon
	_color_shader.set_shader_parameter(
		"tint_color", unit.avatar_color
	)
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
	avatar_rect.texture = _settle_icon
	_color_shader.set_shader_parameter(
		"tint_color", player_color
	)
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
