# state_flee.gd
# Le NPC pacifique fuit le joueur.
extends NpcStateBase

const SAFE_DIST: float = 160.0


func enter(_prev: String) -> void:
	pass


func update(_delta: float) -> String:
	var player: Node = _get_player()
	if player == null:
		return "idle"
	var dist: float = npc.global_position.distance_to((player as Node2D).global_position)
	if dist >= SAFE_DIST:
		return "wander"
	var dir: Vector2 = (npc.global_position - (player as Node2D).global_position).normalized()
	npc.velocity = dir * npc.speed * 1.3
	npc.move_and_slide()
	return ""


func _get_player() -> Node:
	var arr: Array = npc.get_tree().get_nodes_in_group("player")
	return arr[0] if arr.size() > 0 else null
