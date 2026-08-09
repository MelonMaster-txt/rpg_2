# population_manager.gd -- Autoload
# Gere la liste des compagnons et esclaves du joueur.
# Verifie HousingManager avant tout ajout.
extends Node

signal population_changed
signal housing_full(role: String)

var companions: Array[Dictionary] = []
var slaves:     Array[Dictionary] = []


func _ready() -> void:
	pass


func _get_km() -> Node:
	return Engine.get_singleton("KingdomManager")


func _get_hm() -> Node:
	return Engine.get_singleton("HousingManager")


# --- Compagnons ---

func add_companion(entry: Dictionary) -> bool:
	var hm: Node = _get_hm()
	if hm != null and not hm.can_house():
		housing_full.emit("companion")
		print("[PopulationManager] Pas de place pour loger un compagnon !")
		return false
	entry["role"] = "companion"
	companions.append(entry)
	var km: Node = _get_km()
	if km:
		km.add_member(entry)
	population_changed.emit()
	return true


func remove_companion(npc_name: String) -> void:
	for i: int in range(companions.size() - 1, -1, -1):
		if companions[i].get("name", "") == npc_name:
			companions.remove_at(i)
			population_changed.emit()
			return


func get_companions() -> Array[Dictionary]:
	return companions


# --- Esclaves ---

func add_slave(entry: Dictionary) -> bool:
	var hm: Node = _get_hm()
	if hm != null and not hm.can_house():
		housing_full.emit("slave")
		print("[PopulationManager] Pas de place pour loger un esclave !")
		return false
	entry["role"] = "slave"
	slaves.append(entry)
	var km: Node = _get_km()
	if km:
		km.add_member(entry)
	population_changed.emit()
	return true


func remove_slave(npc_name: String) -> void:
	for i: int in range(slaves.size() - 1, -1, -1):
		if slaves[i].get("name", "") == npc_name:
			slaves.remove_at(i)
			population_changed.emit()
			return


func get_slaves() -> Array[Dictionary]:
	return slaves


func get_all() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	all.append_array(companions)
	all.append_array(slaves)
	return all


func get_total_count() -> int:
	return companions.size() + slaves.size()


# --- Sauvegarde ---

func get_save_data() -> Dictionary:
	return {
		"companions": companions,
		"slaves":     slaves,
	}


func load_save_data(data: Dictionary) -> void:
	companions = data.get("companions", [])
	slaves     = data.get("slaves",     [])
	population_changed.emit()
