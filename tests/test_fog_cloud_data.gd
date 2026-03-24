extends RefCounted

var data: FogCloudData


func before_each() -> void:
	data = FogCloudData.new()


func test_starts_empty() -> void:
	TestAssert.assert_eq(data.get_blob_count(), 0, "starts with zero blobs")
	TestAssert.assert_false(data.has_tile(Vector2i(0, 0)), "no tiles tracked")


func test_add_tile_creates_blobs() -> void:
	data.add_tile(Vector2i(0, 0), Vector3(0, 0, 0), 0.3)
	TestAssert.assert_true(data.has_tile(Vector2i(0, 0)), "tile tracked")
	TestAssert.assert_gt(data.get_blob_count(), 0, "blobs created")


func test_add_tile_blob_count_in_expected_range() -> void:
	data.add_tile(Vector2i(0, 0), Vector3(0, 0, 0), 0.3)
	var count: int = data.get_blob_count()
	TestAssert.assert_true(
		count >= 4 and count <= 6,
		"expected 4-6 blobs (2 clusters * 2-3 each), got %d" % count,
	)


func test_remove_tile_clears_blobs() -> void:
	data.add_tile(Vector2i(0, 0), Vector3(0, 0, 0), 0.3)
	data.remove_tile(Vector2i(0, 0))
	TestAssert.assert_eq(data.get_blob_count(), 0, "blobs removed")
	TestAssert.assert_false(data.has_tile(Vector2i(0, 0)), "tile untracked")


func test_remove_nonexistent_tile_is_safe() -> void:
	data.remove_tile(Vector2i(99, 99))
	TestAssert.assert_eq(data.get_blob_count(), 0, "still zero")


func test_multiple_tiles_accumulate_blobs() -> void:
	data.add_tile(Vector2i(0, 0), Vector3(0, 0, 0), 0.3)
	var count1: int = data.get_blob_count()
	data.add_tile(Vector2i(1, 0), Vector3(2, 0, 0), 0.3)
	var count2: int = data.get_blob_count()
	TestAssert.assert_gt(count2, count1, "second tile adds more blobs")


func test_remove_one_tile_keeps_others() -> void:
	data.add_tile(Vector2i(0, 0), Vector3(0, 0, 0), 0.3)
	data.add_tile(Vector2i(1, 0), Vector3(2, 0, 0), 0.3)
	var count_before: int = data.get_blob_count()
	data.remove_tile(Vector2i(0, 0))
	TestAssert.assert_true(data.get_blob_count() > 0, "other tile blobs remain")
	TestAssert.assert_true(
		data.get_blob_count() < count_before, "total decreased"
	)
	TestAssert.assert_true(data.has_tile(Vector2i(1, 0)), "other tile still tracked")


func test_add_duplicate_tile_is_idempotent() -> void:
	data.add_tile(Vector2i(0, 0), Vector3(0, 0, 0), 0.3)
	var count1: int = data.get_blob_count()
	data.add_tile(Vector2i(0, 0), Vector3(0, 0, 0), 0.3)
	TestAssert.assert_eq(data.get_blob_count(), count1, "no double-add")


func test_get_instance_transforms_returns_correct_count() -> void:
	data.add_tile(Vector2i(0, 0), Vector3(0, 0, 0), 0.3)
	var transforms: Array = data.get_instance_transforms()
	TestAssert.assert_eq(
		transforms.size(), data.get_blob_count(),
		"transform count matches blob count",
	)


func test_get_instance_custom_data_returns_correct_count() -> void:
	data.add_tile(Vector2i(0, 0), Vector3(0, 0, 0), 0.3)
	var custom: Array = data.get_instance_custom_data()
	TestAssert.assert_eq(
		custom.size(), data.get_blob_count(),
		"custom data count matches blob count",
	)


func test_blob_transforms_are_near_tile_position() -> void:
	var world_pos := Vector3(5.0, 0.2, 8.0)
	data.add_tile(Vector2i(3, 2), world_pos, 0.3)
	var transforms: Array = data.get_instance_transforms()
	for i in transforms.size():
		var t: Transform3D = transforms[i]
		var dist: float = Vector2(
			t.origin.x - world_pos.x,
			t.origin.z - world_pos.z,
		).length()
		TestAssert.assert_true(
			dist < 2.0,
			"blob %d too far from tile (dist=%.1f)" % [i, dist],
		)
