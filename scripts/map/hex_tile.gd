extends Node3D

static var _materials_icon: Texture2D
static var _food_icon: Texture2D
static var _parchment_tex: Texture2D
static var _yield_bg_mat: StandardMaterial3D
static var _yield_bg_mesh: CylinderMesh

var coord: Vector2i
var terrain: TerrainType
var is_revealed: bool = false

var _highlight_mat: StandardMaterial3D
var _pulse_tween: Tween
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _yield_sprites: Array[Sprite3D] = []
var _has_settlement: bool = false


func setup(
	axial_coord: Vector2i, terrain_type: TerrainType,
	mesh: Mesh, shape: ConvexPolygonShape3D,
	terrain_mat: StandardMaterial3D = null,
) -> void:
	coord = axial_coord
	terrain = terrain_type

	$MeshInstance3D.mesh = mesh
	if terrain_mat:
		$MeshInstance3D.material_override = terrain_mat
	else:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = terrain.color
		if terrain.texture:
			mat.albedo_texture = terrain.texture
		$MeshInstance3D.material_override = mat

	$StaticBody3D/CollisionShape3D.shape = shape

	position = HexUtil.axial_to_world(coord.x, coord.y)
	position.y = 0.0

	$HighlightMesh.visible = false
	$FogOverlay.visible = false
	_create_yield_markers()
	apply_visibility(MapData.Visibility.UNEXPLORED)


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


static func _ensure_yield_shared() -> void:
	if _yield_bg_mesh == null:
		_yield_bg_mesh = CylinderMesh.new()
		_yield_bg_mesh.top_radius = 0.156
		_yield_bg_mesh.bottom_radius = 0.156
		_yield_bg_mesh.height = 0.01
		_yield_bg_mesh.radial_segments = 8
	if _parchment_tex == null:
		_parchment_tex = load(
			"res://assets/textures/ui/parchment_256_grayscale.png"
		) as Texture2D
	if _yield_bg_mat == null:
		_yield_bg_mat = StandardMaterial3D.new()
		if _parchment_tex:
			_yield_bg_mat.albedo_texture = _parchment_tex
		_yield_bg_mat.albedo_color = Color(0.3, 0.22, 0.15, 0.9)
		_yield_bg_mat.transparency = (
			BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		)
		_yield_bg_mat.alpha_scissor_threshold = 0.3
		_yield_bg_mat.cull_mode = BaseMaterial3D.CULL_DISABLED


func _add_yield_sprite(
	tex: Texture2D, _tint: Color, pos: Vector3,
) -> void:
	_ensure_yield_shared()
	var bg := MeshInstance3D.new()
	bg.mesh = _yield_bg_mesh
	bg.material_override = _yield_bg_mat
	bg.position = pos
	bg.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_ON
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
		GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	)
	add_child(sprite)
	_yield_sprites.append(sprite)


func _get_yield_positions(count: int) -> Array[Vector3]:
	var y_off := 0.15
	if terrain.terrain_name == "Mountain":
		y_off = 0.85
	elif terrain.terrain_name == "Forest":
		y_off = 0.75
	var spacing := 0.56 if not _has_settlement else 0.72
	var result: Array[Vector3] = []
	var start_x := -spacing * (count - 1) * 0.5
	for i in range(count):
		result.append(Vector3(start_x + i * spacing, y_off, 0))
	return result


func _reposition_yields() -> void:
	var count := _yield_sprites.size()
	if count == 0:
		return
	var positions := _get_yield_positions(count)
	for i in count:
		var sprite: Sprite3D = _yield_sprites[i]
		sprite.position = Vector3(
			positions[i].x, positions[i].y + 0.01,
			positions[i].z,
		)
		# Move background disc too (sibling before sprite)
		var idx := sprite.get_index()
		if idx > 0:
			var bg := get_child(idx - 1)
			if bg is MeshInstance3D:
				bg.position = positions[i]


func _ensure_highlight_mat() -> void:
	if _highlight_mat:
		return
	_highlight_mat = StandardMaterial3D.new()
	_highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_highlight_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_highlight_mat.albedo_color = Color(1.0, 0.9, 0.2, 0.9)
	_highlight_mat.emission_enabled = true
	_highlight_mat.emission = Color(1.0, 0.9, 0.2)
	_highlight_mat.emission_energy_multiplier = 2.5
	$HighlightMesh.material_override = _highlight_mat


func set_highlighted(value: bool, color: Color = Color(1.0, 0.9, 0.2, 0.9)) -> void:
	$HighlightMesh.visible = value
	if value:
		_ensure_highlight_mat()
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
	if _highlight_mat:
		_highlight_mat.emission_energy_multiplier = 2.5


func set_fog(value: bool) -> void:
	is_revealed = not value
	$FogOverlay.visible = value


