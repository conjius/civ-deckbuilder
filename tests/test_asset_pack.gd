extends RefCounted


func test_pack_loads() -> void:
	var scene: PackedScene = load(
		"res://assets/models/adventure_pack.res"
	) as PackedScene
	TestAssert.assert_true(scene != null, "pack should load")


func test_get_tent_model() -> void:
	var node := AssetPack.get_model("Tent", 0.003)
	TestAssert.assert_true(
		node.get_child_count() > 0,
		"Tent wrapper should have mesh child"
	)
	TestAssert.assert_true(
		node.get_child(0) is MeshInstance3D,
		"Tent child should be MeshInstance3D"
	)


func test_get_house_model() -> void:
	var node := AssetPack.get_model("House", 0.002)
	TestAssert.assert_true(
		node.get_child(0) is MeshInstance3D,
		"House child should be MeshInstance3D"
	)


func test_get_guy_model() -> void:
	var node := AssetPack.get_model("Guy", 0.002)
	TestAssert.assert_true(
		node.get_child(0) is MeshInstance3D,
		"Guy child should be MeshInstance3D"
	)


func test_get_rocks_model() -> void:
	var node := AssetPack.get_model("Rocks", 0.01)
	TestAssert.assert_true(
		node.get_child(0) is MeshInstance3D,
		"Rocks child should be MeshInstance3D"
	)


func test_get_tree_models() -> void:
	var names := [
		"PineTree_V1", "Pinetree_V2", "PineTree_V3",
		"Tree", "Tree1", "Tree2", "Tree4",
	]
	for n in names:
		var node := AssetPack.get_model(n, 0.003)
		TestAssert.assert_true(
			node.get_child(0) is MeshInstance3D,
			"%s child should be MeshInstance3D" % n
		)


func test_model_rotated_for_y_up() -> void:
	var node := AssetPack.get_model("Tent", 0.003)
	var mi := node.get_child(0) as MeshInstance3D
	TestAssert.assert_eq(
		int(mi.rotation_degrees.x), -90
	)


func test_tinted_model_has_material() -> void:
	var node := AssetPack.get_model_tinted(
		"Tent", Color(0.8, 0.2, 0.2), 0.003
	)
	var mi := node.get_child(0) as MeshInstance3D
	var mat: Material = mi.get_surface_override_material(0)
	TestAssert.assert_true(
		mat != null, "tinted mesh should have override material"
	)


func test_nonexistent_model_returns_node() -> void:
	var node := AssetPack.get_model("DoesNotExist", 1.0)
	TestAssert.assert_true(
		node is Node3D, "missing model should return empty Node3D"
	)
