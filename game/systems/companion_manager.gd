# companion_manager.gd
# Autoload — Manages companions and slaves of the kingdom.
# Access: CompanionManager.companions, CompanionManager.slaves
extends Node

# ─── Data ─────────────────────────────────────────────────────────────────────
# Each entry is a Dictionary:
# {
#   "name": String, "gender": String, "role": "companion"|"slave",
#   "job": String ("" = inactive), "archetype": String,
#   "strength": int, "max_hp": int,
#   "skills": { "farming":int, "woodcutting":int, ... },
#   "happiness": int  (0-100, slaves decrease if job is too hard)
# }

var companions: Array[Dictionary] = []
var slaves:     Array[Dictionary] = []

const JOB_PRODUCTION: Dictionary = {
	"farmer":     { "berries": 3 },
	"woodcutter": { "wood": 4 },
	"miner":      { "stone": 3 },
	"guard":      {},
	"trader":     { "gold": 2 },
	"builder":    { "wood": -1, "stone": -1, "build_points": 1 },
}

const JOBS: Array = ["farmer", "woodcutter", "miner", "guard", "trader", "builder", ""]

signal roster_changed

# ─── Add ──────────────────────────────────────────────────────────────────────

func add_companion(entry: Dictionary) -> void:
	entry["role"] = "companion"
	companions.append(entry)
	roster_changed.emit()
	print("[CompanionManager] Companion added: ", entry.get("name", "?"))


func add_slave(entry: Dictionary) -> void:
	entry["role"] = "slave"
	slaves.append(entry)
	roster_changed.emit()
	print("[CompanionManager] Slave added: ", entry.get("name", "?"))


# ─── Job management ───────────────────────────────────────────────────────────

func assign_job(person_name: String, job: String) -> bool:
	if not job in JOBS:
		push_warning("CompanionManager: unknown job '%s'" % job)
		return false
	for entry: Dictionary in companions:
		if entry["name"] == person_name:
			entry["job"] = job
			roster_changed.emit()
			return true
	for entry: Dictionary in slaves:
		if entry["name"] == person_name:
			entry["job"] = job
			var penalty: int = _slave_happiness_penalty(job)
			entry["happiness"] = max(0, entry.get("happiness", 100) - penalty)
			roster_changed.emit()
			return true
	return false


func _slave_happiness_penalty(job: String) -> int:
	match job:
		"miner":      return 15
		"builder":    return 10
		"woodcutter": return 8
		"farmer":     return 5
		_:            return 3


# ─── Daily production ─────────────────────────────────────────────────────────

func process_daily_production() -> void:
	var all_workers: Array = companions + slaves
	for person: Dictionary in all_workers:
		var job: String = person.get("job", "")
		if job == "" or not JOB_PRODUCTION.has(job):
			continue
		var prod: Dictionary = JOB_PRODUCTION[job]
		var skill_bonus: float = _get_skill_bonus(person, job)
		for resource: String in prod:
			var amount: int = int(prod[resource] * skill_bonus)
			if amount == 0:
				continue
			if resource == "build_points":
				GameManager.build_points += amount
			else:
				GameManager.add_item(resource, amount)
		if person["role"] == "slave":
			person["happiness"] = max(0, person.get("happiness", 50) - 1)


func _get_skill_bonus(person: Dictionary, job: String) -> float:
	var skills: Dictionary = person.get("skills", {})
	var key: String
	match job:
		"farmer":     key = "farming"
		"woodcutter": key = "woodcutting"
		"miner":      key = "mining"
		"trader":     key = "trading"
		"guard":      key = "combat"
		_:            key = ""
	if key == "" or not skills.has(key):
		return 1.0
	return 0.5 + (float(skills[key]) / 100.0) * 1.5


# ─── Serialization ────────────────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"companions": companions,
		"slaves":     slaves,
	}


func from_dict(d: Dictionary) -> void:
	companions = []
	slaves     = []
	for e: Dictionary in d.get("companions", []):
		companions.append(e)
	for e: Dictionary in d.get("slaves", []):
		slaves.append(e)
	roster_changed.emit()


# ─── Utilities ────────────────────────────────────────────────────────────────

func get_all() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for c: Dictionary in companions:
		all.append(c)
	for s: Dictionary in slaves:
		all.append(s)
	return all


func count() -> int:
	return companions.size() + slaves.size()


func find_by_name(nm: String) -> Dictionary:
	for e: Dictionary in get_all():
		if e["name"] == nm:
			return e
	return {}
