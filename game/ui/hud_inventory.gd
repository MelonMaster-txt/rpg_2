# HUD Inventaire - Affiché en permanence en bas de l'écran
# Scène : CanvasLayer > Control
#   - HBoxContainer (slots)
#     - Pour chaque item : VBoxContainer > [TextureRect (icon), Label (qty)]
#   - Label (held_label) -- indique l'item en main en haut
extends Control

@onready var slots_container: HBoxContainer = $HBoxContainer
@onready var held_label: Label = $HeldLabel

# Ordre d'affichage dans le HUD
const SLOT_ORDER: Array = ["bois", "pierre", "baies", "graine_baie", "pioche", "arrosoir", "nourriture"]

var _slot_labels: Dictionary = {}  # item_id -> Label (quantité)

func _ready() -> void:
	add_to_group("hud_inventory")
	_build_slots()
	GameManager.inventory_changed.connect(_on_inventory_changed)
	_refresh_all()
	# Écoute le changement d'item en main
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("held_item_changed"):
		player.held_item_changed.connect(_on_held_item_changed)

func _build_slots() -> void:
	var db = get_node("/root/ItemDatabase")
	for item_id in SLOT_ORDER:
		var data = db.get_item(item_id)
		if data.is_empty():
			continue

		var slot = VBoxContainer.new()
		slot.name = item_id

		# Icône placeholder (remplace par TextureRect + texture si icônes dispo)
		var icon_lbl = Label.new()
		icon_lbl.text = data.get("nom", item_id).left(3).to_upper()
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 10)

		var qty_lbl = Label.new()
		qty_lbl.name = "Qty"
		qty_lbl.text = "0"
		qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		qty_lbl.add_theme_font_size_override("font_size", 12)

		slot.add_child(icon_lbl)
		slot.add_child(qty_lbl)
		slots_container.add_child(slot)
		_slot_labels[item_id] = qty_lbl

func _refresh_all() -> void:
	for item_id in _slot_labels:
		var qty = GameManager.get_item(item_id)
		_slot_labels[item_id].text = str(qty)
		# Grise le slot si quantité 0
		var slot = slots_container.get_node_or_null(item_id)
		if slot:
			slot.modulate = Color.WHITE if qty > 0 else Color(0.5, 0.5, 0.5)

func _on_inventory_changed(_item: String, _amount: int) -> void:
	_refresh_all()

func _on_held_item_changed(item_id: String) -> void:
	if item_id == "":
		held_label.text = ""
	else:
		var db = get_node("/root/ItemDatabase")
		var data = db.get_item(item_id)
		held_label.text = "✋ " + data.get("nom", item_id)
