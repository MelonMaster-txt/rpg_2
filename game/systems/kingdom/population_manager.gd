extends Node

# Autoload enregistré comme "PopulationManager" dans Project > Autoload
# Si pas encore enregistré, l'ajouter via Project Settings > Autoload

signal companion_added(entry: Dictionary)
signal slave_added(entry: Dictionary)
signal member_removed(member_name: String)
signal job_changed(member_name: String, new_job: String)

var companions: Array[Dictionary] = []
var slaves:     Array[Dictionary] = []


func _ready() -> void:
	add_to_group("population_manager")


func add_companion(entry: Dictionary) -> void:
	entry["role"] = "companion"
	companions.append(entry)
	companion_added.emit(entry)
	print("[PopulationManager] Compagnon ajouté : ", entry.get("name", "?"))


func add_slave(entry: Dictionary) -> void:
	entry["role"] = "slave"
	slaves.append(entry)
	slave_added.emit(entry)
	print("[PopulationManager] Esclave ajouté : ", entry.get("name", "?"))


func remove_member(member_name: String) -> void:
	for i: int in range(companions.size() - 1, -1, -1):
		if companions[i].get("name", "") == member_name:
			companions.remove_at(i)
			member_removed.emit(member_name)
			return
	for i: int in range(slaves.size() - 1, -1, -1):
		if slaves[i].get("name", "") == member_name:
			slaves.remove_at(i)
			member_removed.emit(member_name)
			return


func assign_job(member_name: String, new_job: String) -> void:
	for member in companions:
		if member.get("name", "") == member_name:
			member["job"] = new_job
			job_changed.emit(member_name, new_job)
			return
	for member in slaves:
		if member.get("name", "") == member_name:
			member["job"] = new_job
			job_changed.emit(member_name, new_job)
			return


func get_all_members() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	all.append_array(companions)
	all.append_array(slaves)
	return all


func get_population_count() -> int:
	return companions.size() + slaves.size()


func get_workers_by_job(job: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for member in get_all_members():
		if member.get("job", "") == job:
			result.append(member)
	return result


func save_data() -> Dictionary:
	return {
		"companions": companions,
		"slaves":     slaves,
	}


func load_data(d: Dictionary) -> void:
	companions = d.get("companions", [])
	slaves     = d.get("slaves",     [])
