# ResourceNode.gd
# Structure de la scene :
#   ResourceNode (Area2D)
#     ├── CollisionShape2D
#     ├── Sprite2D
#     ├── InteractHint (Label)
#     └── RespawnTimer (Timer)
extends Area2D

enum ResourceType { BOIS, BAIES, PIERRE }

@export var resource_type: ResourceType = ResourceType.BOIS
@export var amount_min: int = 1
@export var amount_max: int = 3
@export var respawn_time: float = 30.0

@onready var sprite: Node               = $Sprite2D
@onready var interact_hint: Label       = $InteractHint
@onready var respawn_timer: Timer       = $RespawnTimer
@onready var collision: CollisionShape2D = $CollisionShape2D

var is_depleted: bool   = false
var player_nearby: bool = false

func _ready() -> void:
	respawn_timer.wait_time = respawn_time
	respawn_timer.one_shot  = true
	respawn_timer.timeout.connect(_on_respawn)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	interact_hint.visible = false
	match resource_type:
		ResourceType.BOIS:   interact_hint.text = "[E] Couper le bois"
		ResourceType.BAIES:  interact_hint.text = "[E] Cueillir des baies"
		ResourceType.PIERRE: interact_hint.text = "[E] Ramasser de la pierre"

func _unhandled_input(event: InputEvent) -> void:
	# On utilise _unhandled_input pour ne pas entrer en conflit
	# avec d'autres handlers (workbench, etc.)
	if player_nearby and not is_depleted and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		harvest()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if not is_depleted:
			interact_hint.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		interact_hint.visible = false

func harvest() -> void:
	var amount: int = randi_range(amount_min, amount_max)
	var item_key: String = ""
	var label_text: String = ""
	match resource_type:
		ResourceType.BOIS:
			item_key   = "bois"
			label_text = "+%d Bois" % amount
		ResourceType.BAIES:
			item_key   = "baies"
			label_text = "+%d Baies" % amount
		ResourceType.PIERRE:
			item_key   = "pierre"
			label_text = "+%d Pierre" % amount
	if item_key != "":
		GameManager.add_item(item_key, amount)
		_show_pickup_text(label_text)
	_deplete()

func can_gather() -> bool:
	return not is_depleted

func _deplete() -> void:
	is_depleted = true
	interact_hint.visible = false
	if sprite is CanvasItem:
		(sprite as CanvasItem).modulate.a = 0.3
	collision.disabled = true
	respawn_timer.start()

func _on_respawn() -> void:
	is_depleted = false
	if sprite is CanvasItem:
		(sprite as CanvasItem).modulate.a = 1.0
	collision.disabled = false
	if player_nearby:
		interact_hint.visible = true

func _show_pickup_text(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.position = Vector2(-20, -40)
	label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(label)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -30), 0.8)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)
