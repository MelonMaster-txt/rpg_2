# SaveMenu — menu save/load (8 slots, disposition GridContainer originale)
extends Control

enum Mode { LOAD, SAVE }
var mode: Mode = Mode.LOAD

@onready var slots: Array = [
	$GridContainer/Slot1,
	$GridContainer/Slot2,
	$GridContainer/Slot3,
	$GridContainer/Slot4,
	$GridContainer/Slot5,
	$GridContainer/Slot6,
	$GridContainer/Slot7,
	$GridContainer/Slot8,
]
@onready var confirm_panel: Panel = $ConfirmPanel
@onready var confirm_label: Label = $ConfirmPanel/VBox/ConfirmLabel

var _pending_slot: int = -1


func _ready() -> void:
	confirm_panel.hide()
	_refresh_slots()


func setup(p_mode: Mode) -> void:
	mode = p_mode
	_refresh_slots()


func _refresh_slots() -> void:
	for i in range(slots.size()):
		var btn: Button = slots[i]
		btn.disabled = false
		if SaveSystem.slot_exists(i):
			var info := SaveSystem.get_slot_info(i)
			var pt := int(info.get("play_time", 0.0))
			var h := pt / 3600
			var m := (pt % 3600) / 60
			btn.text = "Slot %d\n%s • Niv %d\nJour %d • %02dh%02d" % [
				i + 1,
				info.get("player_name", "?"),
				info.get("player_level", 1),
				info.get("day_count", 1),
				h, m
			]
		else:
			btn.text = "Slot %d\n— Vide —" % (i + 1)
			if mode == Mode.LOAD:
				btn.disabled = true


func _on_slot_pressed(slot: int) -> void:
	_pending_slot = slot
	if mode == Mode.SAVE and SaveSystem.slot_exists(slot):
		confirm_label.text = "Écraser le slot %d ?" % (slot + 1)
		confirm_panel.show()
	elif mode == Mode.LOAD and SaveSystem.slot_exists(slot):
		confirm_label.text = "Charger le slot %d ?" % (slot + 1)
		confirm_panel.show()
	else:
		_execute_action(slot)


func _execute_action(slot: int) -> void:
	if mode == Mode.SAVE:
		SaveSystem.save_game(slot)
		_refresh_slots()
	else:
		if SaveSystem.load_game(slot):
			get_tree().change_scene_to_file(GameState.current_scene)


func _on_slot_1_pressed() -> void: _on_slot_pressed(0)
func _on_slot_2_pressed() -> void: _on_slot_pressed(1)
func _on_slot_3_pressed() -> void: _on_slot_pressed(2)
func _on_slot_4_pressed() -> void: _on_slot_pressed(3)
func _on_slot_5_pressed() -> void: _on_slot_pressed(4)
func _on_slot_6_pressed() -> void: _on_slot_pressed(5)
func _on_slot_7_pressed() -> void: _on_slot_pressed(6)
func _on_slot_8_pressed() -> void: _on_slot_pressed(7)


func _on_confirm_yes_pressed() -> void:
	confirm_panel.hide()
	_execute_action(_pending_slot)


func _on_confirm_no_pressed() -> void:
	confirm_panel.hide()
	_pending_slot = -1


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://game/ui/menu/main_menu.tscn")
