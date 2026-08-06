extends Control

# ─── CONSTS ───────────────────────────────────────────────────────────────────
const SHOWN_ITEMS: Array[String] = [
	"wood", "berries", "stone", "gold", "flint"
]

# ─── ONREADY ──────────────────────────────────────────────────────────────────
@onready var _container: HBoxContainer = $HBoxContainer

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _labels: Dictionary = {}


func _ready() -> void:
	GameManager.inventory_changed.connect(_on_inventory_changed)
	_build_slots()


func _build_slots() -> void:
	for key: String in SHOWN_ITEMS:
		var lbl: Label = Label.new()
		lbl.text = "%s:0" % key
		_container.add_child(lbl)
		_labels[key] = lbl


func _on_inventory_changed(item: String, amount: int) -> void:
	if _labels.has(item):
		_labels[item].text = "%s:%d" % [item, amount]
