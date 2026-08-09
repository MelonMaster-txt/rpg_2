# kingdom_manager.gd — Autoload
# Gère l'état global du royaume : population, bâtiments, ressources royales.
extends Node

signal kingdom_updated

# Population
var population: Array[Dictionary] = []

# Bâtiments construits
var buildings: Array[String] = []

# Niveau du royaume
var kingdom_level: int = 0


func _ready() -> void:
	pass


# --- Population ---

func add_member(entry: Dictionary) -> void:
	population.append(entry)
	kingdom_updated.emit()


func remove_member(npc_name: String) -> void:
	for i: int in range(population.size() - 1, -1, -1):
		if population[i].get("name", "") == npc_name:
			population.remove_at(i)
			kingdom_updated.emit()
			return


func get_population() -> Array[Dictionary]:
	return population


func get_population_count() -> int:
	return population.size()


func get_members_by_role(role: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for member: Dictionary in population:
		if member.get("role", "") == role:
			result.append(member)
	return result


func assign_job(npc_name: String, job: String) -> void:
	for member: Dictionary in population:
		if member.get("name", "") == npc_name:
			member["job"] = job
			kingdom_updated.emit()
			return


# --- Bâtiments ---

func add_building(building_id: String) -> void:
	if not building_id in buildings:
		buildings.append(building_id)
		kingdom_updated.emit()


func has_building(building_id: String) -> bool:
	return building_id in buildings


# --- Sauvegarde ---

func get_save_data() -> Dictionary:
	return {
		"population":     population,
		"buildings":      buildings,
		"kingdom_level":  kingdom_level,
	}


func load_save_data(data: Dictionary) -> void:
	population    = data.get("population",    [])
	buildings     = data.get("buildings",     [])
	kingdom_level = data.get("kingdom_level", 0)
	kingdom_updated.emit()
