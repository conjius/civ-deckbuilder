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

		# Inner ring points at band boundary (fully opaque)
		var band_frac := 0.75
		var inner_pts: Array[Vector3] = []
		for j in range(edge_pts.size()):
			var ep := edge_pts[j]
			inner_pts.append(Vector3(
				ep.x * band_frac, 0.0, ep.z * band_frac
			))

		# Inner triangles: center → inner ring (fully opaque)
		for j in range(inner_pts.size() - 1):
			var r0 := inner_pts[j]
			var r1 := inner_pts[j + 1]
			st.set_normal(Vector3.UP)
			st.set_color(Color(1, 1, 1, 1))
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(center)
			st.set_uv(_hex_uv(r0))
			st.add_vertex(Vector3(r0.x, top_y, r0.z))
			st.set_uv(_hex_uv(r1))
			st.add_vertex(Vector3(r1.x, top_y, r1.z))

		# Outer band: inner ring → wavy edge (opaque to transparent)
		for j in range(edge_pts.size() - 1):
			var r0 := inner_pts[j]
			var r1 := inner_pts[j + 1]
			var e0 := edge_pts[j]
			var e1 := edge_pts[j + 1]
			var a0 := _edge_alpha(e0, hex_radius)
			var a1 := _edge_alpha(e1, hex_radius)
			st.set_normal(Vector3.UP)
			st.set_color(Color(1, 1, 1, 1))
			st.set_uv(_hex_uv(r0))
			st.add_vertex(Vector3(r0.x, top_y, r0.z))
			st.set_color(Color(1, 1, 1, a0))
			st.set_uv(_hex_uv(e0))
			st.add_vertex(Vector3(e0.x, top_y, e0.z))
			st.set_color(Color(1, 1, 1, a1))
			st.set_uv(_hex_uv(e1))
			st.add_vertex(Vector3(e1.x, top_y, e1.z))
			st.set_normal(Vector3.UP)
			st.set_color(Color(1, 1, 1, 1))
			st.set_uv(_hex_uv(r0))
			st.add_vertex(Vector3(r0.x, top_y, r0.z))
			st.set_color(Color(1, 1, 1, a1))
			st.set_uv(_hex_uv(e1))
			st.add_vertex(Vector3(e1.x, top_y, e1.z))
			st.set_color(Color(1, 1, 1, 1))
			st.set_uv(_hex_uv(r1))
			st.add_vertex(Vector3(r1.x, top_y, r1.z))

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
	point: Vector3, _hex_radius: float,
) -> float:
	# Distance to nearest hex edge (not center)
	var p := Vector2(point.x, point.z)
	var min_dist := INF
	for i in range(6):
		var c0 := HexUtil.hex_corner_offset(i)
		var c1 := HexUtil.hex_corner_offset((i + 1) % 6)
		var a := Vector2(c0.x, c0.z)
		var b := Vector2(c1.x, c1.z)
		var d := _point_to_segment_dist(p, a, b)
		if d < min_dist:
			min_dist = d
	# Band: fade over the last 0.2 units from the edge inward
	var band_width := 0.2
	if min_dist >= band_width:
		return 1.0
	return clampf(min_dist / band_width, 0.0, 1.0)


static func _point_to_segment_dist(
	p: Vector2, a: Vector2, b: Vector2,
) -> float:
	var ab := b - a
	var ap := p - a
	var t := clampf(ap.dot(ab) / ab.dot(ab), 0.0, 1.0)
	var closest := a + ab * t
	return p.distance_to(closest)


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
	subdivisions: int = 12,
	amplitude: float = 0.25,
) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	var edge_dir := (c1 - c0).normalized()
	var perp := Vector3(-edge_dir.z, 0.0, edge_dir.x)
	var seed_val := int(absf(
		float(coord.x) * 7919.0 + float(coord.y) * 4513.0
		+ float(edge_idx) * 3571.0 + 1234.0
	))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	# Generate raw offsets
	var offsets: Array[float] = []
	for i in range(subdivisions + 1):
		if i == 0 or i == subdivisions:
			offsets.append(0.0)
		else:
			offsets.append(rng.randf_range(-amplitude, amplitude))
	# Smooth passes — average with neighbors
	for _pass in range(3):
		var smoothed: Array[float] = []
		for i in range(offsets.size()):
			if i == 0 or i == offsets.size() - 1:
				smoothed.append(0.0)
			else:
				smoothed.append(
					offsets[i - 1] * 0.25
					+ offsets[i] * 0.5
					+ offsets[i + 1] * 0.25
				)
		offsets = smoothed
	# Build points
	var raw: Array[Vector3] = []
	for i in range(subdivisions + 1):
		var t := float(i) / float(subdivisions)
		var base := c0.lerp(c1, t)
		raw.append(base + perp * offsets[i])
	pts.assign(raw)
	return pts


static func _hex_uv(corner: Vector3) -> Vector2:
	var u := 0.5 + corner.x / (2.0 * HexUtil.HEX_SIZE)
	var v := 0.5 + corner.z / (2.0 * HexUtil.HEX_SIZE)
	return Vector2(u, v)
