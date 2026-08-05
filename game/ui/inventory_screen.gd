# inventory_screen.gd
# Inventaire complet : grille dynamique depuis ItemDatabase,
# onglets par catégorie, panneau stats joueur, slots d'équipement,
# tooltip au survol, bouton Utiliser pour consommables.
# Ouverture : touche "inventory" (I par défaut)
extends Control

# ─── Catégories affichées dans les onglets ──────────────────────────────────
const TABS: Array = [
	{"id": "all",         "label": "Tout"},
	{"id": "ressource",   "label": "Ressources"},
	{"id": "ingredient",  "label": "Ingredients"},
	{"id": "outil",       "label": "Outils"},
	{"id": "consommable", "label": "Consommables"},
	{"id": "equipement",  "label": "Equipements"},
]

# ─── Emojis par item (fallback si pas d'icône) ──────────────────────────────
const EMOJI: Dictionary = {
	"wood":             "🪵",
	"stone":            "🪨",
	"berries":          "🍇",
	"mushroom":         "🍄",
	"flint":            "🔷",
	"herb":             "🌿",
	"resin":            "🪡",
	"bone":             "🦴",
	"corde":            "🧵",
	"colle_resine":     "🧲",
	"cuir":             "🟤",
	"hoe":              "⛏️",
	"watering_can":     "🪣",
	"berry_seed":       "🌱",
	"couteau_silex":    "🔪",
	"hache_silex":      "🚓",
	"pioche_silex":     "⛏️",
	"arc_primitif":     "🏹",
	"torche":           "🕯️",
	"hache_pierre":     "🪓",
	"pioche_pierre":    "⛏️",
	"bandage":          "🩹",
	"potion_soin":      "🧪",
	"soupe_champignon": "🍲",
	"the_herbal":       "🍵",
	"armure_cuir":      "🛡️",
	"bouclier_os":      "🛡️",
	"amulette_foi":     "💎",
}

# ─── Nœuds ──────────────────────────────────────────────────────────────────
@onready var _tab_bar:      HBoxContainer = $BG/Panel/VBox/TopBar/TabBar
@onready var _close_btn:    Button        = $BG/Panel/VBox/TopBar/CloseBtn
@onready var _grid:         GridContainer = $BG/Panel/VBox/Content/Left/ScrollContainer/Grid
@onready var _stats_panel:  VBoxContainer = $BG/Panel/VBox/Content/Right/Stats
@onready var _equip_panel:  VBoxContainer = $BG/Panel/VBox/Content/Right/Equip
@onready var _tooltip:      PanelContainer = $Tooltip
@onready var _tooltip_lbl:  Label         = $Tooltip/Label

# ─── État ───────────────────────────────────────────────────────────────────
var _is_open:       bool   = false
var _dirty:         bool   = false
var _active_tab:    String = "all"
# Slot actif équipé : { "weapon": item_id||"", "armor": ..., "shield": ..., "amulet": ... }
var _equipped:      Dictionary = {"weapon": "", "armor": "", "shield": "", "amulet": ""}

