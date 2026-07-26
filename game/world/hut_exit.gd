extends Area2D

# Ramène le joueur dans l'overworld quand il appuie sur [E]
# à la sortie de la cahute.

var _player_in_area: bool = false


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_area = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_area = false


func _unhandled_input(event: InputEvent) -> void:
	if _player_in_area and event.is_action_pressed("interact"):
		SceneManager.change_scene("res://game/world/scenes/overworld.tscn")
