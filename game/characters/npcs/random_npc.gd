# random_npc.gd
extends CharacterBody2D

signal interaction_requested(npc)
signal npc_defeated(npc)
signal npc_captured(npc)
signal npc_recruited(npc)

enum AiState { IDLE, WANDER, FLEE, CHASE, DEAD, WORKING }

const COLOR_MALE    := Color(0.25, 0.50, 1.00)
const COLOR_FEMALE  := Color(1.00, 0.45, 0.70)
const COLOR_MONSTER := Color(0.10, 0.75, 0.20)
const COLOR_DEAD    := Color(0.30, 0.30, 0.30)
const COLOR_HOSTILE := Color(0.90, 0.15, 0.10)
const COLOR_WORKER  := Color(0.90, 0.75, 0.20)
const DETECT_RANGE    := 120.0
const ATTACK_RANGE    := 32.0
const ATTACK_COOLDOWN := 1.5

var data: NpcData = null
var npc_name:   String = ""
var npc_gender: String = "male"
var strength:   int    = 5
var max_hp:     int    = 30
var current_hp: int    = 30
var is_hostile: bool   = false
var speed:      float  = 60.0
var state:      int    = 0
var _ai: AiState = AiState.IDLE
var _wander_timer: float   = 2.0
var _wander_dir:   Vector2 = Vector2.ZERO
var _target:       Node2D  = null
var _attack_timer: float = 0.0
var _pending_randomize: bool = false
var _pending_seed:      int  = -1
var _player_near: bool = false

@onready var _appearance:       Node      = $CharacterAppearance
@onready var _name_label:       Label     = $NameLabel
@onready var _color_rect:       ColorRect = $ColorRect
@onready var _interaction_area: Area2D    = $InteractionArea


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
		_pending_seed      = seed_val
		return
	_do_randomize(seed_val)


func _do_randomize(seed_val: int) -> void:
	_pending_randomize = false
	if seed_val >= 0:
		seed(seed_val)
	data       = NpcData.generate_random()
	npc_name   = data.npc_name
	npc_gender = _gender_from_archetype(data.archetype)
	strength   = data.stats.force
	max_hp     = data.stats.max_hp
	current_hp = max_hp
	is_hostile = data.archetype == NpcData.Archetype.BANDIT or randf() < 0.2
	speed      = randf_range(40.0, 90.0)
	if _appearance:
		_appearance.randomize_appearance()
		var adat: Dictionary = _appearance.get_appearance_data()
		npc_gender = adat.get("gender", npc_gender)
	if _name_label:
		_name_label.text = npc_name
	_update_color_rect()


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
		"female":  _color_rect.color = COLOR_FEMALE
		"monster": _color_rect.color = COLOR_MONSTER
		_:         _color_rect.color = COLOR_MALE


func _physics_process(delta: float) -> void:
	if _ai == AiState.DEAD:
		return
	if _ai == AiState.WORKING:
		return
	_attack_timer = max(0.0, _attack_timer - delta)
	_update_ai(delta)


func _update_ai(delta: float) -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
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
				var dir: Vector2 = (
					global_position - _target.global_position
				).normalized()
				velocity = dir * speed * 1.3
				_update_facing()
				move_and_slide()
		AiState.CHASE:
			if _target != null:
				var dir: Vector2 = (
					_target.global_position - global_position
				).normalized()
				velocity = dir * speed * 1.1
				_update_facing()
				move_and_slide()
				if dist < ATTACK_RANGE and _attack_timer <= 0.0:
					_melee_attack()


func _melee_attack() -> void:
	_attack_timer = ATTACK_COOLDOWN
	var dmg: int = max(1, int(float(strength) / 3.0))
	if _target != null and _target.has_method("take_damage"):
		_target.take_damage(dmg)


func _unhandled_input(event: InputEvent) -> void:
	if _player_near and _ai != AiState.DEAD and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interaction_requested.emit(self)
		_open_interaction_menu()


func _open_interaction_menu() -> void:
	var menu_scene: PackedScene = load(
		"res://game/systems/npc_interaction_menu.tscn"
	)
	if menu_scene == null:
		push_error("RandomNpc: npc_interaction_menu.tscn introuvable")
		return
	var menu: Node = menu_scene.instantiate()
	get_tree().current_scene.add_child(menu)
	menu.open(self)


