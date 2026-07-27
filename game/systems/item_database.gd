# ItemDatabase - Autoload
# Pour ajouter un item : ajouter une entrée dans ITEMS
extends Node

const ITEMS: Dictionary = {
	"bois": {
		"nom": "Bois",
		"description": "Du bois brut coupé dans la forêt.",
		"icon": "res://game/assets/icons/bois.png",
		"stackable": true,
		"max_stack": 99,
		"craftable": false,
		"recette": {}
	},
	"pierre": {
		"nom": "Pierre",
		"description": "Une pierre ramassée par terre.",
		"icon": "res://game/assets/icons/pierre.png",
		"stackable": true,
		"max_stack": 99,
		"craftable": false,
		"recette": {}
	},
	"baies": {
		"nom": "Baies",
		"description": "Des baies comestibles. Restaure 10 HP.",
		"icon": "res://game/assets/icons/baies.png",
		"stackable": true,
		"max_stack": 99,
		"craftable": false,
		"recette": {},
		"consommable": true,
		"hp_restore": 10
	},
	"pioche": {
		"nom": "Pioche",
		"description": "Permet de bêcher la terre pour planter.",
		"icon": "res://game/assets/icons/pioche.png",
		"stackable": false,
		"max_stack": 1,
		"craftable": true,
		"recette": {"bois": 2, "pierre": 3}
	},
	"arrosoir": {
		"nom": "Arrosoir",
		"description": "Accélère la pousse des plantes x2.",
		"icon": "res://game/assets/icons/arrosoir.png",
		"stackable": false,
		"max_stack": 1,
		"craftable": true,
		"recette": {"bois": 3, "pierre": 1}
	},
	"graine_baie": {
		"nom": "Graine de baie",
		"description": "Se plante sur une tuile bêchée.",
		"icon": "res://game/assets/icons/graine_baie.png",
		"stackable": true,
		"max_stack": 99,
		"craftable": true,
		"recette": {"baies": 2}
	}
}

# Retourne les données d'un item, null si inexistant
func get_item(id: String) -> Dictionary:
	if ITEMS.has(id):
		return ITEMS[id]
	push_warning("ItemDatabase: item inconnu '%s'" % id)
	return {}

# Retourne tous les items craftables
func get_craftable_items() -> Array:
	var result = []
	for id in ITEMS:
		if ITEMS[id].get("craftable", false):
			result.append(id)
	return result

# Vérifie si l'inventaire a les ressources pour crafter un item
func can_craft(item_id: String, inventory: Dictionary) -> bool:
	var data = get_item(item_id)
	if data.is_empty() or not data.get("craftable", false):
		return false
	for resource in data["recette"]:
		var needed = data["recette"][resource]
		if inventory.get(resource, 0) < needed:
			return false
	return true
