class_name BonfireBuilder
extends RefCounted


static func create_bonfire(
	player_color: Color = Color(0.9, 0.2, 0.2),
) -> Node3D:
	var root := Node3D.new()
	_add_stone_ring(root)
	_add_logs(root)
	_add_flames(root, player_color)
	_add_embers(root)
	_add_smoke(root)
	return root


static func _add_stone_ring(root: Node3D) -> void:
	var count := 10
	var radius := 0.22
	for i in count:
		var angle := TAU * float(i) / float(count)
		angle += randf_range(-0.12, 0.12)
		var r := radius + randf_range(-0.03, 0.03)
		var stone := _make_irregular_stone()
		stone.position = Vector3(
			cos(angle) * r, 0.0, sin(angle) * r
		)
		stone.rotation = Vector3(
			randf_range(-0.25, 0.25),
			randf() * TAU,
			randf_range(-0.25, 0.25),
		)
		root.add_child(stone)


static func _make_irregular_stone() -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base_r := randf_range(0.06, 0.1)
	var h := randf_range(0.06, 0.1)
	var shade := randf_range(0.35, 0.55)
	var col := Color(shade, shade * 0.95, shade * 0.88)
	var sides := 8
	var layers := 3
	var all_rings: Array[Array] = []
	var all_colors: Array[Color] = []
	for ly in layers + 1:
		var t := float(ly) / float(layers)
		var lr := base_r * lerpf(1.0, randf_range(0.5, 0.8), t)
		var ly_h := h * t
		var ring: Array[Vector3] = []
		for j in sides:
			var a := TAU * float(j) / float(sides)
			var jr := lr * randf_range(0.7, 1.3)
			ring.append(Vector3(
				cos(a) * jr + randf_range(-0.008, 0.008),
				ly_h * randf_range(0.85, 1.15),
				sin(a) * jr + randf_range(-0.008, 0.008),
			))
		all_rings.append(ring)
		all_colors.append(col.darkened(t * 0.15))
	# Top cap
	var top_center := Vector3(0, h, 0)
	var top_ring: Array = all_rings[layers]
	for j in sides:
		var j2 := (j + 1) % sides
		st.set_color(all_colors[layers])
		st.set_normal(Vector3.UP)
		st.add_vertex(top_center)
		var v0: Vector3 = top_ring[j]
		var v1: Vector3 = top_ring[j2]
		st.add_vertex(v0)
		st.add_vertex(v1)
	# Bottom cap
	for j in sides:
		var j2 := (j + 1) % sides
		st.set_color(col.darkened(0.4))
		st.set_normal(Vector3.DOWN)
		st.add_vertex(Vector3.ZERO)
		var v0: Vector3 = all_rings[0][j2]
		var v1: Vector3 = all_rings[0][j]
		st.add_vertex(v0)
		st.add_vertex(v1)
	# Side faces between layers
	for ly in layers:
		var r0: Array = all_rings[ly]
		var r1: Array = all_rings[ly + 1]
		var c0: Color = all_colors[ly]
		var c1: Color = all_colors[ly + 1]
		for j in sides:
			var j2 := (j + 1) % sides
			var v0: Vector3 = r0[j]
			var v1: Vector3 = r0[j2]
			var v2: Vector3 = r1[j]
			var v3: Vector3 = r1[j2]
			var n := (v1 - v0).cross(v2 - v0).normalized()
			st.set_normal(n)
			st.set_color(c0)
			st.add_vertex(v0)
			st.set_color(c0)
			st.add_vertex(v1)
			st.set_color(c1)
			st.add_vertex(v2)
			st.set_normal(n)
			st.set_color(c0)
			st.add_vertex(v1)
			st.set_color(c1)
			st.add_vertex(v3)
			st.set_color(c1)
			st.add_vertex(v2)
	var mesh_inst := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mesh_inst.material_override = mat
	mesh_inst.mesh = st.commit()
	return mesh_inst


