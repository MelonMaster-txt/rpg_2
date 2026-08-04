# debug_menu.gd - Menu debug F1
# Give items, teleport, vitesse, spawn NPC, stats joueur
extends CanvasLayer

const GIVE_SETS: Array[Dictionary] = [
	{"label": "Tout x20",      "items": {"bois":20,"pierre":20,"baies":20,"graine_baie":10,"pioche":1,"arrosoir":1}},
	{"label": "Outils",        "items": {"pioche":1,"arrosoir":1}},
	{"label": "Ressources",    "items": {"bois":20,"pierre":20}},
	{"label": "Graines x10",   "items": {"graine_baie":10}},
	{"label": "Baies x20",     "items": {"baies":20}},
]

# stat_key -> [label_display, couleur_bouton]
const STAT_DEFS: Array = [
	["force",        "⚔ Force",      Color(0.8, 0.3, 0.2)],
	["charisma",     "✦ Charisme",   Color(0.8, 0.3, 0.8)],
	["stamina",      "🛡 Endurance",  Color(0.3, 0.6, 0.8)],
	["luck",         "★ Chance",     Color(0.9, 0.75, 0.1)],
	["intelligence", "◆ Intell.",    Color(0.2, 0.7, 0.7)],
	["speed",        "⚡ Agilité",   Color(0.3, 0.9, 0.4)],
	["life",         "♥ HP max",     Color(0.9, 0.2, 0.2)],
]

var _visible: bool = false
var _panel: PanelContainer
var _speed_label: Label
var _stat_labels: Dictionary = {}

func _ready() -> void:
	layer = 100
	_build_ui()
	_panel.visible = false

func _build_ui() -> void:
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color      = Color(0.05, 0.05, 0.08, 0.93)
	style.border_color  = Color(1.0, 0.4, 0.1, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left   = 14
	style.content_margin_right  = 14
	style.content_margin_top    = 10
	style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", style)
	_panel.position = Vector2(12, 12)
	add_child(_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_panel.add_child(vb)

	var title := Label.new()
	title.text = "DEBUG  [F1]  |  Noise: [F2]"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1))
	vb.add_child(title)

	_add_separator(vb, "-- Give --")

	for gset in GIVE_SETS:
		var btn := Button.new()
		btn.text = gset["label"]
		_style_btn(btn, Color(0.2, 0.7, 0.3))
		btn.pressed.connect(_on_give_pressed.bind(gset["items"]))
		vb.add_child(btn)

	_add_separator(vb, "-- Joueur --")

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	var lbl_s := Label.new()
	lbl_s.text = "Vitesse:"
	lbl_s.add_theme_font_size_override("font_size", 11)
	lbl_s.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	_speed_label = Label.new()
	_speed_label.text = "120"
	_speed_label.add_theme_font_size_override("font_size", 11)
	_speed_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.4))
	var btn_slow := Button.new()
	btn_slow.text = "-"
	_style_btn(btn_slow, Color(0.6, 0.3, 0.2))
	btn_slow.custom_minimum_size = Vector2(24, 0)
	btn_slow.pressed.connect(_change_speed.bind(-40))
	var btn_fast := Button.new()
	btn_fast.text = "+"
	_style_btn(btn_fast, Color(0.3, 0.5, 0.8))
	btn_fast.custom_minimum_size = Vector2(24, 0)
	btn_fast.pressed.connect(_change_speed.bind(40))
	hb.add_child(lbl_s)
	hb.add_child(_speed_label)
	hb.add_child(btn_slow)
	hb.add_child(btn_fast)
	vb.add_child(hb)

	var btn_clear := Button.new()
	btn_clear.text = "Vider inventaire"
	_style_btn(btn_clear, Color(0.7, 0.2, 0.2))
	btn_clear.pressed.connect(_on_clear_inventory)
	vb.add_child(btn_clear)

	# ── Section STATS ────────────────────────────────────────────────
	_add_separator(vb, "-- Stats joueur --")

	for sdef in STAT_DEFS:
		var key: String     = sdef[0]
		var lbl_txt: String = sdef[1]
		var col: Color      = sdef[2]

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)

		var lbl_name := Label.new()
		lbl_name.text = lbl_txt
		lbl_name.custom_minimum_size = Vector2(90, 0)
		lbl_name.add_theme_font_size_override("font_size", 11)
		lbl_name.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		row.add_child(lbl_name)

		var val_lbl := Label.new()
		val_lbl.text = str(GameManager.get(key) if GameManager.get(key) != null else 0)
		val_lbl.custom_minimum_size = Vector2(30, 0)
		val_lbl.add_theme_font_size_override("font_size", 11)
		val_lbl.add_theme_color_override("font_color", col)
		_stat_labels[key] = val_lbl
		row.add_child(val_lbl)

		var btn_minus := Button.new()
		btn_minus.text = "-10"
		_style_btn(btn_minus, Color(0.6, 0.25, 0.2))
		btn_minus.custom_minimum_size = Vector2(36, 0)
		btn_minus.pressed.connect(_modify_stat.bind(key, -10))
		row.add_child(btn_minus)

		var btn_plus := Button.new()
		btn_plus.text = "+10"
		_style_btn(btn_plus, col)
		btn_plus.custom_minimum_size = Vector2(36, 0)
		btn_plus.pressed.connect(_modify_stat.bind(key, 10))
		row.add_child(btn_plus)

		var btn_max := Button.new()
		btn_max.text = "MAX"
		_style_btn(btn_max, Color(col.r * 0.7, col.g * 0.7, col.b * 0.7))
		btn_max.custom_minimum_size = Vector2(36, 0)
		btn_max.pressed.connect(_max_stat.bind(key))
		row.add_child(btn_max)

		vb.add_child(row)

	# ── Section NPC ────────────────────────────────────────────────
	_add_separator(vb, "-- NPC --")

	var btn_spawn1 := Button.new()
	btn_spawn1.text = "Spawn NPC x1"
	_style_btn(btn_spawn1, Color(0.3, 0.6, 1.0))
	btn_spawn1.pressed.connect(_on_spawn_npc.bind(1))
	vb.add_child(btn_spawn1)

	var btn_spawn5 := Button.new()
	btn_spawn5.text = "Spawn NPC x5"
	_style_btn(btn_spawn5, Color(0.2, 0.5, 0.9))
	btn_spawn5.pressed.connect(_on_spawn_npc.bind(5))
	vb.add_child(btn_spawn5)

	var btn_clear_npc := Button.new()
	btn_clear_npc.text = "Clear NPC"
	_style_btn(btn_clear_npc, Color(0.8, 0.2, 0.2))
	btn_clear_npc.pressed.connect(_on_clear_npc)
	vb.add_child(btn_clear_npc)

