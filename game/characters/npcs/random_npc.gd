# random_npc.gd
class_name RandomNpc
extends CharacterBody2D

const COLOR_MALE:    Color = Color(0.25, 0.50, 1.00)
const COLOR_FEMALE:  Color = Color(1.00, 0.45, 0.70)
const COLOR_MONSTER: Color = Color(0.10, 0.75, 0.20)
const COLOR_DEAD:    Color = Color(0.30, 0.30, 0.30)
const COLOR_HOSTILE: Color = Color(0.90, 0.15, 0.10)
const COLOR_WORKER:  Color = Color(0.90, 0.75, 0.20)

const DETECT_RANGE:    float = 120.0
const ATTACK_RANGE:    float = 32.0

signal interaction_requested(npc: Node)
signal npc_defeated(npc: Node)
signal npc_captured(npc: Node)
signal npc_recruited(npc: Node)

var data:       NpcData = null
var npc_name:   String  = ""
var npc_gender: String  = "male"
var strength:   int     = 5
var max_hp:     int     = 30
var current_hp: int     = 30
var is_hostile: bool    = false
var speed:      float   = 60.0

# État recrutement/capture (0=libre, 1=compagnon, 2=esclave)
var _npc_state: int = 0

var _pending_randomize: bool = false
var _pending_seed:      int  = -1
var _player_near:       bool = false

@onready var _appearance:       Node      = $CharacterAppearance
@onready var _name_label:       Label     = $NameLabel
@onready var _color_rect:       ColorRect = $ColorRect
@onready var _interaction_area: Area2D    = $InteractionArea
@onready var _sm:               NpcStateMachine = $NpcStateMachine


func _ready() -> void:
	current_hp = max_hp
	add_to_group("npc")
	_interaction_area.body_entered.connect(_on_player_enter)
	_interaction_area.body_exited.connect(_on_player_exit)
	_sm.init(self)
	_sm.state_changed.connect(_on_state_changed)
	if _pending_randomize:
		_do_randomize(_pending_seed)
	_sm.transition("idle")
	_update_color()


func _physics_process(delta: float) -> void:
	if _sm.is_state("dead") or _sm.is_state("work"):
		if _sm.is_state("work"):
			_sm.update(delta)
		return
	_sm.update(delta)


# ─── Apparence ────────────────────────────────────────────────────────────────

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
	_update_color()


func _gender_from_archetype(arch: int) -> String:
	if arch == NpcData.Archetype.BANDIT and randf() < 0.3:
		return "monster"
	return ["male", "female"].pick_random()


func set_appearance(adat: Dictionary) -> void:
	if _appearance:
		_appearance.apply_appearance_data(adat)
	if adat.has("name") and _name_label:
		npc_name = adat["name"]
		_name_label.text = npc_name
	if adat.has("gender"):
		npc_gender = adat["gender"]
		_update_color()


func _update_color() -> void:
	if _color_rect == null:
		return
	match _sm.get_current():
		"combat": _color_rect.color = COLOR_HOSTILE
		"work":   _color_rect.color = COLOR_WORKER
		"dead":   _color_rect.color = COLOR_DEAD
		_:
			match npc_gender:
				"female":  _color_rect.color = COLOR_FEMALE
				"monster": _color_rect.color = COLOR_MONSTER
				_:         _color_rect.color = COLOR_MALE


func _on_state_changed(_from: String, _to: String) -> void:
	_update_color()


# ─── Combat / Vie ─────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if _sm.is_state("dead"):
		return
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		die()


func die() -> void:
	_sm.transition("dead")
	npc_defeated.emit(self)
	await get_tree().create_timer(3.0).timeout
	queue_free()


# ─── Interaction ──────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _player_near and not _sm.is_state("dead") and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interaction_requested.emit(self)
		_open_interaction_menu()


func _open_interaction_menu() -> void:
	var menu_scene: PackedScene = load("res://game/systems/npc_interaction_menu.tscn")
	if menu_scene == null:
		push_error("RandomNpc: npc_interaction_menu.tscn introuvable")
		return
	var menu: Node = menu_scene.instantiate()
	get_tree().current_scene.add_child(menu)
	menu.open(self)


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


# ─── Recrutement / Capture ────────────────────────────────────────────────────

func recruit() -> void:
	_npc_state = 1
	is_hostile = false
	var entry: Dictionary = _build_kingdom_entry("companion")
	if Engine.has_singleton("CompanionManager"):
		Engine.get_singleton("CompanionManager").call("add_companion", entry)
	npc_recruited.emit(self)
	_start_working("woodcutter")
	_add_relation_component()


func capture() -> void:
	_npc_state = 2
	is_hostile = false
	var entry: Dictionary = _build_kingdom_entry("slave")
	if Engine.has_singleton("CompanionManager"):
		Engine.get_singleton("CompanionManager").call("add_slave", entry)
	npc_captured.emit(self)
	_start_working("woodcutter")
	_add_relation_component()


func _start_working(initial_job: String) -> void:
	_sm.transition("work")
	var worker_script: Script = load("res://game/characters/npcs/worker_ai.gd")
	if worker_script == null:
		push_error("RandomNpc: worker_ai.gd introuvable")
		return
	var old: Node = get_node_or_null("WorkerAI")
	if old:
		old.queue_free()
	var worker: Node = Node.new()
	worker.set_script(worker_script)
	worker.set_name("WorkerAI")
	worker.set("job", initial_job)
	add_child(worker)
	print("[RandomNpc] WorkerAI créé pour ", npc_name, " avec job=", initial_job)


func change_job(new_job: String) -> void:
	var w: Node = get_node_or_null("WorkerAI")
	if w != null:
		w.update_job(new_job)
	print("[RandomNpc] %s -> métier : %s" % [npc_name, new_job])


func get_worker_ai() -> Node:
	return get_node_or_null("WorkerAI")


func _add_relation_component() -> void:
	var existing: Node = get_node_or_null("RelationComponent")
	if existing:
		return
	var rel_script: Script = load("res://game/characters/npcs/npc_relation.gd")
	if rel_script == null:
		push_error("random_npc: npc_relation.gd introuvable")
		return
	var rel: Node = Node.new()
	rel.set_script(rel_script)
	rel.set_name("RelationComponent")
	add_child(rel)
	rel.randomize_mood()


func _build_kingdom_entry(role: String) -> Dictionary:
	var entry: Dictionary = {
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
			"farming":     data.stats.skill_farming,
			"woodcutting": data.stats.skill_woodcutting,
			"mining":      data.stats.skill_mining,
			"crafting":    data.stats.skill_crafting,
			"combat":      data.stats.skill_combat,
			"trading":     data.stats.skill_trading,
		}
	return entry
