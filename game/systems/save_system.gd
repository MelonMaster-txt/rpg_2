# save_system.gd
# Autoload : SaveSystem
# Sauvegarde / charge : joueur, NPCs alliés/esclaves, coffre, position.
extends Node

const SAVE_PATH := "user://savegame.json"

# ─── API publique ─────────────────────────────────────────────────────────────

func save_game() -> void:
	var data := _collect_data()
	var json_str := JSON.stringify(data, "\t")
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveSystem: impossible d'ouvrir %s en écriture" % SAVE_PATH)
		return
	f.store_string(json_str)
	f.close()
	print("[SaveSystem] Sauvegarde OK → ", SAVE_PATH)


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveSystem] Aucune sauvegarde trouvée.")
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_error("SaveSystem: impossible de lire %s" % SAVE_PATH)
		return false
	var raw := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if parsed == null:
		push_error("[SaveSystem] JSON invalide")
		return false
	_apply_data(parsed)
	print("[SaveSystem] Chargement OK")
	return true


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	print("[SaveSystem] Sauvegarde supprimée.")

# ─── Collecte ─────────────────────────────────────────────────────────────────

func _collect_data() -> Dictionary:
	var d := {}
	d["version"] = 1
	d["timestamp"] = Time.get_unix_time_from_system()
	d["player"]   = _collect_player()
	d["npcs"]     = _collect_npcs()
	d["chest"]    = _collect_chest()
	return d


func _collect_player() -> Dictionary:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty(): return {}
	var p: Node = players[0]
	var pd := {}
	# Position
	pd["pos_x"] = p.global_position.x
	pd["pos_y"] = p.global_position.y
	# Stats de base
	for key in ["max_hp", "current_hp", "strength", "agility", "intelligence",
				"endurance", "charisma", "luck", "level", "xp", "gold"]:
		if p.get(key) != null:
			pd[key] = p.get(key)
	# Inventaire
	var inv_node: Node = p.get_node_or_null("Inventory")
	if inv_node != null and inv_node.get("items") != null:
		pd["inventory"] = inv_node.items
	else:
		pd["inventory"] = {}
	# Apparence
	var app: Node = p.get_node_or_null("CharacterAppearance")
	if app != null and app.has_method("get_appearance_data"):
		pd["appearance"] = app.get_appearance_data()
	return pd


func _collect_npcs() -> Array:
	var list: Array = []
	var all_npcs := get_tree().get_nodes_in_group("npc")
	for npc in all_npcs:
		var nd := {}
		nd["pos_x"]      = npc.global_position.x
		nd["pos_y"]      = npc.global_position.y
		nd["npc_name"]   = npc.get("npc_name") if npc.get("npc_name") != null else ""
		nd["npc_gender"] = npc.get("npc_gender") if npc.get("npc_gender") != null else "male"
		nd["state"]      = npc.get("state") if npc.get("state") != null else 0
		nd["is_hostile"] = npc.get("is_hostile") if npc.get("is_hostile") != null else false
		nd["strength"]   = npc.get("strength") if npc.get("strength") != null else 5
		nd["max_hp"]     = npc.get("max_hp") if npc.get("max_hp") != null else 30
		nd["current_hp"] = npc.get("current_hp") if npc.get("current_hp") != null else 30
		nd["speed"]      = npc.get("speed") if npc.get("speed") != null else 60.0
		# Job du travailleur
		var worker: Node = npc.get_node_or_null("WorkerAI")
		nd["job"] = worker.job if worker != null else ""
		# Relation
		var rel: Node = npc.get_node_or_null("RelationComponent")
		if rel != null:
			nd["relation"] = {
				"friendship": rel.get("friendship") if rel.get("friendship") != null else 0,
				"trust":      rel.get("trust") if rel.get("trust") != null else 0,
				"mood":       rel.get("mood") if rel.get("mood") != null else 50,
			}
		else:
			nd["relation"] = null
		# Apparence
		var app: Node = npc.get_node_or_null("CharacterAppearance")
		if app != null and app.has_method("get_appearance_data"):
			nd["appearance"] = app.get_appearance_data()
		else:
			nd["appearance"] = null
		list.append(nd)
	return list


