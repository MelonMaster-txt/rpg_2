# WorkerAI — composant enfant d'un RandomNpc recrute ou capture.
# Attache dynamiquement via random_npc._start_working()
extends Node

const WORK_INTERVAL: float = 5.0

var job: String = ""
var _work_timer: float = 0.0


func _process(delta: float) -> void:
	_work_timer -= delta
	if _work_timer <= 0.0:
		_work_timer = WORK_INTERVAL
		_do_work()


func _do_work() -> void:
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm == null:
		push_warning("[WorkerAI] GameManager introuvable")
		return
	match job:
		"farmer":
			gm.add_item("berries", 1)
		"woodcutter", "lumberjack":
			gm.add_item("wood", 2)
		"miner":
			gm.add_item("stone", 1)
		"blacksmith":
			gm.add_item("flint", 1)
		"priest":
			var rm: Node = get_node_or_null("/root/ReligionManager")
			if rm != null and rm.has_method("add_faith"):
				rm.add_faith(2)


func update_job(new_job: String) -> void:
	job = new_job


func _get_owner_name() -> String:
	var p: Node = get_parent()
	if p != null and p.get("npc_name") != null:
		return p.npc_name
	return "NPC"
