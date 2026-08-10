# main_menu.gd
# Menu principal du jeu.
# Flux :
#   Nouvelle Partie → CharacterCustomization → World
#   Continuer       → World (via SaveSystem)
#   Charger         → save_menu.tscn
#   Quitter         → get_tree().quit()
extends Control

const CUSTOMIZATION_SCENE: String = "res://game/ui/character_customization_ui.tscn"
const SAVE_MENU_SCENE:      String = "res://game/core/save_menu.tscn"

@onready var _btn_new_game:  Button = $ButtonContainer/BtnNewGame
@onready var _btn_continue:  Button = $ButtonContainer/BtnContinue
@onready var _btn_load_game: Button = $ButtonContainer/BtnLoadGame
@onready var _btn_quit:      Button = $ButtonContainer/BtnQuit


func _ready() -> void:
	# Active Continuer seulement si une sauvegarde existe
	var any_save: bool = false
	for slot: int in range(SaveSystem.MAX_SLOTS):
		if SaveSystem.slot_exists(slot):
			any_save = true
			break
	_btn_continue.disabled = not any_save

	_btn_new_game.pressed.connect(_on_new_game)
	_btn_continue.pressed.connect(_on_continue)
	_btn_load_game.pressed.connect(_on_load_game)
	_btn_quit.pressed.connect(_on_quit)


func _on_new_game() -> void:
	GameState.reset()
	# Va vers l'écran de customisation avant de lancer le monde
	get_tree().change_scene_to_file(CUSTOMIZATION_SCENE)


func _on_continue() -> void:
	for slot: int in range(SaveSystem.MAX_SLOTS):
		if SaveSystem.slot_exists(slot):
			if SaveSystem.load_game(slot):
				get_tree().change_scene_to_file(GameState.current_scene)
				return


func _on_load_game() -> void:
	GameState.set_meta("open_save_menu_mode", 0)
	get_tree().change_scene_to_file(SAVE_MENU_SCENE)


func _on_quit() -> void:
	get_tree().quit()
