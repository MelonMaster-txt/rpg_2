# WorkbenchUI - Interface de craft
# Scène : CanvasLayer > Control > VBoxContainer
#   - Title (Label)
#   - ItemList (VBoxContainer) -- généré dynamiquement
#   - CloseButton (Button)
extends Control

@onready var item_list: VBoxContainer = $VBoxContainer/ItemList
@onready var close_btn: Button = $VBoxContainer/CloseButton

var _inventory: Dictionary = {}

func _ready() -> void:
	add_to_group("workbench_ui")
	visible = false
	close_btn.pressed.connect(close)

func open() -> void:
	# Récupère l'inventaire du joueur
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_inventory"):
		_inventory = player.get_inventory()
	_build_list()
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _build_list() -> void:
	# Vide la liste
	for child in item_list.get_children():
		child.queue_free()

	var db = get_node("/root/ItemDatabase")
	for item_id in db.get_craftable_items():
		var data = db.get_item(item_id)
		var row = HBoxContainer.new()

		var lbl = Label.new()
		var can = db.can_craft(item_id, _inventory)
		var recette_str = ", ".join(
			data["recette"].keys().map(func(k): return "%dx %s" % [data["recette"][k], k])
		)
		lbl.text = "%s  [%s]" % [data["nom"], recette_str]
		lbl.modulate = Color.WHITE if can else Color(0.5, 0.5, 0.5)

		var btn = Button.new()
		btn.text = "Crafter"
		btn.disabled = not can
		btn.pressed.connect(_on_craft_pressed.bind(item_id))

		row.add_child(lbl)
		row.add_child(btn)
		item_list.add_child(row)

func _on_craft_pressed(item_id: String) -> void:
	var db = get_node("/root/ItemDatabase")
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var data = db.get_item(item_id)
	# Retire les ressources
	for resource in data["recette"]:
		player.remove_item(resource, data["recette"][resource])
	# Donne l'item crafté
	player.add_item(item_id, 1)
	# Rafraîchit l'UI
	_inventory = player.get_inventory()
	_build_list()
