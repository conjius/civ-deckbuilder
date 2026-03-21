extends Node3D

var coord: Vector2i
var terrain: TerrainType
var is_revealed: bool = false

var _highlight_mat: StandardMaterial3D


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


func set_fog(value: bool) -> void:
	is_revealed = not value
	$FogOverlay.visible = value


func place_settlement(
	settlement_name: String,
	player_color: Color = Color(0.9, 0.2, 0.2),
) -> void:
	var marker := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.15
	cylinder.bottom_radius = 0.3
	cylinder.height = 0.6
	marker.mesh = cylinder
	var mat := StandardMaterial3D.new()
	mat.albedo_color = player_color
	marker.material_override = mat
	marker.position = Vector3(0, 0.4, 0)
	add_child(marker)

	var label := Label3D.new()
	label.text = settlement_name
	label.font_size = 48
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.0, 0)
	label.modulate = Color(1.0, 0.95, 0.8)
	label.outline_modulate = Color(0.15, 0.1, 0.05)
	label.outline_size = 8
	add_child(label)
