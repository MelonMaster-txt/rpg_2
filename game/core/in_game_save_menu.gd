# InGameSaveMenu — overlay accessible via Escape en jeu
extends CanvasLayer

@onready var panel: Control = $Panel
@onready var save_menu: Control = $Panel/CenterBox/SaveMenu

var _visible: bool = false


func _ready() -> void:
	# ALWAYS pour recevoir les inputs même quand le jeu est pausé
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	if save_menu.has_method("setup"):
		save_menu.setup(0)  # 0 = Mode.SAVE


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		toggle()


func toggle() -> void:
	_visible = not _visible
	panel.visible = _visible
	get_tree().paused = _visible


func hide_menu() -> void:
	_visible = false
	panel.hide()
	get_tree().paused = false


func _on_btn_save_mode_pressed() -> void:
	if save_menu.has_method("setup"):
		save_menu.setup(0)  # SAVE


func _on_btn_load_mode_pressed() -> void:
	if save_menu.has_method("setup"):
		save_menu.setup(1)  # LOAD


func _on_btn_resume_pressed() -> void:
	hide_menu()


func _on_btn_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://game/ui/menu/main_menu.tscn")
