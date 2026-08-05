extends CanvasLayer

# ─── CONSTS ───────────────────────────────────────────────────────────────────
const SLOT_COUNT: int = 8

# ─── ONREADY ──────────────────────────────────────────────────────────────────
@onready var _slots: HBoxContainer = $HBoxContainer

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _selected_slot: int = 0
var _slot_nodes: Array[Control] = []

func _ready() -> void:
	_build_hotbar()

func _build_hotbar() -> void:
	for i: int in range(SLOT_COUNT):
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(40, 40)
		_slots.add_child(slot)
		_slot_nodes.append(slot)
	_highlight_slot(0)

func _input(event: InputEvent) -> void:
	for i: int in range(SLOT_COUNT):
		if event.is_action_just_pressed("hotbar_%d" % (i + 1)):
			_selected_slot = i
			_highlight_slot(i)
			return

func _highlight_slot(index: int) -> void:
	for i: int in range(_slot_nodes.size()):
		_slot_nodes[i].modulate = Color.WHITE if i != index else Color(1.4, 1.4, 0.4)
