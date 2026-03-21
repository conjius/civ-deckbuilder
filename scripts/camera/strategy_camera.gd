extends Node3D

@export var pan_speed: float = 10.0
@export var zoom_speed: float = 1.2
@export var zoom_min: float = 3.0
@export var zoom_max: float = 30.0
@export var rotate_speed: float = 0.005
@export var drag_speed: float = 0.02
@export var smooth_factor: float = 8.0

var _target_zoom: float = 15.0
var _current_zoom: float = 15.0
var _target_position: Vector3 = Vector3.ZERO
var _dragging: bool = false


func _ready() -> void:
	_target_position = global_position
	_apply_zoom()


func _process(delta: float) -> void:
	var input_dir := Vector2.ZERO
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

	global_position = global_position.lerp(
		_target_position, smooth_factor * delta
	)

	_current_zoom = lerpf(
		_current_zoom, _target_zoom, smooth_factor * delta
	)
	_apply_zoom()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_zoom = maxf(
				zoom_min, _target_zoom - zoom_speed
			)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_zoom = minf(
				zoom_max, _target_zoom + zoom_speed
			)

	if event is InputEventPanGesture:
		_target_zoom = clampf(
			_target_zoom + event.delta.y * zoom_speed * 0.3,
			zoom_min, zoom_max,
		)
		rotate_y(event.delta.x * rotate_speed * 10.0)

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed

	if event is InputEventMouseMotion:
		if _dragging:
			var forward := -global_transform.basis.z
			forward.y = 0.0
			forward = forward.normalized()
			var right := global_transform.basis.x
			right.y = 0.0
			right = right.normalized()
			var move: Vector3 = (
				right * -event.relative.x
				+ forward * event.relative.y
			)
			var offset := move * drag_speed * _current_zoom * 0.05
			global_position += offset
			_target_position = global_position
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			rotate_y(-event.relative.x * rotate_speed)


func _apply_zoom() -> void:
	$CameraPivot/Camera3D.position.z = _current_zoom
