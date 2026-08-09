# state_wander.gd
# Le NPC se déplace dans une direction aléatoire.
extends NpcStateBase

var _timer: float = 0.0
var _dir: Vector2 = Vector2.ZERO


func enter(_prev: String) -> void:
	var angle: float = randf() * TAU
	_dir  = Vector2(cos(angle), sin(angle))
	_timer = randf_range(1.0, 2.5)


func update(delta: float) -> String:
	_timer -= delta
	npc.velocity = _dir * npc.speed
	npc.move_and_slide()
	_update_facing()
	if _timer <= 0.0:
		return "idle"
	if npc.is_hostile and _player_in_range(npc.DETECT_RANGE):
		return "combat"
	if not npc.is_hostile and _player_in_range(npc.DETECT_RANGE * 0.5):
		return "flee"
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


func _player_in_range(range_val: float) -> bool:
	var player: Node = _get_player()
	if player == null:
		return false
	return npc.global_position.distance_to((player as Node2D).global_position) < range_val


func _get_player() -> Node:
	var arr: Array = npc.get_tree().get_nodes_in_group("player")
	return arr[0] if arr.size() > 0 else null
