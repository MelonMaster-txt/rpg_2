# ItemDatabase - Autoload
# To add an item: add an entry to ITEMS
extends Node

const ITEMS: Dictionary = {
	"wood": {
		"name": "Wood",
		"description": "Raw wood chopped from the forest.",
		"icon": "res://game/assets/icons/wood.png",
		"stackable": true,
		"max_stack": 99,
		"craftable": false,
		"recipe": {}
	},
	"stone": {
		"name": "Stone",
		"description": "A stone picked up off the ground.",
		"icon": "res://game/assets/icons/stone.png",
		"stackable": true,
		"max_stack": 99,
		"craftable": false,
		"recipe": {}
	},
	"berries": {
		"name": "Berries",
		"description": "Edible berries. Restores 10 HP.",
		"icon": "res://game/assets/icons/berries.png",
		"stackable": true,
		"max_stack": 99,
		"craftable": false,
		"recipe": {},
		"consumable": true,
		"hp_restore": 10
	},
	"hoe": {
		"name": "Hoe",
		"description": "Used to till the soil for planting.",
		"icon": "res://game/assets/icons/hoe.png",
		"stackable": false,
		"max_stack": 1,
		"craftable": true,
		"recipe": {"wood": 2, "stone": 3}
	},
	"watering_can": {
		"name": "Watering Can",
		"description": "Speeds up plant growth x2.",
		"icon": "res://game/assets/icons/watering_can.png",
		"stackable": false,
		"max_stack": 1,
		"craftable": true,
		"recipe": {"wood": 3, "stone": 1}
	},
	"berry_seed": {
		"name": "Berry Seed",
		"description": "Plant it on tilled soil.",
		"icon": "res://game/assets/icons/berry_seed.png",
		"stackable": true,
		"max_stack": 99,
		"craftable": true,
		"recipe": {"berries": 2}
	}
}

# Returns item data, empty dict if not found
func get_item(id: String) -> Dictionary:
	if ITEMS.has(id):
		return ITEMS[id]
	push_warning("ItemDatabase: unknown item '%s'" % id)
	return {}

# Returns all craftable items
func get_craftable_items() -> Array:
	var result = []
	for id in ITEMS:
		if ITEMS[id].get("craftable", false):
			result.append(id)
	return result

# Checks if the inventory has the resources to craft an item
func can_craft(item_id: String, inventory: Dictionary) -> bool:
	var data = get_item(item_id)
	if data.is_empty() or not data.get("craftable", false):
		return false
	for resource in data["recipe"]:
		var needed = data["recipe"][resource]
		if inventory.get(resource, 0) < needed:
			return false
	return true
