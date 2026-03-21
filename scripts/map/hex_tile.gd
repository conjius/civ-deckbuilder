extends Node3D

var coord: Vector2i
var terrain: TerrainType
var is_revealed: bool = false

var _highlight_mat: StandardMaterial3D
var _pulse_tween: Tween
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _tent_path: String = "res://assets/models/buildings/tent.gltf"


func setup(
	axial_coord: Vector2i, terrain_type: TerrainType,
	mesh: ArrayMesh, shape: ConvexPolygonShape3D
) -> void:
	coord = axial_coord
	terrain = terrain_type

	$MeshInstance3D.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = terrain.color
	if terrain.texture:
		mat.albedo_texture = terrain.texture
	$MeshInstance3D.material_override = mat

	$StaticBody3D/CollisionShape3D.shape = shape

	_highlight_mat = StandardMaterial3D.new()
	_highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_highlight_mat.albedo_color = Color(1.0, 0.9, 0.2, 0.9)
	_highlight_mat.emission_enabled = true
	_highlight_mat.emission = Color(1.0, 0.9, 0.2)
	_highlight_mat.emission_energy_multiplier = 2.5
	$HighlightMesh.material_override = _highlight_mat

	position = HexUtil.axial_to_world(coord.x, coord.y)
	position.y = terrain.height - 0.1

	$HighlightMesh.visible = false
	$FogOverlay.visible = not is_revealed


func set_highlighted(value: bool, color: Color = Color(1.0, 0.9, 0.2, 0.9)) -> void:
	$HighlightMesh.visible = value
	if value:
		_highlight_mat.albedo_color = color
		_highlight_mat.emission = Color(color.r, color.g, color.b)


func pulse_highlight(color: Color) -> void:
	set_highlighted(true, color)
	if _pulse_tween:
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(
		_highlight_mat, "emission_energy_multiplier", 5.0, 0.5
	).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(
		_highlight_mat, "emission_energy_multiplier", 1.5, 0.5
	).set_trans(Tween.TRANS_SINE)


func stop_pulse() -> void:
	if _pulse_tween:
		_pulse_tween.kill()
		_pulse_tween = null
	_highlight_mat.emission_energy_multiplier = 2.5


func set_fog(value: bool) -> void:
	is_revealed = not value
	$FogOverlay.visible = value


func place_settlement(
	settlement_name: String,
	player_color: Color = Color(0.9, 0.2, 0.2),
) -> void:
	var tent_scene: PackedScene = load(_tent_path) as PackedScene
	if tent_scene == null:
		return
	var tent: Node3D = tent_scene.instantiate()
	tent.scale = Vector3(1.0, 1.0, 1.0)
	tent.position = Vector3(0, 0.1, 0)
	add_child(tent)
	for child in tent.get_children():
		if child is MeshInstance3D:
			var mi: MeshInstance3D = child as MeshInstance3D
			var mat := mi.get_active_material(0)
			if mat is StandardMaterial3D:
				var m: StandardMaterial3D = mat.duplicate()
				m.albedo_color = m.albedo_color.lerp(
					player_color, 0.3
				)
				mi.material_override = m

	var label := Label3D.new()
	label.text = settlement_name
	label.font = _font_bold
	label.font_size = UIHelpers.SETTLEMENT_FONT_SIZE
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.0, 0)
	label.modulate = Color(1.0, 0.95, 0.8)
	label.outline_modulate = Color(0.15, 0.1, 0.05)
	label.outline_size = UIHelpers.SETTLEMENT_OUTLINE
	add_child(label)
