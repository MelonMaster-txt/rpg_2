# SaveSystem — Autoload singleton
extends Node

const SAVE_DIR       := "user://saves/"
const SAVE_EXTENSION := ".json"
const MAX_SLOTS      := 8


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_%d%s" % [slot, SAVE_EXTENSION]


func save_game(slot: int) -> bool:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if has_node("/root/GameManager"):
		GameState.sync_from_game_manager()
	var data: Dictionary = GameState.to_dict()
	data["save_date"] = Time.get_datetime_string_from_system()
	data["slot"]      = slot
	var file := FileAccess.open(get_save_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("[SaveSystem] Cannot write slot %d" % slot)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[SaveSystem] Slot %d saved." % slot)
	return true


func load_game(slot: int) -> bool:
	var path := get_save_path(slot)
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		push_error("[SaveSystem] Invalid JSON slot %d" % slot)
		return false
	file.close()
	var parsed: Variant = json.get_data()
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	GameState.from_dict(parsed as Dictionary)
	if has_node("/root/GameManager"):
		GameState.apply_to_game_manager()
	print("[SaveSystem] Slot %d loaded." % slot)
	return true


func delete_slot(slot: int) -> void:
	var path := get_save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		print("[SaveSystem] Slot %d deleted." % slot)


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
	var parsed: Variant = json.get_data()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = parsed as Dictionary
	var raw_play: float = float(d.get("play_time", 0.0))
	var play_sec: int = int(raw_play)
	return {
		"save_date":    str(d.get("save_date",    "")),
		"player_name":  str(d.get("player_name",  "?")),
		"player_level": int(d.get("player_level", 1)),
		"play_time":    play_sec,
		"day_count":    int(d.get("day_count",    1)),
		"time_string":  str(d.get("time_string",  "06:00")),
	}
