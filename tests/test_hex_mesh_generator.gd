extends RefCounted


func test_wavy_edge_points_count() -> void:
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var pts := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(0, 0), 0, 8
	)
	# 8 subdivisions = 9 points (including endpoints)
	TestAssert.assert_eq(pts.size(), 9)


func test_wavy_edge_endpoints_match_corners() -> void:
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var pts := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(0, 0), 0, 8
	)
	# First and last points match the corners exactly
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
		c0, c1, Vector2i(0, 0), 0, 8
	)
	var pts_b := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(0, 0), 0, 8
	)
	for i in range(pts_a.size()):
		TestAssert.assert_true(
			pts_a[i].distance_to(pts_b[i]) < 0.001,
			"same inputs should produce same points",
		)


func test_shared_edge_matches_neighbor() -> void:
	# Edge 0 of tile (0,0) shares with edge 3 of tile (1,0)
	# The points should be the same but reversed
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var pts_a := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(0, 0), 0, 8
	)
	# Neighbor sees the same edge reversed
	var pts_b := HexMeshGenerator.get_wavy_edge_points(
		c1, c0, Vector2i(0, 0), 0, 8
	)
	# pts_b should be pts_a reversed
	for i in range(pts_a.size()):
		var j: int = pts_a.size() - 1 - i
		TestAssert.assert_true(
			pts_a[i].distance_to(pts_b[j]) < 0.001,
			"shared edge reversed should match",
		)


func test_wavy_edge_not_straight() -> void:
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var pts := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(5, 3), 2, 8
	)
	# At least one middle point should deviate from the straight line
	var any_offset := false
	for i in range(1, pts.size() - 1):
		var t := float(i) / float(pts.size() - 1)
		var straight := c0.lerp(c1, t)
		if pts[i].distance_to(straight) > 0.005:
			any_offset = true
			break
	TestAssert.assert_true(
		any_offset, "wavy points should deviate from straight line"
	)
