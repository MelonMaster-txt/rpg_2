extends Control

@onready var slots := [$GridContainer/Slot1, $GridContainer/Slot2, $GridContainer/Slot3, $GridContainer/Slot4, $GridContainer/Slot5, $GridContainer/Slot6, $GridContainer/Slot7, $GridContainer/Slot8]

func _ready() -> void:
	_refresh_slots()

func _refresh_slots() -> void:
	for i in range(slots.size()):
		var btn: Button = slots[i]
		if SaveSystem.slot_exists(i):
			var info = SaveSystem.get_slot_info(i)
			btn.text = "Slot %d | %s | Niv %d | Jour %d" % [i + 1, info.get("player_name", ""), info.get("player_level", 1), info.get("day_count", 1)]
			btn.disabled = false
		else:
			btn.text = "Slot %d | Vide" % (i + 1)
			btn.disabled = true

func _load_slot(slot: int) -> void:
	if SaveSystem.load_game(slot):
		get_tree().change_scene_to_file(GameState.current_scene)

func _on_slot_0_pressed() -> void:
	_load_slot(0)

func _on_slot_1_pressed() -> void:
	_load_slot(1)

func _on_slot_2_pressed() -> void:
	_load_slot(2)

func _on_slot_3_pressed() -> void:
	_load_slot(3)


func _on_slot_4_pressed() -> void:
	_load_slot(4)


func _on_slot_5_pressed() -> void:
	_load_slot(5)


func _on_slot_6_pressed() -> void:
	_load_slot(6)


func _on_slot_7_pressed() -> void:
	_load_slot(7)


func _on_slot_8_pressed() -> void:
	_load_slot(8)
	
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://game/ui/menu/main_menu.tscn")
