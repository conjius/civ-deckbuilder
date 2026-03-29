extends RefCounted


func test_renderer_is_gl_compatibility() -> void:
	var cfg := ConfigFile.new()
	cfg.load("res://project.godot")
	var renderer: String = cfg.get_value(
		"rendering", "renderer/rendering_method", ""
	) as String
	TestAssert.assert_eq(renderer, "gl_compatibility")


func test_etc2_astc_enabled() -> void:
	var cfg := ConfigFile.new()
	cfg.load("res://project.godot")
	var enabled: bool = cfg.get_value(
		"rendering",
		"textures/vram_compression/import_etc2_astc",
		false,
	) as bool
	TestAssert.assert_true(enabled)


func test_coi_service_worker_exists() -> void:
	var file := FileAccess.open(
		"res://scripts/tools/coi-serviceworker.min.js",
		FileAccess.READ,
	)
	TestAssert.assert_not_null(file, "coi-serviceworker.min.js must exist")
	if file:
		var content := file.get_as_text()
		TestAssert.assert_true(
			content.length() > 100,
			"coi-serviceworker should not be empty",
		)
		file.close()


func test_web_export_uses_nothreads() -> void:
	var file := FileAccess.open(
		"res://scripts/tools/dev-server.sh", FileAccess.READ
	)
	TestAssert.assert_not_null(file, "dev-server.sh must exist")
	if file:
		var content := file.get_as_text()
		TestAssert.assert_true(
			content.contains("thread_support=false"),
			"web export must use nothreads",
		)
		file.close()


func test_main_scene_set() -> void:
	var cfg := ConfigFile.new()
	cfg.load("res://project.godot")
	var scene: String = cfg.get_value(
		"application", "run/main_scene", ""
	) as String
	TestAssert.assert_true(
		scene != "", "main scene must be set"
	)
