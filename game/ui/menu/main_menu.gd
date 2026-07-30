extends Control

@onready var btn_continue: Button = $ButtonContainer/BtnContinue

func _ready() -> void:
	btn_continue.disabled = not (SaveSystem.slot_exists(0) or SaveSystem.slot_exists(1) or SaveSystem.slot_exists(2))
	$ButtonContainer.add_theme_constant_override("separation", 16)
	for b in [$ButtonContainer/BtnNewGame, $ButtonContainer/BtnContinue, $ButtonContainer/BtnLoadGame, $ButtonContainer/BtnQuit]:
		b.custom_minimum_size = Vector2(320, 60)

func _on_btn_new_game_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://game/main.tscn")

func _on_btn_continue_pressed() -> void:
	for slot in range(3):
		if SaveSystem.slot_exists(slot):
			if SaveSystem.load_game(slot):
				get_tree().change_scene_to_file(GameState.current_scene)
				return

func _on_btn_load_game_pressed() -> void:
	get_tree().change_scene_to_file("res://game/core/save_menu.gd")

func _on_btn_quit_pressed() -> void:
	get_tree().quit()
