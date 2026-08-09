# chest.gd
extends Node2D

const ICON: String = "\ud83d\udce6"

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
var _ui_open:     bool = false
var _ui_layer:    CanvasLayer = null

@onready var label:      Label  = $Label
@onready var hint_label: Label  = $HintLabel       if has_node("HintLabel")    else null
@onready var detection:  Area2D = $DetectionArea   if has_node("DetectionArea") else null


func _ready() -> void:
	add_to_group("chest")
	_refresh_label()
	if hint_label != null:
		hint_label.visible = false
	# Connexion avec CONNECT_REFERENCE_COUNTED pour éviter double-connect
	if detection != null:
		if not detection.body_entered.is_connected(_on_body_entered):
			detection.body_entered.connect(_on_body_entered)
		if not detection.body_exited.is_connected(_on_body_exited):
			detection.body_exited.connect(_on_body_exited)


# ─── Interaction joueur ──────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not _player_near:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _ui_open:
			_close_ui()
		else:
			_open_ui()


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
			_close_ui()


# ─── UI créée par code ────────────────────────────────────────────────

func _open_ui() -> void:
	_ui_open = true
	if _ui_layer != null and is_instance_valid(_ui_layer):
		_ui_layer.queue_free()
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 50
	_ui_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().current_scene.add_child(_ui_layer)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(260, 320)
	panel.position = Vector2(-130, -160)
	_ui_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = ICON + " Coffre"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	var has_items := false
	for key: String in inventory:
		if inventory[key] <= 0:
			continue
		has_items = true
		var row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = _icon_for(key) + "  " + key
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var qty_lbl := Label.new()
		qty_lbl.text = str(inventory[key])
		qty_lbl.modulate = Color(1.0, 0.85, 0.4)
		row.add_child(name_lbl)
		row.add_child(qty_lbl)
		content.add_child(row)
	if not has_items:
		var empty := Label.new()
		empty.text = "(vide)"
		empty.modulate = Color(0.6, 0.6, 0.6)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(empty)

	var btn := Button.new()
	btn.text = "Fermer  [E]"
	btn.pressed.connect(_close_ui)
	vbox.add_child(btn)


func _close_ui() -> void:
	_ui_open = false
	if _ui_layer != null and is_instance_valid(_ui_layer):
		_ui_layer.queue_free()
		_ui_layer = null


# ─── Helpers ────────────────────────────────────────────────────────

func _icon_for(key: String) -> String:
	var icons: Dictionary = {
		"food": "\ud83e\uddb4", "wood": "\ud83e\udeb5", "stone": "\ud83e\udea8",
		"ore": "\u26cf", "gold": "\ud83d\udcb0", "build_points": "\ud83d\udd28",
		"berries": "\ud83ced", "seed_wheat": "\ud83c\udf3e", "herb": "\ud83c\udf3f",
	}
	return icons.get(key, ICON)


func _refresh_label() -> void:
	if label == null:
		return
	var lines: Array[String] = [ICON + " Coffre"]
	for key: String in inventory:
		if inventory[key] > 0:
			lines.append("%s: %d" % [key, inventory[key]])
	label.text = "\n".join(lines)


# ─── Dépôt ──────────────────────────────────────────────────────────
func deposit(resource: String, amount: int) -> void:
	if amount <= 0:
		return
	if not inventory.has(resource):
		inventory[resource] = 0
	inventory[resource] += amount
	item_deposited.emit(resource, amount)
	inventory_changed.emit(inventory)
	_refresh_label()
	print("[Chest] +%d %s (total: %d)" % [amount, resource, inventory[resource]])
