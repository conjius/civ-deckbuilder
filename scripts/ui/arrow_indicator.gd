extends MeshInstance3D

@export var arrow_width: float = 1.05
@export var dash_length: float = 1.8
@export var gap_length: float = 0.9
@export var arrowhead_length: float = 4.8
@export var arrowhead_width: float = 4.2
@export var arrow_color: Color = Color(0.7, 0.15, 0.1, 0.85)
@export var y_offset: float = 0.7

var _immediate_mesh: ImmediateMesh
var _material: StandardMaterial3D


func _ready() -> void:
	_immediate_mesh = ImmediateMesh.new()
	mesh = _immediate_mesh

	_material = StandardMaterial3D.new()
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_material.vertex_color_use_as_albedo = true
	material_override = _material

	visible = false


func show_arrow(from_pos: Vector3, to_pos: Vector3) -> void:
	visible = true
	_draw_arrow(from_pos, to_pos)


func hide_arrow() -> void:
	visible = false
	_immediate_mesh.clear_surfaces()


func _draw_arrow(from_pos: Vector3, to_pos: Vector3) -> void:
	_immediate_mesh.clear_surfaces()

	var start := Vector3(from_pos.x, y_offset, from_pos.z)
	var end := Vector3(to_pos.x, y_offset, to_pos.z)
	var dir := (end - start)
	var total_length := dir.length()

	if total_length < 0.1:
		return

	dir = dir.normalized()
	var perp := Vector3(-dir.z, 0.0, dir.x)
	var half_w := arrow_width * 0.5

	var shaft_length := maxf(0.0, total_length - arrowhead_length)

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	var pos := 0.0
	while pos < shaft_length:
		var seg_end := minf(pos + dash_length, shaft_length)
		var p0 := start + dir * pos
		var p1 := start + dir * seg_end

		var v0 := p0 + perp * half_w
		var v1 := p0 - perp * half_w
		var v2 := p1 + perp * half_w
		var v3 := p1 - perp * half_w

		var t0 := pos / total_length
		var t1 := seg_end / total_length
		var c0 := _color_at(t0)
		var c1 := _color_at(t1)

		_immediate_mesh.surface_set_color(c0)
		_immediate_mesh.surface_add_vertex(v0)
		_immediate_mesh.surface_set_color(c0)
		_immediate_mesh.surface_add_vertex(v1)
		_immediate_mesh.surface_set_color(c1)
		_immediate_mesh.surface_add_vertex(v2)

		_immediate_mesh.surface_set_color(c0)
		_immediate_mesh.surface_add_vertex(v1)
		_immediate_mesh.surface_set_color(c1)
		_immediate_mesh.surface_add_vertex(v3)
		_immediate_mesh.surface_set_color(c1)
		_immediate_mesh.surface_add_vertex(v2)

		pos = seg_end + gap_length

	var head_base := start + dir * shaft_length
	var head_tip := end
	var head_half_w := arrowhead_width * 0.5

	var h0 := head_base + perp * head_half_w
	var h1 := head_base - perp * head_half_w
	var h2 := head_tip

	var t_base := shaft_length / total_length
	var c_base := _color_at(t_base)
	var c_tip := _color_at(1.0)

	_immediate_mesh.surface_set_color(c_base)
	_immediate_mesh.surface_add_vertex(h0)
	_immediate_mesh.surface_set_color(c_base)
	_immediate_mesh.surface_add_vertex(h1)
	_immediate_mesh.surface_set_color(c_tip)
	_immediate_mesh.surface_add_vertex(h2)

	_immediate_mesh.surface_end()


func _color_at(t: float) -> Color:
	var alpha := lerpf(0.05, arrow_color.a, t)
	return Color(arrow_color.r, arrow_color.g, arrow_color.b, alpha)
