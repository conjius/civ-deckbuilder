extends MeshInstance3D

@export var arrow_width: float = 0.35
@export var dash_length: float = 0.6
@export var gap_length: float = 0.3
@export var arrowhead_length: float = 1.6
@export var arrowhead_width: float = 1.4
@export var arrow_color: Color = Color(0.7, 0.15, 0.1, 0.85)
@export var y_offset: float = 0.15

var _immediate_mesh: ImmediateMesh
var _material: StandardMaterial3D


func _ready() -> void:
	_immediate_mesh = ImmediateMesh.new()
	mesh = _immediate_mesh

	_material = StandardMaterial3D.new()
	_material.albedo_color = arrow_color
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
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

	# Shorten the shaft to leave room for the arrowhead
	var shaft_length := maxf(0.0, total_length - arrowhead_length)

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	# Draw dashed shaft segments
	var pos := 0.0
	while pos < shaft_length:
		var seg_end := minf(pos + dash_length, shaft_length)
		var p0 := start + dir * pos
		var p1 := start + dir * seg_end

		# Quad as two triangles
		var v0 := p0 + perp * half_w
		var v1 := p0 - perp * half_w
		var v2 := p1 + perp * half_w
		var v3 := p1 - perp * half_w

		_immediate_mesh.surface_set_color(arrow_color)
		_immediate_mesh.surface_add_vertex(v0)
		_immediate_mesh.surface_add_vertex(v1)
		_immediate_mesh.surface_add_vertex(v2)

		_immediate_mesh.surface_add_vertex(v1)
		_immediate_mesh.surface_add_vertex(v3)
		_immediate_mesh.surface_add_vertex(v2)

		pos = seg_end + gap_length

	# Arrowhead triangle
	var head_base := start + dir * shaft_length
	var head_tip := end
	var head_half_w := arrowhead_width * 0.5

	var h0 := head_base + perp * head_half_w
	var h1 := head_base - perp * head_half_w
	var h2 := head_tip

	_immediate_mesh.surface_set_color(arrow_color)
	_immediate_mesh.surface_add_vertex(h0)
	_immediate_mesh.surface_add_vertex(h1)
	_immediate_mesh.surface_add_vertex(h2)

	_immediate_mesh.surface_end()
