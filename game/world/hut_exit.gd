extends Area2D

var player_in_area: bool = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_area = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_area = false

func _input(event: InputEvent) -> void:
	if player_in_area \
	and event.is_action_pressed("interact"):
		SceneManager.change_scene("res://game/world/scenes/overworld.tscn")
