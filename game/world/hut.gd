extends Node2D

const PLAYER_SCENE = preload("res://game/characters/player/player.tscn")

func _ready() -> void:
	_spawn_player()


func _spawn_player() -> void:
	var spawn: Marker2D = get_node_or_null("ExitSpawn")
	var container: Node2D = get_node_or_null("PlayerContainer")
	if container == null or spawn == null:
		return

	# S'il existe déjà un joueur (groupe "player"), on le recycle au lieu d'en créer un nouveau
	var existing_player := get_tree().get_first_node_in_group("player")
	if existing_player != null:
		if existing_player.get_parent() != container:
			existing_player.get_parent().remove_child(existing_player)
			container.add_child(existing_player)
		existing_player.global_position = spawn.global_position
		return

	# Sinon, on instancie un joueur pour la cahute
	var player: Node2D = PLAYER_SCENE.instantiate()
	player.global_position = spawn.global_position
	container.add_child(player)
