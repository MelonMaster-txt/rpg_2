# in_game_save_menu.gd
extends CanvasLayer

signal resume_requested

@onready var _panel: Control = $Panel
@onready var _save_menu: Control = $Panel/SaveMenu


func _ready() -> void:
	_panel.visible = false
	if _save_menu:
		_save_menu.visible = false


func open() -> void:
	_panel.visible = true
	if _save_menu:
		_save_menu.visible = false
	get_tree().paused = true


func close() -> void:
	_panel.visible = false
	if _save_menu:
		_save_menu.visible = false
	get_tree().paused = false
	resume_requested.emit()


func _on_btn_resume_pressed() -> void:
	close()


func _on_btn_save_mode_pressed() -> void:
	if _save_menu:
		_save_menu.set_mode("save")
		_save_menu.visible = true


func _on_btn_load_mode_pressed() -> void:
	if _save_menu:
		_save_menu.set_mode("load")
		_save_menu.visible = true


func _on_btn_quit_to_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred("res://game/ui/menu/main_menu.tscn")
