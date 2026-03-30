extends Node3D

const CLICK_DRAG_THRESHOLD := 5.0

var ai_controller: AIController
var ai_unit: Node3D

var _move_1: CardData = preload("res://resources/cards/move_1.tres")
var _move_2: CardData = preload("res://resources/cards/move_2.tres")
var _scout: CardData = preload("res://resources/cards/scout.tres")
var _gather: CardData = preload("res://resources/cards/gather.tres")
var _settle: CardData = preload("res://resources/cards/settle.tres")
var _chicken: CardData = preload("res://resources/cards/chicken.tres")
var _beef: CardData = preload("res://resources/cards/beef.tres")
var _pork: CardData = preload("res://resources/cards/pork.tres")
var _ore: CardData = preload("res://resources/cards/ore.tres")
var _iron: CardData = preload("res://resources/cards/iron.tres")
var _copper: CardData = preload("res://resources/cards/copper.tres")
var _wood: CardData = preload("res://resources/cards/wood.tres")
var _glass: CardData = preload("res://resources/cards/glass.tres")
var _strike: CardData = preload("res://resources/cards/strike.tres")
var _shoot: CardData = preload("res://resources/cards/shoot.tres")
var _shields_up: CardData = preload("res://resources/cards/shields_up.tres")
var _selected_coord: Vector2i = Vector2i(-999, -999)
var _selected_index: int = 0
var _last_hover_time: int = 0
var _last_hover_coord: Vector2i = Vector2i(-999, -999)
var _click_start_pos: Vector2 = Vector2.ZERO
var _click_pending: bool = false
var _click_start_time: int = 0

@onready var hex_map: Node3D = $HexMap
@onready var player_unit: Node3D = $PlayerUnit
@onready var camera_rig: Node3D = $CameraRig
@onready var card_manager: Node = $CardManager
@onready var card_effects: Node = $CardEffects
@onready var turn_manager: Node = $TurnManager
@onready var game_ui: CanvasLayer = $GameUI
@onready var arrow_indicator: Control = $ArrowLayer/ArrowIndicator


func _ready() -> void:
	UIHelpers.set_default_cursor()
	_setup_starfield()
	# Wire references
	card_effects.hex_map = hex_map
	card_effects.player_unit = player_unit
	turn_manager.card_manager = card_manager

	# Generate map first so MapData is populated before CardResolver needs it
	hex_map.generate_map()
	card_effects.card_resolver = CardResolver.new(hex_map.map_data)

	var cam: Camera3D = $CameraRig/CameraPivot/Camera3D
	arrow_indicator.setup_camera(cam)
	player_unit.setup_camera(cam)
	player_unit.set_selected(true)
	game_ui.setup_refs(hex_map, cam, card_effects, player_unit, arrow_indicator)
	game_ui.card_hand.deck_manager = card_manager.deck_manager
	game_ui._deck_manager_ref = card_manager.deck_manager

	# Connect signals
	game_ui.card_dropped.connect(_on_card_dropped)
	game_ui.end_turn_pressed.connect(_on_end_turn)
	game_ui.action_pressed.connect(_on_action_pressed)
	game_ui.gallery_closed.connect(_highlight_active_unit)
	card_manager.card_played.connect(game_ui.card_hand.remove_card)
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.phase_changed.connect(_on_phase_changed)
	player_unit.movement_finished.connect(_on_unit_moved)
	card_effects.gather_choice_needed.connect(
		_on_gather_choice_needed
	)
	card_effects.settled.connect(_on_settled)

	# Build the starter deck
	var deck: Array[CardData] = [
		_move_1, _move_1, _move_1, _move_1,
		_move_2, _move_2,
		_scout, _scout,
		_gather, _gather,
		_settle,
		_chicken, _beef, _pork,
		_ore, _iron, _copper, _wood, _glass,
		_strike, _shoot, _shields_up,
	]
	card_manager.starting_deck = deck
	card_manager.initialize_deck()

	# Find a passable starting tile near center
	var start_coord: Vector2i = _find_start_coord()
	var start_terrain: TerrainType = hex_map.get_terrain(start_coord)
	player_unit.place_at(start_coord, 0.0)

	# Center camera on player unit
	var start_world: Vector3 = HexUtil.axial_to_world(
		start_coord.x, start_coord.y
	)
	var cam_pos := Vector3(start_world.x, 0.0, start_world.z)
	camera_rig.global_position = cam_pos
	camera_rig._target_position = cam_pos

	# Reveal starting area (fog of war)
	_reveal_around(start_coord, 2)

	# Highlight active unit hex and track selection
	_selected_coord = start_coord
	_highlight_active_unit()

	# Set up AI player
	_setup_ai(start_coord, deck)

	# Start the game
	turn_manager.start_game()
	_refresh_cards_ui(false)


