extends CharacterBody2D

@export var move_speed: float = 120.0
@export var zoom_in_factor: float = 1.2
@export var zoom_out_factor: float = 0.8

@onready var camera: Camera2D = $Camera2D
@onready var appearance: Node = $CharacterAppearance

var _held_item: String = ""
signal held_item_changed(item_id: String)

const QUICK_SELECT: Array[String] = ["pioche", "arrosoir", "graine_baie"]
var _quick_index: int = -1

var _anim_timer: float = 0.0
const ANIM_STEP: float = 0.12
var _walk_frame: int = 0

func _ready() -> void:
	add_to_group("player")
	if camera != null:
		camera.enabled = true

func _physics_process(delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	).normalized()
	velocity = dir * move_speed
	move_and_slide()
	_update_animation(dir, delta)

func _update_animation(dir: Vector2, delta: float) -> void:
	if appearance == null:
		return
	if dir != Vector2.ZERO:
		if abs(dir.x) > abs(dir.y):
			appearance.set_direction("right" if dir.x > 0 else "left")
		else:
			appearance.set_direction("down" if dir.y > 0 else "up")
		_anim_timer += delta
		if _anim_timer >= ANIM_STEP:
			_anim_timer = 0.0
			_walk_frame = (_walk_frame + 1) % 8
			appearance.set_walk_frame(_walk_frame)
	else:
		_walk_frame = 0
		_anim_timer = 0.0
		appearance.set_walk_frame(0)

func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return
	if event.is_action_pressed("zoom_in"):
		camera.zoom *= zoom_in_factor
	elif event.is_action_pressed("zoom_out"):
		camera.zoom *= zoom_out_factor
	elif event.is_action_pressed("ui_cancel"):
		set_held_item("")
	elif event.is_action_pressed("interact") and not event.is_echo():
		# Seulement avec la pioche ET seulement si pas dans la maison
		# On NE marque PAS l'event comme handled ici :
		# si farm_placer a traite l'action, il le marque lui-meme
		if _held_item == "pioche":
			_try_farm_interact()
	elif event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and key_event.keycode == KEY_TAB:
			_cycle_held_item()

## Tente de becher/interagir avec le sol.
## NE consomme l'event QUE si le farm_placer a vraiment agi.
func _try_farm_interact() -> void:
	var placer = get_tree().get_first_node_in_group("farm_placer")
	if placer == null or not placer.has_method("interact_at"):
		return
	var handled: bool = placer.interact_at(global_position)
	if handled:
		get_viewport().set_input_as_handled()

func get_inventory() -> Dictionary:
	return GameManager.inventory

func add_item(item_id: String, amount: int = 1) -> void:
	GameManager.add_item(item_id, amount)

func remove_item(item_id: String, amount: int = 1) -> bool:
	return GameManager.remove_item(item_id, amount)

func get_held_item() -> String:
	return _held_item

func set_held_item(item_id: String) -> void:
	_held_item = item_id
	held_item_changed.emit(item_id)

func _cycle_held_item() -> void:
	_quick_index = (_quick_index + 1) % QUICK_SELECT.size()
	var candidate: String = QUICK_SELECT[_quick_index]
	if GameManager.get_item(candidate) > 0:
		set_held_item(candidate)
	else:
		set_held_item("")
