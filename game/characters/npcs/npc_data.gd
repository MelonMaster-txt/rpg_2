class_name NpcData
extends Resource

enum Archetype {
	HUNTER,
	FARMER,
	WARRIOR,
	MERCHANT,
	NOMAD,
	BANDIT,
	SAGE,
}

class NpcStats:
	var force: int = 5
	var max_hp: int = 30
	var skill_farming: int = 0
	var skill_woodcutting: int = 0
	var skill_mining: int = 0
	var skill_combat: int = 0
	var skill_trading: int = 0


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

var archetype: int = Archetype.NOMAD
var stats: NpcStats = NpcStats.new()


func get_display_name() -> String:
	if npc_name.is_empty():
		return "NPC_%s" % npc_id
	return npc_name


func is_hostile_npc() -> bool:
	return base_relation < -20


func can_be_recruited() -> bool:
	return base_relation >= 0


static func generate_random() -> NpcData:
	var d: NpcData = NpcData.new()

	var archetypes: Array[int] = [
		Archetype.HUNTER,
		Archetype.FARMER,
		Archetype.WARRIOR,
		Archetype.MERCHANT,
		Archetype.NOMAD,
		Archetype.BANDIT,
		Archetype.SAGE,
	]
	d.archetype = archetypes.pick_random()

	var noms_masculins: Array[String] = [
		"Aldric", "Bjorn", "Caius", "Drak", "Erwin",
		"Fenris", "Gunnar", "Harald", "Ingmar", "Jord",
		"Knut", "Leif", "Magnus", "Njal", "Orm",
	]
	var noms_feminins: Array[String] = [
		"Astrid", "Brenna", "Ciara", "Dagny", "Elva",
		"Freya", "Gudrun", "Helga", "Ingrid", "Jorunn",
		"Kara", "Lifa", "Marta", "Norna", "Ragna",
	]
	var tous_noms: Array[String] = noms_masculins + noms_feminins
	d.npc_name = tous_noms.pick_random()
	d.npc_id = "npc_" + str(randi())

	var s: NpcStats = NpcStats.new()
	match d.archetype:
		Archetype.WARRIOR, Archetype.BANDIT:
			s.force = randi_range(8, 15)
			s.max_hp = randi_range(40, 60)
			s.skill_combat = randi_range(3, 8)
		Archetype.HUNTER:
			s.force = randi_range(5, 10)
			s.max_hp = randi_range(25, 40)
			s.skill_woodcutting = randi_range(2, 6)
			s.skill_combat = randi_range(2, 5)
		Archetype.FARMER:
			s.force = randi_range(4, 8)
			s.max_hp = randi_range(20, 35)
			s.skill_farming = randi_range(3, 8)
		Archetype.MERCHANT:
			s.force = randi_range(3, 6)
			s.max_hp = randi_range(20, 30)
			s.skill_trading = randi_range(4, 9)
		Archetype.SAGE:
			s.force = randi_range(2, 5)
			s.max_hp = randi_range(15, 25)
			s.skill_trading = randi_range(2, 5)
		_:
			s.force = randi_range(4, 9)
			s.max_hp = randi_range(20, 40)
	d.stats = s
	d.max_health = s.max_hp

	if d.archetype == Archetype.BANDIT:
		d.base_relation = randi_range(-50, -20)
	else:
		d.base_relation = randi_range(-10, 30)

	return d
