# GameManager.gd — Autoload singleton
extends Node

# ─── SIGNALS ──────────────────────────────────────────────────────────────────
signal inventory_changed(item: String, amount: int)
signal stats_changed
signal buff_applied(stat: String, amount: int, duration: float)
signal time_changed(hour: int, minute: int, day: int)
signal day_night_changed(is_day: bool)

# ─── CONSTANTES ───────────────────────────────────────────────────────────────
const DAY_DURATION: float = 240.0

# ─── INVENTORY ────────────────────────────────────────────────────────────────
var inventory: Dictionary = {
	"wood":         0,
	"berries":      0,
	"stone":        0,
	"mushroom":     0,
	"flint":        0,
	"herb":         0,
	"resin":        0,
	"bone":         0,
	"corde":        0,
	"colle_resine": 0,
	"cuir":         0,
	"hoe":          0,
	"watering_can": 0,
	"berry_seed":   0,
	"couteau_silex": 0,
	"hache_silex":   0,
	"pioche_silex":  0,
	"arc_primitif":  0,
	"torche":        0,
	"hache_pierre":  0,
	"pioche_pierre": 0,
	"bandage":          0,
	"potion_soin":      0,
	"soupe_champignon": 0,
	"the_herbal":       0,
	"armure_cuir":   0,
	"bouclier_os":   0,
	"amulette_foi":  0,
	"gold":          0,
}

# ─── GAME STATS ───────────────────────────────────────────────────────────────
var life: int         = 100
var max_life: int     = 100
var force: int        = 10
var stamina: int      = 10
var luck: int         = 5
var intelligence: int = 5
var charisma: int     = 5
var speed: int        = 10
var armor: int        = 0

var _active_buffs: Dictionary = {}

# ─── TIME ─────────────────────────────────────────────────────────────────────
var current_time: float = 0.0
var current_day: int    = 1
var hour: int           = 6
var minute: int         = 0
var is_day: bool        = true
var play_time: float    = 0.0

# ─── SPAWN POSITION ───────────────────────────────────────────────────────────
var saved_spawn_position: Vector2 = Vector2.ZERO
var has_saved_position: bool = false

# ─── FARM TILES ───────────────────────────────────────────────────────────────
var farm_tiles_data: Array = []

# ─── INVENTORY METHODS ────────────────────────────────────────────────────────
func add_item(item: String, amount: int = 1) -> void:
	if inventory.has(item):
		inventory[item] += amount
	else:
		inventory[item] = amount
	inventory_changed.emit(item, inventory[item])

func remove_item(item: String, amount: int = 1) -> bool:
	if inventory.get(item, 0) >= amount:
		inventory[item] -= amount
		inventory_changed.emit(item, inventory[item])
		return true
	return false

func get_item(item: String) -> int:
	return inventory.get(item, 0)

# ─── STATS METHODS ────────────────────────────────────────────────────────────
func apply_buff(stat: String, amount: int, duration: float) -> void:
	_active_buffs[stat] = {"amount": amount, "timer": duration}
	_apply_stat_delta(stat, amount)
	buff_applied.emit(stat, amount, duration)
	stats_changed.emit()

func _apply_stat_delta(stat: String, delta: int) -> void:
	match stat:
		"life":         life     = clampi(life     + delta, 0, max_life)
		"force":        force    = maxi(1, force    + delta)
		"stamina":      stamina  = maxi(1, stamina  + delta)
		"luck":         luck     = maxi(0, luck     + delta)
		"speed":        speed    = maxi(1, speed    + delta)
		"charisma":     charisma = maxi(0, charisma + delta)
		"armor":        armor    = maxi(0, armor    + delta)

func heal(amount: int) -> void:
	life = clampi(life + amount, 0, max_life)
	stats_changed.emit()

# ─── SPAWN METHODS ────────────────────────────────────────────────────────────
func save_spawn_position(pos: Vector2) -> void:
	saved_spawn_position = pos
	has_saved_position = true

func consume_spawn_position() -> Vector2:
	has_saved_position = false
	return saved_spawn_position

# ─── FARM TILES METHODS ───────────────────────────────────────────────────────
func save_farm_tiles(tile_map: Dictionary) -> void:
	farm_tiles_data.clear()
	for tile: Variant in tile_map.values():
		if is_instance_valid(tile) and tile.has_method("get_save_data"):
			farm_tiles_data.append(tile.get_save_data())

func restore_farm_tiles(container: Node, tile_map: Dictionary) -> void:
	if container == null or farm_tiles_data.is_empty():
		return
	var scene: Resource = load("res://game/world/farm_tile.tscn")
	if scene == null:
		return
	for data: Variant in farm_tiles_data:
		var tile: Node2D = scene.instantiate()
		tile.global_position = data["pos"]
		container.add_child(tile)
		tile_map[_pos_key(data["pos"])] = tile
		tile.call_deferred("load_save_data", data)

func _pos_key(pos: Vector2) -> String:
	return "%d_%d" % [int(pos.x), int(pos.y)]

func get_time_string() -> String:
	return "%02d:%02d" % [hour, minute]

# ─── PROCESS ──────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	var expired: Array = []
	for stat: String in _active_buffs:
		_active_buffs[stat]["timer"] -= delta
		if _active_buffs[stat]["timer"] <= 0.0:
			_apply_stat_delta(stat, -_active_buffs[stat]["amount"])
			expired.append(stat)
			stats_changed.emit()
	for stat: String in expired:
		_active_buffs.erase(stat)

	if not get_tree().paused:
		play_time += delta

	current_time += delta
	if current_time >= DAY_DURATION:
		current_time = 0.0
		current_day += 1

	var progress: float        = current_time / DAY_DURATION
	var game_hour_float: float = 6.0 + progress * 24.0
	var real_hour: int         = int(game_hour_float) % 24
	var real_minute: int       = int((game_hour_float - int(game_hour_float)) * 60)

	if real_hour != hour or real_minute != minute:
		hour   = real_hour
		minute = real_minute
		time_changed.emit(hour, minute, current_day)
		var new_is_day: bool = (hour >= 6 and hour < 20)
		if new_is_day != is_day:
			is_day = new_is_day
			day_night_changed.emit(is_day)
