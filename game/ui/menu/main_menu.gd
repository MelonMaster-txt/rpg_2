extends Control

const OVERWORLD_SCENE := "res://game/world/overworld.tscn"
const SAVE_MENU_SCENE := "res://game/core/save_menu.tscn"

@onready var btn_new_game   : Button = $ButtonContainer/BtnNewGame
@onready var btn_continue   : Button = $ButtonContainer/BtnContinue
@onready var btn_load_game  : Button = $ButtonContainer/BtnLoadGame
@onready var btn_quit       : Button = $ButtonContainer/BtnQuit

func _ready() -> void:
	# Active "Continue" seulement si un save existe
	var has_save := false
	for i in range(1, 4):
		if SaveSystem.slot_exists(i):
			has_save = true
			break
	btn_continue.disabled = not has_save
	btn_load_game.disabled = not has_save

# --- Nouveau jeu ---
func _on_btn_new_game_pressed() -> void:
	GameManager.reset()
	SceneManager.goto_scene(OVERWORLD_SCENE)

# --- Continuer (charge le save le plus récent) ---
func _on_btn_continue_pressed() -> void:
	var latest_slot := _get_latest_slot()
	if latest_slot == -1:
		return
	SaveSystem.load_game(latest_slot)
	SceneManager.goto_scene(OVERWORLD_SCENE)

# --- Charger une partie (ouvre le menu de slots) ---
func _on_btn_load_game_pressed() -> void:
	var save_menu = load(SAVE_MENU_SCENE).instantiate()
	save_menu.mode = "load"
	get_tree().root.add_child(save_menu)

# --- Quitter ---
func _on_btn_quit_pressed() -> void:
	get_tree().quit()

# Retourne le numéro du slot dont la date est la plus récente
func _get_latest_slot() -> int:
	var best_slot := -1
	var best_time := 0
	for i in range(1, 4):
		var info := SaveSystem.get_slot_info(i)
		if info.is_empty():
			continue
		# On compare via play_time comme approximation si pas de timestamp
		var t : int = info.get("play_time", 0)
		if t > best_time:
			best_time = t
			best_slot = i
	return best_slot
