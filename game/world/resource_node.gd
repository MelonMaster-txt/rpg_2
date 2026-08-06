extends Node2D

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal depleted

# ─── ENUMS ────────────────────────────────────────────────────────────────────
enum ResourceType { TREE, STONE, BERRY_BUSH, MUSHROOM, FLINT, HERB }

# ─── CONSTS ───────────────────────────────────────────────────────────────────
const TYPE_TO_KEY: Dictionary = {
	ResourceType.TREE:       "wood",
	ResourceType.STONE:      "stone",
	ResourceType.BERRY_BUSH: "berries",
	ResourceType.MUSHROOM:   "mushroom",
	ResourceType.FLINT:      "flint",
	ResourceType.HERB:       "herb",
}

# ─── EXPORTS ──────────────────────────────────────────────────────────────────
@export var resource_type: ResourceType = ResourceType.TREE
@export var max_charges: int = 3
@export var yield_min: int = 1
@export var yield_max: int = 3
@export var respawn_time: float = 60.0

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _charges: int = 3
var _respawn_timer: float = 0.0
var _depleted: bool = false

func _ready() -> void:
	_charges = max_charges

func harvest() -> void:
	if _depleted:
		return
	var amount: int = randi_range(yield_min, yield_max)
	var key: String = TYPE_TO_KEY.get(resource_type, "wood") as String
	GameManager.add_item(key, amount)
	_charges -= 1
	if _charges <= 0:
		_depleted = true
		modulate = Color(0.5, 0.5, 0.5)
		emit_signal("depleted")

func _process(delta: float) -> void:
	if not _depleted:
		return
	_respawn_timer += delta
	if _respawn_timer >= respawn_time:
		_respawn()

func _respawn() -> void:
	_charges = max_charges
	_depleted = false
	_respawn_timer = 0.0
	modulate = Color.WHITE
