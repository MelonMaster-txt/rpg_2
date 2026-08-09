# state_work.gd
# Le NPC travaille sur place. Se déplace vers le coffre pour déposer les ressources.
extends NpcStateBase

const WORK_INTERVAL:  float = 5.0
const DEPOSIT_RANGE:  float = 48.0
const MOVE_TO_CHEST_DIST: float = 200.0

var _work_timer:    float = WORK_INTERVAL
var _going_to_chest: bool = false
var _chest_target:   Node2D = null


func enter(_prev: String) -> void:
	_work_timer = WORK_INTERVAL
	_going_to_chest = false


func update(delta: float) -> String:
	if _going_to_chest:
		_walk_to_chest(delta)
		return ""
	_work_timer -= delta
	npc.velocity = Vector2.ZERO
	if _work_timer <= 0.0:
		_work_timer = WORK_INTERVAL
		_produce()
	return ""


func _produce() -> void:
	var worker: Node = npc.get_node_or_null("WorkerAI")
	if worker == null:
		return
	# Délègue la production au WorkerAI existant
	if worker.has_method("tick"):
		worker.tick()
		return
	# Fallback direct
	var job: String = worker.get("job") if worker.get("job") != null else ""
	var prod: Dictionary = CompanionManager.JOB_PRODUCTION.get(job, {})
	if prod.is_empty():
		return
	var chest: Node2D = _find_chest()
	if chest != null and npc.global_position.distance_to(chest.global_position) > MOVE_TO_CHEST_DIST:
		_chest_target = chest
		_going_to_chest = true
		return
	for resource: String in prod:
		var amount: int = prod[resource]
		if amount <= 0:
			continue
		GameManager.add_item(resource, amount)


func _walk_to_chest(delta: float) -> void:
	if _chest_target == null or not is_instance_valid(_chest_target):
		_going_to_chest = false
		return
	var dist: float = npc.global_position.distance_to(_chest_target.global_position)
	if dist < DEPOSIT_RANGE:
		_going_to_chest = false
		_deposit_to_chest()
		return
	var dir: Vector2 = (_chest_target.global_position - npc.global_position).normalized()
	npc.velocity = dir * npc.speed
	npc.move_and_slide()


func _deposit_to_chest() -> void:
	var worker: Node = npc.get_node_or_null("WorkerAI")
	if worker == null:
		return
	var job: String = worker.get("job") if worker.get("job") != null else ""
	var prod: Dictionary = CompanionManager.JOB_PRODUCTION.get(job, {})
	for resource: String in prod:
		var amount: int = prod[resource]
		if amount > 0:
			GameManager.add_item(resource, amount)
	print("[WorkState] ", npc.npc_name, " a déposé ses ressources (job: ", job, ")")


func _find_chest() -> Node2D:
	var chests: Array = npc.get_tree().get_nodes_in_group("chest")
	if chests.size() > 0:
		return chests[0] as Node2D
	return null
