# worker_ai.gd
# Composant IA "travailleur" à attacher à un RandomNpc après capture/recrutement.
# Le NPC marche vers une position de travail, joue une animation, puis dépose
# dans le coffre global à intervalle régulier.
extends Node

# ─── Config ──────────────────────────────────────────────────────────────────

@export var job:             String  = "woodcutter"
@export var work_radius:    float   = 80.0   # rayon autour du point de travail
@export var work_duration:  float   = 5.0    # secondes sur place avant dépôt
@export var travel_speed:   float   = 50.0

# Production par dépôt (par défaut = même que CompanionManager.JOB_PRODUCTION)
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
	"":           "💤",
}

# ─── État interne ─────────────────────────────────────────────────────────────

enum State { IDLE, TRAVEL_TO_WORK, WORKING, TRAVEL_TO_CHEST, DEPOSIT }
var _state: State = State.IDLE

var _work_position:  Vector2 = Vector2.ZERO
var _chest_node:     Node2D  = null
var _work_timer:     float   = 0.0
var _owner_npc:      CharacterBody2D = null

@onready var _job_label: Label = null  # créé dynamiquement

# ─── Init ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_owner_npc = get_parent() as CharacterBody2D
	_create_job_label()
	_find_chest()
	_pick_work_position()
	_state = State.TRAVEL_TO_WORK


func _create_job_label() -> void:
	_job_label = Label.new()
	_job_label.text = JOB_ICON.get(job, "?") + " " + job
	_job_label.position = Vector2(-20, -48)
	_job_label.add_theme_font_size_override("font_size", 11)
	if _owner_npc:
		_owner_npc.add_child(_job_label)


func _find_chest() -> void:
	var chests: Array = get_tree().get_nodes_in_group("chest")
	if chests.size() > 0:
		_chest_node = chests[0] as Node2D


func _pick_work_position() -> void:
	if _chest_node == null:
		_work_position = Vector2(randf_range(-120, 120), randf_range(-80, 80))
		return
	# Travaille dans un rayon autour du coffre, côté opposé selon le job
	var angle: float = randf() * TAU
	_work_position = _chest_node.global_position + Vector2(cos(angle), sin(angle)) * work_radius

# ─── Boucle ───────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _owner_npc == null:
		return
	match _state:
		State.TRAVEL_TO_WORK:   _do_travel_to_work(delta)
		State.WORKING:          _do_working(delta)
		State.TRAVEL_TO_CHEST:  _do_travel_to_chest(delta)
		State.DEPOSIT:          _do_deposit()


func _do_travel_to_work(delta: float) -> void:
	var dist: float = _owner_npc.global_position.distance_to(_work_position)
	if dist < 8.0:
		_owner_npc.velocity = Vector2.ZERO
		_work_timer = work_duration
		_state = State.WORKING
		return
	var dir: Vector2 = (_work_position - _owner_npc.global_position).normalized()
	_owner_npc.velocity = dir * travel_speed
	_owner_npc.move_and_slide()


func _do_working(delta: float) -> void:
	_owner_npc.velocity = Vector2.ZERO
	# Animation de travail : petit oscillement vertical
	var t: float = Time.get_ticks_msec() * 0.005
	_owner_npc.position.y += sin(t * 8.0) * 0.3
	_work_timer -= delta
	if _work_timer <= 0.0:
		if _chest_node != null:
			_state = State.TRAVEL_TO_CHEST
		else:
			_deposit_resources()
			_pick_work_position()
			_state = State.TRAVEL_TO_WORK


func _do_travel_to_chest(delta: float) -> void:
	if _chest_node == null:
		_state = State.TRAVEL_TO_WORK
		return
	var dist: float = _owner_npc.global_position.distance_to(_chest_node.global_position)
	if dist < 12.0:
		_owner_npc.velocity = Vector2.ZERO
		_state = State.DEPOSIT
		return
	var dir: Vector2 = (_chest_node.global_position - _owner_npc.global_position).normalized()
	_owner_npc.velocity = dir * travel_speed
	_owner_npc.move_and_slide()


func _do_deposit() -> void:
	_deposit_resources()
	_pick_work_position()
	_state = State.TRAVEL_TO_WORK


func _deposit_resources() -> void:
	if _chest_node == null or not _chest_node.has_method("deposit"):
		return
	var yields: Dictionary = JOB_YIELDS.get(job, {})
	for resource in yields:
		_chest_node.deposit(resource, yields[resource])
