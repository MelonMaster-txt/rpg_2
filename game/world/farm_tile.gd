<<<<<<< HEAD
# farm_tile.gd
extends Area2D

enum State { EMPTY, PLANTED, WATERED, READY }
var _state: State = State.EMPTY
var _crop:  String = ""
const GROWTH_TIME := 30.0
var GROW_TIME_EFFECTIVE: float = GROWTH_TIME
var _growth_timer: float = 0.0
=======
# FarmTile — cultivable soil
extends Node2D

enum State { SOIL, TILLED, PLANTED, READY }
>>>>>>> origin/test_recover

@onready var _color_rect: ColorRect = $ColorRect
@onready var _label:      Label     = $Label
var _player_near: bool = false

<<<<<<< HEAD
const STATE_COLORS := {
	State.EMPTY:   Color(0.35, 0.22, 0.10),
	State.PLANTED: Color(0.30, 0.45, 0.15),
	State.WATERED: Color(0.20, 0.50, 0.25),
	State.READY:   Color(0.15, 0.75, 0.30),
}
const CROP_YIELDS: Dictionary = {
	"berries": { "food": 3, "seed_berries": 1 },
	"wheat":   { "food": 4, "seed_wheat": 1 },
	"herb":    { "herb": 2, "seed_herb": 1 },
}
const CROP_ICONS: Dictionary = {
	"berries": "�ae",
	"wheat":   "🌾",
	"herb":    "🌿",
}

signal harvested(crop: String, yields: Dictionary)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh_visuals()


func _process(delta: float) -> void:
	if _state == State.PLANTED or _state == State.WATERED:
		_growth_timer += delta
		if _growth_timer >= GROW_TIME_EFFECTIVE:
			_state = State.READY
			_refresh_visuals()

=======
const COLOR_SOIL:    Color = Color(0.55, 0.38, 0.18)
const COLOR_TILLED:  Color = Color(0.28, 0.15, 0.05)
const COLOR_PLANTED: Color = Color(0.20, 0.55, 0.15)
const COLOR_READY:   Color = Color(0.90, 0.75, 0.10)

@onready var visual:        ColorRect = $Visual
@onready var grow_timer:    Timer     = $GrowTimer
@onready var interact_area: Area2D    = $InteractArea
@onready var hint_label:    Label     = $HintLabel

var state: State = State.SOIL
var _player_nearby: bool = false
# Cache the player to avoid get_first_node_in_group on every interact
var _player_cache: Node = null

func _ready() -> void:
	visual.color = COLOR_SOIL
	_update_hint("")
	grow_timer.timeout.connect(_on_grow_timer_timeout)
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
>>>>>>> origin/test_recover

func _unhandled_input(event: InputEvent) -> void:
	if not _player_near: return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_interact()

<<<<<<< HEAD
=======
func _try_interact() -> void:
	var player: Node = _player_cache
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		_player_cache = player
	if not player:
		return
	var held: String = player.get_held_item() if player.has_method("get_held_item") else ""
	match state:
		State.SOIL:
			if held == "hoe":
				_set_state(State.TILLED)
		State.TILLED:
			if held == "berry_seed" and GameManager.get_item("berry_seed") > 0:
				GameManager.remove_item("berry_seed", 1)
				_set_state(State.PLANTED)
				var watered: bool = GameManager.get_item("watering_can") > 0
				grow_timer.wait_time = GROW_TIME_WATERED if watered else GROW_TIME_BASE
				grow_timer.start()
		State.PLANTED:
			if held == "watering_can" and grow_timer.time_left > GROW_TIME_WATERED:
				grow_timer.wait_time = GROW_TIME_WATERED
				grow_timer.start()
				_show_popup("Watered!")
		State.READY:
			GameManager.add_item("berries", 3)
			_show_popup("+3 Berries")
			_set_state(State.SOIL)
>>>>>>> origin/test_recover

func _interact() -> void:
	match _state:
		State.EMPTY:   _plant()
		State.PLANTED: _water()
		State.WATERED: pass
		State.READY:   _harvest()


