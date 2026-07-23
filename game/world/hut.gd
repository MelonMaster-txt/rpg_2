extends Node2D

const PLAYER_SCENE := preload("res://game/characters/player/player.tscn")

@onready var player_container: Node2D = $PlayerContainer
@onready var exit_spawn: Marker2D = $ExitSpawn

func _ready() -> void:
	spawn_player()

func spawn_player() -> void:
	var player = PLAYER_SCENE.instantiate()
	player.global_position = exit_spawn.global_position
	player_container.add_child(player)
