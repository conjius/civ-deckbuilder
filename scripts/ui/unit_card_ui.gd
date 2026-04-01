class_name UnitCardUI
extends DarkCardUI

var _unit_icon: TextureRect
var _lines_container: VBoxContainer
var _original_y: float = 0.0
var _showing: bool = false
var _current_unit: Node3D
var _icon_mat: ShaderMaterial

var _boot_tex: Texture2D = preload(
	"res://assets/icons/boot_move_white_on_transparent.png"
)
var _tent_tex: Texture2D = preload(
	"res://assets/icons/tent_icon.svg"
)
var _boot_scale := 1.1
var _tent_scale := 1.3


func _ready() -> void:
	setup_card()

	var icon_sz: float = UIHelpers.sf(20.0)
	_unit_icon = TextureRect.new()
	_unit_icon.texture = _boot_tex
	_unit_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_unit_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_unit_icon.size = Vector2(icon_sz, icon_sz)
	_unit_icon.position = Vector2(
		(float(card_w) - icon_sz) * 0.5, 14.0
	)
	_icon_mat = UIHelpers.create_icon_tint_shader(
		Color(0.95, 0.88, 0.7)
	)
	_unit_icon.material = _icon_mat
	_unit_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_clip.add_child(_unit_icon)

	var top_offset: float = icon_sz + 22.0
	_lines_container = VBoxContainer.new()
	_lines_container.position = Vector2(4, top_offset)
	_lines_container.size = Vector2(
		float(card_w) - 8, float(card_h) - top_offset - 8
	)
	_lines_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_content_clip.add_child(_lines_container)
	visible = false


func show_unit(unit: Node3D) -> void:
	if unit == _current_unit and _showing:
		_populate(unit)
		return
	if _showing:
		_slide_out_then_in(unit)
	else:
		_current_unit = unit
		_populate(unit)
		_slide_in()


func hide_unit() -> void:
	if not _showing:
		return
	_current_unit = null
	_slide_out()


func slide_out_for_gallery() -> void:
	if not _showing:
		return
	var tw := create_tween()
	tw.tween_property(
		self, "position:y", -size.y - 20.0, 0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)


func slide_in_from_gallery() -> void:
	if not _showing:
		return
	var tw := create_tween()
	tw.tween_property(
		self, "position:y", _original_y, 0.35,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func store_original_pos() -> void:
	_original_y = position.y


func show_settlement(
	sname: String, color: Color,
	hp: int, atk: int, def: int,
) -> void:
	if _showing:
		var tw := create_tween()
		tw.tween_property(
			self, "position:y", -size.y - 20.0, 0.2,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			_current_unit = null
			_populate_settlement(sname, color, hp, atk, def)
		)
		tw.tween_property(
			self, "position:y", _original_y, 0.25,
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_populate_settlement(sname, color, hp, atk, def)
		_slide_in()


func _populate(unit: Node3D) -> void:
	for child in _lines_container.get_children():
		child.queue_free()
	if unit == null:
		return
	_unit_icon.texture = _boot_tex
	_set_icon_scale(_boot_scale)
	if "avatar_color" in unit:
		var c: Color = unit.avatar_color
		_icon_mat.set_shader_parameter(
			"tint_color", Color(c.r, c.g, c.b, 0.9)
		)
	var hp: int = unit.health if "health" in unit else 0
	var atk: int = unit.attack if "attack" in unit else 0
	var def: int = unit.defense if "defense" in unit else 0
	if "state" in unit and unit.state:
		def += unit.state.defense_modifier
	_add_line(UIHelpers.icon_value("HP", str(hp)))
	_add_line(UIHelpers.icon_value("Attack", str(atk)))
	_add_line(UIHelpers.icon_value("Defense", str(def)))


func _populate_settlement(
	_sname: String, color: Color,
	hp: int, atk: int, def: int,
) -> void:
	for child in _lines_container.get_children():
		child.queue_free()
	_unit_icon.texture = _tent_tex
	_set_icon_scale(_tent_scale)
	_icon_mat.set_shader_parameter(
		"tint_color", Color(color.r, color.g, color.b, 0.9)
	)
	_add_line(UIHelpers.icon_value("HP", str(hp)))
	_add_line(UIHelpers.icon_value("Attack", str(atk)))
	_add_line(UIHelpers.icon_value("Defense", str(def)))


func _set_icon_scale(s: float) -> void:
	var base_sz: float = UIHelpers.sf(20.0)
	var sz: float = base_sz * s
	_unit_icon.size = Vector2(sz, sz)
	_unit_icon.position = Vector2(
		(float(card_w) - sz) * 0.5, 14.0 - (sz - base_sz) * 0.5
	)


func _add_line(bbcode: String) -> void:
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.fit_content = true
	lbl.add_theme_font_override("normal_font", _font_bold)
	lbl.add_theme_font_size_override(
		"normal_font_size", UIHelpers.s(8)
	)
	lbl.add_theme_color_override(
		"default_color", Color(0.95, 0.88, 0.7)
	)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIHelpers.set_bbcode(
		lbl, "[center]" + bbcode + "[/center]"
	)
	_lines_container.add_child(lbl)


func _slide_in() -> void:
	visible = true
	_showing = true
	position.y = -size.y - 20.0
	var tw := create_tween()
	tw.tween_property(
		self, "position:y", _original_y, 0.3,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _slide_out() -> void:
	_showing = false
	var tw := create_tween()
	tw.tween_property(
		self, "position:y", -size.y - 20.0, 0.25,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		visible = false
	)


func _slide_out_then_in(new_unit: Node3D) -> void:
	var tw := create_tween()
	tw.tween_property(
		self, "position:y", -size.y - 20.0, 0.2,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		_current_unit = new_unit
		_populate(new_unit)
	)
	tw.tween_property(
		self, "position:y", _original_y, 0.25,
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
