extends Node
# WorkerAI — composant enfant d'un RandomNpc recruté ou capturé.
# Attaché dynamiquement via random_npc._start_working()

var job: String = ""
var _work_timer: float = 0.0
const WORK_INTERVAL: float = 5.0


func _ready() -> void:
	pass


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
			print("[WorkerAI] ", _get_owner_name(), " produit 1 baie")
		"woodcutter", "lumberjack":
			gm.add_item("wood", 2)
			print("[WorkerAI] ", _get_owner_name(), " produit 2 bois")
		"miner":
			gm.add_item("stone", 1)
			print("[WorkerAI] ", _get_owner_name(), " produit 1 pierre")
		"blacksmith":
			gm.add_item("flint", 1)
			print("[WorkerAI] ", _get_owner_name(), " produit 1 silex")
		"priest":
			var rm: Node = get_node_or_null("/root/ReligionManager")
			if rm != null and rm.has_method("add_faith"):
				rm.add_faith(2)
				print("[WorkerAI] ", _get_owner_name(), " génère 2 foi")
		"guard":
			pass


func update_job(new_job: String) -> void:
	job = new_job
	print("[WorkerAI] ", _get_owner_name(), " change de metier -> ", new_job)


func _get_owner_name() -> String:
	var p: Node = get_parent()
	if p != null and p.get("npc_name") != null:
		return p.npc_name
	return "NPC"
