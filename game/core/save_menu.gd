# save_menu.gd
# Aligné sur la hiérarchie réelle de save_menu.tscn :
# SaveMenu > GridContainer > Slot1..Slot8, Back
# SaveMenu > DeleteButton
# SaveMenu > ConfirmPanel > VBox > ConfirmLabel, Buttons > Yes, No
extends Control

signal save_requested(slot_index: int)
signal load_requested(slot_index: int)

const MAX_SLOTS: int = 8

@onready var _grid:          GridContainer = $GridContainer
@onready var _delete_btn:    Button        = $DeleteButton
@onready var _confirm_panel: Panel         = $ConfirmPanel
@onready var _confirm_label: Label         = $ConfirmPanel/VBox/ConfirmLabel
@onready var _yes_btn:       Button        = $ConfirmPanel/VBox/Buttons/Yes
@onready var _no_btn:        Button        = $ConfirmPanel/VBox/Buttons/No

var _selected_slot: int = -1
var _mode: String = "save"  # "save" ou "load"


func _ready() -> void:
	_confirm_panel.visible = false
	_yes_btn.pressed.connect(_on_confirm_yes_pressed)
	_no_btn.pressed.connect(_on_confirm_no_pressed)
	_delete_btn.pressed.connect(_on_delete_button_pressed)
	_refresh_slots()


func set_mode(mode: String) -> void:
	_mode = mode
	_refresh_slots()


func _refresh_slots() -> void:
	for i in range(1, MAX_SLOTS + 1):
		var slot_btn: Button = _grid.get_node_or_null("Slot%d" % i)
		if slot_btn == null:
			continue
		var slot_idx: int = i - 1
		# Déconnecte les anciens signaux pour éviter les doublons
		if slot_btn.pressed.is_connected(_on_slot_pressed.bind(slot_idx)):
			slot_btn.pressed.disconnect(_on_slot_pressed.bind(slot_idx))
		slot_btn.pressed.connect(_on_slot_pressed.bind(slot_idx))
		var save_sys: Node = get_node_or_null("/root/SaveSystem")
		if save_sys != null and save_sys.has_method("slot_exists"):
			slot_btn.text = ("Slot %d \u2605" if save_sys.slot_exists(slot_idx) else "Slot %d") % i
		else:
			slot_btn.text = "Slot %d" % i
	# Bouton Back
	var back_btn: Button = _grid.get_node_or_null("Back")
	if back_btn and not back_btn.pressed.is_connected(_on_back_pressed):
		back_btn.pressed.connect(_on_back_pressed)


func _on_slot_pressed(slot_idx: int) -> void:
	_selected_slot = slot_idx
	if _mode == "save":
		emit_signal("save_requested", slot_idx)
	else:
		emit_signal("load_requested", slot_idx)


func _on_delete_button_pressed() -> void:
	if _selected_slot < 0:
		return
	_confirm_label.text = "Supprimer Slot %d ?" % (_selected_slot + 1)
	_confirm_panel.visible = true


func _on_confirm_yes_pressed() -> void:
	_confirm_panel.visible = false
	var save_sys: Node = get_node_or_null("/root/SaveSystem")
	if save_sys != null and save_sys.has_method("delete_slot"):
		save_sys.delete_slot(_selected_slot)
	_refresh_slots()


func _on_confirm_no_pressed() -> void:
	_confirm_panel.visible = false


func _on_back_pressed() -> void:
	hide()


# Slots connectés via tscn — on garde les méthodes pour compatibilité
func _on_slot_1_pressed() -> void: _on_slot_pressed(0)
func _on_slot_2_pressed() -> void: _on_slot_pressed(1)
func _on_slot_3_pressed() -> void: _on_slot_pressed(2)
func _on_slot_4_pressed() -> void: _on_slot_pressed(3)
func _on_slot_5_pressed() -> void: _on_slot_pressed(4)
func _on_slot_6_pressed() -> void: _on_slot_pressed(5)
func _on_slot_7_pressed() -> void: _on_slot_pressed(6)
func _on_slot_8_pressed() -> void: _on_slot_pressed(7)
