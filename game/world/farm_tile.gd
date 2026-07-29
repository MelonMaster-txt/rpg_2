# FarmTile — sans StaticBody ni CollisionShape, juste Area2D de detection joueur
extends Node2D

enum State { SOL, BECHE, PLANTE, PRET }

const GROW_TIME_BASE:    float = 30.0
const GROW_TIME_WATERED: float = 15.0

const COLOR_SOL:    Color = Color(0.55, 0.38, 0.18)
const COLOR_BECHE:  Color = Color(0.28, 0.15, 0.05)
const COLOR_PLANTE: Color = Color(0.20, 0.55, 0.15)
const COLOR_PRET:   Color = Color(0.90, 0.75, 0.10)

@onready var visual:        ColorRect = $Visual
@onready var grow_timer:    Timer     = $GrowTimer
@onready var interact_area: Area2D    = $InteractArea
@onready var hint_label:    Label     = $HintLabel

var state: State = State.SOL
var _player_nearby: bool = false

func _ready() -> void:
	visual.color = COLOR_SOL
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
				var watered := GameManager.get_item("arrosoir") > 0
				grow_timer.wait_time = GROW_TIME_WATERED if watered else GROW_TIME_BASE
				grow_timer.start()
		State.PLANTE:
			if held == "arrosoir" and grow_timer.time_left > GROW_TIME_WATERED:
				grow_timer.wait_time = GROW_TIME_WATERED
				grow_timer.start()
				_show_popup("\U0001f4a7 Arrose!")
		State.PRET:
			GameManager.add_item("baies", 3)
			_show_popup("+3 \U0001f347")
			_set_state(State.SOL)

func _set_state(s: State) -> void:
	state = s
	_update_visual()
	if _player_nearby:
		_update_hint_for_player()
	else:
		_update_hint("")

func _update_visual() -> void:
	var c: Color
	match state:
		State.SOL:    c = COLOR_SOL
		State.BECHE:  c = COLOR_BECHE
		State.PLANTE: c = COLOR_PLANTE
		State.PRET:   c = COLOR_PRET
	create_tween().tween_property(visual, "color", c, 0.4)

func _update_hint(msg: String) -> void:
	if hint_label:
		hint_label.text = msg
		hint_label.visible = msg != ""

func _update_hint_for_player() -> void:
	match state:
		State.SOL:    _update_hint("[E] Becher")
		State.BECHE:  _update_hint("[E] Planter")
		State.PLANTE: _update_hint("Pousse %ds [E] arroser" % int(grow_timer.time_left))
		State.PRET:   _update_hint("[E] Recolter!")

func _show_popup(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(1, 1, 0.4))
	lbl.position = Vector2(-24, -40)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -28), 0.9)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.9)
	tw.tween_callback(lbl.queue_free)

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
