# npc_spawner.gd
# Autoload : NpcSpawner
# Gere le spawn/despawn des NPC aleatoires et la liste des NPC du royaume
extends Node

const NPC_SCENE := "res://game/characters/npcs/random_npc.tscn"

# Probabilites de genre : 40% homme, 40% femme, 20% monstre
const GENDER_WEIGHTS := [
	{"gender": "male",    "weight": 40},
	{"gender": "female",  "weight": 40},
	{"gender": "monster", "weight": 20},
]

var _active_npcs: Array  = []  # NPC en vie dans le monde
var _kingdom_npcs: Array = []  # Compagnons + esclaves


func spawn_random_around(origin: Vector2, radius: float, count: int) -> void:
	var scene: PackedScene = load(NPC_SCENE)
	if scene == null:
		push_error("NpcSpawner: random_npc.tscn introuvable")
		return
	var root := get_tree().current_scene
	for i in range(count):
		var npc: Node = scene.instantiate()
		# Tirer le genre AVANT d'ajouter à la scène
		var gender: String = _pick_gender()
		npc.npc_gender = gender
		# Positionner
		var angle := randf() * TAU
		var dist  := randf_range(60.0, radius)
		npc.global_position = origin + Vector2(cos(angle), sin(angle)) * dist
		root.add_child(npc)
		# randomize_full APRES add_child pour que l'arbre soit prêt
		npc.randomize_full()
		_active_npcs.append(npc)


func _pick_gender() -> String:
	# Tirage pondéré
	var total: int = 0
	for entry in GENDER_WEIGHTS:
		total += entry["weight"]
	var roll: int = randi_range(0, total - 1)
	var acc:  int = 0
	for entry in GENDER_WEIGHTS:
		acc += entry["weight"]
		if roll < acc:
			return entry["gender"]
	return "male"


func despawn_all() -> void:
	for npc in _active_npcs:
		if is_instance_valid(npc) and npc.get("state") == 0:
			npc.queue_free()
	_active_npcs = _active_npcs.filter(
		func(n): return is_instance_valid(n) and n.get("state") != 0
	)


func unregister(npc: Node) -> void:
	_active_npcs.erase(npc)
	_kingdom_npcs.erase(npc)


func register_kingdom_npc(npc: Node) -> void:
	if not npc in _kingdom_npcs:
		_kingdom_npcs.append(npc)


func get_kingdom_npcs() -> Array:
	return _kingdom_npcs


func get_npcs_by_state(state: int) -> Array:
	return _kingdom_npcs.filter(
		func(n): return is_instance_valid(n) and n.get("state") == state
	)
