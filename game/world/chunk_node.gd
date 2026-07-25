extends Node2D

const HUT_CHUNK_SCENE     := preload("res://game/world/scenes/hut_chunk.tscn")
const FOREST_CHUNK_SCENE  := preload("res://game/world/scenes/forest_chunk_base.tscn")
# plus tard : VILLAGE_CHUNK_SCENE, CAMP_CHUNK_SCENE...

var coords: Vector2i

func setup(_coords: Vector2i, chunk_size: int, chunk_type: String) -> void:
	coords = _coords
	global_position = Vector2(coords.x * chunk_size, coords.y * chunk_size)

	var scene_to_instance: PackedScene = null

	match chunk_type:
		"hut":
			scene_to_instance = HUT_CHUNK_SCENE
		"forest":
			scene_to_instance = FOREST_CHUNK_SCENE
		"special_village":
			scene_to_instance = VILLAGE_CHUNK_SCENE
		"special_camp":
			scene_to_instance = CAMP_CHUNK_SCENE
		_:
			scene_to_instance = FOREST_CHUNK_SCENE  # fallback

	if scene_to_instance != null:
		var content := scene_to_instance.instantiate()
		add_child(content)

func load_chunk(coords: Vector2i) -> void:
	var chunk := preload("res://game/world/scenes/chunk_node.tscn").instantiate()
	var chunk_type := ChunkGenerator.get_chunk_type(coords)
	chunk.setup(coords, chunk_size, chunk_type)
	add_child(chunk)
	loaded_chunks[coords] = chunk
