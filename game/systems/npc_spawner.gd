# npc_spawner.gd
# Autoload — Spawne des NPCs aléatoires dans la forêt.
# Gère un pool, le nettoyage des morts et la densité par zone.
extends Node

const NPC_SCENE := "res://game/characters/npcs/random_npc.tscn"
const MAX_NPCS          := 8    # max actifs en même temps
const SPAWN_INTERVAL    := 20.0 # secondes entre chaque vague
const DESPAWN_DISTANCE  := 800.0

# Zones de spawn (rectangles en coordonnées monde) — à adapter selon ta map
const SPAWN_ZONES := [
	{"rect": Rect2(-600, -600, 400, 400), "weight": 3},  # forêt nord-ouest
	{"rect": Rect2( 200, -600, 400, 400), "weight": 3},  # forêt nord-est
	{"rect": Rect2(-600,  200, 400, 400), "weight": 2},  # forêt sud-ouest
	{"rect": Rect2( 200,  200, 400, 400), "weight": 2},  # forêt sud-est
]

var _npc_scene: PackedScene = null
var _active_npcs: Array[Node] = []
var _spawn_timer: float = 5.0   # premier spawn rapide
var _world_root:  Node  = null

func _ready() -> void:
	_npc_scene = load(NPC_SCENE)
	if _npc_scene == null:
		push_error("NpcSpawner: scène NPC introuvable : " + NPC_SCENE)


func initialize(world_root: Node) -> void:
	_world_root = world_root


func _process(delta: float) -> void:
	if _world_root == null or _npc_scene == null:
		return
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_INTERVAL
		_cleanup_dead()
		_try_spawn()


# ─── Spawn automatique ────────────────────────────────────────────────────────

func _try_spawn() -> void:
	if _active_npcs.size() >= MAX_NPCS:
		return
	var zone: Dictionary = _pick_weighted_zone()
	var pos: Vector2 = _random_pos_in_rect(zone["rect"])
	_spawn_at(pos)


func _spawn_at(pos: Vector2) -> void:
	if _npc_scene == null:
		return
	var root: Node = _world_root if _world_root != null else get_tree().current_scene
	if root == null:
		return
	var npc: Node = _npc_scene.instantiate()
	root.add_child(npc)
	(npc as Node2D).global_position = pos
	npc.randomize_full(randi())
	if npc.has_signal("npc_defeated"):
		npc.npc_defeated.connect(_on_npc_defeated)
	_active_npcs.append(npc)


func _pick_weighted_zone() -> Dictionary:
	var total_weight: int = 0
	for z: Dictionary in SPAWN_ZONES:
		total_weight += z["weight"]
	var r: int = randi() % total_weight
	var acc: int = 0
	for z: Dictionary in SPAWN_ZONES:
		acc += z["weight"]
		if r < acc:
			return z
	return SPAWN_ZONES[0]


func _random_pos_in_rect(rect: Rect2) -> Vector2:
	return Vector2(
		randf_range(rect.position.x, rect.position.x + rect.size.x),
		randf_range(rect.position.y, rect.position.y + rect.size.y)
	)


# ─── Nettoyage ────────────────────────────────────────────────────────────────

func _cleanup_dead() -> void:
	var alive: Array[Node] = []
	for npc: Node in _active_npcs:
		if is_instance_valid(npc):
			alive.append(npc)
	_active_npcs = alive
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player_pos: Vector2 = (players[0] as Node2D).global_position
	var still_alive: Array[Node] = []
	for npc: Node in _active_npcs:
		if not is_instance_valid(npc):
			continue
		var d: float = (npc as Node2D).global_position.distance_to(player_pos)
		if d > DESPAWN_DISTANCE:
			npc.queue_free()
		else:
			still_alive.append(npc)
	_active_npcs = still_alive


func _on_npc_defeated(npc: Node) -> void:
	if npc in _active_npcs:
		_active_npcs.erase(npc)


# ─── API publique ─────────────────────────────────────────────────────────────

func get_active_count() -> int:
	return _active_npcs.size()


## Spawne [count] NPCs dans un rayon [radius] autour de [origin].
## Utilisé par le HUD debug et les événements scénarisés.
func spawn_random_around(origin: Vector2, radius: float, count: int = 1) -> void:
	for i: int in range(count):
		if _active_npcs.size() >= MAX_NPCS:
			break
		var angle: float = randf() * TAU
		var dist: float  = randf_range(32.0, radius)
		var pos: Vector2 = origin + Vector2(cos(angle), sin(angle)) * dist
		_spawn_at(pos)


## Supprime tous les NPCs actifs (alias de clear_all pour le debug).
func despawn_all() -> void:
	clear_all()


func clear_all() -> void:
	for npc: Node in _active_npcs:
		if is_instance_valid(npc):
			npc.queue_free()
	_active_npcs.clear()
