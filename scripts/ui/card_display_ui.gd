extends PanelContainer

signal drag_started(card: CardData)
signal drag_ended(card: CardData, target: Vector2i, success: bool)

var card_data: CardData
var hex_map: Node3D
var camera: Camera3D
var card_effects: Node
var active_unit: Node3D
var arrow_indicator: MeshInstance3D

var _card_icon_textures: Dictionary = {
	CardData.CardType.MOVE: preload("res://assets/icons/move_64.svg"),
	CardData.CardType.SCOUT: preload("res://assets/icons/scout_64.svg"),
	CardData.CardType.GATHER: preload("res://assets/icons/gather_64.svg"),
	CardData.CardType.SETTLE: preload("res://assets/icons/settle_64.svg"),
}
var _parchment_tex: Texture2D = preload(
	"res://assets/textures/ui/parchment_256_grayscale.png"
)
var _font_regular: Font = preload("res://assets/fonts/Cinzel-Regular.ttf")
var _font_bold: Font = preload("res://assets/fonts/Cinzel-Bold.ttf")
var _dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO
var _original_position: Vector2 = Vector2.ZERO
var _valid_targets: Array[Vector2i] = []


func setup(card: CardData) -> void:
	card_data = card
	var base: Color = card.card_color
	var dark: Color = base.darkened(0.35)
	var light: Color = base.lightened(0.2)

	# Outer container — dark background with border
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color(0.12, 0.08, 0.05)
	outer.border_color = Color(0.55, 0.4, 0.15)
	outer.border_width_left = 2
	outer.border_width_right = 2
	outer.border_width_top = 2
	outer.border_width_bottom = 2
	outer.corner_radius_top_left = 6
	outer.corner_radius_top_right = 6
	outer.corner_radius_bottom_left = 6
	outer.corner_radius_bottom_right = 6
	add_theme_stylebox_override("panel", outer)

	# Header — dark, textured
	_apply_section_style($VBox/Header, dark)
	$VBox/Header/CardName.text = card.card_name
	var title_size := UIHelpers.fit_font_size(
		card.card_name, UIHelpers.CONTENT_WIDTH,
		UIHelpers.HEADER_HEIGHT - 8, 13, 9,
	)
	$VBox/Header/CardName.add_theme_font_size_override(
		"font_size", title_size
	)
	$VBox/Header/CardName.add_theme_color_override(
		"font_color", Color.WHITE
	)
	$VBox/Header/CardName.add_theme_font_override("font", _font_bold)

	# Avatar — parchment texture with lighter shade
	_apply_section_style($VBox/Avatar, light)
	_setup_avatar(card)

	# Description — base color, textured
	_apply_section_style($VBox/DescSection, base)
	$VBox/DescSection/Description.text = card.description
	var desc_size := UIHelpers.fit_font_size(
		card.description, UIHelpers.CONTENT_WIDTH,
		UIHelpers.DESC_HEIGHT - 8, 11, 7,
	)
	$VBox/DescSection/Description.add_theme_font_size_override(
		"font_size", desc_size
	)
	$VBox/DescSection/Description.add_theme_color_override(
		"font_color", Color.WHITE
	)
	$VBox/DescSection/Description.add_theme_font_override(
		"font", _font_regular
	)

	# Footer — dark, textured
	_apply_section_style($VBox/Footer, dark)
	$VBox/Footer/FooterLabel.text = "Range %d" % card.range_value
	var footer_size := UIHelpers.fit_font_size(
		"Range %d" % card.range_value,
		UIHelpers.CONTENT_WIDTH,
		UIHelpers.FOOTER_HEIGHT - 8, 11, 8,
	)
	$VBox/Footer/FooterLabel.add_theme_font_size_override(
		"font_size", footer_size
	)
	$VBox/Footer/FooterLabel.add_theme_color_override(
		"font_color", Color(1, 1, 1, 0.8)
	)
	$VBox/Footer/FooterLabel.add_theme_font_override(
		"font", _font_regular
	)


