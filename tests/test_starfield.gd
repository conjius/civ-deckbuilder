extends RefCounted


func test_starfield_shader_exists() -> void:
	var shader: Shader = load(
		"res://assets/shaders/starfield_sky.gdshader"
	) as Shader
	TestAssert.assert_not_null(shader, "starfield shader must exist")


func test_starfield_shader_compiles() -> void:
	var shader: Shader = load(
		"res://assets/shaders/starfield_sky.gdshader"
	) as Shader
	if shader == null:
		TestAssert.assert_true(false, "shader not found")
		return
	TestAssert.assert_eq(shader.get_mode(), Shader.MODE_SKY)
