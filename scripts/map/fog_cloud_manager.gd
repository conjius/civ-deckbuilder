class_name FogCloudManager
extends Node3D

var _data := FogCloudData.new()
var _cloud_multimesh: MultiMeshInstance3D
var _multimesh: MultiMesh
var _dirty := false

var _cloud_shader: Shader


func _ready() -> void:
	_setup_multimesh()


func _setup_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_custom_data = true
	var shader := Shader.new()
	shader.code = """shader_type spatial;
render_mode blend_mix, depth_draw_alpha_prepass, cull_back, unshaded;

void vertex() {
	vec3 o = MODEL_MATRIX[3].xyz;
	float ph = fract(sin(dot(o.xz, vec2(127.1, 311.7))) * 43758.5) * 6.28;
	float bs = 0.3 + fract(sin(dot(o.xz + vec2(2.0), vec2(127.1, 311.7))) * 43758.5) * 0.5;
	float ba = 0.1 + fract(sin(dot(o.xz + vec2(3.0), vec2(127.1, 311.7))) * 43758.5) * 0.2;
	float ds = 0.03 + fract(sin(dot(o.xz + vec2(1.0), vec2(127.1, 311.7))) * 43758.5) * 0.05;
	VERTEX *= 1.0 + ba * sin(TIME * bs + ph);
	VERTEX.x += sin(TIME * ds + ph) * 0.5;
	VERTEX.z += cos(TIME * ds * 0.7 + ph * 1.3) * 0.5;
}

void fragment() {
	ALBEDO = vec3(0.6, 0.6, 0.65);
	ALPHA = 0.5;
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.render_priority = 1
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 1.0
	sphere.radial_segments = 12
	sphere.rings = 6
	sphere.material = mat
	_multimesh.mesh = sphere
	_multimesh.instance_count = 0

	_cloud_multimesh = MultiMeshInstance3D.new()
	_cloud_multimesh.multimesh = _multimesh
	_cloud_multimesh.cast_shadow = (
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
	add_child(_cloud_multimesh)


func add_fog(
	coord: Vector2i, world_pos: Vector3, tile_height: float,
) -> void:
	_data.add_tile(coord, world_pos, tile_height)
	_dirty = true


func remove_fog(coord: Vector2i) -> void:
	_data.remove_tile(coord)
	_dirty = true


func has_fog(coord: Vector2i) -> bool:
	return _data.has_tile(coord)


func rebuild() -> void:
	if not _dirty:
		return
	_dirty = false
	var count: int = _data.get_blob_count()
	_multimesh.instance_count = count
	var transforms: Array = _data.get_instance_transforms()
	var customs: Array = _data.get_instance_custom_data()
	for i in count:
		_multimesh.set_instance_transform(
			i, transforms[i] as Transform3D
		)
		_multimesh.set_instance_custom_data(
			i, customs[i] as Color
		)


func _process(_delta: float) -> void:
	if _dirty:
		rebuild()