func apply_visibility(state: MapData.Visibility) -> void:
	match state:
		MapData.Visibility.UNEXPLORED:
			is_revealed = false
			$MeshInstance3D.visible = false
			$FogOverlay.visible = false
			_set_content_visible(false)
		MapData.Visibility.FOGGED:
			is_revealed = false
			$MeshInstance3D.visible = true
			$FogOverlay.visible = true
			_set_content_visible(true)
		MapData.Visibility.VISIBLE:
			is_revealed = true
			$MeshInstance3D.visible = true
			$FogOverlay.visible = false
			_set_content_visible(true)


func _set_content_visible(value: bool) -> void:
	for sprite in _yield_sprites:
		sprite.visible = value
		var idx := sprite.get_index()
		if idx > 0:
			var bg := get_child(idx - 1)
			if bg is MeshInstance3D:
				bg.visible = value


func place_settlement(
	settlement_name: String,
	player_color: Color = Color(0.9, 0.2, 0.2),
	_map_data: MapData = null,
) -> void:
	_has_settlement = true
	var tent := _build_procedural_tent(player_color)
	tent.position = Vector3(0, 0.1, 0)
	add_child(tent)
	_reposition_yields()

	var label_y := 1.2
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


func _build_procedural_tent(
	player_color: Color,
) -> Node3D:
	var root := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := 0.18
	var h := 0.45
	var depth := 0.28
	var overhang := 0.06
	var col := player_color
	# Base corners (walls)
	var fl := Vector3(-hw, 0, -depth)
	var fr := Vector3(hw, 0, -depth)
	var bl := Vector3(-hw, 0, depth)
	var br := Vector3(hw, 0, depth)
	# Roof ridge with overhang
	var ft := Vector3(0, h, -depth - overhang)
	var bt := Vector3(0, h, depth + overhang)
	# Roof slopes
	var n_left := (bt - fl).cross(bl - fl).normalized()
	st.set_normal(n_left)
	st.set_color(col)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(fl)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(bl)
	st.set_uv(Vector2(0.5, 0))
	st.add_vertex(ft)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(bl)
	st.set_uv(Vector2(0.5, 0))
	st.add_vertex(bt)
	st.set_uv(Vector2(0.5, 0))
	st.add_vertex(ft)
	var n_right := (br - fr).cross(bt - fr).normalized()
	st.set_normal(n_right)
	st.set_color(col)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(fr)
	st.set_uv(Vector2(0.5, 0))
	st.add_vertex(ft)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(br)
	st.set_uv(Vector2(0.5, 0))
	st.add_vertex(ft)
	st.set_uv(Vector2(0.5, 0))
	st.add_vertex(bt)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(br)
	# Back wall
	st.set_normal(Vector3(0, 0, 1))
	st.set_color(col)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(br)
	st.set_uv(Vector2(0.5, 0))
	st.add_vertex(bt)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(bl)
	# Front wall
	st.set_normal(Vector3(0, 0, -1))
	st.set_color(col)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(fl)
	st.set_uv(Vector2(0.5, 0))
	st.add_vertex(ft)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(fr)
	# Bottom face
	st.set_normal(Vector3.DOWN)
	st.set_color(col)
	st.set_uv(Vector2(0, 0))
	st.add_vertex(fl)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(fr)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(bl)
	st.set_uv(Vector2(1, 0))
	st.add_vertex(fr)
	st.set_uv(Vector2(1, 1))
	st.add_vertex(br)
	st.set_uv(Vector2(0, 1))
	st.add_vertex(bl)
	# Flag pole + flag at front peak
	var pole_h := 0.15
	var pw := 0.008
	var pz := -depth - overhang - 0.001
	st.set_normal(Vector3(0, 0, -1))
	st.set_color(Color(0.3, 0.2, 0.1))
	st.add_vertex(Vector3(-pw, h, pz))
	st.add_vertex(Vector3(pw, h, pz))
	st.add_vertex(Vector3(pw, h + pole_h, pz))
	st.add_vertex(Vector3(-pw, h, pz))
	st.add_vertex(Vector3(pw, h + pole_h, pz))
	st.add_vertex(Vector3(-pw, h + pole_h, pz))
	st.set_normal(Vector3(0, 0, -1))
	st.set_color(player_color)
	st.add_vertex(Vector3(0, h + pole_h, pz - 0.001))
	st.add_vertex(Vector3(
		0.12, h + pole_h * 0.3, pz - 0.001
	))
	st.add_vertex(Vector3(
		0, h + pole_h * 0.6, pz - 0.001
	))
	var mesh_inst := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.8
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_inst.material_override = mat
	mesh_inst.mesh = st.commit()
	if _parchment_tex:
		var overlay := StandardMaterial3D.new()
		overlay.albedo_texture = _parchment_tex
		overlay.albedo_color = Color(1, 1, 1, 0.3)
		overlay.transparency = (
			BaseMaterial3D.TRANSPARENCY_ALPHA
		)
		overlay.cull_mode = BaseMaterial3D.CULL_DISABLED
		overlay.uv1_scale = Vector3(2.0, 2.0, 2.0)
		mesh_inst.material_overlay = overlay
	root.add_child(mesh_inst)
	return root


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
