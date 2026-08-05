# ItemDatabase — Autoload
# Catalogue complet des items : ressources, outils, consommables, équipements.
# Structure d'un item :
#   name        : String   — nom affiché
#   description : String   — tooltip
#   category    : String   — "ressource" | "ingredient" | "outil" | "consommable" | "equipement"
#   tier        : int      — 1=primitif, 2=pierre, 3=avancé
#   stackable   : bool
#   max_stack   : int
#   craftable   : bool
#   recipe      : Dictionary  { item_id: quantite }
#   consumable  : bool     — peut être utilisé depuis l'inventaire
#   hp_restore  : int      — PV restaurés à la consommation
#   buffs       : Array    — [{ "stat": String, "amount": int, "duration": float }]
#   equip_slot  : String   — "armor" | "shield" | "amulet" | "weapon" | ""
#   equip_stats : Dictionary — { stat: bonus }
extends Node

const ITEMS: Dictionary = {

	# ══════════════════════════════════════════════
	# RESSOURCES BRUTES
	# ══════════════════════════════════════════════
	"wood": {
		"name": "Bois", "description": "Bois brut coupé en forêt.",
		"category": "ressource", "tier": 1,
		"stackable": true, "max_stack": 99, "craftable": false, "recipe": {}
	},
	"stone": {
		"name": "Pierre", "description": "Pierre ramassée dans la nature.",
		"category": "ressource", "tier": 1,
		"stackable": true, "max_stack": 99, "craftable": false, "recipe": {}
	},
	"berries": {
		"name": "Baies", "description": "Baies comestibles. Restaure 10 PV.",
		"category": "consommable", "tier": 1,
		"stackable": true, "max_stack": 99, "craftable": false, "recipe": {},
		"consumable": true, "hp_restore": 10, "buffs": []
	},
	"mushroom": {
		"name": "Champignon", "description": "Champignon sauvage. Ingredient de cuisine.",
		"category": "ressource", "tier": 1,
		"stackable": true, "max_stack": 99, "craftable": false, "recipe": {}
	},
	"flint": {
		"name": "Silex", "description": "Pierre dure. Indispensable pour les outils primitifs.",
		"category": "ressource", "tier": 1,
		"stackable": true, "max_stack": 99, "craftable": false, "recipe": {}
	},
	"herb": {
		"name": "Herbe Médicinale", "description": "Pousse en clairière. Base des potions.",
		"category": "ressource", "tier": 1,
		"stackable": true, "max_stack": 99, "craftable": false, "recipe": {}
	},
	"resin": {
		"name": "Résine", "description": "Seve d'arbre durcie. Sert de colle naturelle.",
		"category": "ressource", "tier": 1,
		"stackable": true, "max_stack": 99, "craftable": false, "recipe": {}
	},
	"bone": {
		"name": "Os", "description": "Reste d'animal. Solide mais fragile.",
		"category": "ressource", "tier": 1,
		"stackable": true, "max_stack": 99, "craftable": false, "recipe": {}
	},

	# ══════════════════════════════════════════════
	# INGREDIENTS INTERMEDIAIRES (Tier 1)
	# ══════════════════════════════════════════════
	"corde": {
		"name": "Corde", "description": "Fibres tressées. Nécessaire pour arcs et pièges.",
		"category": "ingredient", "tier": 1,
		"stackable": true, "max_stack": 99,
		"craftable": true, "recipe": {"herb": 3}
	},
	"colle_resine": {
		"name": "Colle Resine", "description": "Adhesif naturel. Renforce les outils en pierre.",
		"category": "ingredient", "tier": 1,
		"stackable": true, "max_stack": 99,
		"craftable": true, "recipe": {"resin": 2}
	},
	"cuir": {
		"name": "Cuir Brut", "description": "Peau traitee. Necessite os et resin pour tanner.",
		"category": "ingredient", "tier": 2,
		"stackable": true, "max_stack": 50,
		"craftable": true, "recipe": {"bone": 2, "resin": 1}
	},

	# ══════════════════════════════════════════════
	# OUTILS AGRICOLES
	# ══════════════════════════════════════════════
	"hoe": {
		"name": "Houe", "description": "Permet de labourer la terre pour planter.",
		"category": "outil", "tier": 1,
		"stackable": false, "max_stack": 1,
		"craftable": true, "recipe": {"wood": 2, "flint": 2}
	},
	"watering_can": {
		"name": "Arrosoir", "description": "Accelere la croissance des plantes x2.",
		"category": "outil", "tier": 1,
		"stackable": false, "max_stack": 1,
		"craftable": true, "recipe": {"wood": 3, "stone": 1}
	},
	"berry_seed": {
		"name": "Graine de Baie", "description": "A planter sur sol laboure.",
		"category": "ressource", "tier": 1,
		"stackable": true, "max_stack": 99,
		"craftable": true, "recipe": {"berries": 2}
	},

	# ══════════════════════════════════════════════
	# OUTILS PRIMITIFS (Tier 1 — silex)
	# ══════════════════════════════════════════════
	"couteau_silex": {
		"name": "Couteau Silex", "description": "Outil polyvalent. Permet de recolter cuir et chair.",
		"category": "outil", "tier": 1,
		"stackable": false, "max_stack": 1,
		"craftable": true, "recipe": {"flint": 2, "wood": 1},
		"equip_slot": "weapon", "equip_stats": {"force": 2}
	},
	"hache_silex": {
		"name": "Hache Silex", "description": "Coupe le bois plus vite. +1 bois par recolte.",
		"category": "outil", "tier": 1,
		"stackable": false, "max_stack": 1,
		"craftable": true, "recipe": {"flint": 3, "wood": 2, "corde": 1},
		"equip_slot": "weapon", "equip_stats": {"force": 3}
	},
	"pioche_silex": {
		"name": "Pioche Silex", "description": "Extrait la pierre et le silex plus efficacement.",
		"category": "outil", "tier": 1,
		"stackable": false, "max_stack": 1,
		"craftable": true, "recipe": {"flint": 4, "wood": 2, "corde": 1},
		"equip_slot": "weapon", "equip_stats": {"force": 2}
	},
	"arc_primitif": {
		"name": "Arc Primitif", "description": "Arc rudimentaire. Utile pour chasser a distance.",
		"category": "outil", "tier": 1,
		"stackable": false, "max_stack": 1,
		"craftable": true, "recipe": {"wood": 3, "corde": 2},
		"equip_slot": "weapon", "equip_stats": {"force": 4}
	},
	"torche": {
		"name": "Torche", "description": "Eclaire la nuit et eloigne les betes sauvages.",
		"category": "outil", "tier": 1,
		"stackable": true, "max_stack": 10,
		"craftable": true, "recipe": {"wood": 1, "resin": 1}
	},

	# ══════════════════════════════════════════════
	# OUTILS PIERRE (Tier 2)
	# ══════════════════════════════════════════════
	"hache_pierre": {
		"name": "Hache en Pierre", "description": "Bien plus efficace que le silex. +2 bois par coup.",
		"category": "outil", "tier": 2,
		"stackable": false, "max_stack": 1,
		"craftable": true, "recipe": {"stone": 4, "wood": 3, "corde": 2, "colle_resine": 1},
		"equip_slot": "weapon", "equip_stats": {"force": 6}
	},
	"pioche_pierre": {
		"name": "Pioche en Pierre", "description": "Mine la pierre et le silex efficacement.",
		"category": "outil", "tier": 2,
		"stackable": false, "max_stack": 1,
		"craftable": true, "recipe": {"stone": 5, "wood": 3, "corde": 2, "colle_resine": 1},
		"equip_slot": "weapon", "equip_stats": {"force": 5}
	},

	# ══════════════════════════════════════════════
	# CONSOMMABLES
	# ══════════════════════════════════════════════
	"bandage": {
		"name": "Bandage", "description": "Pansement primitif. Restaure 20 PV.",
		"category": "consommable", "tier": 1,
		"stackable": true, "max_stack": 20,
		"craftable": true, "recipe": {"herb": 2},
		"consumable": true, "hp_restore": 20, "buffs": []
	},
	"potion_soin": {
		"name": "Potion de Soin", "description": "Remede herbal. Restaure 50 PV instantanement.",
		"category": "consommable", "tier": 2,
		"stackable": true, "max_stack": 10,
		"craftable": true, "recipe": {"herb": 4, "mushroom": 2, "resin": 1},
		"consumable": true, "hp_restore": 50, "buffs": []
	},
	"soupe_champignon": {
		"name": "Soupe Champignon", "description": "Nourrissant. +3 Stamina pendant 60s.",
		"category": "consommable", "tier": 1,
		"stackable": true, "max_stack": 10,
		"craftable": true, "recipe": {"mushroom": 3, "herb": 1},
		"consumable": true, "hp_restore": 15,
		"buffs": [{"stat": "stamina", "amount": 3, "duration": 60.0}]
	},
	"the_herbal": {
		"name": "The Herbal", "description": "Infusion calmante. +3 Charisme, +2 Chance pendant 90s.",
		"category": "consommable", "tier": 1,
		"stackable": true, "max_stack": 10,
		"craftable": true, "recipe": {"herb": 3, "berries": 1},
		"consumable": true, "hp_restore": 5,
		"buffs": [
			{"stat": "charisma", "amount": 3, "duration": 90.0},
			{"stat": "luck",     "amount": 2, "duration": 90.0}
		]
	},

	# ══════════════════════════════════════════════
	# EQUIPEMENTS (Tier 3)
	# ══════════════════════════════════════════════
	"armure_cuir": {
		"name": "Armure en Cuir", "description": "Protection legere. +5 Armure.",
		"category": "equipement", "tier": 3,
		"stackable": false, "max_stack": 1,
		"craftable": true, "recipe": {"cuir": 5, "corde": 3, "resin": 2},
		"equip_slot": "armor", "equip_stats": {"armor": 5}
	},
	"bouclier_os": {
		"name": "Bouclier d'Os", "description": "Bouclier brut. +3 Armure, +1 Force.",
		"category": "equipement", "tier": 3,
		"stackable": false, "max_stack": 1,
		"craftable": true, "recipe": {"bone": 8, "corde": 2, "colle_resine": 2},
		"equip_slot": "shield", "equip_stats": {"armor": 3, "force": 1}
	},
	"amulette_foi": {
		"name": "Amulette de Foi", "description": "Symbole sacre. +5 Charisma, booste la foi du royaume.",
		"category": "equipement", "tier": 3,
		"stackable": false, "max_stack": 1,
		"craftable": true, "recipe": {"bone": 3, "resin": 3, "herb": 5, "flint": 2},
		"equip_slot": "amulet", "equip_stats": {"charisma": 5}
	},
}