func _apply_section_style(
	node: PanelContainer, color: Color,
) -> void:
	var style := StyleBoxTexture.new()
	style.texture = _parchment_tex
	style.modulate_color = color
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	node.add_theme_stylebox_override("panel", style)


func _setup_avatar(card: CardData) -> void:
	$VBox/Avatar/AvatarLabel.visible = false
	$VBox/Avatar/AvatarArt.visible = false
	var icon_tex: Texture2D = null
	if card.icon_path != "":
		icon_tex = load(card.icon_path) as Texture2D
	if icon_tex == null:
		icon_tex = _card_icon_textures.get(
			card.card_type, null
		) as Texture2D
	if icon_tex:
		var tex_rect: TextureRect = $VBox/Avatar/AvatarIcon
		tex_rect.texture = icon_tex
		tex_rect.visible = true
	else:
		$VBox/Avatar/AvatarLabel.visible = true
		$VBox/Avatar/AvatarLabel.text = "?"


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not _dragging:
			_start_drag(event.global_position)
			accept_event()
		elif not event.pressed and _dragging:
			_end_drag(event.global_position)
			accept_event()


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseMotion:
		global_position = event.global_position - _drag_offset
		_update_hover(event.global_position)
	elif event is InputEventMouseButton and not event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_end_drag(event.global_position)


func _start_drag(mouse_pos: Vector2) -> void:
	_dragging = true
	_original_position = global_position
	_drag_offset = mouse_pos - global_position

	z_index = 100
	modulate = Color(1.0, 1.0, 1.0, 0.5)
	scale = Vector2(1.05, 1.05)

	# Cache valid targets once at drag start
	_valid_targets.clear()
	if hex_map and card_effects and active_unit:
		_valid_targets = card_effects.get_valid_targets(
			card_data, active_unit.current_coord
		)
		hex_map.highlight_tiles(_valid_targets, Color(0.3, 0.8, 1.0, 0.8))

	drag_started.emit(card_data)


func _end_drag(mouse_pos: Vector2) -> void:
	_dragging = false
	z_index = 0
	modulate = Color.WHITE
	scale = Vector2.ONE

	hex_map.clear_highlights()
	if arrow_indicator:
		arrow_indicator.hide_arrow()

	var target := _raycast_hex(mouse_pos)
	var is_valid := target != Vector2i(-999, -999) and _is_valid_target(target)
	_valid_targets.clear()

	if is_valid:
		drag_ended.emit(card_data, target, true)
	else:
		global_position = _original_position
		drag_ended.emit(card_data, Vector2i.ZERO, false)


func _update_hover(mouse_pos: Vector2) -> void:
	if not hex_map or not camera:
		return

	# Restore base highlighting — subtle tint for valid targets
	hex_map.clear_highlights()
	hex_map.highlight_tiles(_valid_targets, Color(0.3, 0.8, 1.0, 0.8))

	var hovered := _raycast_hex(mouse_pos)
	if hovered != Vector2i(-999, -999) and _is_valid_target(hovered):
		# Brighter highlight on the hovered hex
		hex_map.highlight_tiles(
			[hovered] as Array[Vector2i],
			Color(1.0, 1.0, 0.3, 1.0),
		)
		# Show arrow from card slot to hovered hex
		if arrow_indicator and camera:
			var from_pos := _screen_to_ground(_original_position + size * 0.5)
			var to_pos := HexUtil.axial_to_world(hovered.x, hovered.y)
			arrow_indicator.show_arrow(from_pos, to_pos)
	else:
		if arrow_indicator:
			arrow_indicator.hide_arrow()


func _raycast_hex(screen_pos: Vector2) -> Vector2i:
	if not hex_map or not camera:
		return Vector2i(-999, -999)
	return hex_map.raycast_to_hex(camera, screen_pos)


func _is_valid_target(coord: Vector2i) -> bool:
	return coord in _valid_targets


func _screen_to_ground(screen_pos: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(screen_pos)
	var dir := camera.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.001:
		return Vector3.ZERO
	var t := -origin.y / dir.y
	return origin + dir * t
