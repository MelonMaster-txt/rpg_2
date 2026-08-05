# HUD.gd
extends CanvasLayer

@onready var time_label:         Label = $HUDPanel/HUDContainer/TimeLabel
@onready var day_label:          Label = $HUDPanel/HUDContainer/DayLabel
@onready var money_label:        Label = $HUDPanel/HUDContainer/MoneyLabel
@onready var life_label:         Label = $HUDPanel/HUDContainer/LifeLabel
@onready var Force_label:        Label = $HUDPanel/HUDContainer/ForceLabel
@onready var Stamina_label:      Label = $HUDPanel/HUDContainer/StaminaLabel
@onready var Luck_label:         Label = $HUDPanel/HUDContainer/LuckLabel
@onready var Intelligence_label: Label = $HUDPanel/HUDContainer/IntelligenceLabel
@onready var Charisma_label:     Label = $HUDPanel/HUDContainer/CharismaLabel

@onready var inventory_screen = $InventoryScreen

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.day_night_changed.connect(_on_day_night_changed)
	# BUG FIX : connecte stats_changed pour mise à jour live
	GameManager.stats_changed.connect(_refresh_stats)
	GameManager.inventory_changed.connect(_on_inventory_changed)
	_refresh_all()

# BUG FIX : écoute "inventory" (action définie dans inventory_screen.gd)
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		get_viewport().set_input_as_handled()
		inventory_screen.toggle()

func _refresh_all() -> void:
	_refresh_stats()
	time_label.text  = "Time: " + GameManager.get_time_string()
	day_label.text   = "Day %d" % GameManager.current_day
	money_label.text = "Gold: %d" % GameManager.get_item("gold")

func _refresh_stats() -> void:
	life_label.text         = "HP: %d" % GameManager.life
	Force_label.text        = "Str: %d" % GameManager.force
	Stamina_label.text      = "Stam: %d" % GameManager.stamina
	Luck_label.text         = "Luck: %d" % GameManager.luck
	Intelligence_label.text = "Int: %d" % GameManager.intelligence
	Charisma_label.text     = "Cha: %d" % GameManager.charisma

func _on_inventory_changed(item: String, _amount: int) -> void:
	if item == "gold":
		money_label.text = "Gold: %d" % GameManager.get_item("gold")

func _on_time_changed(h: int, m: int, d: int) -> void:
	time_label.text = "%02d:%02d" % [h, m]
	day_label.text  = "Day %d" % d

func _on_day_night_changed(is_day: bool) -> void:
	if is_day:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1))
	else:
		time_label.add_theme_color_override("font_color", Color(0.6, 0.7, 1.0, 1))
