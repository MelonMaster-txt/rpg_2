extends CharacterBody2D

@export var move_speed: float = 120.0
@export var zoom_in_factor: float = 1.2
@export var zoom_out_factor: float = 0.8

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("player")

	if camera != null:
		camera.enabled = true
		print("Player ready. Camera zoom =", camera.zoom)
	else:
		print("ERROR: Camera2D not found under Player")

func _physics_process(_delta: float) -> void:
	var input_vector := Vector2.ZERO

	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	input_vector = input_vector.normalized()
	velocity = input_vector * move_speed
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return

	if event.is_action_pressed("zoom_in"):
		camera.zoom *= zoom_in_factor
		#print("Zoom in ->", camera.zoom)

	if event.is_action_pressed("zoom_out"):
		camera.zoom *= zoom_out_factor
		#print("Zoom out ->", camera.zoom)
