extends RefCounted

const MAX_TEXTURE_BYTES := 512 * 1024


func test_mountain_normal_under_limit() -> void:
	var size := _file_size(
		"res://assets/models/mountain/mountain_normal.png"
	)
	TestAssert.assert_true(
		size < MAX_TEXTURE_BYTES,
		"mountain_normal.png is %d bytes, max %d" % [
			size, MAX_TEXTURE_BYTES,
		],
	)


func test_mountain_texture_under_limit() -> void:
	var size := _file_size(
		"res://assets/models/mountain/SnowyMountainTexture.png"
	)
	TestAssert.assert_true(
		size < MAX_TEXTURE_BYTES,
		"SnowyMountainTexture.png is %d bytes, max %d" % [
			size, MAX_TEXTURE_BYTES,
		],
	)


func test_boot_texture_under_limit() -> void:
	var size := _file_size(
		"res://assets/models/boots/Tcuer.png"
	)
	TestAssert.assert_true(
		size < MAX_TEXTURE_BYTES,
		"Tcuer.png is %d bytes, max %d" % [
			size, MAX_TEXTURE_BYTES,
		],
	)


func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	var size := file.get_length()
	file.close()
	return size
