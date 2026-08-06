# MainMenu — menu principal
extends Control

@onready var btn_continue: Button = $ButtonContainer/BtnContinue


func _ready() -> void:
	# Sécurité : la pause doit toujours être désactivée sur le menu principal
	get_tree().paused = false
	var any_save: bool = false
	for slot: int in range(SaveSystem.MAX_SLOTS):
		if SaveSystem.slot_exists(slot):
			any_save = true
			break
	btn_continue.disabled = not any_save


func _on_btn_new_game_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file.call_deferred(GameState.OVERWORLD)


func _on_btn_continue_pressed() -> void:
	for slot: int in range(SaveSystem.MAX_SLOTS):
		if SaveSystem.slot_exists(slot):
			if SaveSystem.load_game(slot):
				get_tree().change_scene_to_file.call_deferred(GameState.current_scene)
				return


func _on_btn_load_game_pressed() -> void:
	GameState.set_meta("open_save_menu_mode", 0)
	get_tree().change_scene_to_file.call_deferred("res://game/core/save_menu.tscn")


func _on_btn_quit_pressed() -> void:
	get_tree().quit()