func _setup_starfield() -> void:
	var env_node: WorldEnvironment = $WorldEnvironment
	if env_node == null or env_node.environment == null:
		return
	var env := env_node.environment
	var sky := Sky.new()
	var mat := ShaderMaterial.new()
	mat.shader = load(
		"res://assets/shaders/starfield_sky.gdshader"
	)
	sky.sky_material = mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	env.background_mode = Environment.BG_SKY
	env.sky = sky


func _input(event: InputEvent) -> void:
	# Track click vs drag — _input always fires, even if GUI consumes
	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
		if mb.pressed:
			_click_start_pos = mb.position
			_click_pending = true
		elif _click_pending:
			_click_pending = false
			if game_ui.card_hand._any_dragging:
				return
			var dist := mb.position.distance_to(_click_start_pos)
			if dist <= CLICK_DRAG_THRESHOLD:
				var vp_h: float = (
					get_viewport().get_visible_rect().size.y
				)
				var hand_top: float = (
					vp_h - float(UIHelpers.CARD_HEIGHT)
				)
				if mb.position.y < hand_top:
					_handle_click(mb.position)
	var mm := event as InputEventMouseMotion
	if mm != null and _click_pending:
		var dist := mm.position.distance_to(_click_start_pos)
		if dist > CLICK_DRAG_THRESHOLD:
			_click_pending = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if game_ui.card_gallery.visible:
		return

	# Show terrain info on hover (throttled)
	if event is InputEventMouseMotion:
		var now: int = Time.get_ticks_msec()
		if now - _last_hover_time < 50:
			return
		_last_hover_time = now
		var coord: Vector2i = hex_map.raycast_to_hex(
			$CameraRig/CameraPivot/Camera3D, event.position
		)
		if coord == _last_hover_coord:
			return
		_last_hover_coord = coord
		if coord != Vector2i(-999, -999):
			hex_map.set_hover_highlight(coord)
			var vis: MapData.Visibility = (
				hex_map.map_data.get_visibility(coord)
			)
			if vis == MapData.Visibility.UNEXPLORED:
				var empty: Array[String] = []
				game_ui.update_tile_info("Unexplored", empty)
			elif vis == MapData.Visibility.FOGGED:
				var empty: Array[String] = []
				game_ui.update_tile_info("Fogged", empty)
			else:
				var terrain: TerrainType = (
					hex_map.get_terrain(coord)
				)
				if terrain:
					var yields: Array[String] = []
					if terrain.materials_yield > 0:
						yields.append(UIHelpers.icon_value(
							"Materials",
							str(terrain.materials_yield),
						))
					if terrain.food_yield > 0:
						yields.append(UIHelpers.icon_value(
							"Food",
							str(terrain.food_yield),
						))
					game_ui.update_tile_info(
						terrain.terrain_name, yields
					)
		else:
			hex_map.clear_hover_highlight()
			game_ui.update_tile_info("", [])



func _on_card_dropped(card: CardData, target: Vector2i) -> void:
	if turn_manager.can_play_cards():
		var result: CardResolver.CardResult = card_effects.execute_card(card, target)
		if result.success:
			if card.defense_cost > 0:
				player_unit.state.defense_modifier -= (
					card.defense_cost
				)
			card_manager.play_card(card)
			game_ui.update_piles(
				card_manager.deck_manager.draw_pile_count(),
				card_manager.deck_manager.discard_pile_count(),
			)
			_highlight_active_unit()
			game_ui.refresh_unit_info()


func _on_end_turn() -> void:
	hex_map.clear_highlights()
	game_ui.set_end_turn_enabled(false)
	# Animate discard, then continue turn
	card_manager.discard_hand()
	game_ui.card_hand.discard_all(func() -> void:
		game_ui.update_piles(
			card_manager.deck_manager.draw_pile_count(),
			card_manager.deck_manager.discard_pile_count(),
		)
		_finish_end_turn()
	)


func _finish_end_turn() -> void:
	# Opponent's turn
	await ai_controller.take_turn()
	turn_manager.end_turn()
	_degrade_fog()
	_reveal_around(
		player_unit.current_coord,
		player_unit.state.sight_range,
	)
	_highlight_active_unit()
	# Draw new hand
	card_manager.draw_new_hand()
	_refresh_cards_ui()


func _degrade_fog() -> void:
	var visible_coords: Array[Vector2i] = []
	var player_hexes := HexUtil.get_hexes_in_range(
		player_unit.current_coord,
		player_unit.state.sight_range,
	)
	for coord in player_hexes:
		visible_coords.append(coord)
	if ai_unit:
		var ai_hexes := HexUtil.get_hexes_in_range(
			ai_unit.current_coord,
			ai_unit.state.sight_range,
		)
		for coord in ai_hexes:
			visible_coords.append(coord)
	for coord: Vector2i in hex_map.map_data._visibility:
		var state: MapData.Visibility = (
			hex_map.map_data.get_visibility(coord)
		)
		if (state == MapData.Visibility.VISIBLE
			and coord not in visible_coords
		):
			hex_map.fog_tile(coord)


