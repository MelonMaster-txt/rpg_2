# FarmTile - Tuile agricole interactive
# Scène : StaticBody2D
#   - Sprite2D (frames: sol, beché, planté, prêt)
#   - Area2D > CollisionShape2D (zone d'interaction)
#   - Timer (grow_timer)
extends StaticBody2D

enum State { SOL, BECHE, PLANTE, PRET }

const GROW_TIME_BASE: float = 30.0  # secondes
const GROW_TIME_WATERED: float = 15.0

@export var frame_sol: int = 0
@export var frame_beche: int = 1
@export var frame_plante: int = 2
@export var frame_pret: int = 3

@onready var sprite: Sprite2D = $Sprite2D
@onready var grow_timer: Timer = $GrowTimer
@onready var interact_area: Area2D = $Area2D

var state: State = State.SOL
var _player_nearby: bool = false

func _ready() -> void:
	_update_sprite()
	grow_timer.timeout.connect(_on_grow_timer_timeout)
	if not interact_area.body_entered.is_connected(_on_body_entered):
		interact_area.body_entered.connect(_on_body_entered)
	if not interact_area.body_exited.is_connected(_on_body_exited):
		interact_area.body_exited.connect(_on_body_exited)

func _input(event: InputEvent) -> void:
	if not _player_nearby:
		return
	if event.is_action_pressed("interact"):
		_try_interact()

func _try_interact() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var held = player.get_held_item()  # retourne l'id de l'item en main

	match state:
		State.SOL:
			if held == "pioche":
				_set_state(State.BECHE)
		State.BECHE:
			if held == "graine_baie":
				player.remove_item("graine_baie", 1)
				_set_state(State.PLANTE)
				var watered = player.get_inventory().get("arrosoir", 0) > 0
				grow_timer.wait_time = GROW_TIME_WATERED if watered else GROW_TIME_BASE
				grow_timer.start()
		State.PLANTE:
			if held == "arrosoir":
				# Accélère si pas encore arrosé
				if grow_timer.time_left > GROW_TIME_WATERED:
					grow_timer.wait_time = GROW_TIME_WATERED
					grow_timer.start()
		State.PRET:
			# Récolte
			player.add_item("baies", 3)
			_set_state(State.SOL)

func _set_state(new_state: State) -> void:
	state = new_state
	_update_sprite()

func _update_sprite() -> void:
	match state:
		State.SOL:    sprite.frame = frame_sol
		State.BECHE:  sprite.frame = frame_beche
		State.PLANTE: sprite.frame = frame_plante
		State.PRET:   sprite.frame = frame_pret

func _on_grow_timer_timeout() -> void:
	if state == State.PLANTE:
		_set_state(State.PRET)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
