# FarmTile - Tuile agricole interactive
# Scène : StaticBody2D
#   - ColorRect  (Sprite2D placeholder, nom: Sprite2D)
#   - CollisionShape2D
#   - Area2D > CollisionShape2D
#   - Timer (GrowTimer)
extends StaticBody2D

enum State { SOL, BECHE, PLANTE, PRET }

const GROW_TIME_BASE: float = 30.0
const GROW_TIME_WATERED: float = 15.0

# Couleurs représentant les 4 états (placeholder géométrique)
const COLOR_SOL:    Color = Color(0.55, 0.38, 0.18)  # brun clair
const COLOR_BECHE:  Color = Color(0.35, 0.22, 0.08)  # brun foncé
const COLOR_PLANTE: Color = Color(0.2,  0.55, 0.15)  # vert
const COLOR_PRET:   Color = Color(0.9,  0.75, 0.1)   # jaune doré

@onready var visual: ColorRect   = $Sprite2D
@onready var grow_timer: Timer   = $GrowTimer
@onready var interact_area: Area2D = $Area2D

var state: State = State.SOL
var _player_nearby: bool = false

func _ready() -> void:
	_update_visual()
	grow_timer.timeout.connect(_on_grow_timer_timeout)
	if not interact_area.body_entered.is_connected(_on_body_entered):
		interact_area.body_entered.connect(_on_body_entered)
	if not interact_area.body_exited.is_connected(_on_body_exited):
		interact_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby:
		return
	if event.is_action_pressed("interact"):
		_try_interact()

func _try_interact() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var held: String = player.get_held_item()

	match state:
		State.SOL:
			if held == "pioche":
				_set_state(State.BECHE)
		State.BECHE:
			if held == "graine_baie":
				player.remove_item("graine_baie", 1)
				_set_state(State.PLANTE)
				var inv: Dictionary = player.get_inventory()
				grow_timer.wait_time = GROW_TIME_WATERED if inv.get("arrosoir", 0) > 0 else GROW_TIME_BASE
				grow_timer.start()
		State.PLANTE:
			if held == "arrosoir":
				if grow_timer.time_left > GROW_TIME_WATERED:
					grow_timer.wait_time = GROW_TIME_WATERED
					grow_timer.start()
		State.PRET:
			player.add_item("baies", 3)
			_set_state(State.SOL)

func _set_state(new_state: State) -> void:
	state = new_state
	_update_visual()

func _update_visual() -> void:
	match state:
		State.SOL:    visual.color = COLOR_SOL
		State.BECHE:  visual.color = COLOR_BECHE
		State.PLANTE: visual.color = COLOR_PLANTE
		State.PRET:   visual.color = COLOR_PRET

func _on_grow_timer_timeout() -> void:
	if state == State.PLANTE:
		_set_state(State.PRET)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