# ─── Init ───────────────────────────────────────────────────────────────────
func _ready() -> void:
	add_to_group("inventory_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_tooltip.visible = false
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.stats_changed.connect(_on_stats_changed)
	_build_tabs()
	_close_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_close_btn.pressed.connect(toggle)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle()

func toggle() -> void:
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		_rebuild_grid()
		_rebuild_stats()
		_rebuild_equip()
		get_tree().paused = true
	else:
		_tooltip.visible = false
		get_tree().paused = false

func _on_inventory_changed(_item: String, _amount: int) -> void:
	if _is_open:
		_dirty = true

func _on_stats_changed() -> void:
	if _is_open:
		_rebuild_stats()

func _process(_delta: float) -> void:
	if _dirty and _is_open:
		_dirty = false
		_rebuild_grid()
		_rebuild_equip()

# ─── Onglets ─────────────────────────────────────────────────────────────
func _build_tabs() -> void:
	for c in _tab_bar.get_children():
		c.queue_free()
	for tab in TABS:
		var btn := Button.new()
		btn.text = tab["label"]
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.pressed.connect(_on_tab_pressed.bind(tab["id"]))
		_tab_bar.add_child(btn)

func _on_tab_pressed(tab_id: String) -> void:
	_active_tab = tab_id
	_rebuild_grid()

# ─── Grille items ───────────────────────────────────────────────────────────
func _rebuild_grid() -> void:
	for c in _grid.get_children():
		c.queue_free()

	# Filtre : items en inventaire (ou onglet = all)
	var shown: Array = []
	for item_id in GameManager.inventory:
		var qty: int = GameManager.get_item(item_id)
		if qty <= 0 and _active_tab != "all":
			continue
		var data: Dictionary = ItemDatabase.get_item(item_id)
		if data.is_empty():
			continue
		var cat: String = data.get("category", "")
		if _active_tab != "all" and cat != _active_tab:
			continue
		shown.append(item_id)

	if shown.is_empty():
		var lbl := Label.new()
		lbl.text = "Aucun item."
		lbl.modulate = Color(0.5, 0.5, 0.5)
		_grid.add_child(lbl)
		return

	for item_id in shown:
		_grid.add_child(_make_card(item_id))

func _make_card(item_id: String) -> PanelContainer:
	var data: Dictionary  = ItemDatabase.get_item(item_id)
	var qty: int          = GameManager.get_item(item_id)
	var is_equipped: bool = _equipped.values().has(item_id)

	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	if is_equipped:
		style.bg_color = Color(0.1, 0.25, 0.1, 0.98)
		style.border_width_bottom = 2
		style.border_color = Color(0.3, 1.0, 0.3)
	elif qty > 0:
		style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	else:
		style.bg_color = Color(0.07, 0.07, 0.09, 0.6)
	for i in 4:
		style.set_corner_radius(i, 6)
	style.content_margin_left   = 6.0
	style.content_margin_right  = 6.0
	style.content_margin_top    = 5.0
	style.content_margin_bottom = 5.0
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(76, 88)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# Emoji / icône
	var icon_lbl := Label.new()
	icon_lbl.text = EMOJI.get(item_id, "?")
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 26)

	# Nom
	var name_lbl := Label.new()
	name_lbl.text = data.get("name", item_id)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.modulate = Color(0.3, 1.0, 0.3) if is_equipped else (Color.WHITE if qty > 0 else Color(0.45, 0.45, 0.45))
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_lbl.custom_minimum_size = Vector2(72, 0)

	# Quantité
	var qty_lbl := Label.new()
	qty_lbl.text = "x%d" % qty
	qty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qty_lbl.add_theme_font_size_override("font_size", 12)
	qty_lbl.modulate = Color(1, 0.9, 0.4) if qty > 0 else Color(0.35, 0.35, 0.35)

	vbox.add_child(icon_lbl)
	vbox.add_child(name_lbl)
	vbox.add_child(qty_lbl)

	# Bouton Utiliser (consommable en inventaire)
	if data.get("consumable", false) and qty > 0:
		var btn := Button.new()
		btn.text = "Utiliser"
		btn.process_mode = Node.PROCESS_MODE_ALWAYS
		btn.add_theme_font_size_override("font_size", 9)
		btn.pressed.connect(_on_use_pressed.bind(item_id))
		vbox.add_child(btn)

	# Bouton Equiper / Désequiper
	var slot: String = data.get("equip_slot", "")
	if slot != "" and qty > 0:
		var eq_btn := Button.new()
		eq_btn.process_mode = Node.PROCESS_MODE_ALWAYS
		eq_btn.add_theme_font_size_override("font_size", 9)
		if is_equipped:
			eq_btn.text = "Retirer"
			eq_btn.pressed.connect(_on_unequip_pressed.bind(item_id, slot))
		else:
			eq_btn.text = "Equiper"
			eq_btn.pressed.connect(_on_equip_pressed.bind(item_id, slot))
		vbox.add_child(eq_btn)

	card.add_child(vbox)

	# Tooltip au survol
	card.mouse_entered.connect(_show_tooltip.bind(item_id))
	card.mouse_exited.connect(_hide_tooltip)

	return card

# ─── Panneau stats joueur ─────────────────────────────────────────────────────
func _rebuild_stats() -> void:
	for c in _stats_panel.get_children():
		c.queue_free()

	var title := Label.new()
	title.text = "--- Stats ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	_stats_panel.add_child(title)

	var gm := GameManager
	var stats: Array = [
		["PV",           "%d / %d" % [gm.life, gm.max_life], Color(0.9, 0.3, 0.3)],
		["Force",        str(gm.force),       Color(1.0, 0.6, 0.3)],
		["Stamina",      str(gm.stamina),     Color(0.4, 0.8, 0.4)],
		["Vitesse",      str(gm.speed),       Color(0.5, 0.8, 1.0)],
		["Armure",       str(gm.armor),       Color(0.7, 0.7, 0.7)],
		["Charisme",     str(gm.charisma),    Color(1.0, 0.7, 1.0)],
		["Chance",       str(gm.luck),        Color(1.0, 0.9, 0.3)],
	]

	for stat in stats:
		var row := HBoxContainer.new()
		var k := Label.new()
		k.text = stat[0] + " :"
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		k.add_theme_font_size_override("font_size", 12)
		var v := Label.new()
		v.text = stat[1]
		v.modulate = stat[2]
		v.add_theme_font_size_override("font_size", 12)
		row.add_child(k)
		row.add_child(v)
		_stats_panel.add_child(row)

	# Buffs actifs
	if not GameManager._active_buffs.is_empty():
		var sep := HSeparator.new()
		_stats_panel.add_child(sep)
		var buff_title := Label.new()
		buff_title.text = "Buffs actifs :"
		buff_title.add_theme_font_size_override("font_size", 11)
		buff_title.modulate = Color(0.4, 0.8, 1.0)
		_stats_panel.add_child(buff_title)
		for stat in GameManager._active_buffs:
			var b: Dictionary = GameManager._active_buffs[stat]
			var bl := Label.new()
			bl.text = "+%d %s (%.0fs)" % [b["amount"], stat, b["timer"]]
			bl.add_theme_font_size_override("font_size", 11)
			bl.modulate = Color(0.4, 0.9, 0.5)
			_stats_panel.add_child(bl)

