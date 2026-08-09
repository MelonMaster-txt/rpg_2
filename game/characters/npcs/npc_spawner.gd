# npc_spawner.gd — Autoload
# Spawne des PNJ aléatoires autour d'une position donnée.
extends Node

const NPC_SCENE: PackedScene = preload("res://game/characters/npcs/random_npc.tscn")

var _spawned: Array[Node] = []


func _ready() -> void:
	pass


func spawn_random_around(origin: Vector2, radius: float, count: int = 1) -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	for _i: int in range(count):
		var angle: float  = randf() * TAU
		var dist:  float  = randf_range(radius * 0.3, radius)
		var pos:   Vector2 = origin + Vector2(cos(angle), sin(angle)) * dist
		var npc:   Node   = NPC_SCENE.instantiate()
		scene_root.add_child(npc)
		npc.global_position = pos
		if npc.has_method("randomize_full"):
			npc.randomize_full()
		_spawned.append(npc)
		npc.tree_exited.connect(_on_npc_removed.bind(npc))


func despawn_all() -> void:
	for npc: Node in _spawned:
		if is_instance_valid(npc):
			npc.queue_free()
	_spawned.clear()


func get_spawned_count() -> int:
	return _spawned.size()


func _on_npc_removed(npc: Node) -> void:
	_spawned.erase(npc)
