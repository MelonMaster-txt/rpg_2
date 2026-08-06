extends Node

signal building_built(building_id: String)
signal kingdom_level_up(new_level: int)

var kingdom_name:  String = "Mon Clan"
var kingdom_level: int    = 1
var buildings:     Array[String] = []

# Seuils de population pour monter de niveau
const LEVEL_THRESHOLDS: Array[int] = [0, 3, 8, 15, 25, 40]


func _ready() -> void:
	add_to_group("kingdom_manager")


func build(building_id: String) -> void:
	if buildings.has(building_id):
		push_warning("[KingdomManager] Bâtiment déjà construit : " + building_id)
		return
	buildings.append(building_id)
	building_built.emit(building_id)
	print("[KingdomManager] Construit : ", building_id)
	_check_level_up()


func has_building(building_id: String) -> bool:
	return buildings.has(building_id)


func get_job_for_building(building_id: String) -> String:
	var jobs: Dictionary = {
		"farm":     "farmer",
		"sawmill":  "woodcutter",
		"mine":     "miner",
		"barracks": "guard",
		"temple":   "priest",
		"market":   "merchant",
	}
	return jobs.get(building_id, "idle")


func _check_level_up() -> void:
	var pm: Node = get_node_or_null("/root/PopulationManager")
	if pm == null:
		var nodes: Array[Node] = get_tree().get_nodes_in_group("population_manager")
		if nodes.size() > 0:
			pm = nodes[0]
	if pm == null:
		return
	var pop: int = pm.get_population_count()
	for lvl: int in range(LEVEL_THRESHOLDS.size() - 1, 0, -1):
		if pop >= LEVEL_THRESHOLDS[lvl] and kingdom_level < lvl:
			kingdom_level = lvl
			kingdom_level_up.emit(kingdom_level)
			print("[KingdomManager] Niveau de royaume : ", kingdom_level)
			break


func save_data() -> Dictionary:
	return {
		"kingdom_name":  kingdom_name,
		"kingdom_level": kingdom_level,
		"buildings":     buildings,
	}


func load_data(d: Dictionary) -> void:
	kingdom_name  = d.get("kingdom_name",  "Mon Clan")
	kingdom_level = d.get("kingdom_level", 1)
	buildings     = d.get("buildings",     [])
