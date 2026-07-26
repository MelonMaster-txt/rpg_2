extends Area2D

var player_in_area: bool = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_in_area = true
		print("Player ENTERED HutEntrance")

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_in_area = false
		print("Player EXITED HutEntrance")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		print("HutEntrance _input received, player_in_area =", player_in_area)
		if player_in_area:
			print("HutEntrance: teleporting to hut")
			SceneManager.change_scene("res://game/world/scenes/hut.tscn")
