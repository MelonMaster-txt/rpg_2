# companion_manager.gd
# Autoload — Gère compagnons et esclaves du royaume.
# Accès : CompanionManager.companions, CompanionManager.slaves
extends Node

# ─── Données ─────────────────────────────────────────────────────────────────
# Chaque entrée est un Dictionary :
# {
#   "name": String, "gender": String, "role": "companion"|"slave",
#   "job": String ("" = inactif), "archetype": String,
#   "strength": int, "max_hp": int,
#   "skills": { "farming":int, "woodcutting":int, ... },
#   "happiness": int  (0-100, esclaves descendent si job trop dur)
# }

var companions: Array[Dictionary] = []
var slaves:     Array[Dictionary] = []

# Production par tick de jour (ressources générées chaque nouveau jour)
# FIX: clés alignées sur GameManager.inventory (français) + "or" pour gold
const JOB_PRODUCTION := {
	"farmer":      { "baies": 3 },
	"woodcutter":  { "bois": 4 },
	"miner":       { "pierre": 3 },
	"guard":       {},
	"trader":      { "or": 2 },
	"builder":     { "bois": -1, "pierre": -1, "build_points": 1 },
}

# Jobs disponibles
const JOBS := ["farmer", "woodcutter", "miner", "guard", "trader", "builder", ""]

signal roster_changed

# ─── Ajout ───────────────────────────────────────────────────────────────────

func add_companion(entry: Dictionary) -> void:
	entry["role"] = "companion"
	companions.append(entry)
	roster_changed.emit()
	print("[CompanionManager] Compagnon ajouté : ", entry.get("name", "?"))


func add_slave(entry: Dictionary) -> void:
	entry["role"] = "slave"
	slaves.append(entry)
	roster_changed.emit()
	print("[CompanionManager] Esclave ajouté : ", entry.get("name", "?"))

# ─── Gestion des jobs ────────────────────────────────────────────────────────

func assign_job(person_name: String, job: String) -> bool:
	if not job in JOBS:
		push_warning("CompanionManager: job inconnu '%s'" % job)
		return false
	for entry in companions:
		if entry["name"] == person_name:
			entry["job"] = job
			roster_changed.emit()
			return true
	for entry in slaves:
		if entry["name"] == person_name:
			entry["job"] = job
			# Les esclaves perdent du bonheur selon la dureté du job
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

# ─── Production quotidienne ──────────────────────────────────────────────────
# Appelé par GameManager ou TimeSystem chaque nouveau jour

func process_daily_production() -> void:
	var all_workers := companions + slaves
	for person in all_workers:
		var job: String = person.get("job", "")
		if job == "" or not JOB_PRODUCTION.has(job):
			continue
		var prod: Dictionary = JOB_PRODUCTION[job]
		var skill_bonus: float = _get_skill_bonus(person, job)
		for resource in prod:
			var amount: int = int(prod[resource] * skill_bonus)
			if amount == 0:
				continue
			if resource == "build_points":
				# FIX: build_points stockés dans GameManager directement
				var cur_bp: int = GameManager.get("build_points") if GameManager.get("build_points") != null else 0
				GameManager.set("build_points", cur_bp + amount)
			else:
				# FIX: toutes les autres ressources passent par add_item (clés fr)
				GameManager.add_item(resource, amount)
		# Réduction bonheur esclaves au fil du temps
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
	# Skill 0-100 → bonus 0.5x à 2.0x
	return 0.5 + (float(skills[key]) / 100.0) * 1.5

# ─── Sérialisation (sauvegarde) ───────────────────────────────────────────────

func to_dict() -> Dictionary:
	return {
		"companions": companions,
		"slaves":     slaves,
	}


func from_dict(d: Dictionary) -> void:
	companions = []
	slaves     = []
	for e in d.get("companions", []):
		companions.append(e)
	for e in d.get("slaves", []):
		slaves.append(e)
	roster_changed.emit()

# ─── Utilitaires ─────────────────────────────────────────────────────────────

func get_all() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for c in companions:
		all.append(c)
	for s in slaves:
		all.append(s)
	return all


func count() -> int:
	return companions.size() + slaves.size()


func find_by_name(nm: String) -> Dictionary:
	for e in get_all():
		if e["name"] == nm:
			return e
	return {}
