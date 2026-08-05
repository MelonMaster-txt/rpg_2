extends NpcBase
class_name WorkerAI

# ─── EXPORTS ──────────────────────────────────────────────────────────────────
@export var job_id: String = ""
@export var work_radius: float = 200.0

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _work_target: Node = null
var _work_timer: float = 0.0
const WORK_INTERVAL: float = 5.0

func _ready() -> void:
	super._ready()
	current_state = State.WORK

func _physics_process(delta: float) -> void:
	if current_state == State.WORK:
		_process_work(delta)
		return
	super._physics_process(delta)

func _process_work(delta: float) -> void:
	_work_timer -= delta
	if _work_timer > 0.0:
		return
	_work_timer = WORK_INTERVAL
	_do_work()

func _do_work() -> void:
	if job_id == "farmer":
		GameManager.add_item("berries", 1)
	elif job_id == "lumberjack":
		GameManager.add_item("wood", 2)
	elif job_id == "miner":
		GameManager.add_item("stone", 1)
	elif job_id == "blacksmith":
		GameManager.add_item("flint", 1)
	elif job_id == "priest":
		if Engine.has_singleton("ReligionManager"):
			ReligionManager.add_faith(2)
