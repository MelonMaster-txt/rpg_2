# npc_inventory.gd
# Inventaire individuel d'un NPC (compagnon ou esclave).
extends Resource
class_name NpcInventory

const SLOTS: Array[String] = ["tool", "armor", "accessory"]

var equipped: Dictionary = {
	"tool":      null,
	"armor":     null,
	"accessory": null,
}


func get_total_bonuses() -> Dictionary:
	var total: Dictionary = {}
	for slot: String in SLOTS:
		var item: Variant = equipped.get(slot)
		if item == null:
			continue
		for stat: String in item.get("bonuses", {}):
			total[stat] = total.get(stat, 0) + item["bonuses"][stat]
	return total


func get_bonus(stat: String) -> int:
	return get_total_bonuses().get(stat, 0)


func equip(item: Dictionary) -> bool:
	var slot: String = item.get("slot", "")
	if slot not in SLOTS:
		push_warning("NpcInventory: slot invalide '%s'" % slot)
		return false
	equipped[slot] = item
	return true


func unequip(slot: String) -> Dictionary:
	var old: Variant = equipped.get(slot)
	equipped[slot] = null
	return old if old != null else {}


func is_slot_empty(slot: String) -> bool:
	return equipped.get(slot) == null


func to_dict() -> Dictionary:
	return {"equipped": equipped.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	if d.has("equipped"):
		equipped = d["equipped"]
