extends RefCounted


func test_wavy_edge_points_count() -> void:
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var pts := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(0, 0), 0
	)
	TestAssert.assert_eq(pts.size(), 13)


func test_wavy_edge_endpoints_match_corners() -> void:
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var pts := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(0, 0), 0
	)
	TestAssert.assert_true(
		pts[0].distance_to(c0) < 0.001,
		"first point should match c0",
	)
	TestAssert.assert_true(
		pts[pts.size() - 1].distance_to(c1) < 0.001,
		"last point should match c1",
	)


func test_wavy_edge_deterministic() -> void:
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var pts_a := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(3, 7), 2
	)
	var pts_b := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(3, 7), 2
	)
	for i in range(pts_a.size()):
		TestAssert.assert_true(
			pts_a[i].distance_to(pts_b[i]) < 0.001,
			"same inputs should produce same points",
		)


func test_different_tiles_different_waves() -> void:
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var pts_a := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(0, 0), 0
	)
	var pts_b := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(5, 3), 0
	)
	var any_diff := false
	for i in range(1, pts_a.size() - 1):
		if pts_a[i].distance_to(pts_b[i]) > 0.01:
			any_diff = true
			break
	TestAssert.assert_true(
		any_diff, "different tiles should have different waves"
	)


func test_wavy_edge_not_straight() -> void:
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var pts := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(5, 3), 2
	)
	var any_offset := false
	for i in range(1, pts.size() - 1):
		var t := float(i) / float(pts.size() - 1)
		var straight := c0.lerp(c1, t)
		if pts[i].distance_to(straight) > 0.01:
			any_offset = true
			break
	TestAssert.assert_true(
		any_offset, "wavy points should deviate from straight line"
	)


func test_inner_ring_constant_distance_from_edge() -> void:
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var edge_pts := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(0, 0), 0
	)
	var inner_pts := HexMeshGenerator.compute_inner_ring(
		edge_pts
	)
	var expected := HexMeshGenerator.BAND_WIDTH
	for i in range(inner_pts.size()):
		var dist := inner_pts[i].distance_to(edge_pts[i])
		TestAssert.assert_true(
			absf(dist - expected) < 0.001,
			"inner point should be BAND_WIDTH from edge point",
		)


func test_inner_ring_points_toward_center() -> void:
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var edge_pts: Array[Vector3] = [c0, c1] as Array[Vector3]
	var inner_pts := HexMeshGenerator.compute_inner_ring(
		edge_pts
	)
	for i in range(inner_pts.size()):
		var inner_dist := Vector2(
			inner_pts[i].x, inner_pts[i].z
		).length()
		var edge_dist := Vector2(
			edge_pts[i].x, edge_pts[i].z
		).length()
		TestAssert.assert_true(
			inner_dist < edge_dist,
			"inner point should be closer to center than edge",
		)


func test_no_neighbors_has_side_faces() -> void:
	var mesh_none := HexMeshGenerator.create_hex_mesh(
		0.1, Vector2i.ZERO, false, 0
	)
	var mesh_all := HexMeshGenerator.create_hex_mesh(
		0.1, Vector2i.ZERO, false, 0b111111
	)
	var verts_none: int = mesh_none.surface_get_array_len(0)
	var verts_all: int = mesh_all.surface_get_array_len(0)
	TestAssert.assert_true(
		verts_none > verts_all,
		"mesh with no neighbors should have more verts than all-neighbors",
	)


func test_all_neighbors_skips_all_side_faces() -> void:
	var mesh_no_sides := HexMeshGenerator.create_hex_mesh(
		0.1, Vector2i.ZERO, false, 0b111111
	)
	var mesh_no_neighbors := HexMeshGenerator.create_hex_mesh(
		0.1, Vector2i.ZERO, false, 0
	)
	# Each edge has 2 triangles (6 verts) for side faces, 6 edges total
	# = 36 side verts for non-wavy mesh (1 subdivision per edge)
	var diff: int = (
		mesh_no_neighbors.surface_get_array_len(0)
		- mesh_no_sides.surface_get_array_len(0)
	)
	TestAssert.assert_eq(diff, 36)


func test_single_neighbor_skips_one_side() -> void:
	var mesh_none := HexMeshGenerator.create_hex_mesh(
		0.1, Vector2i.ZERO, false, 0
	)
	var mesh_one := HexMeshGenerator.create_hex_mesh(
		0.1, Vector2i.ZERO, false, 0b000001
	)
	var diff: int = (
		mesh_none.surface_get_array_len(0)
		- mesh_one.surface_get_array_len(0)
	)
	# 1 edge × 2 triangles × 3 verts = 6
	TestAssert.assert_eq(diff, 6)
