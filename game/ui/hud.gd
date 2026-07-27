# HUD.gd — Interface principale (inventaire + temps)
extends CanvasLayer

@onready var time_label: Label = $HUDPanel/HUDContainer/TimeRow/TimeLabel
@onready var day_label: Label = $HUDPanel/HUDContainer/DayLabel
@onready var bois_label: Label = $HUDPanel/HUDContainer/BoisLabel
@onready var baies_label: Label = $HUDPanel/HUDContainer/BaiesLabel
@onready var nourriture_label: Label = $HUDPanel/HUDContainer/NourritureLabel
@onready var pierre_label: Label = $HUDPanel/HUDContainer/PierreLabel

func _ready() -> void:
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.day_night_changed.connect(_on_day_night_changed)
	_refresh_all()

func _refresh_all() -> void:
	_update_inventory()
	time_label.text = "⏰ " + GameManager.get_time_string()
	day_label.text = "📅 Jour %d" % GameManager.current_day

func _update_inventory() -> void:
	bois_label.text = "🪵  %d" % GameManager.get_item("bois")
	baies_label.text = "🍇  %d" % GameManager.get_item("baies")
	nourriture_label.text = "🍖  %d" % GameManager.get_item("nourriture")
	pierre_label.text = "🪨  %d" % GameManager.get_item("pierre")

func _on_inventory_changed(item: String, _amount: int) -> void:
	_update_inventory()
	_flash_label(item)

func _flash_label(item: String) -> void:
	var lbl: Label = null
	match item:
		"bois":        lbl = bois_label
		"baies":       lbl = baies_label
		"nourriture":  lbl = nourriture_label
		"pierre":      lbl = pierre_label
	if lbl == null:
		return
	var tw := create_tween()
	tw.tween_property(lbl, "theme_override_colors/font_color", Color(1, 1, 0.3, 1), 0.05)
	tw.tween_property(lbl, "theme_override_colors/font_color", Color(1, 1, 1, 1), 0.4)

func _on_time_changed(h: int, m: int, d: int) -> void:
	time_label.text = "⏰ %02d:%02d" % [h, m]
	day_label.text = "📅 Jour %d" % d

func _on_day_night_changed(is_day: bool) -> void:
	if is_day:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1))
	else:
		time_label.add_theme_color_override("font_color", Color(0.6, 0.7, 1.0, 1))
