extends Node2D

signal harvested(item: String, amount: int)

enum TileState { EMPTY, SEEDED, GROWING, READY }

const GROW_TIME: float = 60.0

var state: TileState = TileState.EMPTY
var seed_type: String = ""
var grow_timer: float = 0.0
var _is_watered: bool = false


func plant(seed: String) -> void:
	if state != TileState.EMPTY:
		return
	seed_type = seed
	state = TileState.SEEDED
	grow_timer = 0.0


func water() -> void:
	_is_watered = true


func _process(delta: float) -> void:
	if state != TileState.GROWING and state != TileState.SEEDED:
		return
	if not _is_watered:
		return
	grow_timer += delta
	if state == TileState.SEEDED:
		state = TileState.GROWING
	if grow_timer >= GROW_TIME:
		state = TileState.READY


func harvest() -> void:
	if state != TileState.READY:
		return
	harvested.emit(seed_type, 3)
	GameManager.add_item(seed_type, 3)
	state = TileState.EMPTY
	seed_type = ""
	grow_timer = 0.0
	_is_watered = false


func get_save_data() -> Dictionary:
	return {
		"pos": global_position,
		"state": state,
		"seed": seed_type,
		"timer": grow_timer,
		"watered": _is_watered,
	}


func load_save_data(data: Dictionary) -> void:
	state = data.get("state", TileState.EMPTY)
	seed_type = data.get("seed", "")
	grow_timer = data.get("timer", 0.0)
	_is_watered = data.get("watered", false)
