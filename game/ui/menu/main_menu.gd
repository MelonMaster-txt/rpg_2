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
	get_tree().change_scene_to_file(GameState.OVERWORLD)


func _on_btn_continue_pressed() -> void:
	for slot in range(SaveSystem.MAX_SLOTS):
		if SaveSystem.slot_exists(slot):
			if SaveSystem.load_game(slot):
				get_tree().change_scene_to_file(GameState.current_scene)
				return


func _on_btn_load_game_pressed() -> void:
	# Passe en mode LOAD via métadonnée lue par save_menu au _ready()
	GameState.set_meta("open_save_menu_mode", 0)  # 0 = LOAD
	get_tree().change_scene_to_file("res://game/core/save_menu.tscn")


func _on_btn_quit_pressed() -> void:
	get_tree().quit()
