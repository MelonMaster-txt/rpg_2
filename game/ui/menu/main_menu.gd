# game/ui/main_menu/main_menu.gd
extends Control

@onready var btn_continue = $ButtonContainer/BtnContinue

func _ready() -> void:
	# Désactive "Continuer" si aucune save n'existe
	btn_continue.disabled = not (
		SaveSystem.slot_exists(0) or 
		SaveSystem.slot_exists(1) or 
		SaveSystem.slot_exists(2)
	)

func _on_btn_new_game_pressed() -> void:
	# Reset l'état et lance le jeu
	GameState.from_dict({})
	SceneManager.change_scene("res://game/world/world.tscn")

func _on_btn_continue_pressed() -> void:
	# Charge le slot le plus récent (slot 0 par défaut)
	if SaveSystem.load_game(0):
		SceneManager.change_scene(GameState.current_scene)

func _on_btn_load_game_pressed() -> void:
	# Ouvre le menu de sélection de slot
	SceneManager.change_scene("res://game/ui/save_menu/save_menu.tscn")

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