func _add_separator(vb: VBoxContainer, txt: String) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	vb.add_child(lbl)

func _style_btn(btn: Button, col: Color) -> void:
	btn.add_theme_font_size_override("font_size", 11)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(col.r*0.25, col.g*0.25, col.b*0.25, 0.9)
	normal.border_color = col
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	normal.content_margin_left   = 8
	normal.content_margin_right  = 8
	normal.content_margin_top    = 4
	normal.content_margin_bottom = 4
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(col.r*0.45, col.g*0.45, col.b*0.45, 0.95)
	hover.border_color = col
	hover.set_border_width_all(1)
	hover.set_corner_radius_all(4)
	hover.content_margin_left   = 8
	hover.content_margin_right  = 8
	hover.content_margin_top    = 4
	hover.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover",  hover)
	btn.add_theme_stylebox_override("pressed", hover)

# _input au lieu de _unhandled_input : capte F1 MEME si un bouton du panel a le focus
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if (event as InputEventKey).keycode == KEY_F1:
			_toggle()
			get_viewport().set_input_as_handled()

func _toggle() -> void:
	_visible = not _visible
	_panel.visible = _visible
	if _visible:
		_refresh_stats()

func _refresh_stats() -> void:
	for key in _stat_labels:
		var val = GameManager.get(key)
		_stat_labels[key].text = str(val if val != null else 0)

func _modify_stat(key: String, delta: int) -> void:
	var current: int = GameManager.get(key) if GameManager.get(key) != null else 0
	var new_val: int = max(0, current + delta)
	GameManager.set(key, new_val)
	_stat_labels[key].text = str(new_val)

func _max_stat(key: String) -> void:
	GameManager.set(key, 100)
	_stat_labels[key].text = "100"

func _on_give_pressed(items: Dictionary) -> void:
	for id in items:
		GameManager.add_item(id, items[id])

func _on_clear_inventory() -> void:
	for id in GameManager.inventory.keys():
		GameManager.inventory[id] = 0

func _change_speed(delta: int) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var new_speed: float = clamp((player as Node2D).get("move_speed") + delta, 40.0, 400.0)
	(player as Node2D).set("move_speed", new_speed)
	_speed_label.text = str(int(new_speed))

func _on_spawn_npc(count: int) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	NpcSpawner.spawn_random_around((player as Node2D).global_position, 200.0, count)

func _on_clear_npc() -> void:
	NpcSpawner.despawn_all()
