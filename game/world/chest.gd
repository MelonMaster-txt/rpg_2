# chest.gd
# Coffre global de la cahute / overworld.
extends Node2D

const ICON := "📦"

var inventory: Dictionary = {
	"food":         0,
	"wood":         0,
	"stone":        0,
	"ore":          0,
	"gold":         0,
	"build_points": 0,
}

signal item_deposited(resource: String, amount: int)
signal inventory_changed(inventory: Dictionary)

var _player_near: bool = false
var _ui_open: bool = false

@onready var label: Label        = $Label
@onready var hint_label: Label   = $HintLabel if has_node("HintLabel") else null
@onready var detection: Area2D   = $DetectionArea if has_node("DetectionArea") else null
@onready var chest_ui_layer: CanvasLayer = $ChestUILayer if has_node("ChestUILayer") else null
@onready var chest_ui: Control   = $ChestUILayer/ChestUI if has_node("ChestUILayer/ChestUI") else null
@onready var ui_content: VBoxContainer = $ChestUILayer/ChestUI/Panel/VBox/Content if has_node("ChestUILayer/ChestUI/Panel/VBox/Content") else null
@onready var btn_close: Button   = $ChestUILayer/ChestUI/Panel/VBox/BtnClose if has_node("ChestUILayer/ChestUI/Panel/VBox/BtnClose") else null

func _ready() -> void:
	add_to_group("chest")
	_refresh_label()

	if detection != null:
		detection.body_entered.connect(_on_body_entered)
		detection.body_exited.connect(_on_body_exited)

	if btn_close != null:
		btn_close.pressed.connect(close_ui)

	if chest_ui != null:
		chest_ui.visible = false

	if hint_label != null:
		hint_label.visible = false

# ─── Interaction joueur ───────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or chest_ui == null:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _ui_open:
			close_ui()
		else:
			open_ui()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		if hint_label != null:
			hint_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		if hint_label != null:
			hint_label.visible = false
		if _ui_open:
			close_ui()

# ─── UI ───────────────────────────────────────────────────────────────────────

func open_ui() -> void:
	if chest_ui_layer == null or chest_ui == null or ui_content == null:
		return
	_ui_open = true
	chest_ui.visible = true
	get_tree().paused = true
	chest_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_ui()

func close_ui() -> void:
	_ui_open = false
	if chest_ui != null:
		chest_ui.visible = false
	get_tree().paused = false

func _refresh_ui() -> void:
	if ui_content == null:
		return
	for child in ui_content.get_children():
		child.queue_free()
	for key in inventory:
		if inventory[key] <= 0:
			continue
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = _icon_for(key) + "  " + key
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var qty_lbl := Label.new()
		qty_lbl.text = str(inventory[key])
		qty_lbl.modulate = Color(1.0, 0.85, 0.4)
		row.add_child(name_lbl)
		row.add_child(qty_lbl)
		ui_content.add_child(row)
	if ui_content.get_child_count() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "(vide)"
		empty_lbl.modulate = Color(0.6, 0.6, 0.6)
		ui_content.add_child(empty_lbl)

func _icon_for(key: String) -> String:
	var icons := {
		"food": "🍖", "wood": "🪵", "stone": "🪨",
		"ore": "⛏", "gold": "💰", "build_points": "🔨",
		"seed_berries": "🫐", "seed_wheat": "🌾", "seed_herb": "🌿",
		"herb": "🌿",
	}
	return icons.get(key, ICON)

func _refresh_label() -> void:
	if label == null:
		return
	var lines: Array[String] = [ICON + " Coffre"]
	for key in inventory:
		if inventory[key] > 0:
			lines.append("%s: %d" % [key, inventory[key]])
	label.text = "\n".join(lines)

# ─── Dépôt ────────────────────────────────────────────────────────────────────

func deposit(resource: String, amount: int) -> void:
	if amount <= 0:
		return
	if not inventory.has(resource):
		inventory[resource] = 0
	inventory[resource] += amount
	item_deposited.emit(resource, amount)
	inventory_changed.emit(inventory)
	_refresh_label()
	if _ui_open:
		_refresh_ui()
	print("[Chest] +%d %s (total: %d)" % [amount, resource, inventory[resource]])
