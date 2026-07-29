# forest_chunk_base.gd
# OPTIMISATION : les scenes de ressources (arbres, baies, pierres)
# sont instanciées une par une via call_deferred pour étaler
# le coût sur plusieurs frames et éviter les freeze.
extends Node2D

@export var tree_count_min:  int = 5
@export var tree_count_max:  int = 12
@export var berry_count_min: int = 1
@export var berry_count_max: int = 4
@export var stone_count_min: int = 1
@export var stone_count_max: int = 3

const TREE_SCENE   := "res://game/world/scenes/resources_node/tree_node.tscn"
const BERRY_SCENE  := "res://game/world/scenes/resources_node/berry_node.tscn"
const STONE_SCENE  := "res://game/world/scenes/resources_node/stone_node.tscn"
const GROUND_SCRIPT := "res://game/world/ground_painter.gd"

var _chunk_coords: Vector2i = Vector2i.ZERO
var _chunk_size:   int      = 512

# File de spawn : chaque entrée = [PackedScene, Vector2]
var _spawn_queue: Array = []


func setup(coords: Vector2i, size: int) -> void:
	_chunk_coords = coords
	_chunk_size   = size
	_paint_ground()
	_build_spawn_queue()
	# Lance le premier spawn différé
	call_deferred("_spawn_next")


func _paint_ground() -> void:
	var script: GDScript = load(GROUND_SCRIPT) as GDScript
	if script == null:
		return
	var painter: Node2D = Node2D.new()
	painter.set_script(script)
	painter.name = "Ground"
	add_child(painter)
	painter.z_index = -10
	painter.paint(_chunk_coords, _chunk_size)


func _build_spawn_queue() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(_chunk_coords.x * 73856093, _chunk_coords.y * 19349663))

	var tree_count  := rng.randi_range(tree_count_min,  tree_count_max)
	var berry_count := rng.randi_range(berry_count_min, berry_count_max)
	var stone_count := rng.randi_range(stone_count_min, stone_count_max)

	var tree_scene  := load(TREE_SCENE)  as PackedScene
	var berry_scene := load(BERRY_SCENE) as PackedScene
	var stone_scene := load(STONE_SCENE) as PackedScene

	_spawn_queue.clear()
	for _i in tree_count:
		_spawn_queue.append([
			tree_scene,
			Vector2(rng.randf_range(48.0, _chunk_size - 48.0),
					rng.randf_range(48.0, _chunk_size - 48.0))
		])
	for _i in berry_count:
		_spawn_queue.append([
			berry_scene,
			Vector2(rng.randf_range(48.0, _chunk_size - 48.0),
					rng.randf_range(48.0, _chunk_size - 48.0))
		])
	for _i in stone_count:
		_spawn_queue.append([
			stone_scene,
			Vector2(rng.randf_range(48.0, _chunk_size - 48.0),
					rng.randf_range(48.0, _chunk_size - 48.0))
		])


## Instancie UN seul objet par frame depuis la queue
func _spawn_next() -> void:
	if _spawn_queue.is_empty():
		return
	var data: Array = _spawn_queue.pop_front()
	var scene: PackedScene = data[0]
	var pos: Vector2 = data[1]
	if scene == null:
		call_deferred("_spawn_next")
		return
	var inst := scene.instantiate() as Node2D
	inst.position = pos
	add_child(inst)
	# Planifie le suivant à la prochaine frame
	if not _spawn_queue.is_empty():
		call_deferred("_spawn_next")
