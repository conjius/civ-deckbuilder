extends Node3D

@export var pan_speed: float = 10.0
@export var zoom_speed: float = 1.6
@export var zoom_min: float = 3.0
@export var zoom_max: float = 30.0
@export var rotate_speed: float = 0.005
@export var smooth_factor: float = 12.0
@export var tilt_min: float = 15.0
@export var tilt_max: float = 90.0
@export var tilt_speed: float = 8.0
@export var orbit_speed: float = 2.6
@export var input_enabled: bool = true

var _target_zoom: float = 15.0
var _current_zoom: float = 15.0
var _target_position: Vector3 = Vector3.ZERO
var _target_tilt: float = 60.0
var _current_tilt: float = 60.0
var _dragging: bool = false
var _drag_origin: Vector3 = Vector3.ZERO

@onready var _pivot: Node3D = $CameraPivot


func _ready() -> void:
	_target_position = global_position
	_apply_zoom()
	_apply_tilt()


func _process(delta: float) -> void:
	var input_dir := Vector2.ZERO
	if not input_enabled:
		_apply_smooth(delta)
		return
	if Input.is_action_pressed("pan_up"):
		input_dir.y -= 1.0
	if Input.is_action_pressed("pan_down"):
		input_dir.y += 1.0
	if Input.is_action_pressed("pan_left"):
		input_dir.x -= 1.0
	if Input.is_action_pressed("pan_right"):
		input_dir.x += 1.0

	if input_dir != Vector2.ZERO:
		var forward := -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right := global_transform.basis.x
		right.y = 0.0
		right = right.normalized()
		_target_position += (
			(forward * -input_dir.y + right * input_dir.x)
			* pan_speed * delta
		)

	if _dragging:
		global_position = _target_position
		_current_zoom = _target_zoom
		_current_tilt = _target_tilt
	else:
		global_position = global_position.lerp(
			_target_position, smooth_factor * delta
		)
		_current_zoom = lerpf(
			_current_zoom, _target_zoom, smooth_factor * delta
		)
		_current_tilt = lerpf(
			_current_tilt, _target_tilt, smooth_factor * delta
		)
	_apply_zoom()
	_apply_tilt()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseButton:
		var shift: bool = event.shift_pressed
		var cmd: bool = event.meta_pressed
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if shift:
				rotate_y(deg_to_rad(orbit_speed))
			elif cmd:
				_target_tilt = clampf(
					_target_tilt - tilt_speed,
					tilt_min, tilt_max,
				)
			else:
				_target_zoom = maxf(
					zoom_min, _target_zoom - zoom_speed
				)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if shift:
				rotate_y(deg_to_rad(-orbit_speed))
			elif cmd:
				_target_tilt = clampf(
					_target_tilt + tilt_speed,
					tilt_min, tilt_max,
				)
			else:
				_target_zoom = minf(
					zoom_max, _target_zoom + zoom_speed
				)
		elif event.button_index == MOUSE_BUTTON_WHEEL_LEFT:
			rotate_y(deg_to_rad(orbit_speed))
		elif event.button_index == MOUSE_BUTTON_WHEEL_RIGHT:
			rotate_y(deg_to_rad(-orbit_speed))
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_origin = _screen_to_ground(
					event.position
				)
			else:
				_dragging = false

	if event is InputEventPanGesture:
		var pan_event: InputEventPanGesture = (
			event as InputEventPanGesture
		)
		if pan_event.meta_pressed:
			_target_tilt = clampf(
				_target_tilt + pan_event.delta.y * tilt_speed,
				tilt_min, tilt_max,
			)
		else:
			_target_zoom = clampf(
				_target_zoom + pan_event.delta.y * zoom_speed * 0.3,
				zoom_min, zoom_max,
			)
		# Horizontal pan gesture always rotates (shift+scroll on macOS)
		if absf(pan_event.delta.x) > 0.01:
			rotate_y(
				-pan_event.delta.x * deg_to_rad(orbit_speed)
			)

	if event is InputEventMouseMotion:
		if _dragging:
			var current := _screen_to_ground(event.position)
			var diff := _drag_origin - current
			global_position += diff
			_target_position = global_position
			_drag_origin = _screen_to_ground(event.position)
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			rotate_y(-event.relative.x * rotate_speed * 2.0)
			_target_tilt = clampf(
				_target_tilt + event.relative.y * 0.3,
				tilt_min, tilt_max,
			)


func _apply_zoom() -> void:
	$CameraPivot/Camera3D.position.z = _current_zoom


func _apply_tilt() -> void:
	var rad := deg_to_rad(_current_tilt)
	_pivot.rotation.x = -rad


func _screen_to_ground(screen_pos: Vector2) -> Vector3:
	var cam: Camera3D = $CameraPivot/Camera3D
	var origin := cam.project_ray_origin(screen_pos)
	var dir := cam.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return Vector3.ZERO
	var t := -origin.y / dir.y
	return origin + dir * t
