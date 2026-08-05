# population_manager.gd — Autoload singleton
# Gère compagnons et esclaves du royaume.
extends Node

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal companion_added(entry: Dictionary)
signal slave_added(entry: Dictionary)
signal population_changed

# ─── DATA ─────────────────────────────────────────────────────────────────────
var companions: Array = []
var slaves:     Array = []

# ─── COMPANIONS ───────────────────────────────────────────────────────────────
func add_companion(entry: Dictionary) -> void:
	entry["role"] = "companion"
	companions.append(entry)
	companion_added.emit(entry)
	population_changed.emit()
	print("[PopulationManager] Compagnon ajouté : ", entry.get("name", "???"))


func remove_companion(npc_name: String) -> bool:
	for i: int in range(companions.size()):
		if companions[i].get("name", "") == npc_name:
			companions.remove_at(i)
			population_changed.emit()
			return true
	return false

# ─── SLAVES ───────────────────────────────────────────────────────────────────
func add_slave(entry: Dictionary) -> void:
	entry["role"] = "slave"
	slaves.append(entry)
	slave_added.emit(entry)
	population_changed.emit()
	print("[PopulationManager] Esclave ajouté : ", entry.get("name", "???"))


func remove_slave(npc_name: String) -> bool:
	for i: int in range(slaves.size()):
		if slaves[i].get("name", "") == npc_name:
			slaves.remove_at(i)
			population_changed.emit()
			return true
	return false

# ─── JOB ASSIGNMENT ───────────────────────────────────────────────────────────
func assign_job(npc_name: String, job: String) -> bool:
	for entry: Dictionary in companions:
		if entry.get("name", "") == npc_name:
			entry["job"] = job
			population_changed.emit()
			return true
	for entry: Dictionary in slaves:
		if entry.get("name", "") == npc_name:
			entry["job"] = job
			population_changed.emit()
			return true
	return false

# ─── QUERIES ──────────────────────────────────────────────────────────────────
func get_all() -> Array:
	return companions + slaves


func get_workers_by_job(job: String) -> Array:
	var result: Array = []
	for entry: Dictionary in get_all():
		if entry.get("job", "") == job:
			result.append(entry)
	return result


func get_total_count() -> int:
	return companions.size() + slaves.size()