static func _add_logs(root: Node3D) -> void:
	var char_mat := StandardMaterial3D.new()
	char_mat.albedo_color = Color(0.12, 0.06, 0.03)
	char_mat.roughness = 1.0
	# Charred center bed
	var char_mesh := CylinderMesh.new()
	char_mesh.top_radius = 0.1
	char_mesh.bottom_radius = 0.14
	char_mesh.height = 0.04
	var char_node := MeshInstance3D.new()
	char_node.mesh = char_mesh
	char_node.material_override = char_mat
	char_node.position = Vector3(0, 0.02, 0)
	root.add_child(char_node)
	# Lying logs with gradient: black center, brown edge
	var log_count := 5
	for i in log_count:
		var angle := TAU * float(i) / float(log_count)
		angle += randf_range(-0.3, 0.3)
		var log_len := randf_range(0.3, 0.4)
		var log_r := randf_range(0.025, 0.04)
		var log_node := _make_gradient_log(
			log_len, log_r, angle
		)
		root.add_child(log_node)


static func _make_gradient_log(
	length: float, radius: float, angle: float,
) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 6
	var rings := 6
	var brown := Color(0.4, 0.25, 0.12)
	var black := Color(0.08, 0.04, 0.02)
	var all_ring_pts: Array[Array] = []
	var all_ring_cols: Array[Color] = []
	for ri in rings + 1:
		var t := float(ri) / float(rings)
		var x := (t - 0.5) * length
		var dist_from_center := absf(t - 0.5) * 2.0
		var col := black.lerp(brown, dist_from_center)
		all_ring_cols.append(col)
		var ring: Array[Vector3] = []
		for si in segments:
			var a := TAU * float(si) / float(segments)
			ring.append(Vector3(
				x, cos(a) * radius, sin(a) * radius
			))
		all_ring_pts.append(ring)
	for ri in rings:
		var r0: Array = all_ring_pts[ri]
		var r1: Array = all_ring_pts[ri + 1]
		var c0: Color = all_ring_cols[ri]
		var c1: Color = all_ring_cols[ri + 1]
		for si in segments:
			var si2 := (si + 1) % segments
			var v0: Vector3 = r0[si]
			var v1: Vector3 = r0[si2]
			var v2: Vector3 = r1[si]
			var v3: Vector3 = r1[si2]
			var n := (v1 - v0).cross(v2 - v0).normalized()
			st.set_normal(n)
			st.set_color(c0)
			st.add_vertex(v0)
			st.set_color(c0)
			st.add_vertex(v1)
			st.set_color(c1)
			st.add_vertex(v2)
			st.set_normal(n)
			st.set_color(c0)
			st.add_vertex(v1)
			st.set_color(c1)
			st.add_vertex(v3)
			st.set_color(c1)
			st.add_vertex(v2)
	var mesh_inst := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	mesh_inst.material_override = mat
	mesh_inst.mesh = st.commit()
	mesh_inst.rotation.y = angle
	mesh_inst.rotation.z = randf_range(-0.1, 0.1)
	mesh_inst.position = Vector3(0, 0.06, 0)
	return mesh_inst


