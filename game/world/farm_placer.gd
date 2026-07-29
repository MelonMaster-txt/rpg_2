# farm_placer.gd
# Gere le placement/interaction des FarmTiles
extends Node2D

const FARM_TILE_SCENE := preload("res://game/world/farm_tile.tscn")
const GRID := 32

var _container: Node = null

func _ready() -> void:
	_container = get_parent().get_node_or_null("FarmContainer")
	if _container == null:
		_container = Node2D.new()
		_container.name = "FarmContainer"
		get_parent().add_child(_container)
	# Restaure les tuiles sauvegardees
	GameManager.restore_farm_tiles(_container)

func _notification(what: int) -> void:
	# Sauvegarde avant que la scene soit detruite
	if what == NOTIFICATION_PREDELETE:
		GameManager.save_farm_tiles(_container)

## Appele par le joueur quand il presse E avec la pioche
func interact_at(world_pos: Vector2) -> bool:
	if _container == null:
		return false
	var grid_pos := _snap(world_pos)
	for child in _container.get_children():
		if child is Node2D and (child as Node2D).global_position == grid_pos:
			if child.has_method("_try_interact"):
				child._try_interact()
			return true
	var tile: Node2D = FARM_TILE_SCENE.instantiate()
	tile.global_position = grid_pos
	_container.add_child(tile)
	tile.call_deferred("_try_interact")
	return true

# Snap au CENTRE de la cellule de grille
func _snap(pos: Vector2) -> Vector2:
	var half := GRID / 2.0
	return Vector2(
		floor(pos.x / GRID) * GRID + half,
		floor(pos.y / GRID) * GRID + half
	)
