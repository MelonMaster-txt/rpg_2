# chest.gd
# Coffre global de la cahute.
# Autoload NON — placé comme nœud unique dans la scène principale.
# Accès : get_tree().get_first_node_in_group("chest")
extends Node2D

const ICON := "📦"

# Inventaire du coffre
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

@onready var label: Label = $Label

func _ready() -> void:
	add_to_group("chest")
	_refresh_label()

# ─── Dépôt ───────────────────────────────────────────────────────────────────

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

# ─── UI ──────────────────────────────────────────────────────────────────────

func _refresh_label() -> void:
	if label == null:
		return
	var lines: Array[String] = [ICON + " Coffre"]
	for key in inventory:
		if inventory[key] > 0:
			lines.append("%s: %d" % [key, inventory[key]])
	label.text = "\n".join(lines)