func _plant() -> void:
	var inv := _get_player_inventory()
	var chosen: String = ""
	for crop in ["berries", "wheat", "herb"]:
		var seed_key: String = "seed_" + crop
		if inv.get(seed_key, 0) > 0:
			chosen = crop
			_consume_seed(inv, seed_key)
			break
	if chosen == "": chosen = "berries"
	_crop  = chosen
	_state = State.PLANTED
	_growth_timer = 0.0
	GROW_TIME_EFFECTIVE = GROWTH_TIME
	_refresh_visuals()
	print("[FarmTile] Planté : ", _crop)


func _water() -> void:
	_state = State.WATERED
	_growth_timer = 0.0
	GROW_TIME_EFFECTIVE = 15.0
	_refresh_visuals()


func _harvest() -> void:
	var yields: Dictionary = CROP_YIELDS.get(_crop, { "food": 2 })
	var chests: Array = get_tree().get_nodes_in_group("chest")
	if chests.size() > 0:
		var chest = chests[0]
		for resource in yields: chest.deposit(resource, yields[resource])
	else:
		for resource in yields:
			if GameManager.has_method("add_resource"):
				GameManager.add_resource(resource, yields[resource])
			elif resource == "food":
				var cur = GameManager.get("food")
				GameManager.food = (cur if cur != null else 0) + yields[resource]
	harvested.emit(_crop, yields)
	print("[FarmTile] Récolte %s : %s" % [_crop, str(yields)])
	_crop  = ""
	_state = State.EMPTY
	_growth_timer = 0.0
	_refresh_visuals()

<<<<<<< HEAD
=======
func _update_visual() -> void:
	var c: Color
	match state:
		State.SOIL:    c = COLOR_SOIL
		State.TILLED:  c = COLOR_TILLED
		State.PLANTED: c = COLOR_PLANTED
		State.READY:   c = COLOR_READY
	create_tween().tween_property(visual, "color", c, 0.4)
>>>>>>> origin/test_recover

func _get_player_inventory() -> Dictionary:
	var chests: Array = get_tree().get_nodes_in_group("chest")
	if chests.size() > 0: return chests[0].inventory
	return {}

<<<<<<< HEAD
=======
func _update_hint_for_player() -> void:
	match state:
		State.SOIL:    _update_hint("[E] Till")
		State.TILLED:  _update_hint("[E] Plant")
		State.PLANTED: _update_hint("Growing %ds" % int(grow_timer.time_left))
		State.READY:   _update_hint("[E] Harvest!")
>>>>>>> origin/test_recover

func _consume_seed(_inv: Dictionary, seed_key: String) -> void:
	var chests: Array = get_tree().get_nodes_in_group("chest")
	if chests.size() > 0:
		var chest = chests[0]
		chest.inventory[seed_key] = max(0, chest.inventory.get(seed_key, 1) - 1)

<<<<<<< HEAD
=======
func _on_grow_timer_timeout() -> void:
	if state == State.PLANTED:
		_set_state(State.READY)
>>>>>>> origin/test_recover

func _refresh_visuals() -> void:
	if _color_rect: _color_rect.color = STATE_COLORS.get(_state, Color.WHITE)
	if _label:
		match _state:
			State.EMPTY:   _label.text = "[E] Planter"
			State.PLANTED: _label.text = CROP_ICONS.get(_crop, "🌱") + " Pousse..."
			State.WATERED: _label.text = CROP_ICONS.get(_crop, "🌱") + " 💧 Arrosé"
			State.READY:   _label.text = CROP_ICONS.get(_crop, "🌱") + " [E] Récolter"


<<<<<<< HEAD
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"): _player_near = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"): _player_near = false
=======
# ─── PERSISTENCE ──────────────────────────────────────────────────────────────
func get_save_data() -> Dictionary:
	return {
		"pos":       global_position,
		"state":     int(state),
		"time_left": grow_timer.time_left if state == State.PLANTED else 0.0,
	}

func load_save_data(data: Dictionary) -> void:
	state = data.get("state", State.SOIL) as State
	_update_visual()
	if state == State.PLANTED:
		var tl: float = data.get("time_left", GROW_TIME_BASE)
		if tl > 0.0:
			grow_timer.wait_time = tl
			grow_timer.start()
		else:
			_set_state(State.READY)
>>>>>>> origin/test_recover
