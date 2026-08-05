extends Node2D

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal chunk_loaded(chunk_pos: Vector2i)
signal chunk_unloaded(chunk_pos: Vector2i)

# ─── CONSTS ───────────────────────────────────────────────────────────────────
const CHUNK_SIZE: int = 16
const TILE_SIZE: int = 32
const LOAD_RADIUS: int = 3
const UNLOAD_RADIUS: int = 5

# ─── EXPORTS ──────────────────────────────────────────────────────────────────
@export var chunk_scene: PackedScene = null
@export var player_path: NodePath = NodePath("../Player")

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _loaded_chunks: Dictionary = {}
var _player: Node = null

func _ready() -> void:
	_player = get_node_or_null(player_path)

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
	for dx: int in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dy: int in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var cpos := Vector2i(center.x + dx, center.y + dy)
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
		if dist > UNLOAD_RADIUS:
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
	emit_signal("chunk_loaded", cpos)

func _despawn_chunk(cpos: Vector2i) -> void:
	if not _loaded_chunks.has(cpos):
		return
	_loaded_chunks[cpos].queue_free()
	_loaded_chunks.erase(cpos)
	emit_signal("chunk_unloaded", cpos)
