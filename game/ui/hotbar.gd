# hotbar.gd — Barre d'outils en bas de l'ecran
# Se connecte au signal held_item_changed du player
extends CanvasLayer

const TOOLS: Array[Dictionary] = [
	{"id": "pioche",     "icon": "\u26cf\ufe0f", "label": "Pioche"},
	{"id": "arrosoir",   "icon": "\U0001faa3",  "label": "Arrosoir"},
	{"id": "graine_baie","icon": "\U0001f330",  "label": "Graine"},
]

@onready var slots_container: HBoxContainer = $HotbarPanel/SlotsRow

var _slot_panels: Array[PanelContainer] = []
var _current_id: String = ""

func _ready() -> void:
	layer = 15
	_build_slots()
	# Connexion differee (player pas encore spawn)
	call_deferred("_connect_player")

func _connect_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_signal("held_item_changed"):
		player.held_item_changed.connect(_on_held_item_changed)
		_on_held_item_changed(player.get_held_item())
	else:
		# Reessaye dans 0.2s si le player n'est pas encore pret
		get_tree().create_timer(0.2).timeout.connect(_connect_player)

func _build_slots() -> void:
	for t in TOOLS:
		var pc := PanelContainer.new()
		var style_normal := StyleBoxFlat.new()
		style_normal.bg_color = Color(0.08, 0.08, 0.10, 0.88)
		style_normal.border_width_left   = 2
		style_normal.border_width_top    = 2
		style_normal.border_width_right  = 2
		style_normal.border_width_bottom = 2
		style_normal.border_color = Color(1, 1, 1, 0.18)
		style_normal.corner_radius_top_left     = 8
		style_normal.corner_radius_top_right    = 8
		style_normal.corner_radius_bottom_right = 8
		style_normal.corner_radius_bottom_left  = 8
		style_normal.content_margin_left   = 10
		style_normal.content_margin_right  = 10
		style_normal.content_margin_top    = 8
		style_normal.content_margin_bottom = 8
		pc.add_theme_stylebox_override("panel", style_normal)
		pc.custom_minimum_size = Vector2(56, 56)
		pc.set_meta("tool_id", t["id"])
		pc.set_meta("style_normal", style_normal)

		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER

		var icon_lbl := Label.new()
		icon_lbl.text = t["icon"]
		icon_lbl.add_theme_font_size_override("font_size", 22)
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		var name_lbl := Label.new()
		name_lbl.text = t["label"]
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

		vb.add_child(icon_lbl)
		vb.add_child(name_lbl)
		pc.add_child(vb)
		slots_container.add_child(pc)
		_slot_panels.append(pc)

func _on_held_item_changed(item_id: String) -> void:
	_current_id = item_id
	for pc in _slot_panels:
		var tid: String = pc.get_meta("tool_id")
		var style: StyleBoxFlat = pc.get_meta("style_normal").duplicate()
		if tid == item_id:
			# Slot actif : fond dore + bordure lumineuse
			style.bg_color     = Color(0.55, 0.40, 0.05, 0.95)
			style.border_color = Color(1.0, 0.80, 0.20, 1.0)
			style.border_width_left   = 2
			style.border_width_top    = 2
			style.border_width_right  = 2
			style.border_width_bottom = 2
		else:
			style.bg_color     = Color(0.08, 0.08, 0.10, 0.88)
			style.border_color = Color(1, 1, 1, 0.18)
		pc.add_theme_stylebox_override("panel", style)
