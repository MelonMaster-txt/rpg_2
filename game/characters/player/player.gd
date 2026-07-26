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

	if event.is_action_pressed("zoom_out"):
		camera.zoom *= zoom_out_factor

	if event.is_action_just_pressed("interact"):
		_try_gather()


func _try_gather() -> void:
	var nodes = get_tree().get_nodes_in_group("resource_nodes")
	var candidate = null

	for node in nodes:
		if not node.has_method("gather"):
			continue
		if node.can_gather():
			candidate = node
			break

	if candidate == null:
		return

	var result: Dictionary = candidate.gather()
	if result.is_empty():
		return

	var rtype: String = result.get("type", "")
	var amount: int = result.get("amount", 1)
	var rname: String = result.get("name", rtype)

	var inv_key: String = ""
	match rtype:
		"wood":
			inv_key = "bois"
		"berry", "baies":
			inv_key = "baies"
		"stone", "pierre":
			inv_key = "pierre"
		_:
			inv_key = rtype

	if inv_key != "":
		GameManager.add_item(inv_key, amount)
		_show_pickup_popup("+" + str(amount) + " " + rname)


func _show_pickup_popup(msg: String) -> void:
	var popup = Label.new()
	popup.text = msg
	popup.position = global_position + Vector2(-20, -60)
	get_tree().current_scene.add_child(popup)
	var tw = create_tween()
	tw.tween_property(popup, "position", popup.position + Vector2(0, -40), 0.8)
	tw.parallel().tween_property(popup, "modulate:a", 0.0, 0.8)
	tw.tween_callback(popup.queue_free)
