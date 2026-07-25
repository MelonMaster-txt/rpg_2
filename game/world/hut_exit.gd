extends Area2D

var player_in_area: bool = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_area = true

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_area = false

func _process(_delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("interact"):
		SceneManager.change_scene("res://game/world/scenes/overworld.tscn")
