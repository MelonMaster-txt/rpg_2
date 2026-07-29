# farm_placer.gd
# Gere le placement/interaction des FarmTiles
extends Node2D

const FARM_TILE_SCENE := preload("res://game/world/farm_tile.tscn")
const GRID := 32

var _container: Node = null
# Dictionnaire position -> tile pour lookup O(1) au lieu de boucle lineaire
var _tile_map: Dictionary = {}

func _ready() -> void:
	add_to_group("farm_placer")
	_container = get_parent().get_node_or_null("FarmContainer")
	if _container == null:
		_container = Node2D.new()
		_container.name = "FarmContainer"
		get_parent().add_child(_container)
	GameManager.restore_farm_tiles(_container, _tile_map)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		GameManager.save_farm_tiles(_tile_map)

func interact_at(world_pos: Vector2) -> bool:
	if _container == null:
		return false
	var grid_pos := _snap(world_pos)
	var key := _key(grid_pos)
	if _tile_map.has(key):
		var tile = _tile_map[key]
		if is_instance_valid(tile) and tile.has_method("_try_interact"):
			tile._try_interact()
		return true
	var tile: Node2D = FARM_TILE_SCENE.instantiate()
	tile.global_position = grid_pos
	_container.add_child(tile)
	_tile_map[key] = tile
	tile.call_deferred("_try_interact")
	return true

func _snap(pos: Vector2) -> Vector2:
	var half := GRID / 2.0
	return Vector2(
		floor(pos.x / GRID) * GRID + half,
		floor(pos.y / GRID) * GRID + half
	)

func _key(pos: Vector2) -> String:
	return "%d_%d" % [int(pos.x), int(pos.y)]
