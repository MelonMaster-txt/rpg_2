extends Node2D

const PLAYER_SCENE := preload("res://game/characters/player/player.tscn")

@onready var _player_container: Node2D = $PlayerContainer
@onready var _player_spawn: Marker2D   = $PlayerSpawn


func _ready() -> void:
	call_deferred("_spawn_player")


func _spawn_player() -> void:
	var player: Node2D = PLAYER_SCENE.instantiate() as Node2D
	player.global_position = _player_spawn.global_position
	_player_container.add_child(player)
