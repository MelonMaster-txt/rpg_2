# npc_inventory_ui.gd
# UI pour équiper/déséquiper les items d'un NPC.
extends CanvasLayer

@onready var title_label: Label         = $Panel/VBox/Title
@onready var slots_vbox:  VBoxContainer = $Panel/VBox/Slots
@onready var btn_close:   Button        = $Panel/VBox/BtnClose

var _entry: Dictionary = {}
var _inventory: NpcInventory = null

const AVAILABLE_ITEMS: Array[Dictionary] = [
	{"id": "farmers_hoe",     "name": "Houe du fermier",       "icon": "🪩", "slot": "tool",      "bonuses": {"farming": 3}},
	{"id": "woodcutters_axe", "name": "Hache de bûcheron",    "icon": "🪓", "slot": "tool",      "bonuses": {"woodcutting": 3, "strength": 1}},
	{"id": "miners_pick",     "name": "Pioche du mineur",      "icon": "⛏",  "slot": "tool",      "bonuses": {"mining": 4}},
	{"id": "leather_armor",   "name": "Armure en cuir",        "icon": "🥋", "slot": "armor",     "bonuses": {"strength": 2, "max_hp": 10}},
	{"id": "iron_ring",       "name": "Anneau de fer",         "icon": "💍", "slot": "accessory", "bonuses": {"strength": 1, "combat": 1}},
	{"id": "lucky_charm",     "name": "Amulette porte-bonheur","icon": "🍀", "slot": "accessory", "bonuses": {"farming": 1, "woodcutting": 1, "mining": 1}},
]


func _ready() -> void:
	if btn_close:
		btn_close.pressed.connect(_close)


func open(entry: Dictionary) -> void:
	_entry = entry
	if not _entry.has("inventory"):
		_entry["inventory"] = NpcInventory.new()
	_inventory = _entry["inventory"]
	_refresh()
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS


func _refresh() -> void:
	if title_label:
		title_label.text = "🎒 Inventaire — %s" % _entry.get("name", "?")
	_build_slots()


func _build_slots() -> void:
	for child: Node in slots_vbox.get_children():
		child.queue_free()
	for slot: String in NpcInventory.SLOTS:
		var row: HBoxContainer = HBoxContainer.new()
		var slot_label: Label = Label.new()
		slot_label.text = "[%s]" % slot
		slot_label.custom_minimum_size = Vector2(90, 0)
		row.add_child(slot_label)
		var equipped_item: Variant = _inventory.equipped.get(slot)
		var item_label: Label = Label.new()
		if equipped_item:
			item_label.text = "%s %s" % [equipped_item.get("icon", ""), equipped_item.get("name", "")]
			item_label.modulate = Color(0.8, 1.0, 0.6)
		else:
			item_label.text = "(vide)"
			item_label.modulate = Color(0.6, 0.6, 0.6)
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(item_label)
		var btn_equip: Button = Button.new()
		btn_equip.text = "Équiper"
		btn_equip.pressed.connect(_open_equip_picker.bind(slot))
		row.add_child(btn_equip)
		if equipped_item:
			var btn_un: Button = Button.new()
			btn_un.text = "Retirer"
			btn_un.pressed.connect(_do_unequip.bind(slot))
			row.add_child(btn_un)
		slots_vbox.add_child(row)
	var sep: HSeparator = HSeparator.new()
	slots_vbox.add_child(sep)
	var bonus_label: Label = Label.new()
	var bonuses: Dictionary = _inventory.get_total_bonuses()
	if bonuses.is_empty():
		bonus_label.text = "Aucun bonus actif"
	else:
		var parts: Array[String] = []
		for k: String in bonuses:
			parts.append("+%d %s" % [bonuses[k], k])
		bonus_label.text = "Bonus : " + ", ".join(parts)
	bonus_label.modulate = Color(1.0, 0.85, 0.4)
	slots_vbox.add_child(bonus_label)


func _open_equip_picker(slot: String) -> void:
	var items_for_slot: Array = AVAILABLE_ITEMS.filter(func(i: Dictionary) -> bool: return i["slot"] == slot)
	if items_for_slot.is_empty():
		return
	var picker: Window = Window.new()
	picker.title = "Choisir un item — " + slot
	picker.size = Vector2i(260, 200)
	var vbox: VBoxContainer = VBoxContainer.new()
	for item: Dictionary in items_for_slot:
		var b: Button = Button.new()
		var bonuses_str: String = ", ".join(
			item["bonuses"].keys().map(func(k: String) -> String: return "+%d %s" % [item["bonuses"][k], k])
		)
		b.text = "%s %s (%s)" % [item.get("icon", ""), item["name"], bonuses_str]
		b.pressed.connect(_do_equip.bind(item, picker))
		vbox.add_child(b)
	picker.add_child(vbox)
	get_tree().current_scene.add_child(picker)
	picker.popup_centered()


func _do_equip(item: Dictionary, picker: Window) -> void:
	_inventory.equip(item)
	_refresh()
	CompanionManager.roster_changed.emit()
	picker.queue_free()


func _do_unequip(slot: String) -> void:
	_inventory.unequip(slot)
	_refresh()
	CompanionManager.roster_changed.emit()


func _close() -> void:
	get_tree().paused = false
	queue_free()
