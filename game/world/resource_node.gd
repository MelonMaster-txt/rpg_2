# resource_node.gd
# Attacher sur un Area2D avec les enfants :
#   - Sprite2D
#   - CollisionShape2D
#   - Label (InteractHint)
#   - Timer (RespawnTimer)
extends Area2D

enum ResourceType { BOIS, BAIES }

@export var resource_type: int = ResourceType.BOIS
@export var amount_min: int = 1
@export var amount_max: int = 3
@export var respawn_time: float = 30.0

@onready var sprite = $Sprite2D
@onready var interact_hint = $InteractHint
@onready var respawn_timer = $RespawnTimer
@onready var collision_shape = $CollisionShape2D

var is_depleted: bool = false
var player_nearby: bool = false

func _ready() -> void:
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interact_hint.visible = false

	if resource_type == ResourceType.BOIS:
		interact_hint.text = "[E] Couper le bois"
	else:
		interact_hint.text = "[E] Cueillir des baies"

func _process(_delta: float) -> void:
	if player_nearby and not is_depleted and Input.is_action_just_pressed("interact"):
		harvest()

func _on_body_entered(body) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if not is_depleted:
			interact_hint.visible = true

func _on_body_exited(body) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		interact_hint.visible = false

func harvest() -> void:
	var amount = randi_range(amount_min, amount_max)
	if resource_type == ResourceType.BOIS:
		GameManager.add_item("bois", amount)
		_show_pickup_text("+" + str(amount) + " Bois")
	else:
		GameManager.add_item("baies", amount)
		_show_pickup_text("+" + str(amount) + " Baies")
	_deplete()

func _deplete() -> void:
	is_depleted = true
	interact_hint.visible = false
	sprite.modulate.a = 0.3
	collision_shape.disabled = true
	respawn_timer.start()

func _on_respawn() -> void:
	is_depleted = false
	sprite.modulate.a = 1.0
	collision_shape.disabled = false
	if player_nearby:
		interact_hint.visible = true

func _show_pickup_text(msg: String) -> void:
	var popup = Label.new()
	popup.text = msg
	popup.position = Vector2(-20.0, -40.0)
	popup.modulate = Color(1.0, 1.0, 0.0, 1.0)
	add_child(popup)
	var tw = create_tween()
	tw.tween_property(popup, "position", Vector2(-20.0, -70.0), 0.8)
	tw.parallel().tween_property(popup, "modulate:a", 0.0, 0.8)
	tw.tween_callback(popup.queue_free)
