extends Area2D

var player_in_area: bool = false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

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
		if player_in_area:
			print("HutEntrance: teleporting to hut")
			SceneManager.change_scene("res://game/world/scenes/hut.tscn")
