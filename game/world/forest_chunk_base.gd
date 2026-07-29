extends Node2D

@export var tree_count_min: int = 5
@export var tree_count_max: int = 12
@export var berry_count_min: int = 1
@export var berry_count_max: int = 4
@export var stone_count_min: int = 1
@export var stone_count_max: int = 3

const TREE_SCENE  := "res://game/world/scenes/resources_node/tree_node.tscn"
const BERRY_SCENE := "res://game/world/scenes/resources_node/berry_node.tscn"
const STONE_SCENE := "res://game/world/scenes/resources_node/stone_node.tscn"

var _chunk_coords: Vector2i = Vector2i.ZERO
var _chunk_size: int = 512


func setup(coords: Vector2i, size: int) -> void:
	_chunk_coords = coords
	_chunk_size   = size
	_generate()


func _generate() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(_chunk_coords.x * 73856093, _chunk_coords.y * 19349663))

	var tree_count  := rng.randi_range(tree_count_min, tree_count_max)
	var berry_count := rng.randi_range(berry_count_min, berry_count_max)
	var stone_count := rng.randi_range(stone_count_min, stone_count_max)

	var tree_scene  := load(TREE_SCENE)  as PackedScene
	var berry_scene := load(BERRY_SCENE) as PackedScene
	var stone_scene := load(STONE_SCENE) as PackedScene

	for _i in tree_count:
		_place(rng, tree_scene)
	for _i in berry_count:
		_place(rng, berry_scene)
	for _i in stone_count:
		_place(rng, stone_scene)


func _place(rng: RandomNumberGenerator, scene: PackedScene) -> void:
	if scene == null:
		return
	var inst := scene.instantiate() as Node2D
	inst.position = Vector2(
		rng.randf_range(32.0, _chunk_size - 32.0),
		rng.randf_range(32.0, _chunk_size - 32.0)
	)
	add_child(inst)
