extends Node2D

const CHUNK_NODE_SCENE: PackedScene = preload("res://game/world/chunk_node.tscn")

@export var chunk_size: int = 512
@export var load_radius: int = 1
## Désactiver en production pour les perfs
@export var debug_draw_chunks: bool = false
## Nb de frames entre chaque tentative de trouver le joueur
@export var find_player_interval: int = 30
## Nb max de chunks à décharger par frame (évite les spikes)
@export var unload_per_frame: int = 2

var _loaded_chunks: Dictionary = {}
## Pool de chunks libres pour éviter instantiate() à chaque fois
var _chunk_pool: Array[Node2D] = []

var _player: Node2D = null
var _last_player_chunk: Vector2i = Vector2i(999999, 999999)
var _find_player_cooldown: int = 0
## File d'attente de coords à décharger, traités par petits paquets
var _unload_queue: Array[Vector2i] = []


func _ready() -> void:
	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_player = _find_player()
	if _player != null:
		var start := _world_to_chunk(_player.global_position)
		_load_chunks_around(start, load_radius + 1)
		_update_chunks()


func _process(_delta: float) -> void:
	# Traite la file de déchargement par petits paquets
	_flush_unload_queue()

	if _player == null or not is_instance_valid(_player):
		_find_player_cooldown -= 1
		if _find_player_cooldown <= 0:
			_find_player_cooldown = find_player_interval
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
	# Early exit : le joueur n'a pas changé de chunk
	if current == _last_player_chunk:
		return
	_last_player_chunk = current

	# Calcul des chunks nécessaires avec un Set (Dictionary clé-only)
	var needed: Dictionary = {}
	for x in range(current.x - load_radius, current.x + load_radius + 1):
		for y in range(current.y - load_radius, current.y + load_radius + 1):
			needed[Vector2i(x, y)] = true

	# Charger les manquants
	for c in needed.keys():
		if not _loaded_chunks.has(c):
			_load_chunk(c)

	# Mettre en file de déchargement
	for c in _loaded_chunks.keys():
		if not needed.has(c) and not _unload_queue.has(c):
			_unload_queue.append(c)

	if debug_draw_chunks:
		queue_redraw()


## Recycle un chunk depuis le pool ou en instancie un nouveau
func _get_chunk_from_pool() -> Node2D:
	if _chunk_pool.size() > 0:
		var recycled: Node2D = _chunk_pool.pop_back()
		recycled.visible = true
		return recycled
	return CHUNK_NODE_SCENE.instantiate() as Node2D


func _load_chunk(coords: Vector2i) -> void:
	var chunk: Node2D = _get_chunk_from_pool()
	var ctype: String = ChunkGenerator.get_chunk_type(coords)
	chunk.name = "Chunk_%d_%d" % [coords.x, coords.y]
	# Ajoute seulement si pas encore dans l'arbre
	if not chunk.is_inside_tree():
		add_child(chunk)
	chunk.setup(coords, chunk_size, ctype)
	_loaded_chunks[coords] = chunk


## Renvoi le chunk dans le pool au lieu de le détruire
func _unload_chunk(coords: Vector2i) -> void:
	if not _loaded_chunks.has(coords):
		return
	var chunk: Node = _loaded_chunks[coords]
	_loaded_chunks.erase(coords)
	if not is_instance_valid(chunk):
		return
	chunk.visible = false
	# Reset le chunk si la méthode existe
	if chunk.has_method("reset"):
		chunk.reset()
	_chunk_pool.append(chunk)


## Traite N chunks de la file par frame pour éviter les spikes
func _flush_unload_queue() -> void:
	var processed := 0
	while _unload_queue.size() > 0 and processed < unload_per_frame:
		var c: Vector2i = _unload_queue.pop_front()
		# Vérifie qu'il est toujours hors de la zone
		if _loaded_chunks.has(c):
			_unload_chunk(c)
		processed += 1


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
