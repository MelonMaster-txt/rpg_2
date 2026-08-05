extends CanvasLayer

const SLOT_COUNT: int = 8

@onready var _slots: HBoxContainer = $HotbarPanel/SlotsRow

var _selected_slot: int = 0
var _slot_nodes: Array[Control] = []


func _ready() -> void:
	_build_hotbar()


func _build_hotbar() -> void:
	if _slots == null:
		push_error("Hotbar: nœud SlotsRow introuvable dans hotbar.tscn")
		return
	for i: int in range(SLOT_COUNT):
		var slot := Panel.new()
		slot.custom_minimum_size = Vector2(40, 40)
		_slots.add_child(slot)
		_slot_nodes.append(slot)
	_highlight_slot(0)


func _input(event: InputEvent) -> void:
	# FIX: is_action_just_pressed n'existe pas sur InputEventMouseMotion
	# On filtre uniquement les évènements clavier / manette
	if not (event is InputEventKey or event is InputEventJoypadButton):
		return
	for i: int in range(SLOT_COUNT):
		if event.is_action_pressed("hotbar_%d" % (i + 1)):
			_selected_slot = i
			_highlight_slot(i)
			get_viewport().set_input_as_handled()
			return


func _highlight_slot(index: int) -> void:
	for i: int in range(_slot_nodes.size()):
		_slot_nodes[i].modulate = Color.WHITE if i != index else Color(1.4, 1.4, 0.4)
