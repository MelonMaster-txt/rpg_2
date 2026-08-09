# state_idle.gd
# Le NPC est immobile. Après un délai aléatoire, passe en WANDER.
extends NpcStateBase

var _timer: float = 0.0


func enter(_prev: String) -> void:
	npc.velocity = Vector2.ZERO
	_timer = randf_range(1.5, 3.5)


func update(delta: float) -> String:
	_timer -= delta
	if _timer <= 0.0:
		return "wander"
	# Si hostile et joueur proche → combat
	if npc.is_hostile and _player_in_range(npc.DETECT_RANGE):
		return "combat"
	# Si pas hostile et joueur très proche → fuite
	if not npc.is_hostile and _player_in_range(npc.DETECT_RANGE * 0.5):
		return "flee"
	return ""


func _player_in_range(range_val: float) -> bool:
	var player: Node = _get_player()
	if player == null:
		return false
	return npc.global_position.distance_to((player as Node2D).global_position) < range_val


func _get_player() -> Node:
	var arr: Array = npc.get_tree().get_nodes_in_group("player")
	return arr[0] if arr.size() > 0 else null
