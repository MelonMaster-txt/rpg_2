# housing_manager.gd -- Autoload : HousingManager
# Gere la capacite de logement du royaume.
# Chaque batiment construit appelle register_shelter() pour ajouter des places.
# PopulationManager verifie can_house() avant d'accepter un nouveau membre.
extends Node

signal housing_changed(used: int, capacity: int)

# Capacite de base : la cahute de depart loge 1 personne (le joueur ne compte pas)
const BASE_CAPACITY: int = 1

var _shelters: Array[Dictionary] = []
# { id: String, name: String, capacity: int }


func _ready() -> void:
	pass


# Capacite totale disponible
func get_capacity() -> int:
	var total: int = BASE_CAPACITY
	for s: Dictionary in _shelters:
		total += s.get("capacity", 0)
	return total


# Places occupees
func get_used() -> int:
	var pm: Node = Engine.get_singleton("PopulationManager")
	if pm == null:
		return 0
	return pm.get_total_count()


# Places libres
func get_free() -> int:
	return get_capacity() - get_used()


# Peut-on loger une personne de plus ?
func can_house() -> bool:
	return get_free() > 0


# Enregistre un batiment de logement
func register_shelter(id: String, shelter_name: String, capacity: int) -> void:
	for s: Dictionary in _shelters:
		if s["id"] == id:
			return  # deja enregistre
	_shelters.append({"id": id, "name": shelter_name, "capacity": capacity})
	housing_changed.emit(get_used(), get_capacity())
	print("[HousingManager] +%d places : %s" % [capacity, shelter_name])


# Supprime un batiment detruit
func unregister_shelter(id: String) -> void:
	for i: int in range(_shelters.size() - 1, -1, -1):
		if _shelters[i]["id"] == id:
			_shelters.remove_at(i)
			housing_changed.emit(get_used(), get_capacity())
			return


func get_status_text() -> String:
	return "Logement : %d / %d" % [get_used(), get_capacity()]


# Sauvegarde
func get_save_data() -> Dictionary:
	return {"shelters": _shelters}


func load_save_data(data: Dictionary) -> void:
	_shelters = data.get("shelters", [])
	housing_changed.emit(get_used(), get_capacity())
