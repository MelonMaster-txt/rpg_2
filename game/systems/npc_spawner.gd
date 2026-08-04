# npc_spawner.gd
# Autoload : NpcSpawner
# Gere le spawn/despawn des NPC aleatoires et la liste des NPC du royaume
extends Node

const NPC_SCENE := "res://game/characters/npcs/npc_base.tscn"

var _active_npcs: Array = []   # NPC en vie dans le monde
var _kingdom_npcs: Array = []  # Compagnons + esclaves

func spawn_random_around(origin: Vector2, radius: float, count: int) -> void:
	var scene: PackedScene = load(NPC_SCENE)
	if scene == null:
		push_error("NpcSpawner: npc_base.tscn introuvable")
		return
	var root := get_tree().current_scene
	for i in range(count):
		var npc: Node2D = scene.instantiate()
		var angle := randf() * TAU
		var dist  := randf_range(60.0, radius)
		npc.global_position = origin + Vector2(cos(angle), sin(angle)) * dist
		root.add_child(npc)
		_active_npcs.append(npc)

func despawn_all() -> void:
	for npc in _active_npcs:
		if is_instance_valid(npc) and npc.get("state") == 0: # 0 = State.LIBRE
			npc.queue_free()
	_active_npcs = _active_npcs.filter(
		func(n):
			return is_instance_valid(n) and n.get("state") != 0
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
		func(n):
			return is_instance_valid(n) and n.get("state") == state
	)
