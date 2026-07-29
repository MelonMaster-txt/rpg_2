## ChunkManager — Pipeline asynchrone inspiré de Minecraft
##
## Architecture en 3 couches :
##   1. TICKETS  : chaque chunk a un niveau de priorité (ACTIVE / LAZY / SLEEP)
##   2. THREAD   : tout le calcul de génération se fait hors main thread
##   3. POOL     : les nodes chunk sont recyclés, jamais détruits/recréés
extends Node2D

const CHUNK_NODE_SCENE: PackedScene = preload("res://game/world/chunk_node.tscn")

# --- Niveaux de ticket (inspiré Minecraft) ---
enum TicketLevel {
	ACTIVE = 0,   # Chunk visible, pleinement actif (rendu + process)
	LAZY   = 1,   # Chunk en mémoire, invisible, process désactivé
	SLEEP  = 2,   # Chunk dans le pool, non attaché à la scène
}

@export var chunk_size:         int  = 512
@export var load_radius:        int  = 1
## Rayon supplémentaire chargé en LAZY (en mémoire mais inactif)
@export var lazy_radius:        int  = 2
## Spawn chunks : toujours en ACTIVE, jamais déchargés (comme Minecraft)
@export var spawn_chunk_radius: int  = 1
@export var debug_draw_chunks:  bool = false

## Nombre maximum de chunks appliqués par frame (1 = zéro saccade, 2 = chargement plus rapide)
@export var max_chunks_per_frame: int = 1

# --- État interne ---
var _loaded_chunks:  Dictionary = {}   # Vector2i → chunk node
var _ticket_levels:  Dictionary = {}   # Vector2i → TicketLevel
var _chunk_pool:     Array      = []   # nodes en attente de réutilisation
var _gen_queue:      Array      = []   # Vector2i à générer (thread)
var _ready_queue:    Array      = []   # {coords, data} prêts à appliquer (main thread)
var _gen_thread:     Thread     = null
var _thread_mutex:   Mutex      = Mutex.new()
var _thread_running: bool       = false

var _player:            Node2D   = null
var _last_player_chunk: Vector2i = Vector2i(999999, 999999)
var _find_player_cd:    int      = 0
var _spawn_center:      Vector2i = Vector2i(0, 0)


func _ready() -> void:
	_gen_thread     = Thread.new()
	_thread_running = true
	_gen_thread.start(_generation_thread_loop)
	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_player = _find_player()
	if _player != null:
		_spawn_center = _world_to_chunk(_player.global_position)
		_load_chunks_around(_spawn_center, load_radius + 1)
		_update_chunks()


func _process(_delta: float) -> void:
	# On applique AU MAXIMUM max_chunks_per_frame chunks par frame
	# pour éviter les saccades quand plusieurs chunks arrivent ensemble
	_flush_ready_queue()
	if _player == null or not is_instance_valid(_player):
		_find_player_cd -= 1
		if _find_player_cd <= 0:
			_find_player_cd = 30
			_player = _find_player()
		return
	_update_chunks()


func _exit_tree() -> void:
	_thread_running = false
	_thread_mutex.lock()
	_gen_queue.append(null)  # signal d'arrêt
	_thread_mutex.unlock()
	if _gen_thread and _gen_thread.is_started():
		_gen_thread.wait_to_finish()


# ---------------------------------------------------------------------------
# THREAD — calcul pur, zéro accès au scene tree
# ---------------------------------------------------------------------------
func _generation_thread_loop() -> void:
	while _thread_running:
		_thread_mutex.lock()
		var coords: Variant = null
		if _gen_queue.size() > 0:
			coords = _gen_queue.pop_front()
		_thread_mutex.unlock()

		if coords == null:
			OS.delay_msec(4)
			continue

		var data: Dictionary = _compute_chunk_data(coords as Vector2i)

		_thread_mutex.lock()
		_ready_queue.append({"coords": coords, "data": data})
		_thread_mutex.unlock()


func _compute_chunk_data(coords: Vector2i) -> Dictionary:
	var ctype: String = ChunkGenerator.get_chunk_type(coords)
	return {"type": ctype}


# ---------------------------------------------------------------------------
# MAIN THREAD — application des données + gestion du pool
# ---------------------------------------------------------------------------
func _flush_ready_queue() -> void:
	# On extrait seulement max_chunks_per_frame éléments du ready_queue
	_thread_mutex.lock()
	var available: int = _ready_queue.size()
	_thread_mutex.unlock()

	if available == 0:
		return

	var to_apply: int = mini(available, max_chunks_per_frame)

	for _i: int in to_apply:
		_thread_mutex.lock()
		var item: Dictionary = _ready_queue.pop_front()
		_thread_mutex.unlock()

		var coords: Vector2i = item["coords"]
		var data: Dictionary  = item["data"]
		if not _loaded_chunks.has(coords):
			continue
		var chunk: Node2D = _loaded_chunks[coords]
		if is_instance_valid(chunk):
			chunk.setup(coords, chunk_size, data["type"])
			_apply_ticket(coords)


# ---------------------------------------------------------------------------
# TICKETS — contrôle le niveau d'activité de chaque chunk
# ---------------------------------------------------------------------------
func _apply_ticket(coords: Vector2i) -> void:
	if not _loaded_chunks.has(coords) or not _ticket_levels.has(coords):
		return
	var chunk: Node2D = _loaded_chunks[coords]
	if not is_instance_valid(chunk):
		return
	match _ticket_levels[coords]:
		TicketLevel.ACTIVE:
			chunk.visible = true
			chunk.process_mode = Node.PROCESS_MODE_INHERIT
		TicketLevel.LAZY:
			chunk.visible = false
			chunk.process_mode = Node.PROCESS_MODE_DISABLED
		_:
			pass


