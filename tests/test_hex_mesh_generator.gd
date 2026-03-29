extends RefCounted


func test_wavy_edge_points_count() -> void:
	var c0 := HexUtil.hex_corner_offset(0)
	var c1 := HexUtil.hex_corner_offset(1)
	var pts := HexMeshGenerator.get_wavy_edge_points(
		c0, c1, Vector2i(0, 0), 0
	)
	TestAssert.assert_eq(pts.size(), 11)


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


func test_edge_alpha_center_is_opaque() -> void:
	var alpha := HexMeshGenerator._edge_alpha(
		Vector3.ZERO, HexUtil.HEX_SIZE
	)
	TestAssert.assert_eq(alpha, 1.0)


func test_edge_alpha_edge_is_transparent() -> void:
	var corner := HexUtil.hex_corner_offset(0)
	var alpha := HexMeshGenerator._edge_alpha(
		corner, HexUtil.HEX_SIZE
	)
	TestAssert.assert_true(
		alpha < 0.5, "corner should be faded"
	)
