# npc_base.gd
# NPC vivant : wandering, etats, interaction avec le joueur
class_name NpcBase
extends CharacterBody2D

enum State { LIBRE, COMPAGNON, ESCLAVE }
enum Behaviour { WANDERING, IDLE, WORKING, FOLLOWING }

const INTERACTION_MENU_SCENE := "res://game/systems/npc_interaction_menu.tscn"

@export var data: NpcData = null

@onready var name_label: Label        = $NameLabel
@onready var interact_area: Area2D    = $InteractArea

var state: State         = State.LIBRE
var behaviour: Behaviour = Behaviour.WANDERING

var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float    = 0.0
var _idle_timer: float      = 0.0
var _move_speed: float      = 50.0
var _interaction_cooldown: float = 0.0

const WANDER_RADIUS   := 200.0
const WANDER_INTERVAL := 4.0
const IDLE_DURATION   := 2.0
const INTERACT_DIST   := 64.0

func _ready() -> void:
	add_to_group("npc")
	if data == null:
		data = NpcData.generate_random()
	_setup_visuals()
	_pick_wander_target()

	if interact_area:
		interact_area.body_entered.connect(_on_body_entered)

func _setup_visuals() -> void:
	if name_label:
		name_label.text = data.npc_name

func _physics_process(delta: float) -> void:
	if _interaction_cooldown > 0:
		_interaction_cooldown -= delta

	match behaviour:
		Behaviour.WANDERING: _process_wander(delta)
		Behaviour.IDLE:      _process_idle(delta)
		Behaviour.FOLLOWING: _process_follow(delta)
		Behaviour.WORKING:   pass

func _process_wander(delta: float) -> void:
	_wander_timer -= delta
	var dir := (_wander_target - global_position)
	if dir.length() < 8.0 or _wander_timer <= 0.0:
		behaviour = Behaviour.IDLE
		_idle_timer = IDLE_DURATION
		velocity = Vector2.ZERO
		return
	velocity = dir.normalized() * _move_speed
	move_and_slide()

func _process_idle(delta: float) -> void:
	_idle_timer -= delta
	velocity = Vector2.ZERO
	if _idle_timer <= 0.0:
		_pick_wander_target()
		behaviour = Behaviour.WANDERING

func _process_follow(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player: Node2D = players[0]
	var dir := (player.global_position - global_position)
	if dir.length() > 80.0:
		velocity = dir.normalized() * _move_speed * 1.2
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func _pick_wander_target() -> void:
	var angle := randf() * TAU
	var dist  := randf_range(40.0, WANDER_RADIUS)
	_wander_target  = global_position + Vector2(cos(angle), sin(angle)) * dist
	_wander_timer   = WANDER_INTERVAL

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and _interaction_cooldown <= 0:
		_open_interaction_menu()

func _open_interaction_menu() -> void:
	_interaction_cooldown = 1.5
	var menu_scene := load(INTERACTION_MENU_SCENE)
	if menu_scene == null:
		push_error("NpcBase: npc_interaction_menu.tscn introuvable")
		return
	var menu: Node = menu_scene.instantiate()
	get_tree().current_scene.add_child(menu)
	menu.open(self)

# ── API publique ───────────────────────────────────────────────────

func set_state(new_state: State) -> void:
	state = new_state
	match state:
		State.COMPAGNON:
			behaviour = Behaviour.FOLLOWING
			_move_speed = 60.0
		State.ESCLAVE:
			behaviour = Behaviour.WORKING
		State.LIBRE:
			behaviour = Behaviour.WANDERING
			_pick_wander_target()


func die() -> void:
	NpcSpawner.unregister(self)
	queue_free()

func capture() -> void:
	set_state(State.ESCLAVE)
	NpcSpawner.register_kingdom_npc(self)

func recruit() -> void:
	set_state(State.COMPAGNON)
	NpcSpawner.register_kingdom_npc(self)
