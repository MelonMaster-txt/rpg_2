# SaveSystem.gd — Autoload singleton
# Sauvegarde et charge toutes les données de jeu dans un fichier JSON
extends Node

const SAVE_PATH: String = "user://savegame.json"

# ─── SAUVEGARDE ──────────────────────────────────────────────────────────────
func save_game() -> void:
	var data: Dictionary = {
		# Temps
		"current_time": GameManager.current_time,
		"current_day":  GameManager.current_day,
		"hour":         GameManager.hour,
		"minute":       GameManager.minute,
		# Inventaire
		"inventory":    GameManager.inventory.duplicate(),
		# Niveau
		"player_level": GameManager.player_level,
		"player_xp":    GameManager.player_xp,
		# Position
		"player_pos_x": GameManager.saved_spawn_position.x,
		"player_pos_y": GameManager.saved_spawn_position.y,
		"has_saved_position": GameManager.has_saved_position,
		# Farm
		"farm_tiles": GameManager.farm_tiles_data.duplicate(deep),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: impossible d'ouvrir le fichier de sauvegarde")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("[SaveSystem] Sauvegarde OK — Jour %d %02d:%02d — Niveau %d" % [
		GameManager.current_day, GameManager.hour, GameManager.minute, GameManager.player_level
	])

# ─── CHARGEMENT ──────────────────────────────────────────────────────────────
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveSystem] Aucune sauvegarde trouvée.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: impossible de lire le fichier de sauvegarde")
		return false

	var json_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(json_text)
	if err != OK:
		push_error("SaveSystem: JSON invalide — " + json.get_error_message())
		return false

	var data: Dictionary = json.get_data()

	# Temps
	GameManager.current_time = float(data.get("current_time", 0.0))
	GameManager.current_day  = int(data.get("current_day", 1))
	GameManager.hour         = int(data.get("hour", 6))
	GameManager.minute       = int(data.get("minute", 0))

	# Inventaire
	var saved_inv: Dictionary = data.get("inventory", {})
	for key in saved_inv.keys():
		GameManager.inventory[key] = int(saved_inv[key])

	# Niveau
	GameManager.player_level = int(data.get("player_level", 1))
	GameManager.player_xp    = int(data.get("player_xp", 0))

	# Position
	var px: float = float(data.get("player_pos_x", 0.0))
	var py: float = float(data.get("player_pos_y", 0.0))
	GameManager.saved_spawn_position = Vector2(px, py)
	GameManager.has_saved_position   = bool(data.get("has_saved_position", false))

	# Farm
	GameManager.farm_tiles_data = data.get("farm_tiles", [])

	print("[SaveSystem] Chargement OK — Jour %d %02d:%02d — Niveau %d" % [
		GameManager.current_day, GameManager.hour, GameManager.minute, GameManager.player_level
	])
	return true

# ─── UTILITAIRE ──────────────────────────────────────────────────────────────
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("[SaveSystem] Sauvegarde supprimée.")
