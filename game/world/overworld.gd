extends Node2D

const PLAYER_SCENE := preload("res://game/characters/player/player.tscn")

@onready var player_container: Node2D = $PlayerContainer
@onready var player_spawn: Marker2D = $PlayerSpawn

func _ready() -> void:
	call_deferred("spawn_player")

func spawn_player() -> void:
	var player = PLAYER_SCENE.instantiate()
	player.global_position = player_spawn.global_position
	player_container.add_child(player)