func take_damage(amount: int) -> void:
	if _ai == AiState.DEAD:
		return
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		die()


func die() -> void:
	_ai = AiState.DEAD
	velocity = Vector2.ZERO
	if _appearance:
		_appearance.set_eye_style("closed")
	if _color_rect:
		_color_rect.color = COLOR_DEAD
	npc_defeated.emit(self)
	await get_tree().create_timer(3.0).timeout
	queue_free()


func recruit() -> void:
	state = 1
	is_hostile = false
	var entry: Dictionary = _build_kingdom_entry("companion")
	if PopulationManager != null:
		PopulationManager.add_companion(entry)
	npc_recruited.emit(self)
	_start_working("woodcutter")
	_add_relation_component()


func capture() -> void:
	state = 2
	is_hostile = false
	var entry: Dictionary = _build_kingdom_entry("slave")
	if PopulationManager != null:
		PopulationManager.add_slave(entry)
	npc_captured.emit(self)
	_start_working("woodcutter")
	_add_relation_component()


func _add_relation_component() -> void:
	var existing = get_node_or_null("RelationComponent")
	if existing:
		return
	var rel_script: Script = load(
		"res://game/characters/npcs/npc_relation.gd"
	)
	if rel_script == null:
		push_error("random_npc: npc_relation.gd introuvable")
		return
	var rel: Node = Node.new()
	rel.set_script(rel_script)
	rel.set_name("RelationComponent")
	add_child(rel)
	rel.randomize_mood()


func _start_working(initial_job: String) -> void:
	_ai = AiState.WORKING
	_update_color_rect()
	var worker_script: Script = load(
		"res://game/characters/npcs/worker_ai.gd"
	)
	if worker_script == null:
		push_error("RandomNpc: worker_ai.gd introuvable")
		return
	var old = get_node_or_null("WorkerAI")
	if old:
		old.queue_free()
	var worker: Node = Node.new()
	worker.set_script(worker_script)
	worker.set_name("WorkerAI")
	worker.job = initial_job
	add_child(worker)
	print("[RandomNpc] WorkerAI cree pour ", npc_name, " avec job=", initial_job)


func get_worker_ai() -> Node:
	return get_node_or_null("WorkerAI")


func change_job(new_job: String) -> void:
	var w = get_worker_ai()
	if w != null:
		w.update_job(new_job)
	print("[RandomNpc] %s -> metier : %s" % [npc_name, new_job])


func _build_kingdom_entry(role: String) -> Dictionary:
	var entry: Dictionary = {
		"name": npc_name,
		"gender": npc_gender,
		"role": role,
		"job": "",
		"strength": strength,
		"max_hp": max_hp,
		"archetype": "",
		"skills": {},
		"happiness": 100,
	}
	if data != null:
		entry["archetype"] = NpcData.Archetype.keys()[data.archetype]
		entry["skills"] = {
			"farming":     data.stats.skill_farming,
			"woodcutting": data.stats.skill_woodcutting,
			"mining":      data.stats.skill_mining,
			"combat":      data.stats.skill_combat,
			"trading":     data.stats.skill_trading,
		}
	return entry


func set_appearance(adat: Dictionary) -> void:
	if _appearance:
		_appearance.apply_appearance_data(adat)
	if adat.has("name") and _name_label:
		npc_name = adat["name"]
		_name_label.text = npc_name
	if adat.has("gender"):
		npc_gender = adat["gender"]
		_update_color_rect()


func _on_player_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		if _name_label:
			_name_label.visible = true


func _on_player_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		if _name_label:
			_name_label.visible = false


func _pick_wander_dir() -> void:
	if randf() < 0.4:
		_ai = AiState.IDLE
		_wander_timer = randf_range(1.5, 3.0)
		return
	_ai = AiState.WANDER
	var angle: float = randf() * TAU
	_wander_dir = Vector2(cos(angle), sin(angle))
	_wander_timer = randf_range(0.8, 2.5)


func _update_facing() -> void:
	if velocity.length() < 5.0:
		return
	var dominant: String
	if abs(velocity.x) > abs(velocity.y):
		dominant = "right" if velocity.x > 0 else "left"
	else:
		dominant = "down" if velocity.y > 0 else "up"
	if _appearance:
		_appearance.set_direction(dominant)
		var f: int = (Engine.get_process_frames() >> 3) % 4 + 1
		_appearance.set_walk_frame(f)
