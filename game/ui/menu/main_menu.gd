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
	# FIX : call_deferred évite le crash "grow_direction out of bounds"
	# qui survient quand change_scene est appelé depuis un signal Button.pressed
	get_tree().change_scene_to_file.call_deferred(GameState.OVERWORLD)


func _on_btn_continue_pressed() -> void:
	for slot in range(SaveSystem.MAX_SLOTS):
		if SaveSystem.slot_exists(slot):
			if SaveSystem.load_game(slot):
				get_tree().change_scene_to_file.call_deferred(GameState.current_scene)
				return


func _on_btn_load_game_pressed() -> void:
	GameState.set_meta("open_save_menu_mode", 0)
	get_tree().change_scene_to_file.call_deferred("res://game/core/save_menu.tscn")


func _on_btn_quit_pressed() -> void:
	get_tree().quit()
