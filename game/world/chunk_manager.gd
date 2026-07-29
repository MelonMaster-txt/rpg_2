# chunk_manager.gd
# Gere le chargement / déchargement des chunks autour du joueur.
#
# OPTIMISATIONS :
#  1. File d'attente avec BUDGET TEMPS : on charge autant de chunks que possible
#     dans une fenêtre de X millisecondes par frame (pas de compteur fixe).
#  2. Tri par distance : toujours charger le plus proche d'abord.
#  3. Visibilité : les chunks hors caméra sont mis en mode "invisible"
#     (process_mode = DISABLED) pour économiser CPU et draw calls.
#  4. Preload anticipé : au démarrage on charge load_radius+1 pour avoir
#     une marge avant que le joueur ne bouge.
extends Node2D

const CHUNK_NODE_SCENE: PackedScene = preload("res://game/world/chunk_node.tscn")

@export var chunk_size:          int   = 512
@export var load_radius:         int   = 1
## Budget en millisecondes alloué au chargement de chunks par frame
## 4ms = très lisse, 8ms = chargement plus rapide, 16ms = tout en une frame (ancien comportement)
@export var load_budget_ms:      float = 4.0
@export var debug_draw_chunks:   bool  = false

var _loaded_chunks:      Dictionary     = {}
var _player:             Node2D         = null
var _last_player_chunk:  Vector2i       = Vector2i(999999, 999999)
var _find_player_cooldown: int          = 0
var _load_queue:         Array[Vector2i] = []
## Cache de la région visible en chunk-coords (mis à jour chaque frame)
var _visible_rect:       Rect2i          = Rect2i()


func _ready() -> void:
	call_deferred("_deferred_init")


func _deferred_init() -> void:
	_player = _find_player()
	if _player == null:
		return
	var start := _world_to_chunk(_player.global_position)
	# Preload région élargie dès le démarrage
	for x in range(start.x - (load_radius + 1), start.x + load_radius + 2):
		for y in range(start.y - (load_radius + 1), start.y + load_radius + 2):
			var c := Vector2i(x, y)
			if not _loaded_chunks.has(c):
				_load_queue.append(c)
	# Le chunk du joueur est chargé immédiatement
	if not _loaded_chunks.has(start):
		_load_chunk(start)
		_load_queue.erase(start)
	_sort_queue_by_distance()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_find_player_cooldown -= 1
		if _find_player_cooldown <= 0:
			_find_player_cooldown = 30
			_player = _find_player()
		return

	_update_visible_rect()
	_update_chunks()
	_process_load_queue()
	_update_chunk_visibility()


func _find_player() -> Node2D:
	var direct: Node = get_node_or_null("../PlayerContainer/Player")
	if direct is Node2D:
		return direct as Node2D
	var group := get_tree().get_nodes_in_group("player")
	if group.size() > 0 and group[0] is Node2D:
		return group[0] as Node2D
	return null


## Met à jour le rectangle de chunks actuellement dans la caméra
func _update_visible_rect() -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var zoom: Vector2    = cam.zoom
	var half: Vector2    = (vp_size / zoom) * 0.5
	var cam_pos: Vector2 = cam.global_position
	var top_left  := _world_to_chunk(cam_pos - half - Vector2(chunk_size, chunk_size))
	var bot_right := _world_to_chunk(cam_pos + half + Vector2(chunk_size, chunk_size))
	_visible_rect = Rect2i(top_left, bot_right - top_left + Vector2i(1, 1))


## Active/désactive le process des chunks selon leur visibilité caméra
func _update_chunk_visibility() -> void:
	for coords in _loaded_chunks.keys():
		var chunk: Node = _loaded_chunks[coords]
		if not is_instance_valid(chunk):
			continue
		var visible: bool = _visible_rect.has_point(coords)
		chunk.visible = visible
		# Désactive le process des chunks invisibles = économie CPU
		chunk.process_mode = Node.PROCESS_MODE_INHERIT if visible else Node.PROCESS_MODE_DISABLED


func _process_load_queue() -> void:
	if _load_queue.is_empty():
		return
	var t_start: int = Time.get_ticks_usec()
	var budget_us: int = int(load_budget_ms * 1000.0)
	while not _load_queue.is_empty():
		var elapsed: int = Time.get_ticks_usec() - t_start
		if elapsed >= budget_us:
			break
		var coords: Vector2i = _load_queue.pop_front()
		if not _loaded_chunks.has(coords):
			_load_chunk(coords)


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
		if not _loaded_chunks.has(c) and not _load_queue.has(c):
			_load_queue.append(c)

	# Retire de la queue ce qui n'est plus nécessaire
	var i := _load_queue.size() - 1
	while i >= 0:
		if not needed.has(_load_queue[i]):
			_load_queue.remove_at(i)
		i -= 1

	# Décharge les chunks hors rayon
	var to_unload: Array[Vector2i] = []
	for c in _loaded_chunks.keys():
		if not needed.has(c):
			to_unload.append(c)
	for c in to_unload:
		_unload_chunk(c)

	_sort_queue_by_distance()

	if debug_draw_chunks:
		queue_redraw()


func _sort_queue_by_distance() -> void:
	if _player == null or _load_queue.is_empty():
		return
	var pc := _world_to_chunk(_player.global_position)
	_load_queue.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a - pc).length_squared() < (b - pc).length_squared()
	)


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
		var col := Color(0, 1, 0, 0.8) if _visible_rect.has_point(coords) else Color(1, 0.5, 0, 0.5)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), Color(col.r, col.g, col.b, 0.12), true)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), col, false, 2.0)
	for coords in _load_queue:
		var tl := Vector2(coords.x * chunk_size, coords.y * chunk_size)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), Color(1, 1, 0, 0.08), true)
		draw_rect(Rect2(tl, Vector2(chunk_size, chunk_size)), Color(1, 1, 0, 0.5), false, 1.0)
