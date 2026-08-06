# DebugMenu — Autoload *script-only* (pas de .tscn associée).
# Les nœuds UI sont créés dynamiquement dans _ready().
# Touche : F9 (ne dépend pas de l'InputMap).
extends CanvasLayer

var _panel: Panel = null
var _label: RichTextLabel = null
var _visible_flag: bool = false
var _update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.5


func _ready() -> void:
	layer = 128
	_build_ui()
	_panel.visible = false


func _build_ui() -> void:
	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.offset_right = 440.0
	_panel.offset_bottom = 270.0
	_panel.offset_left = 8.0
	_panel.offset_top = 8.0
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.0, 0.0, 0.75)
	sb.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(scroll)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.add_theme_font_size_override("normal_font_size", 13)
	_label.add_theme_color_override("default_color", Color(0.9, 0.95, 1.0))
	vbox.add_child(_label)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F9:
			_visible_flag = not _visible_flag
			_panel.visible = _visible_flag
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _visible_flag:
		return
	_update_timer += delta
	if _update_timer < UPDATE_INTERVAL:
		return
	_update_timer = 0.0
	_refresh()


func _refresh() -> void:
	var gm: Node = GameManager
	var lines: PackedStringArray = [
		"[b][color=#ffd080]== DEBUG F9 ==[/color][/b]",
		"Jour : %d  Heure : %s" % [gm.current_day, gm.get_time_string()],
		"HP : %d / %d" % [gm.life, gm.max_life],
		"Force:%d  Stamina:%d  Chance:%d" % [gm.force, gm.stamina, gm.luck],
		"Charisme:%d  Vitesse:%d  Armure:%d" % [gm.charisma, gm.speed, gm.armor],
		"",
		"[b]Inventaire[/b]",
	]
	for key: String in gm.inventory:
		var qty: int = gm.inventory[key]
		if qty > 0:
			lines.append("  %s : %d" % [key, qty])
	_label.text = "\n".join(lines)
