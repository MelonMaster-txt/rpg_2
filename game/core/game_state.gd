# GameState — Autoload singleton
extends Node

const OVERWORLD := "res://game/world/scenes/overworld.tscn"

var player_name: String      = "Barbarian"
var player_health: int       = 100
var player_position: Vector2 = Vector2.ZERO
var player_gold: int         = 0
var player_level: int        = 1
var current_scene: String    = OVERWORLD
var play_time: float         = 0.0
var day_count: int           = 1
var companions: Array        = []
var workers: Array           = []
var deity: String            = ""
var faith_points: int        = 0
var inventory: Dictionary    = {}
var current_time: float      = 0.0
var current_day_gm: int      = 1
var farm_tiles_data: Array   = []
var time_string: String      = "06:00"


func to_dict() -> Dictionary:
	return {
		"player_name":     player_name,
		"player_health":   player_health,
		"player_position": {"x": player_position.x, "y": player_position.y},
		"player_gold":     player_gold,
		"player_level":    player_level,
		"current_scene":   current_scene,
		"play_time":       play_time,
		"day_count":       day_count,
		"companions":      companions,
		"workers":         workers,
		"deity":           deity,
		"faith_points":    faith_points,
		"inventory":       inventory,
		"current_time":    current_time,
		"current_day_gm":  current_day_gm,
		"farm_tiles_data": farm_tiles_data,
		"time_string":     time_string,
	}


func from_dict(data: Dictionary) -> void:
	player_name     = str(data.get("player_name",   "Barbarian"))
	player_health   = int(data.get("player_health",  100))
	# Cast sécurisé : player_position peut être un Dictionary ou manquer
	var raw_pos: Variant = data.get("player_position", null)
	if raw_pos is Dictionary:
		player_position = Vector2(float(raw_pos.get("x", 0.0)), float(raw_pos.get("y", 0.0)))
	else:
		player_position = Vector2.ZERO
	player_gold     = int(data.get("player_gold",   0))
	player_level    = int(data.get("player_level",  1))
	current_scene   = str(data.get("current_scene", OVERWORLD))
	play_time       = float(data.get("play_time",   0.0))
	day_count       = int(float(str(data.get("day_count", 1))))
	companions      = data.get("companions",        [])
	workers         = data.get("workers",           [])
	deity           = str(data.get("deity",         ""))
	faith_points    = int(data.get("faith_points",  0))
	inventory       = data.get("inventory",         {})
	current_time    = float(data.get("current_time", 0.0))
	current_day_gm  = int(float(str(data.get("current_day_gm", 1))))
	farm_tiles_data = data.get("farm_tiles_data",   [])
	time_string     = str(data.get("time_string",   "06:00"))


func reset() -> void:
	from_dict({})
	play_time = 0.0
	time_string = "06:00"


# --- Called just before save_game() ---
func sync_from_game_manager() -> void:
	inventory       = GameManager.inventory.duplicate()
	current_time    = GameManager.current_time
	current_day_gm  = GameManager.current_day
	day_count       = GameManager.current_day
	play_time       = GameManager.play_time
	player_health   = GameManager.life
	player_level    = GameManager.force
	farm_tiles_data = []
	# Itérateur non typé car Array générique peut contenir des non-Dictionary (ex: JSON chargé)
	for tile in GameManager.farm_tiles_data:
		if tile is Dictionary:
			farm_tiles_data.append(tile)
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_position = (players[0] as Node2D).global_position
	time_string = GameManager.get_time_string()


# --- Called just after load_game() ---
func apply_to_game_manager() -> void:
	for key: String in inventory:
		GameManager.inventory[key] = inventory[key]
	GameManager.current_time    = current_time
	GameManager.current_day     = current_day_gm
	GameManager.play_time       = play_time
	GameManager.life            = player_health
	GameManager.force           = player_level
	GameManager.farm_tiles_data = farm_tiles_data.duplicate()
	GameManager.save_spawn_position(player_position)
