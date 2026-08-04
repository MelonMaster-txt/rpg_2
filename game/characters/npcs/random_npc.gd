# random_npc.gd
# NPC générique rencontrable dans la forêt.
# Utilise NpcData pour l'archetype, les stats et les dialogues.
extends CharacterBody2D

signal interaction_requested(npc)
signal npc_defeated(npc)
signal npc_captured(npc)
signal npc_recruited(npc)

# ─── Données NpcData (archetype, stats, dialogues) ────────────────────────────
var data: NpcData = null

# Propriétés directes (rétro-compat npc_interaction_menu)
var npc_name:   String = ""
var npc_gender: String = "male"
var strength:   int    = 5
var max_hp:     int    = 30
var current_hp: int    = 30
var is_hostile: bool   = false
var speed:      float  = 60.0
var state:      int    = 0  # 0=LIBRE 1=COMPAGNON 2=ESCLAVE

@onready var _appearance:     Node      = $CharacterAppearance
@onready var _name_label:     Label     = $NameLabel
@onready var _color_rect:     ColorRect = $ColorRect
@onready var _interaction_area: Area2D  = $InteractionArea

const COLOR_MALE    := Color(0.25, 0.50, 1.00)
const COLOR_FEMALE  := Color(1.00, 0.45, 0.70)
const COLOR_MONSTER := Color(0.10, 0.75, 0.20)
const COLOR_DEAD    := Color(0.30, 0.30, 0.30)
const COLOR_HOSTILE := Color(0.90, 0.15, 0.10)

# ─── Etats IA ────────────────────────────────────────────────────────────────
enum AiState { IDLE, WANDER, FLEE, CHASE, DEAD }
var _ai: AiState = AiState.IDLE
var _wander_timer: float   = 2.0
var _wander_dir:   Vector2 = Vector2.ZERO
var _target:       Node    = null
const DETECT_RANGE  := 120.0
const ATTACK_RANGE  := 32.0
const ATTACK_COOLDOWN := 1.5
var _attack_timer: float = 0.0

# Pending randomize (si appelé avant _ready)
var _pending_randomize: bool = false
var _pending_seed:      int  = -1

# ─── Cycle de vie ────────────────────────────────────────────────────────────

func _ready() -> void:
	current_hp = max_hp
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
	# Générer NpcData complet
	data = NpcData.generate_random()
	npc_name   = data.npc_name
	npc_gender = _gender_from_archetype(data.archetype)
	strength   = data.stats.force
	max_hp     = data.stats.max_hp if data.stats.get("max_hp") != null else randi_range(20, 60)
	current_hp = max_hp
	is_hostile = data.archetype == NpcData.Archetype.BANDIT or randf() < 0.2
	speed      = randf_range(40.0, 90.0)
	# Apparence
	if _appearance:
		_appearance.randomize_appearance()
		var adat: Dictionary = _appearance.get_appearance_data()
		npc_gender = adat.get("gender", npc_gender)
	if _name_label:
		_name_label.text = npc_name
	_update_color_rect()


func _gender_from_archetype(arch: int) -> String:
	# Les monstres ont un genre "monster" visuellement
	if arch == NpcData.Archetype.BANDIT and randf() < 0.3:
		return "monster"
	return ["male", "female"].pick_random()


func _update_color_rect() -> void:
	if _color_rect == null:
		return
	if _ai == AiState.CHASE:
		_color_rect.color = COLOR_HOSTILE
		return
	match npc_gender:
		"female":  _color_rect.color = COLOR_FEMALE
		"monster": _color_rect.color = COLOR_MONSTER
		_:         _color_rect.color = COLOR_MALE

# ─── Physique & IA ────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _ai == AiState.DEAD:
		velocity = Vector2.ZERO
		return
	_attack_timer = max(0.0, _attack_timer - delta)
	_update_ai(delta)


func _update_ai(delta: float) -> void:
	# Détecter le joueur
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0]
	var dist := INF
	if _target:
		dist = global_position.distance_to(_target.global_position)

	# Transitions selon hostilité
	if is_hostile and _target != null:
		if dist < DETECT_RANGE and _ai not in [AiState.CHASE, AiState.FLEE]:
			_ai = AiState.CHASE
			_update_color_rect()
		elif dist > DETECT_RANGE * 1.5:
			_ai = AiState.WANDER
			_update_color_rect()
	else:
		if dist < DETECT_RANGE * 0.6 and _ai != AiState.FLEE:
			_ai = AiState.FLEE  # NPC pacifique fuit si trop proche
		elif dist > DETECT_RANGE and _ai == AiState.FLEE:
			_ai = AiState.WANDER

	# Actions IA
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
			if _target:
				var dir := (global_position - _target.global_position).normalized()
				velocity = dir * speed * 1.3
				_update_facing()
				move_and_slide()
		AiState.CHASE:
			if _target:
				var dir := (_target.global_position - global_position).normalized()
				velocity = dir * speed * 1.1
				_update_facing()
				move_and_slide()
				# Attaque au corps à corps
				if dist < ATTACK_RANGE and _attack_timer <= 0.0:
					_melee_attack()


func _melee_attack() -> void:
	_attack_timer = ATTACK_COOLDOWN
	var dmg := max(1, strength / 3)
	if _target and _target.has_method("take_damage"):
		_target.take_damage(dmg)

# ─── Interaction joueur ───────────────────────────────────────────────────────

var _player_near: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_near and _ai != AiState.DEAD and event.is_action_pressed("interact"):
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

# ─── Combat (externe) ─────────────────────────────────────────────────────────

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


# ─── Recrutement / Capture ────────────────────────────────────────────────────

func recruit() -> void:
	state = 1  # COMPAGNON
	is_hostile = false
	_ai = AiState.IDLE
	_update_color_rect()
	var entry := _build_kingdom_entry("companion")
	CompanionManager.add_companion(entry)
	npc_recruited.emit(self)
	queue_free()


func capture() -> void:
	state = 2  # ESCLAVE
	is_hostile = false
	_ai = AiState.DEAD  # Immobilisé
	if _color_rect:
		_color_rect.color = COLOR_DEAD
	var entry := _build_kingdom_entry("slave")
	CompanionManager.add_slave(entry)
	npc_captured.emit(self)
	queue_free()


func _build_kingdom_entry(role: String) -> Dictionary:
	var entry := {
		"name":      npc_name,
		"gender":    npc_gender,
		"role":      role,
		"job":       "",
		"strength":  strength,
		"max_hp":    max_hp,
		"archetype": "",
		"skills":    {},
		"happiness": 100,
	}
	if data != null:
		entry["archetype"] = NpcData.Archetype.keys()[data.archetype]
		entry["skills"] = {
			"farming":     data.stats.get("skill_farming")    if data.stats.get("skill_farming")    != null else 0,
			"woodcutting": data.stats.get("skill_woodcutting") if data.stats.get("skill_woodcutting") != null else 0,
			"mining":      data.stats.get("skill_mining")      if data.stats.get("skill_mining")      != null else 0,
			"combat":      data.stats.get("skill_combat")      if data.stats.get("skill_combat")      != null else 0,
			"trading":     data.stats.get("skill_trading")     if data.stats.get("skill_trading")     != null else 0,
		}
	return entry


# ─── Helpers ─────────────────────────────────────────────────────────────────

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
	var angle := randf() * TAU
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
