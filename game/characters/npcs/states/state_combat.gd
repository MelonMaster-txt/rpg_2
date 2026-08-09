# state_combat.gd
# Le NPC hostile poursuit et attaque le joueur.
extends NpcStateBase

const ATTACK_RANGE:    float = 32.0
const ATTACK_COOLDOWN: float = 1.5
const DISENGAGE_DIST:  float = 220.0

var _attack_timer: float = 0.0


func enter(_prev: String) -> void:
	_attack_timer = 0.0


func update(delta: float) -> String:
	_attack_timer = max(0.0, _attack_timer - delta)
	var player: Node = _get_player()
	if player == null:
		return "idle"
	var dist: float = npc.global_position.distance_to((player as Node2D).global_position)
	# Disengage si trop loin
	if dist > DISENGAGE_DIST:
		return "wander"
	if dist > ATTACK_RANGE:
		var dir: Vector2 = ((player as Node2D).global_position - npc.global_position).normalized()
		npc.velocity = dir * npc.speed * 1.1
		npc.move_and_slide()
		_update_facing()
	else:
		npc.velocity = Vector2.ZERO
		if _attack_timer <= 0.0:
			_melee_attack(player)
	return ""


func _melee_attack(player: Node) -> void:
	_attack_timer = ATTACK_COOLDOWN
	var dmg: int = max(1, int(float(npc.strength) / 3.0))
	if player.has_method("take_damage"):
		player.take_damage(dmg)
	print("[CombatState] ", npc.npc_name, " attaque le joueur pour ", dmg, " dégâts")


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


func _get_player() -> Node:
	var arr: Array = npc.get_tree().get_nodes_in_group("player")
	return arr[0] if arr.size() > 0 else null
