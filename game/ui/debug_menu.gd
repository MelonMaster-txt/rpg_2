extends CanvasLayer

# ─── ONREADY ──────────────────────────────────────────────────────────────────
@onready var _label: RichTextLabel = $Panel/ScrollContainer/VBoxContainer/DebugLabel
@onready var _panel: Panel = $Panel

# ─── VARS ─────────────────────────────────────────────────────────────────────
var _visible_flag: bool = false
var _update_timer: float = 0.0
const UPDATE_INTERVAL: float = 0.5

func _ready() -> void:
	_panel.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle"):
		_visible_flag = not _visible_flag
		_panel.visible = _visible_flag

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
		"[b]== DEBUG ==[/b]",
		"Jour : %d  Heure : %s" % [gm.current_day, gm.get_time_string()],
		"HP : %d / %d" % [gm.life, gm.max_life],
	]
	for key: String in gm.inventory:
		var qty: int = gm.inventory[key]
		if qty > 0:
			lines.append("  %s : %d" % [key, qty])
	_label.text = "\n".join(lines)
