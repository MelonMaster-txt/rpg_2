# hotbar.gd - Barre d'outils visuelle en bas de l'ecran
extends CanvasLayer

# Utilise des labels texte simples plutot qu'emoji (pas supportes par Godot sans police speciale)
const TOOLS: Array[Dictionary] = [
	{"id": "pioche",      "icon": "[ / ]",  "label": "Pioche",   "color": Color(0.85, 0.70, 0.45)},
	{"id": "arrosoir",   "icon": "[~]",    "label": "Arrosoir", "color": Color(0.40, 0.75, 0.90)},
	{"id": "graine_baie","icon": "[o]",    "label": "Graine",   "color": Color(0.55, 0.85, 0.35)},
]

@onready var slots_container: HBoxContainer = $HotbarPanel/SlotsRow

var _slot_panels: Array[PanelContainer] = []

func _ready() -> void:
	layer = 15
	_build_slots()
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
		s.border_width_left   = 2
		s.border_width_top    = 2
		s.border_width_right  = 2
		s.border_width_bottom = 2
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

func _build_slots() -> void:
	for t in TOOLS:
		var pc := PanelContainer.new()
		pc.custom_minimum_size = Vector2(64, 60)
		pc.set_meta("tool_id",    t["id"])
		pc.set_meta("tool_color", t["color"])
		pc.add_theme_stylebox_override("panel", _make_style(false, t["color"]))

		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER

		var icon_lbl := Label.new()
		icon_lbl.text = t["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 14)
		icon_lbl.add_theme_color_override("font_color", t["color"])
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.name = "IconLabel"

		var name_lbl := Label.new()
		name_lbl.text = t["label"]
		name_lbl.add_theme_font_size_override("font_size", 10)
		name_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		vb.add_child(icon_lbl)
		vb.add_child(name_lbl)
		pc.add_child(vb)
		slots_container.add_child(pc)
		_slot_panels.append(pc)

func _on_held_item_changed(item_id: String) -> void:
	for pc in _slot_panels:
		var tid:   String = pc.get_meta("tool_id")
		var col: Color  = pc.get_meta("tool_color")
		var active := (tid == item_id)
		pc.add_theme_stylebox_override("panel", _make_style(active, col))
		# Nom plus lumineux si actif
		var name_lbl: Label = pc.get_child(0).get_child(1) as Label
		if name_lbl:
			var fc := col if active else Color(0.55, 0.55, 0.55)
			name_lbl.add_theme_color_override("font_color", fc)
