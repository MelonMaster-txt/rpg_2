# population_manager.gd — Autoload
# Gère la liste des compagnons et esclaves du joueur.
# Utilise Engine.get_singleton() pour éviter les erreurs de compilation
# dues à l'ordre de chargement des Autoloads.
extends Node

signal population_changed

var companions: Array[Dictionary] = []
var slaves:     Array[Dictionary] = []


func _ready() -> void:
	pass


func _get_km() -> Node:
	return Engine.get_singleton("KingdomManager")


# --- Compagnons ---

func add_companion(entry: Dictionary) -> void:
	entry["role"] = "companion"
	companions.append(entry)
	var km: Node = _get_km()
	if km:
		km.add_member(entry)
	population_changed.emit()


func remove_companion(npc_name: String) -> void:
	for i: int in range(companions.size() - 1, -1, -1):
		if companions[i].get("name", "") == npc_name:
			companions.remove_at(i)
			population_changed.emit()
			return


func get_companions() -> Array[Dictionary]:
	return companions


# --- Esclaves ---

func add_slave(entry: Dictionary) -> void:
	entry["role"] = "slave"
	slaves.append(entry)
	var km: Node = _get_km()
	if km:
		km.add_member(entry)
	population_changed.emit()


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
