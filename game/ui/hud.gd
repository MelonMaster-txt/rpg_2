# hud.gd
# Attacher sur un CanvasLayer, structure attendue :
#   CanvasLayer
#     VBoxContainer (HUDContainer)
#       Label (TimeLabel)
#       Label (DayLabel)
#       HSeparator
#       Label (BoisLabel)
#       Label (BaiesLabel)
#       Label (NourritureLabel)
#       Label (PierreLabel)
extends CanvasLayer

@onready var time_label = $HUDContainer/TimeLabel
@onready var day_label = $HUDContainer/DayLabel
@onready var bois_label = $HUDContainer/BoisLabel
@onready var baies_label = $HUDContainer/BaiesLabel
@onready var nourriture_label = $HUDContainer/NourritureLabel
@onready var pierre_label = $HUDContainer/PierreLabel

func _ready() -> void:
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.day_night_changed.connect(_on_day_night_changed)
	_refresh_all()

func _refresh_all() -> void:
	_update_inventory()
	time_label.text = "Heure : " + GameManager.get_time_string()
	day_label.text = "Jour " + str(GameManager.current_day)

func _update_inventory() -> void:
	bois_label.text = "Bois : " + str(GameManager.get_item("bois"))
	baies_label.text = "Baies : " + str(GameManager.get_item("baies"))
	nourriture_label.text = "Nourriture : " + str(GameManager.get_item("nourriture"))
	pierre_label.text = "Pierre : " + str(GameManager.get_item("pierre"))

func _on_inventory_changed(_item: String, _amount: int) -> void:
	_update_inventory()

func _on_time_changed(h: int, m: int, d: int) -> void:
	time_label.text = "Heure : %02d:%02d" % [h, m]
	day_label.text = "Jour " + str(d)

func _on_day_night_changed(is_day: bool) -> void:
	if is_day:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1.0))
	else:
		time_label.add_theme_color_override("font_color", Color(0.6, 0.7, 1.0, 1.0))
