class_name FogCloudManager
extends Node3D

var _data := FogCloudData.new()
var _cloud_multimesh: MultiMeshInstance3D
var _multimesh: MultiMesh
var _dirty := false
var _base_transforms: Array = []
var _anim_params: Array = []


func _ready() -> void:
	_setup_multimesh()


func _setup_multimesh() -> void:
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_custom_data = true
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.6, 0.6, 0.65, 0.5)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_BACK
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
	_base_transforms = _data.get_instance_transforms()
	var customs: Array = _data.get_instance_custom_data()
	_anim_params.clear()
	for i in count:
		_multimesh.set_instance_transform(
			i, _base_transforms[i] as Transform3D
		)
		var c: Color = customs[i] as Color
		_anim_params.append({
			"phase": c.r,
			"drift": c.g,
			"breathe_spd": c.b,
			"breathe_amp": c.a,
		})


func _process(_delta: float) -> void:
	if _dirty:
		rebuild()
	var count: int = _base_transforms.size()
	if count == 0:
		return
	var t: float = Time.get_ticks_msec() * 0.001
	for i in count:
		var base: Transform3D = _base_transforms[i] as Transform3D
		var p: Dictionary = _anim_params[i]
		var phase: float = p["phase"] as float
		var drift: float = p["drift"] as float
		var bs: float = p["breathe_spd"] as float
		var ba: float = p["breathe_amp"] as float
		var breathe: float = 1.0 + ba * sin(t * bs + phase)
		var dx: float = sin(t * drift + phase) * 0.5
		var dz: float = cos(t * drift * 0.7 + phase * 1.3) * 0.5
		var animated := Transform3D(
			base.basis.scaled(
				Vector3(breathe, breathe, breathe)
			),
			base.origin + Vector3(dx, 0, dz),
		)
		_multimesh.set_instance_transform(i, animated)
