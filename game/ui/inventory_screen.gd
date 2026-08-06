extends Control

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal closed

# ─── CONSTS ───────────────────────────────────────────────────────────────────
const ITEMS_PER_ROW: int = 6

# ─── ONREADY — chemins alignés sur inventory_screen.tscn ──────────────────────
@onready var _grid:      GridContainer = $BG/Panel/VBox/Content/Left/ScrollContainer/Grid
@onready var _close_btn: Button        = $BG/Panel/VBox/TopBar/CloseBtn
@onready var _item_label: Label        = $Tooltip/Label

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _slot_nodes: Dictionary = {}


func _ready() -> void:
	_close_btn.pressed.connect(_on_close)
	GameManager.inventory_changed.connect(_on_inventory_changed)
	_grid.columns = ITEMS_PER_ROW
	_build_grid()


func toggle() -> void:
	if visible:
		hide()
	else:
		show()
		_build_grid()


func _build_grid() -> void:
	for child in _grid.get_children():
		child.queue_free()
	_slot_nodes.clear()
	for key: String in GameManager.inventory:
		var btn := Button.new()
		btn.text = "%s\n%d" % [key, GameManager.inventory[key]]
		btn.custom_minimum_size = Vector2(80, 60)
		btn.pressed.connect(_on_slot_pressed.bind(key))
		_grid.add_child(btn)
		_slot_nodes[key] = btn


func _on_inventory_changed(item: String, amount: int) -> void:
	if _slot_nodes.has(item):
		_slot_nodes[item].text = "%s\n%d" % [item, amount]
	else:
		_build_grid()


func _on_slot_pressed(item: String) -> void:
	var qty: int = GameManager.get_item(item)
	_item_label.text = "%s : %d" % [item, qty]
	var tooltip: Node = get_node_or_null("Tooltip")
	if tooltip:
		tooltip.visible = true


func _on_close() -> void:
	hide()
	closed.emit()
