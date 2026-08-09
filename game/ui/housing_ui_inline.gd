# housing_ui_inline.gd
# UI gestionnaire de logement creee entierement par code.
# Affiche un tableau : batiment -> slots -> occupant + bouton assigner/liberer.
# Ouverture : .open(building_id) pour focus sur un batiment precis,
#             ou .open("") pour afficher tous les batiments.
extends Node

var _building_id: String = ""
var _panel: PanelContainer = null
var _content: VBoxContainer = null


func open(building_id: String) -> void:
	_building_id = building_id
	_build_ui()


func _build_ui() -> void:
	# Conteneur principal centre
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(480, 420)
	_panel.position = Vector2(-240, -210)
	get_parent().add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	# Titre
	var title := Label.new()
	title.text = "Gestionnaire de logement"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

	var sep1 := HSeparator.new()
	vbox.add_child(sep1)

	# Barre d'info capacite
	var hm: Node = Engine.get_singleton("HousingManager")
	if hm != null:
		var cap_tent:  int = hm.get_capacity_for(hm.BuildingType.TENT)
		var used_tent: int = hm.get_used_for(hm.BuildingType.TENT)
		var cap_pris:  int = hm.get_capacity_for(hm.BuildingType.PRISON)
		var used_pris: int = hm.get_used_for(hm.BuildingType.PRISON)
		var info := Label.new()
		info.text = "Tentes: %d/%d  |  Cellules: %d/%d" % [used_tent, cap_tent, used_pris, cap_pris]
		info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		info.modulate = Color(0.8, 0.85, 1.0)
		vbox.add_child(info)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Zone scrollable = tableau des batiments
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(460, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 4)
	scroll.add_child(_content)

	_populate_table()

	var sep3 := HSeparator.new()
	vbox.add_child(sep3)

	# Bouton fermer
	var close_btn := Button.new()
	close_btn.text = "Fermer  [E]"
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)


# Remplit le tableau avec tous les batiments (ou un seul si _building_id defini)
func _populate_table() -> void:
	for child: Node in _content.get_children():
		child.queue_free()

	var hm: Node = Engine.get_singleton("HousingManager")
	if hm == null:
		return

	var buildings: Array[Dictionary] = hm.get_all_buildings()
	if buildings.is_empty():
		var empty := Label.new()
		empty.text = "Aucun batiment de logement construit."
		empty.modulate = Color(0.6, 0.6, 0.6)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_content.add_child(empty)
		return

	for b: Dictionary in buildings:
		if _building_id != "" and b["id"] != _building_id:
			continue
		_add_building_section(b, hm)


# Section d'un batiment : header + lignes de slots + bouton ameliorer
func _add_building_section(b: Dictionary, hm: Node) -> void:
	var type_label: String = "Tente" if b["type"] == hm.BuildingType.TENT else "Prison"
	var bname: String = hm.get_building_name(b)

	# Header batiment
	var header := HBoxContainer.new()
	var h_lbl := Label.new()
	h_lbl.text = "%s  (niv. %d)" % [bname, b["level"]]
	h_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_lbl.add_theme_font_size_override("font_size", 14)
	header.add_child(h_lbl)

	# Bouton ameliorer
	var cost: Dictionary = hm.get_upgrade_cost(b["id"])
	var up_btn := Button.new()
	if cost.is_empty():
		up_btn.text = "Niveau max"
		up_btn.disabled = true
	else:
		var cost_str: String = ", ".join(cost.keys().map(func(k): return "%d %s" % [cost[k], k]))
		up_btn.text = "Ameliorer (%s)" % cost_str
		up_btn.pressed.connect(_on_upgrade_pressed.bind(b["id"]))
	header.add_child(up_btn)
	_content.add_child(header)

	# Lignes de slots
	var slot_idx: int = 0
	for slot: Dictionary in b["slots"]:
		slot_idx += 1
		var row := HBoxContainer.new()

		# Nom de la piece
		var slot_type: String = "Chambre" if b["type"] == hm.BuildingType.TENT else "Cellule"
		var slot_lbl := Label.new()
		slot_lbl.text = "  %s %d" % [slot_type, slot_idx]
		slot_lbl.custom_minimum_size = Vector2(110, 0)
		row.add_child(slot_lbl)

		# Occupant
		var occ_lbl := Label.new()
		if slot["occupant"] == "":
			occ_lbl.text = "(vide)"
			occ_lbl.modulate = Color(0.5, 0.5, 0.5)
		else:
			occ_lbl.text = slot["occupant"]
			occ_lbl.modulate = Color(1.0, 0.9, 0.6)
		occ_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(occ_lbl)

		# Bouton assigner ou liberer
		var action_btn := Button.new()
		if slot["occupant"] == "":
			action_btn.text = "Assigner"
			action_btn.pressed.connect(
				_on_assign_pressed.bind(b["id"], slot["slot_id"], b["type"])
			)
		else:
			action_btn.text = "Liberer"
			action_btn.pressed.connect(
				_on_free_pressed.bind(slot["occupant"])
			)
		row.add_child(action_btn)
		_content.add_child(row)

	var sep := HSeparator.new()
	_content.add_child(sep)


