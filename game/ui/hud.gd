# HUD.gd — Interface principale (temps seulement, inventaire via I)
extends CanvasLayer

@onready var time_label: Label = $HUDPanel/HUDContainer/TimeLabel
@onready var day_label:  Label = $HUDPanel/HUDContainer/DayLabel

func _ready() -> void:
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.day_night_changed.connect(_on_day_night_changed)
	_refresh_all()

func _refresh_all() -> void:
	time_label.text = "⏰ " + GameManager.get_time_string()
	day_label.text  = "📅 Jour %d" % GameManager.current_day

func _on_time_changed(h: int, m: int, d: int) -> void:
	time_label.text = "⏰ %02d:%02d" % [h, m]
	day_label.text  = "📅 Jour %d" % d

func _on_day_night_changed(is_day: bool) -> void:
	if is_day:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1))
	else:
		time_label.add_theme_color_override("font_color", Color(0.6, 0.7, 1.0, 1))
