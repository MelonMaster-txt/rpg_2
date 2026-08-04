# worker_ai.gd
# IA travailleur : va d'arbre en arbre, remplit son inventaire, rentre au chunk (0,0) déposer.
extends Node

# ─── Config ──────────────────────────────────────────────────────────────────
var job:              String = "woodcutter"
var travel_speed:     float  = 55.0
var inventory_max:    int    = 8   # nombre de ressources avant de rentrer

# ─── Tables métier ───────────────────────────────────────────────────────────
const JOB_RESOURCE: Dictionary = {
	"woodcutter": "wood",
	"farmer":     "food",
	"miner":      "stone",
	"guard":      "",
	"trader":     "gold",
	"builder":    "build_points",
}
const JOB_HARVEST_TIME: Dictionary = {
	"woodcutter": 4.0,
	"farmer":     6.0,
	"miner":      5.0,
	"guard":      999.0,
	"trader":     8.0,
	"builder":    5.0,
}
const JOB_ICON: Dictionary = {
	"woodcutter": "🪓",
	"farmer":     "🌾",
	"miner":      "⛏️",
	"guard":      "🛡️",
	"trader":     "💰",
	"builder":    "🔨",
	"":            "💤",
}

# ─── Groupe des ressources cibles selon le métier ────────────────────────────
const JOB_TARGET_GROUP: Dictionary = {
	"woodcutter": "tree",
	"farmer":     "farm_tile",
	"miner":      "rock",
	"guard":      "",
	"trader":     "",
	"builder":    "",
}

# ─── État ────────────────────────────────────────────────────────────────────
enum State { IDLE, SEEK_TARGET, HARVEST, RETURN_HOME, DEPOSIT }
var _state:        State   = State.IDLE
var _target_node:  Node2D  = null   # arbre/tuile courant
var _chest_pos:    Vector2 = Vector2.ZERO   # position du coffre (chunk 0,0)
var _chest_node:   Node2D  = null
var _harvest_timer: float  = 0.0
var _inventory:    int     = 0      # nombre de ressources portées
var _owner_npc:    CharacterBody2D = null
var _job_label:    Label   = null
var _start_timer:  float   = 1.0   # délai avant premier cycle (évite race-condition _ready)

# ─── Init ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_owner_npc = get_parent() as CharacterBody2D
	if _owner_npc == null:
		push_error("WorkerAI: parent doit être CharacterBody2D")
		return
	_create_job_label()
	_state = State.IDLE


func _create_job_label() -> void:
	var existing = _owner_npc.get_node_or_null("JobLabel")
	if existing: existing.queue_free()
	_job_label = Label.new()
	_job_label.name = "JobLabel"
	_job_label.position = Vector2(-22, -52)
	_job_label.add_theme_font_size_override("font_size", 11)
	_update_label()
	_owner_npc.add_child(_job_label)


func _update_label() -> void:
	if _job_label == null: return
	var icon: String = JOB_ICON.get(job, "?")
	_job_label.text = "%s %d/%d" % [icon, _inventory, inventory_max]

# ─── Boucle principale ────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if _owner_npc == null: return

	# Délai de démarrage pour laisser le temps à l'arbre d'être en scène
	if _start_timer > 0.0:
		_start_timer -= delta
		return

	# Garde la référence du coffre à jour
	if _chest_node == null or not is_instance_valid(_chest_node):
		_find_chest()

	match _state:
		State.IDLE:         _on_idle()
		State.SEEK_TARGET:  _on_seek_target(delta)
		State.HARVEST:      _on_harvest(delta)
		State.RETURN_HOME:  _on_return_home(delta)
		State.DEPOSIT:      _on_deposit()

# ─── États ────────────────────────────────────────────────────────────────────

func _on_idle() -> void:
	if job == "" or job == "guard":
		_owner_npc.velocity = Vector2.ZERO
		return
	if _inventory >= inventory_max:
		_state = State.RETURN_HOME
	else:
		_target_node = _find_nearest_target()
		if _target_node != null:
			_state = State.SEEK_TARGET
		# Si aucune cible trouvée, on reste IDLE et on réessaie au prochain frame


