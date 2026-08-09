# npc_offline_sim.gd  — Autoload : NpcOfflineSim
# Gere la simulation offline des NPC travailleurs quand leur chunk est déchargé.
#
# Workflow :
#   1. Le ChunkManager appelle npc_offline_sim.save_npcs_from_chunk(chunk_node)
#      avant de retourner le chunk au pool.
#   2. A chaque frame, _process() accumule du temps et simule la production.
#   3. Quand le chunk se recharge, npc_offline_sim.restore_npcs_to_chunk(chunk_node)
#      recrée les NPC avec leur état sauvegardé.
extends Node

# Taux de production : unités/seconde par job
const PRODUCTION_RATE: Dictionary = {
	"woodcutter": 1.0 / 20.0,   # 1 bois toutes les 20s
	"farmer":     1.0 / 30.0,   # 1 baie toutes les 30s
	"miner":      1.0 / 25.0,   # 1 pierre toutes les 25s
	"guard":      0.0,
	"trader":     1.0 / 60.0,
	"builder":    1.0 / 40.0,
}

const RESOURCE_BY_JOB: Dictionary = {
	"woodcutter": "wood",
	"farmer":     "berries",
	"miner":      "stone",
	"guard":      "",
	"trader":     "gold",
	"builder":    "build_points",
}

const NPC_SCENE: String = "res://game/characters/npcs/random_npc.tscn"

# Structure d'un NPC sauvegardé
# { chunk_coords: Vector2i, npc_data: Dictionary }
# npc_data: { name, gender, job, local_pos, hp, max_hp,
#             appearance, accumulated, role, strength }

var _saved: Array = []  # Array[Dictionary]


func _process(delta: float) -> void:
	if _saved.is_empty():
		return
	for entry: Dictionary in _saved:
		var d: Dictionary = entry["npc_data"]
		var job: String = d.get("job", "")
		var rate: float = PRODUCTION_RATE.get(job, 0.0)
		if rate <= 0.0:
			continue
		d["accumulated"] = d.get("accumulated", 0.0) + delta * rate
		if d["accumulated"] >= 1.0:
			var produced: int = int(d["accumulated"])
			d["accumulated"] -= float(produced)
			var res: String = RESOURCE_BY_JOB.get(job, "")
			if res != "":
				_deposit_to_chest(res, produced)
				_show_production_log(d.get("name", "?"), job, produced, res)


# Appelé par ChunkManager avant déchargement
func save_npcs_from_chunk(chunk_node: Node2D, coords: Vector2i) -> void:
	var npcs: Array = []
	_collect_npcs(chunk_node, npcs)
	for npc: Node in npcs:
		if not npc.is_in_group("npc"):
			continue
		var worker: Node = npc.get_node_or_null("WorkerAI")
		if worker == null:
			continue  # NPC sans job : on ne simule pas
		var app_data: Dictionary = {}
		var app: Node = npc.get_node_or_null("CharacterAppearance")
		if app != null and app.has_method("get_appearance_data"):
			app_data = app.get_appearance_data()
		var entry: Dictionary = {
			"chunk_coords": coords,
			"npc_data": {
				"name":        npc.get("npc_name") if npc.get("npc_name") != null else "?",
				"gender":      npc.get("npc_gender") if npc.get("npc_gender") != null else "male",
				"job":         worker.get("job") if worker.get("job") != null else "",
				"local_pos":   npc.position,
				"hp":          npc.get("current_hp") if npc.get("current_hp") != null else 30,
				"max_hp":      npc.get("max_hp") if npc.get("max_hp") != null else 30,
				"strength":    npc.get("strength") if npc.get("strength") != null else 5,
				"role":        npc.get("_npc_state") if npc.get("_npc_state") != null else 0,
				"appearance":  app_data,
				"accumulated": worker.get("_accumulated") if worker.get("_accumulated") != null else 0.0,
			}
		}
		_saved.append(entry)
		print("[NpcOfflineSim] Sauvegardé %s (job=%s) chunk=%s" % [
			entry["npc_data"]["name"], entry["npc_data"]["job"], coords
		])
		npc.queue_free()


# Appelé par ChunkManager après rechargement
func restore_npcs_to_chunk(chunk_node: Node2D, coords: Vector2i) -> void:
	var to_restore: Array = []
	var remaining: Array  = []
	for entry: Dictionary in _saved:
		if entry["chunk_coords"] == coords:
			to_restore.append(entry)
		else:
			remaining.append(entry)
	_saved = remaining
	for entry: Dictionary in to_restore:
		_spawn_npc_from_data(chunk_node, entry["npc_data"])


func _spawn_npc_from_data(parent: Node2D, d: Dictionary) -> void:
	var scene: PackedScene = load(NPC_SCENE) as PackedScene
	if scene == null:
		push_error("NpcOfflineSim: random_npc.tscn introuvable")
		return
	var npc: Node2D = scene.instantiate() as Node2D
	npc.position = d.get("local_pos", Vector2(256, 256))
	parent.add_child(npc)
	# Restaurer apparence
	var app_data: Dictionary = d.get("appearance", {})
	if not app_data.is_empty() and npc.has_method("set_appearance"):
		npc.call("set_appearance", app_data)
	# Restaurer stats
	if npc.get("npc_name") != null:   npc.set("npc_name", d.get("name", "?"))
	if npc.get("npc_gender") != null: npc.set("npc_gender", d.get("gender", "male"))
	if npc.get("current_hp") != null: npc.set("current_hp", d.get("hp", 30))
	if npc.get("max_hp") != null:     npc.set("max_hp", d.get("max_hp", 30))
	if npc.get("strength") != null:   npc.set("strength", d.get("strength", 5))
	# Restaurer job via change_job
	var job: String = d.get("job", "")
	if job != "" and npc.has_method("_prepare_worker"):
		npc.call("_prepare_worker", job)
		var worker: Node = npc.get_node_or_null("WorkerAI")
		if worker != null:
			worker.set("_accumulated", d.get("accumulated", 0.0))
	print("[NpcOfflineSim] Restauré %s (job=%s)" % [d.get("name", "?"), job])


func _collect_npcs(node: Node, result: Array) -> void:
	if node.is_in_group("npc") and node.get_node_or_null("WorkerAI") != null:
		result.append(node)
	for child: Node in node.get_children():
		_collect_npcs(child, result)


func _deposit_to_chest(resource: String, amount: int) -> void:
	var chests: Array = get_tree().get_nodes_in_group("chest")
	if chests.size() > 0 and chests[0].has_method("deposit"):
		chests[0].deposit(resource, amount)
	else:
		GameManager.add_item(resource, amount)


func _show_production_log(npc_name: String, job: String, amount: int, res: String) -> void:
	print("[NpcOfflineSim] %s (%s) produit %d %s (offline)" % [npc_name, job, amount, res])
