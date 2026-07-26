# HUD.gd — Interface principale (inventaire + temps)
# Structure de la scène HUD (CanvasLayer) :
#   HUD (CanvasLayer)  <── ce script
#     └── HUDContainer (VBoxContainer, en haut à gauche)
#           ├── TimeLabel       (Label)
#           ├── DayLabel        (Label)
#           ├── HSeparator
#           ├── BoisLabel       (Label)
#           ├── BaiesLabel      (Label)
#           ├── NourritureLabel (Label)
#           └── PierreLabel     (Label)

extends CanvasLayer

@onready var time_label: Label = $HUDContainer/TimeLabel
@onready var day_label: Label = $HUDContainer/DayLabel
@onready var bois_label: Label = $HUDContainer/BoisLabel
@onready var baies_label: Label = $HUDContainer/BaiesLabel
@onready var nourriture_label: Label = $HUDContainer/NourritureLabel
@onready var pierre_label: Label = $HUDContainer/PierreLabel

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
	bois_label.text = "🪵 Bois : %d" % GameManager.get_item("bois")
	baies_label.text = "🍇 Baies : %d" % GameManager.get_item("baies")
	nourriture_label.text = "🍖 Nourriture : %d" % GameManager.get_item("nourriture")
	pierre_label.text = "🪨 Pierre : %d" % GameManager.get_item("pierre")

func _on_inventory_changed(_item: String, _amount: int) -> void:
	_update_inventory()

func _on_time_changed(h: int, m: int, d: int) -> void:
	time_label.text = "⏰ %02d:%02d" % [h, m]
	day_label.text = "📅 Jour %d" % d

func _on_day_night_changed(is_day: bool) -> void:
	if is_day:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))  # jaune jour
	else:
		time_label.add_theme_color_override("font_color", Color(0.6, 0.7, 1.0))   # bleu nuit
