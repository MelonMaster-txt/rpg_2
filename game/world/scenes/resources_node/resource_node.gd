extends Area2D

@export var resource_name: String = "Ressource"
@export var resource_type: String = "generic"
@export var max_health: int = 3
@export var gather_amount: int = 1
@export var respawn_time: float = 12.0

var _visual: Sprite2D = null
var _label: Label = null
var _gather_shape: CollisionShape2D = null
var _blocker_shape: CollisionShape2D = null
var _respawn_timer: Timer = null

var current_health: int = 0
var is_depleted: bool = false
var player_in_area: bool = false


func _ready() -> void:
	current_health = max_health
	add_to_group("resource_nodes")

	_visual        = get_node_or_null("Visual") as Sprite2D
	_label         = get_node_or_null("Label") as Label
	_gather_shape  = get_node_or_null("GatherShape") as CollisionShape2D
	_blocker_shape = get_node_or_null("Blocker/BlockerShape") as CollisionShape2D
	_respawn_timer = get_node_or_null("RespawnTimer") as Timer

	if _label != null:
		_label.text = "[E] " + resource_name
		_label.visible = false

	if _respawn_timer != null:
		_respawn_timer.timeout.connect(_on_respawn)

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and player_in_area and not is_depleted:
		get_viewport().set_input_as_handled()
		_do_gather()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not is_depleted:
		player_in_area = true
		if _label != null:
			_label.visible = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		if _label != null:
			_label.visible = false


func _resource_type_to_key(rtype: String) -> String:
	match rtype:
		"wood", "bois":              return "bois"
		"berry", "baies", "berries": return "baies"
		"stone", "pierre", "rock":   return "pierre"
		_:                            return rtype


func _do_gather() -> void:
	current_health -= 1
	var inv_key: String = _resource_type_to_key(resource_type)
	GameManager.add_item(inv_key, gather_amount)
	_spawn_gather_feedback()  # UNE seule fois
	if current_health <= 0:
		_deplete()


func _deplete() -> void:
	is_depleted = true
	player_in_area = false
	if _label != null:
		_label.visible = false
	if _gather_shape != null:
		_gather_shape.set_deferred("disabled", true)
	if _blocker_shape != null:
		_blocker_shape.set_deferred("disabled", true)
	if _visual != null:
		_visual.modulate.a = 0.3
	if _respawn_timer != null:
		_respawn_timer.start(respawn_time)
	else:
		queue_free()


func _on_respawn() -> void:
	is_depleted = false
	current_health = max_health
	if _gather_shape != null:
		_gather_shape.set_deferred("disabled", false)
	if _blocker_shape != null:
		_blocker_shape.set_deferred("disabled", false)
	if _visual != null:
		_visual.modulate.a = 1.0


func _spawn_gather_feedback() -> void:
	var lbl := Label.new()
	lbl.text = "+%d %s" % [gather_amount, resource_name]
	lbl.position = Vector2(-20, -50)
	add_child(lbl)
	var tw := create_tween()
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -30), 0.8)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_callback(lbl.queue_free)
