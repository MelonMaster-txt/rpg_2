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
	$ButtonContainer.add_theme_constant_override("separation", 16)
	for b in [$ButtonContainer/BtnNewGame, $ButtonContainer/BtnContinue, $ButtonContainer/BtnLoadGame, $ButtonContainer/BtnQuit]:
		b.custom_minimum_size = Vector2(320, 60)


func _on_btn_new_game_pressed() -> void:
	GameState.reset()
	GameState.apply_to_game_manager()
	get_tree().change_scene_to_file("res://game/main.tscn")


func _on_btn_continue_pressed() -> void:
	for slot in range(SaveSystem.MAX_SLOTS):
		if SaveSystem.slot_exists(slot):
			if SaveSystem.load_game(slot):
				get_tree().change_scene_to_file(GameState.current_scene)
				return


func _on_btn_load_game_pressed() -> void:
	var menu = load("res://game/core/save_menu.tscn").instantiate()
	menu.mode = SaveMenu.Mode.LOAD
	get_tree().root.add_child(menu)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = menu


func _on_btn_quit_pressed() -> void:
	get_tree().quit()
