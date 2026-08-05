extends CharacterBody2D
class_name NpcBase

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal npc_died(npc: NpcBase)
signal npc_captured(npc: NpcBase)

# ─── ENUMS ────────────────────────────────────────────────────────────────────
enum State { IDLE, WANDER, FLEE, WORK, FOLLOW, COMBAT }

# ─── EXPORTS ──────────────────────────────────────────────────────────────────
@export var npc_name: String = "NPC"
@export var max_health: int = 50
@export var move_speed: float = 60.0
@export var detection_range: float = 150.0
@export var npc_data: Resource = null

# ─── ONREADY ──────────────────────────────────────────────────────────────────
@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _nav: NavigationAgent2D = $NavigationAgent2D

# ─── VARS ─────────────────────────────────────────────────────────────────────
var current_health: int = 50
var current_state: State = State.IDLE
var _wander_timer: float = 0.0
var _wander_target: Vector2 = Vector2.ZERO

func _ready() -> void:
	current_health = max_health

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	emit_signal("npc_died", self)
	for spawner in get_tree().get_nodes_in_group("npc_spawner"):
		if spawner.has_method("_on_npc_defeated"):
			spawner._on_npc_defeated(self)
	queue_free()

func capture() -> void:
	emit_signal("npc_captured", self)
	queue_free()

func set_state(new_state: State) -> void:
	current_state = new_state

func _physics_process(delta: float) -> void:
	match current_state:
		State.WANDER:
			_process_wander(delta)
		State.FOLLOW:
			_process_follow()
		_:
			pass

func _process_wander(delta: float) -> void:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(2.0, 5.0)
		_wander_target = global_position + Vector2(
				randf_range(-80.0, 80.0),
				randf_range(-80.0, 80.0)
		)
		_nav.target_position = _wander_target
	if not _nav.is_navigation_finished():
		var dir: Vector2 = _nav.get_next_path_position() - global_position
		velocity = dir.normalized() * move_speed
		move_and_slide()

func _process_follow() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	_nav.target_position = player.global_position
	if not _nav.is_navigation_finished():
		var dir: Vector2 = _nav.get_next_path_position() - global_position
		velocity = dir.normalized() * move_speed
		move_and_slide()