func _on_turn_started(turn_number: int) -> void:
	player_unit.state.defense_modifier = 0
	game_ui.update_turn(turn_number)
	game_ui.refresh_unit_info()


func _on_phase_changed(phase: int) -> void:
	game_ui.set_end_turn_enabled(phase == TurnStateMachine.Phase.PLAY)


func _on_unit_moved() -> void:
	_reveal_around(
		player_unit.current_coord,
		player_unit.state.sight_range,
	)
	_update_packing()
	_highlight_active_unit()


func _on_gather_choice_needed(
	_coord: Vector2i,
	types: Array[CardData.ResourceType],
) -> void:
	if types.is_empty():
		return
	if types.size() == 1:
		_complete_gather(types[0])
		return
	game_ui.card_hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picker := YieldPickerUI.new()
	game_ui.add_child(picker)
	game_ui._active_picker = picker
	picker.show_choices(types)
	var res_type: CardData.ResourceType = await picker.resource_chosen
	if game_ui.card_gallery.visible:
		game_ui.card_gallery.hide_gallery()
		await get_tree().create_timer(0.35).timeout
	picker.hide_choices()
	await get_tree().create_timer(0.35).timeout
	game_ui._active_picker = null
	picker.queue_free()
	game_ui.card_hand.mouse_filter = Control.MOUSE_FILTER_STOP
	_complete_gather(res_type)


func _complete_gather(res_type: CardData.ResourceType) -> void:
	var resolver: CardResolver = card_effects.card_resolver
	var card: CardData = resolver.pick_resource_card(res_type)
	card_manager.deck_manager.hand.append(card)
	game_ui.set_current_cards(card_manager.deck_manager.hand)
	game_ui.card_hand.add_cards_to_hand(
		[card] as Array[CardData]
	)


func _on_settled(coord: Vector2i, settlement_name: String) -> void:
	hex_map.map_data.place_settlement(
		coord, settlement_name, player_unit.avatar_color,
	)
	var tile: Node3D = hex_map.get_tile(coord)
	if tile:
		tile.place_settlement(
			settlement_name, player_unit.avatar_color,
			hex_map.map_data,
		)
	_reveal_around(coord, player_unit.state.sight_range)
	_update_packing()


func _handle_click(screen_pos: Vector2) -> void:
	var coord: Vector2i = hex_map.raycast_to_hex(
		$CameraRig/CameraPivot/Camera3D, screen_pos
	)
	if coord == Vector2i(-999, -999):
		_deselect()
		return

	var inhabitants := _get_inhabitants(coord)
	if inhabitants.is_empty():
		_deselect()
		return

	if coord == _selected_coord:
		if inhabitants.size() <= 1:
			return
		_selected_index = (_selected_index + 1) % inhabitants.size()
	else:
		_selected_coord = coord
		_selected_index = 0

	_select(inhabitants[_selected_index], coord)


func _deselect() -> void:
	if _selected_coord == Vector2i(-999, -999):
		return
	_selected_coord = Vector2i(-999, -999)
	_selected_index = 0
	hex_map.clear_blue_highlight(true)
	player_unit.set_selected(false)
	game_ui.slide_unit_panel_out()


func _select(info: Dictionary, coord: Vector2i) -> void:
	var was_selected: bool = (
		_selected_coord != Vector2i(-999, -999)
	)
	hex_map.clear_hover_highlight()
	hex_map.set_blue_highlight(coord)
	game_ui.slide_unit_panel_in(
		was_selected,
		func() -> void: _show_inhabitant(info, coord),
	)


