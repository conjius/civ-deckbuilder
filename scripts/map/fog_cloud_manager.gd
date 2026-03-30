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
	_cloud_shader = load(
		"res://assets/shaders/fog_cloud.gdshader"
	) as Shader
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_custom_data = true
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 1.0
	sphere.radial_segments = 6
	sphere.rings = 3
	_multimesh.mesh = sphere
	_multimesh.instance_count = 0

	_cloud_multimesh = MultiMeshInstance3D.new()
	_cloud_multimesh.multimesh = _multimesh
	var mat := ShaderMaterial.new()
	mat.shader = _cloud_shader
	mat.render_priority = 1
	_cloud_multimesh.material_override = mat
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
