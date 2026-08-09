# state_follow.gd
# Le NPC (compagnon) suit le joueur à distance confortable.
extends NpcStateBase

const FOLLOW_DIST:     float = 80.0
const STOP_DIST:       float = 40.0
const LOST_DIST:       float = 400.0


func enter(_prev: String) -> void:
	pass


func update(_delta: float) -> String:
	var player: Node = _get_player()
	if player == null:
		return "idle"
	var dist: float = npc.global_position.distance_to((player as Node2D).global_position)
	if dist > LOST_DIST:
		# Téléporte près du joueur pour ne pas se perdre
		npc.global_position = (player as Node2D).global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
		return ""
	if dist > STOP_DIST:
		var dir: Vector2 = ((player as Node2D).global_position - npc.global_position).normalized()
		npc.velocity = dir * npc.speed
		npc.move_and_slide()
		_update_facing()
	else:
		npc.velocity = Vector2.ZERO
	return ""


func _update_facing() -> void:
	if npc.velocity.length() < 5.0:
		return
	var app: Node = npc.get_node_or_null("CharacterAppearance")
	if app == null:
		return
	var dominant: String
	if abs(npc.velocity.x) > abs(npc.velocity.y):
		dominant = "right" if npc.velocity.x > 0 else "left"
	else:
		dominant = "down" if npc.velocity.y > 0 else "up"
	app.set_direction(dominant)
	var f: int = (Engine.get_process_frames() >> 3) % 4 + 1
	app.set_walk_frame(f)


func _get_player() -> Node:
	var arr: Array = npc.get_tree().get_nodes_in_group("player")
	return arr[0] if arr.size() > 0 else null
