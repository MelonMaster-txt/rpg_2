# WorkbenchUI - Interface de craft (branché sur GameManager)
# Scène : CanvasLayer > Control > VBoxContainer
#   - Title (Label)
#   - ItemList (VBoxContainer)
#   - CloseButton (Button)
extends Control

@onready var item_list: VBoxContainer = $VBoxContainer/ItemList
@onready var close_btn: Button = $VBoxContainer/CloseButton

func _ready() -> void:
	add_to_group("workbench_ui")
	visible = false
	close_btn.pressed.connect(close)

func open() -> void:
	_build_list()
	visible = true
	get_tree().paused = true

func close() -> void:
	visible = false
	get_tree().paused = false

func _build_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	var db = get_node("/root/ItemDatabase")
	for item_id in db.get_craftable_items():
		var data = db.get_item(item_id)
		var can = db.can_craft(item_id, GameManager.inventory)

		var row = HBoxContainer.new()

		var lbl = Label.new()
		var recette_str = ", ".join(
			data["recette"].keys().map(func(k): return "%dx %s" % [data["recette"][k], k])
		)
		lbl.text = "%s  [%s]" % [data["nom"], recette_str]
		lbl.modulate = Color.WHITE if can else Color(0.5, 0.5, 0.5)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var btn = Button.new()
		btn.text = "Crafter"
		btn.disabled = not can
		btn.pressed.connect(_on_craft_pressed.bind(item_id))

		row.add_child(lbl)
		row.add_child(btn)
		item_list.add_child(row)

func _on_craft_pressed(item_id: String) -> void:
	var db = get_node("/root/ItemDatabase")
	var data = db.get_item(item_id)
	for resource in data["recette"]:
		GameManager.remove_item(resource, data["recette"][resource])
	GameManager.add_item(item_id, 1)
	_build_list()
