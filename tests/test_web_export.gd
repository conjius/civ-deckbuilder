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


func test_main_scene_set() -> void:
	var cfg := ConfigFile.new()
	cfg.load("res://project.godot")
	var scene: String = cfg.get_value(
		"application", "run/main_scene", ""
	) as String
	TestAssert.assert_true(
		scene != "", "main scene must be set"
	)
