# FarmTile - Tuile agricole interactive
# Structure :
#   FarmTile (StaticBody2D)
#     - Sprite2D  (ColorRect placeholder)
#     - CollisionShape2D
#     - Area2D > CollisionShape2D
#     - GrowTimer (Timer)
#     - HintLabel (Label)  <- hint contextuel
extends StaticBody2D

enum State { SOL, BECHE, PLANTE, PRET }

const GROW_TIME_BASE:    float = 30.0
const GROW_TIME_WATERED: float = 15.0

const COLOR_SOL:    Color = Color(0.55, 0.38, 0.18)
const COLOR_BECHE:  Color = Color(0.35, 0.22, 0.08)
const COLOR_PLANTE: Color = Color(0.20, 0.55, 0.15)
const COLOR_PRET:   Color = Color(0.90, 0.75, 0.10)

@onready var visual:        ColorRect  = $Sprite2D
@onready var grow_timer:    Timer      = $GrowTimer
@onready var interact_area: Area2D     = $Area2D
@onready var hint_label:    Label      = $HintLabel

var state: State = State.SOL
var _player_nearby: bool = false

func _ready() -> void:
	_update_visual()
	_update_hint("")
	grow_timer.timeout.connect(_on_grow_timer_timeout)
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_try_interact()

func _try_interact() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if not player:
		return
	var held: String = player.get_held_item() if player.has_method("get_held_item") else ""

	match state:
		State.SOL:
			if held == "pioche":
				_set_state(State.BECHE)
		State.BECHE:
			if held == "graine_baie" and GameManager.get_item("graine_baie") > 0:
				GameManager.remove_item("graine_baie", 1)
				_set_state(State.PLANTE)
				var has_arrosoir: bool = GameManager.get_item("arrosoir") > 0
				grow_timer.wait_time = GROW_TIME_WATERED if has_arrosoir else GROW_TIME_BASE
				grow_timer.start()
		State.PLANTE:
			if held == "arrosoir":
				if grow_timer.time_left > GROW_TIME_WATERED:
					grow_timer.wait_time = GROW_TIME_WATERED
					grow_timer.start()
		State.PRET:
			GameManager.add_item("baies", 3)
			_set_state(State.SOL)

func _set_state(new_state: State) -> void:
	state = new_state
	_update_visual()
	if _player_nearby:
		_update_hint_for_player()
	else:
		_update_hint("")

func _update_visual() -> void:
	match state:
		State.SOL:    visual.color = COLOR_SOL
		State.BECHE:  visual.color = COLOR_BECHE
		State.PLANTE: visual.color = COLOR_PLANTE
		State.PRET:   visual.color = COLOR_PRET

func _update_hint(msg: String) -> void:
	if hint_label == null:
		return
	hint_label.text = msg
	hint_label.visible = msg != ""

func _update_hint_for_player() -> void:
	match state:
		State.SOL:    _update_hint("[E] Bêcher (pioche)")
		State.BECHE:  _update_hint("[E] Planter (graine baie)")
		State.PLANTE:
			var secs: int = int(grow_timer.time_left)
			_update_hint("Pousse dans %ds  [E arrosoir = +rapide]" % secs)
		State.PRET:   _update_hint("[E] Récolter les baies !")

func _on_grow_timer_timeout() -> void:
	if state == State.PLANTE:
		_set_state(State.PRET)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		_update_hint_for_player()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		_update_hint("")
