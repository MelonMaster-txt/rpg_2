# WorkbenchUI — Interface de craft du workbench
# Affiche les recettes groupées par catégorie avec onglets.
# Support : craft normal + consommation directe depuis l'inventaire.
extends Control

const CATEGORIES: Array = [
	{"id": "ingredient",  "label": "Ingredients"},
	{"id": "outil",       "label": "Outils T1"},
	{"id": "outil2",      "label": "Outils T2"},
	{"id": "consommable", "label": "Consommables"},
	{"id": "equipement",  "label": "Equipements"},
]

@onready var _item_list:  VBoxContainer = $VBoxContainer/ScrollContainer/ItemList
@onready var _close_btn:  Button        = $VBoxContainer/TopBar/CloseButton
@onready var _tab_bar:    HBoxContainer = $VBoxContainer/TabBar
@onready var _title_lbl:  Label         = $VBoxContainer/TopBar/Title
@onready var _feedback:   Label         = $VBoxContainer/Feedback

var _current_category: String = "outil"

func _ready() -> void:
	add_to_group("workbench_ui")
	visible = false
	_close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_close_btn.pressed.connect(close)
	_build_tabs()

func open() -> void:
	_build_list()
	visible = true
	get_tree().paused = true
	_feedback.text = ""

func close() -> void:
	visible = false
	get_tree().paused = false


# ─── ONGLETS ─────────────────────────────────────────────────────────────
func _build_tabs() -> void:
	for child in _tab_bar.get_children():
		child.queue_free()
	for cat in CATEGORIES:
		var btn := Button.new()
		btn.text = cat["label"]
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.pressed.connect(_on_tab_pressed.bind(cat["id"]))
		_tab_bar.add_child(btn)

func _on_tab_pressed(cat_id: String) -> void:
	_current_category = cat_id
	_build_list()
	_feedback.text = ""


# ─── LISTE DE RECETTES ───────────────────────────────────────────────────
func _build_list() -> void:
	for child in _item_list.get_children():
		child.queue_free()

	# Collecte les craftables de la catégorie active
	# "outil2" = outil tier 2 seulement
	var items: Array = []
	for item_id in ItemDatabase.get_craftable_items():
		var data: Dictionary = ItemDatabase.get_item(item_id)
		var cat: String  = data.get("category", "")
		var tier: int    = data.get("tier", 1)
		if _current_category == "outil2":
			if cat == "outil" and tier == 2:
				items.append(item_id)
		elif _current_category == "outil":
			if cat == "outil" and tier == 1:
				items.append(item_id)
		else:
			if cat == _current_category:
				items.append(item_id)

	if items.is_empty():
		var lbl := Label.new()
		lbl.text = "Aucune recette dans cette categorie."
		lbl.modulate = Color(0.6, 0.6, 0.6)
		_item_list.add_child(lbl)
		return

	for item_id in items:
		_item_list.add_child(_build_row(item_id))


func _build_row(item_id: String) -> HBoxContainer:
	var data: Dictionary = ItemDatabase.get_item(item_id)
	var can_craft: bool  = ItemDatabase.can_craft(item_id, GameManager.inventory)
	var in_inv: int      = GameManager.get_item(item_id)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# --- Colonne gauche : nom + recette + description ---
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_lbl := Label.new()
	var tier_tag: String = " [T%d]" % data.get("tier", 1)
	name_lbl.text = data.get("name", item_id) + tier_tag
	name_lbl.modulate = Color.WHITE if can_craft else Color(0.55, 0.55, 0.55)

	var desc_lbl := Label.new()
	desc_lbl.text = data.get("description", "")
	desc_lbl.modulate = Color(0.75, 0.75, 0.75)
	desc_lbl.add_theme_font_size_override("font_size", 11)

	var recipe_lbl := Label.new()
	var parts: Array = []
	for k in data["recipe"]:
		var have: int   = GameManager.get_item(k)
		var need: int   = data["recipe"][k]
		var col: String = "[color=green]" if have >= need else "[color=red]"
		parts.append("%s%dx %s[/color]" % [col, need, k])
	recipe_lbl.text = "Recette : " + ", ".join(parts)
	recipe_lbl.add_theme_font_size_override("font_size", 11)

	# Buffs si consommable
	if data.get("buffs", []).size() > 0:
		var buff_lbl := Label.new()
		var buff_parts: Array = []
		for b in data["buffs"]:
			buff_parts.append("+%d %s (%ds)" % [b["amount"], b["stat"], int(b["duration"])])
		buff_lbl.text = "Buff : " + ", ".join(buff_parts)
		buff_lbl.modulate = Color(0.4, 0.8, 1.0)
		buff_lbl.add_theme_font_size_override("font_size", 11)
		info.add_child(buff_lbl)

	info.add_child(name_lbl)
	info.add_child(desc_lbl)
	info.add_child(recipe_lbl)

	# --- Colonne droite : bouton Craft + quantité en inventaire ---
	var right := VBoxContainer.new()

	var inv_lbl := Label.new()
	inv_lbl.text = "Inv: %d" % in_inv
	inv_lbl.add_theme_font_size_override("font_size", 11)
	inv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var craft_btn := Button.new()
	craft_btn.text = "Craft"
	craft_btn.disabled = not can_craft
	craft_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	craft_btn.pressed.connect(_on_craft_pressed.bind(item_id))

	# Bouton Utiliser (consommables seulement)
	if data.get("consumable", false) and in_inv > 0:
		var use_btn := Button.new()
		use_btn.text = "Utiliser"
		use_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		use_btn.pressed.connect(_on_use_pressed.bind(item_id))
		right.add_child(use_btn)

	right.add_child(inv_lbl)
	right.add_child(craft_btn)

	row.add_child(info)
	row.add_child(right)

	# Separateur
	var sep := HSeparator.new()
	var wrapper := VBoxContainer.new()
	wrapper.add_child(row)
	wrapper.add_child(sep)
	return wrapper as HBoxContainer


# ─── ACTIONS ─────────────────────────────────────────────────────────────
func _on_craft_pressed(item_id: String) -> void:
	var data: Dictionary = ItemDatabase.get_item(item_id)
	for resource in data["recipe"]:
		GameManager.remove_item(resource, data["recipe"][resource])
	GameManager.add_item(item_id, 1)
	_show_feedback("✓ Crafté : " + data.get("name", item_id), Color(0.3, 1.0, 0.3))
	_build_list()

func _on_use_pressed(item_id: String) -> void:
	var ok: bool = ItemDatabase.consume_item(item_id)
	if ok:
		var data: Dictionary = ItemDatabase.get_item(item_id)
		_show_feedback("✓ Utilise : " + data.get("name", item_id), Color(0.3, 0.8, 1.0))
	else:
		_show_feedback("✗ Impossible d'utiliser.", Color(1.0, 0.4, 0.4))
	_build_list()

func _show_feedback(msg: String, col: Color) -> void:
	_feedback.text = msg
	_feedback.modulate = col
	# Efface après 3 secondes
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func(): _feedback.text = "")
