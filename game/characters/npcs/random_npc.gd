# random_npc.gd
# NPC generique rencontrable dans la foret.
extends CharacterBody2D

signal interaction_requested(npc)
signal npc_defeated(npc)
signal npc_captured(npc)

@export var npc_name:    String = ""
@export var max_hp:      int    = 30
@export var strength:    int    = 5
@export var speed:       float  = 60.0
@export var is_hostile:  bool   = false
# "male", "female", "monster"
@export var npc_gender:  String = "male"

var current_hp:   int
var _appearance:  Node
var _name_label:  Label
var _color_rect:  ColorRect
var _player_near: bool   = false
var _state:       String = "idle"

const NAMES_MALE    := ["Bjorn","Ulf","Ragnar","Gunnar","Leif","Sigurd","Erik","Ivar"]
const NAMES_FEMALE  := ["Astrid","Freya","Sigrid","Hilde","Runa","Ylva","Ingrid","Solveig"]
const NAMES_MONSTER := ["Grak","Urgh","Morgh","Skral","Vroth","Drak","Krull","Zogg"]

# Couleur selon genre
const COLOR_MALE    := Color(0.25, 0.50, 1.00)  # bleu   = homme
const COLOR_FEMALE  := Color(1.00, 0.45, 0.70)  # rose   = femme
const COLOR_MONSTER := Color(0.10, 0.75, 0.20)  # vert   = monstre
const COLOR_DEAD    := Color(0.30, 0.30, 0.30)  # gris   = mort

var _wander_timer: float   = 2.0
var _wander_dir:   Vector2 = Vector2.ZERO

var _pending_randomize: bool = false
var _pending_seed:      int  = -1

func _ready() -> void:
	current_hp   = max_hp
	_appearance  = $CharacterAppearance
	_name_label  = $NameLabel
	_color_rect  = $ColorRect
	$InteractionArea.body_entered.connect(_on_player_enter)
	$InteractionArea.body_exited.connect(_on_player_exit)
	if _pending_randomize:
		_do_randomize(_pending_seed)
	_update_color_rect()


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
	# Recuperer le genre depuis l'apparence
	var appearance_data: Dictionary = _appearance.get_appearance_data()
	var gender: String = appearance_data.get("gender", "male")
	npc_gender = gender
	if npc_name == "":
		match npc_gender:
			"female":  npc_name = NAMES_FEMALE.pick_random()
			"monster": npc_name = NAMES_MONSTER.pick_random()
			_:         npc_name = NAMES_MALE.pick_random()
	if _name_label:
		_name_label.text = npc_name
	max_hp     = randi_range(20, 60)
	strength   = randi_range(3, 12)
	speed      = randf_range(40.0, 90.0)
	is_hostile = randf() < 0.25
	current_hp = max_hp
	_update_color_rect()


func _update_color_rect() -> void:
	if _color_rect == null:
		return
	match npc_gender:
		"female":  _color_rect.color = COLOR_FEMALE
		"monster": _color_rect.color = COLOR_MONSTER
		_:         _color_rect.color = COLOR_MALE


func set_appearance(data: Dictionary) -> void:
	if _appearance:
		_appearance.apply_appearance_data(data)
	if data.has("name") and _name_label:
		npc_name = data["name"]
		_name_label.text = npc_name
	if data.has("gender"):
		npc_gender = data["gender"]
		_update_color_rect()


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


# Interaction uniquement sur pression de E quand le joueur est proche
func _unhandled_input(event: InputEvent) -> void:
	if _player_near and _state != "dead" and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interaction_requested.emit(self)
		_open_interaction_menu()


func _open_interaction_menu() -> void:
	var menu_scene := load("res://game/systems/npc_interaction_menu.tscn")
	if menu_scene == null:
		push_error("RandomNpc: npc_interaction_menu.tscn introuvable")
		return
	var menu: Node = menu_scene.instantiate()
	get_tree().current_scene.add_child(menu)
	menu.open(self)


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
	if _color_rect:
		_color_rect.color = COLOR_DEAD
	npc_defeated.emit(self)


func capture() -> Dictionary:
	var data: Dictionary = _appearance.get_appearance_data() if _appearance else {}
	data["name"]     = npc_name
	data["strength"] = strength
	data["max_hp"]   = max_hp
	data["gender"]   = npc_gender
	npc_captured.emit(self)
	return data


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
		var f: int = (Engine.get_process_frames() >> 3) % 4 + 1
		_appearance.set_walk_frame(f)
