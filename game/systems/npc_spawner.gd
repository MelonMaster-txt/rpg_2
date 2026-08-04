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


# ─── Spawn ────────────────────────────────────────────────────────────────────

func _try_spawn() -> void:
	if _active_npcs.size() >= MAX_NPCS:
		return
	var zone := _pick_weighted_zone()
	var pos   := _random_pos_in_rect(zone["rect"])
	var npc: Node = _npc_scene.instantiate()
	_world_root.add_child(npc)
	npc.global_position = pos
	npc.randomize_full(randi())
	# Connecter les signaux
	if npc.has_signal("npc_defeated"):
		npc.npc_defeated.connect(_on_npc_defeated)
	_active_npcs.append(npc)


func _pick_weighted_zone() -> Dictionary:
	var total_weight: int = 0
	for z in SPAWN_ZONES:
		total_weight += z["weight"]
	var r := randi() % total_weight
	var acc := 0
	for z in SPAWN_ZONES:
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
	for npc in _active_npcs:
		if is_instance_valid(npc):
			alive.append(npc)
	_active_npcs = alive
	# Despawn les NPCs trop loin du joueur
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player_pos: Vector2 = (players[0] as Node2D).global_position
	var still_alive: Array[Node] = []
	for npc in _active_npcs:
		if not is_instance_valid(npc):
			continue
		var d := (npc as Node2D).global_position.distance_to(player_pos)
		if d > DESPAWN_DISTANCE:
			npc.queue_free()
		else:
			still_alive.append(npc)
	_active_npcs = still_alive


func _on_npc_defeated(npc: Node) -> void:
	# Laisser die() gérer le queue_free — juste retirer de la liste
	if npc in _active_npcs:
		_active_npcs.erase(npc)


# ─── API publique ─────────────────────────────────────────────────────────────

func get_active_count() -> int:
	return _active_npcs.size()


func clear_all() -> void:
	for npc in _active_npcs:
		if is_instance_valid(npc):
			npc.queue_free()
	_active_npcs.clear()
