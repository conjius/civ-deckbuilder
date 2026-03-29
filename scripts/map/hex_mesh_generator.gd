class_name HexMeshGenerator


static func create_hex_mesh(
	height: float = 0.1,
	coord: Vector2i = Vector2i.ZERO,
	wavy: bool = true,
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var top_y := height * 0.5
	var bot_y := -height * 0.5
	var center := Vector3(0.0, top_y, 0.0)
	var hex_radius := HexUtil.HEX_SIZE

	for i in range(6):
		var c0 := HexUtil.hex_corner_offset(i)
		var c1 := HexUtil.hex_corner_offset((i + 1) % 6)

		var edge_pts: Array[Vector3]
		if wavy:
			edge_pts = get_wavy_edge_points(c0, c1, coord, i)
		else:
			edge_pts = [c0, c1] as Array[Vector3]

		# Top face — fan from center with edge fade alpha
		for j in range(edge_pts.size() - 1):
			var p0 := edge_pts[j]
			var p1 := edge_pts[j + 1]
			var a0 := _edge_alpha(p0, hex_radius)
			var a1 := _edge_alpha(p1, hex_radius)
			st.set_normal(Vector3.UP)
			st.set_color(Color(1, 1, 1, 1))
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(center)
			st.set_color(Color(1, 1, 1, a0))
			st.set_uv(_hex_uv(p0))
			st.add_vertex(Vector3(p0.x, top_y, p0.z))
			st.set_color(Color(1, 1, 1, a1))
			st.set_uv(_hex_uv(p1))
			st.add_vertex(Vector3(p1.x, top_y, p1.z))

		# Side faces
		for j in range(edge_pts.size() - 1):
			var p0 := edge_pts[j]
			var p1 := edge_pts[j + 1]
			var sn := Vector3(
				(p0.x + p1.x) * 0.5, 0.0,
				(p0.z + p1.z) * 0.5,
			).normalized()
			var a0 := _edge_alpha(p0, hex_radius)
			var a1 := _edge_alpha(p1, hex_radius)
			st.set_normal(sn)
			st.set_color(Color(1, 1, 1, a0))
			st.add_vertex(Vector3(p0.x, top_y, p0.z))
			st.set_color(Color(1, 1, 1, a0 * 0.5))
			st.add_vertex(Vector3(p0.x, bot_y, p0.z))
			st.set_color(Color(1, 1, 1, a1 * 0.5))
			st.add_vertex(Vector3(p1.x, bot_y, p1.z))
			st.set_normal(sn)
			st.set_color(Color(1, 1, 1, a0))
			st.add_vertex(Vector3(p0.x, top_y, p0.z))
			st.set_color(Color(1, 1, 1, a1 * 0.5))
			st.add_vertex(Vector3(p1.x, bot_y, p1.z))
			st.set_color(Color(1, 1, 1, a1))
			st.add_vertex(Vector3(p1.x, top_y, p1.z))

	return st.commit()


static func _edge_alpha(
	point: Vector3, hex_radius: float,
) -> float:
	var dist := Vector2(point.x, point.z).length()
	var fade_start := hex_radius * 0.75
	if dist <= fade_start:
		return 1.0
	return clampf(
		1.0 - (dist - fade_start) / (hex_radius * 0.35), 0.0, 1.0
	)


static func create_hex_collision_shape(
	height: float = 0.1,
) -> ConvexPolygonShape3D:
	var points: PackedVector3Array = []
	var top_y := height * 0.5
	var bot_y := -height * 0.5
	for i in range(6):
		var c := HexUtil.hex_corner_offset(i)
		points.append(Vector3(c.x, top_y, c.z))
		points.append(Vector3(c.x, bot_y, c.z))
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	return shape


static func create_hex_outline_mesh(
	thickness: float = 0.08,
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var y := 0.0
	for i in range(6):
		var c0 := HexUtil.hex_corner_offset(i)
		var c1 := HexUtil.hex_corner_offset((i + 1) % 6)

		var dir0 := c0.normalized()
		var dir1 := c1.normalized()
		var inner0 := c0 - dir0 * thickness
		var inner1 := c1 - dir1 * thickness

		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(inner0.x, y, inner0.z))
		st.add_vertex(Vector3(c0.x, y, c0.z))
		st.add_vertex(Vector3(c1.x, y, c1.z))

		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(inner0.x, y, inner0.z))
		st.add_vertex(Vector3(c1.x, y, c1.z))
		st.add_vertex(Vector3(inner1.x, y, inner1.z))

	return st.commit()


static func get_wavy_edge_points(
	c0: Vector3, c1: Vector3,
	coord: Vector2i, edge_idx: int,
	subdivisions: int = 10,
	amplitude: float = 0.25,
) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	var edge_dir := (c1 - c0).normalized()
	var perp := Vector3(-edge_dir.z, 0.0, edge_dir.x)
	# Per-tile per-edge unique seed
	var seed_val := int(absf(
		float(coord.x) * 7919.0 + float(coord.y) * 4513.0
		+ float(edge_idx) * 3571.0 + 1234.0
	))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var raw: Array[Vector3] = []
	for i in range(subdivisions + 1):
		var t := float(i) / float(subdivisions)
		var base := c0.lerp(c1, t)
		if i == 0 or i == subdivisions:
			raw.append(base)
		else:
			var offset := rng.randf_range(-amplitude, amplitude)
			raw.append(base + perp * offset)
	pts.assign(raw)
	return pts


static func _hex_uv(corner: Vector3) -> Vector2:
	var u := 0.5 + corner.x / (2.0 * HexUtil.HEX_SIZE)
	var v := 0.5 + corner.z / (2.0 * HexUtil.HEX_SIZE)
	return Vector2(u, v)
