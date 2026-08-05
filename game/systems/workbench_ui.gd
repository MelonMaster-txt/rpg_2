# WorkbenchUI - uses ItemDatabase (autoload) + GameManager
extends Control

@onready var item_list: VBoxContainer = $VBoxContainer/ItemList
@onready var close_btn: Button        = $VBoxContainer/CloseButton

func _ready() -> void:
	add_to_group("workbench_ui")
	visible = false
	close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
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

	var craftable: Array = ItemDatabase.get_craftable_items()
	for item_id in craftable:
		var data: Dictionary = ItemDatabase.get_item(item_id)
		var can: bool = ItemDatabase.can_craft(item_id, GameManager.inventory)

		var row := HBoxContainer.new()

		var lbl := Label.new()
		var keys: Array = data["recipe"].keys()
		var parts: Array = []
		for k in keys:
			parts.append("%dx %s" % [data["recipe"][k], k])
		var recipe_str: String = ", ".join(parts)
		lbl.text = "%s  [%s]" % [data["name"], recipe_str]
		lbl.modulate = Color.WHITE if can else Color(0.5, 0.5, 0.5)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var btn := Button.new()
		btn.text = "Craft"
		btn.disabled = not can
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.pressed.connect(_on_craft_pressed.bind(item_id))

		row.add_child(lbl)
		row.add_child(btn)
		item_list.add_child(row)

func _on_craft_pressed(item_id: String) -> void:
	var data: Dictionary = ItemDatabase.get_item(item_id)
	var resources: Array = data["recipe"].keys()
	for resource in resources:
		GameManager.remove_item(resource, data["recipe"][resource])
	GameManager.add_item(item_id, 1)
	_build_list()
