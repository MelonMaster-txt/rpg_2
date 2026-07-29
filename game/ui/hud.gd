# HUD.gd
extends CanvasLayer

const DEBUG_MENU_SCR := preload("res://game/ui/debug_menu.gd")

@onready var time_label: Label = $HUDPanel/HUDContainer/TimeLabel
@onready var day_label:  Label = $HUDPanel/HUDContainer/DayLabel
@onready var inventory_screen = $InventoryScreen

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Menu debug
	var dm := CanvasLayer.new()
	dm.set_script(DEBUG_MENU_SCR)
	dm.name = "DebugMenu"
	add_child(dm)

	GameManager.time_changed.connect(_on_time_changed)
	GameManager.day_night_changed.connect(_on_day_night_changed)
	_refresh_all()

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		get_viewport().set_input_as_handled()
		inventory_screen.toggle()

func _refresh_all() -> void:
	time_label.text = "Heure: " + GameManager.get_time_string()
	day_label.text  = "Jour %d" % GameManager.current_day

func _on_time_changed(h: int, m: int, d: int) -> void:
	time_label.text = "%02d:%02d" % [h, m]
	day_label.text  = "Jour %d" % d

func _on_day_night_changed(is_day: bool) -> void:
	if is_day:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1))
	else:
		time_label.add_theme_color_override("font_color", Color(0.6, 0.7, 1.0, 1))
