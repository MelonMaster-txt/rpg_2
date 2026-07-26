extends Node2D

var world_seed: int = 123456

func set_world_seed(new_seed: int) -> void:
	world_seed = new_seed

func get_chunk_type(coords: Vector2i) -> String:
	if coords == Vector2i(0, 0):
		return "hut"

	return "forest"
