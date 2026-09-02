extends CharacterBody2D

signal interaction_requested(npc: Node)
signal npc_defeated(npc: Node)
signal npc_captured(npc: Node)
signal npc_recruited(npc: Node)

enum AiState { IDLE, WANDER, FLEE, CHASE, DEAD, WORKING }

const COLOR_MALE: Color = Color(0.25, 0.50, 1.00)
const COLOR_FEMALE: Color = Color(1.00, 0.45, 0.70)
const COLOR_MONSTER: Color = Color(0.10, 0.75, 0.20)
const COLOR_DEAD: Color = Color(0.30, 0.30, 0.30)
const COLOR_HOSTILE: Color = Color(0.90, 0.15, 0.10)
const COLOR_WORKER: Color = Color(0.90, 0.75, 0.20)
const DETECT_RANGE: float = 120.0
const ATTACK_RANGE: float = 32.0
const ATTACK_COOLDOWN: float = 1.5

var data: NpcData = null
var npc_name: String = ""
var npc_gender: String = "male"
var strength: int = 5
var max_hp: int = 30
var current_hp: int = 30
var is_hostile: bool = false
var speed: float = 60.0
var _ai: AiState = AiState.IDLE
var _wander_timer: float = 2.0
var _wander_dir: Vector2 = Vector2.ZERO
var _target: Node2D = null
var _attack_timer: float = 0.0
var _pending_randomize: bool = false
var _pending_seed: int = -1
var _player_near: bool = false
# FIX : garde pour éviter d'ouvrir deux menus en même temps
var _interaction_menu_open: bool = false

@onready var _appearance: Node = $CharacterAppearance
@onready var _name_label: Label = $NameLabel
@onready var _color_rect: ColorRect = $ColorRect
@onready var _interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	current_hp = max_hp
	add_to_group("npc")
	_interaction_area.body_entered.connect(_on_player_enter)
	_interaction_area.body_exited.connect(_on_player_exit)
	if _pending_randomize:
		_do_randomize(_pending_seed)
	_update_color_rect()


func randomize_full(seed_val: int = -1) -> void:
	if not is_inside_tree() or _appearance == null:
		_pending_randomize = true
		_pending_seed = seed_val
		return
	_do_randomize(seed_val)


func _do_randomize(seed_val: int) -> void:
	_pending_randomize = false
	if seed_val >= 0:
		seed(seed_val)
	data = NpcData.generate_random()
	npc_name = data.npc_name
	npc_gender = _gender_from_archetype(data.archetype)
	strength = data.stats.force
	max_hp = data.stats.max_hp
	current_hp = max_hp
	is_hostile = data.archetype == NpcData.Archetype.BANDIT or randf() < 0.2
	speed = randf_range(40.0, 90.0)
	if _appearance:
		_appearance.randomize_appearance()
		var adat: Dictionary = _appearance.get_appearance_data()
		npc_gender = adat.get("gender", npc_gender)
	if _name_label:
		_name_label.text = npc_name
	_update_color_rect()


func set_appearance(appearance_data: Dictionary) -> void:
	if _appearance and _appearance.has_method("set_appearance_data"):
		_appearance.set_appearance_data(appearance_data)


func _gender_from_archetype(arch: int) -> String:
	if arch == NpcData.Archetype.BANDIT and randf() < 0.3:
		return "monster"
	return ["male", "female"].pick_random()


func _update_color_rect() -> void:
	if _color_rect == null:
		return
	if _ai == AiState.CHASE:
		_color_rect.color = COLOR_HOSTILE
		return
	if _ai == AiState.WORKING:
		_color_rect.color = COLOR_WORKER
		return
	match npc_gender:
		"female":
			_color_rect.color = COLOR_FEMALE
		"monster":
			_color_rect.color = COLOR_MONSTER
		_:
			_color_rect.color = COLOR_MALE


func _physics_process(delta: float) -> void:
	if _ai == AiState.DEAD:
		return
	if _ai == AiState.WORKING:
		return
	_attack_timer = max(0.0, _attack_timer - delta)
	_update_ai(delta)


