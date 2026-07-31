# GameManager.gd — Autoload singleton
extends Node

# ─── INVENTAIRE ───────────────────────────────────────────────────────────────
var inventory: Dictionary = {
	"bois":        0,
	"baies":       0,
	"pierre":      0,
	"graine_baie": 0,
	"pioche":      0,
	"arrosoir":    0,
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

#──── GAME STATS ───────────────────────────────────────────────────────────────
var life: int = 0
var force: int = 0
var stamina: int = 0
var luck: int = 0
var intelligence: int = 0
var charisma: int = 0

var speed: int = 0
# ─── SPAWN POSITION ───────────────────────────────────────────────────────────
var saved_spawn_position: Vector2 = Vector2.ZERO
var has_saved_position: bool = false

func save_spawn_position(pos: Vector2) -> void:
	saved_spawn_position = pos
	has_saved_position = true

func consume_spawn_position() -> Vector2:
	has_saved_position = false
	return saved_spawn_position

# ─── FARM TILES PERSISTANCE ───────────────────────────────────────────────────
# Chaque entree : { "pos": Vector2, "state": int, "time_left": float }
var farm_tiles_data: Array = []

func save_farm_tiles(tile_map: Dictionary) -> void:
	farm_tiles_data.clear()
	for tile in tile_map.values():
		if is_instance_valid(tile) and tile.has_method("get_save_data"):
			farm_tiles_data.append(tile.get_save_data())

func restore_farm_tiles(container: Node, tile_map: Dictionary) -> void:
	if container == null or farm_tiles_data.is_empty():
		return
	var scene := load("res://game/world/farm_tile.tscn")
	for data in farm_tiles_data:
		var tile: Node2D = scene.instantiate()
		tile.global_position = data["pos"]
		container.add_child(tile)
		tile_map[_pos_key(data["pos"])] = tile
		tile.call_deferred("load_save_data", data)

func _pos_key(pos: Vector2) -> String:
	return "%d_%d" % [int(pos.x), int(pos.y)]

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
