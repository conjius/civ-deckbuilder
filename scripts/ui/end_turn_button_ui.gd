extends Control

signal pressed

var _tex: Texture2D = preload(
	"res://assets/icons/hourglass_64.svg"
)
var _font: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _icon: TextureRect
var _bg: Panel
var _label: Label
var _hovering: bool = false
var _animating: bool = false
var _disabled: bool = false


func _ready() -> void:
	var sz: int = int(UIHelpers.CARD_WIDTH * 0.75)
	custom_minimum_size = Vector2(sz, sz)
	size = Vector2(sz, sz)
	mouse_filter = Control.MOUSE_FILTER_STOP

	_bg = Panel.new()
	_bg.position = Vector2.ZERO
	_bg.size = Vector2(sz, sz)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	@warning_ignore("integer_division")
	var half: int = sz / 2
	var bg_style := UIHelpers.create_circle_panel_style(half)
	_bg.add_theme_stylebox_override("panel", bg_style)
	add_child(_bg)
	UIHelpers.apply_parchment_bg(_bg, false, true)

	var icon_sz: float = sz * 0.45
	var icon_x: float = (sz - icon_sz) * 0.5
	var icon_y: float = sz * 0.15
	_icon = TextureRect.new()
	_icon.texture = _tex
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.position = Vector2(icon_x, icon_y)
	_icon.size = Vector2(icon_sz, icon_sz)
	_icon.pivot_offset = Vector2(icon_sz * 0.5, icon_sz * 0.5)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)

	_label = Label.new()
	_label.text = "End Turn"
	_label.add_theme_font_override("font", _font)
	_label.add_theme_font_size_override(
		"font_size", UIHelpers.s(9)
	)
	_label.add_theme_color_override("font_color", Color.BLACK)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.position = Vector2(0, sz * 0.65)
	_label.size = Vector2(sz, sz * 0.2)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	add_child(_label)


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
		_icon, "rotation", _icon.rotation + PI, 0.2
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func() -> void:
		_animating = false
		_update_hover()
		pressed.emit()
	)
