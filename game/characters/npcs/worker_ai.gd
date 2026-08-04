# worker_ai.gd
# Composant IA travailleur attaché au NPC après recrutement/capture.
# Le point de travail est généré PRÈS du NPC lui-même, pas du coffre.
extends Node

@export var job:            String = "woodcutter"
@export var work_radius:    float  = 60.0
@export var work_duration:  float  = 5.0
@export var travel_speed:   float  = 50.0

const JOB_YIELDS: Dictionary = {
	"farmer":     { "food": 2 },
	"woodcutter": { "wood": 3 },
	"miner":      { "stone": 2, "ore": 1 },
	"guard":      {},
	"trader":     { "gold": 2 },
	"builder":    { "build_points": 1 },
}

const JOB_ICON: Dictionary = {
	"farmer":     "🌾",
	"woodcutter": "🪓",
	"miner":      "⛏️",
	"guard":      "🛡️",
	"trader":     "💰",
	"builder":    "🔨",
	"":            "💤",
}

enum State { TRAVEL_TO_WORK, WORKING, TRAVEL_TO_CHEST, DEPOSIT }
var _state: State = State.TRAVEL_TO_WORK

var _work_position: Vector2 = Vector2.ZERO
var _home_position: Vector2 = Vector2.ZERO  # position initiale du NPC = base de travail
var _chest_node:    Node2D  = null
var _work_timer:    float   = 0.0
var _owner_npc:     CharacterBody2D = null
var _job_label:     Label   = null

func _ready() -> void:
	_owner_npc = get_parent() as CharacterBody2D
	if _owner_npc == null:
		push_error("WorkerAI: parent n'est pas un CharacterBody2D")
		return
	# Mémorise la position courante comme base de travail
	_home_position = _owner_npc.global_position
	_create_job_label()
	_find_chest()
	_pick_work_position()
	_state = State.TRAVEL_TO_WORK


func _create_job_label() -> void:
	_job_label = Label.new()
	_job_label.text = JOB_ICON.get(job, "?") + " " + job
	_job_label.position = Vector2(-20, -48)
	_job_label.add_theme_font_size_override("font_size", 11)
	_owner_npc.add_child(_job_label)


func _find_chest() -> void:
	var chests: Array = get_tree().get_nodes_in_group("chest")
	if chests.size() > 0:
		_chest_node = chests[0] as Node2D


func _pick_work_position() -> void:
	# Le point de travail est dans un rayon autour de la position de base du NPC
	# => il ne sort jamais de sa zone, pas de déplacement inter-scène
	var angle: float = randf() * TAU
	_work_position = _home_position + Vector2(cos(angle), sin(angle)) * randf_range(20.0, work_radius)

# ─── Boucle ───────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _owner_npc == null:
		return
	# Si le coffre est dans une autre scène, on dépose sur place
	if _chest_node != null and not is_instance_valid(_chest_node):
		_chest_node = null
		_find_chest()
	match _state:
		State.TRAVEL_TO_WORK:  _do_travel(_work_position, 8.0, _on_reached_work)
		State.WORKING:         _do_working(delta)
		State.TRAVEL_TO_CHEST: _do_travel_chest(delta)
		State.DEPOSIT:         _do_deposit()


func _do_travel(target: Vector2, threshold: float, on_reach: Callable) -> void:
	var dist: float = _owner_npc.global_position.distance_to(target)
	if dist < threshold:
		_owner_npc.velocity = Vector2.ZERO
		on_reach.call()
		return
	var dir: Vector2 = (target - _owner_npc.global_position).normalized()
	_owner_npc.velocity = dir * travel_speed
	_owner_npc.move_and_slide()


func _on_reached_work() -> void:
	_work_timer = work_duration
	_state = State.WORKING


func _do_working(delta: float) -> void:
	_owner_npc.velocity = Vector2.ZERO
	# Petit oscillement pour signifier le travail
	var t: float = Time.get_ticks_msec() * 0.005
	_owner_npc.position.y += sin(t * 8.0) * 0.3
	_work_timer -= delta
	if _work_timer > 0.0:
		return
	# Travail terminé : aller au coffre s'il est accessible, sinon déposer directement
	if _chest_node != null and _chest_node.is_inside_tree():
		_state = State.TRAVEL_TO_CHEST
	else:
		_deposit_resources()
		_pick_work_position()
		_state = State.TRAVEL_TO_WORK


func _do_travel_chest(delta: float) -> void:
	if _chest_node == null or not _chest_node.is_inside_tree():
		_deposit_resources()
		_pick_work_position()
		_state = State.TRAVEL_TO_WORK
		return
	_do_travel(_chest_node.global_position, 12.0, _on_reached_chest)


func _on_reached_chest() -> void:
	_state = State.DEPOSIT


func _do_deposit() -> void:
	_deposit_resources()
	_pick_work_position()
	_state = State.TRAVEL_TO_WORK


func _deposit_resources() -> void:
	if _chest_node == null or not _chest_node.has_method("deposit"):
		return
	var inv_bonus: int = 0
	# Lit les bonus d'inventaire si le NPC en a un
	var npc_inv = _owner_npc.get("inventory")
	if npc_inv != null and npc_inv.has_method("get_bonus"):
		inv_bonus = npc_inv.get_bonus(job_skill_name())
	var yields: Dictionary = JOB_YIELDS.get(job, {})
	for resource in yields:
		var amount: int = yields[resource] + inv_bonus
		_chest_node.deposit(resource, amount)


func job_skill_name() -> String:
	match job:
		"farmer":     return "farming"
		"woodcutter": return "woodcutting"
		"miner":      return "mining"
		"trader":     return "trading"
		_:            return ""


func update_job(new_job: String) -> void:
	job = new_job
	if _job_label:
		_job_label.text = JOB_ICON.get(job, "?") + " " + job
	_pick_work_position()
	_state = State.TRAVEL_TO_WORK
