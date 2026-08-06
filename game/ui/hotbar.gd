# hotbar.gd - Single slot showing the active tool
# TAB cycles between available tools in the inventory
extends CanvasLayer

const TOOLS: Array[Dictionary] = [
	{"id": "hoe",          "icon": "[ / ]", "label": "Hoe",          "color": Color(0.85, 0.70, 0.45)},
	{"id": "watering_can", "icon": "[~]",   "label": "Watering Can", "color": Color(0.40, 0.75, 0.90)},
	{"id": "berry_seed",   "icon": "[o]",   "label": "Berry Seed",   "color": Color(0.55, 0.85, 0.35)},
]

@onready var slots_container: HBoxContainer = $HotbarPanel/SlotsRow

var _slot: PanelContainer = null

func _ready() -> void:
	layer = 15
	_build_slot()
	call_deferred("_connect_player")

func _connect_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_signal("held_item_changed"):
		player.held_item_changed.connect(_on_held_item_changed)
		_on_held_item_changed(player.get_held_item())
	else:
		get_tree().create_timer(0.2).timeout.connect(_connect_player)

func _make_style(active: bool, tool_color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	if active:
		s.bg_color     = Color(tool_color.r * 0.35, tool_color.g * 0.35, tool_color.b * 0.10, 0.95)
		s.border_color = tool_color
	else:
		s.bg_color     = Color(0.08, 0.08, 0.10, 0.88)
		s.border_color = Color(1, 1, 1, 0.15)
	s.border_width_left   = 2
	s.border_width_top    = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left     = 8
	s.corner_radius_top_right    = 8
	s.corner_radius_bottom_right = 8
	s.corner_radius_bottom_left  = 8
	s.content_margin_left   = 10
	s.content_margin_right  = 10
	s.content_margin_top    = 8
	s.content_margin_bottom = 8
	return s

func _build_slot() -> void:
	# Clear old slots if rebuilding
	for c in slots_container.get_children():
		c.queue_free()
	_slot = PanelContainer.new()
	_slot.custom_minimum_size = Vector2(72, 64)
	_slot.add_theme_stylebox_override("panel", _make_style(false, Color.WHITE))

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER

	var icon_lbl := Label.new()
	icon_lbl.name = "IconLabel"
	icon_lbl.text = ""
	icon_lbl.add_theme_font_size_override("font_size", 15)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var name_lbl := Label.new()
	name_lbl.name = "NameLabel"
	name_lbl.text = ""
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var hint_lbl := Label.new()
	hint_lbl.name = "HintLabel"
	hint_lbl.text = "[TAB]"
	hint_lbl.add_theme_font_size_override("font_size", 9)
	hint_lbl.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	vb.add_child(icon_lbl)
	vb.add_child(name_lbl)
	vb.add_child(hint_lbl)
	_slot.add_child(vb)
	slots_container.add_child(_slot)

func _on_held_item_changed(item_id: String) -> void:
	if _slot == null:
		return
	var vb := _slot.get_child(0)
	var icon_lbl: Label = vb.get_node("IconLabel")
	var name_lbl: Label = vb.get_node("NameLabel")
	var hint_lbl: Label = vb.get_node("HintLabel")

	if item_id == "":
		# No tool selected
		_slot.add_theme_stylebox_override("panel", _make_style(false, Color.WHITE))
		icon_lbl.text = ""
		icon_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		name_lbl.text = ""
		hint_lbl.text = "[TAB]"
		return

	# Find tool info
	var info: Dictionary = {}
	for t in TOOLS:
		if t["id"] == item_id:
			info = t
			break
	if info.is_empty():
		return

	_slot.add_theme_stylebox_override("panel", _make_style(true, info["color"]))
	icon_lbl.text = info["icon"]
	icon_lbl.add_theme_color_override("font_color", info["color"])
	name_lbl.text = info["label"]
	name_lbl.add_theme_color_override("font_color", info["color"])
	hint_lbl.text = "[TAB] next"