# ─── Slots d'équipement ─────────────────────────────────────────────────────
func _rebuild_equip() -> void:
	for c in _equip_panel.get_children():
		c.queue_free()

	var title := Label.new()
	title.text = "--- Equipement ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 13)
	_equip_panel.add_child(title)

	var slot_labels: Dictionary = {
		"weapon": "Arme",
		"armor":  "Armure",
		"shield": "Bouclier",
		"amulet": "Amulette",
	}
	for slot in slot_labels:
		var row := HBoxContainer.new()
		var slot_lbl := Label.new()
		slot_lbl.text = slot_labels[slot] + " :"
		slot_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_lbl.add_theme_font_size_override("font_size", 12)

		var val_lbl := Label.new()
		var eq_id: String = _equipped.get(slot, "")
		if eq_id != "":
			var d: Dictionary = ItemDatabase.get_item(eq_id)
			val_lbl.text = EMOJI.get(eq_id, "?") + " " + d.get("name", eq_id)
			val_lbl.modulate = Color(0.4, 1.0, 0.4)
		else:
			val_lbl.text = "(vide)"
			val_lbl.modulate = Color(0.45, 0.45, 0.45)
		val_lbl.add_theme_font_size_override("font_size", 12)

		row.add_child(slot_lbl)
		row.add_child(val_lbl)
		_equip_panel.add_child(row)

# ─── Actions ───────────────────────────────────────────────────────────────
func _on_use_pressed(item_id: String) -> void:
	var ok: bool = ItemDatabase.consume_item(item_id)
	if ok:
		_spawn_popup("+HP", Color(0.3, 1.0, 0.3))

func _on_equip_pressed(item_id: String, slot: String) -> void:
	# Désequipe l'item précédent dans ce slot
	var prev: String = _equipped.get(slot, "")
	if prev != "":
		_unapply_equip(prev)
	_equipped[slot] = item_id
	_apply_equip(item_id)
	_rebuild_grid()
	_rebuild_equip()
	_rebuild_stats()

func _on_unequip_pressed(item_id: String, slot: String) -> void:
	_unapply_equip(item_id)
	_equipped[slot] = ""
	_rebuild_grid()
	_rebuild_equip()
	_rebuild_stats()

func _apply_equip(item_id: String) -> void:
	var data: Dictionary = ItemDatabase.get_item(item_id)
	for stat in data.get("equip_stats", {}):
		GameManager._apply_stat_delta(stat, data["equip_stats"][stat])
	GameManager.emit_signal("stats_changed")

func _unapply_equip(item_id: String) -> void:
	var data: Dictionary = ItemDatabase.get_item(item_id)
	for stat in data.get("equip_stats", {}):
		GameManager._apply_stat_delta(stat, -data["equip_stats"][stat])
	GameManager.emit_signal("stats_changed")

# ─── Tooltip ───────────────────────────────────────────────────────────────
func _show_tooltip(item_id: String) -> void:
	var data: Dictionary = ItemDatabase.get_item(item_id)
	if data.is_empty():
		return
	var lines: Array = [
		data.get("name", item_id),
		data.get("description", ""),
		"Cat : " + data.get("category", "?") + " | T" + str(data.get("tier", 1)),
	]
	var hp: int = data.get("hp_restore", 0)
	if hp > 0:
		lines.append("Restaure +%d PV" % hp)
	for b in data.get("buffs", []):
		lines.append("+%d %s pendant %ds" % [b["amount"], b["stat"], int(b["duration"])])
	for stat in data.get("equip_stats", {}):
		lines.append("+%d %s (equipé)" % [data["equip_stats"][stat], stat])
	_tooltip_lbl.text = "\n".join(lines)
	_tooltip.visible = true
	_tooltip.global_position = get_global_mouse_position() + Vector2(12, 8)

func _hide_tooltip() -> void:
	_tooltip.visible = false

func _process_tooltip() -> void:
	if _tooltip.visible:
		_tooltip.global_position = get_global_mouse_position() + Vector2(12, 8)

# ─── Popup flottant ─────────────────────────────────────────────────────────
func _spawn_popup(msg: String, col: Color) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", col)
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -50), 1.0)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 1.0)
	tw.tween_callback(lbl.queue_free)