func get_item(id: String) -> Dictionary:
	if ITEMS.has(id):
		return ITEMS[id]
	push_warning("ItemDatabase: item inconnu '%s'" % id)
	return {}

func get_craftable_items() -> Array:
	var result: Array = []
	for id in ITEMS:
		if ITEMS[id].get("craftable", false):
			result.append(id)
	return result

func get_items_by_category(cat: String) -> Array:
	var result: Array = []
	for id in ITEMS:
		if ITEMS[id].get("category", "") == cat:
			result.append(id)
	return result

func can_craft(item_id: String, inventory: Dictionary) -> bool:
	var data: Dictionary = get_item(item_id)
	if data.is_empty() or not data.get("craftable", false):
		return false
	for resource in data["recipe"]:
		if inventory.get(resource, 0) < data["recipe"][resource]:
			return false
	return true

# Consomme l'item et applique ses effets sur le joueur
func consume_item(item_id: String) -> bool:
	var data: Dictionary = get_item(item_id)
	if not data.get("consumable", false):
		return false
	if GameManager.get_item(item_id) <= 0:
		return false
	GameManager.remove_item(item_id, 1)
	var hp: int = data.get("hp_restore", 0)
	if hp > 0:
		GameManager.heal(hp)
	for buff in data.get("buffs", []):
		GameManager.apply_buff(buff["stat"], buff["amount"], buff["duration"])
	return true
