# SaveMenu — 8 slots, utilisable seul ou embarqué dans InGameSaveMenu
extends Control

enum Mode { LOAD = 0, SAVE = 1 }

var mode: Mode     = Mode.SAVE
var embedded: bool = false

@onready var title_label:   Label  = $TitleLabel
@onready var back_btn:      Button = $GridContainer/Back
@onready var confirm_panel: Panel  = $ConfirmPanel
@onready var confirm_label: Label  = $ConfirmPanel/VBox/ConfirmLabel
@onready var slots: Array[Button]  = [
	$GridContainer/Slot1, $GridContainer/Slot2,
	$GridContainer/Slot3, $GridContainer/Slot4,
	$GridContainer/Slot5, $GridContainer/Slot6,
	$GridContainer/Slot7, $GridContainer/Slot8,
]

var _pending_slot: int  = -1
var _pending_action: String = ""


func _ready() -> void:
	confirm_panel.hide()
	if GameState.has_meta("open_save_menu_mode"):
		mode = GameState.get_meta("open_save_menu_mode") as Mode
		GameState.remove_meta("open_save_menu_mode")
	_apply_embedded()
	_refresh_slots()


# ── API publique
func setup(p_mode: int, p_embedded: bool = false) -> void:
	mode     = p_mode as Mode
	embedded = p_embedded
	_apply_embedded()
	_refresh_slots()


func _apply_embedded() -> void:
	title_label.visible = not embedded
	back_btn.visible    = not embedded
	if not embedded:
		match mode:
			Mode.LOAD: title_label.text = "Charger"
			Mode.SAVE: title_label.text = "Sauvegarder"


func _refresh_slots() -> void:
	for i in range(slots.size()):
		var btn := slots[i]
		btn.disabled = false
		if SaveSystem.slot_exists(i):
			var info := SaveSystem.get_slot_info(i)
			btn.text = "Slot %d\n%s • Niv %d\nJour %d • %s" % [
				i + 1,
				str(info.get("player_name",  "?")),
				int(info.get("player_level", 1)),
				int(info.get("day_count",    1)),
				str(info.get("time_string",  "??:??")),
			]
		else:
			btn.text = "Slot %d\n— Vide —" % (i + 1)
			if mode == Mode.LOAD:
				btn.disabled = true


func _slot_pressed(slot: int) -> void:
	if mode == Mode.LOAD and not SaveSystem.slot_exists(slot):
		return
	_pending_slot = slot
	if SaveSystem.slot_exists(slot):
		_pending_action = ("Écraser" if mode == Mode.SAVE else "Charger")
		confirm_label.text = "%s le slot %d ?" % [_pending_action, slot + 1]
		confirm_panel.show()
	else:
		_execute(slot)


func _execute(slot: int) -> void:
	if mode == Mode.SAVE:
		SaveSystem.save_game(slot)
		_refresh_slots()
	else:
		if SaveSystem.load_game(slot):
			var parent = get_parent()
			if parent != null and parent.has_method("hide_menu"):
				parent.hide_menu()
			else:
				get_tree().paused = false
			get_tree().change_scene_to_file(GameState.current_scene)
		else:
			push_error("[SaveMenu] Échec chargement slot %d" % slot)


# Handlers slots
func _on_slot_1_pressed() -> void: _slot_pressed(0)
func _on_slot_2_pressed() -> void: _slot_pressed(1)
func _on_slot_3_pressed() -> void: _slot_pressed(2)
func _on_slot_4_pressed() -> void: _slot_pressed(3)
func _on_slot_5_pressed() -> void: _slot_pressed(4)
func _on_slot_6_pressed() -> void: _slot_pressed(5)
func _on_slot_7_pressed() -> void: _slot_pressed(6)
func _on_slot_8_pressed() -> void: _slot_pressed(7)

# Handlers confirm
func _on_confirm_yes_pressed() -> void:
	confirm_panel.hide()
	if _pending_slot >= 0:
		_execute(_pending_slot)
	_pending_slot = -1

func _on_confirm_no_pressed() -> void:
	confirm_panel.hide()
	_pending_slot = -1

# Back (visible seulement en mode standalone)
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://game/ui/menu/main_menu.tscn")
