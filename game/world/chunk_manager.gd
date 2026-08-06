extends Node2D

signal chunk_loaded(chunk_pos: Vector2i)
signal chunk_unloaded(chunk_pos: Vector2i)

const CHUNK_SIZE: int = 16
const TILE_SIZE: int = 32

@export var load_radius: int = 3
@export var lazy_radius: int = 5
@export var spawn_chunk_radius: int = 1
@export var max_chunks_per_frame: int = 1
@export var chunk_scene: PackedScene = null

var _loaded_chunks: Dictionary = {}
var _player: Node = null


func set_player(p: Node) -> void:
	_player = p


func _process(_delta: float) -> void:
	if _player == null:
		return
	var player_chunk: Vector2i = _world_to_chunk(_player.global_position)
	_load_around(player_chunk)
	_unload_far(player_chunk)


func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	var cell_size: int = CHUNK_SIZE * TILE_SIZE
	return Vector2i(
		int(floor(world_pos.x / cell_size)),
		int(floor(world_pos.y / cell_size))
	)


func _load_around(center: Vector2i) -> void:
	for dx: int in range(-load_radius, load_radius + 1):
		for dy: int in range(-load_radius, load_radius + 1):
			var cpos: Vector2i = Vector2i(center.x + dx, center.y + dy)
			if _loaded_chunks.has(cpos):
				continue
			_spawn_chunk(cpos)


func _unload_far(center: Vector2i) -> void:
	var to_remove: Array[Vector2i] = []
	for cpos: Vector2i in _loaded_chunks:
		var dist: int = maxi(
			abs(cpos.x - center.x),
			abs(cpos.y - center.y)
		)
		if dist > lazy_radius:
			to_remove.append(cpos)
	for cpos: Vector2i in to_remove:
		_despawn_chunk(cpos)


func _spawn_chunk(cpos: Vector2i) -> void:
	if chunk_scene == null:
		return
	var chunk: Node2D = chunk_scene.instantiate()
	var cell_size: int = CHUNK_SIZE * TILE_SIZE
	chunk.global_position = Vector2(cpos.x * cell_size, cpos.y * cell_size)
	add_child(chunk)
	_loaded_chunks[cpos] = chunk
	chunk_loaded.emit(cpos)


func _despawn_chunk(cpos: Vector2i) -> void:
	if not _loaded_chunks.has(cpos):
		return
	_loaded_chunks[cpos].queue_free()
	_loaded_chunks.erase(cpos)
	chunk_unloaded.emit(cpos)