func _get_inhabitants(coord: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if player_unit.current_coord == coord:
		result.append({"type": "unit", "unit": player_unit})
	if ai_unit and ai_unit.current_coord == coord:
		result.append({"type": "unit", "unit": ai_unit})
	if hex_map.map_data.has_settlement(coord):
		result.append({
			"type": "settlement",
			"name": hex_map.map_data.get_settlement_name(coord),
		})
	return result


func _show_inhabitant(info: Dictionary, coord: Vector2i) -> void:
	var itype: String = info["type"] as String
	if itype == "unit":
		var unit: Node3D = info["unit"] as Node3D
		if unit == player_unit:
			player_unit.set_selected(true)
		game_ui.show_unit_info(unit)
	elif itype == "settlement":
		player_unit.set_selected(false)
		var sname: String = info["name"] as String
		var owner_color: Color = (
			hex_map.map_data.get_settlement_color(coord)
		)
		var terrain: TerrainType = hex_map.get_terrain(coord)
		game_ui.show_settlement_info(
			sname, owner_color, coord, terrain
		)


func _update_packing() -> void:
	var coord: Vector2i = player_unit.current_coord
	var has_building: bool = hex_map.map_data.has_settlement(coord)
	var terrain: TerrainType = hex_map.get_terrain(coord)
	var has_yields: bool = (
		terrain != null
		and (terrain.materials_yield > 0 or terrain.food_yield > 0)
	)
	player_unit.offset_for_packing(has_building, has_yields)


func _refresh_cards_ui(animate: bool = true) -> void:
	var dm: DeckManager = card_manager.deck_manager
	if animate:
		game_ui.animate_deal(
			dm.hand, dm.draw_pile_count(),
			dm.discard_pile_count(),
		)
	else:
		game_ui.set_current_cards(dm.hand)
		game_ui.card_hand.show_cards(dm.hand, false)
		game_ui.update_piles(
			dm.draw_pile_count(), dm.discard_pile_count(),
		)


func _on_action_pressed(action_name: String) -> void:
	if action_name == "build":
		pass # TODO: open build menu for selected settlement


func _highlight_active_unit() -> void:
	hex_map.clear_highlights()
	if _selected_coord == Vector2i(-999, -999):
		return
	hex_map.set_blue_highlight(player_unit.current_coord)


func _find_start_coord() -> Vector2i:
	@warning_ignore("integer_division")
	var center := Vector2i(
		hex_map.map_width / 2,
		hex_map.map_height / 2 - hex_map.map_width / 4,
	)
	for radius in range(0, 10):
		var hexes := HexUtil.get_hexes_in_range(center, radius)
		hexes.shuffle()
		for coord in hexes:
			var terrain: TerrainType = hex_map.get_terrain(coord)
			if terrain and terrain.is_passable:
				return coord
	return center


func _setup_ai(
	player_start: Vector2i, deck: Array[CardData],
) -> void:
	# Create AI unit
	ai_unit = Node3D.new()
	ai_unit.set_script(
		load("res://scripts/unit/player_unit.gd")
	)
	ai_unit.avatar_color = Color(0.6, 0.2, 0.8, 1)
	add_child(ai_unit)
	var ai_start := _find_ai_start_coord(player_start, 7)
	var ai_terrain: TerrainType = hex_map.get_terrain(
		ai_start
	)
	ai_unit.place_at(ai_start, 0.0)
	hex_map.map_data.set_enemy_position(ai_start, true)
	ai_unit.movement_finished.connect(_on_ai_unit_moved)
	# Create AI controller
	ai_controller = AIController.new()
	ai_controller.ai_unit = ai_unit
	ai_controller.card_effects = card_effects
	ai_controller.card_resolver = card_effects.card_resolver
	ai_controller.hex_map = hex_map
	add_child(ai_controller)
	ai_controller.initialize(deck.duplicate())
	# Debug: reveal fog around AI start
	_reveal_around(ai_start, 2)


func _find_ai_start_coord(
	player_start: Vector2i, target_dist: int,
) -> Vector2i:
	for offset in range(0, 4):
		for dist in [target_dist + offset, target_dist - offset]:
			if dist < 1:
				continue
			var hexes := HexUtil.get_hexes_in_range(
				player_start, dist
			)
			var candidates: Array[Vector2i] = []
			for coord in hexes:
				if HexUtil.axial_distance(
					player_start, coord
				) != dist:
					continue
				var terrain: TerrainType = (
					hex_map.get_terrain(coord)
				)
				if terrain and terrain.is_passable:
					candidates.append(coord)
			if not candidates.is_empty():
				return candidates[
					randi() % candidates.size()
				]
	return player_start + Vector2i(7, 0)


func _on_ai_unit_moved() -> void:
	_update_enemy_positions()
	_reveal_around(
		ai_unit.current_coord,
		ai_unit.state.sight_range,
	)
	var coord: Vector2i = ai_unit.current_coord
	var has_building: bool = (
		hex_map.map_data.has_settlement(coord)
	)
	var ai_terrain: TerrainType = hex_map.get_terrain(coord)
	var has_yields: bool = (
		ai_terrain != null
		and (ai_terrain.materials_yield > 0
		or ai_terrain.food_yield > 0)
	)
	ai_unit.offset_for_packing(has_building, has_yields)


func _update_enemy_positions() -> void:
	hex_map.map_data._enemies.clear()
	if ai_unit:
		hex_map.map_data.set_enemy_position(
			ai_unit.current_coord, true
		)


func _reveal_around(coord: Vector2i, radius: int) -> void:
	var hexes := HexUtil.get_hexes_in_range(coord, radius)
	for c in hexes:
		hex_map.reveal_tile(c)
