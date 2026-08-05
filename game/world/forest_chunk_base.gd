extends Node2D

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal npc_encounter_triggered(npc_data: Resource)

# ─── CONSTS ───────────────────────────────────────────────────────────────────
const CHUNK_SIZE: int = 16
const TILE_SIZE: int = 32
const NPC_SPAWN_CHANCE: float = 0.05
const RESOURCE_DENSITY: float = 0.15
const TREE_DENSITY: float = 0.3
const BUSH_DENSITY: float = 0.1
const MUSHROOM_DENSITY: float = 0.05
const STONE_DENSITY: float = 0.08

# ─── EXPORTS ──────────────────────────────────────────────────────────────────
@export var tree_scene: PackedScene = null
@export var stone_scene: PackedScene = null
@export var bush_scene: PackedScene = null
@export var mushroom_scene: PackedScene = null
@export var npc_scene: PackedScene = null
@export var random_npc_data: Array[Resource] = []

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _spawned: bool = false

func _ready() -> void:
	if not _spawned:
		_populate()
		_spawned = true

func _populate() -> void:
	_rng.randomize()
	var world_size: int = CHUNK_SIZE * TILE_SIZE
	for _i: int in range(int(CHUNK_SIZE * CHUNK_SIZE * TREE_DENSITY)):
		if tree_scene == null:
			break
		var obj: Node2D = tree_scene.instantiate()
		obj.position = Vector2(
				_rng.randf_range(0, world_size),
				_rng.randf_range(0, world_size)
		)
		add_child(obj)
	if _rng.randf() < NPC_SPAWN_CHANCE and npc_scene != null:
		_spawn_npc()

func _spawn_npc() -> void:
	var npc: Node2D = npc_scene.instantiate()
	var world_size: int = CHUNK_SIZE * TILE_SIZE
	npc.position = Vector2(
			_rng.randf_range(32, world_size - 32),
			_rng.randf_range(32, world_size - 32)
	)
	add_child(npc)
	if random_npc_data.size() > 0:
		var data: Resource = random_npc_data[
				_rng.randi() % random_npc_data.size()
		]
		if npc.has_method("set_npc_data"):
			npc.set_npc_data(data)
		emit_signal("npc_encounter_triggered", data)
