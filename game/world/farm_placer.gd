# farm_placer.gd — autoload ou noeud dans overworld
# Clic droit n'importe ou = poser une FarmTile sous le curseur (grille 32px)
extends Node

const FARM_TILE_SCENE := preload("res://game/world/farm_tile.tscn")
const GRID := 32

var _container: Node2D = null

func init(container: Node2D) -> void:
	_container = container

func _unhandled_input(event: InputEvent) -> void:
	if _container == null:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			_place_tile(mb.global_position)

func _place_tile(screen_pos: Vector2) -> void:
	# Convertit coords ecran -> monde via la camera du joueur
	var vp := get_viewport()
	var world_pos: Vector2 = vp.get_canvas_transform().affine_inverse() * screen_pos
	# Snap sur grille 32px
	world_pos = Vector2(
		snappedi(int(world_pos.x), GRID),
		snappedi(int(world_pos.y), GRID)
	)
	# Evite les doublons
	for child in _container.get_children():
		if child.position == world_pos:
			return
	var tile := FARM_TILE_SCENE.instantiate() as Node2D
	tile.position = world_pos
	_container.add_child(tile)
