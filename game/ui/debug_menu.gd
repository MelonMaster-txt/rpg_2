# debug_menu.gd - Menu debug F1 (instance dynamique dans overworld)
extends CanvasLayer

const GIVE_SETS: Array[Dictionary] = [
	{"label": "Tout x20",    "items": {"wood":20,"stone":20,"berries":20,"berry_seed":10,"hoe":1,"watering_can":1,"gold":50}},
	{"label": "Outils",      "items": {"hoe":1,"watering_can":1}},
	{"label": "Ressources",  "items": {"wood":20,"stone":20}},
	{"label": "Graines x10", "items": {"berry_seed":10}},
	{"label": "Baies x20",   "items": {"berries":20}},
	{"label": "Or x100",     "items": {"gold":100}},
]

var _visible: bool = false
var _panel: PanelContainer
var _speed_label: Label

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

	for gset: Dictionary in GIVE_SETS:
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

func _add_separator(vb: VBoxContainer, txt: String) -> void:
	var lbl := Label.new()
	lbl.text = txt
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	vb.add_child(lbl)

func _style_btn(btn: Button, col: Color) -> void:
	btn.add_theme_font_size_override("font_size", 11)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25, 0.9)
	normal.border_color = col
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(4)
	normal.content_margin_left   = 8
	normal.content_margin_right  = 8
	normal.content_margin_top    = 4
	normal.content_margin_bottom = 4
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(col.r * 0.45, col.g * 0.45, col.b * 0.45, 0.95)
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo():
		if (event as InputEventKey).keycode == KEY_F1:
			_toggle()
			get_viewport().set_input_as_handled()

func _toggle() -> void:
	_visible = not _visible
	_panel.visible = _visible

func _on_give_pressed(items: Dictionary) -> void:
	for id: String in items:
		GameManager.add_item(id, items[id])

func _on_clear_inventory() -> void:
	for id: String in GameManager.inventory.keys():
		GameManager.inventory[id] = 0

func _change_speed(delta: int) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var new_speed: float = clamp(float(player.get("move_speed")) + float(delta), 40.0, 400.0)
	player.set("move_speed", new_speed)
	_speed_label.text = str(int(new_speed))