# ---------------------------------------------------------------------------
# POOL — réutilisation des nodes, zéro GC spike
# ---------------------------------------------------------------------------
func _get_chunk_from_pool() -> Node2D:
	if _chunk_pool.size() > 0:
		return _chunk_pool.pop_back() as Node2D
	return CHUNK_NODE_SCENE.instantiate() as Node2D


func _return_chunk_to_pool(chunk: Node2D) -> void:
	if not is_instance_valid(chunk):
		return
	chunk.visible = false
	chunk.process_mode = Node.PROCESS_MODE_DISABLED
	if chunk.get_parent() != null:
		chunk.get_parent().remove_child(chunk)
	_chunk_pool.append(chunk)


# ---------------------------------------------------------------------------
# CHARGEMENT / DÉCHARGEMENT
# ---------------------------------------------------------------------------
func _load_chunks_around(center: Vector2i, radius: int) -> void:
	for x: int in range(center.x - radius, center.x + radius + 1):
		for y: int in range(center.y - radius, center.y + radius + 1):
			var c := Vector2i(x, y)
			if not _loaded_chunks.has(c):
				_queue_load_chunk(c, TicketLevel.ACTIVE)


func _update_chunks() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var current: Vector2i = _world_to_chunk(_player.global_position)
	if current == _last_player_chunk:
		return
	_last_player_chunk = current

	var active_set: Dictionary = {}
	var lazy_set:   Dictionary = {}

	# Spawn chunks — toujours ACTIVE
	for x: int in range(_spawn_center.x - spawn_chunk_radius, _spawn_center.x + spawn_chunk_radius + 1):
		for y: int in range(_spawn_center.y - spawn_chunk_radius, _spawn_center.y + spawn_chunk_radius + 1):
			active_set[Vector2i(x, y)] = true

	# Zone joueur → ACTIVE
	for x: int in range(current.x - load_radius, current.x + load_radius + 1):
		for y: int in range(current.y - load_radius, current.y + load_radius + 1):
			active_set[Vector2i(x, y)] = true

	# Anneau LAZY
	for x: int in range(current.x - lazy_radius, current.x + lazy_radius + 1):
		for y: int in range(current.y - lazy_radius, current.y + lazy_radius + 1):
			var c := Vector2i(x, y)
			if not active_set.has(c):
				lazy_set[c] = true

	for c: Vector2i in active_set:
		if not _loaded_chunks.has(c):
			_queue_load_chunk(c, TicketLevel.ACTIVE)
		else:
			_set_ticket(c, TicketLevel.ACTIVE)

	for c: Vector2i in lazy_set:
		if not _loaded_chunks.has(c):
			_queue_load_chunk(c, TicketLevel.LAZY)
		else:
			_set_ticket(c, TicketLevel.LAZY)

	var to_unload: Array = []
	for c: Vector2i in _loaded_chunks.keys():
		if not active_set.has(c) and not lazy_set.has(c):
			to_unload.append(c)
	for c: Vector2i in to_unload:
		_unload_chunk(c)

	if debug_draw_chunks:
		queue_redraw()


func _queue_load_chunk(coords: Vector2i, level: TicketLevel) -> void:
	var chunk: Node2D = _get_chunk_from_pool()
	chunk.name = "Chunk_%d_%d" % [coords.x, coords.y]
	add_child(chunk)
	_loaded_chunks[coords] = chunk
	_ticket_levels[coords] = level
	_thread_mutex.lock()
	_gen_queue.append(coords)
	_thread_mutex.unlock()


func _set_ticket(coords: Vector2i, level: TicketLevel) -> void:
	if _ticket_levels.get(coords) == level:
		return
	_ticket_levels[coords] = level
	_apply_ticket(coords)


func _unload_chunk(coords: Vector2i) -> void:
	# Spawn chunks protégés
	var dx: int = absi(coords.x - _spawn_center.x)
	var dy: int = absi(coords.y - _spawn_center.y)
	if dx <= spawn_chunk_radius and dy <= spawn_chunk_radius:
		return
	if _loaded_chunks.has(coords):
		var chunk: Node2D = _loaded_chunks[coords]
		_return_chunk_to_pool(chunk)
		_loaded_chunks.erase(coords)
		_ticket_levels.erase(coords)


# ---------------------------------------------------------------------------
# UTILITAIRES
# ---------------------------------------------------------------------------
func _find_player() -> Node2D:
	var direct: Node = get_node_or_null("../PlayerContainer/Player")
	if direct is Node2D:
		return direct as Node2D
	var group: Array = get_tree().get_nodes_in_group("player")
	if group.size() > 0 and group[0] is Node2D:
		return group[0] as Node2D
	return null


func _world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / float(chunk_size)),
		int(world_pos.y / float(chunk_size))
	)


func _draw() -> void:
	if not debug_draw_chunks:
		return
	for coords: Vector2i in _loaded_chunks.keys():
		var tl: Vector2  = Vector2(coords.x * chunk_size, coords.y * chunk_size)
		var col: Color
		match _ticket_levels.get(coords, TicketLevel.SLEEP):
			TicketLevel.ACTIVE: col = Color(0, 1, 0, 0.15)
			TicketLevel.LAZY:   col = Color(1, 0.6, 0, 0.10)
			_:                  col = Color(0.5, 0.5, 0.5, 0.05)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), col, true)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), Color(col.r, col.g, col.b, 0.8), false, 2.0)
