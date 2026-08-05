# GameManager.gd — Autoload singleton
extends Node

# ─── INVENTORY ────────────────────────────────────────────────────────────────
var inventory: Dictionary = {
	# ─ Ressources brutes ────────────────────────────────────────────────
	"wood":         0,
	"berries":      0,
	"stone":        0,
	"mushroom":     0,
	"flint":        0,
	"herb":         0,
	"resin":        0,
	"bone":         0,
	# ─ Ressources craftées intermédiaires ──────────────────────────────
	"corde":        0,
	"colle_resine": 0,
	"cuir":         0,
	# ─ Outils agricoles ─────────────────────────────────────────────
	"hoe":          0,
	"watering_can": 0,
	"berry_seed":   0,
	# ─ Outils T1 ──────────────────────────────────────────────────
	"couteau_silex": 0,
	"hache_silex":   0,
	"pioche_silex":  0,
	"arc_primitif":  0,
	"torche":        0,
	# ─ Outils T2 ──────────────────────────────────────────────────
	"hache_pierre":  0,
	"pioche_pierre": 0,
	# ─ Consommables ──────────────────────────────────────────────
	"bandage":          0,
	"potion_soin":      0,
	"soupe_champignon": 0,
	"the_herbal":       0,
	# ─ Équipements T3 ────────────────────────────────────────────
	"armure_cuir":   0,
	"bouclier_os":   0,
	"amulette_foi":  0,
	# ─ Divers ────────────────────────────────────────────────────
	"gold":          0,
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

# Buffs temporaires actifs { "stat": { "amount": int, "timer": float } }
var _active_buffs: Dictionary = {}

signal stats_changed
signal buff_applied(stat: String, amount: int, duration: float)

# Applique un buff temporaire sur une stat
func apply_buff(stat: String, amount: int, duration: float) -> void:
	_active_buffs[stat] = {"amount": amount, "timer": duration}
	_apply_stat_delta(stat, amount)
	emit_signal("buff_applied", stat, amount, duration)
	emit_signal("stats_changed")

func _apply_stat_delta(stat: String, delta: int) -> void:
	match stat:
		"life":         life    = clampi(life    + delta, 0, max_life)
		"force":        force   = maxi(1, force   + delta)
		"stamina":      stamina = maxi(1, stamina + delta)
		"luck":         luck    = maxi(0, luck    + delta)
		"speed":        speed   = maxi(1, speed   + delta)
		"charisma":     charisma = maxi(0, charisma + delta)
		"armor":        armor   = maxi(0, armor   + delta)

# Restaure des HP directement (consommable)
func heal(amount: int) -> void:
	life = clampi(life + amount, 0, max_life)
	emit_signal("stats_changed")

func _process(delta: float) -> void:
	# Tick buffs
	var expired: Array = []
	for stat in _active_buffs:
		_active_buffs[stat]["timer"] -= delta
		if _active_buffs[stat]["timer"] <= 0.0:
			# Retire le buff
			_apply_stat_delta(stat, -_active_buffs[stat]["amount"])
			expired.append(stat)
			emit_signal("stats_changed")
	for stat in expired:
		_active_buffs.erase(stat)

	# Real playtime
	if not get_tree().paused:
		play_time += delta

	current_time += delta
	if current_time >= DAY_DURATION:
		current_time = 0.0
		current_day += 1

	var progress: float       = current_time / DAY_DURATION
	var game_hour_float: float = 6.0 + progress * 24.0
	var real_hour: int         = int(game_hour_float) % 24
	var real_minute: int       = int((game_hour_float - int(game_hour_float)) * 60)

	if real_hour != hour or real_minute != minute:
		hour   = real_hour
		minute = real_minute
		emit_signal("time_changed", hour, minute, current_day)
		var new_is_day: bool = (hour >= 6 and hour < 20)
		if new_is_day != is_day:
			is_day = new_is_day
			emit_signal("day_night_changed", is_day)

# ─── SPAWN POSITION ───────────────────────────────────────────────────────────
var saved_spawn_position: Vector2 = Vector2.ZERO
var has_saved_position: bool = false

func save_spawn_position(pos: Vector2) -> void:
	saved_spawn_position = pos
	has_saved_position = true

func consume_spawn_position() -> Vector2:
	has_saved_position = false
	return saved_spawn_position

# ─── FARM TILES PERSISTENCE ───────────────────────────────────────────────────
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

# ─── TIME ─────────────────────────────────────────────────────────────────────
const DAY_DURATION: float = 240.0

var current_time: float = 0.0
var current_day: int    = 1
var hour: int           = 6
var minute: int         = 0
var is_day: bool        = true
var play_time: float    = 0.0

signal time_changed(hour: int, minute: int, day: int)
signal day_night_changed(is_day: bool)

func get_time_string() -> String:
	return "%02d:%02d" % [hour, minute]
