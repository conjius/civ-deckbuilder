class_name AssetPack
extends RefCounted

const PACK_PATH := "res://assets/models/adventure_pack.res"
const GROUP_PATH := [
	"Sketchfab_model",
	"4e65bb4247c24ae9829c43604374e9b7_fbx",
	"Object_2", "RootNode", "Group001",
]

static var _pack_scene: PackedScene
static var _mesh_cache: Dictionary = {}


static func get_model(model_name: String, s: float = 1.0) -> Node3D:
	_ensure_loaded()
	var cached_mesh: Mesh = _mesh_cache.get(model_name) as Mesh
	if cached_mesh:
		return _wrap_mesh(cached_mesh, s)
	var root := _pack_scene.instantiate()
	var group: Node = root
	for seg in GROUP_PATH:
		group = group.get_node(seg)
	var source: Node = group.get_node_or_null(model_name)
	if source == null:
		root.queue_free()
		return Node3D.new()
	var mesh: Mesh = _find_mesh(source)
	if mesh:
		_mesh_cache[model_name] = mesh
		root.queue_free()
		return _wrap_mesh(mesh, s)
	root.queue_free()
	return Node3D.new()


static func _wrap_mesh(mesh: Mesh, s: float) -> Node3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.scale = Vector3(s, s, s)
	mi.rotation_degrees = Vector3(-90, 0, 0)
	var wrapper := Node3D.new()
	wrapper.add_child(mi)
	return wrapper


static func get_model_tinted(
	model_name: String, color: Color, s: float = 1.0,
) -> Node3D:
	var node := get_model(model_name, s)
	for child in node.get_children():
		if child is MeshInstance3D:
			_tint_mesh(child as MeshInstance3D, color)
	return node


static func _ensure_loaded() -> void:
	if _pack_scene != null:
		return
	_pack_scene = load(PACK_PATH) as PackedScene


static func _find_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh:
			return mi.mesh
	for child in node.get_children():
		var m := _find_mesh(child)
		if m:
			return m
	return null


static func _tint_mesh(mi: MeshInstance3D, color: Color) -> void:
	for i in mi.mesh.get_surface_count():
		var base_mat: Material = mi.mesh.surface_get_material(i)
		if base_mat is StandardMaterial3D:
			var mat := (
				base_mat as StandardMaterial3D
			).duplicate() as StandardMaterial3D
			mat.albedo_color = Color(
				mat.albedo_color.r * color.r,
				mat.albedo_color.g * color.g,
				mat.albedo_color.b * color.b,
			)
			mi.set_surface_override_material(i, mat)
