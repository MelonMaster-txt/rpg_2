# farm_placer.gd
# Clic droit n'importe ou -> place une FarmTile snappee sur grille 32px
extends Node2D

const FARM_TILE_SCR := preload("res://game/world/farm_tile.gd")
const GRID := 32

func _ready() -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			_place_tile(mb.global_position)
			get_viewport().set_input_as_handled()

func _place_tile(screen_pos: Vector2) -> void:
	var container := get_parent().get_node_or_null("FarmContainer")
	if container == null:
		return
	var cam := get_viewport().get_camera_2d()
	var world_pos : Vector2
	if cam:
		world_pos = screen_pos + cam.get_screen_center_position() - get_viewport_rect().size / 2.0
	else:
		world_pos = screen_pos
	# snap est un builtin, on utilise un nom different
	var grid_pos := Vector2(
		floor(world_pos.x / GRID) * GRID,
		floor(world_pos.y / GRID) * GRID
	)
	# Anti doublon
	for child in container.get_children():
		if child is Node2D and (child as Node2D).global_position == grid_pos:
			return
	var tile : Node2D = Node2D.new()
	tile.set_script(FARM_TILE_SCR)
	tile.global_position = grid_pos
	container.add_child(tile)
