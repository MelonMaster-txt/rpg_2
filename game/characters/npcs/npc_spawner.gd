# npc_spawner.gd
# Autoload OU Node enfant de la World scene.
# Gere le spawn/depop des NPC aleatoires dans la foret.
#
# USAGE :
#   NpcSpawner.spawn_at(position)           → 1 NPC random
#   NpcSpawner.spawn_at(position, data)     → NPC avec apparence forcee
#   NpcSpawner.spawn_group(positions_array) → groupe de NPC
#   NpcSpawner.spawn_random_around(center, radius, count) → NPC en cercle
#   NpcSpawner.despawn_all()                → vide la scene
extends Node

const NPC_SCENE := preload("res://game/characters/npcs/random_npc.tscn")

@export var max_npcs: int = 20
@export var spawn_parent: NodePath = NodePath()

var _active_npcs: Array[Node] = []


func spawn_at(pos: Vector2, appearance_data: Dictionary = {}) -> Node:
	if _active_npcs.size() >= max_npcs:
		push_warning("NpcSpawner: limite de %d NPC atteinte." % max_npcs)
		return null

	var npc: Node = NPC_SCENE.instantiate()
	_get_parent_node().add_child(npc)
	npc.global_position = pos

	if appearance_data.is_empty():
		npc.randomize_full()
	else:
		npc.set_appearance(appearance_data)

	npc.tree_exited.connect(_on_npc_removed.bind(npc))
	_active_npcs.append(npc)
	return npc


func spawn_group(positions: Array) -> Array:
	var spawned: Array = []
	for pos: Variant in positions:
		var n: Node = spawn_at(pos)
		if n:
			spawned.append(n)
	return spawned


func spawn_random_around(center: Vector2, radius: float, count: int) -> Array:
	var positions: Array = []
	for i: int in count:
		var angle: float = randf() * TAU
		var dist: float = randf() * radius
		positions.append(center + Vector2(cos(angle), sin(angle)) * dist)
	return spawn_group(positions)


func despawn_all() -> void:
	for npc: Node in _active_npcs.duplicate():
		if is_instance_valid(npc):
			npc.queue_free()
	_active_npcs.clear()


func get_active_count() -> int:
	return _active_npcs.size()


func _on_npc_removed(npc: Node) -> void:
	_active_npcs.erase(npc)


func _get_parent_node() -> Node:
	if not spawn_parent.is_empty():
		var n: Node = get_node_or_null(spawn_parent)
		if n:
			return n
	return get_tree().current_scene
