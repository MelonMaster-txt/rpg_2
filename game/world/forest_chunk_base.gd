extends Node2D

@export var tree_count_min: int = 5
@export var tree_count_max: int = 12
@export var berry_count_min: int = 1
@export var berry_count_max: int = 4

var _chunk_coords: Vector2i = Vector2i.ZERO
var _chunk_size: int = 512


func setup(coords: Vector2i, size: int) -> void:
	_chunk_coords = coords
	_chunk_size   = size
	_generate()


func _generate() -> void:
	# Seed déterministe : même coordonnées = même forêt à chaque session
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(_chunk_coords.x * 73856093, _chunk_coords.y * 19349663))

	var tree_count  := rng.randi_range(tree_count_min, tree_count_max)
	var berry_count := rng.randi_range(berry_count_min, berry_count_max)

	for i in tree_count:
		_place_resource_node(rng, "BOIS")
	for i in berry_count:
		_place_resource_node(rng, "BAIES")


func _place_resource_node(rng: RandomNumberGenerator, rtype: String) -> void:
	var node_scene := load("res://game/world/scenes/resources_node/resource_node.tscn") as PackedScene
	if node_scene == null:
		return
	var inst: Node2D = node_scene.instantiate() as Node2D
	inst.resource_type = ForestResourceNode.Type[rtype]
	inst.position = Vector2(
		rng.randf_range(32.0, _chunk_size - 32.0),
		rng.randf_range(32.0, _chunk_size - 32.0)
	)
	add_child(inst)