func _on_seek_target(delta: float) -> void:
	if not is_instance_valid(_target_node):
		_target_node = null
		_state = State.IDLE
		return
	var dist: float = _owner_npc.global_position.distance_to(_target_node.global_position)
	if dist < 24.0:
		_owner_npc.velocity = Vector2.ZERO
		_harvest_timer = JOB_HARVEST_TIME.get(job, 4.0)
		_state = State.HARVEST
		return
	_move_toward(_target_node.global_position, delta)


func _on_harvest(delta: float) -> void:
	_owner_npc.velocity = Vector2.ZERO
	# Petit bounce visuel
	var t := Time.get_ticks_msec() * 0.005
	_owner_npc.position.y += sin(t * 10.0) * 0.25
	_harvest_timer -= delta
	if _harvest_timer > 0.0: return

	# Récolte
	var gained: int = 1
	if is_instance_valid(_target_node) and _target_node.has_method("harvest"):
		gained = _target_node.harvest(1)   # ResourceNode.harvest() retourne la quantité réelle
	_inventory += gained
	_update_label()

	# Notifier la relation
	_notify_favor()

	if _inventory >= inventory_max:
		_state = State.RETURN_HOME
	else:
		# Cherche un autre arbre
		var next = _find_nearest_target(_target_node)
		_target_node = next
		_state = State.SEEK_TARGET if _target_node != null else State.IDLE


func _on_return_home(_delta: float) -> void:
	if _chest_node == null or not is_instance_valid(_chest_node):
		_find_chest()
	if _chest_node == null:
		# Pas de coffre : on vide quand même l'inventaire virtuellement
		_inventory = 0
		_update_label()
		_state = State.IDLE
		return
	var dist: float = _owner_npc.global_position.distance_to(_chest_node.global_position)
	if dist < 30.0:
		_owner_npc.velocity = Vector2.ZERO
		_state = State.DEPOSIT
		return
	_move_toward(_chest_node.global_position, _delta)


func _on_deposit() -> void:
	var resource: String = JOB_RESOURCE.get(job, "")
	if resource != "" and _chest_node != null and _chest_node.has_method("deposit"):
		_chest_node.deposit(resource, _inventory)
		print("[WorkerAI] %s dépose %d %s" % [_owner_npc.get("npc_name"), _inventory, resource])
	_inventory = 0
	_update_label()
	_state = State.IDLE

# ─── Helpers ──────────────────────────────────────────────────────────────────

func _move_toward(target: Vector2, _delta: float) -> void:
	var dir: Vector2 = (target - _owner_npc.global_position).normalized()
	_owner_npc.velocity = dir * travel_speed
	_owner_npc.move_and_slide()

func _find_chest() -> void:
	# Priorité 1 : nœud du groupe "chest"
	var chests: Array = get_tree().get_nodes_in_group("chest")
	if chests.size() > 0:
		_chest_node = chests[0] as Node2D
		_chest_pos  = _chest_node.global_position
		return
	# Priorité 2 : chunk (0,0) = position monde (0,0) — la hutte
	_chest_pos  = Vector2.ZERO
	_chest_node = null

func _find_nearest_target(exclude: Node2D = null) -> Node2D:
	var group: String = JOB_TARGET_GROUP.get(job, "")
	if group == : return null
	var nodes: Array = get_tree().get_nodes_in_group(group)
	var best: Node2D = null
	var best_dist: float = INF
	for n in nodes:
		if n == exclude: continue
		if not is_instance_valid(n): continue
		# Ignore les arbres épuisés s'ils ont un flag
		if n.get("is_depleted") == true: continue
		var d: float = _owner_npc.global_position.distance_to((n as Node2D).global_position)
		if d < best_dist:
			best_dist = d
			best = n as Node2D
	return best

func _notify_favor() -> void:
	var rel = _owner_npc.get_node_or_null("RelationComponent")
	if rel != null and rel.has_method("do_favor"):
		rel.do_favor(1)

# ─── API publique ─────────────────────────────────────────────────────────────

func update_job(new_job: String) -> void:
	job = new_job
	_inventory = 0
	_target_node = null
	_state = State.IDLE
	_update_label()
	print("[WorkerAI] Nouveau métier : ", new_job)
