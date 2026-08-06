# HUD.gd
extends CanvasLayer

<<<<<<< HEAD
@onready var time_label:          Label = $HUDPanel/HUDContainer/TimeLabel
@onready var day_label:           Label = $HUDPanel/HUDContainer/DayLabel
@onready var money_label:         Label = $HUDPanel/HUDContainer/MoneyLabel
@onready var life_label:          Label = $HUDPanel/HUDContainer/LifeLabel
@onready var Force_label:         Label = $HUDPanel/HUDContainer/ForceLabel
@onready var Stamina_label:       Label = $HUDPanel/HUDContainer/StaminaLabel
@onready var Luck_label:          Label = $HUDPanel/HUDContainer/LuckLabel
@onready var Intelligence_label:  Label = $HUDPanel/HUDContainer/IntelligenceLabel
@onready var Charisma_label:      Label = $HUDPanel/HUDContainer/CharismaLabel
=======
@onready var time_label:         Label = $HUDPanel/HUDContainer/TimeLabel
@onready var day_label:          Label = $HUDPanel/HUDContainer/DayLabel
@onready var money_label:        Label = $HUDPanel/HUDContainer/MoneyLabel
@onready var life_label:         Label = $HUDPanel/HUDContainer/LifeLabel
@onready var Force_label:        Label = $HUDPanel/HUDContainer/ForceLabel
@onready var Stamina_label:      Label = $HUDPanel/HUDContainer/StaminaLabel
@onready var Luck_label:         Label = $HUDPanel/HUDContainer/LuckLabel
@onready var Intelligence_label: Label = $HUDPanel/HUDContainer/IntelligenceLabel
@onready var Charisma_label:     Label = $HUDPanel/HUDContainer/CharismaLabel
>>>>>>> origin/test_recover

@onready var inventory_screen = $InventoryScreen

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.day_night_changed.connect(_on_day_night_changed)
	_refresh_all()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		get_viewport().set_input_as_handled()
		inventory_screen.toggle()


func _refresh_all() -> void:
<<<<<<< HEAD
	time_label.text         = "Heure: " + GameManager.get_time_string()
	day_label.text          = "Jour %d" % GameManager.current_day
	money_label.text        = "Argent: %d" % GameManager.get_item("money")
	life_label.text         = "Vie: %d" % GameManager.life
	Force_label.text        = "Force: %d" % GameManager.force
	Stamina_label.text      = "Endurance: %d" % GameManager.stamina
	Luck_label.text         = "Chance: %d" % GameManager.luck
	Intelligence_label.text = "Intelligence: %d" % GameManager.intelligence
	Charisma_label.text     = "Charisme: %d" % GameManager.charisma

=======
	time_label.text         = "Time: " + GameManager.get_time_string()
	day_label.text          = "Day %d" % GameManager.current_day
	money_label.text        = "Gold: %d" % GameManager.get_item("gold")
	life_label.text         = "HP: %d" % GameManager.life
	Force_label.text        = "Str: %d" % GameManager.force
	Stamina_label.text      = "Stam: %d" % GameManager.stamina
	Luck_label.text         = "Luck: %d" % GameManager.luck
	Intelligence_label.text = "Int: %d" % GameManager.intelligence
	Charisma_label.text     = "Cha: %d" % GameManager.charisma
>>>>>>> origin/test_recover

func _on_time_changed(h: int, m: int, d: int) -> void:
	time_label.text = "%02d:%02d" % [h, m]
	day_label.text  = "Day %d" % d


func _on_day_night_changed(is_day: bool) -> void:
	if is_day:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6, 1))
	else:
		time_label.add_theme_color_override("font_color", Color(0.6, 0.7, 1.0, 1))


# ── Debug buttons: spawn / clear NPC ───────────────────────────────

func _on_spawn_npc_button_pressed() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var origin: Vector2 = (players[0] as Node2D).global_position
	NpcSpawner.spawn_random_around(origin, 200.0, 1)


func _on_spawn_npc5_button_pressed() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var origin: Vector2 = (players[0] as Node2D).global_position
	NpcSpawner.spawn_random_around(origin, 200.0, 5)


func _on_clear_npc_button_pressed() -> void:
	NpcSpawner.despawn_all()
