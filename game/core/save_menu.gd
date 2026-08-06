# save_menu.gd
# Les signaux Slot1-8, Back, DeleteButton, Yes, No
# sont DEJA connectés dans save_menu.tscn via [connection].
# On ne reconnecte PAS dans _ready().
extends Control

signal save_requested(slot_index: int)
signal load_requested(slot_index: int)

const MAX_SLOTS: int = 8
const MAIN_MENU: String = "res://game/ui/menu/main_menu.tscn"

@onready var _grid:          GridContainer = $GridContainer
@onready var _confirm_panel: Panel         = $ConfirmPanel
@onready var _confirm_label: Label         = $ConfirmPanel/VBox/ConfirmLabel

var _selected_slot: int = -1
var _mode: String       = "save"
# Stocke la scène depuis laquelle save_menu a été ouvert
# "main_menu" ou "in_game"
var _origin: String = "main_menu"


func _ready() -> void:
	if _confirm_panel:
		_confirm_panel.visible = false
	# Détermine l'origine via le meta posé par l'appelant
	if GameState.has_meta("open_save_menu_mode"):
		_origin = "main_menu"
	else:
		_origin = "in_game"
	_refresh_slots()


func set_mode(mode: String) -> void:
	_mode = mode
	_refresh_slots()


func _refresh_slots() -> void:
	var save_sys: Node = get_node_or_null("/root/SaveSystem")
	for i in range(1, MAX_SLOTS + 1):
		var slot_btn: Button = _grid.get_node_or_null("Slot%d" % i)
		if slot_btn == null:
			continue
		if save_sys != null and save_sys.has_method("slot_exists"):
			slot_btn.text = ("Slot %d \u2605" if save_sys.slot_exists(i - 1) else "Slot %d") % i
		else:
			slot_btn.text = "Slot %d" % i


# ---- Callbacks connectés via .tscn ----------------------------------------
func _on_slot_1_pressed() -> void: _handle_slot(0)
func _on_slot_2_pressed() -> void: _handle_slot(1)
func _on_slot_3_pressed() -> void: _handle_slot(2)
func _on_slot_4_pressed() -> void: _handle_slot(3)
func _on_slot_5_pressed() -> void: _handle_slot(4)
func _on_slot_6_pressed() -> void: _handle_slot(5)
func _on_slot_7_pressed() -> void: _handle_slot(6)
func _on_slot_8_pressed() -> void: _handle_slot(7)

func _handle_slot(slot_idx: int) -> void:
	_selected_slot = slot_idx
	if _mode == "save":
		save_requested.emit(slot_idx)
	else:
		load_requested.emit(slot_idx)


func _on_back_pressed() -> void:
	if _origin == "main_menu":
		# On est une scène standalone : retour au menu principal
		if GameState.has_meta("open_save_menu_mode"):
			GameState.remove_meta("open_save_menu_mode")
		get_tree().change_scene_to_file.call_deferred(MAIN_MENU)
	else:
		# On est instancié dans in_game_save_menu : juste se cacher
		hide()


func _on_delete_button_pressed() -> void:
	if _selected_slot < 0:
		return
	if _confirm_label:
		_confirm_label.text = "Supprimer Slot %d ?" % (_selected_slot + 1)
	if _confirm_panel:
		_confirm_panel.visible = true


func _on_confirm_yes_pressed() -> void:
	if _confirm_panel:
		_confirm_panel.visible = false
	var save_sys: Node = get_node_or_null("/root/SaveSystem")
	if save_sys != null and save_sys.has_method("delete_slot"):
		save_sys.delete_slot(_selected_slot)
	_refresh_slots()


func _on_confirm_no_pressed() -> void:
	if _confirm_panel:
		_confirm_panel.visible = false
