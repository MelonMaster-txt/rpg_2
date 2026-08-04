# farm_tile.gd
extends Area2D

enum State { EMPTY, PLANTED, WATERED, READY }
var _state: State = State.EMPTY
var _crop:  String = ""
const GROWTH_TIME := 30.0
var GROW_TIME_EFFECTIVE: float = GROWTH_TIME
var _growth_timer: float = 0.0

@onready var _color_rect: ColorRect = $ColorRect
@onready var _label:      Label     = $Label
var _player_near: bool = false

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


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near: return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_interact()


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


func _get_player_inventory() -> Dictionary:
	var chests: Array = get_tree().get_nodes_in_group("chest")
	if chests.size() > 0: return chests[0].inventory
	return {}


func _consume_seed(_inv: Dictionary, seed_key: String) -> void:
	var chests: Array = get_tree().get_nodes_in_group("chest")
	if chests.size() > 0:
		var chest = chests[0]
		chest.inventory[seed_key] = max(0, chest.inventory.get(seed_key, 1) - 1)


func _refresh_visuals() -> void:
	if _color_rect: _color_rect.color = STATE_COLORS.get(_state, Color.WHITE)
	if _label:
		match _state:
			State.EMPTY:   _label.text = "[E] Planter"
			State.PLANTED: _label.text = CROP_ICONS.get(_crop, "🌱") + " Pousse..."
			State.WATERED: _label.text = CROP_ICONS.get(_crop, "🌱") + " 💧 Arrosé"
			State.READY:   _label.text = CROP_ICONS.get(_crop, "🌱") + " [E] Récolter"


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"): _player_near = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"): _player_near = false
