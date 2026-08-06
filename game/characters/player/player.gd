extends CharacterBody2D

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal interacted_with_npc(npc: Node)
signal player_died

# ─── CONSTS ───────────────────────────────────────────────────────────────────
const SPEED: float = 120.0
const SPRINT_MULT: float = 1.6
const ROLL_SPEED: float = 200.0
const ROLL_DURATION: float = 0.35
const INTERACT_RADIUS: float = 40.0

# ─── EXPORTS ──────────────────────────────────────────────────────────────────
@export var interact_area: Area2D = null

# ─── ONREADY ──────────────────────────────────────────────────────────────────
@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _interact_hint: Label = $InteractHint

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _roll_timer: float = 0.0
var _is_rolling: bool = false
var _roll_dir: Vector2 = Vector2.ZERO
var _nearby_npc: Node = null
var _facing: Vector2 = Vector2.DOWN

func _ready() -> void:
	if _interact_hint:
		_interact_hint.visible = false
	if GameManager.has_saved_position:
		global_position = GameManager.consume_spawn_position()

func _physics_process(delta: float) -> void:
	if _is_rolling:
		_process_roll(delta)
		return
	_process_move(delta)
	_process_interact()

func _process_move(delta: float) -> void:
	var dir: Vector2 = Input.get_vector(
			"move_left", "move_right", "move_up", "move_down"
	)
	if dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		_play_anim("idle")
		return
	_facing = dir
	var spd: float = SPEED
	if Input.is_action_pressed("sprint"):
		spd *= SPRINT_MULT
	velocity = dir * spd
	_play_anim("walk")
	move_and_slide()
	if Input.is_action_just_pressed("roll"):
		_start_roll(dir)

func _start_roll(dir: Vector2) -> void:
	_is_rolling = true
	_roll_timer = ROLL_DURATION
	_roll_dir = dir.normalized()
	_play_anim("roll")

func _process_roll(delta: float) -> void:
	_roll_timer -= delta
	if _roll_timer <= 0.0:
		_is_rolling = false
		return
	velocity = _roll_dir * ROLL_SPEED
	move_and_slide()

func _process_interact() -> void:
	if _nearby_npc == null:
		return
	if Input.is_action_just_pressed("interact"):
		interacted_with_npc.emit(_nearby_npc)

func _play_anim(anim: String) -> void:
	if _anim and _anim.sprite_frames and _anim.sprite_frames.has_animation(anim):
		if _anim.animation != anim:
			_anim.play(anim)

func set_nearby_npc(npc: Node) -> void:
	_nearby_npc = npc
	if _interact_hint:
		_interact_hint.visible = npc != null

func take_damage(amount: int) -> void:
	GameManager.life -= amount
	if GameManager.life <= 0:
		GameManager.life = 0
		GameManager.stats_changed.emit()
		player_died.emit()
		return
	GameManager.stats_changed.emit()
