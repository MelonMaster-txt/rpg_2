# npc_inventory.gd
# Inventaire individuel d'un NPC (compagnon ou esclave).
# Stocke les items équipés + leurs effets sur les stats.
# Utilisé comme composant : add_child(NpcInventory.new()) sur un NPC du roster.
extends Resource
class_name NpcInventory

# ─── Structure d'un item ──────────────────────────────────────────────────────
# {
#   "id":      String   — identifiant unique ("farmers_hoe", "leather_gloves"...)
#   "name":    String   — nom affiché
#   "icon":    String   — emoji
#   "slot":    String   — "tool" | "armor" | "accessory"
#   "bonuses": Dictionary  — { "farming": 2, "strength": 1, ... }
# }

# Slots disponibles par NPC
const SLOTS := ["tool", "armor", "accessory"]

# Items équipés : slot → item dict (ou null)
var equipped: Dictionary = {
	"tool":      null,
	"armor":     null,
	"accessory": null,
}

# ─── Bonus calculés ───────────────────────────────────────────────────────────

func get_total_bonuses() -> Dictionary:
	var total: Dictionary = {}
	for slot in SLOTS:
		var item = equipped.get(slot)
		if item == null:
			continue
		for stat in item.get("bonuses", {}):
			total[stat] = total.get(stat, 0) + item["bonuses"][stat]
	return total


func get_bonus(stat: String) -> int:
	return get_total_bonuses().get(stat, 0)

# ─── Équipement ───────────────────────────────────────────────────────────────

func equip(item: Dictionary) -> bool:
	var slot: String = item.get("slot", "")
	if slot not in SLOTS:
		push_warning("NpcInventory: slot invalide '%s'" % slot)
		return false
	equipped[slot] = item
	return true


func unequip(slot: String) -> Dictionary:
	var old = equipped.get(slot)
	equipped[slot] = null
	return old if old != null else {}


func is_slot_empty(slot: String) -> bool:
	return equipped.get(slot) == null

# ─── Sérialisation (save/load) ────────────────────────────────────────────────

func to_dict() -> Dictionary:
	return { "equipped": equipped.duplicate(true) }


func from_dict(d: Dictionary) -> void:
	if d.has("equipped"):
		equipped = d["equipped"]
