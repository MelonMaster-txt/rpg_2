# housing_manager.gd -- Autoload : HousingManager
# Gere tous les batiments de logement : tentes (compagnons) et prisons (esclaves).
# Chaque batiment s'enregistre avec register_building().
# L'UI gestionnaire lit get_all_buildings() pour afficher le tableau.
extends Node

signal housing_changed

# Types de batiments
enum BuildingType { TENT, PRISON }

# Niveaux de tente
const TENT_LEVELS: Array[Dictionary] = [
	{ "level": 1, "name": "Petite tente",    "capacity": 1, "cost": { "wood": 10 } },
	{ "level": 2, "name": "Grande tente",    "capacity": 2, "cost": { "wood": 20, "stone": 5 } },
	{ "level": 3, "name": "Tente renforcee", "capacity": 3, "cost": { "wood": 30, "stone": 15, "gold": 5 } },
]

# Niveaux de prison
const PRISON_LEVELS: Array[Dictionary] = [
	{ "level": 1, "name": "Prison rudimentaire", "capacity": 2, "cost": { "wood": 15, "stone": 20 } },
	{ "level": 2, "name": "Prison renforcee",    "capacity": 4, "cost": { "wood": 20, "stone": 40, "gold": 10 } },
	{ "level": 3, "name": "Donjon",              "capacity": 8, "cost": { "stone": 60, "gold": 25 } },
]

# Structure d'un batiment :
# {
#   id: String, type: BuildingType, level: int,
#   slots: Array[Dictionary]  <- { slot_id: String, occupant: String (npc_name ou "") }
# }
var _buildings: Array[Dictionary] = []
var _next_id: int = 0


func _ready() -> void:
	pass


# --- Enregistrement ---

func register_building(type: BuildingType, level: int = 1) -> String:
	var id: String = "building_%d" % _next_id
	_next_id += 1
	var capacity: int = _get_capacity(type, level)
	var slots: Array[Dictionary] = []
	for i: int in range(capacity):
		slots.append({ "slot_id": "%s_slot_%d" % [id, i], "occupant": "" })
	_buildings.append({
		"id":    id,
		"type":  type,
		"level": level,
		"slots": slots,
	})
	housing_changed.emit()
	print("[HousingManager] Batiment enregistre : %s (type=%d lvl=%d cap=%d)" % [id, type, level, capacity])
	return id


func unregister_building(id: String) -> void:
	for i: int in range(_buildings.size() - 1, -1, -1):
		if _buildings[i]["id"] == id:
			_buildings.remove_at(i)
			housing_changed.emit()
			return


# --- Amelioration ---

func upgrade_building(id: String) -> bool:
	var b: Dictionary = _find(id)
	if b.is_empty():
		return false
	var max_level: int = TENT_LEVELS.size() if b["type"] == BuildingType.TENT else PRISON_LEVELS.size()
	if b["level"] >= max_level:
		print("[HousingManager] Deja au niveau max : %s" % id)
		return false
	var new_level: int = b["level"] + 1
	var new_cap: int = _get_capacity(b["type"], new_level)
	var old_cap: int = b["slots"].size()
	for i: int in range(old_cap, new_cap):
		b["slots"].append({ "slot_id": "%s_slot_%d" % [id, i], "occupant": "" })
	b["level"] = new_level
	housing_changed.emit()
	print("[HousingManager] Ameliore %s -> niveau %d" % [id, new_level])
	return true


func get_upgrade_cost(id: String) -> Dictionary:
	var b: Dictionary = _find(id)
	if b.is_empty():
		return {}
	var next_level: int = b["level"] + 1
	var table: Array = TENT_LEVELS if b["type"] == BuildingType.TENT else PRISON_LEVELS
	if next_level > table.size():
		return {}
	return table[next_level - 1]["cost"]


# --- Assignation de slots ---

# Assigne un NPC a un slot libre du bon type
func assign_occupant(building_id: String, slot_id: String, npc_name: String) -> bool:
	var b: Dictionary = _find(building_id)
	if b.is_empty():
		return false
	for slot: Dictionary in b["slots"]:
		if slot["slot_id"] == slot_id:
			slot["occupant"] = npc_name
			housing_changed.emit()
			return true
	return false


func free_occupant(npc_name: String) -> void:
	for b: Dictionary in _buildings:
		for slot: Dictionary in b["slots"]:
			if slot["occupant"] == npc_name:
				slot["occupant"] = ""
	housing_changed.emit()


func find_free_slot(type: BuildingType) -> Dictionary:
	for b: Dictionary in _buildings:
		if b["type"] != type:
			continue
		for slot: Dictionary in b["slots"]:
			if slot["occupant"] == "":
				return { "building_id": b["id"], "slot_id": slot["slot_id"] }
	return {}


# --- Capacite globale ---

func can_house_companion() -> bool:
	return not find_free_slot(BuildingType.TENT).is_empty()


func can_house_slave() -> bool:
	return not find_free_slot(BuildingType.PRISON).is_empty()


func get_capacity_for(type: BuildingType) -> int:
	var total: int = 0
	for b: Dictionary in _buildings:
		if b["type"] == type:
			total += b["slots"].size()
	return total


func get_used_for(type: BuildingType) -> int:
	var total: int = 0
	for b: Dictionary in _buildings:
		if b["type"] != type:
			continue
		for slot: Dictionary in b["slots"]:
			if slot["occupant"] != "":
				total += 1
	return total


# --- Lecture ---

func get_all_buildings() -> Array[Dictionary]:
	return _buildings


func get_buildings_of_type(type: BuildingType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for b: Dictionary in _buildings:
		if b["type"] == type:
			result.append(b)
	return result


func get_building_name(b: Dictionary) -> String:
	var table: Array = TENT_LEVELS if b["type"] == BuildingType.TENT else PRISON_LEVELS
	var lvl: int = clamp(b["level"] - 1, 0, table.size() - 1)
	return table[lvl]["name"]


# --- Helpers ---

func _find(id: String) -> Dictionary:
	for b: Dictionary in _buildings:
		if b["id"] == id:
			return b
	return {}


func _get_capacity(type: BuildingType, level: int) -> int:
	var table: Array = TENT_LEVELS if type == BuildingType.TENT else PRISON_LEVELS
	var idx: int = clamp(level - 1, 0, table.size() - 1)
	return table[idx]["capacity"]


# --- Sauvegarde ---

func get_save_data() -> Dictionary:
	return { "buildings": _buildings, "next_id": _next_id }


func load_save_data(data: Dictionary) -> void:
	_buildings = data.get("buildings", [])
	_next_id   = data.get("next_id", 0)
	housing_changed.emit()
