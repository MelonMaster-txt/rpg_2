# chunk_manager.gd
# Gere le chargement / déchargement des chunks autour du joueur.
# OPTIMISATION : les chunks en attente sont mis dans une _load_queue
# et on n'en instancie qu'un seul par frame pour eviter les freeze.
extends Node2D

const CHUNK_NODE_SCENE: PackedScene = preload("res://game/world/chunk_node.tscn")

@export var chunk_size: int = 512
@export var load_radius: int = 1
## Désactiver en production pour les perfs
@export var debug_draw_chunks: bool = false
## Nombre de chunks instanciés par frame (1 = lissage max, 2-3 = chargement plus rapide)
@export var chunks_per_frame: int = 1

var _loaded_chunks: Dictionary = {}
var _player: Node2D = null
var _last_player_chunk: Vector2i = Vector2i(999999, 999999)
var _find_player_cooldown: int = 0

# File d'attente : chunks à charger sans bloquer le rendu
var _load_queue: Array[Vector2i] = []


func _ready() -> void:
	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_player = _find_player()
	if _player != null:
		var start := _world_to_chunk(_player.global_position)
		_enqueue_chunks_around(start, load_radius + 1)
		# Le chunk central est chargé immédiatement pour ne pas partir de rien
		if not _loaded_chunks.has(start):
			_load_chunk(start)
			_load_queue.erase(start)


func _process(_delta: float) -> void:
	# --- Trouver le joueur si perdu ---
	if _player == null or not is_instance_valid(_player):
		_find_player_cooldown -= 1
		if _find_player_cooldown <= 0:
			_find_player_cooldown = 30
			_player = _find_player()
		return

	# --- Mise à jour de la liste des chunks nécessaires ---
	_update_chunks()

	# --- Dépiler la queue : N chunks max par frame ---
	var loaded_this_frame := 0
	while _load_queue.size() > 0 and loaded_this_frame < chunks_per_frame:
		var coords: Vector2i = _load_queue.pop_front()
		# Vérifier qu'il n'a pas été déchargé entre-temps
		if not _loaded_chunks.has(coords):
			_load_chunk(coords)
			loaded_this_frame += 1


func _find_player() -> Node2D:
	var direct: Node = get_node_or_null("../PlayerContainer/Player")
	if direct is Node2D:
		return direct as Node2D
	var group := get_tree().get_nodes_in_group("player")
	if group.size() > 0 and group[0] is Node2D:
		return group[0] as Node2D
	return null


func _enqueue_chunks_around(center: Vector2i, radius: int) -> void:
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var c := Vector2i(x, y)
			if not _loaded_chunks.has(c) and not _load_queue.has(c):
				_load_queue.append(c)


## Trie la queue par proximité au joueur pour charger d'abord ce qui est visible
func _sort_queue_by_distance() -> void:
	if _player == null:
		return
	var player_chunk := _world_to_chunk(_player.global_position)
	_load_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := (a - player_chunk).length_squared()
		var db := (b - player_chunk).length_squared()
		return da < db
	)


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

	# Enfile les chunks manquants
	for c in needed:
		if not _loaded_chunks.has(c) and not _load_queue.has(c):
			_load_queue.append(c)

	# Retire de la queue les coords devenues inutiles
	var i := _load_queue.size() - 1
	while i >= 0:
		if not needed.has(_load_queue[i]):
			_load_queue.remove_at(i)
		i -= 1

	# Décharge les chunks trop loin
	var to_unload: Array[Vector2i] = []
	for c in _loaded_chunks.keys():
		if not needed.has(c):
			to_unload.append(c)
	for c in to_unload:
		_unload_chunk(c)

	# Trie la queue pour prioriser ce qui est proche
	_sort_queue_by_distance()

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
		int(floor(world_pos.x / float(chunk_size))),
		int(floor(world_pos.y / float(chunk_size)))
	)


func _draw() -> void:
	if not debug_draw_chunks:
		return
	for coords in _loaded_chunks.keys():
		var tl := Vector2(coords.x * chunk_size, coords.y * chunk_size)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), Color(0, 1, 0, 0.15), true)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), Color(0, 1, 0, 0.8), false, 2.0)
	for coords in _load_queue:
		var tl := Vector2(coords.x * chunk_size, coords.y * chunk_size)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), Color(1, 0.5, 0, 0.10), true)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), Color(1, 0.5, 0, 0.6), false, 1.0)
