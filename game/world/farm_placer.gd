# farm_placer.gd
extends Node2D

const FARM_TILE_SCENE: PackedScene = preload("res://game/world/farm_tile.tscn")
const GRID:      int   = 32
const GRID_F:    float = 32.0  # version float pour les divisions sans warning

var _container: Node = null
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
		var existing: Node = _tile_map[key]
		if is_instance_valid(existing) and existing.has_method("_try_interact"):
			existing._try_interact()
		return true
	# Nouvelle tuile
	var new_tile: Node2D = FARM_TILE_SCENE.instantiate()
	new_tile.global_position = grid_pos
	_container.add_child(new_tile)
	_tile_map[key] = new_tile
	new_tile.call_deferred("_try_interact")
	return true

func _snap(pos: Vector2) -> Vector2:
	var half: float = GRID_F * 0.5
	return Vector2(
		floor(pos.x / GRID_F) * GRID_F + half,
		floor(pos.y / GRID_F) * GRID_F + half
	)

func _key(pos: Vector2) -> String:
	return "%d_%d" % [int(pos.x), int(pos.y)]
