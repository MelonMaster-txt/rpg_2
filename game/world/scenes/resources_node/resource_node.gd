extends Area2D

@export var resource_name: String = "Resource"
@export var resource_type: String = "generic"
@export var max_health: int = 3
@export var gather_amount: int = 1
@export var respawn_time: float = 12.0

@onready var visual = $Visual
@onready var label = $Label
@onready var gather_shape = $GatherShape
@onready var blocker = $Blocker
@onready var blocker_shape = $Blocker/BlockerShape

var current_health: int
var is_depleted: bool = false


func _ready() -> void:
	current_health = max_health
	label.visible = false
	label.text = resource_name
	add_to_group("resource_nodes")


func get_interaction_text() -> String:
	if is_depleted:
		return ""
	return "E : Recolter " + resource_name


func can_gather() -> bool:
	return not is_depleted


func gather() -> Dictionary:
	if is_depleted:
		return {}

	current_health -= 1

	if current_health <= 0:
		deplete()

	return {
		"type": resource_type,
		"amount": gather_amount,
		"name": resource_name
	}


func deplete() -> void:
	if is_depleted:
		return

	is_depleted = true
	current_health = 0
	label.visible = false

	if gather_shape != null:
		gather_shape.disabled = true

	if blocker_shape != null:
		blocker_shape.disabled = true

	notify_harvested_and_remove()


func notify_harvested_and_remove() -> void:
	var chunk_manager = get_tree().get_first_node_in_group("chunk_manager")
	if chunk_manager != null and chunk_manager.has_method("on_resource_harvested"):
		chunk_manager.on_resource_harvested(self, respawn_time)

	queue_free()


func show_label() -> void:
	if not is_depleted:
		label.visible = true


func hide_label() -> void:
	label.visible = false
