extends Control

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal crafted(recipe_id: String)

# ─── EXPORTS ──────────────────────────────────────────────────────────────────
@export var recipes: Array[Resource] = []

# ─── ONREADY ──────────────────────────────────────────────────────────────────
@onready var _list: VBoxContainer = $MarginContainer/VBox/RecipeList
@onready var _close_btn: Button = $MarginContainer/VBox/CloseButton
@onready var _info_label: Label = $MarginContainer/VBox/InfoLabel

func _ready() -> void:
	_close_btn.pressed.connect(hide)
	_build_list()

func _build_list() -> void:
	for recipe: Resource in recipes:
		if recipe == null:
			continue
		var btn := Button.new()
		btn.text = recipe.get("recipe_name") if recipe.get("recipe_name") else "?"
		btn.pressed.connect(_on_recipe_pressed.bind(recipe))
		_list.add_child(btn)

func _on_recipe_pressed(recipe: Resource) -> void:
	var recipe_id: String = recipe.get("recipe_id") if recipe.get("recipe_id") else ""
	if recipe_id.is_empty():
		return
	var raw_cost: Variant = recipe.get("cost")
	var cost: Dictionary = raw_cost as Dictionary if raw_cost is Dictionary else {}
	for item: String in cost:
		if GameManager.get_item(item) < cost[item]:
			_info_label.text = "Ressources insuffisantes."
			return
	for item: String in cost:
		GameManager.remove_item(item, cost[item])
	var output: String = recipe.get("output") if recipe.get("output") else ""
	var qty: int = recipe.get("output_qty") if recipe.get("output_qty") else 1
	if not output.is_empty():
		GameManager.add_item(output, qty)
	_info_label.text = "Fabriqué : %s x%d" % [output, qty]
	crafted.emit(recipe_id)
