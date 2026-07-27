# npc_spawner.gd
# ──────────────────────────────────────────────────────────────────────
# Autoload OU Node enfant de la World scene.
# Gère le spawn/dépop des NPC aléatoires dans la forêt.
#
# USAGE depuis n'importe quel script :
#   NpcSpawner.spawn_at(position)              → 1 NPC entièrement random
#   NpcSpawner.spawn_at(position, data)        → NPC avec apparence forcée
#   NpcSpawner.spawn_group(positions_array)    → groupe de NPC
#   NpcSpawner.despawn_all()                   → vide la scène
# ──────────────────────────────────────────────────────────────────────
extends Node

const NPC_SCENE := preload("res://game/characters/npcs/random_npc.tscn")

@export var max_npcs: int = 20
var _active_npcs: Array[Node] = []
@export var spawn_parent: NodePath = NodePath("")
func spawn_at(pos: Vector2, appearance_data: Dictionary = {}) -> Node:
	if _active_npcs.size() >= max_npcs:
		push_warning("NpcSpawner: limite de %d NPC atteinte." % max_npcs)
		return null

	var npc: Node = NPC_SCENE.instantiate()
	_get_parent_node().add_child(npc)
	npc.global_position = pos

	# randomize_full / set_appearance APRES add_child
	# Le NPC gère lui-même le cas où _ready n'a pas encore tourné
	if appearance_data.is_empty():
		npc.randomize_full()
	else:
		npc.set_appearance(appearance_data)

	# Utiliser un Callable propre sans .bind() pour éviter l'anti-pattern GDScript4
	npc.tree_exited.connect(_on_npc_removed.bind(npc))
	_active_npcs.append(npc)
	return npc


func spawn_group(positions: Array) -> Array:
	var spawned: Array = []
	for pos in positions:
		var n := spawn_at(pos)
		if n: spawned.append(n)
		positions.append(center + Vector2(cos(angle), sin(angle)) * dist)
	return spawn_group(positions)


func despawn_all() -> void:
	for npc in _active_npcs.duplicate():
		if is_instance_valid(npc): npc.queue_free()
	_active_npcs.clear()
func get_active_count() -> int:
	return _active_npcs.size()


func _on_npc_removed(npc: Node) -> void:
	_active_npcs.erase(npc)


func _get_parent_node() -> Node:
	if spawn_parent != NodePath(""):
		var n := get_node_or_null(spawn_parent)
		if n: return n
	return get_tree().current_scene