static func _add_flames(
	root: Node3D, player_color: Color,
) -> void:
	var base_color := Color(1.0, 0.85, 0.1)
	var mid_color := Color(1.0, 0.5, 0.0)
	# Main tall flame — single trunk that splits into tongues
	_add_splitting_flame(
		root, Vector3(0, 0.12, 0),
		0.1, 0.6, 8, base_color, mid_color, player_color,
		3, 0.6,
	)
	# Secondary flames — split higher up
	var count := 4
	for i in count:
		var angle := TAU * float(i) / float(count)
		angle += randf_range(-0.3, 0.3)
		var dist := randf_range(0.01, 0.03)
		_add_splitting_flame(
			root,
			Vector3(
				cos(angle) * dist, 0.1,
				sin(angle) * dist,
			),
			randf_range(0.06, 0.09),
			randf_range(0.35, 0.5), 6,
			base_color, mid_color, player_color,
			randi_range(2, 3), randf_range(0.5, 0.7),
		)
	# Small base tongues — no splitting
	for i in 6:
		var angle := TAU * float(i) / 6.0 + randf_range(0, 0.5)
		var dist := randf_range(0.02, 0.05)
		_add_flame_tongue(
			root,
			Vector3(
				cos(angle) * dist, 0.08,
				sin(angle) * dist,
			),
			randf_range(0.02, 0.04),
			randf_range(0.12, 0.22), 5,
			base_color, mid_color, player_color,
		)


static func _add_splitting_flame(
	root: Node3D, pos: Vector3,
	base_radius: float, height: float, segments: int,
	bottom_color: Color, mid_color: Color,
	top_color: Color,
	split_count: int, split_at: float,
) -> void:
	# Draw trunk up to split point
	var trunk_h := height * split_at
	_add_flame_tongue(
		root, pos,
		base_radius, trunk_h, segments,
		bottom_color, mid_color,
		mid_color.lerp(top_color, 0.3),
	)
	# Split into child tongues from the split point
	var remain_h := height - trunk_h
	for i in split_count:
		var angle := TAU * float(i) / float(split_count)
		angle += randf_range(-0.4, 0.4)
		var spread := randf_range(0.02, 0.05)
		var child_r := base_radius * randf_range(0.3, 0.5)
		var child_h := remain_h * randf_range(0.7, 1.1)
		_add_flame_tongue(
			root,
			pos + Vector3(
				cos(angle) * spread,
				trunk_h * 0.95,
				sin(angle) * spread,
			),
			child_r, child_h,
			maxi(segments - 2, 4),
			mid_color.lerp(top_color, 0.2),
			mid_color.lerp(top_color, 0.5),
			top_color,
		)


static func _add_flame_tongue(
	root: Node3D, pos: Vector3,
	base_radius: float, height: float, segments: int,
	bottom_color: Color, mid_color: Color,
	top_color: Color,
) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var layers := 6
	var rings: Array[Array] = []
	var ring_colors: Array[Color] = []
	for layer in layers + 1:
		var t := float(layer) / float(layers)
		var r: float
		if t < 0.25:
			r = base_radius * lerpf(0.7, 1.0, t / 0.25)
		elif t < 0.6:
			var lt := (t - 0.25) / 0.35
			r = base_radius * lerpf(1.0, 0.45, lt)
		else:
			var lt := (t - 0.6) / 0.4
			r = base_radius * lerpf(0.45, 0.0, lt)
		var y := t * height
		var wobble := t * 0.025
		var color: Color
		if t < 0.35:
			color = bottom_color.lerp(mid_color, t / 0.35)
		else:
			color = mid_color.lerp(
				top_color, (t - 0.35) / 0.65
			)
		color.a = lerpf(0.95, 0.0, t * t)
		ring_colors.append(color)
		var ring: Array[Vector3] = []
		for s in segments:
			var a := TAU * float(s) / float(segments)
			var px := cos(a) * r + randf_range(
				-wobble, wobble
			)
			var pz := sin(a) * r + randf_range(
				-wobble, wobble
			)
			ring.append(Vector3(px, y, pz))
		rings.append(ring)
	for layer in layers:
		var r0: Array = rings[layer]
		var r1: Array = rings[layer + 1]
		var c0: Color = ring_colors[layer]
		var c1: Color = ring_colors[layer + 1]
		for s in segments:
			var s2 := (s + 1) % segments
			var v0: Vector3 = r0[s]
			var v1: Vector3 = r0[s2]
			var v2: Vector3 = r1[s]
			var v3: Vector3 = r1[s2]
			var n := (v1 - v0).cross(v2 - v0).normalized()
			st.set_normal(n)
			st.set_color(c0)
			st.add_vertex(v0)
			st.set_color(c0)
			st.add_vertex(v1)
			st.set_color(c1)
			st.add_vertex(v2)
			st.set_normal(n)
			st.set_color(c0)
			st.add_vertex(v1)
			st.set_color(c1)
			st.add_vertex(v3)
			st.set_color(c1)
			st.add_vertex(v2)
	var top_ring: Array = rings[layers]
	var tip := Vector3(0, height, 0)
	var tip_col: Color = ring_colors[layers]
	for s in segments:
		var s2 := (s + 1) % segments
		var v0: Vector3 = top_ring[s]
		var v1: Vector3 = top_ring[s2]
		st.set_normal(Vector3.UP)
		st.set_color(tip_col)
		st.add_vertex(v0)
		st.add_vertex(v1)
		st.add_vertex(tip)
	var mesh_inst := MeshInstance3D.new()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.6, 0.1)
	mat.emission_energy_multiplier = 2.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_inst.material_override = mat
	mesh_inst.mesh = st.commit()
	mesh_inst.position = pos
	# Slight random outward tilt
	if pos.x != 0.0 or pos.z != 0.0:
		var outward_angle := atan2(pos.z, pos.x)
		var tilt := randf_range(0.0, deg_to_rad(5.0))
		mesh_inst.rotation.x = -sin(outward_angle) * tilt
		mesh_inst.rotation.z = cos(outward_angle) * tilt
	root.add_child(mesh_inst)


