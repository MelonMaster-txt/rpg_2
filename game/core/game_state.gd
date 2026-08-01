# GameState — Autoload singleton
extends Node

const OVERWORLD := "res://game/world/scenes/overworld.tscn"

var player_name: String = "Barbare"
var player_health: int = 100
var player_position: Vector2 = Vector2.ZERO
var player_gold: int = 0
var player_level: int = 1
var current_scene: String = OVERWORLD
var play_time: float = 0.0
var day_count: int = 1
var companions: Array = []
var workers: Array = []
var deity: String = ""
var faith_points: int = 0
var inventory: Dictionary = {}
var current_time: float = 0.0
var current_day_gm: int = 1
var farm_tiles_data: Array = []


func to_dict() -> Dictionary:
	return {
		"player_name": player_name,
		"player_health": player_health,
		"player_position": {"x": player_position.x, "y": player_position.y},
		"player_gold": player_gold,
		"player_level": player_level,
		"current_scene": current_scene,
		"play_time": play_time,
		"day_count": day_count,
		"companions": companions,
		"workers": workers,
		"deity": deity,
		"faith_points": faith_points,
		"inventory": inventory,
		"current_time": current_time,
		"current_day_gm": current_day_gm,
		"farm_tiles_data": farm_tiles_data,
	}


func from_dict(data: Dictionary) -> void:
	player_name    = str(data.get("player_name", "Barbare"))
	player_health  = int(data.get("player_health", 100))
	var pos        = data.get("player_position", {"x": 0.0, "y": 0.0})
	player_position = Vector2(float(pos.get("x", 0.0)), float(pos.get("y", 0.0)))
	player_gold    = int(data.get("player_gold", 0))
	player_level   = int(data.get("player_level", 1))
	current_scene  = str(data.get("current_scene", OVERWORLD))
	play_time      = float(data.get("play_time", 0.0))
	day_count      = int(data.get("day_count", 1))
	companions     = data.get("companions", [])
	workers        = data.get("workers", [])
	deity          = str(data.get("deity", ""))
	faith_points   = int(data.get("faith_points", 0))
	inventory      = data.get("inventory", {})
	current_time   = float(data.get("current_time", 0.0))
	current_day_gm = int(data.get("current_day_gm", 1))
	farm_tiles_data = data.get("farm_tiles_data", [])


func reset() -> void:
	from_dict({})


# Appelé juste avant save_game() pour capturer l'état live du monde
func sync_from_game_manager() -> void:
	inventory       = GameManager.inventory.duplicate()
	current_time    = GameManager.current_time
	current_day_gm  = GameManager.current_day
	farm_tiles_data = []
	for tile in GameManager.farm_tiles_data:
		farm_tiles_data.append(tile)
	# Capture la position live du joueur
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_position = (players[0] as Node2D).global_position


func apply_to_game_manager() -> void:
	for key in inventory:
		GameManager.inventory[key] = inventory[key]
	GameManager.current_time = current_time
	GameManager.current_day  = current_day_gm
	GameManager.farm_tiles_data = farm_tiles_data.duplicate()
	# Indique au GameManager de spawner le joueur à la position sauvegardée
	GameManager.set_spawn_position(player_position)
