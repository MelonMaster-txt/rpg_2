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

# ─── TEMPS ────────────────────────────────────────────────────────────────────
# 1 jour in-game = 240 secondes réelles (modifiable)
const DAY_DURATION: float = 240.0

var current_time: float = 0.0   # secondes dans la journée (0 → DAY_DURATION)
var current_day: int = 1
var hour: int = 6               # on commence à 6h du matin
var minute: int = 0
var is_day: bool = true

signal time_changed(hour: int, minute: int, day: int)
signal day_night_changed(is_day: bool)

func _process(delta: float) -> void:
	current_time += delta
	if current_time >= DAY_DURATION:
		current_time = 0.0
		current_day += 1

	# Convertir en heure (6h → 30h, soit 24h cyclé sur DAY_DURATION)
	var progress: float = current_time / DAY_DURATION  # 0.0 → 1.0
	var game_hour_float: float = 6.0 + progress * 24.0  # commence à 6h
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
