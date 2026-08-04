# InGameSaveMenu — overlay Échap en jeu (CanvasLayer)
extends CanvasLayer

@onready var panel:     Control = $Panel
@onready var save_menu          = $Panel/SaveMenu

var _open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	call_deferred("_setup")


func _setup() -> void:
	if is_instance_valid(save_menu) and save_menu.has_method("setup"):
		save_menu.setup(1, true)  # 1 = SAVE, embedded


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		toggle()


func toggle() -> void:
	_open = not _open
	panel.visible = _open
	get_tree().paused = _open


func hide_menu() -> void:
	_open = false
	panel.hide()
	get_tree().paused = false


func _on_btn_save_mode_pressed() -> void:
	if is_instance_valid(save_menu):
		save_menu.setup(1, true)  # SAVE


func _on_btn_load_mode_pressed() -> void:
	if is_instance_valid(save_menu):
		save_menu.setup(0, true)  # LOAD


func _on_btn_resume_pressed() -> void:
	hide_menu()


func _on_btn_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://game/ui/menu/main_menu.tscn")