static func _add_embers(root: Node3D) -> void:
	var ember_mat := StandardMaterial3D.new()
	ember_mat.albedo_color = Color(1.0, 0.3, 0.0)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.3, 0.0)
	ember_mat.emission_energy_multiplier = 3.0
	var count := 8
	for i in count:
		var angle := TAU * float(i) / float(count)
		angle += randf_range(-0.3, 0.3)
		var r := randf_range(0.02, 0.14)
		var ember := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = randf_range(0.01, 0.025)
		sphere.height = sphere.radius * 2.0
		ember.mesh = sphere
		ember.material_override = ember_mat
		ember.position = Vector3(
			cos(angle) * r, randf_range(0.02, 0.08),
			sin(angle) * r,
		)
		root.add_child(ember)


static func _add_smoke(root: Node3D) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = 12
	particles.lifetime = 2.5
	particles.speed_scale = 0.6
	particles.position = Vector3(0, 0.5, 0)
	particles.visibility_aabb = AABB(
		Vector3(-1, -0.5, -1), Vector3(2, 3, 2)
	)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 15.0
	mat.initial_velocity_min = 0.15
	mat.initial_velocity_max = 0.3
	mat.gravity = Vector3(0, 0.05, 0)
	mat.scale_min = 0.3
	mat.scale_max = 0.8
	mat.scale_curve = _make_smoke_scale_curve()
	mat.color = Color(0.35, 0.32, 0.28, 0.2)
	var color_ramp := GradientTexture1D.new()
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.4, 0.35, 0.3, 0.25))
	gradient.add_point(0.4, Color(0.5, 0.48, 0.45, 0.15))
	gradient.set_color(1, Color(0.6, 0.58, 0.55, 0.0))
	color_ramp.gradient = gradient
	mat.color_ramp = color_ramp
	particles.process_material = mat
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	mesh.radial_segments = 6
	mesh.rings = 3
	var draw_mat := StandardMaterial3D.new()
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.vertex_color_use_as_albedo = true
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh.material = draw_mat
	particles.draw_pass_1 = mesh
	root.add_child(particles)


static func _make_smoke_scale_curve() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(0.3, 0.7))
	curve.add_point(Vector2(0.7, 1.0))
	curve.add_point(Vector2(1.0, 1.2))
	var tex := CurveTexture.new()
	tex.curve = curve
	return tex
