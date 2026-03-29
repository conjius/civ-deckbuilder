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

	for i in range(6):
		var c0 := HexUtil.hex_corner_offset(i)
		var c1 := HexUtil.hex_corner_offset((i + 1) % 6)

		var edge_pts: Array[Vector3]
		if wavy:
			edge_pts = get_wavy_edge_points(c0, c1, coord, i)
		else:
			edge_pts = [c0, c1] as Array[Vector3]

		# Top face — fan triangles from center to each edge segment
		for j in range(edge_pts.size() - 1):
			var p0 := edge_pts[j]
			var p1 := edge_pts[j + 1]
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(center)
			st.set_uv(_hex_uv(p0))
			st.add_vertex(Vector3(p0.x, top_y, p0.z))
			st.set_uv(_hex_uv(p1))
			st.add_vertex(Vector3(p1.x, top_y, p1.z))

		# Side faces — quad strip along edge segments
		for j in range(edge_pts.size() - 1):
			var p0 := edge_pts[j]
			var p1 := edge_pts[j + 1]
			var sn := Vector3(
				(p0.x + p1.x) * 0.5, 0.0,
				(p0.z + p1.z) * 0.5,
			).normalized()
			st.set_normal(sn)
			st.add_vertex(Vector3(p0.x, top_y, p0.z))
			st.add_vertex(Vector3(p0.x, bot_y, p0.z))
			st.add_vertex(Vector3(p1.x, bot_y, p1.z))
			st.set_normal(sn)
			st.add_vertex(Vector3(p0.x, top_y, p0.z))
			st.add_vertex(Vector3(p1.x, bot_y, p1.z))
			st.add_vertex(Vector3(p1.x, top_y, p1.z))

	return st.commit()


static func create_hex_collision_shape(height: float = 0.1) -> ConvexPolygonShape3D:
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


static func create_hex_outline_mesh(thickness: float = 0.08) -> ArrayMesh:
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

		# Quad: outer0, outer1, inner1, inner0 (two triangles, CCW)
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
	_coord: Vector2i, _edge_idx: int,
	subdivisions: int = 8,
	amplitude: float = 0.06,
) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	# Sort corners so both tiles sharing this edge get same seed
	var key_a := c0.x * 1000.0 + c0.z
	var key_b := c1.x * 1000.0 + c1.z
	var reversed := key_a > key_b
	var p0 := c1 if reversed else c0
	var p1 := c0 if reversed else c1
	# Direction along edge and perpendicular
	var edge_dir := (p1 - p0).normalized()
	var perp := Vector3(-edge_dir.z, 0.0, edge_dir.x)
	# Seed from corner positions for determinism
	var seed_val := int(
		absf(p0.x * 7919.0 + p0.z * 4513.0
		+ p1.x * 3571.0 + p1.z * 6271.0)
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var raw: Array[Vector3] = []
	for i in range(subdivisions + 1):
		var t := float(i) / float(subdivisions)
		var base := p0.lerp(p1, t)
		if i == 0 or i == subdivisions:
			raw.append(base)
		else:
			var offset := rng.randf_range(-amplitude, amplitude)
			raw.append(base + perp * offset)
	if reversed:
		raw.reverse()
	pts.assign(raw)
	return pts


static func _hex_uv(corner: Vector3) -> Vector2:
	var u := 0.5 + corner.x / (2.0 * HexUtil.HEX_SIZE)
	var v := 0.5 + corner.z / (2.0 * HexUtil.HEX_SIZE)
	return Vector2(u, v)
