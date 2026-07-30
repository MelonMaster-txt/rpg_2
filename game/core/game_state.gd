# game/core/game_state.gd
extends Node

# Données joueur
var player_name: String = "Barbare"
var player_health: int = 100
var player_position: Vector2 = Vector2.ZERO
var player_gold: int = 0
var player_level: int = 1

# Monde
var current_scene: String = "game/world/world.tscn"
var play_time: float = 0.0
var day_count: int = 1

# Compagnons et esclaves
var companions: Array = []
var workers: Array = []

# Religion
var deity: String = ""
var faith_points: int = 0

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
		"faith_points": faith_points
	}

func from_dict(data: Dictionary) -> void:
	player_name = data.get("player_name", "Barbare")
	player_health = data.get("player_health", 100)
	var pos = data.get("player_position", {"x": 0, "y": 0})
	player_position = Vector2(pos["x"], pos["y"])
	player_gold = data.get("player_gold", 0)
	player_level = data.get("player_level", 1)
	current_scene = data.get("current_scene", "game/world/world.tscn")
	play_time = data.get("play_time", 0.0)
	day_count = data.get("day_count", 1)
	companions = data.get("companions", [])
	workers = data.get("workers", [])
	deity = data.get("deity", "")
	faith_points = data.get("faith_points", 0)
