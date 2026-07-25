extends Node

@export var chunk_size: int = 128
@export var load_radius: int = 2  # nombre de chunks autour du joueur

var loaded_chunks: = {}  # clé: Vector2i (cx, cy) -> valeur: ChunkNode

func _process(_delta: float) -> void:
	update_chunks_around_player()

func update_chunks_around_player() -> void:
	var player := get_parent().get_node("Player")  # ou un chemin plus propre
	var current_chunk := world_to_chunk(player.global_position)

	var needed := []
	for x in range(current_chunk.x - load_radius, current_chunk.x + load_radius + 1):
		for y in range(current_chunk.y - load_radius, current_chunk.y + load_radius + 1):
			needed.append(Vector2i(x, y))

	# Charger les chunks manquants
	for coords in needed:
		if not loaded_chunks.has(coords):
			load_chunk(coords)

	# Décharger les chunks plus nécessaires
	for coords in loaded_chunks.keys():
		if coords not in needed:
			unload_chunk(coords)
			
func world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(world_pos.x / chunk_size),
		floor(world_pos.y / chunk_size)
	)
