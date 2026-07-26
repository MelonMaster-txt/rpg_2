extends Node2D

const CHUNK_NODE_SCENE: PackedScene = preload("res://game/world/chunk_node.tscn")

@export var chunk_size: int = 512
@export var load_radius: int = 1
## Désactiver en production pour les perfs
@export var debug_draw_chunks: bool = false

var _loaded_chunks: Dictionary = {}
var _player: Node2D = null
var _last_player_chunk: Vector2i = Vector2i(999999, 999999)
# Compteur de frames avant de retenter find_player (pour ne pas chercher chaque frame)
var _find_player_cooldown: int = 0


func _ready() -> void:
	# Le joueur est spawné en différé par overworld.gd ;
	# on attend la fin du frame courant pour être sûr qu'il est dans l'arbre.
	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_player = _find_player()
	if _player != null:
		var start := _world_to_chunk(_player.global_position)
		_load_chunks_around(start, load_radius + 1)
		_update_chunks()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		# Retenter find_player toutes les 30 frames seulement
		_find_player_cooldown -= 1
		if _find_player_cooldown <= 0:
			_find_player_cooldown = 30
			_player = _find_player()
		return
	_update_chunks()


func _find_player() -> Node2D:
	var direct: Node = get_node_or_null("../PlayerContainer/Player")
	if direct is Node2D:
		return direct as Node2D
	var group := get_tree().get_nodes_in_group("player")
	if group.size() > 0 and group[0] is Node2D:
		return group[0] as Node2D
	return null


func _load_chunks_around(center: Vector2i, radius: int) -> void:
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var c := Vector2i(x, y)
			if not _loaded_chunks.has(c):
				_load_chunk(c)


func _update_chunks() -> void:
	if _player == null or not is_instance_valid(_player):
		return

	var current := _world_to_chunk(_player.global_position)
	if current == _last_player_chunk:
		return
	_last_player_chunk = current

	var needed: Array[Vector2i] = []
	for x in range(current.x - load_radius, current.x + load_radius + 1):
		for y in range(current.y - load_radius, current.y + load_radius + 1):
			needed.append(Vector2i(x, y))

	for c in needed:
		if not _loaded_chunks.has(c):
			_load_chunk(c)

	var to_unload: Array[Vector2i] = []
	for c in _loaded_chunks.keys():
		if not needed.has(c):
			to_unload.append(c)
	for c in to_unload:
		_unload_chunk(c)

	if debug_draw_chunks:
		queue_redraw()


func _load_chunk(coords: Vector2i) -> void:
	var chunk: Node2D = CHUNK_NODE_SCENE.instantiate()
	var ctype: String = ChunkGenerator.get_chunk_type(coords)
	chunk.name = "Chunk_%d_%d" % [coords.x, coords.y]
	add_child(chunk)
	chunk.setup(coords, chunk_size, ctype)
	_loaded_chunks[coords] = chunk


func _unload_chunk(coords: Vector2i) -> void:
	if _loaded_chunks.has(coords):
		var chunk: Node = _loaded_chunks[coords]
		if is_instance_valid(chunk):
			chunk.queue_free()
		_loaded_chunks.erase(coords)


func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(world_pos.x / chunk_size) as int,
		floor(world_pos.y / chunk_size) as int
	)


func _draw() -> void:
	if not debug_draw_chunks:
		return
	for coords in _loaded_chunks.keys():
		var tl := Vector2(coords.x * chunk_size, coords.y * chunk_size)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), Color(0, 1, 0, 0.15), true)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), Color(0, 1, 0, 0.8), false, 2.0)