# --- Actions ---

func _on_upgrade_pressed(building_id: String) -> void:
	var hm: Node = Engine.get_singleton("HousingManager")
	if hm == null:
		return
	var cost: Dictionary = hm.get_upgrade_cost(building_id)
	# Verifie et consomme les ressources
	for res: String in cost:
		var rm: Node = Engine.get_singleton("ResourceManager")
		if rm == null or rm.get_resource(res) < cost[res]:
			print("[HousingUI] Ressources insuffisantes pour amelioration")
			return
	for res: String in cost:
		var rm: Node = Engine.get_singleton("ResourceManager")
		rm.remove_resource(res, cost[res])
	hm.upgrade_building(building_id)
	_populate_table()  # Rafraichit le tableau


func _on_assign_pressed(building_id: String, slot_id: String, type: int) -> void:
	# Ouvre un sous-menu pour choisir quel NPC assigner
	var hm: Node = Engine.get_singleton("HousingManager")
	var pm: Node = Engine.get_singleton("PopulationManager")
	if pm == null:
		return
	var candidates: Array[Dictionary] = []
	if type == hm.BuildingType.TENT:
		candidates = pm.get_companions()
	else:
		candidates = pm.get_slaves()
	# Filtre ceux deja loges dans ce slot
	_open_assign_picker(building_id, slot_id, candidates)


func _open_assign_picker(building_id: String, slot_id: String, candidates: Array[Dictionary]) -> void:
	var popup := AcceptDialog.new()
	popup.title = "Choisir un occupant"
	var vb := VBoxContainer.new()
	popup.add_child(vb)
	if candidates.is_empty():
		var lbl := Label.new()
		lbl.text = "Aucun PNJ disponible."
		vb.add_child(lbl)
	else:
		for entry: Dictionary in candidates:
			var npc_name: String = entry.get("name", "?")
			var btn := Button.new()
			btn.text = npc_name
			btn.pressed.connect(func():
				var hm2: Node = Engine.get_singleton("HousingManager")
				if hm2 != null:
					# Libere l'ancien slot si le NPC en avait un
					hm2.free_occupant(npc_name)
					hm2.assign_occupant(building_id, slot_id, npc_name)
				popup.queue_free()
				_populate_table()
			)
			vb.add_child(btn)
	get_parent().add_child(popup)
	popup.popup_centered()


func _on_free_pressed(npc_name: String) -> void:
	var hm: Node = Engine.get_singleton("HousingManager")
	if hm != null:
		hm.free_occupant(npc_name)
	_populate_table()


func _close() -> void:
	var layer: Node = get_parent()
	if layer != null:
		layer.queue_free()