func _update_ai(delta: float) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0] as Node2D
	var dist: float = INF
	if _target != null:
		dist = global_position.distance_to(_target.global_position)
	if is_hostile and _target != null:
		if dist < DETECT_RANGE and _ai not in [AiState.CHASE, AiState.FLEE]:
			_ai = AiState.CHASE
			_update_color_rect()
		elif dist > DETECT_RANGE * 1.5:
			_ai = AiState.WANDER
			_update_color_rect()
	else:
		if dist < DETECT_RANGE * 0.6 and _ai != AiState.FLEE:
			_ai = AiState.FLEE
		elif dist > DETECT_RANGE and _ai == AiState.FLEE:
			_ai = AiState.WANDER
	match _ai:
		AiState.IDLE:
			velocity = Vector2.ZERO
			_wander_timer -= delta
			if _wander_timer <= 0.0:
				_pick_wander_dir()
		AiState.WANDER:
			_wander_timer -= delta
			velocity = _wander_dir * speed
			_update_facing()
			move_and_slide()
			if _wander_timer <= 0.0:
				_ai = AiState.IDLE
				velocity = Vector2.ZERO
		AiState.FLEE:
			if _target != null:
				var flee_dir: Vector2 = (
					global_position - _target.global_position
				).normalized()
				velocity = flee_dir * speed * 1.3
				_update_facing()
				move_and_slide()
		AiState.CHASE:
			if _target != null:
				var chase_dir: Vector2 = (
					_target.global_position - global_position
				).normalized()
				velocity = chase_dir * speed * 1.1
				_update_facing()
				move_and_slide()
				if dist < ATTACK_RANGE and _attack_timer <= 0.0:
					_melee_attack()


func _pick_wander_dir() -> void:
	_wander_timer = randf_range(2.0, 5.0)
	_wander_dir = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	_ai = AiState.WANDER


func _update_facing() -> void:
	pass


func _melee_attack() -> void:
	_attack_timer = ATTACK_COOLDOWN
	var dmg: int = max(1, int(float(strength) / 3.0))
	if _target != null and _target.has_method("take_damage"):
		_target.take_damage(dmg)


func _unhandled_key_input(event: InputEvent) -> void:
	# FIX : ne pas ouvrir le menu si déjà ouvert ou si NPC mort
	if _player_near and _ai != AiState.DEAD and not _interaction_menu_open and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interaction_requested.emit(self)
		_open_interaction_menu()


func _open_interaction_menu() -> void:
	if _interaction_menu_open:
		return
	var menu_scene: PackedScene = load(
		"res://game/systems/npc_interaction_menu.tscn"
	)
	if menu_scene == null:
		push_error("RandomNpc: npc_interaction_menu.tscn introuvable")
		return
	var menu: Node = menu_scene.instantiate()
	get_tree().current_scene.add_child(menu)
	menu.open(self)
	_interaction_menu_open = true
	# FIX : réinitialiser le flag quand le menu se ferme (via tree_exited)
	menu.tree_exited.connect(func() -> void: _interaction_menu_open = false)


func take_damage(amount: int) -> void:
	if _ai == AiState.DEAD:
		return
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		die()


func die() -> void:
	_ai = AiState.DEAD
	_update_color_rect()
	npc_defeated.emit(self)
	queue_free()


func capture() -> void:
	var entry: Dictionary = {
		"name": npc_name,
		"archetype": data.archetype if data != null else 0,
		"strength": strength,
		"max_hp": max_hp,
	}
	npc_captured.emit(self)
	var pm: Node = get_node_or_null("/root/PopulationManager")
	if pm == null:
		var nodes: Array[Node] = get_tree().get_nodes_in_group("population_manager")
		if nodes.size() > 0:
			pm = nodes[0]
	if pm != null and pm.has_method("add_slave"):
		pm.add_slave(entry)
	queue_free()


func recruit() -> void:
	var entry: Dictionary = {
		"name": npc_name,
		"archetype": data.archetype if data != null else 0,
		"strength": strength,
		"max_hp": max_hp,
	}
	npc_recruited.emit(self)
	var pm: Node = get_node_or_null("/root/PopulationManager")
	if pm == null:
		var nodes: Array[Node] = get_tree().get_nodes_in_group("population_manager")
		if nodes.size() > 0:
			pm = nodes[0]
	if pm != null and pm.has_method("add_companion"):
		pm.add_companion(entry)
	queue_free()


func _on_player_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true


func _on_player_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
