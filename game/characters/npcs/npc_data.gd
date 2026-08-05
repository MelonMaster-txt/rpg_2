extends Resource
class_name NPCData

# ─── EXPORTS ──────────────────────────────────────────────────────────────────
@export var npc_id: String = ""
@export var npc_name: String = "Inconnu"
@export var npc_type: String = "random"
@export var max_health: int = 50
@export var move_speed: float = 60.0
@export var detection_range: float = 150.0
@export var base_relation: int = 0
@export var job_id: String = ""
@export var dialogue_tree: String = ""
@export var portrait: Texture2D = null
@export var sprite_sheet: Texture2D = null
@export var loot_table: Array[String] = []

func get_display_name() -> String:
	if npc_name.is_empty():
		return "NPC_%s" % npc_id
	return npc_name

func is_hostile() -> bool:
	return base_relation < -20

func can_be_recruited() -> bool:
	return base_relation >= 0
