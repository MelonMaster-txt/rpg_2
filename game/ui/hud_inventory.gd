# HUD Inventaire - Affiché en permanence en bas de l'écran
# Scène : CanvasLayer > Control
#   - HeldLabel (Label) -- ancré en haut centre
#   - HBoxContainer    -- ancré en bas centre
extends Control

@onready var slots_container: HBoxContainer = $HBoxContainer
@onready var held_label: Label = $HeldLabel

const SLOT_ORDER: Array[String] = ["bois", "pierre", "baies", "graine_baie", "pioche", "arrosoir", "nourriture"]

var _slot_labels: Dictionary = {}

func _ready() -> void:
	add_to_group("hud_inventory")
	_build_slots()
	GameManager.inventory_changed.connect(_on_inventory_changed)
	_refresh_all()
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("held_item_changed"):
		player.held_item_changed.connect(_on_held_item_changed)

func _build_slots() -> void:
	var db: Node = get_node("/root/ItemDatabase")
	for item_id: String in SLOT_ORDER:
		var data: Dictionary = db.get_item(item_id)
		if data.is_empty():
			continue

		var slot := VBoxContainer.new()
		slot.name = item_id

		var icon_lbl := Label.new()
		icon_lbl.text = (data.get("nom", item_id) as String).left(3).to_upper()
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 10)

		var qty_lbl := Label.new()
		qty_lbl.name = "Qty"
		qty_lbl.text = "0"
		qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty_lbl.add_theme_font_size_override("font_size", 12)

		slot.add_child(icon_lbl)
		slot.add_child(qty_lbl)
		slots_container.add_child(slot)
		_slot_labels[item_id] = qty_lbl

func _refresh_all() -> void:
	for item_id: String in _slot_labels:
		var qty: int = GameManager.get_item(item_id)
		(_slot_labels[item_id] as Label).text = str(qty)
		var slot: Node = slots_container.get_node_or_null(item_id)
		if slot:
			(slot as CanvasItem).modulate = Color.WHITE if qty > 0 else Color(0.5, 0.5, 0.5)

func _on_inventory_changed(_item: String, _amount: int) -> void:
	_refresh_all()

func _on_held_item_changed(item_id: String) -> void:
	if item_id == "":
		held_label.text = ""
	else:
		var db: Node = get_node("/root/ItemDatabase")
		var data: Dictionary = db.get_item(item_id)
		held_label.text = "✋ " + (data.get("nom", item_id) as String)
