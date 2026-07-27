# random_npc.gd
extends CharacterBody2D

signal interaction_requested(npc)
signal npc_defeated(npc)
signal npc_captured(npc)

@export var npc_name:    String = ""
@export var max_hp:      int    = 30
@export var strength:    int    = 5
@export var speed:       float  = 60.0
@export var is_hostile:  bool   = false

var current_hp:   int
var _appearance:  Node
var _name_label:  Label
var _player_near: bool   = false
var _state:       String = "idle"

const NAMES_MALE   := ["Bjorn","Ulf","Ragnar","Gunnar","Leif","Sigurd","Erik","Ivar"]
const NAMES_FEMALE := ["Astrid","Freya","Sigrid","Hilde","Runa","Ylva","Ingrid","Solveig"]

var _wander_timer: float  = 2.0
var _wander_dir:   Vector2 = Vector2.ZERO

var _pending_randomize: bool = false
var _pending_seed:      int  = -1


func _ready() -> void:
	current_hp  = max_hp
	_appearance = $CharacterAppearance
	_name_label = $NameLabel
	$InteractionArea.body_entered.connect(_on_player_enter)
	$InteractionArea.body_exited.connect(_on_player_exit)
	if _pending_randomize:
		_do_randomize(_pending_seed)


func randomize_full(seed_val: int = -1) -> void:
	if not is_inside_tree() or _appearance == null:
		_pending_randomize = true
		_pending_seed      = seed_val
		return
	_do_randomize(seed_val)


func _do_randomize(seed_val: int) -> void:
	_pending_randomize = false
	if seed_val >= 0:
		seed(seed_val)
	_appearance.randomize_appearance()
	var gender: String = _appearance.get_appearance_data().get("gender", "male")
	if npc_name == "":
		npc_name = NAMES_MALE.pick_random() if gender == "male" else NAMES_FEMALE.pick_random()
	if _name_label:
		_name_label.text = npc_name
	max_hp     = randi_range(20, 60)
	strength   = randi_range(3, 12)
	speed      = randf_range(40.0, 90.0)
	is_hostile = randf() < 0.25
	current_hp = max_hp


func set_appearance(data: Dictionary) -> void:
	if _appearance:
		_appearance.apply_appearance_data(data)
	if data.has("name") and _name_label:
		npc_name = data["name"]
		_name_label.text = npc_name


func _physics_process(delta: float) -> void:
	match _state:
		"idle":
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_pick_wander_dir()
		"wander":
			_wander_timer -= delta
			velocity = _wander_dir * speed
			_update_facing()
			move_and_slide()
			if _wander_timer <= 0.0:
				_state = "idle"
				velocity = Vector2.ZERO
				if _appearance:
					_appearance.set_walk_frame(0)
		"dead":
			velocity = Vector2.ZERO


func take_damage(amount: int) -> void:
	if _state == "dead": return
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		_die()


func _die() -> void:
	_state = "dead"
	if _appearance:
		_appearance.set_eye_style("closed")
	npc_defeated.emit(self)


func capture() -> Dictionary:
	var data: Dictionary = _appearance.get_appearance_data() if _appearance else {}
	data["name"]     = npc_name
	data["strength"] = strength
	data["max_hp"]   = max_hp
	npc_captured.emit(self)
	return data


func _unhandled_input(event: InputEvent) -> void:
	if _player_near and event.is_action_pressed("interact") and _state != "dead":
		interaction_requested.emit(self)


func _on_player_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		if _name_label: _name_label.visible = true


func _on_player_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		if _name_label: _name_label.visible = false


func _pick_wander_dir() -> void:
	if randf() < 0.4:
		_state = "idle"
		_wander_timer = randf_range(1.5, 3.0)
		return
	_state = "wander"
	var angle := randf() * TAU
	_wander_dir = Vector2(cos(angle), sin(angle))
	_wander_timer = randf_range(0.8, 2.5)


func _update_facing() -> void:
	if velocity.length() < 5.0: return
	var dominant: String
	if abs(velocity.x) > abs(velocity.y):
		dominant = "right" if velocity.x > 0 else "left"
	else:
		dominant = "down" if velocity.y > 0 else "up"
	if _appearance:
		_appearance.set_direction(dominant)
		# Correction integer division : forcer le cast float
		var f: int = (Engine.get_process_frames() / 8) % 4 + 1
		_appearance.set_walk_frame(f)
