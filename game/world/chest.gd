# chest.gd
# Coffre global de la cahute.
# Le joueur appuie sur [E] pour ouvrir l'UI du coffre.
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

@onready var label: Label                  = $Label
@onready var hint_label: Label             = $HintLabel
@onready var detection: Area2D             = $DetectionArea
@onready var chest_ui_layer: CanvasLayer   = $ChestUILayer
@onready var chest_ui: Control             = $ChestUILayer/ChestUI
@onready var ui_content: VBoxContainer     = $ChestUILayer/ChestUI/Panel/VBox/Content
@onready var btn_close: Button             = $ChestUILayer/ChestUI/Panel/VBox/BtnClose

func _ready() -> void:
	add_to_group("chest")
	_refresh_label()
	detection.body_entered.connect(_on_body_entered)
	detection.body_exited.connect(_on_body_exited)
	btn_close.pressed.connect(close_ui)
	chest_ui.visible = false
	if hint_label:
		hint_label.visible = false

# ─── Interaction joueur ───────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _player_near and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _ui_open:
			close_ui()
		else:
			open_ui()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = true
		if hint_label:
			hint_label.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_near = false
		if hint_label:
			hint_label.visible = false
		if _ui_open:
			close_ui()

# ─── UI ───────────────────────────────────────────────────────────────────────

func open_ui() -> void:
	_ui_open = true
	chest_ui.visible = true
	get_tree().paused = true
	chest_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	_refresh_ui()

func close_ui() -> void:
	_ui_open = false
	chest_ui.visible = false
	get_tree().paused = false

func _refresh_ui() -> void:
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
	return icons.get(key, "📦")

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
