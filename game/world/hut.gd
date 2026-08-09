extends Node2D

const PLAYER_SCENE: PackedScene = preload("res://game/characters/player/player.tscn")

func _ready() -> void:
	_spawn_player()


func _spawn_player() -> void:
	var spawn: Marker2D   = get_node_or_null("ExitSpawn")
	var container: Node2D = get_node_or_null("PlayerContainer")
	if container == null or spawn == null:
		return

	var existing_player: Node = get_tree().get_first_node_in_group("player")
	if existing_player != null:
		if existing_player.get_parent() != container:
			existing_player.get_parent().remove_child(existing_player)
			container.add_child(existing_player)
		existing_player.global_position = spawn.global_position
		return

	var player: Node2D = PLAYER_SCENE.instantiate()
	player.global_position = spawn.global_position
	container.add_child(player)
