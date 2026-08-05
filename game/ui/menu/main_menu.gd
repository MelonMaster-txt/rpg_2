# MainMenu — menu principal
extends Control

@onready var btn_continue: Button = $ButtonContainer/BtnContinue


func _ready() -> void:
	var any_save := false
	for slot in range(SaveSystem.MAX_SLOTS):
		if SaveSystem.slot_exists(slot):
			any_save = true
			break
	btn_continue.disabled = not any_save


func _on_btn_new_game_pressed() -> void:
	GameState.reset()
	# FIX : change_scene_to_file attend un String, pas une constante via Autoload
	# GameState.OVERWORLD est bien une const String → on la passe directement
	var overworld_path: String = GameState.OVERWORLD
	get_tree().change_scene_to_file(overworld_path)


func _on_btn_continue_pressed() -> void:
	for slot in range(SaveSystem.MAX_SLOTS):
		if SaveSystem.slot_exists(slot):
			if SaveSystem.load_game(slot):
				var scene_path: String = GameState.current_scene
				get_tree().change_scene_to_file(scene_path)
				return


func _on_btn_load_game_pressed() -> void:
	GameState.set_meta("open_save_menu_mode", 0)
	get_tree().change_scene_to_file("res://game/core/save_menu.tscn")


func _on_btn_quit_pressed() -> void:
	get_tree().quit()
