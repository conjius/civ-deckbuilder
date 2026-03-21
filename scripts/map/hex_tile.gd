extends Node3D

var coord: Vector2i
var terrain: TerrainType
var is_revealed: bool = false

var _highlight_mat: StandardMaterial3D
var _pulse_tween: Tween
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _tent_path: String = "res://assets/models/buildings/tent.gltf"
var _yield_sprites: Array[Sprite3D] = []
var _materials_icon: Texture2D
var _food_icon: Texture2D


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
	_create_yield_markers()


func _create_yield_markers() -> void:
	if _materials_icon == null:
		_materials_icon = load(
			"res://assets/icons/entities/materials.svg"
		) as Texture2D
	if _food_icon == null:
		_food_icon = load(
			"res://assets/icons/entities/food.svg"
		) as Texture2D
	var icons: Array[Array] = []
	for i in range(terrain.materials_yield):
		icons.append([_materials_icon, Color(1.0, 1.0, 1.0)])
	for i in range(terrain.food_yield):
		icons.append([_food_icon, Color(1.0, 1.0, 1.0)])
	if icons.is_empty():
		return
	var count: int = icons.size()
	var positions: Array[Vector3] = _get_yield_positions(count)
	for idx in range(count):
		var tex: Texture2D = icons[idx][0] as Texture2D
		var tint: Color = icons[idx][1] as Color
		if tex == null:
			continue
		_add_yield_sprite(tex, tint, positions[idx])


func _add_yield_sprite(
	tex: Texture2D, _tint: Color, pos: Vector3,
) -> void:
	# Background circle
	var bg := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.156
	disc.bottom_radius = 0.156
	disc.height = 0.01
	disc.radial_segments = 16
	bg.mesh = disc
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.12, 0.08, 0.05, 0.6)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	bg.material_override = bg_mat
	bg.position = pos
	bg.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
	add_child(bg)

	# Icon sprite lying flat facing sky
	var sprite := Sprite3D.new()
	sprite.texture = tex
	sprite.pixel_size = 0.0004
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	sprite.double_sided = true
	sprite.position = Vector3(pos.x, pos.y + 0.01, pos.z)
	sprite.rotation_degrees = Vector3(-90, 0, 0)
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.8)
	sprite.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
	add_child(sprite)
	_yield_sprites.append(sprite)


func _get_yield_positions(count: int) -> Array[Vector3]:
	var y_off := 0.15
	var spacing := 0.56
	var result: Array[Vector3] = []
	var start_x := -spacing * (count - 1) * 0.5
	for i in range(count):
		result.append(Vector3(start_x + i * spacing, y_off, 0))
	return result


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
	map_data: MapData = null,
) -> void:
	var tent_scene: PackedScene = load(_tent_path) as PackedScene
	if tent_scene:
		var tent: Node3D = tent_scene.instantiate()
		tent.scale = Vector3(0.5, 0.5, 0.5)
		tent.position = Vector3(0, 0.1, 0)
		add_child(tent)
		_color_wash_recursive(tent, player_color)
	else:
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

	var max_h := terrain.height
	if map_data:
		for neighbor in HexUtil.get_neighbors(coord):
			var nt: TerrainType = map_data.get_terrain(neighbor)
			if nt and nt.height > max_h:
				max_h = nt.height
	var label_y := max_h - (terrain.height - 0.1) + 1.2
	var label := Label3D.new()
	label.text = settlement_name
	label.font = _font_bold
	label.font_size = UIHelpers.SETTLEMENT_FONT_SIZE
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, label_y, 0)
	label.modulate = player_color
	label.outline_modulate = Color(0.15, 0.1, 0.05)
	label.outline_size = UIHelpers.SETTLEMENT_OUTLINE
	add_child(label)


func _color_wash_recursive(
	node: Node, color: Color,
) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var overlay := StandardMaterial3D.new()
		overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		overlay.albedo_color = Color(
			color.r, color.g, color.b, 0.7
		)
		overlay.shading_mode = (
			BaseMaterial3D.SHADING_MODE_UNSHADED
		)
		mi.material_overlay = overlay
	for child in node.get_children():
		_color_wash_recursive(child, color)