func _collect_chest() -> Dictionary:
	var chests := get_tree().get_nodes_in_group("chest")
	if chests.is_empty(): return {}
	var chest: Node = chests[0]
	if chest.get("contents") != null:
		return chest.contents.duplicate()
	return {}

# ─── Application ──────────────────────────────────────────────────────────────

func _apply_data(d: Dictionary) -> void:
	if d.has("player"): _apply_player(d["player"])
	if d.has("chest"):  _apply_chest(d["chest"])
	# Les NPCs sont respawnés via NpcSpawner ; on restaure leur état après
	if d.has("npcs"):   _apply_npcs(d["npcs"])


func _apply_player(pd: Dictionary) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty(): return
	var p: Node = players[0]
	if pd.has("pos_x") and pd.has("pos_y"):
		p.global_position = Vector2(pd["pos_x"], pd["pos_y"])
	for key in ["max_hp", "current_hp", "strength", "agility", "intelligence",
				"endurance", "charisma", "luck", "level", "xp", "gold"]:
		if pd.has(key): p.set(key, pd[key])
	if pd.has("inventory"):
		var inv_node: Node = p.get_node_or_null("Inventory")
		if inv_node != null: inv_node.items = pd["inventory"]
	if pd.has("appearance"):
		var app: Node = p.get_node_or_null("CharacterAppearance")
		if app != null and app.has_method("apply_appearance_data"):
			app.apply_appearance_data(pd["appearance"])


func _apply_chest(cd: Dictionary) -> void:
	var chests := get_tree().get_nodes_in_group("chest")
	if chests.is_empty(): return
	var chest: Node = chests[0]
	if chest.get("contents") != null:
		chest.contents = cd.duplicate()
		if chest.has_method("_update_label"): chest._update_label()


func _apply_npcs(list: Array) -> void:
	# On cherche les NPCs déjà en scène (alliés / esclaves) pour restaurer leurs données
	var scene_npcs := get_tree().get_nodes_in_group("npc")
	for nd in list:
		if (nd["state"] as int) == 0: continue  # NPCs libres : ignorés au chargement
		# Chercher un NPC existant par nom
		var found: Node = null
		for sn in scene_npcs:
			if sn.get("npc_name") == nd["npc_name"]:
				found = sn; break
		if found == null:
			# Spawner un nouveau NPC allié
			var spawner: Node = get_node_or_null("/root/NpcSpawner")
			if spawner != null and spawner.has_method("spawn_npc_at"):
				var pos := Vector2(nd["pos_x"], nd["pos_y"])
				found = spawner.spawn_npc_at(pos)
		if found == null: continue
		# Restaurer valeurs
		for key in ["npc_name", "npc_gender", "state", "is_hostile",
					"strength", "max_hp", "current_hp", "speed"]:
			if nd.has(key): found.set(key, nd[key])
		found.global_position = Vector2(nd["pos_x"], nd["pos_y"])
		# Job
		if nd.has("job") and nd["job"] != "":
			if found.has_method("change_job"): found.change_job(nd["job"])
		# Relation
		if nd.has("relation") and nd["relation"] != null:
			var rel: Node = found.get_node_or_null("RelationComponent")
			if rel == null and found.has_method("_add_relation_component"):
				found._add_relation_component()
				rel = found.get_node_or_null("RelationComponent")
			if rel != null:
				var rv: Dictionary = nd["relation"]
				if rv.has("friendship"): rel.set("friendship", rv["friendship"])
				if rv.has("trust"):      rel.set("trust",      rv["trust"])
				if rv.has("mood"):       rel.set("mood",       rv["mood"])
		# Apparence
		if nd.has("appearance") and nd["appearance"] != null:
			var app: Node = found.get_node_or_null("CharacterAppearance")
			if app != null and app.has_method("apply_appearance_data"):
				app.apply_appearance_data(nd["appearance"])
