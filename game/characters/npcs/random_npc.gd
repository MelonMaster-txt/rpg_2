# random_npc.gd
# ──────────────────────────────────────────────────────────────────────
# NPC générique rencontrable dans la forêt.
# Utilise CharacterAppearance pour le visuel (layers LPC + RGB modulate).
#
# SCÈNE ATTENDUE : random_npc.tscn
#   RandomNPC  (CharacterBody2D)  ← ce script
#   ├─ CharacterAppearance (Node) ← character_appearance.gd
#   ├─ CollisionShape2D
#   ├─ InteractionArea (Area2D)
#   │   └─ CollisionShape2D
#   └─ NameLabel (Label)
# ──────────────────────────────────────────────────────────────────────
extends CharacterBody2D

# ── Signaux ────────────────────────────────────────────────────────
signal interaction_requested(npc)   # joueur appuie sur E à portée
signal npc_defeated(npc)            # PV tombés à 0
signal npc_captured(npc)            # joueur choisit de capturer

# ── Stats de base (surchargées par NpcSpawner si besoin) ───────────
@export var npc_name:    String = ""
@export var max_hp:      int    = 30
@export var strength:    int    = 5
@export var speed:       float  = 60.0
@export var is_hostile:  bool   = false   # peut attaquer le joueur spontanément

# ── État interne ───────────────────────────────────────────────────
var current_hp:   int
var _appearance:  Node          # CharacterAppearance
var _name_label:  Label
var _player_near: bool = false
var _state:       String = "idle"   # idle / wander / flee / dead

# Noms aléatoires (pool de base — à étoffer)
const NAMES_MALE   := ["Bjorn","Ulf","Ragnar","Gunnar","Leif","Sigurd","Erik","Ivar"]
const NAMES_FEMALE := ["Astrid","Freya","Sigrid","Hilde","Runa","Ylva","Ingrid","Solveig"]

# Directions walk cycle
const DIRS := ["down","left","right","up"]
var _wander_timer:  float = 0.0
var _wander_dir:    Vector2 = Vector2.ZERO


# ══════════════════════════════════════════════════════════════════
#  INIT
# ══════════════════════════════════════════════════════════════════

func _ready() -> void:
	current_hp  = max_hp
	_appearance = $CharacterAppearance
	_name_label = $NameLabel
	$InteractionArea.body_entered.connect(_on_player_enter)
	$InteractionArea.body_exited.connect(_on_player_exit)


# ══════════════════════════════════════════════════════════════════
#  API PUBLIQUE — appelée par NpcSpawner
# ══════════════════════════════════════════════════════════════════

## Génère une apparence et des stats complètement aléatoires.
func randomize_full(seed_val: int = -1) -> void:
	if seed_val >= 0:
		seed(seed_val)

	# ── Apparence visuelle ──────────────────────────────────────────
	_appearance.randomize_appearance()

	# ── Nom selon le genre ──────────────────────────────────────────
	if npc_name == "":
		if _appearance._gender == "male":
			npc_name = NAMES_MALE.pick_random()
		else:
			npc_name = NAMES_FEMALE.pick_random()

	_name_label.text = npc_name

	# ── Stats légèrement randomisées ───────────────────────────────
	max_hp    = randi_range(20, 60)
	strength  = randi_range(3, 12)
	speed     = randf_range(40.0, 90.0)
	is_hostile = randf() < 0.25   # 25 % de chance d'être hostile
	current_hp = max_hp


## Force une apparence précise (pour NPC scénarisés).
func set_appearance(data: Dictionary) -> void:
	_appearance.apply_appearance_data(data)
	if data.has("name"):
		npc_name = data["name"]
		_name_label.text = npc_name


# ══════════════════════════════════════════════════════════════════
#  BOUCLE
# ══════════════════════════════════════════════════════════════════

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
				_appearance.set_walk_frame(0)
		"dead":
			velocity = Vector2.ZERO


# ══════════════════════════════════════════════════════════════════
#  COMBAT
# ══════════════════════════════════════════════════════════════════

func take_damage(amount: int) -> void:
	if _state == "dead": return
	current_hp -= amount
	if current_hp <= 0:
		current_hp = 0
		_die()


func _die() -> void:
	_state = "dead"
	_appearance.set_eye_style("closed")
	npc_defeated.emit(self)


## Capture le NPC (après victoire). Retourne ses données d'apparence.
func capture() -> Dictionary:
	var data := _appearance.get_appearance_data()
	data["name"]     = npc_name
	data["strength"] = strength
	data["max_hp"]   = max_hp
	npc_captured.emit(self)
	return data


# ══════════════════════════════════════════════════════════════════
#  INTERACTION
# ══════════════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if _player_near and event.is_action_pressed("interact") and _state != "dead":
		interaction_requested.emit(self)


func _on_player_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_name_label.visible = true


func _on_player_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		_name_label.visible = false


# ══════════════════════════════════════════════════════════════════
#  WANDER INTERNE
# ══════════════════════════════════════════════════════════════════

func _pick_wander_dir() -> void:
	if randf() < 0.4:   # 40 % de chance de rester immobile
		_state = "idle"
		_wander_timer = randf_range(1.5, 3.0)
		return
	_state = "wander"
	var angle := randf() * TAU
	_wander_dir = Vector2(cos(angle), sin(angle))
	_wander_timer = randf_range(0.8, 2.5)


func _update_facing() -> void:
	# Choisit la direction sprite selon velocity
	if velocity.length() < 5.0: return
	var dominant: String
	if abs(velocity.x) > abs(velocity.y):
		dominant = "right" if velocity.x > 0 else "left"
	else:
		dominant = "down" if velocity.y > 0 else "up"
	_appearance.set_direction(dominant)
	# Cycle walk : alterne frames 1-4
	var f := (Engine.get_process_frames() / 8) % 4 + 1
	_appearance.set_walk_frame(f)
