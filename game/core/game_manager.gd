# GameManager.gd — Autoload singleton
extends Node

# ─── INVENTAIRE ───────────────────────────────────────────────────────────────
var inventory: Dictionary = {
	"bois": 0,
	"baies": 0,
	"nourriture": 0,
	"pierre": 0,
}

signal inventory_changed(item: String, amount: int)

func add_item(item: String, amount: int = 1) -> void:
	if inventory.has(item):
		inventory[item] += amount
	else:
		inventory[item] = amount
	emit_signal("inventory_changed", item, inventory[item])

func remove_item(item: String, amount: int = 1) -> bool:
	if inventory.get(item, 0) >= amount:
		inventory[item] -= amount
		emit_signal("inventory_changed", item, inventory[item])
		return true
	return false

func get_item(item: String) -> int:
	return inventory.get(item, 0)

# ─── SPAWN POSITION ───────────────────────────────────────────────────────────
# Sauvegarde la position du joueur avant un changement de scène
var saved_spawn_position: Vector2 = Vector2.ZERO
var has_saved_position: bool = false

func save_spawn_position(pos: Vector2) -> void:
	saved_spawn_position = pos
	has_saved_position = true

func consume_spawn_position() -> Vector2:
	has_saved_position = false
	return saved_spawn_position

# ─── TEMPS ────────────────────────────────────────────────────────────────────
const DAY_DURATION: float = 240.0

var current_time: float = 0.0
var current_day: int = 1
var hour: int = 6
var minute: int = 0
var is_day: bool = true

signal time_changed(hour: int, minute: int, day: int)
signal day_night_changed(is_day: bool)

func _process(delta: float) -> void:
	current_time += delta
	if current_time >= DAY_DURATION:
		current_time = 0.0
		current_day += 1

	var progress: float = current_time / DAY_DURATION
	var game_hour_float: float = 6.0 + progress * 24.0
	var real_hour: int = int(game_hour_float) % 24
	var real_minute: int = int((game_hour_float - int(game_hour_float)) * 60)

	if real_hour != hour or real_minute != minute:
		hour = real_hour
		minute = real_minute
		emit_signal("time_changed", hour, minute, current_day)

		var new_is_day: bool = (hour >= 6 and hour < 20)
		if new_is_day != is_day:
			is_day = new_is_day
			emit_signal("day_night_changed", is_day)

func get_time_string() -> String:
	return "%02d:%02d" % [hour, minute]
