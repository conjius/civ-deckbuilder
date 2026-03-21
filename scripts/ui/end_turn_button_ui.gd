extends Control

signal pressed

var _tex: Texture2D = preload(
	"res://assets/icons/hourglass_64.svg"
)
var _icon: TextureRect
var _bg: Panel
var _hovering: bool = false
var _animating: bool = false
var _disabled: bool = false


func _ready() -> void:
	var sz := UIHelpers.CARD_WIDTH
	custom_minimum_size = Vector2(sz, sz)
	size = Vector2(sz, sz)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_bg = Panel.new()
	_bg.position = Vector2.ZERO
	_bg.size = Vector2(sz, sz)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	@warning_ignore("integer_division")
	var half := sz / 2
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.12, 0.08, 0.05)
	bg_style.border_color = Color(0.55, 0.4, 0.15)
	bg_style.set_border_width_all(UIHelpers.CARD_BORDER)
	bg_style.set_corner_radius_all(half)
	_bg.add_theme_stylebox_override("panel", bg_style)
	add_child(_bg)

	_icon = TextureRect.new()
	_icon.texture = _tex
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.position = Vector2.ZERO
	_icon.size = Vector2(sz, sz)
	_icon.pivot_offset = Vector2(sz * 0.5, sz * 0.5)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)


func set_disabled(value: bool) -> void:
	_disabled = value
	modulate.a = 0.4 if _disabled else 1.0


func _gui_input(event: InputEvent) -> void:
	if _disabled or _animating:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_clicked()
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER and not _disabled:
		_hovering = true
		_update_hover()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovering = false
		_update_hover()


func _update_hover() -> void:
	if _animating:
		return
	if _hovering and not _disabled:
		_icon.modulate = Color(1.4, 1.4, 1.4)
	else:
		_icon.modulate = Color.WHITE


func _on_clicked() -> void:
	_animating = true
	_icon.modulate = Color(0.7, 0.7, 0.7)
	var tween := create_tween()
	tween.tween_property(
		_icon, "rotation", _icon.rotation + PI, 1.0
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		_animating = false
		_update_hover()
		pressed.emit()
	)
