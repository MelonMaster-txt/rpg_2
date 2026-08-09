# population_manager.gd -- Autoload
# Verifie HousingManager (tente pour compagnons, prison pour esclaves) avant ajout.
extends Node

signal population_changed
signal housing_full(role: String)  # emis si pas de batiment disponible

var companions: Array[Dictionary] = []
var slaves:     Array[Dictionary] = []


func _ready() -> void:
	pass


func _get_km() -> Node:
	return Engine.get_singleton("KingdomManager")


func _get_hm() -> Node:
	return Engine.get_singleton("HousingManager")


# --- Compagnons (tente) ---

func add_companion(entry: Dictionary) -> bool:
	var hm: Node = _get_hm()
	if hm != null:
		var slot: Dictionary = hm.find_free_slot(hm.BuildingType.TENT)
		if slot.is_empty():
			housing_full.emit("companion")
			print("[PopulationManager] Pas de tente disponible pour %s" % entry.get("name", "?"))
			return false
		hm.assign_occupant(slot["building_id"], slot["slot_id"], entry.get("name", "?"))
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
			var hm: Node = _get_hm()
			if hm != null:
				hm.free_occupant(npc_name)
			population_changed.emit()
			return


func get_companions() -> Array[Dictionary]:
	return companions


# --- Esclaves (prison) ---

func add_slave(entry: Dictionary) -> bool:
	var hm: Node = _get_hm()
	if hm != null:
		var slot: Dictionary = hm.find_free_slot(hm.BuildingType.PRISON)
		if slot.is_empty():
			housing_full.emit("slave")
			print("[PopulationManager] Pas de cellule disponible pour %s" % entry.get("name", "?"))
			return false
		hm.assign_occupant(slot["building_id"], slot["slot_id"], entry.get("name", "?"))
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
			var hm: Node = _get_hm()
			if hm != null:
				hm.free_occupant(npc_name)
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


func get_save_data() -> Dictionary:
	return { "companions": companions, "slaves": slaves }


func load_save_data(data: Dictionary) -> void:
	companions = data.get("companions", [])
	slaves     = data.get("slaves",     [])
	population_changed.emit()
