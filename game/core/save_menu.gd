extends Control

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal save_requested(slot_index: int)
signal load_requested(slot_index: int)

# ─── CONSTS ───────────────────────────────────────────────────────────────────
const MAX_SLOTS: int = 5

# ─── ONREADY ──────────────────────────────────────────────────────────────────
@onready var _slots_container: VBoxContainer = $VBoxContainer/SlotsContainer
@onready var _close_btn: Button = $VBoxContainer/CloseButton

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _save_system: Node = null

func _ready() -> void:
	_save_system = get_node_or_null("/root/SaveSystem")
	_close_btn.pressed.connect(_on_close_pressed)
	_build_slots()

func _build_slots() -> void:
	for i: int in range(MAX_SLOTS):
		var hbox := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "Slot %d" % (i + 1)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var save_btn := Button.new()
		save_btn.text = "Sauvegarder"
		save_btn.pressed.connect(_on_save_pressed.bind(i))
		var load_btn := Button.new()
		load_btn.text = "Charger"
		load_btn.pressed.connect(_on_load_pressed.bind(i))
		hbox.add_child(lbl)
		hbox.add_child(save_btn)
		hbox.add_child(load_btn)
		_slots_container.add_child(hbox)

func _on_save_pressed(slot_index: int) -> void:
	emit_signal("save_requested", slot_index)

func _on_load_pressed(slot_index: int) -> void:
	emit_signal("load_requested", slot_index)

func _on_close_pressed() -> void:
	hide()
