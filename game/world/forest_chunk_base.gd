extends Node2D

const TREE_SCENE: PackedScene = preload("res://game/world/scenes/resources_node/tree_node.tscn")
const BERRY_SCENE: PackedScene = preload("res://game/world/scenes/resources_node/berry_node.tscn")

var chunk_coords: Vector2i = Vector2i.ZERO
var chunk_size: int = 512

func setup(coords: Vector2i, world_chunk_size: int) -> void:
	chunk_coords = coords
	chunk_size = world_chunk_size

	print("ForestChunkBase setup for coords =", chunk_coords, "chunk_size =", chunk_size)
	generate_content()

func generate_content() -> void:
	var trees_container: Node2D = get_node_or_null("Trees")
	var berries_container: Node2D = get_node_or_null("Berries")

	if trees_container == null:
		push_error("ForestChunkBase: node 'Trees' introuvable dans forest_chunk_base.tscn")
		return

	if berries_container == null:
		push_error("ForestChunkBase: node 'Berries' introuvable dans forest_chunk_base.tscn")
		return

	clear_existing_content(trees_container, berries_container)

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = get_chunk_seed(chunk_coords)

	print("ForestChunkBase RNG seed =", rng.seed)

	var tree_count: int = rng.randi_range(6, 14)
	var berry_count: int = rng.randi_range(2, 6)

	print("ForestChunkBase generating", tree_count, "trees and", berry_count, "berries")

	for i in range(tree_count):
		var tree: Node2D = TREE_SCENE.instantiate()
		tree.position = Vector2(
			rng.randf_range(32.0, chunk_size - 32.0),
			rng.randf_range(32.0, chunk_size - 32.0)
		)
		trees_container.add_child(tree)

	for i in range(berry_count):
		var berry: Node2D = BERRY_SCENE.instantiate()
		berry.position = Vector2(
			rng.randf_range(32.0, chunk_size - 32.0),
			rng.randf_range(32.0, chunk_size - 32.0)
		)
		berries_container.add_child(berry)

func clear_existing_content(trees_container: Node2D, berries_container: Node2D) -> void:
	for child in trees_container.get_children():
		child.queue_free()

	for child in berries_container.get_children():
		child.queue_free()

func get_chunk_seed(coords: Vector2i) -> int:
	return int(
		ChunkGenerator.world_seed
		+ coords.x * 92821
		+ coords.y * 68917
	)
