extends CharacterBody2D

@export var move_speed: float = 120.0
@export var zoom_in_factor: float = 1.2
@export var zoom_out_factor: float = 0.8

@onready var camera: Camera2D = $Camera2D
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Direction courante pour les animations
var _last_dir: Vector2 = Vector2.DOWN

func _ready() -> void:
	add_to_group("player")
	if camera != null:
		camera.enabled = true


func _physics_process(_delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	velocity = dir * move_speed
	move_and_slide()
	_update_animation(dir)


func _update_animation(dir: Vector2) -> void:
	if anim_sprite == null:
		return
	if dir != Vector2.ZERO:
		_last_dir = dir
		# Choisit walk_down/up/left/right selon la direction dominante
		if abs(dir.x) > abs(dir.y):
			anim_sprite.play("walk_right" if dir.x > 0 else "walk_left")
		else:
			anim_sprite.play("walk_down" if dir.y > 0 else "walk_up")
	else:
		# Idle dans la dernière direction regardée
		if abs(_last_dir.x) > abs(_last_dir.y):
			anim_sprite.play("idle_right" if _last_dir.x > 0 else "idle_left")
		else:
			anim_sprite.play("idle_down" if _last_dir.y > 0 else "idle_up")


func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return
	if event.is_action_pressed("zoom_in"):
		camera.zoom *= zoom_in_factor
	if event.is_action_pressed("zoom_out"):
		camera.zoom *= zoom_out_factor
	if event.is_action_pressed("interact"):
		_try_gather()


func _try_gather() -> void:
	var nodes := get_tree().get_nodes_in_group("resource_nodes")
	var best: Node = null
	var best_dist := INF
	for node in nodes:
		if not node.has_method("gather") or not node.can_gather():
			continue
		var d := global_position.distance_to(node.global_position)
		if d < best_dist:
			best_dist = d
			best = node
	if best == null:
		return
	var result: Dictionary = best.gather()
	if result.is_empty():
		return
	var rtype: String = result.get("type", "")
	var amount: int = result.get("amount", 1)
	var rname: String = result.get("name", rtype)
	var inv_key: String = _resource_type_to_key(rtype)
	if inv_key != "":
		GameManager.add_item(inv_key, amount)


func _resource_type_to_key(rtype: String) -> String:
	match rtype:
		"wood", "bois":              return "bois"
		"berry", "baies", "berries": return "baies"
		"stone", "pierre", "rock":   return "pierre"
		"food", "nourriture":        return "nourriture"
		_:                           return rtype
