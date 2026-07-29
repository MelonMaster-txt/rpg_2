# farm_placer.gd
# Gere le placement/interaction des FarmTiles
# - Appel externe interact_at(world_pos) pour le joueur avec pioche
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

## Appele par le joueur quand il presse E avec la pioche
## Retourne true si une tile a ete bechee ou interagie
func interact_at(world_pos: Vector2) -> bool:
	if _container == null:
		return false
	var grid_pos := _snap(world_pos)
	# Cherche une tile existante a cette position
	for child in _container.get_children():
		if child is Node2D and (child as Node2D).global_position == grid_pos:
			if child.has_method("_try_interact"):
				child._try_interact()
			return true
	# Pas de tile : on en cree une nouvelle en etat SOL et on beche directement
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
