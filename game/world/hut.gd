extends Node2D

const PLAYER_SCENE = preload("res://game/characters/player/player.tscn")

func _ready() -> void:
	_spawn_player()


func _spawn_player() -> void:
	var spawn: Marker2D = get_node_or_null("ExitSpawn")
	var container: Node2D = get_node_or_null("PlayerContainer")
	if container == null or spawn == null:
		return
	var player = PLAYER_SCENE.instantiate()
	player.global_position = spawn.global_position
	container.add_child(player)
