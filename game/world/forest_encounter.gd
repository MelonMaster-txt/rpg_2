# forest_encounter.gd
# ──────────────────────────────────────────────────────────────────────
# À attacher sur la scène Forêt (forest.tscn).
# Déclenche des rencontres aléatoires pendant l'exploration.
#
# FONCTIONNEMENT :
#  - Un timer tick toutes les ENCOUNTER_INTERVAL secondes
#  - Si le joueur est dans la zone forêt → chance de spawn un groupe
#  - Les NPC spawnent dans un rayon autour du joueur
#  - Quand le joueur quitte la zone, tous les NPC sont dépopés
# ──────────────────────────────────────────────────────────────────────
extends Node

@export var encounter_interval: float  = 15.0   # secondes entre deux rolls
@export var encounter_chance:   float  = 0.40   # 40 % de chance de rencontre
@export var spawn_radius:       float  = 200.0  # rayon de spawn autour du joueur
@export var group_size_min:     int    = 1
@export var group_size_max:     int    = 3

var _timer:  float = 0.0
var _player: Node  = null


func _ready() -> void:
	# Récupère le joueur (groupe "player")
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]


func _process(delta: float) -> void:
	if not _player: return
	_timer += delta
	if _timer >= encounter_interval:
		_timer = 0.0
		_roll_encounter()


func _roll_encounter() -> void:
	if randf() > encounter_chance: return
	var count := randi_range(group_size_min, group_size_max)
	NpcSpawner.spawn_random_around(_player.global_position, spawn_radius, count)
	print("[ForestEncounter] %d NPC spawnés autour du joueur" % count)


## Appelé quand le joueur quitte la zone forêt.
func clear_encounters() -> void:
	NpcSpawner.despawn_all()
