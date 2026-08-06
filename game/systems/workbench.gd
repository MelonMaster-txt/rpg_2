# Workbench - Zone interactive dans la hut
# Scène : Area2D > CollisionShape2D
extends Area2D

signal player_in_range(is_in: bool)

@export var interaction_label: String = "[E] Workbench"

var _player_nearby: bool = false

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _input(event: InputEvent) -> void:
	if _player_nearby and event.is_action_pressed("interact"):
		_open_workbench()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		player_in_range.emit(true)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		player_in_range.emit(false)

func _open_workbench() -> void:
	var ui: Node = get_tree().get_first_node_in_group("workbench_ui")
	if ui:
		ui.open()
