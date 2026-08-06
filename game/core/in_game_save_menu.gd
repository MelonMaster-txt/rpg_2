extends CanvasLayer
# in_game_save_menu.gd
# Hiérarchie réelle dans in_game_save_menu.tscn :
#   InGameSaveMenu (CanvasLayer)
#     Panel
#       SaveMenu (instance save_menu.tscn)

signal resume_requested

@onready var _save_menu: Control = $Panel/SaveMenu


func _ready() -> void:
	if _save_menu == null:
		push_error("InGameSaveMenu: $Panel/SaveMenu introuvable")
		return
	_save_menu.visible = false


func open() -> void:
	if _save_menu:
		_save_menu.visible = true
	get_tree().paused = true


func close() -> void:
	if _save_menu:
		_save_menu.visible = false
	get_tree().paused = false
	resume_requested.emit()


# Callbacks connectés via .tscn
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
