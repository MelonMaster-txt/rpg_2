extends Area2D

@export var resource_name: String = "Resource"
@export var resource_type: String = "generic"
@export var max_health: int = 3
@export var gather_amount: int = 1
@export var respawn_time: float = 12.0

# Références optionnelles — tolèrent l'absence du noeud dans la scène
var _visual: Node = null
var _label: Label = null
var _gather_shape: CollisionShape2D = null
var _blocker_shape: CollisionShape2D = null

var current_health: int
var is_depleted: bool = false
var player_in_area: bool = false


func _ready() -> void:
	current_health = max_health
	add_to_group("resource_nodes")

	_visual        = get_node_or_null("Visual")
	_label         = get_node_or_null("Label")
	_gather_shape  = get_node_or_null("GatherShape")
	_blocker_shape = get_node_or_null("Blocker/BlockerShape")

	if _label != null:
		_label.text = resource_name
		_label.visible = false

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not is_depleted:
		player_in_area = true
		_show_label()


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_in_area = false
		_hide_label()


func can_gather() -> bool:
	return not is_depleted and player_in_area


func gather() -> Dictionary:
	if not can_gather():
		return {}
	current_health -= 1
	if current_health <= 0:
		_deplete()
	return {
		"type": resource_type,
		"amount": gather_amount,
		"name": resource_name,
	}


func _deplete() -> void:
	if is_depleted:
		return
	is_depleted = true
	player_in_area = false
	current_health = 0
	_hide_label()
	if _gather_shape != null:
		_gather_shape.set_deferred("disabled", true)
	if _blocker_shape != null:
		_blocker_shape.set_deferred("disabled", true)
	# Informe le ChunkManager si besoin de respawn
	var cm := get_tree().get_first_node_in_group("chunk_manager")
	if cm != null and cm.has_method("on_resource_harvested"):
		cm.on_resource_harvested(self, respawn_time)
	queue_free()


func _show_label() -> void:
	if _label != null and not is_depleted:
		_label.visible = true


func _hide_label() -> void:
	if _label != null:
		_label.visible = false
