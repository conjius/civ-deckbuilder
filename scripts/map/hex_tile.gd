extends Node3D

var coord: Vector2i
var terrain: TerrainType
var is_revealed: bool = false

var _highlight_mat: StandardMaterial3D
var _pulse_tween: Tween
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _yield_sprites: Array[Sprite3D] = []
var _materials_icon: Texture2D
var _food_icon: Texture2D
var _parchment_tex: Texture2D
var _has_settlement: bool = false
var _fog_particles: Node3D


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
	if not is_revealed:
		_fog_particles = _create_fog_clouds()
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
	if _parchment_tex == null:
		_parchment_tex = load(
			"res://assets/textures/ui/parchment_256_grayscale.png"
		) as Texture2D
	var bg_mat := StandardMaterial3D.new()
	if _parchment_tex:
		bg_mat.albedo_texture = _parchment_tex
	bg_mat.albedo_color = Color(0.3, 0.22, 0.15, 0.8)
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
	if value and _fog_particles == null:
		_fog_particles = _create_fog_clouds()
	if _fog_particles:
		_fog_particles.visible = value


func _create_fog_clouds() -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(0, 0.55, 0)
	add_child(root)
	var cloud_mat := StandardMaterial3D.new()
	cloud_mat.transparency = (
		BaseMaterial3D.TRANSPARENCY_ALPHA
	)
	cloud_mat.albedo_color = Color(0.6, 0.6, 0.65, 0.2)
	cloud_mat.cull_mode = BaseMaterial3D.CULL_BACK
	cloud_mat.render_priority = -1
	cloud_mat.shading_mode = (
		BaseMaterial3D.SHADING_MODE_PER_VERTEX
	)
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.albedo_color = Color.BLACK
	var cloud_count := 2
	for i in cloud_count:
		var angle := randf() * TAU
		var dist := randf_range(0.0, 0.5)
		var cluster := Node3D.new()
		cluster.position = Vector3(
			cos(angle) * dist,
			randf_range(-0.05, 0.15),
			sin(angle) * dist,
		)
		root.add_child(cluster)
		var blob_count := randi_range(2, 3)
		for j in blob_count:
			var mesh := SphereMesh.new()
			mesh.radius = randf_range(0.25, 0.5)
			mesh.height = randf_range(0.4, 0.7)
			mesh.radial_segments = 16
			mesh.rings = 8
			mesh.material = cloud_mat
			var mi := MeshInstance3D.new()
			mi.mesh = mesh
			var blob_pos := Vector3(
				randf_range(-0.2, 0.2),
				randf_range(-0.06, 0.1),
				randf_range(-0.2, 0.2),
			)
			var blob_scale := Vector3(
				randf_range(0.7, 1.8),
				randf_range(0.4, 1.0),
				randf_range(0.7, 1.8),
			)
			var blob_rot := Vector3(
				randf_range(-0.3, 0.3),
				randf() * TAU,
				randf_range(-0.3, 0.3),
			)
			mi.position = blob_pos
			mi.scale = blob_scale
			mi.rotation = blob_rot
			cluster.add_child(mi)
			# Shadow caster
			var shadow_mesh := SphereMesh.new()
			shadow_mesh.radius = mesh.radius * 0.8
			shadow_mesh.height = mesh.height * 0.5
			shadow_mesh.radial_segments = 8
			shadow_mesh.rings = 4
			shadow_mesh.material = shadow_mat
			var shadow_mi := MeshInstance3D.new()
			shadow_mi.mesh = shadow_mesh
			shadow_mi.position = blob_pos
			shadow_mi.scale = blob_scale
			shadow_mi.rotation = blob_rot
			shadow_mi.cast_shadow = (
				GeometryInstance3D
				.SHADOW_CASTING_SETTING_SHADOWS_ONLY
			)
			cluster.add_child(shadow_mi)
		_animate_cloud(cluster)
	return root


func _animate_cloud(cloud: Node3D) -> void:
	_animate_cloud_step(cloud)
	for child in cloud.get_children():
		if child is MeshInstance3D:
			_animate_blob_breathe(child)


func _animate_cloud_step(cloud: Node3D) -> void:
	var duration := randf_range(25.0, 45.0)
	var angle := randf() * TAU
	var dist := randf_range(1.0, 3.0)
	var target := Vector3(
		cos(angle) * dist,
		randf_range(-0.08, 0.15),
		sin(angle) * dist,
	)
	var tween := create_tween()
	tween.tween_property(
		cloud, "position", target, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(
		func() -> void: _animate_cloud_step(cloud)
	)


func _animate_blob_breathe(blob: MeshInstance3D) -> void:
	var base_scale := blob.scale
	_animate_blob_step(blob, base_scale)


func _animate_blob_step(
	blob: MeshInstance3D, base_scale: Vector3,
) -> void:
	var duration := randf_range(8.0, 18.0)
	var factor := randf_range(0.7, 1.3)
	var target_scale := Vector3(
		base_scale.x * factor,
		base_scale.y * randf_range(0.75, 1.25),
		base_scale.z * factor,
	)
	var target_alpha := randf_range(0.4, 1.0)
	var tween := blob.create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		blob, "scale", target_scale, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		blob, "transparency", target_alpha, duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.chain().tween_callback(
		func() -> void: _animate_blob_step(
			blob, base_scale
		)
	)


func place_settlement(
	settlement_name: String,
	player_color: Color = Color(0.9, 0.2, 0.2),
	map_data: MapData = null,
) -> void:
	_has_settlement = true
	var tent := _build_procedural_tent(player_color)
	tent.position = Vector3(0, 0.1, 0)
	add_child(tent)
	_reposition_yields()

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
