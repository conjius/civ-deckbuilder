class_name HexMeshGenerator

const BAND_WIDTH := 0.35
const EDGE_STRETCH := 1.15


static func compute_inner_ring(
	edge_pts: Array[Vector3],
) -> Array[Vector3]:
	var inner: Array[Vector3] = []
	for j in range(edge_pts.size()):
		var ep := edge_pts[j]
		var dir := Vector3(ep.x, 0.0, ep.z).normalized()
		inner.append(Vector3(
			ep.x - dir.x * BAND_WIDTH,
			0.0,
			ep.z - dir.z * BAND_WIDTH,
		))
	return inner


static func create_hex_mesh(
	height: float = 0.1,
	coord: Vector2i = Vector2i.ZERO,
	wavy: bool = true,
	neighbor_mask: int = 0,
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var top_y := height * 0.5
	var bot_y := -height * 0.5
	var center := Vector3(0.0, top_y, 0.0)
	var zoom_hash: int = absi(hash(Vector3i(coord.x, coord.y, 7)) % 100)
	var uv_zoom := 0.75 + float(zoom_hash) / 100.0 * 0.2

	for i in range(6):
		var c0 := HexUtil.hex_corner_offset(i) * EDGE_STRETCH
		var c1 := HexUtil.hex_corner_offset((i + 1) % 6) * EDGE_STRETCH

		var edge_pts: Array[Vector3]
		if wavy:
			edge_pts = get_wavy_edge_points(c0, c1, coord, i)
		else:
			edge_pts = [c0, c1] as Array[Vector3]

		var inner_pts := compute_inner_ring(edge_pts)

		# Inner triangles: center → inner ring (fully opaque)
		for j in range(inner_pts.size() - 1):
			var r0 := inner_pts[j]
			var r1 := inner_pts[j + 1]
			st.set_normal(Vector3.UP)
			st.set_color(Color(1, 1, 1, 1))
			st.set_uv(Vector2(0.5, 0.5))
			st.add_vertex(center)
			st.set_uv(_hex_uv(r0, uv_zoom))
			st.add_vertex(Vector3(r0.x, top_y, r0.z))
			st.set_uv(_hex_uv(r1, uv_zoom))
			st.add_vertex(Vector3(r1.x, top_y, r1.z))

		# Outer band: inner ring (opaque) → wavy edge (transparent)
		for j in range(edge_pts.size() - 1):
			var r0 := inner_pts[j]
			var r1 := inner_pts[j + 1]
			var e0 := edge_pts[j]
			var e1 := edge_pts[j + 1]
			st.set_normal(Vector3.UP)
			st.set_color(Color(1, 1, 1, 1))
			st.set_uv(_hex_uv(r0, uv_zoom))
			st.add_vertex(Vector3(r0.x, top_y, r0.z))
			st.set_color(Color(1, 1, 1, 0))
			st.set_uv(_hex_uv(e0, uv_zoom))
			st.add_vertex(Vector3(e0.x, top_y, e0.z))
			st.set_color(Color(1, 1, 1, 0))
			st.set_uv(_hex_uv(e1, uv_zoom))
			st.add_vertex(Vector3(e1.x, top_y, e1.z))
			st.set_normal(Vector3.UP)
			st.set_color(Color(1, 1, 1, 1))
			st.set_uv(_hex_uv(r0, uv_zoom))
			st.add_vertex(Vector3(r0.x, top_y, r0.z))
			st.set_color(Color(1, 1, 1, 0))
			st.set_uv(_hex_uv(e1, uv_zoom))
			st.add_vertex(Vector3(e1.x, top_y, e1.z))
			st.set_color(Color(1, 1, 1, 1))
			st.set_uv(_hex_uv(r1, uv_zoom))
			st.add_vertex(Vector3(r1.x, top_y, r1.z))

		# Side faces (skip if neighbor exists on this edge)
		if neighbor_mask & (1 << i):
			continue
		for j in range(edge_pts.size() - 1):
			var p0 := edge_pts[j]
			var p1 := edge_pts[j + 1]
			var sn := Vector3(
				(p0.x + p1.x) * 0.5, 0.0,
				(p0.z + p1.z) * 0.5,
			).normalized()
			st.set_normal(sn)
			st.set_color(Color(1, 1, 1, 0))
			st.add_vertex(Vector3(p0.x, top_y, p0.z))
			st.add_vertex(Vector3(p0.x, bot_y, p0.z))
			st.add_vertex(Vector3(p1.x, bot_y, p1.z))
			st.set_normal(sn)
			st.add_vertex(Vector3(p0.x, top_y, p0.z))
			st.add_vertex(Vector3(p1.x, bot_y, p1.z))
			st.add_vertex(Vector3(p1.x, top_y, p1.z))

	return st.commit()


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
	amplitude: float = 0.4,
) -> Array[Vector3]:
	var pts: Array[Vector3] = []
	var edge_dir := (c1 - c0).normalized()
	var perp := Vector3(-edge_dir.z, 0.0, edge_dir.x)
	var seed_val: int = hash(
		Vector3i(coord.x, coord.y, edge_idx)
	)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	# Generate raw offsets
	var offsets: Array[float] = []
	for i in range(subdivisions + 1):
		if i == 0 or i == subdivisions:
			offsets.append(0.0)
		else:
			offsets.append(rng.randf_range(
				-amplitude, -amplitude * 0.2
			))
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


static func _hex_uv(corner: Vector3, uv_zoom: float = 1.0) -> Vector2:
	var u := 0.5 + corner.x / (2.0 * HexUtil.HEX_SIZE) * uv_zoom
	var v := 0.5 + corner.z / (2.0 * HexUtil.HEX_SIZE) * uv_zoom
	return Vector2(u, v)
