# SaveSystem — Autoload singleton
# Gère lecture / écriture des sauvegardes JSON (8 slots)
extends Node

const SAVE_DIR := "user://saves/"
const SAVE_EXTENSION := ".json"
const MAX_SLOTS := 8


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_%d%s" % [slot, SAVE_EXTENSION]


func save_game(slot: int) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	GameState.sync_from_game_manager()
	var data := GameState.to_dict()
	data["save_date"] = Time.get_datetime_string_from_system()
	data["slot"] = slot
	var file := FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("[SaveSystem] Impossible d'écrire la sauvegarde slot %d" % slot)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[SaveSystem] Slot %d sauvegardé." % slot)
	return true


func load_game(slot: int) -> bool:
	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		push_error("[SaveSystem] Erreur JSON slot %d" % slot)
		return false
	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	GameState.from_dict(data)
	GameState.apply_to_game_manager()
	print("[SaveSystem] Slot %d chargé." % slot)
	return true


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(get_save_path(slot))


func get_slot_info(slot: int) -> Dictionary:
	if not slot_exists(slot):
		return {}
	var file := FileAccess.open(get_save_path(slot), FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return {}
	file.close()
	var data = json.get_data()
	return {
		"save_date": data.get("save_date", ""),
		"player_name": data.get("player_name", "?"),
		"player_level": data.get("player_level", 1),
		"play_time": data.get("play_time", 0.0),
		"day_count": data.get("day_count", 1),
	}


func delete_save(slot: int) -> void:
	if slot_exists(slot):
		DirAccess.remove_absolute(get_save_path(slot))
		print("[SaveSystem] Slot %d supprimé." % slot)
