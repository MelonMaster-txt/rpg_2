# FarmTile — cultivable soil
extends Node2D

enum State { SOIL, TILLED, PLANTED, READY }

const GROW_TIME_BASE:    float = 30.0
const GROW_TIME_WATERED: float = 15.0

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

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_try_interact()

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
		State.SOIL:    c = COLOR_SOIL
		State.TILLED:  c = COLOR_TILLED
		State.PLANTED: c = COLOR_PLANTED
		State.READY:   c = COLOR_READY
	create_tween().tween_property(visual, "color", c, 0.4)

func _update_hint(msg: String) -> void:
	if hint_label:
		hint_label.text = msg
		hint_label.visible = msg != ""

func _update_hint_for_player() -> void:
	match state:
		State.SOIL:    _update_hint("[E] Till")
		State.TILLED:  _update_hint("[E] Plant")
		State.PLANTED: _update_hint("Growing %ds" % int(grow_timer.time_left))
		State.READY:   _update_hint("[E] Harvest!")

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
	if state == State.PLANTED:
		_set_state(State.READY)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		_player_cache = body
		_update_hint_for_player()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		_update_hint("")

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
